#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/agent_display.sh" 2>/dev/null || true
}
teardown() { common_teardown; }

@test "collect_agent_display_data extracts agent name" {
    export STATUSLINE_INPUT_JSON='{"agent":{"name":"security-reviewer"}}'
    collect_agent_display_data
    [[ "$COMPONENT_AGENT_DISPLAY_NAME" == "security-reviewer" ]]
}

@test "collect_agent_display_data empty when no agent" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_agent_display_data
    [[ -z "$COMPONENT_AGENT_DISPLAY_NAME" ]]
}

@test "render_agent_display shows agent name" {
    COMPONENT_AGENT_DISPLAY_NAME="security-reviewer"
    run render_agent_display "false"
    assert_success
    assert_output "Agent: security-reviewer"
}

@test "render_agent_display returns 1 when no agent" {
    COMPONENT_AGENT_DISPLAY_NAME=""
    run render_agent_display "false"
    assert_failure
}
