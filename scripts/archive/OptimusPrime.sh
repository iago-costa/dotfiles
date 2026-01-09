#!/usr/bin/env bash
#
# Optimus Prime: A Comprehensive Debian/Ubuntu System Optimization & Hardening Script
# Version: 1.0.0
# Author: System Administration Expert Group
#
# This script is designed to perform a series of system cleanup, performance tuning,
# and security hardening tasks on Debian and Ubuntu-based systems. It is built with
# safety, transparency, and idempotency in mind.

# --- ---
# Exit immediately if a command exits with a non-zero status.
set -o errexit
# Treat unset variables as an error when substituting.
set -o nounset
# Pipelines return the exit status of the last command to fail, not the last command.
set -o pipefail

# --- [ Global Configuration & Environment ] ---
# These variables can be overridden by exporting them in your environment.
# Example: export LOG_FILE="/path/to/custom.log"
readonly LOG_FILE="${LOG_FILE:-/var/log/optimus_prime.log}"
readonly BACKUP_DIR="${BACKUP_DIR:-/var/log/optimus_prime_backups}"
readonly NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
readonly SWAPPINESS_VALUE="${SWAPPINESS_VALUE:-10}"
readonly CPU_GOVERNOR="${CPU_GOVERNOR:-performance}"
readonly JOURNAL_VACUUM_SIZE="${JOURNAL_VACUUM_SIZE:-200M}"
readonly TMP_FILE_AGE="${TMP_FILE_AGE:-7}"
readonly VAR_TMP_FILE_AGE="${VAR_TMP_FILE_AGE:-30}"

# --- [ Color and Logging Framework ] ---
# Environment-aware logging: only use colors if stdout is a terminal.
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\e${COLOR_RESET} ${timestamp} - ${message}" | tee -a "${LOG_FILE}"
}

log_info() { log "INFO" "${COLOR_BLUE}" "$@"; }
log_success() { log "SUCCESS" "${COLOR_GREEN}" "$@"; }
log_warn() { log "WARN" "${COLOR_YELLOW}" "$@"; }
log_error() { log "ERROR" "${COLOR_RED}" "$@"; }
die() { log_error "$@"; exit 1; }

# --- ---
check_root() {
    if]; then
        die "This script must be run as root. Please use sudo."
    fi
}

check_os_compatibility() {
    local os_id=""
    local os_version=""

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        os_id=$ID
        os_version=$VERSION_ID
    elif command -v lsb_release >/dev/null 2>&1; then
        os_id=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        os_version=$(lsb_release -sr)
    else
        die "Cannot determine OS distribution and version."
    fi

    log_info "Detected OS: ${os_id} ${os_version}"

    case "${os_id}" in
        ubuntu)
            if! [[ "${os_version}" == "20.04" |

| "${os_version}" == "22.04" |
| "${os_version}" == "24.04" ]]; then
                die "Unsupported Ubuntu version: ${os_version}. Supported versions are 20.04, 22.04, 24.04."
            fi
            ;;
        debian)
            if! [[ "$(echo "${os_version}" | cut -d'.' -f1)" -ge 10 ]]; then
                die "Unsupported Debian version: ${os_version}. Supported versions are 10 (Buster) and newer."
            fi
            ;;
        *)
            die "Unsupported OS: ${os_id}. This script is for Debian and Ubuntu-based systems only."
            ;;
    esac
}

confirm() {
    if]; then
        return 0
    fi

    local prompt="$1"
    while true; do
        read -p "$(echo -e "${COLOR_YELLOW}${prompt} (y/n): ${COLOR_RESET}")" -n 1 -r reply
        echo # Move to a new line
        case "${reply}" in
           ) return 0 ;;
            [Nn]) return 1 ;;
            *) log_warn "Invalid input. Please answer 'y' or 'n'." ;;
        esac
    done
}

# --- ---
backup_file() {
    local file_path="$1"
    if [[! -f "${file_path}" ]]; then
        log_warn "File to back up does not exist: ${file_path}"
        return 1
    fi
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local backup_path="${BACKUP_DIR}/$(basename "${file_path}").${timestamp}.bak"
    
    log_info "Backing up '${file_path}' to '${backup_path}'..."
    cp -a "${file_path}" "${backup_path}" |

| die "Failed to back up ${file_path}."
    log_success "Backup created successfully."
}

