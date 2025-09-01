#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Period Component
# ============================================================================
# 
# This component handles periodic cost displays (30day, 7day, daily).
#
# Dependencies: cost.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COST_PERIOD_MONTH=""
COMPONENT_COST_PERIOD_WEEK=""
COMPONENT_COST_PERIOD_TODAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect period cost data
collect_cost_period_data() {
    debug_log "Collecting cost_period component data" "INFO"
    
    # Initialize defaults
    COMPONENT_COST_PERIOD_MONTH="-.--"
    COMPONENT_COST_PERIOD_WEEK="-.--"  
    COMPONENT_COST_PERIOD_TODAY="-.--"
    
    if is_module_loaded "cost" && is_ccusage_available; then
        # Get usage info and parse period costs
        local usage_info
        usage_info=$(get_claude_usage_info)
        
        if [[ -n "$usage_info" ]]; then
            # Parse usage info (format: session:month:week:today:block:reset)
            local remaining="$usage_info"
            
            # Skip session cost
            remaining="${remaining#*:}"
            
            # Extract month cost
            COMPONENT_COST_PERIOD_MONTH="${remaining%%:*}"
            remaining="${remaining#*:}"
            
            # Extract week cost
            COMPONENT_COST_PERIOD_WEEK="${remaining%%:*}"
            remaining="${remaining#*:}"
            
            # Extract today cost
            COMPONENT_COST_PERIOD_TODAY="${remaining%%:*}"
        fi
    fi
    
    debug_log "cost_period data: month=$COMPONENT_COST_PERIOD_MONTH, week=$COMPONENT_COST_PERIOD_WEEK, today=$COMPONENT_COST_PERIOD_TODAY" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render period costs display
render_cost_period() {
    local output=""
    local show_monthly show_weekly show_daily
    
    show_monthly=$(get_cost_period_config "show_monthly" "true")
    show_weekly=$(get_cost_period_config "show_weekly" "true")
    show_daily=$(get_cost_period_config "show_daily" "true")
    
    # Add monthly cost if enabled
    if [[ "$show_monthly" == "true" ]]; then
        local formatted_monthly
        formatted_monthly=$(format_monthly_cost "$COMPONENT_COST_PERIOD_MONTH")
        
        if [[ -n "$output" ]]; then
            output="${output} ${formatted_monthly}"
        else
            output="$formatted_monthly"
        fi
    fi
    
    # Add weekly cost if enabled
    if [[ "$show_weekly" == "true" ]]; then
        local formatted_weekly
        formatted_weekly=$(format_weekly_cost "$COMPONENT_COST_PERIOD_WEEK")
        
        if [[ -n "$output" ]]; then
            output="${output} ${formatted_weekly}"
        else
            output="$formatted_weekly"
        fi
    fi
    
    # Add daily cost if enabled
    if [[ "$show_daily" == "true" ]]; then
        local formatted_daily
        formatted_daily=$(format_daily_cost "$COMPONENT_COST_PERIOD_TODAY")
        
        if [[ -n "$output" ]]; then
            output="${output} ${formatted_daily}"
        else
            output="$formatted_daily"
        fi
    fi
    
    echo "$output"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_cost_period_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "cost_period" "enabled" "${default_value:-true}"
            ;;
        "show_monthly")
            get_component_config "cost_period" "show_monthly" "${default_value:-true}"
            ;;
        "show_weekly")
            get_component_config "cost_period" "show_weekly" "${default_value:-true}"
            ;;
        "show_daily")
            get_component_config "cost_period" "show_daily" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the cost_period component
register_component \
    "cost_period" \
    "Periodic costs (30day, 7day, daily)" \
    "cost display" \
    "$(get_cost_period_config 'enabled' 'true')"

debug_log "Cost period component loaded" "INFO"