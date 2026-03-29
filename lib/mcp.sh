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
# NATIVE MCP JSON EXTRACTION (Issue #228)
# ============================================================================
# Claude Code sends fresh MCP data on every render via stdin JSON:
#   "mcp": { "servers": [{"name": "ctx7", "status": "connected"}, ...] }
# These functions provide zero-latency, always-fresh MCP data without CLI calls.
# Follows the native-first pattern from lib/cost/native.sh

# Check if native MCP JSON data is available and non-empty
has_native_mcp_data() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        debug_log "MCP native: no STATUSLINE_INPUT_JSON" "INFO"
        return 1
    fi

    local server_count mcp_type
    mcp_type=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.mcp.servers | type' 2>/dev/null)
    server_count=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.mcp.servers | if type == "array" and length > 0 then length else empty end' 2>/dev/null)

    debug_log "MCP native: servers type=$mcp_type, count=${server_count:-0}" "INFO"

    [[ -n "$server_count" && "$server_count" -gt 0 ]] 2>/dev/null
}

# Check if native JSON has MCP field (even if empty servers array)
# Returns 0 if .mcp.servers exists as array (including empty [])
# Used to avoid CLI fallback when CC provides authoritative empty data
has_native_mcp_field() {
    [[ -n "${STATUSLINE_INPUT_JSON:-}" ]] || return 1
    local mcp_type
    mcp_type=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.mcp.servers | type' 2>/dev/null)
    [[ "$mcp_type" == "array" ]]
}

