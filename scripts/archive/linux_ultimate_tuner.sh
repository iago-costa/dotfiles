#!/bin/bash

# linux_ultimate_tuner.sh - A comprehensive system optimization suite for modern Linux distributions
# Version: 1.0
# Author: Linux System Administrator & DevOps Engineer
# Description: This script optimizes CPU, memory, disk I/O, networking, and power management
#              while embedding critical safety and reversibility features.

# Exit immediately if a command exits with a non-zero status
set -e

# Global variables
SCRIPT_NAME="linux_ultimate_tuner.sh"
BACKUP_DIR="/opt/ultimate_tuner_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/ultimate_tuner.log"
DISTRO=""
PACKAGE_MANAGER=""
IS_LAPTOP=false
IS_VIRTUALIZED=false
VIRTUALIZATION_TYPE=""
ROOT_FS_TYPE=""
CPU_FLAGS=""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize log file
touch "$LOG_FILE"

# Function to log messages
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_color $RED "Error: This script must be run as root."
        log "Script execution attempted without root privileges."
        exit 1
    fi
    log "Root privileges confirmed."
}

# Function to detect system information
detect_system() {
    log "Starting system detection..."
    
    # Detect distribution and package manager
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        log "Detected distribution: $DISTRO"
    else
        print_color $RED "Error: Cannot detect Linux distribution."
        exit 1
    fi
    
    # Set package manager based on distribution
    case "$DISTRO" in
        ubuntu|debian)
            PACKAGE_MANAGER="apt"
            ;;
        fedora|centos|rhel)
            PACKAGE_MANAGER="dnf"
            ;;
        arch)
            PACKAGE_MANAGER="pacman"
            ;;
        opensuse-leap|opensuse-tumbleweed)
            PACKAGE_MANAGER="zypper"
            ;;
        *)
            print_color $RED "Error: Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
    log "Detected package manager: $PACKAGE_MANAGER"
    
    # Check if system is a laptop
    if [ -d "/sys/class/power_supply/" ]; then
        IS_LAPTOP=true
        log "Detected laptop form factor."
    else
        log "Detected desktop form factor."
    fi
    
    # Check if system is virtualized
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        VIRTUALIZATION_TYPE=$(systemd-detect-virt)
        if [ "$VIRTUALIZATION_TYPE" != "none" ]; then
            IS_VIRTUALIZED=true
            log "Detected virtualization: $VIRTUALIZATION_TYPE"
        else
            log "Detected bare metal system."
        fi
    else
        log "systemd-detect-virt not available, cannot detect virtualization."
    fi
    
    # Detect root filesystem type
    ROOT_FS_TYPE=$(df -Th / | awk 'NR==2 {print $2}')
    log "Detected root filesystem type: $ROOT_FS_TYPE"
    
    # Detect CPU flags
    CPU_FLAGS=$(cat /proc/cpuinfo | grep flags | head -n 1 | cut -d: -f2)
    log "Detected CPU flags: $CPU_FLAGS"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    log "Created backup directory: $BACKUP_DIR"
    
    print_color $GREEN "System detection completed successfully."
}

# Function to backup a file
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup.$TIMESTAMP"
        log "Backed up $file to $BACKUP_DIR/$(basename "$file").backup.$TIMESTAMP"
    fi
}

# Function to install packages based on package manager
install_packages() {
    local packages=("$@")
    log "Installing packages: ${packages[*]}"
    
    case "$PACKAGE_MANAGER" in
        apt)
            apt update
            apt install -y "${packages[@]}"
            ;;
        dnf)
            dnf install -y "${packages[@]}"
            ;;
        pacman)
            pacman -Syu --noconfirm "${packages[@]}"
            ;;
        zypper)
            zypper --non-interactive install "${packages[@]}"
            ;;
    esac
}

# Function to clean package caches
clean_package_caches() {
    log "Cleaning package caches..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            apt-get clean
            apt-get autoremove -y
            ;;
        dnf)
            dnf clean all
            dnf autoremove -y
            ;;
        pacman)
            pacman -Scc --noconfirm
            pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
            ;;
        zypper)
            zypper clean --all
            ;;
    esac
    
    print_color $GREEN "Package caches cleaned successfully."
}

# Function to clean user caches
clean_user_caches() {
    log "Cleaning user caches..."
    
    # Clean thumbnail cache
    find /home -type d -name ".cache" -exec find {} -name "thumbnails" -type d \; 2>/dev/null | while read dir; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            log "Removed thumbnail cache: $dir"
        fi
    done
    
    # Clean Flatpak unused runtimes
    if command -v flatpak >/dev/null 2>&1; then
        flatpak uninstall --unused -y 2>/dev/null || true
        log "Cleaned unused Flatpak runtimes."
    fi
    
    # Clean Snap unused packages
    if command -v snap >/dev/null 2>&1; then
        snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
            snap remove "$snapname" --revision="$revision"
            log "Removed disabled Snap package: $snapname revision $revision"
        done
    fi
    
    print_color $GREEN "User caches cleaned successfully."
}

