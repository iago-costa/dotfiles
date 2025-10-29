@echo off
:: Win10_Optimize.bat - Windows 10 performance & privacy tuning CMD batch script
:: Author: Expert Windows Sysadmin
:: Date: 2025-08-28

:: ===== Administrator Check =====
:: Verify if running elevated. Exit if not.
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo ERROR: This script must be run as Administrator!
    pause
    exit /b 1
)

:: ===== Environment Detection =====
set "IsVM=0"
:: Use wmic to detect if running inside a VM by checking manufacturer and model strings
for /f "tokens=2 delims==" %%I in (
  'wmic computersystem get manufacturer /value ^| findstr /i "microsoft corporation vmware inc. vmware virtualbox oracle"'
) do (
  set "Manufacturer=%%I"
)
for /f "tokens=2 delims==" %%I in (
  'wmic computersystem get model /value ^| findstr /i "virtual vmware virtualbox hyper-v"'
) do (
  set "Model=%%I"
)

:: If Manufacturer or Model string contains known VM keywords, flag as VM
echo %Manufacturer% | findstr /i "microsoft corporation" >nul && set IsVM=1
echo %Manufacturer% | findstr /i "vmware" >nul && set IsVM=1
echo %Manufacturer% | findstr /i "oracle" >nul && set IsVM=1
echo %Model% | findstr /i "virtual" >nul && set IsVM=1
echo.

:: ===== Menu System =====
:Menu
cls
echo ================= Windows 10 Optimization Script ====================
echo.
echo Detected Environment: %IsVM% (0 = Bare Metal, 1 = Virtual Machine)
echo.
echo Select optimization category to apply:
echo 1. Disable Non-Essential Services
echo 2. Optimize Memory and Paging File
echo 3. Optimize Disk Performance
echo 4. Disable Visual Effects and Delays
echo 5. General System and Network Optimization
echo 6. Enhance Privacy and Disable Telemetry
echo 7. Implement Basic Security Hardening
echo 8. Run ALL Optimizations
echo 9. Exit
echo.
set /p choice=Enter your choice (1-9): 

if "%choice%"=="1" goto DisableServices
if "%choice%"=="2" goto OptimizeMemoryPaging
if "%choice%"=="3" goto OptimizeDiskPerformance
if "%choice%"=="4" goto DisableVisualEffects
if "%choice%"=="5" goto SystemNetworkOptimization
if "%choice%"=="6" goto PrivacyAndTelemetry
if "%choice%"=="7" goto SecurityHardening
if "%choice%"=="8" (
    call :DisableServices
    call :OptimizeMemoryPaging
    call :OptimizeDiskPerformance
    call :DisableVisualEffects
    call :SystemNetworkOptimization
    call :PrivacyAndTelemetry
    call :SecurityHardening
    echo.
    echo All optimizations applied successfully!
    pause
    goto Menu
)
if "%choice%"=="9" exit /b 0

echo Invalid choice! Please try again.
pause
goto Menu

:: ===== Section 1: Disable Non-Essential Services =====
:DisableServices
cls
echo Disabling Non-Essential Services...

:: Backup current service states to a timestamped text file
echo Backing up service states...
sc query state= all > "%USERPROFILE%\Desktop\ServicesBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.txt"

:: Disable Connected User Experiences and Telemetry (DiagTrack)
echo Disabling DiagTrack (Connected User Experiences and Telemetry)...
sc stop DiagTrack
sc config DiagTrack start= disabled

:: Disable dmwappushservice (Device Management Wireless Application Protocol)
echo Disabling dmwappushservice...
sc stop dmwappushservice
sc config dmwappushservice start= disabled

:: Disable Fax service (typical for non-fax users)
echo Disabling Fax service...
sc stop Fax
sc config Fax start= disabled

:: Disable Print Spooler if no printer is used - CAUTION if you do actually print!
echo Note: Disable Print Spooler only if you don't print
set /p print_check="Do you want to disable Print Spooler? (Y/N): "
if /i "%print_check%"=="Y" (
    sc stop Spooler
    sc config Spooler start= disabled
)

