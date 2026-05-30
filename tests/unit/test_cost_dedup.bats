#!/usr/bin/env bats

# ============================================================================
# Cost de-duplication tests
# ============================================================================
# Claude Code re-logs the SAME assistant API response into transcripts on
# session resume, compaction, and subagent sidechains — each copy carries the
# original usage block. Anthropic bills each response (message.id) once, so
# summing every JSONL occurrence overcounts cost/tokens (observed 6-20x in the
# wild). Cost calculations must deduplicate by (message.id, requestId).
# ============================================================================

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    source "$PROJECT_ROOT/lib/core.sh" || skip "core not available"
    source "$PROJECT_ROOT/lib/security.sh" || skip "security not available"
    source "$PROJECT_ROOT/lib/cache.sh" || skip "cache not available"
    source "$PROJECT_ROOT/lib/config.sh" || skip "config not available"
    source "$PROJECT_ROOT/lib/cost.sh" || skip "cost not available"

    # Isolated fake projects dir so cost functions never touch real transcripts
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-proj"
    TEST_JSONL="$CLAUDE_CONFIG_DIR/projects/-test-proj/session.jsonl"
}

teardown() {
    unset COMPONENT_USAGE_FIVE_HOUR_RESET
    common_teardown
}

# Write one assistant entry. Args: msg_id req_id uuid output_tokens timestamp [input_tokens]
_entry() {
    local input="${6:-0}"
    printf '{"type":"assistant","timestamp":"%s","requestId":"%s","uuid":"%s","message":{"id":"%s","model":"claude-opus-4-8","usage":{"input_tokens":%s,"output_tokens":%s,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}\n' \
        "$5" "$2" "$3" "$1" "$input" "$4"
}

# Write one assistant entry WITHOUT a message.id. Args: req_id uuid output_tokens timestamp
_entry_noid() {
    printf '{"type":"assistant","timestamp":"%s","requestId":"%s","uuid":"%s","message":{"model":"claude-opus-4-8","usage":{"input_tokens":0,"output_tokens":%s,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}\n' \
        "$4" "$1" "$2" "$3"
}

# Cross-platform "now minus N minutes" as UTC ISO-8601 (with millis + Z)
_utc_iso_minutes_ago() {
    local m="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -u -v-"${m}"M +%Y-%m-%dT%H:%M:%S.000Z
    else
        date -u -d "$m minutes ago" +%Y-%m-%dT%H:%M:%S.000Z
    fi
}

# ----------------------------------------------------------------------------
# calculate_cost_in_range (REPO/DAY/7DAY/30DAY foundation)
# ----------------------------------------------------------------------------

@test "calculate_cost_in_range counts a duplicated message.id only once" {
    # Opus 4.8 output = \$25/M. msg_A is logged TWICE (resume/sidechain copy),
    # msg_B once. Correct cost = 2 unique x 1M output x \$25 = \$50.00
    {
        _entry msg_A req_A uuid_1 1000000 "2026-05-30T01:00:00.000Z"
        _entry msg_A req_A uuid_2 1000000 "2026-05-30T01:00:00.000Z"
        _entry msg_B req_B uuid_3 1000000 "2026-05-30T01:05:00.000Z"
    } > "$TEST_JSONL"

    run calculate_cost_in_range "2026-05-30T00:00:00"
    [ "$status" -eq 0 ]
    [ "$output" = "50.00" ]
}

@test "calculate_cost_in_range keeps distinct messages with same requestId" {
    # Same requestId can appear on different responses; the message.id differs,
    # so both must count: 2 x \$25 = \$50.00
    {
        _entry msg_A req_SHARED uuid_1 1000000 "2026-05-30T01:00:00.000Z"
        _entry msg_B req_SHARED uuid_2 1000000 "2026-05-30T01:01:00.000Z"
    } > "$TEST_JSONL"

    run calculate_cost_in_range "2026-05-30T00:00:00"
    [ "$status" -eq 0 ]
    [ "$output" = "50.00" ]
}

@test "calculate_cost_in_range does not over-dedupe entries missing message.id" {
    # No message.id -> cannot prove duplication -> fall back to per-line uuid,
    # so two distinct uuids both count: 2 x \$25 = \$50.00 (never collapse to \$25)
    {
        _entry_noid req_A uuid_1 1000000 "2026-05-30T01:00:00.000Z"
        _entry_noid req_B uuid_2 1000000 "2026-05-30T01:01:00.000Z"
    } > "$TEST_JSONL"

    run calculate_cost_in_range "2026-05-30T00:00:00"
    [ "$status" -eq 0 ]
    [ "$output" = "50.00" ]
}

# ----------------------------------------------------------------------------
# calculate_window_tokens (burn rate + projection token counts)
# ----------------------------------------------------------------------------

@test "calculate_window_tokens dedupes duplicated responses in the 5h window" {
    # Window = resets_at - 5h. Put reset 1h ahead so window started 4h ago.
    export COMPONENT_USAGE_FIVE_HOUR_RESET="$(( $(date +%s) + 3600 ))"

    local ts1 ts2
    ts1="$(_utc_iso_minutes_ago 10)"
    ts2="$(_utc_iso_minutes_ago 9)"
    {
        _entry msg_A req_A uuid_1 1000000 "$ts1" 500000
        _entry msg_A req_A uuid_2 1000000 "$ts1" 500000   # duplicate
        _entry msg_B req_B uuid_3 1000000 "$ts2" 500000
    } > "$TEST_JSONL"

    # total:input:output:cache_read:cache_write — 2 unique entries:
    # output = 2,000,000 ; input = 1,000,000 ; total = 3,000,000
    run calculate_window_tokens
    [ "$status" -eq 0 ]
    local output_tokens
    output_tokens=$(echo "$output" | cut -d: -f3)
    [ "$output_tokens" = "2000000" ]
}
