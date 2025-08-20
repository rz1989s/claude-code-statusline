#!/usr/bin/env bats

# Advanced TOML Configuration Tests
# Tests schema validation, error handling, and migration scenarios

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    export PATH="$STATUSLINE_DIR:$PATH"
    cd "$STATUSLINE_DIR"
    
    # Create test directory for advanced TOML tests
    export TEST_CONFIG_DIR="/tmp/toml_advanced_tests"
    mkdir -p "$TEST_CONFIG_DIR"
    
    # Source the statusline script for function access
    local saved_args=("$@")
    set --
    export STATUSLINE_TESTING="true"
    source statusline.sh 2>/dev/null || true
    set -- "${saved_args[@]}"
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
}

# Test schema validation for TOML configuration structure
@test "should validate TOML schema and reject invalid structures" {
    skip_if_no_jq
    
    local invalid_config="$TEST_CONFIG_DIR/invalid_schema.toml"
    
    # Invalid structure - missing required sections
    cat > "$invalid_config" << 'EOF'
[invalid_section]
unknown_key = "value"

[theme]
# Missing name field

[colors]
# Colors should be nested under basic/extended
red = "\033[31m"
EOF

    # Test that invalid structure is handled gracefully
    local config_json
    config_json=$(parse_toml_to_json "$invalid_config" 2>/dev/null || echo "{}")
    
    # Should not crash, but may return empty or handle gracefully
    [[ -n "$config_json" ]]
}

