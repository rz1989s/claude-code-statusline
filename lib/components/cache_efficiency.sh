#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Efficiency Component
# ============================================================================
# 
# This component displays cache hit percentage for the current billing block.
# Shows cache efficiency to help users understand cost optimization.
#
# Dependencies: cost.sh (native cache from STATUSLINE_INPUT_JSON + JSONL), display.sh
# ============================================================================

# Component data storage
COMPONENT_CACHE_EFFICIENCY_INFO=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect cache efficiency data from native sources
collect_cache_efficiency_data() {
    debug_log "Collecting cache_efficiency component data" "INFO"

    COMPONENT_CACHE_EFFICIENCY_INFO="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"

    if is_module_loaded "cost"; then
        local got_data=false

        # Try native cache efficiency first (from STATUSLINE_INPUT_JSON)
        if declare -f get_native_cache_efficiency &>/dev/null; then
            local native_efficiency
            native_efficiency=$(get_native_cache_efficiency)

            if [[ -n "$native_efficiency" && "$native_efficiency" != "0" ]]; then
                COMPONENT_CACHE_EFFICIENCY_INFO="Cache: ${native_efficiency}% hit"
                debug_log "Using native cache efficiency: ${native_efficiency}%" "INFO"
                got_data=true
            fi
        fi

        # Fallback: Calculate from JSONL window tokens
        if [[ "$got_data" == "false" ]] && declare -f get_cached_window_tokens &>/dev/null; then
            local token_data
            token_data=$(get_cached_window_tokens)

            if [[ -n "$token_data" && "$token_data" != "0:0:0:0:0" ]]; then
                # Parse token data (total:input:output:cache_read:cache_write)
                local cache_read cache_write
                cache_read=$(echo "$token_data" | cut -d: -f4)
                cache_write=$(echo "$token_data" | cut -d: -f5)

                # Calculate cache efficiency percentage
                if [[ "${cache_read:-0}" -gt 0 || "${cache_write:-0}" -gt 0 ]]; then
                    local total_cache_tokens efficiency
                    total_cache_tokens=$((cache_read + cache_write))

                    if [[ "$total_cache_tokens" -gt 0 ]]; then
                        efficiency=$(awk -v cr="$cache_read" -v t="$total_cache_tokens" 'BEGIN {printf "%.0f", cr * 100 / t}' 2>/dev/null || echo "0")
                        COMPONENT_CACHE_EFFICIENCY_INFO="Cache: ${efficiency}% hit"
                        debug_log "Using JSONL cache efficiency: ${efficiency}%" "INFO"
                    else
                        COMPONENT_CACHE_EFFICIENCY_INFO="No cache data"
                    fi
                else
                    COMPONENT_CACHE_EFFICIENCY_INFO="No cache used"
                fi
            fi
        fi
    fi

    debug_log "cache_efficiency data: info=$COMPONENT_CACHE_EFFICIENCY_INFO" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render cache efficiency component
render_cache_efficiency() {
    local theme_enabled="${1:-true}"
    
    # Apply theme colors if enabled
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        # Use green for cache efficiency (positive metric)
        color_code="$CONFIG_GREEN"
    fi
    
    # Display the cache efficiency with color
    echo "${color_code}${COMPONENT_CACHE_EFFICIENCY_INFO}${COLOR_RESET}"
}

# Get cache efficiency configuration 
get_cache_efficiency_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    
    case "$key" in
        "component_name"|"name")
            echo "cache_efficiency"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_COST_TRACKING:-${default:-true}}"
            ;;
        "description")
            echo "Cache hit percentage for cost optimization"
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
CACHE_EFFICIENCY_COMPONENT_NAME="cache_efficiency"
CACHE_EFFICIENCY_COMPONENT_DESCRIPTION="Cache hit percentage for cost optimization"
CACHE_EFFICIENCY_COMPONENT_VERSION="2.10.0"
CACHE_EFFICIENCY_COMPONENT_DEPENDENCIES=("cost")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the cache_efficiency component
register_component \
    "cache_efficiency" \
    "Cache hit percentage for cost optimization" \
    "cost display" \
    "true"

# Export component functions
export -f collect_cache_efficiency_data render_cache_efficiency get_cache_efficiency_config