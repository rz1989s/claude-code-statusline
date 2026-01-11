#!/bin/bash

# ============================================================================
# Claude Code Statusline - Git Integration Module
# ============================================================================
#
# This module handles all git-related operations including repository status,
# commit counting, branch detection, and submodule management.
#
# Error Suppression Patterns (Issue #76):
# - git rev-parse 2>/dev/null: May fail in non-git directories (expected)
# - git branch/log/config 2>/dev/null: May fail in empty repos or missing configs
# - git submodule 2>/dev/null: May fail if no .gitmodules present
# - grep .gitmodules 2>/dev/null: File may not exist in repos without submodules
# - timeout/gtimeout 2>/dev/null: Cross-platform timeout (GNU vs BSD)
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_GIT_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_GIT_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# GIT REPOSITORY DETECTION
# ============================================================================

# Check if current directory is inside a git repository (with intelligent caching)
is_git_repository() {
    # Use cached result if available (30 second cache - directories rarely change repo status)
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local current_dir=$(pwd)
        local result
        result=$(cache_git_operation "is_repo_${current_dir//\//_}" "$CACHE_DURATION_SHORT" git rev-parse --is-inside-work-tree)
        [[ -n "$result" ]] && [[ "$result" == "true" ]]
    else
        # Fallback to direct check
        git rev-parse --is-inside-work-tree >/dev/null 2>&1
    fi
}

# Get the root directory of the git repository (with intelligent caching)
get_git_root() {
    if is_git_repository; then
        # Cache git root per directory (medium duration - rarely changes)
        if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
            local current_dir=$(pwd)
            cache_git_operation "root_${current_dir//\//_}" "$CACHE_DURATION_MEDIUM" git rev-parse --show-toplevel
        else
            git rev-parse --show-toplevel 2>/dev/null
        fi
    else
        return 1
    fi
}

# Check if current directory is the root of the git repository
is_git_root() {
    local current_dir
    local git_root
    
    current_dir=$(pwd)
    git_root=$(get_git_root)
    
    [[ "$current_dir" == "$git_root" ]]
}

# ============================================================================
# BRANCH INFORMATION
# ============================================================================

# Get current git branch name (with intelligent caching)
get_git_branch() {
    if ! is_git_repository; then
        return 1
    fi
    
    # Use cached result if available (30 second cache - branches change during development)
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local git_root
        git_root=$(get_git_root)
        cache_git_operation "branch_${git_root//\//_}" "$CACHE_DURATION_SHORT" _get_git_branch_direct
    else
        _get_git_branch_direct
    fi
}

# Internal function for direct branch detection (used by caching)
_get_git_branch_direct() {
    # Try multiple methods to get branch name
    local branch=""
    
    # Method 1: git branch (most reliable)
    branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    
    # Method 2: git symbolic-ref (fallback for detached HEAD)
    if [[ -z "$branch" ]]; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    fi
    
    # Method 3: git describe (for detached HEAD)
    if [[ -z "$branch" ]]; then
        branch=$(git describe --exact-match HEAD 2>/dev/null)
    fi
    
    # Method 4: short commit hash (last resort)
    if [[ -z "$branch" ]]; then
        branch=$(git rev-parse --short HEAD 2>/dev/null)
        [[ -n "$branch" ]] && branch="detached:$branch"
    fi
    
    if [[ -n "$branch" ]]; then
        echo "$branch"
        return 0
    else
        return 1
    fi
}

# Check if current branch is the main branch
is_main_branch() {
    local branch
    branch=$(get_git_branch)
    
    case "$branch" in
        "main"|"master"|"trunk"|"develop"|"development")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# REPOSITORY STATUS
# ============================================================================

# Get git repository status (clean/dirty)
get_git_status() {
    if ! is_git_repository; then
        echo "not_git"
        return 1
    fi
    
    # Use cached result if available (30 second cache - status changes frequently during development)
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local git_root
        git_root=$(get_git_root)
        cache_git_operation "status_${git_root//\//_}" "$CACHE_DURATION_SHORT" _get_git_status_direct
    else
        _get_git_status_direct
    fi
}

# Internal function for direct status detection (used by caching)
_get_git_status_direct() {
    # Check if repository has any changes
    if git diff --quiet && git diff --cached --quiet; then
        echo "clean"
        return 0
    else
        echo "dirty"
        return 0
    fi
}

# Check if repository has uncommitted changes
has_uncommitted_changes() {
    if ! is_git_repository; then
        return 1
    fi
    
    # Check working directory and staging area
    ! (git diff --quiet && git diff --cached --quiet)
}

# Check if repository has untracked files
has_untracked_files() {
    if ! is_git_repository; then
        return 1
    fi
    
    local untracked_count
    untracked_count=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
    [[ "$untracked_count" -gt 0 ]]
}