# Parse native MCP servers into "name:status" format (matching CLI parse output)
# Returns: "ctx7:connected,fs:connected,gh:disconnected"
get_native_mcp_servers() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        return 1
    fi

    local servers
    servers=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '
        .mcp.servers // [] |
        if type == "array" and length > 0 then
            map((.name // "unknown") + ":" + (.status // "unknown"))
            | join(",")
        else empty end
    ' 2>/dev/null)

    if [[ -n "$servers" ]]; then
        echo "$servers"
        return 0
    fi
    return 1
}

# Get native MCP status as "connected/total" format
# Returns: "3/3" or "2/3"
get_native_mcp_status() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        return 1
    fi

    local status
    status=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '
        .mcp.servers // [] |
        if type == "array" and length > 0 then
            "\(map(select(.status == "connected")) | length)/\(length)"
        else empty end
    ' 2>/dev/null)

    if [[ -n "$status" ]]; then
        echo "$status"
        return 0
    fi
    return 1
}

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
    local _in_cc_session="false"

    # Detect active Claude Code session.
    # STATUSLINE_INPUT_JSON is only set when CC pipes JSON to us.
    # Inside CC: use short 3s timeout (CLI works in CC v2.1.85+ but may hang
    # in older versions) and prefer cache. Outside CC: normal timeout.
    # Allow mock claude binaries (integration tests with MOCK_BIN_DIR) to proceed.
    if [[ -n "${STATUSLINE_INPUT_JSON:-}" || "${STATUSLINE_TESTING:-}" == "true" ]]; then
        local _claude_path
        _claude_path=$(command -v claude 2>/dev/null) || return 1
        if [[ -z "${MOCK_BIN_DIR:-}" || "$_claude_path" != "${MOCK_BIN_DIR}"/* ]]; then
            _in_cc_session="true"
            timeout_duration="3s"
        fi
    fi

    if ! is_claude_cli_available; then
        debug_log "Claude CLI not available for MCP monitoring" "WARN"
        return 1
    fi

    # Use universal caching system with repository-aware cache keys
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cache_key
        cache_key=$(generate_typed_cache_key "claude_mcp_list" "mcp")

        # Inside active CC session: prefer cache (any age), fall back to short-timeout CLI
        if [[ "$_in_cc_session" == "true" ]]; then
            local cache_file
            cache_file=$(get_cache_file_path "external_${cache_key}" "true")
            if [[ -f "$cache_file" ]] && validate_command_output "$cache_file"; then
                debug_log "MCP: using cached CLI result inside CC session" "INFO"
                cat "$cache_file" 2>/dev/null
                return 0
            fi
            debug_log "MCP: cache cold, trying CLI with ${timeout_duration} timeout" "INFO"
        fi

        # Normal cache + refresh cycle (short timeout inside CC, normal outside)
        if command_exists timeout; then
            cache_external_command "$cache_key" "$CACHE_DURATION_MCP" "validate_command_output" timeout "$timeout_duration" claude mcp list 2>/dev/null
        elif command_exists gtimeout; then
            cache_external_command "$cache_key" "$CACHE_DURATION_MCP" "validate_command_output" gtimeout "$timeout_duration" claude mcp list 2>/dev/null
        else
            cache_external_command "$cache_key" "$CACHE_DURATION_MCP" "validate_command_output" claude mcp list 2>/dev/null
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
            
            # Determine connection status using bash pattern matching (Issue #136)
            # Avoids spawning subshell+grep for each pattern check
            if [[ "$line" == *"$MCP_CONNECTED_PATTERN"* ]]; then
                server_status="$MCP_STATUS_CONNECTED"
            elif [[ "$line" == *"$MCP_DISCONNECTED_PATTERN"* ]]; then
                server_status="$MCP_STATUS_DISCONNECTED"
            elif [[ "$line" == *"$MCP_ERROR_PATTERN"* ]]; then
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

    # Native-first: use fresh JSON from Claude Code stdin (Issue #228)
    if has_native_mcp_data; then
        local native_status
        native_status=$(get_native_mcp_status)
        if [[ -n "$native_status" ]]; then
            local status_time
            status_time=$(end_timer "mcp_status")
            debug_log "MCP status from native JSON in ${status_time}s: ${native_status}" "INFO"
            echo "$native_status"
            return 0
        fi
    elif has_native_mcp_field; then
        # Native JSON has .mcp.servers but it's empty — authoritative "0 servers"
        # Don't fall back to CLI (hangs inside active CC sessions)
        local status_time
        status_time=$(end_timer "mcp_status")
        debug_log "MCP status from native JSON (empty servers): 0/0 in ${status_time}s" "INFO"
        echo "0/0"
        return 0
    fi

    # Fallback: CLI path with reduced 30s cache (only when no native JSON available)
    local mcp_list_output
    if ! mcp_list_output=$(execute_mcp_list); then
        debug_log "Failed to get MCP server list" "WARN"
        local _discard; _discard=$(end_timer "mcp_status")
        echo "?/?"
        return 1
    fi

    # Parse server information
    local servers_data
    servers_data=$(parse_mcp_server_list "$mcp_list_output")

    if [[ -z "$servers_data" ]]; then
        debug_log "No MCP servers found in output" "INFO"
        local _discard; _discard=$(end_timer "mcp_status")
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

    # Native-first: use fresh JSON from Claude Code stdin (Issue #228)
    if has_native_mcp_data; then
        local native_servers
        native_servers=$(get_native_mcp_servers)
        if [[ -n "$native_servers" ]]; then
            local all_servers_time
            all_servers_time=$(end_timer "mcp_all_servers")
            debug_log "MCP all servers from native JSON in ${all_servers_time}s" "INFO"
            echo "$native_servers"
            return 0
        fi
    elif has_native_mcp_field; then
        # Native JSON has .mcp.servers but it's empty — authoritative "no servers"
        # Don't fall back to CLI (hangs inside active CC sessions)
        local all_servers_time
        all_servers_time=$(end_timer "mcp_all_servers")
        debug_log "MCP all servers from native JSON (empty): none in ${all_servers_time}s" "INFO"
        echo "$CONFIG_MCP_NONE_MESSAGE"
        return 0
    fi

    # Fallback: CLI path with reduced 30s cache (only when no native JSON available)
    local mcp_list_output
    if ! mcp_list_output=$(execute_mcp_list); then
        debug_log "Failed to get MCP server list for all servers" "WARN"
        local _discard; _discard=$(end_timer "mcp_all_servers")
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

# ============================================================================
# FILE-BASED MCP SERVER DETECTION
# ============================================================================
# Detects MCP servers from project .mcp.json and global settings.json files.
# Provides a config-file-based fallback when CC doesn't send MCP data via stdin.
# SSH servers are probed for connectivity; command-based servers check PATH.

# Parse configured MCP servers from .mcp.json and global settings.json
# Returns lines of "name:command:ssh_host" (ssh_host empty for non-SSH)
get_configured_mcp_servers() {
    local search_dir="${1:-${STATUSLINE_CURRENT_DIR:-$(pwd)}}"
    local mcp_json_file="$search_dir/.mcp.json"
    local servers=""

    # Source 1: Project .mcp.json
    if [[ -f "$mcp_json_file" ]]; then
        local file_servers
        file_servers=$(jq -r '
            .mcpServers // {} | to_entries[] |
            .key as $name |
            .value |
            ($name + ":" + (.command // "unknown") + ":" +
                (if .command == "ssh" then (.args[0] // "" | split("@") | if length > 1 then .[1] else .[0] end) else "" end))
        ' "$mcp_json_file" 2>/dev/null)
        if [[ -n "$file_servers" ]]; then
            servers="$file_servers"
        fi
    fi

    # Source 2: Global settings.json mcpServers
    local global_settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
    if [[ -f "$global_settings" ]]; then
        local settings_servers
        settings_servers=$(jq -r '
            .mcpServers // {} | to_entries[] |
            .key as $name |
            .value |
            ($name + ":" + (.command // "unknown") + ":" +
                (if .command == "ssh" then (.args[0] // "" | split("@") | if length > 1 then .[1] else .[0] end) else "" end))
        ' "$global_settings" 2>/dev/null)
        if [[ -n "$settings_servers" ]]; then
            if [[ -n "$servers" ]]; then
                servers="$servers"$'\n'"$settings_servers"
            else
                servers="$settings_servers"
            fi
        fi
    fi

    echo "$servers"
}

# Probe SSH server connectivity on port 22
# Returns 0 (success) if reachable, 1 (failure) if not
probe_ssh_server() {
    local host="$1"
    local timeout_sec="${2:-1}"

    if [[ -z "$host" ]]; then
        return 1
    fi

    # Prefer nc (netcat) — available on most systems, clean timeout handling
    if command_exists nc; then
        nc -z -w "$timeout_sec" "$host" 22 &>/dev/null
        return $?
    fi

    # Fallback: bash /dev/tcp with manual timeout
    (echo >/dev/tcp/"$host"/22) &>/dev/null &
    local pid=$!
    local elapsed=0
    while kill -0 "$pid" 2>/dev/null && [[ $elapsed -lt $timeout_sec ]]; do
        sleep 0.2
        elapsed=$((elapsed + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        return 1
    fi
    wait "$pid" 2>/dev/null
    return $?
}

# Get configured MCP servers with live connectivity status
# Returns comma-separated "name:status" pairs (e.g. "ctx7:connected,remote:failed")
# Caches results for 300s (5 min) per directory
get_configured_mcp_servers_with_status() {
    local search_dir="${1:-${STATUSLINE_CURRENT_DIR:-$(pwd)}}"
    local result=""
    local dir_hash
    dir_hash=$(printf '%s' "$search_dir" | md5sum 2>/dev/null | cut -c1-8) ||
    dir_hash=$(printf '%s' "$search_dir" | md5 -q 2>/dev/null | cut -c1-8) ||
    dir_hash="default"
    local cache_key="mcp_configured_servers_${dir_hash}"

    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cached
        cached=$(get_cached_value "$cache_key" "300" 2>/dev/null)
        if [[ -n "$cached" ]]; then
            debug_log "MCP configured servers from cache: $cached" "INFO"
            echo "$cached"
            return 0
        fi
    fi

    local servers
    servers=$(get_configured_mcp_servers "$search_dir")

    if [[ -z "$servers" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local name="${line%%:*}"
        local rest="${line#*:}"
        local command="${rest%%:*}"
        local ssh_host="${rest#*:}"

        local status="configured"
        if [[ "$command" == "ssh" && -n "$ssh_host" ]]; then
            if probe_ssh_server "$ssh_host" "1"; then
                status="connected"
            else
                status="failed"
            fi
        elif command_exists "$command"; then
            status="connected"
        else
            status="failed"
        fi

        if [[ -n "$result" ]]; then
            result="$result,$name:$status"
        else
            result="$name:$status"
        fi
    done <<< "$servers"

    if [[ -n "$result" && "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        set_cached_value "$cache_key" "$result" 2>/dev/null
    fi

    debug_log "MCP configured servers probed: $result" "INFO"
    echo "$result"
}

# Get only active (connected) MCP servers
get_active_mcp_servers() {
    start_timer "mcp_active_servers"
    
    local all_servers
    all_servers=$(get_all_mcp_servers)
    
    if [[ "$all_servers" == "$CONFIG_MCP_UNKNOWN_MESSAGE" ]] || [[ "$all_servers" == "$CONFIG_MCP_NONE_MESSAGE" ]]; then
        local _discard; _discard=$(end_timer "mcp_active_servers")
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

# Initialize the module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_mcp_module
fi

# Export MCP functions
export -f has_native_mcp_data get_native_mcp_servers get_native_mcp_status
export -f is_claude_cli_available execute_mcp_list parse_mcp_server_list
export -f get_mcp_status get_all_mcp_servers get_active_mcp_servers
export -f format_mcp_servers get_mcp_display get_mcp_health
export -f get_mcp_server_details get_cached_mcp_status
export -f get_configured_mcp_servers probe_ssh_server get_configured_mcp_servers_with_status