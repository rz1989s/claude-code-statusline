#!/usr/bin/env bats
# ==============================================================================
# Test: Bash 3 fallback statusline
# ==============================================================================
# When no bash 4+ interpreter is available, the script used to warn and then
# fall through into the (bash4-only) module pipeline anyway, crashing on the
# first `declare -A` and printing nothing. Covers the minimal fallback line
# rendered instead, including a real run under /bin/bash.
#
# Not exported (like lib/components.sh functions, see Issue #134 comment in
# lib/core.sh) since it's only ever invoked within a freshly-run statusline.sh,
# never expected to persist across bats' per-test process boundary. So each
# test extracts and sources just the function body, matching that pattern.

load "../setup_suite"

setup() {
    common_setup
}

teardown() {
    common_teardown
}

_fallback_fn_src() {
    sed -n '/^_render_bash3_fallback_statusline() {/,/^}/p' "$STATUSLINE_SCRIPT"
}

_run_fallback_with_json() {
    printf '%s' "$1" | bash -c "$(_fallback_fn_src)"$'\n''_render_bash3_fallback_statusline'
}

_run_fallback() {
    _run_fallback_with_json "$(generate_test_input "$1" "$2")"
}

_run_fallback_bash3() {
    local json
    json="$(generate_test_input "$1" "$2")"
    printf '%s' "$json" | /bin/bash -c "$(_fallback_fn_src)"$'\n''_render_bash3_fallback_statusline'
}

@test "fallback renders model, cwd, and git branch from JSON input" {
    run _run_fallback "$STATUSLINE_ROOT" "Sonnet 5"
    assert_success
    assert_output_contains "Sonnet 5"
    assert_output_contains "$(basename "$STATUSLINE_ROOT")"
}

@test "fallback degrades gracefully with missing fields" {
    run _run_fallback_with_json '{}'
    assert_success
    assert_output_contains "Claude"
}

@test "fallback runs cleanly under real /bin/bash (bash 3 target)" {
    run _run_fallback_bash3 "$STATUSLINE_ROOT" "Sonnet 5"
    assert_success
    assert_output_contains "Sonnet 5"
}

@test "no-modern-bash branch invokes the fallback and exits immediately" {
    run bash -c 'grep -A15 "No modern bash found" "'"$STATUSLINE_SCRIPT"'"'
    assert_success
    assert_output_contains "_render_bash3_fallback_statusline"
    assert_output_contains "exit 0"
}
