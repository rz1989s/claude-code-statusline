#!/bin/bash

# ============================================================================
# Claude Code Statusline - Weekly Cost Component (Atomic)
# ============================================================================
# 
# This atomic component handles only weekly (7-day) cost display.
# Part of the atomic component refactoring to provide granular control.
#
# Dependencies: cost.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COST_WEEKLY_AMOUNT=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect weekly cost data
collect_cost_weekly_data() {
    debug_log "Collecting cost_weekly component data" "INFO"
    
    # Initialize default
    COMPONENT_COST_WEEKLY_AMOUNT="-.--"
    
    if is_module_loaded "cost"; then
        # Get usage info and parse weekly cost
        # Uses native JSONL calculation
        local usage_info
        usage_info=$(get_claude_usage_info)

        if [[ -n "$usage_info" ]]; then
            # Parse usage info (format: session:month:week:today:block:reset)
            local remaining="$usage_info"

            # Skip session cost
            remaining="${remaining#*:}"
            # Skip month cost
            remaining="${remaining#*:}"

            # Extract week cost
            COMPONENT_COST_WEEKLY_AMOUNT="${remaining%%:*}"
        fi
    fi
    
    debug_log "cost_weekly data: amount=$COMPONENT_COST_WEEKLY_AMOUNT" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render weekly cost display
render_cost_weekly() {
    local show_weekly
    show_weekly=$(get_cost_weekly_config "enabled" "true")
    
    # Return empty if disabled
    if [[ "$show_weekly" != "true" ]]; then
        debug_log "Cost weekly component disabled" "INFO"
        return 0
    fi
    
    # Use display.sh formatting function
    if type format_weekly_cost &>/dev/null; then
        format_weekly_cost "$COMPONENT_COST_WEEKLY_AMOUNT"
    else
        # Fallback formatting
        echo "${CONFIG_WEEKLY_LABEL} \$${COMPONENT_COST_WEEKLY_AMOUNT}"
    fi
    
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get weekly cost-specific configuration
get_cost_weekly_config() {
    local key="$1"
    local default="$2"
    get_component_config "cost_weekly" "$key" "$default"
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the weekly cost component
register_component \
    "cost_weekly" \
    "7-day period cost tracking" \
    "cost display" \
    "$(get_cost_weekly_config 'enabled' 'true')"

debug_log "Cost weekly component (atomic) loaded successfully" "INFO"