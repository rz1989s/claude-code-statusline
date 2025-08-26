#!/bin/bash

# ============================================================================
# Claude Code Statusline - Configuration Module
# ============================================================================
# 
# This module handles all configuration loading, TOML parsing, validation,
# and environment variable overrides.
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# CONFIGURATION CONSTANTS
# ============================================================================

# Configuration file precedence (highest to lowest)
export CONFIG_FILE_PATHS=(
    "./Config.toml"
    "$HOME/.config/claude-code-statusline/Config.toml"
    "$HOME/.claude-statusline.toml"
)

# Default configuration values
export DEFAULT_CONFIG_THEME="catppuccin"
export DEFAULT_CONFIG_SHOW_COMMITS=true
export DEFAULT_CONFIG_SHOW_VERSION=true
export DEFAULT_CONFIG_SHOW_SUBMODULES=true
export DEFAULT_CONFIG_SHOW_MCP_STATUS=true
export DEFAULT_CONFIG_SHOW_COST_TRACKING=true
export DEFAULT_CONFIG_SHOW_RESET_INFO=true
export DEFAULT_CONFIG_SHOW_SESSION_INFO=true

# Global configuration variables (will be set by load_configuration)
export CONFIG_THEME=""
export CONFIG_SHOW_COMMITS=""
export CONFIG_SHOW_VERSION=""
export CONFIG_SHOW_SUBMODULES=""
export CONFIG_SHOW_MCP_STATUS=""
export CONFIG_SHOW_COST_TRACKING=""
export CONFIG_SHOW_RESET_INFO=""
export CONFIG_SHOW_SESSION_INFO=""

export CONFIG_MCP_TIMEOUT=""
export CONFIG_VERSION_TIMEOUT=""
export CONFIG_CCUSAGE_TIMEOUT=""

export CONFIG_VERSION_CACHE_DURATION=""
export CONFIG_VERSION_CACHE_FILE=""

export CONFIG_TIME_FORMAT=""
export CONFIG_DATE_FORMAT=""
export CONFIG_DATE_FORMAT_COMPACT=""

# Color configuration variables (will be set by theme system)
export CONFIG_RED=""
export CONFIG_BLUE=""
export CONFIG_GREEN=""
export CONFIG_YELLOW=""
export CONFIG_MAGENTA=""
export CONFIG_CYAN=""
export CONFIG_WHITE=""
export CONFIG_ORANGE=""
export CONFIG_LIGHT_ORANGE=""
export CONFIG_LIGHT_GRAY=""
export CONFIG_BRIGHT_GREEN=""
export CONFIG_PURPLE=""
export CONFIG_TEAL=""
export CONFIG_GOLD=""
export CONFIG_PINK_BRIGHT=""
export CONFIG_INDIGO=""
export CONFIG_VIOLET=""
export CONFIG_LIGHT_BLUE=""
export CONFIG_DIM=""
export CONFIG_ITALIC=""
export CONFIG_STRIKETHROUGH=""
export CONFIG_RESET=""

# Emoji configuration
export CONFIG_OPUS_EMOJI=""
export CONFIG_HAIKU_EMOJI=""
export CONFIG_SONNET_EMOJI=""
export CONFIG_DEFAULT_MODEL_EMOJI=""
export CONFIG_CLEAN_STATUS_EMOJI=""
export CONFIG_DIRTY_STATUS_EMOJI=""
export CONFIG_CLOCK_EMOJI=""
export CONFIG_LIVE_BLOCK_EMOJI=""

# Label configuration
export CONFIG_COMMITS_LABEL=""
export CONFIG_REPO_LABEL=""
export CONFIG_MONTHLY_LABEL=""
export CONFIG_WEEKLY_LABEL=""
export CONFIG_DAILY_LABEL=""
export CONFIG_SUBMODULE_LABEL=""
export CONFIG_MCP_LABEL=""
export CONFIG_VERSION_PREFIX=""
export CONFIG_SESSION_PREFIX=""
export CONFIG_LIVE_LABEL=""
export CONFIG_RESET_LABEL=""

