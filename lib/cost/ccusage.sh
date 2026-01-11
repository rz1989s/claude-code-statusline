#!/bin/bash

# ============================================================================
# Claude Code Statusline - ccusage Integration Module
# ============================================================================
#
# Handles ccusage availability checking and command execution with caching.
# Split from cost.sh as part of Issue #132.
#
# Dependencies: core.sh, cost/core.sh, cache.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_CCUSAGE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_CCUSAGE_LOADED=true

# ============================================================================
# CCUSAGE AVAILABILITY CHECKING
# ============================================================================

# Check if ccusage is available via bunx
is_ccusage_available() {
    if ! command_exists bunx; then
        debug_log "bunx not available for ccusage" "INFO"
        return 1
    fi

    # Use universal caching for ccusage availability check (6-hour cache)
    local ccusage_check_result
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        ccusage_check_result=$(cache_external_command "ccusage_availability" "$CACHE_DURATION_VERY_LONG" "validate_command_output" bash -c 'bunx ccusage --version >/dev/null 2>&1 && echo "available" || echo "unavailable"')
        if [[ "$ccusage_check_result" == "available" ]]; then
            debug_log "ccusage available via bunx (cached)" "INFO"
            return 0
        else
            debug_log "ccusage not available via bunx (cached)" "INFO"
            return 1
        fi
    else
        # Fallback to direct execution
        if bunx ccusage --version >/dev/null 2>&1; then
            debug_log "ccusage available via bunx" "INFO"
            return 0
        else
            debug_log "ccusage not available via bunx" "INFO"
            return 1
        fi
    fi
}

# ============================================================================
# CCUSAGE EXECUTION WITH CACHING
# ============================================================================

# Enhanced ccusage execution with intelligent caching and startup detection
execute_ccusage_with_cache() {
    local cache_file="$1"
    local ccusage_command="$2"
    local cache_duration="$3"
    local timeout_duration="${4:-$CONFIG_CCUSAGE_TIMEOUT}"

    # Startup detection: Force refresh all data on first Claude Code startup
    cleanup_old_session_markers

    local force_refresh=false
    local session_marker instance_id
    session_marker=$(get_session_marker)
    instance_id=$(get_instance_id)

    if [[ ! -f "$session_marker" ]]; then
        force_refresh=true
        echo "$(date '+%Y-%m-%d %H:%M:%S') Instance: $instance_id PID: $PPID" > "$session_marker" 2>/dev/null
        debug_log "First startup for Claude Code instance $instance_id - forcing refresh of all ccusage data" "INFO"
    else
        debug_log "Subsequent call for instance $instance_id - using intelligent cache durations" "INFO"
    fi

    # Check if cache is fresh and valid (skip if force refresh)
    if [[ "$force_refresh" != "true" ]] && [[ -f "$cache_file" ]] && is_cache_fresh "$cache_file" "$cache_duration"; then
        if validate_cache_file "$cache_file"; then
            cat "$cache_file" 2>/dev/null
            debug_log "Using cached ccusage data: $(basename "$cache_file")" "INFO"
            return 0
        else
            debug_log "Cache file corrupted, forcing refresh: $(basename "$cache_file")" "WARN"
            rm -f "$cache_file" 2>/dev/null
        fi
    fi

    local lock_file="${cache_file}.lock"

    # Clean up stale locks
    cleanup_stale_locks "$lock_file"

    # Enhanced lock acquisition with retry logic
    local max_retries=3
    local retry_count=0
    local lock_acquired=false

    while [[ $retry_count -lt $max_retries ]]; do
        if (
            set -C
            echo "$$:$(date +%s):$CLAUDE_INSTANCE_ID" >"$lock_file" 2>/dev/null
        ); then
            lock_acquired=true
            break
        else
            retry_count=$((retry_count + 1))
            debug_log "Lock acquisition attempt $retry_count/$max_retries failed: $(basename "$cache_file")" "INFO"
            sleep "0.$(( (RANDOM % 5) + 1 ))"
        fi
    done

    if [[ "$lock_acquired" == "true" ]]; then
        debug_log "Acquired lock for ccusage: $(basename "$cache_file")" "INFO"

        # Execute ccusage command
        local fresh_data
        if command_exists timeout; then
            fresh_data=$(timeout "$timeout_duration" bunx ccusage $ccusage_command --json 2>/dev/null)
        elif command_exists gtimeout; then
            fresh_data=$(gtimeout "$timeout_duration" bunx ccusage $ccusage_command --json 2>/dev/null)
        else
            fresh_data=$(bunx ccusage $ccusage_command --json 2>/dev/null)
        fi

        # Cache the result if successful using atomic write
        if [[ $? -eq 0 && -n "$fresh_data" ]]; then
            local temp_file="${cache_file}.tmp.$$"
            if echo "$fresh_data" > "$temp_file" 2>/dev/null && mv "$temp_file" "$cache_file" 2>/dev/null; then
                debug_log "Cached fresh ccusage data: $(basename "$cache_file")" "INFO"
                echo "$fresh_data"
            else
                debug_log "Failed to write cache file: $(basename "$cache_file")" "WARN"
                rm -f "$temp_file" 2>/dev/null
                echo "$fresh_data"
            fi
        else
            debug_log "Failed to get fresh ccusage data: $(basename "$cache_file")" "WARN"
            if [[ -f "$cache_file" ]]; then
                cat "$cache_file" 2>/dev/null
            fi
        fi

        rm -f "$lock_file" 2>/dev/null
    else
        debug_log "Lock acquisition failed after $max_retries attempts: $(basename "$cache_file")" "WARN"
        if [[ -f "$cache_file" ]] && validate_cache_file "$cache_file"; then
            debug_log "Using existing cache while other instance refreshes: $(basename "$cache_file")" "INFO"
            cat "$cache_file" 2>/dev/null
        fi
    fi
}

# Export functions
export -f is_ccusage_available execute_ccusage_with_cache
