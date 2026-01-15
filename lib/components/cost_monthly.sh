#!/bin/bash

# ============================================================================
# Claude Code Statusline - Monthly Cost Component (Atomic)
# ============================================================================
# 
# This atomic component handles only monthly (30-day) cost display.
# Part of the atomic component refactoring to provide granular control.
#
# Dependencies: cost.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COST_MONTHLY_AMOUNT=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect monthly cost data
collect_cost_monthly_data() {
    debug_log "Collecting cost_monthly component data" "INFO"
    
    # Initialize default
    COMPONENT_COST_MONTHLY_AMOUNT="-.--"
    
    if is_module_loaded "cost"; then
        # Get usage info and parse monthly cost
        # Uses native JSONL calculation (primary) or ccusage (fallback)
        local usage_info
        usage_info=$(get_claude_usage_info)

        if [[ -n "$usage_info" ]]; then
            # Parse usage info (format: session:month:week:today:block:reset)
            local remaining="$usage_info"

            # Skip session cost
            remaining="${remaining#*:}"

            # Extract month cost
            COMPONENT_COST_MONTHLY_AMOUNT="${remaining%%:*}"
        fi
    fi
    
    debug_log "cost_monthly data: amount=$COMPONENT_COST_MONTHLY_AMOUNT" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render monthly cost display
render_cost_monthly() {
    local show_monthly
    show_monthly=$(get_cost_monthly_config "enabled" "true")
    
    # Return empty if disabled
    if [[ "$show_monthly" != "true" ]]; then
        debug_log "Cost monthly component disabled" "INFO"
        return 0
    fi
    
    # Use display.sh formatting function
    if type format_monthly_cost &>/dev/null; then
        format_monthly_cost "$COMPONENT_COST_MONTHLY_AMOUNT"
    else
        # Fallback formatting
        echo "${CONFIG_MONTHLY_LABEL} \$${COMPONENT_COST_MONTHLY_AMOUNT}"
    fi
    
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get monthly cost-specific configuration
get_cost_monthly_config() {
    local key="$1"
    local default="$2"
    get_component_config "cost_monthly" "$key" "$default"
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the monthly cost component
register_component \
    "cost_monthly" \
    "30-day period cost tracking" \
    "cost display" \
    "$(get_cost_monthly_config 'enabled' 'true')"

debug_log "Cost monthly component (atomic) loaded successfully" "INFO"