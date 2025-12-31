#!/usr/bin/env bats

# Unit tests for native Anthropic data extraction functions
# Tests Issue #99 (native cost) and Issue #103 (native cache efficiency)

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Load required dependency modules
    source "$PROJECT_ROOT/lib/core.sh" || skip "Core module not available"
    source "$PROJECT_ROOT/lib/security.sh" || skip "Security module not available"
    source "$PROJECT_ROOT/lib/cache.sh" || skip "Cache module not available"
    source "$PROJECT_ROOT/lib/config.sh" || skip "Config module not available"
    source "$PROJECT_ROOT/lib/cost.sh" || skip "Cost module not available"
}

teardown() {
    # Clean up test environment variables
    unset STATUSLINE_INPUT_JSON
    common_teardown
}

# ============================================================================
# NATIVE COST EXTRACTION TESTS (Issue #99)
# ============================================================================

@test "get_native_session_cost returns empty when no JSON input" {
    unset STATUSLINE_INPUT_JSON

    run get_native_session_cost
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "get_native_session_cost extracts cost.total_cost_usd correctly" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":0.0123}}'

    run get_native_session_cost
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0.01" ]]
}

@test "get_native_session_cost handles larger costs" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":1.2345}}'

    run get_native_session_cost
    [[ "$status" -eq 0 ]]
    [[ "$output" == "1.23" ]]
}

@test "get_native_session_cost handles zero cost" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":0}}'

    run get_native_session_cost
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0.00" ]]
}

@test "get_native_session_cost handles missing cost field" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'

    run get_native_session_cost
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "get_native_session_duration extracts duration correctly" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_duration_ms":45000}}'

    run get_native_session_duration
    [[ "$status" -eq 0 ]]
    [[ "$output" == "45000" ]]
}

@test "get_native_api_duration extracts API duration correctly" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_api_duration_ms":2300}}'

    run get_native_api_duration
    [[ "$status" -eq 0 ]]
    [[ "$output" == "2300" ]]
}

# ============================================================================
# NATIVE CACHE EFFICIENCY TESTS (Issue #103)
# ============================================================================

@test "get_native_cache_read_tokens returns 0 when no JSON input" {
    unset STATUSLINE_INPUT_JSON

    run get_native_cache_read_tokens
    [[ "$status" -eq 1 ]]
    [[ "$output" == "0" ]]
}

@test "get_native_cache_read_tokens extracts tokens correctly" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_read_input_tokens":5000}}'

    run get_native_cache_read_tokens
    [[ "$status" -eq 0 ]]
    [[ "$output" == "5000" ]]
}

@test "get_native_cache_creation_tokens extracts tokens correctly" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_creation_input_tokens":2000}}'

    run get_native_cache_creation_tokens
    [[ "$status" -eq 0 ]]
    [[ "$output" == "2000" ]]
}

@test "get_native_cache_efficiency calculates 71% correctly" {
    # 5000 / 7000 = 71.43%
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_read_input_tokens":5000,"cache_creation_input_tokens":2000}}'

    run get_native_cache_efficiency
    [[ "$status" -eq 0 ]]
    [[ "$output" == "71" ]]
}

@test "get_native_cache_efficiency calculates 100% for all reads" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_read_input_tokens":10000,"cache_creation_input_tokens":0}}'

    run get_native_cache_efficiency
    [[ "$status" -eq 0 ]]
    [[ "$output" == "100" ]]
}

@test "get_native_cache_efficiency calculates 0% for all creation" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":10000}}'

    run get_native_cache_efficiency
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0" ]]
}

@test "get_native_cache_efficiency returns 0 when no cache data" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"input_tokens":1000}}'

    run get_native_cache_efficiency
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0" ]]
}

@test "get_native_cache_efficiency handles 50/50 split" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_read_input_tokens":5000,"cache_creation_input_tokens":5000}}'

    run get_native_cache_efficiency
    [[ "$status" -eq 0 ]]
    [[ "$output" == "50" ]]
}

# ============================================================================
# HYBRID SOURCE TESTS
# ============================================================================

@test "get_session_cost_with_source returns native cost when source is native" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":0.5678}}'

    run get_session_cost_with_source "native"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0.57" ]]
}

@test "get_session_cost_with_source returns default when native unavailable" {
    unset STATUSLINE_INPUT_JSON

    run get_session_cost_with_source "native"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0.00" ]]
}

# ============================================================================
# JSON PARSING EDGE CASES
# ============================================================================

@test "native functions handle null values gracefully" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":null}}'

    run get_native_session_cost
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "native functions handle malformed JSON gracefully" {
    export STATUSLINE_INPUT_JSON='not valid json'

    run get_native_session_cost
    # Should not crash, just return empty
    [[ "$output" == "" ]]
}

@test "native cache functions handle large token counts" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"cache_read_input_tokens":11969706,"cache_creation_input_tokens":415188}}'

    run get_native_cache_efficiency
    [[ "$status" -eq 0 ]]
    # 11969706 / 12384894 = 96.6% -> rounds to 97
    [[ "$output" == "97" ]]
}

# ============================================================================
# NATIVE CODE PRODUCTIVITY TESTS (Issue #100)
# ============================================================================

@test "get_native_lines_added returns 0 when no JSON input" {
    unset STATUSLINE_INPUT_JSON

    run get_native_lines_added
    [[ "$status" -eq 1 ]]
    [[ "$output" == "0" ]]
}

@test "get_native_lines_added extracts lines correctly" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_lines_added":156}}'

    run get_native_lines_added
    [[ "$status" -eq 0 ]]
    [[ "$output" == "156" ]]
}

@test "get_native_lines_removed extracts lines correctly" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_lines_removed":23}}'

    run get_native_lines_removed
    [[ "$status" -eq 0 ]]
    [[ "$output" == "23" ]]
}

