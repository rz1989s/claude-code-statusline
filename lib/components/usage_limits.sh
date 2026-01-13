#!/bin/bash

# ============================================================================
# Claude Code Statusline - Usage Limits Component
# ============================================================================
#
# Displays Claude Code rate limit usage from Anthropic's OAuth API.
# Shows 5-hour session usage and 7-day weekly usage percentages.
#
# API Endpoint: https://api.anthropic.com/api/oauth/usage
# Data Source: Anthropic OAuth API (requires token from keychain)
#
# Display Format: 📊 5h: 22% | 7d: 54%
#
# Reference: https://codelynx.dev/posts/claude-code-usage-limits-statusline
# ============================================================================

# Component data storage
COMPONENT_USAGE_FIVE_HOUR=""
COMPONENT_USAGE_SEVEN_DAY=""
COMPONENT_USAGE_FIVE_HOUR_RESET=""
COMPONENT_USAGE_SEVEN_DAY_RESET=""

# Cache TTL for usage API (5 minutes - don't spam the API)
USAGE_LIMITS_CACHE_TTL="${USAGE_LIMITS_CACHE_TTL:-300}"

# ============================================================================
# RESET TIME FORMATTING
# ============================================================================

# Format ISO timestamp to human-readable relative time
# Input: ISO 8601 timestamp (e.g., "2026-01-13T05:59:59.519761+00:00")
# Output: "2h15m" for <24h, "Jan13" for >24h
format_reset_time() {
    local iso_timestamp="$1"

    if [[ -z "$iso_timestamp" || "$iso_timestamp" == "null" ]]; then
        echo ""
        return 1
    fi

    # Parse ISO timestamp to epoch (handle various formats)
    local reset_epoch
    # Remove fractional seconds and normalize timezone for date parsing
    local normalized_ts
    normalized_ts=$(echo "$iso_timestamp" | sed 's/\.[0-9]*//; s/+00:00/Z/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS date command
        reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$normalized_ts" "+%s" 2>/dev/null) ||
        reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$normalized_ts" "+%s" 2>/dev/null)
    else
        # GNU date command (Linux)
        reset_epoch=$(date -d "$iso_timestamp" "+%s" 2>/dev/null)
    fi

    if [[ -z "$reset_epoch" ]]; then
        debug_log "Could not parse reset timestamp: $iso_timestamp" "WARN"
        echo ""
        return 1
    fi

    local now_epoch
    now_epoch=$(date "+%s")

    local diff_seconds=$((reset_epoch - now_epoch))

    # If already past, return empty
    if [[ "$diff_seconds" -le 0 ]]; then
        echo "now"
        return 0
    fi

    # Format based on time remaining
    if [[ "$diff_seconds" -lt 3600 ]]; then
        # Less than 1 hour: show minutes
        local minutes=$((diff_seconds / 60))
        echo "${minutes}m"
    elif [[ "$diff_seconds" -lt 86400 ]]; then
        # Less than 24 hours: show hours and minutes
        local hours=$((diff_seconds / 3600))
        local minutes=$(((diff_seconds % 3600) / 60))
        if [[ "$minutes" -gt 0 ]]; then
            echo "${hours}h${minutes}m"
        else
            echo "${hours}h"
        fi
    else
        # More than 24 hours: show date
        if [[ "$(uname -s)" == "Darwin" ]]; then
            date -j -f "%s" "$reset_epoch" "+%b%d" 2>/dev/null
        else
            date -d "@$reset_epoch" "+%b%d" 2>/dev/null
        fi
    fi
}

# ============================================================================
# OAUTH TOKEN RETRIEVAL
# ============================================================================

# Get OAuth token from macOS Keychain or Linux secret-tool
get_claude_oauth_token() {
    local token=""

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS: Use security command to get from Keychain
        token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    elif command -v secret-tool &>/dev/null; then
        # Linux: Try secret-tool (GNOME Keyring)
        token=$(secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
    fi

    if [[ -n "$token" ]]; then
        # Parse JSON to extract access_token (handle nested structure)
        local access_token
        # Try nested path first (claudeAiOauth.accessToken), then flat paths
        access_token=$(echo "$token" | jq -r '.claudeAiOauth.accessToken // .accessToken // .access_token // empty' 2>/dev/null)

        if [[ -n "$access_token" && "$access_token" != "null" ]]; then
            echo "$access_token"
            return 0
        fi
    fi

    debug_log "Could not retrieve OAuth token from keychain" "WARN"
    echo ""
    return 1
}

# ============================================================================
# USAGE API FETCHING
# ============================================================================

# Fetch usage limits from Anthropic OAuth API
fetch_usage_limits() {
    local token
    token=$(get_claude_oauth_token)

    if [[ -z "$token" ]]; then
        debug_log "No OAuth token available for usage limits" "INFO"
        echo ""
        return 1
    fi

    # Check cache first
    local cache_key="usage_limits_api"
    local cached_result
    cached_result=$(get_cached_value "$cache_key" "$USAGE_LIMITS_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached_result" ]]; then
        debug_log "Using cached usage limits" "INFO"
        echo "$cached_result"
        return 0
    fi

    # Fetch from API
    local response
    response=$(curl -s --max-time 5 \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Accept: application/json" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [[ -n "$response" ]] && echo "$response" | jq -e '.five_hour' &>/dev/null; then
        # Cache the result
        set_cached_value "$cache_key" "$response" 2>/dev/null
        debug_log "Fetched fresh usage limits from API" "INFO"
        echo "$response"
        return 0
    fi

    debug_log "Failed to fetch usage limits from API" "WARN"
    echo ""
    return 1
}

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect usage limits data from Anthropic API
collect_usage_limits_data() {
    debug_log "Collecting usage_limits component data" "INFO"

    COMPONENT_USAGE_FIVE_HOUR=""
    COMPONENT_USAGE_SEVEN_DAY=""
    COMPONENT_USAGE_FIVE_HOUR_RESET=""
    COMPONENT_USAGE_SEVEN_DAY_RESET=""

    local usage_data
    usage_data=$(fetch_usage_limits)

    if [[ -n "$usage_data" ]]; then
        # Extract 5-hour (session) usage
        COMPONENT_USAGE_FIVE_HOUR=$(echo "$usage_data" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
        COMPONENT_USAGE_FIVE_HOUR_RESET=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)

        # Extract 7-day (weekly) usage
        COMPONENT_USAGE_SEVEN_DAY=$(echo "$usage_data" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
        COMPONENT_USAGE_SEVEN_DAY_RESET=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

        # Round percentages to integers
        if [[ -n "$COMPONENT_USAGE_FIVE_HOUR" ]]; then
            COMPONENT_USAGE_FIVE_HOUR=$(printf "%.0f" "$COMPONENT_USAGE_FIVE_HOUR" 2>/dev/null)
        fi
        if [[ -n "$COMPONENT_USAGE_SEVEN_DAY" ]]; then
            COMPONENT_USAGE_SEVEN_DAY=$(printf "%.0f" "$COMPONENT_USAGE_SEVEN_DAY" 2>/dev/null)
        fi

        debug_log "usage_limits data: 5h=${COMPONENT_USAGE_FIVE_HOUR}%, 7d=${COMPONENT_USAGE_SEVEN_DAY}%" "INFO"
    else
        debug_log "No usage limits data available" "INFO"
    fi

    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render usage limits display
render_usage_limits() {
    local theme_enabled="${1:-true}"

    # Skip if no data available
    if [[ -z "$COMPONENT_USAGE_FIVE_HOUR" && -z "$COMPONENT_USAGE_SEVEN_DAY" ]]; then
        return 1  # No content - skip this component
    fi

    # Get thresholds and settings from config
    local warn_threshold="${CONFIG_USAGE_WARN_THRESHOLD:-50}"
    local critical_threshold="${CONFIG_USAGE_CRITICAL_THRESHOLD:-80}"
    local show_reset_times="${CONFIG_USAGE_SHOW_RESET_TIMES:-true}"

    local output=""
    local label="${CONFIG_USAGE_LABEL:-Limit:}"

    # Build output with colors based on usage level
    if [[ -n "$COMPONENT_USAGE_FIVE_HOUR" ]]; then
        local five_hour_color=""
        if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
            if [[ "$COMPONENT_USAGE_FIVE_HOUR" -ge "$critical_threshold" ]]; then
                five_hour_color="${CONFIG_RED:-}"
            elif [[ "$COMPONENT_USAGE_FIVE_HOUR" -ge "$warn_threshold" ]]; then
                five_hour_color="${CONFIG_YELLOW:-}"
            else
                five_hour_color="${CONFIG_GREEN:-}"
            fi
        fi

        local five_hour_reset_str=""
        if [[ "$show_reset_times" == "true" && -n "$COMPONENT_USAGE_FIVE_HOUR_RESET" ]]; then
            local formatted_reset
            formatted_reset=$(format_reset_time "$COMPONENT_USAGE_FIVE_HOUR_RESET")
            if [[ -n "$formatted_reset" ]]; then
                five_hour_reset_str="(↻${formatted_reset})"
            fi
        fi

        output="${label} ${five_hour_color}5h:${COMPONENT_USAGE_FIVE_HOUR}%${five_hour_reset_str}${COLOR_RESET:-}"
    fi

    if [[ -n "$COMPONENT_USAGE_SEVEN_DAY" ]]; then
        local seven_day_color=""
        if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
            if [[ "$COMPONENT_USAGE_SEVEN_DAY" -ge "$critical_threshold" ]]; then
                seven_day_color="${CONFIG_RED:-}"
            elif [[ "$COMPONENT_USAGE_SEVEN_DAY" -ge "$warn_threshold" ]]; then
                seven_day_color="${CONFIG_YELLOW:-}"
            else
                seven_day_color="${CONFIG_GREEN:-}"
            fi
        fi

        local seven_day_reset_str=""
        if [[ "$show_reset_times" == "true" && -n "$COMPONENT_USAGE_SEVEN_DAY_RESET" ]]; then
            local formatted_reset
            formatted_reset=$(format_reset_time "$COMPONENT_USAGE_SEVEN_DAY_RESET")
            if [[ -n "$formatted_reset" ]]; then
                seven_day_reset_str="(↻${formatted_reset})"
            fi
        fi

        if [[ -n "$output" ]]; then
            output="${output} ${seven_day_color}7d:${COMPONENT_USAGE_SEVEN_DAY}%${seven_day_reset_str}${COLOR_RESET:-}"
        else
            output="${label} ${seven_day_color}7d:${COMPONENT_USAGE_SEVEN_DAY}%${seven_day_reset_str}${COLOR_RESET:-}"
        fi
    fi

    echo "$output"
}

# Get usage limits configuration
get_usage_limits_config() {
    local key="${1:-component_name}"
    local default="${2:-}"

    case "$key" in
        "component_name"|"name")
            echo "usage_limits"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_USAGE_LIMITS:-${default:-true}}"
            ;;
        "label")
            echo "${CONFIG_USAGE_LABEL:-${default:-Limit:}}"
            ;;
        "warn_threshold")
            echo "${CONFIG_USAGE_WARN_THRESHOLD:-${default:-50}}"
            ;;
        "critical_threshold")
            echo "${CONFIG_USAGE_CRITICAL_THRESHOLD:-${default:-80}}"
            ;;
        "cache_ttl")
            echo "${USAGE_LIMITS_CACHE_TTL:-${default:-300}}"
            ;;
        "show_reset_times")
            echo "${CONFIG_USAGE_SHOW_RESET_TIMES:-${default:-true}}"
            ;;
        "description")
            echo "Claude Code rate limit usage (5h session, 7d weekly)"
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# ============================================================================
# COMPONENT INTERFACE COMPLIANCE
# ============================================================================

# Component metadata
USAGE_LIMITS_COMPONENT_NAME="usage_limits"
USAGE_LIMITS_COMPONENT_DESCRIPTION="Claude Code rate limit usage (5h session, 7d weekly)"
USAGE_LIMITS_COMPONENT_VERSION="2.15.0"
USAGE_LIMITS_COMPONENT_DEPENDENCIES=("cache")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the usage_limits component
register_component \
    "usage_limits" \
    "Claude Code rate limit usage (5h session, 7d weekly)" \
    "cache" \
    "true"

# Export component functions
export -f get_claude_oauth_token fetch_usage_limits format_reset_time
export -f collect_usage_limits_data render_usage_limits get_usage_limits_config

debug_log "Usage limits component loaded" "INFO"
