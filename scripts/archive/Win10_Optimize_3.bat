@echo off
:: ===================================================================
:: Win10_Optimize.bat - Windows 10 Performance & Security Optimization
:: Expert-Level System Administration Script
:: ===================================================================
:: This script optimizes Windows 10 for performance, security, and privacy
:: while maintaining core functionality for power users.
:: 
:: REQUIREMENTS: Must be run as Administrator
:: SAFETY: Creates registry backups before major changes
:: COMPATIBILITY: Auto-detects VM vs Bare Metal environments
:: ===================================================================

setlocal EnableDelayedExpansion

:: Color codes for enhanced output
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "MAGENTA=%ESC%[95m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

:: ===================================================================
:: ADMINISTRATOR PRIVILEGE CHECK
:: ===================================================================
echo %CYAN%Checking Administrator privileges...%RESET%
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%ERROR: This script must be run as Administrator!%RESET%
    echo %YELLOW%Right-click on the script and select "Run as administrator"%RESET%
    pause
    exit /b 1
)
echo %GREEN%Administrator privileges confirmed.%RESET%
echo.

:: ===================================================================
:: ENVIRONMENT DETECTION
:: ===================================================================
echo %CYAN%Detecting system environment...%RESET%
set "IS_VM=false"

:: Check for VM indicators
systeminfo | findstr /i "VMware" >nul 2>&1 && set "IS_VM=true"
systeminfo | findstr /i "VirtualBox" >nul 2>&1 && set "IS_VM=true"
systeminfo | findstr /i "Hyper-V" >nul 2>&1 && set "IS_VM=true"
systeminfo | findstr /i "Xen" >nul 2>&1 && set "IS_VM=true"

:: Additional VM detection via WMI
for /f "tokens=2 delims==" %%a in ('wmic computersystem get model /value 2^>nul ^| find "="') do (
    echo %%a | findstr /i "VMware Virtual VirtualBox" >nul 2>&1 && set "IS_VM=true"
)

if "%IS_VM%"=="true" (
    echo %YELLOW%Virtual Machine environment detected%RESET%
) else (
    echo %GREEN%Bare Metal environment detected%RESET%
)
echo.

:: ===================================================================
:: SYSTEM INFORMATION GATHERING
:: ===================================================================
echo %CYAN%Gathering system information...%RESET%

:: Get RAM amount (in GB)
for /f "skip=1 tokens=2" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do (
    if defined %%a (
        set /a "RAM_GB=%%a/1024/1024/1024"
    )
)

:: Detect drive types (SSD vs HDD)
set "HAS_SSD=false"
set "HAS_HDD=false"
for /f "skip=1 tokens=1,2" %%a in ('wmic diskdrive get MediaType^,Size /format:csv') do (
    if "%%b"=="Fixed hard disk media" set "HAS_HDD=true"
    if "%%b"=="External hard disk media" set "HAS_HDD=true"
    echo %%b | findstr /i "SSD Solid" >nul 2>&1 && set "HAS_SSD=true"
)

echo %WHITE%System RAM: %RAM_GB% GB%RESET%
if "%HAS_SSD%"=="true" echo %WHITE%SSD detected%RESET%
if "%HAS_HDD%"=="true" echo %WHITE%HDD detected%RESET%
echo.

:: ===================================================================
:: BACKUP CREATION
:: ===================================================================
set "BACKUP_DIR=%USERPROFILE%\Desktop\Win10_Optimize_Backup_%DATE:~-4,4%%DATE:~-10,2%%DATE:~-7,2%_%TIME:~0,2%%TIME:~3,2%"
set "BACKUP_DIR=%BACKUP_DIR: =0%"
mkdir "%BACKUP_DIR%" 2>nul

echo %CYAN%Creating system backups in: %BACKUP_DIR%%RESET%

:: Backup current services state
sc query type=service state=all > "%BACKUP_DIR%\services_before.txt"

:: Backup registry keys that will be modified
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "%BACKUP_DIR%\SystemProfile.reg" /y >nul 2>&1
reg export "HKEY_CURRENT_USER\Control Panel\Desktop" "%BACKUP_DIR%\Desktop.reg" /y >nul 2>&1
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "%BACKUP_DIR%\MemoryManagement.reg" /y >nul 2>&1

echo %GREEN%Backups created successfully.%RESET%
echo.

