#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Servers Component
# ============================================================================
#
# Displays project-level MCP servers from .mcp.json and settings mcpServers.
# Uses rotating display: shows one name + N remaining per render cycle.
# Color: green=connected, red=failed, yellow=unknown.
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
    max_name_len=$(get_mcp_servers_config "max_name_length" "10")
    local label
    label=$(get_mcp_servers_config "label" "S")

    # Build entries array (name:status pairs)
    local names=()
    local statuses=()
    local tmp="${COMPONENT_MCP_SERVERS_DATA},"
    while [[ "$tmp" == *","* ]]; do
        local entry="${tmp%%,*}"
        tmp="${tmp#*,}"
        [[ -z "$entry" ]] && continue
        names+=("${entry%%:*}")
        statuses+=("${entry#*:}")
    done

    local total=${#names[@]}
    if [[ $total -eq 0 ]]; then
        return 1
    fi

    # Rotate: pick entry based on current time
    local idx=$(( $(date +%s) % total ))
    local display_name
    display_name=$(truncate_mcp_name "${names[$idx]}" "$max_name_len")

    local color
    case "${statuses[$idx]}" in
        "connected") color="$CONFIG_BRIGHT_GREEN" ;;
        "failed")    color="$CONFIG_RED" ;;
        *)           color="$CONFIG_YELLOW" ;;
    esac

    local formatted="${color}${display_name}${CONFIG_RESET}"

    local remaining=$((total - 1))
    if [[ $remaining -gt 0 ]]; then
        formatted="${formatted} ${CONFIG_DIM}+${remaining}${CONFIG_RESET}"
    fi

    echo "${CONFIG_DIM}${label}:${CONFIG_RESET}${formatted}"
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
            get_component_config "mcp_servers" "label" "${default_value:-S}"
            ;;
        "max_name_length")
            get_component_config "mcp_servers" "max_name_length" "${default_value:-10}"
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
    "Project MCP servers with rotation display" \
    "mcp display" \
    "$(get_mcp_servers_config 'enabled' 'true')"

debug_log "MCP servers component loaded" "INFO"
