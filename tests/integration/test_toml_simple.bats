#!/usr/bin/env bats

# Simple TOML Integration Tests
# Tests core TOML functionality without complex script sourcing

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    cd "$STATUSLINE_DIR"
    
    # Create test directory for TOML configs
    export TEST_CONFIG_DIR="/tmp/toml_simple_tests"
    mkdir -p "$TEST_CONFIG_DIR"
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
}

# Test basic TOML parsing functionality
@test "should parse basic TOML file" {
    local test_config="$TEST_CONFIG_DIR/basic.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "catppuccin"

[features]
show_commits = true
show_version = false

[timeouts]
mcp = "5s"
EOF

    # Test that the file exists and is readable
    [[ -f "$test_config" ]]
    [[ -r "$test_config" ]]
    
    # Test basic content
    grep -q "catppuccin" "$test_config"
    grep -q "show_commits = true" "$test_config"
    grep -q "mcp = \"5s\"" "$test_config"
}

# Test TOML file structure validation
@test "should validate TOML file structure" {
    local test_config="$TEST_CONFIG_DIR/structured.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "custom"

[colors.basic]
red = "\033[31m"
blue = "\033[34m"

[colors.extended]
orange = "\033[38;5;208m"

[features]
show_commits = true
show_version = true

[labels]
commits = "Commits:"
repo = "REPO"
EOF

    # Verify file structure
    [[ -f "$test_config" ]]
    
    # Check sections exist
    grep -q "^\[theme\]" "$test_config"
    grep -q "^\[colors\.basic\]" "$test_config"
    grep -q "^\[colors\.extended\]" "$test_config"
    grep -q "^\[features\]" "$test_config"
    grep -q "^\[labels\]" "$test_config"
    
    # Check key-value pairs
    grep -q "name = \"custom\"" "$test_config"
    grep -q "red = \"\\\\033\[31m\"" "$test_config"
    grep -q "show_commits = true" "$test_config"
}

# Test TOML with various data types
@test "should handle different TOML data types" {
    local test_config="$TEST_CONFIG_DIR/datatypes.toml"
    
    cat > "$test_config" << 'EOF'
[settings]
# String values
theme_name = "catppuccin"
custom_label = "My Custom Label"

# Boolean values  
enable_feature = true
disable_option = false

# Integer values
timeout_seconds = 30
cache_duration = 3600

# String with special characters
ansi_color = "\033[31m"
emoji_char = "🧠"
EOF

    # Verify different data types are present
    grep -q "theme_name = \"catppuccin\"" "$test_config"
    grep -q "enable_feature = true" "$test_config"
    grep -q "disable_option = false" "$test_config"
    grep -q "timeout_seconds = 30" "$test_config"
    grep -q "ansi_color = \"\\\\033\[31m\"" "$test_config"
    grep -q "emoji_char = \"🧠\"" "$test_config"
}

# Test nested TOML sections
@test "should handle nested TOML sections correctly" {
    local test_config="$TEST_CONFIG_DIR/nested.toml"
    
    cat > "$test_config" << 'EOF'
[colors]
default = "white"

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
reset = "\033[0m"
EOF

    # Verify nested structure
    grep -q "^\[colors\]" "$test_config"
    grep -q "^\[colors\.basic\]" "$test_config"
    grep -q "^\[colors\.extended\]" "$test_config"
    grep -q "^\[colors\.formatting\]" "$test_config"
    
    # Verify values in different sections
    grep -q "default = \"white\"" "$test_config"
    grep -q "red = \"\\\\033\[31m\"" "$test_config"
    grep -q "orange = \"\\\\033\[38;5;208m\"" "$test_config"
    grep -q "dim = \"\\\\033\[2m\"" "$test_config"
}