# Function to clean logs
clean_logs() {
    log "Cleaning logs..."
    
    # Limit journal size
    journalctl --vacuum-size=250M
    log "Limited journal size to 250MB."
    
    # Clean old log files in /var/log
    find /var/log -type f -name "*.log.*" -delete 2>/dev/null || true
    find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
    find /var/log -type f -name "*.old" -delete 2>/dev/null || true
    
    print_color $GREEN "Logs cleaned successfully."
}

# Function to remove old kernels
remove_old_kernels() {
    if [ "$IS_LAPTOP" = true ]; then
        print_color $YELLOW "Warning: Removing old kernels on laptops can be risky."
        read -p "Do you want to continue? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Skipping old kernel removal as per user request."
            return
        fi
    fi
    
    log "Removing old kernels..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            if command -v apt-get >/dev/null 2>&1; then
                apt-get autoremove -y
                log "Removed old kernels using apt-get autoremove."
            fi
            ;;
        dnf)
            if command -v dnf >/dev/null 2>&1; then
                dnf autoremove -y
                log "Removed old kernels using dnf autoremove."
            fi
            ;;
        pacman)
            if command -v pacman >/dev/null 2>&1; then
                pacman -Qdtq | pacman -Rns - 2>/dev/null || true
                log "Removed old kernels using pacman."
            fi
            ;;
        zypper)
            if command -v zypper >/dev/null 2>&1; then
                zypper packages --unneeded | awk -F'|' 'NR==4{print $3}' | xargs -r zypper remove -y
                log "Removed old kernels using zypper."
            fi
            ;;
    esac
    
    print_color $GREEN "Old kernels removed successfully."
}

# Function to optimize I/O scheduler
optimize_io_scheduler() {
    log "Optimizing I/O scheduler..."
    
    # Get primary disk
    local primary_disk=$(lsblk -d -o NAME,ROTA | grep -w "0" | head -n 1 | awk '{print "/dev/"$1}')
    if [ -z "$primary_disk" ]; then
        primary_disk=$(lsblk -d -o NAME,ROTA | grep -w "1" | head -n 1 | awk '{print "/dev/"$1}')
    fi
    
    if [ -z "$primary_disk" ]; then
        print_color $RED "Error: Cannot detect primary disk."
        return
    fi
    
    log "Detected primary disk: $primary_disk"
    
    # Check if disk is SSD or HDD
    local is_ssd=$(cat /sys/block/$(basename $primary_disk)/queue/rotational 2>/dev/null || echo "1")
    
    if [ "$is_ssd" = "0" ]; then
        log "Detected SSD disk."
        
        # Enable fstrim timer
        if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
            systemctl enable fstrim.timer
            systemctl start fstrim.timer
            log "Enabled and started fstrim.timer."
        fi
        
        # Suggest fstab options
        print_color $YELLOW "Consider adding 'discard,noatime' options to your SSD partitions in /etc/fstab."
        echo "# Example fstab entry for SSD:" >> "$BACKUP_DIR/fstab_ssd_suggestions.$TIMESTAMP"
        echo "# UUID=your-uuid-here  /  ext4  defaults,discard,noatime  0  1" >> "$BACKUP_DIR/fstab_ssd_suggestions.$TIMESTAMP"
        log "Created fstab SSD suggestions in $BACKUP_DIR/fstab_ssd_suggestions.$TIMESTAMP"
    else
        log "Detected HDD disk."
        
        # Set I/O scheduler to bfq or mq-deadline
        local scheduler_file="/sys/block/$(basename $primary_disk)/queue/scheduler"
        if [ -f "$scheduler_file" ]; then
            if grep -q "bfq" "$scheduler_file"; then
                echo bfq > "$scheduler_file"
                log "Set I/O scheduler to bfq."
            elif grep -q "mq-deadline" "$scheduler_file"; then
                echo mq-deadline > "$scheduler_file"
                log "Set I/O scheduler to mq-deadline."
            else
                print_color $YELLOW "Warning: Neither bfq nor mq-deadline scheduler is available."
            fi
        fi
    fi
    
    print_color $GREEN "I/O scheduler optimized successfully."
}

# Function to disable file indexing services
disable_file_indexing() {
    log "Disabling file indexing services..."
    
    # Stop and disable baloo (KDE)
    if systemctl is-active --quiet baloo.service 2>/dev/null; then
        systemctl stop baloo.service
        systemctl disable baloo.service
        log "Stopped and disabled baloo.service."
    fi
    
    if systemctl is-active --quiet baloo-file.service 2>/dev/null; then
        systemctl stop baloo-file.service
        systemctl disable baloo-file.service
        log "Stopped and disabled baloo-file.service."
    fi
    
    # Stop and disable tracker (GNOME)
    if systemctl is-active --quiet tracker-miner-fs.service 2>/dev/null; then
        systemctl stop tracker-miner-fs.service
        systemctl disable tracker-miner-fs.service
        log "Stopped and disabled tracker-miner-fs.service."
    fi
    
    if systemctl is-active --quiet tracker-store.service 2>/dev/null; then
        systemctl stop tracker-store.service
        systemctl disable tracker-store.service
        log "Stopped and disabled tracker-store.service."
    fi
    
    print_color $GREEN "File indexing services disabled successfully."
}

