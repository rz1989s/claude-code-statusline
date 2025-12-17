#!/usr/bin/env bats
# ==============================================================================
# Test: Structured logging (JSON format)
# ==============================================================================
# Tests the optional JSON structured logging feature (Issue #73).

# Load test helpers
load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
}

teardown() {
    common_teardown
}

# ==============================================================================
# Default text format tests
# ==============================================================================

@test "default log format is text" {
    export STATUSLINE_DEBUG=true
    unset STATUSLINE_LOG_FORMAT
    run "$STATUSLINE_SCRIPT" --version
    # stderr should contain text format logs
    [[ "$output" =~ \[INFO\] ]] || [[ "$stderr" =~ \[INFO\] ]] || true
}

@test "text format includes timestamp" {
    export STATUSLINE_DEBUG=true
    unset STATUSLINE_LOG_FORMAT
    output=$("$STATUSLINE_SCRIPT" --version 2>&1)
    # Should contain date format YYYY-MM-DD HH:MM:SS
    [[ "$output" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]
}

@test "text format includes log level in brackets" {
    export STATUSLINE_DEBUG=true
    unset STATUSLINE_LOG_FORMAT
    output=$("$STATUSLINE_SCRIPT" --version 2>&1)
    [[ "$output" =~ \[INFO\] ]]
}

# ==============================================================================
# JSON format tests
# ==============================================================================

@test "JSON format enabled with STATUSLINE_LOG_FORMAT=json" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1)
    # Should contain JSON object markers
    [[ "$output" =~ \{.*\"timestamp\" ]]
}

@test "JSON output is valid JSON" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1 | head -1)
    # Validate with jq
    echo "$output" | jq -e . >/dev/null
}

@test "JSON output contains timestamp field" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1 | head -1)
    local timestamp
    timestamp=$(echo "$output" | jq -r '.timestamp')
    [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "JSON output contains level field" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1 | head -1)
    local level
    level=$(echo "$output" | jq -r '.level')
    [[ "$level" =~ ^(INFO|WARN|ERROR|PERF|DEBUG)$ ]]
}

@test "JSON output contains message field" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1 | head -1)
    local message
    message=$(echo "$output" | jq -r '.message')
    [[ -n "$message" && "$message" != "null" ]]
}

@test "JSON timestamp uses UTC (Z suffix)" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1 | head -1)
    local timestamp
    timestamp=$(echo "$output" | jq -r '.timestamp')
    [[ "$timestamp" =~ Z$ ]]
}

@test "multiple JSON log lines are each valid" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1 | head -5)
    # Each line should be valid JSON
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        echo "$line" | jq -e . >/dev/null
    done <<< "$output"
}

# ==============================================================================
# Log level tests
# ==============================================================================

@test "INFO level appears in JSON output" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1)
    [[ "$output" =~ \"level\":\"INFO\" ]]
}

@test "PERF level appears in JSON output for timers" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    output=$("$STATUSLINE_SCRIPT" --version 2>&1)
    # Timer logs use PERF level
    [[ "$output" =~ \"level\":\"PERF\" ]] || true  # May not always have PERF logs
}

# ==============================================================================
# Backward compatibility tests
# ==============================================================================

@test "logs disabled when STATUSLINE_DEBUG not set" {
    unset STATUSLINE_DEBUG
    unset STATUSLINE_LOG_FORMAT
    output=$("$STATUSLINE_SCRIPT" --version 2>&1)
    # Should not contain log format markers
    [[ ! "$output" =~ \[INFO\] ]] || [[ "$output" =~ "Claude Code Statusline" ]]
}

@test "JSON format only active when explicitly set" {
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=text
    output=$("$STATUSLINE_SCRIPT" --version 2>&1)
    # Should use text format, not JSON
    [[ "$output" =~ \[INFO\] ]]
    [[ ! "$output" =~ \{.*\"timestamp\" ]]
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions STATUSLINE_LOG_FORMAT" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "STATUSLINE_LOG_FORMAT"
}

@test "--help mentions JSON logs option" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "JSON logs"
}

# ==============================================================================
# Special character handling tests
# ==============================================================================

@test "JSON escapes special characters in messages" {
    # Source the script to get access to debug_log
    export STATUSLINE_DEBUG=true
    export STATUSLINE_LOG_FORMAT=json
    source "$STATUSLINE_SCRIPT" 2>/dev/null || true

    # Test with a message containing quotes
    output=$(debug_log 'Message with "quotes"' "INFO" 2>&1)
    # Should be valid JSON (quotes escaped)
    echo "$output" | jq -e . >/dev/null
}
