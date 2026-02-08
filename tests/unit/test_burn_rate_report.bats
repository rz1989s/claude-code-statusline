#!/usr/bin/env bats
# ==============================================================================
# Test: --burn-rate cost/token velocity analysis
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
}

teardown() {
    common_teardown
}

# ==============================================================================
# Human-readable output tests
# ==============================================================================

@test "--burn-rate outputs Burn Rate Analysis header" {
    run "$STATUSLINE_SCRIPT" --burn-rate
    assert_success
    assert_output --partial "Burn Rate Analysis"
}

@test "--burn-rate shows period info" {
    run "$STATUSLINE_SCRIPT" --burn-rate
    assert_success
    assert_output --partial "Period:"
}

@test "--burn-rate shows total info" {
    run "$STATUSLINE_SCRIPT" --burn-rate
    assert_success
    assert_output --partial "Total:"
}

@test "--burn-rate shows rates or no-data message" {
    run "$STATUSLINE_SCRIPT" --burn-rate
    assert_success
    [[ "$output" == *"Current Rates:"* ]] || [[ "$output" == *"No active usage data"* ]]
}

@test "--burn-rate shows predictions or no-data message" {
    run "$STATUSLINE_SCRIPT" --burn-rate
    assert_success
    [[ "$output" == *"Predictions"* ]] || [[ "$output" == *"No active usage data"* ]]
}

@test "--burn-rate returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --burn-rate
    assert_success
}

# ==============================================================================
# JSON output tests
# ==============================================================================

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

@test "--burn-rate --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --burn-rate --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--burn-rate --json has report field" {
    run "$STATUSLINE_SCRIPT" --burn-rate --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local report
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "burn_rate" ]]
}

@test "--burn-rate --json has rates object" {
    run "$STATUSLINE_SCRIPT" --burn-rate --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.rates' >/dev/null
    echo "$json_output" | jq -e '.rates.cost_per_minute' >/dev/null
    echo "$json_output" | jq -e '.rates.cost_per_hour' >/dev/null
    echo "$json_output" | jq -e '.rates.tokens_per_minute' >/dev/null
}

@test "--burn-rate --json has predictions object" {
    run "$STATUSLINE_SCRIPT" --burn-rate --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.predictions' >/dev/null
    echo "$json_output" | jq -e '.predictions.five_hour_block_cost' >/dev/null
}

@test "--burn-rate --json has summary object" {
    run "$STATUSLINE_SCRIPT" --burn-rate --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.summary.total_cost_usd' >/dev/null
    echo "$json_output" | jq -e '.summary.total_tokens' >/dev/null
    echo "$json_output" | jq -e '.summary.elapsed_minutes' >/dev/null
}

@test "--burn-rate --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --burn-rate --json
    assert_success
}

# ==============================================================================
# Filter integration tests
# ==============================================================================

@test "--burn-rate works with --since" {
    run "$STATUSLINE_SCRIPT" --burn-rate --since 7d
    assert_success
    assert_output --partial "Burn Rate Analysis"
}

@test "--burn-rate works with --project" {
    run "$STATUSLINE_SCRIPT" --burn-rate --project nonexistent-project-$$
    assert_failure
    assert_output --partial "No project found"
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --burn-rate flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--burn-rate"
}
