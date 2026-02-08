#!/usr/bin/env bats
# ==============================================================================
# Test: --since / --until date filtering and parse_date_arg()
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
# parse_date_arg() Tests
# ==============================================================================

@test "parse_date_arg should handle YYYYMMDD format" {
    run parse_date_arg "20260115"
    assert_success
    assert_output "2026-01-15"
}

@test "parse_date_arg should handle YYYY-MM-DD format" {
    run parse_date_arg "2026-01-15"
    assert_success
    assert_output "2026-01-15"
}

@test "parse_date_arg should handle 'today'" {
    run parse_date_arg "today"
    assert_success
    local expected
    expected=$(date +%Y-%m-%d)
    assert_output "$expected"
}

@test "parse_date_arg should handle 'yesterday'" {
    run parse_date_arg "yesterday"
    assert_success
    # Just verify format
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "parse_date_arg should handle relative days (7d)" {
    run parse_date_arg "7d"
    assert_success
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "parse_date_arg should handle relative days (30d)" {
    run parse_date_arg "30d"
    assert_success
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "parse_date_arg should handle 'week'" {
    run parse_date_arg "week"
    assert_success
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "parse_date_arg should handle 'month'" {
    run parse_date_arg "month"
    assert_success
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "parse_date_arg should reject empty input" {
    run parse_date_arg ""
    assert_failure
}

@test "parse_date_arg should reject invalid format" {
    run parse_date_arg "invalid"
    assert_failure
    assert_output --partial "Error: Invalid date format"
}

@test "parse_date_arg should reject invalid date values" {
    run parse_date_arg "20261301"
    assert_failure
    assert_output --partial "Error:"
}

@test "parse_date_arg should reject invalid relative format" {
    run parse_date_arg "abcd"
    assert_failure
}

# ==============================================================================
# date_to_iso_utc() Tests
# ==============================================================================

@test "date_to_iso_utc should return ISO timestamp" {
    run date_to_iso_utc "2026-01-15"
    assert_success
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]
}

@test "date_to_iso_utc should reject empty input" {
    run date_to_iso_utc ""
    assert_failure
}

# ==============================================================================
# CLI integration tests
# ==============================================================================

@test "--since flag is recognized" {
    run "$STATUSLINE_SCRIPT" --daily --since today
    assert_success
    assert_output --partial "Daily Cost Report"
}

@test "--until flag is recognized" {
    run "$STATUSLINE_SCRIPT" --daily --since yesterday --until today
    assert_success
    assert_output --partial "Daily Cost Report"
}

@test "--since without value shows error" {
    run "$STATUSLINE_SCRIPT" --daily --since
    assert_failure
    assert_output --partial "Error"
}

@test "--since with invalid date shows error" {
    run "$STATUSLINE_SCRIPT" --daily --since invalid
    assert_failure
    assert_output --partial "Error: Invalid date format"
}

@test "--since after --until shows error" {
    run "$STATUSLINE_SCRIPT" --daily --since 2026-02-07 --until 2026-01-01
    assert_failure
    assert_output --partial "Error: --since date must be before --until date"
}

@test "--since works with --weekly" {
    run "$STATUSLINE_SCRIPT" --weekly --since 7d
    assert_success
    assert_output --partial "Weekly Cost Report"
}

@test "--since works with --monthly" {
    run "$STATUSLINE_SCRIPT" --monthly --since 30d
    assert_success
    assert_output --partial "Monthly Cost Report"
}

@test "--since works with --breakdown" {
    run "$STATUSLINE_SCRIPT" --breakdown --since 7d
    assert_success
    assert_output --partial "Model Cost Breakdown"
}

@test "--since works with --instances" {
    run "$STATUSLINE_SCRIPT" --instances --since 7d
    assert_success
    assert_output --partial "Multi-Project Cost Summary"
}

@test "--help mentions --since flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--since"
}

@test "--help mentions --until flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--until"
}
