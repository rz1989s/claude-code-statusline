#!/usr/bin/env bash

# Test Helpers for Claude Code Enhanced Statusline Tests

# Source setup_suite.bash for common functions (fail, assert_*, source_with_fallback)
_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$_HELPERS_DIR/../setup_suite.bash" ]]; then
    source "$_HELPERS_DIR/../setup_suite.bash"
fi

# Source script with fallback - silently skip if file doesn't exist
# (Also defined in setup_suite.bash, but needed here for standalone use)
if ! type source_with_fallback &>/dev/null; then
    source_with_fallback() {
        local script_path="$1"
        if [[ -f "$script_path" ]]; then
            STATUSLINE_SOURCING=true source "$script_path" 2>/dev/null || true
            return 0
        fi
        return 0
    }
fi

# Source the main statusline script for function testing
source_statusline_script() {
    # Source the script in a way that doesn't execute the main logic
    # We'll need to modify the main script to be testable
    source "$STATUSLINE_SCRIPT"
}

# Mock git repository status
setup_mock_git_repo() {
    local repo_dir="$1"
    local is_clean="${2:-clean}"

    mkdir -p "$repo_dir/.git"
    cd "$repo_dir"

    # Create comprehensive mock git command
    local diff_exit_code=0
    [[ "$is_clean" == "dirty" ]] && diff_exit_code=1

    cat > "$MOCK_BIN_DIR/git" << EOF
#!/bin/bash
case "\$1" in
    "rev-parse")
        case "\$2" in
            "--is-inside-work-tree")
                echo "true"
                exit 0
                ;;
            "--abbrev-ref")
                echo "main"
                exit 0
                ;;
            "--show-toplevel")
                echo "$repo_dir"
                exit 0
                ;;
            *)
                echo "mock-sha"
                exit 0
                ;;
        esac
        ;;
    "branch")
        echo "* main"
        ;;
    "diff")
        # Handle both: git diff --quiet and git diff --cached --quiet
        if [[ "\$2" == "--quiet" ]] || [[ "\$3" == "--quiet" ]]; then
            exit $diff_exit_code
        fi
        echo ""
        ;;
    "status")
        if [[ "\$2" == "--porcelain" ]]; then
            [[ $diff_exit_code -eq 1 ]] && echo "M file.txt"
        fi
        exit 0
        ;;
    "log")
        if [[ "\$*" == *"--oneline"* ]]; then
            echo "abc1234 Commit 1"
            echo "def5678 Commit 2"
        else
            echo "commit abc1234"
            echo "commit def5678"
        fi
        ;;
    "config")
        echo "mock-value"
        ;;
    "submodule")
        echo ""
        ;;
    *)
        # Default: return success
        exit 0
        ;;
esac
EOF
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

# Setup comprehensive mock environment for FAST test execution
# This mocks ALL external commands to avoid slow network/disk operations
setup_full_mock_environment() {
    local git_status="${1:-clean}"
    local mcp_status="${2:-connected}"
    local ccusage_status="${3:-success}"

    # Set short timeouts for test mode
    export CONFIG_MCP_TIMEOUT="1s"
    export CONFIG_VERSION_TIMEOUT="1s"
    export CONFIG_CCUSAGE_TIMEOUT="1s"

    # Disable expensive features in test mode (use correct ENV_CONFIG format)
    export ENV_CONFIG_FEATURES_SHOW_PRAYER_TIMES="false"
    export ENV_CONFIG_FEATURES_SHOW_HIJRI_DATE="false"
    export CONFIG_PRAYER_ENABLED="false"
    export CONFIG_LOCATION_ENABLED="false"
    export CONFIG_GITHUB_ENABLED="false"

    # Skip slow TOML parsing (saves 6+ seconds per test)
    export STATUSLINE_SKIP_TOML="true"

    # Use mock cost data ONLY when ccusage is available
    # This allows proper testing of "not_available" scenarios
    if [[ "$ccusage_status" != "not_available" ]]; then
        export STATUSLINE_MOCK_COST_DATA="true"
    else
        export STATUSLINE_MOCK_COST_DATA="false"
    fi

    # Force disable cache for predictable tests
    export ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING="false"

    setup_mock_git_repo "$TEST_TMP_DIR/mock_repo" "$git_status"
    setup_mock_ccusage "$ccusage_status"

    # Note: Do NOT mock jq - it's needed to parse the JSON input correctly
    # The statusline uses jq to extract current_dir and model_name from input

    # Create combined claude mock that handles both version and MCP commands
    local mcp_file=""
    case "$mcp_status" in
        "connected")
            mcp_file="$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_connected.txt"
            ;;
        "partial")
            mcp_file="$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_partial.txt"
            ;;
        "empty")
            mcp_file="$TEST_FIXTURES_DIR/sample_outputs/claude_mcp_list_empty.txt"
            ;;
        "timeout"|"not_available")
            # For timeout/not_available, create a failing mock
            create_failing_mock_command "claude" "claude: command not found" 127
            ;;
    esac

    # Create combined claude mock (unless timeout/not_available scenario)
    if [[ "$mcp_status" != "timeout" && "$mcp_status" != "not_available" ]]; then
        cat > "$MOCK_BIN_DIR/claude" << EOF
