#!/usr/bin/env bats

# Unit tests for file-based MCP server detection (lib/mcp.sh)
# Tests get_configured_mcp_servers, probe_ssh_server, get_configured_mcp_servers_with_status

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
  common_setup

  # Source the statusline to get all functions loaded
  source "$STATUSLINE_SCRIPT" < /dev/null
}

teardown() {
  common_teardown
}

# ============================================================================
# get_configured_mcp_servers — .mcp.json parsing
# ============================================================================

@test "get_configured_mcp_servers returns servers from .mcp.json" {
  local test_dir="$TEST_TMP_DIR/project_with_mcp"
  mkdir -p "$test_dir"

  cat > "$test_dir/.mcp.json" << 'MCPJSON'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-filesystem"]
    }
  }
}
MCPJSON

  run get_configured_mcp_servers "$test_dir"

  assert_success
  assert_output --partial "context7:npx:"
  assert_output --partial "filesystem:npx:"
}

@test "get_configured_mcp_servers returns empty for missing .mcp.json" {
  local test_dir="$TEST_TMP_DIR/no_mcp_dir"
  mkdir -p "$test_dir"

  # No .mcp.json in this directory, and no global settings.json either
  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/fake_claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  run get_configured_mcp_servers "$test_dir"

  assert_success
  # Output should be empty (no servers found)
  [[ -z "$output" ]]
}

@test "get_configured_mcp_servers returns empty for empty mcpServers" {
  local test_dir="$TEST_TMP_DIR/empty_mcp"
  mkdir -p "$test_dir"

  cat > "$test_dir/.mcp.json" << 'MCPJSON'
{
  "mcpServers": {}
}
MCPJSON

  # Ensure no global settings either
  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/fake_claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  run get_configured_mcp_servers "$test_dir"

  assert_success
  [[ -z "$output" ]]
}

@test "get_configured_mcp_servers parses server command type" {
  local test_dir="$TEST_TMP_DIR/mixed_commands"
  mkdir -p "$test_dir"

  cat > "$test_dir/.mcp.json" << 'MCPJSON'
{
  "mcpServers": {
    "ctx7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "remote-dev": {
      "command": "ssh",
      "args": ["user@dev.example.com"]
    },
    "local-tool": {
      "command": "node",
      "args": ["./server.js"]
    }
  }
}
MCPJSON

  # Ensure no global settings
  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/fake_claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  run get_configured_mcp_servers "$test_dir"

  assert_success
  # Verify command types are parsed correctly
  assert_output --partial "ctx7:npx:"
  assert_output --partial "remote-dev:ssh:dev.example.com"
  assert_output --partial "local-tool:node:"
}

@test "get_configured_mcp_servers parses SSH host from user@host format" {
  local test_dir="$TEST_TMP_DIR/ssh_host_parse"
  mkdir -p "$test_dir"

  cat > "$test_dir/.mcp.json" << 'MCPJSON'
{
  "mcpServers": {
    "remote-server": {
      "command": "ssh",
      "args": ["deploy@production.example.com"]
    }
  }
}
MCPJSON

  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/fake_claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  run get_configured_mcp_servers "$test_dir"

  assert_success
  # Should extract host from user@host — "production.example.com"
  assert_output --partial "remote-server:ssh:production.example.com"
}

@test "get_configured_mcp_servers merges project and global settings" {
  local test_dir="$TEST_TMP_DIR/merge_test"
  mkdir -p "$test_dir"

  # Project .mcp.json
  cat > "$test_dir/.mcp.json" << 'MCPJSON'
{
  "mcpServers": {
    "project-server": {
      "command": "npx",
      "args": ["-y", "@project/mcp"]
    }
  }
}
MCPJSON

  # Global settings.json with mcpServers
  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  cat > "$CLAUDE_CONFIG_DIR/settings.json" << 'SETTINGS'
{
  "mcpServers": {
    "global-server": {
      "command": "node",
      "args": ["./global-mcp.js"]
    }
  }
}
SETTINGS

  run get_configured_mcp_servers "$test_dir"

  assert_success
  assert_output --partial "project-server:npx:"
  assert_output --partial "global-server:node:"
}

@test "get_configured_mcp_servers handles malformed JSON gracefully" {
  local test_dir="$TEST_TMP_DIR/bad_json"
  mkdir -p "$test_dir"

  echo "not valid json {{{" > "$test_dir/.mcp.json"

  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/fake_claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  run get_configured_mcp_servers "$test_dir"

  # Should not crash — jq errors go to /dev/null
  assert_success
  [[ -z "$output" ]]
}

# ============================================================================
# probe_ssh_server — connectivity checks
# ============================================================================

@test "probe_ssh_server returns connected for reachable host" {
  # 127.0.0.1 port 22 — only works if sshd is running locally
  # Use nc to pre-check so we skip cleanly if SSH isn't available
  if ! nc -z -w 1 127.0.0.1 22 &>/dev/null; then
    skip "Local SSH not running on port 22"
  fi

  run probe_ssh_server "127.0.0.1" "1"

  assert_success
}

@test "probe_ssh_server returns failure for unreachable host" {
  # Use a hostname that definitely won't resolve
  # macOS nc hangs on non-routable IPs (192.0.2.1), so use DNS failure instead
  run probe_ssh_server "host.invalid" "1"

  assert_failure
}

@test "probe_ssh_server returns failure for empty host" {
  run probe_ssh_server "" "1"

  assert_failure
}

@test "probe_ssh_server respects timeout parameter" {
  # Use localhost on a guaranteed-closed port (port 1 is almost never open)
  # This avoids the macOS nc issue where non-routable IPs ignore -w timeout
  local start_time
  start_time=$(/bin/date +%s)

  run probe_ssh_server "127.0.0.1" "1"

  local end_time
  end_time=$(/bin/date +%s)
  local elapsed=$(( end_time - start_time ))

  # If SSH is running locally, this succeeds — either way, it should be fast
  # The key assertion: completes within 3 seconds regardless of outcome
  [[ "$elapsed" -lt 4 ]]
}

# ============================================================================
# get_configured_mcp_servers_with_status — probing integration
# ============================================================================

@test "get_configured_mcp_servers_with_status marks command-based servers" {
  local test_dir="$TEST_TMP_DIR/status_test"
  mkdir -p "$test_dir"

  cat > "$test_dir/.mcp.json" << 'MCPJSON'
{
  "mcpServers": {
    "npx-server": {
      "command": "npx",
      "args": ["-y", "@test/mcp"]
    }
  }
}
MCPJSON

  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/fake_claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  # Disable cache to force fresh probe
  export STATUSLINE_CACHE_LOADED="false"

  run get_configured_mcp_servers_with_status "$test_dir"

  assert_success
  # npx should be found on PATH in most dev environments
  # The server should have either "connected" (npx found) or "failed" (not found)
  [[ "$output" == *"npx-server:"* ]]
}

@test "get_configured_mcp_servers_with_status returns empty for no servers" {
  local test_dir="$TEST_TMP_DIR/empty_status"
  mkdir -p "$test_dir"

  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/fake_claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR"

  export STATUSLINE_CACHE_LOADED="false"

  run get_configured_mcp_servers_with_status "$test_dir"

  assert_success
  [[ -z "$output" ]]
}