@test "get_code_productivity_display formats correctly" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_lines_added":156,"total_lines_removed":23}}'

    run get_code_productivity_display
    [[ "$status" -eq 0 ]]
    [[ "$output" == "+156/-23" ]]
}

@test "get_code_productivity_display handles zero values" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_lines_added":0,"total_lines_removed":0}}'

    run get_code_productivity_display
    [[ "$status" -eq 0 ]]
    [[ "$output" == "+0/-0" ]]
}

@test "get_code_productivity_display handles large numbers" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_lines_added":1500,"total_lines_removed":500}}'

    run get_code_productivity_display
    [[ "$status" -eq 0 ]]
    [[ "$output" == "+1500/-500" ]]
}

@test "get_native_lines_added handles missing field" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":0.01}}'

    run get_native_lines_added
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0" ]]
}

# ============================================================================
# CONTEXT WINDOW TESTS (Issue #101)
# ============================================================================

@test "get_transcript_path returns empty when no JSON input" {
    unset STATUSLINE_INPUT_JSON

    run get_transcript_path
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "get_transcript_path returns empty when transcript_path missing" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'

    run get_transcript_path
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "get_context_window_percentage returns 0 when no transcript" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'

    run get_context_window_percentage
    [[ "$status" -eq 1 ]]
    [[ "$output" == "0" ]]
}

@test "parse_transcript_last_usage returns empty for non-existent file" {
    run parse_transcript_last_usage "/nonexistent/transcript.jsonl"
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "parse_transcript_last_usage returns empty for empty path" {
    run parse_transcript_last_usage ""
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "get_context_window_display returns N/A when no data" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'

    run get_context_window_display
    [[ "$status" -eq 1 ]]
    [[ "$output" == "N/A" ]]
}

@test "CONTEXT_WINDOW_SIZE constant is set correctly" {
    [[ "$CONTEXT_WINDOW_SIZE" == "200000" ]]
}

# ============================================================================
# SESSION INFO TESTS (Issue #102)
# ============================================================================

@test "get_native_session_id returns empty when no JSON input" {
    unset STATUSLINE_INPUT_JSON

    run get_native_session_id
    [[ "$status" -eq 1 ]]
    [[ "$output" == "" ]]
}

@test "get_native_session_id extracts session_id correctly" {
    export STATUSLINE_INPUT_JSON='{"session_id":"abc12345-def6-7890-ghij-klmnopqrstuv"}'

    run get_native_session_id
    [[ "$status" -eq 0 ]]
    [[ "$output" == "abc12345-def6-7890-ghij-klmnopqrstuv" ]]
}

@test "get_short_session_id returns first 8 chars by default" {
    export STATUSLINE_INPUT_JSON='{"session_id":"abc12345-def6-7890-ghij-klmnopqrstuv"}'

    run get_short_session_id
    [[ "$status" -eq 0 ]]
    [[ "$output" == "abc12345" ]]
}

@test "get_short_session_id respects custom length" {
    export STATUSLINE_INPUT_JSON='{"session_id":"abc12345-def6-7890-ghij-klmnopqrstuv"}'

    run get_short_session_id 12
    [[ "$status" -eq 0 ]]
    [[ "$output" == "abc12345-def" ]]
}

@test "get_native_project_dir extracts workspace.project_dir" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"project_dir":"/Users/rz/local-dev/my-project"}}'

    run get_native_project_dir
    [[ "$status" -eq 0 ]]
    [[ "$output" == "/Users/rz/local-dev/my-project" ]]
}

@test "get_native_project_name returns basename of project_dir" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"project_dir":"/Users/rz/local-dev/my-project"}}'

    run get_native_project_name
    [[ "$status" -eq 0 ]]
    [[ "$output" == "my-project" ]]
}

@test "get_native_current_dir extracts workspace.current_dir" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/Users/rz/local-dev/my-project/src"}}'

    run get_native_current_dir
    [[ "$status" -eq 0 ]]
    [[ "$output" == "/Users/rz/local-dev/my-project/src" ]]
}

@test "get_session_info_display formats correctly with ID and project" {
    export STATUSLINE_INPUT_JSON='{"session_id":"abc12345-def6-7890","workspace":{"project_dir":"/Users/rz/my-project"}}'

    run get_session_info_display
    [[ "$status" -eq 0 ]]
    [[ "$output" == "abc12345 • my-project" ]]
}

@test "get_session_info_display returns empty when no data" {
    export STATUSLINE_INPUT_JSON='{}'

    run get_session_info_display
    [[ "$status" -eq 0 ]]
    [[ "$output" == "" ]]
}

@test "get_native_project_name returns empty for missing workspace" {
    export STATUSLINE_INPUT_JSON='{"session_id":"abc12345"}'

    run get_native_project_name
    [[ "$output" == "" ]]
}

# ============================================================================
# HYBRID COST SOURCE TESTS (Issue #104)
# ============================================================================

@test "get_session_cost_with_source auto prefers native when available" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":0.5678}}'

    run get_session_cost_with_source "auto"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0.57" ]]
}

@test "get_session_cost_with_source native returns native cost" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":1.2345}}'

    run get_session_cost_with_source "native"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "1.23" ]]
}

@test "get_session_cost_with_source native returns default when unavailable" {
    unset STATUSLINE_INPUT_JSON

    run get_session_cost_with_source "native"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "0.00" ]]
}

@test "get_session_cost_with_source handles empty source as auto" {
    export STATUSLINE_INPUT_JSON='{"cost":{"total_cost_usd":0.9999}}'

    run get_session_cost_with_source ""
    [[ "$status" -eq 0 ]]
    [[ "$output" == "1.00" ]]
}