#!/bin/bash
if [[ "\$1" == "--version" ]]; then
    cat "$TEST_FIXTURES_DIR/sample_outputs/claude_version.txt"
elif [[ "\$1" == "mcp" && "\$2" == "list" ]]; then
    cat "$mcp_file"
else
    echo "Mock claude command: \$*"
fi
EOF
        chmod +x "$MOCK_BIN_DIR/claude"
    fi

    # Mock curl to avoid network calls (prayer API, location API)
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
# Fast mock curl - return empty JSON for any request
echo '{}'
exit 0
EOF
    chmod +x "$MOCK_BIN_DIR/curl"

    # Mock gh (GitHub CLI) to avoid API calls
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
# Fast mock gh - return success with minimal data
case "$1" in
    "api")
        echo '{"login":"test-user"}'
        ;;
    "auth")
        echo "Logged in as test-user"
        ;;
    *)
        echo "mock gh: $*"
        ;;
esac
exit 0
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    # Mock CoreLocationCLI (macOS GPS)
    cat > "$MOCK_BIN_DIR/CoreLocationCLI" << 'EOF'
#!/bin/bash
echo "-6.2088 106.8456"
exit 0
EOF
    chmod +x "$MOCK_BIN_DIR/CoreLocationCLI"

    # Mock timeout/gtimeout to just run command directly (faster)
    cat > "$MOCK_BIN_DIR/timeout" << 'EOF'
#!/bin/bash
# Skip timeout wrapper, run command directly for speed
shift  # Remove timeout duration
exec "$@"
EOF
    chmod +x "$MOCK_BIN_DIR/timeout"
    cp "$MOCK_BIN_DIR/timeout" "$MOCK_BIN_DIR/gtimeout"

    # Create simple mock date command - pass through to system date
    cat > "$MOCK_BIN_DIR/date" << 'EOF'
#!/bin/bash
exec /bin/date "$@"
EOF
    chmod +x "$MOCK_BIN_DIR/date"

    # Mock bc and python3 for calculations
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

    # Should have at least 3 lines of output
    if [[ "$line_count" -lt 3 ]]; then
        echo "Invalid line count: expected at least 3 lines, got $line_count"
        return 1
    fi

    # Check that output contains key indicators (flexible positioning)
    # Line 1 should have separators
    local line1
    line1=$(extract_line_from_output 1 "$output_text")
    if ! echo "$line1" | grep -q "│"; then
        echo "Line 1 missing separators: $line1"
        return 1
    fi

    # Output should contain cost indicators somewhere
    if ! echo "$output_text" | grep -q "\$"; then
        echo "Output missing cost indicators"
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

# Performance testing helper (macOS compatible)
measure_execution_time() {
    local command="$1"
    local start_time end_time duration

    # Use seconds only - milliseconds not reliable on macOS
    start_time=$(/bin/date +%s)
    eval "$command"
    end_time=$(/bin/date +%s)

    # Return duration in milliseconds (approximate from seconds)
    duration=$(( (end_time - start_time) * 1000 ))
    echo "$duration"
}

# Concurrent testing helper with timeout protection
run_concurrent_tests() {
    local num_processes="$1"
    local test_command="$2"
    local pids=()
    local results=()
    local timeout_cmd

    # Use gtimeout on macOS, timeout on Linux
    timeout_cmd=$(command -v gtimeout 2>/dev/null || command -v timeout 2>/dev/null || echo "")

    # Start concurrent processes with timeout
    for ((i=1; i<=num_processes; i++)); do
        if [[ -n "$timeout_cmd" ]]; then
            $timeout_cmd 10s bash -c "$test_command" &
        else
            eval "$test_command" &
        fi
        pids+=($!)
    done

    # Wait for all processes and collect results (with timeout)
    local wait_result=0
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || wait_result=1
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