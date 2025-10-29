#!/usr/bin/env bash

# nixos-optimizer.sh: A Comprehensive NixOS Maintenance and Optimization Utility
#
# Author: NixOS Power User & System Administrator
# Version: 1.0.2
#
# Description:
# This script provides a unified command-line interface for performing systematic
# cleaning, maintenance, and on-demand performance tuning for NixOS systems.
# It is designed with safety as a primary concern, incorporating dry-run modes,
# interactive confirmations, and robust error handling.

# --- Strict Mode and Error Handling ---
set -euo pipefail

# --- Global Variables and Constants ---
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="1.0.2"
readonly SYSTEM_PROFILE="/nix/var/nix/profiles/system"

# Flags and configuration variables
DRY_RUN=0
ASSUME_YES=0
VERBOSE=0
REPORT_ONLY=0
KEEP_GENERATIONS=""
DELETE_OLDER_THAN=""
GC_STANDARD=0
GC_DEEP=0
NIX_STORE_OPTIMISE=0
JOURNAL_VACUUM_TIME=""
JOURNAL_VACUUM_SIZE=""
REBUILD_BOOTLOADER=0
SET_SWAPPINESS=""
SET_GOVERNOR=""
SETUP_ZRAM=""
ZRAM_ALGO="zstd"
ZRAM_DEVICE="/dev/zram0"

declare -A PRE_RUN_STATS
declare -A POST_RUN_STATS

# --- Utility and Logging Functions ---
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BOLD='\033[1m'

log_info() { echo -e "${COLOR_BOLD}$1${COLOR_RESET}" >&2; }
log_warn() { echo -e "${COLOR_YELLOW}WARN:${COLOR_RESET} $1" >&2; }
log_error() { echo -e "${COLOR_RED}ERROR:${COLOR_RESET} $1" >&2; }
log_success() { echo -e "${COLOR_GREEN}$1${COLOR_RESET}" >&2; }
log_verbose() {
    if [[ $VERBOSE -gt 0 ]]; then
        echo -e "${COLOR_YELLOW}VERBOSE:${COLOR_RESET} $1" >&2
    fi
}

