#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Times Component
# ============================================================================
# 
# This component handles Islamic prayer times display.
#
# Dependencies: prayer.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_PRAYER_TIMES_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect prayer times data
collect_prayer_times_data() {
    debug_log "Collecting prayer_times component data" "INFO"
    
    COMPONENT_PRAYER_TIMES_DISPLAY=""
    
    # Only collect if prayer module is loaded and enabled
    if is_module_loaded "prayer" && [[ "$(get_prayer_times_config 'enabled' 'true')" == "true" ]]; then
        if type get_prayer_display &>/dev/null; then
            COMPONENT_PRAYER_TIMES_DISPLAY=$(get_prayer_display)
            
            if [[ $? -ne 0 || -z "$COMPONENT_PRAYER_TIMES_DISPLAY" ]]; then
                COMPONENT_PRAYER_TIMES_DISPLAY=""
            fi
        fi
    fi
    
    debug_log "prayer_times data: display=$COMPONENT_PRAYER_TIMES_DISPLAY" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render prayer times display
render_prayer_times() {
    if [[ -n "$COMPONENT_PRAYER_TIMES_DISPLAY" ]]; then
        echo "$COMPONENT_PRAYER_TIMES_DISPLAY"
        return 0
    else
        return 1  # No content to render
    fi
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_prayer_times_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "prayer_times" "enabled" "${default_value:-true}"
            ;;
        "show_hijri_date")
            get_component_config "prayer_times" "show_hijri_date" "${default_value:-true}"
            ;;
        "compact_mode")
            get_component_config "prayer_times" "compact_mode" "${default_value:-false}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the prayer_times component
register_component \
    "prayer_times" \
    "Islamic prayer times and Hijri calendar" \
    "prayer display" \
    "$(get_prayer_times_config 'enabled' 'true')"

debug_log "Prayer times component loaded" "INFO"