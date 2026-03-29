#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Plugins Component
# ============================================================================
#
# Displays enabled CC plugins (non-LSP) from settings.json enabledPlugins.
# These are CC-managed and always active when CC is running.
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
        # Count plugins (comma-separated entries)
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
    max_name_len=$(get_mcp_plugins_config "max_name_length" "15")
    local label
    label=$(get_mcp_plugins_config "label" "Ext")

    local formatted=""
    local temp_plugins="${COMPONENT_MCP_PLUGINS_DATA},"
    local parse_count=0

    while [[ "$temp_plugins" == *","* ]] && [[ $parse_count -lt 50 ]]; do
        local name="${temp_plugins%%,*}"
        temp_plugins="${temp_plugins#*,}"
        parse_count=$((parse_count + 1))

        [[ -z "$name" ]] && continue

        local display_name
        display_name=$(truncate_mcp_name "$name" "$max_name_len")

        # Plugins are CC-managed — always active (green) when CC is running
        local formatted_entry="${CONFIG_BRIGHT_GREEN}${display_name}${CONFIG_RESET}"

        if [[ -n "$formatted" ]]; then
            formatted="$formatted, $formatted_entry"
        else
            formatted="$formatted_entry"
        fi
    done

    echo "${CONFIG_DIM}${label}:${CONFIG_RESET} ${formatted}"
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
            get_component_config "mcp_plugins" "label" "${default_value:-Ext}"
            ;;
        "max_name_length")
            get_component_config "mcp_plugins" "max_name_length" "${default_value:-15}"
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
    "Enabled CC plugins (non-LSP) from settings" \
    "mcp display" \
    "$(get_mcp_plugins_config 'enabled' 'true')"

debug_log "MCP plugins component loaded" "INFO"