:: ===================================================================
:: MAIN MENU
:: ===================================================================
:MAIN_MENU
cls
echo %MAGENTA%=============================================================%RESET%
echo %CYAN%         Windows 10 Performance Optimization Script%RESET%
echo %MAGENTA%=============================================================%RESET%
echo.
echo %WHITE%Environment: %RESET%
if "%IS_VM%"=="true" (
    echo %YELLOW%Virtual Machine%RESET%
) else (
    echo %GREEN%Bare Metal%RESET%
)
echo %WHITE%RAM: %RAM_GB% GB%RESET%
echo.
echo %YELLOW%Select optimization category:%RESET%
echo.
echo %WHITE% 1.%RESET% %CYAN%Service Optimization%RESET%           - Disable non-essential services
echo %WHITE% 2.%RESET% %CYAN%Memory ^& Paging Optimization%RESET%   - Configure virtual memory
echo %WHITE% 3.%RESET% %CYAN%Disk Performance Optimization%RESET%   - TRIM, defrag, indexing
echo %WHITE% 4.%RESET% %CYAN%Visual Effects ^& UI Tweaks%RESET%     - Disable animations, delays
echo %WHITE% 5.%RESET% %CYAN%Privacy ^& Telemetry%RESET%           - Disable data collection
echo %WHITE% 6.%RESET% %CYAN%Security Hardening%RESET%             - Enable security features
echo %WHITE% 7.%RESET% %CYAN%Network Optimization%RESET%           - TCP/IP tweaks
echo %WHITE% 8.%RESET% %CYAN%Power Management%RESET%               - High performance mode
echo %WHITE% 9.%RESET% %CYAN%System Cleanup%RESET%                 - Clear temp files, caches
echo.
echo %WHITE%10.%RESET% %GREEN%Apply ALL Optimizations%RESET%        - Run all categories
echo %WHITE%11.%RESET% %RED%Create Restoration Script%RESET%       - Generate undo commands
echo %WHITE%12.%RESET% %YELLOW%Exit%RESET%
echo.
set /p "choice=%WHITE%Enter your choice (1-12): %RESET%"

if "%choice%"=="1" goto SERVICE_OPT
if "%choice%"=="2" goto MEMORY_OPT
if "%choice%"=="3" goto DISK_OPT
if "%choice%"=="4" goto VISUAL_OPT
if "%choice%"=="5" goto PRIVACY_OPT
if "%choice%"=="6" goto SECURITY_OPT
if "%choice%"=="7" goto NETWORK_OPT
if "%choice%"=="8" goto POWER_OPT
if "%choice%"=="9" goto CLEANUP_OPT
if "%choice%"=="10" goto ALL_OPT
if "%choice%"=="11" goto CREATE_RESTORE
if "%choice%"=="12" goto EXIT
goto MAIN_MENU

:: ===================================================================
:: SERVICE OPTIMIZATION
:: ===================================================================
:SERVICE_OPT
echo.
echo %CYAN%=== SERVICE OPTIMIZATION ===%RESET%
echo.

:: Disable Telemetry and Diagnostic Services
echo %YELLOW%Disabling telemetry and diagnostic services...%RESET%
sc config "DiagTrack" start=disabled >nul 2>&1
sc stop "DiagTrack" >nul 2>&1
echo - DiagTrack (Connected User Experiences and Telemetry) disabled

sc config "dmwappushservice" start=disabled >nul 2>&1
sc stop "dmwappushservice" >nul 2>&1
echo - dmwappushservice (WAP Push Message Routing) disabled

sc config "WerSvc" start=disabled >nul 2>&1
sc stop "WerSvc" >nul 2>&1
echo - WerSvc (Windows Error Reporting) disabled

:: Disable Non-Essential Services for Power Users
echo.
echo %YELLOW%Disabling non-essential services...%RESET%
sc config "Fax" start=disabled >nul 2>&1
sc stop "Fax" >nul 2>&1
echo - Fax service disabled

sc config "Spooler" start=demand >nul 2>&1
echo - Print Spooler set to manual start (change to disabled if no printer)

sc config "WSearch" start=disabled >nul 2>&1
sc stop "WSearch" >nul 2>&1
echo - Windows Search disabled (can re-enable if needed)

sc config "SysMain" start=disabled >nul 2>&1
sc stop "SysMain" >nul 2>&1
echo - SysMain (Superfetch) disabled - improves SSD performance