# Message configuration
export CONFIG_NO_CCUSAGE_MESSAGE=""
export CONFIG_CCUSAGE_INSTALL_MESSAGE=""
export CONFIG_NO_ACTIVE_BLOCK_MESSAGE=""
export CONFIG_MCP_UNKNOWN_MESSAGE=""
export CONFIG_MCP_NONE_MESSAGE=""
export CONFIG_UNKNOWN_VERSION=""
export CONFIG_NO_SUBMODULES=""

# ============================================================================
# TOML PARSING FUNCTIONS
# ============================================================================

# Simple TOML to JSON converter for basic types (strings, booleans, integers)
parse_toml_to_json() {
    local toml_file="$1"

    # Enhanced error handling with proper exit codes
    if [[ -z "$toml_file" ]]; then
        handle_error "No TOML file path provided" 2 "parse_toml_to_json"
        echo "{}"
        return 2 # Invalid arguments
    fi

    if [[ ! -f "$toml_file" ]]; then
        handle_error "TOML configuration file not found: $toml_file" 1 "parse_toml_to_json"
        echo "{}"
        return 1 # File not found
    fi

    if [[ ! -r "$toml_file" ]]; then
        handle_error "TOML configuration file not readable: $toml_file" 3 "parse_toml_to_json"
        echo "{}"
        return 3 # Permission denied
    fi

    # Create temporary flat structure
    local flat_json="{"
    local current_section=""
    local first_item=true

    # Read TOML file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Handle section headers [section] or [section.subsection] or [section.sub.subsub]
        if [[ "$line" =~ ^\\[[[:space:]]*([^]]+)[[:space:]]*\\]$ ]]; then
            local section_name="${BASH_REMATCH[1]}"
            current_section="$section_name"
            continue
        fi

        # Handle key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Clean up key and value
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Create flat key with section prefix
            local flat_key
            if [[ -n "$current_section" ]]; then
                flat_key="${current_section}.${key}"
            else
                flat_key="$key"
            fi

            # Add comma if not first item
            if [[ "$first_item" != "true" ]]; then
                flat_json="$flat_json,"
            fi

            # Parse value type and format for JSON
            if [[ "$value" =~ ^\\\"(.*)\\\"$ ]]; then
                # String value (quoted)
                local string_val="${BASH_REMATCH[1]}"
                # Escape quotes and backslashes for JSON (fixed over-escaping)
                string_val=$(echo "$string_val" | sed 's/\\\\/\\\\/g; s/"/\\"/g')
                flat_json="$flat_json\"$flat_key\":\"$string_val\""
            elif [[ "$value" =~ ^\\[.*\\]$ ]]; then
                # Array value - simplified for now
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^(true|false)$ ]]; then
                # Boolean value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]+$ ]]; then
                # Integer value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]*\\.[0-9]+$ ]]; then
                # Float value
                flat_json="$flat_json\"$flat_key\":$value"
            else
                # Unquoted string - treat as string (fixed over-escaping)
                value=$(echo "$value" | sed 's/\\\\/\\\\/g; s/"/\\"/g')
                flat_json="$flat_json\"$flat_key\":\"$value\""
            fi

            first_item=false
        fi
    done <"$toml_file"

    # Close flat JSON
    flat_json="$flat_json}"

    # Check if jq is available for JSON validation
    if command_exists jq; then
        # Validate flat JSON before processing
        if ! echo "$flat_json" | jq . >/dev/null 2>&1; then
            handle_error "Generated invalid JSON during TOML parsing: $toml_file" 4 "parse_toml_to_json"
            debug_log "Invalid flat JSON: $flat_json" "DEBUG"
            echo "{}"
            return 4 # Parse error
        else
            debug_log "Valid flat JSON generated successfully" "DEBUG"
        fi
    else
        debug_log "jq not available for JSON validation, skipping validation: $toml_file" "WARN"
    fi

    # Convert flat structure to nested using Python (if available) or simple approach
    if command_exists python3; then
        local nested_json
        nested_json=$(python3 -c "
import json
import sys

try:
    flat = json.loads('$flat_json')
    nested = {}
    
    for key, value in flat.items():
        parts = key.split('.')
        current = nested
        
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]
        
        current[parts[-1]] = value
    
    print(json.dumps(nested))
