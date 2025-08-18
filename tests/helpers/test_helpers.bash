#!/usr/bin/env bash

# Test Helpers for Claude Code Enhanced Statusline Tests

# Source the main statusline script for function testing
source_statusline_script() {
    # Source the script in a way that doesn't execute the main logic
    # We'll need to modify the main script to be testable
    source "$STATUSLINE_SCRIPT"
}

# Mock git repository status
setup_mock_git_repo() {
    local repo_dir="$1"
    local is_clean="${2:-true}"
    
    mkdir -p "$repo_dir/.git"
    cd "$repo_dir"
    
    # Create mock git commands
    if [[ "$is_clean" == "true" ]]; then
        create_mock_command "git" "* main"
        
        cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
case "$1" in
    "rev-parse")
        if [[ "$2" == "--is-inside-work-tree" ]]; then
            exit 0
        fi
        ;;
    "branch")
        echo "* main"
        ;;
    "diff")
        if [[ "$2" == "--quiet" ]]; then
            exit 0  # Clean repo
        fi
        ;;
    "log")
        echo "commit1"
        echo "commit2"
        ;;
    *)
        echo "Mock git command: $*"
        ;;
esac
EOF
    else
        # Dirty repository
        cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
case "$1" in
    "rev-parse")
        if [[ "$2" == "--is-inside-work-tree" ]]; then
            exit 0
        fi
        ;;
    "branch")
        echo "* main"
        ;;
    "diff")
        if [[ "$2" == "--quiet" ]]; then
            exit 1  # Dirty repo
        fi
        ;;
    "log")
        echo "commit1"
        echo "commit2"
        echo "commit3"
        ;;
    *)
        echo "Mock git command: $*"
        ;;
esac
EOF
    fi
    chmod +x "$MOCK_BIN_DIR/git"
}

# Setup mock commands for ccusage
setup_mock_ccusage() {
    local scenario="${1:-success}"
    
    case "$scenario" in
        "success")
            create_mock_command "bunx" "" 0
            
            cat > "$MOCK_BIN_DIR/bunx" << EOF
#!/bin/bash
if [[ "\$1" == "ccusage" ]]; then
    case "\$2" in
        "--version")
            echo "ccusage 1.0.0"
            exit 0
            ;;
        "session")
            cat "$TEST_FIXTURES_DIR/sample_outputs/ccusage_session.json"
            ;;
        "daily")
            cat "$TEST_FIXTURES_DIR/sample_outputs/ccusage_daily.json"
            ;;
        "blocks")
            if [[ "\$3" == "--active" ]]; then
                cat "$TEST_FIXTURES_DIR/sample_outputs/ccusage_blocks_active.json"
            fi
            ;;
        *)
            echo "Mock ccusage command: \$*"
            ;;
    esac
else
    echo "Mock bunx command: \$*"
fi
EOF
            chmod +x "$MOCK_BIN_DIR/bunx"
            ;;
        "not_available")
            create_failing_mock_command "bunx" "bunx: command not found" 127
            ;;
        "timeout")
            create_mock_command "bunx" "" 124  # timeout exit code
            ;;
    esac
}

# Setup mock MCP commands
setup_mock_mcp() {
    local scenario="${1:-connected}"
    
    case "$scenario" in
        "connected")
            create_mock_command_from_file "claude" "$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_connected.txt"
            ;;
        "partial")
            create_mock_command_from_file "claude" "$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_partial.txt"
            ;;
        "empty")
            create_mock_command_from_file "claude" "$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_empty.txt"
            ;;
        "timeout")
            create_failing_mock_command "claude" "" 124
            ;;
        "not_available")
            create_failing_mock_command "claude" "claude: command not found" 127
            ;;
    esac
}

# Setup mock version command
setup_mock_version() {
    local scenario="${1:-success}"
    
    case "$scenario" in
        "success")
            cat > "$MOCK_BIN_DIR/claude" << EOF
