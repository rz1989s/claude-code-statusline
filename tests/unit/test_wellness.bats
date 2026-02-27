#!/usr/bin/env bats
# ==============================================================================
# Test: Wellness Mode - Break Reminders (Issue #219)
# ==============================================================================
# Tests the wellness module functions: session tracking, level calculation,
# display formatting, and component data collection/rendering.

# Load test helpers
load "../setup_suite"

setup() {
  common_setup
  STATUSLINE_TESTING="true"
  export STATUSLINE_TESTING
  # Prevent scanning real JSONL files
  export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
  mkdir -p "$CLAUDE_CONFIG_DIR/projects"

  # Source core module stubs for debug_log
  if [[ -f "$STATUSLINE_ROOT/lib/core.sh" ]]; then
    # Reset module guard so we can source
    export STATUSLINE_CORE_LOADED=""
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
  fi

  # Source the wellness module directly for unit testing
  export STATUSLINE_WELLNESS_LOADED=""
  source "$STATUSLINE_ROOT/lib/wellness.sh" 2>/dev/null || true
}

teardown() {
  common_teardown
}

# ==============================================================================
# get_wellness_level tests
# ==============================================================================

@test "get_wellness_level: 30 minutes returns normal" {
  run get_wellness_level 30
  assert_success
  assert_output "normal"
}

@test "get_wellness_level: 0 minutes returns normal" {
  run get_wellness_level 0
  assert_success
  assert_output "normal"
}

@test "get_wellness_level: 44 minutes returns normal (just under gentle)" {
  run get_wellness_level 44
  assert_success
  assert_output "normal"
}

@test "get_wellness_level: 45 minutes returns gentle (exact threshold)" {
  run get_wellness_level 45
  assert_success
  assert_output "gentle"
}

@test "get_wellness_level: 50 minutes returns gentle" {
  run get_wellness_level 50
  assert_success
  assert_output "gentle"
}

@test "get_wellness_level: 89 minutes returns gentle (just under warn)" {
  run get_wellness_level 89
  assert_success
  assert_output "gentle"
}

@test "get_wellness_level: 90 minutes returns warn (exact threshold)" {
  run get_wellness_level 90
  assert_success
  assert_output "warn"
}

@test "get_wellness_level: 100 minutes returns warn" {
  run get_wellness_level 100
  assert_success
  assert_output "warn"
}

@test "get_wellness_level: 119 minutes returns warn (just under urgent)" {
  run get_wellness_level 119
  assert_success
  assert_output "warn"
}

@test "get_wellness_level: 120 minutes returns urgent (exact threshold)" {
  run get_wellness_level 120
  assert_success
  assert_output "urgent"
}

@test "get_wellness_level: 130 minutes returns urgent" {
  run get_wellness_level 130
  assert_success
  assert_output "urgent"
}

@test "get_wellness_level: 300 minutes returns urgent" {
  run get_wellness_level 300
  assert_success
  assert_output "urgent"
}

@test "get_wellness_level: empty input defaults to normal" {
  run get_wellness_level ""
  assert_success
  assert_output "normal"
}

@test "get_wellness_level: respects custom CONFIG thresholds" {
  CONFIG_WELLNESS_GENTLE_MINUTES=30
  CONFIG_WELLNESS_WARN_MINUTES=60
  CONFIG_WELLNESS_URGENT_MINUTES=90
  export CONFIG_WELLNESS_GENTLE_MINUTES CONFIG_WELLNESS_WARN_MINUTES CONFIG_WELLNESS_URGENT_MINUTES

  run get_wellness_level 35
  assert_success
  assert_output "gentle"

  run get_wellness_level 65
  assert_success
  assert_output "warn"

  run get_wellness_level 95
  assert_success
  assert_output "urgent"
}

# ==============================================================================
# format_wellness_display tests
# ==============================================================================

@test "format_wellness_display: normal level shows only minutes" {
  run format_wellness_display 30 "normal"
  assert_success
  assert_output "30m"
}

@test "format_wellness_display: gentle level shows break soon" {
  run format_wellness_display 50 "gentle"
  assert_success
  assert_output "50m | Break soon"
}

@test "format_wellness_display: warn level shows take a break" {
  run format_wellness_display 100 "warn"
  assert_success
  assert_output "100m | Take a break"
}

