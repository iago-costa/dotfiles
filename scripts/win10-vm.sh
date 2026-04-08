#!/usr/bin/env bash
# =============================================================================
# win10-vm.sh - Quick Windows 10 VM launcher with optimized graphics
# =============================================================================
# Uses quickemu for easy Windows 10 VM management with SPICE + OpenGL
# Run your Windows-Ultimate-Optimizer.bat inside the VM for best performance
# =============================================================================

set -euo pipefail

# Configuration
VM_DIR="${HOME}/VMs/windows10"
CONF_FILE="${VM_DIR}/windows-10.conf"
RAM="${WIN10_RAM:-4G}"
CORES="${WIN10_CORES:-4}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         Windows 10 VM - Optimized for Graphics               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup     Download Windows 10 ISO and create VM configuration"
    echo "  start     Start the Windows 10 VM (default if VM exists)"
    echo "  spice     Start with SPICE display (best for 3D acceleration)"
    echo "  sdl       Start with SDL display (fallback)"
    echo "  status    Check if VM is running"
    echo "  stop      Stop the running VM"
    echo "  delete    Delete VM and all data (requires confirmation)"
    echo ""
    echo "Environment variables:"
    echo "  WIN10_RAM     RAM allocation (default: 4G)"
    echo "  WIN10_CORES   CPU cores (default: 4, +2 adicionados)"
    echo ""
    echo "Tips for best graphics performance:"
    echo "  1. Install VirtIO drivers from the mounted ISO in Windows"
    echo "  2. Run Windows-Ultimate-Optimizer.bat inside the VM"
    echo "  3. Use 'spice' display mode for OpenGL/DirectX acceleration"
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

find_iso() {
    # Look for any Windows 10 ISO in the VM working directory
    local iso_path=""
    if [ -f "$CONF_FILE" ]; then
        iso_path=$(grep '^iso=' "$CONF_FILE" 2>/dev/null | cut -d'"' -f2)
    fi
    # Check if the ISO from config exists
    if [ -n "$iso_path" ] && [ -f "$iso_path" ]; then
        echo "$iso_path"
        return 0
    fi
    # Fallback: find any Win10 ISO in the directory
    local found
    found=$(find "$VM_DIR" -maxdepth 2 -name "*.iso" \
        ! -name "virtio-win*" ! -name "unattended*" ! -name "spice*" \
        -size +1G 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi
    return 1
}

setup_vm() {
    echo -e "${YELLOW}Setting up Windows 10 VM...${NC}"
    
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
    fi
    
    echo -e "${CYAN}Downloading Windows 10 ISO via quickget...${NC}"
    echo "This may take a while depending on your internet connection."
    echo ""
    
    # Use quickget to download Windows 10
    quickget windows 10
    
    # ── Verify ISO was actually downloaded ──────────────────────────
    if ! find_iso &>/dev/null; then
        echo ""
        echo -e "${RED}✗ Windows 10 ISO download failed!${NC}"
        echo -e "${YELLOW}Microsoft blocked the automated download (common issue).${NC}"
        echo ""
        echo -e "${CYAN}Opening the download page in your browser...${NC}"
        
        # Try to open browser
        if command -v xdg-open &>/dev/null; then
            xdg-open "https://www.microsoft.com/en-us/software-download/windows10ISO" 2>/dev/null &
        elif command -v vivaldi &>/dev/null; then
            vivaldi "https://www.microsoft.com/en-us/software-download/windows10ISO" 2>/dev/null &
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}Manual download steps:${NC}"
        echo "  1. Select 'Windows 10 (multi-edition ISO)'"
        echo "  2. Choose language: English International"
        echo "  3. Click '64-bit Download'"
        echo -e "  4. Save to: ${CYAN}${VM_DIR}/windows-10/${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Wait for user to download
        echo -e "${YELLOW}Waiting for ISO file... (press Ctrl+C to cancel)${NC}"
        while ! find_iso &>/dev/null; do
            sleep 5
            # Also check ~/Downloads for the ISO
            local dl_iso
            dl_iso=$(find "$HOME/Downloads" -maxdepth 1 -name "Win10*.iso" -size +1G 2>/dev/null | head -1)
            if [ -n "$dl_iso" ]; then
                echo -e "${GREEN}Found ISO in Downloads! Moving to VM directory...${NC}"
                mv "$dl_iso" "${VM_DIR}/windows-10/"
                break
            fi
        done
        
        # Update conf to point to the actual ISO filename
        local actual_iso
        actual_iso=$(find_iso)
        if [ -n "$actual_iso" ] && [ -f "$CONF_FILE" ]; then
            local relative_iso
            relative_iso=$(realpath --relative-to="$VM_DIR" "$actual_iso")
            sed -i "s|^iso=.*|iso=\"${relative_iso}\"|" "$CONF_FILE"
            echo -e "${GREEN}Updated config to use: $relative_iso${NC}"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✓ Windows 10 VM setup complete!${NC}"
    echo -e "${CYAN}Configuration file: $CONF_FILE${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: $0 start"
    echo "  2. Install Windows 10"
    echo "  3. Install VirtIO drivers from the mounted virtio-win ISO"
    echo "  4. Run Windows-Ultimate-Optimizer.bat for best performance"
}

