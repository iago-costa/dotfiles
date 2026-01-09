<#
.SYNOPSIS
    A comprehensive PowerShell script to optimize and harden a Windows 10 installation for power users.
.DESCRIPTION
    This script provides a menu-driven interface to apply various performance, privacy, and security tweaks.
    It automatically detects if it's running on a physical machine or a VM and adjusts optimizations accordingly.
    All major changes include backup procedures.
.AUTHOR
    Expert Windows System Administrator
.VERSION
    1.0
.NOTES
    Run this script with Administrator privileges. Use at your own risk.
#>

#==================================================================================================
# SCRIPT START
#==================================================================================================

#--------------------------------------------------------------------------------------------------
# 1. INITIAL SETUP & CHECKS
#--------------------------------------------------------------------------------------------------

# Administrator Check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as an Administrator. Please right-click and 'Run with PowerShell'."
    Start-Sleep -Seconds 5
    exit
}

# Create a directory for backups
$backupDir = "C:\Windows_Optimize_Backups"
if (-NOT (Test-Path -Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    Write-Host "Created backup directory at $backupDir" -ForegroundColor Green
}

# Environment Detection (VM vs. Bare-Metal)
$isVM = $false
$computerModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
if ($computerModel -match 'Virtual|VMware|Hyper-V|VirtualBox') {
    $isVM = $true
    $envType = "Virtual Machine"
} else {
    $envType = "Bare-Metal"
}

#==================================================================================================
# 2. FUNCTION DEFINITIONS
#==================================================================================================

#--------------------------------------------------------------------------------------------------
# Function: Apply Service Tweaks
#--------------------------------------------------------------------------------------------------
function Apply-ServiceTweaks {
    Write-Host "`n[+] Applying Service Tweaks..." -ForegroundColor Cyan

    # Backup current service configurations
    Get-Service | Select-Object Name, StartType | Export-Csv -Path "$backupDir\Services_Backup.csv" -NoTypeInformation
    Write-Host "  [i] Service configurations backed up to $backupDir\Services_Backup.csv"

    # Services to disable for general performance/privacy
    $servicesToDisable = @{
        "DiagTrack"              = "Connected User Experiences and Telemetry"
        "dmwappushservice"       = "Device Management Wireless Application Protocol"
        "Fax"                    = "Fax Service"
        "RetailDemo"             = "Retail Demo Service"
    }

    # Add VM-specific services if applicable
    if ($isVM) {
        Write-Host "  [i] VM detected. Disabling additional hardware-related services."
        $servicesToDisable.Add("SensorService", "Sensor Service")
        $servicesToDisable.Add("BthAvctpSvc", "AVCTP service for Bluetooth")
        $servicesToDisable.Add("bthserv", "Bluetooth Support Service")
    }

    # Disable Print Spooler only if user confirms
    $printChoice = Read-Host "  [?] Do you use a physical printer? (Y/N)"
    if ($printChoice -ne 'y') {
        $servicesToDisable.Add("Spooler", "Print Spooler")
    }

    foreach ($service in $servicesToDisable.GetEnumerator()) {
        try {
            Write-Host "  [*] Disabling $($service.Value) ($($service.Name))..."
            Get-Service -Name $service.Name | Set-Service -StartupType Disabled -ErrorAction Stop
            # To reverse, run: Set-Service -Name $($service.Name) -StartupType Automatic (or Manual)
        }
        catch {
            Write-Warning "  [!] Could not modify service '$($service.Name)'. It may not exist on your system."
        }
    }
    Write-Host "[+] Service Tweaks Applied." -ForegroundColor Green
    Read-Host "Press Enter to return to the menu."
}

#--------------------------------------------------------------------------------------------------
# Function: Optimize Performance (Visuals, Delays, Power)
#--------------------------------------------------------------------------------------------------
function Optimize-Performance {
    Write-Host "`n[+] Applying Performance Optimizations..." -ForegroundColor Cyan

    # --- Power Plan ---
    Write-Host "  [*] Setting power plan to Ultimate Performance..."
    # First, unhide the Ultimate Performance plan
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    $ultimatePlan = powercfg /LIST | Select-String "Ultimate Performance"
    if ($ultimatePlan) {
        $planGUID = ($ultimatePlan -split " ")[3]
        powercfg /SETACTIVE $planGUID
        Write-Host "  [i] Power Plan set to Ultimate Performance."
    } else {
        # Fallback to High Performance if Ultimate is not available
        powercfg /SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Host "  [i] Ultimate Performance plan not found. Set to High Performance instead."
    }

    # --- Visual Effects (Set for Best Performance) ---
    Write-Host "  [*] Adjusting visual effects for best performance..."
    $vfxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    # Backup current settings
    reg export $vfxPath "$backupDir\VisualEffects_Backup.reg"
    # Set 'VisualFxSetting' to 2 (Custom) and then disable individual effects
    Set-ItemProperty -Path $vfxPath -Name "VisualFxSetting" -Value 2
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force
    # Enable only "Show thumbnails instead of icons" and "Smooth edges of screen fonts"
    # To reverse: Restore the .reg backup or set VisualFxSetting to 0 (Let Windows choose) or 1 (Best appearance).

    # --- Reduce Menu Animation Speed ---
    Write-Host "  [*] Reducing menu show delay..."
    $menuPath = "HKCU:\Control Panel\Desktop"
    # Backup
    $currentDelay = Get-ItemProperty -Path $menuPath -Name "MenuShowDelay"
    Set-ItemProperty -Path $menuPath -Name "MenuShowDelay_Backup" -Value $currentDelay.MenuShowDelay
    # Set new value (200 is a good balance, default is 400)
    Set-ItemProperty -Path $menuPath -Name "MenuShowDelay" -Value "200"
    # To reverse: Set-ItemProperty -Path $menuPath -Name "MenuShowDelay" -Value "400"

    Write-Host "[+] Performance Optimizations Applied." -ForegroundColor Green
    Read-Host "Press Enter to return to the menu."
}

#--------------------------------------------------------------------------------------------------
# Function: Harden Privacy & Disable Telemetry
#--------------------------------------------------------------------------------------------------
function Harden-Privacy {
    Write-Host "`n[+] Applying Privacy & Telemetry Hardening..." -ForegroundColor Cyan

    # --- Registry Tweaks for Telemetry ---
    $telemetryKeys = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    )
    foreach ($key in $telemetryKeys) {
        if (-not(Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        # Setting AllowTelemetry to 0 disables it. (0 = Security, 1 = Basic, 2 = Enhanced, 3 = Full)
        Set-ItemProperty -Path $key -Name "AllowTelemetry" -Value 0 -Type DWord -Force
        # To reverse: Set-ItemProperty -Path $key -Name "AllowTelemetry" -Value 1
    }
    Write-Host "  [*] Registry keys for telemetry configured."

    # --- Block Telemetry Domains via Hosts File ---
    Write-Host "  [*] Blocking known telemetry domains via hosts file..."
    $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
    $hostsBackup = "C:\Windows\System32\drivers\etc\hosts.bak"

    if (-not(Test-Path $hostsBackup)) {
        Copy-Item -Path $hostsFile -Destination $hostsBackup
        Write-Host "  [i] Original hosts file backed up to hosts.bak"
    }

    $telemetryDomains = @(
        "0.0.0.0 vortex.data.microsoft.com",
        "0.0.0.0 settings-win.data.microsoft.com",
        "0.0.0.0 watson.telemetry.microsoft.com"
        # Add more domains here if desired
    )

    foreach ($domain in $telemetryDomains) {
        if (-not(Select-String -Path $hostsFile -Pattern $domain -Quiet)) {
            Add-Content -Path $hostsFile -Value $domain
        }
    }
    Write-Host "  [i] Telemetry domains added to hosts file."
    # To reverse: Delete the added lines from the hosts file or restore hosts.bak

    Write-Host "[+] Privacy & Telemetry Hardening Applied." -ForegroundColor Green
    Read-Host "Press Enter to return to the menu."
}

#--------------------------------------------------------------------------------------------------
# Function: Remove Bloatware
#--------------------------------------------------------------------------------------------------
function Remove-Bloatware {
    Write-Host "`n[+] Removing Windows 10 Bloatware..." -ForegroundColor Cyan

    # --- List of UWP Apps to Remove (Customize this list as needed) ---
    $appsToRemove = @(
        "*3DBuilder*",
        "*3DViewer*",
        "*BingFinance*",
        "*BingNews*",
        "*BingSports*",
        "*BingWeather*",
        "*CandyCrush*",
        "*GetHelp*",
        "*Getstarted*",
        "*Messaging*",
        "*MicrosoftOfficeHub*",
        "*MicrosoftSolitaireCollection*",
        "*MixedReality.Portal*",
        "*Office.OneNote*",
        "*OneConnect*",
        "*People*",
        "*Print3D*",
        "*SkypeApp*",
        "*Wallet*",
        "*XboxApp*",
        "*XboxGameOverlay*",
        "*XboxGamingOverlay*",
        "*XboxSpeechToTextOverlay*",
        "*YourPhone*"
    )

    Write-Host "  [i] The following app patterns will be removed:"
    $appsToRemove | ForEach-Object { Write-Host "    - $_" }
    $confirm = Read-Host "  [?] Do you want to proceed? (Y/N)"
    if ($confirm -ne 'y') {
        Write-Host "[-] Bloatware removal cancelled." -ForegroundColor Yellow
        return
    }

    foreach ($app in $appsToRemove) {
        Write-Host "  [*] Searching for and removing apps matching '$app'..."
        $packages = Get-AppxPackage -AllUsers -Name $app
        if ($packages) {
            foreach ($package in $packages) {
                try {
                    Remove-AppxPackage -AllUsers -Package $package.PackageFullName -ErrorAction Stop
                    Write-Host "    - Removed $($package.Name)" -ForegroundColor Gray
                }
                catch {
                    Write-Warning "    - Failed to remove $($package.Name). It might be a core system component."
                }
            }
        } else {
            Write-Host "    - No packages found matching '$app'." -ForegroundColor Gray
        }
    }

    Write-Host "[+] Bloatware Removal Complete." -ForegroundColor Green
    # Note: Re-installing these apps typically requires using the Microsoft Store.
    Read-Host "Press Enter to return to the menu."
}


#--------------------------------------------------------------------------------------------------
# Function: Harden System Security
#--------------------------------------------------------------------------------------------------
function Harden-Security {
    Write-Host "`n[+] Applying Basic Security Hardening..." -ForegroundColor Cyan

    # --- Disable SMBv1 (Crucial for preventing legacy attacks) ---
    Write-Host "  [*] Disabling SMBv1 protocol..."
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop
        Write-Host "  [i] SMBv1 feature disabled. A restart may be required to finalize."
        # To reverse: Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    }
    catch {
        Write-Warning "  [!] Could not disable SMBv1. It might already be disabled or not present."
    }

    # --- Enable Controlled Folder Access (Ransomware Protection) ---
    Write-Host "  [*] Enabling Controlled Folder Access..."
    Set-MpPreference -EnableControlledFolderAccess Enabled
    Write-Host "  [i] Controlled Folder Access is now enabled. You may need to authorize legitimate applications."
    # To reverse: Set-MpPreference -EnableControlledFolderAccess Disabled

    # --- Enable some key Attack Surface Reduction (ASR) Rules ---
    # These are generally safe for power users and highly effective.
    Write-Host "  [*] Enabling key Attack Surface Reduction (ASR) rules..."
    # Rule: Block executable content from email client and webmail
    Add-MpPreference -AttackSurfaceReductionRules_Ids 'BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550' -AttackSurfaceReductionRules_Actions Enabled
    # Rule: Block credential stealing from the Windows local security authority subsystem (lsass.exe)
    Add-MpPreference -AttackSurfaceReductionRules_Ids '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' -AttackSurfaceReductionRules_Actions Enabled
    Write-Host "  [i] ASR rules for email attachments and LSASS credential stealing enabled."
    # To reverse: Use -AttackSurfaceReductionRules_Actions Disabled

    Write-Host "[+] Security Hardening Applied." -ForegroundColor Green
    Read-Host "Press Enter to return to the menu."
}


#==================================================================================================
# 3. MAIN MENU
#==================================================================================================
while ($true) {
    Clear-Host
    Write-Host "===========================================================" -ForegroundColor Yellow
    Write-Host "    Windows 10 Power User Optimization & Hardening"
    Write-Host "===========================================================" -ForegroundColor Yellow
    Write-Host "Detected Environment: $envType" -ForegroundColor White
    Write-Host ""
    Write-Host "Please choose an option:" -ForegroundColor Green
    Write-Host "  1. Apply Service Tweaks (Performance & Privacy)"
    Write-Host "  2. Apply Performance Tweaks (Visuals, Delays, Power Plan)"
    Write-Host "  3. Apply Privacy & Telemetry Hardening"
    Write-Host "  4. Remove Windows Bloatware (UWP Apps)"
    Write-Host "  5. Apply Basic Security Hardening"
    Write-Host "  -------------------------------------------------"
    Write-Host "  9. ✨ Apply ALL Optimizations"
    Write-Host "  Q. Quit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" { Apply-ServiceTweaks }
        "2" { Optimize-Performance }
        "3" { Harden-Privacy }
        "4" { Remove-Bloatware }
        "5" { Harden-Security }
        "9" {
            Write-Host "`n[+] Applying ALL optimizations..." -ForegroundColor Cyan
            Apply-ServiceTweaks
            Optimize-Performance
            Harden-Privacy
            Remove-Bloatware
            Harden-Security
            Write-Host "`n[+] ALL OPTIMIZATIONS APPLIED! A reboot is recommended." -ForegroundColor Magenta
            Read-Host "Press Enter to return to the menu."
        }
        "q" {
            Write-Host "Exiting script."
            exit
        }
        default {
            Write-Warning "Invalid option. Please try again."
            Start-Sleep -Seconds 2
        }
    }
}