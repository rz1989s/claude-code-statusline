#!/usr/bin/env bats
# ==============================================================================
# Test: Commit cost attribution (#215)
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

@test "--commits outputs Commit Attribution header" {
  run "$STATUSLINE_SCRIPT" --commits
  assert_success
  assert_output --partial "Commit Attribution"
}

@test "--commits returns exit code 0" {
  run "$STATUSLINE_SCRIPT" --commits
  assert_success
}

@test "--commits shows no-commits message when no data" {
  run "$STATUSLINE_SCRIPT" --commits
  assert_success
  [[ "$output" == *"no commits"* || "$output" == *"Commit"* ]]
}

# ==============================================================================
# JSON output tests
# ==============================================================================

@test "--commits --json outputs valid JSON" {
  run "$STATUSLINE_SCRIPT" --commits --json
  assert_success
  local json_output
  # Extract JSON array from output
  json_output=$(echo "$output" | grep -E '^\[' || echo "[]")
  echo "$json_output" | jq -e . >/dev/null 2>&1
}

@test "--commits --json returns array" {
  run "$STATUSLINE_SCRIPT" --commits --json
  assert_success
  local json_output
  json_output=$(echo "$output" | grep -E '^\[' || echo "[]")
  local type
  type=$(echo "$json_output" | jq -r 'type' 2>/dev/null)
  [[ "$type" == "array" ]]
}

# ==============================================================================
# CSV output tests
# ==============================================================================

@test "--commits --csv outputs CSV header" {
  # --csv flag requires Issue #218 (CSV export) to be implemented first
  skip "CSV export not yet implemented (#218)"
}

# ==============================================================================
# Help text test
# ==============================================================================

@test "--help mentions --commits flag" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--commits"
}