# Function to clean disk and optimize I/O
clean_disk_io() {
    print_color $BLUE "Starting disk cleaning and I/O optimization..."
    
    clean_package_caches
    clean_user_caches
    clean_logs
    
    read -p "Do you want to remove old kernels? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        remove_old_kernels
    else
        log "Skipping old kernel removal as per user request."
    fi
    
    optimize_io_scheduler
    
    read -p "Do you want to disable file indexing services? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disable_file_indexing
    else
        log "Skipping file indexing service disabling as per user request."
    fi
    
    print_color $GREEN "Disk cleaning and I/O optimization completed successfully."
}

# Function to optimize memory and swap
optimize_memory() {
    print_color $BLUE "Starting memory and swap optimization..."
    
    # Create sysctl configuration
    local sysctl_file="/etc/sysctl.d/99-ultimate-tuner.conf"
    backup_file "$sysctl_file"
    
    cat > "$sysctl_file" << EOF
# Memory and swap optimization by linux_ultimate_tuner.sh
# Created on $(date)

# Lower swappiness to prefer RAM over swap
vm.swappiness=10

# Retain dentry/inode cache
vm.vfs_cache_pressure=50

# Improve memory management
vm.dirty_ratio=10
vm.dirty_background_ratio=5
EOF
    
    log "Created sysctl configuration: $sysctl_file"
    
    # Apply sysctl settings
    sysctl -p "$sysctl_file"
    log "Applied sysctl settings."
    
    # Offer to drop caches
    read -p "Do you want to drop caches now? This will free memory but may slow down subsequent operations. (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches
        log "Dropped caches."
        print_color $GREEN "Caches dropped successfully."
    else
        log "Skipping cache dropping as per user request."
    fi
    
    # Install and configure earlyoom
    if ! command -v earlyoom >/dev/null 2>&1; then
        print_color $YELLOW "Installing earlyoom for better OOM handling..."
        install_packages earlyoom
        
        # Configure earlyoom
        backup_file "/etc/default/earlyoom"
        cat > /etc/default/earlyoom << EOF
# Configuration for earlyoom
EARLYOOM_ARGS="-r 60 -m 10"
EOF
        systemctl enable earlyoom
        systemctl start earlyoom
        log "Configured and started earlyoom."
    else
        log "earlyoom is already installed."
    fi
    
    # Configure ZRAM if RAM < 16GB
    local total_ram=$(free -g | awk '/Mem:/ {print $2}')
    if [ "$total_ram" -lt 16 ]; then
        print_color $YELLOW "Configuring ZRAM for systems with less than 16GB RAM..."
        
        # Install zram-config if not present
        if ! dpkg -l | grep -q zram-config; then
            install_packages zram-config
        fi
        
        # Calculate ZRAM size (50% of RAM)
        local zram_size=$((total_ram / 2))
        
        # Create ZRAM configuration
        backup_file "/etc/systemd/zram-generator.conf"
        cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ${zram_size} * 1024 * 1024 * 1024
compression-algorithm = zstd
EOF
        
        systemctl daemon-reload
        systemctl enable systemd-zram-setup@zram0.service
        systemctl start systemd-zram-setup@zram0.service
        log "Configured ZRAM with size ${zram_size}GB and zstd compression."
    fi
    
    print_color $GREEN "Memory and swap optimization completed successfully."
}

# Function to optimize CPU and process scheduling
optimize_cpu() {
    print_color $BLUE "Starting CPU and process scheduling optimization..."
    
    # Set CPU governor to performance for desktops
    if [ "$IS_LAPTOP" = false ]; then
        log "Setting CPU governor to performance mode..."
        
        # Install cpufrequtils if not present
        if ! command -v cpufreq-set >/dev/null 2>&1; then
            install_packages cpufrequtils
        fi
        
        # Set governor to performance
        for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
            echo performance > "$cpu/cpufreq/scaling_governor" 2>/dev/null || true
        done
        
        # Make the change persistent
        backup_file "/etc/default/cpufrequtils"
        cat > /etc/default/cpufrequtils << EOF
# Configuration for cpufrequtils
GOVERNOR="performance"
EOF
        
        log "Set CPU governor to performance mode."
    else
        log "Skipping CPU governor optimization on laptop (will be handled in power management section)."
    fi
    
    # Ensure irqbalance is running
    if systemctl is-active --quiet irqbalance; then
        log "irqbalance is already running."
    else
        if systemctl is-enabled --quiet irqbalance 2>/dev/null; then
            systemctl start irqbalance
            log "Started irqbalance service."
        else
            install_packages irqbalance
            systemctl enable irqbalance
            systemctl start irqbalance
            log "Installed and started irqbalance service."
        fi
    fi
    
    print_color $GREEN "CPU and process scheduling optimization completed successfully."
}

