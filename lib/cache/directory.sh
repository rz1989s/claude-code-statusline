#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Directory Module
# ============================================================================
#
# This module handles XDG-compliant cache directory detection, initialization,
# and path management.
#
# Error Suppression Patterns (Issue #108):
# - mkdir -p 2>/dev/null: Race condition safe - another process may create dir
# - chmod 700 2>/dev/null: Best-effort permissions - may fail on some filesystems
# - rm -f 2>/dev/null: Cleanup ops where file may not exist (expected)
#
# All critical failures are reported via report_cache_error() or debug_log().
#
# Dependencies: config.sh (for CACHE_CONFIG_*), security.sh (for sanitize_variable_name)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_DIRECTORY_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_DIRECTORY_LOADED=true

# ============================================================================
# XDG-COMPLIANT CACHE DIRECTORY CONFIGURATION
# ============================================================================

# Determine XDG-compliant cache directory with intelligent fallback
# Priority: CLAUDE_CACHE_DIR -> XDG_CACHE_HOME -> HOME/.cache -> /tmp (secure fallback)
determine_cache_base_dir() {
    local cache_dir=""

    # Priority 1: User-specified cache directory
    if [[ -n "${CLAUDE_CACHE_DIR:-}" ]]; then
        cache_dir="$CLAUDE_CACHE_DIR"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using CLAUDE_CACHE_DIR: $cache_dir" "INFO"
    # Priority 2: XDG Base Directory specification
    elif [[ -n "${XDG_CACHE_HOME:-}" ]]; then
        cache_dir="$XDG_CACHE_HOME/claude-code-statusline"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using XDG_CACHE_HOME: $cache_dir" "INFO"
    # Priority 3: Standard user cache directory
    elif [[ -n "${HOME:-}" ]] && [[ -w "${HOME:-}" ]]; then
        cache_dir="$HOME/.cache/claude-code-statusline"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using HOME/.cache: $cache_dir" "INFO"
    # Priority 4: Secure fallback using TMPDIR with user isolation (Issue #110)
    else
        local temp_base="${TMPDIR:-/tmp}"
        cache_dir="${temp_base}/.claude_statusline_cache_${USER:-$(id -u)}"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using secure temp fallback: $cache_dir" "WARN"
    fi

    echo "$cache_dir"
}

# ============================================================================
# CACHE FILE MANAGEMENT
# ============================================================================

# Initialize cache directory structure
init_cache_directory() {
    if [[ ! -d "$CACHE_BASE_DIR" ]]; then
        if mkdir -p "$CACHE_BASE_DIR" 2>/dev/null; then
            # Set restrictive permissions (non-fatal if fails)
            if ! chmod 700 "$CACHE_BASE_DIR" 2>/dev/null; then
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Could not set permissions on $CACHE_BASE_DIR (non-fatal)" "WARN"
            fi
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Created XDG-compliant cache directory: $CACHE_BASE_DIR" "INFO"
        else
            # Attempt directory recovery
            local recovered_dir
            recovered_dir="$(recover_cache_directory "$CACHE_BASE_DIR" "primary directory creation failed")"
            if [[ -n "$recovered_dir" ]]; then
                CACHE_BASE_DIR="$recovered_dir"
                export CACHE_BASE_DIR
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache directory recovered: $CACHE_BASE_DIR" "INFO"
            else
                report_cache_error "DIRECTORY_CREATION_FAILED" \
                    "Failed to create any cache directory" \
                    "Check filesystem permissions, available space, and user access rights"
                return 1
            fi
        fi
    fi
}

# Get cache file path for a specific operation
get_cache_file_path() {
    local cache_key="$1"
    local instance_specific="${2:-true}"

    init_cache_directory

    if [[ "$instance_specific" == "true" ]]; then
        echo "$CACHE_BASE_DIR/${cache_key}_${CACHE_INSTANCE_ID}.cache"
    else
        # Shared cache (for system info that's the same across instances)
        echo "$CACHE_BASE_DIR/${cache_key}_shared.cache"
    fi
}

# Clean up old cache files and orphaned session markers
cleanup_cache_files() {
    # Remove cache files older than 24 hours
    # Note: Errors suppressed intentionally - cleanup is best-effort, cache dir may not exist
    find "$CACHE_BASE_DIR" -name "*.cache" -mtime +1 -delete 2>/dev/null || true

    # Remove orphaned session markers (where process no longer exists)
    # Uses XDG-compliant runtime directory (Issue #110)
    local runtime_dir
    if declare -f get_secure_runtime_dir >/dev/null 2>&1; then
        runtime_dir=$(get_secure_runtime_dir)
    else
        runtime_dir="$CACHE_BASE_DIR"
    fi

    for marker in "$runtime_dir"/.session_*; do
        [[ -f "$marker" ]] || continue

        local marker_pid="${marker##*_}"
        # Note: kill -0 stderr suppressed - expected to fail for non-existent processes
        if [[ "$marker_pid" =~ ^[0-9]+$ ]] && ! kill -0 "$marker_pid" 2>/dev/null; then
            # Note: rm stderr suppressed - file may already be removed by another process
            rm -f "$marker" 2>/dev/null
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Removed orphaned cache session marker: $marker_pid" "INFO"
        fi
    done
}

# ============================================================================
# STARTUP DETECTION AND SESSION MANAGEMENT
# ============================================================================

# Check if this is the first startup for this instance
is_first_startup() {
    local session_marker="$CACHE_SESSION_MARKER"

    if [[ ! -f "$session_marker" ]]; then
        # Create session marker
        echo "$(date '+%Y-%m-%d %H:%M:%S') Cache Instance: $CACHE_INSTANCE_ID PID: $PPID" > "$session_marker" 2>/dev/null
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "First startup detected for cache instance $CACHE_INSTANCE_ID" "INFO"
        return 0
    else
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Subsequent call for cache instance $CACHE_INSTANCE_ID" "INFO"
        return 1
    fi
}

# Force refresh for first startup
should_force_refresh() {
    local force_refresh="${1:-false}"

    if [[ "$force_refresh" == "true" ]]; then
        return 0
    fi

    # Force refresh on first startup
    is_first_startup
}

# Export functions
export -f determine_cache_base_dir init_cache_directory
export -f get_cache_file_path cleanup_cache_files is_first_startup should_force_refresh
