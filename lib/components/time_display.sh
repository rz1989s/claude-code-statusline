#!/bin/bash

# ============================================================================
# Claude Code Statusline - Time Display Component
# ============================================================================
# 
# This component handles current time display with configurable format.
#
# Dependencies: display.sh
# ============================================================================

# Component data storage
COMPONENT_TIME_DISPLAY_TIME=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect current time data
collect_time_display_data() {
    debug_log "Collecting time_display component data" "INFO"
    
    local time_format
    time_format=$(get_time_display_config "format" "$CONFIG_TIME_FORMAT")
    
    COMPONENT_TIME_DISPLAY_TIME=$(date "+$time_format")
    
    debug_log "time_display data: time=$COMPONENT_TIME_DISPLAY_TIME" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render time display
render_time_display() {
    local formatted_time
    formatted_time=$(format_current_time "$(get_time_display_config 'format' "$CONFIG_TIME_FORMAT")")
    echo "$formatted_time"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_time_display_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "time_display" "enabled" "${default_value:-true}"
            ;;
        "format")
            get_component_config "time_display" "format" "${default_value:-%H:%M}"
            ;;
        "show_clock_emoji")
            get_component_config "time_display" "show_clock_emoji" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the time_display component
register_component \
    "time_display" \
    "Current time display" \
    "display" \
    "$(get_time_display_config 'enabled' 'true')"

debug_log "Time display component loaded" "INFO"