#!/usr/bin/env bats
# ==============================================================================
# Test: Enhanced --json export functionality (Issue #205)
# ==============================================================================
# Tests the enhanced JSON export with schema v2.0, --compact flag,
# and multi-arg CLI parser.

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

# Helper function to extract JSON from output (handles any prefix/suffix noise)
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

# ==============================================================================
# Basic JSON output tests
# ==============================================================================

@test "--json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--json --compact outputs single-line JSON" {
    run "$STATUSLINE_SCRIPT" --json --compact
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    # Compact JSON should be a single line (no newlines inside the JSON object)
    local line_count
    line_count=$(echo "$json_output" | wc -l | tr -d ' ')
    [[ "$line_count" -eq 1 ]]
}

# ==============================================================================
# Schema v2.0 field tests
# ==============================================================================

@test "--json contains schema_version 2.0" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local schema_version
    schema_version=$(echo "$json_output" | jq -r '.schema_version')
    [[ "$schema_version" == "2.0" ]]
}

@test "--json contains version field" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local version
    version=$(echo "$json_output" | jq -r '.version')
    [[ -n "$version" && "$version" != "null" ]]
}

@test "--json contains timestamp fields" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    local timestamp
    timestamp=$(echo "$json_output" | jq -r '.timestamp')
    [[ "$timestamp" =~ ^[0-9]+$ ]]
    local timestamp_iso
    timestamp_iso=$(echo "$json_output" | jq -r '.timestamp_iso')
    [[ "$timestamp_iso" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]
}

@test "--json contains project object" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.project' >/dev/null
    echo "$json_output" | jq -e '.project.name' >/dev/null
    echo "$json_output" | jq -e '.project.path' >/dev/null
    echo "$json_output" | jq -e '.project.branch' >/dev/null
}

@test "--json contains cost object with numeric values" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.cost' >/dev/null
    echo "$json_output" | jq -e '.cost.currency' >/dev/null
    # Verify cost values are numbers
    local daily
    daily=$(echo "$json_output" | jq -r '.cost.daily')
    [[ "$daily" =~ ^[0-9]+\.?[0-9]*$ ]]
}

@test "--json contains mcp object" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.mcp' >/dev/null
    echo "$json_output" | jq -e '.mcp.connected' >/dev/null
    echo "$json_output" | jq -e '.mcp.total' >/dev/null
    echo "$json_output" | jq -e '.mcp.servers' >/dev/null
}

@test "--json contains system object" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.system' >/dev/null
    echo "$json_output" | jq -e '.system.theme' >/dev/null
    echo "$json_output" | jq -e '.system.modules_loaded' >/dev/null
    echo "$json_output" | jq -e '.system.platform' >/dev/null
}

@test "--json contains context_window object" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.context_window' >/dev/null
    echo "$json_output" | jq -e '.context_window.used_percentage' >/dev/null
    echo "$json_output" | jq -e '.context_window.size' >/dev/null
}

@test "--json contains session object" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.session' >/dev/null
    echo "$json_output" | jq -e '.session.cost_usd' >/dev/null
}

# ==============================================================================
# Exit code tests
# ==============================================================================

@test "--json returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --json
    assert_success
}

@test "--json --compact returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --json --compact
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --json flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--json"
}

@test "--help mentions --compact flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--compact"
}

@test "--help mentions REPORTS section" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "REPORTS:"
}

# ==============================================================================
# Backward compatibility tests
# ==============================================================================

@test "existing --health flag still works" {
    run "$STATUSLINE_SCRIPT" --health
    assert_success
    assert_output --partial "Health Check"
}

@test "existing --health=json flag still works" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.status' >/dev/null
}

@test "existing --metrics flag still works" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.timestamp' >/dev/null
}

@test "existing --metrics=prometheus flag still works" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
    assert_output --partial "# HELP"
}

@test "unknown flags still produce error" {
    run "$STATUSLINE_SCRIPT" --invalid-flag
    assert_failure
    assert_output --partial "Unknown option"
}