# Function to renice a process
renice_process() {
    print_color $BLUE "Process renicing tool"
    
    # List running processes
    echo "Running processes:"
    ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -20
    
    read -p "Enter PID of the process to renice: " pid
    if [ -z "$pid" ]; then
        log "No PID entered, returning to menu."
        return
    fi
    
    # Check if PID exists
    if ! ps -p "$pid" > /dev/null; then
        print_color $RED "Error: Process with PID $pid does not exist."
        return
    fi
    
    read -p "Enter nice value (-20 to 19, lower is higher priority): " nice_value
    if [ -z "$nice_value" ]; then
        log "No nice value entered, returning to menu."
        return
    fi
    
    # Validate nice value
    if ! [[ "$nice_value" =~ ^-?[0-9]+$ ]] || [ "$nice_value" -lt -20 ] || [ "$nice_value" -gt 19 ]; then
        print_color $RED "Error: Invalid nice value. Must be between -20 and 19."
        return
    fi
    
    # Renice the process
    renice -n "$nice_value" -p "$pid"
    log "Reniced process $pid to nice value $nice_value."
    print_color $GREEN "Process $pid reniced to $nice_value successfully."
}

# Function to pin a process to CPU cores
pin_process() {
    print_color $BLUE "Process CPU pinning tool"
    
    # List running processes
    echo "Running processes:"
    ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -20
    
    read -p "Enter PID of the process to pin: " pid
    if [ -z "$pid" ]; then
        log "No PID entered, returning to menu."
        return
    fi
    
    # Check if PID exists
    if ! ps -p "$pid" > /dev/null; then
        print_color $RED "Error: Process with PID $pid does not exist."
        return
    fi
    
    # Get number of CPU cores
    local cpu_cores=$(nproc)
    echo "Available CPU cores: 0 to $((cpu_cores-1))"
    
    read -p "Enter CPU core(s) to pin to (comma-separated, e.g., 0,1,2): " cores
    if [ -z "$cores" ]; then
        log "No CPU cores entered, returning to menu."
        return
    fi
    
    # Pin the process
    taskset -cp "$cores" "$pid"
    log "Pinned process $pid to CPU core(s) $cores."
    print_color $GREEN "Process $pid pinned to CPU core(s) $cores successfully."
}

# Function to optimize network
optimize_network() {
    print_color $BLUE "Starting network optimization..."
    
    # Install and configure systemd-resolved
    if ! systemctl is-active --quiet systemd-resolved; then
        install_packages systemd-resolved
        
        # Enable and start systemd-resolved
        systemctl enable systemd-resolved
        systemctl start systemd-resolved
        
        # Create symlink for resolv.conf
        backup_file "/etc/resolv.conf"
        ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
        
        log "Configured systemd-resolved as local DNS cache."
    else
        log "systemd-resolved is already running."
    fi
    
    # Create sysctl configuration for network optimization
    local sysctl_file="/etc/sysctl.d/99-ultimate-tuner-network.conf"
    backup_file "$sysctl_file"
    
    cat > "$sysctl_file" << EOF
# Network optimization by linux_ultimate_tuner.sh
# Created on $(date)

# Increase TCP buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Enable BBR congestion control
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# Optimize network stack for high throughput
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 16384
EOF
    
    log "Created network sysctl configuration: $sysctl_file"
    
    # Apply sysctl settings
    sysctl -p "$sysctl_file"
    log "Applied network sysctl settings."
    
    # Optimize NIC settings
    local primary_interface=$(ip route | awk '/default/ {print $5}' | head -n 1)
    if [ -n "$primary_interface" ] && command -v ethtool >/dev/null 2>&1; then
        log "Optimizing NIC settings for interface: $primary_interface"
        
        # Disable Energy-Efficient Ethernet if supported
        if ethtool --show-eee "$primary_interface" 2>/dev/null | grep -q "EEE status: enabled"; then
            ethtool --set-eee "$primary_interface" eee off
            log "Disabled Energy-Efficient Ethernet for $primary_interface."
        fi
        
        # Optimize ring buffer sizes
        if ethtool -g "$primary_interface" 2>/dev/null | grep -q "Pre-set maximums"; then
            # Get current max values
            local rx_max=$(ethtool -g "$primary_interface" 2>/dev/null | grep "RX:" | head -n 1 | awk '{print $2}')
            local tx_max=$(ethtool -g "$primary_interface" 2>/dev/null | grep "TX:" | head -n 1 | awk '{print $2}')
            
            # Set ring buffer sizes to maximum
            ethtool -G "$primary_interface" rx "$rx_max" tx "$tx_max"
            log "Optimized ring buffer sizes for $primary_interface."
        fi
    fi
    
    print_color $GREEN "Network optimization completed successfully."
}

