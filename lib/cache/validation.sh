#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Validation Module
# ============================================================================
#
# This module provides various validation functions for cached data including
# basic validation, JSON validation, Git-specific validation, and content
# validators.
#
# Dependencies: core.sh (for command_exists, debug_log)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_VALIDATION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_VALIDATION_LOADED=true

# ============================================================================
# CACHE VALIDATION FUNCTIONS
# ============================================================================

# Generic cache validation (non-empty file)
validate_basic_cache() {
    local cache_file="$1"
    [[ -f "$cache_file" && -s "$cache_file" ]]
}

# JSON cache validation
validate_json_cache() {
    local cache_file="$1"

    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi

    if command_exists jq; then
        jq empty "$cache_file" 2>/dev/null
    else
        # Basic JSON syntax check
        [[ "$(head -c1 "$cache_file")" =~ ^[\{\[] ]]
    fi
}

# Command output validation (exit code based)
validate_command_output() {
    local cache_file="$1"
    local expected_pattern="${2:-.*}"

    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi

    # Check if content matches expected pattern
    grep -q "$expected_pattern" "$cache_file" 2>/dev/null
}

# Git output validation
validate_git_cache() {
    local cache_file="$1"
    local git_operation="${2:-status}"

    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi

    case "$git_operation" in
        "branch")
            # Enhanced branch name validation using Git's own validation rules
            # Supports Unicode, emojis, and all valid Git branch naming conventions
            validate_git_branch_name "$cache_file"
            ;;
        "status")
            # Status should be clean, dirty, or not_git
            grep -qE "^(clean|dirty|not_git)$" "$cache_file" 2>/dev/null
            ;;
        "config")
            # Config values can be anything, just check non-empty
            validate_basic_cache "$cache_file"
            ;;
        *)
            validate_basic_cache "$cache_file"
            ;;
    esac
}

# Enhanced Git branch name validation using Git's own validation rules
validate_git_branch_name() {
    local cache_file="$1"

    # First perform basic cache validation
    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi

    local branch_name
    branch_name="$(cat "$cache_file" 2>/dev/null)"

    # Handle empty branch names (can happen during git operations)
    if [[ -z "$branch_name" ]]; then
        report_cache_warning "VALIDATION_FAILED" \
            "Empty branch name in cache file: $(basename "$cache_file")" \
            "Git repository may be in detached HEAD state or cache corruption"
        return 1
    fi

    # Use Git's own validation for branch names (supports Unicode, emojis, etc.)
    if command -v git >/dev/null 2>&1; then
        if git check-ref-format --branch "$branch_name" 2>/dev/null; then
            return 0
        else
            report_cache_warning "GIT_VALIDATION_FAILED" \
                "Invalid Git branch name: $branch_name" \
                "Branch name violates Git naming rules - clearing cache for regeneration"
            rm -f "$cache_file" 2>/dev/null  # Remove invalid cache to force regeneration
            return 1
        fi
    else
        # Fallback validation if git is not available (should be rare)
        # Allow most characters but reject obvious invalid cases
        if [[ "$branch_name" =~ ^[[:space:]]*$ ]] || \
           [[ "$branch_name" =~ \\.\\. ]] || \
           [[ "$branch_name" =~ [[:cntrl:]] ]] || \
           [[ "$branch_name" =~ ^\\.$ ]] || \
           [[ "$branch_name" =~ \\.$$ ]]; then
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Branch name failed fallback validation: $branch_name" "WARN"
            return 1
        fi

        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Used fallback branch validation for: $branch_name" "INFO"
        return 0
    fi
}

# System info validation (should never change)
validate_system_cache() {
    local cache_file="$1"
    validate_basic_cache "$cache_file"
}

# ============================================================================
# CONTENT-SPECIFIC VALIDATION FUNCTIONS
# ============================================================================

# Validate git branch content (not file)
validate_git_branch_content() {
    local content="$1"
    [[ -n "$content" ]] && [[ ! "$content" =~ $'\n' ]] && [[ ${#content} -lt 256 ]]
}

# Validate JSON content
validate_json_content() {
    local content="$1"
    echo "$content" | jq . >/dev/null 2>&1
}

# Validate command output content
validate_command_output_content() {
    local content="$1"
    [[ -n "$content" ]] && [[ ${#content} -lt 10240 ]]  # Reasonable size limit
}

# Validate basic content (no null bytes)
validate_basic_content() {
    local content="$1"
    [[ -n "$content" ]] && [[ ! "$content" =~ $'\0' ]]  # No null bytes
}

# Export functions
export -f validate_basic_cache validate_json_cache validate_command_output
export -f validate_git_cache validate_git_branch_name validate_system_cache
export -f validate_git_branch_content validate_json_content
export -f validate_command_output_content validate_basic_content
