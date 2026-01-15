#!/bin/bash

# ============================================================================
# Claude Code Statusline - Block Projection Component
# ============================================================================
# 
# This component displays projected cost and tokens for the current 5-hour block.
# Shows predictions to help users budget and avoid unexpected costs.
#
# Dependencies: cost.sh (native block projection from api_live.sh), display.sh
# ============================================================================

# Component data storage
COMPONENT_BLOCK_PROJECTION_INFO=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect block projection data from native calculation
collect_block_projection_data() {
    debug_log "Collecting block_projection component data" "INFO"

    COMPONENT_BLOCK_PROJECTION_INFO="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"

    if is_module_loaded "cost"; then
        # Get native block projection (cached 30s)
        if declare -f get_cached_native_block_projection &>/dev/null; then
            local projection_data
            projection_data=$(get_cached_native_block_projection)

            if [[ -n "$projection_data" ]]; then
                # Parse projection data (projected_cost:projected_tokens)
                local proj_cost proj_tokens
                IFS=':' read -r proj_cost proj_tokens <<< "$projection_data"

                # Format projection display
                if [[ -n "$proj_cost" && "$proj_cost" != "0.00" ]] && [[ -n "$proj_tokens" && "$proj_tokens" != "0" ]]; then
                    local formatted_cost formatted_tokens
                    formatted_cost=$(printf "%.2f" "$proj_cost" 2>/dev/null || echo "0.00")
                    formatted_tokens=$(format_tokens_compact "$proj_tokens")
                    COMPONENT_BLOCK_PROJECTION_INFO="Est: \$${formatted_cost} (${formatted_tokens})"
                else
                    COMPONENT_BLOCK_PROJECTION_INFO="No projections"
                fi
            fi
        fi
    fi

    debug_log "block_projection data: info=$COMPONENT_BLOCK_PROJECTION_INFO" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render block projection component
render_block_projection() {
    local theme_enabled="${1:-true}"
    
    # Apply theme colors if enabled
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        # Use magenta for projections (future-oriented)
        color_code="$CONFIG_MAGENTA"
    fi
    
    # Display the block projection with color
    echo "${color_code}${COMPONENT_BLOCK_PROJECTION_INFO}${COLOR_RESET}"
}

# Get block projection configuration 
get_block_projection_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    
    case "$key" in
        "component_name"|"name")
            echo "block_projection"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_COST_TRACKING:-${default:-true}}"
            ;;
        "description")
            echo "Projected cost and tokens for current block"
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
BLOCK_PROJECTION_COMPONENT_NAME="block_projection"
BLOCK_PROJECTION_COMPONENT_DESCRIPTION="Projected cost and tokens for current block"
BLOCK_PROJECTION_COMPONENT_VERSION="2.10.0"
BLOCK_PROJECTION_COMPONENT_DEPENDENCIES=("cost")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the block_projection component
register_component \
    "block_projection" \
    "Projected cost and tokens for current block" \
    "cost display" \
    "true"

# Export component functions
export -f collect_block_projection_data render_block_projection get_block_projection_config