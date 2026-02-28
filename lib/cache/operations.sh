#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Operations Module
# ============================================================================
#
# This module provides core cache operations including the universal caching
# function, specialized caching functions, resource cleanup, and cache
# management utilities.
#
# Error Suppression Patterns (Issue #108):
# - rm -f 2>/dev/null: Cleanup of temp/stale files (may not exist)
# - find -exec rm 2>/dev/null: Batch cleanup where files may be gone
# - eval 2>/dev/null: Dynamic command execution with fallback
# - cat 2>/dev/null: Reading cache that may have been invalidated
#
# Dependencies: All other cache sub-modules, security.sh (for is_cache_fresh)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_OPERATIONS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_OPERATIONS_LOADED=true

# ============================================================================
# COMPREHENSIVE RESOURCE CLEANUP SYSTEM
# ============================================================================

# Instance-specific cleanup registry for temporary files
declare -a CACHE_TEMP_FILES=()
declare -a CACHE_CLEANUP_REGISTERED=()

# Register a temporary file for cleanup on exit
register_temp_file() {
    local temp_file="$1"
    if [[ -n "$temp_file" ]]; then
        CACHE_TEMP_FILES+=("$temp_file")
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Registered temp file for cleanup: $(basename "$temp_file")" "INFO"
    fi
}

# Comprehensive cleanup function for cache resources
cleanup_cache_resources() {
    local cleanup_count=0

    # Clean up temporary files created by this instance
    for temp_file in "${CACHE_TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file" 2>/dev/null
            if [[ ! -f "$temp_file" ]]; then
                cleanup_count=$((cleanup_count + 1))
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleaned up temp file: $(basename "$temp_file")" "INFO"
            fi
        fi
    done

    # Clean up any orphaned temporary files from this instance
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        find "$CACHE_BASE_DIR" -name "*.tmp.$$" -type f -exec rm -f {} \; 2>/dev/null
        find "$CACHE_BASE_DIR" -name "*.migrating" -type f -mmin +5 -exec rm -f {} \; 2>/dev/null
    fi

    # Release any locks held by this instance
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        find "$CACHE_BASE_DIR" -name "*.lock" -type f -exec sh -c '
            for lock in "$@"; do
                if [[ -f "$lock" ]] && grep -q "^'"$CACHE_INSTANCE_ID"':" "$lock" 2>/dev/null; then
                    rm -f "$lock" 2>/dev/null
                fi
            done
        ' _ {} + 2>/dev/null
    fi

    # Clear the temporary files registry
    CACHE_TEMP_FILES=()

    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && [[ $cleanup_count -gt 0 ]] && \
        debug_log "Cache cleanup completed: $cleanup_count files removed" "INFO"
}

# Install cleanup traps for comprehensive resource management
install_cleanup_traps() {
    # Only install traps once per instance
    local trap_marker="CACHE_CLEANUP_TRAP_${CACHE_INSTANCE_ID}"
    if [[ "${!trap_marker:-}" == "installed" ]]; then
        return 0
    fi

    # Install signal traps for comprehensive cleanup
    # EXIT: Normal script termination
    # INT: Ctrl+C (SIGINT)
    # TERM: Termination request (SIGTERM)
    # HUP: Terminal hangup (SIGHUP)
    trap 'cleanup_cache_resources' EXIT INT TERM HUP

    # Mark traps as installed for this instance
    eval "$trap_marker=installed"
    export "$trap_marker"

    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Installed cache cleanup traps for instance $CACHE_INSTANCE_ID" "INFO"
}

# ============================================================================
# UNIVERSAL COMMAND CACHING FUNCTION
# ============================================================================

