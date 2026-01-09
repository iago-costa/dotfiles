#!/usr/bin/env bash
#===============================================================================
#
#   CLEAN-SYSTEM.SH
#   Comprehensive cleanup script for NixOS and Linux systems
#
#   Usage: ./clean-system.sh [options]
#   NOTE:  Run with bash, not sh! (bash clean-system.sh or ./clean-system.sh)
#
#===============================================================================

# Force bash - re-exec if running under sh/dash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail
shopt -s nullglob  # Globs that match nothing expand to nothing

# Detect real user when running with sudo
if [[ -n "${SUDO_USER:-}" ]] && [[ "$SUDO_USER" != "root" ]]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_USER="$SUDO_USER"
else
    REAL_HOME="$HOME"
    REAL_USER="$USER"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Defaults
DRY_RUN=false
CLEAN_ALL=false
CLEAN_NIX=false
CLEAN_USER=false
CLEAN_SYSTEM=false
CLEAN_HOME=false
TOTAL_FREED=0

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
info()  { echo -e "${BLUE}[i]${NC} $1"; }
header() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }

# Get directory size in bytes
get_size() {
    du -sb "$1" 2>/dev/null | cut -f1 || echo 0
}

# Format bytes to human readable
human_size() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        echo "$(( bytes / 1073741824 ))GB"
    elif (( bytes >= 1048576 )); then
        echo "$(( bytes / 1048576 ))MB"
    elif (( bytes >= 1024 )); then
        echo "$(( bytes / 1024 ))KB"
    else
        echo "${bytes}B"
    fi
}

# Safe remove with size tracking
safe_rm() {
    local target="$1"
    local size=0
    
    # Handle glob patterns that didn't match
    [[ ! -e "$target" ]] && return 0
    
    size=$(get_size "$target") || size=0
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would remove: $target ($(human_size $size))"
    else
        rm -rf "${target:?}" 2>/dev/null || true
        TOTAL_FREED=$((TOTAL_FREED + size))
    fi
    return 0
}

# Show disk usage
show_disk_usage() {
    echo -e "\n${YELLOW}${BOLD}Disk Usage:${NC}"
    df -h / /home /nix 2>/dev/null | head -10 || df -h /
}