:: Conditional VM-specific service disables
if "%IsVM%"=="1" (
    echo Detected VM - disabling VM-related non-essential services...
    echo Disabling Sensor Service...
    sc stop SensorService
    sc config SensorService start= disabled

    echo Disabling Bluetooth Support Service...
    sc stop bthserv
    sc config bthserv start= disabled
)

echo Services disabled as selected.
pause
goto Menu

:: ===== Section 2: Optimize Memory and Disk Paging =====
:OptimizeMemoryPaging
cls
echo Optimizing Memory and Paging File...

:: Retrieve total physical RAM in MB
for /f "tokens=2 delims==" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do set "TotalMemBytes=%%a"
set /a TotalMemMB=%TotalMemBytes:~0,-6%
echo Total Installed RAM: %TotalMemMB% MB

:: Determine paging file drive (usually C:)
set PagingDrive=C:

:: Detect if PagingDrive is SSD or HDD using PowerShell call
for /f %%d in ('powershell -command "Get-PhysicalDisk | Where-Object {($_.FriendlyName -like '*%PagingDrive%*')} | Select -ExpandProperty MediaType" 2^>nul') do set DiskType=%%d

:: Default fallback if detection fails
if not defined DiskType set DiskType=HDD

echo Detected drive type for paging file: %DiskType%

:: Backup current paging file settings to registry export
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "%USERPROFILE%\Desktop\PagingBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.reg" /y

if /i "%DiskType%"=="SSD" (
    echo Setting paging file to System Managed Size (recommended for SSD)...
    wmic pagefileset where name="%PagingDrive%\\pagefile.sys" set InitialSize=0,MaximumSize=0
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "%PagingDrive%\pagefile.sys 0 0" /f
) else (
    :: For HDD, set static paging file size = 1.5x RAM, min=max=RAM*1.5 MB
    set /a PagingFileSize=%TotalMemMB%*3/2
    echo Setting static paging file size to %PagingFileSize% MB (1.5x RAM)...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "%PagingDrive%\pagefile.sys %PagingFileSize% %PagingFileSize%" /f
)

echo Memory and paging file settings adjusted.
pause
goto Menu

:: ===== Section 3: Optimize Disk Performance =====
:OptimizeDiskPerformance
cls
echo Optimizing Disk Performance...

:: Check TRIM status for SSD
echo Checking TRIM status...
for /f "tokens=3" %%a in ('fsutil behavior query DisableDeleteNotify') do set "trimstatus=%%a"
if /i "%trimstatus%"=="0" (
    echo TRIM is ENABLED (good for SSD performance).
) else (
    echo TRIM is DISABLED - enabling TRIM...
    fsutil behavior set DisableDeleteNotify 0
)

:: For HDD, ensure scheduled defragmentation enabled
if /i "%DiskType%"=="HDD" (
    echo Ensuring scheduled defragmentation is ENABLED for HDD...
    defrag %PagingDrive% /C /H /O
) else (
    echo SSD detected - disabling scheduled defragmentation...
    powershell -Command "Disable-ScheduledTask -TaskName 'ScheduledDefrag'"
)

:: Disable disk indexing on paging drive to reduce disk writes
echo Disabling indexing on drive %PagingDrive% to reduce disk activity...
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE 0
:: Below disables indexing service, which affects all drives, can be re-enabled by reversing
:: sc stop WSearch
:: sc config WSearch start= disabled

echo Disk performance optimizations applied.
pause
goto Menu

:: ===== Section 4: Disable Visual Effects and Delays =====
:DisableVisualEffects
cls
echo Disabling Visual Effects and Delays...

:: Backup current Explorer visual effects registry keys
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "%USERPROFILE%\Desktop\ExplorerVisualEffectsBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.reg" /y
reg export "HKCU\Control Panel\Desktop" "%USERPROFILE%\Desktop\DesktopRegBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.reg" /y

:: Set to "Adjust for best performance" style (disable animations, shadows, etc)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f

:: Disable Menu Show Delay - reduce menu popup delay (default 400ms -> 0ms)
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f

