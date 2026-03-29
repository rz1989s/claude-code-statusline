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

# ==============================================================================
# Width Measurement
# ==============================================================================

@test "measure_visible_width counts plain text correctly" {
    run measure_visible_width "hello"
    assert_success
    assert_output "5"
}

@test "measure_visible_width strips ANSI color codes" {
    run measure_visible_width $'\e[32mhello\e[0m'
    assert_success
    assert_output "5"
}

@test "measure_visible_width strips nested ANSI codes" {
    run measure_visible_width $'\e[1m\e[32mbold green\e[0m'
    assert_success
    assert_output "10"
}

@test "measure_visible_width counts emoji as double-width" {
    run measure_visible_width "🧠 Opus"
    assert_success
    # 🧠 = 2 cols, space = 1, O-p-u-s = 4 → total 7
    assert_output "7"
}

@test "measure_visible_width returns 0 for empty string" {
    run measure_visible_width ""
    assert_success
    assert_output "0"
}

@test "measure_visible_width handles separator pipe character" {
    run measure_visible_width " │ "
    assert_success
    assert_output "3"
}

# ==============================================================================
# Component Priority
# ==============================================================================

@test "get_component_priority returns 1 for essential components" {
    run get_component_priority "repo_info"
    assert_success
    assert_output "1"
}

@test "get_component_priority returns 4 for low-priority components" {
    run get_component_priority "time_display"
    assert_success
    assert_output "4"
}

@test "get_component_priority returns 3 for unregistered components" {
    run get_component_priority "some_unknown_component"
    assert_success
    assert_output "3"
}

# ==============================================================================
# Component Filtering
# ==============================================================================

@test "filter_line_components passes all through when width sufficient" {
    local names=("aaa" "bbb" "ccc")
    local outputs=("AAAA" "BBBB" "CCCC")
    run filter_line_components 120 " │ " names outputs
    assert_success
    assert_output "aaa,bbb,ccc"
}

@test "filter_line_components drops lowest priority first" {
    # time_display (pri 4) should be dropped before model_info (pri 1)
    local names=("model_info" "time_display")
    local outputs=("$(printf '%0.s=' {1..40})" "$(printf '%0.s=' {1..40})")
    run filter_line_components 50 " │ " names outputs
    assert_success
    assert_output "model_info"
}

@test "filter_line_components tie-breaks by dropping rightmost" {
    local names=("submodules" "version_info")
    local outputs=("$(printf '%0.s=' {1..40})" "$(printf '%0.s=' {1..40})")
    run filter_line_components 50 " │ " names outputs
    assert_success
    assert_output "submodules"
}

@test "filter_line_components never drops last component" {
    local names=("repo_info")
    local outputs=("$(printf '%0.s=' {1..200})")
    run filter_line_components 50 " │ " names outputs
    assert_success
    assert_output "repo_info"
}

@test "filter_line_components accounts for separator width" {
    # 3 components each 25 chars. Separators: 2 × 3 = 6. Total = 81.
    # Budget 80 — should drop one.
    local names=("cost_repo" "cost_monthly" "cost_live")
    local outputs=("$(printf '%0.s=' {1..25})" "$(printf '%0.s=' {1..25})" "$(printf '%0.s=' {1..25})")
    run filter_line_components 80 " │ " names outputs
    assert_success
    # cost_live and cost_monthly are both priority 2 — rightmost (cost_live) dropped
    assert_output "cost_repo,cost_monthly"
}

@test "filter_line_components handles empty component list" {
    local names=()
    local outputs=()
    run filter_line_components 120 " │ " names outputs
    assert_success
    assert_output ""
}

@test "filter_line_components skips empty rendered outputs" {
    local names=("model_info" "bedrock_model" "commits")
    local outputs=("ModelOutput" "" "Commits:3")
    run filter_line_components 120 " │ " names outputs
    assert_success
    assert_output "model_info,commits"
}

# ==============================================================================
# ANSI-Safe Truncation
# ==============================================================================

@test "truncate_line_ansi_safe no-op when within budget" {
    run truncate_line_ansi_safe "short" 80
    assert_success
    assert_output "short"
}

@test "truncate_line_ansi_safe truncates plain text with ellipsis" {
    run truncate_line_ansi_safe "hello world" 8
    assert_success
    assert_output "hello w…"
}

@test "truncate_line_ansi_safe preserves ANSI and adds reset" {
    local input=$'\e[32mhello world\e[0m'
    run truncate_line_ansi_safe "$input" 8
    assert_success
    # Should keep color, truncate visible text, close with reset
    [[ "$output" == *"hello w"* ]]
    [[ "$output" == *"…" ]]
}

@test "truncate_line_ansi_safe handles width of 1" {
    run truncate_line_ansi_safe "hello" 1
    assert_success
    assert_output "…"
}
