#!/usr/bin/env bats
# ==============================================================================
# Test: render_progress_bar() ASCII progress bar utility
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    STATUSLINE_CLI_REPORT_FORMAT_LOADED=""
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ==============================================================================
# Block style tests (default)
# ==============================================================================

@test "render_progress_bar block style at 0%" {
    local result
    result=$(render_progress_bar 0 10 "block")
    [[ "$result" == *"0%"* ]]
    [[ "$result" == *"░░░░░░░░░░"* ]]
}

@test "render_progress_bar block style at 50%" {
    local result
    result=$(render_progress_bar 50 10 "block")
    [[ "$result" == *"50%"* ]]
    [[ "$result" == *"▓▓▓▓▓"* ]]
    [[ "$result" == *"░░░░░"* ]]
}

@test "render_progress_bar block style at 100%" {
    local result
    result=$(render_progress_bar 100 10 "block")
    [[ "$result" == *"100%"* ]]
    [[ "$result" == *"▓▓▓▓▓▓▓▓▓▓"* ]]
}

@test "render_progress_bar defaults to block style" {
    local result
    result=$(render_progress_bar 50 10)
    [[ "$result" == *"▓"* ]]
    [[ "$result" == *"░"* ]]
}

# ==============================================================================
# Simple style tests
# ==============================================================================

@test "render_progress_bar simple style at 50%" {
    local result
    result=$(render_progress_bar 50 10 "simple")
    [[ "$result" == *"["* ]]
    [[ "$result" == *"]"* ]]
    [[ "$result" == *"="* ]]
    [[ "$result" == *"50%"* ]]
}

@test "render_progress_bar simple style at 0%" {
    local result
    result=$(render_progress_bar 0 10 "simple")
    [[ "$result" == *"["* ]]
    [[ "$result" == *"]"* ]]
    [[ "$result" == *"0%"* ]]
}

@test "render_progress_bar simple style at 100%" {
    local result
    result=$(render_progress_bar 100 10 "simple")
    [[ "$result" == *"=========="* ]]
    [[ "$result" == *"100%"* ]]
}

# ==============================================================================
# Minimal style tests
# ==============================================================================

@test "render_progress_bar minimal style at 50%" {
    local result
    result=$(render_progress_bar 50 10 "minimal")
    [[ "$result" == *"|"* ]]
    [[ "$result" == *"●"* ]]
    [[ "$result" == *"○"* ]]
    [[ "$result" == *"50%"* ]]
}

@test "render_progress_bar minimal style at 0%" {
    local result
    result=$(render_progress_bar 0 10 "minimal")
    [[ "$result" == *"○○○○○○○○○○"* ]]
}

@test "render_progress_bar minimal style at 100%" {
    local result
    result=$(render_progress_bar 100 10 "minimal")
    [[ "$result" == *"●●●●●●●●●●"* ]]
}

# ==============================================================================
# Gradient style tests
# ==============================================================================

@test "render_progress_bar gradient style at 50%" {
    local result
    result=$(render_progress_bar 50 10 "gradient")
    [[ "$result" == *"█"* ]]
    [[ "$result" == *"░"* ]]
    [[ "$result" == *"50%"* ]]
}

# ==============================================================================
# Edge case tests
# ==============================================================================

@test "render_progress_bar clamps negative percentage to 0" {
    local result
    result=$(render_progress_bar -10 10 "block")
    [[ "$result" == *"0%"* ]]
}

@test "render_progress_bar clamps percentage above 100" {
    local result
    result=$(render_progress_bar 150 10 "block")
    [[ "$result" == *"100%"* ]]
}

@test "render_progress_bar handles default width" {
    local result
    result=$(render_progress_bar 50)
    [[ "$result" == *"50%"* ]]
}

@test "render_progress_bar handles custom width" {
    local result
    result=$(render_progress_bar 50 30 "block")
    [[ "$result" == *"50%"* ]]
    # 15 filled + 15 empty = 30 chars
    local bar_part="${result% *}"
    [[ ${#bar_part} -eq 30 ]]
}

@test "render_progress_bar handles unknown style gracefully" {
    local result
    result=$(render_progress_bar 50 10 "unknown_style")
    [[ "$result" == *"50%"* ]]
}