# --- Core Architectural Functions ---
usage() {
    cat << EOF
${COLOR_BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${COLOR_RESET} - A NixOS Maintenance and Optimization Utility.

${COLOR_BOLD}USAGE:${COLOR_RESET}
    sudo ./${SCRIPT_NAME} [OPTIONS]

${COLOR_BOLD}DESCRIPTION:${COLOR_RESET}
    This script provides a suite of tools for cleaning up and optimizing a NixOS system.
    Operations that require root privileges will use 'sudo' if the script is not already
    run as root. For safety, destructive operations require interactive confirmation
    unless '-y' is specified.

${COLOR_BOLD}OPTIONS:${COLOR_RESET}
    ${COLOR_BOLD}General:${COLOR_RESET}
    -h, --help                     Display this help message and exit.
    -d, --dry-run                  Show what commands would be executed without actually running them.
    -y, --yes                      Automatically answer 'yes' to all confirmation prompts.
    -v, --verbose                  Enable verbose output for debugging.
    --report-only                  Gather and display system stats without performing any actions.
    --rebuild-bootloader           After cleaning generations, run 'nixos-rebuild boot' to update boot entries.

    ${COLOR_BOLD}Cleanup:${COLOR_RESET}
    -k, --keep-generations <num>   Keep the last <num> system generations and delete older ones.
    --delete-older-than <period>   Delete system generations older than a given period (e.g., '30d', '2w').
    --gc-standard                  Run standard Nix garbage collection ('nix-collect-garbage').
    --gc-deep                      Run deep Nix garbage collection ('nix-collect-garbage -d').
                                       ${COLOR_YELLOW}WARNING:${COLOR_RESET} This removes old generations and makes rollback impossible.
    --nix-store-optimise           Run 'nix-store --optimise' to deduplicate the Nix store.
    -j, --journal-vacuum-time <p>  Vacuum systemd journal entries older than a period (e.g., '2d').
    --journal-vacuum-size <size>   Vacuum systemd journal to reduce its total size (e.g., '500M').

    ${COLOR_BOLD}Performance (Ephemeral - Not persistent across reboots):${COLOR_RESET}
    -s, --set-swappiness <0-200>   Set 'vm.swappiness' kernel parameter at runtime.
    -g, --set-governor <governor>  Set CPU governor for all cores (e.g., 'performance', 'powersave').
    -z, --setup-zram <size>        Setup a ZRAM swap device of a given size (e.g., '4G', '50%').
    --zram-algo <algo>             Compression algorithm for ZRAM (default: zstd).

${COLOR_BOLD}EXAMPLES:${COLOR_RESET}
    ${COLOR_GREEN}# Safe weekly cleanup (good for a cron job/systemd timer):${COLOR_RESET}
    sudo ./${SCRIPT_NAME} --keep-generations 10 --gc-standard --nix-store-optimise --journal-vacuum-time 14d -y

    ${COLOR_GREEN}# Aggressively reclaim disk space, with a dry run first:${COLOR_RESET}
    sudo ./${SCRIPT_NAME} -d --keep-generations 3 --gc-deep --journal-vacuum-size 200M
    sudo ./${SCRIPT_NAME} --keep-generations 3 --gc-deep --journal-vacuum-size 200M

    ${COLOR_GREEN}# Enter 'performance mode' for a demanding task:${COLOR_RESET}
    sudo ./${SCRIPT_NAME} -g performance -s 10 -z 50%
EOF
    exit 0
}

cleanup() {
    local exit_code=$?
    log_verbose "Running cleanup function with exit code ${exit_code}..."

    if [[ -n "$SETUP_ZRAM" ]] && swapon --show | grep -q "${ZRAM_DEVICE}"; then
        log_info "Tearing down ZRAM device ${ZRAM_DEVICE}..."
        run_command swapoff "${ZRAM_DEVICE}" || true
        run_command zramctl --reset "${ZRAM_DEVICE}" || true
    fi

    echo -e "${COLOR_RESET}" >&2
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with a non-zero status code: ${exit_code}."
    fi
}
trap cleanup EXIT ERR SIGINT SIGTERM

check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires root privileges for many operations. Please run with 'sudo'."
        exit 1
    fi
}

run_command() {
    local cmd_str="$*"
    log_verbose "Executing: ${cmd_str}"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${COLOR_YELLOW}DRY-RUN:${COLOR_RESET} Would execute: ${COLOR_BOLD}${cmd_str}${COLOR_RESET}" >&2
        return 0
    else
        if ! "$@" > >(while IFS= read -r line; do echo -e "  $line"; done) 2>&1; then
            log_error "Command failed: ${cmd_str}"
            return 1
        fi
    fi
    return 0
}

confirm() {
    if [[ $ASSUME_YES -eq 1 ]]; then
        log_warn "Assuming 'yes' due to --yes flag."
        return 0
    fi

    local prompt="$1"
    while true; do
        read -p "$(echo -e "${COLOR_YELLOW}CONFIRM:${COLOR_RESET} ${prompt} [y/N] ")" -r answer
        case "$answer" in
            [Yy]*) return 0;;
            [Nn]*|"") return 1;;
            *) echo "Please answer 'y' or 'n'.";;
        esac
    done
}

# --- Data Collection Functions ---
get_disk_usage() { df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}' ; }
get_nix_store_size() { du -sh /nix/store | awk '{print $1}' ; }
get_generation_count() { nix-env --profile "${SYSTEM_PROFILE}" --list-generations | wc -l ; }
get_boot_time() { systemd-analyze | head -n 1 ; }

collect_stats() {
    local -n stats_array=$1
    log_info "Collecting system statistics..."
    stats_array["disk_usage"]=$(get_disk_usage)
    stats_array["nix_store_size"]=$(get_nix_store_size)
    stats_array["generation_count"]=$(get_generation_count)
    stats_array["boot_time"]=$(get_boot_time)
}