# Function to install Timeshift
install_timeshift() {
    if ! command -v timeshift >/dev/null 2>&1; then
        print_color $YELLOW "Installing Timeshift for system snapshots..."
        
        # Install Timeshift
        case "$PACKAGE_MANAGER" in
            apt)
                # Add repository for Timeshift
                apt-add-repository -y ppa:teejee2008/ppa
                apt update
                apt install -y timeshift
                ;;
            dnf)
                dnf install -y timeshift
                ;;
            pacman)
                # Timeshift is in AUR, need to install an AUR helper first
                if ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
                    print_color $YELLOW "Installing yay AUR helper..."
                    sudo -u "$SUDO_USER" git clone https://aur.archlinux.org/yay.git /tmp/yay
                    cd /tmp/yay
                    sudo -u "$SUDO_USER" makepkg -si --noconfirm
                    cd /
                    rm -rf /tmp/yay
                fi
                
                # Install Timeshift using yay or paru
                if command -v yay >/dev/null 2>&1; then
                    sudo -u "$SUDO_USER" yay -S --noconfirm timeshift
                elif command -v paru >/dev/null 2>&1; then
                    sudo -u "$SUDO_USER" paru -S --noconfirm timeshift
                fi
                ;;
            zypper)
                zypper --non-interactive install timeshift
                ;;
        esac
        
        log "Timeshift installed successfully."
    else
        log "Timeshift is already installed."
    fi
}

# Function to create a Timeshift snapshot
create_timeshift_snapshot() {
    local snapshot_name=$1
    
    if command -v timeshift >/dev/null 2>&1; then
        log "Creating Timeshift snapshot: $snapshot_name"
        
        # Create snapshot based on filesystem type
        if [ "$ROOT_FS_TYPE" = "btrfs" ]; then
            timeshift --create --comments "$snapshot_name" --snapshot-device /
        else
            timeshift --create --comments "$snapshot_name"
        fi
        
        log "Timeshift snapshot created successfully."
    else
        print_color $RED "Error: Timeshift is not installed."
        log "Failed to create Timeshift snapshot: Timeshift not installed."
    fi
}

# Function to setup backups
setup_backups() {
    print_color $BLUE "Setting up system backups..."
    
    # Install Timeshift
    install_timeshift
    
    # Configure Timeshift based on filesystem type
    if [ "$ROOT_FS_TYPE" = "btrfs" ]; then
        print_color $YELLOW "Configuring Timeshift for BTRFS filesystem..."
        
        # Create BTRFS configuration
        backup_file "/etc/timeshift/timeshift.json"
        mkdir -p /etc/timeshift
        
        cat > /etc/timeshift/timeshift.json << EOF
{
  "backup_device_uuid": "",
  "parent_device_uuid": "",
  "do_first_run": false,
  "btrfs_mode": true,
  "btrfs_use_qgroup": true,
  "snapshot_type": "btrfs",
  "snapshot_devices": [],
  "snapshot_dir": "/timeshift-btrfs",
  "snapshot_root": "/",
  "exclude": [
    "/home/*/.cache",
    "/home/*/.local/share/Trash",
    "/var/cache",
    "/var/tmp",
    "/var/log",
    "/var/crash",
    "/proc",
    "/sys",
    "/dev",
    "/run",
    "/tmp"
  ],
  "exclude_apps": [],
  "schedule_monthly": false,
  "schedule_weekly": false,
  "schedule_daily": true,
  "schedule_hourly": false,
  "schedule_boot": false,
  "count_monthly": "2",
  "count_weekly": "3",
  "count_daily": "5",
  "count_hourly": "6",
  "count_boot": "5",
  "date_format": "%Y-%m-%d %H:%M:%S",
  "notify": true,
  "rsync_options": "-aAXHv",
  "rsync_excludes": []
}
EOF
        
        log "Configured Timeshift for BTRFS filesystem."
    else
        print_color $YELLOW "Configuring Timeshift for RSYNC mode..."
        
        # Create RSYNC configuration
        backup_file "/etc/timeshift/timeshift.json"
        mkdir -p /etc/timeshift
        
        # Find a suitable backup device
        local backup_device=""
        local backup_uuid=""
        
        # Look for a separate partition with enough space
        for device in $(lsblk -d -o NAME,SIZE -n | sort -k2 -hr | head -5 | awk '{print $1}'); do
            local mountpoint=$(lsblk -o NAME,MOUNTPOINT -n | grep "^$device " | awk '{print $2}')
            local size=$(lsblk -o NAME,SIZE -n | grep "^$device " | awk '{print $2}')
            
            if [ -n "$mountpoint" ] && [ "$mountpoint" != "/" ] && [ "$mountpoint" != "[SWAP]" ]; then
                # Check if there's enough space (at least 10GB)
                local available_space=$(df -h "$mountpoint" | awk 'NR==2 {print $4}')
                if [[ "$available_space" == *G* ]]; then
                    local gb=$(echo "$available_space" | sed 's/G//')
                    if (( $(echo "$gb >= 10" | bc -l) )); then
                        backup_device="$device"
                        backup_uuid=$(lsblk -d -o NAME,UUID -n | grep "^$device " | awk '{print $2}')
                        break
                    fi
                fi
            fi
        done
        
        if [ -z "$backup_uuid" ]; then
            print_color $YELLOW "Warning: No suitable backup device found. Using default configuration."
            backup_uuid=""
        else
            log "Found suitable backup device: $backup_device with UUID: $backup_uuid"
        fi
        
        cat > /etc/timeshift/timeshift.json << EOF
{
  "backup_device_uuid": "$backup_uuid",
  "parent_device_uuid": "",
  "do_first_run": false,
  "btrfs_mode": false,
  "btrfs_use_qgroup": false,
  "snapshot_type": "rsync",
  "snapshot_devices": [],
  "snapshot_dir": "/timeshift",
  "snapshot_root": "/",
  "exclude": [
    "/home/*/.cache",
    "/home/*/.local/share/Trash",
    "/var/cache",
    "/var/tmp",
    "/var/log",
    "/var/crash",
    "/proc",
    "/sys",
    "/dev",
    "/run",
    "/tmp"
  ],
  "exclude_apps": [],
  "schedule_monthly": false,
  "schedule_weekly": false,
  "schedule_daily": true,
  "schedule_hourly": false,
  "schedule_boot": false,
  "count_monthly": "2",
  "count_weekly": "3",
  "count_daily": "5",
  "count_hourly": "6",
  "count_boot": "5",
  "date_format": "%Y-%m-%d %H:%M:%S",
  "notify": true,
  "rsync_options": "-aAXHv",
  "rsync_excludes": []
}
EOF
        
        log "Configured Timeshift for RSYNC mode."
    fi
    
    # Create a pre-optimization snapshot
    read -p "Do you want to create a pre-optimization snapshot now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_timeshift_snapshot "Pre-Ultimate-Tuner-$(date +%Y%m%d)"
    else
        log "Skipping pre-optimization snapshot as per user request."
    fi
    
    print_color $GREEN "System backup setup completed successfully."
}

