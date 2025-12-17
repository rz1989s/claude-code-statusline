#!/usr/bin/env bats

# Unit tests for Git-related functions in statusline.sh

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
}

teardown() {
    common_teardown
}

# Test git repository detection
@test "should detect when inside git repository" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"
    
    run git rev-parse --is-inside-work-tree
    assert_success
}

@test "should detect when not in git repository" {
    cd "$TEST_TMP_DIR"
    
    # Mock git to fail for non-git directory
    create_failing_mock_command "git" "not a git repository" 128
    
    run git rev-parse --is-inside-work-tree
    assert_failure
}

# Test commit counting functionality
@test "get_commits_today should return commit count" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"

    # Mock git log to return 3 commits
    # Note: Pattern must match actual git command with quoted date argument
    cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
case "$*" in
    "rev-parse --is-inside-work-tree")
        echo "true"
        exit 0
        ;;
    *"--since"*"--oneline"*)
        # Match any log command with --since and --oneline flags
        echo "commit1 First commit"
        echo "commit2 Second commit"
        echo "commit3 Third commit"
        ;;
    *)
        # Fallback for other git commands
        exit 0
        ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/git"

    # Source the function and test it
    source "$STATUSLINE_SCRIPT"
    run get_commits_today

    assert_success
    assert_output "3"
}

@test "get_commits_today should return 0 for non-git directory" {
    cd "$TEST_TMP_DIR"

    # Mock git to fail for is_git_repository check
    create_failing_mock_command "git" "not a git repository" 128

    source "$STATUSLINE_SCRIPT"
    run get_commits_today

    # Function returns exit code 1 when not in git repo, but still outputs "0"
    assert_failure
    assert_output "0"
}

# Test git status detection
@test "should detect clean repository status" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"
    
    # Test the git diff commands return success (clean repo)
    run git diff --quiet
    assert_success
    
    run git diff --cached --quiet
    assert_success
}

@test "should detect dirty repository status" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "dirty"
    cd "$TEST_TMP_DIR/git_repo"
    
    # Test that git diff returns failure (dirty repo)
    run git diff --quiet
    assert_failure
}

# Test branch name extraction
@test "should extract current branch name" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"
    
    run git branch
    assert_success
    assert_output_contains "main"
}

@test "should handle detached HEAD state" {
    cd "$TEST_TMP_DIR"
    
    # Mock git branch to show detached HEAD
    cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
case "$*" in
    "rev-parse --is-inside-work-tree")
        exit 0
        ;;
    "branch")
        echo "* (HEAD detached at 1234567)"
        ;;
    *)
        echo "Mock git: $*"
        ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/git"
    
    run git branch
    assert_success
    assert_output_contains "detached"
}

# Test git status with various scenarios
@test "should handle repository with staged changes" {
    cd "$TEST_TMP_DIR"
    
    cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
case "$*" in
    "rev-parse --is-inside-work-tree")
        exit 0
        ;;
    "diff --quiet")
        exit 0  # No unstaged changes
        ;;
    "diff --cached --quiet")
        exit 1  # Has staged changes
        ;;
    "branch")
        echo "* main"
        ;;
    *)
        echo "Mock git: $*"
        ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/git"
    
    # Should be considered dirty due to staged changes
    run git diff --cached --quiet
    assert_failure
}

@test "should handle repository with unstaged changes" {
    cd "$TEST_TMP_DIR"
    
    cat > "$MOCK_BIN_DIR/git" << 'EOF'
#!/bin/bash
case "$*" in
    "rev-parse --is-inside-work-tree")
        exit 0
        ;;
    "diff --quiet")
        exit 1  # Has unstaged changes
        ;;
    "diff --cached --quiet")
        exit 0  # No staged changes
        ;;
    "branch")
        echo "* main"
        ;;
    *)
        echo "Mock git: $*"
        ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/git"
    
    # Should be considered dirty due to unstaged changes
    run git diff --quiet
    assert_failure
}

# Test edge cases
@test "should handle git command timeout" {
    cd "$TEST_TMP_DIR"
    
    # Mock git to timeout
    create_failing_mock_command "git" "" 124
    
    run git rev-parse --is-inside-work-tree
    [ "$status" -eq 124 ]  # timeout exit code
}

@test "should handle corrupted git repository" {
    cd "$TEST_TMP_DIR"
    mkdir -p ".git"
    
    # Mock git to return corruption error
    create_failing_mock_command "git" "fatal: not a git repository (or any of the parent directories)" 128
    
    run git rev-parse --is-inside-work-tree
    assert_failure
}

# Test performance with multiple rapid calls
@test "git functions should handle rapid successive calls" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"
    
    # Test multiple rapid calls don't interfere
    for i in {1..5}; do
        run git rev-parse --is-inside-work-tree
        assert_success
    done
}

# Test submodule counting functionality
@test "get_submodule_status should handle repository without submodules" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"
    
    # No .gitmodules file
    source "$STATUSLINE_SCRIPT"
    run get_submodule_status
    
    assert_success
    assert_output_contains "--"
}

@test "get_submodule_status should count submodules correctly" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"
    
    # Create mock .gitmodules file
    cat > .gitmodules << 'EOF'
[submodule "libs/awesome"]
    path = libs/awesome
    url = https://github.com/example/awesome.git
[submodule "vendor/tool"]
    path = vendor/tool
    url = https://github.com/example/tool.git
EOF
    
    source "$STATUSLINE_SCRIPT"
    run get_submodule_status
    
    assert_success
    assert_output_contains "SUB:2"
}

@test "get_submodule_status should handle malformed .gitmodules" {
    setup_mock_git_repo "$TEST_TMP_DIR/git_repo" "clean"
    cd "$TEST_TMP_DIR/git_repo"
    
    # Create malformed .gitmodules file
    echo "invalid content" > .gitmodules
    
    source "$STATUSLINE_SCRIPT"
    run get_submodule_status
    
    assert_success
    assert_output_contains "SUB:0"
}