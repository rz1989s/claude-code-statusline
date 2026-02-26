#!/bin/bash

# ============================================================================
# Claude Code Statusline - GitHub Integration Module (Issue #92)
# ============================================================================
#
# This module provides GitHub API integration for the statusline:
# - CI/CD workflow status (passing/failing)
# - Open PR count
# - Latest release version
# - Rate limit handling
# - Intelligent caching (5 min TTL)
#
# Dependencies: core.sh, cache.sh
# Requires: gh CLI (GitHub CLI)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_GITHUB_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_GITHUB_LOADED=true

# ============================================================================
# GITHUB CONFIGURATION DEFAULTS
# ============================================================================

CONFIG_GITHUB_ENABLED="${CONFIG_GITHUB_ENABLED:-false}"
CONFIG_GITHUB_SHOW_CI_STATUS="${CONFIG_GITHUB_SHOW_CI_STATUS:-true}"
CONFIG_GITHUB_SHOW_OPEN_PRS="${CONFIG_GITHUB_SHOW_OPEN_PRS:-true}"
CONFIG_GITHUB_SHOW_LATEST_RELEASE="${CONFIG_GITHUB_SHOW_LATEST_RELEASE:-false}"
CONFIG_GITHUB_CACHE_TTL="${CONFIG_GITHUB_CACHE_TTL:-300}"  # 5 minutes
CONFIG_GITHUB_TIMEOUT="${CONFIG_GITHUB_TIMEOUT:-10}"       # 10 seconds

# Rate limiting configuration
CONFIG_GITHUB_RATE_LIMIT_THRESHOLD="${CONFIG_GITHUB_RATE_LIMIT_THRESHOLD:-100}"  # Warn when below this
CONFIG_GITHUB_RATE_LIMIT_CRITICAL="${CONFIG_GITHUB_RATE_LIMIT_CRITICAL:-10}"     # Stop API calls below this
CONFIG_GITHUB_RATE_LIMIT_CACHE_TTL="${CONFIG_GITHUB_RATE_LIMIT_CACHE_TTL:-60}"   # Cache rate limit for 60s
CONFIG_GITHUB_SHOW_RATE_LIMIT_WARNING="${CONFIG_GITHUB_SHOW_RATE_LIMIT_WARNING:-true}"

# Status indicators
CONFIG_GITHUB_CI_PASSING="${CONFIG_GITHUB_CI_PASSING:-✓}"
CONFIG_GITHUB_CI_FAILING="${CONFIG_GITHUB_CI_FAILING:-✗}"
CONFIG_GITHUB_CI_PENDING="${CONFIG_GITHUB_CI_PENDING:-●}"
CONFIG_GITHUB_CI_UNKNOWN="${CONFIG_GITHUB_CI_UNKNOWN:-?}"

# ============================================================================
# RATE LIMITING (Issue #121)
# ============================================================================

# Global rate limit state
GITHUB_RATE_LIMITED="false"
GITHUB_RATE_REMAINING=""
GITHUB_RATE_RESET=""

