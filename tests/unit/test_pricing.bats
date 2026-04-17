#!/usr/bin/env bats

# Unit tests for Claude model pricing accuracy
# Validates pricing.sh against the official Anthropic pricing table:
# https://platform.claude.com/docs/en/about-claude/pricing

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    source "$PROJECT_ROOT/lib/core.sh" || skip "Core module not available"
    source "$PROJECT_ROOT/lib/cost/pricing.sh" || skip "Pricing module not available"
}

teardown() {
    common_teardown
}

# Helper: extract Nth column from pricing string
_col() {
    local pricing="$1" col="$2"
    echo "$pricing" | awk -v c="$col" '{print $c}'
}

# ============================================================================
# FORMAT: 5-column pricing
# Format: "input output cache_write_5m cache_write_1h cache_read"
# ============================================================================

@test "pricing returns 5 space-separated columns" {
    run get_model_pricing "claude-opus-4-6-20250415"
    [[ "$status" -eq 0 ]]
    local col_count
    col_count=$(echo "$output" | awk '{print NF}')
    [[ "$col_count" == "5" ]]
}

# ============================================================================
# OPUS 4.7 - same as 4.6 ($5 / $25)
# ============================================================================

@test "Opus 4.7 bare ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-7"
    [[ "$output" == "5.00 25.00 6.25 10.00 0.50" ]]
}

@test "Opus 4.7 wildcard dated ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-7-20260416"
    [[ "$output" == "5.00 25.00 6.25 10.00 0.50" ]]
}

# ============================================================================
# OPUS 4.6 - $5 input / $25 output / 5m $6.25 / 1h $10 / read $0.50
# ============================================================================

@test "Opus 4.6 dated ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-6-20250415"
    [[ "$output" == "5.00 25.00 6.25 10.00 0.50" ]]
}

@test "Opus 4.6 bare ID (no date) returns correct pricing" {
    run get_model_pricing "claude-opus-4-6"
    [[ "$output" == "5.00 25.00 6.25 10.00 0.50" ]]
}

# ============================================================================
# OPUS 4.5 - same as 4.6
# ============================================================================

@test "Opus 4.5 dated ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-5-20251101"
    [[ "$output" == "5.00 25.00 6.25 10.00 0.50" ]]
}

@test "Opus 4.5 bare ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-5"
    [[ "$output" == "5.00 25.00 6.25 10.00 0.50" ]]
}

# ============================================================================
# OPUS 4.1 - $15 input / $75 output / 5m $18.75 / 1h $30 / read $1.50
# ============================================================================

@test "Opus 4.1 dated ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-1-20250805"
    [[ "$output" == "15.00 75.00 18.75 30.00 1.50" ]]
}

@test "Opus 4.1 bare ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-1"
    [[ "$output" == "15.00 75.00 18.75 30.00 1.50" ]]
}

# ============================================================================
# OPUS 4 - $15 input / $75 output
# ============================================================================

@test "Opus 4 dated ID returns correct pricing" {
    run get_model_pricing "claude-opus-4-20250514"
    [[ "$output" == "15.00 75.00 18.75 30.00 1.50" ]]
}

# ============================================================================
# OPUS 3 (deprecated) - $15 / $75
# ============================================================================

@test "Opus 3 returns correct pricing" {
    run get_model_pricing "claude-3-opus-20240229"
    [[ "$output" == "15.00 75.00 18.75 30.00 1.50" ]]
}

# ============================================================================
# SONNET 4.6 - $3 / $15 / 5m $3.75 / 1h $6 / read $0.30
# ============================================================================

