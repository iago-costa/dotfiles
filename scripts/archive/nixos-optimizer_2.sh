#!/usr/bin/env bash

# nixos-optimizer.sh: A Comprehensive NixOS Maintenance and Optimization Utility
#
# Author: NixOS Power User & System Administrator
# Version: 1.0.1
#
# Description:
# This script provides a unified command-line interface for performing systematic
# cleaning, maintenance, and on-demand performance tuning for NixOS systems.
# It is designed with safety as a primary concern, incorporating dry-run modes,
# interactive confirmations, and robust error handling.

# --- Strict Mode and Error Handling ---
# set -e: Exit immediately if a command exits with a non-zero status.
# set -u: Treat unset variables as an error when substituting.
# set -o pipefail: The return value of a pipeline is the status of the last
# command to exit with a non-zero status, or zero if no command exited
# with a non-zero status. This is crucial for catching errors in pipelines.
set -euo pipefail

# --- Global Variables and Constants ---

# Script metadata
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="1.0.1"

# NixOS specific paths
readonly SYSTEM_PROFILE="/nix/var/nix/profiles/system"

# Flags and configuration variables set by getopts
DRY_RUN=0
ASSUME_YES=0
VERBOSE=0
REPORT_ONLY=0

# Cleanup options
KEEP_GENERATIONS=""
DELETE_OLDER_THAN=""
GC_STANDARD=0
GC_DEEP=0
NIX_STORE_OPTIMISE=0
JOURNAL_VACUUM_TIME=""
JOURNAL_VACUUM_SIZE=""
REBUILD_BOOTLOADER=0

# Performance options
SET_SWAPPINESS=""
SET_GOVERNOR=""
SETUP_ZRAM=""
ZRAM_ALGO="zstd"
ZRAM_DEVICE="/dev/zram0"

# Reporting variables
declare -A PRE_RUN_STATS
declare -A POST_RUN_STATS

# --- Utility and Logging Functions ---

# FIX: Correctly defined color constants.
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BOLD='\033[1m'

# FIX: Correctly defined logging functions to echo colored output.
log_info() {
    echo -e "${COLOR_BOLD}$1${COLOR_RESET}" >&2
}

log_warn() {
    echo -e "${COLOR_YELLOW}WARN:${COLOR_RESET} $1" >&2
}

log_error() {
    echo -e "${COLOR_RED}ERROR:${COLOR_RESET} $1" >&2
}

log_success() {
    echo -e "${COLOR_GREEN}$1${COLOR_RESET}" >&2
}

log_verbose() {
    # FIX: Corrected the conditional test for the VERBOSE flag.
    if [[ $VERBOSE -gt 0 ]]; then
        echo -e "${COLOR_YELLOW}VERBOSE:${COLOR_RESET} $1" >&2
    fi
}

# --- Core Architectural Functions ---

# Function to display usage information.
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

# A trap function to ensure cleanup on script exit, error, or interruption.
# This is critical for tearing down temporary resources like ZRAM.
cleanup() {
    local exit_code=$?
    log_verbose "Running cleanup function with exit code ${exit_code}..."

    # FIX: Corrected conditional check for ZRAM teardown.
    # Check if a ZRAM device was supposed to be set up by this script's invocation.
    if [[ -n "$SETUP_ZRAM" ]] && swapon --show | grep -q "${ZRAM_DEVICE}"; then
        log_info "Tearing down ZRAM device ${ZRAM_DEVICE}..."
        # FIX: Removed invalid '||' piping. run_command already handles errors.
        # Adding '|| true' to prevent the trap from exiting on a non-critical cleanup error.
        run_command swapoff "${ZRAM_DEVICE}" || true
        run_command zramctl --reset "${ZRAM_DEVICE}" || true
    fi

    echo -e "${COLOR_RESET}" >&2 # Reset terminal colors
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with a non-zero status code: ${exit_code}."
    fi
    # No explicit exit here to allow the original exit code to propagate
}
trap cleanup EXIT ERR SIGINT SIGTERM

