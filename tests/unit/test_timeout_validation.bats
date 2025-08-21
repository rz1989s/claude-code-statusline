#!/usr/bin/env bats

# Unit tests for timeout validation functions in statusline.sh

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    # Source statusline.sh functions without executing main logic
    STATUSLINE_TESTING="true" source "$STATUSLINE_SCRIPT" 2>/dev/null
}

teardown() {
    common_teardown
}

# =============================================================================
# parse_timeout_to_seconds() Tests
# =============================================================================

@test "parse_timeout_to_seconds should handle seconds format" {
    run parse_timeout_to_seconds "10s"
    assert_success
    assert_output "10"
}

@test "parse_timeout_to_seconds should handle minutes format" {
    run parse_timeout_to_seconds "2m" 
    assert_success
    assert_output "120"
}

@test "parse_timeout_to_seconds should handle numeric only (defaults to seconds)" {
    run parse_timeout_to_seconds "30"
    assert_success
    assert_output "30"
}

@test "parse_timeout_to_seconds should reject invalid formats" {
    run parse_timeout_to_seconds "10x"
    assert_failure
    
    run parse_timeout_to_seconds "abc"
    assert_failure
    
    run parse_timeout_to_seconds "s10"
    assert_failure
}

@test "parse_timeout_to_seconds should handle edge cases" {
    run parse_timeout_to_seconds ""
    assert_failure
    
    run parse_timeout_to_seconds "null"
    assert_failure
    
    run parse_timeout_to_seconds "0s"
    assert_success
    assert_output "0"
}

# =============================================================================
# validate_timeout_bounds() Tests  
# =============================================================================

@test "validate_timeout_bounds should accept valid MCP timeouts" {
    local errors=() warnings=() suggestions=()
    
    # Test optimal range
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "10s" "mcp" errors warnings suggestions
    assert_success
    [ ${#errors[@]} -eq 0 ]
    [ ${#warnings[@]} -eq 0 ]
}

@test "validate_timeout_bounds should warn for high MCP timeouts" {
    local errors=() warnings=() suggestions=()
    
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "45s" "mcp" errors warnings suggestions  
    [ $status -eq 2 ]  # Warning status
    [ ${#errors[@]} -eq 0 ]
    [ ${#warnings[@]} -gt 0 ]
    [[ "${warnings[0]}" == *"may impact responsiveness"* ]]
}

@test "validate_timeout_bounds should error for too-short MCP timeouts" {
    local errors=() warnings=() suggestions=()
    
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "0s" "mcp" errors warnings suggestions
    assert_failure  
    [ ${#errors[@]} -gt 0 ]
    [[ "${errors[0]}" == *"too short"* ]]
    [[ "${suggestions[0]}" == *"need at least 1s"* ]]
}

@test "validate_timeout_bounds should error for too-long MCP timeouts" {
    local errors=() warnings=() suggestions=()
    
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "70s" "mcp" errors warnings suggestions
    assert_failure
    [ ${#errors[@]} -gt 0 ]
    [[ "${errors[0]}" == *"too long"* ]]
    [[ "${suggestions[0]}" == *"can freeze statusline"* ]]
}

@test "validate_timeout_bounds should handle version timeout bounds" {
    local errors=() warnings=() suggestions=()
    
    # Valid version timeout
    run validate_timeout_bounds "CONFIG_VERSION_TIMEOUT" "2s" "version" errors warnings suggestions
    assert_success
    [ ${#errors[@]} -eq 0 ]
    
    # Too long version timeout  
    run validate_timeout_bounds "CONFIG_VERSION_TIMEOUT" "15s" "version" errors warnings suggestions
    assert_failure
    [ ${#errors[@]} -gt 0 ]
    [[ "${errors[0]}" == *"too long"* ]]
}

@test "validate_timeout_bounds should handle ccusage timeout bounds" {
    local errors=() warnings=() suggestions=()
    
    # Valid ccusage timeout
    run validate_timeout_bounds "CONFIG_CCUSAGE_TIMEOUT" "8s" "ccusage" errors warnings suggestions  
    assert_success
    [ ${#errors[@]} -eq 0 ]
    
    # Too long ccusage timeout
    run validate_timeout_bounds "CONFIG_CCUSAGE_TIMEOUT" "40s" "ccusage" errors warnings suggestions
    assert_failure
    [ ${#errors[@]} -gt 0 ]
}

@test "validate_timeout_bounds should handle invalid formats" {
    local errors=() warnings=() suggestions=()
    
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "invalid" "mcp" errors warnings suggestions
    assert_failure
    [ ${#errors[@]} -gt 0 ]
    [[ "${errors[0]}" == *"invalid format"* ]]
    [[ "${suggestions[0]}" == *"Example:"* ]]
}

@test "validate_timeout_bounds should provide contextual suggestions" {
    local errors=() warnings=() suggestions=()
    
    # Test MCP-specific suggestions
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "45s" "mcp" errors warnings suggestions
    [ $status -eq 2 ]  # Warning
    [[ "${suggestions[0]}" == *"3s-15s for most setups"* ]]
    
    # Test version-specific suggestions  
    run validate_timeout_bounds "CONFIG_VERSION_TIMEOUT" "8s" "version" errors warnings suggestions
    [ $status -eq 2 ]  # Warning
    [[ "${suggestions[0]}" == *"usually cached"* ]]
}

@test "validate_timeout_bounds should handle minutes format" {
    local errors=() warnings=() suggestions=()
    
    # 1 minute = 60 seconds (at MCP max limit)
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "1m" "mcp" errors warnings suggestions
    assert_success
    [ ${#errors[@]} -eq 0 ]
    
    # 2 minutes = 120 seconds (over MCP limit)
    run validate_timeout_bounds "CONFIG_MCP_TIMEOUT" "2m" "mcp" errors warnings suggestions  
    assert_failure
    [ ${#errors[@]} -gt 0 ]
    [[ "${errors[0]}" == *"too long"* ]]
}

# =============================================================================
# Integration with validate_configuration() Tests
# =============================================================================

@test "validate_configuration should use enhanced timeout validation" {
    # Set up test configuration with problematic timeout
    CONFIG_MCP_TIMEOUT="0s"
    
    # Mock the validation function to capture its calls
    run validate_configuration
    
    # Should contain timeout-related errors
    [[ "$output" == *"timeout"* ]] || [[ "$output" == *"too short"* ]]
}