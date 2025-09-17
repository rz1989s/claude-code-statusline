#!/bin/bash

# ============================================================================
# Claude Code Statusline - Location Fallback Module
# ============================================================================
#
# This module handles component data collection and fallback logic
# for location detection when primary methods fail.
#
# Dependencies: detector.sh, database.sh, debug logging functions
# ============================================================================

# Collect location display data - SIMPLIFIED (No VPN Detection)
collect_location_display_data() {
    debug_log "Collecting location_display component data" "INFO"

    # Get location data from the prayer system (uses IP geolocation or manual coordinates)
    local location_data
    if location_data=$(get_location_data_from_prayer_system); then
        # Parse the returned data: coordinates,method,source
        local coordinates=$(echo "$location_data" | cut -d',' -f1-2)
        local method=$(echo "$location_data" | cut -d',' -f3)
        local source=$(echo "$location_data" | cut -d',' -f4)

        COMPONENT_LOCATION_DISPLAY_COORDINATES="$coordinates"
        COMPONENT_LOCATION_DISPLAY_METHOD="$method"

        # Set confidence based on method
        case "$method" in
            "ip_geolocation") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="85" ;;
            "manual") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="100" ;;
            "ip_geolocation"|"direct_call") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="85" ;;
            "cached_location") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="80" ;;
            "timezone_fallback") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="70" ;;
            *) COMPONENT_LOCATION_DISPLAY_CONFIDENCE="60" ;;
        esac

        debug_log "Using coordinates from prayer system: $coordinates via $method (confidence: ${COMPONENT_LOCATION_DISPLAY_CONFIDENCE}%)" "INFO"
    else
        # Ultimate fallback to Jakarta if prayer system fails
        debug_log "Prayer system location unavailable, using Jakarta fallback" "WARN"
        COMPONENT_LOCATION_DISPLAY_COORDINATES="-6.2088,106.8456"
        COMPONENT_LOCATION_DISPLAY_METHOD="ultimate_fallback"
        COMPONENT_LOCATION_DISPLAY_CONFIDENCE="50"
    fi

    # Extract city from coordinates
    local latitude="${coordinates%%,*}"
    local longitude="${coordinates##*,}"
    COMPONENT_LOCATION_DISPLAY_CITY=$(get_city_from_coordinates "$latitude" "$longitude")

    debug_log "location_display data: city=$COMPONENT_LOCATION_DISPLAY_CITY, method=$COMPONENT_LOCATION_DISPLAY_METHOD, confidence=$COMPONENT_LOCATION_DISPLAY_CONFIDENCE" "INFO"
    return 0
}