# Function to clean containers
clean_containers() {
    print_color $BLUE "Starting container cleanup..."
    
    # Check for Docker
    if command -v docker >/dev/null 2>&1; then
        print_color $YELLOW "Detected Docker installation."
        
        read -p "Do you want to prune Docker system? This will remove all unused containers, images, networks, and volumes. (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker system prune -af --volumes
            log "Docker system pruned."
            print_color $GREEN "Docker system pruned successfully."
        else
            log "Skipping Docker system prune as per user request."
        fi
        
        # List dangling volumes
        local dangling_volumes=$(docker volume ls -qf dangling=true)
        if [ -n "$dangling_volumes" ]; then
            print_color $YELLOW "Found dangling Docker volumes:"
            echo "$dangling_volumes"
            
            read -p "Do you want to remove these dangling volumes? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker volume prune -f
                log "Dangling Docker volumes removed."
                print_color $GREEN "Dangling Docker volumes removed successfully."
            else
                log "Skipping removal of dangling Docker volumes as per user request."
            fi
        else
            log "No dangling Docker volumes found."
        fi
    fi
    
    # Check for Podman
    if command -v podman >/dev/null 2>&1; then
        print_color $YELLOW "Detected Podman installation."
        
        read -p "Do you want to prune Podman system? This will remove all unused containers, images, networks, and volumes. (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            podman system prune -af --volumes
            log "Podman system pruned."
            print_color $GREEN "Podman system pruned successfully."
        else
            log "Skipping Podman system prune as per user request."
        fi
    fi
    
    print_color $GREEN "Container cleanup completed successfully."
}

# Function to optimize power management (laptops only)
optimize_power() {
    if [ "$IS_LAPTOP" = false ]; then
        print_color $YELLOW "Power management optimization is only available for laptops."
        log "Skipping power management optimization on desktop."
        return
    fi
    
    print_color $BLUE "Starting power management optimization..."
    
    # Install TLP or auto-cpufreq
    if ! command -v tlp >/dev/null 2>&1 && ! command -v auto-cpufreq >/dev/null 2>&1; then
        print_color $YELLOW "Installing power management tool..."
        
        read -p "Do you want to install TLP (1) or auto-cpufreq (2)? Enter 1 or 2: " -n 1 -r
        echo
        
        case $REPLY in
            1)
                # Install TLP
                case "$PACKAGE_MANAGER" in
                    apt)
                        apt install -y tlp tlp-rdw
                        ;;
                    dnf)
                        dnf install -y tlp tlp-rdw
                        ;;
                    pacman)
                        pacman -S --noconfirm tlp tlp-rdw
                        ;;
                    zypper)
                        zypper --non-interactive install tlp tlp-rdw
                        ;;
                esac
                
                # Enable and start TLP
                systemctl enable tlp
                systemctl start tlp
                
                log "Installed and started TLP."
                ;;
            2)
                # Install auto-cpufreq
                if ! command -v auto-cpufreq >/dev/null 2>&1; then
                    # Install dependencies
                    install_packages python3 python3-pip python3-setuptools python3-wheel
                    
                    # Install auto-cpufreq
                    pip3 install auto-cpufreq
                    
                    # Install and start the daemon
                    auto-cpufreq --install
                    
                    log "Installed and started auto-cpufreq."
                fi
                ;;
            *)
                print_color $RED "Invalid selection. Skipping power management tool installation."
                log "Invalid selection for power management tool."
                return
                ;;
        esac
    fi
    
    # Configure power management
    if command -v tlp >/dev/null 2>&1; then
        print_color $YELLOW "Configuring TLP..."
        
        # Backup TLP configuration
        backup_file "/etc/default/tlp"
        
        # Create optimized TLP configuration
        cat > /etc/default/tlp << EOF
