#!/usr/bin/env bats
# ==============================================================================
# Test: OAuth Usage Limits API Hardening
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/security.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/cache.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/usage_limits.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

@test "collect_usage_limits_data uses native JSON when five_hour.utilization present" {
    export STATUSLINE_INPUT_JSON='{"five_hour":{"utilization":22.5,"resets_at":"2026-03-04T19:00:00Z"},"seven_day":{"utilization":54.0,"resets_at":"2026-03-08T08:00:00Z"}}'
    collect_usage_limits_data
    [[ "$COMPONENT_USAGE_FIVE_HOUR" == "23" || "$COMPONENT_USAGE_FIVE_HOUR" == "22" ]]
}

@test "collect_usage_limits_data sets status ok on success" {
    export STATUSLINE_INPUT_JSON='{"five_hour":{"utilization":22.5,"resets_at":"2026-03-04T19:00:00Z"}}'
    collect_usage_limits_data
    [[ "$COMPONENT_USAGE_STATUS" == "ok" ]]
}

@test "collect_usage_limits_data sets status unavailable on failure" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'
    # Mock curl and security to fail
    create_failing_mock_command "curl" "Connection refused"
    create_failing_mock_command "security" "SecItemNotFound"
    collect_usage_limits_data
    [[ "$COMPONENT_USAGE_STATUS" == "unavailable" ]]
}

@test "collect_usage_limits_data sets empty when no data available" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'
    create_failing_mock_command "curl" "Connection refused"
    create_failing_mock_command "security" "SecItemNotFound"
    collect_usage_limits_data
    [[ -z "$COMPONENT_USAGE_FIVE_HOUR" ]]
}

@test "render_usage_reset shows countdown when data available" {
    export STATUSLINE_INPUT_JSON='{"five_hour":{"utilization":22.5,"resets_at":"2026-03-04T23:00:00Z"},"seven_day":{"utilization":54.0,"resets_at":"2026-03-08T08:00:00Z"}}'
    collect_usage_limits_data
    run render_usage_reset "false"
    assert_success
    assert_output --partial "5H"
}

@test "render_usage_reset returns 1 when no data" {
    COMPONENT_USAGE_FIVE_HOUR=""
    COMPONENT_USAGE_SEVEN_DAY=""
    run render_usage_reset "false"
    assert_failure
}
