#!/bin/bash

# ============================================================================
# Claude Code Statusline - Native Cost Extraction Module
# ============================================================================
#
# Extract cost data directly from Anthropic's native statusline JSON input.
# This provides zero-latency cost data without external ccusage calls.
# Available in Claude Code v1.0.85+
#
# Split from cost.sh as part of Issue #132.
# Implements Issues #99, #100, #103
#
# Dependencies: core.sh, cost/core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_NATIVE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_NATIVE_LOADED=true

# ============================================================================
# NATIVE COST EXTRACTION (Issue #99)
# ============================================================================

# Extract native session cost from Anthropic JSON input
# Returns: cost value or empty string if unavailable
get_native_session_cost() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        debug_log "No native JSON input available for cost extraction" "INFO"
        echo ""
        return 1
    fi

    local native_cost
    native_cost=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)

    if [[ -n "$native_cost" && "$native_cost" != "null" ]]; then
        # Format to 2 decimal places
        printf "%.2f" "$native_cost" 2>/dev/null || echo ""
        return 0
    else
        echo ""
        return 1
    fi
}

# Extract native duration from Anthropic JSON input
# Returns: duration in ms or empty string if unavailable
get_native_session_duration() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_duration_ms // empty' 2>/dev/null
}

# Extract native API duration from Anthropic JSON input
# Returns: API duration in ms or empty string if unavailable
get_native_api_duration() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_api_duration_ms // empty' 2>/dev/null
}

# Debug comparison: Log native vs ccusage cost side-by-side
# This helps validate that native data matches ccusage before production use
compare_native_vs_ccusage_cost() {
    local native_cost ccusage_cost

    # Get native cost
    native_cost=$(get_native_session_cost)

    # Get ccusage cost (extract from full usage info)
    if is_ccusage_available; then
        local usage_info
        usage_info=$(get_claude_usage_info)
        ccusage_cost="${usage_info%%:*}"
    else
        ccusage_cost="N/A"
    fi

    # Format for comparison
    local native_display="${native_cost:-N/A}"
    local ccusage_display="${ccusage_cost:-N/A}"

    # Calculate difference if both are available
    local diff_display="N/A"
    if [[ -n "$native_cost" && "$ccusage_cost" != "N/A" && "$ccusage_cost" != "-.--" ]]; then
        local diff
        diff=$(awk "BEGIN {printf \"%.4f\", $native_cost - $ccusage_cost}" 2>/dev/null)
        if [[ -n "$diff" ]]; then
            diff_display="$diff"
        fi
    fi

    # Log the comparison (always visible in debug mode)
    debug_log "[COST COMPARE] Native: \$$native_display | ccusage: \$$ccusage_display | Diff: \$$diff_display" "INFO"

    # Return comparison data for further processing
    echo "${native_display}:${ccusage_display}:${diff_display}"
}

# Get session cost with source preference
# Supports: auto | native (both use native implementation)
get_session_cost_with_source() {
    local source="${1:-auto}"

    local native_cost
    native_cost=$(get_native_session_cost)

    if [[ -n "$native_cost" && "$native_cost" != "0.00" ]]; then
        debug_log "Using native cost source: \$$native_cost" "INFO"
        echo "$native_cost"
    else
        echo "$DEFAULT_COST"
    fi
}

# ============================================================================
# NATIVE CACHE EFFICIENCY EXTRACTION (Issue #103)
# ============================================================================
# Extract cache token data from Anthropic's native current_usage field.
# This provides real-time cache efficiency without ccusage calls.

# Extract native cache read tokens from Anthropic JSON input
get_native_cache_read_tokens() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local tokens
    tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_read_input_tokens // 0' 2>/dev/null)
    echo "${tokens:-0}"
}

# Extract native cache creation tokens from Anthropic JSON input
get_native_cache_creation_tokens() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local tokens
    tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_creation_input_tokens // 0' 2>/dev/null)
    echo "${tokens:-0}"
}

