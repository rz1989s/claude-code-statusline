#!/bin/bash

# ============================================================================
# Claude Code Statusline - Token Usage Component
# ============================================================================
# 
# This component displays total tokens consumed in the current 5-hour billing block.
# Shows current usage to help users understand consumption within billing windows.
#
# Dependencies: cost.sh (get_unified_block_metrics), display.sh
# ============================================================================

# Component data storage
COMPONENT_TOKEN_USAGE_INFO=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect token usage data from unified block metrics
collect_token_usage_data() {
    debug_log "Collecting token_usage component data" "INFO"
    
    COMPONENT_TOKEN_USAGE_INFO="$CONFIG_NO_CCUSAGE_MESSAGE"
    
    if is_module_loaded "cost" && is_ccusage_available; then
        # Get unified metrics from single ccusage call (cached 30s)
        local metrics
        metrics=$(get_unified_block_metrics)
        
        if [[ -n "$metrics" && "$metrics" != "0:0:0:0:0:0:0" ]]; then
            # Parse token usage (field 3)
            local total_tokens
            total_tokens=$(echo "$metrics" | cut -d: -f3)
            
            # Format token usage display
            if [[ "$total_tokens" != "0" && "$total_tokens" != "null" ]]; then
                local formatted_tokens
                formatted_tokens=$(format_tokens_compact "$total_tokens")
                COMPONENT_TOKEN_USAGE_INFO="📊${formatted_tokens} tokens"
            else
                COMPONENT_TOKEN_USAGE_INFO="📊No tokens used"
            fi
        else
            COMPONENT_TOKEN_USAGE_INFO="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
        fi
    fi
    
    debug_log "token_usage data: info=$COMPONENT_TOKEN_USAGE_INFO" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render token usage component
render_token_usage() {
    local theme_enabled="${1:-true}"
    
    # Apply theme colors if enabled
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        # Use blue for token usage (informational)
        color_code="$CONFIG_BLUE"
    fi
    
    # Display the token usage with color
    echo "${color_code}${COMPONENT_TOKEN_USAGE_INFO}${COLOR_RESET}"
}

# Get token usage configuration 
get_token_usage_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    
    case "$key" in
        "component_name"|"name")
            echo "token_usage"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_COST_TRACKING:-${default:-true}}"
            ;;
        "description")
            echo "Total tokens consumed in current block"
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
TOKEN_USAGE_COMPONENT_NAME="token_usage"
TOKEN_USAGE_COMPONENT_DESCRIPTION="Total tokens consumed in current block"
TOKEN_USAGE_COMPONENT_VERSION="2.10.0"
TOKEN_USAGE_COMPONENT_DEPENDENCIES=("cost")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the token_usage component
register_component \
    "token_usage" \
    "Total tokens consumed in current block" \
    "cost display" \
    "true"

# Export component functions
export -f collect_token_usage_data render_token_usage get_token_usage_config