start_vm() {
    local display_mode="${1:-spice}"
    
    if [ ! -f "$CONF_FILE" ]; then
        echo -e "${RED}Error: VM not configured. Run '$0 setup' first.${NC}"
        exit 1
    fi
    
    cd "$VM_DIR"
    
    # Check if ISO is needed (first boot) and exists
    local iso_path
    iso_path=$(grep '^iso=' "$CONF_FILE" 2>/dev/null | cut -d'"' -f2)
    if [ -n "$iso_path" ] && [ ! -f "$iso_path" ]; then
        echo -e "${RED}Error: Windows ISO not found at: $iso_path${NC}"
        echo -e "${YELLOW}Run '$0 setup' to download it, or manually place the ISO there.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Starting Windows 10 VM...${NC}"
    echo -e "  Display: ${CYAN}$display_mode${NC}"
    echo -e "  RAM: ${CYAN}$RAM${NC}"
    echo -e "  Cores: ${CYAN}$CORES${NC}"
    echo ""

    # Patch .conf with cpu_cores and ram (quickemu reads from conf, not CLI flags)
    # Also enable clipboard sharing via SPICE (copy to guest / paste from guest)
    sed -i \
        -e "s/^cpu_cores=.*/cpu_cores=\"${CORES}\"/" \
        -e "s/^ram=.*/ram=\"${RAM}\"/" \
        "$CONF_FILE"
    # Add keys if they don't exist yet
    grep -q '^cpu_cores=' "$CONF_FILE" || echo "cpu_cores=\"${CORES}\"" >> "$CONF_FILE"
    grep -q '^ram='       "$CONF_FILE" || echo "ram=\"${RAM}\""             >> "$CONF_FILE"

    echo -e "  ${CYAN}Clipboard:${NC} habilitado (copy to guest / paste from guest via SPICE + spice-vdagent)"
    echo ""

    case "$display_mode" in
        spice)
            # SPICE: clipboard bidirecional é automático via spice-vdagent no Windows
            quickemu --vm windows-10.conf \
                --display spice
            ;;
        sdl)
            # SDL fallback (clipboard limitado, prefira spice)
            quickemu --vm windows-10.conf \
                --display sdl
            ;;
        *)
            echo -e "${RED}Unknown display mode: $display_mode${NC}"
            exit 1
            ;;
    esac
}

check_status() {
    if pgrep -f "windows-10.conf" > /dev/null; then
        echo -e "${GREEN}Windows 10 VM is running${NC}"
        pgrep -af "windows-10.conf"
    else
        echo -e "${YELLOW}Windows 10 VM is not running${NC}"
    fi
}

stop_vm() {
    if pgrep -f "windows-10.conf" > /dev/null; then
        echo -e "${YELLOW}Stopping Windows 10 VM...${NC}"
        pkill -f "windows-10.conf" || true
        echo -e "${GREEN}VM stopped${NC}"
    else
        echo -e "${YELLOW}VM is not running${NC}"
    fi
}

delete_vm() {
    echo -e "${RED}WARNING: This will delete the entire Windows 10 VM including:${NC}"
    echo "  - VM configuration"
    echo "  - Virtual disk (all data inside Windows)"
    echo "  - Downloaded ISO files"
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
        setup_vm
        ;;
    start|"")
        if [ -f "$CONF_FILE" ]; then
            start_vm spice
        else
            echo -e "${YELLOW}No VM found. Running setup...${NC}"
            echo ""
            setup_vm
        fi
        ;;
    spice)
        start_vm spice
        ;;
    sdl)
        start_vm sdl
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
