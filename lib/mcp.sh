#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Server Monitoring Module
# ============================================================================
# 
# This module handles all MCP (Model Context Protocol) server monitoring,
# including connection status, server enumeration, and health checking.
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_MCP_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_MCP_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# MCP CONSTANTS
# ============================================================================

# MCP status indicators
export MCP_STATUS_CONNECTED="connected"
export MCP_STATUS_DISCONNECTED="disconnected"
export MCP_STATUS_UNKNOWN="unknown"
export MCP_STATUS_ERROR="error"

# Connection patterns for parsing MCP output
export MCP_CONNECTED_PATTERN="✓ Connected"
export MCP_DISCONNECTED_PATTERN="✗ Disconnected"
export MCP_ERROR_PATTERN="❌ Error"

# ============================================================================
# MCP SERVER DETECTION
# ============================================================================

# Check if Claude CLI is available
is_claude_cli_available() {
    command_exists claude
}

# Execute claude mcp list command with intelligent caching
execute_mcp_list() {
    local timeout_duration="${1:-$CONFIG_MCP_TIMEOUT}"
    
    if ! is_claude_cli_available; then
        debug_log "Claude CLI not available for MCP monitoring" "WARN"
        return 1
    fi
    
    # Use universal caching system with repository-aware cache keys
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        # Generate repository-aware cache key to prevent cross-contamination
        local cache_key
        cache_key=$(generate_typed_cache_key "claude_mcp_list" "mcp")
        
        # Use direct command instead of function call for cache compatibility
        if command_exists timeout; then
            cache_external_command "$cache_key" "$CACHE_DURATION_MEDIUM" "validate_command_output" timeout "$timeout_duration" claude mcp list 2>/dev/null
        elif command_exists gtimeout; then
            cache_external_command "$cache_key" "$CACHE_DURATION_MEDIUM" "validate_command_output" gtimeout "$timeout_duration" claude mcp list 2>/dev/null
        else
            cache_external_command "$cache_key" "$CACHE_DURATION_MEDIUM" "validate_command_output" claude mcp list 2>/dev/null
        fi
    else
        _execute_mcp_list_direct "$timeout_duration"
    fi
}

# Internal function for direct MCP list execution (used by caching)
_execute_mcp_list_direct() {
    local timeout_duration="${1:-$CONFIG_MCP_TIMEOUT}"
    
    # Execute with timeout protection
    if command_exists timeout; then
        timeout "$timeout_duration" claude mcp list 2>/dev/null
    elif command_exists gtimeout; then
        gtimeout "$timeout_duration" claude mcp list 2>/dev/null
    else
        # Fallback without timeout (risky)
        claude mcp list 2>/dev/null
    fi
}

# Parse MCP server list output
parse_mcp_server_list() {
    local mcp_output="$1"
    local servers_data=""
    
    if [[ -z "$mcp_output" ]]; then
        return 1
    fi
    
    while IFS= read -r line; do
        # Skip empty lines and header lines
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^Checking ]] && continue
        
        # Parse server name using secure parsing
        local server_name
        if server_name=$(parse_mcp_server_name_secure "$line" 2>/dev/null); then
            local server_status="$MCP_STATUS_DISCONNECTED"
            
            # Determine connection status
            if echo "$line" | grep -q "$MCP_CONNECTED_PATTERN"; then
                server_status="$MCP_STATUS_CONNECTED"
            elif echo "$line" | grep -q "$MCP_DISCONNECTED_PATTERN"; then
                server_status="$MCP_STATUS_DISCONNECTED"
            elif echo "$line" | grep -q "$MCP_ERROR_PATTERN"; then
                server_status="$MCP_STATUS_ERROR"
            else
                server_status="$MCP_STATUS_UNKNOWN"
            fi
            
            # Add to servers data
            if [[ -z "$servers_data" ]]; then
                servers_data="${server_name}:${server_status}"
            else
                servers_data="${servers_data},${server_name}:${server_status}"
            fi
        fi
    done <<<"$mcp_output"
    
    echo "$servers_data"
}

# ============================================================================
# MCP STATUS FUNCTIONS
# ============================================================================

