#!/usr/bin/env bats
# ==============================================================================
# Test: --health flag functionality
# ==============================================================================
# Tests the health check diagnostic output for both human-readable and JSON formats.

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
# Human-readable output tests
# ==============================================================================

@test "--health flag outputs human-readable format" {
    run "$STATUSLINE_SCRIPT" --health
    assert_success
    assert_output --partial "Claude Code Statusline Health Check"
    assert_output --partial "Status:"
    assert_output --partial "Dependencies:"
    assert_output --partial "Modules:"
}

@test "--health shows bash version" {
    run "$STATUSLINE_SCRIPT" --health
    assert_success
    assert_output --partial "bash"
}

@test "--health shows jq version when available" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    run "$STATUSLINE_SCRIPT" --health
    assert_success
    assert_output --partial "jq"
}

@test "--health shows module count" {
    run "$STATUSLINE_SCRIPT" --health
    assert_success
    # Should show "X loaded, Y failed" format
    assert_output --partial "loaded"
}

@test "--health shows config status" {
    run "$STATUSLINE_SCRIPT" --health
    assert_success
    assert_output --partial "Config:"
}

@test "--health shows cache status" {
    run "$STATUSLINE_SCRIPT" --health
    assert_success
    assert_output --partial "Cache:"
}

# ==============================================================================
# JSON output tests
# ==============================================================================

# Helper function to extract JSON from output (handles any prefix/suffix noise)
_extract_json() {
    # Find lines starting from { to the last } - handles multiline JSON
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

@test "--health=json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    # Extract JSON and validate syntax
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--health-json alternative flag works" {
    run "$STATUSLINE_SCRIPT" --health-json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    [[ -n "$json_output" ]] || { echo "No JSON found in output: $output"; return 1; }
    echo "$json_output" | jq -e . >/dev/null
}

@test "--health=json contains status field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output status
    json_output=$(_extract_json "$output")
    status=$(echo "$json_output" | jq -r '.status')
    [[ "$status" =~ ^(healthy|degraded|unhealthy)$ ]]
}

@test "--health=json contains version field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output version
    json_output=$(_extract_json "$output")
    version=$(echo "$json_output" | jq -r '.version')
    [[ -n "$version" && "$version" != "null" ]]
}

@test "--health=json contains modules_loaded field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output modules_loaded
    json_output=$(_extract_json "$output")
    modules_loaded=$(echo "$json_output" | jq -r '.modules_loaded')
    [[ "$modules_loaded" =~ ^[0-9]+$ ]]
}

@test "--health=json contains modules_failed field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output modules_failed
    json_output=$(_extract_json "$output")
    modules_failed=$(echo "$json_output" | jq -r '.modules_failed')
    [[ "$modules_failed" =~ ^[0-9]+$ ]]
}

@test "--health=json contains dependencies object" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.dependencies' >/dev/null
    echo "$json_output" | jq -e '.dependencies.bash' >/dev/null
}

@test "--health=json contains optional object" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output
    json_output=$(_extract_json "$output")
    echo "$json_output" | jq -e '.optional' >/dev/null
}

@test "--health=json contains config field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output config
    json_output=$(_extract_json "$output")
    config=$(echo "$json_output" | jq -r '.config')
    [[ -n "$config" && "$config" != "null" ]]
}

@test "--health=json contains cache field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local json_output cache
    json_output=$(_extract_json "$output")
    cache=$(echo "$json_output" | jq -r '.cache')
    [[ -n "$cache" && "$cache" != "null" ]]
}

# ==============================================================================
# Exit code tests
# ==============================================================================

@test "--health returns exit code 0 when healthy" {
    run "$STATUSLINE_SCRIPT" --health
    assert_success
}

@test "--health=json returns exit code 0 when healthy" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --health flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--health"
}

@test "--help mentions --health=json flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--health=json"
}
