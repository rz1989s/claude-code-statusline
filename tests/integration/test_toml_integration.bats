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
theme.name = "custom"

colors.basic.red = "red"
colors.basic.blue = "blue"
colors.basic.green = "green"

colors.extended.orange = "orange"
colors.extended.purple = "purple"

colors.formatting.dim = "dim"
colors.formatting.italic = "italic"

features.show_commits = true
features.show_version = false
features.show_submodules = true
features.show_mcp_status = false

timeouts.mcp = "5s"
timeouts.version = "3s"
emojis.opus = "🧠"
emojis.haiku = "⚡"
emojis.sonnet = "🎵"
emojis.clean_status = "✅"

labels.commits = "Commits:"
labels.repo = "REPOSITORY"
labels.monthly = "MONTH"

cache.version_duration = 7200
cache.version_file = "/tmp/custom_cache"

display.time_format = "%H:%M:%S"
display.date_format = "%Y-%m-%d"

messages.mcp_unknown = "unknown_mcp"

debug.log_level = "info"
debug.benchmark_performance = true
EOF

    # Test TOML parsing
    local json_result
    json_result=$(parse_toml_to_json "$test_config")
    
    # Should not be empty
    [[ "$json_result" != "{}" ]]
    [[ -n "$json_result" ]]
    
    # Test that JSON contains expected values
    echo "$json_result" | grep -q "custom"
    echo "$json_result" | grep -q "red"       # Red color (simple string)
    echo "$json_result" | grep -q "true"      # Boolean values
    echo "$json_result" | grep -q "5s"        # Timeout values
}

