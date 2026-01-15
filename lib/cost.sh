#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Tracking Module (Facade)
# ============================================================================
#
# This module handles all cost tracking and billing information.
# Primary: Native JSONL calculation (no external dependencies)
# Fallback: ccusage integration (deprecated)
#
# Architecture: Thin facade that sources modular sub-components
# - cost/core.sh        - Constants, session tracking, cache validation
# - cost/api_live.sh    - Pricing lookup, API-synced LIVE calculation
# - cost/native_calc.sh - Native JSONL cost calculation (all periods)
# - cost/ccusage.sh     - ccusage availability (deprecated fallback)
# - cost/aggregation.sh - Date calculations, cost data retrieval
# - cost/blocks.sh      - Block processing, unified metrics
# - cost/native.sh      - Native Anthropic JSON extraction
# - cost/session.sh     - Session info, transcript parsing
# - cost/alerts.sh      - Cost threshold alerts, notifications
#
# Error Suppression Patterns (Issue #76):
# - jq empty 2>/dev/null: JSON validation where invalid data returns fallback
# - date -d/-r 2>/dev/null: Cross-platform date (GNU -d vs BSD -r)
# - bunx ccusage 2>/dev/null: External tool may not be installed
# - printf "%.2f" 2>/dev/null: Numeric formatting with fallback on invalid input
# - kill -0 2>/dev/null: Process existence check (expected to fail for dead PIDs)
# - rm/mkdir/chmod 2>/dev/null: Best-effort filesystem ops (race conditions)
#
# Dependencies: core.sh, security.sh, cache.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_LOADED=true

# ============================================================================
# SOURCE SUB-MODULES
# ============================================================================

# Get the directory containing this script
COST_LIB_DIR="${BASH_SOURCE[0]%/*}"

# Source sub-modules in dependency order
# shellcheck source=cost/core.sh
source "${COST_LIB_DIR}/cost/core.sh" 2>/dev/null || {
    debug_log "Failed to load cost/core.sh" "ERROR"
    return 1
}

# shellcheck source=cost/ccusage.sh
source "${COST_LIB_DIR}/cost/ccusage.sh" 2>/dev/null || {
    debug_log "Failed to load cost/ccusage.sh" "ERROR"
    return 1
}

# shellcheck source=cost/aggregation.sh
source "${COST_LIB_DIR}/cost/aggregation.sh" 2>/dev/null || {
    debug_log "Failed to load cost/aggregation.sh" "ERROR"
    return 1
}

# shellcheck source=cost/blocks.sh
source "${COST_LIB_DIR}/cost/blocks.sh" 2>/dev/null || {
    debug_log "Failed to load cost/blocks.sh" "ERROR"
    return 1
}

# shellcheck source=cost/native.sh
source "${COST_LIB_DIR}/cost/native.sh" 2>/dev/null || {
    debug_log "Failed to load cost/native.sh" "ERROR"
    return 1
}

# shellcheck source=cost/session.sh
source "${COST_LIB_DIR}/cost/session.sh" 2>/dev/null || {
    debug_log "Failed to load cost/session.sh" "ERROR"
    return 1
}

# shellcheck source=cost/alerts.sh
source "${COST_LIB_DIR}/cost/alerts.sh" 2>/dev/null || {
    debug_log "Failed to load cost/alerts.sh" "ERROR"
    return 1
}

# shellcheck source=cost/api_live.sh
source "${COST_LIB_DIR}/cost/api_live.sh" 2>/dev/null || {
    debug_log "Failed to load cost/api_live.sh (optional)" "WARN"
    # Not fatal - API-synced LIVE is optional enhancement
}

# shellcheck source=cost/native_calc.sh
source "${COST_LIB_DIR}/cost/native_calc.sh" 2>/dev/null || {
    debug_log "Failed to load cost/native_calc.sh (optional)" "WARN"
    # Not fatal - will fallback to ccusage
}

# ============================================================================
# FILE-BASED CACHE FOR STATUSLINE RENDER (Issue #147)
# ============================================================================
# Cache result of get_claude_usage_info() to avoid redundant calls
# Multiple components call this function - cache ensures single execution
# Uses file cache because bash subshells don't share variables

_COST_RENDER_CACHE_FILE="${TMPDIR:-/tmp}/.statusline_cost_render_$$"

# ============================================================================
# MAIN COST INFORMATION FUNCTION
# ============================================================================

