#!/bin/bash

# ============================================================================
# Claude Code Statusline - Model Info Component
# ============================================================================
# 
# This component handles Claude model display with emoji indicators.
#
# Dependencies: display.sh
# ============================================================================

# Component data storage
COMPONENT_MODEL_INFO_NAME=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect model information data  
collect_model_info_data() {
    debug_log "Collecting model_info component data" "INFO"
    
    # Model name is passed from main script via JSON input
    COMPONENT_MODEL_INFO_NAME="${model_name:-Claude}"
    
    debug_log "model_info data: name=$COMPONENT_MODEL_INFO_NAME" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render model information display
render_model_info() {
    local formatted_model
    formatted_model=$(format_model_name "$COMPONENT_MODEL_INFO_NAME")
    echo "$formatted_model"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_model_info_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "model_info" "enabled" "${default_value:-true}"
            ;;
        "show_emoji")
            get_component_config "model_info" "show_emoji" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the model_info component
register_component \
    "model_info" \
    "Claude model name with emoji" \
    "display" \
    "$(get_model_info_config 'enabled' 'true')"

debug_log "Model info component loaded" "INFO"