#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Times Only Component
# ============================================================================
#
# This component displays Islamic prayer times without the Hijri calendar.
# Uses the same logic as the original prayer_times component for full
# feature parity (time remaining, status indicators, colors, etc.)
#
# Output: Fajr 04:27 ✓ │ Dhuhr 12:03 (6h 15m) │ Asr 15:26 │ Maghrib 18:16 │ Isha 19:30
#
# Dependencies: prayer/display.sh, prayer/core.sh, prayer/calculation.sh
# ============================================================================

# Component data storage
COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect prayer times data (without Hijri date)
collect_prayer_times_only_data() {
    debug_log "Collecting prayer_times_only component data" "INFO"

    COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=""

    # Only collect if prayer module is loaded and enabled
    if ! is_module_loaded "prayer"; then
        debug_log "Prayer module not loaded for prayer_times_only" "WARN"
        return 1
    fi

    if [[ "$(get_prayer_times_only_config 'enabled' 'true')" != "true" ]]; then
        debug_log "prayer_times_only component disabled" "INFO"
        return 1
    fi

    # Get comprehensive prayer data
    local prayer_data
    if type get_prayer_times_and_hijri &>/dev/null; then
        prayer_data=$(get_prayer_times_and_hijri)
        if [[ $? -ne 0 || -z "$prayer_data" ]]; then
            debug_log "Failed to get prayer data for prayer_times_only" "ERROR"
            return 1
        fi
    else
        debug_log "get_prayer_times_and_hijri not available" "ERROR"
        return 1
    fi

    # Parse prayer data using tab delimiter
    # Format: prayer_times\tprayer_statuses\thijri_date\tcurrent_time
    local prayer_times prayer_statuses hijri_date current_time
    IFS=$'\t' read -r prayer_times prayer_statuses hijri_date current_time <<< "$prayer_data"

    debug_log "Processing prayer data: times=[$prayer_times], statuses=[$prayer_statuses]" "DEBUG"

    # Format prayer times using the existing display function (same as original prayer_times)
    if type format_prayer_times_display &>/dev/null; then
        COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=$(format_prayer_times_display "$prayer_times" "$prayer_statuses" "$current_time")
        if [[ $? -ne 0 || -z "$COMPONENT_PRAYER_TIMES_ONLY_DISPLAY" ]]; then
            debug_log "Failed to format prayer times display" "ERROR"
            COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=""
            return 1
        fi
    else
        debug_log "format_prayer_times_display not available" "ERROR"
        return 1
    fi

    debug_log "prayer_times_only data: display=$COMPONENT_PRAYER_TIMES_ONLY_DISPLAY" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render prayer times display (without Hijri date)
render_prayer_times_only() {
    if [[ -n "$COMPONENT_PRAYER_TIMES_ONLY_DISPLAY" ]]; then
        echo "$COMPONENT_PRAYER_TIMES_ONLY_DISPLAY"
        return 0
    else
        return 1  # No content to render
    fi
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_prayer_times_only_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "prayer_times_only" "enabled" "${default_value:-true}"
            ;;
        "compact_mode")
            # Use same config as prayer_times for consistency
            get_component_config "prayer_times_only" "compact_mode" "${default_value:-false}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the prayer_times_only component
register_component \
    "prayer_times_only" \
    "Islamic prayer times display (without Hijri calendar)" \
    "prayer display" \
    "$(get_prayer_times_only_config 'enabled' 'true')"

debug_log "Prayer times only component loaded" "INFO"
