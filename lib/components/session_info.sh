#!/bin/bash

# ============================================================================
# Claude Code Statusline - Session Info Component (Issue #102)
# ============================================================================
#
# This component displays session identification info (short session ID +
# derived project name) from Anthropic's native statusline JSON input.
#
# Display Format: 🔗 abc12345 • project-name
#
# Use Cases:
#   - Resume sessions easily: claude -r abc12345
#   - Identify which project/session is active
#   - Debug correlation with transcript files
#   - Multi-session awareness
#
# Dependencies: cost.sh (session extraction functions)
# ============================================================================

# Component data storage
COMPONENT_SESSION_ID=""
COMPONENT_SESSION_PROJECT=""
COMPONENT_SESSION_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect session info data from native JSON input
collect_session_info_data() {
    debug_log "Collecting session_info component data" "INFO"

    COMPONENT_SESSION_ID=""
    COMPONENT_SESSION_PROJECT=""
    COMPONENT_SESSION_DISPLAY=""

    if is_module_loaded "cost"; then
        local id_length="${CONFIG_SESSION_INFO_ID_LENGTH:-8}"

        COMPONENT_SESSION_ID=$(get_short_session_id "$id_length")
        COMPONENT_SESSION_PROJECT=$(get_native_project_name)
        COMPONENT_SESSION_DISPLAY=$(get_session_info_display)

        debug_log "session_info data: ID=${COMPONENT_SESSION_ID}, Project=${COMPONENT_SESSION_PROJECT}" "INFO"
    fi

    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render session info display
render_session_info() {
    local theme_enabled="${1:-true}"
    local show_id="${CONFIG_SESSION_INFO_SHOW_ID:-true}"
    local show_project="${CONFIG_SESSION_INFO_SHOW_PROJECT:-true}"

    # Skip if nothing to show
    if [[ "$show_id" != "true" && "$show_project" != "true" ]]; then
        return 1
    fi

    # Skip if no data available
    if [[ -z "$COMPONENT_SESSION_ID" && -z "$COMPONENT_SESSION_PROJECT" ]]; then
        local show_when_empty="${CONFIG_SESSION_INFO_SHOW_WHEN_EMPTY:-false}"
        if [[ "$show_when_empty" != "true" ]]; then
            return 1  # No content - skip this component
        fi
    fi

    # Get configuration
    local separator="${CONFIG_SESSION_INFO_SEPARATOR:- • }"
    local emoji_session="${CONFIG_SESSION_INFO_EMOJI_SESSION:-🔗}"
    local emoji_project="${CONFIG_SESSION_INFO_EMOJI_PROJECT:-📁}"

    # Apply theme colors if enabled
    local id_color="" project_color="" reset_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        id_color="${CONFIG_CYAN:-}"
        project_color="${CONFIG_BLUE:-}"
        reset_code="${COLOR_RESET:-}"
    fi

    # Build output using printf for reliable emoji handling
    local output=""
    local parts=()

    # Session ID with emoji
    if [[ "$show_id" == "true" && -n "$COMPONENT_SESSION_ID" ]]; then
        if [[ -n "$emoji_session" ]]; then
            parts+=("${emoji_session} ${id_color}${COMPONENT_SESSION_ID}${reset_code}")
        else
            parts+=("${id_color}${COMPONENT_SESSION_ID}${reset_code}")
        fi
    fi

    # Project name (emoji only if no session ID shown)
    if [[ "$show_project" == "true" && -n "$COMPONENT_SESSION_PROJECT" ]]; then
        if [[ ${#parts[@]} -eq 0 && -n "$emoji_project" ]]; then
            parts+=("${emoji_project} ${project_color}${COMPONENT_SESSION_PROJECT}${reset_code}")
        else
            parts+=("${project_color}${COMPONENT_SESSION_PROJECT}${reset_code}")
        fi
    fi

    # Join parts with separator
    local IFS="$separator"
    output="${parts[*]}"

    printf '%s' "$output"
}

# Get session info configuration
get_session_info_config() {
    local key="${1:-component_name}"
    local default="${2:-}"

    case "$key" in
        "component_name"|"name")
            echo "session_info"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_SESSION_INFO:-${default:-true}}"
            ;;
        "show_id")
            echo "${CONFIG_SESSION_INFO_SHOW_ID:-${default:-true}}"
            ;;
        "show_project")
            echo "${CONFIG_SESSION_INFO_SHOW_PROJECT:-${default:-true}}"
            ;;
        "id_length")
            echo "${CONFIG_SESSION_INFO_ID_LENGTH:-${default:-8}}"
            ;;
        "separator")
            echo "${CONFIG_SESSION_INFO_SEPARATOR:-${default:- • }}"
            ;;
        "emoji_session")
            echo "${CONFIG_SESSION_INFO_EMOJI_SESSION:-${default:-🔗}}"
            ;;
        "emoji_project")
            echo "${CONFIG_SESSION_INFO_EMOJI_PROJECT:-${default:-📁}}"
            ;;
        "description")
            echo "Session ID and project name"
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# ============================================================================
# COMPONENT INTERFACE COMPLIANCE
# ============================================================================

# Component metadata
SESSION_INFO_COMPONENT_NAME="session_info"
SESSION_INFO_COMPONENT_DESCRIPTION="Session ID and project name"
SESSION_INFO_COMPONENT_VERSION="2.13.0"
SESSION_INFO_COMPONENT_DEPENDENCIES=("cost")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the session_info component
register_component \
    "session_info" \
    "Session ID and project name" \
    "cost" \
    "true"

# Export component functions
export -f collect_session_info_data render_session_info get_session_info_config

debug_log "Session info component loaded" "INFO"
