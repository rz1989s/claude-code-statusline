#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/context_alert.sh" 2>/dev/null || true
}
teardown() { common_teardown; }

@test "collect_context_alert_data detects exceeded true" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":true}'
    collect_context_alert_data
    [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" == "true" ]]
}

@test "collect_context_alert_data detects exceeded false" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":false}'
    collect_context_alert_data
    [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" == "false" ]]
}

@test "collect_context_alert_data defaults false when missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_context_alert_data
    [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" == "false" ]]
}

@test "render_context_alert shows warning when exceeded" {
    COMPONENT_CONTEXT_ALERT_EXCEEDED="true"
    run render_context_alert "false"
    assert_success
    assert_output --partial ">200K"
}

@test "render_context_alert returns 1 when not exceeded" {
    COMPONENT_CONTEXT_ALERT_EXCEEDED="false"
    run render_context_alert "false"
    assert_failure
}

@test "render_context_alert returns 1 when field absent" {
    COMPONENT_CONTEXT_ALERT_EXCEEDED=""
    run render_context_alert "false"
    assert_failure
}