# --- ---
perform_apt_cleanup() {
    log_info "Starting Advanced APT Cleanup..."
    
    if confirm "Remove orphaned packages and their configuration files? (apt autoremove --purge)"; then
        log_info "Removing unused packages and dependencies..."
        apt-get autoremove --purge -y |

| log_warn "apt autoremove failed. Continuing..."
        log_success "Orphaned packages removed."
    fi

    if confirm "Purge residual configuration files from removed packages?"; then
        log_info "Searching for packages with residual configuration files..."
        local remnant_configs
        remnant_configs=$(dpkg -l | grep '^rc' | awk '{print $2}')
        if [[ -n "${remnant_configs}" ]]; then
            log_info "Found residual configs for: ${remnant_configs}"
            # shellcheck disable=SC2086
            apt-get purge -y ${remnant_configs} |

| log_warn "Failed to purge some remnant configs."
            log_success "Residual configuration files purged."
        else
            log_info "No residual configuration files found."
        fi
    fi

    if confirm "Clear the local APT package cache? (apt clean)"; then
        log_info "Clearing APT cache..."
        apt-get clean |

| log_warn "apt clean failed."
        log_success "APT cache cleared."
    fi

    if confirm "Clear APT package list files? (will be regenerated on next 'apt update')"; then
        log_info "Removing APT list files..."
        rm -rf /var/lib/apt/lists/*
        mkdir -p /var/lib/apt/lists/partial
        log_success "APT lists cleared."
    fi
}

perform_kernel_cleanup() {
    log_info "Starting Safe Kernel Decommissioning..."
    
    local current_kernel
    current_kernel=$(uname -r)
    log_info "Current running kernel is '${current_kernel}'. It will NOT be removed."

    local installed_kernels
    installed_kernels=$(dpkg -l | grep -E 'linux-(image|headers)-[0-9]' | awk '{print $2}')
    
    # Sort kernels by version to identify the latest one
    local latest_kernel_image
    latest_kernel_image=$(echo "${installed_kernels}" | grep 'linux-image' | sort -V | tail -n 1)
    
    local kernels_to_remove=()
    for kernel in ${installed_kernels}; do
        # Protect the current kernel's image and headers
        if [[ "${kernel}" == "linux-image-${current_kernel}" |

| "${kernel}" == "linux-headers-${current_kernel}" ]]; then
            continue
        fi
        # Protect the latest kernel's image and headers
        if [[ -n "${latest_kernel_image}" && "${kernel}" == "${latest_kernel_image}" |

| "${kernel}" == "linux-headers-$(echo ${latest_kernel_image} | sed 's/linux-image-//')" ]]; then
            continue
        fi
        kernels_to_remove+=("${kernel}")
    done

    if [[ ${#kernels_to_remove[@]} -eq 0 ]]; then
        log_info "No old kernels found to remove."
        return
    fi
    
    log_warn "The following old kernel packages will be removed:"
    printf "  %s\n" "${kernels_to_remove[@]}"

    if confirm "Proceed with the removal of these ${#kernels_to_remove[@]} packages?"; then
        # shellcheck disable=SC2068
        apt-get purge -y ${kernels_to_remove[@]} |

| log_error "Failed to remove old kernels."
        log_success "Old kernels successfully removed."
        log_info "It is recommended to run 'update-grub' if it wasn't triggered automatically."
    else
        log_info "Kernel cleanup aborted by user."
    fi
}

perform_log_cleanup() {
    log_info "Starting Log and Cache Management..."

    if confirm "Prune systemd journal to a maximum size of ${JOURNAL_VACUUM_SIZE}?"; then
        log_info "Vacuuming systemd journal..."
        journalctl --vacuum-size="${JOURNAL_VACUUM_SIZE}" |

| log_warn "journalctl vacuum failed."
        log_success "Systemd journal pruned."
    fi
    
    if! grep -q -E "^SystemMaxUse=" /etc/systemd/journald.conf; then
        if confirm "Set a persistent size limit for the systemd journal in /etc/systemd/journald.conf?"; then
            backup_file "/etc/systemd/journald.conf"
            log_info "Setting 'SystemMaxUse=${JOURNAL_VACUUM_SIZE}' in journald.conf..."
            echo "SystemMaxUse=${JOURNAL_VACUUM_SIZE}" >> /etc/systemd/journald.conf
            systemctl restart systemd-journald
            log_success "Persistent journal size limit set."
        fi
    fi

    if confirm "Clean temporary files older than ${TMP_FILE_AGE} days in /tmp?"; then
        log_info "Cleaning /tmp..."
        find /tmp -type f -mtime +"${TMP_FILE_AGE}" -exec sh -c 'fuser -s "$1" |

| rm -f "$1"' sh {} \; |
| log_warn "Failed to clean some files in /tmp."
        log_success "/tmp cleaned."
    fi
    
    if confirm "Clean temporary files older than ${VAR_TMP_FILE_AGE} days in /var/tmp?"; then
        log_info "Cleaning /var/tmp..."
        find /var/tmp -type f -mtime +"${VAR_TMP_FILE_AGE}" -exec sh -c 'fuser -s "$1" |

| rm -f "$1"' sh {} \; |
| log_warn "Failed to clean some files in /var/tmp."
        log_success "/var/tmp cleaned."
    fi
}

# --- ---
tune_memory_management() {
    log_info "Starting Memory Management Tuning..."

    if confirm "Adjust vm.swappiness to ${SWAPPINESS_VALUE}? (Recommended for systems with >2GB RAM)"; then
        local sysctl_conf_file="/etc/sysctl.d/98-optimus-prime-sysctl.conf"
        log_info "Applying swappiness value and making it persistent..."
        sysctl -w vm.swappiness="${SWAPPINESS_VALUE}"
        if [[ -f "${sysctl_conf_file}" ]]; then
            sed -i '/vm.swappiness/d' "${sysctl_conf_file}"
        fi
        echo "vm.swappiness = ${SWAPPINESS_VALUE}" >> "${sysctl_conf_file}"
        log_success "Swappiness set to ${SWAPPINESS_VALUE}."
    fi

    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    if [[ ${total_mem_kb} -lt 4000000 ]]; then # Less than ~4GB RAM
        if confirm "System has low RAM. Install and configure ZRAM for compressed RAM swapping?"; then
            if! command -v zramctl >/dev/null 2>&1; then
                log_info "Installing zram-tools..."
                apt-get update && apt-get install -y zram-tools |

| die "Failed to install zram-tools."
            fi
            log_info "Configuring ZRAM with zstd compression and 50% of RAM size..."
            cat > /etc/default/zramswap <<EOF
ALGO=zstd
PERCENT=50
EOF
            systemctl restart zramswap.service
            log_success "ZRAM configured and enabled."
        fi
    fi
}

tune_cpu_performance() {
    log_info "Starting CPU Performance Tuning..."
    if! command -v cpupower >/dev/null 2>&1; then
        log_info "cpupower utility not found. Installing linux-tools-common..."
        apt-get update && apt-get install -y linux-tools-common "linux-tools-$(uname -r)" |

| die "Failed to install cpupower."
    fi
    
    local available_governors
    available_governors=$(cpupower frequency-info -g | awk 'NR==3 {print $0}')
    log_info "Available CPU governors: ${available_governors}"

    if]; then
        if confirm "Set CPU governor to '${CPU_GOVERNOR}'?"; then
            log_info "Setting CPU governor to '${CPU_GOVERNOR}'..."
            cpupower frequency-set -g "${CPU_GOVERNOR}"
            
            # Make persistent
            if [[ -f /etc/default/cpupower ]]; then
                backup_file "/etc/default/cpupower"
                sed -i "s/^governor=.*/governor='${CPU_GOVERNOR}'/" /etc/default/cpupower
            else
                echo "governor='${CPU_GOVERNOR}'" > /etc/default/cpupower
            fi
            systemctl enable cpupower.service --now >/dev/null 2>&1 |

| log_warn "Could not enable cpupower service."
            log_success "CPU governor set to '${CPU_GOVERNOR}'."
        fi
    else
        log_warn "Desired governor '${CPU_GOVERNOR}' is not available on this system. Skipping."
    fi
}