# Function to check for root privileges (EUID 0).
check_privileges() {
    # FIX: Corrected the syntax for the numeric test.
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires root privileges for many operations. Please run with 'sudo'."
        exit 1
    fi
}

# A wrapper for executing commands that respects DRY_RUN mode.
run_command() {
    local cmd_str="$*"
    log_verbose "Executing: ${cmd_str}"
    # FIX: Corrected the conditional test.
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${COLOR_YELLOW}DRY-RUN:${COLOR_RESET} Would execute: ${COLOR_BOLD}${cmd_str}${COLOR_RESET}" >&2
        return 0
    else
        # Execute the command. Redirect stderr to stdout to capture all output.
        # Then pipe to a while loop to process line-by-line for logging.
        # This prevents buffering issues and provides real-time output.
        # FIX: Corrected 'if!' to 'if !'.
        if ! "$@" > >(while IFS= read -r line; do echo -e "  $line"; done) 2>&1; then
            log_error "Command failed: ${cmd_str}"
            return 1
        fi
    fi
    return 0
}

# Function to prompt for user confirmation.
confirm() {
    # FIX: Corrected conditional test.
    if [[ $ASSUME_YES -eq 1 ]]; then
        log_warn "Assuming 'yes' due to --yes flag."
        return 0
    fi

    local prompt="$1"
    while true; do
        read -p "$(echo -e "${COLOR_YELLOW}CONFIRM:${COLOR_RESET} ${prompt} [y/N] ")" -r answer
        # FIX: Corrected the case statement logic to properly handle 'y' vs 'n'.
        case "$answer" in
            [Yy]*) return 0;;
            [Nn]*|"") return 1;;
            *) echo "Please answer 'y' or 'n'.";;
        esac
    done
}

# --- Data Collection Functions for Reporting ---

get_disk_usage() {
    df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'
}

get_nix_store_size() {
    du -sh /nix/store | awk '{print $1}'
}

get_generation_count() {
    # It's crucial to target the system profile explicitly.
    nix-env --profile "${SYSTEM_PROFILE}" --list-generations | wc -l
}

get_boot_time() {
    systemd-analyze | head -n 1
}

collect_stats() {
    local -n stats_array=$1 # Use nameref to write to the specified array
    log_info "Collecting system statistics..."
    stats_array["disk_usage"]=$(get_disk_usage)
    stats_array["nix_store_size"]=$(get_nix_store_size)
    stats_array["generation_count"]=$(get_generation_count)
    stats_array["boot_time"]=$(get_boot_time)
}

# --- Cleanup Module Functions ---

# Manages system generations based on user-defined policies.
manage_generations() {
    # FIX: Corrected logic to only run if one of the relevant options is provided.
    if [[ -z "$KEEP_GENERATIONS" && -z "$DELETE_OLDER_THAN" ]]; then
        return 0
    fi

    log_info "Managing NixOS system generations..."
    local initial_count
    initial_count=$(get_generation_count)

    # FIX: Corrected conditional tests for variable presence and validity.
    if [[ -n "$KEEP_GENERATIONS" ]]; then
        if ! [[ "$KEEP_GENERATIONS" =~ ^[1-9][0-9]*$ ]]; then
            log_error "Invalid number for --keep-generations: must be a positive integer."
            return 1
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

    local final_count
    final_count=$(get_generation_count)
    # FIX: Ensure a change occurred before logging success.
    if [[ "$initial_count" != "$final_count" ]]; then
        log_success "Generations reduced from ${initial_count} to ${final_count}."
    fi
}

