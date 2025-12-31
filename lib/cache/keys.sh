#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Keys Module
# ============================================================================
#
# This module handles cache key generation with support for different
# isolation modes (repository, instance, shared).
#
# Error Suppression Patterns (Issue #108):
# - pwd 2>/dev/null: Working directory may be deleted (rare but possible)
#
# Dependencies: config.sh (for CACHE_CONFIG_*_ISOLATION)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_KEYS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_KEYS_LOADED=true

# ============================================================================
# UNIFIED CACHE KEY GENERATION
# ============================================================================

# Get repository identifier for cache isolation
get_repo_identifier() {
    local repo_path="${1:-$PWD}"
    local hash_method="${2:-path}"

    # Validate path length - switch to hash method for extremely long paths
    if [[ ${#repo_path} -gt 200 ]]; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && \
            debug_log "Repository path too long (${#repo_path} chars), using hash method" "INFO"
        hash_method="hash"
    fi

    case "$hash_method" in
        "hash")
            # Use SHA-256 hash for shorter keys
            echo "$repo_path" | sha256sum 2>/dev/null | cut -d' ' -f1 | cut -c1-8
            ;;
        "path"|*)
            # Use sanitized path with safer delimiter to prevent collisions
            # Double underscore reduces collision risk between paths like:
            # /home/user_project vs /home/user/project
            echo "${repo_path//\//__}"
            ;;
    esac
}

# Generate instance-aware cache key with configurable isolation
generate_instance_cache_key() {
    local base_key="$1"
    local isolation_mode="${2:-$CACHE_CONFIG_ISOLATION_MODE}"
    local repo_path="${3:-$PWD}"

    # Validate isolation mode
    case "$isolation_mode" in
        "repository")
            local repo_id
            repo_id=$(get_repo_identifier "$repo_path" "path")
            echo "${base_key}_${repo_id}"
            ;;
        "instance")
            echo "${base_key}_${CACHE_INSTANCE_ID}"
            ;;
        "shared")
            echo "$base_key"
            ;;
        *)
            # Default to repository isolation for safety
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && \
                debug_log "Unknown isolation mode '$isolation_mode', defaulting to repository" "WARN"
            local repo_id
            repo_id=$(get_repo_identifier "$repo_path" "path")
            echo "${base_key}_${repo_id}"
            ;;
    esac
}

# Generate cache key for specific data types with their configured isolation
generate_typed_cache_key() {
    local base_key="$1"
    local data_type="$2"  # mcp, git, cost, session
    local repo_path="${3:-$PWD}"

    local isolation_mode
    case "$data_type" in
        "mcp")
            isolation_mode="$CACHE_CONFIG_MCP_ISOLATION"
            ;;
        "git")
            isolation_mode="$CACHE_CONFIG_GIT_ISOLATION"
            ;;
        "cost")
            isolation_mode="$CACHE_CONFIG_COST_ISOLATION"
            ;;
        "session")
            isolation_mode="$CACHE_CONFIG_SESSION_ISOLATION"
            ;;
        *)
            isolation_mode="$CACHE_CONFIG_ISOLATION_MODE"
            ;;
    esac

    generate_instance_cache_key "$base_key" "$isolation_mode" "$repo_path"
}

# Sanitize cache key to avoid bash arithmetic evaluation issues
# Replaces patterns like "1m", "2k", etc. that bash may try to evaluate as numbers
sanitize_cache_key() {
    local key="$1"
    # Replace all hyphens with double underscores to completely avoid arithmetic parsing issues
    # The hyphen after number+letter patterns seems to confuse bash's parser
    echo "$key" | tr '-' '_'
}

# Export functions
export -f get_repo_identifier generate_instance_cache_key generate_typed_cache_key sanitize_cache_key
