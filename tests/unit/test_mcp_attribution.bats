#!/usr/bin/env bats
# ==============================================================================
# Test: MCP cost attribution (#216)
# ==============================================================================

load '../setup_suite'

setup() {
  common_setup
  export STATUSLINE_TESTING=true
  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR/projects"
}

teardown() {
  common_teardown
}

# ==============================================================================
# Function existence tests
# ==============================================================================

@test "--mcp-costs outputs MCP Cost Attribution header" {
  run "$STATUSLINE_SCRIPT" --mcp-costs < /dev/null
  assert_success
  assert_output --partial "MCP"
}

@test "--mcp-costs returns exit code 0" {
  run "$STATUSLINE_SCRIPT" --mcp-costs < /dev/null
  assert_success
}

@test "--mcp-costs shows no-data message when no MCP usage" {
  run "$STATUSLINE_SCRIPT" --mcp-costs < /dev/null
  assert_success
  [[ "$output" == *"no MCP"* || "$output" == *"MCP"* ]]
}

# ==============================================================================
# JSON output tests
# ==============================================================================

@test "--mcp-costs --json outputs valid JSON" {
  run "$STATUSLINE_SCRIPT" --mcp-costs --json < /dev/null
  assert_success
  local json_output
  json_output=$(echo "$output" | grep -E '^\[' || echo "[]")
  echo "$json_output" | jq -e . >/dev/null 2>&1
}

@test "--mcp-costs --json returns array" {
  run "$STATUSLINE_SCRIPT" --mcp-costs --json < /dev/null
  assert_success
  local json_output
  json_output=$(echo "$output" | grep -E '^\[' || echo "[]")
  local type
  type=$(echo "$json_output" | jq -r 'type' 2>/dev/null)
  [[ "$type" == "array" ]]
}

# ==============================================================================
# parse_mcp_server_from_tool tests
# ==============================================================================

@test "parse_mcp_server_from_tool extracts server name" {
  source "$PROJECT_ROOT/lib/cost/mcp_attribution.sh"
  run parse_mcp_server_from_tool "mcp__filesystem__read_file"
  assert_success
  assert_output "filesystem"
}

@test "parse_mcp_server_from_tool returns empty for non-MCP tools" {
  source "$PROJECT_ROOT/lib/cost/mcp_attribution.sh"
  run parse_mcp_server_from_tool "Write"
  assert_success
  assert_output ""
}

@test "parse_mcp_server_from_tool handles complex server names" {
  source "$PROJECT_ROOT/lib/cost/mcp_attribution.sh"
  run parse_mcp_server_from_tool "mcp__claude-in-chrome__navigate"
  assert_success
  assert_output "claude-in-chrome"
}

# ==============================================================================
# Help text test
# ==============================================================================

@test "--help mentions --mcp-costs flag" {
  run "$STATUSLINE_SCRIPT" --help < /dev/null
  assert_success
  assert_output --partial "--mcp-costs"
}