except json.JSONDecodeError as e:
    print(f'ERROR: JSON decode error in TOML parser: {e}', file=sys.stderr)
    print('{}')
except Exception as e:
    print(f'ERROR: Python processing error in TOML parser: {e}', file=sys.stderr)
    print('{}')
" 2>/dev/null)

        # Validate nested JSON output (if jq is available)
        local is_valid_nested=false
        if command_exists jq; then
            if [[ -n "$nested_json" ]] && echo "$nested_json" | jq . >/dev/null 2>&1; then
                is_valid_nested=true
            fi
        else
            # Without jq, use basic validation
            if [[ -n "$nested_json" && "$nested_json" != "{}" ]]; then
                is_valid_nested=true
            fi
        fi

        if [[ "$is_valid_nested" == "true" ]]; then
            echo "$nested_json"
        else
            if [[ "$nested_json" == "{}" ]]; then
                handle_warning "Python TOML processing failed, falling back to flat structure: $toml_file" "parse_toml_to_json"
            else
                handle_warning "Invalid nested JSON generated, falling back to flat structure: $toml_file" "parse_toml_to_json"
                debug_log "Python output: $nested_json" "DEBUG"
            fi
            
            # Validate flat JSON again before returning it (if jq available)
            if command_exists jq && echo "$flat_json" | jq . >/dev/null 2>&1; then
                echo "$flat_json"
            elif [[ ! -f "$(which jq)" ]]; then
                # Without jq, assume flat JSON is valid if non-empty
                echo "$flat_json"
            else
                handle_error "Both nested and flat JSON structures are invalid: $toml_file" 5 "parse_toml_to_json"
                echo "{}"
                return 5 # Critical parse failure
            fi
        fi
    else
        handle_warning "Python3 not available for TOML nesting, using flat structure: $toml_file" "parse_toml_to_json"
        echo "$flat_json"
    fi
}

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
# CONFIGURATION LOADING
# ============================================================================

# Initialize default configuration values
init_default_config() {
    # Set all configuration to defaults
    CONFIG_THEME="$DEFAULT_CONFIG_THEME"
    CONFIG_SHOW_COMMITS="$DEFAULT_CONFIG_SHOW_COMMITS"
    CONFIG_SHOW_VERSION="$DEFAULT_CONFIG_SHOW_VERSION"
    CONFIG_SHOW_SUBMODULES="$DEFAULT_CONFIG_SHOW_SUBMODULES"
    CONFIG_SHOW_MCP_STATUS="$DEFAULT_CONFIG_SHOW_MCP_STATUS"
    CONFIG_SHOW_COST_TRACKING="$DEFAULT_CONFIG_SHOW_COST_TRACKING"
    CONFIG_SHOW_RESET_INFO="$DEFAULT_CONFIG_SHOW_RESET_INFO"
    CONFIG_SHOW_SESSION_INFO="$DEFAULT_CONFIG_SHOW_SESSION_INFO"

    CONFIG_MCP_TIMEOUT="$DEFAULT_MCP_TIMEOUT"
    CONFIG_VERSION_TIMEOUT="$DEFAULT_VERSION_TIMEOUT"
    CONFIG_CCUSAGE_TIMEOUT="$DEFAULT_CCUSAGE_TIMEOUT"

    CONFIG_VERSION_CACHE_DURATION="$DEFAULT_VERSION_CACHE_DURATION"
    CONFIG_VERSION_CACHE_FILE="$DEFAULT_VERSION_CACHE_FILE"

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

    debug_log "Default configuration initialized" "INFO"
}