# --- Module Functions ---
manage_generations() {
    if [[ -z "$KEEP_GENERATIONS" && -z "$DELETE_OLDER_THAN" ]]; then return 0; fi

    log_info "Managing NixOS system generations..."
    local initial_count; initial_count=$(get_generation_count)

    if [[ -n "$KEEP_GENERATIONS" ]]; then
        if ! [[ "$KEEP_GENERATIONS" =~ ^[1-9][0-9]*$ ]]; then
            log_error "Invalid number for --keep-generations: must be a positive integer."; return 1
        fi
        if confirm "This will delete all but the last ${KEEP_GENERATIONS} system generations. This action cannot be undone."; then
            log_info "Keeping the last ${KEEP_GENERATIONS} generations..."
            run_command nix-env --profile "${SYSTEM_PROFILE}" --delete-generations "+${KEEP_GENERATIONS}"
        else
            log_warn "Generation cleanup skipped by user."
        fi
    elif [[ -n "$DELETE_OLDER_THAN" ]]; then
        if confirm "This will delete system generations older than ${DELETE_OLDER_THAN}. This action cannot be undone."; then
            log_info "Deleting generations older than ${DELETE_OLDER_THAN}..."
            run_command nix-env --profile "${SYSTEM_PROFILE}" --delete-generations "${DELETE_OLDER_THAN}"
        else
            log_warn "Generation cleanup skipped by user."
        fi
    fi

    local final_count; final_count=$(get_generation_count)
    if [[ "$initial_count" != "$final_count" ]]; then
        log_success "Generations reduced from ${initial_count} to ${final_count}."
    fi
}

run_garbage_collection() {
    if [[ $GC_STANDARD -eq 0 && $GC_DEEP -eq 0 ]]; then return 0; fi

    log_info "Running Nix store garbage collection..."
    local pre_gc_size; pre_gc_size=$(get_nix_store_size)

    if [[ $GC_DEEP -eq 1 ]]; then
        log_warn "Performing DEEP garbage collection. This will delete old generations."
        if confirm "This will remove all non-current system generations, making rollback impossible. Are you sure?"; then
            run_command nix-collect-garbage -d
        else
            log_warn "Deep garbage collection skipped by user."; return 0
        fi
    elif [[ $GC_STANDARD -eq 1 ]]; then
        log_info "Performing STANDARD garbage collection..."
        run_command nix-collect-garbage
    fi

    local post_gc_size; post_gc_size=$(get_nix_store_size)
    if [[ "$pre_gc_size" != "$post_gc_size" ]]; then
        log_success "Garbage collection complete. Store size changed from ${pre_gc_size} to ${post_gc_size}."
    fi
}

optimise_nix_store() {
    if [[ $NIX_STORE_OPTIMISE -eq 0 ]]; then return 0; fi
    log_info "Optimising the Nix store by deduplicating files..."
    log_warn "This can be a long and resource-intensive process."
    run_command nix-store --optimise
    log_success "Nix store optimisation finished."
}

vacuum_journal() {
    if [[ -z "$JOURNAL_VACUUM_TIME" && -z "$JOURNAL_VACUUM_SIZE" ]]; then return 0; fi
    log_info "Vacuuming the systemd journal..."
    if [[ -n "$JOURNAL_VACUUM_TIME" ]]; then
        log_info "Removing journal entries older than ${JOURNAL_VACUUM_TIME}..."
        run_command journalctl --vacuum-time="${JOURNAL_VACUUM_TIME}"
    fi
    if [[ -n "$JOURNAL_VACUUM_SIZE" ]]; then
        log_info "Reducing journal size to ${JOURNAL_VACUUM_SIZE}..."
        run_command journalctl --vacuum-size="${JOURNAL_VACUUM_SIZE}"
    fi
    log_success "Journal vacuuming complete."
}

run_rebuild_bootloader() {
    if [[ $REBUILD_BOOTLOADER -eq 0 ]]; then return 0; fi
    log_info "Updating bootloader entries..."
    if confirm "This will run 'nixos-rebuild boot'. Do you want to proceed?"; then
        run_command nixos-rebuild boot
        log_success "Bootloader entries updated."
    else
        log_warn "Bootloader update skipped by user."
    fi
}

