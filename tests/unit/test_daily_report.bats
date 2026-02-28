#!/usr/bin/env bats
# ==============================================================================
# Test: --daily report functionality (Issue #200)
# ==============================================================================
# Tests the daily cost report with hourly breakdown in both
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

@test "--daily outputs Daily Cost Report header" {
    run "$STATUSLINE_SCRIPT" --daily < /dev/null
    assert_success
    assert_output --partial "Daily Cost Report"
}

@test "--daily contains Hour column or no-data message" {
    run "$STATUSLINE_SCRIPT" --daily < /dev/null
    assert_success
    # With data: shows Hour column; without data: shows no-data message
    [[ "$output" == *"Hour"* || "$output" == *"No usage data"* ]]
}

@test "--daily contains today's date" {
    run "$STATUSLINE_SCRIPT" --daily < /dev/null
    assert_success
    local today
    today=$(date +%Y-%m-%d)
    assert_output --partial "$today"
}

@test "--daily returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --daily < /dev/null
    assert_success
}

# ==============================================================================
# JSON output tests
# ==============================================================================

@test "--daily --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --daily --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--daily --json has report field set to daily" {
    run "$STATUSLINE_SCRIPT" --daily --json < /dev/null
    assert_success
    local json_output report
    json_output=$(_extract_json "$output")
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "daily" ]]
}

@test "--daily --json has hours array" {
    run "$STATUSLINE_SCRIPT" --daily --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.hours' >/dev/null
    # hours should be an array
    local hours_type
    hours_type=$(echo "$json_output" | jq -r '.hours | type')
    [[ "$hours_type" == "array" ]]
}

@test "--daily --json has models array" {
    run "$STATUSLINE_SCRIPT" --daily --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.models' >/dev/null
    local models_type
    models_type=$(echo "$json_output" | jq -r '.models | type')
    [[ "$models_type" == "array" ]]
}

@test "--daily --json has summary object" {
    run "$STATUSLINE_SCRIPT" --daily --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.summary' >/dev/null
    echo "$json_output" | jq -e '.summary.total_cost_usd' >/dev/null
    echo "$json_output" | jq -e '.summary.total_sessions' >/dev/null
}

@test "--daily --json --compact outputs single-line JSON" {
    run "$STATUSLINE_SCRIPT" --daily --json --compact < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    local line_count
    line_count=$(echo "$json_output" | wc -l | tr -d ' ')
    [[ "$line_count" -eq 1 ]]
}

@test "--daily --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --daily --json < /dev/null
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --daily flag" {
    run "$STATUSLINE_SCRIPT" --help < /dev/null
    assert_success
    assert_output --partial "--daily"
}
