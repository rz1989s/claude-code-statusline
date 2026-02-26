#!/usr/bin/env bats
# ==============================================================================
# Test: Historical trends with ASCII charts (#217)
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
# parse_period_arg tests
# ==============================================================================

@test "parse_period_arg: 30d returns 30" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "30d"
  assert_success
  assert_output "30"
}

@test "parse_period_arg: 7d returns 7" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "7d"
  assert_success
  assert_output "7"
}

@test "parse_period_arg: 4w returns 28" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "4w"
  assert_success
  assert_output "28"
}

@test "parse_period_arg: 2w returns 14" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "2w"
  assert_success
  assert_output "14"
}

@test "parse_period_arg: 3m returns 90" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "3m"
  assert_success
  assert_output "90"
}

@test "parse_period_arg: 1m returns 30" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "1m"
  assert_success
  assert_output "30"
}

@test "parse_period_arg: plain number 14 returns 14" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "14"
  assert_success
  assert_output "14"
}

@test "parse_period_arg: empty string returns error" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg ""
  assert_failure
}

@test "parse_period_arg: invalid format returns error" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "abc"
  assert_failure
}

@test "parse_period_arg: 0d returns error" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run parse_period_arg "0d"
  assert_failure
}

# ==============================================================================
# calculate_trend_percentage tests
# ==============================================================================

@test "calculate_trend_percentage: 10 vs 8 outputs +25%" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run calculate_trend_percentage "10" "8"
  assert_success
  [[ "$output" == *"25"* ]]
}

@test "calculate_trend_percentage: 8 vs 10 outputs -20%" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run calculate_trend_percentage "8" "10"
  assert_success
  [[ "$output" == *"-20"* ]]
}

@test "calculate_trend_percentage: equal values outputs 0%" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run calculate_trend_percentage "5" "5"
  assert_success
  [[ "$output" == *"0%"* ]]
}

@test "calculate_trend_percentage: previous zero outputs +inf%" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run calculate_trend_percentage "10" "0"
  assert_success
  [[ "$output" == *"inf"* ]]
}

@test "calculate_trend_percentage: both zero outputs 0%" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run calculate_trend_percentage "0" "0"
  assert_success
  assert_output "0%"
}

# ==============================================================================
# render_vertical_bar_chart tests
# ==============================================================================

@test "render_vertical_bar_chart: contains title in output" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run render_vertical_bar_chart "1,3,5,2,4" "A,B,C,D,E" 5 "Test"
  assert_success
  assert_output --partial "Test"
}

@test "render_vertical_bar_chart: contains bar characters" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run render_vertical_bar_chart "1,3,5,2,4" "A,B,C,D,E" 5 "Chart"
  assert_success
  # Should contain at least one Unicode block character
  [[ "$output" == *"█"* || "$output" == *"▇"* || "$output" == *"▆"* || "$output" == *"▅"* || "$output" == *"▄"* || "$output" == *"▃"* || "$output" == *"▂"* || "$output" == *"▁"* ]]
}

@test "render_vertical_bar_chart: shows summary with Avg/Peak/Total" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run render_vertical_bar_chart "1,3,5,2,4" "A,B,C,D,E" 5 "Test"
  assert_success
  assert_output --partial "Avg:"
  assert_output --partial "Peak:"
  assert_output --partial "Total:"
}

@test "render_vertical_bar_chart: handles empty data gracefully" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run render_vertical_bar_chart "" "A,B" 5 "Empty"
  assert_success
}

@test "render_vertical_bar_chart: handles single value" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run render_vertical_bar_chart "5" "Mon" 5 "Single"
  assert_success
  assert_output --partial "Single"
}

@test "render_vertical_bar_chart: handles all-zero values" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  run render_vertical_bar_chart "0,0,0" "A,B,C" 3 "Zeros"
  assert_success
  assert_output --partial "Zeros"
}

# ==============================================================================
# CLI flag tests
# ==============================================================================

@test "--trends flag is accepted by CLI" {
  run "$STATUSLINE_SCRIPT" --trends
  assert_success
}

@test "--trends returns exit code 0" {
  run "$STATUSLINE_SCRIPT" --trends
  assert_success
}

@test "--trends shows trends header" {
  run "$STATUSLINE_SCRIPT" --trends
  assert_success
  assert_output --partial "Trend"
}

@test "--trends --period 7d is accepted" {
  run "$STATUSLINE_SCRIPT" --trends --period 7d
  assert_success
}

@test "--trends --json outputs valid JSON" {
  run "$STATUSLINE_SCRIPT" --trends --json
  assert_success
  # Output should contain JSON structure
  [[ "$output" == *"period"* ]]
  [[ "$output" == *"data"* ]]
}

@test "--trends --json --compact outputs single line" {
  run "$STATUSLINE_SCRIPT" --trends --json --compact
  assert_success
  # Compact JSON should be parseable
  local json_line
  json_line=$(echo "$output" | grep -E '^\{' | head -1)
  [[ -n "$json_line" ]]
}

@test "--period without argument shows error" {
  run "$STATUSLINE_SCRIPT" --trends --period
  assert_failure
  assert_output --partial "Error"
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --trends flag" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--trends"
}

@test "--help mentions --period flag" {
  run "$STATUSLINE_SCRIPT" --help
  assert_success
  assert_output --partial "--period"
}

# ==============================================================================
# Module loading tests
# ==============================================================================

@test "charts module sets loaded guard" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  [[ "$STATUSLINE_CLI_CHARTS_LOADED" == "true" ]]
}

@test "charts module exports parse_period_arg" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  declare -f parse_period_arg >/dev/null
}

@test "charts module exports calculate_trend_percentage" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  declare -f calculate_trend_percentage >/dev/null
}

@test "charts module exports render_vertical_bar_chart" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  declare -f render_vertical_bar_chart >/dev/null
}

@test "charts module exports show_trends_report" {
  source "$PROJECT_ROOT/lib/cli/charts.sh"
  declare -f show_trends_report >/dev/null
}
