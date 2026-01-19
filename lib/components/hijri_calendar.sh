#!/bin/bash

# ============================================================================
# Claude Code Statusline - Hijri Calendar Component
# ============================================================================
#
# This component displays Hijri calendar with dynamic moon phase icon,
# Gregorian date, and location information on a single line.
#
# Output: 🕌 1 Sha'ban 1447 🌓 │ Jan 20 2026 │ 📍 Loc: Southeast Asia
#
# Dependencies: prayer/display.sh, prayer/core.sh, location_display.sh
# ============================================================================

# Component data storage
COMPONENT_HIJRI_CALENDAR_HIJRI_DATE=""
COMPONENT_HIJRI_CALENDAR_HIJRI_DAY=""
COMPONENT_HIJRI_CALENDAR_MOON_PHASE=""
COMPONENT_HIJRI_CALENDAR_GREGORIAN_DATE=""
COMPONENT_HIJRI_CALENDAR_LOCATION=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect Hijri calendar data
collect_hijri_calendar_data() {
    debug_log "Collecting hijri_calendar component data" "INFO"

    COMPONENT_HIJRI_CALENDAR_HIJRI_DATE=""
    COMPONENT_HIJRI_CALENDAR_HIJRI_DAY=""
    COMPONENT_HIJRI_CALENDAR_MOON_PHASE=""
    COMPONENT_HIJRI_CALENDAR_GREGORIAN_DATE=""
    COMPONENT_HIJRI_CALENDAR_LOCATION=""

    # Only collect if prayer module is loaded and enabled
    if ! is_module_loaded "prayer"; then
        debug_log "Prayer module not loaded" "WARN"
        return 1
    fi

    # Get comprehensive prayer data for Hijri date
    local prayer_data
    if type get_prayer_times_and_hijri &>/dev/null; then
        prayer_data=$(get_prayer_times_and_hijri)
        if [[ $? -ne 0 || -z "$prayer_data" ]]; then
            debug_log "Failed to get prayer data for hijri_calendar" "ERROR"
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

    # Parse Hijri date components: day,month,year,weekday
    local hijri_day hijri_month hijri_year hijri_weekday
    IFS=',' read -r hijri_day hijri_month hijri_year hijri_weekday <<< "$hijri_date"

    if [[ -z "$hijri_day" || -z "$hijri_month" || -z "$hijri_year" ]]; then
        debug_log "Invalid Hijri date components" "ERROR"
        return 1
    fi

    # Store Hijri date
    COMPONENT_HIJRI_CALENDAR_HIJRI_DATE="${hijri_day} ${hijri_month} ${hijri_year}"
    COMPONENT_HIJRI_CALENDAR_HIJRI_DAY="$hijri_day"

    # Get moon phase icon based on Hijri day
    if type get_moon_phase_icon &>/dev/null; then
        COMPONENT_HIJRI_CALENDAR_MOON_PHASE=$(get_moon_phase_icon "$hijri_day")
    else
        COMPONENT_HIJRI_CALENDAR_MOON_PHASE="🌙"
    fi

    # Get Gregorian date
    if [[ "$(get_hijri_calendar_config 'show_gregorian' 'true')" == "true" ]]; then
        COMPONENT_HIJRI_CALENDAR_GREGORIAN_DATE=$(date "+%b %d %Y")
    fi

    # Get location from location_display component or prayer system
    if [[ -n "${COMPONENT_LOCATION_DISPLAY_CITY:-}" ]]; then
        COMPONENT_HIJRI_CALENDAR_LOCATION="$COMPONENT_LOCATION_DISPLAY_CITY"
    elif [[ -n "${STATUSLINE_DETECTED_COORDINATES:-}" ]]; then
        # Try to get city from coordinates
        local coordinates="${STATUSLINE_DETECTED_COORDINATES}"
        local latitude="${coordinates%%,*}"
        local longitude="${coordinates##*,}"
        if type get_city_from_coordinates &>/dev/null; then
            COMPONENT_HIJRI_CALENDAR_LOCATION=$(get_city_from_coordinates "$latitude" "$longitude")
        fi
    fi

    debug_log "hijri_calendar data: hijri=$COMPONENT_HIJRI_CALENDAR_HIJRI_DATE, day=$COMPONENT_HIJRI_CALENDAR_HIJRI_DAY, moon=$COMPONENT_HIJRI_CALENDAR_MOON_PHASE, gregorian=$COMPONENT_HIJRI_CALENDAR_GREGORIAN_DATE, location=$COMPONENT_HIJRI_CALENDAR_LOCATION" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render Hijri calendar display
# Output: 🕌 1 Sha'ban 1447 🌓 │ Jan 20 2026 │ 📍 Loc: Southeast Asia
render_hijri_calendar() {
    if [[ -z "$COMPONENT_HIJRI_CALENDAR_HIJRI_DATE" ]]; then
        return 1  # No content to render
    fi

    local display=""

    # Build Hijri date with mosque indicator
    local hijri_indicator="${HIJRI_INDICATOR:-🕌}"
    display="${hijri_indicator} ${COMPONENT_HIJRI_CALENDAR_HIJRI_DATE}"

    # Add moon phase icon if enabled
    if [[ "$(get_hijri_calendar_config 'show_moon_phase' 'true')" == "true" ]]; then
        display="${display} ${COMPONENT_HIJRI_CALENDAR_MOON_PHASE}"
    fi

    # Add Gregorian date if available and enabled
    if [[ -n "$COMPONENT_HIJRI_CALENDAR_GREGORIAN_DATE" ]]; then
        display="${display} │ ${COMPONENT_HIJRI_CALENDAR_GREGORIAN_DATE}"
    fi

    # Add location if available
    if [[ -n "$COMPONENT_HIJRI_CALENDAR_LOCATION" ]]; then
        display="${display} │ 📍 Loc: ${COMPONENT_HIJRI_CALENDAR_LOCATION}"
    fi

    echo "$display"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_hijri_calendar_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "hijri_calendar" "enabled" "${default_value:-true}"
            ;;
        "show_moon_phase")
            get_component_config "hijri_calendar" "show_moon_phase" "${default_value:-true}"
            ;;
        "show_gregorian")
            get_component_config "hijri_calendar" "show_gregorian" "${default_value:-true}"
            ;;
        "show_location")
            get_component_config "hijri_calendar" "show_location" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the hijri_calendar component
register_component \
    "hijri_calendar" \
    "Hijri calendar with moon phase, Gregorian date, and location" \
    "prayer display" \
    "$(get_hijri_calendar_config 'enabled' 'true')"

debug_log "Hijri calendar component loaded" "INFO"
