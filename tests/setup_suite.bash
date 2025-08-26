#!/usr/bin/env bash

# Test Suite Setup for Claude Code Enhanced Statusline
# This file is loaded before all test suites

# Set up test environment
export BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
export STATUSLINE_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export STATUSLINE_SCRIPT="$STATUSLINE_ROOT/statusline.sh"

# Fallback path resolution for CI environments
if [[ ! -f "$STATUSLINE_SCRIPT" ]]; then
    # Try alternative path resolution methods
    if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
        export STATUSLINE_ROOT="$GITHUB_WORKSPACE"
        export STATUSLINE_SCRIPT="$STATUSLINE_ROOT/statusline.sh"
    elif [[ -f "$(pwd)/statusline.sh" ]]; then
        export STATUSLINE_ROOT="$(pwd)"
        export STATUSLINE_SCRIPT="$STATUSLINE_ROOT/statusline.sh"
    elif [[ -f "../statusline.sh" ]]; then
        export STATUSLINE_ROOT="$(cd .. && pwd)"
        export STATUSLINE_SCRIPT="$STATUSLINE_ROOT/statusline.sh"
    fi
fi

# Debug path resolution in CI
if [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]]; then
    echo "DEBUG: BATS_TEST_DIRNAME=$BATS_TEST_DIRNAME" >&2
    echo "DEBUG: STATUSLINE_ROOT=$STATUSLINE_ROOT" >&2  
    echo "DEBUG: STATUSLINE_SCRIPT=$STATUSLINE_SCRIPT" >&2
    echo "DEBUG: Script exists: $(test -f "$STATUSLINE_SCRIPT" && echo yes || echo no)" >&2
    echo "DEBUG: Current directory: $(pwd)" >&2
    echo "DEBUG: GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-unset}" >&2
fi

# Test configuration
export CONFIG_TEST_MODE=true
export CONFIG_MCP_TIMEOUT="1s"
export CONFIG_VERSION_TIMEOUT="1s"
export CONFIG_CCUSAGE_TIMEOUT="1s"

# Test directories
export TEST_FIXTURES_DIR="$BATS_TEST_DIRNAME/fixtures"
export TEST_TMP_DIR="/tmp/statusline_test_$$"
export TEST_CACHE_DIR="$TEST_TMP_DIR/cache"

# Mock command paths
export MOCK_BIN_DIR="$TEST_TMP_DIR/mock_bin"

# Setup test environment
setup_test_env() {
    # Create temporary test directories
    mkdir -p "$TEST_TMP_DIR"
    mkdir -p "$TEST_CACHE_DIR"
    mkdir -p "$MOCK_BIN_DIR"
    
    # Add mock bin to PATH
    export PATH="$MOCK_BIN_DIR:$PATH"
    
    # Set test-specific cache file
    export CONFIG_VERSION_CACHE_FILE="$TEST_CACHE_DIR/.claude_version_cache"
}

