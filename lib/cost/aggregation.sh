#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Aggregation Module
# ============================================================================
#
# Handles date calculations and cost data retrieval (daily/weekly/monthly).
# Split from cost.sh as part of Issue #132.
#
# Dependencies: core.sh, cost/core.sh, cost/ccusage.sh, cache.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_AGGREGATION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_AGGREGATION_LOADED=true

# ============================================================================
# DATE CALCULATION UTILITIES
# ============================================================================

# Calculate dates for cost queries
calculate_cost_dates() {
    local seven_days_ago thirty_days_ago today

    # CRITICAL FIX: Ensure date format variables are never empty (fallback to hardcoded defaults)
    # This fixes the DAY $0.00 issue when TOML configuration fails to load
    if [[ -z "$CONFIG_DATE_FORMAT" || "$CONFIG_DATE_FORMAT" == "" ]]; then
        export CONFIG_DATE_FORMAT="%Y-%m-%d"
        debug_log "Applied fallback for CONFIG_DATE_FORMAT: %Y-%m-%d" "INFO"
    fi
    if [[ -z "$CONFIG_DATE_FORMAT_COMPACT" || "$CONFIG_DATE_FORMAT_COMPACT" == "" ]]; then
        export CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"
        debug_log "Applied fallback for CONFIG_DATE_FORMAT_COMPACT: %Y%m%d" "INFO"
    fi

    # Calculate dates with proper fallbacks
    if date -d '7 days ago' "+$CONFIG_DATE_FORMAT_COMPACT" >/dev/null 2>&1; then
        # GNU date (Linux)
        seven_days_ago=$(date -d '7 days ago' "+$CONFIG_DATE_FORMAT_COMPACT")
        thirty_days_ago=$(date -d '30 days ago' "+$CONFIG_DATE_FORMAT_COMPACT")
    elif date -v-7d "+$CONFIG_DATE_FORMAT_COMPACT" >/dev/null 2>&1; then
        # BSD date (macOS)
        seven_days_ago=$(date -v-7d "+$CONFIG_DATE_FORMAT_COMPACT")
        thirty_days_ago=$(date -v-30d "+$CONFIG_DATE_FORMAT_COMPACT")
    else
        # Fallback for systems without proper date arithmetic
        local current_epoch=$(date +%s)
        local seven_days_epoch=$((current_epoch - 7 * 24 * 3600))
        local thirty_days_epoch=$((current_epoch - 30 * 24 * 3600))
        # Note: Chained date calls try GNU (-d @epoch) then BSD (-r epoch) then today as final fallback
        seven_days_ago=$(date -d "@$seven_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || date -r "$seven_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || echo "$(date "+$CONFIG_DATE_FORMAT_COMPACT")")
        thirty_days_ago=$(date -d "@$thirty_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || date -r "$thirty_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || echo "$(date "+$CONFIG_DATE_FORMAT_COMPACT")")
    fi

    today=$(date "+$CONFIG_DATE_FORMAT")

    # Export for use by other functions
    export COST_SEVEN_DAYS_AGO="$seven_days_ago"
    export COST_THIRTY_DAYS_AGO="$thirty_days_ago"
    export COST_TODAY="$today"

    debug_log "Cost dates calculated - today: $today, 7d: $seven_days_ago, 30d: $thirty_days_ago" "INFO"
}

# ============================================================================
# INDIVIDUAL COST DATA RETRIEVAL
# ============================================================================

# Get active billing blocks information
get_active_blocks_data() {
    if ! is_ccusage_available; then
        return 1
    fi

    execute_ccusage_with_cache "$BLOCKS_CACHE_FILE" "blocks --active" "$COST_CACHE_DURATION_LIVE"
}

