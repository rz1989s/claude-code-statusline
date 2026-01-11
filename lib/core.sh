#!/bin/bash

# ============================================================================
# Claude Code Statusline - Core Module
# ============================================================================
#
# This module contains core constants, shared utilities, and foundational
# functions that other modules depend on.
#
# Error Suppression Patterns (Issue #108):
# - command -v 2>/dev/null: Check if command exists (expected to fail if not)
# - rm -rf temp_dir 2>/dev/null: Cleanup temp directories (may not exist)
# - type -t 2>/dev/null: Check function/command type (expected to fail)
#
# Dependencies: None (this is the base module)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CORE_LOADED=true

# ============================================================================
# STRICT MODE / FAIL-FAST BEHAVIOR
# ============================================================================
# Enable strict mode for robust error handling across all modules.
# - set -e: Exit immediately if a command exits with non-zero status
# - set -o pipefail: Pipeline fails if any command in it fails
#
# Note: We intentionally omit -u (nounset) because this codebase uses
# associative arrays with dynamic keys for caching, which triggers false
# positives when checking if a key exists.
#
# Usage: Call enable_strict_mode early in the main script (statusline.sh)
# ============================================================================

enable_strict_mode() {
    # Skip strict mode in testing environment to allow test assertions to work (Issue #62)
    [[ "${STATUSLINE_TESTING:-}" == "true" ]] && return 0

    set -eo pipefail

    # Set up ERR trap to provide better error context
    trap '_strict_mode_error_handler $? "${BASH_SOURCE[0]}" "${LINENO}" "${FUNCNAME[0]:-main}"' ERR
}

# Internal error handler for strict mode
_strict_mode_error_handler() {
    local exit_code="$1"
    local source_file="$2"
    local line_number="$3"
    local func_name="$4"

    # Only log if debug mode is enabled to avoid noise
    if [[ "${STATUSLINE_DEBUG:-false}" == "true" ]]; then
        echo "[ERR] Command failed (exit $exit_code) at ${source_file}:${line_number} in ${func_name}" >&2
    fi

    # Don't exit - let the normal error handling continue
    # The trap is for debugging, not for changing behavior
    return 0
}

# Disable strict mode (for sections that need lenient error handling)
disable_strict_mode() {
    set +eo pipefail
    trap - ERR
}

# Export strict mode functions
export -f enable_strict_mode disable_strict_mode _strict_mode_error_handler

# ============================================================================
# CORE CONSTANTS
# ============================================================================