configure_swappiness() {
    if [[ -z "$SET_SWAPPINESS" ]]; then return 0; fi
    if ! [[ "$SET_SWAPPINESS" =~ ^[0-9]+$ ]] || [[ "$SET_SWAPPINESS" -gt 200 ]]; then
        log_error "Invalid value for swappiness: must be an integer between 0 and 200."; return 1
    fi
    log_info "Setting vm.swappiness to ${SET_SWAPPINESS}..."
    run_command sysctl -w "vm.swappiness=${SET_SWAPPINESS}"
    log_success "vm.swappiness set to ${SET_SWAPPINESS} for the current session."
}

configure_governor() {
    if [[ -z "$SET_GOVERNOR" ]]; then return 0; fi
    local available_governors; available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
    if ! [[ " $available_governors " =~ " ${SET_GOVERNOR} " ]]; then
        log_error "Governor '${SET_GOVERNOR}' is not available. Available governors: ${available_governors}"; return 1
    fi
    log_info "Setting CPU governor to '${SET_GOVERNOR}' for all cores..."
    if command -v cpupower &> /dev/null; then
        run_command cpupower frequency-set -g "${SET_GOVERNOR}"
    else
        log_warn "'cpupower' command not found. Falling back to writing to sysfs."
        if [[ $DRY_RUN -eq 1 ]]; then
            echo -e "${COLOR_YELLOW}DRY-RUN:${COLOR_RESET} Would execute: ${COLOR_BOLD}echo ${SET_GOVERNOR} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor${COLOR_RESET}" >&2
        else
            echo "${SET_GOVERNOR}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        fi
    fi
    log_success "CPU governor set to '${SET_GOVERNOR}' for the current session."
}

configure_zram() {
    if [[ -z "$SETUP_ZRAM" ]]; then return 0; fi
    log_info "Setting up ZRAM swap device..."
    run_command modprobe zram
    local zram_size
    if [[ "$SETUP_ZRAM" == *"%"* ]]; then
        local percentage=${SETUP_ZRAM%\%}
        if ! [[ "$percentage" =~ ^[0-9]+$ ]] || [[ "$percentage" -gt 100 ]] || [[ "$percentage" -eq 0 ]]; then
            log_error "Invalid ZRAM percentage. Must be between 1 and 100."; return 1
        fi
        local total_mem_kb; total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        zram_size=$(( total_mem_kb * percentage / 100 * 1024 ))
    else
        zram_size="$SETUP_ZRAM"
    fi
    log_info "Configuring ${ZRAM_DEVICE} with size ${zram_size} and algorithm ${ZRAM_ALGO}..."
    run_command zramctl --reset "${ZRAM_DEVICE}"
    run_command zramctl --find --size "${zram_size}" --algorithm "${ZRAM_ALGO}"
    run_command mkswap "${ZRAM_DEVICE}"
    run_command swapon "${ZRAM_DEVICE}" -p 100
    log_success "ZRAM swap device ${ZRAM_DEVICE} is active."
    if [[ $VERBOSE -gt 0 ]]; then swapon --show; fi
}