# Get basic MCP server count status (connected/total)
get_mcp_status() {
    start_timer "mcp_status"
    
    local mcp_list_output
    if ! mcp_list_output=$(execute_mcp_list); then
        debug_log "Failed to get MCP server list" "WARN"
        end_timer "mcp_status"
        echo "?/?"
        return 1
    fi
    
    # Parse server information
    local servers_data
    servers_data=$(parse_mcp_server_list "$mcp_list_output")
    
    if [[ -z "$servers_data" ]]; then
        debug_log "No MCP servers found in output" "INFO"
        end_timer "mcp_status"
        echo "0/0"
        return 0
    fi
    
    # Count connected and total servers
    local connected_count=0
    local total_count=0
    
    # Split servers by comma and count
    local temp_servers="${servers_data}," # Add trailing comma for easier parsing
    local parse_count=0
    local max_servers=50  # Prevent infinite parsing loops
    
    while [[ "$temp_servers" == *","* ]] && [[ $parse_count -lt $max_servers ]]; do
        local server_entry="${temp_servers%%,*}"
        temp_servers="${temp_servers#*,}"
        parse_count=$((parse_count + 1))
        
        # Extract server status
        local server_status="${server_entry#*:}"
        
        total_count=$((total_count + 1))
        
        if [[ "$server_status" == "$MCP_STATUS_CONNECTED" ]]; then
            connected_count=$((connected_count + 1))
        fi
    done
    
    local status_time
    status_time=$(end_timer "mcp_status")
    debug_log "MCP status check completed in ${status_time}s: ${connected_count}/${total_count}" "INFO"
    
    echo "${connected_count}/${total_count}"
}

# Get all MCP servers with their status
get_all_mcp_servers() {
    start_timer "mcp_all_servers"
    
    local mcp_list_output
    if ! mcp_list_output=$(execute_mcp_list); then
        debug_log "Failed to get MCP server list for all servers" "WARN"
        end_timer "mcp_all_servers"
        echo "$CONFIG_MCP_UNKNOWN_MESSAGE"
        return 1
    fi
    
    local servers_data
    servers_data=$(parse_mcp_server_list "$mcp_list_output")
    
    local all_servers_time
    all_servers_time=$(end_timer "mcp_all_servers")
    debug_log "MCP all servers check completed in ${all_servers_time}s" "INFO"
    
    if [[ -n "$servers_data" ]]; then
        echo "$servers_data"
    else
        echo "$CONFIG_MCP_NONE_MESSAGE"
    fi
}

# Get only active (connected) MCP servers
get_active_mcp_servers() {
    start_timer "mcp_active_servers"
    
    local all_servers
    all_servers=$(get_all_mcp_servers)
    
    if [[ "$all_servers" == "$CONFIG_MCP_UNKNOWN_MESSAGE" ]] || [[ "$all_servers" == "$CONFIG_MCP_NONE_MESSAGE" ]]; then
        end_timer "mcp_active_servers"
        echo "$all_servers"
        return 0
    fi
    
    local active_servers=""
    
    # Filter only connected servers
    local temp_servers="${all_servers}," # Add trailing comma for easier parsing
    local parse_count=0
    local max_servers=50  # Prevent infinite parsing loops
    
    while [[ "$temp_servers" == *","* ]] && [[ $parse_count -lt $max_servers ]]; do
        local server_entry="${temp_servers%%,*}"
        temp_servers="${temp_servers#*,}"
        parse_count=$((parse_count + 1))
        
        # Extract server name and status
        local server_name="${server_entry%:*}"
        local server_status="${server_entry#*:}"
        
        if [[ "$server_status" == "$MCP_STATUS_CONNECTED" ]]; then
            if [[ -z "$active_servers" ]]; then
                active_servers="$server_name"
            else
                active_servers="${active_servers},${server_name}"
            fi
        fi
    done
    
    local active_servers_time
    active_servers_time=$(end_timer "mcp_active_servers")
    debug_log "MCP active servers check completed in ${active_servers_time}s" "INFO"
    
    if [[ -n "$active_servers" ]]; then
        echo "$active_servers"
    else
        echo "$CONFIG_MCP_NONE_MESSAGE"
    fi
}

# ============================================================================
# MCP DISPLAY FORMATTING
# ============================================================================

# Format MCP servers with colors and strikethrough for broken ones
format_mcp_servers() {
    local servers="$1"
    local formatted=""

    if [[ "$servers" == "$CONFIG_MCP_UNKNOWN_MESSAGE" ]] || [[ "$servers" == "$CONFIG_MCP_NONE_MESSAGE" ]]; then
        echo "$servers"
        return
    fi

    # Split servers by comma and process each one
    local temp_servers="${servers}," # Add trailing comma for easier parsing
    local parse_count=0
    local max_servers=50  # Prevent infinite parsing loops
    
    while [[ "$temp_servers" == *","* ]] && [[ $parse_count -lt $max_servers ]]; do
        local server_entry="${temp_servers%%,*}"
        temp_servers="${temp_servers#*,}"
        parse_count=$((parse_count + 1))
        
        # Extract server name and status
        local server_name="${server_entry%:*}"
        local server_status="${server_entry#*:}"

        local formatted_server
        case "$server_status" in
            "$MCP_STATUS_CONNECTED")
                # Green for connected servers
                formatted_server="${CONFIG_BRIGHT_GREEN}${server_name}${CONFIG_RESET}"
                ;;
            "$MCP_STATUS_ERROR")
                # Red with strikethrough for error servers
                formatted_server="${CONFIG_RED}${CONFIG_STRIKETHROUGH}${server_name}${CONFIG_RESET}"
                ;;
            "$MCP_STATUS_DISCONNECTED"|"$MCP_STATUS_UNKNOWN"|*)
                # Red with strikethrough for disconnected/unknown servers
                formatted_server="${CONFIG_RED}${CONFIG_STRIKETHROUGH}${server_name}${CONFIG_RESET}"
                ;;
        esac

        if [[ -z "$formatted" ]]; then
            formatted="$formatted_server"
        else
            formatted="$formatted, $formatted_server"
        fi
    done

    echo "$formatted"
}