# Check API rate limit status
# Returns: 0 if OK to proceed, 1 if rate limited
check_api_rate_limit() {
    local force_check="${1:-false}"
    # Issue #135: Use XDG-compliant fallback instead of /tmp
    local cache_file="${CACHE_BASE_DIR:-${HOME:-.}/.cache/claude-code-statusline}/github_rate_limit_cache"
    local cache_ttl="${CONFIG_GITHUB_RATE_LIMIT_CACHE_TTL:-60}"

    # Check cached rate limit first (unless forced)
    if [[ "$force_check" != "true" && -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(get_file_mtime "$cache_file")))
        if [[ $file_age -lt $cache_ttl ]]; then
            local cached_data
            cached_data=$(cat "$cache_file" 2>/dev/null)
            GITHUB_RATE_REMAINING=$(echo "$cached_data" | cut -d: -f1)
            GITHUB_RATE_RESET=$(echo "$cached_data" | cut -d: -f2)
            GITHUB_RATE_LIMITED=$(echo "$cached_data" | cut -d: -f3)

            if [[ "$GITHUB_RATE_LIMITED" == "true" ]]; then
                debug_log "Rate limit cached: $GITHUB_RATE_REMAINING remaining, reset at $GITHUB_RATE_RESET" "WARN"
                return 1
            fi
            return 0
        fi
    fi

    # Query GitHub API for rate limit
    local rate_data
    if command_exists timeout; then
        rate_data=$(timeout 5 gh api rate_limit 2>/dev/null)
    elif command_exists gtimeout; then
        rate_data=$(gtimeout 5 gh api rate_limit 2>/dev/null)
    else
        rate_data=$(gh api rate_limit 2>/dev/null)
    fi

    if [[ -z "$rate_data" ]]; then
        debug_log "Failed to get rate limit info" "WARN"
        # Assume OK if we can't check
        return 0
    fi

    # Parse rate limit response
    GITHUB_RATE_REMAINING=$(echo "$rate_data" | jq -r '.rate.remaining // 5000' 2>/dev/null)
    GITHUB_RATE_RESET=$(echo "$rate_data" | jq -r '.rate.reset // 0' 2>/dev/null)

    local critical_threshold="${CONFIG_GITHUB_RATE_LIMIT_CRITICAL:-10}"

    # Check if critically rate limited
    if [[ -n "$GITHUB_RATE_REMAINING" && "$GITHUB_RATE_REMAINING" -lt "$critical_threshold" ]]; then
        GITHUB_RATE_LIMITED="true"
        debug_log "GitHub API rate limit critical: $GITHUB_RATE_REMAINING remaining" "WARN"

        # Cache the rate limited state
        echo "${GITHUB_RATE_REMAINING}:${GITHUB_RATE_RESET}:true" > "$cache_file" 2>/dev/null

        return 1
    fi

    GITHUB_RATE_LIMITED="false"

    # Cache the OK state
    echo "${GITHUB_RATE_REMAINING}:${GITHUB_RATE_RESET}:false" > "$cache_file" 2>/dev/null

    # Log warning if approaching threshold
    local warn_threshold="${CONFIG_GITHUB_RATE_LIMIT_THRESHOLD:-100}"
    if [[ -n "$GITHUB_RATE_REMAINING" && "$GITHUB_RATE_REMAINING" -lt "$warn_threshold" ]]; then
        debug_log "GitHub API quota low: $GITHUB_RATE_REMAINING remaining" "WARN"
    fi

    return 0
}

# Get rate limit warning for display (if enabled)
get_rate_limit_warning() {
    if [[ "${CONFIG_GITHUB_SHOW_RATE_LIMIT_WARNING:-true}" != "true" ]]; then
        echo ""
        return 0
    fi

    local warn_threshold="${CONFIG_GITHUB_RATE_LIMIT_THRESHOLD:-100}"

    if [[ -n "$GITHUB_RATE_REMAINING" && "$GITHUB_RATE_REMAINING" -lt "$warn_threshold" ]]; then
        local reset_time=""
        if [[ -n "$GITHUB_RATE_RESET" && "$GITHUB_RATE_RESET" != "0" ]]; then
            reset_time=$(date -r "$GITHUB_RATE_RESET" "+%H:%M" 2>/dev/null || echo "")
        fi

        if [[ -n "$reset_time" ]]; then
            echo "⚠️ GH:${GITHUB_RATE_REMAINING}@${reset_time}"
        else
            echo "⚠️ GH:${GITHUB_RATE_REMAINING}"
        fi
    else
        echo ""
    fi
}

# Get time until rate limit reset (human readable)
get_rate_limit_reset_time() {
    if [[ -z "$GITHUB_RATE_RESET" || "$GITHUB_RATE_RESET" == "0" ]]; then
        echo ""
        return 0
    fi

    local now reset_in
    now=$(date +%s)
    reset_in=$((GITHUB_RATE_RESET - now))

    if [[ $reset_in -lt 0 ]]; then
        echo "now"
    elif [[ $reset_in -lt 60 ]]; then
        echo "${reset_in}s"
    else
        echo "$((reset_in / 60))m"
    fi
}