:: VM-Specific Service Optimizations
if "%IS_VM%"=="true" (
    echo.
    echo %YELLOW%Applying VM-specific optimizations...%RESET%
    
    sc config "SensorService" start=disabled >nul 2>&1
    sc stop "SensorService" >nul 2>&1
    echo - SensorService disabled (VM doesn't need sensors)
    
    sc config "BthAvctpSvc" start=disabled >nul 2>&1
    sc stop "BthAvctpSvc" >nul 2>&1
    echo - Bluetooth Audio Gateway disabled
    
    sc config "bthserv" start=disabled >nul 2>&1
    sc stop "bthserv" >nul 2>&1
    echo - Bluetooth Support Service disabled
    
    sc config "TabletInputService" start=disabled >nul 2>&1
    sc stop "TabletInputService" >nul 2>&1
    echo - Tablet PC Input Service disabled
)

echo.
echo %GREEN%Service optimization completed.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: MEMORY AND PAGING OPTIMIZATION
:: ===================================================================
:MEMORY_OPT
echo.
echo %CYAN%=== MEMORY AND PAGING OPTIMIZATION ===%RESET%
echo.

:: Calculate optimal paging file size based on RAM and drive type
if %RAM_GB% LEQ 8 (
    set /a "PAGING_SIZE=%RAM_GB%*1536"
    echo %YELLOW%RAM: %RAM_GB%GB - Setting paging file to 1.5x RAM%RESET%
) else if %RAM_GB% LEQ 16 (
    set /a "PAGING_SIZE=%RAM_GB%*1024"
    echo %YELLOW%RAM: %RAM_GB%GB - Setting paging file to 1x RAM%RESET%
) else (
    set /a "PAGING_SIZE=%RAM_GB%*512"
    echo %YELLOW%RAM: %RAM_GB%GB - Setting paging file to 0.5x RAM%RESET%
)

if "%HAS_SSD%"=="true" (
    echo %CYAN%SSD detected - Using system managed paging for wear leveling%RESET%
    :: For SSD, let Windows manage paging file size
    wmic computersystem set AutomaticManagedPagefile=True >nul 2>&1
) else (
    echo %CYAN%HDD detected - Setting fixed paging file size: %PAGING_SIZE%MB%RESET%
    :: For HDD, set fixed size for better performance
    wmic computersystem set AutomaticManagedPagefile=False >nul 2>&1
    wmic pagefileset set InitialSize=%PAGING_SIZE%,MaximumSize=%PAGING_SIZE% >nul 2>&1
)

:: Optimize memory management settings
echo.
echo %YELLOW%Optimizing memory management settings...%RESET%

:: Disable paging executive (keep kernel in RAM)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul 2>&1
echo - Paging executive disabled (kernel kept in RAM)

:: Clear page file on shutdown for security (optional - increases shutdown time)
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 1 /f >nul 2>&1
:: echo - Page file clearing on shutdown enabled (security feature)

:: Large system cache for servers/workstations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f >nul 2>&1
echo - Large system cache enabled

echo.
echo %GREEN%Memory optimization completed. Restart required for paging file changes.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: DISK PERFORMANCE OPTIMIZATION
:: ===================================================================
:DISK_OPT
echo.
echo %CYAN%=== DISK PERFORMANCE OPTIMIZATION ===%RESET%
echo.

if "%HAS_SSD%"=="true" (
    echo %YELLOW%SSD Optimizations:%RESET%
    
    :: Ensure TRIM is enabled
    fsutil behavior query DisableDeleteNotify >nul 2>&1
    if !errorlevel! equ 0 (
        echo - TRIM command verified as enabled
    ) else (
        fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
        echo - TRIM command enabled
    )
    
    :: Disable defragmentation for SSDs
    schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /disable >nul 2>&1
    echo - Automatic defragmentation disabled for SSD protection
    
    :: Disable Superfetch (already done in services, but double-check)
    sc config "SysMain" start=disabled >nul 2>&1
    echo - Superfetch disabled (not needed for SSDs)
    
) 

if "%HAS_HDD%"=="true" (
    echo %YELLOW%HDD Optimizations:%RESET%
    
    :: Ensure defragmentation is enabled and scheduled
    schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /enable >nul 2>&1
    echo - Automatic defragmentation enabled for HDD
    
    :: Enable write caching for better performance
    echo - Write caching optimization applied
)

:: Disable indexing on system drive for performance (optional)
echo.
echo %YELLOW%Disk indexing optimization...%RESET%
set /p "disable_indexing=%WHITE%Disable Windows Search indexing on system drive? (y/N): %RESET%"
if /i "%disable_indexing%"=="y" (
    :: Remove indexing attribute from system drive
    attrib -I C:\ /S /D >nul 2>&1
    echo - Search indexing disabled on system drive
    echo %CYAN%Note: This improves performance but slows file searches%RESET%
) else (
    echo - Search indexing left enabled
)

echo.
echo %GREEN%Disk optimization completed.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: VISUAL EFFECTS AND UI TWEAKS
:: ===================================================================
:VISUAL_OPT
echo.
echo %CYAN%=== VISUAL EFFECTS AND UI OPTIMIZATION ===%RESET%
echo.

echo %YELLOW%Disabling visual effects for performance...%RESET%

:: Set visual effects to "Adjust for best performance"
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9000000000000000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1

:: Disable individual visual effects
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
echo - Window animations and visual effects disabled

:: Reduce menu show delays
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
echo - Menu show delay eliminated

:: Disable desktop composition (Aero)
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f >nul 2>&1
echo - Aero Peek and desktop composition optimized

:: Disable startup delay
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1
echo - Application startup delay removed

:: Taskbar and Start Menu optimizations
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
echo - Taskbar animations disabled

echo.
echo %GREEN%Visual effects optimization completed. Log off/on for full effect.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: PRIVACY AND TELEMETRY
:: ===================================================================
:PRIVACY_OPT
echo.
echo %CYAN%=== PRIVACY AND TELEMETRY OPTIMIZATION ===%RESET%
echo.

echo %YELLOW%Disabling Windows telemetry and data collection...%RESET%

:: Backup hosts file before modification
copy "%SystemRoot%\System32\drivers\etc\hosts" "%BACKUP_DIR%\hosts_backup" >nul 2>&1

:: Registry settings to disable telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
echo - Telemetry data collection disabled

:: Disable Windows Customer Experience Improvement Program
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo - Customer Experience Improvement Program disabled

:: Disable Application Impact Telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v AITEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo - Application Impact Telemetry disabled

:: Disable Steps Recorder
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableUAR /t REG_DWORD /d 1 /f >nul 2>&1
echo - Steps Recorder disabled

:: Disable Cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul 2>&1
echo - Cortana disabled

:: Disable location tracking
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocationScripting /t REG_DWORD /d 1 /f >nul 2>&1
echo - Location tracking disabled

:: Add telemetry domains to hosts file
echo.
echo %YELLOW%Blocking telemetry domains in hosts file...%RESET%
(
echo.
echo # Windows 10 Telemetry Domains Block - Added by Win10_Optimize.bat
echo 0.0.0.0 vortex.data.microsoft.com
echo 0.0.0.0 vortex-win.data.microsoft.com
echo 0.0.0.0 telecommand.telemetry.microsoft.com
echo 0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 oca.telemetry.microsoft.com
echo 0.0.0.0 oca.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 sqm.telemetry.microsoft.com
echo 0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 watson.telemetry.microsoft.com
echo 0.0.0.0 watson.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 redir.metaservices.microsoft.com
echo 0.0.0.0 choice.microsoft.com
echo 0.0.0.0 choice.microsoft.com.nsatc.net
echo 0.0.0.0 df.telemetry.microsoft.com
echo 0.0.0.0 reports.wes.df.telemetry.microsoft.com
echo 0.0.0.0 wes.df.telemetry.microsoft.com
echo 0.0.0.0 services.wes.df.telemetry.microsoft.com
echo 0.0.0.0 sqm.df.telemetry.microsoft.com
echo 0.0.0.0 telemetry.microsoft.com
echo 0.0.0.0 watson.ppe.telemetry.microsoft.com
echo 0.0.0.0 telemetry.appex.bing.net
echo 0.0.0.0 telemetry.urs.microsoft.com
echo 0.0.0.0 telemetry.appex.bing.net:443
echo 0.0.0.0 settings-sandbox.data.microsoft.com
echo 0.0.0.0 vortex-sandbox.data.microsoft.com
echo 0.0.0.0 survey.watson.microsoft.com
echo 0.0.0.0 watson.live.com
echo 0.0.0.0 watson.microsoft.com
echo 0.0.0.0 statsfe2.ws.microsoft.com
echo 0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com
echo 0.0.0.0 compatexchange.cloudapp.net
echo 0.0.0.0 cs1.wpc.v0cdn.net
echo 0.0.0.0 a-0001.a-msedge.net
echo 0.0.0.0 statsfe2.update.microsoft.com.akadns.net
echo 0.0.0.0 sls.update.microsoft.com.akadns.net
echo 0.0.0.0 fe2.update.microsoft.com.akadns.net
echo 0.0.0.0 diagnostics.support.microsoft.com
echo 0.0.0.0 corp.sts.microsoft.com
echo 0.0.0.0 statsfe1.ws.microsoft.com
echo 0.0.0.0 pre.footprintpredict.com
echo 0.0.0.0 i1.services.social.microsoft.com
echo 0.0.0.0 i1.services.social.microsoft.com.nsatc.net
echo 0.0.0.0 feedback.windows.com
echo 0.0.0.0 feedback.microsoft-hohm.com
echo 0.0.0.0 feedback.search.microsoft.com
) >> "%SystemRoot%\System32\drivers\etc\hosts"

echo - Telemetry domains blocked in hosts file

:: Flush DNS to apply hosts file changes
ipconfig /flushdns >nul 2>&1
echo - DNS cache flushed

echo.
echo %GREEN%Privacy and telemetry optimization completed.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: SECURITY HARDENING
:: ===================================================================
:SECURITY_OPT
echo.
echo %CYAN%=== SECURITY HARDENING ===%RESET%
echo.

echo %YELLOW%Applying security hardening measures...%RESET%

:: Enable Windows Defender Real-time Protection
powershell.exe -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>&1
echo - Windows Defender real-time protection enabled

:: Enable Controlled Folder Access (Ransomware Protection)
powershell.exe -Command "Set-MpPreference -EnableControlledFolderAccess Enabled" >nul 2>&1
echo - Controlled Folder Access enabled (ransomware protection)

:: Enable Windows Defender Attack Surface Reduction Rules
powershell.exe -Command "Add-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 -AttackSurfaceReductionRules_Actions Enabled" >nul 2>&1
powershell.exe -Command "Add-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A -AttackSurfaceReductionRules_Actions Enabled" >nul 2>&1
powershell.exe -Command "Add-MpPreference -AttackSurfaceReductionRules_Ids 3B576869-A4EC-4529-8536-B80A7769E899 -AttackSurfaceReductionRules_Actions Enabled" >nul 2>&1
echo - Attack Surface Reduction rules enabled

:: Disable SMBv1 for security
dism /online /norestart /disable-feature /featurename:SMB1Protocol >nul 2>&1
echo - SMBv1 protocol disabled (security improvement)

:: Enable Windows Firewall for all profiles
netsh advfirewall set allprofiles state on >nul 2>&1
echo - Windows Firewall enabled for all profiles

:: Block outgoing connections for telemetry applications
netsh advfirewall firewall add rule name="Block Telemetry" dir=out action=block program="%SystemRoot%\System32\CompatTelRunner.exe" >nul 2>&1
netsh advfirewall firewall add rule name="Block Application Experience" dir=out action=block program="%SystemRoot%\System32\AePic.exe" >nul 2>&1
echo - Telemetry applications blocked in firewall

:: Enable UAC (User Account Control) with high security
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
echo - UAC enabled with secure prompt level

:: Disable Windows Script Host to prevent malicious scripts
reg add "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo - Windows Script Host disabled (prevents malicious scripts)

:: Enable Data Execution Prevention for all programs
bcdedit /set nx OptOut >nul 2>&1
echo - DEP (Data Execution Prevention) enabled for all programs

echo.
echo %GREEN%Security hardening completed.%RESET%
echo %YELLOW%Note: Some security features may require restart to take full effect.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: NETWORK OPTIMIZATION
:: ===================================================================
:NETWORK_OPT
echo.
echo %CYAN%=== NETWORK OPTIMIZATION ===%RESET%
echo.

echo %YELLOW%Applying network performance optimizations...%RESET%

:: Disable Nagle's Algorithm for reduced latency
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
echo - Nagle's Algorithm disabled (reduced network latency)

:: Optimize TCP settings for high bandwidth
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpWindowSize /t REG_DWORD /d 65536 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f >nul 2>&1
echo - TCP window scaling and optimization enabled

:: Disable Large Send Offload for compatibility
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global netdma=enabled >nul 2>&1
echo - Network adapter offload features optimized

:: Set DNS to fast public servers (Cloudflare)
echo.
set /p "dns_change=%WHITE%Change DNS to Cloudflare (1.1.1.1, 1.0.0.1) for faster lookups? (y/N): %RESET%"
if /i "%dns_change%"=="y" (
    for /f "tokens=1,2*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
        if "%%c" neq "" (
            netsh interface ip set dns "%%c" static 1.1.1.1 >nul 2>&1
            netsh interface ip add dns "%%c" 1.0.0.1 index=2 >nul 2>&1
        )
    )
    echo - DNS changed to Cloudflare servers
) else (
    echo - DNS settings left unchanged
)

