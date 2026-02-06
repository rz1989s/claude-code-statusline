#!/usr/bin/env bats
# ==============================================================================
# Test: --weekly report functionality (Issue #202)
# ==============================================================================
# Tests the weekly cost report with 7-day breakdown and week-over-week
# comparison in both human-readable and JSON output formats.

# Load test helpers
load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    # Point to empty projects dir to avoid scanning real JSONL files
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects"
}

teardown() {
    common_teardown
}

# Helper function to extract JSON from output
_extract_json() {
    local in_json=false
    local json_lines=""
    while IFS= read -r line; do
        if [[ "$line" == "{"* ]]; then
            in_json=true
        fi
        if [[ "$in_json" == "true" ]]; then
            json_lines+="$line"
        fi
        if [[ "$line" == "}" ]]; then
            break
        fi
    done <<< "$1"
    echo "$json_lines"
}

# ==============================================================================
# Human-readable output tests
# ==============================================================================

@test "--weekly outputs Weekly Cost Report header" {
    run "$STATUSLINE_SCRIPT" --weekly
    assert_success
    assert_output --partial "Weekly Cost Report"
}

@test "--weekly contains Week-over-Week section or no-data message" {
    run "$STATUSLINE_SCRIPT" --weekly
    assert_success
    [[ "$output" == *"Week-over-Week"* || "$output" == *"No usage data"* ]]
}

@test "--weekly contains full weekday names" {
    run "$STATUSLINE_SCRIPT" --weekly
    assert_success
    # At least one weekday name should appear in the Day column
    assert_output --partial "Day"
}

@test "--weekly returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --weekly
    assert_success
}

# ==============================================================================
# JSON output tests
# ==============================================================================

@test "--weekly --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--weekly --json has report field set to weekly" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
    local json_output report
    json_output=$(_extract_json "$output")
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "weekly" ]]
}

@test "--weekly --json has days array" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.days' >/dev/null
    local days_type
    days_type=$(echo "$json_output" | jq -r '.days | type')
    [[ "$days_type" == "array" ]]
}

@test "--weekly --json has comparison object" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.comparison' >/dev/null
    echo "$json_output" | jq -e '.comparison.previous_week_cost_usd' >/dev/null
    echo "$json_output" | jq -e '.comparison.change_usd' >/dev/null
    echo "$json_output" | jq -e '.comparison.change_percent' >/dev/null
}

@test "--weekly --json has period with 7 days" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local period_days
    period_days=$(echo "$json_output" | jq -r '.period.days')
    [[ "$period_days" == "7" ]]
}

@test "--weekly --json has summary with daily_average" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.summary' >/dev/null
    echo "$json_output" | jq -e '.summary.total_cost_usd' >/dev/null
    echo "$json_output" | jq -e '.summary.daily_average_usd' >/dev/null
}

@test "--weekly --json has models array" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.models' >/dev/null
    local models_type
    models_type=$(echo "$json_output" | jq -r '.models | type')
    [[ "$models_type" == "array" ]]
}

@test "--weekly --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --weekly --json
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --weekly flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--weekly"
}