# TLP configuration optimized by linux_ultimate_tuner.sh
# Created on $(date)

TLP_ENABLE=1
TLP_DEFAULT_MODE=AC
TLP_PERSISTENT_DEFAULT=1
DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2
MAX_LOST_WORK_SECS_ON_AC=15
MAX_LOST_WORK_SECS_ON_BAT=60
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=30
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
SCHED_POWERSAVE_ON_AC=0
SCHED_POWERSAVE_ON_BAT=1
NMI_WATCHDOG=0
ENERGY_PERF_POLICY_ON_AC=performance
ENERGY_PERF_POLICY_ON_BAT=power
DISK_DEVICES="sda sdb sdc sdd"
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
SATA_LINKPWR_ON_AC=max_performance
SATA_LINKPWR_ON_BAT=min_power
AHCI_RUNTIME_PM_ON_AC=on
AHCI_RUNTIME_PM_ON_BAT=auto
PCIE_ASPM_ON_AC=performance
PCIE_ASPM_ON_BAT=default
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
WOL_DISABLE=Y
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1
MICROPHONE_POWER_SAVE_ON_AC=0
MICROPHONE_POWER_SAVE_ON_BAT=1
BAY_POWEROFF_ON_AC=0
BAY_POWEROFF_ON_BAT=1
BAY_DEVICE="sr0"
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
RUNTIME_PM_DRIVER_BLACKLIST="radeon nouveau"
USB_AUTOSUSPEND=1
USB_BLACKLIST_BTUSB=1
USB_BLACKLIST_PHONE=1
USB_BLACKLIST_PRINTER=1
USB_BLACKLIST_WWAN=1
RESTORE_DEVICE_STATE_ON_STARTUP=0
EOF
        
        # Restart TLP to apply changes
        systemctl restart tlp
        
        log "Configured TLP for optimal power management."
    fi
    
    if command -v auto-cpufreq >/dev/null 2>&1; then
        print_color $YELLOW "Configuring auto-cpufreq..."
        
        # Backup auto-cpufreq configuration
        backup_file "/etc/auto-cpufreq.conf"
        
        # Create optimized auto-cpufreq configuration
        cat > /etc/auto-cpufreq.conf << EOF
# auto-cpufreq configuration optimized by linux_ultimate_tuner.sh
# Created on $(date)

[charger]
governor = performance
energy_perf_bias = performance
scaling_min_freq = 0
scaling_max_freq = 0
turbo = auto

[battery]
governor = powersave
energy_perf_bias = balance_power
scaling_min_freq = 0
scaling_max_freq = 70
turbo = auto
EOF
        
        # Restart auto-cpufreq to apply changes
        systemctl restart auto-cpufreq
        
        log "Configured auto-cpufreq for optimal power management."
    fi
    
    print_color $GREEN "Power management optimization completed successfully."
}

# Function to install monitoring tools
install_monitoring_tools() {
    print_color $BLUE "Installing system monitoring tools..."
    
    # Install monitoring tools
    local tools=("htop" "btop" "ncdu" "smartmontools")
    install_packages "${tools[@]}"
    
    log "Installed monitoring tools: ${tools[*]}"
    
    print_color $GREEN "Monitoring tools installed successfully."
}

