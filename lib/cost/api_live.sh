#!/bin/bash

# ============================================================================
# Claude Code Statusline - API-Synced LIVE Cost Module
# ============================================================================
#
# Calculates LIVE cost by reading JSONL files within the Anthropic API's
# 5-hour billing window. This ensures LIVE syncs with the reset timer.
#
# Data Sources:
# - Anthropic OAuth API: Gets 5-hour window boundaries (resets_at)
# - Local JSONL files: Reads token usage from ~/.claude/projects/
#
# Pricing (per million tokens):
# - Opus 4.5: Input $5, Output $25, Cache Write $6.25, Cache Read $0.50
# - Sonnet 4.5: Input $3, Output $15, Cache Write $3.75, Cache Read $0.30
# - Haiku 4.5: Input $1, Output $5, Cache Write $1.25, Cache Read $0.10
#
# Dependencies: usage_limits.sh (for OAuth token), jq
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_API_LIVE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_API_LIVE_LOADED=true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Format tokens in compact notation (e.g., 1.5M, 500K)
# Used by block_projection, token_usage, and session components
format_tokens_compact() {
    local tokens="${1:-0}"

    # Handle empty or non-numeric input
    if [[ -z "$tokens" || ! "$tokens" =~ ^[0-9]+$ ]]; then
        echo "0"
        return
    fi

    if [[ "$tokens" -ge 1000000 ]]; then
        awk -v t="$tokens" 'BEGIN { printf "%.1fM", t / 1000000 }'
    elif [[ "$tokens" -ge 1000 ]]; then
        awk -v t="$tokens" 'BEGIN { printf "%.1fK", t / 1000 }'
    else
        echo "$tokens"
    fi
}

# ============================================================================
# PRICING LOOKUP (bash 3.x compatible - no associative arrays)
# ============================================================================
# Prices per million tokens

# Get model pricing (returns: input output cache_write cache_read)
# Uses case statement for bash 3.x compatibility (macOS default bash)
get_model_pricing() {
    local model="$1"

    # Official Anthropic pricing from https://claude.com/pricing
    case "$model" in
        claude-opus-4-5-20251101)
            echo "5.00 25.00 6.25 0.50"
            ;;
        claude-sonnet-4-5-20251101|claude-sonnet-4-5-20250929|claude-sonnet-4-20250514)
            echo "3.00 15.00 3.75 0.30"
            ;;
        claude-haiku-4-5-20251101|claude-haiku-4-5-20251001)
            echo "1.00 5.00 1.25 0.10"
            ;;
        *)
            # Default to Sonnet pricing (safer middle ground)
            echo "3.00 15.00 3.75 0.30"
            ;;
    esac
}

# Cache TTL for API-synced LIVE (30 seconds)
API_LIVE_CACHE_TTL="${API_LIVE_CACHE_TTL:-30}"

# ============================================================================
# JSONL DIRECTORY DISCOVERY
# ============================================================================

# Get Claude projects directory path
get_claude_projects_dir() {
    local projects_dir=""

    # Check environment variable first
    if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
        projects_dir="${CLAUDE_CONFIG_DIR}/projects"
    elif [[ -d "$HOME/.claude/projects" ]]; then
        projects_dir="$HOME/.claude/projects"
    elif [[ -d "$HOME/.config/claude/projects" ]]; then
        projects_dir="$HOME/.config/claude/projects"
    fi

    echo "$projects_dir"
}

# ============================================================================
# COST CALCULATION
# ============================================================================

# Calculate cost for a single entry based on token usage
# Args: model, input_tokens, output_tokens, cache_write_tokens, cache_read_tokens
calculate_entry_cost() {
    local model="$1"
    local input_tokens="${2:-0}"
    local output_tokens="${3:-0}"
    local cache_write_tokens="${4:-0}"
    local cache_read_tokens="${5:-0}"

    # Get pricing for model (space-separated: input output cache_write cache_read)
    local pricing
    pricing=$(get_model_pricing "$model")

    # Parse pricing values
    local input_price output_price cache_write_price cache_read_price
    read -r input_price output_price cache_write_price cache_read_price <<< "$pricing"

    # Calculate cost (prices are per million tokens)
    local cost
    cost=$(awk -v it="$input_tokens" -v ip="$input_price" \
               -v ot="$output_tokens" -v op="$output_price" \
               -v cwt="$cache_write_tokens" -v cwp="$cache_write_price" \
               -v crt="$cache_read_tokens" -v crp="$cache_read_price" \
        'BEGIN {
            input_cost = it * ip / 1000000
            output_cost = ot * op / 1000000
            cache_write_cost = cwt * cwp / 1000000
            cache_read_cost = crt * crp / 1000000
            total = input_cost + output_cost + cache_write_cost + cache_read_cost
            printf "%.6f", total
        }' 2>/dev/null)

    echo "${cost:-0}"
}

