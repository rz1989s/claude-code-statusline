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

# Single configuration file location (source of truth)
export CONFIG_FILE_PATHS=(
    "$HOME/.claude/statusline/Config.toml"
)

# Configuration variables are now loaded exclusively from Config.toml
# No hardcoded defaults - single source of truth approach

# Global configuration variables (will be set by load_configuration)
export CONFIG_THEME="catppuccin"  # Default theme for single source architecture
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

# Display line configuration (new modular system)
export CONFIG_DISPLAY_LINES=""
export CONFIG_LINE1_COMPONENTS=""
export CONFIG_LINE2_COMPONENTS=""
export CONFIG_LINE3_COMPONENTS=""
export CONFIG_LINE4_COMPONENTS=""
export CONFIG_LINE5_COMPONENTS=""
export CONFIG_LINE6_COMPONENTS=""
export CONFIG_LINE7_COMPONENTS=""
export CONFIG_LINE8_COMPONENTS=""
export CONFIG_LINE9_COMPONENTS=""
export CONFIG_LINE1_SEPARATOR=""
export CONFIG_LINE2_SEPARATOR=""
export CONFIG_LINE3_SEPARATOR=""
export CONFIG_LINE4_SEPARATOR=""
export CONFIG_LINE5_SEPARATOR=""
export CONFIG_LINE6_SEPARATOR=""
export CONFIG_LINE7_SEPARATOR=""
export CONFIG_LINE8_SEPARATOR=""
export CONFIG_LINE9_SEPARATOR=""
export CONFIG_LINE1_SHOW_WHEN_EMPTY=""
export CONFIG_LINE2_SHOW_WHEN_EMPTY=""
export CONFIG_LINE3_SHOW_WHEN_EMPTY=""
export CONFIG_LINE4_SHOW_WHEN_EMPTY=""
export CONFIG_LINE5_SHOW_WHEN_EMPTY=""
export CONFIG_LINE6_SHOW_WHEN_EMPTY=""
export CONFIG_LINE7_SHOW_WHEN_EMPTY=""
export CONFIG_LINE8_SHOW_WHEN_EMPTY=""
export CONFIG_LINE9_SHOW_WHEN_EMPTY=""

# Display line configuration loaded from Config.toml only

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

        # Detect nested TOML sections and return error (flat format required)
        if [[ "$line" == \[*\] ]]; then
            # Extract section name using sed for better compatibility
            local section_name=$(echo "$line" | sed 's/^[[:space:]]*\[\([^]]*\)\][[:space:]]*$/\1/')
            
            # Return clear error for nested configuration
            handle_error "❌ NESTED TOML FORMAT DETECTED: [$section_name]

Your Config.toml uses nested sections, but this system now requires FLAT format for reliability.

NESTED (old):          FLAT (required):
[theme]                theme.name = \"catppuccin\"
name = \"catppuccin\"     theme.inheritance.enabled = true

[theme.inheritance]
enabled = true

Please convert your Config.toml to flat format using dot notation.
Run: ./statusline.sh --help config  for examples and migration help.