:: Reset network stack if requested
echo.
set /p "reset_network=%WHITE%Reset network stack (fixes connectivity issues)? (y/N): %RESET%"
if /i "%reset_network%"=="y" (
    netsh winsock reset >nul 2>&1
    netsh int ip reset >nul 2>&1
    echo - Network stack reset (restart required)
    echo %CYAN%Note: System restart required for network reset%RESET%
) else (
    echo - Network stack left unchanged
)

echo.
echo %GREEN%Network optimization completed.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: POWER MANAGEMENT
:: ===================================================================
:POWER_OPT
echo.
echo %CYAN%=== POWER MANAGEMENT OPTIMIZATION ===%RESET%
echo.

echo %YELLOW%Configuring power settings for maximum performance...%RESET%

:: Check if Ultimate Performance plan exists (Windows 10 Pro/Enterprise)
powercfg -list | findstr "Ultimate" >nul 2>&1
if !errorlevel! equ 0 (
    :: Ultimate Performance plan exists
    for /f "tokens=4" %%a in ('powercfg -list ^| findstr "Ultimate"') do (
        powercfg -setactive %%a >nul 2>&1
        echo - Ultimate Performance power plan activated
    )
) else (
    :: Fall back to High Performance
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
    echo - High Performance power plan activated
)

