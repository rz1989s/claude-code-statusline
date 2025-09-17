#!/bin/bash

# ============================================================================
# Claude Code Statusline - Location Display Component (Main Module)
# ============================================================================
#
# This component displays detected location for prayer time calculations
# using privacy-friendly IP geolocation with manual coordinate override.
#
# Dependencies: display.sh, prayer/location.sh, prayer/core.sh
# ============================================================================

# Component data storage
COMPONENT_LOCATION_DISPLAY_CITY=""
COMPONENT_LOCATION_DISPLAY_METHOD=""
# REMOVED: VPN status tracking no longer needed
COMPONENT_LOCATION_DISPLAY_CONFIDENCE=""
COMPONENT_LOCATION_DISPLAY_COORDINATES=""

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize location display module by sourcing dependencies
location_display_init() {
    local location_dir="$(dirname "${BASH_SOURCE[0]}")"

    # Source database module
    if [[ -f "$location_dir/database.sh" ]]; then
        source "$location_dir/database.sh"
    else
        debug_log "Warning: Location database module not found" "WARN"
        return 1
    fi

    # Source detector module
    if [[ -f "$location_dir/detector.sh" ]]; then
        source "$location_dir/detector.sh"
    else
        debug_log "Warning: Location detector module not found" "WARN"
        return 1
    fi

    # Source fallback module
    if [[ -f "$location_dir/fallback.sh" ]]; then
        source "$location_dir/fallback.sh"
    else
        debug_log "Warning: Location fallback module not found" "WARN"
        return 1
    fi

    debug_log "Location display modules initialized successfully" "INFO"
    return 0
}

# Call initialization when module loads
location_display_init

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render location display
render_location_display() {
    local display_format
    display_format=$(get_location_display_config "format" "short")

    # Note: VPN usage will affect IP-based location accuracy

    local show_confidence
    show_confidence=$(get_location_display_config "show_confidence" "false")

    # Build base display
    local location_text="Loc: ${COMPONENT_LOCATION_DISPLAY_CITY}"

    # Add format variations
    case "$display_format" in
        "full")
            case "$COMPONENT_LOCATION_DISPLAY_CITY" in
                "Jakarta") location_text="Loc: Jakarta, DKI Jakarta, Indonesia" ;;
                "Bekasi") location_text="Loc: Bekasi, West Java, Indonesia" ;;
                "Surabaya") location_text="Loc: Surabaya, East Java, Indonesia" ;;
                "Bandung") location_text="Loc: Bandung, West Java, Indonesia" ;;
                *) location_text="Loc: ${COMPONENT_LOCATION_DISPLAY_CITY}" ;;
            esac
            ;;
        "short"|*)
            location_text="Loc: ${COMPONENT_LOCATION_DISPLAY_CITY}"
            ;;
    esac

    # Note: Manual coordinates provide the highest accuracy

    # Add confidence indicator
    if [[ "$show_confidence" == "true" ]]; then
        location_text="${location_text} [${COMPONENT_LOCATION_DISPLAY_CONFIDENCE}%]"
    fi

    # Add method indicator for debugging (only if debug enabled)
    if [[ "${STATUSLINE_DEBUG:-}" == "true" ]]; then
        location_text="${location_text} (${COMPONENT_LOCATION_DISPLAY_METHOD})"
    fi

    echo "$location_text"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_location_display_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "location_display" "enabled" "${default_value:-true}"
            ;;
        "format")
            # short, full
            get_component_config "location_display" "format" "${default_value:-short}"
            ;;
        # REMOVED: show_vpn_indicator config option no longer needed
        "show_vpn_indicator")
            echo "false"  # Always false - VPN detection removed
            ;;
        "show_confidence")
            get_component_config "location_display" "show_confidence" "${default_value:-false}"
            ;;
        "icon")
            get_component_config "location_display" "icon" "${default_value:-Loc}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the location_display component
register_component \
    "location_display" \
    "Location detection display with VPN awareness" \
    "prayer/location,display" \
    "$(get_location_display_config 'enabled' 'true')"