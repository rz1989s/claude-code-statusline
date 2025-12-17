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

@test "--health=json outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    # Validate JSON syntax using jq
    echo "$output" | jq -e . >/dev/null
}

@test "--health-json alternative flag works" {
    run "$STATUSLINE_SCRIPT" --health-json
    assert_success
    echo "$output" | jq -e . >/dev/null
}

@test "--health=json contains status field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local status
    status=$(echo "$output" | jq -r '.status')
    [[ "$status" =~ ^(healthy|degraded|unhealthy)$ ]]
}

@test "--health=json contains version field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local version
    version=$(echo "$output" | jq -r '.version')
    [[ -n "$version" && "$version" != "null" ]]
}

@test "--health=json contains modules_loaded field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local modules_loaded
    modules_loaded=$(echo "$output" | jq -r '.modules_loaded')
    [[ "$modules_loaded" =~ ^[0-9]+$ ]]
}

@test "--health=json contains modules_failed field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local modules_failed
    modules_failed=$(echo "$output" | jq -r '.modules_failed')
    [[ "$modules_failed" =~ ^[0-9]+$ ]]
}

@test "--health=json contains dependencies object" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    echo "$output" | jq -e '.dependencies' >/dev/null
    echo "$output" | jq -e '.dependencies.bash' >/dev/null
}

@test "--health=json contains optional object" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    echo "$output" | jq -e '.optional' >/dev/null
}

@test "--health=json contains config field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local config
    config=$(echo "$output" | jq -r '.config')
    [[ -n "$config" && "$config" != "null" ]]
}

@test "--health=json contains cache field" {
    run "$STATUSLINE_SCRIPT" --health=json
    assert_success
    local cache
    cache=$(echo "$output" | jq -r '.cache')
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