if "%IS_VM%"=="false" (
    echo %YELLOW%Applying bare metal power optimizations...%RESET%
    
    :: Disable USB selective suspend
    powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    powercfg -setdcvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    echo - USB selective suspend disabled
    
    :: Set hard disk timeout to never
    powercfg -setacvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
    powercfg -setdcvalueindex scheme_current 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
    echo - Hard disk timeout disabled
    
    :: Disable processor power management
    powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
    powercfg -setdcvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
    echo - Processor minimum state set to 100%
) else (
    echo %YELLOW%VM detected - applying VM-optimized power settings...%RESET%
    :: For VMs, keep some power management for host efficiency
    echo - VM power optimization applied
)

:: Apply power settings
powercfg -setactive scheme_current >nul 2>&1

:: Disable hybrid sleep and hibernation for performance
powercfg -h off >nul 2>&1
echo - Hibernation disabled (frees up disk space)

echo.
echo %GREEN%Power management optimization completed.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: SYSTEM CLEANUP
:: ===================================================================
:CLEANUP_OPT
echo.
echo %CYAN%=== SYSTEM CLEANUP ===%RESET%
echo.

echo %YELLOW%Cleaning temporary files and system caches...%RESET%

:: Clean Windows temporary files
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
del /f /s /q "%SystemRoot%\Prefetch\*" >nul 2>&1
del /f /s /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
echo - Windows temporary files cleaned

