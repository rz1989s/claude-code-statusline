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

    if is_module_loaded "cost"; then
        # Issue #104: Use hybrid cost source (native + ccusage fallback)
        # Session cost prefers native data for zero-latency, real-time accuracy
        local source="${CONFIG_COST_SESSION_SOURCE:-auto}"
        local session_cost

        session_cost=$(get_session_cost_with_source "$source")

        if [[ -n "$session_cost" && "$session_cost" != "0.00" ]]; then
            COMPONENT_COST_REPO_COST="$session_cost"
            debug_log "Using hybrid session cost ($source): \$$session_cost" "INFO"
        elif is_ccusage_available; then
            # Fallback to ccusage if hybrid returns zero/empty
            local usage_info
            usage_info=$(get_claude_usage_info)

            if [[ -n "$usage_info" ]]; then
                COMPONENT_COST_REPO_COST="${usage_info%%:*}"
                debug_log "Fallback to ccusage session cost: \$$COMPONENT_COST_REPO_COST" "INFO"
            fi
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