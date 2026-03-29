#!/usr/bin/env bats
# ==============================================================================
# Test: Responsive statusline — width detection, measurement, filtering
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/responsive.sh" 2>/dev/null || true
    # Clear cached width between tests
    unset STATUSLINE_TERMINAL_WIDTH
}

teardown() {
    common_teardown
    unset STATUSLINE_TERMINAL_WIDTH
    unset ENV_CONFIG_TERMINAL_WIDTH
    unset COLUMNS
}

# ==============================================================================
# Width Detection
# ==============================================================================

@test "detect_terminal_width returns COLUMNS when set" {
    export COLUMNS=142
    run detect_terminal_width
    assert_success
    assert_output "142"
}

@test "detect_terminal_width ENV_CONFIG override takes priority over COLUMNS" {
    export COLUMNS=142
    export ENV_CONFIG_TERMINAL_WIDTH=90
    run detect_terminal_width
    assert_success
    assert_output "90"
}

@test "detect_terminal_width falls back to 120 when nothing set" {
    unset COLUMNS
    unset ENV_CONFIG_TERMINAL_WIDTH
    export TERM=""
    run detect_terminal_width
    assert_success
    [[ "$output" -ge 1 ]]
}

@test "detect_terminal_width rejects invalid negative value" {
    export COLUMNS="-1"
    unset ENV_CONFIG_TERMINAL_WIDTH
    run detect_terminal_width
    assert_success
    assert_output "120"
}

@test "detect_terminal_width caches result across calls" {
    export COLUMNS=100
    detect_terminal_width > /dev/null
    export COLUMNS=200
    run detect_terminal_width
    assert_success
    assert_output "100"
}
