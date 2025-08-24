#!/usr/bin/env bats

# Integration tests for cache system enhancements
# Tests end-to-end cache behavior with all enhancements enabled

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    
    # Load all required modules
    source "$PROJECT_ROOT/lib/core.sh" || skip "Core module not available"
    source "$PROJECT_ROOT/lib/cache.sh" || skip "Cache module not available"
    
    # Create temporary test environment
    export TEST_CACHE_DIR="/tmp/test_integration_cache_$$"
    export ORIGINAL_CACHE_BASE_DIR="$CACHE_BASE_DIR"
    export CACHE_BASE_DIR="$TEST_CACHE_DIR"
    mkdir -p "$TEST_CACHE_DIR"
    
    # Enable all cache features for integration testing
    export CACHE_CONFIG_ENABLE_UNIVERSAL="true"
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    export CACHE_CONFIG_ENABLE_CHECKSUMS="true"
    export CACHE_CONFIG_VALIDATE_ON_READ="true"
    export CACHE_CONFIG_CLEANUP_STALE="true"
    export CACHE_CONFIG_MIGRATE_LEGACY="true"
    
    # Initialize cache system
    load_cache_configuration
    init_cache_directory
}

teardown() {
    # Restore original configuration
    export CACHE_BASE_DIR="$ORIGINAL_CACHE_BASE_DIR"
    
    # Cleanup test environment
    [[ -d "$TEST_CACHE_DIR" ]] && rm -rf "$TEST_CACHE_DIR"
    
    common_teardown
}

# ============================================================================
# END-TO-END CACHE WORKFLOW TESTS
# ============================================================================

@test "complete cache workflow with checksums and statistics" {
    local cache_key="integration_test_key"
    local test_command=('echo' 'test output for integration')
    
    # Clear any existing statistics
    clear_cache_stats
    
    # First call should be a cache miss
    local output1
    output1=$(execute_cached_command "$cache_key" "$CACHE_DURATION_SHORT" "validate_basic_cache" "true" "false" "${test_command[@]}")
    
    [[ "$output1" == "test output for integration" ]]
    [[ ${CACHE_STATS_MISSES["$cache_key"]} -eq 1 ]]
    [[ ${CACHE_STATS_TOTAL_CALLS["$cache_key"]} -eq 1 ]]
    
    # Second call should be a cache hit
    local output2
    output2=$(execute_cached_command "$cache_key" "$CACHE_DURATION_SHORT" "validate_basic_cache" "true" "false" "${test_command[@]}")
    
    [[ "$output2" == "test output for integration" ]]
    [[ ${CACHE_STATS_HITS["$cache_key"]} -eq 1 ]]
    [[ ${CACHE_STATS_TOTAL_CALLS["$cache_key"]} -eq 2 ]]
    
    # Verify cache file has checksum protection
    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "true")
    [[ -f "$cache_file" ]]
    grep -q "# Cache Integrity Checksum:" "$cache_file"
}

@test "cache recovery from corruption" {
    local cache_key="corruption_recovery_test"
    local test_command=('echo' 'original content')
    
    # Create initial cache
    execute_cached_command "$cache_key" "$CACHE_DURATION_SHORT" "validate_basic_cache" "true" "false" "${test_command[@]}"
    
    # Get cache file path and corrupt it
    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "true")
    
    # Corrupt the content while keeping checksum header
    sed -i.bak 's/original content/corrupted content/' "$cache_file"
    
    # Next call should detect corruption and regenerate cache
    local output
    output=$(execute_cached_command "$cache_key" "$CACHE_DURATION_SHORT" "validate_basic_cache" "true" "false" "${test_command[@]}")
    
    [[ "$output" == "original content" ]]
    
    # Verify cache was regenerated with correct content
    local recovered_content
    recovered_content=$(read_cache_with_checksum "$cache_file" "true")
    [[ "$recovered_content" == "original content" ]]
}

@test "XDG cache directory migration during operation" {
    # Create legacy cache with some content
    local legacy_dir="/tmp/test_legacy_integration_$$"
    mkdir -p "$legacy_dir"
    
    # Simulate legacy cache files
    echo "legacy_content_1" > "$legacy_dir/legacy_key_1"
    echo "legacy_content_2" > "$legacy_dir/legacy_key_2"
    
    # Set up for migration
    export LEGACY_CACHE_DIR="$legacy_dir"
    
    # Initialize cache directory (should trigger migration)
    init_cache_directory
    
    # Verify migration occurred
    [[ -f "$TEST_CACHE_DIR/legacy_key_1" ]]
    [[ -f "$TEST_CACHE_DIR/legacy_key_2" ]]
    [[ "$(cat "$TEST_CACHE_DIR/legacy_key_1")" == "legacy_content_1" ]]
    [[ "$(cat "$TEST_CACHE_DIR/legacy_key_2")" == "legacy_content_2" ]]
    
    # Cleanup
    rm -rf "$legacy_dir"
}

