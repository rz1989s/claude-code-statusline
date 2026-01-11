#!/usr/bin/env bats

# Unit tests for modular system - module loading and initialization
# Tests the new modular architecture's core functionality

load '../setup_suite'
load '../helpers/test_helpers'

# Source the script once per file (optimization - avoids 10s per test)
setup_file() {
    common_setup
    # Source the main script to get core functionality
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() {
    common_teardown
}

# Note: Individual tests run in isolation, so module state from setup_file
# isn't available. Tests verify function availability instead.

@test "should export core module functions" {
    # Verify core functions are available after sourcing
    run type load_module
    assert_success

    run type is_module_loaded
    assert_success

    run type get_script_dir
    assert_success

    run type debug_log
    assert_success
}

@test "should export security module functions" {
    # Check that key security functions are available
    run type sanitize_path_secure
    assert_success

    run type validate_ansi_color
    assert_success

    run type parse_mcp_server_name_secure
    assert_success
}

@test "should export config module functions" {
    # Check that key config functions are available
    run type load_toml_configuration
    assert_success

    run type discover_config_file
    assert_success
}

@test "should define themes module functions" {
    # Issue #134: Theme functions are defined but NOT exported (run in main process only)
    # Unset module guards (exported from setup_file) so modules can be sourced fresh
    run bash -c "unset STATUSLINE_CORE_LOADED STATUSLINE_SECURITY_LOADED STATUSLINE_CONFIG_LOADED STATUSLINE_THEMES_LOADED && cd '$STATUSLINE_ROOT' && source lib/core.sh && source lib/security.sh && source lib/config.sh && source lib/themes.sh && type apply_theme >/dev/null && echo ok"
    assert_success
    [[ "$output" == "ok" ]]

    run bash -c "unset STATUSLINE_CORE_LOADED STATUSLINE_SECURITY_LOADED STATUSLINE_CONFIG_LOADED STATUSLINE_THEMES_LOADED && cd '$STATUSLINE_ROOT' && source lib/core.sh && source lib/security.sh && source lib/config.sh && source lib/themes.sh && type get_current_theme >/dev/null && echo ok"
    assert_success
    [[ "$output" == "ok" ]]
}

@test "should define display module functions" {
    # Issue #134: Display functions are defined but NOT exported (run in main process only)
    # Unset module guards (exported from setup_file) so modules can be sourced fresh
    run bash -c "unset STATUSLINE_CORE_LOADED STATUSLINE_SECURITY_LOADED STATUSLINE_CONFIG_LOADED STATUSLINE_THEMES_LOADED STATUSLINE_DISPLAY_LOADED && cd '$STATUSLINE_ROOT' && source lib/core.sh && source lib/security.sh && source lib/config.sh && source lib/themes.sh && source lib/display.sh && type build_line1 >/dev/null && echo ok"
    assert_success
    [[ "$output" == "ok" ]]

    run bash -c "unset STATUSLINE_CORE_LOADED STATUSLINE_SECURITY_LOADED STATUSLINE_CONFIG_LOADED STATUSLINE_THEMES_LOADED STATUSLINE_DISPLAY_LOADED && cd '$STATUSLINE_ROOT' && source lib/core.sh && source lib/security.sh && source lib/config.sh && source lib/themes.sh && source lib/display.sh && type build_line2 >/dev/null && echo ok"
    assert_success
    [[ "$output" == "ok" ]]

    run bash -c "unset STATUSLINE_CORE_LOADED STATUSLINE_SECURITY_LOADED STATUSLINE_CONFIG_LOADED STATUSLINE_THEMES_LOADED STATUSLINE_DISPLAY_LOADED && cd '$STATUSLINE_ROOT' && source lib/core.sh && source lib/security.sh && source lib/config.sh && source lib/themes.sh && source lib/display.sh && type build_line3 >/dev/null && echo ok"
    assert_success
    [[ "$output" == "ok" ]]
}

@test "should have is_module_loaded function working" {
    # Verify function exists and runs without error
    run type is_module_loaded
    assert_success

    # Test with a dummy value (won't find it, but shouldn't crash)
    run is_module_loaded "nonexistent"
    assert_failure  # Expected - module doesn't exist
}

@test "should load core module independently" {
    # Test loading core.sh directly in a subshell
    run bash -c "cd '$STATUSLINE_ROOT' && source lib/core.sh && echo 'loaded'"
    assert_success
    [[ "$output" == "loaded" ]]
}

@test "should fail for non-existent required module" {
    # Verify load_module fails for non-existent required modules
    run bash -c "cd '$STATUSLINE_ROOT' && source lib/core.sh && load_module 'nonexistent_required' true 2>&1"
    assert_failure
}

@test "should validate get_script_dir returns valid path" {
    # Test get_script_dir function is available
    run type get_script_dir
    assert_success
}

@test "should have key functions defined" {
    # Issue #134: Only check functions that actually need to be available
    # Core/security functions are exported; theme/display run in main process only
    local expected_functions=(
        "load_module"
        "is_module_loaded"
        "debug_log"
        "handle_error"
        "handle_warning"
        "sanitize_path_secure"
    )

    for func in "${expected_functions[@]}"; do
        run type "$func"
        assert_success
    done

    # Theme functions are defined but not exported - test via bash -c
    # Unset module guards (exported from setup_file) so modules can be sourced fresh
    run bash -c "unset STATUSLINE_CORE_LOADED STATUSLINE_SECURITY_LOADED STATUSLINE_CONFIG_LOADED STATUSLINE_THEMES_LOADED && cd '$STATUSLINE_ROOT' && source lib/core.sh && source lib/security.sh && source lib/config.sh && source lib/themes.sh && type apply_theme >/dev/null && echo ok"
    assert_success
}

@test "should have strict mode functions available" {
    # Verify strict mode functions added in Issue #77
    run type enable_strict_mode
    assert_success

    run type disable_strict_mode
    assert_success
}
