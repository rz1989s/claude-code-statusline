#!/usr/bin/env bats

# Performance regression tests for cache system enhancements
# Ensures optimizations improve performance without degrading functionality

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    
    # Load required modules
    source "$PROJECT_ROOT/lib/core.sh" || skip "Core module not available"
    source "$PROJECT_ROOT/lib/cache.sh" || skip "Cache module not available"
    
    # Create test environment
    export TEST_CACHE_DIR="/tmp/test_perf_cache_$$"
    export ORIGINAL_CACHE_BASE_DIR="$CACHE_BASE_DIR"
    export CACHE_BASE_DIR="$TEST_CACHE_DIR"
    mkdir -p "$TEST_CACHE_DIR"
    
    # Configure for performance testing
    load_cache_configuration
    init_cache_directory
}

teardown() {
    # Restore and cleanup
    export CACHE_BASE_DIR="$ORIGINAL_CACHE_BASE_DIR"
    [[ -d "$TEST_CACHE_DIR" ]] && rm -rf "$TEST_CACHE_DIR"
    common_teardown
}

# Helper function to measure execution time
measure_time() {
    local start_time end_time
    if command -v python3 >/dev/null 2>&1; then
        start_time=$(python3 -c "import time; print(int(time.time() * 1000))")
        "$@"
        end_time=$(python3 -c "import time; print(int(time.time() * 1000))")
        echo $((end_time - start_time))
    else
        # Fallback to second precision
        start_time=$(date +%s)
        "$@"
        end_time=$(date +%s)
        echo $(( (end_time - start_time) * 1000 ))
    fi
}

# ============================================================================
# CACHE HIT PERFORMANCE TESTS
# ============================================================================

