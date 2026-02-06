#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Live Component
# ============================================================================
#
# This component handles live cost display, synchronized with the Anthropic
# API's 5-hour billing window for accurate alignment with reset timer.
#
# v2.16.0: API-synced calculation
# - Uses Anthropic OAuth API's resets_at as time window boundary
# - Reads JSONL files directly and calculates cost from token usage
# - Ensures LIVE and reset timer reference the same 5-hour window
#
# Dependencies: cost.sh, display.sh, usage_limits.sh (for API data)
# ============================================================================

# Component data storage
COMPONENT_COST_LIVE_BLOCK=""
COMPONENT_COST_LIVE_VALUE=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect live cost data (API-synced, uses cached values)
collect_cost_live_data() {
    debug_log "Collecting cost_live component data" "INFO"

    COMPONENT_COST_LIVE_BLOCK="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
    COMPONENT_COST_LIVE_VALUE=""

    # PRIMARY: Get from cached usage info (includes LIVE in block field)
    # This avoids redundant API-synced calculation (~15s savings per call)
    if declare -f get_claude_usage_info &>/dev/null; then
        local usage_info
        usage_info=$(get_claude_usage_info)

        if [[ -n "$usage_info" ]]; then
            # Parse usage info (format: session:month:week:today:block:reset)
            local remaining="$usage_info"

            # Skip to block info (5th field)
            for i in {1..4}; do
                remaining="${remaining#*:}"
            done

            # Extract block info (contains "🔥LIVE $XX.XX" or "No active block")
            local block_info="${remaining%%:*}"

            if [[ -n "$block_info" && "$block_info" != "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE" && "$block_info" != "No active block" ]]; then
                COMPONENT_COST_LIVE_BLOCK="$block_info"
                # Extract numeric value for COMPONENT_COST_LIVE_VALUE
                COMPONENT_COST_LIVE_VALUE=$(echo "$block_info" | grep -oE '[0-9]+\.[0-9]+' | head -1)
                debug_log "cost_live data (cached): $block_info" "INFO"
                return 0
            fi
        fi
    fi

    debug_log "cost_live: no active block or cached data" "DEBUG"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render live block cost display
render_cost_live() {
    # Only render if there's an active block
    if [[ "$COMPONENT_COST_LIVE_BLOCK" != "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE" ]]; then
        local formatted_live
        formatted_live=$(format_live_block_cost "$COMPONENT_COST_LIVE_BLOCK")
        echo "$formatted_live"
        return 0
    else
        return 1  # No content to render
    fi
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_cost_live_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "cost_live" "enabled" "${default_value:-true}"
            ;;
        "hide_when_inactive")
            get_component_config "cost_live" "hide_when_inactive" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the cost_live component
register_component \
    "cost_live" \
    "Live block cost (when active)" \
    "cost display" \
    "$(get_cost_live_config 'enabled' 'true')"

debug_log "Cost live component loaded" "INFO"