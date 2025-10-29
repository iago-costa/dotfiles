@echo off
setlocal

:: ================================================================================================
:: SCRIPT START
:: ================================================================================================
::
:: SYNOPSIS:
::   A CMD batch script to apply basic optimizations to a Windows 10 installation.
::
:: DESCRIPTION:
::   Provides a menu to apply service, performance, and privacy tweaks.
::   Includes environment detection for VMs and basic backup capabilities.
::   NOTE: This script is less powerful than its PowerShell equivalent. For tasks like
::   bloatware removal, please use the Win10_Optimize.ps1 script.
::
:: AUTHOR:
::   Expert Windows System Administrator
::
:: VERSION:
::   1.0
::
:: NOTES:
::   Must be run as an Administrator. Use at your own risk.
:: ================================================================================================


:: ------------------------------------------------------------------------------------------------
:: 1. INITIAL SETUP & CHECKS
:: ------------------------------------------------------------------------------------------------

:: Administrator Check
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [!] ERROR: This script must be run as an Administrator.
    echo Please right-click the file and select "Run as administrator".
    pause
    exit
)

:: Create a directory for backups
set "backupDir=C:\Windows_Optimize_Backups"
if not exist "%backupDir%" (
    mkdir "%backupDir%"
    echo [+] Created backup directory at %backupDir%
)

:: Environment Detection (VM vs. Bare-Metal)
set "isVM=false"
set "envType=Bare-Metal"
wmic computersystem get model | find /i "Virtual" >nul && set "isVM=true"
wmic computersystem get model | find /i "VMware" >nul && set "isVM=true"
wmic computersystem get model | find /i "Hyper-V" >nul && set "isVM=true"
if "%isVM%"=="true" set "envType=Virtual Machine"


:: ================================================================================================
:: 2. MAIN MENU
:: ================================================================================================
:MENU
cls
echo ===========================================================
echo     Windows 10 Power User Optimization (CMD Version)
echo ===========================================================
echo Detected Environment: %envType%
echo.
echo Please choose an option:
echo   1. Apply Service Tweaks
echo   2. Apply Performance Tweaks (Visuals, Power Plan)
echo   3. Apply Privacy ^& Telemetry Hardening
echo   4. Apply Basic Security Hardening
echo   -------------------------------------------------
echo   9. Apply ALL Optimizations
echo   Q. Quit
echo.

set /p choice="Enter your choice: "

if /i "%choice%"=="1" goto ApplyServiceTweaks
if /i "%choice%"=="2" goto OptimizePerformance
if /i "%choice%"=="3" goto HardenPrivacy
if /i "%choice%"=="4" goto HardenSecurity
if /i "%choice%"=="9" goto ApplyAll
if /i "%choice%"=="q" exit

echo Invalid choice.
pause
goto MENU


:: ================================================================================================
:: 3. FUNCTION DEFINITIONS (GOTO LABELS)
:: ================================================================================================

:: ------------------------------------------------------------------------------------------------
:: Function: Apply Service Tweaks
:: ------------------------------------------------------------------------------------------------
:ApplyServiceTweaks
cls
echo [+] Applying Service Tweaks...

REM --- Backup current service states ---
echo [+] Backing up service configurations...
wmic service get name,startmode > "%backupDir%\Services_Backup.txt"
echo   [i] Service configurations backed up to %backupDir%\Services_Backup.txt

REM --- Disable general services ---
echo [+] Disabling Connected User Experiences and Telemetry (DiagTrack)...
sc config "DiagTrack" start=disabled
REM To reverse: sc config "DiagTrack" start=auto

echo [+] Disabling Device Management WAP Push (dmwappushservice)...
sc config "dmwappushservice" start=disabled
REM To reverse: sc config "dmwappushservice" start=demand

echo [+] Disabling Fax service...
sc config "Fax" start=disabled
REM To reverse: sc config "Fax" start=demand

REM --- Disable VM-specific services ---
if "%isVM%"=="true" (
    echo [+] VM Detected. Disabling additional services...
    sc config "SensorService" start=disabled
    sc config "bthserv" start=disabled
)

REM --- Ask about Print Spooler ---
set /p printChoice="[?] Do you use a physical printer? (Y/N): "
if /i not "%printChoice%"=="y" (
    echo [+] Disabling Print Spooler...
    sc config "Spooler" start=disabled
    REM To reverse: sc config "Spooler" start=auto
)

echo.
echo [+] Service Tweaks Applied.
pause
goto MENU

:: ------------------------------------------------------------------------------------------------
:: Function: Optimize Performance
:: ------------------------------------------------------------------------------------------------
:OptimizePerformance
cls
echo [+] Applying Performance Optimizations...

REM --- Set Power Plan to High Performance ---
echo [+] Setting power plan to High Performance...
powercfg /SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo   [i] Note: The Ultimate Performance plan can only be reliably set via PowerShell.

REM --- Adjust visual effects for best performance ---
echo [+] Adjusting visual effects for best performance...
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "%backupDir%\VisualEffects_Backup.reg" /y
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f
REM To reverse: Import the .reg backup or change settings in System Properties.

REM --- Reduce menu animation speed ---
echo [+] Reducing menu show delay...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 200 /f
REM To reverse: reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f

echo.
echo [+] Performance Optimizations Applied.
pause
goto MENU

:: ------------------------------------------------------------------------------------------------
:: Function: Harden Privacy & Disable Telemetry
:: ------------------------------------------------------------------------------------------------
:HardenPrivacy
cls
echo [+] Applying Privacy & Telemetry Hardening...

REM --- Registry Tweaks for Telemetry ---
echo [+] Disabling telemetry via registry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
REM To reverse: reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f

REM --- Block Telemetry Domains via Hosts File ---
echo [+] Blocking known telemetry domains via hosts file...
set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"
copy "%hostsFile%" "%hostsFile%.bak" >nul
echo   [i] Original hosts file backed up to hosts.bak

(echo 0.0.0.0 vortex.data.microsoft.com) >> "%hostsFile%"
(echo 0.0.0.0 settings-win.data.microsoft.com) >> "%hostsFile%"
echo   [i] Telemetry domains added to hosts file.
REM To reverse: Delete the added lines from the hosts file or restore hosts.bak

echo.
echo [+] Privacy & Telemetry Hardening Applied.
pause
goto MENU

:: ------------------------------------------------------------------------------------------------
:: Function: Harden System Security
:: ------------------------------------------------------------------------------------------------
:HardenSecurity
cls
echo [+] Applying Basic Security Hardening...

REM --- Disable SMBv1 ---
echo [+] Disabling SMBv1 protocol...
dism /online /Disable-Feature /FeatureName:SMB1Protocol /NoRestart
REM To reverse: dism /online /Enable-Feature /FeatureName:SMB1Protocol /NoRestart

REM --- Enable Controlled Folder Access (via PowerShell from CMD) ---
echo [+] Enabling Controlled Folder Access (Ransomware Protection)...
powershell -Command "Set-MpPreference -EnableControlledFolderAccess Enabled"
echo   [i] Controlled Folder Access is now enabled.

echo.
echo [+] Security Hardening Applied.
pause
goto MENU

:: ------------------------------------------------------------------------------------------------
:: Function: Apply All
:: ------------------------------------------------------------------------------------------------
:ApplyAll
cls
echo [+] Applying ALL optimizations...
call :ApplyServiceTweaks
call :OptimizePerformance
call :HardenPrivacy
call :HardenSecurity
echo.
echo [+] ALL OPTIMIZATIONS APPLIED! A reboot is recommended.
pause
goto MENU