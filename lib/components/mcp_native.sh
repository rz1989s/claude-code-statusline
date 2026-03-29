#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Native Component
# ============================================================================
#
# Displays session MCP servers detected from transcript JSONL.
# Shows servers like pencil, chrome, slack that aren't in config files.
# Uses rotating display: one name + N remaining per render cycle.
#
# Dependencies: mcp.sh, display.sh
# ============================================================================

[[ "${STATUSLINE_MCP_NATIVE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_MCP_NATIVE_LOADED=true

COMPONENT_MCP_NATIVE_DATA=""
COMPONENT_MCP_NATIVE_COUNT=0

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_mcp_native_data() {
    debug_log "Collecting mcp_native component data" "INFO"

    COMPONENT_MCP_NATIVE_DATA=""
    COMPONENT_MCP_NATIVE_COUNT=0

    local native_data
    native_data=$(get_session_mcp_servers)

    if [[ -n "$native_data" ]]; then
        COMPONENT_MCP_NATIVE_DATA="$native_data"
        local count=1
        local tmp="$native_data"
        while [[ "$tmp" == *","* ]]; do
            count=$((count + 1))
            tmp="${tmp#*,}"
        done
        COMPONENT_MCP_NATIVE_COUNT=$count
    fi

    debug_log "mcp_native data: count=$COMPONENT_MCP_NATIVE_COUNT, data=$COMPONENT_MCP_NATIVE_DATA" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_mcp_native() {
    if [[ -z "$COMPONENT_MCP_NATIVE_DATA" || "$COMPONENT_MCP_NATIVE_COUNT" -eq 0 ]]; then
        return 1
    fi

    local max_name_len
    max_name_len=$(get_mcp_native_config "max_name_length" "50")
    local label
    label=$(get_mcp_native_config "label" "Native")

    # Build entries array (name:status pairs)
    local names=()
    local tmp="${COMPONENT_MCP_NATIVE_DATA},"
    while [[ "$tmp" == *","* ]]; do
        local entry="${tmp%%,*}"
        tmp="${tmp#*,}"
        [[ -z "$entry" ]] && continue
        names+=("${entry%%:*}")
    done

    local total=${#names[@]}
    if [[ $total -eq 0 ]]; then
        return 1
    fi

    # Rotate: pick name based on current time
    local idx=$(( $(date +%s) % total ))
    local display_name
    display_name=$(truncate_mcp_name "${names[$idx]}" "$max_name_len")

    # Session servers are always active (green)
    local formatted="${CONFIG_BRIGHT_GREEN}${display_name}${CONFIG_RESET}"

    local remaining=$((total - 1))
    if [[ $remaining -gt 0 ]]; then
        formatted="${formatted} ${CONFIG_DIM}+${remaining}${CONFIG_RESET}"
    fi

    echo "${CONFIG_DIM}${label}:${CONFIG_RESET}${formatted}"
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

get_mcp_native_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "mcp_native" "enabled" "${default_value:-true}"
            ;;
        "label")
            get_component_config "mcp_native" "label" "${default_value:-Native}"
            ;;
        "max_name_length")
            get_component_config "mcp_native" "max_name_length" "${default_value:-50}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

register_component \
    "mcp_native" \
    "Session MCP servers from transcript (pencil, chrome, slack)" \
    "mcp display" \
    "$(get_mcp_native_config 'enabled' 'true')"

debug_log "MCP native component loaded" "INFO"
