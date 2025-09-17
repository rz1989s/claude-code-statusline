#!/bin/bash

# ============================================================================
# Claude Code Statusline - Location Detector Module
# ============================================================================
#
# This module handles location detection and data integration from prayer system
# using privacy-friendly IP geolocation with manual coordinate override.
#
# Dependencies: prayer/location.sh, debug logging functions
# ============================================================================

# Get location data from prayer location system
get_location_data_from_prayer_system() {
    debug_log "Getting location data from prayer location system..." "INFO"

    # Use the prayer system's exported location data if available
    if [[ -n "${STATUSLINE_DETECTED_COORDINATES:-}" ]]; then
        local coordinates="${STATUSLINE_DETECTED_COORDINATES}"
        local method="${STATUSLINE_DETECTION_METHOD:-unknown}"
        local source="${STATUSLINE_VPN_STATUS:-UNKNOWN}"

        debug_log "Using prayer system location: $coordinates via $method ($source)" "INFO"
        echo "$coordinates,$method,$source"
        return 0
    fi

    # Fallback: Try to get fresh coordinates using prayer location functions
    if type get_location_coordinates &>/dev/null; then
        local coordinates
        if coordinates=$(get_location_coordinates); then
            debug_log "Got fresh coordinates from prayer system: $coordinates" "INFO"
            echo "$coordinates,direct_call,FRESH_DATA"
            return 0
        fi
    fi

    debug_log "No location data available from prayer system" "WARN"
    return 1
}