optimize_ssd() {
    log_info "Checking for SSDs and enabling TRIM..."
    local has_ssd=false
    for device in /sys/block/sd* /sys/block/nvme*n*; do
        if [[ -e "${device}/queue/rotational" ]] && [[ "$(cat "${device}/queue/rotational")" -eq 0 ]]; then
            log_info "SSD detected: $(basename "$device")"
            has_ssd=true
            break
        fi
    done

    if [[ "${has_ssd}" == "true" ]]; then
        if confirm "SSD detected. Ensure periodic TRIM is enabled via fstrim.timer?"; then
            log_info "Enabling and starting fstrim.timer..."
            systemctl enable fstrim.timer
            systemctl start fstrim.timer
            log_success "fstrim.timer enabled for periodic SSD trimming."
        fi
    else
        log_info "No SSDs detected. Skipping TRIM optimization."
    fi
}

# --- ---
harden_firewall() {
    log_info "Starting Firewall Configuration (UFW)..."
    if! command -v ufw >/dev/null 2>&1; then
        log_info "UFW not found. Installing..."
        apt-get update && apt-get install -y ufw |

| die "Failed to install UFW."
    fi
    
    if]; then
        log_warn "This script appears to be running over SSH."
        log_warn "A rule to allow SSH on port 22 will be added before enabling the firewall."
        log_warn "If your SSH port is non-standard, ABORT NOW."
    fi

    if confirm "Configure UFW with 'deny incoming', 'allow outgoing', and allow SSH?"; then
        log_info "Resetting UFW to defaults..."
        echo "y" | ufw reset
        log_info "Setting default policies..."
        ufw default deny incoming
        ufw default allow outgoing
        log_info "Allowing SSH connections..."
        ufw allow OpenSSH
        log_info "Enabling UFW..."
        echo "y" | ufw enable
        log_success "UFW has been enabled and configured."
        ufw status verbose
    fi
}

