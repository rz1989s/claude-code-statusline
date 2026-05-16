#!/usr/bin/env bats
# ==============================================================================
# Test: Zero-day backfill in --weekly and --monthly reports
# ==============================================================================
# Verifies that inactive days within the report period appear as $0 rows
# instead of being silently skipped. This makes the daily calendar continuous
# and prevents readers from mistaking missing dates for a rendering bug.

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/test-project"
}

teardown() {
    common_teardown
}

# Helper: extract JSON object from output
_extract_json() {
    local in_json=false
    local json_lines=""
    while IFS= read -r line; do
        if [[ "$line" == "{"* ]]; then
            in_json=true
        fi
        if [[ "$in_json" == "true" ]]; then
            json_lines+="$line"
        fi
        if [[ "$line" == "}" ]]; then
            break
        fi
    done <<< "$1"
    echo "$json_lines"
}

# Helper: write a JSONL entry for a given date (YYYY-MM-DD) at noon UTC
_write_jsonl_entry() {
    local jsonl_path="$1" date="$2"
    local model="${3:-claude-sonnet-4-5-20251022}"
    cat >> "$jsonl_path" <<EOF
{"type":"assistant","timestamp":"${date}T12:00:00Z","message":{"model":"$model","usage":{"input_tokens":1000,"output_tokens":500,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}
EOF
}

# Helper: get a date N days ago (YYYY-MM-DD) - cross-platform
_date_n_days_ago() {
    local n="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -v-${n}d +%Y-%m-%d
    else
        date -d "${n} days ago" +%Y-%m-%d
    fi
}

# ==============================================================================
# Weekly report (7 days)
# ==============================================================================

@test "--weekly --json emits 7 day entries when only 1 day has data" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    # Only 1 day (3 days ago) has activity
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 3)"

    run "$STATUSLINE_SCRIPT" --weekly --json < /dev/null
    assert_success

    local json_output days_count
    json_output=$(_extract_json "$output")
    days_count=$(echo "$json_output" | jq -r '.days | length')
    [[ "$days_count" -eq 7 ]] || { echo "Expected 7 days, got $days_count. JSON: $json_output"; return 1; }
}

@test "--weekly --json zero days have sessions=0 and cost_usd=0" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 3)"

    run "$STATUSLINE_SCRIPT" --weekly --json < /dev/null
    assert_success

    local json_output zero_days_count
    json_output=$(_extract_json "$output")
    # Count entries where sessions == 0 and cost_usd == 0
    zero_days_count=$(echo "$json_output" | jq -r '[.days[] | select(.sessions == 0 and .cost_usd == 0)] | length')
    [[ "$zero_days_count" -eq 6 ]] || { echo "Expected 6 zero days, got $zero_days_count. JSON: $json_output"; return 1; }
}

@test "--weekly --json days are sorted chronologically" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 5)"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 1)"

    run "$STATUSLINE_SCRIPT" --weekly --json < /dev/null
    assert_success

    local json_output sorted_check
    json_output=$(_extract_json "$output")
    # Verify ascending date order
    sorted_check=$(echo "$json_output" | jq -r '[.days[].date] | . == sort')
    [[ "$sorted_check" == "true" ]] || { echo "Days not chronologically sorted. JSON: $json_output"; return 1; }
}

@test "--weekly human-readable shows zero-activity day with \$0.00" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    local missing_day
    missing_day="$(_date_n_days_ago 2)"
    # Activity on other days, but not on `missing_day`
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 5)"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 1)"

    run "$STATUSLINE_SCRIPT" --weekly < /dev/null
    assert_success
    # The missing day's date should appear in the table with $0.00
    [[ "$output" == *"$missing_day"* ]] || { echo "Expected $missing_day in output. Got: $output"; return 1; }
}

@test "--weekly with no data at all keeps 'No usage data' message" {
    # Empty projects dir, no JSONL files
    run "$STATUSLINE_SCRIPT" --weekly < /dev/null
    assert_success
    [[ "$output" == *"No usage data"* ]] || { echo "Expected 'No usage data' for empty input. Got: $output"; return 1; }
}

@test "--weekly --csv emits 7 rows when only 1 day has data" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 3)"

    run "$STATUSLINE_SCRIPT" --weekly --csv < /dev/null
    assert_success
    # Count rows containing a date (excludes header which has no digits)
    local data_rows
    data_rows=$(echo "$output" | grep -cE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
    [[ "$data_rows" -eq 7 ]] || { echo "Expected 7 CSV data rows, got $data_rows. Output: $output"; return 1; }
}