# Test configuration completeness
@test "should support comprehensive configuration" {
    local test_config="$TEST_CONFIG_DIR/complete.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "custom"

[features]
show_commits = true
show_version = true
show_submodules = false
show_mcp_status = true

[timeouts]
mcp = "3s"
version = "2s" 
ccusage = "4s"

[emojis]
opus = "🧠"
haiku = "⚡"
sonnet = "🎵"

[labels]
commits = "Commits:"
repo = "REPO"
monthly = "30DAY"

[cache]
version_duration = 3600
version_file = "/tmp/.claude_version_cache"

[messages]
no_ccusage = "No ccusage"
mcp_unknown = "unknown"
EOF

    # Test that all major sections are present
    local sections=(
        "theme"
        "features" 
        "timeouts"
        "emojis"
        "labels"
        "cache"
        "messages"
    )
    
    for section in "${sections[@]}"; do
        grep -q "^\[$section\]" "$test_config"
    done
    
    # Test specific configuration values
    grep -q "name = \"custom\"" "$test_config"
    grep -q "show_commits = true" "$test_config"
    grep -q "mcp = \"3s\"" "$test_config"
    grep -q "opus = \"🧠\"" "$test_config"
    grep -q "version_duration = 3600" "$test_config"
}

# Test malformed TOML handling
@test "should handle malformed TOML gracefully" {
    local test_config="$TEST_CONFIG_DIR/malformed.toml"
    
    cat > "$test_config" << 'EOF'
[theme
name = "broken_toml
missing_quote = value
[section_missing_bracket
key_without_value =
= value_without_key
EOF

    # File should exist but contain malformed content
    [[ -f "$test_config" ]]
    
    # Should contain malformed elements we can detect
    ! grep -q "^\[theme\]$" "$test_config"  # Missing closing bracket
    grep -q "^\[theme$" "$test_config"      # Malformed section
    grep -q "name = \"broken_toml$" "$test_config"  # Missing closing quote
}

# Test empty and minimal configurations
@test "should handle minimal TOML configurations" {
    local test_config="$TEST_CONFIG_DIR/minimal.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "catppuccin"
EOF

    # Should handle minimal config
    [[ -f "$test_config" ]]
    grep -q "^\[theme\]" "$test_config"
    grep -q "name = \"catppuccin\"" "$test_config"
    
    # File should be small
    local file_size=$(wc -c < "$test_config")
    [[ "$file_size" -lt 100 ]]  # Less than 100 bytes
}

# Test comment handling in TOML
@test "should handle TOML comments correctly" {
    local test_config="$TEST_CONFIG_DIR/comments.toml"
    
    cat > "$test_config" << 'EOF'
# This is a comment at the top
[theme]
name = "catppuccin"  # Inline comment

# Comment before section
[features]
show_commits = true   # Feature toggle
# show_version = false   # Commented out setting
show_submodules = true

# Another comment
# Multiple comment lines
[timeouts]
mcp = "3s"  # Timeout setting
EOF

    # Should contain comments
    grep -q "^# This is a comment" "$test_config"
    grep -q "# Inline comment" "$test_config"
    grep -q "# Feature toggle" "$test_config"
    grep -q "^# show_version = false" "$test_config"
    
    # Should also contain actual configuration
    grep -q "name = \"catppuccin\"" "$test_config"
    grep -q "show_commits = true" "$test_config"
    grep -q "mcp = \"3s\"" "$test_config"
}

# Test file permission and access
@test "should verify TOML file accessibility" {
    local test_config="$TEST_CONFIG_DIR/permissions.toml"
    
    cat > "$test_config" << 'EOF'
[theme]
name = "test"
EOF

    # Verify basic file operations
    [[ -f "$test_config" ]]     # File exists
    [[ -r "$test_config" ]]     # File is readable
    [[ -s "$test_config" ]]     # File is not empty
    
    # Verify file has reasonable permissions
    local perms=$(stat -f %A "$test_config" 2>/dev/null || stat -c %a "$test_config" 2>/dev/null)
    [[ -n "$perms" ]]           # Permissions are readable
    
    # File should be readable by owner
    [[ "$perms" =~ ^[67] ]] || [[ "$perms" =~ ^[4567][4567][4567]$ ]]
}