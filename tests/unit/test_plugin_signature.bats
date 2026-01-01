#!/usr/bin/env bats

# Unit tests for plugin signature verification (Issue #120)

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Set up mock environment
    export CONFIG_PLUGINS_ENABLED="true"
    export CONFIG_PLUGINS_REQUIRE_SIGNATURE="false"
    export CONFIG_PLUGINS_WARN_UNSIGNED="true"
    export CONFIG_PLUGINS_TRUSTED_KEYS=""

    # Create mock plugin directory
    export TEST_PLUGIN_DIR="$TEST_TMP_DIR/plugins/test-plugin"
    mkdir -p "$TEST_PLUGIN_DIR"

    # Create a valid plugin script
    cat > "$TEST_PLUGIN_DIR/plugin.sh" << 'EOF'
#!/bin/bash
get_test_plugin_component() {
    echo "Test Output"
}
EOF
    chmod +x "$TEST_PLUGIN_DIR/plugin.sh"

    # Source the required modules
    export STATUSLINE_TESTING="true"
    source "$STATUSLINE_ROOT/lib/core.sh"
    source "$STATUSLINE_ROOT/lib/plugins.sh"
}

teardown() {
    common_teardown
}

# ============================================================================
# GPG AVAILABILITY TESTS
# ============================================================================

@test "is_gpg_available should return success when gpg exists" {
    # Create mock gpg
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
echo "gpg (GnuPG) 2.4.0"
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run is_gpg_available

    assert_success
}

@test "is_gpg_available should return failure when gpg missing" {
    # This test validates behavior, but requires no system gpg
    # Skip if system gpg is installed (we can't easily override command_exists)
    if command -v gpg >/dev/null 2>&1 || command -v gpg2 >/dev/null 2>&1; then
        skip "System gpg installed - cannot test missing gpg scenario"
    fi

    run is_gpg_available

    assert_failure
}

@test "get_gpg_cmd should prefer gpg2 over gpg" {
    # Create both
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
echo "gpg"
EOF
    cat > "$MOCK_BIN_DIR/gpg2" << 'EOF'
#!/bin/bash
echo "gpg2"
EOF
    chmod +x "$MOCK_BIN_DIR/gpg" "$MOCK_BIN_DIR/gpg2"

    run get_gpg_cmd

    assert_success
    assert_output "gpg2"
}

# ============================================================================
# SIGNATURE VALIDATION TESTS
# ============================================================================

@test "validate_plugin_signature should return 1 for unsigned plugin" {
    # No signature file exists
    rm -f "$TEST_PLUGIN_DIR/plugin.sh.sig" "$TEST_PLUGIN_DIR/plugin.sh.asc"

    # Create mock gpg
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
echo "gpg (GnuPG) 2.4.0"
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run validate_plugin_signature "$TEST_PLUGIN_DIR/" "test-plugin"

    assert_failure
    [ "$status" -eq 1 ]
}

@test "validate_plugin_signature should return 0 for valid signature" {
    # Create signature file
    echo "mock signature" > "$TEST_PLUGIN_DIR/plugin.sh.sig"

    # Create mock gpg that returns success
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
if [[ "$1" == "--verify" ]]; then
    echo "gpg: Good signature from \"Test Key <test@example.com>\""
    echo "Primary key fingerprint: ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234"
    exit 0
fi
echo "gpg (GnuPG) 2.4.0"
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run validate_plugin_signature "$TEST_PLUGIN_DIR/" "test-plugin"

    assert_success
}

@test "validate_plugin_signature should return 2 for invalid signature" {
    # Create signature file
    echo "invalid signature" > "$TEST_PLUGIN_DIR/plugin.sh.sig"

    # Create mock gpg that returns failure
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
if [[ "$1" == "--verify" ]]; then
    echo "gpg: BAD signature from \"Unknown Key\"" >&2
    exit 1
fi
echo "gpg (GnuPG) 2.4.0"
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run validate_plugin_signature "$TEST_PLUGIN_DIR/" "test-plugin"

    assert_failure
    [ "$status" -eq 2 ]
}

@test "validate_plugin_signature should return 3 when gpg unavailable" {
    # This test validates behavior when gpg is missing
    # Skip if system gpg is installed
    if command -v gpg >/dev/null 2>&1 || command -v gpg2 >/dev/null 2>&1; then
        skip "System gpg installed - cannot test gpg unavailable scenario"
    fi

    run validate_plugin_signature "$TEST_PLUGIN_DIR/" "test-plugin"

    assert_failure
    [ "$status" -eq 3 ]
}

@test "validate_plugin_signature should detect .asc signature files" {
    # Create .asc signature file (armored)
    echo "-----BEGIN PGP SIGNATURE-----" > "$TEST_PLUGIN_DIR/plugin.sh.asc"

    # Create mock gpg
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
if [[ "$1" == "--verify" ]]; then
    echo "gpg: Good signature"
    exit 0
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run validate_plugin_signature "$TEST_PLUGIN_DIR/" "test-plugin"

    assert_success
}

# ============================================================================
# TRUSTED KEYS TESTS
# ============================================================================

