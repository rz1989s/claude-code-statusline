#!/usr/bin/env bats
# ==============================================================================
# Integration: Responsive statusline — end-to-end width constraint tests
# ==============================================================================

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    cd "$STATUSLINE_DIR"
    export STATUSLINE_SCRIPT="$STATUSLINE_DIR/statusline.sh"
    export STATUSLINE_TESTING="true"

    export TEST_TMP_DIR="/tmp/responsive_integration_$$"
    mkdir -p "$TEST_TMP_DIR/projects/test/sessions"
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR"
    export XDG_CACHE_HOME="$TEST_TMP_DIR/cache"
    mkdir -p "$XDG_CACHE_HOME"
}

teardown() {
    rm -rf "$TEST_TMP_DIR"
    unset STATUSLINE_TERMINAL_WIDTH
    unset ENV_CONFIG_TERMINAL_WIDTH
    unset COLUMNS
}

teardown_file() {
    pkill -f "responsive_integration_" 2>/dev/null || true
    sleep 0.2
    pkill -9 -f "responsive_integration_" 2>/dev/null || true
}

_test_json='{"version":"2.1.86","workspace":{"current_dir":"/tmp/test-repo"},"model":{"id":"claude-opus-4-6-20250415","display_name":"Claude Opus 4.6"},"context_window":{"used_percentage":12,"remaining_percentage":88,"context_window_size":1000000,"current_usage":{"cache_read_input_tokens":5000,"input_tokens":10000},"total_input_tokens":45000,"total_output_tokens":12000},"cost":{"total_cost_usd":0.45,"total_lines_added":120,"total_lines_removed":30},"session_id":"test-responsive","mcp":{"servers":[]}}'

# Helper: run statusline in FD-clean environment (prevents BATS hang)
_run_sl() {
    local json="$1"
    local extra_env="${2:-}"
    timeout 10 bash -c "exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&- 2>/dev/null; ${extra_env} echo '${json}' | '$STATUSLINE_SCRIPT'"
}

# Helper: get visible width of a line (strip ANSI, count chars)
_visible_width() {
    printf '%s' "$1" | sed $'s/\x1b\[[0-9;]*m//g' | wc -m | tr -d ' '
}

@test "wide terminal (120 cols) renders all components" {
    export COLUMNS=120
    run _run_sl "$_test_json"

    [[ "$status" -eq 0 ]]
    [[ -n "$output" ]]
    local line_count
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    [[ "$line_count" -ge 2 ]]
}

@test "narrow terminal (60 cols) — no line exceeds width" {
    export COLUMNS=60
    run _run_sl "$_test_json"

    [[ "$status" -eq 0 ]]
    [[ -n "$output" ]]
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local w
        w=$(_visible_width "$line")
        # Allow ±2 columns tolerance for emoji measurement
        [[ "$w" -le 62 ]]
    done <<< "$output"
}

@test "very narrow terminal (40 cols) — output exists and fits" {
    export COLUMNS=40
    run _run_sl "$_test_json"

    [[ "$status" -eq 0 ]]
    [[ -n "$output" ]]
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local w
        w=$(_visible_width "$line")
        [[ "$w" -le 42 ]]
    done <<< "$output"
}

@test "ENV_CONFIG_TERMINAL_WIDTH overrides COLUMNS" {
    export COLUMNS=200
    export ENV_CONFIG_TERMINAL_WIDTH=50
    run _run_sl "$_test_json"

    [[ "$status" -eq 0 ]]
    [[ -n "$output" ]]
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local w
        w=$(_visible_width "$line")
        [[ "$w" -le 52 ]]
    done <<< "$output"
}
