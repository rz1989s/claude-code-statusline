#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Alerts Module
# ============================================================================
#
# Monitor costs against configured thresholds and provide visual warnings
# and optional desktop notifications when limits are approached/exceeded.
#
# Split from cost.sh as part of Issue #132.
# Implements Issue #93
#
# Dependencies: core.sh, cost/core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_ALERTS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_ALERTS_LOADED=true

# ============================================================================
# COST THRESHOLD ALERTS CONFIGURATION
# ============================================================================

# Configuration defaults for cost alerts
CONFIG_COST_ALERTS_ENABLED="${CONFIG_COST_ALERTS_ENABLED:-false}"
CONFIG_COST_DAILY_THRESHOLD="${CONFIG_COST_DAILY_THRESHOLD:-5.00}"
CONFIG_COST_WEEKLY_THRESHOLD="${CONFIG_COST_WEEKLY_THRESHOLD:-25.00}"
CONFIG_COST_MONTHLY_THRESHOLD="${CONFIG_COST_MONTHLY_THRESHOLD:-100.00}"
CONFIG_COST_SESSION_THRESHOLD="${CONFIG_COST_SESSION_THRESHOLD:-2.00}"
CONFIG_COST_WARN_PERCENT="${CONFIG_COST_WARN_PERCENT:-80}"
CONFIG_COST_CRITICAL_PERCENT="${CONFIG_COST_CRITICAL_PERCENT:-100}"
CONFIG_COST_DESKTOP_NOTIFY="${CONFIG_COST_DESKTOP_NOTIFY:-false}"
CONFIG_COST_NOTIFY_COOLDOWN="${CONFIG_COST_NOTIFY_COOLDOWN:-300}"
CONFIG_COST_NOTIFY_ON_WARN="${CONFIG_COST_NOTIFY_ON_WARN:-false}"
CONFIG_COST_NOTIFY_ON_CRITICAL="${CONFIG_COST_NOTIFY_ON_CRITICAL:-true}"

# Cost alert state tracking (prevents notification spam)
COST_ALERT_LAST_NOTIFY_FILE="${CACHE_BASE_DIR:-${HOME:-/tmp}/.cache/claude-code-statusline}/cost_alert_last_notify"

# ============================================================================
# COST ALERT DETECTION
# ============================================================================

# Check if cost alerts are enabled
is_cost_alerts_enabled() {
    [[ "${CONFIG_COST_ALERTS_ENABLED:-false}" == "true" ]]
}

# Calculate cost percentage against threshold
# Returns: percentage (0-100+), or "N/A" if invalid
get_cost_percentage() {
    local cost="$1"
    local threshold="$2"

    # Validate inputs
    if [[ -z "$cost" || "$cost" == "-.--" || -z "$threshold" || "$threshold" == "0" ]]; then
        echo "0"
        return 1
    fi

    local percentage
    percentage=$(awk "BEGIN {printf \"%.0f\", ($cost / $threshold) * 100}" 2>/dev/null)
    echo "${percentage:-0}"
}

# Determine alert level for a cost value
# Returns: "normal", "warn", or "critical"
get_cost_alert_level() {
    local cost="$1"
    local threshold="$2"
    local warn_percent="${CONFIG_COST_WARN_PERCENT:-80}"
    local critical_percent="${CONFIG_COST_CRITICAL_PERCENT:-100}"

    if ! is_cost_alerts_enabled; then
        echo "normal"
        return 0
    fi

    local percentage
    percentage=$(get_cost_percentage "$cost" "$threshold")

    if [[ "$percentage" -ge "$critical_percent" ]]; then
        echo "critical"
    elif [[ "$percentage" -ge "$warn_percent" ]]; then
        echo "warn"
    else
        echo "normal"
    fi
}

# Get color code for cost display based on alert level
# Returns: ANSI color escape sequence
get_cost_alert_color() {
    local alert_level="$1"

    case "$alert_level" in
        "critical")
            # Red for critical
            echo "${CONFIG_RED:-\033[31m}"
            ;;
        "warn")
            # Yellow for warning
            echo "${CONFIG_YELLOW:-\033[33m}"
            ;;
        *)
            # Default color (green for normal)
            echo "${CONFIG_GREEN:-\033[32m}"
            ;;
    esac
}

