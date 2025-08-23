#!/bin/bash

# ============================================================================
# Claude Code Statusline - Core Module
# ============================================================================
# 
# This module contains core constants, shared utilities, and foundational
# functions that other modules depend on.
#
# Dependencies: None (this is the base module)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CORE_LOADED=true

# ============================================================================
# CORE CONSTANTS
# ============================================================================

# Version information
export STATUSLINE_VERSION="2.0.0-refactored"
export STATUSLINE_COMPATIBILITY_VERSION="1.3.0"

# Module loading status
export STATUSLINE_MODULES_LOADED=()
export STATUSLINE_MODULES_FAILED=()

# Default timeouts (can be overridden by configuration)
export DEFAULT_MCP_TIMEOUT="10s"
export DEFAULT_VERSION_TIMEOUT="2s"
export DEFAULT_CCUSAGE_TIMEOUT="3s"

# Default cache settings
export DEFAULT_VERSION_CACHE_DURATION=3600
export DEFAULT_VERSION_CACHE_FILE="/tmp/.claude_version_cache"

# Common patterns for validation
export VALID_TIMEOUT_PATTERN='^[0-9]+[sm]?$'
export VALID_ANSI_COLOR_PATTERN='\\033\[[0-9;]+m$'

# ============================================================================
# CORE UTILITY FUNCTIONS  
# ============================================================================

# Module loading system
load_module() {
    local module_name="$1"
    local module_path="${BASH_SOURCE[0]%/*}/${module_name}.sh"
    local required="${2:-true}"
    
    # Check if already loaded
    if [[ " ${STATUSLINE_MODULES_LOADED[@]} " =~ " ${module_name} " ]]; then
        return 0
    fi
    
    # Check if module file exists
    if [[ ! -f "$module_path" ]]; then
        if [[ "$required" == "true" ]]; then
            echo "ERROR: Required module not found: $module_name at $module_path" >&2
            return 1
        else
            echo "WARNING: Optional module not found: $module_name" >&2
            return 1
        fi
    fi
    
    # Source the module
    if source "$module_path"; then
        STATUSLINE_MODULES_LOADED+=("$module_name")
        return 0
    else
        STATUSLINE_MODULES_FAILED+=("$module_name")
        if [[ "$required" == "true" ]]; then
            echo "ERROR: Failed to load required module: $module_name" >&2
            return 1
        else
            echo "WARNING: Failed to load optional module: $module_name" >&2
            return 1
        fi
    fi
}

# Check if a module is loaded
# Usage: is_module_loaded "module_name"
# Returns: 0 if module is loaded, 1 if not loaded
is_module_loaded() {
    local module_name="$1"
    [[ " ${STATUSLINE_MODULES_LOADED[@]} " =~ " ${module_name} " ]]
}

# Get the directory containing the statusline script
# Resolves symlinks and returns the actual directory path
# Usage: script_dir=$(get_script_dir)
# Returns: String path to script directory
get_script_dir() {
    local script_path="${BASH_SOURCE[0]}"
    # Follow symlinks to find the real script location
    while [[ -L "$script_path" ]]; do
        script_path=$(readlink "$script_path")
    done
    dirname "$(cd "$(dirname "$script_path")" && pwd)"
}

# Safe echo with error handling
safe_echo() {
    local message="$1"
    local target="${2:-stdout}"
    
    case "$target" in
        "stderr")
            echo "$message" >&2
            ;;
        "stdout"|*)
            echo "$message"
            ;;
    esac
}

# Check if a command exists and is executable
command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

# Get current timestamp in seconds
get_timestamp() {
    date +%s
}

# Check if a value is numeric
is_numeric() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
}

# Check if a value is a valid boolean
is_boolean() {
    local value="$1"
    [[ "$value" == "true" || "$value" == "false" ]]
}

# Safe string comparison that handles empty values
safe_compare() {
    local val1="${1:-}"
    local val2="${2:-}"
    [[ "$val1" == "$val2" ]]
}

# Create a temporary directory with proper permissions
create_temp_dir() {
    local prefix="${1:-statusline}"
    local temp_dir
    
    if temp_dir=$(mktemp -d -t "${prefix}.XXXXXX" 2>/dev/null); then
        chmod 700 "$temp_dir"
        echo "$temp_dir"
        return 0
    else
        echo "ERROR: Failed to create temporary directory" >&2
        return 1
    fi
}

# Cleanup function for temporary resources
cleanup_temp_resources() {
    local temp_dir="$1"
    [[ -n "$temp_dir" && -d "$temp_dir" ]] && rm -rf "$temp_dir" 2>/dev/null
}

# Debug logging function (respects debug configuration)
debug_log() {
    local message="$1"
    local level="${2:-INFO}"
    
    # Only log if debug mode is enabled (will be set by config module)
    if [[ "${STATUSLINE_DEBUG_MODE:-false}" == "true" ]]; then
        echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
    fi
}

# Performance timing utilities
start_timer() {
    local timer_name="$1"
    local timer_var="STATUSLINE_TIMER_$(echo "$timer_name" | tr '[:lower:]' '[:upper:]')"
    export "$timer_var"=$(get_timestamp)
}

end_timer() {
    local timer_name="$1"
    local start_var="STATUSLINE_TIMER_$(echo "$timer_name" | tr '[:lower:]' '[:upper:]')"
    local start_time="${!start_var:-}"
    
    if [[ -n "$start_time" ]]; then
        local end_time=$(get_timestamp)
        local duration=$((end_time - start_time))
        debug_log "Timer $timer_name: ${duration}s" "PERF"
        echo "$duration"
    else
        debug_log "Timer $timer_name was not started" "WARN"
        echo "0"
    fi
}

# Error handling with context
handle_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    local context="${3:-unknown}"
    
    safe_echo "ERROR in $context: $error_msg" "stderr"
    debug_log "Error in $context: $error_msg (code: $error_code)" "ERROR"
    return "$error_code"
}

# Warning handling
handle_warning() {
    local warning_msg="$1"
    local context="${2:-unknown}"
    
    safe_echo "WARNING in $context: $warning_msg" "stderr"
    debug_log "Warning in $context: $warning_msg" "WARN"
}

# Module initialization
init_core_module() {
    debug_log "Core module initialized (version: $STATUSLINE_VERSION)" "INFO"
    
    # Set up signal handlers for cleanup
    trap 'cleanup_on_exit' EXIT
    trap 'cleanup_on_signal SIGINT' INT
    trap 'cleanup_on_signal SIGTERM' TERM
    
    return 0
}

# Cleanup functions
cleanup_on_exit() {
    debug_log "Performing cleanup on exit" "INFO"
    # Cleanup will be handled by individual modules
}

cleanup_on_signal() {
    local signal="$1"
    debug_log "Received signal $signal, cleaning up" "INFO"
    exit 0
}

# Initialize the core module
init_core_module

# Export core functions for use by other modules
export -f load_module is_module_loaded get_script_dir safe_echo command_exists
export -f get_timestamp is_numeric is_boolean safe_compare
export -f create_temp_dir cleanup_temp_resources debug_log
export -f start_timer end_timer handle_error handle_warning