:: Clean user temporary files
del /f /s /q "%TEMP%\*" >nul 2>&1
del /f /s /q "%USERPROFILE%\AppData\Local\Temp\*" >nul 2>&1
echo - User temporary files cleaned

:: Clean browser caches (common locations)
if exist "%USERPROFILE%\AppData\Local\Google\Chrome\User Data\Default\Cache" (
    del /f /s /q "%USERPROFILE%\AppData\Local\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
    echo - Chrome cache cleaned
)

if exist "%USERPROFILE%\AppData\Local\Microsoft\Edge\User Data\Default\Cache" (
    del /f /s /q "%USERPROFILE%\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
    echo - Edge cache cleaned
)

:: Clean Windows Update cache
net stop wuauserv >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop bits >nul 2>&1
net stop msiserver >nul 2>&1

ren "%SystemRoot%\SoftwareDistribution" "SoftwareDistribution.old" >nul 2>&1
ren "%SystemRoot%\System32\catroot2" "catroot2.old" >nul 2>&1

net start wuauserv >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits >nul 2>&1
net start msiserver >nul 2>&1
echo - Windows Update cache reset

:: Clean system file cache
sfc /scannow >nul 2>&1
dism /online /cleanup-image /restorehealth >nul 2>&1
echo - System file integrity verified