# Get detailed status information
get_detailed_git_status() {
    if ! is_git_repository; then
        echo "not_git_repo"
        return 1
    fi
    
    local status=""
    local staged_count modified_count untracked_count
    
    # Get counts for different types of changes
    staged_count=$(git diff --cached --name-only | wc -l | tr -d ' ')
    modified_count=$(git diff --name-only | wc -l | tr -d ' ')
    untracked_count=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
    
    # Build status string
    if [[ "$staged_count" -gt 0 ]]; then
        status="${status}+${staged_count}"
    fi
    
    if [[ "$modified_count" -gt 0 ]]; then
        [[ -n "$status" ]] && status="${status} "
        status="${status}~${modified_count}"
    fi
    
    if [[ "$untracked_count" -gt 0 ]]; then
        [[ -n "$status" ]] && status="${status} "
        status="${status}?${untracked_count}"
    fi
    
    if [[ -z "$status" ]]; then
        echo "clean"
    else
        echo "$status"
    fi
}

# ============================================================================
# COMMIT INFORMATION
# ============================================================================

# Get total commit count in current branch
get_total_commit_count() {
    if ! is_git_repository; then
        echo "0"
        return 1
    fi
    
    # Use caching for expensive commit counting operation
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cache_key
        cache_key=$(generate_typed_cache_key "total_commit_count" "git")
        cache_git_operation "$cache_key" "$CACHE_DURATION_MEDIUM" git rev-list --count HEAD
    else
        git rev-list --count HEAD 2>/dev/null || echo "0"
    fi
}

# Get commits count since a specific date
get_commits_since() {
    local since_date="$1"
    
    if ! is_git_repository; then
        echo "0"
        return 1
    fi
    
    if [[ -z "$since_date" ]]; then
        echo "0"
        return 1
    fi
    
    # Use caching for date-based commit counting with date in cache key
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cache_key
        local sanitized_date="${since_date// /_}"  # Replace spaces with underscores
        sanitized_date="${sanitized_date//:/_}"    # Replace colons with underscores
        cache_key=$(generate_typed_cache_key "commits_since_${sanitized_date}" "git")
        cache_git_operation "$cache_key" "$CACHE_DURATION_SHORT" bash -c "git log --since='$since_date' --oneline 2>/dev/null | wc -l | tr -d ' '"
    else
        git log --since="$since_date" --oneline 2>/dev/null | wc -l | tr -d ' '
    fi
}

# Get commits today
get_commits_today() {
    get_commits_since "today 00:00"
}

# Get commits this week
get_commits_this_week() {
    get_commits_since "1 week ago"
}

# Get last commit information
get_last_commit_info() {
    if ! is_git_repository; then
        return 1
    fi
    
    local commit_hash commit_date commit_message
    
    commit_hash=$(git rev-parse --short HEAD 2>/dev/null)
    commit_date=$(git log -1 --format=%cd --date=relative 2>/dev/null)
    commit_message=$(git log -1 --format=%s 2>/dev/null)
    
    if [[ -n "$commit_hash" ]]; then
        echo "${commit_hash} (${commit_date}): ${commit_message}"
        return 0
    else
        return 1
    fi
}

# ============================================================================
# SUBMODULE MANAGEMENT
# ============================================================================

# Check if repository has submodules
has_submodules() {
    # Use caching for submodule detection (rarely changes)
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cache_key
        cache_key=$(generate_typed_cache_key "has_submodules" "git")
        local result
        result=$(cache_git_operation "$cache_key" "$CACHE_DURATION_LONG" bash -c '[[ -f .gitmodules ]] && echo "true" || echo "false"')
        [[ "$result" == "true" ]]
    else
        [[ -f .gitmodules ]]
    fi
}

# Get submodule count
get_submodule_count() {
    if ! is_git_repository || ! has_submodules; then
        echo "0"
        return 0
    fi
    
    # Use caching for submodule count (rarely changes)
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cache_key
        cache_key=$(generate_typed_cache_key "submodule_count" "git")
        cache_git_operation "$cache_key" "$CACHE_DURATION_LONG" bash -c 'grep -c "^\[submodule " .gitmodules 2>/dev/null || echo "0"'
    else
        grep -c "^\[submodule " .gitmodules 2>/dev/null || echo "0"
    fi
}

# Get submodule status
get_submodule_status() {
    if ! is_git_repository; then
        echo "${CONFIG_SUBMODULE_LABEL}${CONFIG_NO_SUBMODULES}"
        return 1
    fi
    
    if ! has_submodules; then
        echo "${CONFIG_SUBMODULE_LABEL}${CONFIG_NO_SUBMODULES}"
        return 0
    fi
    
    local total_submodules
    total_submodules=$(get_submodule_count)
    
    if [[ "$total_submodules" == "0" ]]; then
        echo "${CONFIG_SUBMODULE_LABEL}${CONFIG_NO_SUBMODULES}"
    else
        echo "${CONFIG_SUBMODULE_LABEL}${total_submodules}"
    fi
}

