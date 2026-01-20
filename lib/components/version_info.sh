#!/bin/bash

# ============================================================================
# Claude Code Statusline - Version Info Component
# ============================================================================
#
# This component handles Claude Code version display with intelligent caching.
# Includes update checking with 24-hour cache and upgrade indicator.
#
# Dependencies: cache.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_VERSION_INFO_CC_VERSION=""
COMPONENT_VERSION_INFO_SL_VERSION=""
COMPONENT_VERSION_INFO_UPDATE_AVAILABLE=""
COMPONENT_VERSION_INFO_LATEST_VERSION=""

# Update check cache duration (24 hours in seconds)
VERSION_UPDATE_CHECK_CACHE_TTL="${VERSION_UPDATE_CHECK_CACHE_TTL:-86400}"

# ============================================================================
# UPDATE CHECKING FUNCTIONS
# ============================================================================

# Silently check for updates (cached, non-blocking)
# Returns: "true" if update available, "false" otherwise
# Sets: COMPONENT_VERSION_INFO_LATEST_VERSION
check_for_statusline_update() {
    local current_version="${STATUSLINE_VERSION:-0.0.0}"

    # Check if update checking is enabled
    if [[ "$(get_version_info_config 'check_updates' 'true')" != "true" ]]; then
        COMPONENT_VERSION_INFO_UPDATE_AVAILABLE="false"
        return 1
    fi

    # Try to get cached result first
    local cache_key="statusline_update_check"
    local cached_result=""

    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        cached_result=$(get_cached_value "$cache_key" "$VERSION_UPDATE_CHECK_CACHE_TTL" 2>/dev/null)
    fi

    if [[ -n "$cached_result" ]]; then
        # Parse cached result: "latest_version:update_available"
        COMPONENT_VERSION_INFO_LATEST_VERSION="${cached_result%%:*}"
        COMPONENT_VERSION_INFO_UPDATE_AVAILABLE="${cached_result##*:}"
        debug_log "Using cached update check: latest=$COMPONENT_VERSION_INFO_LATEST_VERSION, update=$COMPONENT_VERSION_INFO_UPDATE_AVAILABLE" "INFO"
        return 0
    fi

    # Fetch latest version from GitHub (silent, with timeout)
    local latest_version=""
    if command_exists curl; then
        # Use raw version.txt for speed (no API rate limits)
        latest_version=$(curl -fsSL --connect-timeout 3 --max-time 5 \
            "https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/version.txt" 2>/dev/null | tr -d '\n\r')
    fi

    if [[ -z "$latest_version" ]]; then
        debug_log "Could not fetch latest version" "WARN"
        COMPONENT_VERSION_INFO_UPDATE_AVAILABLE="false"
        return 1
    fi

    COMPONENT_VERSION_INFO_LATEST_VERSION="$latest_version"

    # Compare versions
    if [[ "$current_version" == "$latest_version" ]]; then
        COMPONENT_VERSION_INFO_UPDATE_AVAILABLE="false"
    elif [[ "$(printf '%s\n' "$current_version" "$latest_version" | sort -V | tail -1)" == "$current_version" ]]; then
        # Current is newer (dev version)
        COMPONENT_VERSION_INFO_UPDATE_AVAILABLE="false"
    else
        # Update available
        COMPONENT_VERSION_INFO_UPDATE_AVAILABLE="true"
    fi

    # Cache the result
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        set_cached_value "$cache_key" "${latest_version}:${COMPONENT_VERSION_INFO_UPDATE_AVAILABLE}" 2>/dev/null
    fi

    debug_log "Update check: current=$current_version, latest=$latest_version, update=$COMPONENT_VERSION_INFO_UPDATE_AVAILABLE" "INFO"
    return 0
}

