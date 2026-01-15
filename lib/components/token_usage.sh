#!/bin/bash

# ============================================================================
# Claude Code Statusline - Token Usage Component
# ============================================================================
# 
# This component displays total tokens consumed in the current 5-hour billing block.
# Shows current usage to help users understand consumption within billing windows.
#
# Dependencies: cost.sh (native window tokens from api_live.sh), display.sh
# ============================================================================

# Component data storage
COMPONENT_TOKEN_USAGE_INFO=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect token usage data from native JSONL calculation
collect_token_usage_data() {
    debug_log "Collecting token_usage component data" "INFO"

    COMPONENT_TOKEN_USAGE_INFO="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"

    if is_module_loaded "cost"; then
        # Get native window tokens from JSONL (cached 30s)
        if declare -f get_cached_window_tokens &>/dev/null; then
            local token_data
            token_data=$(get_cached_window_tokens)

            if [[ -n "$token_data" && "$token_data" != "0:0:0:0:0" ]]; then
                # Parse token data (total:input:output:cache_read:cache_write)
                local total_tokens
                total_tokens=$(echo "$token_data" | cut -d: -f1)

                # Format token usage display
                if [[ "$total_tokens" != "0" && -n "$total_tokens" ]]; then
                    local formatted_tokens
                    formatted_tokens=$(format_tokens_compact "$total_tokens")
                    COMPONENT_TOKEN_USAGE_INFO="${formatted_tokens} tokens"
                else
                    COMPONENT_TOKEN_USAGE_INFO="No tokens used"
                fi
            fi
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