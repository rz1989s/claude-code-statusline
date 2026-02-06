#!/usr/bin/env bats
# ==============================================================================
# Test: --monthly report functionality (Issue #201)
# ==============================================================================
# Tests the monthly cost report with 30-day daily breakdown in both
# human-readable and JSON output formats.

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

@test "--monthly outputs Monthly Cost Report header" {
    run "$STATUSLINE_SCRIPT" --monthly
    assert_success
    assert_output --partial "Monthly Cost Report"
}

@test "--monthly contains Stats section or no-data message" {
    run "$STATUSLINE_SCRIPT" --monthly
    assert_success
    [[ "$output" == *"Stats:"* || "$output" == *"No usage data"* ]]
}

@test "--monthly contains Date column or no-data message" {
    run "$STATUSLINE_SCRIPT" --monthly
    assert_success
    [[ "$output" == *"Date"* || "$output" == *"No usage data"* ]]
}

@test "--monthly returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --monthly
    assert_success
}

# ==============================================================================
# JSON output tests
# ==============================================================================

@test "--monthly --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --monthly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--monthly --json has report field set to monthly" {
    run "$STATUSLINE_SCRIPT" --monthly --json
    assert_success
    local json_output report
    json_output=$(_extract_json "$output")
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "monthly" ]]
}

@test "--monthly --json has days array with at most 30 elements" {
    run "$STATUSLINE_SCRIPT" --monthly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.days' >/dev/null
    local days_count
    days_count=$(echo "$json_output" | jq -r '.days | length')
    [[ "$days_count" -le 30 ]]
}

@test "--monthly --json has summary with active_days" {
    run "$STATUSLINE_SCRIPT" --monthly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.summary' >/dev/null
    echo "$json_output" | jq -e '.summary.active_days' >/dev/null
    echo "$json_output" | jq -e '.summary.daily_average_usd' >/dev/null
}

@test "--monthly --json has period object with 30 days" {
    run "$STATUSLINE_SCRIPT" --monthly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local period_days
    period_days=$(echo "$json_output" | jq -r '.period.days')
    [[ "$period_days" == "30" ]]
}

@test "--monthly --json has models array" {
    run "$STATUSLINE_SCRIPT" --monthly --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.models' >/dev/null
    local models_type
    models_type=$(echo "$json_output" | jq -r '.models | type')
    [[ "$models_type" == "array" ]]
}

@test "--monthly --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --monthly --json
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --monthly flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--monthly"
}