# ============================================================================
# GITHUB UTILITIES
# ============================================================================

# Check if GitHub integration is enabled
is_github_enabled() {
    [[ "${CONFIG_GITHUB_ENABLED:-false}" == "true" ]]
}

# Check if gh CLI is available
is_gh_available() {
    command_exists gh
}

# Check if we're in a git repo with GitHub remote
is_github_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 1
    fi

    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)

    [[ "$remote_url" == *"github.com"* ]]
}

# Get repository owner/name from git remote
get_github_repo_info() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)

    if [[ -z "$remote_url" ]]; then
        echo ""
        return 1
    fi

    # Parse GitHub URL formats:
    # git@github.com:owner/repo.git
    # https://github.com/owner/repo.git
    local repo_info

    if [[ "$remote_url" == git@github.com:* ]]; then
        repo_info="${remote_url#git@github.com:}"
    elif [[ "$remote_url" == https://github.com/* ]]; then
        repo_info="${remote_url#https://github.com/}"
    else
        echo ""
        return 1
    fi

    # Remove .git suffix
    repo_info="${repo_info%.git}"

    echo "$repo_info"
}

# Execute gh command with timeout and rate limit checking
execute_gh_command() {
    local timeout="${CONFIG_GITHUB_TIMEOUT:-10}"
    local cmd="$1"
    shift

    # Check rate limit before making API call
    if ! check_api_rate_limit; then
        debug_log "Skipping GitHub API call due to rate limit" "WARN"
        echo ""
        return 1
    fi

    local result
    if command_exists timeout; then
        result=$(timeout "$timeout" gh "$cmd" "$@" 2>/dev/null)
    elif command_exists gtimeout; then
        result=$(gtimeout "$timeout" gh "$cmd" "$@" 2>/dev/null)
    else
        result=$(gh "$cmd" "$@" 2>/dev/null)
    fi

    echo "$result"
}

# ============================================================================
# CI/CD STATUS
# ============================================================================

# Get CI status for the current branch
get_ci_status() {
    if ! is_github_enabled || ! is_gh_available || ! is_github_repo; then
        echo ""
        return 1
    fi

    local cache_key="github_ci_status"
    local cache_ttl="${CONFIG_GITHUB_CACHE_TTL:-300}"

    # Try cache first using file-based caching
    # Issue #135: Use XDG-compliant fallback instead of /tmp
    local cache_file="${CACHE_BASE_DIR:-${HOME:-.}/.cache/claude-code-statusline}/github_ci_status_cache"
    local use_stale_cache="false"

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(get_file_mtime "$cache_file")))
        if [[ $file_age -lt $cache_ttl ]]; then
            cat "$cache_file"
            return 0
        fi
        # Cache is stale but usable as fallback
        use_stale_cache="true"
    fi

    # Get current branch
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [[ -z "$branch" ]]; then
        echo "${CONFIG_GITHUB_CI_UNKNOWN:-?}"
        return 1
    fi

    # Get workflow run status using gh CLI
    local run_status
    run_status=$(execute_gh_command run list --branch "$branch" --limit 1 --json conclusion,status 2>/dev/null)

    # If API call failed (rate limited), use stale cache
    if [[ -z "$run_status" && "$use_stale_cache" == "true" ]]; then
        debug_log "Using stale cache for CI status (rate limited)" "INFO"
        cat "$cache_file"
        return 0
    fi

    if [[ -z "$run_status" || "$run_status" == "[]" ]]; then
        debug_log "No CI runs found for branch: $branch" "INFO"
        echo "${CONFIG_GITHUB_CI_UNKNOWN:-?}"
        return 0
    fi

    # Parse JSON response
    local status conclusion
    status=$(echo "$run_status" | jq -r '.[0].status // empty' 2>/dev/null)
    conclusion=$(echo "$run_status" | jq -r '.[0].conclusion // empty' 2>/dev/null)

    local ci_indicator
    if [[ "$status" == "in_progress" || "$status" == "queued" ]]; then
        ci_indicator="${CONFIG_GITHUB_CI_PENDING:-●}"
    elif [[ "$conclusion" == "success" ]]; then
        ci_indicator="${CONFIG_GITHUB_CI_PASSING:-✓}"
    elif [[ "$conclusion" == "failure" || "$conclusion" == "cancelled" ]]; then
        ci_indicator="${CONFIG_GITHUB_CI_FAILING:-✗}"
    else
        ci_indicator="${CONFIG_GITHUB_CI_UNKNOWN:-?}"
    fi

    # Cache result
    echo "$ci_indicator" > "$cache_file" 2>/dev/null

    echo "$ci_indicator"
}

