#!/usr/bin/env bats
# ==============================================================================
# Test: JSON Field Access Abstraction Layer
# ==============================================================================
# Tests the JSON field abstraction layer that provides path migration
# for Claude Code v2.1.66 schema changes (current_usage moved under
# context_window).

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ==============================================================================
# get_json_field: basic extraction
# ==============================================================================

@test "get_json_field extracts simple top-level field" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    run get_json_field "version"
    assert_success
    assert_output "2.1.66"
}

@test "get_json_field extracts nested field with dot notation" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus","id":"claude-opus-4-6"}}'
    run get_json_field "model.display_name"
    assert_success
    assert_output "Opus"
}

@test "get_json_field returns default when field missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    run get_json_field "version" "unknown"
    assert_success
    assert_output "unknown"
}

@test "get_json_field returns empty string when field missing and no default" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    run get_json_field "nonexistent"
    assert_success
    assert_output ""
}

@test "get_json_field handles null JSON values" {
    export STATUSLINE_INPUT_JSON='{"version":null}'
    run get_json_field "version" "fallback"
    assert_success
    assert_output "fallback"
}

@test "get_json_field handles empty STATUSLINE_INPUT_JSON" {
    export STATUSLINE_INPUT_JSON=""
    run get_json_field "version" "none"
    assert_success
    assert_output "none"
}

# ==============================================================================
# get_json_field: path migration (current_usage -> context_window.current_usage)
# ==============================================================================

@test "get_json_field migrates current_usage to context_window.current_usage (new path)" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"input_tokens":8500}}}'
    run get_json_field "current_usage.input_tokens"
    assert_success
    assert_output "8500"
}

@test "get_json_field falls back to legacy current_usage path" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"input_tokens":7000}}'
    run get_json_field "current_usage.input_tokens"
    assert_success
    assert_output "7000"
}

@test "get_json_field prefers new path over legacy" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"input_tokens":9000}},"current_usage":{"input_tokens":5000}}'
    run get_json_field "current_usage.input_tokens"
    assert_success
    assert_output "9000"
}

@test "get_json_field migrates cache_read_input_tokens" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"cache_read_input_tokens":3000}}}'
    run get_json_field "current_usage.cache_read_input_tokens"
    assert_success
    assert_output "3000"
}

@test "get_json_field migrates cache_creation_input_tokens" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"cache_creation_input_tokens":2000}}}'
    run get_json_field "current_usage.cache_creation_input_tokens"
    assert_success
    assert_output "2000"
}

# ==============================================================================
# has_json_field
# ==============================================================================

@test "has_json_field returns 0 when field exists" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    run has_json_field "version"
    assert_success
}

@test "has_json_field returns 1 when field missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    run has_json_field "version"
    assert_failure
}

@test "has_json_field returns 1 for null field" {
    export STATUSLINE_INPUT_JSON='{"version":null}'
    run has_json_field "version"
    assert_failure
}

@test "has_json_field detects nested fields" {
    export STATUSLINE_INPUT_JSON='{"vim":{"mode":"NORMAL"}}'
    run has_json_field "vim.mode"
    assert_success
}

# ==============================================================================
# validate_json_schema / get_detected_cc_version
# ==============================================================================

@test "validate_json_schema detects Claude Code version" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66","workspace":{"current_dir":"/tmp"}}'
    validate_json_schema
    run get_detected_cc_version
    assert_success
    assert_output "2.1.66"
}

@test "validate_json_schema returns unknown for missing version" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'
    validate_json_schema
    run get_detected_cc_version
    assert_success
    assert_output "unknown"
}

# ==============================================================================
# get_json_field_bool
# ==============================================================================

@test "get_json_field_bool returns true for true boolean" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":true}'
    run get_json_field_bool "exceeds_200k_tokens"
    assert_success
    assert_output "true"
}

@test "get_json_field_bool returns false for false boolean" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":false}'
    run get_json_field_bool "exceeds_200k_tokens"
    assert_success
    assert_output "false"
}

@test "get_json_field_bool returns default for missing field" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    run get_json_field_bool "exceeds_200k_tokens" "false"
    assert_success
    assert_output "false"
}

# ==============================================================================
# get_json_field_num
# ==============================================================================

@test "get_json_field_num returns numeric value" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"total_input_tokens":15234}}'
    run get_json_field_num "context_window.total_input_tokens"
    assert_success
    assert_output "15234"
}

@test "get_json_field_num returns default for missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    run get_json_field_num "context_window.total_input_tokens" "0"
    assert_success
    assert_output "0"
}

# ==============================================================================
# Typed extractors: path migration
# ==============================================================================

@test "has_json_field detects migrated path in new schema" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"input_tokens":8500}}}'
    run has_json_field "current_usage.input_tokens"
    assert_success
}

@test "has_json_field detects migrated path in legacy schema" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"input_tokens":7000}}'
    run has_json_field "current_usage.input_tokens"
    assert_success
}

@test "get_json_field_num extracts migrated path from new schema" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"input_tokens":8500}}}'
    run get_json_field_num "current_usage.input_tokens" "0"
    assert_success
    assert_output "8500"
}

@test "get_json_field_num falls back to legacy path" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"input_tokens":7000}}'
    run get_json_field_num "current_usage.input_tokens" "0"
    assert_success
    assert_output "7000"
}

@test "get_json_field_bool resolves migrated boolean path" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"is_cached":true}}}'
    run get_json_field_bool "current_usage.is_cached" "false"
    assert_success
    assert_output "true"
}

@test "get_json_field_bool falls back to legacy boolean path" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"is_cached":false}}'
    run get_json_field_bool "current_usage.is_cached" "true"
    assert_success
    assert_output "false"
}