# Function to generate system health report
generate_health_report() {
    print_color $BLUE "Generating system health report..."
    
    local report_file="/tmp/system_health_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "System Health Report" > "$report_file"
    echo "Generated on: $(date)" >> "$report_file"
    echo "=====================================" >> "$report_file"
    echo "" >> "$report_file"
    
    # System information
    echo "System Information:" >> "$report_file"
    echo "Distribution: $DISTRO" >> "$report_file"
    echo "Kernel: $(uname -r)" >> "$report_file"
    echo "Uptime: $(uptime -p)" >> "$report_file"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')" >> "$report_file"
    echo "" >> "$report_file"
    
    # Memory information
    echo "Memory Information:" >> "$report_file"
    free -h >> "$report_file"
    echo "" >> "$report_file"
    
    # Disk information
    echo "Disk Information:" >> "$report_file"
    df -h >> "$report_file"
    echo "" >> "$report_file"
    
    # Service status
    echo "Service Status:" >> "$report_file"
    echo "systemd-resolved: $(systemctl is-active systemd-resolved)" >> "$report_file"
    if command -v tlp >/dev/null 2>&1; then
        echo "tlp: $(systemctl is-active tlp)" >> "$report_file"
    fi
    if command -v auto-cpufreq >/dev/null 2>&1; then
        echo "auto-cpufreq: $(systemctl is-active auto-cpufreq)" >> "$report_file"
    fi
    echo "earlyoom: $(systemctl is-active earlyoom)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Failed systemd units
    echo "Failed Systemd Units:" >> "$report_file"
    systemctl --failed --no-pager >> "$report_file"
    echo "" >> "$report_file"
    
    # SMART status for primary drives
    echo "SMART Status:" >> "$report_file"
    for device in $(lsblk -d -o NAME,ROTA | grep -w "0" | head -n 1 | awk '{print "/dev/"$1}'); do
        if [ -b "$device" ]; then
            echo "SMART status for $device:" >> "$report_file"
            smartctl -H "$device" >> "$report_file" 2>/dev/null || echo "SMART not available for $device" >> "$report_file"
            echo "" >> "$report_file"
        fi
    done
    
    # Display the report
    cat "$report_file"
    
    # Save a copy to the log directory
    cp "$report_file" "$BACKUP_DIR/"
    log "System health report generated: $report_file"
    
    print_color $GREEN "System health report generated successfully."
}

# Function to run system health checks
system_health() {
    print_color $BLUE "Starting system health checks..."
    
    read -p "Do you want to install monitoring tools (htop, btop, ncdu, smartmontools)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_monitoring_tools
    else
        log "Skipping monitoring tools installation as per user request."
    fi
    
    generate_health_report
    
    print_color $GREEN "System health checks completed successfully."
}

# Function to run all optimizations
run_all_optimizations() {
    print_color $BLUE "Running all optimizations..."
    
    # Create a pre-optimization snapshot
    if command -v timeshift >/dev/null 2>&1; then
        read -p "Do you want to create a pre-optimization snapshot? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            create_timeshift_snapshot "Pre-All-Optimizations-$(date +%Y%m%d)"
        else
            log "Skipping pre-optimization snapshot as per user request."
        fi
    fi
    
    clean_disk_io
    optimize_memory
    optimize_cpu
    optimize_network
    clean_containers
    
    if [ "$IS_LAPTOP" = true ]; then
        optimize_power
    fi
    
    system_health
    
    print_color $GREEN "All optimizations completed successfully."
}

# Function to display the main menu
show_menu() {
    clear
    echo "============================================"
    echo "  Linux Ultimate Tuner v1.0"
    echo "============================================"
    echo ""
    echo "System Information:"
    echo "  Distribution: $DISTRO"
    echo "  Package Manager: $PACKAGE_MANAGER"
    echo "  Form Factor: $([ "$IS_LAPTOP" = true ] && echo "Laptop" || echo "Desktop")"
    echo "  Virtualization: $([ "$IS_VIRTUALIZED" = true ] && echo "$VIRTUALIZATION_TYPE" || echo "Bare Metal")"
    echo "  Root Filesystem: $ROOT_FS_TYPE"
    echo ""
    echo "Optimization Menu:"
    echo "  1. Disk Cleaning & I/O Optimization"
    echo "  2. Memory & Swap Optimization"
    echo "  3. CPU & Process Scheduling Optimization"
    echo "  4. Network Optimization"
    echo "  5. Backup & System Snapshots"
    echo "  6. Container & Runtime Cleanup"
    if [ "$IS_LAPTOP" = true ]; then
    echo "  7. Power Management (Laptop Only)"
    fi
    echo "  8. System Health Checks"
    echo "  9. Process Renicing Tool"
    echo " 10. Process CPU Pinning Tool"
    echo " 11. Run All Optimizations"
    echo ""
    echo "  0. Exit"
    echo ""
    echo "============================================"
    echo -n "Enter your choice [0-11]: "
}

# Main function
main() {
    check_root
    detect_system
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                clean_disk_io
                ;;
            2)
                optimize_memory
                ;;
            3)
                optimize_cpu
                ;;
            4)
                optimize_network
                ;;
            5)
                setup_backups
                ;;
            6)
                clean_containers
                ;;
            7)
                if [ "$IS_LAPTOP" = true ]; then
                    optimize_power
                else
                    print_color $RED "Invalid choice."
                fi
                ;;
            8)
                system_health
                ;;
            9)
                renice_process
                ;;
            10)
                pin_process
                ;;
            11)
                run_all_optimizations
                ;;
            0)
                print_color $GREEN "Exiting Linux Ultimate Tuner. Goodbye!"
                log "Script execution completed."
                exit 0
                ;;
            *)
                print_color $RED "Invalid choice. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run the main function
main