#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Servers Component
# ============================================================================
#
# Displays project-level MCP servers from .mcp.json and settings mcpServers.
# Uses TCP probe for SSH-based servers, command existence for stdio.
#
# Dependencies: mcp.sh, display.sh
# ============================================================================

[[ "${STATUSLINE_MCP_SERVERS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_MCP_SERVERS_LOADED=true

COMPONENT_MCP_SERVERS_DATA=""
COMPONENT_MCP_SERVERS_COUNT=0

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_mcp_servers_data() {
    debug_log "Collecting mcp_servers component data" "INFO"

    COMPONENT_MCP_SERVERS_DATA=""
    COMPONENT_MCP_SERVERS_COUNT=0

    if ! is_module_loaded "mcp"; then
        debug_log "MCP module not loaded, skipping mcp_servers" "INFO"
        return 0
    fi

    local servers_data
    servers_data=$(get_configured_mcp_servers_with_status)

    if [[ -n "$servers_data" ]]; then
        COMPONENT_MCP_SERVERS_DATA="$servers_data"
        # Count servers (comma-separated entries)
        local count=1
        local tmp="$servers_data"
        while [[ "$tmp" == *","* ]]; do
            count=$((count + 1))
            tmp="${tmp#*,}"
        done
        COMPONENT_MCP_SERVERS_COUNT=$count
    fi

    debug_log "mcp_servers data: count=$COMPONENT_MCP_SERVERS_COUNT, data=$COMPONENT_MCP_SERVERS_DATA" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_mcp_servers() {
    if [[ -z "$COMPONENT_MCP_SERVERS_DATA" || "$COMPONENT_MCP_SERVERS_COUNT" -eq 0 ]]; then
        return 1
    fi

    local max_name_len
    max_name_len=$(get_mcp_servers_config "max_name_length" "15")
    local label
    label=$(get_mcp_servers_config "label" "Srv")

    local formatted=""
    local temp_servers="${COMPONENT_MCP_SERVERS_DATA},"
    local parse_count=0

    while [[ "$temp_servers" == *","* ]] && [[ $parse_count -lt 50 ]]; do
        local entry="${temp_servers%%,*}"
        temp_servers="${temp_servers#*,}"
        parse_count=$((parse_count + 1))

        [[ -z "$entry" ]] && continue

        local name="${entry%%:*}"
        local status="${entry#*:}"
        local display_name
        display_name=$(truncate_mcp_name "$name" "$max_name_len")

        local formatted_entry
        case "$status" in
            "connected")
                formatted_entry="${CONFIG_BRIGHT_GREEN}${display_name}${CONFIG_RESET}"
                ;;
            "failed")
                formatted_entry="${CONFIG_RED}${display_name}${CONFIG_RESET}"
                ;;
            *)
                formatted_entry="${CONFIG_YELLOW}${display_name}${CONFIG_RESET}"
                ;;
        esac

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

get_mcp_servers_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "mcp_servers" "enabled" "${default_value:-true}"
            ;;
        "label")
            get_component_config "mcp_servers" "label" "${default_value:-Srv}"
            ;;
        "max_name_length")
            get_component_config "mcp_servers" "max_name_length" "${default_value:-15}"
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
    "mcp_servers" \
    "Project MCP servers from .mcp.json and settings" \
    "mcp display" \
    "$(get_mcp_servers_config 'enabled' 'true')"

debug_log "MCP servers component loaded" "INFO"