@test "validate_plugin_signature should return 4 for untrusted key" {
    # Create signature file
    echo "mock signature" > "$TEST_PLUGIN_DIR/plugin.sh.sig"

    # Set trusted keys
    export CONFIG_PLUGINS_TRUSTED_KEYS="AAAA1111AAAA1111,BBBB2222BBBB2222"

    # Create mock gpg with different key
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
if [[ "$1" == "--verify" ]]; then
    echo "gpg: Good signature from \"Unknown <unknown@example.com>\""
    echo "Primary key fingerprint: CCCC3333CCCC3333CCCC3333CCCC3333CCCC3333"
    exit 0
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run validate_plugin_signature "$TEST_PLUGIN_DIR/" "test-plugin"

    assert_failure
    [ "$status" -eq 4 ]
}

@test "validate_plugin_signature should accept trusted key" {
    # Create signature file
    echo "mock signature" > "$TEST_PLUGIN_DIR/plugin.sh.sig"

    # Set trusted keys including the signing key
    export CONFIG_PLUGINS_TRUSTED_KEYS="AAAA1111AAAA1111,ABCD1234ABCD1234"

    # Create mock gpg with matching key
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
if [[ "$1" == "--verify" ]]; then
    echo "gpg: Good signature from \"Trusted <trusted@example.com>\""
    echo "Primary key fingerprint: ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234"
    exit 0
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run validate_plugin_signature "$TEST_PLUGIN_DIR/" "test-plugin"

    assert_success
}

# ============================================================================
# CONFIGURATION TESTS
# ============================================================================

@test "should_allow_unsigned returns true when signature not required" {
    export CONFIG_PLUGINS_REQUIRE_SIGNATURE="false"

    run should_allow_unsigned

    assert_success
}

@test "should_allow_unsigned returns false when signature required" {
    export CONFIG_PLUGINS_REQUIRE_SIGNATURE="true"

    run should_allow_unsigned

    assert_failure
}

@test "get_plugin_signature_status returns correct status" {
    # Manually set status
    PLUGIN_SIGNATURE_STATUS["test-plugin"]="valid:ABCD1234"

    run get_plugin_signature_status "test-plugin"

    assert_success
    assert_output "valid:ABCD1234"
}

# ============================================================================
# INTEGRATION WITH LOAD_PLUGIN TESTS
# ============================================================================

@test "load_plugin should reject plugin with invalid signature" {
    # Register the plugin
    LOADED_PLUGINS["test-plugin"]="$TEST_PLUGIN_DIR/"

    # Create invalid signature
    echo "invalid" > "$TEST_PLUGIN_DIR/plugin.sh.sig"

    # Create mock gpg that fails verification
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
if [[ "$1" == "--verify" ]]; then
    exit 1
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run load_plugin "test-plugin"

    assert_failure
}

@test "load_plugin should reject unsigned plugin when signature required" {
    export CONFIG_PLUGINS_REQUIRE_SIGNATURE="true"

    # Register the plugin
    LOADED_PLUGINS["test-plugin"]="$TEST_PLUGIN_DIR/"

    # No signature file
    rm -f "$TEST_PLUGIN_DIR/plugin.sh.sig" "$TEST_PLUGIN_DIR/plugin.sh.asc"

    # Create mock gpg
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
echo "gpg available"
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run load_plugin "test-plugin"

    assert_failure
}

@test "load_plugin should allow unsigned plugin when signature not required" {
    export CONFIG_PLUGINS_REQUIRE_SIGNATURE="false"
    export CONFIG_PLUGINS_WARN_UNSIGNED="false"
    export CONFIG_PLUGINS_VALIDATE="false"  # Disable security validation for this test

    # Create plugin directory with underscore name (valid bash identifier)
    local test_plugin_dir="$TEST_TMP_DIR/plugins/testplugin"
    mkdir -p "$test_plugin_dir"

    # Create plugin with generic component function (also supported)
    cat > "$test_plugin_dir/plugin.sh" << 'PLUGINEOF'
#!/bin/bash
get_component() {
    echo "Test Output"
}
PLUGINEOF
    chmod +x "$test_plugin_dir/plugin.sh"

    # Register the plugin
    LOADED_PLUGINS["testplugin"]="$test_plugin_dir/"

    # Create mock gpg
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
echo "gpg available"
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run load_plugin "testplugin"

    assert_success
}

@test "load_plugin should load signed plugin successfully" {
    export CONFIG_PLUGINS_VALIDATE="false"  # Disable security validation for this test

    # Create plugin directory with valid name
    local signed_plugin_dir="$TEST_TMP_DIR/plugins/signedplugin"
    mkdir -p "$signed_plugin_dir"

    # Create plugin with generic component function
    cat > "$signed_plugin_dir/plugin.sh" << 'PLUGINEOF'
#!/bin/bash
get_component() {
    echo "Signed Plugin Output"
}
PLUGINEOF
    chmod +x "$signed_plugin_dir/plugin.sh"

    # Register the plugin
    LOADED_PLUGINS["signedplugin"]="$signed_plugin_dir/"

    # Create valid signature
    echo "valid sig" > "$signed_plugin_dir/plugin.sh.sig"

    # Create mock gpg that passes verification
    cat > "$MOCK_BIN_DIR/gpg" << 'EOF'
#!/bin/bash
if [[ "$1" == "--verify" ]]; then
    echo "gpg: Good signature"
    exit 0
fi
EOF
    chmod +x "$MOCK_BIN_DIR/gpg"

    run load_plugin "signedplugin"

    assert_success
}
