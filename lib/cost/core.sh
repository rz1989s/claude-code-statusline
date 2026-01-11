#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Core Module
# ============================================================================
#
# Core constants, session tracking, and cache validation for cost tracking.
# Split from cost.sh as part of Issue #132.
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_CORE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_CORE_LOADED=true

# ============================================================================
# COST TRACKING CONSTANTS
# ============================================================================

# CRITICAL FIX: Set date format defaults immediately to fix DAY $0.00 bug
[[ -z "$CONFIG_DATE_FORMAT" ]] && export CONFIG_DATE_FORMAT="%Y-%m-%d"
[[ -z "$CONFIG_DATE_FORMAT_COMPACT" ]] && export CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"

# Cache settings for cost data - differentiated by data type
export COST_CACHE_DURATION_LIVE=30        # 30 seconds - active blocks (real-time)
export COST_CACHE_DURATION_SESSION=120    # 2 minutes - repository session cost
export COST_CACHE_DURATION_DAILY=60       # 1 minute - today's cost
export COST_CACHE_DURATION_WEEKLY=3600    # 1 hour - 7-day total
export COST_CACHE_DURATION_MONTHLY=7200   # 2 hours - 30-day total

# Use the proper XDG-compliant cache directory from cache.sh module (Issue #110)
export COST_CACHE_DIR="${CACHE_BASE_DIR:-${HOME:-/tmp}/.cache/claude-code-statusline}"

# Cache file names
export BLOCKS_CACHE_FILE="$COST_CACHE_DIR/blocks.json"
export SESSION_CACHE_FILE="$COST_CACHE_DIR/session.json"
export DAILY_CACHE_FILE="$COST_CACHE_DIR/daily_7d.json"
export MONTHLY_CACHE_FILE="$COST_CACHE_DIR/monthly_30d.json"

# Default cost values
export DEFAULT_COST="0.00"

# ============================================================================
# INSTANCE AND SESSION TRACKING
# ============================================================================

# Function to get current instance ID dynamically
get_instance_id() {
    # Priority: CLAUDE_INSTANCE_ID env var > PPID > current PID
    echo "${CLAUDE_INSTANCE_ID:-${PPID:-$$}}"
}

# Function to get the current session marker path
get_session_marker() {
    local instance_id
    instance_id=$(get_instance_id)

    # Use get_session_marker_path from security.sh if available
    if declare -f get_session_marker_path >/dev/null 2>&1; then
        get_session_marker_path "$instance_id"
    else
        # Fallback to cache directory if security module not loaded
        echo "${CACHE_BASE_DIR:-${HOME:-/tmp}/.cache/claude-code-statusline}/session_${instance_id}"
    fi
}

# Cleanup old session markers (older than 24 hours) and orphaned markers
cleanup_old_session_markers() {
    # Use cleanup_runtime_session_markers from security.sh if available
    if declare -f cleanup_runtime_session_markers >/dev/null 2>&1; then
        cleanup_runtime_session_markers
        return
    fi

    # Fallback: Clean up in cache directory
    local runtime_dir="${CACHE_BASE_DIR:-${HOME:-/tmp}/.cache/claude-code-statusline}"
    [[ -d "$runtime_dir" ]] || return 0

    # Remove old markers (older than 24 hours)
    find "$runtime_dir" -name "session_*" -mtime +1 -delete 2>/dev/null || true

    # Remove orphaned markers (where the parent process no longer exists)
    local marker
    for marker in "$runtime_dir"/session_*; do
        [[ -f "$marker" ]] || continue
        local marker_pid="${marker##*_}"
        if [[ "$marker_pid" =~ ^[0-9]+$ ]] && ! kill -0 "$marker_pid" 2>/dev/null; then
            rm -f "$marker" 2>/dev/null
            debug_log "Removed orphaned session marker for dead process: $marker_pid" "INFO"
        fi
    done
}

# ============================================================================
# CACHE VALIDATION
# ============================================================================

# Validate cache file integrity (check if it contains valid JSON)
validate_cache_file() {
    local cache_file="$1"

    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    # Check if file is not empty and contains valid JSON
    if [[ -s "$cache_file" ]] && jq empty "$cache_file" 2>/dev/null; then
        return 0
    else
        debug_log "Invalid cache file detected: $(basename "$cache_file")" "WARN"
        return 1
    fi
}

# Initialize cost cache directory
init_cost_cache() {
    if [[ ! -d "$COST_CACHE_DIR" ]]; then
        mkdir -p "$COST_CACHE_DIR" 2>/dev/null
        chmod 700 "$COST_CACHE_DIR" 2>/dev/null
        debug_log "Created cost cache directory: $COST_CACHE_DIR" "INFO"
    fi
}

# Clear cost cache
clear_cost_cache() {
    rm -f "$BLOCKS_CACHE_FILE" "$SESSION_CACHE_FILE" "$DAILY_CACHE_FILE" "$MONTHLY_CACHE_FILE" 2>/dev/null
    debug_log "Cleared cost cache files" "INFO"
}

# Export functions
export -f get_instance_id get_session_marker cleanup_old_session_markers
export -f validate_cache_file init_cost_cache clear_cost_cache
