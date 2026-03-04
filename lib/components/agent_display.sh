#!/bin/bash

# ============================================================================
# Claude Code Statusline - Agent Display Component
# ============================================================================
#
# Displays the agent name when running with --agent flag.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_AGENT_DISPLAY_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_AGENT_DISPLAY_LOADED=true

COMPONENT_AGENT_DISPLAY_NAME=""

collect_agent_display_data() {
    debug_log "Collecting agent_display component data" "INFO"
    COMPONENT_AGENT_DISPLAY_NAME=""

    if declare -f get_json_field &>/dev/null; then
        COMPONENT_AGENT_DISPLAY_NAME=$(get_json_field "agent.name")
    fi

    debug_log "agent_display data: name=$COMPONENT_AGENT_DISPLAY_NAME" "INFO"
    return 0
}

render_agent_display() {
    local theme_enabled="${1:-true}"

    if [[ -z "$COMPONENT_AGENT_DISPLAY_NAME" ]]; then
        return 1
    fi

    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_PURPLE:-\033[95m}"
    fi

    echo "${color_code}Agent: ${COMPONENT_AGENT_DISPLAY_NAME}${COLOR_RESET}"
}

get_agent_display_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "agent_display" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_AGENT_DISPLAY:-${default:-true}}" ;;
        "description") echo "Agent name when running with --agent" ;;
        *) echo "$default" ;;
    esac
}

AGENT_DISPLAY_COMPONENT_NAME="agent_display"
AGENT_DISPLAY_COMPONENT_VERSION="2.20.0"
AGENT_DISPLAY_COMPONENT_DEPENDENCIES=("json_fields")

register_component "agent_display" "Agent name when running with --agent" "display" "true"
export -f collect_agent_display_data render_agent_display get_agent_display_config
debug_log "Agent display component loaded" "INFO"
