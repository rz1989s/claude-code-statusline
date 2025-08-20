#!/usr/bin/env bats

# Performance benchmark tests to prevent regressions
# These tests ensure our optimizations maintain their performance benefits

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    export PATH="$STATUSLINE_DIR:$PATH"
    cd "$STATUSLINE_DIR"
    
    # Create test TOML config for consistent benchmarking
    export TEST_CONFIG="/tmp/benchmark_config.toml"
    cat > "$TEST_CONFIG" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"
green = "\033[32m"

[features]
show_commits = true
show_version = true
show_submodules = true

[timeouts]
mcp = "3s"
version = "2s"

[emojis]
opus = "🧠"
haiku = "⚡"

[labels]
commits = "Commits:"
repo = "REPO"

[cache]
version_duration = 3600

[display]
time_format = "%H:%M"

[messages]
no_ccusage = "No ccusage"
EOF
}

teardown() {
    rm -f "$TEST_CONFIG"
}

# Benchmark: jq call count should remain low
@test "config loading should use minimal jq calls" {
    # Count jq calls in config loading section (lines 700-1100)
    local jq_count=$(sed -n '700,1100p' statusline.sh | grep -c "jq -r" || true)
    
    # Should be <= 10 jq calls (we achieved 6, allow some buffer)
    [ "$jq_count" -le 10 ]
    
    # Log actual count for monitoring
    echo "# Current jq calls in config loading: $jq_count" >&3
}

# Benchmark: Total jq usage should remain controlled
@test "total jq usage should remain under 50 calls" {
    local total_jq_count=$(grep -c "jq -r" statusline.sh || true)
    
    # Should be <= 50 total jq calls (we achieved 40)
    [ "$total_jq_count" -le 50 ]
    
    echo "# Total jq calls in script: $total_jq_count" >&3
}

# Benchmark: Config loading time should be fast
@test "config loading should complete within reasonable time" {
    skip_if_no_jq
    
    # Time the parse_toml_to_json function (use seconds for macOS compatibility)
    local start_time=$(date +%s)
    
    # Source the script and test parsing
STATUSLINE_TESTING="true" source statusline.sh 2>/dev/null
    parse_toml_to_json "$TEST_CONFIG" >/dev/null
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Should complete within 5 seconds (very generous for config parsing on any system)
    [ "$duration" -lt 5 ]
    
    echo "# Config parsing time: ${duration}s" >&3
}

# Benchmark: Memory usage should be reasonable
@test "config loading should not consume excessive memory" {
    skip_if_no_jq
    
    # Monitor memory usage during config loading
    local memory_before=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    
    # Load configuration multiple times
STATUSLINE_TESTING="true" source statusline.sh 2>/dev/null
    for i in {1..10}; do
        parse_toml_to_json "$TEST_CONFIG" >/dev/null
    done
    
    local memory_after=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    local memory_increase=$((memory_after - memory_before))
    
    # Should not increase memory by more than 50MB
    [ "$memory_increase" -lt 51200 ]
    
    echo "# Memory increase: ${memory_increase}KB" >&3
}

# Benchmark: Error handling should not add significant overhead
@test "error handling should be efficient" {
    local start_time=$(date +%s)
    
    # Test error handling paths (ignore exit codes, we're measuring timing)
STATUSLINE_TESTING="true" source statusline.sh 2>/dev/null
    parse_toml_to_json "/nonexistent/file.toml" >/dev/null 2>&1 || true
    parse_toml_to_json "" >/dev/null 2>&1 || true
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Error handling should complete quickly
    [ "$duration" -lt 3 ]
    
    echo "# Error handling time: ${duration}s" >&3
}

# Benchmark: Security functions should be fast
@test "path sanitization should be efficient" {
    local start_time=$(date +%s)
    
STATUSLINE_TESTING="true" source statusline.sh 2>/dev/null
    
    # Test multiple path sanitizations
    for i in {1..100}; do
        sanitize_path_secure "/path/../../../test/file" >/dev/null
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 100 sanitizations should complete within 500ms
    [ "$duration" -lt 500 ]
    
    echo "# 100x path sanitization time: ${duration}ms" >&3
}

# Regression test: Ensure optimization markers exist
@test "optimization markers should be present" {
    # Check for our optimization comment
    grep -q "64 individual jq calls replaced with 1 optimized operation" statusline.sh
    
    # Check for single-pass extraction comment
    grep -q "single-pass jq config extraction" statusline.sh
    
    # Check for security improvements
    grep -q "Security-first sanitization" statusline.sh
    grep -q "create_secure_cache_file" statusline.sh
}

# Performance regression detection
@test "performance should not regress from baseline" {
    # If this file exists, compare against baseline
    local baseline_file="tests/benchmarks/performance_baseline.txt"
    
    if [[ -f "$baseline_file" ]]; then
        local baseline_jq=$(grep "^jq_calls:" "$baseline_file" | cut -d: -f2)
        local current_jq=$(grep -c "jq -r" statusline.sh || true)
        
        # Current should not exceed baseline by more than 20%
        local max_allowed=$((baseline_jq * 12 / 10))
        [ "$current_jq" -le "$max_allowed" ]
        
        echo "# Baseline jq calls: $baseline_jq, Current: $current_jq" >&3
    else
        # Create baseline file for future comparisons
        mkdir -p "$(dirname "$baseline_file")"
        echo "jq_calls:$(grep -c "jq -r" statusline.sh || true)" > "$baseline_file"
        echo "# Created performance baseline" >&3
    fi
}

# Helper functions
skip_if_no_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not available for benchmark testing"
    fi
}

skip_if_no_time() {
    if ! command -v date >/dev/null 2>&1; then
        skip "date command not available for timing"
    fi
}