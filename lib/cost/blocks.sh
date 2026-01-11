#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Blocks Module
# ============================================================================
#
# Handles active block processing and unified block metrics.
# Split from cost.sh as part of Issue #132.
#
# Dependencies: core.sh, cost/core.sh, cost/ccusage.sh, cost/aggregation.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_BLOCKS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_BLOCKS_LOADED=true

# ============================================================================
# TOKEN FORMATTING UTILITIES
# ============================================================================

# Format tokens for display (compact format)
format_tokens_compact() {
    local tokens="$1"

    if [[ -z "$tokens" || "$tokens" == "null" || "$tokens" == "0" ]]; then
        echo "0"
        return 0
    fi

    # Convert to millions/thousands with appropriate suffix
    # Use awk for all arithmetic to handle floating point properly
    local result
    result=$(awk "BEGIN {
        tokens = $tokens;
        if (tokens >= 1000000) {
            printf \"%.1fM\", tokens / 1000000;
        } else if (tokens >= 1000) {
            printf \"%.1fk\", tokens / 1000;
        } else {
            printf \"%.0f\", tokens;
        }
    }" 2>/dev/null)

    if [[ -n "$result" ]]; then
        echo "$result"
    else
        # Fallback for very old awk versions
        echo "$tokens"
    fi
}

# Format tokens for burn rate (per minute format)
format_tokens_per_minute() {
    local tokens_per_min="$1"

    if [[ -z "$tokens_per_min" || "$tokens_per_min" == "null" || "$tokens_per_min" == "0" ]]; then
        echo "0/min"
        return 0
    fi

    local formatted=$(format_tokens_compact "$tokens_per_min")
    echo "${formatted}/min"
}

# ============================================================================
# ACTIVE BLOCK PROCESSING
# ============================================================================

# Process active billing block information
process_active_blocks() {
    local block_data="$1"

    if [[ -z "$block_data" ]] || ! echo "$block_data" | jq empty 2>/dev/null; then
        echo "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE:$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
        return 1
    fi

    local block_cost remaining_minutes is_active
    block_cost=$(echo "$block_data" | jq -r '.blocks[0].costUSD // 0' 2>/dev/null)
    remaining_minutes=$(echo "$block_data" | jq -r '.blocks[0].projection.remainingMinutes // null' 2>/dev/null)
    is_active=$(echo "$block_data" | jq -r '.blocks[0].isActive // false' 2>/dev/null)

    # Enhanced block detection with three states
    if [[ "$is_active" == "true" ]]; then
        # Get reset time from endTime and convert to local time (always needed)
        local end_time reset_time
        end_time=$(echo "$block_data" | jq -r '.blocks[0].endTime // ""' 2>/dev/null)

        if [[ -n "$end_time" && "$end_time" != "null" ]]; then
            reset_time=$(execute_python_safely "
import datetime
utc_time = datetime.datetime.fromisoformat('$end_time'.replace('Z', '+00:00'))
local_time = utc_time.replace(tzinfo=datetime.timezone.utc).astimezone()
print(local_time.strftime('%H.%M'))
" "")
        fi

        local block_info reset_info time_str
        block_info=$(printf "%s%s \$%.2f" "$CONFIG_LIVE_BLOCK_EMOJI" "$CONFIG_LIVE_LABEL" "$block_cost")

        # Check if we have valid projection data
        if [[ "$remaining_minutes" != "null" && "$remaining_minutes" -gt 0 ]]; then
            # Valid projection: show normal countdown
            local hours=$((remaining_minutes / 60))
            local mins=$((remaining_minutes % 60))

            if [[ "$hours" -gt 0 ]]; then
                time_str="${hours}h ${mins}m left"
            else
                time_str="${mins}m left"
            fi
        else
            # Active block but no projection: API still calculating
            time_str="waiting API response..."
        fi

        # Format reset info
        if [[ -n "$reset_time" ]]; then
            reset_info=$(printf "$CONFIG_RESET_LABEL at %s (%s)" "$reset_time" "$time_str")
        else
            reset_info=$(printf "$CONFIG_RESET_LABEL (%s)" "$time_str")
        fi

        echo "$block_info:$reset_info"
    else
        echo "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE:$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
    fi
}

# ============================================================================
# UNIFIED BLOCK METRICS (v2.10.0)
# ============================================================================

# Get unified block metrics - ONE ccusage call for ALL components
get_unified_block_metrics() {
    debug_log "Getting unified block metrics..." "INFO"

    # Check if ccusage is available
    if ! is_ccusage_available; then
        # Return default values for all metrics (colon-separated)
        echo "0:0:0:0:0:0:0"
        return 1
    fi

    # Use cache with 30s TTL for rapidly changing block data
    local cache_file="$COST_CACHE_DIR/unified_block_metrics.cache"

    # Check cache first
    if [[ -f "$cache_file" ]] && is_cache_fresh "$cache_file" 30; then
        local cached_data=$(cat "$cache_file" 2>/dev/null)
        if [[ -n "$cached_data" ]]; then
            debug_log "Using cached unified block metrics" "INFO"
            echo "$cached_data"
            return 0
        fi
    fi

    # Get fresh block data using existing function
    local block_data
    block_data=$(get_active_blocks_data)

    if [[ -z "$block_data" ]] || ! echo "$block_data" | jq empty 2>/dev/null; then
        debug_log "No valid block data available" "WARN"
        echo "0:0:0:0:0:0:0"
        return 1
    fi

    # Parse ALL metrics at once from the block data
    local burn_rate cost_per_hour total_tokens cache_read cache_creation proj_cost proj_tokens

    # Extract burn rate metrics
    burn_rate=$(echo "$block_data" | jq -r '.blocks[0].burnRate.tokensPerMinute // 0' 2>/dev/null)
    cost_per_hour=$(echo "$block_data" | jq -r '.blocks[0].burnRate.costPerHour // 0' 2>/dev/null)

    # Extract token usage
    total_tokens=$(echo "$block_data" | jq -r '.blocks[0].totalTokens // 0' 2>/dev/null)

    # Extract cache metrics
    cache_read=$(echo "$block_data" | jq -r '.blocks[0].tokenCounts.cacheReadInputTokens // 0' 2>/dev/null)
    cache_creation=$(echo "$block_data" | jq -r '.blocks[0].tokenCounts.cacheCreationInputTokens // 0' 2>/dev/null)

    # Extract projection metrics
    proj_cost=$(echo "$block_data" | jq -r '.blocks[0].projection.totalCost // 0' 2>/dev/null)
    proj_tokens=$(echo "$block_data" | jq -r '.blocks[0].projection.totalTokens // 0' 2>/dev/null)

    # Format the unified metrics string (colon-separated)
    local unified_metrics="${burn_rate}:${cost_per_hour}:${total_tokens}:${cache_read}:${cache_creation}:${proj_cost}:${proj_tokens}"

    # Cache the results for 30 seconds
    echo "$unified_metrics" > "$cache_file" 2>/dev/null

    debug_log "Unified block metrics cached: burn_rate=${burn_rate}, tokens=${total_tokens}" "INFO"
    echo "$unified_metrics"
    return 0
}

# Export functions
export -f format_tokens_compact format_tokens_per_minute
export -f process_active_blocks get_unified_block_metrics