File: $toml_file" 6 "parse_toml_to_json"
            echo "{}"
            return 6 # Nested format detected
        fi

        # Handle key-value pairs using sed for robust extraction (fixes BASH_REMATCH compatibility issues)
        if [[ "$line" =~ = ]]; then
            # Use sed to extract key and value parts
            local key=$(echo "$line" | sed 's/^[[:space:]]*\([^=]*\)[[:space:]]*=.*/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            local value=$(echo "$line" | sed 's/^[[:space:]]*[^=]*=[[:space:]]*\(.*\)/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Skip if key is empty (malformed line)
            if [[ -z "$key" ]]; then
                debug_log "Skipping malformed TOML line: $line" "DEBUG"
                continue
            fi

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

            # Parse value type and format for JSON using sed-based extraction
            if [[ "$value" =~ ^\".*\"$ ]]; then
                # String value (quoted) - extract content between quotes using sed
                local string_val=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
                # Escape quotes and backslashes for JSON (fixed over-escaping)
                string_val=$(echo "$string_val" | sed 's/\\\\/\\\\/g; s/"/\\"/g')
                flat_json="$flat_json\"$flat_key\":\"$string_val\""
            elif [[ "$value" =~ ^\[.*\]$ ]]; then
                # Array value - simplified for now
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^(true|false)$ ]]; then
                # Boolean value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]+$ ]]; then
                # Integer value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]*\.[0-9]+$ ]]; then
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

    # Return the flat JSON directly (no Python nesting needed)
    debug_log "Flat TOML configuration parsed successfully: $toml_file" "INFO"
    echo "$flat_json"
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
    # Hardcoded defaults for single source architecture (v2.8.0 - no DEFAULT_CONFIG_* constants needed)
    CONFIG_THEME="catppuccin"
    CONFIG_SHOW_COMMITS="true"
    CONFIG_SHOW_VERSION="true"
    CONFIG_SHOW_SUBMODULES="true"
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

    # Line configuration defaults removed in v2.8.1 single source architecture
    # All configuration now loaded exclusively from Config.toml via auto-regeneration
    # No hardcoded defaults needed - auto_regenerate_config() ensures Config.toml always exists

    debug_log "Default configuration initialized" "INFO"
}

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
        debug_log "Found config file: $config_file" "INFO"
    else
        # No config file found - attempt auto-regeneration
        debug_log "No configuration file found in search paths" "INFO"
        
        # Check if we should attempt auto-regeneration
        if [[ -n "${CONFIG_PATH:-}" ]] && auto_regenerate_config; then
            # Auto-regeneration successful - try discovery again
            if config_file=$(discover_config_file); then
                debug_log "Auto-regeneration successful, using: $config_file" "INFO"
                
                # Show user-friendly message (not just debug log)
                if [[ "${STATUSLINE_DEBUG:-false}" != "true" ]]; then
                    echo "🔧 Config.toml was missing and has been regenerated from examples" >&2
                    echo "💡 Edit $(basename "$config_file") to customize your statusline" >&2
                fi
            else
                debug_log "Auto-regeneration completed but config still not discoverable" "ERROR"
                return 1
            fi
        else
            debug_log "Auto-regeneration failed or not attempted" "INFO"
            debug_log "No Config.toml found, using inline defaults" "INFO"
            return 1
        fi
    fi

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
}