# Load configuration from TOML file and set variables
load_toml_configuration() {
    # Check if jq is available for TOML configuration
    if ! command_exists jq; then
        handle_warning "jq not available - TOML configuration disabled, using inline configuration" "load_toml_configuration"
        debug_log "Install jq to enable TOML configuration support" "INFO"
        return 0 # Continue with inline configuration
    fi

    local config_file

    # Try to find config file
    if config_file=$(discover_config_file); then
        debug_log "Loading configuration from: $config_file" "INFO"

        # Parse TOML to JSON with comprehensive error handling
        local config_json parse_exit_code
        config_json=$(parse_toml_to_json "$config_file")
        parse_exit_code=$?

        # Handle different types of parsing errors
        case $parse_exit_code in
        0)
            # Success - check for empty result
            if [[ "$config_json" == "{}" ]]; then
                handle_warning "Empty config file, using defaults" "load_toml_configuration"
                return 1
            fi

            # Extract configuration values using optimized single-pass jq operation
            if ! extract_config_values "$config_json"; then
                handle_warning "Failed to extract config values, using defaults" "load_toml_configuration"
                return 1
            fi

            debug_log "Configuration loaded successfully from TOML" "INFO"
            return 0
            ;;
        1)
            handle_warning "Configuration file not found, using defaults" "load_toml_configuration"
            return 1
            ;;
        2)
            handle_warning "Invalid configuration file path, using defaults" "load_toml_configuration"
            return 1
            ;;
        3)
            handle_warning "Configuration file not readable (permissions), using defaults" "load_toml_configuration"
            return 1
            ;;
        *)
            handle_warning "Unknown error parsing configuration file, using defaults" "load_toml_configuration"
            return 1
            ;;
        esac
    else
        debug_log "No Config.toml found, using inline defaults" "INFO"
        return 1
    fi
}

# Extract configuration values from JSON using optimized jq operation
extract_config_values() {
    local config_json="$1"

    if [[ -z "$config_json" || "$config_json" == "{}" ]]; then
        handle_error "Empty or invalid JSON configuration" 1 "extract_config_values"
        return 1
    fi

    # Single jq operation for single-pass config extraction with fallbacks
    local config_data
    config_data=$(echo "$config_json" | jq -r '{
            theme_name: (.theme.name // "catppuccin"),
            feature_show_commits: (.features.show_commits // true),
            feature_show_version: (.features.show_version // true),
            feature_show_submodules: (.features.show_submodules // true),
            feature_show_mcp: (.features.show_mcp_status // true),
            feature_show_cost: (.features.show_cost_tracking // true),
            feature_show_reset: (.features.show_reset_info // true),
            feature_show_session: (.features.show_session_info // true),
            timeout_mcp: (.timeouts.mcp // "10s"),
            timeout_version: (.timeouts.version // "2s"),
            timeout_ccusage: (.timeouts.ccusage // "3s"),
            cache_version_duration: (.cache.version_duration // 3600),
            cache_version_file: (.cache.version_file // "/tmp/.claude_version_cache"),
            display_time_format: (.display.time_format // "%H:%M"),
            display_date_format: (.display.date_format // "%Y-%m-%d"),
            display_date_format_compact: (.display.date_format_compact // "%Y%m%d")
        } | to_entries | map("\\(.key)=\\(.value)") | .[]' 2>/dev/null)

    if [[ -z "$config_data" ]]; then
        handle_warning "Failed to extract config values from JSON" "extract_config_values"
        return 1
    fi

    # Parse the extracted config values and apply them
    while IFS='=' read -r key value; do
        case "$key" in
        theme_name)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_THEME="$value"
            ;;
        feature_show_commits)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_COMMITS="$value"
            ;;
        feature_show_version)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_VERSION="$value"
            ;;
        feature_show_submodules)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_SUBMODULES="$value"
            ;;
        feature_show_mcp)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_MCP_STATUS="$value"
            ;;
        feature_show_cost)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_COST_TRACKING="$value"
            ;;
        feature_show_reset)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_RESET_INFO="$value"
            ;;
        feature_show_session)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_SESSION_INFO="$value"
            ;;
        timeout_mcp)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_MCP_TIMEOUT="$value"
            ;;
        timeout_version)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_TIMEOUT="$value"
            ;;
        timeout_ccusage)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_CCUSAGE_TIMEOUT="$value"
            ;;
        cache_version_duration)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_CACHE_DURATION="$value"
            ;;
        cache_version_file)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_CACHE_FILE="$value"
            ;;
        display_time_format)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_TIME_FORMAT="$value"
            ;;
        display_date_format)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DATE_FORMAT="$value"
            ;;
        display_date_format_compact)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DATE_FORMAT_COMPACT="$value"
            ;;
        esac
    done <<<"$config_data"

    return 0
}

