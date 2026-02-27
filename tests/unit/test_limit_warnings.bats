#!/usr/bin/env bats
# ==============================================================================
# Test: --limits unified limit warnings system (Issue #210)
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    # Prevent scanning real JSONL files
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects"
}

teardown() {
    common_teardown
}

# ==============================================================================
# get_context_alert_level() unit tests
# ==============================================================================

@test "get_context_alert_level returns normal for low percentage" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run get_context_alert_level 30
    assert_success
    assert_output "normal"
}

@test "get_context_alert_level returns normal at threshold boundary minus one" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run get_context_alert_level 74
    assert_success
    assert_output "normal"
}

@test "get_context_alert_level returns warn at warn threshold" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run get_context_alert_level 75
    assert_success
    assert_output "warn"
}

@test "get_context_alert_level returns warn between thresholds" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run get_context_alert_level 85
    assert_success
    assert_output "warn"
}

@test "get_context_alert_level returns critical at critical threshold" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run get_context_alert_level 90
    assert_success
    assert_output "critical"
}

@test "get_context_alert_level returns critical above critical threshold" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run get_context_alert_level 99
    assert_success
    assert_output "critical"
}

@test "get_context_alert_level defaults to 0 with no argument" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run get_context_alert_level
    assert_success
    assert_output "normal"
}

# ==============================================================================
# check_all_limits() unit tests
# ==============================================================================

@test "check_all_limits returns empty when all values are normal" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 30 20 15 1.00
    assert_success
    assert_output ""
}

@test "check_all_limits detects high context percentage" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 80 20 15 1.00
    assert_success
    assert_output --partial "context"
    assert_output --partial "warn"
}

@test "check_all_limits detects critical context percentage" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 95 20 15 1.00
    assert_success
    assert_output --partial "context"
    assert_output --partial "critical"
}

@test "check_all_limits detects high 5-hour rate" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 30 75 15 1.00
    assert_success
    assert_output --partial "rate_5h"
    assert_output --partial "warn"
}

@test "check_all_limits detects critical 5-hour rate" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 30 95 15 1.00
    assert_success
    assert_output --partial "rate_5h"
    assert_output --partial "critical"
}

@test "check_all_limits detects high 7-day rate" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 30 20 80 1.00
    assert_success
    assert_output --partial "rate_7d"
    assert_output --partial "warn"
}

@test "check_all_limits detects multiple warnings simultaneously" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 85 75 80 1.00
    assert_success
    assert_output --partial "context"
    assert_output --partial "rate_5h"
    assert_output --partial "rate_7d"
}

@test "check_all_limits returns zero exit code always" {
    source "$PROJECT_ROOT/lib/cost/alerts.sh" || true
    run check_all_limits 99 99 99 99.00
    assert_success
}

# ==============================================================================
# CLI --limits human output tests
# ==============================================================================

@test "--limits outputs System Limits Status header" {
    run "$STATUSLINE_SCRIPT" --limits
    assert_success
    assert_output --partial "System Limits Status"
}

@test "--limits shows all-normal message with default env" {
    export STATUSLINE_CONTEXT_PCT=0
    export STATUSLINE_FIVE_HOUR_PCT=0
    export STATUSLINE_SEVEN_DAY_PCT=0
    export STATUSLINE_DAILY_COST=0
    run "$STATUSLINE_SCRIPT" --limits
    assert_success
    assert_output --partial "All limits within normal range"
}

@test "--limits shows warnings when context is high" {
    export STATUSLINE_CONTEXT_PCT=85
    export STATUSLINE_FIVE_HOUR_PCT=0
    export STATUSLINE_SEVEN_DAY_PCT=0
    export STATUSLINE_DAILY_COST=0
    run "$STATUSLINE_SCRIPT" --limits
    assert_success
    assert_output --partial "context"
    assert_output --partial "warn"
}

@test "--limits returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --limits
    assert_success
}

# ==============================================================================
# CLI --limits --json output tests
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

@test "--limits --json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --limits --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--limits --json has report field set to limits" {
    run "$STATUSLINE_SCRIPT" --limits --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local report
    report=$(echo "$json_output" | jq -r '.report')
    [[ "$report" == "limits" ]]
}

@test "--limits --json has status field" {
    run "$STATUSLINE_SCRIPT" --limits --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.status' >/dev/null
}

@test "--limits --json has warnings array" {
    run "$STATUSLINE_SCRIPT" --limits --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.warnings | type == "array"' >/dev/null
}

@test "--limits --json shows ok status when all normal" {
    export STATUSLINE_CONTEXT_PCT=0
    export STATUSLINE_FIVE_HOUR_PCT=0
    export STATUSLINE_SEVEN_DAY_PCT=0
    export STATUSLINE_DAILY_COST=0
    run "$STATUSLINE_SCRIPT" --limits --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local status
    status=$(echo "$json_output" | jq -r '.status')
    [[ "$status" == "ok" ]]
}

@test "--limits --json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --limits --json
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --limits flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--limits"
}

@test "--help mentions limit warnings description" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "System limit warnings"
}
