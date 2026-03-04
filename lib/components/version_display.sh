#!/bin/bash

# ============================================================================
# Claude Code Statusline - Version Display Component
# ============================================================================
#
# Displays the Claude Code CLI version from native JSON input.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

COMPONENT_VERSION_DISPLAY_VALUE=""

collect_version_display_data() {
    debug_log "Collecting version_display component data" "INFO"
    COMPONENT_VERSION_DISPLAY_VALUE=""

    if declare -f get_json_field &>/dev/null; then
        COMPONENT_VERSION_DISPLAY_VALUE=$(get_json_field "version")
    fi

    debug_log "version_display data: value=$COMPONENT_VERSION_DISPLAY_VALUE" "INFO"
    return 0
}

render_version_display() {
    local theme_enabled="${1:-true}"

    if [[ -z "$COMPONENT_VERSION_DISPLAY_VALUE" ]]; then
        return 1
    fi

    local format="${CONFIG_VERSION_DISPLAY_FORMAT:-short}"
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_TEAL:-}"
    fi

    local output
    case "$format" in
        full) output="CC v${COMPONENT_VERSION_DISPLAY_VALUE}" ;;
        *)    output="v${COMPONENT_VERSION_DISPLAY_VALUE}" ;;
    esac

    echo "${color_code}${output}${COLOR_RESET}"
}

get_version_display_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "version_display" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_VERSION_DISPLAY:-${default:-true}}" ;;
        "format") echo "${CONFIG_VERSION_DISPLAY_FORMAT:-${default:-short}}" ;;
        "description") echo "Claude Code CLI version" ;;
        *) echo "$default" ;;
    esac
}

VERSION_DISPLAY_COMPONENT_NAME="version_display"
VERSION_DISPLAY_COMPONENT_VERSION="2.20.0"
VERSION_DISPLAY_COMPONENT_DEPENDENCIES=("json_fields")

register_component "version_display" "Claude Code CLI version" "display" "true"
export -f collect_version_display_data render_version_display get_version_display_config
debug_log "Version display component loaded" "INFO"
