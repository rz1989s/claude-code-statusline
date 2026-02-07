#!/bin/bash

# ============================================================================
# Claude Code Statusline - Daily Cost Component (Atomic)
# ============================================================================
# 
# This atomic component handles only daily cost display.
# Part of the atomic component refactoring to provide granular control.
#
# Dependencies: cost.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COST_DAILY_AMOUNT=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect daily cost data
collect_cost_daily_data() {
    debug_log "Collecting cost_daily component data" "INFO"
    
    # Initialize default
    COMPONENT_COST_DAILY_AMOUNT="-.--"
    
    if is_module_loaded "cost"; then
        # Get usage info and parse daily cost
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
            # Skip week cost
            remaining="${remaining#*:}"

            # Extract today cost
            COMPONENT_COST_DAILY_AMOUNT="${remaining%%:*}"
        fi
    fi
    
    debug_log "cost_daily data: amount=$COMPONENT_COST_DAILY_AMOUNT" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render daily cost display
render_cost_daily() {
    local show_daily
    show_daily=$(get_cost_daily_config "enabled" "true")
    
    # Return empty if disabled
    if [[ "$show_daily" != "true" ]]; then
        debug_log "Cost daily component disabled" "INFO"
        return 0
    fi
    
    # Use display.sh formatting function
    if type format_daily_cost &>/dev/null; then
        format_daily_cost "$COMPONENT_COST_DAILY_AMOUNT"
    else
        # Fallback formatting
        echo "${CONFIG_DAILY_LABEL} \$${COMPONENT_COST_DAILY_AMOUNT}"
    fi
    
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get daily cost-specific configuration
get_cost_daily_config() {
    local key="$1"
    local default="$2"
    get_component_config "cost_daily" "$key" "$default"
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the daily cost component
register_component \
    "cost_daily" \
    "Today's cost tracking" \
    "cost display" \
    "$(get_cost_daily_config 'enabled' 'true')"

debug_log "Cost daily component (atomic) loaded successfully" "INFO"