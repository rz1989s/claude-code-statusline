#!/bin/bash

# ============================================================================
# Claude Code Statusline - GitHub Component (Issue #92)
# ============================================================================
#
# This component displays GitHub CI/CD status, open PRs, and release info.
#
# Dependencies: github.sh
# ============================================================================

# Component data storage
COMPONENT_GITHUB_CI_STATUS=""
COMPONENT_GITHUB_PR_COUNT=""
COMPONENT_GITHUB_RELEASE=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect GitHub data
collect_github_data() {
    debug_log "Collecting github component data" "INFO"

    # Reset data
    COMPONENT_GITHUB_CI_STATUS=""
    COMPONENT_GITHUB_PR_COUNT=""
    COMPONENT_GITHUB_RELEASE=""

    # Check if GitHub module is loaded and enabled
    if ! is_module_loaded "github"; then
        debug_log "GitHub module not loaded" "INFO"
        return 0
    fi

    if ! is_github_enabled; then
        debug_log "GitHub integration disabled" "INFO"
        return 0
    fi

    if ! is_gh_available; then
        debug_log "GitHub CLI (gh) not available" "WARN"
        return 0
    fi

    if ! is_github_repo; then
        debug_log "Not a GitHub repository" "INFO"
        return 0
    fi

    # Collect CI status
    if [[ "${CONFIG_GITHUB_SHOW_CI_STATUS:-true}" == "true" ]]; then
        COMPONENT_GITHUB_CI_STATUS=$(get_ci_status)
        debug_log "GitHub CI status: $COMPONENT_GITHUB_CI_STATUS" "INFO"
    fi

    # Collect PR count
    if [[ "${CONFIG_GITHUB_SHOW_OPEN_PRS:-true}" == "true" ]]; then
        COMPONENT_GITHUB_PR_COUNT=$(get_open_pr_count)
        debug_log "GitHub PR count: $COMPONENT_GITHUB_PR_COUNT" "INFO"
    fi

    # Collect latest release
    if [[ "${CONFIG_GITHUB_SHOW_LATEST_RELEASE:-false}" == "true" ]]; then
        COMPONENT_GITHUB_RELEASE=$(get_latest_release)
        debug_log "GitHub release: $COMPONENT_GITHUB_RELEASE" "INFO"
    fi

    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render GitHub status display
render_github() {
    # Check if enabled and has data
    if ! is_github_enabled; then
        echo ""
        return 0
    fi

    local parts=()

    # CI Status
    if [[ -n "$COMPONENT_GITHUB_CI_STATUS" ]]; then
        parts+=("CI: $COMPONENT_GITHUB_CI_STATUS")
    fi

    # PR Count (only show if > 0)
    if [[ -n "$COMPONENT_GITHUB_PR_COUNT" && "$COMPONENT_GITHUB_PR_COUNT" != "0" ]]; then
        parts+=("PRs: $COMPONENT_GITHUB_PR_COUNT")
    fi

    # Latest Release
    if [[ -n "$COMPONENT_GITHUB_RELEASE" ]]; then
        parts+=("Rel: $COMPONENT_GITHUB_RELEASE")
    fi

    # Join parts with separator
    if [[ ${#parts[@]} -gt 0 ]]; then
        local IFS=" "
        echo "${parts[*]}"
    else
        echo ""
    fi

    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_github_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            echo "${CONFIG_GITHUB_ENABLED:-false}"
            ;;
        "show_ci_status")
            echo "${CONFIG_GITHUB_SHOW_CI_STATUS:-true}"
            ;;
        "show_open_prs")
            echo "${CONFIG_GITHUB_SHOW_OPEN_PRS:-true}"
            ;;
        "show_latest_release")
            echo "${CONFIG_GITHUB_SHOW_LATEST_RELEASE:-false}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the github component
register_component \
    "github" \
    "GitHub CI status, PRs, and releases" \
    "github" \
    "$(get_github_config 'enabled' 'false')"

debug_log "GitHub component loaded" "INFO"