# Test optimized config extraction performance
@test "should extract all config values in single operation" {
    local test_config="$TEST_CONFIG_DIR/performance_test.toml"
    
    cat > "$test_config" << 'EOF'
theme.name = "catppuccin"

features.show_commits = true
features.show_version = true

timeouts.mcp = "3s"

emojis.opus = "🧠"

labels.commits = "Commits:"
EOF

    # Parse TOML to JSON
    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Test the optimized single-pass extraction (flat TOML keys)
    local config_data
    config_data=$(echo "$config_json" | jq -r '{
        theme_name: (.["theme.name"] // "catppuccin"),
        feature_show_commits: (.["features.show_commits"] // true),
        feature_show_version: (.["features.show_version"] // true),
        timeout_mcp: (.["timeouts.mcp"] // "3s"),
        emoji_opus: (.["emojis.opus"] // "🧠"),
        label_commits: (.["labels.commits"] // "Commits:")
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
theme.name = "custom"

colors.basic.red = "bright_red"
colors.basic.blue = "bright_blue"
colors.basic.green = "bright_green"
colors.basic.yellow = "bright_yellow"

colors.extended.orange = "custom_orange"
colors.extended.purple = "custom_purple"

colors.formatting.dim = "dim"
colors.formatting.reset = "reset"
EOF

    # Test complete custom theme flow
    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Verify theme is set to custom
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.["theme.name"] // "default"')
    [[ "$theme_name" == "custom" ]]

    # Test color extraction for custom theme
    local red_color
    red_color=$(echo "$config_json" | jq -r '.["colors.basic.red"] // "default"')
    [[ "$red_color" == "bright_red" ]]

    local orange_color
    orange_color=$(echo "$config_json" | jq -r '.["colors.extended.orange"] // "default"')
    [[ "$orange_color" == "custom_orange" ]]
}

# Test feature toggles integration
@test "should handle feature toggles correctly" {
    local test_config="$TEST_CONFIG_DIR/features.toml"

    cat > "$test_config" << 'EOF'
features.show_commits = false
features.show_version = true
features.show_submodules = false
features.show_mcp_status = true
features.show_cost_tracking = false
features.show_reset_info = true
features.show_session_info = false
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Test boolean value extraction (use tostring to avoid jq // fallback issues with false)
    local show_commits
    show_commits=$(echo "$config_json" | jq -r '.["features.show_commits"] | tostring')
    [[ "$show_commits" == "false" ]]

    local show_version
    show_version=$(echo "$config_json" | jq -r '.["features.show_version"] | tostring')
    [[ "$show_version" == "true" ]]

    local show_mcp
    show_mcp=$(echo "$config_json" | jq -r '.["features.show_mcp_status"] | tostring')
    [[ "$show_mcp" == "true" ]]
}

# Test timeout configuration integration
@test "should handle timeout values correctly" {
    local test_config="$TEST_CONFIG_DIR/timeouts.toml"

    cat > "$test_config" << 'EOF'
timeouts.mcp = "10s"
timeouts.version = "5s"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Test timeout value extraction
    local mcp_timeout
    mcp_timeout=$(echo "$config_json" | jq -r '.["timeouts.mcp"] // "3s"')
    [[ "$mcp_timeout" == "10s" ]]

    local version_timeout
    version_timeout=$(echo "$config_json" | jq -r '.["timeouts.version"] // "2s"')
    [[ "$version_timeout" == "5s" ]]
}

# Test emoji configuration integration
@test "should handle emoji configuration correctly" {
    local test_config="$TEST_CONFIG_DIR/emojis.toml"

    cat > "$test_config" << 'EOF'
emojis.opus = "🔥"
emojis.haiku = "💨"
emojis.sonnet = "🎼"
emojis.default_model = "🤖"
emojis.clean_status = "✨"
emojis.dirty_status = "💥"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Test emoji extraction
    local opus_emoji
    opus_emoji=$(echo "$config_json" | jq -r '.["emojis.opus"] // "🧠"')
    [[ "$opus_emoji" == "🔥" ]]

    local clean_emoji
    clean_emoji=$(echo "$config_json" | jq -r '.["emojis.clean_status"] // "✅"')
    [[ "$clean_emoji" == "✨" ]]
}

# Test label customization integration
@test "should handle label customization correctly" {
    local test_config="$TEST_CONFIG_DIR/labels.toml"

    cat > "$test_config" << 'EOF'
labels.commits = "CHANGES:"
labels.repo = "PROJECT"
labels.monthly = "MONTHLY"
labels.weekly = "WEEKLY"
labels.daily = "TODAY"
labels.mcp = "SERVER"
labels.version_prefix = "v"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Test label extraction
    local commits_label
    commits_label=$(echo "$config_json" | jq -r '.["labels.commits"] // "Commits:"')
    [[ "$commits_label" == "CHANGES:" ]]

    local repo_label
    repo_label=$(echo "$config_json" | jq -r '.["labels.repo"] // "REPO"')
    [[ "$repo_label" == "PROJECT" ]]
}

# Test cache configuration integration
@test "should handle cache configuration correctly" {
    local test_config="$TEST_CONFIG_DIR/cache.toml"

    cat > "$test_config" << 'EOF'
cache.version_duration = 7200
cache.version_file = "/tmp/custom_version_cache"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Test cache settings extraction
    local cache_duration
    cache_duration=$(echo "$config_json" | jq -r '.["cache.version_duration"] // 3600')
    [[ "$cache_duration" == "7200" ]]

    local cache_file
    cache_file=$(echo "$config_json" | jq -r '.["cache.version_file"] // "/tmp/.claude_version_cache"')
    [[ "$cache_file" == "/tmp/custom_version_cache" ]]
}

# Test error message customization
@test "should handle message customization correctly" {
    local test_config="$TEST_CONFIG_DIR/messages.toml"

    cat > "$test_config" << 'EOF'
messages.no_active_block = "No active session"
messages.mcp_unknown = "server_unknown"
messages.mcp_none = "no_server"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Test message extraction
    local mcp_unknown
    mcp_unknown=$(echo "$config_json" | jq -r '.["messages.mcp_unknown"] // "unknown"')
    [[ "$mcp_unknown" == "server_unknown" ]]
}

# Test fallback behavior with minimal config
@test "should handle minimal TOML configuration with proper fallbacks" {
    local test_config="$TEST_CONFIG_DIR/minimal.toml"

    cat > "$test_config" << 'EOF'
theme.name = "catppuccin"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Should parse successfully
    [[ "$config_json" != "{}" ]]

    # Theme should be extracted
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.["theme.name"] // "default"')
    [[ "$theme_name" == "catppuccin" ]]

    # Missing values should fall back to defaults in extraction
    local show_commits
    show_commits=$(echo "$config_json" | jq -r '.["features.show_commits"] // true')
    [[ "$show_commits" == "true" ]]  # Default fallback
}

# Test complex flat TOML configuration
@test "should handle complex flat TOML structure" {
    local test_config="$TEST_CONFIG_DIR/complex.toml"

    cat > "$test_config" << 'EOF'
theme.name = "custom"

colors.basic.red = "red"
colors.basic.blue = "blue"

colors.extended.orange = "orange"
colors.extended.purple = "purple"

colors.formatting.dim = "dim"
colors.formatting.italic = "italic"

features.show_commits = true
features.show_version = false

advanced.debug_mode = true
advanced.performance_mode = false

platform.prefer_gtimeout = true
platform.use_gdate = false
EOF

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    # Should handle flat structures correctly
    [[ "$config_json" != "{}" ]]

    # Test color access (flat keys)
    local red_color
    red_color=$(echo "$config_json" | jq -r '.["colors.basic.red"] // "default"')
    [[ "$red_color" == "red" ]]

    local orange_color
    orange_color=$(echo "$config_json" | jq -r '.["colors.extended.orange"] // "default"')
    [[ "$orange_color" == "orange" ]]

    # Test advanced settings
    local debug_mode
    debug_mode=$(echo "$config_json" | jq -r '.["advanced.debug_mode"] // false')
    [[ "$debug_mode" == "true" ]]
}

# Test performance regression prevention
@test "should maintain fast parsing performance" {
    local test_config="$TEST_CONFIG_DIR/large_config.toml"

    # Create a larger config file to test performance (flat format)
    cat > "$test_config" << 'EOF'
theme.name = "custom"

colors.basic.red = "red"
colors.basic.blue = "blue"
colors.basic.green = "green"
colors.basic.yellow = "yellow"
colors.basic.magenta = "magenta"
colors.basic.cyan = "cyan"
colors.basic.white = "white"

colors.extended.orange = "orange"
colors.extended.light_orange = "light_orange"
colors.extended.light_gray = "light_gray"
colors.extended.bright_green = "bright_green"
colors.extended.purple = "purple"
colors.extended.teal = "teal"
colors.extended.gold = "gold"
colors.extended.pink_bright = "pink_bright"
colors.extended.indigo = "indigo"
colors.extended.violet = "violet"
colors.extended.light_blue = "light_blue"

features.show_commits = true
features.show_version = true
features.show_submodules = true
features.show_mcp_status = true
features.show_cost_tracking = true
features.show_reset_info = true
features.show_session_info = true

timeouts.mcp = "3s"
timeouts.version = "2s"
emojis.opus = "🧠"
emojis.haiku = "⚡"
emojis.sonnet = "🎵"
emojis.default_model = "🤖"
emojis.clean_status = "✅"
emojis.dirty_status = "📁"
emojis.clock = "🕐"
emojis.live_block = "🔥"

labels.commits = "Commits:"
labels.repo = "REPO"
labels.monthly = "30DAY"
labels.weekly = "7DAY"
labels.daily = "DAY"
labels.mcp = "MCP"
labels.version_prefix = "ver"
labels.submodule = "SUB:"
labels.session_prefix = "S:"
labels.live = "LIVE"
labels.reset = "RESET"
EOF

    # Time the parsing (seconds for macOS compatibility)
    local start_time=$(date +%s)

    local config_json
    config_json=$(parse_toml_to_json "$test_config")

    local end_time=$(date +%s)

    # Should parse successfully
    [[ "$config_json" != "{}" ]]
    [[ -n "$config_json" ]]

    # Performance should be reasonable (allow up to 10 seconds for CI)
    if [[ "$start_time" != "$end_time" ]]; then
        local duration=$((end_time - start_time))
        [[ "$duration" -lt 10 ]]  # Less than 10 seconds
    fi
}

# Test nested TOML format detection and error code 6
@test "should detect nested TOML format and return error code 6" {
    local test_config="$TEST_CONFIG_DIR/nested_format.toml"

    cat > "$test_config" << 'EOF'
[theme]
name = "catppuccin"

[features]
show_commits = true
show_version = false

[colors.basic]
red = "red"
blue = "blue"
EOF

    # Call parse_toml_to_json and capture exit code
    local exit_code=0
    parse_toml_to_json "$test_config" >/dev/null 2>&1 || exit_code=$?

    # Should return exit code 6 for nested format detection
    [[ "$exit_code" -eq 6 ]]
}

# Test multiple nested sections trigger error code 6
@test "should detect multiple nested sections and return error code 6" {
    local test_config="$TEST_CONFIG_DIR/multiple_nested.toml"

    cat > "$test_config" << 'EOF'
theme.name = "catppuccin"

[theme]
inheritance = true

[colors.basic]
red = "red"

[features]
show_commits = true
EOF

    # Should fail on first nested section encountered
    local exit_code=0
    parse_toml_to_json "$test_config" >/dev/null 2>&1 || exit_code=$?

    [[ "$exit_code" -eq 6 ]]
}

# Test valid flat format works correctly (regression test)
@test "should parse valid flat TOML format without error" {
    local test_config="$TEST_CONFIG_DIR/valid_flat.toml"

    cat > "$test_config" << 'EOF'
theme.name = "catppuccin"
theme.inheritance.enabled = true

features.show_commits = true
features.show_version = false

colors.basic.red = "red"
colors.basic.blue = "blue"

timeouts.mcp = "3s"
timeouts.version = "2s"
EOF

    # Should parse successfully
    local config_json
    local exit_code

    config_json=$(parse_toml_to_json "$test_config")
    exit_code=$?

    # Should succeed with exit code 0
    [[ "$exit_code" -eq 0 ]]

    # Should contain valid JSON
    [[ "$config_json" != "{}" ]]
    [[ -n "$config_json" ]]

    # Verify specific flat format values are parsed correctly
    if command -v jq >/dev/null 2>&1; then
        local theme_name
        theme_name=$(echo "$config_json" | jq -r '.["theme.name"] // "default"')
        [[ "$theme_name" == "catppuccin" ]]

        local show_commits
        show_commits=$(echo "$config_json" | jq -r '.["features.show_commits"] // false')
        [[ "$show_commits" == "true" ]]

        local red_color
        red_color=$(echo "$config_json" | jq -r '.["colors.basic.red"] // "default"')
        [[ "$red_color" == "red" ]]
    fi
}

# Helper function to skip tests if jq is not available
skip_if_no_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not available for TOML integration testing"
    fi
}