# Execute command with intelligent caching
execute_cached_command() {
    local cache_key="$1"
    local cache_duration="$2"
    local validator_func="${3:-validate_basic_cache}"
    local instance_specific="${4:-true}"
    local force_refresh="${5:-false}"
    shift 5
    local command=("$@")

    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "$instance_specific")

    # Cleanup old cache files periodically
    cleanup_cache_files

    # Check if we should force refresh (first startup)
    if should_force_refresh "$force_refresh"; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Force refresh triggered for cache: $cache_key" "INFO"
    else
        # Check if cache is fresh and valid
        if is_cache_fresh "$cache_file" "$cache_duration" && "$validator_func" "$cache_file"; then
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using cached result: $cache_key" "INFO"

            # Record cache hit if statistics are enabled
            [[ "${CACHE_CONFIG_ENABLE_STATISTICS:-}" == "true" ]] && record_cache_hit "$cache_key" 0

            cat "$cache_file" 2>/dev/null
            return 0
        fi
    fi

    # Ensure cleanup traps are installed for this instance
    install_cleanup_traps

    # Acquire lock for cache update
    if acquire_cache_lock "$cache_file"; then
        local temp_file="${cache_file}.tmp.$$"
        local command_output

        # Register temporary file for cleanup
        register_temp_file "$temp_file"

        # Execute the command
        if command_output=$("${command[@]}" 2>/dev/null); then
            # Atomic write to cache
            if echo "$command_output" > "$temp_file" 2>/dev/null && mv "$temp_file" "$cache_file" 2>/dev/null; then
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cached fresh result: $cache_key" "INFO"

                # Record cache miss (successful regeneration) if statistics are enabled
                [[ "${CACHE_CONFIG_ENABLE_STATISTICS:-}" == "true" ]] && record_cache_miss "$cache_key" 0

                echo "$command_output"
                release_cache_lock "$cache_file"
                return 0
            else
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Failed to write cache file: $cache_key" "WARN"
                rm -f "$temp_file" 2>/dev/null
                echo "$command_output"
                release_cache_lock "$cache_file"
                return 0
            fi
        else
            report_cache_warning "COMMAND_EXECUTION_FAILED" \
                "Command execution failed for cache key: $cache_key" \
                "Using stale cache if available, otherwise falling back to direct execution"

            # Record cache error if statistics are enabled
            [[ "${CACHE_CONFIG_ENABLE_STATISTICS:-}" == "true" ]] && record_cache_error "$cache_key"

            # Use stale cache if available and valid
            if "$validator_func" "$cache_file"; then
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using stale cache due to command failure: $cache_key" "INFO"
                cat "$cache_file" 2>/dev/null
                release_cache_lock "$cache_file"
                return 1
            fi

            release_cache_lock "$cache_file"
            return 1
        fi
    else
        # Lock acquisition failed, try to use existing cache
        if "$validator_func" "$cache_file"; then
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using existing cache while other instance updates: $cache_key" "INFO"
            cat "$cache_file" 2>/dev/null
            return 0
        fi

        # No cache available and no lock - execute directly
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Direct execution due to lock failure: $cache_key" "INFO"
        "${command[@]}" 2>/dev/null
        return $?
    fi
}

# ============================================================================
# SPECIALIZED CACHING FUNCTIONS
# ============================================================================

# Cache command existence checks (session-wide)
cache_command_exists() {
    local command_name="$1"

    execute_cached_command \
        "cmd_exists_${command_name}" \
        "$CACHE_DURATION_SESSION" \
        "validate_basic_cache" \
        "true" \
        "false" \
        bash -c "command -v '$command_name' >/dev/null 2>&1 && echo 'true' || echo 'false'"
}

# Cache system information (permanent)
cache_system_info() {
    local info_type="$1"

    case "$info_type" in
        "os")
            execute_cached_command \
                "system_os" \
                "$CACHE_DURATION_PERMANENT" \
                "validate_system_cache" \
                "false" \
                "false" \
                uname -s
            ;;
        "arch")
            execute_cached_command \
                "system_arch" \
                "$CACHE_DURATION_PERMANENT" \
                "validate_system_cache" \
                "false" \
                "false" \
                uname -m
            ;;
        *)
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Unknown system info type: $info_type" "WARN"
            return 1
            ;;
    esac
}

# Cache git operations with appropriate durations
cache_git_operation() {
    local git_operation="$1"
    local cache_duration="$2"
    shift 2
    local git_command=("$@")

    execute_cached_command \
        "git_${git_operation}" \
        "$cache_duration" \
        "validate_git_cache" \
        "true" \
        "false" \
        "${git_command[@]}"
}

# Cache external command outputs
cache_external_command() {
    local command_name="$1"
    local cache_duration="$2"
    local validator_func="${3:-validate_command_output}"
    shift 3
    local command=("$@")

    execute_cached_command \
        "external_${command_name}" \
        "$cache_duration" \
        "$validator_func" \
        "true" \
        "false" \
        "${command[@]}"
}

# ============================================================================
# CACHE MANAGEMENT UTILITIES
# ============================================================================

# Clear all cache files
clear_all_cache() {
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        rm -rf "$CACHE_BASE_DIR"/*cache* 2>/dev/null || true
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleared all cache files" "INFO"
    fi
}

# Clear cache for specific instance
clear_instance_cache() {
    local instance_id="${1:-$CACHE_INSTANCE_ID}"

    if [[ -d "$CACHE_BASE_DIR" ]]; then
        rm -f "$CACHE_BASE_DIR"/*"_${instance_id}.cache" 2>/dev/null || true
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleared cache for instance: $instance_id" "INFO"
    fi
}

# Export functions
export -f register_temp_file cleanup_cache_resources install_cleanup_traps
export -f execute_cached_command cache_command_exists cache_system_info
export -f cache_git_operation cache_external_command
export -f clear_all_cache clear_instance_cache