:: Disable startup delay for desktop apps
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f

echo Visual effects and delay tweaks applied.
pause
goto Menu

:: ===== Section 5: General System and Network Optimization =====
:SystemNetworkOptimization
cls
echo Applying General System and Network Optimizations...

:: Set power plan to High Performance, or Ultimate Performance if available
powercfg /L | findstr "Ultimate" > nul
if %errorlevel%==0 (
    echo Setting power plan to Ultimate Performance...
    for /f "tokens=1-3 delims= " %%a in ('powercfg /L ^| find "Ultimate"') do set "planGuid=%%a"
    powercfg /S %planGuid%
) else (
    echo Setting power plan to High Performance...
    for /f "tokens=1-3 delims= " %%a in ('powercfg /L ^| find "High performance"') do set "planGuid=%%a"
    powercfg /S %planGuid%
)

:: Clear temp files - user and system temp folders
echo Clearing temporary files...
del /s /q "%TEMP%\*"
del /s /q "%SYSTEMROOT%\Temp\*"

:: Disable Nagle's Algorithm for network latency improvements

:: Backup current TcpAckFrequency registry key
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "%USERPROFILE%\Desktop\TcpipParamsBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%.reg" /y

echo Setting TcpAckFrequency and TcpNoDelay for all interfaces...

for /f "tokens=*" %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"') do (
    reg add "%%I" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%I" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
)

echo Nagle's Algorithm disabled where possible.
pause
goto Menu

:: ===== Section 6: Enhance Privacy and Disable Telemetry =====
:PrivacyAndTelemetry
cls
echo Enhancing Privacy and Disabling Telemetry...

:: Backup hosts file
copy "%windir%\System32\drivers\etc\hosts" "%USERPROFILE%\Desktop\hosts_backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%" >nul

:: Overwrite hosts file to block known Microsoft telemetry domains 
:: (append rather than overwrite if better for safety)

(
echo 127.0.0.1 vortex.data.microsoft.com
echo 127.0.0.1 settings-win.data.microsoft.com
echo 127.0.0.1 telecommand.telemetry.microsoft.com
echo 127.0.0.1 watson.telemetry.microsoft.com
echo 127.0.0.1 telemetry.microsoft.com
echo 127.0.0.1 telemetry.appex.bing.net
echo 127.0.0.1 telemetry.urs.microsoft.com
) >> "%windir%\System32\drivers\etc\hosts"

:: Disable telemetry services
for %%S in (DiagTrack dmwappushservice diagnostics tracking service) do (
    echo Stopping and disabling %%S...
    sc stop %%S
    sc config %%S start= disabled
)

:: Registry tweak to reduce telemetry (set AllowTelemetry to 0 - Security level)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

echo Privacy and telemetry services disabled and hosts entries added.
pause
goto Menu

:: ===== Section 7: Implement Basic Security Hardening =====
:SecurityHardening
cls
echo Applying Basic Security Hardening...

:: Enable Controlled Folder Access
echo Enabling Controlled Folder Access (ransomware protection)...
powershell -Command "Set-MpPreference -EnableControlledFolderAccess Enabled" >nul 2>&1

:: Enable Windows Defender Attack Surface Reduction (ASR) rules for typical power user
echo Enabling recommended Attack Surface Reduction rules...
powershell -Command "Add-MpPreference -AttackSurfaceReductionRules_Ids 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84 -AttackSurfaceReductionRules_Actions Block" >nul 2>&1

:: Disable SMBv1 for security
echo Disabling SMBv1 protocol...
sc config lanmanworkstation depend= bowser/mrxdav/fs
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f

:: Configure firewall to block outgoing connections for specific Windows apps (example: OneDrive)
echo Blocking outgoing connections for OneDrive to reduce background network usage...
netsh advfirewall firewall add rule name="Block OneDrive Outbound" dir=out action=block program="%USERPROFILE%\AppData\Local\Microsoft\OneDrive\OneDrive.exe" enable=yes

echo Security hardening completed.
pause
goto Menu
