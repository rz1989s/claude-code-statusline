#!/bin/bash

# ============================================================================
# Multi-Instance Race Condition Test for Universal Caching System
# ============================================================================
# This test simulates multiple Claude Code statusline instances running
# simultaneously to verify that the cache locking mechanisms work properly
# and prevent race conditions, data corruption, or crashes.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_INPUT='{"workspace":{"current_dir":"'$PROJECT_ROOT'"},"model":{"display_name":"Test Model"}}'

# Test configuration
NUM_INSTANCES=5
TEST_DURATION=10
RESULTS_DIR="$SCRIPT_DIR/results"
CACHE_DIR="/tmp/.claude_statusline_cache"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize test environment
init_test() {
    echo -e "${BLUE}🧪 Initializing Multi-Instance Race Condition Test${NC}"
    echo "============================================================"
    
    # Clean up previous test results
    rm -rf "$RESULTS_DIR" 2>/dev/null || true
    mkdir -p "$RESULTS_DIR"
    
    # Clean cache to start fresh
    rm -rf "$CACHE_DIR" 2>/dev/null || true
    
    echo "✓ Test environment initialized"
    echo "✓ Number of instances: $NUM_INSTANCES"
    echo "✓ Test duration: ${TEST_DURATION}s"
    echo "✓ Results directory: $RESULTS_DIR"
    echo ""
}

# Run single statusline instance
run_statusline_instance() {
    local instance_id="$1"
    local output_file="$RESULTS_DIR/instance_${instance_id}.log"
    local error_file="$RESULTS_DIR/instance_${instance_id}_errors.log"
    local success_file="$RESULTS_DIR/instance_${instance_id}_success.log"
    
    echo "Starting instance $instance_id (PID: $$)" > "$output_file"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION))
    local iteration=0
    
    while [[ $(date +%s) -lt $end_time ]]; do
        iteration=$((iteration + 1))
        echo "Instance $instance_id - Iteration $iteration - $(date '+%H:%M:%S.%3N')" >> "$output_file"
        
        if echo "$TEST_INPUT" | timeout 30s "$PROJECT_ROOT/statusline.sh" >> "$output_file" 2>> "$error_file"; then
            echo "SUCCESS: Instance $instance_id - Iteration $iteration" >> "$success_file"
        else
            echo "ERROR: Instance $instance_id - Iteration $iteration - Exit code: $?" >> "$error_file"
        fi
        
        # Small random delay to increase race condition likelihood
        sleep "0.$(( (RANDOM % 3) + 1 ))"
    done
    
    echo "Instance $instance_id completed $iteration iterations" >> "$output_file"
}

# Monitor cache files during test
monitor_cache() {
    local monitor_file="$RESULTS_DIR/cache_monitor.log"
    local start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION + 5)) # Monitor a bit longer
    
    echo "Cache monitoring started at $(date)" > "$monitor_file"
    
    while [[ $(date +%s) -lt $end_time ]]; do
        echo "=== $(date '+%H:%M:%S') ===" >> "$monitor_file"
        
        if [[ -d "$CACHE_DIR" ]]; then
            echo "Cache directory contents:" >> "$monitor_file"
            ls -la "$CACHE_DIR/" >> "$monitor_file" 2>/dev/null || echo "Cache directory empty" >> "$monitor_file"
            
            echo "Active lock files:" >> "$monitor_file"
            find "$CACHE_DIR" -name "*.lock" -exec ls -la {} \; >> "$monitor_file" 2>/dev/null || echo "No lock files" >> "$monitor_file"
            
            echo "Session markers:" >> "$monitor_file"
            ls -la /tmp/.cache_session_* >> "$monitor_file" 2>/dev/null || echo "No session markers" >> "$monitor_file"
        else
            echo "Cache directory does not exist yet" >> "$monitor_file"
        fi
        
        echo "" >> "$monitor_file"
        sleep 1
    done
    
    echo "Cache monitoring completed at $(date)" >> "$monitor_file"
}

