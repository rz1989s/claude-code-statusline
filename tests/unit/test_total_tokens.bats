#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/total_tokens.sh" 2>/dev/null || true
}
teardown() { common_teardown; }

@test "collect_total_tokens_data extracts cumulative tokens" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"total_input_tokens":15234,"total_output_tokens":4521}}'
    collect_total_tokens_data
    [[ "$COMPONENT_TOTAL_TOKENS_INPUT" == "15234" ]]
    [[ "$COMPONENT_TOTAL_TOKENS_OUTPUT" == "4521" ]]
}

@test "collect_total_tokens_data defaults to 0 when missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_total_tokens_data
    [[ "$COMPONENT_TOTAL_TOKENS_INPUT" == "0" ]]
    [[ "$COMPONENT_TOTAL_TOKENS_OUTPUT" == "0" ]]
}

@test "render_total_tokens split format" {
    COMPONENT_TOTAL_TOKENS_INPUT="15234"
    COMPONENT_TOTAL_TOKENS_OUTPUT="4521"
    CONFIG_TOTAL_TOKENS_FORMAT="split"
    run render_total_tokens "false"
    assert_success
    assert_output --partial "15.2K in"
    assert_output --partial "4.5K out"
}

@test "render_total_tokens compact format" {
    COMPONENT_TOTAL_TOKENS_INPUT="15234"
    COMPONENT_TOTAL_TOKENS_OUTPUT="4521"
    CONFIG_TOTAL_TOKENS_FORMAT="compact"
    run render_total_tokens "false"
    assert_success
    assert_output --partial "19.8K total"
}

@test "render_total_tokens returns 1 when both zero" {
    COMPONENT_TOTAL_TOKENS_INPUT="0"
    COMPONENT_TOTAL_TOKENS_OUTPUT="0"
    run render_total_tokens "false"
    assert_failure
}

@test "render_total_tokens handles millions" {
    COMPONENT_TOTAL_TOKENS_INPUT="1523400"
    COMPONENT_TOTAL_TOKENS_OUTPUT="452100"
    CONFIG_TOTAL_TOKENS_FORMAT="compact"
    run render_total_tokens "false"
    assert_success
    assert_output --partial "M total"
}
