#!/usr/bin/env bats

# Integration tests for complete statusline functionality

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    # Setup a complete mock environment for integration testing
    setup_full_mock_environment "clean" "connected" "success"
    cd "$TEST_TMP_DIR/mock_repo"
}

teardown() {
    common_teardown
}

# Test complete statusline output with optimal conditions
@test "should generate complete statusline with all features working" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    
    # Validate overall structure
    validate_statusline_format "$output"
    
    # Check that all expected sections are present
    assert_output_contains "mock_repo"       # Directory path
    assert_output_contains "main"            # Git branch
    assert_output_contains "✅"              # Clean status emoji
    assert_output_contains "Commits:"        # Commit label
    assert_output_contains "CC:"             # Claude Code version prefix
    assert_output_contains "SL:"             # Statusline version prefix
    assert_output_contains "🎵"              # Sonnet emoji
    assert_output_contains "MCP"             # MCP status
    assert_output_contains "\$"              # Cost indicators
}

@test "should generate statusline for dirty git repository" {
    setup_full_mock_environment "dirty" "connected" "success"
    cd "$TEST_TMP_DIR/mock_repo"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "📁"              # Dirty status emoji
}

@test "should handle partial MCP connectivity" {
    setup_full_mock_environment "clean" "partial" "success"
    cd "$TEST_TMP_DIR/mock_repo"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "MCP:2/3"         # Partial connection status (2 of 3 connected)
}

@test "should handle missing ccusage gracefully" {
    setup_full_mock_environment "clean" "connected" "not_available"
    cd "$TEST_TMP_DIR/mock_repo"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "No ccusage"      # Should show fallback message
}

@test "should work in non-git directory" {
    # Create non-git directory
    local non_git_dir="$TEST_TMP_DIR/non_git"
    mkdir -p "$non_git_dir"
    cd "$non_git_dir"
    
    # Mock git to fail
    create_failing_mock_command "git" "not a git repository" 128
    
    local test_input=$(generate_test_input "$non_git_dir" "Claude 3.5 Haiku")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    # Should not contain git-specific information
    refute_output --partial "main"
    refute_output --partial "✅"
    assert_output_contains "⚡"               # Haiku emoji
    assert_output_contains "Commits:0"       # Zero commits for non-git
}

# Test different Claude model emojis
@test "should display correct emoji for Claude Opus" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3 Opus")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "🧠"              # Opus emoji
}

@test "should display correct emoji for Claude Haiku" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3 Haiku")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "⚡"              # Haiku emoji
}

@test "should display correct emoji for Claude Sonnet" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "🎵"              # Sonnet emoji
}

@test "should display default emoji for unknown model" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Unknown Model")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "🤖"              # Default emoji
}

# Test with different themes
@test "should render correctly with classic theme" {
    export CONFIG_THEME="classic"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    validate_statusline_format "$output"
}

@test "should render correctly with garden theme" {
    export CONFIG_THEME="garden"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    validate_statusline_format "$output"
}

@test "should render correctly with catppuccin theme" {
    export CONFIG_THEME="catppuccin"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    validate_statusline_format "$output"
}

# Test with active billing block
@test "should display reset info when active block exists" {
    # Mock ccusage to return active block
    cat > "$MOCK_BIN_DIR/bunx" << EOF
#!/bin/bash
if [[ "\$1" == "ccusage" ]]; then
    case "\$2" in
        "--version")
            echo "ccusage 1.0.0"
            ;;
        "session"|"daily")
            echo '{"sessions":[],"daily":[],"totals":{"totalCost":0.00}}'
            ;;
        "blocks")
            if [[ "\$3" == "--active" ]]; then
                cat "$TEST_FIXTURES_DIR/sample_outputs/ccusage_blocks_active.json"
            fi
            ;;
    esac
fi
EOF
    chmod +x "$MOCK_BIN_DIR/bunx"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "🔥LIVE"          # Active block indicator (no space between emoji and label)
    assert_output_contains "RESET at"        # Reset time info
}

# Test performance under normal conditions
@test "should complete within reasonable time" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    local execution_time
    execution_time=$(measure_execution_time "echo '$test_input' | '$STATUSLINE_SCRIPT'")
    
    # Should complete within 5 seconds under normal conditions
    if [ "$execution_time" -gt 5000 ]; then
        fail "Statusline took too long: ${execution_time}ms"
    fi
}