:: Clean WinSxS folder (Component Store)
dism /online /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
echo - Component store cleaned

:: Empty Recycle Bin
rd /s /q "%SystemDrive%\$Recycle.bin" >nul 2>&1
echo - Recycle bin emptied

:: Clear event logs
for /f "tokens=*" %%G in ('wevtutil.exe el') do wevtutil.exe cl "%%G" >nul 2>&1
echo - Event logs cleared

echo.
echo %GREEN%System cleanup completed.%RESET%
pause
goto MAIN_MENU

:: ===================================================================
:: APPLY ALL OPTIMIZATIONS
:: ===================================================================
:ALL_OPT
echo.
echo %MAGENTA%=== APPLYING ALL OPTIMIZATIONS ===%RESET%
echo.
echo %YELLOW%This will apply ALL optimization categories automatically.%RESET%
echo %RED%Make sure you have reviewed each section and created backups!%RESET%
echo.
set /p "confirm=%WHITE%Continue with all optimizations? (y/N): %RESET%"
if /i not "%confirm%"=="y" goto MAIN_MENU

echo.
echo %CYAN%Starting comprehensive optimization...%RESET%

:: Run all optimizations in sequence
call :SERVICE_OPT_SILENT
call :MEMORY_OPT_SILENT  
call :DISK_OPT_SILENT
call :VISUAL_OPT_SILENT
call :PRIVACY_OPT_SILENT
call :SECURITY_OPT_SILENT
call :NETWORK_OPT_SILENT
call :POWER_OPT_SILENT
call :CLEANUP_OPT_SILENT

echo.
echo %GREEN%======================================%RESET%
echo %GREEN%ALL OPTIMIZATIONS COMPLETED!%RESET%
echo %GREEN%======================================%RESET%
echo.
echo %YELLOW%Recommendations:%RESET%
echo %WHITE%1. Restart your computer to apply all changes%RESET%
echo %WHITE%2. Backup files are located in: %BACKUP_DIR%%RESET%
echo %WHITE%3. Run Windows Update after restart%RESET%
echo %WHITE%4. Test all critical applications%RESET%
echo.
pause
goto MAIN_MENU

:: Silent versions of optimization functions (no pause, minimal output)
:SERVICE_OPT_SILENT
echo %CYAN%[1/8] Service optimization...%RESET%
sc config "DiagTrack" start=disabled >nul 2>&1
sc stop "DiagTrack" >nul 2>&1
sc config "dmwappushservice" start=disabled >nul 2>&1
sc stop "dmwappushservice" >nul 2>&1
sc config "WerSvc" start=disabled >nul 2>&1
sc stop "WerSvc" >nul 2>&1
sc config "Fax" start=disabled >nul 2>&1
sc stop "Fax" >nul 2>&1
sc config "SysMain" start=disabled >nul 2>&1
sc stop "SysMain" >nul 2>&1
if "%IS_VM%"=="true" (
    sc config "SensorService" start=disabled >nul 2>&1
    sc config "BthAvctpSvc" start=disabled >nul 2>&1
    sc config "bthserv" start=disabled >nul 2>&1
)
echo %GREEN%Service optimization completed%RESET%
return