# ==============================================================================
# Monthly report (30 days)
# ==============================================================================

@test "--monthly --json emits 30 day entries when only 2 days have data" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 5)"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 15)"

    run "$STATUSLINE_SCRIPT" --monthly --json < /dev/null
    assert_success

    local json_output days_count
    json_output=$(_extract_json "$output")
    days_count=$(echo "$json_output" | jq -r '.days | length')
    [[ "$days_count" -eq 30 ]] || { echo "Expected 30 days, got $days_count. JSON: $json_output"; return 1; }
}

@test "--monthly --json active_days reflects only days with sessions > 0" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 5)"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 15)"

    run "$STATUSLINE_SCRIPT" --monthly --json < /dev/null
    assert_success

    local json_output active_days
    json_output=$(_extract_json "$output")
    active_days=$(echo "$json_output" | jq -r '.summary.active_days')
    [[ "$active_days" -eq 2 ]] || { echo "Expected active_days=2, got $active_days. JSON: $json_output"; return 1; }
}

@test "--monthly human-readable shows Active Days less than 30 when gaps exist" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 3)"

    run "$STATUSLINE_SCRIPT" --monthly < /dev/null
    assert_success
    # Should display "Active Days: 1 / 30" (only one day has activity)
    [[ "$output" == *"Active Days:    1 / 30"* ]] || { echo "Expected 'Active Days: 1 / 30'. Got: $output"; return 1; }
}

@test "--monthly --csv emits 30 rows when only 2 days have data" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 5)"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 15)"

    run "$STATUSLINE_SCRIPT" --monthly --csv < /dev/null
    assert_success

    # Count rows containing a date (excludes header which has no digits)
    local data_rows
    data_rows=$(echo "$output" | grep -cE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
    [[ "$data_rows" -eq 30 ]] || { echo "Expected 30 CSV data rows, got $data_rows. Output: $output"; return 1; }
}

# ==============================================================================
# Edge cases: no-gaps, custom ranges, model preservation
# ==============================================================================

@test "--weekly with data on every day still emits exactly 7 rows" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    # Activity on all 7 days
    for n in 0 1 2 3 4 5 6; do
        _write_jsonl_entry "$jsonl" "$(_date_n_days_ago $n)"
    done

    run "$STATUSLINE_SCRIPT" --weekly --json < /dev/null
    assert_success

    local json_output days_count active_days
    json_output=$(_extract_json "$output")
    days_count=$(echo "$json_output" | jq -r '.days | length')
    [[ "$days_count" -eq 7 ]] || { echo "Expected 7 days, got $days_count"; return 1; }
    # All 7 should be active
    active_days=$(echo "$json_output" | jq -r '[.days[] | select(.sessions > 0)] | length')
    [[ "$active_days" -eq 7 ]] || { echo "Expected 7 active days, got $active_days"; return 1; }
}

@test "--weekly --since custom range backfills inactive days" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    # Data only on day 3 of a 5-day custom window
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 3)"

    local since until
    since="$(_date_n_days_ago 5)"
    until="$(_date_n_days_ago 1)"
    run "$STATUSLINE_SCRIPT" --weekly --since "$since" --until "$until" --json < /dev/null
    assert_success

    local json_output days_count
    json_output=$(_extract_json "$output")
    days_count=$(echo "$json_output" | jq -r '.days | length')
    # 5-day inclusive window
    [[ "$days_count" -eq 5 ]] || { echo "Expected 5 days (since..until inclusive), got $days_count. JSON: $json_output"; return 1; }
}

@test "--weekly model data still present alongside zero-day rows" {
    local jsonl="$CLAUDE_CONFIG_DIR/projects/test-project/session.jsonl"
    _write_jsonl_entry "$jsonl" "$(_date_n_days_ago 2)" "claude-opus-4-7"

    run "$STATUSLINE_SCRIPT" --weekly --json < /dev/null
    assert_success

    local json_output models_count
    json_output=$(_extract_json "$output")
    models_count=$(echo "$json_output" | jq -r '.models | length')
    [[ "$models_count" -ge 1 ]] || { echo "Expected at least 1 model entry, got $models_count"; return 1; }
}