# Run upgrade (called by --upgrade flag)
run_statusline_upgrade() {
    local repo="rz1989s/claude-code-statusline"

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           Claude Code Statusline - Upgrade                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Current version: v${STATUSLINE_VERSION:-unknown}"
    echo ""
    echo "Fetching latest version..."

    # Run the installer
    if curl -sSfL "https://raw.githubusercontent.com/${repo}/main/install.sh" | bash; then
        echo ""
        echo "✓ Upgrade completed successfully!"
        echo ""
        echo "Restart your Claude Code session to use the new version."
        return 0
    else
        echo ""
        echo "✗ Upgrade failed. Please try again or install manually."
        return 1
    fi
}

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect Claude Code and Statusline version information
collect_version_info_data() {
    debug_log "Collecting version_info component data" "INFO"

    # Get Claude Code version
    COMPONENT_VERSION_INFO_CC_VERSION="$CONFIG_UNKNOWN_VERSION"

    if command_exists claude; then
        # Use universal caching system (15-minute cache)
        if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
            local claude_raw
            claude_raw=$(execute_cached_command "external_claude_version" "$CACHE_DURATION_CLAUDE_VERSION" "validate_command_output" "false" "false" claude --version)
            if [[ -n "$claude_raw" ]]; then
                # Extract version number from output
                COMPONENT_VERSION_INFO_CC_VERSION=$(echo "$claude_raw" | head -1 | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
                [[ -z "$COMPONENT_VERSION_INFO_CC_VERSION" ]] && COMPONENT_VERSION_INFO_CC_VERSION="$CONFIG_UNKNOWN_VERSION"
            fi
        else
            # Fallback to direct execution
            if local claude_version_raw=$(claude --version 2>/dev/null | head -1); then
                COMPONENT_VERSION_INFO_CC_VERSION=$(echo "$claude_version_raw" | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
            else
                COMPONENT_VERSION_INFO_CC_VERSION="$CONFIG_UNKNOWN_VERSION"
            fi
        fi
    fi

    # Get Statusline version (already exported from core.sh)
    COMPONENT_VERSION_INFO_SL_VERSION="${STATUSLINE_VERSION:-$CONFIG_UNKNOWN_VERSION}"

    # Check for updates (silent, cached)
    COMPONENT_VERSION_INFO_UPDATE_AVAILABLE="false"
    COMPONENT_VERSION_INFO_LATEST_VERSION=""
    check_for_statusline_update

    debug_log "version_info data: cc=$COMPONENT_VERSION_INFO_CC_VERSION sl=$COMPONENT_VERSION_INFO_SL_VERSION update=$COMPONENT_VERSION_INFO_UPDATE_AVAILABLE" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render version information display (shows both Claude Code and Statusline versions)
render_version_info() {
    local cc_formatted sl_formatted update_indicator=""

    # Format Claude Code version
    cc_formatted=$(format_claude_version "$COMPONENT_VERSION_INFO_CC_VERSION")

    # Format Statusline version
    sl_formatted=$(format_statusline_version "$COMPONENT_VERSION_INFO_SL_VERSION")

    # Add update indicator if update is available (shows target version)
    if [[ "$COMPONENT_VERSION_INFO_UPDATE_AVAILABLE" == "true" ]]; then
        if [[ "$(get_version_info_config 'show_update_indicator' 'true')" == "true" ]]; then
            update_indicator=" (new:${COMPONENT_VERSION_INFO_LATEST_VERSION})"
        fi
    fi

    # Combine both: CC:1.0.27 │ SL:2.11.6 (new:2.16.3)
    echo "${cc_formatted} │ ${sl_formatted}${update_indicator}"
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
        "check_updates")
            get_component_config "version_info" "check_updates" "${default_value:-true}"
            ;;
        "show_update_indicator")
            get_component_config "version_info" "show_update_indicator" "${default_value:-true}"
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
    "Claude Code and Statusline version information" \
    "display cache" \
    "$(get_version_info_config 'enabled' 'true')"

debug_log "Version info component loaded" "INFO"