# ===================================================================
# Windows 10 Performance Optimization Script for Virtual Machines
# ===================================================================
# INSTRUCTIONS:
# Run this in powershell: Set-ExecutionPolicy RemoteSigned
# 1. Save this file as "Optimize-VM.ps1".
# 2. Right-click the file and select "Run with PowerShell".
# 3. Accept the User Account Control (UAC) prompt for administrator access.
# ===================================================================

# --- Check for Administrator Privileges ---
Write-Host "Checking for administrator privileges..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as an Administrator. Please right-click and 'Run with PowerShell'."
    Start-Sleep -Seconds 5
    Exit
}

# --- 1. Set Power Plan to High Performance ---
Write-Host "`n[1/5] Setting power plan to 'High Performance'..." -ForegroundColor Green
# This command finds the GUID for the High Performance plan and activates it.
$HighPerf = powercfg -l | ForEach-Object { if ($_ -match "High performance") { $_.Split(' ')[3] } }
powercfg -s $HighPerf
Write-Host "Power plan set to High Performance."

# --- 2. Adjust for Best Performance (Disables Visual Effects) ---
Write-Host "`n[2/5] Disabling visual effects for better performance..." -ForegroundColor Green
# This is the command-line equivalent of 'Adjust for best performance' in System Properties.
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
# Disables animations in the taskbar and start menu
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0
# Disables menu animations
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
Write-Host "Visual effects disabled."

# --- 3. Disable Non-Essential Services ---
Write-Host "`n[3/5] Disabling non-essential services..." -ForegroundColor Green
# Services often not needed in a VM context.
$servicesToDisable = @(
    "DiagTrack",      # Telemetry Service
    "dmwappushservice", # Telemetry Router
    "SysMain",          # Formerly Superfetch; often causes high disk usage
    "WSearch",          # Windows Search Indexer (if you don't use it)
    "Spooler",          # Print Spooler (if you don't print from the VM)
    "Fax",              # Fax Service
    "MapsBroker"        # Downloaded Maps Manager
)

foreach ($service in $servicesToDisable) {
    try {
        Write-Host "  - Disabling $service..."
        Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
    } catch {
        Write-Warning "Could not disable service '$service'. It may not exist or requires different permissions."
    }
}
Write-Host "Services disabled."

# --- 4. Remove Common Bloatware (UWP Apps) ---
Write-Host "`n[4/5] Removing common bloatware apps..." -ForegroundColor Green
# List of common apps that can be safely removed. Add or remove as needed.
$bloatware = @(
    "*3DBuilder*",
    "*GetHelp*",
    "*Getstarted*",
    "*Messaging*",
    "*MicrosoftOfficeHub*",
    "*MicrosoftSolitaireCollection*",
    "*OneNote*",
    "*People*",
    "*SkypeApp*",
    "*Wallet*",
    "*YourPhone*",
    "*ZuneMusic*",
    "*ZuneVideo*",
    "*WindowsFeedbackHub*"
)

foreach ($app in $bloatware) {
    Write-Host "  - Removing package: $app"
    Get-AppxPackage -AllUsers $app | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}
Write-Host "Bloatware removal process completed."

# --- 5. System Maintenance ---
Write-Host "`n[5/5] Performing system maintenance..." -ForegroundColor Green
# Cleans up component store to free up disk space.
DISM.exe /Online /Cleanup-Image /StartComponentCleanup
# Trims the volume, which is beneficial for SSDs and virtual disks.
Optimize-Volume -DriveLetter C -ReTrim -Verbose

# --- Completion Message ---
Write-Host "`nOptimization script finished!" -ForegroundColor Cyan
Write-Host "A system restart is recommended to apply all changes." -ForegroundColor Yellow
Start-Sleep -Seconds 5