# Extract configuration values from JSON using optimized jq operation
extract_config_values() {
    local config_json="$1"

    if [[ -z "$config_json" || "$config_json" == "{}" ]]; then
        handle_error "Empty or invalid JSON configuration" 1 "extract_config_values"
        return 1
    fi

    # Pure extraction from Config.toml - no fallbacks (single source of truth)
    local config_data
    config_data=$(echo "$config_json" | jq -r '{
            theme_name: ."theme.name",
            feature_show_commits: ."features.show_commits",
            feature_show_version: ."features.show_version",
            feature_show_submodules: ."features.show_submodules",
            feature_show_mcp: ."features.show_mcp_status",
            feature_show_cost: ."features.show_cost_tracking",
            feature_show_reset: ."features.show_reset_info",
            feature_show_session: ."features.show_session_info",
            timeout_mcp: ."timeouts.mcp",
            timeout_version: ."timeouts.version",
            timeout_ccusage: ."timeouts.ccusage",
            cache_version_duration: ."cache.version_duration",
            cache_version_file: ."cache.version_file",
            display_time_format: ."display.time_format",
            display_date_format: ."display.date_format",
            display_date_format_compact: ."display.date_format_compact",
            label_commits: ."labels.commits",
            label_repo: ."labels.repo",
            label_monthly: ."labels.monthly",
            label_weekly: ."labels.weekly",
            label_daily: ."labels.daily",
            label_submodule: ."labels.submodule",
            label_mcp: ."labels.mcp",
            label_version_prefix: ."labels.version_prefix",
            label_session_prefix: ."labels.session_prefix",
            label_live: ."labels.live",
            label_reset: ."labels.reset",
            display_lines: ."display.lines",
            line1_components: (."display.line1.components" | join(",")),
            line2_components: (."display.line2.components" | join(",")),
            line3_components: (."display.line3.components" | join(",")),
            line4_components: (."display.line4.components" | join(",")),
            line5_components: (."display.line5.components" | join(",")),
            line6_components: (."display.line6.components" | join(",")),
            line7_components: (."display.line7.components" | join(",")),
            line8_components: (."display.line8.components" | join(",")),
            line9_components: (."display.line9.components" | join(",")),
            line1_separator: ."display.line1.separator",
            line2_separator: ."display.line2.separator",
            line3_separator: ."display.line3.separator",
            line4_separator: ."display.line4.separator",
            line5_separator: ."display.line5.separator",
            line6_separator: ."display.line6.separator",
            line7_separator: ."display.line7.separator",
            line8_separator: ."display.line8.separator",
            line9_separator: ."display.line9.separator",
            line1_show_when_empty: ."display.line1.show_when_empty",
            line2_show_when_empty: ."display.line2.show_when_empty",
            line3_show_when_empty: ."display.line3.show_when_empty",
            line4_show_when_empty: ."display.line4.show_when_empty",
            line5_show_when_empty: ."display.line5.show_when_empty",
            line6_show_when_empty: ."display.line6.show_when_empty",
            line7_show_when_empty: ."display.line7.show_when_empty",
            line8_show_when_empty: ."display.line8.show_when_empty",
            line9_show_when_empty: ."display.line9.show_when_empty"
        } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)

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
        label_commits)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_COMMITS_LABEL="$value"
            ;;
        label_repo)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_REPO_LABEL="$value"
            ;;
        label_monthly)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_MONTHLY_LABEL="$value"
            ;;
        label_weekly)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_WEEKLY_LABEL="$value"
            ;;
        label_daily)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DAILY_LABEL="$value"
            ;;
        label_submodule)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_SUBMODULE_LABEL="$value"
            ;;
        label_mcp)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_MCP_LABEL="$value"
            ;;
        label_version_prefix)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_PREFIX="$value"
            ;;
        label_session_prefix)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_SESSION_PREFIX="$value"
            ;;
        label_live)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LIVE_LABEL="$value"
            ;;
        label_reset)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_RESET_LABEL="$value"
            ;;
        display_lines)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DISPLAY_LINES="$value"
            ;;
        line1_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE1_COMPONENTS="$value"
            ;;
        line2_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE2_COMPONENTS="$value"
            ;;
        line3_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE3_COMPONENTS="$value"
            ;;
        line4_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE4_COMPONENTS="$value"
            ;;
        line5_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE5_COMPONENTS="$value"
            ;;
        line6_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE6_COMPONENTS="$value"
            ;;
        line7_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE7_COMPONENTS="$value"
            ;;
        line8_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE8_COMPONENTS="$value"
            ;;
        line9_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE9_COMPONENTS="$value"
            ;;
        line1_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE1_SEPARATOR="$value"
            ;;
        line2_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE2_SEPARATOR="$value"
            ;;
        line3_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE3_SEPARATOR="$value"
            ;;
        line4_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE4_SEPARATOR="$value"
            ;;
        line5_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE5_SEPARATOR="$value"
            ;;
        line6_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE6_SEPARATOR="$value"
            ;;
        line7_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE7_SEPARATOR="$value"
            ;;
        line8_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE8_SEPARATOR="$value"
            ;;
        line9_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE9_SEPARATOR="$value"
            ;;
        line1_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE1_SHOW_WHEN_EMPTY="$value"
            ;;
        line2_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE2_SHOW_WHEN_EMPTY="$value"
            ;;
        line3_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE3_SHOW_WHEN_EMPTY="$value"
            ;;
        line4_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE4_SHOW_WHEN_EMPTY="$value"
            ;;
        line5_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE5_SHOW_WHEN_EMPTY="$value"
            ;;
        line6_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE6_SHOW_WHEN_EMPTY="$value"
            ;;
        line7_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE7_SHOW_WHEN_EMPTY="$value"
            ;;
        line8_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE8_SHOW_WHEN_EMPTY="$value"
            ;;
        line9_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE9_SHOW_WHEN_EMPTY="$value"
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
    
    # Modular display configuration (v2.5.0+)
    [[ -n "$ENV_CONFIG_DISPLAY_LINES" ]] && CONFIG_DISPLAY_LINES="$ENV_CONFIG_DISPLAY_LINES"
    [[ -n "$ENV_CONFIG_LINE1_COMPONENTS" ]] && CONFIG_LINE1_COMPONENTS="$ENV_CONFIG_LINE1_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE2_COMPONENTS" ]] && CONFIG_LINE2_COMPONENTS="$ENV_CONFIG_LINE2_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE3_COMPONENTS" ]] && CONFIG_LINE3_COMPONENTS="$ENV_CONFIG_LINE3_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE4_COMPONENTS" ]] && CONFIG_LINE4_COMPONENTS="$ENV_CONFIG_LINE4_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE5_COMPONENTS" ]] && CONFIG_LINE5_COMPONENTS="$ENV_CONFIG_LINE5_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE6_COMPONENTS" ]] && CONFIG_LINE6_COMPONENTS="$ENV_CONFIG_LINE6_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE7_COMPONENTS" ]] && CONFIG_LINE7_COMPONENTS="$ENV_CONFIG_LINE7_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE8_COMPONENTS" ]] && CONFIG_LINE8_COMPONENTS="$ENV_CONFIG_LINE8_COMPONENTS"
    [[ -n "$ENV_CONFIG_LINE9_COMPONENTS" ]] && CONFIG_LINE9_COMPONENTS="$ENV_CONFIG_LINE9_COMPONENTS"

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
export -f load_toml_configuration extract_config_values apply_env_overrides auto_regenerate_config
export -f load_configuration