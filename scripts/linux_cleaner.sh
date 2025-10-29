#!/bin/bash
# ===================================================================
# Universal Linux Deep Cleaner
# Cleans system + user caches, dev tools caches, Flatpak, Snap, Conda,
# VSCode-server, Codeium, pyenv, nvm, etc.
# ===================================================================

set -e
echo "=== Linux Deep Cleaner ==="

# Determine root user ID safely
ROOT_UID="${EUID:-$(id -u)}"

# -------------------------------
# Detect package manager and clean
# -------------------------------
echo "[*] Cleaning package manager cache..."
if command -v apt-get &>/dev/null; then
    sudo apt-get clean
    sudo apt-get autoclean
    sudo apt-get autoremove -y
elif command -v dnf &>/dev/null; then
    sudo dnf clean all -y
    sudo dnf autoremove -y
elif command -v yum &>/dev/null; then
    sudo yum clean all -y
    sudo yum autoremove -y
elif command -v pacman &>/dev/null; then
    sudo pacman -Scc --noconfirm
elif command -v zypper &>/dev/null; then
    sudo zypper clean --all
elif command -v slackpkg &>/dev/null; then
    sudo slackpkg clean-system
elif command -v nix-collect-garbage &>/dev/null; then
    nix-collect-garbage -d
fi

# -------------------------------
# 2. Clean system logs
# -------------------------------
if command -v journalctl &>/dev/null; then
    echo "[*] Cleaning systemd journal logs (keeping 7 days)..."
    sudo journalctl --vacuum-time=7d
fi
sudo rm -rf /tmp/* /var/tmp/*

# -------------------------------
# 4. Flatpak cleanup
# -------------------------------
if command -v flatpak &>/dev/null; then
    echo "[*] Cleaning Flatpak unused runtimes..."
    flatpak uninstall --unused -y
    rm -rf ~/.var/app/*/cache/*
    if [ "$ROOT_UID" -eq 0 ] && [ -d /root/.var/app ]; then
        rm -rf /root/.var/app/*/cache/*
    fi
fi

# -------------------------------
# 5. Clean user cache & temp dirs
# -------------------------------
echo "[*] Cleaning user cache..."
rm -rf ~/.cache/*

echo "[*] Cleaning system temporary directories..."
sudo rm -rf /tmp/* /var/tmp/*

# -------------------------------
# 6. Clean thumbnails
# -------------------------------
echo "[*] Cleaning thumbnails..."
rm -rf ~/.cache/thumbnails/*

# -------------------------------
# 7. Clean Flatpak (if installed)
# -------------------------------
if command -v flatpak &>/dev/null; then
    echo "[*] Cleaning Flatpak unused runtimes..."
    flatpak uninstall --unused -y

    echo "[*] Cleaning Flatpak cache..."
    rm -rf ~/.var/app/*/cache/*
fi

# -------------------------------
# 8. SSD trim (if available)
# -------------------------------
if command -v fstrim &>/dev/null; then
    echo "[*] Running SSD TRIM..."
    sudo fstrim -av
fi

# ---------------------------------------------------
# 9. Safely truncate all files in /var/log without deleting directories
# Continues on permission errors
# ---------------------------------------------------
set +e  # disable exit-on-error
LOG_DIR="/var/log"

echo "[*] Cleaning log files in $LOG_DIR..."
# Find all regular files
find "$LOG_DIR" -type f | while IFS= read -r logfile; do
    # Try truncating directly
    if : > "$logfile" 2>/dev/null; then
        echo "Cleaned $logfile"
    else
        # Fallback: try with sudo if available
        if command -v sudo &>/dev/null; then
            if sudo bash -c ": > \"$logfile\"" 2>/dev/null; then
                echo "Cleaned $logfile (with sudo)"
            else
                echo "Skipped (cannot write): $logfile"
            fi
        else
            echo "Skipped (cannot write, no sudo): $logfile"
        fi
    fi
done
echo "[*] Log file cleanup complete."
set -e  # restore exit-on-error
# ===================================================================
# 10. Remove old disabled Snap revisions
# WARNING: Close all running snaps before running
# ===================================================================
set +e
# Check if snap command exists
if ! command -v snap &>/dev/null; then
	echo "Snap not found."
fi

if command -v snap &>/dev/null; then
    echo "Snap not found."
		echo "[*] Listing disabled snap revisions..."

		# Loop through disabled revisions
		snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
				if [ -n "$snapname" ] && [ -n "$revision" ]; then
				    echo "[*] Removing $snapname revision $revision..."
				    # Use --purge to remove data associated with the revision
				    snap remove "$snapname" --revision="$revision" --purge || {
				        echo "[!] Failed to remove $snapname revision $revision"
				    }
				fi
		done
		echo "[*] Snap cleanup complete."
fi
set -e
# -------------------------------
# 11. Clean user dirs
# -------------------------------
clean_home_dir() {
    USER_HOME=$1
    echo "    - Cleaning caches in $USER_HOME"

    # Browsers
    rm -rf "$USER_HOME/.mozilla/firefox/"*.default*/cache2/* 2>/dev/null || true
    rm -rf "$USER_HOME/.config/chromium/Default/Cache/"* 2>/dev/null || true
    rm -rf "$USER_HOME/.config/google-chrome/Default/Cache/"* 2>/dev/null || true

    # Codeium
    rm -rf "$USER_HOME/.codeium/"*

    # VSCode server
    rm -rf "$USER_HOME/.vscode-server/data" \
           "$USER_HOME/.vscode-server/extensions" \
           "$USER_HOME/.vscode-server/cli"

    # Dotnet
    rm -rf "$USER_HOME/.dotnet/corefx"

    # Pyenv
    rm -rf "$USER_HOME/.pyenv/cache" \
           "$USER_HOME/.pyenv/.git" \
           "$USER_HOME/.pyenv/test"

    # NVM
    rm -rf "$USER_HOME/.nvm/.cache" \
           "$USER_HOME/.nvm/test" \
           "$USER_HOME/.nvm/.git"

    # Oh My Zsh
    rm -rf "$USER_HOME/.oh-my-zsh/cache" \
           "$USER_HOME/.oh-my-zsh/log" \
           "$USER_HOME/.oh-my-zsh/.git"

    # Conda / Miniconda
    rm -rf "$USER_HOME/.conda" \
           "$USER_HOME/miniconda3/pkgs" \
           "$USER_HOME/miniconda3/conda-meta" \
           "$USER_HOME/miniconda3/compiler_compat"

    # Snap apps
    rm -rf "$USER_HOME/snap/"*

    # NPM
    rm -rf "$USER_HOME/.npm/_cacache" \
           "$USER_HOME/.npm/_logs" \
           "$USER_HOME/.npm/_npx"

    # Core caches
    rm -rf "$USER_HOME/.cache/"*
    rm -rf "$USER_HOME/.thumbnails/"* 2>/dev/null || true
    rm -rf "$USER_HOME/.local/share/Trash/"* 2>/dev/null || true
    rm -rf "$USER_HOME/.nv/GLCache/"* 2>/dev/null || true
    rm -rf "$USER_HOME/.local/state/"* 2>/dev/null || true
}

echo "[*] Cleaning home directories..."
clean_home_dir "$HOME"

if [ "$ROOT_UID" -eq 0 ] && [ -d /root ]; then
    clean_home_dir "/root"
fi

echo "[*] Get disk usage resume"
df -h

du -h --max-depth=1 / | sort -hr

echo "=== Deep Cleanup Complete ==="