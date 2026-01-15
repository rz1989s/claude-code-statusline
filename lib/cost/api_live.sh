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
# PRICING LOOKUP (bash 3.x compatible - no associative arrays)
# ============================================================================
# Prices per million tokens

# Get model pricing (returns: input output cache_write cache_read)
# Uses case statement for bash 3.x compatibility (macOS default bash)
get_model_pricing() {
    local model="$1"

    case "$model" in
        claude-opus-4-5-20251101)
            echo "5.00 25.00 6.25 0.50"
            ;;
        claude-sonnet-4-5-20251101|claude-sonnet-4-20250514)
            echo "3.00 15.00 3.75 0.30"
            ;;
        claude-haiku-4-5-20251101)
            echo "1.00 5.00 1.25 0.10"
            ;;
        *)
            # Default to Opus pricing for safety
            echo "5.00 25.00 6.25 0.50"
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

    # Convert epoch to ISO format for string comparison (ISO 8601 is lexicographically sortable)
    local window_start_iso
    if [[ "$(uname -s)" == "Darwin" ]]; then
        window_start_iso=$(date -u -r "$window_start_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    else
        window_start_iso=$(date -u -d "@$window_start_epoch" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    fi

    debug_log "API LIVE window start: $window_start_iso" "INFO"

    # Extract all assistant entries with usage, filter by timestamp using string comparison
    # jq outputs one JSON per line, then bash filters by timestamp
    local total_cost=0
    local entry_count=0

    while IFS= read -r jsonl_file; do
        [[ -z "$jsonl_file" ]] && continue

        # Extract relevant fields from assistant entries
        while IFS= read -r entry; do
            [[ -z "$entry" || "$entry" == "null" ]] && continue

            # Parse entry fields
            local timestamp model input output cache_write cache_read
            timestamp=$(echo "$entry" | jq -r '.ts // ""' 2>/dev/null)

            # Skip if timestamp is before window start (string comparison works for ISO 8601)
            [[ -z "$timestamp" ]] && continue
            # Truncate timestamp for comparison (remove milliseconds)
            local ts_compare="${timestamp%%.*}"
            [[ "$ts_compare" < "$window_start_iso" ]] && continue

            model=$(echo "$entry" | jq -r '.model // "default"' 2>/dev/null)
            input=$(echo "$entry" | jq -r '.input // 0' 2>/dev/null)
            output=$(echo "$entry" | jq -r '.output // 0' 2>/dev/null)
            cache_write=$(echo "$entry" | jq -r '.cache_write // 0' 2>/dev/null)
            cache_read=$(echo "$entry" | jq -r '.cache_read // 0' 2>/dev/null)

            # Calculate entry cost
            local entry_cost
            entry_cost=$(calculate_entry_cost "$model" "$input" "$output" "$cache_write" "$cache_read")

            total_cost=$(awk "BEGIN {printf \"%.6f\", $total_cost + $entry_cost}" 2>/dev/null)
            entry_count=$((entry_count + 1))

        done < <(jq -c 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) | {
            ts: .timestamp,
            model: (.message.model // "default"),
            input: (.message.usage.input_tokens // 0),
            output: (.message.usage.output_tokens // 0),
            cache_write: (.message.usage.cache_creation_input_tokens // 0),
            cache_read: (.message.usage.cache_read_input_tokens // 0)
        }' "$jsonl_file" 2>/dev/null)

    done < <(find "$projects_dir" -name "*.jsonl" -type f -mmin -360 2>/dev/null)

    debug_log "API LIVE calculated: \$${total_cost} from ${entry_count} entries" "INFO"

    # Format to 2 decimal places
    printf "%.2f" "$total_cost" 2>/dev/null || echo "0.00"
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
# EXPORTS
# ============================================================================

export -f get_model_pricing get_claude_projects_dir calculate_entry_cost
export -f get_api_window_start calculate_api_synced_live get_api_synced_live_cost

debug_log "API-synced LIVE cost module loaded" "INFO"
