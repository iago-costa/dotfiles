@echo off
setlocal enabledelayedexpansion

:: Admin Check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: This script requires Administrator privileges. Right-click and "Run as administrator".
    pause
    exit /b 1
)

:: VM Detection
set "IS_VM=false"
wmic computersystem get model | findstr /i "VMware VirtualBox Hyper-V" >nul && set IS_VM=true

:: Menu System
:menu
cls
echo ================================
echo    Windows 10 Optimization Script
echo ================================
echo 1. Apply All Optimizations
echo 2. Service Tweaks
echo 3. Memory & Pagefile Tweaks
echo 4. Disk Performance
echo 5. Visual Effects
echo 6. Privacy & Telemetry
echo 7. Security Hardening
echo 8. Exit
choice /c 12345678 /m "Select optimization category:"

goto option%errorlevel%

:option1
call :service_tweaks
call :memory_tweaks
call :disk_tweaks
call :visual_tweaks
call :privacy_tweaks
call :security_tweaks
goto :eof

:option2
call :service_tweaks
goto menu

:option3
call :memory_tweaks
goto menu

:option4
call :disk_tweaks
goto menu

:option5
call :visual_tweaks
goto menu

:option6
call :privacy_tweaks
goto menu

:option7
call :security_tweaks
goto menu

:option8
exit /b 0

:service_tweaks
echo Backing up service states...
sc query state= all > service_backup.txt

:: Common non-essential services
for %%s in (
    "DiagTrack"
    "dmwappushservice"
    "Fax"
    "lfsvc"
    "MapsBroker"
) do (
    sc stop %%s
    sc config %%s start= disabled
)

if %IS_VM%==true (
    for %%s in (
        "SensorService"
        "BluetoothUserService"
        "bthserv"
    ) do (
        sc stop %%s
        sc config %%s start= disabled
    )
)
goto :eof

:memory_tweaks
:: Pagefile optimization
for /f "tokens=3" %%a in ('wmic memorychip get capacity ^| find "Capacity"') do set /a totalmem=%%a/1048576
wmic diskdrive where "mediaType='Fixed hard disk media'" get index,size /format:list | findstr "Size" >nul && set "DRIVE_TYPE=HDD" || set "DRIVE_TYPE=SSD"

if !DRIVE_TYPE!==HDD (
    wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=!totalmem!,MaximumSize=!totalmem!
) else (
    wmic computersystem where name="%computername%" set AutomaticManagedPagefile=true
)
goto :eof

:disk_tweaks
:: SSD TRIM check
fsutil behavior query DisableDeleteNotify | find "0" >nul
if !errorlevel! equ 1 (
    fsutil behavior set DisableDeleteNotify 0
)

:: Defrag settings
if !DRIVE_TYPE!==HDD (
    schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /enable
) else (
    schtasks /change /tn "Microsoft\Windows\Defrag\ScheduledDefrag" /disable
)
goto :eof

:visual_tweaks
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f
:: Additional visual tweaks here
goto :eof

:privacy_tweaks
:: Telemetry disable
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
:: Hosts file blocking
copy /y %windir%\system32\drivers\etc\hosts hosts.backup
echo 0.0.0.0 telemetry.microsoft.com >> %windir%\system32\drivers\etc\hosts
:: Additional privacy tweaks
goto :eof

:security_tweaks
:: Enable security features
powershell -command "Set-MpPreference -EnableControlledFolderAccess Enabled"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f
goto :eof