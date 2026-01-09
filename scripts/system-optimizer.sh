#!/usr/bin/env bash
# =============================================================================
# system-optimizer.sh - Unified Cross-Platform System Optimizer
# =============================================================================
# Supports: NixOS, Ubuntu/Debian, macOS, Windows (via PowerShell helper)
# Author: zen
# Version: 2.0.0
# =============================================================================

set -euo pipefail

# =============================================================================
# GLOBAL VARIABLES
# =============================================================================
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# OS Detection
OS_TYPE=""
OS_NAME=""
IS_ROOT=false
DRY_RUN=false
VERBOSE=false

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_header()  { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}\n"; }

run_cmd() {
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would execute: $*"
        return 0
    fi
    if $VERBOSE; then
        echo -e "${BLUE}[CMD]${NC} $*"
    fi
    "$@"
}

confirm() {
    local prompt="$1"
    read -p "$(echo -e "${YELLOW}[?]${NC} ${prompt} [y/N] ")" -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        IS_ROOT=true
    fi
}

# =============================================================================
# OS DETECTION
# =============================================================================

detect_os() {
    case "$(uname -s)" in
        Linux*)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                if [[ "$ID" == "nixos" ]]; then
                    OS_TYPE="nixos"
                    OS_NAME="NixOS"
                elif [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
                    OS_TYPE="debian"
                    OS_NAME="$NAME"
                elif [[ "$ID" == "fedora" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "centos" ]]; then
                    OS_TYPE="redhat"
                    OS_NAME="$NAME"
                elif [[ "$ID" == "arch" ]]; then
                    OS_TYPE="arch"
                    OS_NAME="Arch Linux"
                else
                    OS_TYPE="linux"
                    OS_NAME="$NAME"
                fi
            else
                OS_TYPE="linux"
                OS_NAME="Unknown Linux"
            fi
            ;;
        Darwin*)
            OS_TYPE="macos"
            OS_NAME="macOS $(sw_vers -productVersion 2>/dev/null || echo '')"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS_TYPE="windows"
            OS_NAME="Windows"
            ;;
        *)
            OS_TYPE="unknown"
            OS_NAME="Unknown"
            ;;
    esac
}

# =============================================================================
# NIXOS FUNCTIONS
# =============================================================================

nixos_clean_cache() {
    log_header "NixOS: Cleaning Caches"
    
    log_info "Running nix garbage collection..."
    run_cmd sudo nix-collect-garbage
    
    log_info "Cleaning nix profile..."
    run_cmd nix-env --delete-generations old 2>/dev/null || true
    
    log_success "Cache cleanup complete"
}

nixos_clean_generations() {
    log_header "NixOS: Cleaning Old Generations"
    
    local keep="${1:-10}"
    log_info "Keeping last $keep generations..."
    
    local profile="/nix/var/nix/profiles/system"
    run_cmd sudo nix-env --profile "$profile" --delete-generations "+$keep"
    
    log_info "Running garbage collection..."
    run_cmd sudo nix-collect-garbage -d
    
    log_success "Generations cleaned"
}

nixos_optimize_store() {
    log_header "NixOS: Optimizing Store"
    
    log_info "Deduplicating nix store (this may take a while)..."
    run_cmd sudo nix-store --optimise
    
    log_success "Store optimized"
}

nixos_clean_logs() {
    log_header "NixOS: Cleaning Logs"
    
    log_info "Vacuuming journal to 500MB..."
    run_cmd sudo journalctl --vacuum-size=500M
    
    log_info "Removing old journal files..."
    run_cmd sudo journalctl --vacuum-time=14d
    
    log_success "Logs cleaned"
}

nixos_memory_optimize() {
    log_header "NixOS: Memory Optimization"
    
    log_info "Syncing filesystem..."
    run_cmd sync
    
    if confirm "Drop filesystem caches? (safe but may slow subsequent operations)"; then
        log_info "Dropping caches..."
        run_cmd sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
        log_success "Caches dropped"
    fi
    
    log_info "Current memory status:"
    free -h
}

