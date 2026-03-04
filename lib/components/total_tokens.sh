#!/bin/bash

# ============================================================================
# Claude Code Statusline - Total Tokens Component
# ============================================================================
#
# Displays cumulative input/output token counts for the session.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_TOTAL_TOKENS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_TOTAL_TOKENS_LOADED=true

COMPONENT_TOTAL_TOKENS_INPUT="0"
COMPONENT_TOTAL_TOKENS_OUTPUT="0"

# Format token count to human-readable (1.5K, 2.3M)
_format_tokens_human() {
    local count="${1:-0}"
    [[ ! "$count" =~ ^[0-9]+$ ]] && { echo "0"; return; }
    if [[ "$count" -ge 1000000 ]]; then
        awk -v c="$count" 'BEGIN { printf "%.1fM", c / 1000000 }' 2>/dev/null
    elif [[ "$count" -ge 1000 ]]; then
        awk -v c="$count" 'BEGIN { printf "%.1fK", c / 1000 }' 2>/dev/null
    else
        echo "$count"
    fi
}

collect_total_tokens_data() {
    debug_log "Collecting total_tokens component data" "INFO"
    COMPONENT_TOTAL_TOKENS_INPUT="0"
    COMPONENT_TOTAL_TOKENS_OUTPUT="0"

    if declare -f get_json_field_num &>/dev/null; then
        COMPONENT_TOTAL_TOKENS_INPUT=$(get_json_field_num "context_window.total_input_tokens" "0")
        COMPONENT_TOTAL_TOKENS_OUTPUT=$(get_json_field_num "context_window.total_output_tokens" "0")
    fi

    debug_log "total_tokens data: in=$COMPONENT_TOTAL_TOKENS_INPUT out=$COMPONENT_TOTAL_TOKENS_OUTPUT" "INFO"
    return 0
}

render_total_tokens() {
    local theme_enabled="${1:-true}"

    local total=$(( COMPONENT_TOTAL_TOKENS_INPUT + COMPONENT_TOTAL_TOKENS_OUTPUT ))
    if [[ "$total" -eq 0 ]]; then
        return 1
    fi

    local format="${CONFIG_TOTAL_TOKENS_FORMAT:-split}"
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_BLUE:-}"
    fi

    local output
    case "$format" in
        compact)
            local total_fmt
            total_fmt=$(_format_tokens_human "$total")
            output="Tokens: ${total_fmt} total"
            ;;
        *)
            local in_fmt out_fmt
            in_fmt=$(_format_tokens_human "$COMPONENT_TOTAL_TOKENS_INPUT")
            out_fmt=$(_format_tokens_human "$COMPONENT_TOTAL_TOKENS_OUTPUT")
            output="Tokens: ${in_fmt} in / ${out_fmt} out"
            ;;
    esac

    echo "${color_code}${output}${COLOR_RESET}"
}

get_total_tokens_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "total_tokens" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_TOTAL_TOKENS:-${default:-true}}" ;;
        "format") echo "${CONFIG_TOTAL_TOKENS_FORMAT:-${default:-split}}" ;;
        "description") echo "Cumulative session token counts" ;;
        *) echo "$default" ;;
    esac
}

TOTAL_TOKENS_COMPONENT_NAME="total_tokens"
TOTAL_TOKENS_COMPONENT_VERSION="2.20.0"
TOTAL_TOKENS_COMPONENT_DEPENDENCIES=("json_fields")

register_component "total_tokens" "Cumulative session token counts" "display" "true"
export -f collect_total_tokens_data render_total_tokens get_total_tokens_config
debug_log "Total tokens component loaded" "INFO"
