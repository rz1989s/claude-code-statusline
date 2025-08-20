#!/usr/bin/env bats

# TOML Configuration Integration Tests
# Tests the complete TOML → application flow with optimized config extraction

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    export PATH="$STATUSLINE_DIR:$PATH"
    cd "$STATUSLINE_DIR"
    
    # Create test directory for TOML configs
    export TEST_CONFIG_DIR="/tmp/toml_integration_tests"
    mkdir -p "$TEST_CONFIG_DIR"
    
    # Source the statusline script for function access (save/restore args to avoid CLI parsing)
    local saved_args=("$@")
    set --
    export STATUSLINE_TESTING="true"
    source statusline.sh 2>/dev/null || true
    set -- "${saved_args[@]}"
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
}

# Test complete TOML to config variable flow
@test "should load complete TOML configuration correctly" {
    local test_config="$TEST_CONFIG_DIR/complete_config.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"
green = "\033[32m"

[colors.extended]
orange = "\033[38;5;208m"
purple = "\033[95m"

[colors.formatting]
dim = "\033[2m"
italic = "\033[3m"

[features]
show_commits = true
show_version = false
show_submodules = true
show_mcp_status = false

[timeouts]
mcp = "5s"
version = "3s"
ccusage = "4s"

[emojis]
opus = "🧠"
haiku = "⚡"
sonnet = "🎵"
clean_status = "✅"

[labels]
commits = "Commits:"
repo = "REPOSITORY"
monthly = "MONTH"

[cache]
version_duration = 7200
version_file = "/tmp/custom_cache"

[display]
time_format = "%H:%M:%S"
date_format = "%Y-%m-%d"

[messages]
no_ccusage = "ccusage not found"
mcp_unknown = "unknown_mcp"

[debug]
log_level = "info"
benchmark_performance = true
EOF

    # Test TOML parsing
    local json_result
    json_result=$(parse_toml_to_json "$test_config")
    
    # Should not be empty
    [[ "$json_result" != "{}" ]]
    [[ -n "$json_result" ]]
    
    # Test that JSON contains expected values
    echo "$json_result" | grep -q "custom"
    echo "$json_result" | grep -q "033\[31m"  # Red color
    echo "$json_result" | grep -q "true"      # Boolean values
    echo "$json_result" | grep -q "5s"        # Timeout values
}