# Get CI status with label
get_ci_status_display() {
    if ! is_github_enabled; then
        echo ""
        return 0
    fi

    local status
    status=$(get_ci_status)

    if [[ -z "$status" ]]; then
        echo ""
        return 0
    fi

    echo "CI: $status"
}

# ============================================================================
# PULL REQUEST COUNT
# ============================================================================

# Get count of open PRs
get_open_pr_count() {
    if ! is_github_enabled || ! is_gh_available || ! is_github_repo; then
        echo ""
        return 1
    fi

    local cache_key="github_pr_count"
    local cache_ttl="${CONFIG_GITHUB_CACHE_TTL:-300}"

    # Try cache first using file-based caching
    # Issue #135: Use XDG-compliant fallback instead of /tmp
    local cache_file="${CACHE_BASE_DIR:-${HOME:-.}/.cache/claude-code-statusline}/github_pr_count_cache"
    local use_stale_cache="false"

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(get_file_mtime "$cache_file")))
        if [[ $file_age -lt $cache_ttl ]]; then
            cat "$cache_file"
            return 0
        fi
        # Cache is stale but usable as fallback
        use_stale_cache="true"
    fi

    # Get open PR count using gh CLI
    local pr_list
    pr_list=$(execute_gh_command pr list --state open --json number 2>/dev/null)

    # If API call failed (rate limited), use stale cache
    if [[ -z "$pr_list" && "$use_stale_cache" == "true" ]]; then
        debug_log "Using stale cache for PR count (rate limited)" "INFO"
        cat "$cache_file"
        return 0
    fi

    local pr_count
    pr_count=$(echo "$pr_list" | jq 'length' 2>/dev/null)

    if [[ -z "$pr_count" || "$pr_count" == "null" ]]; then
        pr_count="0"
    fi

    # Cache result
    echo "$pr_count" > "$cache_file" 2>/dev/null

    echo "$pr_count"
}

# Get PR count with label
get_pr_count_display() {
    if ! is_github_enabled || ! "${CONFIG_GITHUB_SHOW_OPEN_PRS:-true}"; then
        echo ""
        return 0
    fi

    local count
    count=$(get_open_pr_count)

    if [[ -z "$count" || "$count" == "0" ]]; then
        echo ""
        return 0
    fi

    echo "PRs: $count"
}

# ============================================================================
# LATEST RELEASE
# ============================================================================

# Get latest release version
get_latest_release() {
    if ! is_github_enabled || ! is_gh_available || ! is_github_repo; then
        echo ""
        return 1
    fi

    local cache_key="github_latest_release"
    local cache_ttl="${CONFIG_GITHUB_CACHE_TTL:-300}"

    # Try cache first using file-based caching
    # Issue #135: Use XDG-compliant fallback instead of /tmp
    local cache_file="${CACHE_BASE_DIR:-${HOME:-.}/.cache/claude-code-statusline}/github_release_cache"
    local use_stale_cache="false"

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(get_file_mtime "$cache_file")))
        if [[ $file_age -lt $cache_ttl ]]; then
            cat "$cache_file"
            return 0
        fi
        # Cache is stale but usable as fallback
        use_stale_cache="true"
    fi

    # Get latest release using gh CLI
    local release_data
    release_data=$(execute_gh_command release view --json tagName 2>/dev/null)

    # If API call failed (rate limited), use stale cache
    if [[ -z "$release_data" && "$use_stale_cache" == "true" ]]; then
        debug_log "Using stale cache for release info (rate limited)" "INFO"
        cat "$cache_file"
        return 0
    fi

    local release_tag
    release_tag=$(echo "$release_data" | jq -r '.tagName // empty' 2>/dev/null)

    if [[ -z "$release_tag" ]]; then
        release_tag=""
    fi

    # Cache result
    if [[ -n "$release_tag" ]]; then
        echo "$release_tag" > "$cache_file" 2>/dev/null
    fi

    echo "$release_tag"
}