nixos_status_report() {
    log_header "NixOS: System Status Report"
    
    echo -e "${BOLD}Disk Usage:${NC}"
    df -h / /nix 2>/dev/null | grep -v "Filesystem" || df -h /
    
    echo -e "\n${BOLD}Nix Store Size:${NC}"
    du -sh /nix/store 2>/dev/null || echo "Unable to calculate"
    
    echo -e "\n${BOLD}System Generations:${NC}"
    sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -5
    
    echo -e "\n${BOLD}Memory Usage:${NC}"
    free -h
    
    echo -e "\n${BOLD}Swap Status:${NC}"
    swapon --show 2>/dev/null || echo "No swap configured"
    
    echo -e "\n${BOLD}Boot Time:${NC}"
    systemd-analyze 2>/dev/null | head -1 || echo "Unable to analyze"
}

nixos_clean_docker() {
    log_header "Docker: Cleaning Caches and Resources"
    
    if ! command -v docker &>/dev/null; then
        log_warn "Docker not installed, skipping..."
        return 0
    fi
    
    log_info "Docker disk usage before cleanup:"
    docker system df 2>/dev/null || true
    
    log_info "Removing stopped containers..."
    run_cmd docker container prune -f 2>/dev/null || true
    
    log_info "Removing unused images..."
    run_cmd docker image prune -a -f 2>/dev/null || true
    
    log_info "Removing unused volumes..."
    run_cmd docker volume prune -f 2>/dev/null || true
    
    log_info "Removing unused networks..."
    run_cmd docker network prune -f 2>/dev/null || true
    
    log_info "Removing build cache..."
    run_cmd docker builder prune -a -f 2>/dev/null || true
    
    log_info "Docker disk usage after cleanup:"
    docker system df 2>/dev/null || true
    
    log_success "Docker cleanup complete"
}

nixos_full_optimize() {
    log_header "NixOS: Full System Optimization"
    
    nixos_clean_cache
    nixos_clean_generations 5
    nixos_optimize_store
    nixos_clean_logs
    nixos_clean_docker
    
    log_success "Full optimization complete!"
}

# =============================================================================
# DEBIAN/UBUNTU FUNCTIONS
# =============================================================================

debian_clean_cache() {
    log_header "Debian/Ubuntu: Cleaning Caches"
    
    log_info "Cleaning apt cache..."
    run_cmd sudo apt-get clean
    run_cmd sudo apt-get autoremove -y
    
    log_info "Cleaning user cache..."
    rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
    
    # Flatpak cleanup
    if command -v flatpak &>/dev/null; then
        log_info "Cleaning flatpak..."
        run_cmd flatpak uninstall --unused -y 2>/dev/null || true
    fi
    
    # Snap cleanup
    if command -v snap &>/dev/null; then
        log_info "Cleaning snap..."
        snap list --all | awk '/disabled/{print $1, $3}' | while read name rev; do
            run_cmd sudo snap remove "$name" --revision="$rev" 2>/dev/null || true
        done
    fi
    
    log_success "Cache cleanup complete"
}

debian_clean_logs() {
    log_header "Debian/Ubuntu: Cleaning Logs"
    
    log_info "Vacuuming journal..."
    run_cmd sudo journalctl --vacuum-size=500M
    run_cmd sudo journalctl --vacuum-time=14d
    
    log_info "Removing old log files..."
    run_cmd sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
    run_cmd sudo find /var/log -type f -name "*.old" -delete 2>/dev/null || true
    
    log_success "Logs cleaned"
}

debian_memory_optimize() {
    log_header "Debian/Ubuntu: Memory Optimization"
    
    run_cmd sync
    
    if confirm "Drop filesystem caches?"; then
        run_cmd sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
        log_success "Caches dropped"
    fi
    
    free -h
}

debian_status_report() {
    log_header "Debian/Ubuntu: System Status Report"
    
    echo -e "${BOLD}Disk Usage:${NC}"
    df -h /
    
    echo -e "\n${BOLD}Package Cache Size:${NC}"
    du -sh /var/cache/apt/archives 2>/dev/null || echo "Unable to calculate"
    
    echo -e "\n${BOLD}Memory Usage:${NC}"
    free -h
    
    echo -e "\n${BOLD}Upgradable Packages:${NC}"
    apt list --upgradable 2>/dev/null | head -10 || echo "Unable to list"
}

