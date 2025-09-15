#!/bin/bash

# ============================================================================
# Claude Code Statusline - Context Window Component
# ============================================================================
#
# This component extracts and displays Claude Code context usage from /context command.
# Shows token counts and percentage (e.g., "59k/200k tokens (30%)")
#
# Dependencies: cache.sh
# ============================================================================

# Component data storage
COMPONENT_CONTEXT_WINDOW_CURRENT=""
COMPONENT_CONTEXT_WINDOW_MAX=""
COMPONENT_CONTEXT_WINDOW_PERCENTAGE=""
COMPONENT_CONTEXT_WINDOW_AVAILABLE="false"

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect context window data by executing /context command
collect_context_window_data() {
    debug_log "Collecting context_window component data" "INFO"

    local context_data=""
    local current_tokens=""
    local max_tokens=""
    local percentage=""

    # Execute /context command and capture output
    if command -v claude >/dev/null 2>&1; then
        context_data=$(execute_cached_command "claude_context" "claude /context 2>/dev/null" 30)

        # Parse the main context line: "59k/200k tokens (30%)"
        if [[ -n "$context_data" ]]; then
            # Extract using regex pattern matching
            if [[ "$context_data" =~ ([0-9]+)k/([0-9]+)k\ tokens\ \(([0-9]+)%\) ]]; then
                current_tokens="${BASH_REMATCH[1]}k"
                max_tokens="${BASH_REMATCH[2]}k"
                percentage="${BASH_REMATCH[3]}%"
                COMPONENT_CONTEXT_WINDOW_AVAILABLE="true"
            fi
        fi
    fi

    # Store component data
    COMPONENT_CONTEXT_WINDOW_CURRENT="${current_tokens:-unknown}"
    COMPONENT_CONTEXT_WINDOW_MAX="${max_tokens:-200k}"
    COMPONENT_CONTEXT_WINDOW_PERCENTAGE="${percentage:-??%}"

    # If we couldn't get data, mark as unavailable
    if [[ -z "$current_tokens" ]]; then
        COMPONENT_CONTEXT_WINDOW_AVAILABLE="false"
    fi

    debug_log "context_window data: current=$COMPONENT_CONTEXT_WINDOW_CURRENT, max=$COMPONENT_CONTEXT_WINDOW_MAX, percentage=$COMPONENT_CONTEXT_WINDOW_PERCENTAGE, available=$COMPONENT_CONTEXT_WINDOW_AVAILABLE" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render context window component
render_context_window() {
    # Get configuration
    local show_full_info
    show_full_info=$(get_context_window_config "show_full_info" "${CONFIG_CONTEXT_WINDOW_SHOW_FULL_INFO:-false}")

    local show_percentage_only
    show_percentage_only=$(get_context_window_config "show_percentage_only" "${CONFIG_CONTEXT_WINDOW_SHOW_PERCENTAGE_ONLY:-true}")

    local emoji
    emoji=$(get_context_window_config "emoji" "${CONFIG_CONTEXT_WINDOW_EMOJI:-📊}")

    local label
    label=$(get_context_window_config "label" "${CONFIG_CONTEXT_WINDOW_LABEL:-CTX}")

    # Return early if context data unavailable
    if [[ "${COMPONENT_CONTEXT_WINDOW_AVAILABLE}" != "true" ]]; then
        echo "${emoji} ${label}: N/A"
        return 0
    fi

    # Render based on configuration
    if [[ "$show_percentage_only" == "true" ]]; then
        # Simple percentage display: "📊 30%"
        echo "${emoji} ${COMPONENT_CONTEXT_WINDOW_PERCENTAGE}"
    elif [[ "$show_full_info" == "true" ]]; then
        # Full info display: "📊 CTX: 59k/200k (30%)"
        echo "${emoji} ${label}: ${COMPONENT_CONTEXT_WINDOW_CURRENT}/${COMPONENT_CONTEXT_WINDOW_MAX} (${COMPONENT_CONTEXT_WINDOW_PERCENTAGE})"
    else
        # Default compact display: "📊 CTX: 30%"
        echo "${emoji} ${label}: ${COMPONENT_CONTEXT_WINDOW_PERCENTAGE}"
    fi
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration value
get_context_window_config() {
    local config_key="$1"
    local default_value="$2"

    # Use environment override if available
    local env_var="CONFIG_CONTEXT_WINDOW_$(echo "$config_key" | tr '[:lower:]' '[:upper:]')"
    local env_value
    env_value=$(eval echo "\${$env_var:-}")

    if [[ -n "$env_value" ]]; then
        echo "$env_value"
    else
        echo "$default_value"
    fi
}