# Get comprehensive Claude usage information
# This is the main entry point for cost data
# Performance: Caches result per statusline render (Issue #147)
# Strategy: Native JSONL calculation (primary) → ccusage (fallback)
get_claude_usage_info() {
    # Fast path: Return cached result if file exists and is fresh (<30 seconds old)
    # This eliminates 6 redundant calls (~12s saved)
    # 30s TTL ensures cache covers entire statusline render cycle
    if [[ -f "$_COST_RENDER_CACHE_FILE" ]]; then
        local cache_age
        local cache_mtime
        cache_mtime=$(stat -f "%m" "$_COST_RENDER_CACHE_FILE" 2>/dev/null || stat -c "%Y" "$_COST_RENDER_CACHE_FILE" 2>/dev/null)
        cache_age=$(( $(date +%s) - cache_mtime ))
        if [[ $cache_age -lt 30 ]]; then
            debug_log "Cost data returned from render cache (fast path, age=${cache_age}s)" "DEBUG"
            cat "$_COST_RENDER_CACHE_FILE"
            return 0
        fi
    fi

    start_timer "cost_tracking"

    # Fast mock data for testing
    if [[ "${STATUSLINE_MOCK_COST_DATA:-}" == "true" ]]; then
        end_timer "cost_tracking"
        local result="0.00:0.00:0.00:0.00:No data:Mock mode"
        echo "$result" > "$_COST_RENDER_CACHE_FILE"
        echo "$result"
        return 0
    fi

    local result=""

    # =========================================================================
    # PRIMARY: Native JSONL calculation (no external dependencies)
    # =========================================================================
    if declare -f get_cached_native_usage_info &>/dev/null; then
        debug_log "Using native JSONL cost calculation (primary)" "INFO"

        local current_dir="${STATUSLINE_WORKING_DIR:-$(pwd)}"
        result=$(get_cached_native_usage_info "$current_dir")

        if [[ -n "$result" && "$result" != *"-.--"* ]]; then
            local tracking_time
            tracking_time=$(end_timer "cost_tracking")
            debug_log "Native cost tracking completed in ${tracking_time}s" "INFO"
            echo "$result" > "$_COST_RENDER_CACHE_FILE"
            echo "$result"
            return 0
        fi

        debug_log "Native calculation returned empty/invalid, trying ccusage fallback" "WARN"
    fi

    # =========================================================================
    # FALLBACK: ccusage-based calculation (deprecated)
    # =========================================================================
    if ! is_ccusage_available; then
        local result="-.--:-.--:-.--:-.--:${CONFIG_NO_CCUSAGE_MESSAGE:-No data}:Native calc unavailable"
        echo "$result" > "$_COST_RENDER_CACHE_FILE"
        end_timer "cost_tracking"
        echo "$result"
        return 0
    fi

    debug_log "Using ccusage for cost calculation (fallback)" "INFO"

    # Initialize cache
    init_cost_cache

    # Get all cost data via ccusage
    local session_data daily_data monthly_data block_data

    session_data=$(get_session_cost_data)
    daily_data=$(get_daily_cost_data)
    monthly_data=$(get_monthly_cost_data)
    block_data=$(get_active_blocks_data)

    # Process costs
    local session_cost today_cost week_cost month_cost

    session_cost=$(extract_session_cost "$session_data")
    today_cost=$(extract_today_cost "$daily_data")
    week_cost=$(extract_weekly_cost "$daily_data" "$today_cost")
    month_cost=$(extract_monthly_cost "$monthly_data")

    # Process active block info
    local block_info
    block_info=$(process_active_blocks "$block_data")
    local block_cost_info="${block_info%:*}"
    local reset_info="${block_info#*:}"

    local tracking_time
    tracking_time=$(end_timer "cost_tracking")
    debug_log "ccusage cost tracking completed in ${tracking_time}s" "INFO"

    # Cache and return the formatted string
    result="${session_cost}:${month_cost}:${week_cost}:${today_cost}:${block_cost_info}:${reset_info}"
    echo "$result" > "$_COST_RENDER_CACHE_FILE"
    echo "$result"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the cost tracking module
init_cost_module() {
    debug_log "Cost tracking module initialized (native primary, ccusage fallback)" "INFO"

    # Check native calculation availability (primary)
    if declare -f get_native_usage_info &>/dev/null; then
        debug_log "Native JSONL cost calculation available (primary)" "INFO"
    else
        debug_log "Native cost calculation not loaded" "WARN"
    fi

    # Check ccusage availability (fallback)
    if is_ccusage_available; then
        debug_log "ccusage available as fallback" "INFO"
        # Initialize cache for ccusage fallback
        init_cost_cache

        # Log ccusage version for debugging
        if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
            local ccusage_version
            ccusage_version=$(cache_external_command "ccusage_version" "$CACHE_DURATION_VERY_LONG" "validate_command_output" bunx ccusage --version)
            debug_log "ccusage version: $ccusage_version (cached)" "INFO"
        fi
    else
        debug_log "ccusage not available - using native calculation only" "INFO"
    fi

    return 0
}

# Initialize the module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_cost_module
fi

# ============================================================================
# EXPORTS (for backward compatibility)
# ============================================================================

# Main entry point
export -f get_claude_usage_info init_cost_module