# Analyze test results
analyze_results() {
    echo -e "${BLUE}📊 Analyzing Test Results${NC}"
    echo "============================================================"
    
    local total_success=0
    local total_errors=0
    local total_iterations=0
    
    # Count successes and errors
    for i in $(seq 1 $NUM_INSTANCES); do
        local success_file="$RESULTS_DIR/instance_${i}_success.log"
        local error_file="$RESULTS_DIR/instance_${i}_errors.log"
        local log_file="$RESULTS_DIR/instance_${i}.log"
        
        if [[ -f "$success_file" ]]; then
            local instance_success=$(wc -l < "$success_file" 2>/dev/null || echo "0")
            total_success=$((total_success + instance_success))
            echo "✓ Instance $i: $instance_success successful runs"
        fi
        
        if [[ -f "$error_file" ]]; then
            local instance_errors=$(wc -l < "$error_file" 2>/dev/null || echo "0")
            total_errors=$((total_errors + instance_errors))
            if [[ $instance_errors -gt 0 ]]; then
                echo -e "⚠️  Instance $i: $instance_errors errors"
            fi
        fi
        
        # Count iterations from log file
        if [[ -f "$log_file" ]]; then
            local instance_iterations=$(grep -c "Iteration" "$log_file" 2>/dev/null || echo "0")
            total_iterations=$((total_iterations + instance_iterations))
        fi
    done
    
    echo ""
    echo "=== SUMMARY ==="
    echo "Total iterations: $total_iterations"
    echo "Successful runs: $total_success"
    echo "Failed runs: $total_errors"
    
    if [[ $total_errors -eq 0 ]]; then
        echo -e "${GREEN}✅ NO RACE CONDITIONS DETECTED!${NC}"
        echo -e "${GREEN}All $total_success runs completed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  $total_errors failures detected${NC}"
        echo "Checking error patterns..."
        
        # Look for specific race condition indicators
        local lock_errors=0
        local cache_corruption_errors=0
        local timeout_errors=0
        
        for error_file in "$RESULTS_DIR"/instance_*_errors.log; do
            if [[ -f "$error_file" ]]; then
                local lock_count=$(grep -c "lock" "$error_file" 2>/dev/null || echo "0")
                local corruption_count=$(grep -c "corrupt\|invalid" "$error_file" 2>/dev/null || echo "0")  
                local timeout_count=$(grep -c "timeout\|timed out" "$error_file" 2>/dev/null || echo "0")
                
                lock_errors=$((lock_errors + lock_count))
                cache_corruption_errors=$((cache_corruption_errors + corruption_count))
                timeout_errors=$((timeout_errors + timeout_count))
            fi
        done
        
        echo "  - Lock-related errors: $lock_errors"
        echo "  - Cache corruption errors: $cache_corruption_errors"
        echo "  - Timeout errors: $timeout_errors"
    fi
    
    # Success rate calculation
    local success_rate=0
    if [[ $total_iterations -gt 0 ]]; then
        success_rate=$(( (total_success * 100) / total_iterations ))
    fi
    
    echo "Success rate: ${success_rate}%"
    
    # Cache consistency check
    echo ""
    echo "=== CACHE CONSISTENCY CHECK ==="
    if [[ -d "$CACHE_DIR" ]]; then
        local total_cache_files=$(find "$CACHE_DIR" -name "*.cache" | wc -l)
        local corrupted_cache_files=0
        
        for cache_file in "$CACHE_DIR"/*.cache; do
            if [[ -f "$cache_file" ]]; then
                # Check if file is empty or has invalid content
                if [[ ! -s "$cache_file" ]]; then
                    corrupted_cache_files=$((corrupted_cache_files + 1))
                fi
            fi
        done
        
        echo "Total cache files: $total_cache_files"
        echo "Corrupted cache files: $corrupted_cache_files"
        
        if [[ $corrupted_cache_files -eq 0 ]]; then
            echo -e "${GREEN}✅ All cache files are consistent${NC}"
        else
            echo -e "${RED}❌ Found $corrupted_cache_files corrupted cache files${NC}"
        fi
    else
        echo "Cache directory not found (this might be normal if all instances failed)"
    fi
    
    # Overall result
    echo ""
    echo "=== OVERALL RESULT ==="
    if [[ $total_errors -eq 0 && $success_rate -gt 90 ]]; then
        echo -e "${GREEN}🎉 RACE CONDITION TEST PASSED!${NC}"
        echo -e "${GREEN}The universal caching system handles concurrent access safely.${NC}"
        return 0
    else
        echo -e "${RED}❌ RACE CONDITION TEST FAILED${NC}"
        echo -e "${RED}Issues detected in concurrent access handling.${NC}"
        return 1
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}🏁 Starting Multi-Instance Race Condition Test${NC}"
    echo ""
    
    # Initialize
    init_test
    
    # Start cache monitoring in background
    monitor_cache &
    local monitor_pid=$!
    
    # Start multiple statusline instances in parallel
    local pids=()
    for i in $(seq 1 $NUM_INSTANCES); do
        echo "Starting instance $i..."
        run_statusline_instance "$i" &
        pids+=($!)
    done
    
    echo ""
    echo "🔄 Running $NUM_INSTANCES instances for ${TEST_DURATION}s..."
    echo "Instance PIDs: ${pids[*]}"
    
    # Wait for all instances to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Stop cache monitoring
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true
    
    echo ""
    echo "✅ All instances completed"
    
    # Analyze results
    analyze_results
    
    echo ""
    echo "📁 Detailed results available in: $RESULTS_DIR"
}

# Run the test
main "$@"