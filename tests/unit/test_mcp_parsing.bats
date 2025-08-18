#!/usr/bin/env bats

# Unit tests for MCP server parsing functions in statusline.sh

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
}

teardown() {
    common_teardown
}

# Test MCP status parsing with various scenarios
@test "get_mcp_status should parse connected servers correctly" {
    setup_mock_mcp "connected"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    assert_output "3/3"
}

@test "get_mcp_status should parse partial connection correctly" {
    setup_mock_mcp "partial"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    assert_output "2/3"
}

@test "get_mcp_status should handle empty server list" {
    setup_mock_mcp "empty"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    assert_output "0/0"
}

@test "get_mcp_status should handle timeout gracefully" {
    setup_mock_mcp "timeout"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    assert_output "?/?"
}

@test "get_mcp_status should handle command not found" {
    setup_mock_mcp "not_available"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    assert_output "?/?"
}

# Test server name parsing (addresses security concern from line 374, 396-398)
@test "should parse valid server names correctly" {
    local test_output="upstash-context-7-mcp: npx -y @upstash/context-7-mcp ✓ Connected"
    
    # Test the regex pattern extraction
    if echo "$test_output" | grep -q "^[a-zA-Z0-9_-]*:"; then
        server_name=$(echo "$test_output" | grep -o "^[a-zA-Z0-9_-]*" | head -1)
        [ "$server_name" = "upstash-context-7-mcp" ]
    else
        fail "Should match valid server name pattern"
    fi
}

@test "should reject invalid server names with special characters" {
    local test_outputs=(
        "server@name: invalid server"
        "server name: space in name"
        "server/name: slash in name"
        "server.com: dot should work"
        "123server: number prefix should work"
    )
    
    for output in "${test_outputs[@]}"; do
        if echo "$output" | grep -q "^[a-zA-Z0-9_-]*:"; then
            server_name=$(echo "$output" | grep -o "^[a-zA-Z0-9_-]*" | head -1)
            case "$output" in
                "server@name:"*)
                    fail "Should reject @ character"
                    ;;
                "server name:"*)
                    fail "Should reject space character"
                    ;;
                "server/name:"*)
                    fail "Should reject slash character"
                    ;;
                "server.com:"*)
                    [ "$server_name" = "server" ]  # Should only capture up to dot
                    ;;
                "123server:"*)
                    [ "$server_name" = "123server" ]  # Should allow number prefix
                    ;;
            esac
        fi
    done
}

@test "should handle malformed MCP output gracefully" {
    cd "$TEST_TMP_DIR"
    
    # Create malformed MCP output
    cat > "$MOCK_BIN_DIR/claude" << 'EOF'
#!/bin/bash
if [[ "$1" == "mcp" && "$2" == "list" ]]; then
    echo "Malformed output without proper format"
    echo "Another line without colon"
    echo ": colon at start"
    echo "no-colon-anywhere"
fi
EOF
    chmod +x "$MOCK_BIN_DIR/claude"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    assert_output "0/0"
}

# Test get_all_mcp_servers function
@test "get_all_mcp_servers should return formatted server list" {
    setup_mock_mcp "connected"
    
    source "$STATUSLINE_SCRIPT"
    run get_all_mcp_servers
    
    assert_success
    assert_output_contains "upstash-context-7-mcp:connected"
    assert_output_contains "filesystem:connected"
    assert_output_contains "brave-search:connected"
}

@test "get_all_mcp_servers should handle mixed connection states" {
    setup_mock_mcp "partial"
    
    source "$STATUSLINE_SCRIPT"
    run get_all_mcp_servers
    
    assert_success
    assert_output_contains "upstash-context-7-mcp:connected"
    assert_output_contains "filesystem:disconnected"
    assert_output_contains "brave-search:connected"
}

# Test get_active_mcp_servers function (backward compatibility)
@test "get_active_mcp_servers should return only connected servers" {
    setup_mock_mcp "partial"
    
    source "$STATUSLINE_SCRIPT"
    run get_active_mcp_servers
    
    assert_success
    assert_output_contains "upstash-context-7-mcp"
    assert_output_contains "brave-search"
    # Should NOT contain filesystem (disconnected)
    refute_output --partial "filesystem"
}