# Get session cost data
get_session_cost_data() {
    if ! is_ccusage_available; then
        return 1
    fi

    calculate_cost_dates

    # Use repository-aware session cache file to prevent cross-contamination
    local session_cache_file
    if [[ "${CACHE_CONFIG_SESSION_ISOLATION:-}" == "repository" ]]; then
        local repo_id
        repo_id=$(get_repo_identifier "$PWD" "path")
        session_cache_file="$COST_CACHE_DIR/session_${repo_id}.json"
        debug_log "Using repository-aware session cache: $(basename "$session_cache_file")" "INFO"
    else
        session_cache_file="$SESSION_CACHE_FILE"
        debug_log "Using shared session cache: $(basename "$session_cache_file")" "INFO"
    fi

    # Issue #140: Check if current session exists in cached data
    # If cache is fresh but doesn't contain our session, invalidate and refetch
    if [[ -f "$session_cache_file" ]]; then
        local current_session_id
        current_session_id=$(sanitize_path_secure "$PWD")
        local session_exists
        session_exists=$(jq -r --arg sid "$current_session_id" \
            '.sessions[] | select(.sessionId == $sid) | .sessionId' \
            "$session_cache_file" 2>/dev/null | head -1)

        if [[ -z "$session_exists" ]]; then
            debug_log "Current session $current_session_id not in cache, forcing refresh" "INFO"
            rm -f "$session_cache_file" 2>/dev/null
        fi
    fi

    execute_ccusage_with_cache "$session_cache_file" "session --since $COST_SEVEN_DAYS_AGO" "$COST_CACHE_DURATION_SESSION"
}

# Get daily cost data (7 days)
get_daily_cost_data() {
    if ! is_ccusage_available; then
        return 1
    fi

    calculate_cost_dates
    execute_ccusage_with_cache "$DAILY_CACHE_FILE" "daily --since $COST_SEVEN_DAYS_AGO" "$COST_CACHE_DURATION_DAILY"
}

# Get monthly cost data (30 days)
get_monthly_cost_data() {
    if ! is_ccusage_available; then
        return 1
    fi

    calculate_cost_dates
    execute_ccusage_with_cache "$MONTHLY_CACHE_FILE" "daily --since $COST_THIRTY_DAYS_AGO" "$COST_CACHE_DURATION_MONTHLY"
}

# ============================================================================
# COST DATA PROCESSING
# ============================================================================

# Extract session cost for current directory
extract_session_cost() {
    local session_data="$1"
    local current_dir="${2:-$(pwd)}"
    local session_id

    session_id=$(sanitize_path_secure "$current_dir")

    if [[ -z "$session_data" ]] || ! echo "$session_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi

    local session_cost
    session_cost=$(echo "$session_data" | jq -r --arg session_id "$session_id" '.sessions[] | select(.sessionId == $session_id) | .totalCost // 0' 2>/dev/null | head -1)

    if [[ -z "$session_cost" || "$session_cost" == "null" ]]; then
        session_cost="$DEFAULT_COST"
    fi

    printf "%.2f" "$session_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# Extract today's cost from daily data
extract_today_cost() {
    local daily_data="$1"

    if [[ -z "$daily_data" ]] || ! echo "$daily_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi

    calculate_cost_dates
    local today_cost
    today_cost=$(echo "$daily_data" | jq -r --arg today "$COST_TODAY" '.daily[] | select(.date == $today) | .totalCost // 0' 2>/dev/null | head -1)

    if [[ -z "$today_cost" || "$today_cost" == "null" ]]; then
        today_cost="$DEFAULT_COST"
    fi

    printf "%.2f" "$today_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# Extract weekly cost (excluding today)
extract_weekly_cost() {
    local daily_data="$1"
    local today_cost="${2:-0.00}"

    if [[ -z "$daily_data" ]] || ! echo "$daily_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi

    local total_cost
    total_cost=$(echo "$daily_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)

    if [[ -z "$total_cost" || "$total_cost" == "null" ]]; then
        total_cost="$DEFAULT_COST"
    fi

    # Subtract today's cost to get only the last 7 days without today
    local week_cost
    if command_exists bc; then
        week_cost=$(echo "$total_cost - $today_cost" | bc -l 2>/dev/null || echo "0.00")
    else
        # Fallback using shell arithmetic (less precise for floating point)
        week_cost=$(awk "BEGIN {printf \"%.2f\", $total_cost - $today_cost}" 2>/dev/null || echo "0.00")
    fi

    printf "%.2f" "$week_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# Extract monthly cost
extract_monthly_cost() {
    local monthly_data="$1"

    if [[ -z "$monthly_data" ]] || ! echo "$monthly_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi

    local month_cost
    month_cost=$(echo "$monthly_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)

    if [[ -z "$month_cost" || "$month_cost" == "null" ]]; then
        month_cost="$DEFAULT_COST"
    fi

    printf "%.2f" "$month_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# Export functions
export -f calculate_cost_dates
export -f get_active_blocks_data get_session_cost_data get_daily_cost_data get_monthly_cost_data
export -f extract_session_cost extract_today_cost extract_weekly_cost extract_monthly_cost
