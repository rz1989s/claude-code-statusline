#!/bin/bash

# ============================================================================
# Claude Code Statusline - Burn Rate Component
# ============================================================================
# 
# This component displays token burn rate and cost per hour from active blocks.
# Shows token consumption speed to help users avoid hitting limits unexpectedly.
#
# Dependencies: cost.sh (get_unified_block_metrics), display.sh
# ============================================================================

# Component data storage
COMPONENT_BURN_RATE_INFO=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect burn rate data from unified block metrics
collect_burn_rate_data() {
    debug_log "Collecting burn_rate component data" "INFO"
    
    COMPONENT_BURN_RATE_INFO="$CONFIG_NO_CCUSAGE_MESSAGE"
    
    if is_module_loaded "cost" && is_ccusage_available; then
        # Get unified metrics from single ccusage call (cached 30s)
        local metrics
        metrics=$(get_unified_block_metrics)
        
        if [[ -n "$metrics" && "$metrics" != "0:0:0:0:0:0:0" ]]; then
            # Parse burn rate metrics (fields 1 and 2)
            local burn_rate cost_per_hour
            burn_rate=$(echo "$metrics" | cut -d: -f1)
            cost_per_hour=$(echo "$metrics" | cut -d: -f2)
            
            # Format burn rate display
            if [[ "$burn_rate" != "0" && "$burn_rate" != "null" ]] && [[ "$cost_per_hour" != "0" && "$cost_per_hour" != "null" ]]; then
                local formatted_rate formatted_cost
                formatted_rate=$(format_tokens_per_minute "$burn_rate")
                formatted_cost=$(printf "%.2f" "$cost_per_hour" 2>/dev/null || echo "0.00")
                COMPONENT_BURN_RATE_INFO="🔥\$${formatted_cost}/hr"
            else
                COMPONENT_BURN_RATE_INFO="🔥No active burn"
            fi
        else
            COMPONENT_BURN_RATE_INFO="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
        fi
    fi
    
    debug_log "burn_rate data: info=$COMPONENT_BURN_RATE_INFO" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render burn rate component
render_burn_rate() {
    local theme_enabled="${1:-true}"
    
    # Apply theme colors if enabled
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        # Use orange for burn rate (indicates urgency)
        color_code="$CONFIG_ORANGE"
    fi
    
    # Display the burn rate with color
    echo "${color_code}${COMPONENT_BURN_RATE_INFO}${COLOR_RESET}"
}

# Get burn rate configuration 
get_burn_rate_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    
    case "$key" in
        "component_name"|"name")
            echo "burn_rate"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_COST_TRACKING:-${default:-true}}"
            ;;
        "description")
            echo "Token consumption rate and cost per hour"
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# ============================================================================
# COMPONENT INTERFACE COMPLIANCE
# ============================================================================

# Component metadata
BURN_RATE_COMPONENT_NAME="burn_rate"
BURN_RATE_COMPONENT_DESCRIPTION="Token consumption rate and cost per hour"
BURN_RATE_COMPONENT_VERSION="2.10.0"
BURN_RATE_COMPONENT_DEPENDENCIES=("cost")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the burn_rate component
register_component \
    "burn_rate" \
    "Token consumption rate and cost per hour" \
    "cost display" \
    "true"

# Export component functions
export -f collect_burn_rate_data render_burn_rate get_burn_rate_config