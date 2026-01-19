#!/usr/bin/env bats

# Unit tests for Moon Phase Icon function

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Load the prayer display module for testing
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/security.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/prayer/display.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ============================================================================
# MOON PHASE ICON TESTS
# ============================================================================

@test "get_moon_phase_icon returns 🌑 (New Moon) for day 1" {
    run get_moon_phase_icon 1
    assert_success
    assert_output "🌑"
}

@test "get_moon_phase_icon returns 🌒 (Waxing Crescent) for day 2" {
    run get_moon_phase_icon 2
    assert_success
    assert_output "🌒"
}

@test "get_moon_phase_icon returns 🌒 (Waxing Crescent) for day 5" {
    run get_moon_phase_icon 5
    assert_success
    assert_output "🌒"
}

@test "get_moon_phase_icon returns 🌒 (Waxing Crescent) for day 7" {
    run get_moon_phase_icon 7
    assert_success
    assert_output "🌒"
}

@test "get_moon_phase_icon returns 🌓 (First Quarter) for day 8" {
    run get_moon_phase_icon 8
    assert_success
    assert_output "🌓"
}

@test "get_moon_phase_icon returns 🌔 (Waxing Gibbous) for day 9" {
    run get_moon_phase_icon 9
    assert_success
    assert_output "🌔"
}

@test "get_moon_phase_icon returns 🌔 (Waxing Gibbous) for day 12" {
    run get_moon_phase_icon 12
    assert_success
    assert_output "🌔"
}

@test "get_moon_phase_icon returns 🌔 (Waxing Gibbous) for day 14" {
    run get_moon_phase_icon 14
    assert_success
    assert_output "🌔"
}

@test "get_moon_phase_icon returns 🌕 (Full Moon) for day 15" {
    run get_moon_phase_icon 15
    assert_success
    assert_output "🌕"
}

@test "get_moon_phase_icon returns 🌕 (Full Moon) for day 16" {
    run get_moon_phase_icon 16
    assert_success
    assert_output "🌕"
}

@test "get_moon_phase_icon returns 🌖 (Waning Gibbous) for day 17" {
    run get_moon_phase_icon 17
    assert_success
    assert_output "🌖"
}

@test "get_moon_phase_icon returns 🌖 (Waning Gibbous) for day 20" {
    run get_moon_phase_icon 20
    assert_success
    assert_output "🌖"
}

@test "get_moon_phase_icon returns 🌖 (Waning Gibbous) for day 22" {
    run get_moon_phase_icon 22
    assert_success
    assert_output "🌖"
}

@test "get_moon_phase_icon returns 🌗 (Third Quarter) for day 23" {
    run get_moon_phase_icon 23
    assert_success
    assert_output "🌗"
}

@test "get_moon_phase_icon returns 🌘 (Waning Crescent) for day 24" {
    run get_moon_phase_icon 24
    assert_success
    assert_output "🌘"
}

@test "get_moon_phase_icon returns 🌘 (Waning Crescent) for day 27" {
    run get_moon_phase_icon 27
    assert_success
    assert_output "🌘"
}

@test "get_moon_phase_icon returns 🌘 (Waning Crescent) for day 29" {
    run get_moon_phase_icon 29
    assert_success
    assert_output "🌘"
}

@test "get_moon_phase_icon returns 🌘 (Waning Crescent) for day 30" {
    run get_moon_phase_icon 30
    assert_success
    assert_output "🌘"
}

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

@test "get_moon_phase_icon returns 🌙 (fallback) for empty input" {
    run get_moon_phase_icon ""
    assert_failure
    assert_output "🌙"
}

@test "get_moon_phase_icon returns 🌙 (fallback) for non-numeric input" {
    run get_moon_phase_icon "abc"
    assert_failure
    assert_output "🌙"
}

@test "get_moon_phase_icon returns 🌙 (fallback) for negative number" {
    run get_moon_phase_icon "-5"
    assert_failure
    assert_output "🌙"
}

@test "get_moon_phase_icon returns 🌙 (fallback) for day 0" {
    run get_moon_phase_icon 0
    assert_success
    assert_output "🌙"
}

@test "get_moon_phase_icon returns 🌙 (fallback) for day 31" {
    run get_moon_phase_icon 31
    assert_success
    assert_output "🌙"
}

@test "get_moon_phase_icon returns 🌙 (fallback) for day 99" {
    run get_moon_phase_icon 99
    assert_success
    assert_output "🌙"
}

# ============================================================================
# BOUNDARY TESTS (Edges of each phase)
# ============================================================================

@test "get_moon_phase_icon handles phase boundary: day 3 (waxing crescent)" {
    run get_moon_phase_icon 3
    assert_success
    assert_output "🌒"
}

@test "get_moon_phase_icon handles phase boundary: day 10 (waxing gibbous)" {
    run get_moon_phase_icon 10
    assert_success
    assert_output "🌔"
}

@test "get_moon_phase_icon handles phase boundary: day 18 (waning gibbous)" {
    run get_moon_phase_icon 18
    assert_success
    assert_output "🌖"
}

@test "get_moon_phase_icon handles phase boundary: day 25 (waning crescent)" {
    run get_moon_phase_icon 25
    assert_success
    assert_output "🌘"
}
