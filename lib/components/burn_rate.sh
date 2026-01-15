#!/bin/bash

# ============================================================================
# Claude Code Statusline - Burn Rate Component
# ============================================================================
# 
# This component displays token burn rate and cost per hour from active blocks.
# Shows token consumption speed to help users avoid hitting limits unexpectedly.
#
# Dependencies: cost.sh (native burn rate from api_live.sh), display.sh
# ============================================================================

# Component data storage
COMPONENT_BURN_RATE_INFO=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect burn rate data from native JSONL calculation
collect_burn_rate_data() {
    debug_log "Collecting burn_rate component data" "INFO"

    COMPONENT_BURN_RATE_INFO="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"

    if is_module_loaded "cost"; then
        # Get native burn rate from JSONL (cached 30s)
        if declare -f get_cached_native_burn_rate &>/dev/null; then
            local burn_rate_data
            burn_rate_data=$(get_cached_native_burn_rate)

            if [[ -n "$burn_rate_data" && "$burn_rate_data" != "0:0.00" ]]; then
                # Parse burn rate metrics (tokens_per_minute:cost_per_hour)
                local tokens_per_minute cost_per_hour
                IFS=':' read -r tokens_per_minute cost_per_hour <<< "$burn_rate_data"

                # Format burn rate display
                if [[ "$tokens_per_minute" != "0" && -n "$cost_per_hour" && "$cost_per_hour" != "0.00" ]]; then
                    local formatted_cost
                    formatted_cost=$(printf "%.2f" "$cost_per_hour" 2>/dev/null || echo "0.00")
                    COMPONENT_BURN_RATE_INFO="🔥\$${formatted_cost}/hr"
                else
                    COMPONENT_BURN_RATE_INFO="🔥No active burn"
                fi
            fi
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