#!/bin/bash

# ============================================================================
# Claude Code Statusline - Configuration Module
# ============================================================================
#
# This module handles all configuration loading, TOML parsing, validation,
# and environment variable overrides.
#
# Architecture: Modular design with submodules in lib/config/
#   - constants.sh     : Configuration variable declarations
#   - toml_parser.sh   : TOML to JSON parsing
#   - defaults.sh      : Default values and config discovery
#   - extract.sh       : Value extraction from parsed JSON
#   - env_overrides.sh : Environment variable override handling
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_LOADED=true

# ============================================================================
# SUBMODULE LOADING
# ============================================================================

# Get the directory containing this script
_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration submodules in dependency order
source "${_CONFIG_DIR}/config/constants.sh" || {
    echo "ERROR: Failed to load config/constants.sh" >&2
    return 1
}

source "${_CONFIG_DIR}/config/toml_parser.sh" || {
    echo "ERROR: Failed to load config/toml_parser.sh" >&2
    return 1
}

source "${_CONFIG_DIR}/config/defaults.sh" || {
    echo "ERROR: Failed to load config/defaults.sh" >&2
    return 1
}

source "${_CONFIG_DIR}/config/extract.sh" || {
    echo "ERROR: Failed to load config/extract.sh" >&2
    return 1
}

source "${_CONFIG_DIR}/config/env_overrides.sh" || {
    echo "ERROR: Failed to load config/env_overrides.sh" >&2
    return 1
}

source "${_CONFIG_DIR}/config/schema_validator.sh" || {
    echo "ERROR: Failed to load config/schema_validator.sh" >&2
    return 1
}

# ============================================================================
# TOML CONFIGURATION LOADING
# ============================================================================

# Load configuration from TOML file and set variables
load_toml_configuration() {
    # Check if jq is available for TOML configuration
    if ! command_exists jq; then
        handle_warning "jq not available, configuration features limited" "load_toml_configuration"
        return 1
    fi

    # Discover config file
    local config_file
    config_file=$(discover_config_file)

    if [[ -z "$config_file" ]]; then
        debug_log "No Config.toml found, attempting auto-regeneration..." "INFO"

        # Attempt auto-regeneration
        if auto_regenerate_config; then
            config_file=$(discover_config_file)
            if [[ -z "$config_file" ]]; then
                handle_warning "Auto-regeneration succeeded but config file still not found" "load_toml_configuration"
                return 1
            fi
            debug_log "Config.toml auto-regenerated successfully" "INFO"
        else
            handle_warning "No Config.toml found and auto-regeneration failed" "load_toml_configuration"
            return 1
        fi
    fi

    debug_log "Loading configuration from: $config_file" "INFO"

    # Parse TOML to JSON
    local config_json
    config_json=$(parse_toml_to_json "$config_file")
    local parse_result=$?

    # Handle different error codes from parse_toml_to_json
    case $parse_result in
    0)
        # Success - validate schema and extract configuration values
        # Schema validation runs in non-strict mode (warnings only)
        validate_config_schema "$config_file" "false"

        if extract_config_values "$config_json"; then
            debug_log "Configuration loaded successfully from TOML" "INFO"
            return 0
        else
            handle_warning "Failed to extract configuration values" "load_toml_configuration"
            return 1
        fi
        ;;
    1)
        handle_warning "Configuration file not found: $config_file" "load_toml_configuration"
        return 1
        ;;
    2)
        handle_warning "Invalid configuration file path" "load_toml_configuration"
        return 1
        ;;
    3)
        handle_warning "Configuration file not readable: $config_file" "load_toml_configuration"
        return 1
        ;;
    4)
        handle_warning "Invalid TOML syntax in configuration file" "load_toml_configuration"
        return 1
        ;;
    6)
        # Nested TOML format - error already displayed by parser
        return 1
        ;;
    *)
        handle_warning "Unknown error parsing configuration file, using defaults" "load_toml_configuration"
        return 1
        ;;
    esac
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
    # Skip TOML parsing in test mode for faster execution (6+ seconds saved)
    if [[ "${STATUSLINE_SKIP_TOML:-}" == "true" ]]; then
        debug_log "Skipping TOML loading (test mode)" "INFO"
    else
        load_toml_configuration || debug_log "TOML configuration not loaded, using defaults" "INFO"
    fi

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
    debug_log "Configuration module initialized (modular architecture)" "INFO"
    return 0
}

# Initialize the module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_config_module
fi

# Export configuration functions
export -f load_toml_configuration load_configuration