harden_ssh() {
    log_info "Starting SSH Daemon Hardening..."
    local sshd_config="/etc/ssh/sshd_config"

    if confirm "Harden SSH configuration? (Disable root login, etc.)"; then
        backup_file "${sshd_config}"
        
        log_info "Disabling root login..."
        sed -i -E 's/^[#\s]*PermitRootLogin.*/PermitRootLogin no/' "${sshd_config}"
        if! grep -q "^PermitRootLogin" "${sshd_config}"; then
            echo "PermitRootLogin no" >> "${sshd_config}"
        fi

        local user_has_key=false
        if]; then
            user_has_key=true
        fi

        if [[ "${user_has_key}" == "true" ]]; then
            if confirm "SSH key detected. Disable password authentication?"; then
                log_info "Disabling password authentication..."
                sed -i -E 's/^[#\s]*PasswordAuthentication.*/PasswordAuthentication no/' "${sshd_config}"
                if! grep -q "^PasswordAuthentication" "${sshd_config}"; then
                    echo "PasswordAuthentication no" >> "${sshd_config}"
                fi
            fi
        else
            log_warn "No SSH keys found for root or ${SUDO_USER}. Skipping password auth disablement to prevent lockout."
        fi

        log_info "Enforcing Protocol 2..."
        sed -i -E 's/^[#\s]*Protocol.*/Protocol 2/' "${sshd_config}"
        if! grep -q "^Protocol" "${sshd_config}"; then
            echo "Protocol 2" >> "${sshd_config}"
        fi

        log_info "Verifying SSH configuration syntax..."
        if sshd -t; then
            log_info "Restarting SSH service to apply changes..."
            systemctl restart sshd
            log_success "SSH daemon hardened and restarted."
        else
            die "sshd_config syntax check failed. Please review the backup and fix manually."
        fi
    fi
}

install_fail2ban() {
    log_info "Starting Intrusion Prevention Setup (Fail2Ban)..."
    if confirm "Install and configure Fail2Ban to protect SSH?"; then
        if! command -v fail2ban-client >/dev/null 2>&1; then
            log_info "Installing Fail2Ban..."
            apt-get update && apt-get install -y fail2ban |

| die "Failed to install Fail2Ban."
        fi
        
        local jail_local="/etc/fail2ban/jail.local"
        if [[! -f "${jail_local}" ]]; then
            log_info "Creating jail.local from jail.conf..."
            cp /etc/fail2ban/jail.conf "${jail_local}"
        fi
        
        log_info "Configuring SSH jail in jail.local..."
        # This ensures the [sshd] section exists and is enabled.
        if grep -q '\[sshd\]' "${jail_local}"; then
            sed -i '/^\[sshd\]/,/^\[/ s/enabled\s*=\s*false/enabled = true/' "${jail_local}"
        else
            echo -e "\n[sshd]\nenabled = true" >> "${jail_local}"
        fi
        
        log_info "Enabling and starting Fail2Ban service..."
        systemctl enable fail2ban
        systemctl start fail2ban
        log_success "Fail2Ban installed and configured for SSH protection."
    fi
}

harden_sysctl() {
    log_info "Applying Kernel-Level Security (sysctl)..."
    if confirm "Apply recommended security-focused kernel parameters?"; then
        local sysctl_conf_file="/etc/sysctl.d/98-optimus-prime-sysctl.conf"
        log_info "Creating sysctl configuration at ${sysctl_conf_file}..."
        cat > "${sysctl_conf_file}" <<EOF
# Optimus Prime Security Settings
# Protect against SYN flood attacks
net.ipv4.tcp_syncookies = 1
# Enable reverse path filtering to prevent IP spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Ignore ICMP redirects to prevent MITM attacks
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
# Ignore ICMP broadcasts to prevent smurf attacks
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Full ASLR
kernel.randomize_va_space = 2
# Restrict kernel pointer exposure
kernel.kptr_restrict = 2
EOF
        log_info "Applying new sysctl settings..."
        sysctl --system
        log_success "Kernel parameters hardened."
    fi
}

