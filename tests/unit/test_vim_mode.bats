#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/vim_mode.sh" 2>/dev/null || true
}
teardown() { common_teardown; }

@test "collect_vim_mode_data extracts NORMAL mode" {
    export STATUSLINE_INPUT_JSON='{"vim":{"mode":"NORMAL"}}'
    collect_vim_mode_data
    [[ "$COMPONENT_VIM_MODE_VALUE" == "NORMAL" ]]
}

@test "collect_vim_mode_data extracts INSERT mode" {
    export STATUSLINE_INPUT_JSON='{"vim":{"mode":"INSERT"}}'
    collect_vim_mode_data
    [[ "$COMPONENT_VIM_MODE_VALUE" == "INSERT" ]]
}

@test "collect_vim_mode_data empty when vim not enabled" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_vim_mode_data
    [[ -z "$COMPONENT_VIM_MODE_VALUE" ]]
}

@test "render_vim_mode shows VIM:NORMAL" {
    COMPONENT_VIM_MODE_VALUE="NORMAL"
    run render_vim_mode "false"
    assert_success
    assert_output "VIM:NORMAL"
}

@test "render_vim_mode shows VIM:INSERT" {
    COMPONENT_VIM_MODE_VALUE="INSERT"
    run render_vim_mode "false"
    assert_success
    assert_output "VIM:INSERT"
}

@test "render_vim_mode returns 1 when disabled" {
    COMPONENT_VIM_MODE_VALUE=""
    run render_vim_mode "false"
    assert_failure
}