# Check all cost thresholds and return highest alert level
# Returns: "normal", "warn", or "critical"
check_all_cost_thresholds() {
    local session_cost="$1"
    local daily_cost="$2"
    local weekly_cost="$3"
    local monthly_cost="$4"

    if ! is_cost_alerts_enabled; then
        echo "normal"
        return 0
    fi

    local highest_level="normal"

    # Check session threshold
    local session_level
    session_level=$(get_cost_alert_level "$session_cost" "$CONFIG_COST_SESSION_THRESHOLD")
    [[ "$session_level" == "critical" ]] && highest_level="critical"
    [[ "$session_level" == "warn" && "$highest_level" != "critical" ]] && highest_level="warn"

    # Check daily threshold
    local daily_level
    daily_level=$(get_cost_alert_level "$daily_cost" "$CONFIG_COST_DAILY_THRESHOLD")
    [[ "$daily_level" == "critical" ]] && highest_level="critical"
    [[ "$daily_level" == "warn" && "$highest_level" != "critical" ]] && highest_level="warn"

    # Check weekly threshold
    local weekly_level
    weekly_level=$(get_cost_alert_level "$weekly_cost" "$CONFIG_COST_WEEKLY_THRESHOLD")
    [[ "$weekly_level" == "critical" ]] && highest_level="critical"
    [[ "$weekly_level" == "warn" && "$highest_level" != "critical" ]] && highest_level="warn"

    # Check monthly threshold
    local monthly_level
    monthly_level=$(get_cost_alert_level "$monthly_cost" "$CONFIG_COST_MONTHLY_THRESHOLD")
    [[ "$monthly_level" == "critical" ]] && highest_level="critical"
    [[ "$monthly_level" == "warn" && "$highest_level" != "critical" ]] && highest_level="warn"

    echo "$highest_level"
}

# ============================================================================
# DESKTOP NOTIFICATIONS
# ============================================================================

# Send desktop notification (cross-platform)
send_cost_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"  # low, normal, critical

    if [[ "${CONFIG_COST_DESKTOP_NOTIFY:-false}" != "true" ]]; then
        return 0
    fi

    # macOS notification
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null &
        return 0
    fi

    # Linux notification (notify-send)
    if command_exists notify-send; then
        notify-send -u "$urgency" "$title" "$message" 2>/dev/null &
        return 0
    fi

    debug_log "No notification system available" "WARN"
    return 1
}

# Check notification cooldown (prevent spam)
is_notification_cooldown_expired() {
    local cooldown="${CONFIG_COST_NOTIFY_COOLDOWN:-300}"

    if [[ ! -f "$COST_ALERT_LAST_NOTIFY_FILE" ]]; then
        return 0  # No previous notification, cooldown expired
    fi

    local last_notify_time current_time elapsed
    last_notify_time=$(cat "$COST_ALERT_LAST_NOTIFY_FILE" 2>/dev/null)
    current_time=$(date +%s)

    if [[ -z "$last_notify_time" ]]; then
        return 0
    fi

    elapsed=$((current_time - last_notify_time))

    if [[ "$elapsed" -ge "$cooldown" ]]; then
        return 0  # Cooldown expired
    else
        debug_log "Notification cooldown active: ${elapsed}s / ${cooldown}s" "INFO"
        return 1  # Still in cooldown
    fi
}