# ============================================================================
# API-SYNCED LIVE CALCULATION
# ============================================================================

# Get the 5-hour window start time from API's resets_at
# Returns: Unix epoch timestamp of window start
get_api_window_start() {
    # Get resets_at from usage_limits component (already fetched and cached)
    local resets_at="${COMPONENT_USAGE_FIVE_HOUR_RESET:-}"

    if [[ -z "$resets_at" || "$resets_at" == "null" ]]; then
        # Try fetching directly if component data not available
        local usage_data
        usage_data=$(fetch_usage_limits 2>/dev/null)
        resets_at=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
    fi

    if [[ -z "$resets_at" || "$resets_at" == "null" ]]; then
        debug_log "No API resets_at available for LIVE calculation" "WARN"
        echo ""
        return 1
    fi

    # Parse resets_at to epoch
    local reset_epoch
    local normalized_ts
    normalized_ts=$(echo "$resets_at" | sed 's/\.[0-9]*//')

    if [[ "$(uname -s)" == "Darwin" ]]; then
        local mac_ts
        mac_ts=$(echo "$normalized_ts" | sed 's/+00:00/+0000/; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')
        reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)
    else
        reset_epoch=$(date -d "$resets_at" "+%s" 2>/dev/null)
    fi

    if [[ -z "$reset_epoch" ]]; then
        debug_log "Could not parse API resets_at: $resets_at" "WARN"
        echo ""
        return 1
    fi

    # Calculate window start (5 hours before reset)
    local window_start=$((reset_epoch - 5 * 3600))
    echo "$window_start"
}