# --- ---
generate_system_snapshot() {
    log_info "--- ---"
    
    # Disk Usage
    echo -e "${COLOR_BOLD}Disk Usage:${COLOR_RESET}"
    df -h | grep -vE 'tmpfs|squashfs|udev' | sed 's/^/  /'
    echo

    # Memory Usage
    echo -e "${COLOR_BOLD}Memory Usage:${COLOR_RESET}"
    free -m | awk '/^Mem:/ {printf "  RAM: Used %sMB / Total %sMB (%.2f%%)\n", $3, $2, $3*100/$2}'
    free -m | awk '/^Swap:/ {printf "  Swap: Used %sMB / Total %sMB (%.2f%%)\n", $3, $2, $3*100/$2}'
    echo

    # CPU Load
    echo -e "${COLOR_BOLD}CPU Load Average:${COLOR_RESET}"
    uptime | awk -F'load average:' '{print "  " $2}' | sed 's/^[ \t]*//'
    echo

    # Uptime
    echo -e "${COLOR_BOLD}System Uptime:${COLOR_RESET}"
    uptime -p | sed 's/^/  /'
    echo

    # Boot Time
    if command -v systemd-analyze >/dev/null 2>&1; then
        echo -e "${COLOR_BOLD}Boot Time:${COLOR_RESET}"
        systemd-analyze | sed 's/^/  /'
        echo
    fi
    log_info "--- ---"
}

# --- [ Main Execution Logic & Menu ] ---
main_menu() {
    clear
    log_info "=================================================="
    log_info "   Optimus Prime: System Optimizer & Hardener   "
    log_info "=================================================="
    echo
    echo -e "${COLOR_BOLD}Please select an option:${COLOR_RESET}"
    echo "  1. Run ALL Optimizations (Recommended)"
    echo "  2. System Cleanup Only"
    echo "  3. Performance Tuning Only"
    echo "  4. Security Hardening Only"
    echo "  5. Generate System Health Snapshot"
    echo "  6. Exit"
    echo
    read -p "Enter your choice [1-6]: " choice

    case $choice in
        1)
            perform_apt_cleanup
            perform_kernel_cleanup
            perform_log_cleanup
            tune_memory_management
            tune_cpu_performance
            optimize_ssd
            harden_firewall
            harden_ssh
            install_fail2ban
            harden_sysctl
            log_success "All optimizations completed."
            generate_system_snapshot
            ;;
        2)
            perform_apt_cleanup
            perform_kernel_cleanup
            perform_log_cleanup
            log_success "System cleanup completed."
            ;;
        3)
            tune_memory_management
            tune_cpu_performance
            optimize_ssd
            log_success "Performance tuning completed."
            ;;
        4)
            harden_firewall
            harden_ssh
            install_fail2ban
            harden_sysctl
            log_success "Security hardening completed."
            ;;
        5)
            generate_system_snapshot
            ;;
        6)
            log_info "Exiting script."
            exit 0
            ;;
        *)
            log_warn "Invalid option. Please try again."
            sleep 2
            main_menu
            ;;
    esac
}

# --- ---
main() {
    # Initialize log file and backup directory
    touch "${LOG_FILE}" |

| die "Cannot write to log file: ${LOG_FILE}"
    mkdir -p "${BACKUP_DIR}" |

| die "Cannot create backup directory: ${BACKUP_DIR}"
    
    check_root
    check_os_compatibility

    log_info "Optimus Prime script started."
    log_info "Logging to: ${LOG_FILE}"
    log_info "Configuration backups will be stored in: ${BACKUP_DIR}"

    if]; then
        log_warn "Running in non-interactive mode. All default actions will be taken."
        perform_apt_cleanup
        perform_kernel_cleanup
        perform_log_cleanup
        tune_memory_management
        tune_cpu_performance
        optimize_ssd
        harden_firewall
        harden_ssh
        install_fail2ban
        harden_sysctl
        log_success "All non-interactive optimizations completed."
        generate_system_snapshot
    else
        main_menu
    fi

    log_info "Optimus Prime script finished."
}

# Execute main function
main "$@"