@test "get_active_mcp_servers should return none message when no servers connected" {
    cd "$TEST_TMP_DIR"
    
    # Mock output with no connected servers
    cat > "$MOCK_BIN_DIR/claude" << 'EOF'
#!/bin/bash
if [[ "$1" == "mcp" && "$2" == "list" ]]; then
    echo "Checking MCP servers..."
    echo ""
    echo "server1: command ✗ Failed to connect"
    echo "server2: command ✗ Failed to connect"
fi
EOF
    chmod +x "$MOCK_BIN_DIR/claude"
    
    source "$STATUSLINE_SCRIPT"
    run get_active_mcp_servers
    
    assert_success
    assert_output "none"
}

# Test format_mcp_servers function
@test "format_mcp_servers should format connected servers with colors" {
    local test_input="server1:connected,server2:connected"
    
    source "$STATUSLINE_SCRIPT"
    run format_mcp_servers "$test_input"
    
    assert_success
    # Should contain server names (exact color codes depend on theme)
    assert_output_contains "server1"
    assert_output_contains "server2"
}

@test "format_mcp_servers should format disconnected servers with strikethrough" {
    local test_input="server1:connected,server2:disconnected"
    
    source "$STATUSLINE_SCRIPT"
    run format_mcp_servers "$test_input"
    
    assert_success
    assert_output_contains "server1"
    assert_output_contains "server2"
    # Should contain strikethrough formatting for disconnected server
    assert_output_contains "\033[9m"  # strikethrough ANSI code
}

@test "format_mcp_servers should handle special status messages" {
    source "$STATUSLINE_SCRIPT"
    
    run format_mcp_servers "unknown"
    assert_success
    assert_output "unknown"
    
    run format_mcp_servers "none"
    assert_success
    assert_output "none"
}

# Test get_mcp_display function for color determination
@test "get_mcp_display should return green for all connected" {
    source "$STATUSLINE_SCRIPT"
    mcp_status="3/3"
    run get_mcp_display
    
    assert_success
    assert_output_contains "92m"  # bright green
    assert_output_contains "MCP:3/3"
}

@test "get_mcp_display should return yellow for partial connection" {
    source "$STATUSLINE_SCRIPT"
    mcp_status="2/3"
    run get_mcp_display
    
    assert_success
    assert_output_contains "33m"  # yellow
    assert_output_contains "MCP:2/3"
}

@test "get_mcp_display should return red for connection error" {
    source "$STATUSLINE_SCRIPT"
    mcp_status="?/?"
    run get_mcp_display
    
    assert_success
    assert_output_contains "31m"  # red
    assert_output_contains "MCP:?/?"
}

@test "get_mcp_display should return dim for no servers configured" {
    source "$STATUSLINE_SCRIPT"
    mcp_status="0/0"
    run get_mcp_display
    
    assert_success
    assert_output_contains "2m"   # dim
    assert_output_contains "---"
}

# Test edge cases and security concerns
@test "should handle extremely long server names safely" {
    cd "$TEST_TMP_DIR"
    
    # Create output with very long server name
    local long_name=$(printf 'a%.0s' {1..1000})
    cat > "$MOCK_BIN_DIR/claude" << EOF
#!/bin/bash
if [[ "\$1" == "mcp" && "\$2" == "list" ]]; then
    echo "Checking MCP servers..."
    echo "$long_name: command ✓ Connected"
fi
EOF
    chmod +x "$MOCK_BIN_DIR/claude"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    # Should handle gracefully without crashing
}

@test "should handle server names with Unicode characters" {
    cd "$TEST_TMP_DIR"
    
    # Server names should only match ASCII alphanumeric, underscore, hyphen
    cat > "$MOCK_BIN_DIR/claude" << 'EOF'
#!/bin/bash
if [[ "$1" == "mcp" && "$2" == "list" ]]; then
    echo "Checking MCP servers..."
    echo "válid-server: command ✓ Connected"  # Should not match
    echo "valid_server: command ✓ Connected"  # Should match
fi
EOF
    chmod +x "$MOCK_BIN_DIR/claude"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    # Should only count the valid ASCII server name
    assert_output "1/1"
}

# Test timeout handling with mocked timeout commands
@test "should respect MCP timeout configuration" {
    create_timeout_mock "1s"
    
    # Create a slow mock command
    cat > "$MOCK_BIN_DIR/claude" << 'EOF'
#!/bin/bash
if [[ "$1" == "mcp" && "$2" == "list" ]]; then
    sleep 5  # Longer than timeout
    echo "This should not appear"
fi
EOF
    chmod +x "$MOCK_BIN_DIR/claude"
    
    source "$STATUSLINE_SCRIPT"
    run get_mcp_status
    
    assert_success
    assert_output "?/?"  # Should timeout and return unknown status
}