# Performs Nix store garbage collection.
run_garbage_collection() {
    # FIX: Corrected conditional check.
    if [[ $GC_STANDARD -eq 0 && $GC_DEEP -eq 0 ]]; then
        return 0
    fi

    log_info "Running Nix store garbage collection..."
    local pre_gc_size
    pre_gc_size=$(get_nix_store_size)

    # FIX: Corrected conditional checks.
    if [[ $GC_DEEP -eq 1 ]]; then
        log_warn "Performing DEEP garbage collection. This will delete old generations."
        if confirm "This will remove all non-current system generations, making rollback impossible. Are you sure?"; then
            run_command nix-collect-garbage -d
        else
            log_warn "Deep garbage collection skipped by user."
            return 0
        fi
    elif [[ $GC_STANDARD -eq 1 ]]; then
        log_info "Performing STANDARD garbage collection..."
        run_command nix-collect-garbage
    fi

    local post_gc_size
    post_gc_size=$(get_nix_store_size)
    if [[ "$pre_gc_size" != "$post_gc_size" ]]; then
        log_success "Garbage collection complete. Store size changed from ${pre_gc_size} to ${post_gc_size}."
    fi
}

# Deduplicates files in the Nix store.
optimise_nix_store() {
    # FIX: Corrected conditional check.
    if [[ $NIX_STORE_OPTIMISE -eq 0 ]]; then
        return 0
    fi
    log_info "Optimising the Nix store by deduplicating files..."
    log_warn "This can be a long and resource-intensive process."
    run_command nix-store --optimise
    log_success "Nix store optimisation finished."
}

