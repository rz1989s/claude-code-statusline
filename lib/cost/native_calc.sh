#!/bin/bash

# ============================================================================
# Claude Code Statusline - Native Cost Calculator
# ============================================================================
#
# Unified native cost calculation from JSONL files, eliminating ccusage
# dependency. Provides time-based filtering for all cost metrics:
#   - REPO:  Current repository/project cumulative cost
#   - DAY:   Today's cost (since 00:00 UTC)
#   - 7DAY:  Last 7 days cost
#   - 30DAY: Last 30 days cost
#   - LIVE:  API-synced 5-hour window (uses api_live.sh)
#
# Data Source: ~/.claude/projects/ JSONL files
# Pricing: Inherited from api_live.sh (get_model_pricing)
#
# Dependencies: core.sh, api_live.sh (for pricing and base functions)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_NATIVE_CALC_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_NATIVE_CALC_LOADED=true

# ============================================================================
# TIME BOUNDARY CALCULATIONS
# ============================================================================

# Get start of today in ISO format (00:00:00 UTC)
get_today_start_iso() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -u "+%Y-%m-%dT00:00:00"
    else
        date -u "+%Y-%m-%dT00:00:00"
    fi
}

# Get start of N days ago in ISO format
get_days_ago_start_iso() {
    local days="${1:-0}"

    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -u -v-${days}d "+%Y-%m-%dT00:00:00"
    else
        date -u -d "$days days ago" "+%Y-%m-%dT00:00:00"
    fi
}

# ============================================================================
# JSONL COST CALCULATION
# ============================================================================

