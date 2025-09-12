#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Efficiency Component
# ============================================================================
# 
# This component displays cache hit percentage for the current billing block.
# Shows cache efficiency to help users understand cost optimization.
#
# Dependencies: cost.sh (get_unified_block_metrics), display.sh
# ============================================================================

# Component data storage
COMPONENT_CACHE_EFFICIENCY_INFO=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect cache efficiency data from unified block metrics
collect_cache_efficiency_data() {
    debug_log "Collecting cache_efficiency component data" "INFO"
    
    COMPONENT_CACHE_EFFICIENCY_INFO="$CONFIG_NO_CCUSAGE_MESSAGE"
    
    if is_module_loaded "cost" && is_ccusage_available; then
        # Get unified metrics from single ccusage call (cached 30s)
        local metrics
        metrics=$(get_unified_block_metrics)
        
        if [[ -n "$metrics" && "$metrics" != "0:0:0:0:0:0:0" ]]; then
            # Parse cache metrics (fields 4 and 5)
            local cache_read cache_creation
            cache_read=$(echo "$metrics" | cut -d: -f4)
            cache_creation=$(echo "$metrics" | cut -d: -f5)
            
            # Calculate cache efficiency percentage
            if [[ "$cache_read" != "0" && "$cache_read" != "null" ]] && [[ "$cache_creation" != "0" && "$cache_creation" != "null" ]]; then
                local total_cache_tokens efficiency
                total_cache_tokens=$((cache_read + cache_creation))
                
                if [[ "$total_cache_tokens" -gt 0 ]]; then
                    # Calculate percentage with proper arithmetic
                    if command_exists bc; then
                        efficiency=$(echo "scale=0; $cache_read * 100 / $total_cache_tokens" | bc -l 2>/dev/null || echo "0")
                    else
                        efficiency=$(awk "BEGIN {printf \"%.0f\", $cache_read * 100 / $total_cache_tokens}" 2>/dev/null || echo "0")
                    fi
                    COMPONENT_CACHE_EFFICIENCY_INFO="💾Cache: ${efficiency}% hit"
                else
                    COMPONENT_CACHE_EFFICIENCY_INFO="💾No cache data"
                fi
            elif [[ "$cache_read" != "0" && "$cache_creation" == "0" ]]; then
                # All cache hits (100% efficiency)
                COMPONENT_CACHE_EFFICIENCY_INFO="💾Cache: 100% hit"
            elif [[ "$cache_read" == "0" && "$cache_creation" != "0" ]]; then
                # No cache hits (0% efficiency)
                COMPONENT_CACHE_EFFICIENCY_INFO="💾Cache: 0% hit"
            else
                COMPONENT_CACHE_EFFICIENCY_INFO="💾No cache used"
            fi
        else
            COMPONENT_CACHE_EFFICIENCY_INFO="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
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