# Apply environment variable overrides (highest precedence)
apply_env_overrides() {
    # Environment variables follow the ENV_CONFIG_* naming convention
    # These override both TOML config and inline defaults

    # Theme and feature toggles
    [[ -n "$ENV_CONFIG_THEME" ]] && CONFIG_THEME="$ENV_CONFIG_THEME"
    [[ -n "$ENV_CONFIG_SHOW_COMMITS" ]] && CONFIG_SHOW_COMMITS="$ENV_CONFIG_SHOW_COMMITS"
    [[ -n "$ENV_CONFIG_SHOW_VERSION" ]] && CONFIG_SHOW_VERSION="$ENV_CONFIG_SHOW_VERSION"
    [[ -n "$ENV_CONFIG_SHOW_SUBMODULES" ]] && CONFIG_SHOW_SUBMODULES="$ENV_CONFIG_SHOW_SUBMODULES"
    [[ -n "$ENV_CONFIG_SHOW_MCP_STATUS" ]] && CONFIG_SHOW_MCP_STATUS="$ENV_CONFIG_SHOW_MCP_STATUS"
    [[ -n "$ENV_CONFIG_SHOW_COST_TRACKING" ]] && CONFIG_SHOW_COST_TRACKING="$ENV_CONFIG_SHOW_COST_TRACKING"
    [[ -n "$ENV_CONFIG_SHOW_RESET_INFO" ]] && CONFIG_SHOW_RESET_INFO="$ENV_CONFIG_SHOW_RESET_INFO"
    [[ -n "$ENV_CONFIG_SHOW_SESSION_INFO" ]] && CONFIG_SHOW_SESSION_INFO="$ENV_CONFIG_SHOW_SESSION_INFO"

    # Timeouts
    [[ -n "$ENV_CONFIG_MCP_TIMEOUT" ]] && CONFIG_MCP_TIMEOUT="$ENV_CONFIG_MCP_TIMEOUT"
    [[ -n "$ENV_CONFIG_VERSION_TIMEOUT" ]] && CONFIG_VERSION_TIMEOUT="$ENV_CONFIG_VERSION_TIMEOUT"
    [[ -n "$ENV_CONFIG_CCUSAGE_TIMEOUT" ]] && CONFIG_CCUSAGE_TIMEOUT="$ENV_CONFIG_CCUSAGE_TIMEOUT"

    # Log environment overrides if any were applied
    local overrides_applied=false
    for var in ENV_CONFIG_THEME ENV_CONFIG_SHOW_COMMITS ENV_CONFIG_MCP_TIMEOUT; do
        if [[ -n "${!var}" ]]; then
            if [[ "$overrides_applied" == "false" ]]; then
                debug_log "Environment variable overrides applied" "INFO"
                overrides_applied=true
            fi
            debug_log "Override: $var=${!var}" "INFO"
        fi
    done
}

# ============================================================================
# MAIN CONFIGURATION LOADING FUNCTION
# ============================================================================

# Main function to load all configuration
load_configuration() {
    debug_log "Loading configuration..." "INFO"
    start_timer "config_load"

    # 1. Initialize defaults
    init_default_config

    # 2. Load TOML configuration (if available)
    load_toml_configuration || debug_log "TOML configuration not loaded, using defaults" "INFO"

    # 3. Apply environment overrides
    apply_env_overrides

    local load_time
    load_time=$(end_timer "config_load")
    debug_log "Configuration loading completed in ${load_time}s" "INFO"

    return 0
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the config module
init_config_module() {
    debug_log "Configuration module initialized" "INFO"
    return 0
}

# Initialize the module
init_config_module

# Export configuration functions
export -f parse_toml_to_json discover_config_file init_default_config
export -f load_toml_configuration extract_config_values apply_env_overrides
export -f load_configuration