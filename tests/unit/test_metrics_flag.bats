#!/usr/bin/env bats
# ==============================================================================
# Test: --metrics flag functionality
# ==============================================================================
# Tests the metrics export output for both JSON and Prometheus formats.

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
# JSON output tests
# ==============================================================================

@test "--metrics flag outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    echo "$output" | jq -e . >/dev/null
}

@test "--metrics=json flag outputs valid JSON" {
    run "$STATUSLINE_SCRIPT" --metrics=json
    assert_success
    echo "$output" | jq -e . >/dev/null
}

@test "--metrics JSON contains timestamp field" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    local timestamp
    timestamp=$(echo "$output" | jq -r '.timestamp')
    [[ "$timestamp" =~ ^[0-9]+$ ]]
}

@test "--metrics JSON contains version field" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    local version
    version=$(echo "$output" | jq -r '.version')
    [[ -n "$version" && "$version" != "null" ]]
}

@test "--metrics JSON contains modules object" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    echo "$output" | jq -e '.modules' >/dev/null
    echo "$output" | jq -e '.modules.loaded' >/dev/null
    echo "$output" | jq -e '.modules.failed' >/dev/null
}

@test "--metrics JSON modules.loaded is a number" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    local loaded
    loaded=$(echo "$output" | jq -r '.modules.loaded')
    [[ "$loaded" =~ ^[0-9]+$ ]]
}

@test "--metrics JSON contains cache object" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    echo "$output" | jq -e '.cache' >/dev/null
    echo "$output" | jq -e '.cache.hits' >/dev/null
    echo "$output" | jq -e '.cache.misses' >/dev/null
    echo "$output" | jq -e '.cache.hit_rate_percent' >/dev/null
}

@test "--metrics JSON contains components object" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
    echo "$output" | jq -e '.components' >/dev/null
    echo "$output" | jq -e '.components.enabled' >/dev/null
    echo "$output" | jq -e '.components.total' >/dev/null
}

# ==============================================================================
# Prometheus output tests
# ==============================================================================

@test "--metrics=prometheus outputs Prometheus format" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
    assert_output --partial "# HELP"
    assert_output --partial "# TYPE"
}

@test "--metrics=prom short alias works" {
    run "$STATUSLINE_SCRIPT" --metrics=prom
    assert_success
    assert_output --partial "statusline_modules_loaded"
}

@test "--metrics=prometheus contains statusline_info metric" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
    assert_output --partial "statusline_info"
    assert_output --partial "gauge"
}

@test "--metrics=prometheus contains modules metrics" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
    assert_output --partial "statusline_modules_loaded"
    assert_output --partial "statusline_modules_failed"
}

@test "--metrics=prometheus contains cache metrics" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
    assert_output --partial "statusline_cache_hits_total"
    assert_output --partial "statusline_cache_misses_total"
    assert_output --partial "statusline_cache_hit_rate"
    assert_output --partial "statusline_cache_size_bytes"
    assert_output --partial "statusline_cache_file_count"
}

@test "--metrics=prometheus contains component metrics" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
    assert_output --partial "statusline_components_enabled"
    assert_output --partial "statusline_components_total"
}

@test "--metrics=prometheus has correct metric types" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
    # Counters for cumulative values
    assert_output --partial "# TYPE statusline_cache_hits_total counter"
    assert_output --partial "# TYPE statusline_cache_misses_total counter"
    # Gauges for point-in-time values
    assert_output --partial "# TYPE statusline_modules_loaded gauge"
    assert_output --partial "# TYPE statusline_cache_hit_rate gauge"
}

# ==============================================================================
# Error handling tests
# ==============================================================================

@test "--metrics with invalid format returns error" {
    run "$STATUSLINE_SCRIPT" --metrics=invalid
    assert_failure
    # Invalid format treated as unknown option at CLI level
    assert_output --partial "Unknown option"
}

# ==============================================================================
# Exit code tests
# ==============================================================================

@test "--metrics returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --metrics
    assert_success
}

@test "--metrics=prometheus returns exit code 0" {
    run "$STATUSLINE_SCRIPT" --metrics=prometheus
    assert_success
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --metrics flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--metrics"
}

@test "--help mentions --metrics=prometheus flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--metrics=prometheus"
}
