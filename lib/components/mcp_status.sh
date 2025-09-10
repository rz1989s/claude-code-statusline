#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Status Component
# ============================================================================
# 
# This component handles MCP server status display.
#
# Dependencies: mcp.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_MCP_STATUS_STATUS=""
COMPONENT_MCP_STATUS_SERVERS=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect MCP status data
collect_mcp_status_data() {
    debug_log "Collecting mcp_status component data" "INFO"
    
    COMPONENT_MCP_STATUS_STATUS="0/0"
    COMPONENT_MCP_STATUS_SERVERS="$CONFIG_MCP_NONE_MESSAGE"
    
    if is_module_loaded "mcp" && is_claude_cli_available; then
        COMPONENT_MCP_STATUS_STATUS=$(get_mcp_status)
        COMPONENT_MCP_STATUS_SERVERS=$(get_all_mcp_servers)
    fi
    
    debug_log "mcp_status data: status=$COMPONENT_MCP_STATUS_STATUS, servers=$COMPONENT_MCP_STATUS_SERVERS" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render MCP status display
render_mcp_status() {
    local show_server_list
    show_server_list=$(get_mcp_status_config "show_server_list" "true")
    
    # Format MCP status
    local formatted_status
    formatted_status=$(get_mcp_status_format "$COMPONENT_MCP_STATUS_STATUS")
    
    if [[ "$show_server_list" == "true" && "$COMPONENT_MCP_STATUS_SERVERS" != "$CONFIG_MCP_NONE_MESSAGE" ]]; then
        # Format server list
        local formatted_servers
        formatted_servers=$(format_mcp_server_list "$COMPONENT_MCP_STATUS_SERVERS")
        
        echo "${formatted_status}: ${formatted_servers}"
    else
        echo "$formatted_status"
    fi
    
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
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

# Register the mcp_status component
register_component \
    "mcp_status" \
    "MCP server status and health" \
    "mcp display" \
    "$(get_mcp_status_config 'enabled' 'true')"

debug_log "MCP status component loaded" "INFO"