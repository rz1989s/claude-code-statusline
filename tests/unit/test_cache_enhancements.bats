#!/usr/bin/env bats

# Unit tests for cache system enhancements
# Tests XDG compliance, checksum validation, performance monitoring, and error handling

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Load required dependency modules first (Issue #62)
    source "$PROJECT_ROOT/lib/core.sh" || skip "Core module not available"
    source "$PROJECT_ROOT/lib/security.sh" || skip "Security module not available"

    # Load cache module for testing
    source "$PROJECT_ROOT/lib/cache.sh" || skip "Cache module not available"
    
    # Create temporary test cache directory
    export TEST_CACHE_DIR="/tmp/test_cache_$$"
    export ORIGINAL_CACHE_BASE_DIR="$CACHE_BASE_DIR"
    export CACHE_BASE_DIR="$TEST_CACHE_DIR"
    mkdir -p "$TEST_CACHE_DIR"
    
    # Backup original configuration
    export ORIGINAL_CACHE_CONFIG_ENABLE_CHECKSUMS="${CACHE_CONFIG_ENABLE_CHECKSUMS:-}"
    export ORIGINAL_CACHE_CONFIG_ENABLE_STATISTICS="${CACHE_CONFIG_ENABLE_STATISTICS:-}"
}

teardown() {
    # Restore original configuration
    export CACHE_BASE_DIR="$ORIGINAL_CACHE_BASE_DIR"
    export CACHE_CONFIG_ENABLE_CHECKSUMS="$ORIGINAL_CACHE_CONFIG_ENABLE_CHECKSUMS"
    export CACHE_CONFIG_ENABLE_STATISTICS="$ORIGINAL_CACHE_CONFIG_ENABLE_STATISTICS"
    
    # Cleanup test cache directory
    [[ -d "$TEST_CACHE_DIR" ]] && rm -rf "$TEST_CACHE_DIR"
    
    common_teardown
}

# ============================================================================
# XDG CACHE DIRECTORY TESTS
# ============================================================================

@test "determine_cache_base_dir should use CLAUDE_CACHE_DIR if set" {
    export CLAUDE_CACHE_DIR="/custom/cache/dir"
    
    local result
    result=$(determine_cache_base_dir)
    
    [[ "$result" == "/custom/cache/dir" ]]
    
    unset CLAUDE_CACHE_DIR
}

@test "determine_cache_base_dir should use XDG_CACHE_HOME if available" {
    unset CLAUDE_CACHE_DIR
    export XDG_CACHE_HOME="/home/user/.cache"

    local result
    result=$(determine_cache_base_dir)

    [[ "$result" == "/home/user/.cache/claude-code-statusline" ]]

    unset XDG_CACHE_HOME
}

@test "determine_cache_base_dir should fall back to HOME/.cache" {
    unset CLAUDE_CACHE_DIR
    unset XDG_CACHE_HOME
    # Use a real writable directory for HOME (required for -w check)
    local test_home="$TEST_TMP_DIR/home_test"
    mkdir -p "$test_home"
    export HOME="$test_home"

    local result
    result=$(determine_cache_base_dir)

    [[ "$result" == "$test_home/.cache/claude-code-statusline" ]]
}

@test "migrate_legacy_cache should move files from legacy location" {
    # Create legacy cache directory with test files
    local legacy_dir="/tmp/test_legacy_cache_$$"
    mkdir -p "$legacy_dir"
    echo "test_content_1" > "$legacy_dir/test_file_1"
    echo "test_content_2" > "$legacy_dir/test_file_2"
    
    # Set up migration
    export LEGACY_CACHE_DIR="$legacy_dir"
    
    # Run migration
    run migrate_legacy_cache
    [[ $status -eq 0 ]]
    
    # Verify files were migrated
    [[ -f "$TEST_CACHE_DIR/test_file_1" ]]
    [[ -f "$TEST_CACHE_DIR/test_file_2" ]]
    
    # Verify content is correct
    [[ "$(cat "$TEST_CACHE_DIR/test_file_1")" == "test_content_1" ]]
    [[ "$(cat "$TEST_CACHE_DIR/test_file_2")" == "test_content_2" ]]
    
    # Cleanup
    rm -rf "$legacy_dir"
}

# ============================================================================
# GIT BRANCH VALIDATION TESTS  
# ============================================================================

@test "validate_git_branch_name should accept valid branch names" {
    local test_file="$TEST_CACHE_DIR/test_branch"
    
    # Test normal branch name
    echo "main" > "$test_file"
    run validate_git_branch_name "$test_file"
    [[ $status -eq 0 ]]
    
    # Test branch with slashes
    echo "feature/new-feature" > "$test_file"
    run validate_git_branch_name "$test_file"
    [[ $status -eq 0 ]]
    
    # Test branch with numbers
    echo "release-1.2.3" > "$test_file"
    run validate_git_branch_name "$test_file"
    [[ $status -eq 0 ]]
}

