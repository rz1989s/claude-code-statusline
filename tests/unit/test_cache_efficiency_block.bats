#!/usr/bin/env bats

# ============================================================================
# cache_efficiency component: block-based, de-duplicated
# ============================================================================
# The cache_efficiency component represents cache hit rate for the current
# 5-hour billing block (consistent with LIVE / burn_rate / block_projection).
# It must derive from the de-duplicated window tokens, NOT the current turn's
# native current_usage (which can read 0% right after a cache-creation turn).
# ============================================================================

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    source "$PROJECT_ROOT/lib/core.sh" || skip "core not available"
    source "$PROJECT_ROOT/lib/security.sh" || skip "security not available"
    source "$PROJECT_ROOT/lib/cache.sh" || skip "cache not available"
    source "$PROJECT_ROOT/lib/json_fields.sh" || skip "json_fields not available"
    source "$PROJECT_ROOT/lib/config.sh" || skip "config not available"
    source "$PROJECT_ROOT/lib/cost.sh" || skip "cost not available"

    # Stub component registration so the component file sources standalone
    register_component() { return 0; }
    source "$PROJECT_ROOT/lib/components/cache_efficiency.sh" || skip "component not available"

    # Satisfy the `is_module_loaded "cost"` guard
    STATUSLINE_MODULES_LOADED=("cost")

    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-proj"
    TEST_JSONL="$CLAUDE_CONFIG_DIR/projects/-test-proj/session.jsonl"
}

teardown() {
    unset COMPONENT_USAGE_FIVE_HOUR_RESET STATUSLINE_INPUT_JSON
    common_teardown
}

# id req uuid cache_read cache_creation ts
_cache_entry() {
    printf '{"type":"assistant","timestamp":"%s","requestId":"%s","uuid":"%s","message":{"id":"%s","model":"claude-opus-4-8","usage":{"input_tokens":0,"output_tokens":0,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s}}}\n' \
        "$6" "$2" "$3" "$1" "$5" "$4"
}

_utc_iso_minutes_ago() {
    local m="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        date -u -v-"${m}"M +%Y-%m-%dT%H:%M:%S.000Z
    else
        date -u -d "$m minutes ago" +%Y-%m-%dT%H:%M:%S.000Z
    fi
}

@test "cache_efficiency reflects the deduped 5h block, not the current turn" {
    export COMPONENT_USAGE_FIVE_HOUR_RESET="$(( $(date +%s) + 3600 ))"

    # Current turn (native) would report 0% — must NOT be used.
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":1000,"input_tokens":10}}}'

    local ts; ts="$(_utc_iso_minutes_ago 10)"
    # Block: cache_read 900000, cache_write 100000 => 90% hit.
    # The duplicate copy must not skew the ratio.
    {
        _cache_entry msg_A req_A uuid_1 900000 100000 "$ts"
        _cache_entry msg_A req_A uuid_2 900000 100000 "$ts"
    } > "$TEST_JSONL"

    collect_cache_efficiency_data
    [ "$COMPONENT_CACHE_EFFICIENCY_INFO" = "Cache: 90% hit" ]
}

@test "cache_efficiency falls back to native current-turn when no active block" {
    # No reset info -> no window -> fall back to native current_usage (75%).
    unset COMPONENT_USAGE_FIVE_HOUR_RESET
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"cache_read_input_tokens":3000,"cache_creation_input_tokens":1000}}}'
    : > "$TEST_JSONL"

    collect_cache_efficiency_data
    [ "$COMPONENT_CACHE_EFFICIENCY_INFO" = "Cache: 75% hit" ]
}
