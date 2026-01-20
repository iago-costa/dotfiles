#!/usr/bin/env bash
# =============================================================================
# macos-vm.sh - Quick macOS Sonoma VM launcher with optimized settings
# =============================================================================
# Uses quickemu for easy macOS VM management
# Note: Graphics performance is limited without GPU passthrough (no Metal/OpenGL hw accel)
# =============================================================================

set -euo pipefail

# Configuration
VM_DIR="${HOME}/VMs/macos-sonoma"
CONF_FILE="${VM_DIR}/macos-sonoma.conf"
RAM="${MACOS_RAM:-8G}"
CORES="${MACOS_CORES:-4}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         macOS 14 Sonoma VM - Quickemu Launcher               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup     Download macOS Sequoia and create VM configuration"
    echo "  start     Start the macOS VM (default if VM exists)"
    echo "  spice     Start with SPICE display"
    echo "  cocoa     Start with native Cocoa display (macOS host only)"
    echo "  status    Check if VM is running"
    echo "  stop      Stop the running VM"
    echo "  delete    Delete VM and all data (requires confirmation)"
    echo ""
    echo "Environment variables:"
    echo "  MACOS_RAM     RAM allocation (default: 8G)"
    echo "  MACOS_CORES   CPU cores (default: 4)"
    echo ""
    echo -e "${YELLOW}Graphics Limitations:${NC}"
    echo "  macOS VMs have limited graphics acceleration without GPU passthrough."
    echo "  Metal and OpenGL hardware acceleration require compatible AMD GPU passthrough."
    echo "  Basic 2D acceleration is available via VirGL."
}

check_dependencies() {
    local missing=()
    
    for cmd in quickemu quickget; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing dependencies: ${missing[*]}${NC}"
        echo "These should be installed via NixOS configuration"
        exit 1
    fi
}

list_macos_versions() {
    echo -e "${CYAN}Available macOS versions:${NC}"
    quickget macos | head -20
}

setup_vm() {
    local version="${1:-sonoma}"
    
    echo -e "${YELLOW}Setting up macOS $version VM...${NC}"
    echo ""
    echo -e "${CYAN}Note: macOS VMs have limited graphics acceleration.${NC}"
    echo "For development/testing purposes, this works well."
    echo "For graphics-intensive apps, GPU passthrough would be needed."
    echo ""
    
    # Create VM directory
    mkdir -p "$VM_DIR"
    cd "$VM_DIR"
    
    if [ -f "$CONF_FILE" ]; then
        echo -e "${YELLOW}VM configuration already exists at: $CONF_FILE${NC}"
        read -p "Recreate? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Setup cancelled."
            return
        fi
        rm -f "$CONF_FILE"
    fi
    
    echo -e "${CYAN}Downloading macOS $version via quickget...${NC}"
    echo "This will download the macOS recovery image and create a bootable disk."
    echo "The installation process will complete inside the VM."
    echo ""
    
    # Use quickget to download macOS
    quickget macos "$version"
    
    # Rename config if needed (quickget creates macos-$version.conf)
    if [ -f "macos-$version.conf" ] && [ ! -f "$CONF_FILE" ]; then
        mv "macos-$version.conf" "$CONF_FILE"
    fi
    
    echo ""
    echo -e "${GREEN}✓ macOS $version VM setup complete!${NC}"
    echo -e "${CYAN}Configuration file: $CONF_FILE${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: $0 start"
    echo "  2. Follow macOS installation wizard"
    echo "  3. In Disk Utility: Erase 'QEMU HARDDISK' as APFS"
    echo "  4. Install macOS to that disk"
    echo "  5. Complete setup and enjoy!"
    echo ""
    echo -e "${YELLOW}Tips for best performance:${NC}"
    echo "  - Allocate at least 8GB RAM and 4 CPU cores"
    echo "  - Use SSD storage for the VM disk"
    echo "  - Disable transparency effects in System Preferences"
    echo "  - Reduce motion in Accessibility settings"
}