# Test optimized config extraction performance
@test "should extract all config values in single operation" {
    local test_config="$TEST_CONFIG_DIR/performance_test.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "catppuccin"

[features]
show_commits = true
show_version = true

[timeouts]
mcp = "3s"

[emojis]
opus = "🧠"

[labels]
commits = "Commits:"
EOF

    # Parse TOML to JSON
    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Test the optimized single-pass extraction
    local config_data
    config_data=$(echo "$config_json" | jq -r '{
        theme_name: (.theme.name // "catppuccin"),
        feature_show_commits: (.features.show_commits // true),
        feature_show_version: (.features.show_version // true),
        timeout_mcp: (.timeouts.mcp // "3s"),
        emoji_opus: (.emojis.opus // "🧠"),
        label_commits: (.labels.commits // "Commits:")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    # Verify extraction worked
    [[ -n "$config_data" ]]
    
    # Check specific values are extracted correctly
    echo "$config_data" | grep -q "theme_name=catppuccin"
    echo "$config_data" | grep -q "feature_show_commits=true"
    echo "$config_data" | grep -q "timeout_mcp=3s"
    echo "$config_data" | grep -q "emoji_opus=🧠"
    echo "$config_data" | grep -q "label_commits=Commits:"
}

# Test theme configuration integration
@test "should handle custom theme configuration correctly" {
    local test_config="$TEST_CONFIG_DIR/custom_theme.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[91m"
blue = "\033[94m"
green = "\033[92m"
yellow = "\033[93m"

[colors.extended]
orange = "\033[38;5;214m"
purple = "\033[38;5;99m"

[colors.formatting]
dim = "\033[2m"
reset = "\033[0m"
EOF

    # Test complete custom theme flow
    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Verify theme is set to custom
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "default"')
    [[ "$theme_name" == "custom" ]]
    
    # Test color extraction for custom theme
    local red_color
    red_color=$(echo "$config_json" | jq -r '.colors.basic.red // "default"')
    [[ "$red_color" == "\\033[91m" ]]
    
    local orange_color
    orange_color=$(echo "$config_json" | jq -r '.colors.extended.orange // "default"')
    [[ "$orange_color" == "\\033[38;5;214m" ]]
}

# Test feature toggles integration
@test "should handle feature toggles correctly" {
    local test_config="$TEST_CONFIG_DIR/features.toml"
    
    cat > "$test_config" << 'EOF'
[features]
show_commits = false
show_version = true
show_submodules = false
show_mcp_status = true
show_cost_tracking = false
show_reset_info = true
show_session_info = false
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Test boolean value extraction
    local show_commits
    show_commits=$(echo "$config_json" | jq -r '.features.show_commits // true')
    [[ "$show_commits" == "false" ]]
    
    local show_version  
    show_version=$(echo "$config_json" | jq -r '.features.show_version // true')
    [[ "$show_version" == "true" ]]
    
    local show_mcp
    show_mcp=$(echo "$config_json" | jq -r '.features.show_mcp_status // true')
    [[ "$show_mcp" == "true" ]]
}

# Test timeout configuration integration  
@test "should handle timeout values correctly" {
    local test_config="$TEST_CONFIG_DIR/timeouts.toml"
    
    cat > "$test_config" << 'EOF'
[timeouts]
mcp = "10s"
version = "5s"
ccusage = "15s"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Test timeout value extraction
    local mcp_timeout
    mcp_timeout=$(echo "$config_json" | jq -r '.timeouts.mcp // "3s"')
    [[ "$mcp_timeout" == "10s" ]]
    
    local version_timeout
    version_timeout=$(echo "$config_json" | jq -r '.timeouts.version // "2s"')
    [[ "$version_timeout" == "5s" ]]
}

# Test emoji configuration integration
@test "should handle emoji configuration correctly" {
    local test_config="$TEST_CONFIG_DIR/emojis.toml"
    
    cat > "$test_config" << 'EOF'
[emojis]
opus = "🔥"
haiku = "💨"
sonnet = "🎼"
default_model = "🤖"
clean_status = "✨"
dirty_status = "💥"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Test emoji extraction
    local opus_emoji
    opus_emoji=$(echo "$config_json" | jq -r '.emojis.opus // "🧠"')
    [[ "$opus_emoji" == "🔥" ]]
    
    local clean_emoji
    clean_emoji=$(echo "$config_json" | jq -r '.emojis.clean_status // "✅"')
    [[ "$clean_emoji" == "✨" ]]
}

# Test label customization integration
@test "should handle label customization correctly" {
    local test_config="$TEST_CONFIG_DIR/labels.toml"
    
    cat > "$test_config" << 'EOF'
[labels]
commits = "CHANGES:"
repo = "PROJECT"
monthly = "MONTHLY"
weekly = "WEEKLY"
daily = "TODAY"
mcp = "SERVER"
version_prefix = "v"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Test label extraction
    local commits_label
    commits_label=$(echo "$config_json" | jq -r '.labels.commits // "Commits:"')
    [[ "$commits_label" == "CHANGES:" ]]
    
    local repo_label
    repo_label=$(echo "$config_json" | jq -r '.labels.repo // "REPO"')
    [[ "$repo_label" == "PROJECT" ]]
}

# Test cache configuration integration
@test "should handle cache configuration correctly" {
    local test_config="$TEST_CONFIG_DIR/cache.toml"
    
    cat > "$test_config" << 'EOF'
[cache]
version_duration = 7200
version_file = "/tmp/custom_version_cache"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Test cache settings extraction
    local cache_duration
    cache_duration=$(echo "$config_json" | jq -r '.cache.version_duration // 3600')
    [[ "$cache_duration" == "7200" ]]
    
    local cache_file
    cache_file=$(echo "$config_json" | jq -r '.cache.version_file // "/tmp/.claude_version_cache"')
    [[ "$cache_file" == "/tmp/custom_version_cache" ]]
}

# Test error message customization
@test "should handle message customization correctly" {
    local test_config="$TEST_CONFIG_DIR/messages.toml"
    
    cat > "$test_config" << 'EOF'
[messages]
no_ccusage = "Cost tracking unavailable"
ccusage_install = "Please install ccusage for cost tracking"
no_active_block = "No active session"
mcp_unknown = "server_unknown"
mcp_none = "no_server"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Test message extraction
    local no_ccusage
    no_ccusage=$(echo "$config_json" | jq -r '.messages.no_ccusage // "No ccusage"')
    [[ "$no_ccusage" == "Cost tracking unavailable" ]]
    
    local mcp_unknown
    mcp_unknown=$(echo "$config_json" | jq -r '.messages.mcp_unknown // "unknown"')
    [[ "$mcp_unknown" == "server_unknown" ]]
}

# Test fallback behavior with minimal config
@test "should handle minimal TOML configuration with proper fallbacks" {
    local test_config="$TEST_CONFIG_DIR/minimal.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "catppuccin"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Should parse successfully
    [[ "$config_json" != "{}" ]]
    
    # Theme should be extracted
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "default"')
    [[ "$theme_name" == "catppuccin" ]]
    
    # Missing values should fall back to defaults in extraction
    local show_commits
    show_commits=$(echo "$config_json" | jq -r '.features.show_commits // true')
    [[ "$show_commits" == "true" ]]  # Default fallback
}

# Test complex nested configuration
@test "should handle complex nested TOML structure" {
    local test_config="$TEST_CONFIG_DIR/complex.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"

[colors.extended]
orange = "\033[38;5;208m"
purple = "\033[95m"

[colors.formatting]
dim = "\033[2m"
italic = "\033[3m"

[features]
show_commits = true
show_version = false

[advanced]
debug_mode = true
performance_mode = false

[platform]
prefer_gtimeout = true
use_gdate = false
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    # Should handle nested structures correctly
    [[ "$config_json" != "{}" ]]
    
    # Test nested color access
    local red_color
    red_color=$(echo "$config_json" | jq -r '.colors.basic.red // "default"')
    [[ "$red_color" == "\\033[31m" ]]
    
    local orange_color
    orange_color=$(echo "$config_json" | jq -r '.colors.extended.orange // "default"')
    [[ "$orange_color" == "\\033[38;5;208m" ]]
    
    # Test advanced settings
    local debug_mode
    debug_mode=$(echo "$config_json" | jq -r '.advanced.debug_mode // false')
    [[ "$debug_mode" == "true" ]]
}

# Test performance regression prevention
@test "should maintain fast parsing performance" {
    local test_config="$TEST_CONFIG_DIR/large_config.toml"
    
    # Create a larger config file to test performance
    cat > "$test_config" << 'EOF'
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
light_orange = "\033[38;5;215m"
light_gray = "\033[38;5;248m"
bright_green = "\033[92m"
purple = "\033[95m"
teal = "\033[38;5;73m"
gold = "\033[38;5;220m"
pink_bright = "\033[38;5;205m"
indigo = "\033[38;5;105m"
violet = "\033[38;5;99m"
light_blue = "\033[38;5;111m"

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
EOF

    # Time the parsing
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local config_json
    config_json=$(parse_toml_to_json "$test_config")
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Should parse successfully
    [[ "$config_json" != "{}" ]]
    [[ -n "$config_json" ]]
    
    # Performance should be reasonable (allow up to 1000ms for larger configs)
    if [[ "$start_time" != "$end_time" ]]; then
        local duration=$((end_time - start_time))
        [[ "$duration" -lt 1000 ]]  # Less than 1 second
    fi
}

# Helper function to skip tests if jq is not available
skip_if_no_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not available for TOML integration testing"
    fi
}