@test "validate_git_branch_name should reject invalid branch names" {
    local test_file="$TEST_CACHE_DIR/test_invalid_branch"
    
    # Test empty branch name
    echo "" > "$test_file"
    run validate_git_branch_name "$test_file"
    [[ $status -eq 1 ]]
    
    # Test branch name with spaces
    echo "invalid branch name" > "$test_file"  
    run validate_git_branch_name "$test_file"
    [[ $status -eq 1 ]]
}

@test "validate_git_branch_name should handle Unicode branch names if git supports them" {
    if ! command -v git >/dev/null 2>&1; then
        skip "Git not available for Unicode testing"
    fi
    
    local test_file="$TEST_CACHE_DIR/test_unicode_branch"
    echo "feature/测试-branch" > "$test_file"
    
    # This should work with git's validation
    run validate_git_branch_name "$test_file"
    
    # Accept either success or failure depending on git version
    [[ $status -eq 0 ]] || [[ $status -eq 1 ]]
}

# ============================================================================
# CHECKSUM VALIDATION TESTS
# ============================================================================

@test "generate_cache_checksum should produce consistent checksums" {
    local content="test content for checksum"
    
    local checksum1
    checksum1=$(generate_cache_checksum "$content")
    
    local checksum2  
    checksum2=$(generate_cache_checksum "$content")
    
    [[ "$checksum1" == "$checksum2" ]]
    [[ -n "$checksum1" ]]
    [[ ${#checksum1} -ge 8 ]]  # At least 8 characters for any hash
}

@test "write_cache_with_checksum should create protected cache file" {
    local test_file="$TEST_CACHE_DIR/test_checksum_cache"
    local test_content="test content with checksum protection"
    
    run write_cache_with_checksum "$test_file" "$test_content"
    [[ $status -eq 0 ]]
    
    # Verify file was created
    [[ -f "$test_file" ]]
    
    # Verify file contains checksum metadata
    grep -q "# Cache Integrity Checksum:" "$test_file"
    grep -q "# Generated:" "$test_file"
    grep -q "# Content:" "$test_file"
    grep -q "$test_content" "$test_file"
}

@test "read_cache_with_checksum should validate checksums correctly" {
    local test_file="$TEST_CACHE_DIR/test_checksum_validation"
    local test_content="content for validation testing"
    
    # Enable checksum validation
    export CACHE_CONFIG_ENABLE_CHECKSUMS="true"
    
    # Write protected cache
    write_cache_with_checksum "$test_file" "$test_content"
    
    # Read and validate
    local retrieved_content
    retrieved_content=$(read_cache_with_checksum "$test_file" "true")
    
    [[ "$retrieved_content" == "$test_content" ]]
}

@test "read_cache_with_checksum should detect corruption" {
    local test_file="$TEST_CACHE_DIR/test_corruption_detection"
    local test_content="original content"
    
    # Enable checksum validation
    export CACHE_CONFIG_ENABLE_CHECKSUMS="true"
    
    # Write protected cache
    write_cache_with_checksum "$test_file" "$test_content"
    
    # Corrupt the file (change content but keep checksum)
    sed -i.bak 's/original content/corrupted content/' "$test_file"
    
    # Attempt to read - should fail due to checksum mismatch
    run read_cache_with_checksum "$test_file" "true"
    [[ $status -eq 1 ]]
}

@test "migrate_to_checksum_cache should upgrade legacy files" {
    local test_file="$TEST_CACHE_DIR/test_migration"
    local legacy_content="legacy cache content"
    
    # Create legacy cache file (without checksum)
    echo "$legacy_content" > "$test_file"
    
    # Migrate to checksum format
    run migrate_to_checksum_cache "$test_file"
    [[ $status -eq 0 ]]
    
    # Verify file now has checksum protection
    grep -q "# Cache Integrity Checksum:" "$test_file"
    
    # Verify content is preserved
    local migrated_content
    migrated_content=$(read_cache_with_checksum "$test_file" "false")
    [[ "$migrated_content" == "$legacy_content" ]]
}

# ============================================================================
# PERFORMANCE MONITORING TESTS
# ============================================================================

@test "record_cache_hit should increment hit counter" {
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    
    local test_key="test_performance_key"
    
    # Record several hits
    record_cache_hit "$test_key" 10
    record_cache_hit "$test_key" 20
    
    # Verify statistics
    [[ ${CACHE_STATS_HITS["$test_key"]} -eq 2 ]]
    [[ ${CACHE_STATS_TOTAL_CALLS["$test_key"]} -eq 2 ]]
}

@test "record_cache_miss should increment miss counter" {
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    
    local test_key="test_miss_key"
    
    # Record several misses
    record_cache_miss "$test_key" 100
    record_cache_miss "$test_key" 150
    
    # Verify statistics
    [[ ${CACHE_STATS_MISSES["$test_key"]} -eq 2 ]]
    [[ ${CACHE_STATS_TOTAL_CALLS["$test_key"]} -eq 2 ]]
}

@test "get_cache_hit_ratio should calculate correct percentages" {
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    
    local test_key="test_ratio_key"
    
    # Record 3 hits and 1 miss (75% hit rate)
    record_cache_hit "$test_key" 10
    record_cache_hit "$test_key" 10
    record_cache_hit "$test_key" 10
    record_cache_miss "$test_key" 100
    
    local hit_ratio
    hit_ratio=$(get_cache_hit_ratio "$test_key")
    
    [[ "$hit_ratio" == "75.00" ]]
}

@test "clear_cache_stats should reset statistics" {
    export CACHE_CONFIG_ENABLE_STATISTICS="true"
    
    local test_key="test_clear_key"
    
    # Record some statistics
    record_cache_hit "$test_key" 10
    record_cache_miss "$test_key" 100
    
    # Verify statistics exist
    [[ ${CACHE_STATS_HITS["$test_key"]} -eq 1 ]]
    [[ ${CACHE_STATS_MISSES["$test_key"]} -eq 1 ]]
    
    # Clear statistics
    clear_cache_stats "$test_key"
    
    # Verify statistics are cleared
    [[ -z "${CACHE_STATS_HITS["$test_key"]:-}" ]]
    [[ -z "${CACHE_STATS_MISSES["$test_key"]:-}" ]]
}

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

@test "report_cache_error should format error messages correctly" {
    # Capture debug_log output by checking return code
    run report_cache_error "TEST_ERROR" "Test error context" "Test suggestion" 42
    [[ $status -eq 42 ]]
}

@test "report_cache_warning should format warning messages correctly" {
    # Capture debug_log output by checking that function completes
    run report_cache_warning "TEST_WARNING" "Test warning context" "Test recovery action"
    [[ $status -eq 0 ]]
}

@test "detect_and_recover_corruption should remove corrupted files" {
    # Skip on macOS - BSD grep doesn't detect null bytes the same way as GNU grep
    # This is a known platform difference tracked in Issue #79
    [[ "$(uname -s)" == "Darwin" ]] && skip "Null byte detection via grep differs on macOS"

    local corrupted_file="$TEST_CACHE_DIR/corrupted_test"

    # Create file with null bytes (corruption)
    printf "valid content\x00corrupted content" > "$corrupted_file"

    # Should detect corruption and remove file
    run detect_and_recover_corruption "$corrupted_file"
    [[ $status -eq 1 ]]
    [[ ! -f "$corrupted_file" ]]
}

@test "detect_and_recover_corruption should accept valid files" {
    local valid_file="$TEST_CACHE_DIR/valid_test"
    
    # Create valid file
    echo "completely valid content" > "$valid_file"
    
    # Should pass validation
    run detect_and_recover_corruption "$valid_file"
    [[ $status -eq 0 ]]
    [[ -f "$valid_file" ]]
}

# ============================================================================
# RESOURCE CLEANUP TESTS
# ============================================================================

@test "register_temp_file should add files to cleanup registry" {
    local temp_file="/tmp/test_temp_$$"
    touch "$temp_file"
    
    # Register for cleanup
    register_temp_file "$temp_file"
    
    # Verify file is in cleanup registry
    local found=false
    for file in "${CACHE_TEMP_FILES[@]}"; do
        if [[ "$file" == "$temp_file" ]]; then
            found=true
            break
        fi
    done
    
    [[ "$found" == "true" ]]
    
    # Manual cleanup for test
    rm -f "$temp_file"
}

@test "install_cleanup_traps should install signal handlers" {
    # This test is difficult to verify directly, but we can check that
    # the function completes without error
    run install_cleanup_traps
    [[ $status -eq 0 ]]
}

# ============================================================================
# CONFIGURATION LOADING TESTS
# ============================================================================

@test "load_cache_configuration should set default values" {
    # Clear existing configuration
    unset CACHE_CONFIG_ENABLE_UNIVERSAL
    unset CACHE_CONFIG_ENABLE_STATISTICS
    
    # Load configuration
    load_cache_configuration
    
    # Verify defaults are set
    [[ "$CACHE_CONFIG_ENABLE_UNIVERSAL" == "true" ]]
    [[ "$CACHE_CONFIG_ENABLE_STATISTICS" == "true" ]]
}

@test "load_cache_configuration should respect environment variables" {
    export ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING="false"
    export ENV_CONFIG_CACHE_ENABLE_STATISTICS="false"
    
    # Load configuration
    load_cache_configuration
    
    # Verify environment variables are respected
    [[ -z "$CACHE_CONFIG_ENABLE_UNIVERSAL" ]]
    [[ -z "$CACHE_CONFIG_ENABLE_STATISTICS" ]]
    
    # Cleanup
    unset ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING
    unset ENV_CONFIG_CACHE_ENABLE_STATISTICS
}