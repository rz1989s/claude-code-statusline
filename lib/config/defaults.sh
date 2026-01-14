#!/bin/bash

# ============================================================================
# Claude Code Statusline - Configuration Defaults Module
# ============================================================================
#
# This module handles default configuration initialization, config file
# discovery, and auto-regeneration of Config.toml.
#
# Dependencies: core.sh, config/constants.sh, config/toml_parser.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_DEFAULTS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_DEFAULTS_LOADED=true

# ============================================================================
# CONFIG FILE DISCOVERY
# ============================================================================

# Discover config files in order of precedence
discover_config_file() {
    for config_file in "${CONFIG_FILE_PATHS[@]}"; do
        # Expand tilde in path
        local expanded_path="${config_file/#\~/$HOME}"
        if [[ -f "$expanded_path" && -r "$expanded_path" ]]; then
            echo "$expanded_path"
            return 0
        fi
    done

    # No config file found
    return 1
}

# ============================================================================
# DEFAULT CONFIGURATION INITIALIZATION
# ============================================================================

# Initialize default configuration values
init_default_config() {
    # Hardcoded defaults for single source architecture (v2.8.0 - no DEFAULT_CONFIG_* constants needed)
    CONFIG_THEME="catppuccin"
    CONFIG_SHOW_COMMITS="true"
    CONFIG_SHOW_VERSION="true"
    CONFIG_SHOW_SUBMODULES="true"
    CONFIG_HIDE_SUBMODULES_WHEN_EMPTY="true"
    CONFIG_SHOW_MCP_STATUS="true"
    CONFIG_SHOW_COST_TRACKING="true"
    CONFIG_SHOW_RESET_INFO="true"
    CONFIG_SHOW_SESSION_INFO="true"

    CONFIG_MCP_TIMEOUT="10s"
    CONFIG_VERSION_TIMEOUT="5s"
    CONFIG_CCUSAGE_TIMEOUT="8s"

    CONFIG_VERSION_CACHE_DURATION="15"
    CONFIG_VERSION_CACHE_FILE="claude_version.cache"

    CONFIG_TIME_FORMAT="%H:%M"
    CONFIG_DATE_FORMAT="%Y-%m-%d"
    CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"

    # Emoji defaults
    CONFIG_OPUS_EMOJI="🧠"
    CONFIG_HAIKU_EMOJI="⚡"
    CONFIG_SONNET_EMOJI="🎵"
    CONFIG_DEFAULT_MODEL_EMOJI="🤖"
    CONFIG_CLEAN_STATUS_EMOJI="✅"
    CONFIG_DIRTY_STATUS_EMOJI="📁"
    CONFIG_CLOCK_EMOJI="🕐"
    CONFIG_LIVE_BLOCK_EMOJI="🔥"

    # Label defaults
    CONFIG_COMMITS_LABEL="Commits:"
    CONFIG_REPO_LABEL="REPO"
    CONFIG_MONTHLY_LABEL="30DAY"
    CONFIG_WEEKLY_LABEL="7DAY"
    CONFIG_DAILY_LABEL="DAY"
    CONFIG_SUBMODULE_LABEL="SUB:"
    CONFIG_MCP_LABEL="MCP"
    CONFIG_VERSION_PREFIX="ver"
    CONFIG_CLAUDE_CODE_PREFIX="CC:"
    CONFIG_STATUSLINE_PREFIX="SL:"
    CONFIG_SESSION_PREFIX="S:"
    CONFIG_LIVE_LABEL="LIVE"
    CONFIG_RESET_LABEL="RESET"

    # Message defaults
    CONFIG_NO_CCUSAGE_MESSAGE="No ccusage"
    CONFIG_CCUSAGE_INSTALL_MESSAGE="Install ccusage for cost tracking"
    CONFIG_NO_ACTIVE_BLOCK_MESSAGE="No active block"
    CONFIG_MCP_UNKNOWN_MESSAGE="unknown"
    CONFIG_MCP_NONE_MESSAGE="none"
    CONFIG_UNKNOWN_VERSION="?"
    CONFIG_NO_SUBMODULES="--"

    # Prayer configuration defaults
    CONFIG_PRAYER_ENABLED="true"
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    CONFIG_PRAYER_CALCULATION_METHOD=""
    CONFIG_PRAYER_MADHAB="2"
    CONFIG_PRAYER_TIMEZONE=""

    # Line configuration defaults (for test mode when TOML is skipped)
    # These provide minimal working configuration for tests
    if [[ "${STATUSLINE_SKIP_TOML:-}" == "true" ]]; then
        CONFIG_DISPLAY_LINES="4"
        CONFIG_LINE1_COMPONENTS="repo_info,commits,version_info,time_display"
        CONFIG_LINE2_COMPONENTS="model_info,cost_repo,cost_monthly,cost_weekly,cost_daily,cost_live"
        CONFIG_LINE3_COMPONENTS="mcp_status,reset_timer"
        CONFIG_LINE4_COMPONENTS=""
        CONFIG_LINE5_COMPONENTS=""
        CONFIG_LINE6_COMPONENTS=""
        CONFIG_LINE7_COMPONENTS=""
        CONFIG_LINE8_COMPONENTS=""
        CONFIG_LINE9_COMPONENTS=""
        CONFIG_LINE1_SEPARATOR=" │ "
        CONFIG_LINE2_SEPARATOR=" │ "
        CONFIG_LINE3_SEPARATOR=" │ "
        CONFIG_LINE4_SEPARATOR=" │ "
        CONFIG_LINE5_SEPARATOR=" │ "
        CONFIG_LINE6_SEPARATOR=" │ "
        CONFIG_LINE7_SEPARATOR=" │ "
        CONFIG_LINE8_SEPARATOR=" │ "
        CONFIG_LINE9_SEPARATOR=" │ "
        CONFIG_LINE1_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE2_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE3_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE4_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE5_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE6_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE7_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE8_SHOW_WHEN_EMPTY="false"
        CONFIG_LINE9_SHOW_WHEN_EMPTY="false"
        debug_log "Test mode line configuration defaults applied" "INFO"
    fi

    debug_log "Default configuration initialized" "INFO"
}

