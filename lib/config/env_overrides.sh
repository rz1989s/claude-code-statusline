#!/bin/bash

# ============================================================================
# Claude Code Statusline - Environment Variable Overrides Module
# ============================================================================
#
# This module handles environment variable overrides for configuration.
# Environment variables have highest precedence over TOML config.
#
# Dependencies: core.sh, config/constants.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_ENV_OVERRIDES_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_ENV_OVERRIDES_LOADED=true

# ============================================================================
# ENVIRONMENT VARIABLE OVERRIDE FUNCTIONS
# ============================================================================

# Apply environment variable overrides (highest precedence)
apply_env_overrides() {
    # Environment variables follow the ENV_CONFIG_* naming convention
    # These override both TOML config and inline defaults

    # Theme and feature toggles
    [[ -n "$ENV_CONFIG_THEME" ]] && CONFIG_THEME="$ENV_CONFIG_THEME"
    [[ -n "$ENV_CONFIG_SHOW_COMMITS" ]] && CONFIG_SHOW_COMMITS="$ENV_CONFIG_SHOW_COMMITS"
    [[ -n "$ENV_CONFIG_SHOW_VERSION" ]] && CONFIG_SHOW_VERSION="$ENV_CONFIG_SHOW_VERSION"
    [[ -n "$ENV_CONFIG_SHOW_SUBMODULES" ]] && CONFIG_SHOW_SUBMODULES="$ENV_CONFIG_SHOW_SUBMODULES"
    [[ -n "$ENV_CONFIG_HIDE_SUBMODULES_WHEN_EMPTY" ]] && CONFIG_HIDE_SUBMODULES_WHEN_EMPTY="$ENV_CONFIG_HIDE_SUBMODULES_WHEN_EMPTY"
    [[ -n "$ENV_CONFIG_SHOW_WORKTREE" ]] && CONFIG_SHOW_WORKTREE="$ENV_CONFIG_SHOW_WORKTREE"
    [[ -n "$ENV_CONFIG_SHOW_MCP_STATUS" ]] && CONFIG_SHOW_MCP_STATUS="$ENV_CONFIG_SHOW_MCP_STATUS"
    [[ -n "$ENV_CONFIG_SHOW_COST_TRACKING" ]] && CONFIG_SHOW_COST_TRACKING="$ENV_CONFIG_SHOW_COST_TRACKING"
    [[ -n "$ENV_CONFIG_SHOW_RESET_INFO" ]] && CONFIG_SHOW_RESET_INFO="$ENV_CONFIG_SHOW_RESET_INFO"
    [[ -n "$ENV_CONFIG_SHOW_SESSION_INFO" ]] && CONFIG_SHOW_SESSION_INFO="$ENV_CONFIG_SHOW_SESSION_INFO"

    # Timeouts
    [[ -n "$ENV_CONFIG_MCP_TIMEOUT" ]] && CONFIG_MCP_TIMEOUT="$ENV_CONFIG_MCP_TIMEOUT"
    [[ -n "$ENV_CONFIG_VERSION_TIMEOUT" ]] && CONFIG_VERSION_TIMEOUT="$ENV_CONFIG_VERSION_TIMEOUT"
    [[ -n "$ENV_CONFIG_CCUSAGE_TIMEOUT" ]] && CONFIG_CCUSAGE_TIMEOUT="$ENV_CONFIG_CCUSAGE_TIMEOUT"

    # Modular display configuration (v2.5.0+)
    [[ -n "$ENV_CONFIG_DISPLAY_LINES" ]] && CONFIG_DISPLAY_LINES="$ENV_CONFIG_DISPLAY_LINES"
    # Line components: allow empty strings to clear components (use ${VAR+set} pattern)
    [[ "${ENV_CONFIG_LINE1_COMPONENTS+set}" == "set" ]] && CONFIG_LINE1_COMPONENTS="$ENV_CONFIG_LINE1_COMPONENTS"
    [[ "${ENV_CONFIG_LINE2_COMPONENTS+set}" == "set" ]] && CONFIG_LINE2_COMPONENTS="$ENV_CONFIG_LINE2_COMPONENTS"
    [[ "${ENV_CONFIG_LINE3_COMPONENTS+set}" == "set" ]] && CONFIG_LINE3_COMPONENTS="$ENV_CONFIG_LINE3_COMPONENTS"
    [[ "${ENV_CONFIG_LINE4_COMPONENTS+set}" == "set" ]] && CONFIG_LINE4_COMPONENTS="$ENV_CONFIG_LINE4_COMPONENTS"
    [[ "${ENV_CONFIG_LINE5_COMPONENTS+set}" == "set" ]] && CONFIG_LINE5_COMPONENTS="$ENV_CONFIG_LINE5_COMPONENTS"
    [[ "${ENV_CONFIG_LINE6_COMPONENTS+set}" == "set" ]] && CONFIG_LINE6_COMPONENTS="$ENV_CONFIG_LINE6_COMPONENTS"
    [[ "${ENV_CONFIG_LINE7_COMPONENTS+set}" == "set" ]] && CONFIG_LINE7_COMPONENTS="$ENV_CONFIG_LINE7_COMPONENTS"
    [[ "${ENV_CONFIG_LINE8_COMPONENTS+set}" == "set" ]] && CONFIG_LINE8_COMPONENTS="$ENV_CONFIG_LINE8_COMPONENTS"
    [[ "${ENV_CONFIG_LINE9_COMPONENTS+set}" == "set" ]] && CONFIG_LINE9_COMPONENTS="$ENV_CONFIG_LINE9_COMPONENTS"

    # Log environment overrides if any were applied
    local overrides_applied=false
    local env_vars=(ENV_CONFIG_THEME ENV_CONFIG_SHOW_COMMITS ENV_CONFIG_MCP_TIMEOUT ENV_CONFIG_DISPLAY_LINES ENV_CONFIG_LINE1_COMPONENTS ENV_CONFIG_LINE2_COMPONENTS ENV_CONFIG_LINE3_COMPONENTS)

    for var in "${env_vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            if [[ "$overrides_applied" == "false" ]]; then
                debug_log "Environment variable overrides applied" "INFO"
                overrides_applied=true
            fi
            debug_log "Override: $var=${!var}" "INFO"
        fi
    done
}

# Export function
export -f apply_env_overrides
