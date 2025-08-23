#!/usr/bin/env bats

# Unit tests for modular system - module loading and initialization
# Tests the new modular architecture's core functionality

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    # Source the main script to get core functionality
    source "${STATUSLINE_SCRIPT}"
}

teardown() {
    common_teardown
}

# Test core module loading functionality
@test "should load core module successfully" {
    # Reset modules to test loading
    STATUSLINE_MODULES_LOADED=()
    
    run load_module "core"
    assert_success
    
    # Verify module is marked as loaded
    run is_module_loaded "core"
    assert_success
}

@test "should detect module loading status correctly" {
    # Test with unloaded module
    STATUSLINE_MODULES_LOADED=()
    
    run is_module_loaded "nonexistent"
    assert_failure
    
    # Test with loaded module
    STATUSLINE_MODULES_LOADED=("core" "security")
    
    run is_module_loaded "core"
    assert_success
    
    run is_module_loaded "security"  
    assert_success
    
    run is_module_loaded "unloaded"
    assert_failure
}

@test "should validate security module exports key functions" {
    # Load security module
    run load_module "security"
    assert_success
    
    # Check that key security functions are available
    run type sanitize_path_secure
    assert_success
    
    run type validate_ansi_color_code
    assert_success
    
    run type parse_mcp_server_name_secure
    assert_success
}

@test "should validate config module exports configuration functions" {
    # Load required dependencies first
    load_module "core" || skip "Core module required"
    load_module "security" || skip "Security module required"
    
    run load_module "config"
    assert_success
    
    # Check that key config functions are available
    run type load_toml_configuration
    assert_success
    
    run type discover_config_file
    assert_success
}

@test "should validate themes module exports theme functions" {
    # Load required dependencies
    load_module "core" || skip "Core module required"
    load_module "security" || skip "Security module required" 
    load_module "config" || skip "Config module required"
    
    run load_module "themes"
    assert_success
    
    # Check that key theme functions are available
    run type apply_theme
    assert_success
    
    run type get_color
    assert_success
}

@test "should validate display module exports formatting functions" {
    # Load required dependencies
    load_module "core" || skip "Core module required"
    load_module "security" || skip "Security module required"
    load_module "config" || skip "Config module required"
    load_module "themes" || skip "Themes module required"
    
    run load_module "display"
    assert_success
    
    # Check that key display functions are available
    run type build_line_1
    assert_success
    
    run type build_line_2
    assert_success
    
    run type build_line_3
    assert_success
    
    run type build_line_4
    assert_success
}

@test "should handle optional module loading gracefully" {
    # Reset modules
    STATUSLINE_MODULES_LOADED=()
    
    # Test that optional modules can fail without breaking the system
    # (git, mcp, cost are optional modules)
    
    # Mock a failing module by creating a bad script
    cat > "${TEST_TMP_DIR}/bad_module.sh" << 'EOF'
#!/bin/bash
# Intentionally broken module for testing
exit 1
EOF
    
    # This should not cause the test to fail - optional modules should fail gracefully
    run load_module "bad_module" false  # false = optional module
    # Should return failure but not crash
    assert_failure
}

@test "should enforce required module loading" {
    # Reset modules 
    STATUSLINE_MODULES_LOADED=()
    
    # Required modules should fail hard if they can't load
    # We'll test this by mocking a non-existent required module
    
    # This should fail for required modules
    run load_module "nonexistent_required" true  # true = required module
    assert_failure
}

@test "should validate module dependency order" {
    # Reset modules
    STATUSLINE_MODULES_LOADED=()
    
    # Test that modules load in proper dependency order
    # Core should load first
    run load_module "core" 
    assert_success
    
    # Security should load after core
    run load_module "security"
    assert_success
    
    # Verify both are loaded
    run is_module_loaded "core"
    assert_success
    
    run is_module_loaded "security"
    assert_success
}

@test "should prevent duplicate module loading" {
    # Reset modules
    STATUSLINE_MODULES_LOADED=()
    
    # Load core module first time
    run load_module "core"
    assert_success
    
    # Attempt to load again - should detect it's already loaded
    run load_module "core"
    assert_success  # Should succeed but not duplicate
    
    # Verify it's only loaded once (not duplicated in array)
    local core_count=$(echo "${STATUSLINE_MODULES_LOADED[@]}" | grep -o "core" | wc -l)
    [[ $core_count -eq 1 ]]
}

@test "should validate get_script_dir function returns valid path" {
    # Load core module
    run load_module "core"
    assert_success
    
    # Test get_script_dir function
    run get_script_dir
    assert_success
    
    # Should return a directory that exists
    local script_dir="$output"
    [[ -d "$script_dir" ]]
}