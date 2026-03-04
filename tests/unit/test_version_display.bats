#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/version_display.sh" 2>/dev/null || true
}
teardown() { common_teardown; }

@test "collect_version_display_data extracts version from JSON" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    collect_version_display_data
    [[ "$COMPONENT_VERSION_DISPLAY_VALUE" == "2.1.66" ]]
}

@test "collect_version_display_data sets empty when version absent" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_version_display_data
    [[ -z "$COMPONENT_VERSION_DISPLAY_VALUE" ]]
}

@test "render_version_display shows short format" {
    COMPONENT_VERSION_DISPLAY_VALUE="2.1.66"
    CONFIG_VERSION_DISPLAY_FORMAT="short"
    run render_version_display "false"
    assert_success
    assert_output "v2.1.66"
}

@test "render_version_display shows full format" {
    COMPONENT_VERSION_DISPLAY_VALUE="2.1.66"
    CONFIG_VERSION_DISPLAY_FORMAT="full"
    run render_version_display "false"
    assert_success
    assert_output "CC v2.1.66"
}

@test "render_version_display returns 1 when no version" {
    COMPONENT_VERSION_DISPLAY_VALUE=""
    run render_version_display "false"
    assert_failure
}
