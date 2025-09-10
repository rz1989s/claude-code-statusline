#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Session Component
# ============================================================================
# 
# This component handles repository session cost display.
#
# Dependencies: cost.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COST_SESSION_COST=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect session cost data
collect_cost_session_data() {
    debug_log "Collecting cost_session component data" "INFO"
    
    COMPONENT_COST_SESSION_COST="-.--"
    
    if is_module_loaded "cost" && is_ccusage_available; then
        # Get usage info and extract session cost
        local usage_info
        usage_info=$(get_claude_usage_info)
        
        if [[ -n "$usage_info" ]]; then
            # Parse usage info (format: session:month:week:today:block:reset)
            COMPONENT_COST_SESSION_COST="${usage_info%%:*}"
        fi
    fi
    
    debug_log "cost_session data: cost=$COMPONENT_COST_SESSION_COST" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render session cost display
render_cost_session() {
    local formatted_cost
    formatted_cost=$(format_session_cost "$COMPONENT_COST_SESSION_COST")
    echo "$formatted_cost"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_cost_session_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "cost_session" "enabled" "${default_value:-true}"
            ;;
        "label")
            get_component_config "cost_session" "label" "${default_value:-$CONFIG_REPO_LABEL}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the cost_session component
register_component \
    "cost_session" \
    "Repository session cost" \
    "cost display" \
    "$(get_cost_session_config 'enabled' 'true')"

debug_log "Cost session component loaded" "INFO"