# Calculate cache efficiency from native data
# Returns: efficiency percentage (0-100)
get_native_cache_efficiency() {
    local cache_read cache_creation total efficiency

    cache_read=$(get_native_cache_read_tokens)
    cache_creation=$(get_native_cache_creation_tokens)

    # Handle null/empty values
    [[ -z "$cache_read" || "$cache_read" == "null" ]] && cache_read=0
    [[ -z "$cache_creation" || "$cache_creation" == "null" ]] && cache_creation=0

    total=$((cache_read + cache_creation))

    if [[ "$total" -gt 0 ]]; then
        efficiency=$(awk "BEGIN {printf \"%.0f\", $cache_read * 100 / $total}" 2>/dev/null)
        echo "${efficiency:-0}"
    else
        echo "0"
    fi
}

# Debug comparison: Log native vs ccusage cache efficiency side-by-side
compare_native_vs_ccusage_cache() {
    local native_read native_creation native_eff
    local ccusage_read ccusage_creation ccusage_eff

    # Get native values
    native_read=$(get_native_cache_read_tokens)
    native_creation=$(get_native_cache_creation_tokens)

    # Calculate native efficiency
    local native_total=$((native_read + native_creation))
    if [[ "$native_total" -gt 0 ]]; then
        native_eff=$(awk "BEGIN {printf \"%.0f\", $native_read * 100 / $native_total}" 2>/dev/null)
    else
        native_eff="N/A"
    fi

    # Get ccusage values
    if is_ccusage_available; then
        local metrics
        metrics=$(get_unified_block_metrics)

        if [[ -n "$metrics" && "$metrics" != "0:0:0:0:0:0:0" ]]; then
            ccusage_read=$(echo "$metrics" | cut -d: -f4)
            ccusage_creation=$(echo "$metrics" | cut -d: -f5)

            local ccusage_total=$((ccusage_read + ccusage_creation))
            if [[ "$ccusage_total" -gt 0 ]]; then
                ccusage_eff=$(awk "BEGIN {printf \"%.0f\", $ccusage_read * 100 / $ccusage_total}" 2>/dev/null)
            else
                ccusage_eff="N/A"
            fi
        else
            ccusage_read="N/A"
            ccusage_creation="N/A"
            ccusage_eff="N/A"
        fi
    else
        ccusage_read="N/A"
        ccusage_creation="N/A"
        ccusage_eff="N/A"
    fi

    # Format displays
    local native_display="${native_eff}% (read:${native_read}/create:${native_creation})"
    local ccusage_display="${ccusage_eff}% (read:${ccusage_read}/create:${ccusage_creation})"

    # Log the comparison
    debug_log "[CACHE COMPARE] Native: $native_display | ccusage: $ccusage_display" "INFO"

    # Return comparison data
    echo "${native_eff}:${native_read}:${native_creation}:${ccusage_eff}:${ccusage_read}:${ccusage_creation}"
}

# ============================================================================
# NATIVE CODE PRODUCTIVITY EXTRACTION (Issue #100)
# ============================================================================
# Extract lines added/removed from Anthropic's native cost object.
# Provides real-time code productivity metrics.

# Extract lines added from Anthropic JSON input
get_native_lines_added() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local lines
    lines=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_lines_added // 0' 2>/dev/null)
    echo "${lines:-0}"
}

# Extract lines removed from Anthropic JSON input
get_native_lines_removed() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local lines
    lines=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null)
    echo "${lines:-0}"
}

# Get formatted code productivity string
# Returns: "+X/-Y" format
get_code_productivity_display() {
    local added removed

    added=$(get_native_lines_added)
    removed=$(get_native_lines_removed)

    # Handle null/empty values
    [[ -z "$added" || "$added" == "null" ]] && added=0
    [[ -z "$removed" || "$removed" == "null" ]] && removed=0

    echo "+${added}/-${removed}"
}

# Export native cost functions
export -f get_native_session_cost get_native_session_duration get_native_api_duration
export -f compare_native_vs_ccusage_cost get_session_cost_with_source

# Export native cache functions
export -f get_native_cache_read_tokens get_native_cache_creation_tokens
export -f get_native_cache_efficiency compare_native_vs_ccusage_cache

# Export native code productivity functions
export -f get_native_lines_added get_native_lines_removed get_code_productivity_display
