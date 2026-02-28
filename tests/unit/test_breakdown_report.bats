#!/usr/bin/env bats
# ==============================================================================
# Test: --breakdown model cost analysis
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    # Prevent scanning real JSONL files (2500+ files = 23s per invocation)
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects"
}

teardown() {
    common_teardown
}

# ==============================================================================
# Human-readable output tests
# ==============================================================================

@test "--breakdown outputs Model Cost Breakdown header" {
    run "$STATUSLINE_SCRIPT" --breakdown < /dev/null
    assert_success
    assert_output --partial "Model Cost Breakdown"
}

@test "--breakdown shows period info" {
    run "$STATUSLINE_SCRIPT" --breakdown < /dev/null
    assert_success
    assert_output --partial "Period:"
}

@test "--breakdown shows total cost" {
    run "$STATUSLINE_SCRIPT" --breakdown < /dev/null
    assert_success
    assert_output --partial "Total:"
}

@test "--breakdown shows cost efficiency section or no-data message" {
    run "$STATUSLINE_SCRIPT" --breakdown < /dev/null
    assert_success
    # CI may have no JSONL data — accept either output
    [[ "$output" == *"Cost Efficiency:"* ]] || [[ "$output" == *"No usage data"* ]]
}

@test "--breakdown shows TOTAL row or no-data message" {
    run "$STATUSLINE_SCRIPT" --breakdown < /dev/null
    assert_success
    # CI may have no JSONL data — accept either output
    [[ "$output" == *"TOTAL"* ]] || [[ "$output" == *"No usage data"* ]]
}

@test "--breakdown returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --breakdown < /dev/null
    assert_success
}

# ==============================================================================
# JSON output tests
# ==============================================================================

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

@test "--breakdown --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --breakdown --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--breakdown --json has report field" {
    run "$STATUSLINE_SCRIPT" --breakdown --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local report
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "breakdown" ]]
}

@test "--breakdown --json has models array" {
    run "$STATUSLINE_SCRIPT" --breakdown --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.models' >/dev/null
    echo "$json_output" | jq -e '.models | type == "array"' >/dev/null
}

@test "--breakdown --json has summary with total_cost_usd" {
    run "$STATUSLINE_SCRIPT" --breakdown --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.summary.total_cost_usd' >/dev/null
}

@test "--breakdown --json model entries have token fields" {
    run "$STATUSLINE_SCRIPT" --breakdown --json < /dev/null
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local model_count
    model_count=$(echo "$json_output" | jq '.models | length')
    if [[ "$model_count" -gt 0 ]]; then
        echo "$json_output" | jq -e '.models[0].input_tokens' >/dev/null
        echo "$json_output" | jq -e '.models[0].output_tokens' >/dev/null
        echo "$json_output" | jq -e '.models[0].cost_per_1k_tokens' >/dev/null
    fi
}

@test "--breakdown --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --breakdown --json < /dev/null
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --breakdown flag" {
    run "$STATUSLINE_SCRIPT" --help < /dev/null
    assert_success
    assert_output --partial "--breakdown"
}
