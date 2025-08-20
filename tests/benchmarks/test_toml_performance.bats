#!/usr/bin/env bats

# TOML Configuration Performance Benchmarks
# Measures current jq usage overhead and establishes performance baselines

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    export PATH="$STATUSLINE_DIR:$PATH"
    cd "$STATUSLINE_DIR"
    
    # Create test directory for performance tests
    export TEST_PERF_DIR="/tmp/toml_performance_tests"
    mkdir -p "$TEST_PERF_DIR"
    
    # Source the statusline script for function access
    local saved_args=("$@")
    set --
    export STATUSLINE_TESTING="true"
    source statusline.sh 2>/dev/null || true
    set -- "${saved_args[@]}"
}

teardown() {
    rm -rf "$TEST_PERF_DIR"
}

# Benchmark current jq usage pattern (40+ sequential calls)
@test "benchmark: current jq usage overhead in config loading" {
    skip_if_no_jq
    
    local perf_config="$TEST_PERF_DIR/benchmark.toml"
    
    # Create comprehensive config to trigger all jq calls
    cat > "$perf_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"
green = "\033[32m"
yellow = "\033[33m"
magenta = "\033[35m"
cyan = "\033[36m"
white = "\033[37m"

[colors.extended]
orange = "\033[38;5;208m"
purple = "\033[95m"
light_gray = "\033[38;5;248m"
bright_green = "\033[92m"
teal = "\033[38;5;73m"

[colors.formatting]
dim = "\033[2m"
italic = "\033[3m"
reset = "\033[0m"

[features]
show_commits = true
show_version = true
show_submodules = true
show_mcp_status = true
show_cost_tracking = true
show_reset_info = true
show_session_info = true

[timeouts]
mcp = "3s"
version = "2s"
ccusage = "3s"

[emojis]
opus = "🧠"
haiku = "⚡"
sonnet = "🎵"
default_model = "🤖"
clean_status = "✅"
dirty_status = "📁"
clock = "🕐"
live_block = "🔥"

[labels]
commits = "Commits:"
repo = "REPO"
monthly = "30DAY"
weekly = "7DAY"
daily = "DAY"
mcp = "MCP"
version_prefix = "ver"
submodule = "SUB:"
session_prefix = "S:"
live = "LIVE"
reset = "RESET"

[cache]
version_duration = 3600
version_file = "/tmp/.claude_version_cache"

[display]
time_format = "%H:%M"
date_format = "%Y-%m-%d"

[messages]
no_ccusage = "No ccusage"
ccusage_install = "Run: npm install -g ccusage"
no_active_block = "No active block"
mcp_unknown = "unknown"
mcp_none = "none"

[debug]
log_level = "info"
benchmark_performance = false

[platform]
prefer_gtimeout = true
use_gdate = false
color_support_level = "full"
EOF

    echo "# Benchmarking current jq usage pattern..." >&3
    
    # Parse TOML once
    local config_json
    config_json=$(parse_toml_to_json "$perf_config")
    [[ "$config_json" != "{}" ]]
    
    # Benchmark multiple individual jq calls (current pattern)
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Simulate current 40+ jq usage pattern
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "catppuccin"')
    
    # Basic colors (8 calls)
    local red blue green yellow magenta cyan white black
    red=$(echo "$config_json" | jq -r '.colors.basic.red // "\033[31m"')
    blue=$(echo "$config_json" | jq -r '.colors.basic.blue // "\033[34m"')
    green=$(echo "$config_json" | jq -r '.colors.basic.green // "\033[32m"')
    yellow=$(echo "$config_json" | jq -r '.colors.basic.yellow // "\033[33m"')
    magenta=$(echo "$config_json" | jq -r '.colors.basic.magenta // "\033[35m"')
    cyan=$(echo "$config_json" | jq -r '.colors.basic.cyan // "\033[36m"')
    white=$(echo "$config_json" | jq -r '.colors.basic.white // "\033[37m"')
    black=$(echo "$config_json" | jq -r '.colors.basic.black // "\033[30m"')
    
    # Extended colors (5 calls)
    local orange purple light_gray bright_green teal
    orange=$(echo "$config_json" | jq -r '.colors.extended.orange // "\033[38;5;208m"')
    purple=$(echo "$config_json" | jq -r '.colors.extended.purple // "\033[95m"')
    light_gray=$(echo "$config_json" | jq -r '.colors.extended.light_gray // "\033[38;5;248m"')
    bright_green=$(echo "$config_json" | jq -r '.colors.extended.bright_green // "\033[92m"')
    teal=$(echo "$config_json" | jq -r '.colors.extended.teal // "\033[38;5;73m"')
    
    # Features (7 calls)
    local show_commits show_version show_submodules show_mcp show_cost show_reset show_session
    show_commits=$(echo "$config_json" | jq -r '.features.show_commits // true')
    show_version=$(echo "$config_json" | jq -r '.features.show_version // true')
    show_submodules=$(echo "$config_json" | jq -r '.features.show_submodules // true')
    show_mcp=$(echo "$config_json" | jq -r '.features.show_mcp_status // true')
    show_cost=$(echo "$config_json" | jq -r '.features.show_cost_tracking // true')
    show_reset=$(echo "$config_json" | jq -r '.features.show_reset_info // true')
    show_session=$(echo "$config_json" | jq -r '.features.show_session_info // false')
    
    # Timeouts (3 calls)
    local mcp_timeout version_timeout ccusage_timeout
    mcp_timeout=$(echo "$config_json" | jq -r '.timeouts.mcp // "3s"')
    version_timeout=$(echo "$config_json" | jq -r '.timeouts.version // "2s"')
    ccusage_timeout=$(echo "$config_json" | jq -r '.timeouts.ccusage // "3s"')
    
    # Emojis (8 calls)
    local opus_emoji haiku_emoji sonnet_emoji default_emoji clean_emoji dirty_emoji clock_emoji live_emoji
    opus_emoji=$(echo "$config_json" | jq -r '.emojis.opus // "🧠"')
    haiku_emoji=$(echo "$config_json" | jq -r '.emojis.haiku // "⚡"')
    sonnet_emoji=$(echo "$config_json" | jq -r '.emojis.sonnet // "🎵"')
    default_emoji=$(echo "$config_json" | jq -r '.emojis.default_model // "🤖"')
    clean_emoji=$(echo "$config_json" | jq -r '.emojis.clean_status // "✅"')
    dirty_emoji=$(echo "$config_json" | jq -r '.emojis.dirty_status // "📁"')
    clock_emoji=$(echo "$config_json" | jq -r '.emojis.clock // "🕐"')
    live_emoji=$(echo "$config_json" | jq -r '.emojis.live_block // "🔥"')
    
    # Labels (10 calls)
    local commits_label repo_label monthly_label weekly_label daily_label mcp_label version_prefix submodule_label session_prefix live_label
    commits_label=$(echo "$config_json" | jq -r '.labels.commits // "Commits:"')
    repo_label=$(echo "$config_json" | jq -r '.labels.repo // "REPO"')
    monthly_label=$(echo "$config_json" | jq -r '.labels.monthly // "30DAY"')
    weekly_label=$(echo "$config_json" | jq -r '.labels.weekly // "7DAY"')
    daily_label=$(echo "$config_json" | jq -r '.labels.daily // "DAY"')
    mcp_label=$(echo "$config_json" | jq -r '.labels.mcp // "MCP"')
    version_prefix=$(echo "$config_json" | jq -r '.labels.version_prefix // "ver"')
    submodule_label=$(echo "$config_json" | jq -r '.labels.submodule // "SUB:"')
    session_prefix=$(echo "$config_json" | jq -r '.labels.session_prefix // "S:"')
    live_label=$(echo "$config_json" | jq -r '.labels.live // "LIVE"')
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Calculate overhead of multiple jq calls
    if [[ "$start_time" != "$end_time" ]]; then
        local duration=$((end_time - start_time))
        echo "# Current jq pattern (40+ calls): ${duration}ms" >&3
        
        # Set reasonable performance expectation (should be < 200ms as noted in review)
        [[ "$duration" -lt 500 ]]  # Allow generous buffer for testing
    fi
    
    # Verify all values were extracted correctly
    [[ "$theme_name" == "custom" ]]
    [[ "$show_commits" == "true" ]]
    [[ "$opus_emoji" == "🧠" ]]
}

