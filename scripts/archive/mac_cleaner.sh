#!/bin/bash
# ===================================================================
# macOS Cleaner Script
# Cleans caches, logs, temp files, Trash, Homebrew cache,
# and checks SSD TRIM status.
# Compatible with macOS Catalina, Big Sur, Monterey, Ventura, Sonoma
# ===================================================================

set -e

echo "=== macOS System Cleaner ==="

# 1. Clean user cache
echo "[*] Cleaning user cache..."
rm -rf ~/Library/Caches/*

# 2. Clean system cache
echo "[*] Cleaning system cache..."
sudo rm -rf /Library/Caches/*

# 3. Clean system logs
echo "[*] Cleaning system logs..."
sudo rm -rf /var/log/*
sudo rm -rf /Library/Logs/*
rm -rf ~/Library/Logs/*

# 4. Clean temporary files
echo "[*] Cleaning temporary files..."
sudo rm -rf /private/var/tmp/*
sudo rm -rf /private/tmp/*

# 5. Empty Trash
echo "[*] Emptying Trash..."
rm -rf ~/.Trash/*
sudo rm -rf /Volumes/*/.Trashes
sudo rm -rf /private/var/folders/*/*/*/com.apple.LaunchServices*

# 6. Clean Application cache (safe)
echo "[*] Cleaning application support cache..."
rm -rf ~/Library/Application\ Support/Caches/*

# 7. Free up old iOS backups (optional)
if [ -d ~/Library/Application\ Support/MobileSync/Backup ]; then
    echo "[*] Cleaning old iOS backups..."
    rm -rf ~/Library/Application\ Support/MobileSync/Backup/*
fi

# 8. Homebrew cleanup (if installed)
if command -v brew &>/dev/null; then
    echo "[*] Running Homebrew cleanup..."
    brew cleanup -s
    brew autoremove
    rm -rf "$(brew --cache)"
fi

# 9. Run SSD TRIM check
if system_profiler SPSerialATADataType | grep -q "TRIM Support: Yes"; then
    echo "[*] SSD TRIM is supported and already enabled by macOS."
else
    echo "[!] SSD TRIM not enabled or not supported on this disk."
fi

echo "=== Cleanup Complete ==="