# Update notification timestamp
update_notification_timestamp() {
    local dir
    dir=$(dirname "$COST_ALERT_LAST_NOTIFY_FILE")
    [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null
    date +%s > "$COST_ALERT_LAST_NOTIFY_FILE" 2>/dev/null
}

# Process cost alerts and send notifications if needed
process_cost_alerts() {
    local session_cost="$1"
    local daily_cost="$2"
    local weekly_cost="$3"
    local monthly_cost="$4"

    if ! is_cost_alerts_enabled; then
        return 0
    fi

    local alert_level
    alert_level=$(check_all_cost_thresholds "$session_cost" "$daily_cost" "$weekly_cost" "$monthly_cost")

    # Determine if notification should be sent
    local should_notify=false

    if [[ "$alert_level" == "critical" && "${CONFIG_COST_NOTIFY_ON_CRITICAL:-true}" == "true" ]]; then
        should_notify=true
    elif [[ "$alert_level" == "warn" && "${CONFIG_COST_NOTIFY_ON_WARN:-false}" == "true" ]]; then
        should_notify=true
    fi

    # Send notification if conditions met and cooldown expired
    if [[ "$should_notify" == "true" ]] && is_notification_cooldown_expired; then
        local title message urgency

        if [[ "$alert_level" == "critical" ]]; then
            title="💸 Cost Threshold Exceeded!"
            message="Daily: \$${daily_cost} | Monthly: \$${monthly_cost}"
            urgency="critical"
        else
            title="⚠️ Cost Warning"
            message="Approaching threshold - Daily: \$${daily_cost}"
            urgency="normal"
        fi

        send_cost_notification "$title" "$message" "$urgency"
        update_notification_timestamp

        debug_log "Cost alert notification sent: $alert_level" "INFO"
    fi

    echo "$alert_level"
}

# ============================================================================
# COST FORMATTING WITH ALERTS
# ============================================================================

# Format cost for display
format_cost() {
    local cost="$1"
    local prefix="${2:-\$}"

    if [[ "$cost" == "-.--" ]] || [[ -z "$cost" ]]; then
        echo "${prefix}-.--"
    else
        printf "%s%.2f" "$prefix" "$cost" 2>/dev/null || echo "${prefix}-.--"
    fi
}

# Get cost trend (increase/decrease from previous period)
get_cost_trend() {
    local current_cost="$1"
    local previous_cost="$2"

    if [[ "$current_cost" == "-.--" ]] || [[ "$previous_cost" == "-.--" ]]; then
        echo "unknown"
        return 1
    fi

    if command_exists bc; then
        local diff
        diff=$(echo "$current_cost - $previous_cost" | bc -l 2>/dev/null)

        if [[ "$diff" =~ ^- ]]; then
            echo "down"
        elif [[ "$diff" =~ ^0.?0*$ ]]; then
            echo "stable"
        else
            echo "up"
        fi
    else
        echo "unknown"
    fi
}

# Get formatted cost with alert coloring
format_cost_with_alert() {
    local cost="$1"
    local threshold="$2"
    local prefix="${3:-\$}"

    if ! is_cost_alerts_enabled; then
        format_cost "$cost" "$prefix"
        return 0
    fi

    local alert_level color reset
    alert_level=$(get_cost_alert_level "$cost" "$threshold")
    color=$(get_cost_alert_color "$alert_level")
    reset="${CONFIG_RESET:-\033[0m}"

    if [[ "$cost" == "-.--" ]] || [[ -z "$cost" ]]; then
        echo "${prefix}-.--"
    else
        printf "%s%s%.2f%s" "$color" "$prefix" "$cost" "$reset" 2>/dev/null || echo "${prefix}-.--"
    fi
}

# Get cost status summary with indicators
get_cost_status_summary() {
    local session_cost="$1"
    local daily_cost="$2"
    local weekly_cost="$3"
    local monthly_cost="$4"

    if ! is_cost_alerts_enabled; then
        echo ""
        return 0
    fi

    local alert_level
    alert_level=$(check_all_cost_thresholds "$session_cost" "$daily_cost" "$weekly_cost" "$monthly_cost")

    case "$alert_level" in
        "critical")
            echo " 🔴"
            ;;
        "warn")
            echo " ⚠️"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Export cost alert functions
export -f is_cost_alerts_enabled get_cost_percentage get_cost_alert_level
export -f get_cost_alert_color check_all_cost_thresholds
export -f send_cost_notification is_notification_cooldown_expired update_notification_timestamp
export -f process_cost_alerts format_cost format_cost_with_alert get_cost_trend get_cost_status_summary
