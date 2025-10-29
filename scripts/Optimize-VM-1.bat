@echo off
:: Windows 10 Performance Optimization Script for VirtualBox VM
:: Run as Administrator
echo ================================================
echo Windows 10 VM Performance Optimization Script
echo ================================================
echo.
echo Checking for administrator privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Running as Administrator - proceeding with optimizations...
echo.

:: ================================================
:: DISABLE UNNECESSARY SERVICES
:: ================================================
echo [1/8] Disabling unnecessary services...

sc config "DiagTrack" start= disabled >nul 2>&1
sc config "dmwappushservice" start= disabled >nul 2>&1
sc config "WSearch" start= disabled >nul 2>&1
sc config "Fax" start= disabled >nul 2>&1
sc config "MapsBroker" start= disabled >nul 2>&1
sc config "RetailDemo" start= disabled >nul 2>&1
sc config "RemoteAccess" start= disabled >nul 2>&1
sc config "RemoteRegistry" start= disabled >nul 2>&1
sc config "SharedAccess" start= disabled >nul 2>&1
sc config "TrkWks" start= disabled >nul 2>&1
sc config "WbioSrvc" start= disabled >nul 2>&1
sc config "XblAuthManager" start= disabled >nul 2>&1
sc config "XblGameSave" start= disabled >nul 2>&1
sc config "XboxNetApiSvc" start= disabled >nul 2>&1
sc config "SysMain" start= disabled >nul 2>&1
sc config "Themes" start= disabled >nul 2>&1
sc config "TabletInputService" start= disabled >nul 2>&1
sc config "FontCache" start= disabled >nul 2>&1

:: Stop services
sc stop "DiagTrack" >nul 2>&1
sc stop "dmwappushservice" >nul 2>&1
sc stop "WSearch" >nul 2>&1
sc stop "SysMain" >nul 2>&1

echo Services disabled successfully.

:: ================================================
:: DISABLE VISUAL EFFECTS
:: ================================================
echo [2/8] Optimizing visual effects...

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012078010000000 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1

echo Visual effects optimized.

:: ================================================
:: DISABLE STARTUP PROGRAMS
:: ================================================
echo [3/8] Disabling startup programs...

reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "SecurityHealth" /t REG_BINARY /d 030000000000000000000000 /f >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f >nul 2>&1

echo Startup programs disabled.

:: ================================================
:: DISABLE WINDOWS TELEMETRY & PRIVACY
:: ================================================
echo [4/8] Disabling telemetry and privacy settings...

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338393Enabled /t REG_DWORD /d 0 /f >nul 2>&1

echo Telemetry and privacy settings configured.

:: ================================================
:: OPTIMIZE POWER SETTINGS
:: ================================================
echo [5/8] Optimizing power settings for performance...

powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
powercfg -change -monitor-timeout-ac 0 >nul 2>&1
powercfg -change -disk-timeout-ac 0 >nul 2>&1
powercfg -change -standby-timeout-ac 0 >nul 2>&1
powercfg -change -hibernate-timeout-ac 0 >nul 2>&1

echo Power settings optimized.

:: ================================================
:: CLEAN TEMPORARY FILES
:: ================================================
echo [6/8] Cleaning temporary files...

del /q /f /s %TEMP%\*.* >nul 2>&1
del /q /f /s C:\Windows\Temp\*.* >nul 2>&1
del /q /f /s C:\Windows\Prefetch\*.* >nul 2>&1
cleanmgr /sagerun:1 >nul 2>&1

echo Temporary files cleaned.

:: ================================================
:: POWERSHELL OPTIMIZATIONS
:: ================================================
echo [7/8] Running PowerShell optimizations...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    # Remove Windows Store Apps (Bloatware)
    Write-Host 'Removing bloatware apps...'
    $apps = @(
        'Microsoft.3DBuilder',
        'Microsoft.BingFinance',
        'Microsoft.BingNews',
        'Microsoft.BingSports',
        'Microsoft.BingWeather',
        'Microsoft.Getstarted',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.People',
        'Microsoft.SkypeApp',
        'Microsoft.WindowsAlarms',
        'microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo'
    )
    
    foreach ($app in $apps) {
        try {
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        } catch { }
    }
    
    # Disable Windows Defender (for VM performance)
    Write-Host 'Configuring Windows Defender...'
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableOnAccessProtection $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScanOnRealtimeEnable $true -ErrorAction SilentlyContinue
    } catch { }
    
    # Disable Windows Update (manual control)
    Write-Host 'Configuring Windows Update...'
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    
    # Enable high performance mode
    Write-Host 'Setting high performance power plan...'
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    
    # Disable hibernate and page file for VM
    Write-Host 'Disabling hibernate...'
    powercfg -h off
    
    Write-Host 'PowerShell optimizations completed.'
}"

:: ================================================
:: FINAL REGISTRY TWEAKS
:: ================================================
echo [8/8] Applying final registry tweaks...

:: Disable Windows Defender
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable automatic updates
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1

:: Optimize for programs instead of background services
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f >nul 2>&1

:: Disable Error Reporting
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1

echo Registry tweaks applied.

:: ================================================
:: COMPLETION
:: ================================================
echo.
echo ================================================
echo OPTIMIZATION COMPLETE!
echo ================================================
echo.
echo The following optimizations have been applied:
echo - Unnecessary services disabled
echo - Visual effects optimized for performance
echo - Startup programs reduced
echo - Telemetry and privacy settings configured
echo - Power settings optimized
echo - Temporary files cleaned
echo - Bloatware removed
echo - Windows Defender configured for VM use
echo - Registry tweaks applied
echo.
echo IMPORTANT NOTES:
echo - Windows Defender real-time protection has been disabled
echo - Windows Update has been set to manual
echo - Some features may be limited after these changes
echo - A system restart is recommended
echo.
echo Would you like to restart now? (Y/N)
set /p restart="Enter your choice: "
if /i "%restart%"=="Y" (
    echo Restarting in 10 seconds...
    timeout /t 10
    shutdown /r /t 0
) else (
    echo Please restart manually when convenient.
)

echo.
pause