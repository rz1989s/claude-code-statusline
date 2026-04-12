#!/usr/bin/env bats

# Integration tests for pricing accuracy across the JSONL→awk cost pipeline.
# Validates end-to-end: controlled JSONL fixtures → calculate_cost_in_range
# produces the exact expected value computed against official Anthropic rates.

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    source "$PROJECT_ROOT/lib/core.sh" || skip "core"
    source "$PROJECT_ROOT/lib/security.sh" || skip "security"
    source "$PROJECT_ROOT/lib/cache.sh" || skip "cache"
    source "$PROJECT_ROOT/lib/cost/pricing.sh" || skip "pricing"
    source "$PROJECT_ROOT/lib/cost/api_live.sh" || skip "api_live"
    source "$PROJECT_ROOT/lib/cost/native_calc.sh" || skip "native_calc"

    # Isolate: point Claude projects dir at test temp dir
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/test-project"
    export STATUSLINE_TESTING=true
}

teardown() {
    common_teardown
}

# Write a JSONL assistant entry with token usage
_write_entry() {
    local file="$1" model="$2" input="$3" output="$4" cw_5m="$5" cw_1h="$6" cache_read="$7" ts="${8:-2026-04-12T10:00:00.000Z}"
    local cw_total=$((cw_5m + cw_1h))
    jq -cn --arg ts "$ts" --arg model "$model" \
        --argjson input "$input" --argjson output "$output" \
        --argjson cw_5m "$cw_5m" --argjson cw_1h "$cw_1h" \
        --argjson cw_total "$cw_total" --argjson cr "$cache_read" '
        {
          type: "assistant",
          timestamp: $ts,
          message: {
            model: $model,
            usage: {
              input_tokens: $input,
              output_tokens: $output,
              cache_creation_input_tokens: $cw_total,
              cache_creation: {
                ephemeral_5m_input_tokens: $cw_5m,
                ephemeral_1h_input_tokens: $cw_1h
              },
              cache_read_input_tokens: $cr
            }
          }
        }' >> "$file"
}

# ============================================================================
# OPUS 4.6 bare ID - should use $5/$25 pricing (regression for the main bug)
# ============================================================================

@test "Opus 4.6 bare ID: 1M input tokens → \$5.00" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-opus-4-6" 1000000 0 0 0 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "5.00" ]]
}

@test "Opus 4.6 bare ID: 1M output tokens → \$25.00" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-opus-4-6" 0 1000000 0 0 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "25.00" ]]
}

@test "Opus 4.6 bare ID: 1M cache read → \$0.50" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-opus-4-6" 0 0 0 0 1000000
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "0.50" ]]
}

# ============================================================================
# 5m vs 1h cache write tier distinction
# ============================================================================

@test "Opus 4.6: 1M 5-minute cache write → \$6.25 (1.25x input)" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-opus-4-6" 0 0 1000000 0 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "6.25" ]]
}

@test "Opus 4.6: 1M 1-hour cache write → \$10.00 (2x input)" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-opus-4-6" 0 0 0 1000000 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "10.00" ]]
}

@test "Opus 4.6: mixed 5m + 1h cache → sum of 1.25x + 2x" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    # 400k @ 5m ($2.50) + 600k @ 1h ($6.00) = $8.50 (rounding-safe)
    _write_entry "$f" "claude-opus-4-6" 0 0 400000 600000 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "8.50" ]]
}

# ============================================================================
# Legacy fallback: no nested cache_creation, flat cache_creation_input_tokens
# (older JSONL entries without the ephemeral split)
# ============================================================================

@test "legacy flat cache_creation_input_tokens → treated as 5m writes" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/legacy.jsonl"
    # Hand-write entry WITHOUT nested cache_creation object (older format)
    cat > "$f" <<EOF
{"type":"assistant","timestamp":"2026-04-12T10:00:00.000Z","message":{"model":"claude-opus-4-6","usage":{"input_tokens":0,"output_tokens":0,"cache_creation_input_tokens":1000000,"cache_read_input_tokens":0}}}
EOF
    run calculate_cost_in_range "2026-04-01T00:00:00"
    # Should fall back to 5m rate: 1M * $6.25/MTok = $6.25
    [[ "$output" == "6.25" ]]
}

# ============================================================================
# Older model regressions (previously fell through to Sonnet default)
# ============================================================================

@test "Opus 4.1: correctly priced at \$15/\$75 (not \$3/\$15 default)" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-opus-4-1-20250805" 1000000 0 0 0 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "15.00" ]]
}

@test "Haiku 3.5: correctly priced at \$0.80/\$4 (not \$3/\$15 default)" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-3-5-haiku-20241022" 1000000 0 0 0 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "0.80" ]]
}

@test "Haiku 3: correctly priced at \$0.25/\$1.25 (not default)" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    _write_entry "$f" "claude-3-haiku-20240307" 1000000 0 0 0 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "0.25" ]]
}

# ============================================================================
# Realistic mixed session — all components combined
# ============================================================================

@test "mixed realistic session: input + output + 5m + 1h + read" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    # Opus 4.6 bare: 100k input ($0.50) + 50k output ($1.25) +
    #                200k cw_5m ($1.25) + 300k cw_1h ($3.00) +
    #                500k cache_read ($0.25)
    # Total: $0.50 + $1.25 + $1.25 + $3.00 + $0.25 = $6.25
    _write_entry "$f" "claude-opus-4-6" 100000 50000 200000 300000 500000
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "6.25" ]]
}

# ============================================================================
# Multiple entries, different models
# ============================================================================

@test "two sessions (Opus + Sonnet) sum correctly" {
    local f="$CLAUDE_CONFIG_DIR/projects/test-project/session1.jsonl"
    # Opus 4.6: 1M output = $25.00
    _write_entry "$f" "claude-opus-4-6" 0 1000000 0 0 0
    # Sonnet 4.6: 1M output = $15.00
    _write_entry "$f" "claude-sonnet-4-6" 0 1000000 0 0 0
    run calculate_cost_in_range "2026-04-01T00:00:00"
    [[ "$output" == "40.00" ]]
}