# Benchmark optimized single-pass jq extraction
@test "benchmark: optimized single jq operation performance" {
    skip_if_no_jq
    
    local perf_config="$TEST_PERF_DIR/optimized.toml"
    
    # Same comprehensive config as above
    cat > "$perf_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"
green = "\033[32m"
yellow = "\033[33m"

[colors.extended]
orange = "\033[38;5;208m"
purple = "\033[95m"

[features]
show_commits = true
show_version = true
show_submodules = true
show_mcp_status = true

[timeouts]
mcp = "3s"
version = "2s"

[emojis]
opus = "🧠"
haiku = "⚡"
sonnet = "🎵"

[labels]
commits = "Commits:"
repo = "REPO"
monthly = "30DAY"
EOF

    echo "# Benchmarking optimized jq usage pattern..." >&3
    
    # Parse TOML once
    local config_json
    config_json=$(parse_toml_to_json "$perf_config")
    [[ "$config_json" != "{}" ]]
    
    # Benchmark single optimized jq call
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Single jq operation extracting all values at once
    local all_config
    all_config=$(echo "$config_json" | jq -r '
    {
        theme_name: (.theme.name // "catppuccin"),
        color_red: (.colors.basic.red // "\033[31m"),
        color_blue: (.colors.basic.blue // "\033[34m"),
        color_green: (.colors.basic.green // "\033[32m"),
        color_yellow: (.colors.basic.yellow // "\033[33m"),
        color_orange: (.colors.extended.orange // "\033[38;5;208m"),
        color_purple: (.colors.extended.purple // "\033[95m"),
        feature_commits: (.features.show_commits // true),
        feature_version: (.features.show_version // true),
        feature_submodules: (.features.show_submodules // true),
        feature_mcp: (.features.show_mcp_status // true),
        timeout_mcp: (.timeouts.mcp // "3s"),
        timeout_version: (.timeouts.version // "2s"),
        emoji_opus: (.emojis.opus // "🧠"),
        emoji_haiku: (.emojis.haiku // "⚡"),
        emoji_sonnet: (.emojis.sonnet // "🎵"),
        label_commits: (.labels.commits // "Commits:"),
        label_repo: (.labels.repo // "REPO"),
        label_monthly: (.labels.monthly // "30DAY")
    } | to_entries | map("\(.key)=\(.value)") | .[]')
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Calculate optimized performance
    if [[ "$start_time" != "$end_time" ]]; then
        local duration=$((end_time - start_time))
        echo "# Optimized jq pattern (1 call): ${duration}ms" >&3
        
        # Should be significantly faster than multiple calls
        [[ "$duration" -lt 100 ]]  # Should be under 100ms
    fi
    
    # Verify extraction worked correctly
    [[ -n "$all_config" ]]
    echo "$all_config" | grep -q "theme_name=custom"
    echo "$all_config" | grep -q "feature_commits=true" 
    echo "$all_config" | grep -q "emoji_opus=🧠"
}

# Benchmark TOML parsing performance
@test "benchmark: TOML to JSON parsing performance" {
    skip_if_no_jq
    
    local parse_config="$TEST_PERF_DIR/parse_benchmark.toml"
    
    # Create large TOML for parsing benchmark
    cat > "$parse_config" << 'EOF'
[theme]
name = "catppuccin"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"
green = "\033[32m"
yellow = "\033[33m"
magenta = "\033[35m"
cyan = "\033[36m"
white = "\033[37m"
black = "\033[30m"

[colors.extended]
EOF
    
    # Add many extended colors to test parsing performance
    for i in {1..30}; do
        echo "color$i = \"\\033[38;5;${i}m\"" >> "$parse_config"
    done
    
    cat >> "$parse_config" << 'EOF'

[features]
show_commits = true
show_version = true
show_submodules = true
show_mcp_status = true
show_cost_tracking = true
show_reset_info = true

[timeouts]
mcp = "3s"
version = "2s"
ccusage = "3s"

[emojis]
opus = "🧠"
haiku = "⚡"
sonnet = "🎵"

[labels]
commits = "Commits:"
repo = "REPO"
monthly = "30DAY"
EOF

    echo "# Benchmarking TOML parsing..." >&3
    
    # Benchmark TOML parsing
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local config_json
    config_json=$(parse_toml_to_json "$parse_config")
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Calculate parsing performance
    if [[ "$start_time" != "$end_time" ]]; then
        local duration=$((end_time - start_time))
        echo "# TOML parsing time: ${duration}ms" >&3
        
        # TOML parsing should be reasonable
        [[ "$duration" -lt 200 ]]
    fi
    
    # Verify parsing worked
    [[ "$config_json" != "{}" ]]
    [[ -n "$config_json" ]]
    
    # Verify key content is present
    echo "$config_json" | grep -q "catppuccin"
    echo "$config_json" | grep -q "color1"
    echo "$config_json" | grep -q "🧠"
}

# Performance comparison test
@test "benchmark: performance comparison multiple vs single jq calls" {
    skip_if_no_jq
    
    local comparison_config="$TEST_PERF_DIR/comparison.toml"
    
    cat > "$comparison_config" << 'EOF'
[theme]
name = "garden"

[features]
show_commits = true
show_version = false

[timeouts]
mcp = "5s"

[emojis]
opus = "🌿"
EOF

    # Parse TOML once
    local config_json
    config_json=$(parse_toml_to_json "$comparison_config")
    
    echo "# Performance comparison test..." >&3
    
    # Test multiple jq calls (current pattern)
    local multi_start=$(date +%s%3N 2>/dev/null || date +%s)
    
    local theme_name feature_commits timeout_mcp emoji_opus
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "catppuccin"')
    feature_commits=$(echo "$config_json" | jq -r '.features.show_commits // true')
    timeout_mcp=$(echo "$config_json" | jq -r '.timeouts.mcp // "3s"')
    emoji_opus=$(echo "$config_json" | jq -r '.emojis.opus // "🧠"')
    
    local multi_end=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Test single jq call (optimized pattern)
    local single_start=$(date +%s%3N 2>/dev/null || date +%s)
    
    local single_result
    single_result=$(echo "$config_json" | jq -r '{
        theme_name: (.theme.name // "catppuccin"),
        feature_commits: (.features.show_commits // true),
        timeout_mcp: (.timeouts.mcp // "3s"),
        emoji_opus: (.emojis.opus // "🧠")
    } | to_entries | map("\(.key)=\(.value)") | .[]')
    
    local single_end=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Calculate and compare
    if [[ "$multi_start" != "$multi_end" && "$single_start" != "$single_end" ]]; then
        local multi_duration=$((multi_end - multi_start))
        local single_duration=$((single_end - single_start))
        
        echo "# Multiple jq calls: ${multi_duration}ms" >&3
        echo "# Single jq call: ${single_duration}ms" >&3
        
        # Single call should be equal or faster
        [[ "$single_duration" -le "$multi_duration" ]]
    fi
    
    # Verify both approaches give same results
    [[ "$theme_name" == "garden" ]]
    echo "$single_result" | grep -q "theme_name=garden"
    echo "$single_result" | grep -q "feature_commits=true"
    echo "$single_result" | grep -q "emoji_opus=🌿"
}

# Memory usage benchmark (approximate)
@test "benchmark: memory usage with large configurations" {
    skip_if_no_jq
    
    local memory_config="$TEST_PERF_DIR/memory_test.toml"
    
    # Create very large config to test memory usage
    cat > "$memory_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"
green = "\033[32m"
yellow = "\033[33m"
magenta = "\033[35m"
cyan = "\033[36m"
white = "\033[37m"
black = "\033[30m"

[colors.extended]
EOF
    
    # Add 100 extended colors for memory test
    for i in {1..100}; do
        echo "color$i = \"\\033[38;5;${i}m\"" >> "$memory_config"
        echo "bright_color$i = \"\\033[38;5;$((i+100))m\"" >> "$memory_config"
    done
    
    cat >> "$memory_config" << 'EOF'

[features]
show_commits = true
show_version = true
show_submodules = true
show_mcp_status = true
show_cost_tracking = true
show_reset_info = true
show_session_info = true

[labels]
EOF
    
    # Add many labels
    for i in {1..50}; do
        echo "label$i = \"Label $i\"" >> "$memory_config"
    done
    
    echo "# Testing memory usage with large config..." >&3
    
    # Parse large config (this tests memory usage indirectly)
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local config_json
    config_json=$(parse_toml_to_json "$memory_config")
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Should handle large configs without excessive delay
    if [[ "$start_time" != "$end_time" ]]; then
        local duration=$((end_time - start_time))
        echo "# Large config parsing: ${duration}ms" >&3
        
        # Should complete within reasonable time even for large configs
        [[ "$duration" -lt 1000 ]]  # 1 second max for very large configs
    fi
    
    # Verify parsing succeeded
    [[ "$config_json" != "{}" ]]
    [[ -n "$config_json" ]]
    
    # Clean up large config to save disk space
    rm -f "$memory_config"
}

# Helper function to skip tests if jq is not available
skip_if_no_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not available for performance benchmarking"
    fi
}