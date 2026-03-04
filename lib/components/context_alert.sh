#!/bin/bash

# ============================================================================
# Claude Code Statusline - Context Alert Component
# ============================================================================
#
# Shows a warning when token usage exceeds 200K threshold.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

COMPONENT_CONTEXT_ALERT_EXCEEDED=""

collect_context_alert_data() {
    debug_log "Collecting context_alert component data" "INFO"
    COMPONENT_CONTEXT_ALERT_EXCEEDED="false"

    if declare -f get_json_field_bool &>/dev/null; then
        COMPONENT_CONTEXT_ALERT_EXCEEDED=$(get_json_field_bool "exceeds_200k_tokens" "false")
    fi

    debug_log "context_alert data: exceeded=$COMPONENT_CONTEXT_ALERT_EXCEEDED" "INFO"
    return 0
}

render_context_alert() {
    local theme_enabled="${1:-true}"

    if [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" != "true" ]]; then
        return 1
    fi

    local color_code="" bold=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_RED:-}"
        bold="${CONFIG_BOLD:-\033[1m}"
    fi

    local label="${CONFIG_CONTEXT_ALERT_THRESHOLD_LABEL:-">200K"}"
    echo "${bold}${color_code}${label}${COLOR_RESET}"
}

get_context_alert_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "context_alert" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_CONTEXT_ALERT:-${default:-true}}" ;;
        "description") echo "Warning when tokens exceed 200K threshold" ;;
        *) echo "$default" ;;
    esac
}

CONTEXT_ALERT_COMPONENT_NAME="context_alert"
CONTEXT_ALERT_COMPONENT_VERSION="2.20.0"
CONTEXT_ALERT_COMPONENT_DEPENDENCIES=("json_fields")

register_component "context_alert" "Warning when tokens exceed 200K threshold" "display" "true"
export -f collect_context_alert_data render_context_alert get_context_alert_config
debug_log "Context alert component loaded" "INFO"