# ============================================================================
# CONFIG AUTO-REGENERATION
# ============================================================================

# Auto-regenerate Config.toml from examples directory
auto_regenerate_config() {
    # Check if auto-regeneration is disabled
    if [[ "${CLAUDE_STATUSLINE_NO_AUTO_REGEN:-false}" == "true" ]]; then
        debug_log "Auto-regeneration disabled by environment variable" "INFO"
        return 1
    fi

    # Ensure we have the required paths (should be set in statusline.sh)
    if [[ -z "${CONFIG_PATH:-}" || -z "${EXAMPLES_DIR:-}" ]]; then
        debug_log "Auto-regeneration paths not configured" "ERROR"
        return 1
    fi

    debug_log "Attempting auto-regeneration of Config.toml..." "INFO"

    # Use single comprehensive Config.toml template
    local source_template="$EXAMPLES_DIR/Config.toml"
    local template_description="comprehensive configuration template"

    # Check if the template exists and is readable
    if [[ ! -f "$source_template" || ! -r "$source_template" ]]; then
        debug_log "Master Config.toml template not found at: $source_template" "ERROR"
        return 1
    fi

    debug_log "Using template: $source_template ($template_description)" "INFO"

    # Create backup if partial/corrupted config exists
    if [[ -f "$CONFIG_PATH" ]]; then
        if [[ ! -s "$CONFIG_PATH" ]] || ! parse_toml_to_json "$CONFIG_PATH" >/dev/null 2>&1; then
            local backup_path="${CONFIG_PATH}.corrupted.$(date +%s)"
            if mv "$CONFIG_PATH" "$backup_path" 2>/dev/null; then
                debug_log "Backed up corrupted config to: $backup_path" "INFO"
            fi
        fi
    fi

    # Perform atomic copy operation
    local temp_config
    temp_config=$(mktemp) || {
        debug_log "Failed to create temporary file for config regeneration" "ERROR"
        return 1
    }

    # Copy template to temp file first
    if cp "$source_template" "$temp_config"; then
        # Verify the template is valid TOML
        if parse_toml_to_json "$temp_config" >/dev/null 2>&1; then
            # Atomic move to final location
            if mv "$temp_config" "$CONFIG_PATH"; then
                debug_log "Successfully regenerated Config.toml from $template_description" "INFO"
                return 0
            else
                debug_log "Failed to move regenerated config to final location" "ERROR"
                rm -f "$temp_config" 2>/dev/null
                return 1
            fi
        else
            debug_log "Source template contains invalid TOML syntax" "ERROR"
            rm -f "$temp_config" 2>/dev/null
            return 1
        fi
    else
        debug_log "Failed to copy template during regeneration" "ERROR"
        rm -f "$temp_config" 2>/dev/null
        return 1
    fi
}

# Export functions
export -f discover_config_file init_default_config auto_regenerate_config