@test "Sonnet 4.6 dated ID returns correct pricing" {
    run get_model_pricing "claude-sonnet-4-6-20250929"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

@test "Sonnet 4.6 bare ID returns correct pricing" {
    run get_model_pricing "claude-sonnet-4-6"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

# ============================================================================
# SONNET 4.5 - same as 4.6
# ============================================================================

@test "Sonnet 4.5 dated ID (Nov) returns correct pricing" {
    run get_model_pricing "claude-sonnet-4-5-20251101"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

@test "Sonnet 4.5 dated ID (Sep) returns correct pricing" {
    run get_model_pricing "claude-sonnet-4-5-20250929"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

@test "Sonnet 4.5 bare ID returns correct pricing" {
    run get_model_pricing "claude-sonnet-4-5"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

# ============================================================================
# SONNET 4 - same as 4.6
# ============================================================================

@test "Sonnet 4 returns correct pricing" {
    run get_model_pricing "claude-sonnet-4-20250514"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

# ============================================================================
# SONNET 3.7 (deprecated) - same as Sonnet 4
# ============================================================================

@test "Sonnet 3.7 returns correct pricing" {
    run get_model_pricing "claude-3-7-sonnet-20250219"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

# ============================================================================
# HAIKU 4.5 - $1 / $5 / 5m $1.25 / 1h $2 / read $0.10
# ============================================================================

@test "Haiku 4.5 dated ID (Oct) returns correct pricing" {
    run get_model_pricing "claude-haiku-4-5-20251001"
    [[ "$output" == "1.00 5.00 1.25 2.00 0.10" ]]
}

@test "Haiku 4.5 dated ID (Nov) returns correct pricing" {
    run get_model_pricing "claude-haiku-4-5-20251101"
    [[ "$output" == "1.00 5.00 1.25 2.00 0.10" ]]
}

@test "Haiku 4.5 bare ID returns correct pricing" {
    run get_model_pricing "claude-haiku-4-5"
    [[ "$output" == "1.00 5.00 1.25 2.00 0.10" ]]
}

# ============================================================================
# HAIKU 3.5 - $0.80 / $4 / 5m $1 / 1h $1.60 / read $0.08
# ============================================================================

@test "Haiku 3.5 dated ID returns correct pricing" {
    run get_model_pricing "claude-3-5-haiku-20241022"
    [[ "$output" == "0.80 4.00 1.00 1.60 0.08" ]]
}

@test "Haiku 3.5 new-format dated ID returns correct pricing" {
    run get_model_pricing "claude-haiku-3-5-20241022"
    [[ "$output" == "0.80 4.00 1.00 1.60 0.08" ]]
}

# ============================================================================
# HAIKU 3 (deprecated) - $0.25 / $1.25 / 5m $0.30 / 1h $0.50 / read $0.03
# ============================================================================

@test "Haiku 3 returns correct pricing" {
    run get_model_pricing "claude-3-haiku-20240307"
    [[ "$output" == "0.25 1.25 0.30 0.50 0.03" ]]
}

# ============================================================================
# UNKNOWN / FALLBACK - Sonnet default pricing
# ============================================================================

@test "Unknown model falls back to default (Sonnet) pricing" {
    run get_model_pricing "some-unknown-model"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

@test "Default returns Sonnet pricing" {
    run get_model_pricing "default"
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}

# ============================================================================
# get_model_price — individual component lookup
# ============================================================================

@test "get_model_price input returns column 1" {
    run get_model_price "claude-opus-4-6-20250415" "input"
    [[ "$output" == "5.00" ]]
}

@test "get_model_price output returns column 2" {
    run get_model_price "claude-opus-4-6-20250415" "output"
    [[ "$output" == "25.00" ]]
}

@test "get_model_price cache_write_5m returns column 3" {
    run get_model_price "claude-opus-4-6-20250415" "cache_write_5m"
    [[ "$output" == "6.25" ]]
}

@test "get_model_price cache_write_1h returns column 4 (new)" {
    run get_model_price "claude-opus-4-6-20250415" "cache_write_1h"
    [[ "$output" == "10.00" ]]
}

@test "get_model_price cache_read returns column 5" {
    run get_model_price "claude-opus-4-6-20250415" "cache_read"
    [[ "$output" == "0.50" ]]
}

@test "get_model_price cache_write alias returns 5m rate (backward compat)" {
    run get_model_price "claude-opus-4-6-20250415" "cache_write"
    [[ "$output" == "6.25" ]]
}

# ============================================================================
# awk block — all models covered in the inline awk table
# ============================================================================

@test "awk pricing block contains Opus 4.7 bare ID" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-opus-4-7"]'* ]]
}

@test "awk pricing block contains Opus 4.6 bare ID" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-opus-4-6"]'* ]]
}

@test "awk pricing block contains Opus 4.5 bare ID" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-opus-4-5"]'* ]]
}

@test "awk pricing block contains Sonnet 4.6 bare ID" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-sonnet-4-6"]'* ]]
}

@test "awk pricing block contains Opus 4.1" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-opus-4-1-20250805"]'* ]]
}

@test "awk pricing block contains Opus 4" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-opus-4-20250514"]'* ]]
}

@test "awk pricing block contains Haiku 3.5" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-3-5-haiku-20241022"]'* ]]
}

@test "awk pricing block contains Haiku 3" {
    run get_awk_pricing_block
    [[ "$output" == *'p["claude-3-haiku-20240307"]'* ]]
}

@test "awk pricing block entries have 5 columns" {
    run get_awk_pricing_block
    # Find any p["..."] = "..." line and verify value has 5 fields
    local line
    line=$(echo "$output" | grep 'p\["claude-opus-4-6-20250415"\]' | head -1)
    local value
    value=$(echo "$line" | sed 's/.*= "\(.*\)"/\1/')
    local nf
    nf=$(echo "$value" | awk '{print NF}')
    [[ "$nf" == "5" ]]
}

# ============================================================================
# REGRESSION: ensure previously-working IDs still work
# ============================================================================

@test "regression: Opus 4.5 and Opus 4.6 dated IDs match (same price)" {
    run get_model_pricing "claude-opus-4-5-20251101"
    local opus45="$output"
    run get_model_pricing "claude-opus-4-6-20250415"
    local opus46="$output"
    [[ "$opus45" == "$opus46" ]]
}

@test "regression: default fallback preserved" {
    run get_model_pricing ""
    [[ "$output" == "3.00 15.00 3.75 6.00 0.30" ]]
}