#!/bin/bash
if [[ "\$1" == "--version" ]]; then
    cat "$TEST_FIXTURES_DIR/sample_outputs/claude_version.txt"
elif [[ "\$1" == "mcp" && "\$2" == "list" ]]; then
    setup_mock_mcp connected
    cat "$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_connected.txt"
else
    echo "Mock claude command: \$*"
fi
EOF
            chmod +x "$MOCK_BIN_DIR/claude"
            ;;
        "timeout")
            create_failing_mock_command "claude" "" 124
            ;;
    esac
}

# Setup comprehensive mock environment
setup_full_mock_environment() {
    local git_status="${1:-clean}"
    local mcp_status="${2:-connected}"
    local ccusage_status="${3:-success}"
    
    setup_mock_git_repo "$TEST_TMP_DIR/mock_repo" "$git_status"
    setup_mock_mcp "$mcp_status"
    setup_mock_ccusage "$ccusage_status"
    setup_mock_version "success"
    
    # Mock other common commands
    create_mock_command "jq" "mocked jq output"
    create_mock_command "date" "$(date)"
    create_mock_command "bc" "0.00"
    create_mock_command "python3" "12.34"
}

# Extract specific sections from statusline output
extract_line_from_output() {
    local line_number="$1"
    local output_text="$2"
    
    echo "$output_text" | sed -n "${line_number}p"
}

# Clean ANSI escape codes from output
strip_ansi_codes() {
    local text="$1"
    echo "$text" | sed 's/\x1b\[[0-9;]*m//g'
}

# Validate statusline output format
validate_statusline_format() {
    local output_text="$1"
    local line_count
    
    line_count=$(echo "$output_text" | wc -l | tr -d ' ')
    
    # Should have 3-4 lines depending on active block
    if [[ "$line_count" -lt 3 || "$line_count" -gt 4 ]]; then
        echo "Invalid line count: expected 3-4 lines, got $line_count"
        return 1
    fi
    
    # Line 1: Basic repo info
    local line1
    line1=$(extract_line_from_output 1 "$output_text")
    if ! echo "$line1" | grep -q "│"; then
        echo "Line 1 missing separators: $line1"
        return 1
    fi
    
    # Line 2: Cost tracking
    local line2
    line2=$(extract_line_from_output 2 "$output_text")
    if ! echo "$line2" | grep -q "\$"; then
        echo "Line 2 missing cost indicators: $line2"
        return 1
    fi
    
    # Line 3: MCP status
    local line3
    line3=$(extract_line_from_output 3 "$output_text")
    if ! echo "$line3" | grep -q "MCP"; then
        echo "Line 3 missing MCP status: $line3"
        return 1
    fi
    
    return 0
}

# Test specific configuration scenarios
test_with_config() {
    local config_overrides="$1"
    shift
    local input="$*"
    
    # Create temporary config file
    local temp_config="$TEST_TMP_DIR/test_config.sh"
    
    cat > "$temp_config" << EOF
# Test configuration overrides
$config_overrides
EOF
    
    # Source the config and run test
    source "$temp_config"
    echo "$input" | "$STATUSLINE_SCRIPT"
}

# Performance testing helper
measure_execution_time() {
    local command="$1"
    local start_time end_time duration
    
    start_time=$(date +%s%N)
    eval "$command"
    end_time=$(date +%s%N)
    
    duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    echo "$duration"
}

# Concurrent testing helper
run_concurrent_tests() {
    local num_processes="$1"
    local test_command="$2"
    local pids=()
    local results=()
    
    # Start concurrent processes
    for ((i=1; i<=num_processes; i++)); do
        eval "$test_command" &
        pids+=($!)
    done
    
    # Wait for all processes and collect results
    for pid in "${pids[@]}"; do
        wait "$pid"
        results+=($?)
    done
    
    # Check if all succeeded
    for result in "${results[@]}"; do
        if [[ "$result" -ne 0 ]]; then
            return 1
        fi
    done
    
    return 0
}