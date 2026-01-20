#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Icon Component
# ============================================================================
#
# Displays a minimalist icon representing the current prayer time.
# Uses circle phases to represent the sun/moon cycle through the day.
#
# Icons:
#   Fajr    → ◐ (dawn breaking)
#   Dhuhr   → ● (full sun)
#   Asr     → ◑ (sun declining)
#   Maghrib → ◒ (sunset)
#   Isha    → ○ (night)
#
# Dependencies: prayer/calculation.sh
# ============================================================================

# Include guard
[[ "${STATUSLINE_PRAYER_ICON_LOADED:-}" == "true" ]] && return 0

# Component data storage (must be global to persist between collect and render phases)
declare -g COMPONENT_PRAYER_ICON_CURRENT=""
declare -g COMPONENT_PRAYER_ICON_INDEX=-1

# ============================================================================
# ICON DEFINITIONS
# ============================================================================

# Prayer icons (minimalist circles representing sun/moon cycle)
declare -gA PRAYER_ICONS=(
    [0]="◐"  # Fajr - dawn breaking (half-filled, light side right)
    [1]="●"  # Dhuhr - full sun (solid circle)
    [2]="◑"  # Asr - sun declining (half-filled, light side left)
    [3]="◒"  # Maghrib - sunset (half-filled, dark side right)
    [4]="○"  # Isha - night (empty circle)
)

# Prayer names for debugging
declare -ga PRAYER_NAMES=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect current prayer data
collect_prayer_icon_data() {
    debug_log "Collecting prayer_icon component data" "INFO"

    COMPONENT_PRAYER_ICON_CURRENT=""
    COMPONENT_PRAYER_ICON_INDEX=-1

    # Only collect if prayer module is loaded and enabled
    if ! is_module_loaded "prayer"; then
        debug_log "Prayer module not loaded for prayer_icon" "WARN"
        return 1
    fi

    if [[ "$(get_prayer_icon_config 'enabled' 'true')" != "true" ]]; then
        debug_log "prayer_icon component disabled" "INFO"
        return 1
    fi

    # Get comprehensive prayer data
    local prayer_data
    if type get_prayer_times_and_hijri &>/dev/null; then
        prayer_data=$(get_prayer_times_and_hijri)
        if [[ $? -ne 0 || -z "$prayer_data" ]]; then
            debug_log "Failed to get prayer data for prayer_icon" "ERROR"
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

    # Extract next prayer info from statuses
    # Format: status1,status2,status3,status4,status5|next_prayer|next_time|next_index
    local next_info="${prayer_statuses#*|}"
    local next_prayer next_prayer_time next_prayer_index
    IFS='|' read -r next_prayer next_prayer_time next_prayer_index <<< "$next_info"

    debug_log "Next prayer: $next_prayer (index: $next_prayer_index)" "DEBUG"

    # Calculate current prayer index (the prayer we're currently in)
    # If next is Fajr (0), we're in Isha (4)
    # Otherwise, current = next - 1
    local current_index
    if [[ "$next_prayer_index" == "0" ]]; then
        current_index=4  # Isha
    else
        current_index=$((next_prayer_index - 1))
    fi

    # Assign to global variables (must use declare -g to persist across function calls)
    declare -g COMPONENT_PRAYER_ICON_INDEX=$current_index
    declare -g COMPONENT_PRAYER_ICON_CURRENT="${PRAYER_NAMES[$current_index]}"

    debug_log "Current prayer: $COMPONENT_PRAYER_ICON_CURRENT (index: $current_index)" "INFO"

    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render prayer icon
render_prayer_icon() {
    if [[ $COMPONENT_PRAYER_ICON_INDEX -lt 0 || $COMPONENT_PRAYER_ICON_INDEX -gt 4 ]]; then
        debug_log "Invalid prayer icon index: $COMPONENT_PRAYER_ICON_INDEX" "WARN"
        echo ""
        return 1
    fi

    local icon="${PRAYER_ICONS[$COMPONENT_PRAYER_ICON_INDEX]}"
    echo "$icon"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_prayer_icon_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "prayer_icon" "enabled" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the prayer_icon component
register_component \
    "prayer_icon" \
    "Dynamic prayer time icon (minimalist circles)" \
    "prayer" \
    "$(get_prayer_icon_config 'enabled' 'true')"

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Export functions
export -f collect_prayer_icon_data 2>/dev/null || true
export -f render_prayer_icon 2>/dev/null || true
export -f get_prayer_icon_config 2>/dev/null || true

# Mark as loaded
STATUSLINE_PRAYER_ICON_LOADED="true"

debug_log "Prayer icon component loaded" "INFO"