# Show help
show_help() {
    cat << EOF
${BOLD}CLEAN-SYSTEM.SH${NC} - Comprehensive cleanup for NixOS/Linux

${BOLD}USAGE:${NC}
    ./clean-system.sh [OPTIONS]

${BOLD}OPTIONS:${NC}
    -a, --all        Run all cleanups (interactive prompts for browser/docker)
    -n, --nix        NixOS/Nix cleanup only
    -u, --user       User cache cleanup only
    -s, --system     System cache cleanup only (requires sudo)
    -z, --home       Home-specific cleanup (QEMU, GNS3, dev artifacts, etc.)
    -d, --dry-run    Show what would be deleted without actually deleting
    -h, --help       Show this help message

${BOLD}EXAMPLES:${NC}
    ./clean-system.sh              # Interactive mode (runs all)
    ./clean-system.sh -a           # Full cleanup
    ./clean-system.sh -n -u        # Nix + user caches
    ./clean-system.sh -z           # Home-specific only (QEMU logs, dev temp, etc.)
    ./clean-system.sh -d -a        # Dry run of full cleanup

${BOLD}QUICK COMMANDS:${NC}
    # NixOS garbage collection
    sudo nix-collect-garbage -d && sudo nix-store --optimise

    # Clear user cache
    rm -rf ~/.cache/*

    # Trim journal logs
    sudo journalctl --vacuum-size=100M
EOF
}

#===============================================================================
# CLEANUP FUNCTIONS
#===============================================================================

cleanup_nix() {
    header "NixOS / Nix Cleanup"
    
    if ! command -v nix-collect-garbage &>/dev/null; then
        warn "Nix not installed, skipping..."
        return
    fi
    
    # Show current generations
    info "Current system generations:"
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | tail -5 || true
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would run: nix-collect-garbage -d"
        info "[DRY-RUN] Would run: nix-store --optimise"
        return
    fi
    
    # Garbage collection
    log "Collecting garbage (removing old generations)..."
    if [[ $EUID -eq 0 ]]; then
        nix-collect-garbage -d
    else
        nix-collect-garbage -d 2>/dev/null || sudo nix-collect-garbage -d
    fi
    
    # Delete older than X days (alternative)
    # nix-collect-garbage --delete-older-than 7d
    
    # Optimize store (deduplication via hard links)
    log "Optimizing Nix store (this may take a while)..."
    if [[ $EUID -eq 0 ]]; then
        nix-store --optimise
    else
        nix-store --optimise 2>/dev/null || sudo nix-store --optimise
    fi
    
    # Clean result symlinks in home
    find "$REAL_HOME" -maxdepth 1 -name "result*" -type l -delete 2>/dev/null && \
        log "Cleaned result symlinks in home"
    
    # Rebuild boot menu
    if [[ -d /boot/loader/entries ]] || [[ -d /boot/grub ]]; then
        warn "Tip: Run 'sudo /run/current-system/bin/switch-to-configuration boot' to clean boot entries"
    fi
    
    log "Nix cleanup complete"
}

cleanup_user_cache() {
    header "User Cache Cleanup"
    
    info "Cleaning cache directories for user: $REAL_USER"
    
    # Main cache directories - clean contents, keep directory
    local cache_dirs=(
        "$REAL_HOME/.cache"
        "$REAL_HOME/.local/share/Trash"
        "$REAL_HOME/.thumbnails"
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local size=$(get_size "$dir")
            if [[ "$DRY_RUN" == true ]]; then
                info "[DRY-RUN] Would clean: $dir ($(human_size $size))"
            else
                rm -rf "$dir"/* 2>/dev/null || true
                rm -rf "$dir"/.[!.]* 2>/dev/null || true
                log "Cleaned $dir ($(human_size $size))"
            fi
        fi
    done
    
    # Development caches
    header "Development Caches"
    
    local dev_caches=(
        # Node.js / JavaScript
        "$REAL_HOME/.npm/_cacache"
        "$REAL_HOME/.npm/_logs"
        "$REAL_HOME/.pnpm-store"
        "$REAL_HOME/.yarn/cache"
        "$REAL_HOME/.node-gyp"
        "$REAL_HOME/.v8-compile-cache*"
        
        # Python
        "$REAL_HOME/.cache/pip"
        "$REAL_HOME/.local/share/virtualenvs"
        "$REAL_HOME/.pyenv/cache"
        "$REAL_HOME/__pycache__"
        
        # Rust
        "$REAL_HOME/.cargo/registry/cache"
        "$REAL_HOME/.cargo/git/checkouts"
        
        # Go
        "$REAL_HOME/go/pkg/mod/cache"
        
        # Java / Gradle / Maven
        "$REAL_HOME/.gradle/caches"
        "$REAL_HOME/.gradle/wrapper/dists"
        "$REAL_HOME/.m2/repository"
        
        # .NET
        "$REAL_HOME/.nuget/packages"
        "$REAL_HOME/.local/share/NuGet"
        
        # Misc
        "$REAL_HOME/.composer/cache"
        "$REAL_HOME/.gem/cache"
        "$REAL_HOME/.cpan/build"
    )
    
    for pattern in "${dev_caches[@]}"; do
        for dir in $pattern; do
            if [[ -d "$dir" ]]; then
                local size=$(get_size "$dir")
                if (( size > 1048576 )); then  # Only report if > 1MB
                    safe_rm "$dir"
                    log "Cleaned $dir ($(human_size $size))"
                fi
            fi
        done
    done
    
    # IDE / Editor caches
    header "IDE/Editor Caches"
    
    local ide_caches=(
        "$REAL_HOME/.vscode/extensions/.obsolete"
        "$REAL_HOME/.vscode-server/data/CachedExtensionVSIXs"
        "$REAL_HOME/.config/Code/Cache"
        "$REAL_HOME/.config/Code/CachedData"
        "$REAL_HOME/.config/Code/CachedExtensions"
        "$REAL_HOME/.config/Code/CachedExtensionVSIXs"
        "$REAL_HOME/.config/Code/logs"
        "$REAL_HOME/.config/JetBrains/*/caches"
        "$REAL_HOME/.local/share/JetBrains/*/cache"
        "$REAL_HOME/.android/cache"
    )
    
    for pattern in "${ide_caches[@]}"; do
        for dir in $pattern; do
            if [[ -d "$dir" ]]; then
                local size=$(get_size "$dir")
                if (( size > 1048576 )); then
                    safe_rm "$dir"
                    log "Cleaned $dir ($(human_size $size))"
                fi
            fi
        done
    done
    
    log "User cache cleanup complete"
}

