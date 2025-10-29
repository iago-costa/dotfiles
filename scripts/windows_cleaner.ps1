<#
===================================================================
 Windows Cleaner Script
 Cleans temporary files, cache, log files, recycle bin, and runs
 optional SSD trim.
 Compatible with Windows 10 / 11 (PowerShell 5.1+)
===================================================================
#>

Write-Host "=== Windows System Cleaner ===`n"

# 1. Clean user temp files
Write-Host "[*] Cleaning user temp files..."
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# 2. Clean Windows temp directory
Write-Host "[*] Cleaning system temp files..."
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Clean Prefetch (optional)
Write-Host "[*] Cleaning Prefetch files..."
Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Clean Windows Update cache (SoftwareDistribution\Download)
Write-Host "[*] Cleaning Windows Update cache..."
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue

# 5. Clean Delivery Optimization cache
Write-Host "[*] Cleaning Delivery Optimization cache..."
Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

# 6. Clean Recycle Bin
Write-Host "[*] Emptying Recycle Bin..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# 7. Optional: SSD TRIM (only runs if supported)
Write-Host "[*] Running SSD TRIM..."
Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue

Write-Host "`n=== Cleanup Complete ==="
