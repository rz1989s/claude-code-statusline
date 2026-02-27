#!/usr/bin/env bats
# ==============================================================================
# Test: Focus Session Tracking (Issue #220)
# ==============================================================================
# Tests the --focus flag functionality including start, stop, status, and history.

load "../setup_suite"

setup() {
  common_setup
  STATUSLINE_TESTING="true"
  export STATUSLINE_TESTING
  # Prevent scanning real JSONL files
  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR/projects"
  # Isolate cache to test temp dir
  export XDG_CACHE_HOME="$TEST_TMP_DIR/cache"
  mkdir -p "$XDG_CACHE_HOME/claude-code-statusline"
}

teardown() {
  # Clean up any active focus session files
  rm -f "$XDG_CACHE_HOME/claude-code-statusline/focus_active.json" 2>/dev/null || true
  rm -f "$XDG_CACHE_HOME/claude-code-statusline/focus_history.json" 2>/dev/null || true
  common_teardown
}

# ==============================================================================
# Direct function tests (source lib/focus.sh)
# ==============================================================================

@test "focus_start creates session file" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  run focus_start
  assert_success
  assert_output --partial "Focus session started"
  [[ -f "$FOCUS_SESSION_FILE" ]]
}

@test "focus_start outputs default duration" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  run focus_start
  assert_success
  assert_output --partial "50m target"
}

@test "focus_start with custom duration" {
  export CONFIG_FOCUS_DEFAULT_DURATION=25
  source "$STATUSLINE_ROOT/lib/focus.sh"
  run focus_start
  assert_success
  assert_output --partial "25m target"
  unset CONFIG_FOCUS_DEFAULT_DURATION
}

@test "focus_start when already active returns error" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  run focus_start
  assert_failure
  assert_output --partial "already active"
}

@test "focus_stop ends session and shows summary" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  run focus_stop
  assert_success
  assert_output --partial "Focus Session Complete"
  assert_output --partial "Duration:"
}

@test "focus_stop removes session file" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  focus_stop >/dev/null 2>&1
  [[ ! -f "$FOCUS_SESSION_FILE" ]]
}

@test "focus_stop without active session returns error" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  run focus_stop
  assert_failure
  assert_output --partial "No active focus session"
}

@test "focus_stop saves to history file" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  focus_stop >/dev/null 2>&1
  [[ -f "$FOCUS_HISTORY_FILE" ]]
  # Verify it's valid JSON
  jq -e '.' "$FOCUS_HISTORY_FILE" >/dev/null
}

@test "focus_status shows active session info" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  run focus_status
  assert_success
  assert_output --partial "FOCUS Session Active"
  assert_output --partial "Elapsed:"
  assert_output --partial "Remaining:"
}

@test "focus_status shows no session when inactive" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  run focus_status
  assert_success
  assert_output --partial "No active focus session"
}

@test "focus_history shows empty message when no history" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  run focus_history
  assert_success
  assert_output --partial "No focus session history found"
}

@test "focus_history json outputs empty array when no history" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  run focus_history "json"
  assert_success
  assert_output "[]"
}

@test "focus_history json outputs valid JSON after session" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  focus_stop >/dev/null 2>&1
  run focus_history "json"
  assert_success
  echo "$output" | jq -e '.' >/dev/null
  # Should have at least one entry
  local count
  count=$(echo "$output" | jq 'length')
  [[ "$count" -ge 1 ]]
}

@test "focus_history shows table when history exists" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  focus_stop >/dev/null 2>&1
  run focus_history
  assert_success
  assert_output --partial "Focus Session History"
  assert_output --partial "Date"
  assert_output --partial "Duration"
  assert_output --partial "Repo"
}

# ==============================================================================
# CLI flag tests
# ==============================================================================

@test "--focus without action shows error" {
  run "$STATUSLINE_SCRIPT" --focus
  assert_failure
  assert_output --partial "requires"
}

@test "--focus with invalid action shows error" {
  run "$STATUSLINE_SCRIPT" --focus invalid
  assert_failure
  assert_output --partial "unknown focus action"
}

@test "--focus start creates session via CLI" {
  run "$STATUSLINE_SCRIPT" --focus start
  assert_success
  assert_output --partial "Focus session started"
  # Clean up
  rm -f "$XDG_CACHE_HOME/claude-code-statusline/focus_active.json" 2>/dev/null || true
}

@test "--focus status works via CLI" {
  run "$STATUSLINE_SCRIPT" --focus status
  assert_success
  assert_output --partial "No active focus session"
}

@test "--focus history works via CLI" {
  run "$STATUSLINE_SCRIPT" --focus history
  assert_success
  assert_output --partial "No focus session history"
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --focus flag" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--focus"
}

@test "--help shows focus start action" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--focus start"
}

@test "--help shows focus stop action" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--focus stop"
}

@test "--help shows focus status action" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--focus status"
}

@test "--help shows focus history action" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--focus history"
}

# ==============================================================================
# Session file integrity tests
# ==============================================================================

@test "focus session file contains valid JSON with required fields" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  jq -e '.start_time' "$FOCUS_SESSION_FILE" >/dev/null
  jq -e '.duration_minutes' "$FOCUS_SESSION_FILE" >/dev/null
  jq -e '.repo' "$FOCUS_SESSION_FILE" >/dev/null
}

@test "focus history entry contains end_time and elapsed_minutes" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  focus_start >/dev/null 2>&1
  focus_stop >/dev/null 2>&1
  jq -e '.[0].end_time' "$FOCUS_HISTORY_FILE" >/dev/null
  jq -e '.[0].elapsed_minutes' "$FOCUS_HISTORY_FILE" >/dev/null
  jq -e '.[0].start_time' "$FOCUS_HISTORY_FILE" >/dev/null
  jq -e '.[0].repo' "$FOCUS_HISTORY_FILE" >/dev/null
}

@test "multiple sessions accumulate in history" {
  source "$STATUSLINE_ROOT/lib/focus.sh"
  # Session 1
  focus_start >/dev/null 2>&1
  focus_stop >/dev/null 2>&1
  # Session 2
  focus_start >/dev/null 2>&1
  focus_stop >/dev/null 2>&1
  local count
  count=$(jq 'length' "$FOCUS_HISTORY_FILE")
  [[ "$count" -eq 2 ]]
}
