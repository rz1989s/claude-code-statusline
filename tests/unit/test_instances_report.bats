#!/usr/bin/env bats
# ==============================================================================
# Test: --instances multi-project cost summary
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

@test "--instances outputs Multi-Project Cost Summary header" {
    run "$STATUSLINE_SCRIPT" --instances
    assert_success
    assert_output --partial "Multi-Project Cost Summary"
}

@test "--instances shows period info" {
    run "$STATUSLINE_SCRIPT" --instances
    assert_success
    assert_output --partial "Period:"
}

@test "--instances shows total cost" {
    run "$STATUSLINE_SCRIPT" --instances
    assert_success
    assert_output --partial "Total:"
}

@test "--instances shows project count" {
    run "$STATUSLINE_SCRIPT" --instances
    assert_success
    assert_output --partial "projects"
}

@test "--instances shows TOTAL row or no-data message" {
    run "$STATUSLINE_SCRIPT" --instances
    assert_success
    # CI may have no JSONL data — accept either output
    [[ "$output" == *"TOTAL"* ]] || [[ "$output" == *"No project data"* ]]
}

@test "--instances returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --instances
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

@test "--instances --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --instances --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--instances --json has report field" {
    run "$STATUSLINE_SCRIPT" --instances --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local report
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "instances" ]]
}

@test "--instances --json has projects array" {
    run "$STATUSLINE_SCRIPT" --instances --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.projects' >/dev/null
    echo "$json_output" | jq -e '.projects | type == "array"' >/dev/null
}

@test "--instances --json has summary with project_count" {
    run "$STATUSLINE_SCRIPT" --instances --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.summary.project_count' >/dev/null
}

@test "--instances --json project entries have cost fields" {
    run "$STATUSLINE_SCRIPT" --instances --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local count
    count=$(echo "$json_output" | jq '.projects | length')
    if [[ "$count" -gt 0 ]]; then
        echo "$json_output" | jq -e '.projects[0].cost_usd' >/dev/null
        echo "$json_output" | jq -e '.projects[0].sessions' >/dev/null
        echo "$json_output" | jq -e '.projects[0].percent_of_total' >/dev/null
    fi
}

@test "--instances --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --instances --json
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --instances flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--instances"
}