@test "performance monitoring across multiple operations" {
    local keys=("perf_test_1" "perf_test_2" "perf_test_3")
    local commands=(
        'echo "output 1"'
        'echo "output 2"' 
        'echo "output 3"'
    )
    
    clear_cache_stats
    
    # Generate cache misses
    for i in "${!keys[@]}"; do
        eval "execute_cached_command '${keys[$i]}' '$CACHE_DURATION_SHORT' 'validate_basic_cache' 'true' 'false' ${commands[$i]}"
    done
    
    # Generate cache hits
    for i in "${!keys[@]}"; do
        eval "execute_cached_command '${keys[$i]}' '$CACHE_DURATION_SHORT' 'validate_basic_cache' 'true' 'false' ${commands[$i]}"
    done
    
    # Verify statistics
    for key in "${keys[@]}"; do
        [[ ${CACHE_STATS_HITS["$key"]} -eq 1 ]]
        [[ ${CACHE_STATS_MISSES["$key"]} -eq 1 ]]
        [[ ${CACHE_STATS_TOTAL_CALLS["$key"]} -eq 2 ]]
        
        local hit_ratio
        hit_ratio=$(get_cache_hit_ratio "$key")
        [[ "$hit_ratio" == "50.00" ]]
    done
    
    # Test performance report generation
    local report
    report=$(get_cache_performance_report "false")
    
    [[ "$report" =~ "Overall Performance:" ]]
    [[ "$report" =~ "Total Operations: 6" ]]
    [[ "$report" =~ "Cache Hits: 3" ]]
    [[ "$report" =~ "Cache Misses: 3" ]]
}

@test "error handling and recovery workflows" {
    local cache_key="error_recovery_test"
    
    # Test with failing command
    local failing_command=('false')  # Command that always fails
    
    clear_cache_stats
    
    # Should record error and not crash
    run execute_cached_command "$cache_key" "$CACHE_DURATION_SHORT" "validate_basic_cache" "true" "false" "${failing_command[@]}"
    
    # Verify error was recorded
    [[ ${CACHE_STATS_ERRORS["$cache_key"]} -eq 1 ]]
    [[ ${CACHE_STATS_TOTAL_CALLS["$cache_key"]} -eq 1 ]]
}

@test "resource cleanup after interruption simulation" {
    local cache_key="cleanup_test"
    local test_command=('echo' 'content for cleanup test')
    
    # Start cache operation
    execute_cached_command "$cache_key" "$CACHE_DURATION_SHORT" "validate_basic_cache" "true" "false" "${test_command[@]}"
    
    # Get cache file and create some temporary files to simulate interruption
    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "true")
    local temp_file1="${cache_file}.tmp.$$"
    local temp_file2="${cache_file}.migrating"
    
    echo "temp content 1" > "$temp_file1"
    echo "temp content 2" > "$temp_file2"
    
    # Register for cleanup
    register_temp_file "$temp_file1"
    register_temp_file "$temp_file2"
    
    # Simulate cleanup
    cleanup_cache_resources
    
    # Verify temp files were cleaned up
    [[ ! -f "$temp_file1" ]]
    [[ ! -f "$temp_file2" ]]
}

@test "cache integrity audit functionality" {
    # Create mix of protected and legacy cache files
    local protected_file="$TEST_CACHE_DIR/protected_test"
    local legacy_file="$TEST_CACHE_DIR/legacy_test"
    
    # Create protected cache file
    write_cache_with_checksum "$protected_file" "protected content"
    
    # Create legacy cache file
    echo "legacy content" > "$legacy_file"
    
    # Run integrity audit
    local audit_output
    audit_output=$(audit_cache_integrity "false")
    
    [[ "$audit_output" =~ "Cache Integrity Audit" ]]
    [[ "$audit_output" =~ "Total Cache Files: 2" ]]
    [[ "$audit_output" =~ "Checksum Protected: 1" ]]
    [[ "$audit_output" =~ "Legacy Files: 1" ]]
}

@test "configuration loading and application" {
    # Test environment variable override
    export ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING="false"
    export ENV_CONFIG_CACHE_SECURITY_ENABLE_CHECKSUMS="false"
    
    # Reload configuration
    load_cache_configuration
    
    # Verify configuration was applied
    [[ -z "$CACHE_CONFIG_ENABLE_UNIVERSAL" ]]
    [[ -z "$CACHE_CONFIG_ENABLE_CHECKSUMS" ]]
    
    # Test cache operation with checksums disabled
    local cache_key="no_checksum_test"
    local test_command=('echo' 'no checksum content')
    
    execute_cached_command "$cache_key" "$CACHE_DURATION_SHORT" "validate_basic_cache" "true" "false" "${test_command[@]}"
    
    # Verify cache file doesn't have checksum protection
    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "true")
    
    ! grep -q "# Cache Integrity Checksum:" "$cache_file"
    
    # Cleanup environment variables
    unset ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING
    unset ENV_CONFIG_CACHE_SECURITY_ENABLE_CHECKSUMS
}

@test "memory usage statistics accuracy" {
    # Create several cache files of known sizes
    local test_files=("mem_test_1" "mem_test_2" "mem_test_3")
    local test_content="This is test content for memory usage calculation"
    
    for file in "${test_files[@]}"; do
        local cache_file="$TEST_CACHE_DIR/$file"
        echo "$test_content" > "$cache_file"
    done
    
    # Get memory statistics
    local memory_stats
    memory_stats=$(get_cache_memory_stats)
    
    [[ "$memory_stats" =~ "Cache Memory Usage" ]]
    [[ "$memory_stats" =~ "Cache Files: 3" ]]
    [[ "$memory_stats" =~ "Total Size:" ]]
}

@test "git branch validation in real cache operations" {
    if ! command -v git >/dev/null 2>&1; then
        skip "Git not available for integration testing"
    fi
    
    local cache_key="git_branch_test"
    
    # Create cache file with valid branch name
    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "true")
    echo "main" > "$cache_file"
    
    # Test validation through cache system
    run validate_cache_with_checksum "$cache_file" "git_branch"
    [[ $status -eq 0 ]]
    
    # Test with invalid branch name
    echo "invalid..branch" > "$cache_file"
    run validate_cache_with_checksum "$cache_file" "git_branch"
    [[ $status -eq 1 ]]
}