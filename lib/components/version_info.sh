#!/bin/bash

# ============================================================================
# Claude Code Statusline - Version Info Component  
# ============================================================================
# 
# This component handles Claude Code version display with intelligent caching.
#
# Dependencies: cache.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_VERSION_INFO_VERSION=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect Claude version information
collect_version_info_data() {
    debug_log "Collecting version_info component data" "INFO"
    
    COMPONENT_VERSION_INFO_VERSION="$CONFIG_UNKNOWN_VERSION"
    
    if command_exists claude; then
        # Use universal caching system (15-minute cache)
        if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
            local claude_raw
            claude_raw=$(execute_cached_command "external_claude_version" "$CACHE_DURATION_CLAUDE_VERSION" "validate_command_output" "false" "false" claude --version)
            if [[ -n "$claude_raw" ]]; then
                # Extract version number from output
                COMPONENT_VERSION_INFO_VERSION=$(echo "$claude_raw" | head -1 | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
                [[ -z "$COMPONENT_VERSION_INFO_VERSION" ]] && COMPONENT_VERSION_INFO_VERSION="$CONFIG_UNKNOWN_VERSION"
            fi
        else
            # Fallback to direct execution
            if local claude_version_raw=$(claude --version 2>/dev/null | head -1); then
                COMPONENT_VERSION_INFO_VERSION=$(echo "$claude_version_raw" | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
            else
                COMPONENT_VERSION_INFO_VERSION="$CONFIG_UNKNOWN_VERSION"
            fi
        fi
    fi
    
    debug_log "version_info data: version=$COMPONENT_VERSION_INFO_VERSION" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render version information display
render_version_info() {
    local formatted_version
    formatted_version=$(format_claude_version "$COMPONENT_VERSION_INFO_VERSION")
    echo "$formatted_version"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_version_info_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "version_info" "enabled" "${default_value:-true}"
            ;;
        "show_prefix")
            get_component_config "version_info" "show_prefix" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the version_info component
register_component \
    "version_info" \
    "Claude Code version information" \
    "display cache" \
    "$(get_version_info_config 'enabled' 'true')"

debug_log "Version info component loaded" "INFO"