# Get release with label
get_release_display() {
    if ! is_github_enabled || ! "${CONFIG_GITHUB_SHOW_LATEST_RELEASE:-false}"; then
        echo ""
        return 0
    fi

    local release
    release=$(get_latest_release)

    if [[ -z "$release" ]]; then
        echo ""
        return 0
    fi

    echo "Release: $release"
}

# ============================================================================
# GITHUB COMPONENT FOR STATUSLINE
# ============================================================================

# Main component function for statusline display
get_github_component() {
    if ! is_github_enabled; then
        echo ""
        return 0
    fi

    if ! is_gh_available; then
        debug_log "GitHub CLI (gh) not available" "WARN"
        echo ""
        return 0
    fi

    if ! is_github_repo; then
        debug_log "Not a GitHub repository" "INFO"
        echo ""
        return 0
    fi

    local parts=()

    # Rate limit warning (if enabled and quota low)
    local rate_warning
    rate_warning=$(get_rate_limit_warning)
    [[ -n "$rate_warning" ]] && parts+=("$rate_warning")

    # CI Status
    if [[ "${CONFIG_GITHUB_SHOW_CI_STATUS:-true}" == "true" ]]; then
        local ci_display
        ci_display=$(get_ci_status_display)
        [[ -n "$ci_display" ]] && parts+=("$ci_display")
    fi

    # Open PRs
    if [[ "${CONFIG_GITHUB_SHOW_OPEN_PRS:-true}" == "true" ]]; then
        local pr_display
        pr_display=$(get_pr_count_display)
        [[ -n "$pr_display" ]] && parts+=("$pr_display")
    fi

    # Latest Release
    if [[ "${CONFIG_GITHUB_SHOW_LATEST_RELEASE:-false}" == "true" ]]; then
        local release_display
        release_display=$(get_release_display)
        [[ -n "$release_display" ]] && parts+=("$release_display")
    fi

    # Join parts with separator
    if [[ ${#parts[@]} -gt 0 ]]; then
        local IFS=" │ "
        echo "${parts[*]}"
    else
        echo ""
    fi
}

# ============================================================================
# GITHUB STATUS SUMMARY
# ============================================================================

# Get a brief summary for compact display
get_github_status_summary() {
    if ! is_github_enabled || ! is_gh_available || ! is_github_repo; then
        echo ""
        return 0
    fi

    local ci_status pr_count
    ci_status=$(get_ci_status)
    pr_count=$(get_open_pr_count)

    local summary=""

    if [[ -n "$ci_status" ]]; then
        summary="$ci_status"
    fi

    if [[ -n "$pr_count" && "$pr_count" != "0" ]]; then
        [[ -n "$summary" ]] && summary="$summary "
        summary="${summary}${pr_count}PR"
    fi

    echo "$summary"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the GitHub module
init_github_module() {
    debug_log "GitHub module initialized" "INFO"

    if is_github_enabled; then
        if ! is_gh_available; then
            debug_log "GitHub enabled but gh CLI not found - install with: brew install gh" "WARN"
        elif ! is_github_repo; then
            debug_log "GitHub enabled but not in a GitHub repository" "INFO"
        else
            debug_log "GitHub integration active" "INFO"
        fi
    else
        debug_log "GitHub integration disabled" "INFO"
    fi

    return 0
}

# Initialize the module (skip during testing)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_github_module
fi

# Export GitHub functions
export -f is_github_enabled is_gh_available is_github_repo get_github_repo_info
export -f execute_gh_command get_ci_status get_ci_status_display
export -f get_open_pr_count get_pr_count_display
export -f get_latest_release get_release_display
export -f get_github_component get_github_status_summary
export -f check_api_rate_limit get_rate_limit_warning get_rate_limit_reset_time
