#!/usr/bin/env bats

# Unit tests for MCP plugin detection and name truncation (lib/mcp.sh)
# Tests get_enabled_mcp_plugins, truncate_mcp_name

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
# get_enabled_mcp_plugins — plugin filtering
# ============================================================================

@test "get_enabled_mcp_plugins returns non-LSP plugins" {
  local test_settings_dir="$TEST_TMP_DIR/claude_plugins"
  mkdir -p "$test_settings_dir"

  cat > "$test_settings_dir/settings.json" << 'SETTINGS'
{
  "enabledPlugins": {
    "context7@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "ralph-wiggum@claude-plugins-official": true
  }
}
SETTINGS

  CLAUDE_CONFIG_DIR="$test_settings_dir" run get_enabled_mcp_plugins

  assert_success
  assert_output --partial "context7"
  assert_output --partial "superpowers"
  assert_output --partial "ralph-wiggum"
  refute_output --partial "typescript-lsp"
}

@test "get_enabled_mcp_plugins filters all LSP servers" {
  local test_settings_dir="$TEST_TMP_DIR/claude_lsp_only"
  mkdir -p "$test_settings_dir"

  cat > "$test_settings_dir/settings.json" << 'SETTINGS'
{
  "enabledPlugins": {
    "rust-analyzer-lsp@claude-plugins-official": true,
    "pyright-lsp@claude-plugins-official": true,
    "gopls-lsp@claude-plugins-official": true
  }
}
SETTINGS

  CLAUDE_CONFIG_DIR="$test_settings_dir" run get_enabled_mcp_plugins

  assert_success
  [[ -z "$output" ]]
}

@test "get_enabled_mcp_plugins returns empty for no plugins" {
  local test_settings_dir="$TEST_TMP_DIR/claude_no_plugins"
  mkdir -p "$test_settings_dir"

  cat > "$test_settings_dir/settings.json" << 'SETTINGS'
{
  "enabledPlugins": {}
}
SETTINGS

  CLAUDE_CONFIG_DIR="$test_settings_dir" run get_enabled_mcp_plugins

  assert_success
  [[ -z "$output" ]]
}

@test "get_enabled_mcp_plugins skips disabled plugins" {
  local test_settings_dir="$TEST_TMP_DIR/claude_disabled"
  mkdir -p "$test_settings_dir"

  cat > "$test_settings_dir/settings.json" << 'SETTINGS'
{
  "enabledPlugins": {
    "context7@claude-plugins-official": true,
    "superpowers@claude-plugins-official": false,
    "ralph-wiggum@claude-plugins-official": true
  }
}
SETTINGS

  CLAUDE_CONFIG_DIR="$test_settings_dir" run get_enabled_mcp_plugins

  assert_success
  assert_output --partial "context7"
  assert_output --partial "ralph-wiggum"
  refute_output --partial "superpowers"
}

@test "get_enabled_mcp_plugins returns empty when settings.json missing" {
  local test_settings_dir="$TEST_TMP_DIR/claude_missing"
  mkdir -p "$test_settings_dir"
  # No settings.json created

  CLAUDE_CONFIG_DIR="$test_settings_dir" run get_enabled_mcp_plugins

  assert_success
  [[ -z "$output" ]]
}

# ============================================================================
# truncate_mcp_name — name formatting
# ============================================================================

@test "truncate_mcp_name shortens long names" {
  run truncate_mcp_name "very-long-plugin-name-here" 15

  assert_success
  assert_output "very-long-plugi"
}

@test "truncate_mcp_name preserves short names" {
  run truncate_mcp_name "context7" 15

  assert_success
  assert_output "context7"
}

@test "truncate_mcp_name uses default max length of 15" {
  run truncate_mcp_name "short"

  assert_success
  assert_output "short"
}

@test "truncate_mcp_name truncates at exact boundary" {
  run truncate_mcp_name "exactly15chars!" 15

  assert_success
  assert_output "exactly15chars!"
}