# Ultra-simple version reading - No hardcoded versions!
get_statusline_version() {
    # Primary: User's local version file (installed by install.sh)
    local user_version_file="$HOME/.claude/statusline/version.txt"
    if [[ -f "$user_version_file" ]]; then
        local version=$(cat "$user_version_file" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Fallback: Repository version.txt (for developers)
    local script_dir="${BASH_SOURCE[0]%/*}"
    local repo_version_file="${script_dir}/../version.txt"
    if [[ -f "$repo_version_file" ]]; then
        local version=$(cat "$repo_version_file" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    # No hardcoded fallback - clear error message
    echo "VERSION_ERROR"
    return 1
}

# Version information - Single Source of Truth
export STATUSLINE_VERSION=$(get_statusline_version)
export STATUSLINE_ARCHITECTURE_VERSION="2.0.0-refactored" 
export STATUSLINE_COMPATIBILITY_VERSION="1.3.0"

# Module loading status
export STATUSLINE_MODULES_LOADED=()
export STATUSLINE_MODULES_FAILED=()

# Default timeouts (can be overridden by configuration)
export DEFAULT_MCP_TIMEOUT="10s"
export DEFAULT_VERSION_TIMEOUT="10s"
export DEFAULT_CCUSAGE_TIMEOUT="10s"

# Default cache settings
export DEFAULT_VERSION_CACHE_DURATION=3600
# Note: Version cache file location determined dynamically by cache module
# Uses XDG-compliant CACHE_BASE_DIR (see lib/cache/directory.sh)

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
    local link_count=0
    local max_links=10  # Prevent infinite symlink loops
    
    # Follow symlinks to find the real script location with loop protection
    while [[ -L "$script_path" ]] && [[ $link_count -lt $max_links ]]; do
        script_path=$(readlink "$script_path")
        link_count=$((link_count + 1))
    done
    
    # Warn if we hit the symlink limit
    if [[ $link_count -ge $max_links ]]; then
        handle_warning "Too many symlinks detected, using current path: $script_path" "get_script_dir"
    fi
    
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

# Check if a command exists and is executable (with intelligent caching)
command_exists() {
    local cmd="$1"
    
    # Validate input
    if [[ -z "$cmd" ]]; then
        debug_log "Empty command name provided to command_exists" "WARN"
        return 1
    fi
    
    # Use cached result if cache module is available
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local result
        result=$(cache_command_exists "$cmd")
        [[ "$result" == "true" ]]
    else
        # Fallback to direct check if cache not available
        command -v "$cmd" >/dev/null 2>&1
    fi
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

# Check if debug mode is enabled (standardized helper - Issue #78)
# Usage: if is_debug_mode; then echo "debug info"; fi
is_debug_mode() {
    [[ "${STATUSLINE_DEBUG:-false}" == "true" ]]
}

# Check if JSON log format is enabled (Issue #73)
# Usage: STATUSLINE_LOG_FORMAT=json STATUSLINE_DEBUG=true ./statusline.sh
is_json_log_format() {
    [[ "${STATUSLINE_LOG_FORMAT:-text}" == "json" ]]
}

# Debug logging function (respects debug configuration)
# Supports text (default) and JSON structured output (Issue #73)
debug_log() {
    local message="$1"
    local level="${2:-INFO}"

    # Only log if debug mode is enabled
    if ! is_debug_mode; then
        return 0
    fi

    if is_json_log_format; then
        # JSON structured output for log aggregation systems
        local timestamp
        timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

        # Escape special characters in message for valid JSON
        local escaped_msg
        escaped_msg=$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g')

        echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$escaped_msg\"}" >&2
    else
        # Default text format (unchanged)
        echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') $message" >&2
    fi
}

# Performance timing utilities
start_timer() {
    local timer_name="$1"
    local timer_var="STATUSLINE_TIMER_$(echo "$timer_name" | tr '[:lower:]' '[:upper:]')"
    local timestamp=$(get_timestamp)
    
    # Validate timestamp is numeric before export
    if [[ "$timestamp" =~ ^[0-9]+$ ]]; then
        export "$timer_var"="$timestamp"
    else
        debug_log "Invalid timestamp from get_timestamp: $timestamp" "ERROR"
        # Fallback to direct date call
        export "$timer_var"="$(date +%s)"
    fi
}

end_timer() {
    local timer_name="$1"
    local start_var="STATUSLINE_TIMER_$(echo "$timer_name" | tr '[:lower:]' '[:upper:]')"
    local start_time
    
    # Use nameref for safe variable indirection (bash 4.3+)
    # This avoids eval which can be a security concern
    if [[ -n "${!start_var:-}" ]]; then
        start_time="${!start_var}"
    else
        start_time=""
    fi
    
    if [[ -n "$start_time" ]] && [[ "$start_time" =~ ^[0-9]+$ ]]; then
        local end_time=$(get_timestamp)
        
        # Validate end_time is also numeric
        if [[ "$end_time" =~ ^[0-9]+$ ]]; then
            local duration=$((end_time - start_time))
            debug_log "Timer $timer_name: ${duration}s" "PERF"
            echo "$duration"
        else
            debug_log "Invalid end timestamp from get_timestamp: $end_time" "ERROR"
            echo "0"
        fi
    else
        if [[ -n "$start_time" ]]; then
            debug_log "Timer $timer_name has invalid start time: $start_time" "WARN"
        else
            debug_log "Timer $timer_name was not started" "WARN"
        fi
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

# Initialize the core module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_core_module
fi

# Export core functions for use by other modules
export -f load_module is_module_loaded get_script_dir safe_echo command_exists
export -f get_timestamp is_numeric is_boolean safe_compare
export -f create_temp_dir cleanup_temp_resources debug_log is_debug_mode
export -f start_timer end_timer handle_error handle_warning