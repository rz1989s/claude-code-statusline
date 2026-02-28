#!/usr/bin/env bats
# ==============================================================================
# Test: CSV export functionality (Issue #218)
# ==============================================================================
# Tests CSV output format for all report commands including:
# - csv_escape_field() RFC 4180 compliance
# - format_as_csv() generic formatter
# - --csv flag integration with CLI reports
# - Help text mentions --csv

# Load test helpers
load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    # Point to empty projects dir to avoid scanning real JSONL files
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects"
}

teardown() {
    common_teardown
}

# ==============================================================================
# csv_escape_field() tests
# ==============================================================================

@test "csv_escape_field: plain text passes through unchanged" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(csv_escape_field "hello")
    assert_equal "hello" "$result"
}

@test "csv_escape_field: field with comma is quoted" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(csv_escape_field "hello, world")
    assert_equal '"hello, world"' "$result"
}

@test "csv_escape_field: field with double quote is escaped and quoted" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(csv_escape_field 'say "hello"')
    assert_equal '"say ""hello"""' "$result"
}

@test "csv_escape_field: empty string passes through" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(csv_escape_field "")
    assert_equal "" "$result"
}

@test "csv_escape_field: numeric value passes through" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(csv_escape_field "42.50")
    assert_equal "42.50" "$result"
}

@test "csv_escape_field: field with both comma and quote" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(csv_escape_field 'cost is $5.00, or "free"')
    assert_equal '"cost is $5.00, or ""free"""' "$result"
}

# ==============================================================================
# format_as_csv() tests
# ==============================================================================

@test "format_as_csv: outputs header line" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(echo "" | format_as_csv "col1,col2,col3")
    first_line=$(echo "$result" | head -1)
    assert_equal "col1,col2,col3" "$first_line"
}

@test "format_as_csv: converts tab-delimited input to CSV" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    input=$(printf 'alpha\tbeta\tgamma\n')
    result=$(echo "$input" | format_as_csv "a,b,c")
    second_line=$(echo "$result" | sed -n '2p')
    assert_equal "alpha,beta,gamma" "$second_line"
}

@test "format_as_csv: escapes fields with commas" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    input=$(printf 'hello, world\t42\tok\n')
    result=$(echo "$input" | format_as_csv "text,num,status")
    second_line=$(echo "$result" | sed -n '2p')
    assert_equal '"hello, world",42,ok' "$second_line"
}

@test "format_as_csv: handles empty input (header only)" {
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh"
    result=$(echo "" | format_as_csv "a,b,c")
    line_count=$(echo "$result" | wc -l | tr -d ' ')
    # Should have header + possibly one empty-field line from the empty input
    [[ "$line_count" -le 2 ]]
}

# ==============================================================================
# --csv flag CLI tests
# ==============================================================================

@test "--help mentions --csv" {
    run "$STATUSLINE_SCRIPT" --help < /dev/null
    assert_success
    assert_output --partial "--csv"
}

@test "--help mentions OUTPUT FORMAT section" {
    run "$STATUSLINE_SCRIPT" --help < /dev/null
    assert_success
    assert_output --partial "OUTPUT FORMAT"
}

@test "--daily --csv outputs CSV header" {
    run "$STATUSLINE_SCRIPT" --daily --csv < /dev/null
    assert_success
    first_line=$(echo "$output" | head -1)
    assert_equal "date,day,sessions,cost_usd,tokens" "$first_line"
}

@test "--daily --csv returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --daily --csv < /dev/null
    assert_success
}

@test "--weekly --csv outputs CSV header" {
    run "$STATUSLINE_SCRIPT" --weekly --csv < /dev/null
    assert_success
    first_line=$(echo "$output" | head -1)
    assert_equal "week_start,week_end,date,day,sessions,cost_usd" "$first_line"
}

@test "--monthly --csv outputs CSV header" {
    run "$STATUSLINE_SCRIPT" --monthly --csv < /dev/null
    assert_success
    first_line=$(echo "$output" | head -1)
    assert_equal "month,date,day,sessions,cost_usd" "$first_line"
}

@test "--breakdown --csv outputs CSV header" {
    run "$STATUSLINE_SCRIPT" --breakdown --csv < /dev/null
    assert_success
    first_line=$(echo "$output" | head -1)
    assert_equal "model,sessions,cost_usd,tokens,share_pct" "$first_line"
}

@test "--instances --csv outputs CSV header" {
    run "$STATUSLINE_SCRIPT" --instances --csv < /dev/null
    assert_success
    first_line=$(echo "$output" | head -1)
    assert_equal "project,sessions,cost_usd,tokens,share_pct" "$first_line"
}

@test "--burn-rate --csv outputs CSV header" {
    run "$STATUSLINE_SCRIPT" --burn-rate --csv < /dev/null
    assert_success
    first_line=$(echo "$output" | head -1)
    assert_equal "metric,value" "$first_line"
}

@test "--burn-rate --csv outputs metric rows" {
    run "$STATUSLINE_SCRIPT" --burn-rate --csv < /dev/null
    assert_success
    assert_output --partial "total_cost_usd"
    assert_output --partial "cost_per_hour"
    assert_output --partial "tokens_per_minute"
}

@test "--daily --csv does not contain ASCII table separators" {
    run "$STATUSLINE_SCRIPT" --daily --csv < /dev/null
    assert_success
    refute_output --partial "═"
    refute_output --partial "─"
    refute_output --partial "│"
}

@test "--breakdown --csv does not contain ASCII table separators" {
    run "$STATUSLINE_SCRIPT" --breakdown --csv < /dev/null
    assert_success
    refute_output --partial "═"
    refute_output --partial "─"
}

@test "--burn-rate --csv has expected row count" {
    run "$STATUSLINE_SCRIPT" --burn-rate --csv < /dev/null
    assert_success
    # Header + 8 metric rows = 9 lines
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    assert_equal "9" "$line_count"
}