# Calculate total cost from JSONL entries within a time range
# Args: start_iso [end_iso] [project_filter]
# If end_iso is empty, uses current time
# If project_filter is provided, only counts entries from that project
# OPTIMIZED: Single jq pass with awk for cost calculation (no per-entry jq calls)
calculate_cost_in_range() {
    local start_iso="$1"
    local end_iso="${2:-}"
    local project_filter="${3:-}"

    local projects_dir
    projects_dir=$(get_claude_projects_dir)

    if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
        echo "0.00"
        return 1
    fi

    # Find JSONL files (limit to files modified in last 30 days for performance)
    local find_cmd="find \"$projects_dir\" -name \"*.jsonl\" -type f -mtime -30"

    # If project filter specified, only look in that project directory
    if [[ -n "$project_filter" ]]; then
        local sanitized_project
        sanitized_project=$(echo "$project_filter" | sed 's|/|-|g')
        find_cmd="find \"$projects_dir\" -path \"*${sanitized_project}*\" -name \"*.jsonl\" -type f"
    fi

    # OPTIMIZED: Single jq+awk pipeline for all calculations
    # Output format: timestamp|model|input|output|cache_write|cache_read
    local total_cost
    total_cost=$(eval "$find_cmd" 2>/dev/null | while read -r jsonl_file; do
        [[ -z "$jsonl_file" ]] && continue
        jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
            [.timestamp, (.message.model // "default"),
             (.message.usage.input_tokens // 0),
             (.message.usage.output_tokens // 0),
             (.message.usage.cache_creation_input_tokens // 0),
             (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
    done | awk -F'\t' -v start="$start_iso" -v end="$end_iso" '
    BEGIN {
        total = 0
        count = 0
        # Pricing per million tokens (model -> input output cache_write cache_read)
        # Opus 4.5
        p["claude-opus-4-5-20251101"] = "5.00 25.00 6.25 0.50"
        # Sonnet 4.5 / 4
        p["claude-sonnet-4-5-20251101"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-20250514"] = "3.00 15.00 3.75 0.30"
        # Haiku 4.5
        p["claude-haiku-4-5-20251101"] = "1.00 5.00 1.25 0.10"
        # Default (Opus pricing)
        p["default"] = "5.00 25.00 6.25 0.50"
    }
    {
        ts = $1
        # Truncate timestamp for comparison (remove milliseconds and Z)
        gsub(/\.[0-9]+Z?$/, "", ts)

        # Check time range
        if (ts < start) next
        if (end != "" && ts > end) next

        model = $2
        input = $3 + 0
        output = $4 + 0
        cache_write = $5 + 0
        cache_read = $6 + 0

        # Get pricing for model
        pricing = p[model]
        if (pricing == "") pricing = p["default"]
        split(pricing, pr, " ")

        # Calculate cost (prices per million tokens)
        cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000
        total += cost
        count++
    }
    END {
        printf "%.2f", total
    }')

    debug_log "Native calc ($start_iso to ${end_iso:-now}): \$${total_cost}" "INFO"
    echo "${total_cost:-0.00}"
}

# ============================================================================
# SPECIFIC PERIOD CALCULATIONS
# ============================================================================

# Calculate today's cost (since 00:00 UTC)
calculate_native_daily_cost() {
    local today_start
    today_start=$(get_today_start_iso)
    calculate_cost_in_range "$today_start"
}

# Calculate last 7 days cost
calculate_native_weekly_cost() {
    local week_start
    week_start=$(get_days_ago_start_iso 7)
    calculate_cost_in_range "$week_start"
}

# Calculate last 30 days cost
calculate_native_monthly_cost() {
    local month_start
    month_start=$(get_days_ago_start_iso 30)
    calculate_cost_in_range "$month_start"
}

# Calculate repository/project cost (all time for current project)
calculate_native_repo_cost() {
    local current_dir="${1:-$(pwd)}"
    # Use a very old date as start to get all entries
    calculate_cost_in_range "2020-01-01T00:00:00" "" "$current_dir"
}

# ============================================================================
# UNIFIED USAGE INFO (ccusage-compatible format)
# ============================================================================

# Get comprehensive usage info in ccusage-compatible format
# OPTIMIZED: Single pass through JSONL files, calculates all periods at once
# Returns: session:month:week:today:block:reset
get_native_usage_info() {
    local current_dir="${1:-$(pwd)}"

    debug_log "Calculating native usage info for: $current_dir (single pass)" "INFO"

    local projects_dir
    projects_dir=$(get_claude_projects_dir)

    if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
        echo "0.00:0.00:0.00:0.00:No data:"
        return 1
    fi

    # Calculate time boundaries
    local today_start month_start week_start
    today_start=$(get_today_start_iso)
    week_start=$(get_days_ago_start_iso 7)
    month_start=$(get_days_ago_start_iso 30)

    # Sanitize current_dir for project matching
    local sanitized_project
    sanitized_project=$(echo "$current_dir" | sed 's|/|-|g')

    # OPTIMIZED: Single jq+awk pass computes ALL periods at once
    local result
    result=$(find "$projects_dir" -name "*.jsonl" -type f -mtime -30 2>/dev/null | while read -r jsonl_file; do
        [[ -z "$jsonl_file" ]] && continue
        # Include file path for project filtering
        jq -r --arg file "$jsonl_file" 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
            [$file, .timestamp, (.message.model // "default"),
             (.message.usage.input_tokens // 0),
             (.message.usage.output_tokens // 0),
             (.message.usage.cache_creation_input_tokens // 0),
             (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
    done | awk -F'\t' -v today="$today_start" -v week="$week_start" -v month="$month_start" -v project="$sanitized_project" '
    BEGIN {
        daily = 0; weekly = 0; monthly = 0; repo = 0
        # Pricing per million tokens
        p["claude-opus-4-5-20251101"] = "5.00 25.00 6.25 0.50"
        p["claude-sonnet-4-5-20251101"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-20250514"] = "3.00 15.00 3.75 0.30"
        p["claude-haiku-4-5-20251101"] = "1.00 5.00 1.25 0.10"
        p["default"] = "5.00 25.00 6.25 0.50"
    }
    {
        file = $1
        ts = $2
        model = $3
        input = $4 + 0
        output = $5 + 0
        cache_write = $6 + 0
        cache_read = $7 + 0

        # Truncate timestamp
        gsub(/\.[0-9]+Z?$/, "", ts)

        # Get pricing
        pricing = p[model]
        if (pricing == "") pricing = p["default"]
        split(pricing, pr, " ")
        cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000

        # Accumulate by period
        if (ts >= month) monthly += cost
        if (ts >= week) weekly += cost
        if (ts >= today) daily += cost

        # Project-specific (repo) cost
        if (index(file, project) > 0) repo += cost
    }
    END {
        printf "%.2f:%.2f:%.2f:%.2f", repo, monthly, weekly, daily
    }')

    # Parse result
    local repo_cost monthly_cost weekly_cost daily_cost
    IFS=':' read -r repo_cost monthly_cost weekly_cost daily_cost <<< "$result"

    # LIVE block info (from api_live.sh if available)
    local block_info="No active block"
    local reset_info=""

    if declare -f get_api_synced_live_cost &>/dev/null; then
        local live_cost
        live_cost=$(get_api_synced_live_cost 2>/dev/null)
        if [[ -n "$live_cost" && "$live_cost" != "0.00" ]]; then
            block_info="${CONFIG_LIVE_BLOCK_EMOJI:-}${CONFIG_LIVE_LABEL:-LIVE} \$${live_cost}"
        fi
    fi

    debug_log "Native usage: repo=\$${repo_cost} month=\$${monthly_cost} week=\$${weekly_cost} day=\$${daily_cost}" "INFO"

    # Format: session:month:week:today:block:reset
    echo "${repo_cost:-0.00}:${monthly_cost:-0.00}:${weekly_cost:-0.00}:${daily_cost:-0.00}:${block_info}:${reset_info}"
}

# Cached version of get_native_usage_info
# Uses file-based cache (5min TTL) for fast repeated calls
# Processing 1000+ JSONL files takes ~15-20s, so longer TTL is appropriate
get_cached_native_usage_info() {
    local current_dir="${1:-$(pwd)}"
    local cache_ttl="${NATIVE_CALC_CACHE_TTL:-300}"

    # Use project-based cache key (not PID-based)
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
    local sanitized_dir
    sanitized_dir=$(echo "$current_dir" | sed 's|/|_|g')
    local cache_file="${cache_dir}/native_usage_${sanitized_dir}.cache"

    # Ensure cache directory exists
    [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir" 2>/dev/null

    # Return cached if fresh (< cache_ttl seconds, default 5 minutes)
    if [[ -f "$cache_file" ]]; then
        local cache_mtime cache_age
        cache_mtime=$(stat -f "%m" "$cache_file" 2>/dev/null || stat -c "%Y" "$cache_file" 2>/dev/null)
        cache_age=$(( $(date +%s) - cache_mtime ))
        if [[ $cache_age -lt $cache_ttl ]]; then
            debug_log "Using cached native usage info (age=${cache_age}s, ttl=${cache_ttl}s)" "DEBUG"
            cat "$cache_file"
            return 0
        fi
    fi

    # Calculate fresh and cache
    local result
    result=$(get_native_usage_info "$current_dir")
    echo "$result" > "$cache_file"
    echo "$result"
}

# ============================================================================
# CACHED NATIVE CALCULATIONS
# ============================================================================

# Cache TTL for native calculations (300 seconds = 5 minutes)
# Processing 1000+ JSONL files takes ~15-20s, so longer TTL is appropriate
NATIVE_CALC_CACHE_TTL="${NATIVE_CALC_CACHE_TTL:-300}"

# Get cached daily cost
get_cached_native_daily_cost() {
    local cache_key="native_daily_cost"
    local cached
    cached=$(get_cached_value "$cache_key" "$NATIVE_CALC_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached" ]]; then
        echo "$cached"
        return 0
    fi

    local cost
    cost=$(calculate_native_daily_cost)
    set_cached_value "$cache_key" "$cost" 2>/dev/null
    echo "$cost"
}

# Get cached weekly cost
get_cached_native_weekly_cost() {
    local cache_key="native_weekly_cost"
    local cached
    cached=$(get_cached_value "$cache_key" "$NATIVE_CALC_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached" ]]; then
        echo "$cached"
        return 0
    fi

    local cost
    cost=$(calculate_native_weekly_cost)
    set_cached_value "$cache_key" "$cost" 2>/dev/null
    echo "$cost"
}

# Get cached monthly cost
get_cached_native_monthly_cost() {
    local cache_key="native_monthly_cost"
    local cached
    cached=$(get_cached_value "$cache_key" "$NATIVE_CALC_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached" ]]; then
        echo "$cached"
        return 0
    fi

    local cost
    cost=$(calculate_native_monthly_cost)
    set_cached_value "$cache_key" "$cost" 2>/dev/null
    echo "$cost"
}

# Get cached repo cost
get_cached_native_repo_cost() {
    local current_dir="${1:-$(pwd)}"
    local cache_key="native_repo_cost_$(echo "$current_dir" | sed 's|/|_|g')"
    local cached
    cached=$(get_cached_value "$cache_key" "$NATIVE_CALC_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached" ]]; then
        echo "$cached"
        return 0
    fi

    local cost
    cost=$(calculate_native_repo_cost "$current_dir")
    set_cached_value "$cache_key" "$cost" 2>/dev/null
    echo "$cost"
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f get_today_start_iso get_days_ago_start_iso
export -f calculate_cost_in_range
export -f calculate_native_daily_cost calculate_native_weekly_cost
export -f calculate_native_monthly_cost calculate_native_repo_cost
export -f get_native_usage_info get_cached_native_usage_info
export -f get_cached_native_daily_cost get_cached_native_weekly_cost
export -f get_cached_native_monthly_cost get_cached_native_repo_cost

debug_log "Native cost calculator module loaded" "INFO"