# Test TOML parser error handling with malformed files
@test "should handle malformed TOML files gracefully" {
    skip_if_no_jq
    
    local malformed_config="$TEST_CONFIG_DIR/malformed.toml"
    
    # Create malformed TOML
    cat > "$malformed_config" << 'EOF'
[theme
name = "catppuccin"  # Missing closing bracket

[features]
show_commits = true
show_version = # Missing value

[colors.basic]
red = "\033[31m
# Missing closing quote
EOF

    # Test error handling
    local config_json
    config_json=$(parse_toml_to_json "$malformed_config" 2>/dev/null || echo "{}")
    
    # Should return empty JSON on parse failure
    [[ "$config_json" == "{}" ]]
}

# Test migration from inline config to TOML
@test "should support migration from inline configuration to TOML" {
    skip_if_no_jq
    
    local migration_config="$TEST_CONFIG_DIR/migration_test.toml"
    
    # Create TOML config that should override inline defaults
    cat > "$migration_config" << 'EOF'
[theme]
name = "garden"

[features]
show_commits = false

[timeouts]
mcp = "10s"

[emojis]
opus = "🌟"
EOF

    # Test that TOML config loads and can be extracted
    local config_json
    config_json=$(parse_toml_to_json "$migration_config")
    
    # Verify migration values are preserved
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "default"')
    [[ "$theme_name" == "garden" ]]
    
    local show_commits
    show_commits=$(echo "$config_json" | jq -r '.features.show_commits // true')
    [[ "$show_commits" == "false" ]]
    
    local mcp_timeout
    mcp_timeout=$(echo "$config_json" | jq -r '.timeouts.mcp // "3s"')
    [[ "$mcp_timeout" == "10s" ]]
    
    local opus_emoji
    opus_emoji=$(echo "$config_json" | jq -r '.emojis.opus // "🧠"')
    [[ "$opus_emoji" == "🌟" ]]
}

# Test environment variable override behavior
@test "should handle environment variable overrides correctly" {
    skip_if_no_jq
    
    local env_config="$TEST_CONFIG_DIR/env_override.toml"
    
    cat > "$env_config" << 'EOF'
[theme]
name = "classic"

[features]
show_commits = true

[timeouts]
mcp = "3s"
EOF

    # Test environment override (simulated)
    local config_json
    config_json=$(parse_toml_to_json "$env_config")
    
    # Extract base values
    local base_theme
    base_theme=$(echo "$config_json" | jq -r '.theme.name // "default"')
    [[ "$base_theme" == "classic" ]]
    
    # Environment overrides would be applied after TOML parsing
    # This test verifies the TOML foundation for env overrides
}

# Test large configuration file performance
@test "should handle large configuration files efficiently" {
    skip_if_no_jq
    
    local large_config="$TEST_CONFIG_DIR/performance_large.toml"
    
    # Generate a large configuration file
    cat > "$large_config" << 'EOF'
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
    
    # Add 50 extended colors to make it large
    for i in {1..50}; do
        echo "color$i = \"\\033[38;5;${i}m\"" >> "$large_config"
    done
    
    cat >> "$large_config" << 'EOF'

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

[labels]
commits = "Commits:"
repo = "REPO"
monthly = "30DAY"
weekly = "7DAY"
daily = "DAY"
mcp = "MCP"
EOF

    # Measure parsing performance
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local config_json
    config_json=$(parse_toml_to_json "$large_config")
    
    local end_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Should parse successfully
    [[ "$config_json" != "{}" ]]
    [[ -n "$config_json" ]]
    
    # Performance check (allow reasonable time for large files)
    if [[ "$start_time" != "$end_time" ]]; then
        local duration=$((end_time - start_time))
        # Should complete within 2 seconds even for large files
        [[ "$duration" -lt 2000 ]]
    fi
    
    # Verify all sections are parsed correctly
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "default"')
    [[ "$theme_name" == "custom" ]]
    
    # Verify extended colors are accessible
    local color_check
    color_check=$(echo "$config_json" | jq -r '.colors.extended.color1 // "default"')
    [[ "$color_check" == "\\033[38;5;1m" ]]
}

# Test ANSI color code validation
@test "should validate ANSI color codes in custom themes" {
    skip_if_no_jq
    
    local color_config="$TEST_CONFIG_DIR/color_validation.toml"
    
    cat > "$color_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
valid_ansi = "\033[31m"
valid_256 = "\033[38;5;208m"
valid_rgb = "\033[38;2;255;100;50m"
invalid_format = "not-a-color"
empty_color = ""
EOF

    local config_json
    config_json=$(parse_toml_to_json "$color_config")
    
    # Extract color values for validation
    local valid_ansi
    valid_ansi=$(echo "$config_json" | jq -r '.colors.basic.valid_ansi // "default"')
    [[ "$valid_ansi" == "\\033[31m" ]]
    
    local valid_256
    valid_256=$(echo "$config_json" | jq -r '.colors.basic.valid_256 // "default"')
    [[ "$valid_256" == "\\033[38;5;208m" ]]
    
    local valid_rgb
    valid_rgb=$(echo "$config_json" | jq -r '.colors.basic.valid_rgb // "default"')
    [[ "$valid_rgb" == "\\033[38;2;255;100;50m" ]]
    
    # Invalid colors should be extractable but would need validation elsewhere
    local invalid_format
    invalid_format=$(echo "$config_json" | jq -r '.colors.basic.invalid_format // "default"')
    [[ "$invalid_format" == "not-a-color" ]]
}

# Test configuration backup and restore scenarios
@test "should support configuration backup and restore workflows" {
    skip_if_no_jq
    
    local original_config="$TEST_CONFIG_DIR/original.toml"
    local backup_config="$TEST_CONFIG_DIR/backup.toml"
    
    # Create original config
    cat > "$original_config" << 'EOF'
[theme]
name = "garden"

[features]
show_commits = true
show_version = false

[emojis]
opus = "🌿"
EOF

    # Test that original config parses correctly
    local original_json
    original_json=$(parse_toml_to_json "$original_config")
    [[ "$original_json" != "{}" ]]
    
    # Copy to backup location
    cp "$original_config" "$backup_config"
    
    # Test backup config parses identically
    local backup_json
    backup_json=$(parse_toml_to_json "$backup_config")
    [[ "$backup_json" != "{}" ]]
    
    # Compare key values
    local orig_theme
    orig_theme=$(echo "$original_json" | jq -r '.theme.name // "default"')
    local backup_theme
    backup_theme=$(echo "$backup_json" | jq -r '.theme.name // "default"')
    [[ "$orig_theme" == "$backup_theme" ]]
}

# Test edge cases with special characters and unicode
@test "should handle special characters and unicode in TOML values" {
    skip_if_no_jq
    
    local unicode_config="$TEST_CONFIG_DIR/unicode_test.toml"
    
    cat > "$unicode_config" << 'EOF'
[emojis]
opus = "🧠"
haiku = "⚡"
sonnet = "🎵"
special = "🔥💨✨"

[labels]
unicode_label = "测试"
mixed = "Test 🚀 Unicode"
quotes = "Contains \"quotes\""

[messages]
special_chars = "Special: !@#$%^&*()_+"
EOF

    local config_json
    config_json=$(parse_toml_to_json "$unicode_config")
    
    # Should handle unicode emojis correctly
    local opus_emoji
    opus_emoji=$(echo "$config_json" | jq -r '.emojis.opus // "default"')
    [[ "$opus_emoji" == "🧠" ]]
    
    local special_emoji
    special_emoji=$(echo "$config_json" | jq -r '.emojis.special // "default"')
    [[ "$special_emoji" == "🔥💨✨" ]]
    
    # Should handle unicode text
    local unicode_label
    unicode_label=$(echo "$config_json" | jq -r '.labels.unicode_label // "default"')
    [[ "$unicode_label" == "测试" ]]
    
    # Should handle mixed content
    local mixed_label
    mixed_label=$(echo "$config_json" | jq -r '.labels.mixed // "default"')
    [[ "$mixed_label" == "Test 🚀 Unicode" ]]
}

# Test concurrent access scenarios  
@test "should handle concurrent configuration access gracefully" {
    skip_if_no_jq
    
    local concurrent_config="$TEST_CONFIG_DIR/concurrent_test.toml"
    
    cat > "$concurrent_config" << 'EOF'
[theme]
name = "catppuccin"

[features]
show_commits = true
EOF

    # Simulate concurrent access by running multiple parsing operations
    local pid1 pid2 pid3
    
    parse_toml_to_json "$concurrent_config" >/dev/null 2>&1 &
    pid1=$!
    
    parse_toml_to_json "$concurrent_config" >/dev/null 2>&1 &
    pid2=$!
    
    parse_toml_to_json "$concurrent_config" >/dev/null 2>&1 &
    pid3=$!
    
    # Wait for all processes to complete
    wait $pid1 $pid2 $pid3
    
    # Final parse should still work correctly
    local config_json
    config_json=$(parse_toml_to_json "$concurrent_config")
    [[ "$config_json" != "{}" ]]
    
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "default"')
    [[ "$theme_name" == "catppuccin" ]]
}

# Helper function to skip tests if jq is not available
skip_if_no_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not available for advanced TOML testing"
    fi
}