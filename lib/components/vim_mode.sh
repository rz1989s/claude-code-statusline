#!/bin/bash

# ============================================================================
# Claude Code Statusline - Vim Mode Component
# ============================================================================
#
# Displays vim mode state (NORMAL/INSERT) when vim mode is enabled.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_VIM_MODE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_VIM_MODE_LOADED=true

COMPONENT_VIM_MODE_VALUE=""

collect_vim_mode_data() {
    debug_log "Collecting vim_mode component data" "INFO"
    COMPONENT_VIM_MODE_VALUE=""

    if declare -f get_json_field &>/dev/null; then
        COMPONENT_VIM_MODE_VALUE=$(get_json_field "vim.mode")
    fi

    debug_log "vim_mode data: value=$COMPONENT_VIM_MODE_VALUE" "INFO"
    return 0
}

render_vim_mode() {
    local theme_enabled="${1:-true}"

    if [[ -z "$COMPONENT_VIM_MODE_VALUE" ]]; then
        return 1
    fi

    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        case "$COMPONENT_VIM_MODE_VALUE" in
            NORMAL) color_code="${CONFIG_GREEN:-}" ;;
            INSERT) color_code="${CONFIG_YELLOW:-}" ;;
            *) color_code="" ;;
        esac
    fi

    echo "${color_code}VIM:${COMPONENT_VIM_MODE_VALUE}${COLOR_RESET}"
}

get_vim_mode_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "vim_mode" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_VIM_MODE:-${default:-true}}" ;;
        "description") echo "Vim mode state (NORMAL/INSERT)" ;;
        *) echo "$default" ;;
    esac
}

VIM_MODE_COMPONENT_NAME="vim_mode"
VIM_MODE_COMPONENT_VERSION="2.20.0"
VIM_MODE_COMPONENT_DEPENDENCIES=("json_fields")

register_component "vim_mode" "Vim mode state (NORMAL/INSERT)" "display" "true"
export -f collect_vim_mode_data render_vim_mode get_vim_mode_config
debug_log "Vim mode component loaded" "INFO"