# Test timeout handling
@test "should handle MCP timeout gracefully" {
    # Create mock claude that simulates timeout (exit code 124)
    cat > "$MOCK_BIN_DIR/claude" << 'EOF'
#!/bin/bash
if [[ "$1" == "mcp" && "$2" == "list" ]]; then
    # Simulate timeout immediately - exit code 124 is what timeout returns
    exit 124
elif [[ "$1" == "--version" ]]; then
    echo "1.0.81 (Claude Code)"
fi
EOF
    chmod +x "$MOCK_BIN_DIR/claude"

    # Set short timeout
    export CONFIG_MCP_TIMEOUT="1s"

    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")

    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"

    assert_success
    assert_output_contains "MCP:?/?"         # Should show unknown status after timeout
}

@test "should handle ccusage timeout gracefully" {
    # Create mock ccusage that simulates timeout (exit code 124)
    cat > "$MOCK_BIN_DIR/bunx" << 'EOF'
#!/bin/bash
if [[ "$1" == "ccusage" ]]; then
    if [[ "$2" == "--version" ]]; then
        echo "ccusage 1.0.0"
    else
        # Simulate timeout immediately - exit code 124 is what timeout returns
        exit 124
    fi
fi
EOF
    chmod +x "$MOCK_BIN_DIR/bunx"

    export CONFIG_CCUSAGE_TIMEOUT="1s"

    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")

    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"

    assert_success
    # Should show fallback values for cost tracking
    assert_output_contains "\$0.00"
}

# Test with special characters in paths
@test "should handle paths with spaces and special characters" {
    local special_dir="$TEST_TMP_DIR/path with spaces and (parentheses)"
    mkdir -p "$special_dir"
    setup_mock_git_repo "$special_dir" "clean"
    cd "$special_dir"
    
    local test_input=$(generate_test_input "$special_dir" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "spaces"          # Should handle path with spaces
}

# Test concurrent execution
@test "should handle concurrent statusline executions" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    # Run 5 concurrent statusline executions
    local success
    success=$(run_concurrent_tests 5 "echo '$test_input' | '$STATUSLINE_SCRIPT' >/dev/null")
    
    [ "$success" -eq 0 ]  # All should succeed
}

# Test error recovery
@test "should continue working after temporary failures" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    # First run with failing MCP
    setup_mock_mcp "timeout"
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    assert_success
    assert_output_contains "MCP:?/?"

    # Second run with working MCP
    setup_mock_mcp "connected"
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    assert_success
    assert_output_contains "MCP:3/3"
}

# Test cache behavior
@test "should use cached version information" {
    # Create cached version
    local cache_file="$CONFIG_VERSION_CACHE_FILE"
    echo "1.0.99" > "$cache_file"
    
    # Make cache file recent
    touch "$cache_file"
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    assert_output_contains "ver1.0.99"       # Should use cached version
}

# Test with minimal configuration
@test "should work with minimal feature set enabled" {
    export CONFIG_SHOW_MCP_STATUS=false
    export CONFIG_SHOW_COST_TRACKING=false
    export CONFIG_SHOW_SUBMODULES=false
    
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    # Should still have basic info
    assert_output_contains "mock_repo"
    assert_output_contains "🎵"
    # Should not have disabled features
    refute_output --partial "MCP"
    refute_output --partial "\$"
}

# Test output format consistency
@test "output should have consistent line structure" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    
    # Count lines
    local line_count=$(echo "$output" | wc -l | tr -d ' ')
    
    # Should have 3 or 4 lines (4 when active block exists)
    [[ "$line_count" -eq 3 ]] || [[ "$line_count" -eq 4 ]]
    
    # Each line should have proper separators
    local line1=$(extract_line_from_output 1 "$output")
    local line2=$(extract_line_from_output 2 "$output")
    local line3=$(extract_line_from_output 3 "$output")
    
    assert_output_contains "│"  # Should have pipe separators
}

@test "should strip ANSI codes cleanly for testing" {
    local test_input=$(generate_test_input "$TEST_TMP_DIR/mock_repo" "Claude 3.5 Sonnet")
    
    run bash -c "echo '$test_input' | '$STATUSLINE_SCRIPT'"
    
    assert_success
    
    # Test that we can strip ANSI codes for clean text analysis
    local clean_output
    clean_output=$(strip_ansi_codes "$output")
    
    # Clean output should still contain key information
    [[ "$clean_output" == *"mock_repo"* ]]
    [[ "$clean_output" == *"Commits:"* ]]
    [[ "$clean_output" == *"MCP"* ]]
    
    # Should not contain ANSI escape sequences
    [[ "$clean_output" != *"\033["* ]]
}