# --- Main Execution Logic ---
main() {
    # Parse command-line arguments using getopts.
    local OPTSTRING=":hdyvk:j:s:g:z:-:"
    while getopts "$OPTSTRING" opt; do
        # Handle long options
        if [ "$opt" = "-" ]; then
            # FIX: This block is updated to handle both --option=value and --option value
            case "${OPTARG}" in
                help) usage ;;
                dry-run) DRY_RUN=1 ;;
                yes) ASSUME_YES=1 ;;
                verbose) VERBOSE=1 ;;
                report-only) REPORT_ONLY=1 ;;
                rebuild-bootloader) REBUILD_BOOTLOADER=1 ;;
                gc-standard) GC_STANDARD=1 ;;
                gc-deep) GC_DEEP=1 ;;
                nix-store-optimise) NIX_STORE_OPTIMISE=1 ;;

                # Options with arguments: handle both space and equals separator
                keep-generations|delete-older-than|journal-vacuum-time|journal-vacuum-size|set-swappiness|set-governor|setup-zram|zram-algo)
                    # This handles '--option value'
                    if [[ ! -v "OPTIND" ]] || [[ "${!OPTIND:-}" =~ ^- ]]; then
                        log_error "Option --${OPTARG} requires an argument."; usage
                    fi
                    val="${!OPTIND}"; OPTIND=$((OPTIND+1))
                    case "$OPTARG" in
                        keep-generations) KEEP_GENERATIONS="$val" ;;
                        delete-older-than) DELETE_OLDER_THAN="$val" ;;
                        journal-vacuum-time) JOURNAL_VACUUM_TIME="$val" ;;
                        journal-vacuum-size) JOURNAL_VACUUM_SIZE="$val" ;;
                        set-swappiness) SET_SWAPPINESS="$val" ;;
                        set-governor) SET_GOVERNOR="$val" ;;
                        setup-zram) SETUP_ZRAM="$val" ;;
                        zram-algo) ZRAM_ALGO="$val" ;;
                    esac
                    ;;
                keep-generations=*|delete-older-than=*|journal-vacuum-time=*|journal-vacuum-size=*|set-swappiness=*|set-governor=*|setup-zram=*|zram-algo=*)
                    # This handles '--option=value'
                    key="${OPTARG%%=*}"; val="${OPTARG#*=}"
                    case "$key" in
                        keep-generations) KEEP_GENERATIONS="$val" ;;
                        delete-older-than) DELETE_OLDER_THAN="$val" ;;
                        journal-vacuum-time) JOURNAL_VACUUM_TIME="$val" ;;
                        journal-vacuum-size) JOURNAL_VACUUM_SIZE="$val" ;;
                        set-swappiness) SET_SWAPPINESS="$val" ;;
                        set-governor) SET_GOVERNOR="$val" ;;
                        setup-zram) SETUP_ZRAM="$val" ;;
                        zram-algo) ZRAM_ALGO="$val" ;;
                    esac
                    ;;

                *) log_error "Invalid long option --${OPTARG}"; usage ;;
            esac
        else
            case "$opt" in
                h) usage ;;
                d) DRY_RUN=1 ;;
                y) ASSUME_YES=1 ;;
                v) VERBOSE=$((VERBOSE + 1)) ;;
                k) KEEP_GENERATIONS="$OPTARG" ;;
                j) JOURNAL_VACUUM_TIME="$OPTARG" ;;
                s) SET_SWAPPINESS="$OPTARG" ;;
                g) SET_GOVERNOR="$OPTARG" ;;
                z) SETUP_ZRAM="$OPTARG" ;;
                \?) log_error "Invalid option: -$OPTARG"; usage ;;
                :) log_error "Option -$OPTARG requires an argument."; usage ;;
            esac
        fi
    done
    shift $((OPTIND - 1))

    check_privileges
    log_info "Starting NixOS Optimizer v${SCRIPT_VERSION}..."
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "DRY RUN MODE ENABLED. No changes will be made to the system."
    fi

    collect_stats PRE_RUN_STATS

    if [[ $REPORT_ONLY -eq 1 ]]; then
        log_info "Report-only mode enabled. Skipping all actions."
    else
        configure_swappiness
        configure_governor
        configure_zram
        manage_generations
        run_garbage_collection
        optimise_nix_store
        vacuum_journal
        run_rebuild_bootloader
    fi

    collect_stats POST_RUN_STATS

    log_info "Generating summary report..."
    echo -e "--------------------------------------------------"
    echo -e "${COLOR_BOLD}NixOS Optimizer Summary Report${COLOR_RESET}"
    echo -e "--------------------------------------------------"
    printf "%-25s | %-25s | %-25s\n" "Metric" "Before" "After"
    echo -e "--------------------------------------------------"
    printf "%-25s | %-25s | %-25s\n" "Root Disk Usage" "${PRE_RUN_STATS[disk_usage]}" "${POST_RUN_STATS[disk_usage]}"
    printf "%-25s | %-25s | %-25s\n" "/nix/store Size" "${PRE_RUN_STATS[nix_store_size]}" "${POST_RUN_STATS[nix_store_size]}"
    printf "%-25s | %-25s | %-25s\n" "System Generations" "${PRE_RUN_STATS[generation_count]}" "${POST_RUN_STATS[generation_count]}"
    printf "%-25s | %-25s | %-25s\n" "Boot Time" "${PRE_RUN_STATS[boot_time]}" "${POST_RUN_STATS[boot_time]}"
    echo -e "--------------------------------------------------"

    log_success "Optimization script finished successfully."
}

main "$@"
