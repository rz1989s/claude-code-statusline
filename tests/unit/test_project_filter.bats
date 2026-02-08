#!/usr/bin/env bats
# ==============================================================================
# Test: --project filter for report commands
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    STATUSLINE_CLI_REPORT_FORMAT_LOADED=""
    source "$STATUSLINE_ROOT/lib/cli/report_format.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ==============================================================================
# resolve_project_filter() Tests
# ==============================================================================

@test "resolve_project_filter returns failure on empty query" {
    set +e
    resolve_project_filter "" "/tmp" 2>/dev/null
    local rc=$?
    set -e
    [[ "$rc" -ne 0 ]]
}

@test "resolve_project_filter returns failure on empty projects_dir" {
    set +e
    resolve_project_filter "test" "" 2>/dev/null
    local rc=$?
    set -e
    [[ "$rc" -ne 0 ]]
}

@test "resolve_project_filter returns failure on missing directory" {
    set +e
    resolve_project_filter "test" "/tmp/nonexistent_dir_$$" 2>/dev/null
    local rc=$?
    set -e
    [[ "$rc" -ne 0 ]]
}

@test "resolve_project_filter finds exact match" {
    local test_dir="$TEST_TMP_DIR/projects"
    mkdir -p "$test_dir/-Users-foo-myapp"
    local result
    result=$(resolve_project_filter "myapp" "$test_dir" 2>/dev/null)
    [[ "$result" == *"myapp"* ]]
}

@test "resolve_project_filter finds fuzzy match" {
    local test_dir="$TEST_TMP_DIR/projects"
    mkdir -p "$test_dir/-Users-foo-myawesomeapp"
    local result
    result=$(resolve_project_filter "awesome" "$test_dir" 2>/dev/null)
    [[ "$result" == *"myawesomeapp"* ]]
}

@test "resolve_project_filter returns error 2 on ambiguous match" {
    local test_dir="$TEST_TMP_DIR/projects"
    mkdir -p "$test_dir/-Users-foo-coolapp"
    mkdir -p "$test_dir/-Users-bar-niceapp"
    set +e
    resolve_project_filter "app" "$test_dir" 2>/dev/null
    local rc=$?
    set -e
    [[ "$rc" -eq 2 ]]
}

@test "resolve_project_filter returns error 1 on no match" {
    local test_dir="$TEST_TMP_DIR/projects"
    mkdir -p "$test_dir/-Users-foo-myapp"
    set +e
    resolve_project_filter "nonexistent" "$test_dir" 2>/dev/null
    local rc=$?
    set -e
    [[ "$rc" -eq 1 ]]
}

@test "resolve_project_filter lists available projects on no match" {
    local test_dir="$TEST_TMP_DIR/projects"
    mkdir -p "$test_dir/-Users-foo-myapp"
    set +e
    local stderr_output
    stderr_output=$(resolve_project_filter "nonexistent" "$test_dir" 2>&1 >/dev/null)
    set -e
    [[ "$stderr_output" == *"myapp"* ]]
}

@test "resolve_project_filter prefers exact match over fuzzy" {
    local test_dir="$TEST_TMP_DIR/projects"
    mkdir -p "$test_dir/-Users-foo-app"
    mkdir -p "$test_dir/-Users-foo-myapp"
    local result
    result=$(resolve_project_filter "app" "$test_dir" 2>/dev/null)
    [[ "$result" == *"-Users-foo-app"* ]]
}

# ==============================================================================
# CLI integration tests
# ==============================================================================

@test "--project flag is recognized with --daily" {
    run "$STATUSLINE_SCRIPT" --daily --project nonexistent-project-$$
    assert_failure
    assert_output --partial "No project found"
}

@test "--project= syntax is recognized" {
    run "$STATUSLINE_SCRIPT" --daily --project=nonexistent-project-$$
    assert_failure
    assert_output --partial "No project found"
}

@test "--project without value shows error" {
    run "$STATUSLINE_SCRIPT" --daily --project
    assert_failure
    assert_output --partial "Error"
}

@test "--project works with --weekly" {
    run "$STATUSLINE_SCRIPT" --weekly --project nonexistent-project-$$
    assert_failure
    assert_output --partial "No project found"
}

@test "--project works with --monthly" {
    run "$STATUSLINE_SCRIPT" --monthly --project nonexistent-project-$$
    assert_failure
    assert_output --partial "No project found"
}

@test "--project works with --breakdown" {
    run "$STATUSLINE_SCRIPT" --breakdown --project nonexistent-project-$$
    assert_failure
    assert_output --partial "No project found"
}

@test "--project works with --instances" {
    run "$STATUSLINE_SCRIPT" --instances --project nonexistent-project-$$
    assert_failure
    assert_output --partial "No project found"
}

@test "--project shows available projects on no match" {
    run "$STATUSLINE_SCRIPT" --daily --project nonexistent-project-$$
    assert_failure
    assert_output --partial "Available projects"
}

# ==============================================================================
# Help text tests
# ==============================================================================

@test "--help mentions --project flag" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--project"
}

@test "--help shows project filter example" {
    run "$STATUSLINE_SCRIPT" --help
    assert_success
    assert_output --partial "--project my-app"
}