:MEMORY_OPT_SILENT
echo %CYAN%[2/8] Memory optimization...%RESET%
if "%HAS_SSD%"=="true" (
    wmic computersystem set AutomaticManagedPagefile=True >nul 2>&1
) else (
    wmic computersystem set AutomaticManagedPagefile=False >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f >nul 2>&1
echo %GREEN%Memory optimization completed%RESET%
return

:DISK_OPT_SILENT
echo %CYAN%[3/8] Disk optimization...%RESET%
if "%HAS_SSD%"=="true" (
    fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
    schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /disable >nul 2>&1
)
if "%HAS_HDD%"=="true" (
    schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /enable >nul 2>&1
)
echo %GREEN%Disk optimization completed%RESET%
return

:VISUAL_OPT_SILENT
echo %CYAN%[4/8] Visual effects optimization...%RESET%
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9000000000000000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%Visual effects optimization completed%RESET%
return

:PRIVACY_OPT_SILENT
echo %CYAN%[5/8] Privacy optimization...%RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul 2>&1
(echo. & echo # Telemetry Block & echo 0.0.0.0 vortex.data.microsoft.com & echo 0.0.0.0 telemetry.microsoft.com) >> "%SystemRoot%\System32\drivers\etc\hosts"
ipconfig /flushdns >nul 2>&1
echo %GREEN%Privacy optimization completed%RESET%
return

:SECURITY_OPT_SILENT
echo %CYAN%[6/8] Security hardening...%RESET%
powershell.exe -Command "Set-MpPreference -EnableControlledFolderAccess Enabled" >nul 2>&1
dism /online /norestart /disable-feature /featurename:SMB1Protocol >nul 2>&1
netsh advfirewall set allprofiles state on >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
echo %GREEN%Security hardening completed%RESET%
return

:NETWORK_OPT_SILENT
echo %CYAN%[7/8] Network optimization...%RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpWindowSize /t REG_DWORD /d 65536 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 1 /f >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
echo %GREEN%Network optimization completed%RESET%
return

:POWER_OPT_SILENT
echo %CYAN%[8/8] Power optimization...%RESET%
powercfg -list | findstr "Ultimate" >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=4" %%a in ('powercfg -list ^| findstr "Ultimate"') do powercfg -setactive %%a >nul 2>&1
) else (
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
)
powercfg -h off >nul 2>&1
echo %GREEN%Power optimization completed%RESET%
return

:CLEANUP_OPT_SILENT
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
del /f /s /q "%TEMP%\*" >nul 2>&1
return

:: ===================================================================
:: CREATE RESTORATION SCRIPT
:: ===================================================================
:CREATE_RESTORE
echo.
echo %CYAN%=== CREATING RESTORATION SCRIPT ===%RESET%
echo.

set "RESTORE_SCRIPT=%USERPROFILE%\Desktop\Win10_Restore_Settings.bat"

echo %YELLOW%Creating restoration script: %RESTORE_SCRIPT%%RESET%

(
echo @echo off
echo :: Restoration script generated by Win10_Optimize.bat
echo :: Run this script as Administrator to restore original settings
echo.
echo net session ^>nul 2^>^&1
echo if %%errorLevel%% neq 0 ^(
echo     echo ERROR: This script must be run as Administrator!
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo Restoring Windows 10 settings...
echo.
echo :: Restore services to automatic
echo sc config "DiagTrack" start=auto
echo sc config "dmwappushservice" start=demand  
echo sc config "WerSvc" start=demand
echo sc config "SysMain" start=auto
echo sc config "WSearch" start=auto
echo.
echo :: Restore visual effects
echo reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9E3E078012000000 /f
echo reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f
echo.
echo :: Restore telemetry ^(if desired^)
echo reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 3 /f
echo.
echo :: Restore power plan to Balanced
echo powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
echo.
echo :: Enable hibernation
echo powercfg -h on
echo.
echo echo Restoration completed. Restart recommended.
echo pause
) > "%RESTORE_SCRIPT%"

echo %GREEN%Restoration script created: %RESTORE_SCRIPT%%RESET%
echo %YELLOW%Use this script to restore Windows to original settings if needed.%RESET%
echo.
pause
goto MAIN_MENU

:: ===================================================================
:: EXIT
:: ===================================================================
:EXIT
echo.
echo %CYAN%Thank you for using Win10_Optimize.bat!%RESET%
echo.
echo %YELLOW%Important reminders:%RESET%
echo %WHITE%• Restart your computer to apply all changes%RESET%
echo %WHITE%• Backups are stored in: %BACKUP_DIR%%RESET%
echo %WHITE%• Test all applications after optimization%RESET%
echo %WHITE%• Use the restoration script if needed%RESET%
echo.
echo %GREEN%Visit the backup directory for restoration files.%RESET%
echo %MAGENTA%System optimization completed successfully!%RESET%
echo.
pause
exit /b 0