# PowerShell Commands (Run as Admin)
Write-Host "Optimizing Windows 10 for VirtualBox..." -ForegroundColor Green

# 1. Disable unnecessary services
$services = @(
    "SysMain",           # SuperFetch
    "PrintNotify",       # Printer Extensions
    "Fax",               # Fax Service
    "XblAuthManager",    # Xbox Live Auth
    "XblGameSave",       # Xbox Live Game Save
    "XboxNetApiSvc",     # Xbox Live Networking
    "MapsBroker",        # Downloaded Maps Manager
    "lfsvc",             # Geolocation
    "SharedAccess",      # Internet Connection Sharing
    "PhoneSvc",          # Phone Service
    "WMPNetworkSvc",     # Windows Media Player Network Sharing
    "WSearch",           # Windows Search
    "PushToInstall"      # Windows PushToInstall Service
)

foreach ($service in $services) {
    Stop-Service $service -Force -ErrorAction SilentlyContinue
    Set-Service $service -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "Disabled $service" -ForegroundColor Yellow
}

# 2. Disable background apps
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Value 2 -PropertyType DWord -Force
Write-Host "Background apps disabled" -ForegroundColor Yellow

# 3. Adjust performance options
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance power plan
powercfg -h off  # Disable hibernation
Write-Host "Power settings optimized" -ForegroundColor Yellow

# 4. Disable visual effects
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord
Write-Host "Visual effects reduced" -ForegroundColor Yellow

# 5. Disable notifications
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -PropertyType DWord -Force
Write-Host "Notifications disabled" -ForegroundColor Yellow

# 6. Clear temporary files
Cleanmgr /sagerun:1 | Out-Null
Write-Host "Temporary files cleaned" -ForegroundColor Yellow

# 7. Network optimization
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295 -Type DWord
Write-Host "Network throttling disabled" -ForegroundColor Yellow

# 8. Disable tips and suggestions
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0 -PropertyType DWord -Force
Write-Host "Windows tips disabled" -ForegroundColor Yellow

# 9. VirtualBox-specific optimizations
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\VBoxSF" -Name "DisplayName" -Value "VirtualBox Shared Folders" -Type String
Write-Host "VirtualBox services optimized" -ForegroundColor Yellow

# 10. Apply all changes
Write-Host "Optimization complete! Some changes require a reboot to take effect." -ForegroundColor Green
Read-Host "Press Enter to reboot now, or Ctrl+C to cancel"
Restart-Computer -Force