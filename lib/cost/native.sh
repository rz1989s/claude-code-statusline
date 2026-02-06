#!/bin/bash

# ============================================================================
# Claude Code Statusline - Native Cost Extraction Module
# ============================================================================
#
# Extract cost data directly from Anthropic's native statusline JSON input.
# This provides zero-latency cost data from Anthropic's statusline JSON.
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
# This provides real-time cache efficiency from native JSON input.

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
export -f get_session_cost_with_source

# Export native cache functions
export -f get_native_cache_read_tokens get_native_cache_creation_tokens
export -f get_native_cache_efficiency

# Export native code productivity functions
export -f get_native_lines_added get_native_lines_removed get_code_productivity_display
