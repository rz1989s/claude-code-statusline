#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Tracking Module (Facade)
# ============================================================================
#
# This module handles all cost tracking and billing information.
# 100% Native: JSONL calculation (no external dependencies)
#
# Architecture: Thin facade that sources modular sub-components
# - cost/core.sh        - Constants, session tracking, cache validation
# - cost/api_live.sh    - Pricing lookup, API-synced LIVE calculation, block metrics
# - cost/native_calc.sh - Native JSONL cost calculation (all periods)
# - cost/native.sh      - Native Anthropic JSON extraction
# - cost/session.sh     - Session info, transcript parsing
# - cost/alerts.sh      - Cost threshold alerts, notifications
#
# Error Suppression Patterns (Issue #76):
# - jq empty 2>/dev/null: JSON validation where invalid data returns fallback
# - date -d/-r 2>/dev/null: Cross-platform date (GNU -d vs BSD -r)
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

# shellcheck source=cost/api_live.sh
source "${COST_LIB_DIR}/cost/api_live.sh" 2>/dev/null || {
    debug_log "Failed to load cost/api_live.sh" "ERROR"
    return 1
}

# shellcheck source=cost/native_calc.sh
source "${COST_LIB_DIR}/cost/native_calc.sh" 2>/dev/null || {
    debug_log "Failed to load cost/native_calc.sh" "ERROR"
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

# shellcheck source=cost/report_calc.sh
source "${COST_LIB_DIR}/cost/report_calc.sh" 2>/dev/null || {
    debug_log "Failed to load cost/report_calc.sh - report breakdowns disabled" "WARN"
}

# shellcheck source=cost/commit_attribution.sh
source "${COST_LIB_DIR}/cost/commit_attribution.sh" 2>/dev/null || {
    debug_log "Failed to load cost/commit_attribution.sh - commit cost attribution disabled" "WARN"
}

# shellcheck source=cost/mcp_attribution.sh
source "${COST_LIB_DIR}/cost/mcp_attribution.sh" 2>/dev/null || {
    debug_log "Failed to load cost/mcp_attribution.sh - MCP cost attribution disabled" "WARN"
}

# shellcheck source=cost/recommendations.sh
source "${COST_LIB_DIR}/cost/recommendations.sh" 2>/dev/null || {
    debug_log "Failed to load cost/recommendations.sh - cost recommendations disabled" "WARN"
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
# Strategy: 100% Native JSONL calculation
get_claude_usage_info() {
    # Fast path: Return cached result if file exists and is fresh (<30 seconds old)
    # This eliminates redundant calls
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
    # Native JSONL calculation (100% native, no external dependencies)
    # =========================================================================
    if declare -f get_cached_native_usage_info &>/dev/null; then
        debug_log "Using native JSONL cost calculation" "INFO"

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

        debug_log "Native calculation returned empty/invalid" "WARN"
    fi

    # Return empty result if native calculation not available
    result="-.--:-.--:-.--:-.--:${CONFIG_NO_DATA_MESSAGE:-No data}:Native calc unavailable"
    echo "$result" > "$_COST_RENDER_CACHE_FILE"
    end_timer "cost_tracking"
    echo "$result"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the cost tracking module
init_cost_module() {
    debug_log "Cost tracking module initialized (100% native)" "INFO"

    # Verify native calculation modules are available
    if declare -f get_native_usage_info &>/dev/null; then
        debug_log "Native JSONL cost calculation available" "INFO"
    else
        debug_log "Native cost calculation not loaded - cost tracking disabled" "WARN"
    fi

    if declare -f get_cached_native_burn_rate &>/dev/null; then
        debug_log "Native block metrics available (burn rate, projections, reset timer)" "INFO"
    else
        debug_log "Native block metrics not loaded" "WARN"
    fi

    # Initialize cache directory
    init_cost_cache

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
