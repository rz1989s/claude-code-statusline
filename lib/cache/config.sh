#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Configuration Module
# ============================================================================
#
# This module handles cache configuration loading from TOML and environment
# variables with intelligent defaults.
#
# Error Suppression Patterns (Issue #108):
# - jq 2>/dev/null: JSON parsing with fallback to defaults on invalid config
# - source 2>/dev/null: Config file may not exist (use defaults)
#
# Dependencies: core.sh (for debug_log)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_CONFIG_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_CONFIG_LOADED=true

# ============================================================================
# TOML CONFIGURATION INTEGRATION
# ============================================================================

# Load cache configuration from TOML with intelligent defaults
load_cache_configuration() {
    # Initialize cache configuration variables with defaults
    export CACHE_CONFIG_ENABLE_UNIVERSAL=${ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING:-"true"}
    export CACHE_CONFIG_ENABLE_STATISTICS=${ENV_CONFIG_CACHE_ENABLE_STATISTICS:-"true"}
    export CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION=${ENV_CONFIG_CACHE_ENABLE_CORRUPTION_DETECTION:-"true"}
    export CACHE_CONFIG_CLEANUP_STALE=${ENV_CONFIG_CACHE_CLEANUP_STALE_FILES:-"true"}
    export CACHE_CONFIG_MIGRATE_LEGACY=${ENV_CONFIG_CACHE_MIGRATE_LEGACY_CACHE:-"true"}

    # Performance configuration
    export CACHE_CONFIG_MAX_LOCK_RETRIES=${ENV_CONFIG_CACHE_PERFORMANCE_MAX_LOCK_RETRIES:-10}
    export CACHE_CONFIG_LOCK_RETRY_DELAY=${ENV_CONFIG_CACHE_PERFORMANCE_LOCK_RETRY_DELAY_MS:-"100-500"}
    export CACHE_CONFIG_ATOMIC_TIMEOUT=${ENV_CONFIG_CACHE_PERFORMANCE_ATOMIC_WRITE_TIMEOUT:-10}
    export CACHE_CONFIG_CLEANUP_INTERVAL=${ENV_CONFIG_CACHE_PERFORMANCE_CACHE_CLEANUP_INTERVAL:-300}
    export CACHE_CONFIG_MAX_AGE_HOURS=${ENV_CONFIG_CACHE_PERFORMANCE_MAX_CACHE_AGE_HOURS:-168}

    # Security configuration
    export CACHE_CONFIG_DIR_PERMISSIONS=${ENV_CONFIG_CACHE_SECURITY_DIRECTORY_PERMISSIONS:-"700"}
    export CACHE_CONFIG_FILE_PERMISSIONS=${ENV_CONFIG_CACHE_SECURITY_FILE_PERMISSIONS:-"600"}
    export CACHE_CONFIG_ENABLE_CHECKSUMS=${ENV_CONFIG_CACHE_SECURITY_ENABLE_CHECKSUMS:-"true"}
    export CACHE_CONFIG_VALIDATE_ON_READ=${ENV_CONFIG_CACHE_SECURITY_VALIDATE_ON_READ:-"true"}

    # Instance isolation configuration
    export CACHE_CONFIG_ISOLATION_MODE=${ENV_CONFIG_CACHE_ISOLATION_MODE:-"repository"}
    export CACHE_CONFIG_MCP_ISOLATION=${ENV_CONFIG_CACHE_MCP_ISOLATION:-"repository"}
    export CACHE_CONFIG_GIT_ISOLATION=${ENV_CONFIG_CACHE_GIT_ISOLATION:-"repository"}
    export CACHE_CONFIG_COST_ISOLATION=${ENV_CONFIG_CACHE_COST_ISOLATION:-"shared"}
    export CACHE_CONFIG_SESSION_ISOLATION=${ENV_CONFIG_CACHE_SESSION_ISOLATION:-"repository"}

    # Load TOML configuration if available and no environment overrides
    if [[ "${STATUSLINE_CONFIG_LOADED:-}" == "true" ]] && command -v jq >/dev/null 2>&1; then
        local toml_data="${STATUSLINE_TOML_DATA:-}"

        if [[ -n "$toml_data" ]]; then
            # Parse cache configuration from TOML
            local cache_config
            cache_config=$(echo "$toml_data" | jq -r '.cache // {}' 2>/dev/null)

            if [[ "$cache_config" != "null" && "$cache_config" != "{}" ]]; then
                # Load basic cache settings
                [[ -z "${ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING:-}" ]] && \
                    CACHE_CONFIG_ENABLE_UNIVERSAL=$(echo "$cache_config" | jq -r '.enable_universal_caching // true')
                [[ -z "${ENV_CONFIG_CACHE_ENABLE_STATISTICS:-}" ]] && \
                    CACHE_CONFIG_ENABLE_STATISTICS=$(echo "$cache_config" | jq -r '.enable_statistics // true')
                [[ -z "${ENV_CONFIG_CACHE_ENABLE_CORRUPTION_DETECTION:-}" ]] && \
                    CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION=$(echo "$cache_config" | jq -r '.enable_corruption_detection // true')

                # Load performance settings
                local perf_config
                perf_config=$(echo "$cache_config" | jq -r '.performance // {}' 2>/dev/null)
                if [[ "$perf_config" != "null" && "$perf_config" != "{}" ]]; then
                    [[ -z "${ENV_CONFIG_CACHE_PERFORMANCE_MAX_LOCK_RETRIES:-}" ]] && \
                        CACHE_CONFIG_MAX_LOCK_RETRIES=$(echo "$perf_config" | jq -r '.max_lock_retries // 10')
                    [[ -z "${ENV_CONFIG_CACHE_PERFORMANCE_ATOMIC_WRITE_TIMEOUT:-}" ]] && \
                        CACHE_CONFIG_ATOMIC_TIMEOUT=$(echo "$perf_config" | jq -r '.atomic_write_timeout // 10')
                fi

                # Load security settings
                local sec_config
                sec_config=$(echo "$cache_config" | jq -r '.security // {}' 2>/dev/null)
                if [[ "$sec_config" != "null" && "$sec_config" != "{}" ]]; then
                    [[ -z "${ENV_CONFIG_CACHE_SECURITY_ENABLE_CHECKSUMS:-}" ]] && \
                        CACHE_CONFIG_ENABLE_CHECKSUMS=$(echo "$sec_config" | jq -r '.enable_checksums // true')
                    [[ -z "${ENV_CONFIG_CACHE_SECURITY_VALIDATE_ON_READ:-}" ]] && \
                        CACHE_CONFIG_VALIDATE_ON_READ=$(echo "$sec_config" | jq -r '.validate_on_read // true')
                fi

                # Load isolation settings
                local isolation_config
                isolation_config=$(echo "$cache_config" | jq -r '.isolation // {}' 2>/dev/null)
                if [[ "$isolation_config" != "null" && "$isolation_config" != "{}" ]]; then
                    [[ -z "${ENV_CONFIG_CACHE_ISOLATION_MODE:-}" ]] && \
                        CACHE_CONFIG_ISOLATION_MODE=$(echo "$isolation_config" | jq -r '.mode // "repository"')
                    [[ -z "${ENV_CONFIG_CACHE_MCP_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_MCP_ISOLATION=$(echo "$isolation_config" | jq -r '.mcp // "repository"')
                    [[ -z "${ENV_CONFIG_CACHE_GIT_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_GIT_ISOLATION=$(echo "$isolation_config" | jq -r '.git // "repository"')
                    [[ -z "${ENV_CONFIG_CACHE_COST_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_COST_ISOLATION=$(echo "$isolation_config" | jq -r '.cost // "shared"')
                    [[ -z "${ENV_CONFIG_CACHE_SESSION_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_SESSION_ISOLATION=$(echo "$isolation_config" | jq -r '.session // "repository"')
                fi

                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Loaded cache configuration from TOML" "INFO"
            fi
        fi
    fi

    # Convert string booleans to bash-compatible format
    [[ "$CACHE_CONFIG_ENABLE_UNIVERSAL" == "false" ]] && CACHE_CONFIG_ENABLE_UNIVERSAL=""
    [[ "$CACHE_CONFIG_ENABLE_STATISTICS" == "false" ]] && CACHE_CONFIG_ENABLE_STATISTICS=""
    [[ "$CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION" == "false" ]] && CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION=""
    [[ "$CACHE_CONFIG_ENABLE_CHECKSUMS" == "false" ]] && CACHE_CONFIG_ENABLE_CHECKSUMS=""
    [[ "$CACHE_CONFIG_VALIDATE_ON_READ" == "false" ]] && CACHE_CONFIG_VALIDATE_ON_READ=""

    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache configuration loaded and applied" "INFO"
}

# Export function
export -f load_cache_configuration