debian_full_optimize() {
    log_header "Debian/Ubuntu: Full System Optimization"
    
    debian_clean_cache
    debian_clean_logs
    
    log_info "Running fstrim..."
    run_cmd sudo fstrim -av 2>/dev/null || log_warn "fstrim not available or failed"
    
    log_success "Full optimization complete!"
}

# =============================================================================
# MACOS FUNCTIONS
# =============================================================================

macos_clean_cache() {
    log_header "macOS: Cleaning Caches"
    
    log_info "Cleaning user cache..."
    rm -rf ~/Library/Caches/* 2>/dev/null || true
    
    log_info "Cleaning system cache..."
    run_cmd sudo rm -rf /Library/Caches/* 2>/dev/null || true
    
    log_info "Cleaning application support cache..."
    rm -rf ~/Library/Application\ Support/Caches/* 2>/dev/null || true
    
    # Homebrew cleanup
    if command -v brew &>/dev/null; then
        log_info "Cleaning Homebrew..."
        run_cmd brew cleanup -s
        run_cmd brew autoremove
        rm -rf "$(brew --cache)" 2>/dev/null || true
    fi
    
    log_success "Cache cleanup complete"
}

macos_clean_logs() {
    log_header "macOS: Cleaning Logs"
    
    log_info "Cleaning system logs..."
    run_cmd sudo rm -rf /var/log/* 2>/dev/null || true
    run_cmd sudo rm -rf /Library/Logs/* 2>/dev/null || true
    rm -rf ~/Library/Logs/* 2>/dev/null || true
    
    log_success "Logs cleaned"
}

macos_clean_temp() {
    log_header "macOS: Cleaning Temporary Files"
    
    log_info "Cleaning temp directories..."
    run_cmd sudo rm -rf /private/var/tmp/* 2>/dev/null || true
    run_cmd sudo rm -rf /private/tmp/* 2>/dev/null || true
    
    log_info "Emptying Trash..."
    rm -rf ~/.Trash/* 2>/dev/null || true
    
    log_success "Temp files cleaned"
}

macos_memory_optimize() {
    log_header "macOS: Memory Optimization"
    
    if confirm "Purge inactive memory?"; then
        log_info "Purging memory..."
        run_cmd sudo purge
        log_success "Memory purged"
    fi
    
    vm_stat | head -10
}

macos_status_report() {
    log_header "macOS: System Status Report"
    
    echo -e "${BOLD}Disk Usage:${NC}"
    df -h /
    
    echo -e "\n${BOLD}Memory Usage:${NC}"
    vm_stat | head -10
    
    echo -e "\n${BOLD}SSD TRIM Status:${NC}"
    if system_profiler SPSerialATADataType 2>/dev/null | grep -q "TRIM Support: Yes"; then
        echo "TRIM is enabled"
    else
        echo "TRIM not enabled or not supported"
    fi
}

macos_full_optimize() {
    log_header "macOS: Full System Optimization"
    
    macos_clean_cache
    macos_clean_logs
    macos_clean_temp
    
    log_success "Full optimization complete!"
}

# =============================================================================
# WINDOWS FUNCTIONS (via PowerShell)
# =============================================================================

windows_optimize() {
    log_header "Windows: Running Optimization"
    
    local ps_script="$SCRIPT_DIR/Win10_Optimize.ps1"
    
    if [[ -f "$ps_script" ]]; then
        log_info "Launching PowerShell optimizer..."
        powershell.exe -ExecutionPolicy Bypass -File "$ps_script"
    else
        log_error "PowerShell script not found at $ps_script"
        log_info "Please run Win10_Optimize.ps1 directly from PowerShell as Administrator"
    fi
}

# =============================================================================
# MAIN MENU
# =============================================================================

show_menu() {
    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║         System Optimizer v${SCRIPT_VERSION}                         ║${NC}"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  Detected OS: ${GREEN}$OS_NAME${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  Running as root: $( $IS_ROOT && echo "${GREEN}Yes${NC}" || echo "${YELLOW}No${NC}" )"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}1.${NC} Clean caches & temp files"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}2.${NC} Clean logs"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}3.${NC} Optimize memory"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}4.${NC} Optimize storage (GC/TRIM)"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}5.${NC} System status report"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}6.${NC} ${GREEN}Full optimization${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}7.${NC} Clean Docker (containers, images, cache)"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}q.${NC} Quit"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
}

run_action() {
    local action="$1"
    
    case "$OS_TYPE" in
        nixos)
            case "$action" in
                1) nixos_clean_cache ;;
                2) nixos_clean_logs ;;
                3) nixos_memory_optimize ;;
                4) nixos_optimize_store ;;
                5) nixos_status_report ;;
                6) nixos_full_optimize ;;
                7) nixos_clean_docker ;;
            esac
            ;;
        debian)
            case "$action" in
                1) debian_clean_cache ;;
                2) debian_clean_logs ;;
                3) debian_memory_optimize ;;
                4) debian_full_optimize ;;
                5) debian_status_report ;;
                6) debian_full_optimize ;;
                7) nixos_clean_docker ;;  # Docker cleanup is cross-platform
            esac
            ;;
        macos)
            case "$action" in
                1) macos_clean_cache ;;
                2) macos_clean_logs ;;
                3) macos_memory_optimize ;;
                4) macos_clean_temp ;;
                5) macos_status_report ;;
                6) macos_full_optimize ;;
                7) nixos_clean_docker ;;  # Docker cleanup is cross-platform
            esac
            ;;
        windows)
            windows_optimize
            ;;
        *)
            log_error "Unsupported OS: $OS_TYPE"
            exit 1
            ;;
    esac
}

# =============================================================================
# CLI PARSING
# =============================================================================

show_help() {
    cat << EOF
${BOLD}$SCRIPT_NAME v$SCRIPT_VERSION${NC} - Unified Cross-Platform System Optimizer

${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS] [COMMAND]

${BOLD}OPTIONS:${NC}
    -h, --help          Show this help message
    -d, --dry-run       Show commands without executing
    -v, --verbose       Enable verbose output
    --report            Show system status report and exit

${BOLD}COMMANDS:${NC}
    clean-cache         Clean caches and temp files
    clean-logs          Clean system logs
    clean-docker        Clean Docker (containers, images, volumes, cache)
    optimize-memory     Optimize memory usage
    optimize-storage    Optimize storage (GC/TRIM)
    full                Run full optimization
    report              Show system status report

${BOLD}EXAMPLES:${NC}
    $SCRIPT_NAME                    # Interactive menu
    $SCRIPT_NAME --report           # Show status report
    $SCRIPT_NAME -d full            # Dry-run full optimization
    sudo $SCRIPT_NAME full          # Run full optimization (as root)

${BOLD}SUPPORTED OS:${NC}
    NixOS, Ubuntu, Debian, macOS, Windows (via PowerShell)
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --report)
                detect_os
                check_root
                run_action 5
                exit 0
                ;;
            clean-cache)
                detect_os
                check_root
                run_action 1
                exit 0
                ;;
            clean-logs)
                detect_os
                check_root
                run_action 2
                exit 0
                ;;
            optimize-memory)
                detect_os
                check_root
                run_action 3
                exit 0
                ;;
            optimize-storage)
                detect_os
                check_root
                run_action 4
                exit 0
                ;;
            full)
                detect_os
                check_root
                run_action 6
                exit 0
                ;;
            report)
                detect_os
                check_root
                run_action 5
                exit 0
                ;;
            clean-docker)
                detect_os
                check_root
                run_action 7
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Interactive mode
    detect_os
    check_root
    
    if [[ "$OS_TYPE" == "unknown" ]]; then
        log_error "Unable to detect operating system"
        exit 1
    fi
    
    if [[ "$OS_TYPE" == "windows" ]]; then
        windows_optimize
        exit 0
    fi
    
    # Menu loop
    while true; do
        show_menu
        read -p "$(echo -e "\n${BOLD}Select option:${NC} ")" choice
        
        case "$choice" in
            1|2|3|4|5|6|7)
                run_action "$choice"
                echo -e "\n${GREEN}Press Enter to continue...${NC}"
                read -r
                ;;
            q|Q)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_warn "Invalid option. Please try again."
                ;;
        esac
    done
}

main "$@"