@test "format_wellness_display: urgent level shows break overdue" {
  run format_wellness_display 130 "urgent"
  assert_success
  assert_output "130m | Break overdue!"
}

@test "format_wellness_display: 0 minutes normal" {
  run format_wellness_display 0 "normal"
  assert_success
  assert_output "0m"
}

@test "format_wellness_display: contains minutes in output" {
  run format_wellness_display 75 "gentle"
  assert_success
  assert_output --partial "75m"
  assert_output --partial "Break soon"
}

# ==============================================================================
# get_wellness_session_start tests
# ==============================================================================

@test "get_wellness_session_start: creates session file when none exists" {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
  local session_file="$cache_dir/wellness_session_start"

  # Ensure no existing session file
  rm -f "$session_file" 2>/dev/null || true

  run get_wellness_session_start
  assert_success

  # Should have created the file
  [[ -f "$session_file" ]]

  # Output should be a valid timestamp (numeric)
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "get_wellness_session_start: returns existing session timestamp" {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
  local session_file="$cache_dir/wellness_session_start"

  mkdir -p "$cache_dir"
  echo "1700000000" > "$session_file"

  run get_wellness_session_start
  assert_success
  assert_output "1700000000"
}

# ==============================================================================
# reset_wellness_session tests
# ==============================================================================

@test "reset_wellness_session: resets timer to current time" {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
  local session_file="$cache_dir/wellness_session_start"

  # Set an old timestamp
  mkdir -p "$cache_dir"
  echo "1600000000" > "$session_file"

  local before
  before=$(date +%s)

  reset_wellness_session

  local after
  after=$(date +%s)

  # Read the new value
  local new_value
  new_value=$(cat "$session_file")

  # The new timestamp should be between before and after
  [[ "$new_value" -ge "$before" ]]
  [[ "$new_value" -le "$after" ]]
}

@test "reset_wellness_session: creates cache directory if missing" {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"

  # Remove cache dir
  rm -rf "$cache_dir" 2>/dev/null || true

  reset_wellness_session

  # Directory and file should exist now
  [[ -d "$cache_dir" ]]
  [[ -f "$cache_dir/wellness_session_start" ]]
}

# ==============================================================================
# Function existence tests
# ==============================================================================

@test "collect_wellness_data function exists after sourcing component" {
  # Source component module
  export STATUSLINE_COMPONENT_WELLNESS_LOADED=""
  # Stub register_component and get_component_config if not available
  if ! type register_component &>/dev/null; then
    register_component() { return 0; }
    get_component_config() { echo "${3:-true}"; }
  fi
  source "$STATUSLINE_ROOT/lib/components/wellness.sh" 2>/dev/null || true

  run type collect_wellness_data
  assert_success
}

@test "render_wellness function exists after sourcing component" {
  export STATUSLINE_COMPONENT_WELLNESS_LOADED=""
  if ! type register_component &>/dev/null; then
    register_component() { return 0; }
    get_component_config() { echo "${3:-true}"; }
  fi
  source "$STATUSLINE_ROOT/lib/components/wellness.sh" 2>/dev/null || true

  run type render_wellness
  assert_success
}

@test "get_wellness_session_start function exists" {
  run type get_wellness_session_start
  assert_success
}

@test "get_wellness_level function exists" {
  run type get_wellness_level
  assert_success
}

@test "format_wellness_display function exists" {
  run type format_wellness_display
  assert_success
}

@test "reset_wellness_session function exists" {
  run type reset_wellness_session
  assert_success
}

# ==============================================================================
# Module guard tests
# ==============================================================================

@test "wellness module sets STATUSLINE_WELLNESS_LOADED" {
  [[ "$STATUSLINE_WELLNESS_LOADED" == "true" ]]
}

# ==============================================================================
# Integration-style tests
# ==============================================================================

@test "wellness module works end-to-end: session start -> level -> display" {
  # Reset session to now
  reset_wellness_session

  # Get session start
  local start
  start=$(get_wellness_session_start)
  [[ "$start" =~ ^[0-9]+$ ]]

  # At 0 minutes, level should be normal
  local level
  level=$(get_wellness_level 0)
  [[ "$level" == "normal" ]]

  # Format display for normal
  local display
  display=$(format_wellness_display 0 "$level")
  [[ "$display" == "0m" ]]
}