# Get detailed submodule information
get_detailed_submodule_info() {
    if ! is_git_repository || ! has_submodules; then
        return 1
    fi
    
    # Use caching for expensive submodule status operation
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cache_key
        cache_key=$(generate_typed_cache_key "submodule_info" "git")
        cache_git_operation "$cache_key" "$CACHE_DURATION_SHORT" git submodule status
    else
        git submodule status 2>/dev/null
    fi
}

# Check if submodules are up to date
are_submodules_updated() {
    if ! is_git_repository || ! has_submodules; then
        return 0 # No submodules means they're "updated"
    fi
    
    # Check if any submodule is out of sync
    local submodule_status
    submodule_status=$(git submodule status 2>/dev/null)
    
    # Look for submodules that are not up to date (indicated by '+', '-', or 'U' prefixes)
    if echo "$submodule_status" | grep -q '^[+-U]'; then
        return 1 # Submodules are not up to date
    else
        return 0 # All submodules are up to date
    fi
}

# ============================================================================
# REMOTE INFORMATION
# ============================================================================

# Get remote repository URL
get_remote_url() {
    if ! is_git_repository; then
        return 1
    fi
    
    git config --get remote.origin.url 2>/dev/null
}

# Check if local branch is ahead/behind remote
get_remote_status() {
    if ! is_git_repository; then
        return 1
    fi
    
    local branch
    branch=$(get_git_branch)
    
    if [[ -z "$branch" ]]; then
        return 1
    fi
    
    # Fetch remote information (silently)
    git fetch --quiet 2>/dev/null || return 1
    
    local ahead behind
    ahead=$(git rev-list --count HEAD ^origin/"$branch" 2>/dev/null || echo "0")
    behind=$(git rev-list --count ^HEAD origin/"$branch" 2>/dev/null || echo "0")
    
    if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
        echo "diverged:+${ahead}/-${behind}"
    elif [[ "$ahead" -gt 0 ]]; then
        echo "ahead:+${ahead}"
    elif [[ "$behind" -gt 0 ]]; then
        echo "behind:-${behind}"
    else
        echo "up-to-date"
    fi
}

# ============================================================================
# GIT UTILITIES
# ============================================================================

# Safe git command execution with timeout
execute_git_command() {
    local timeout_duration="${1:-5s}"
    shift
    local git_command=("$@")
    
    if ! command_exists git; then
        handle_error "Git command not available" 1 "execute_git_command"
        return 1
    fi
    
    # Execute git command with timeout if available
    if command_exists timeout; then
        timeout "$timeout_duration" git "${git_command[@]}" 2>/dev/null
    elif command_exists gtimeout; then
        gtimeout "$timeout_duration" git "${git_command[@]}" 2>/dev/null
    else
        git "${git_command[@]}" 2>/dev/null
    fi
}

# Get git configuration value
get_git_config() {
    local config_key="$1"
    local default_value="${2:-}"
    
    if ! is_git_repository; then
        echo "$default_value"
        return 1
    fi
    
    local config_value
    config_value=$(git config --get "$config_key" 2>/dev/null)
    
    if [[ -n "$config_value" ]]; then
        echo "$config_value"
    else
        echo "$default_value"
    fi
}

# Check if git repository is bare
is_bare_repository() {
    [[ "$(git config --bool core.bare 2>/dev/null)" == "true" ]]
}

# ============================================================================
# DISPLAY FORMATTING
# ============================================================================

# Format git status for display
format_git_status_display() {
    local git_status
    git_status=$(get_git_status)
    
    case "$git_status" in
        "clean")
            echo "${CONFIG_CLEAN_STATUS_EMOJI}"
            ;;
        "dirty")
            echo "${CONFIG_DIRTY_STATUS_EMOJI}"
            ;;
        "not_git")
            echo ""
            ;;
        *)
            echo "${CONFIG_DIRTY_STATUS_EMOJI}"
            ;;
    esac
}

# Get git branch with color formatting
get_formatted_git_branch() {
    local branch
    branch=$(get_git_branch)
    
    if [[ -z "$branch" ]]; then
        return 1
    fi
    
    local git_status
    git_status=$(get_git_status)
    
    case "$git_status" in
        "clean")
            echo "${CONFIG_GREEN}${branch}${CONFIG_RESET}"
            ;;
        "dirty")
            echo "${CONFIG_YELLOW}${branch}${CONFIG_RESET}"
            ;;
        *)
            echo "${CONFIG_MAGENTA}${branch}${CONFIG_RESET}"
            ;;
    esac
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the git module
init_git_module() {
    debug_log "Git integration module initialized" "INFO"
    
    # Check if git is available
    if ! command_exists git; then
        handle_warning "Git command not available" "init_git_module"
        return 1
    fi
    
    # Log git version for debugging
    local git_version
    git_version=$(git --version 2>/dev/null)
    debug_log "Git version: $git_version" "INFO"
    
    return 0
}

# Initialize the module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_git_module
fi

# Issue #134: Only export functions used in cached subshells
# Internal functions called via cache_git_operation need export
export -f _get_git_branch_direct _get_git_status_direct