cleanup_home_specific() {
    header "Home-Specific Cleanup (zen)"
    
    info "Cleaning QEMU/VM logs and temp files..."
    
    # QEMU VM logs
    local qemu_dir="$REAL_HOME/QEMU VMs"
    if [[ -d "$qemu_dir" ]]; then
        find "$qemu_dir" -type f -name "*.log" -delete 2>/dev/null || true
        find "$qemu_dir" -type f -name "*.ports" -delete 2>/dev/null || true
        find "$qemu_dir" -type f -name "*-monitor.socket" -delete 2>/dev/null || true
        find "$qemu_dir" -type f -name "*-serial.socket" -delete 2>/dev/null || true
        log "Cleaned QEMU VM logs and sockets"
    fi
    
    # DXVK shader caches
    find "$REAL_HOME" -maxdepth 1 -type f -name "*.dxvk-cache" -delete 2>/dev/null || true
    log "Cleaned DXVK shader caches"
    
    # GNS3 temp/backup files
    local gns3_dir="$REAL_HOME/GNS3"
    if [[ -d "$gns3_dir" ]]; then
        find "$gns3_dir/projects" -type f -name "*.backup" -delete 2>/dev/null || true
        find "$gns3_dir/projects" -type f -name "*.log" -delete 2>/dev/null || true
        find "$gns3_dir" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        log "Cleaned GNS3 temp files"
    fi
    
    # Postman temp files
    local postman_dir="$REAL_HOME/Postman/files"
    if [[ -d "$postman_dir" ]]; then
        rm -rf "$postman_dir"/* 2>/dev/null || true
        log "Cleaned Postman temp files"
    fi
    
    # Kindle .sdr metadata folders (reading progress - optional)
    # Uncomment if you want to clean these:
    # find "$REAL_HOME/GITS/KINDLE_TEMP" -type d -name "*.sdr" -exec rm -rf {} + 2>/dev/null || true
    
    # Zsh/shell logs
    rm -f "$REAL_HOME/zsh_startup_log.txt" 2>/dev/null || true
    rm -f "$REAL_HOME/.zsh_history.bak"* 2>/dev/null || true
    rm -f "$REAL_HOME/.bash_history" 2>/dev/null || true
    log "Cleaned shell logs"
    
    # Logseq .transit and bak files
    local logseq_dir="$REAL_HOME/GITS/Loggy"
    if [[ -d "$logseq_dir" ]]; then
        find "$logseq_dir" -type f -name "*.transit" -delete 2>/dev/null || true
        find "$logseq_dir" -type f -name "*.bak" -delete 2>/dev/null || true
        find "$logseq_dir" -type d -name ".recycle" -exec rm -rf {} + 2>/dev/null || true
        log "Cleaned Logseq temp files"
    fi
    
    # NixOS specific in home
    rm -f "$REAL_HOME/x86_64-linux.magic-install" 2>/dev/null || true
    find "$REAL_HOME" -maxdepth 1 -name "result" -type l -delete 2>/dev/null || true
    find "$REAL_HOME" -maxdepth 1 -name "result-*" -type l -delete 2>/dev/null || true
    log "Cleaned Nix result symlinks"
    
    # Common dev temp files in GITS
    local gits_dir="$REAL_HOME/GITS"
    if [[ -d "$gits_dir" ]]; then
        # Python
        find "$gits_dir" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type f -name "*.pyc" -delete 2>/dev/null || true
        
        # Node.js
        find "$gits_dir" -type d -name ".next" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type d -name ".nuxt" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type f -name "*.log" -name "npm-debug.log*" -delete 2>/dev/null || true
        find "$gits_dir" -type f -name "yarn-error.log" -delete 2>/dev/null || true
        
        # Build artifacts
        find "$gits_dir" -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type d -name ".turbo" -exec rm -rf {} + 2>/dev/null || true
        
        # Coverage
        find "$gits_dir" -type d -name "coverage" -exec rm -rf {} + 2>/dev/null || true
        find "$gits_dir" -type d -name ".coverage" -exec rm -rf {} + 2>/dev/null || true
        
        log "Cleaned dev temp files in GITS"
    fi
    
    # INC_FILES dev projects cleanup
    local inc_dir="$REAL_HOME/GITS/INC_FILES"
    if [[ -d "$inc_dir" ]]; then
        find "$inc_dir" -type d -name "node_modules" -prune -exec rm -rf {} + 2>/dev/null || true
        find "$inc_dir" -type d -name ".venv" -exec rm -rf {} + 2>/dev/null || true
        find "$inc_dir" -type d -name "venv" -exec rm -rf {} + 2>/dev/null || true
        find "$inc_dir" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        log "Cleaned INC_FILES dev artifacts"
    fi
    
    # VirtualBox logs
    local vbox_dir="$REAL_HOME/VirtualBox VMs"
    if [[ -d "$vbox_dir" ]]; then
        find "$vbox_dir" -type f -name "*.log" -delete 2>/dev/null || true
        find "$vbox_dir" -type f -name "*.log.*" -delete 2>/dev/null || true
        log "Cleaned VirtualBox logs"
    fi
    
    log "Home-specific cleanup complete"
}

cleanup_browser_cache() {
    header "Browser Cache Cleanup"
    
    warn "This will clear browser caches (not history/passwords)"
    
    if [[ "$DRY_RUN" == false && "$CLEAN_ALL" == false ]]; then
        echo -n "Continue? (y/N) "
        read -r REPLY || REPLY=""
        [[ ! $REPLY =~ ^[Yy]$ ]] && return
    fi
    
    # Firefox
    local ff_profiles="$REAL_HOME/.mozilla/firefox"
    if [[ -d "$ff_profiles" ]]; then
        find "$ff_profiles" -type d -name "cache2" -exec rm -rf {}/* \; 2>/dev/null || true
        find "$ff_profiles" -type d -name "thumbnails" -exec rm -rf {}/* \; 2>/dev/null || true
        log "Firefox cache cleaned"
    fi
    
    # Chrome
    local chrome_cache="$REAL_HOME/.config/google-chrome/Default/Cache"
    if [[ -d "$chrome_cache" ]]; then
        rm -rf "$chrome_cache"/* 2>/dev/null || true
        log "Chrome cache cleaned"
    fi
    
    # Chromium
    local chromium_cache="$REAL_HOME/.config/chromium/Default/Cache"
    if [[ -d "$chromium_cache" ]]; then
        rm -rf "$chromium_cache"/* 2>/dev/null || true
        log "Chromium cache cleaned"
    fi
    
    # Brave
    local brave_cache="$REAL_HOME/.config/BraveSoftware/Brave-Browser/Default/Cache"
    if [[ -d "$brave_cache" ]]; then
        rm -rf "$brave_cache"/* 2>/dev/null || true
        log "Brave cache cleaned"
    fi
    
    # Vivaldi
    local vivaldi_cache="$REAL_HOME/.config/vivaldi/Default/Cache"
    if [[ -d "$vivaldi_cache" ]]; then
        rm -rf "$vivaldi_cache"/* 2>/dev/null || true
        log "Vivaldi cache cleaned"
    fi
    
    log "Browser cache cleanup complete"
}

cleanup_system() {
    header "System Cache Cleanup"
    
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        warn "Requires sudo access"
        if [[ "$DRY_RUN" == false ]]; then
            sudo -v || { error "Cannot obtain sudo"; return; }
        fi
    fi
    
    # Journal logs
    log "Cleaning journal logs (keeping 3 days)..."
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would run: journalctl --vacuum-time=3d"
    else
        sudo journalctl --vacuum-time=3d 2>/dev/null || true
    fi
    
    # Temp files
    log "Cleaning old temp files..."
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would clean /tmp and /var/tmp files older than 7 days"
    else
        sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
        sudo find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
    fi
    
    # Old log files
    log "Cleaning old log files..."
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would clean compressed and rotated logs"
    else
        sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
        sudo find /var/log -type f -name "*.old" -delete 2>/dev/null || true
        sudo find /var/log -type f -name "*.[0-9]" -delete 2>/dev/null || true
        sudo find /var/log -type f -name "*.xz" -delete 2>/dev/null || true
    fi
    
    # Package manager caches (non-NixOS)
    if [[ -d /var/cache/pacman/pkg ]]; then
        log "Cleaning pacman cache..."
        [[ "$DRY_RUN" == false ]] && sudo pacman -Sc --noconfirm 2>/dev/null || true
    fi
    
    if command -v apt-get &>/dev/null; then
        log "Cleaning apt cache..."
        [[ "$DRY_RUN" == false ]] && sudo apt-get clean 2>/dev/null || true
    fi
    
    if command -v dnf &>/dev/null; then
        log "Cleaning dnf cache..."
        [[ "$DRY_RUN" == false ]] && sudo dnf clean all 2>/dev/null || true
    fi
    
    # Clear PageCache, dentries and inodes (optional, aggressive)
    # sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
    
    log "System cache cleanup complete"
}

cleanup_docker() {
    header "Docker Cleanup"
    
    if ! command -v docker &>/dev/null; then
        info "Docker not installed, skipping..."
        return
    fi
    
    if ! docker info &>/dev/null; then
        warn "Docker daemon not running, skipping..."
        return
    fi
    
    warn "This will remove unused containers, images, networks, and volumes"
    
    if [[ "$DRY_RUN" == false && "$CLEAN_ALL" == false ]]; then
        echo -n "Continue? (y/N) "
        read -r REPLY || REPLY=""
        [[ ! $REPLY =~ ^[Yy]$ ]] && return
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would run: docker system prune -af --volumes"
        docker system df
    else
        docker system prune -af --volumes 2>/dev/null && log "Docker cleanup complete"
    fi
}

cleanup_flatpak() {
    header "Flatpak Cleanup"
    
    if ! command -v flatpak &>/dev/null; then
        info "Flatpak not installed, skipping..."
        return
    fi
    
    log "Removing unused Flatpak runtimes..."
    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would run: flatpak uninstall --unused"
    else
        flatpak uninstall --unused -y 2>/dev/null || true
    fi
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║           SYSTEM CLEANUP SCRIPT FOR NIXOS/LINUX           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Show initial state
    show_disk_usage
    local BEFORE=$(df / --output=used 2>/dev/null | tail -1 || echo 0)
    
    # Determine what to clean
    local run_all=false
    if [[ "$CLEAN_ALL" == true ]] || \
       { [[ "$CLEAN_NIX" == false ]] && [[ "$CLEAN_USER" == false ]] && [[ "$CLEAN_SYSTEM" == false ]] && [[ "$CLEAN_HOME" == false ]]; }; then
        run_all=true
    fi
    
    # Execute cleanups
    if [[ "$run_all" == true ]] || [[ "$CLEAN_NIX" == true ]]; then
        cleanup_nix
    fi
    
    if [[ "$run_all" == true ]] || [[ "$CLEAN_USER" == true ]]; then
        cleanup_user_cache
    fi
    
    if [[ "$run_all" == true ]] || [[ "$CLEAN_USER" == true ]] || [[ "$CLEAN_HOME" == true ]]; then
        cleanup_home_specific
    fi
    
    if [[ "$run_all" == true ]]; then
        cleanup_browser_cache
    fi
    
    if [[ "$run_all" == true ]] || [[ "$CLEAN_SYSTEM" == true ]]; then
        cleanup_system
    fi
    
    if [[ "$run_all" == true ]]; then
        cleanup_docker
        cleanup_flatpak
    fi
    
    # Final report
    header "Cleanup Complete"
    show_disk_usage
    
    local AFTER=$(df / --output=used 2>/dev/null | tail -1 || echo 0)
    local SAVED=$(( (BEFORE - AFTER) * 1024 ))  # Convert to bytes
    
    if (( SAVED > 0 )); then
        echo -e "\n${GREEN}${BOLD}Total space freed: ~$(human_size $SAVED)${NC}"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "\n${YELLOW}${BOLD}[DRY-RUN MODE] No files were actually deleted${NC}"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)     CLEAN_ALL=true; shift ;;
        -n|--nix)     CLEAN_NIX=true; shift ;;
        -u|--user)    CLEAN_USER=true; shift ;;
        -s|--system)  CLEAN_SYSTEM=true; shift ;;
        -z|--home)    CLEAN_HOME=true; shift ;;
        -d|--dry-run) DRY_RUN=true; shift ;;
        -h|--help)    show_help; exit 0 ;;
        *)            error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Run
main