# Vacuums the systemd journal.
vacuum_journal() {
    # FIX: Corrected logic to ensure at least one option is present.
    if [[ -z "$JOURNAL_VACUUM_TIME" && -z "$JOURNAL_VACUUM_SIZE" ]]; then
        return 0
    fi

    log_info "Vacuuming the systemd journal..."
    # FIX: Corrected conditional tests.
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

# Updates bootloader entries.
run_rebuild_bootloader() {
    # FIX: Corrected conditional check.
    if [[ $REBUILD_BOOTLOADER -eq 0 ]]; then
        return 0
    fi
    log_info "Updating bootloader entries..."
    if confirm "This will run 'nixos-rebuild boot'. Do you want to proceed?"; then
        run_command nixos-rebuild boot
        log_success "Bootloader entries updated."
    else
        log_warn "Bootloader update skipped by user."
    fi
}

# --- Performance Module Functions ---

# Sets the vm.swappiness kernel parameter at runtime.
configure_swappiness() {
    # FIX: Corrected conditional check.
    if [[ -z "$SET_SWAPPINESS" ]]; then
        return 0
    fi
    # FIX: Corrected validation logic for swappiness value.
    if ! [[ "$SET_SWAPPINESS" =~ ^[0-9]+$ ]] || [[ "$SET_SWAPPINESS" -gt 200 ]]; then
        log_error "Invalid value for swappiness: must be an integer between 0 and 200."
        return 1
    fi

    log_info "Setting vm.swappiness to ${SET_SWAPPINESS}..."
    run_command sysctl -w "vm.swappiness=${SET_SWAPPINESS}"
    log_success "vm.swappiness set to ${SET_SWAPPINESS} for the current session."
}

# Sets the CPU frequency scaling governor for all cores.
configure_governor() {
    # FIX: Corrected conditional check.
    if [[ -z "$SET_GOVERNOR" ]]; then
        return 0
    fi

    local available_governors
    available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
    # FIX: Corrected the check to see if the chosen governor is available.
    if ! [[ " $available_governors " =~ " ${SET_GOVERNOR} " ]]; then
        log_error "Governor '${SET_GOVERNOR}' is not available. Available governors: ${available_governors}"
        return 1
    fi

    log_info "Setting CPU governor to '${SET_GOVERNOR}' for all cores..."
    if command -v cpupower &> /dev/null; then
        run_command cpupower frequency-set -g "${SET_GOVERNOR}"
    else
        log_warn "'cpupower' command not found. Falling back to writing to sysfs."
        # FIX: Corrected the dry-run check and tee command execution.
        if [[ $DRY_RUN -eq 1 ]]; then
            echo -e "${COLOR_YELLOW}DRY-RUN:${COLOR_RESET} Would execute: ${COLOR_BOLD}echo ${SET_GOVERNOR} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor${COLOR_RESET}" >&2
        else
            echo "${SET_GOVERNOR}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        fi
    fi
    log_success "CPU governor set to '${SET_GOVERNOR}' for the current session."
}

# Configures a ZRAM swap device.
configure_zram() {
    # FIX: Corrected conditional check.
    if [[ -z "$SETUP_ZRAM" ]]; then
        return 0
    fi

    log_info "Setting up ZRAM swap device..."
    run_command modprobe zram

    local zram_size
    if [[ "$SETUP_ZRAM" == *"%"* ]]; then
        local percentage
        percentage=${SETUP_ZRAM%\%}
        # FIX: Corrected the multi-line conditional syntax.
        if ! [[ "$percentage" =~ ^[0-9]+$ ]] || [[ "$percentage" -gt 100 ]] || [[ "$percentage" -eq 0 ]]; then
            log_error "Invalid ZRAM percentage. Must be between 1 and 100."
            return 1
        fi
        local total_mem_kb
        total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
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
    if [[ $VERBOSE -gt 0 ]]; then
        swapon --show
    fi
}

# --- Main Execution Logic ---

main() {
    # Parse command-line arguments using getopts.
    # The leading colon in the optstring enables silent error handling.
    # Added support for long options.
    local OPTSTRING=":hdyvk:j:s:g:z:-:"
    while getopts "$OPTSTRING" opt; do
        # Handle long options
        if [ "$opt" = "-" ]; then
            case "${OPTARG}" in
                help) usage ;;
                dry-run) DRY_RUN=1 ;;
                yes) ASSUME_YES=1 ;;
                verbose) VERBOSE=1 ;;
                report-only) REPORT_ONLY=1 ;;
                rebuild-bootloader) REBUILD_BOOTLOADER=1 ;;
                keep-generations=*) KEEP_GENERATIONS="${OPTARG#*=}" ;;
                delete-older-than=*) DELETE_OLDER_THAN="${OPTARG#*=}" ;;
                gc-standard) GC_STANDARD=1 ;;
                gc-deep) GC_DEEP=1 ;;
                nix-store-optimise) NIX_STORE_OPTIMISE=1 ;;
                journal-vacuum-time=*) JOURNAL_VACUUM_TIME="${OPTARG#*=}" ;;
                journal-vacuum-size=*) JOURNAL_VACUUM_SIZE="${OPTARG#*=}" ;;
                set-swappiness=*) SET_SWAPPINESS="${OPTARG#*=}" ;;
                set-governor=*) SET_GOVERNOR="${OPTARG#*=}" ;;
                setup-zram=*) SETUP_ZRAM="${OPTARG#*=}" ;;
                zram-algo=*) ZRAM_ALGO="${OPTARG#*=}" ;;
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

    # --- Pre-run Checks and Setup ---
    check_privileges
    log_info "Starting NixOS Optimizer v${SCRIPT_VERSION}..."
    # FIX: Corrected conditional test.
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "DRY RUN MODE ENABLED. No changes will be made to the system."
    fi

    collect_stats PRE_RUN_STATS

    # FIX: Corrected conditional test.
    if [[ $REPORT_ONLY -eq 1 ]]; then
        log_info "Report-only mode enabled. Skipping all actions."
    else
        # --- Execute Modules in Logical Order ---
        configure_swappiness
        configure_governor
        configure_zram

        manage_generations
        run_garbage_collection
        optimise_nix_store
        vacuum_journal
        run_rebuild_bootloader
    fi

    # --- Post-run Reporting ---
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

# Entry point of the script
main "$@"