# Cleanup test environment
teardown_test_env() {
    # Kill any orphaned processes from this test session first
    local test_session_id="$$"
    
    # Kill processes spawned by this test session
    pkill -f "statusline_test_$test_session_id" 2>/dev/null || true
    pkill -f "$TEST_TMP_DIR" 2>/dev/null || true
    
    # Wait a moment for processes to terminate
    sleep 0.1
    
    # Force kill any remaining processes
    ps aux | grep -E "$TEST_TMP_DIR" | grep -v grep | awk '{print $2}' | xargs -r kill -9 2>/dev/null || true
    
    # Clean up temporary files and directories
    if [[ -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
    
    # Clear test cache files and directories
    rm -f /tmp/.claude_version_cache_test*
    
    # More aggressive cleanup for any orphaned test directories
    find /tmp -maxdepth 1 -name "statusline_test_*" -type d -mmin +5 -exec rm -rf {} + 2>/dev/null || true
}

# Create mock command
create_mock_command() {
    local cmd_name="$1"
    local mock_output="$2"
    local exit_code="${3:-0}"
    
    cat > "$MOCK_BIN_DIR/$cmd_name" << EOF
#!/bin/bash
echo '$mock_output'
exit $exit_code
EOF
    chmod +x "$MOCK_BIN_DIR/$cmd_name"
}

# Create mock command that reads from file
create_mock_command_from_file() {
    local cmd_name="$1"
    local output_file="$2"
    local exit_code="${3:-0}"
    
    cat > "$MOCK_BIN_DIR/$cmd_name" << EOF
#!/bin/bash
if [[ -f "$output_file" ]]; then
    cat "$output_file"
else
    echo "Mock output file not found: $output_file" >&2
    exit 1
fi
exit $exit_code
EOF
    chmod +x "$MOCK_BIN_DIR/$cmd_name"
}

# Create failing mock command
create_failing_mock_command() {
    local cmd_name="$1"
    local error_message="${2:-Command failed}"
    local exit_code="${3:-1}"
    
    cat > "$MOCK_BIN_DIR/$cmd_name" << EOF
#!/bin/bash
echo '$error_message' >&2
exit $exit_code
EOF
    chmod +x "$MOCK_BIN_DIR/$cmd_name"
}

# Mock timeout command that simulates actual timeout behavior
create_timeout_mock() {
    local duration="$1"
    
    cat > "$MOCK_BIN_DIR/timeout" << 'EOF'
#!/bin/bash
# Simple timeout mock for testing with improved process cleanup
duration="$1"
shift
timeout_val="${duration%s}"  # Remove 's' suffix if present

# Create new process group to ensure clean termination
setsid "$@" &
cmd_pid=$!
sleep "$timeout_val" &
sleep_pid=$!

# Wait for either command completion or timeout
wait -n $cmd_pid $sleep_pid
result=$?

# If command is still running, kill the entire process group
if ps -p $cmd_pid > /dev/null 2>&1; then
    # Kill process group to ensure all child processes are terminated
    pkill -g $cmd_pid 2>/dev/null || true
    kill -TERM $cmd_pid 2>/dev/null || true
    sleep 0.1
    kill -KILL $cmd_pid 2>/dev/null || true
    exit 124  # timeout exit code
fi

# Clean up sleep process if command completed first
kill $sleep_pid 2>/dev/null || true
exit $result
EOF
    chmod +x "$MOCK_BIN_DIR/timeout"
    
    # Also create gtimeout (macOS)
    cp "$MOCK_BIN_DIR/timeout" "$MOCK_BIN_DIR/gtimeout"
}

# Generate test git repository
setup_test_git_repo() {
    local repo_dir="$1"
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    
    git init > /dev/null 2>&1
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit" > /dev/null 2>&1
    
    # Create test branch
    git checkout -b test-branch > /dev/null 2>&1
    echo "Test content" > test.txt
    git add test.txt
    git commit -m "Add test file" > /dev/null 2>&1
    git checkout main > /dev/null 2>&1
}

# Generate test input for statusline script
generate_test_input() {
    local current_dir="${1:-/tmp/test}"
    local model_name="${2:-Claude 3.5 Sonnet}"
    
    cat << EOF
{
  "workspace": {
    "current_dir": "$current_dir"
  },
  "model": {
    "display_name": "$model_name"
  }
}
EOF
}

# Assert output contains expected text
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain: '$expected'"
        echo "Actual output: '$output'"
        return 1
    fi
}

# Assert output matches pattern
assert_output_matches() {
    local pattern="$1"
    if ! [[ "$output" =~ $pattern ]]; then
        echo "Expected output to match pattern: '$pattern'"
        echo "Actual output: '$output'"
        return 1
    fi
}

# Assert command succeeded
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Expected command to succeed, but got exit code: $status"
        echo "Output: $output"
        return 1
    fi
}

# Assert command failed
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Expected command to fail, but it succeeded"
        echo "Output: $output"
        return 1
    fi
}

# Load bats-support and bats-assert if available
if [[ -f "/usr/local/lib/bats-support/load.bash" ]]; then
    load "/usr/local/lib/bats-support/load.bash"
fi

if [[ -f "/usr/local/lib/bats-assert/load.bash" ]]; then
    load "/usr/local/lib/bats-assert/load.bash"
fi

# Common setup that runs before each test
common_setup() {
    setup_test_env
}

# Common teardown that runs after each test
common_teardown() {
    teardown_test_env
}