# Calculate LIVE cost from JSONL files within API's 5-hour window
# OPTIMIZED: Single jq+awk pipeline (no per-entry jq calls)
# Returns: Total cost in USD (e.g., "18.51")
calculate_api_synced_live() {
    local projects_dir
    projects_dir=$(get_claude_projects_dir)

    if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
        debug_log "Claude projects directory not found" "WARN"
        echo "0.00"
        return 1
    fi

    local window_start_epoch
    window_start_epoch=$(get_api_window_start)

    if [[ -z "$window_start_epoch" ]]; then
        debug_log "Could not determine API window start" "WARN"
        echo "0.00"
        return 1
    fi

    # Convert epoch to ISO format for string comparison
    local window_start_iso
    if [[ "$(uname -s)" == "Darwin" ]]; then
        window_start_iso=$(date -u -r "$window_start_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    else
        window_start_iso=$(date -u -d "@$window_start_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    fi

    debug_log "API LIVE window start: $window_start_iso" "INFO"

    # OPTIMIZED: Single jq+awk pipeline
    local total_cost
    total_cost=$(find "$projects_dir" -name "*.jsonl" -type f -mmin -360 2>/dev/null | while read -r jsonl_file; do
        [[ -z "$jsonl_file" ]] && continue
        jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
            [.timestamp, (.message.model // "default"),
             (.message.usage.input_tokens // 0),
             (.message.usage.output_tokens // 0),
             (.message.usage.cache_creation_input_tokens // 0),
             (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
    done | awk -F'\t' -v start="$window_start_iso" '
    BEGIN {
        total = 0
        # Pricing per million tokens - Official Anthropic pricing
        p["claude-opus-4-5-20251101"] = "5.00 25.00 6.25 0.50"
        p["claude-sonnet-4-5-20251101"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-5-20250929"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-20250514"] = "3.00 15.00 3.75 0.30"
        p["claude-haiku-4-5-20251101"] = "1.00 5.00 1.25 0.10"
        p["claude-haiku-4-5-20251001"] = "1.00 5.00 1.25 0.10"
        p["default"] = "3.00 15.00 3.75 0.30"
    }
    {
        ts = $1
        gsub(/\.[0-9]+Z?$/, "", ts)
        if (ts < start) next

        model = $2
        input = $3 + 0
        output = $4 + 0
        cache_write = $5 + 0
        cache_read = $6 + 0

        pricing = p[model]
        if (pricing == "") pricing = p["default"]
        split(pricing, pr, " ")
        cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000
        total += cost
    }
    END {
        printf "%.2f", total
    }')

    debug_log "API LIVE calculated: \$${total_cost}" "INFO"
    echo "${total_cost:-0.00}"
}

# Get API-synced LIVE cost with caching
get_api_synced_live_cost() {
    # Check cache first
    local cache_key="api_synced_live"
    local cached_result
    cached_result=$(get_cached_value "$cache_key" "$API_LIVE_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached_result" ]]; then
        debug_log "Using cached API-synced LIVE: \$${cached_result}" "INFO"
        echo "$cached_result"
        return 0
    fi

    # Calculate fresh
    local live_cost
    live_cost=$(calculate_api_synced_live)

    # Cache result
    set_cached_value "$cache_key" "$live_cost" 2>/dev/null

    echo "$live_cost"
}

# ============================================================================
# NATIVE BLOCK METRICS (ccusage replacement)
# ============================================================================

# Calculate token counts in current 5-hour window
# Returns: total_tokens:input_tokens:output_tokens:cache_read:cache_write
calculate_window_tokens() {
    local projects_dir
    projects_dir=$(get_claude_projects_dir)

    if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
        echo "0:0:0:0:0"
        return 1
    fi

    local window_start_epoch
    window_start_epoch=$(get_api_window_start)

    if [[ -z "$window_start_epoch" ]]; then
        echo "0:0:0:0:0"
        return 1
    fi

    # Convert epoch to ISO format for string comparison
    local window_start_iso
    if [[ "$(uname -s)" == "Darwin" ]]; then
        window_start_iso=$(date -u -r "$window_start_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    else
        window_start_iso=$(date -u -d "@$window_start_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    fi

    # Single jq+awk pass to sum all token types
    local result
    result=$(find "$projects_dir" -name "*.jsonl" -type f -mmin -360 2>/dev/null | while read -r jsonl_file; do
        [[ -z "$jsonl_file" ]] && continue
        jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
            [.timestamp,
             (.message.usage.input_tokens // 0),
             (.message.usage.output_tokens // 0),
             (.message.usage.cache_read_input_tokens // 0),
             (.message.usage.cache_creation_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
    done | awk -F'\t' -v start="$window_start_iso" '
    BEGIN {
        total_input = 0; total_output = 0; cache_read = 0; cache_write = 0
    }
    {
        ts = $1
        gsub(/\.[0-9]+Z?$/, "", ts)
        if (ts < start) next

        total_input += $2 + 0
        total_output += $3 + 0
        cache_read += $4 + 0
        cache_write += $5 + 0
    }
    END {
        total = total_input + total_output
        printf "%d:%d:%d:%d:%d", total, total_input, total_output, cache_read, cache_write
    }')

    debug_log "Window tokens calculated: $result" "INFO"
    echo "${result:-0:0:0:0:0}"
}

# Get cached window tokens (30s TTL)
get_cached_window_tokens() {
    local cache_key="window_tokens"
    local cached_result
    cached_result=$(get_cached_value "$cache_key" "$API_LIVE_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached_result" ]]; then
        echo "$cached_result"
        return 0
    fi

    local result
    result=$(calculate_window_tokens)
    set_cached_value "$cache_key" "$result" 2>/dev/null
    echo "$result"
}

# Calculate native burn rate from JSONL activity in 5-hour window
# Returns: tokens_per_minute:cost_per_hour
calculate_native_burn_rate() {
    local window_start_epoch
    window_start_epoch=$(get_api_window_start)

    if [[ -z "$window_start_epoch" ]]; then
        echo "0:0.00"
        return 1
    fi

    local now_epoch
    now_epoch=$(date +%s)

    # Calculate elapsed minutes since window start
    local elapsed_seconds=$((now_epoch - window_start_epoch))
    local elapsed_minutes=$((elapsed_seconds / 60))

    # Avoid division by zero
    if [[ "$elapsed_minutes" -lt 1 ]]; then
        elapsed_minutes=1
    fi

    # Get token counts from window
    local token_data
    token_data=$(get_cached_window_tokens)
    local total_tokens
    total_tokens=$(echo "$token_data" | cut -d: -f1)
    total_tokens="${total_tokens:-0}"

    # Calculate tokens per minute
    local tokens_per_minute
    tokens_per_minute=$((total_tokens / elapsed_minutes))

    # Get cost in window and calculate cost per hour
    local live_cost
    live_cost=$(get_api_synced_live_cost)
    live_cost="${live_cost:-0.00}"

    local cost_per_hour
    cost_per_hour=$(awk -v cost="$live_cost" -v mins="$elapsed_minutes" \
        'BEGIN { printf "%.2f", (cost / mins) * 60 }' 2>/dev/null)

    debug_log "Native burn rate: ${tokens_per_minute}/min, \$${cost_per_hour}/hr" "INFO"
    echo "${tokens_per_minute}:${cost_per_hour}"
}

# Get cached burn rate (30s TTL)
get_cached_native_burn_rate() {
    local cache_key="native_burn_rate"
    local cached_result
    cached_result=$(get_cached_value "$cache_key" "$API_LIVE_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached_result" ]]; then
        echo "$cached_result"
        return 0
    fi

    local result
    result=$(calculate_native_burn_rate)
    set_cached_value "$cache_key" "$result" 2>/dev/null
    echo "$result"
}

# Get native reset timer info from OAuth API
# Returns: reset_time_local:remaining_minutes
get_native_reset_info() {
    # Get resets_at from usage_limits component
    local resets_at="${COMPONENT_USAGE_FIVE_HOUR_RESET:-}"

    if [[ -z "$resets_at" || "$resets_at" == "null" ]]; then
        # Try fetching directly if component data not available
        if declare -f fetch_usage_limits &>/dev/null; then
            local usage_data
            usage_data=$(fetch_usage_limits 2>/dev/null)
            resets_at=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
        fi
    fi

    if [[ -z "$resets_at" || "$resets_at" == "null" ]]; then
        echo ":"
        return 1
    fi

    # Parse resets_at to epoch
    local reset_epoch
    local normalized_ts
    normalized_ts=$(echo "$resets_at" | sed 's/\.[0-9]*//')

    if [[ "$(uname -s)" == "Darwin" ]]; then
        local mac_ts
        mac_ts=$(echo "$normalized_ts" | sed 's/+00:00/+0000/; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')
        reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)
    else
        reset_epoch=$(date -d "$resets_at" "+%s" 2>/dev/null)
    fi

    if [[ -z "$reset_epoch" ]]; then
        echo ":"
        return 1
    fi

    # Calculate remaining time
    local now_epoch
    now_epoch=$(date +%s)
    local remaining_seconds=$((reset_epoch - now_epoch))
    local remaining_minutes=$((remaining_seconds / 60))

    # Handle negative (already reset)
    if [[ "$remaining_minutes" -lt 0 ]]; then
        remaining_minutes=0
    fi

    # Format reset time in local timezone (HH.MM format)
    local reset_time_local
    if [[ "$(uname -s)" == "Darwin" ]]; then
        reset_time_local=$(date -r "$reset_epoch" "+%H.%M" 2>/dev/null)
    else
        reset_time_local=$(date -d "@$reset_epoch" "+%H.%M" 2>/dev/null)
    fi

    debug_log "Native reset info: ${reset_time_local}, ${remaining_minutes}m remaining" "INFO"
    echo "${reset_time_local}:${remaining_minutes}"
}

# Get cached reset info (30s TTL)
get_cached_native_reset_info() {
    local cache_key="native_reset_info"
    local cached_result
    cached_result=$(get_cached_value "$cache_key" "$API_LIVE_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached_result" ]]; then
        echo "$cached_result"
        return 0
    fi

    local result
    result=$(get_native_reset_info)
    set_cached_value "$cache_key" "$result" 2>/dev/null
    echo "$result"
}

# Calculate native block projection
# Returns: projected_cost:projected_tokens
calculate_native_block_projection() {
    # Get current window data
    local burn_rate_data
    burn_rate_data=$(get_cached_native_burn_rate)
    local tokens_per_minute cost_per_hour
    IFS=':' read -r tokens_per_minute cost_per_hour <<< "$burn_rate_data"

    # Get remaining time
    local reset_info
    reset_info=$(get_cached_native_reset_info)
    local remaining_minutes
    remaining_minutes=$(echo "$reset_info" | cut -d: -f2)
    remaining_minutes="${remaining_minutes:-0}"

    # Get current cost
    local current_cost
    current_cost=$(get_api_synced_live_cost)
    current_cost="${current_cost:-0.00}"

    # Get current tokens
    local token_data
    token_data=$(get_cached_window_tokens)
    local current_tokens
    current_tokens=$(echo "$token_data" | cut -d: -f1)
    current_tokens="${current_tokens:-0}"

    # Project to end of window
    local projected_tokens projected_cost
    projected_tokens=$((current_tokens + (tokens_per_minute * remaining_minutes)))

    projected_cost=$(awk -v curr="$current_cost" -v rate="$cost_per_hour" -v mins="$remaining_minutes" \
        'BEGIN { printf "%.2f", curr + (rate * mins / 60) }' 2>/dev/null)

    debug_log "Block projection: \$${projected_cost}, ${projected_tokens} tokens" "INFO"
    echo "${projected_cost}:${projected_tokens}"
}

# Get cached block projection (30s TTL)
get_cached_native_block_projection() {
    local cache_key="native_block_projection"
    local cached_result
    cached_result=$(get_cached_value "$cache_key" "$API_LIVE_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached_result" ]]; then
        echo "$cached_result"
        return 0
    fi

    local result
    result=$(calculate_native_block_projection)
    set_cached_value "$cache_key" "$result" 2>/dev/null
    echo "$result"
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f format_tokens_compact
export -f get_model_pricing get_claude_projects_dir calculate_entry_cost
export -f get_api_window_start calculate_api_synced_live get_api_synced_live_cost
export -f calculate_window_tokens get_cached_window_tokens
export -f calculate_native_burn_rate get_cached_native_burn_rate
export -f get_native_reset_info get_cached_native_reset_info
export -f calculate_native_block_projection get_cached_native_block_projection

debug_log "API-synced LIVE cost module loaded" "INFO"
