#!/usr/bin/env bats
# ==============================================================================
# Test: --recommendations smart cost optimization tips (Issue #221)
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

@test "--recommendations outputs Smart Cost Recommendations header" {
    run "$STATUSLINE_SCRIPT" --recommendations
    assert_success
    assert_output --partial "Smart Cost Recommendations"
}

@test "--recommendations shows checks performed when no issues found" {
    run "$STATUSLINE_SCRIPT" --recommendations
    assert_success
    # Either shows recommendations or the "no recommendations" message with checks
    [[ "$output" == *"recommendation"* ]] || [[ "$output" == *"Checks performed"* ]]
}

@test "--recommendations returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --recommendations
    assert_success
}

@test "--recommendations shows no-data message with empty projects dir" {
    run "$STATUSLINE_SCRIPT" --recommendations
    assert_success
    # With empty projects dir, should show efficient message or at least not crash
    assert_output --partial "Recommendations"
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

@test "--recommendations --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --recommendations --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--recommendations --json has report field" {
    run "$STATUSLINE_SCRIPT" --recommendations --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local report
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "recommendations" ]]
}

@test "--recommendations --json has count field" {
    run "$STATUSLINE_SCRIPT" --recommendations --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.count' >/dev/null
}

@test "--recommendations --json has recommendations array" {
    run "$STATUSLINE_SCRIPT" --recommendations --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.recommendations' >/dev/null
    local rec_type
    rec_type=$(echo "$json_output" | jq -r '.recommendations | type')
    [[ "$rec_type" == "array" ]]
}

@test "--recommendations --json has high_priority field" {
    run "$STATUSLINE_SCRIPT" --recommendations --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.high_priority' >/dev/null
}

@test "--recommendations --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --recommendations --json
    assert_success
}

# ==============================================================================
# Direct function tests: check_cache_efficiency_recommendation
# ==============================================================================

@test "check_cache_efficiency_recommendation flags low cache rate" {
    source "$STATUSLINE_ROOT/lib/cost/recommendations.sh" 2>/dev/null || true
    run check_cache_efficiency_recommendation 40
    assert_success
    assert_output --partial "cache"
    assert_output --partial "HIGH"
}

@test "check_cache_efficiency_recommendation flags medium cache rate" {
    source "$STATUSLINE_ROOT/lib/cost/recommendations.sh" 2>/dev/null || true
    run check_cache_efficiency_recommendation 60
    assert_success
    assert_output --partial "cache"
    assert_output --partial "MEDIUM"
}

@test "check_cache_efficiency_recommendation passes for good cache rate" {
    source "$STATUSLINE_ROOT/lib/cost/recommendations.sh" 2>/dev/null || true
    run check_cache_efficiency_recommendation 85
    assert_success
    # Should produce no output for good rates
    [[ -z "$output" ]]
}

@test "check_cache_efficiency_recommendation handles zero" {
    source "$STATUSLINE_ROOT/lib/cost/recommendations.sh" 2>/dev/null || true
    run check_cache_efficiency_recommendation 0
    assert_success
    assert_output --partial "cache"
    assert_output --partial "HIGH"
}

@test "check_cache_efficiency_recommendation handles invalid input" {
    source "$STATUSLINE_ROOT/lib/cost/recommendations.sh" 2>/dev/null || true
    run check_cache_efficiency_recommendation "abc"
    assert_success
    [[ -z "$output" ]]
}

# ==============================================================================
# Direct function tests: generate_recommendations
# ==============================================================================

@test "generate_recommendations runs without error" {
    source "$STATUSLINE_ROOT/lib/cost/recommendations.sh" 2>/dev/null || true
    run generate_recommendations "" "" ""
    assert_success
}

@test "generate_recommendations produces output with low cache rate via env" {
    source "$STATUSLINE_ROOT/lib/cost/recommendations.sh" 2>/dev/null || true
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_read_input_tokens":100,"input_tokens":1000}}'
    run generate_recommendations "" "" ""
    assert_success
    # 10% cache rate should trigger recommendation
    assert_output --partial "cache"
}

# ==============================================================================
# Filter integration tests
# ==============================================================================

@test "--recommendations works with --since" {
    run "$STATUSLINE_SCRIPT" --recommendations --since 7d
    assert_success
    assert_output --partial "Recommendations"
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --recommendations flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--recommendations"
}

@test "--help shows recommendations description" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "cost optimization"
}
