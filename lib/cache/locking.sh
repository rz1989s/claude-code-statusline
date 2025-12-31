#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Locking Module
# ============================================================================
#
# This module provides file locking for cache concurrency control including
# lock acquisition with retry logic and release mechanisms.
#
# Error Suppression Patterns (Issue #108):
# - rm -f 2>/dev/null: Lock cleanup where file may already be released
# - kill -0 2>/dev/null: Check if lock holder PID exists (expected to fail)
# - echo > lockfile 2>/dev/null: Lock creation (race condition handling)
#
# Dependencies: config.sh (for CACHE_CONFIG_MAX_LOCK_RETRIES), integrity.sh (for report_cache_warning)
#               security.sh (for cleanup_stale_locks)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_LOCKING_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_LOCKING_LOADED=true

# ============================================================================
# ENHANCED LOCKING SYSTEM
# ============================================================================

# Acquire cache lock with retry logic
acquire_cache_lock() {
    local cache_file="$1"
    local max_retries="${2:-${CACHE_CONFIG_MAX_LOCK_RETRIES:-10}}"
    local lock_file="${cache_file}.lock"

    cleanup_stale_locks "$lock_file"

    local retry_count=0
    while [[ $retry_count -lt $max_retries ]]; do
        # Additional aggressive cleanup right before lock attempt
        [[ -f "$lock_file" ]] && rm -f "$lock_file" 2>/dev/null

        # Try to acquire lock atomically
        if (
            set -C
            echo "$CACHE_INSTANCE_ID:$$:$(date +%s)" >"$lock_file" 2>/dev/null
        ); then
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Acquired cache lock: $(basename "$cache_file")" "INFO"
            return 0
        else
            retry_count=$((retry_count + 1))
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache lock attempt $retry_count/$max_retries failed: $(basename "$cache_file")" "INFO"

            # Random backoff to prevent thundering herd
            sleep "0.$(( (RANDOM % 5) + 1 ))"
        fi
    done

    report_cache_warning "LOCK_ACQUISITION_FAILED" \
        "Failed to acquire cache lock after $max_retries attempts: $(basename "$cache_file")" \
        "High cache contention or stale locks - consider increasing max_lock_retries or clearing stale locks"
    return 1
}

# Release cache lock
release_cache_lock() {
    local cache_file="$1"
    local lock_file="${cache_file}.lock"
    rm -f "$lock_file" 2>/dev/null
}

# Export functions
export -f acquire_cache_lock release_cache_lock