# Determine MCP status color and display format
get_mcp_display() {
    local mcp_status="$1"
    
    if [[ "$mcp_status" == "?/?" ]]; then
        echo "31m:MCP:?/?" # Red for error
    elif [[ "$mcp_status" =~ ^([0-9]+)/([0-9]+)$ ]]; then
        local connected="${BASH_REMATCH[1]}"
        local total="${BASH_REMATCH[2]}"

        if [[ "$total" == "0" ]]; then
            # No MCP servers configured - show as dim/gray
            echo "2m:---" # Dim for "no MCP configured"
        elif [[ "$connected" == "$total" ]]; then
            echo "92m:MCP:${mcp_status}" # Bright green for all connected
        else
            echo "33m:MCP:${mcp_status}" # Yellow for partial connection
        fi
    else
        echo "31m:MCP:?/?" # Red for unknown format
    fi
}

# ============================================================================
# MCP HEALTH MONITORING
# ============================================================================

# Check overall MCP system health
get_mcp_health() {
    if ! is_claude_cli_available; then
        echo "no_cli"
        return 1
    fi
    
    local mcp_status
    mcp_status=$(get_mcp_status)
    
    case "$mcp_status" in
        "?/?")
            echo "error"
            ;;
        "0/0")
            echo "no_servers"
            ;;
        *)
            if [[ "$mcp_status" =~ ^([0-9]+)/([0-9]+)$ ]]; then
                local connected="${BASH_REMATCH[1]}"
                local total="${BASH_REMATCH[2]}"
                
                if [[ "$connected" == "$total" ]]; then
                    echo "healthy"
                elif [[ "$connected" -gt 0 ]]; then
                    echo "partial"
                else
                    echo "unhealthy"
                fi
            else
                echo "unknown"
            fi
            ;;
    esac
}

# Get MCP server details (for debugging/troubleshooting)
get_mcp_server_details() {
    local server_name="$1"
    
    if [[ -z "$server_name" ]]; then
        handle_error "Server name required for details" 1 "get_mcp_server_details"
        return 1
    fi
    
    local all_servers
    all_servers=$(get_all_mcp_servers)
    
    # Find the specific server
    local temp_servers="${all_servers},"
    local parse_count=0
    local max_servers=50  # Prevent infinite parsing loops
    
    while [[ "$temp_servers" == *","* ]] && [[ $parse_count -lt $max_servers ]]; do
        local server_entry="${temp_servers%%,*}"
        temp_servers="${temp_servers#*,}"
        parse_count=$((parse_count + 1))
        
        local entry_name="${server_entry%:*}"
        local entry_status="${server_entry#*:}"
        
        if [[ "$entry_name" == "$server_name" ]]; then
            echo "Server: $entry_name"
            echo "Status: $entry_status"
            return 0
        fi
    done
    
    echo "Server '$server_name' not found"
    return 1
}

# ============================================================================
# MCP CACHING (Optional Enhancement)
# ============================================================================

# Cache MCP status for performance (optional)
get_cached_mcp_status() {
    local cache_duration="${1:-120}" # 2 minutes default - MCP disconnections are not that frequent
    
    # Use universal caching system if available
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        # Generate repository-aware cache key for MCP status
        local cache_key
        cache_key=$(generate_typed_cache_key "mcp_status" "mcp")
        cache_external_command "$cache_key" "$cache_duration" "validate_command_output" bash -c 'get_mcp_status'
    else
        # Fallback to direct execution
        get_mcp_status
    fi
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the MCP module
init_mcp_module() {
    debug_log "MCP monitoring module initialized" "INFO"
    
    # Check if Claude CLI is available
    if ! is_claude_cli_available; then
        handle_warning "Claude CLI not available - MCP monitoring disabled" "init_mcp_module"
        return 1
    fi
    
    return 0
}

# Initialize the module
init_mcp_module

# Export MCP functions
export -f is_claude_cli_available execute_mcp_list parse_mcp_server_list
export -f get_mcp_status get_all_mcp_servers get_active_mcp_servers
export -f format_mcp_servers get_mcp_display get_mcp_health
export -f get_mcp_server_details get_cached_mcp_status