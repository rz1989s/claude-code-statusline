#!/usr/bin/env bats

# Unit tests for GitHub API rate limiting (Issue #121)

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Set up mock environment
    export CONFIG_GITHUB_ENABLED="true"
    export CONFIG_GITHUB_RATE_LIMIT_THRESHOLD="100"
    export CONFIG_GITHUB_RATE_LIMIT_CRITICAL="10"
    export CACHE_BASE_DIR="$TEST_TMP_DIR/cache"
    mkdir -p "$CACHE_BASE_DIR"

    # Source the required modules
    export STATUSLINE_TESTING="true"
    source "$STATUSLINE_ROOT/lib/core.sh"
    source "$STATUSLINE_ROOT/lib/cache.sh"
    source "$STATUSLINE_ROOT/lib/github.sh"
}

teardown() {
    common_teardown
}

# ============================================================================
# RATE LIMIT CHECK TESTS
# ============================================================================

@test "check_api_rate_limit should return success when quota is high" {
    # Create mock gh that returns high quota
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
if [[ "$2" == "rate_limit" ]]; then
    echo '{"rate":{"remaining":4500,"reset":1700000000}}'
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    run check_api_rate_limit "true"

    assert_success
    [[ "$GITHUB_RATE_LIMITED" == "false" ]]
}

@test "check_api_rate_limit should return failure when quota is critical" {
    # Create mock gh that returns low quota
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
if [[ "$2" == "rate_limit" ]]; then
    echo '{"rate":{"remaining":5,"reset":1700000000}}'
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    run check_api_rate_limit "true"

    assert_failure
}

@test "check_api_rate_limit should use cached rate limit" {
    # Create cache file with valid rate limit
    echo "4000:1700000000:false" > "$CACHE_BASE_DIR/github_rate_limit_cache"
    touch "$CACHE_BASE_DIR/github_rate_limit_cache"

    # Mock gh should NOT be called since cache is fresh
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
echo "SHOULD_NOT_BE_CALLED" >&2
exit 1
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    run check_api_rate_limit

    assert_success
}

@test "check_api_rate_limit should handle gh API failure gracefully" {
    # Mock gh that fails
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    # Clear cache
    rm -f "$CACHE_BASE_DIR/github_rate_limit_cache"

    run check_api_rate_limit "true"

    # Should return success (assume OK when we can't check)
    assert_success
}

# ============================================================================
# RATE LIMIT WARNING TESTS
# ============================================================================

@test "get_rate_limit_warning should return empty when quota is high" {
    export GITHUB_RATE_REMAINING="4000"
    export CONFIG_GITHUB_RATE_LIMIT_THRESHOLD="100"
    export CONFIG_GITHUB_SHOW_RATE_LIMIT_WARNING="true"

    run get_rate_limit_warning

    assert_success
    assert_output ""
}

@test "get_rate_limit_warning should return warning when quota is low" {
    export GITHUB_RATE_REMAINING="50"
    export CONFIG_GITHUB_RATE_LIMIT_THRESHOLD="100"
    export CONFIG_GITHUB_SHOW_RATE_LIMIT_WARNING="true"

    run get_rate_limit_warning

    assert_success
    assert_output --partial "GH:50"
}

@test "get_rate_limit_warning should respect disabled setting" {
    export GITHUB_RATE_REMAINING="50"
    export CONFIG_GITHUB_RATE_LIMIT_THRESHOLD="100"
    export CONFIG_GITHUB_SHOW_RATE_LIMIT_WARNING="false"

    run get_rate_limit_warning

    assert_success
    assert_output ""
}

# ============================================================================
# RESET TIME TESTS
# ============================================================================

@test "get_rate_limit_reset_time should return empty when no reset time" {
    export GITHUB_RATE_RESET=""

    run get_rate_limit_reset_time

    assert_success
    assert_output ""
}

@test "get_rate_limit_reset_time should return now when reset time passed" {
    export GITHUB_RATE_RESET="1"  # Far in the past

    run get_rate_limit_reset_time

    assert_success
    assert_output "now"
}

# ============================================================================
# INTEGRATION WITH EXECUTE_GH_COMMAND
# ============================================================================

@test "execute_gh_command should skip API call when rate limited" {
    # Set up rate limited state in cache
    echo "5:1700000000:true" > "$CACHE_BASE_DIR/github_rate_limit_cache"
    touch "$CACHE_BASE_DIR/github_rate_limit_cache"

    # Mock gh that should NOT be called
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
echo "API_WAS_CALLED"
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    run execute_gh_command "api" "repos/test"

    assert_failure
    refute_output "API_WAS_CALLED"
}

@test "execute_gh_command should proceed when not rate limited" {
    # Clear rate limit cache
    rm -f "$CACHE_BASE_DIR/github_rate_limit_cache"

    # Mock gh with high quota and API response
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
if [[ "$2" == "rate_limit" ]]; then
    echo '{"rate":{"remaining":4500,"reset":1700000000}}'
else
    echo "API_RESPONSE"
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    run execute_gh_command "api" "repos/test"

    assert_success
    assert_output "API_RESPONSE"
}

# ============================================================================
# STALE CACHE FALLBACK TESTS
# ============================================================================

@test "get_ci_status should use stale cache when rate limited" {
    # Enable GitHub and set up mock repo
    export CONFIG_GITHUB_ENABLED="true"

    # Create stale cache with CI status
    mkdir -p "$CACHE_BASE_DIR"
    echo "✓" > "$CACHE_BASE_DIR/github_ci_status_cache"
    # Make it old (stale)
    touch -t 202301010000 "$CACHE_BASE_DIR/github_ci_status_cache"

    # Set up rate limited state
    echo "5:1700000000:true" > "$CACHE_BASE_DIR/github_rate_limit_cache"
    touch "$CACHE_BASE_DIR/github_rate_limit_cache"

    # Mock git to make it appear as a github repo
    cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
case "$1" in
    "rev-parse")
        if [[ "$2" == "--is-inside-work-tree" ]]; then
            echo "true"
        elif [[ "$2" == "--abbrev-ref" ]]; then
            echo "main"
        fi
        ;;
    "remote")
        echo "https://github.com/test/repo.git"
        ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/git"

    # Mock gh
    cat > "$MOCK_BIN_DIR/gh" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$MOCK_BIN_DIR/gh"

    run get_ci_status

    # Should use stale cache and return the cached value
    assert_success
    assert_output "✓"
}