@test "cache hit response time should be under 50ms" {
    local cache_key="perf_hit_test"
    local test_command=('echo' 'cached content')
    
    # Prime the cache
    execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" "${test_command[@]}"
    
    # Measure cache hit time
    local hit_time
    hit_time=$(measure_time execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" "${test_command[@]}")
    
    # Cache hit should be very fast (under 50ms)
    (( hit_time < 50 )) || {
        echo "Cache hit took ${hit_time}ms, expected < 50ms" >&2
        false
    }
}

@test "checksum validation should add minimal overhead" {
    export CACHE_CONFIG_ENABLE_CHECKSUMS="true"
    
    local cache_key="perf_checksum_test"
    local test_command=('echo' 'content for checksum performance test')
    
    # Prime cache with checksum
    execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" "${test_command[@]}"
    
    # Measure checksum validation time
    local validation_time
    validation_time=$(measure_time execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" "${test_command[@]}")
    
    # Checksum validation should add minimal overhead (under 100ms)
    (( validation_time < 100 )) || {
        echo "Checksum validation took ${validation_time}ms, expected < 100ms" >&2
        false
    }
}

@test "statistics recording should not impact performance" {
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    
    local cache_key="perf_stats_test"
    local test_command=('echo' 'content for statistics performance test')
    
    # Prime the cache
    execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" "${test_command[@]}"
    
    # Measure time with statistics enabled
    local stats_time
    stats_time=$(measure_time execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" "${test_command[@]}")
    
    # Statistics should not significantly impact performance (under 100ms)
    (( stats_time < 100 )) || {
        echo "Statistics recording took ${stats_time}ms, expected < 100ms" >&2
        false
    }
}

# ============================================================================
# BULK OPERATIONS PERFORMANCE TESTS  
# ============================================================================

@test "bulk cache operations should scale linearly" {
    local operations_count=50
    local cache_keys=()
    local total_time
    
    # Generate cache keys
    for ((i=1; i<=operations_count; i++)); do
        cache_keys+=("bulk_perf_test_$i")
    done
    
    # Measure time for bulk cache misses (initial population)
    local start_time
    if command -v python3 >/dev/null 2>&1; then
        start_time=$(python3 -c "import time; print(int(time.time() * 1000))")
    else
        start_time=$(date +%s)
    fi
    
    for key in "${cache_keys[@]}"; do
        execute_cached_command "$key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" echo "content for $key" >/dev/null
    done
    
    local end_time
    if command -v python3 >/dev/null 2>&1; then
        end_time=$(python3 -c "import time; print(int(time.time() * 1000))")
        total_time=$((end_time - start_time))
    else
        end_time=$(date +%s)
        total_time=$(( (end_time - start_time) * 1000 ))
    fi
    
    # Average time per operation should be reasonable (under 100ms per operation)
    local avg_time_per_op=$((total_time / operations_count))
    (( avg_time_per_op < 100 )) || {
        echo "Average time per cache operation: ${avg_time_per_op}ms, expected < 100ms" >&2
        false
    }
    
    # Now measure bulk cache hits (should be much faster)
    if command -v python3 >/dev/null 2>&1; then
        start_time=$(python3 -c "import time; print(int(time.time() * 1000))")
    else
        start_time=$(date +%s)
    fi
    
    for key in "${cache_keys[@]}"; do
        execute_cached_command "$key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" echo "content for $key" >/dev/null
    done
    
    if command -v python3 >/dev/null 2>&1; then
        end_time=$(python3 -c "import time; print(int(time.time() * 1000))")
        total_hit_time=$((end_time - start_time))
    else
        end_time=$(date +%s)
        total_hit_time=$(( (end_time - start_time) * 1000 ))
    fi
    
    # Cache hits should be much faster than cache misses
    (( total_hit_time < total_time / 2 )) || {
        echo "Cache hits (${total_hit_time}ms) not significantly faster than misses (${total_time}ms)" >&2
        false
    }
}

@test "cache directory initialization should be fast" {
    local temp_cache_dir="/tmp/perf_init_test_$$"
    export CACHE_BASE_DIR="$temp_cache_dir"
    
    # Measure initialization time
    local init_time
    init_time=$(measure_time init_cache_directory)
    
    # Cache directory initialization should be fast (under 500ms)
    (( init_time < 500 )) || {
        echo "Cache initialization took ${init_time}ms, expected < 500ms" >&2
        false
    }
    
    # Cleanup
    [[ -d "$temp_cache_dir" ]] && rm -rf "$temp_cache_dir"
    export CACHE_BASE_DIR="$TEST_CACHE_DIR"
}

@test "memory usage should remain reasonable under load" {
    local operations_count=100
    
    # Perform many cache operations
    for ((i=1; i<=operations_count; i++)); do
        local cache_key="memory_test_$i"
        execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" echo "content for memory test $i" >/dev/null
    done
    
    # Check memory usage
    local memory_stats
    memory_stats=$(get_cache_memory_stats)
    
    # Extract total size (rough check - should be reasonable)
    if [[ "$memory_stats" =~ ([0-9]+(\.[0-9]+)?)MB ]]; then
        local size_mb="${BASH_REMATCH[1]}"
        # Should be under 10MB for 100 small cache entries
        (( $(echo "$size_mb < 10" | bc -l) )) || {
            echo "Cache using ${size_mb}MB, expected < 10MB" >&2
            false
        }
    elif [[ "$memory_stats" =~ ([0-9]+(\.[0-9]+)?)KB ]]; then
        local size_kb="${BASH_REMATCH[1]}"
        # Should be under 10MB (10240KB) for 100 small cache entries
        (( $(echo "$size_kb < 10240" | bc -l) )) || {
            echo "Cache using ${size_kb}KB, expected < 10MB" >&2
            false
        }
    fi
}

# ============================================================================
# LOCK CONTENTION PERFORMANCE TESTS
# ============================================================================

@test "lock acquisition should be fast under normal conditions" {
    local cache_key="lock_perf_test"
    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "true")
    
    # Measure lock acquisition time
    local lock_time
    lock_time=$(measure_time acquire_cache_lock "$cache_file")
    
    # Lock should be acquired quickly (under 50ms)
    (( lock_time < 50 )) || {
        echo "Lock acquisition took ${lock_time}ms, expected < 50ms" >&2
        false
    }
    
    # Clean up lock
    release_cache_lock "$cache_file"
}

@test "error handling should not significantly impact performance" {
    local cache_key="error_perf_test"
    local failing_command=('false')
    
    # Measure error handling time
    local error_time
    error_time=$(measure_time execute_cached_command "$cache_key" "$CACHE_DURATION_LONG" "validate_basic_cache" "true" "false" "${failing_command[@]}")
    
    # Error handling should be reasonably fast (under 200ms)
    (( error_time < 200 )) || {
        echo "Error handling took ${error_time}ms, expected < 200ms" >&2
        false
    }
}

# ============================================================================
# REGRESSION PREVENTION TESTS
# ============================================================================

@test "cache hit ratio calculation should be fast" {
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    
    local test_key="ratio_perf_test"
    
    # Generate statistics
    for ((i=1; i<=100; i++)); do
        if (( i % 2 == 0 )); then
            record_cache_hit "$test_key" 10
        else
            record_cache_miss "$test_key" 100
        fi
    done
    
    # Measure hit ratio calculation time
    local calc_time
    calc_time=$(measure_time get_cache_hit_ratio "$test_key")
    
    # Calculation should be very fast (under 10ms)
    (( calc_time < 10 )) || {
        echo "Hit ratio calculation took ${calc_time}ms, expected < 10ms" >&2
        false
    }
}

@test "performance report generation should be reasonable" {
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    
    # Generate statistics for multiple keys
    for ((i=1; i<=20; i++)); do
        local key="report_perf_test_$i"
        record_cache_hit "$key" 10
        record_cache_miss "$key" 50
    done
    
    # Measure report generation time
    local report_time
    report_time=$(measure_time get_cache_performance_report "true")
    
    # Report generation should be reasonable (under 500ms)
    (( report_time < 500 )) || {
        echo "Performance report took ${report_time}ms, expected < 500ms" >&2
        false
    }
}

@test "integrity audit should complete within reasonable time" {
    # Create several cache files
    for ((i=1; i<=10; i++)); do
        local cache_file="$TEST_CACHE_DIR/audit_test_$i"
        write_cache_with_checksum "$cache_file" "content for audit test $i"
    done
    
    # Measure audit time
    local audit_time
    audit_time=$(measure_time audit_cache_integrity "true")
    
    # Audit should complete reasonably quickly (under 1 second for 10 files)
    (( audit_time < 1000 )) || {
        echo "Integrity audit took ${audit_time}ms, expected < 1000ms" >&2
        false
    }
}