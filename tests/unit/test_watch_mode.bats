#!/usr/bin/env bats
# ==============================================================================
# Test: --watch live monitoring mode (#208)
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
# CLI flag acceptance tests
# ==============================================================================

@test "--watch flag accepted by CLI (exits 0 in test mode)" {
  run "$STATUSLINE_SCRIPT" --watch < /dev/null
  assert_success
}

@test "--watch with --refresh flag accepted" {
  run "$STATUSLINE_SCRIPT" --watch --refresh 5 < /dev/null
  assert_success
}

@test "--watch with --refresh=N syntax accepted" {
  run "$STATUSLINE_SCRIPT" --watch --refresh=5 < /dev/null
  assert_success
}

@test "--refresh without value shows error" {
  run "$STATUSLINE_SCRIPT" --refresh < /dev/null
  assert_failure
  assert_output --partial "Error"
}

# ==============================================================================
# validate_refresh_interval tests
# ==============================================================================

@test "validate_refresh_interval 10 outputs 10" {
  source "$PROJECT_ROOT/lib/cli/watch.sh"
  run validate_refresh_interval "10"
  assert_success
  assert_output "10"
}

@test "validate_refresh_interval 5 outputs 5" {
  source "$PROJECT_ROOT/lib/cli/watch.sh"
  run validate_refresh_interval "5"
  assert_success
  assert_output "5"
}

@test "validate_refresh_interval 0.1 clamps to 0.5" {
  source "$PROJECT_ROOT/lib/cli/watch.sh"
  run validate_refresh_interval "0.1"
  assert_success
  assert_output "0.5"
}

@test "validate_refresh_interval 0 clamps to 0.5" {
  source "$PROJECT_ROOT/lib/cli/watch.sh"
  run validate_refresh_interval "0"
  assert_success
  assert_output "0.5"
}

@test "validate_refresh_interval 500 clamps to 300" {
  source "$PROJECT_ROOT/lib/cli/watch.sh"
  run validate_refresh_interval "500"
  assert_success
  assert_output "300"
}

@test "validate_refresh_interval abc exits with failure" {
  source "$PROJECT_ROOT/lib/cli/watch.sh"
  run validate_refresh_interval "abc"
  assert_failure
}

@test "validate_refresh_interval empty exits with failure" {
  source "$PROJECT_ROOT/lib/cli/watch.sh"
  run validate_refresh_interval ""
  assert_failure
}

# ==============================================================================
# Dashboard render tests
# ==============================================================================

@test "--watch outputs Live Monitor header" {
  run "$STATUSLINE_SCRIPT" --watch < /dev/null
  assert_success
  assert_output --partial "Live Monitor"
}

@test "--watch outputs refresh interval in header" {
  run "$STATUSLINE_SCRIPT" --watch --refresh 5 < /dev/null
  assert_success
  assert_output --partial "refresh: 5s"
}

@test "--watch outputs Ctrl+C exit hint" {
  run "$STATUSLINE_SCRIPT" --watch < /dev/null
  assert_success
  assert_output --partial "Ctrl+C"
}

@test "--watch outputs timestamp in header" {
  run "$STATUSLINE_SCRIPT" --watch < /dev/null
  assert_success
  # Match date format YYYY-MM-DD
  [[ "$output" == *20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]* ]]
}

# ==============================================================================
# Help text test
# ==============================================================================

@test "--help mentions --watch flag" {
  run "$STATUSLINE_SCRIPT" --help < /dev/null
  assert_success
  assert_output --partial "--watch"
}

@test "--help mentions --refresh flag" {
  run "$STATUSLINE_SCRIPT" --help < /dev/null
  assert_success
  assert_output --partial "--refresh"
}
