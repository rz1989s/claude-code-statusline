#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Plugins Component
# ============================================================================
#
# Displays enabled CC plugins (non-LSP) from settings.json enabledPlugins.
# Uses rotating display: shows one name + N remaining per render cycle.
#
# Dependencies: mcp.sh, display.sh
# ============================================================================

[[ "${STATUSLINE_MCP_PLUGINS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_MCP_PLUGINS_LOADED=true

COMPONENT_MCP_PLUGINS_DATA=""
COMPONENT_MCP_PLUGINS_COUNT=0

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_mcp_plugins_data() {
    debug_log "Collecting mcp_plugins component data" "INFO"

    COMPONENT_MCP_PLUGINS_DATA=""
    COMPONENT_MCP_PLUGINS_COUNT=0

    local plugins_data
    plugins_data=$(get_enabled_mcp_plugins)

    if [[ -n "$plugins_data" ]]; then
        COMPONENT_MCP_PLUGINS_DATA="$plugins_data"
        local count=1
        local tmp="$plugins_data"
        while [[ "$tmp" == *","* ]]; do
            count=$((count + 1))
            tmp="${tmp#*,}"
        done
        COMPONENT_MCP_PLUGINS_COUNT=$count
    fi

    debug_log "mcp_plugins data: count=$COMPONENT_MCP_PLUGINS_COUNT, data=$COMPONENT_MCP_PLUGINS_DATA" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_mcp_plugins() {
    if [[ -z "$COMPONENT_MCP_PLUGINS_DATA" || "$COMPONENT_MCP_PLUGINS_COUNT" -eq 0 ]]; then
        return 1
    fi

    local max_name_len
    max_name_len=$(get_mcp_plugins_config "max_name_length" "10")
    local label
    label=$(get_mcp_plugins_config "label" "E")

    # Build names array
    local names=()
    local tmp="${COMPONENT_MCP_PLUGINS_DATA},"
    while [[ "$tmp" == *","* ]]; do
        local name="${tmp%%,*}"
        tmp="${tmp#*,}"
        [[ -z "$name" ]] && continue
        names+=("$name")
    done

    local total=${#names[@]}
    if [[ $total -eq 0 ]]; then
        return 1
    fi

    # Rotate: pick name based on current time
    local idx=$(( $(date +%s) % total ))
    local display_name
    display_name=$(truncate_mcp_name "${names[$idx]}" "$max_name_len")
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

get_mcp_plugins_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "mcp_plugins" "enabled" "${default_value:-true}"
            ;;
        "label")
            get_component_config "mcp_plugins" "label" "${default_value:-E}"
            ;;
        "max_name_length")
            get_component_config "mcp_plugins" "max_name_length" "${default_value:-10}"
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
    "mcp_plugins" \
    "Enabled CC plugins (non-LSP) with rotation" \
    "mcp display" \
    "$(get_mcp_plugins_config 'enabled' 'true')"

debug_log "MCP plugins component loaded" "INFO"
