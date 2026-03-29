#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Status Component (Total Count)
# ============================================================================
#
# Displays aggregate MCP count across all sources: native JSON, plugins, servers.
# Format: MCP:X/Y where X=connected, Y=total across all 3 sources.
#
# Dependencies: mcp.sh, display.sh, mcp_servers.sh, mcp_plugins.sh
# ============================================================================

# Component data storage
COMPONENT_MCP_STATUS_STATUS=""
COMPONENT_MCP_STATUS_SERVERS=""
COMPONENT_MCP_STATUS_NATIVE_COUNT=0
COMPONENT_MCP_STATUS_NATIVE_CONNECTED=0

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_mcp_status_data() {
    debug_log "Collecting mcp_status component data" "INFO"

    COMPONENT_MCP_STATUS_STATUS="0/0"
    COMPONENT_MCP_STATUS_SERVERS="$CONFIG_MCP_NONE_MESSAGE"
    COMPONENT_MCP_STATUS_NATIVE_COUNT=0
    COMPONENT_MCP_STATUS_NATIVE_CONNECTED=0

    if is_module_loaded "mcp"; then
        if has_native_mcp_data; then
            local native_status
            native_status=$(get_native_mcp_status)
            if [[ "$native_status" =~ ^([0-9]+)/([0-9]+)$ ]]; then
                COMPONENT_MCP_STATUS_NATIVE_CONNECTED="${BASH_REMATCH[1]}"
                COMPONENT_MCP_STATUS_NATIVE_COUNT="${BASH_REMATCH[2]}"
            fi
            COMPONENT_MCP_STATUS_SERVERS=$(get_native_mcp_servers)
        fi
    fi

    COMPONENT_MCP_STATUS_SERVERS="${COMPONENT_MCP_STATUS_SERVERS//$'\n'/ }"
    debug_log "mcp_status data: native=$COMPONENT_MCP_STATUS_NATIVE_CONNECTED/$COMPONENT_MCP_STATUS_NATIVE_COUNT" "INFO"
    return 0
}

# Build aggregate total at render time (after all components collected)
_mcp_aggregate_total() {
    local total_connected=$COMPONENT_MCP_STATUS_NATIVE_CONNECTED
    local total_count=$COMPONENT_MCP_STATUS_NATIVE_COUNT

    # Plugins: all connected by definition
    total_connected=$((total_connected + ${COMPONENT_MCP_PLUGINS_COUNT:-0}))
    total_count=$((total_count + ${COMPONENT_MCP_PLUGINS_COUNT:-0}))

    # Servers: count connected from probed data
    if [[ -n "${COMPONENT_MCP_SERVERS_DATA:-}" && "${COMPONENT_MCP_SERVERS_COUNT:-0}" -gt 0 ]]; then
        total_count=$((total_count + COMPONENT_MCP_SERVERS_COUNT))
        local tmp="${COMPONENT_MCP_SERVERS_DATA},"
        while [[ "$tmp" == *","* ]]; do
            local entry="${tmp%%,*}"
            tmp="${tmp#*,}"
            [[ -z "$entry" ]] && continue
            if [[ "${entry#*:}" == "connected" ]]; then
                total_connected=$((total_connected + 1))
            fi
        done
    fi

    echo "${total_connected}/${total_count}"
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_mcp_status() {
    local status
    status=$(_mcp_aggregate_total)

    if [[ "$status" =~ ^([0-9]+)/([0-9]+)$ ]]; then
        local connected="${BASH_REMATCH[1]}"
        local total="${BASH_REMATCH[2]}"

        if [[ "$total" == "0" ]]; then
            echo "${CONFIG_DIM}MCP:0/0${CONFIG_RESET}"
        elif [[ "$connected" == "$total" ]]; then
            echo "${CONFIG_BRIGHT_GREEN}MCP:${status}${CONFIG_RESET}"
        else
            echo "${CONFIG_YELLOW}MCP:${status}${CONFIG_RESET}"
        fi
    else
        echo "${CONFIG_DIM}MCP:0/0${CONFIG_RESET}"
    fi

    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

get_mcp_status_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "mcp_status" "enabled" "${default_value:-true}"
            ;;
        "show_server_list")
            get_component_config "mcp_status" "show_server_list" "${default_value:-true}"
            ;;
        "compact_mode")
            get_component_config "mcp_status" "compact_mode" "${default_value:-false}"
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
    "mcp_status" \
    "MCP aggregate count across all sources" \
    "mcp display" \
    "$(get_mcp_status_config 'enabled' 'true')"

debug_log "MCP status component loaded" "INFO"
