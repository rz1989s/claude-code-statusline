#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Live Component
# ============================================================================
# 
# This component handles live block cost display.
#
# Dependencies: cost.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COST_LIVE_BLOCK=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect live block cost data
collect_cost_live_data() {
    debug_log "Collecting cost_live component data" "INFO"
    
    COMPONENT_COST_LIVE_BLOCK="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
    
    if is_module_loaded "cost" && is_ccusage_available; then
        # Get usage info and extract live block cost
        local usage_info
        usage_info=$(get_claude_usage_info)
        
        if [[ -n "$usage_info" ]]; then
            # Parse usage info (format: session:month:week:today:block:reset)
            local remaining="$usage_info"
            
            # Skip to block info (5th field)
            for i in {1..4}; do
                remaining="${remaining#*:}"
            done
            
            # Extract block info
            COMPONENT_COST_LIVE_BLOCK="${remaining%%:*}"
        fi
    fi
    
    debug_log "cost_live data: block=$COMPONENT_COST_LIVE_BLOCK" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render live block cost display
render_cost_live() {
    # Only render if there's an active block
    if [[ "$COMPONENT_COST_LIVE_BLOCK" != "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE" ]]; then
        local formatted_live
        formatted_live=$(format_live_block_cost "$COMPONENT_COST_LIVE_BLOCK")
        echo "$formatted_live"
        return 0
    else
        return 1  # No content to render
    fi
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_cost_live_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "cost_live" "enabled" "${default_value:-true}"
            ;;
        "hide_when_inactive")
            get_component_config "cost_live" "hide_when_inactive" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the cost_live component
register_component \
    "cost_live" \
    "Live block cost (when active)" \
    "cost display" \
    "$(get_cost_live_config 'enabled' 'true')"

debug_log "Cost live component loaded" "INFO"