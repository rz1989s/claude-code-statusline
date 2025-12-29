#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Repo Component
# ============================================================================
# 
# This component handles repository cost display.
#
# Dependencies: cost.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COST_REPO_COST=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect repository cost data
collect_cost_repo_data() {
    debug_log "Collecting cost_repo component data" "INFO"

    COMPONENT_COST_REPO_COST="-.--"

    # Issue #99: Debug comparison mode - log native vs ccusage side-by-side
    # This runs ONLY when STATUSLINE_DEBUG=true to validate native data
    if is_debug_mode && is_module_loaded "cost"; then
        compare_native_vs_ccusage_cost >/dev/null
    fi

    if is_module_loaded "cost" && is_ccusage_available; then
        # Get usage info and extract session cost
        local usage_info
        usage_info=$(get_claude_usage_info)

        if [[ -n "$usage_info" ]]; then
            # Parse usage info (format: session:month:week:today:block:reset)
            COMPONENT_COST_REPO_COST="${usage_info%%:*}"
        fi
    fi

    debug_log "cost_repo data: cost=$COMPONENT_COST_REPO_COST" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render repository cost display
render_cost_repo() {
    local formatted_cost
    formatted_cost=$(format_session_cost "$COMPONENT_COST_REPO_COST")
    echo "$formatted_cost"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_cost_repo_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "cost_repo" "enabled" "${default_value:-true}"
            ;;
        "label")
            get_component_config "cost_repo" "label" "${default_value:-$CONFIG_REPO_LABEL}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the cost_repo component
register_component \
    "cost_repo" \
    "Repository cost" \
    "cost display" \
    "$(get_cost_repo_config 'enabled' 'true')"

debug_log "Cost repo component loaded" "INFO"