start_vm() {
    local display_mode="${1:-spice}"
    
    # Check for any macos config file
    local conf_to_use=""
    if [ -f "$CONF_FILE" ]; then
        conf_to_use="$CONF_FILE"
    elif [ -f "${VM_DIR}/macos-sequoia.conf" ]; then
        conf_to_use="${VM_DIR}/macos-sequoia.conf"
    else
        # Look for any macos config
        for f in "${VM_DIR}"/macos-*.conf; do
            if [ -f "$f" ]; then
                conf_to_use="$f"
                break
            fi
        done
    fi
    
    if [ -z "$conf_to_use" ]; then
        echo -e "${RED}Error: VM not configured. Run '$0 setup' first.${NC}"
        exit 1
    fi
    
    cd "$VM_DIR"
    
    echo -e "${GREEN}Starting macOS Sequoia VM...${NC}"
    echo -e "  Config: ${CYAN}$(basename "$conf_to_use")${NC}"
    echo -e "  Display: ${CYAN}$display_mode${NC}"
    echo -e "  RAM: ${CYAN}$RAM${NC}"
    echo -e "  Cores: ${CYAN}$CORES${NC}"
    echo ""
    
    local conf_basename
    conf_basename=$(basename "$conf_to_use")
    
    case "$display_mode" in
        spice)
            # SPICE for remote-like access with some acceleration
            quickemu --vm "$conf_basename" \
                --display spice
            ;;
        sdl)
            # SDL for local display
            quickemu --vm "$conf_basename" \
                --display sdl
            ;;
        gtk)
            # GTK display
            quickemu --vm "$conf_basename" \
                --display gtk
            ;;
        *)
            echo -e "${RED}Unknown display mode: $display_mode${NC}"
            exit 1
            ;;
    esac
}

check_status() {
    if pgrep -f "macos.*\.conf" > /dev/null; then
        echo -e "${GREEN}macOS VM is running${NC}"
        pgrep -af "macos.*\.conf" | head -3
    else
        echo -e "${YELLOW}macOS VM is not running${NC}"
    fi
}

stop_vm() {
    if pgrep -f "macos.*\.conf" > /dev/null; then
        echo -e "${YELLOW}Stopping macOS VM...${NC}"
        pkill -f "macos.*\.conf" || true
        sleep 2
        echo -e "${GREEN}VM stopped${NC}"
    else
        echo -e "${YELLOW}VM is not running${NC}"
    fi
}

delete_vm() {
    echo -e "${RED}WARNING: This will delete the entire macOS VM including:${NC}"
    echo "  - VM configuration"
    echo "  - Virtual disk (all data inside macOS)"
    echo "  - Downloaded base images"
    echo ""
    echo -e "Directory to delete: ${CYAN}$VM_DIR${NC}"
    echo ""
    read -p "Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" = "DELETE" ]; then
        stop_vm 2>/dev/null || true
        rm -rf "$VM_DIR"
        echo -e "${GREEN}VM deleted successfully${NC}"
    else
        echo "Deletion cancelled."
    fi
}

# Main
print_banner
check_dependencies

case "${1:-}" in
    setup)
        setup_vm "${2:-sequoia}"
        ;;
    start|"")
        if [ -d "$VM_DIR" ] && ls "${VM_DIR}"/macos-*.conf 1>/dev/null 2>&1; then
            start_vm spice
        else
            echo -e "${YELLOW}No VM found. Running setup...${NC}"
            echo ""
            setup_vm sonoma
        fi
        ;;
    spice)
        start_vm spice
        ;;
    sdl)
        start_vm sdl
        ;;
    gtk)
        start_vm gtk
        ;;
    status)
        check_status
        ;;
    stop)
        stop_vm
        ;;
    delete)
        delete_vm
        ;;
    versions)
        list_macos_versions
        ;;
    help|--help|-h)
        print_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        print_help
        exit 1
        ;;
esac
