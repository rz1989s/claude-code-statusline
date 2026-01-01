#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Tracking Module (Facade)
# ============================================================================
#
# This module handles all cost tracking and billing information using
# ccusage integration, including session costs, daily/weekly/monthly totals,
# and active billing block management.
#
# Architecture: Thin facade that sources modular sub-components
# - cost/core.sh       - Constants, session tracking, cache validation
# - cost/ccusage.sh    - ccusage availability and execution
# - cost/aggregation.sh - Date calculations, cost data retrieval
# - cost/blocks.sh     - Block processing, unified metrics
# - cost/native.sh     - Native Anthropic JSON extraction
# - cost/session.sh    - Session info, transcript parsing
# - cost/alerts.sh     - Cost threshold alerts, notifications
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

# ============================================================================
# MAIN COST INFORMATION FUNCTION
# ============================================================================

# Get comprehensive Claude usage information
# This is the main entry point for cost data
get_claude_usage_info() {
    start_timer "cost_tracking"

    # Fast mock data for testing (skips all ccusage calls)
    if [[ "${STATUSLINE_MOCK_COST_DATA:-}" == "true" ]]; then
        end_timer "cost_tracking"
        echo "0.00:0.00:0.00:0.00:No ccusage:Mock mode"
        return 0
    fi

    # Check if ccusage is available
    if ! is_ccusage_available; then
        local no_ccusage_info="-.--:-.--:-.--:-.--:$CONFIG_NO_CCUSAGE_MESSAGE:$CONFIG_CCUSAGE_INSTALL_MESSAGE"
        end_timer "cost_tracking"
        echo "$no_ccusage_info"
        return 0
    fi

    # Initialize cache
    init_cost_cache

    # Get all cost data in parallel (via caching system)
    local session_data daily_data monthly_data block_data

    debug_log "Fetching cost data..." "INFO"

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
    debug_log "Cost tracking completed in ${tracking_time}s" "INFO"

    # Return the formatted string
    echo "${session_cost}:${month_cost}:${week_cost}:${today_cost}:${block_cost_info}:${reset_info}"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the cost tracking module
init_cost_module() {
    debug_log "Cost tracking module initialized (modular architecture)" "INFO"

    # Check ccusage availability
    if ! is_ccusage_available; then
        handle_warning "ccusage not available - cost tracking disabled" "init_cost_module"
        debug_log "To enable cost tracking: npm install -g ccusage" "INFO"
        return 1
    fi

    # Initialize cache
    init_cost_cache

    # Log ccusage version for debugging (using universal caching)
    local ccusage_version
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        ccusage_version=$(cache_external_command "ccusage_version" "$CACHE_DURATION_VERY_LONG" "validate_command_output" bunx ccusage --version)
        debug_log "ccusage version: $ccusage_version (cached)" "INFO"
    else
        ccusage_version=$(bunx ccusage --version 2>/dev/null)
        debug_log "ccusage version: $ccusage_version" "INFO"
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
