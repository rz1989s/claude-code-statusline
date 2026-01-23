#!/bin/bash

# ============================================================================
# Claude Code Statusline - Session Mode Component (Output Style Display)
# ============================================================================
#
# This component displays the current Claude Code session's output style,
# helping users quickly identify how Claude is formatting its responses.
#
# Display Format: Style: default  OR  Style: explanatory  OR  Style: learning
#
# Output Styles:
#   - default: Standard efficient response format
#   - explanatory: Adds educational insights between tasks
#   - learning: Collaborative mode with TODO(human) markers
#   - (custom): User-defined styles from ~/.claude/output-styles/
#
# Data Source: STATUSLINE_INPUT_JSON from Claude Code (output_style.name)
#
# Dependencies: None (reads from native Claude Code JSON input)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_SESSION_MODE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_SESSION_MODE_LOADED=true

# Component data storage
COMPONENT_SESSION_MODE_STYLE=""
COMPONENT_SESSION_MODE_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect session mode data from native Claude Code JSON input
collect_session_mode_data() {
    debug_log "Collecting session_mode component data" "INFO"

    COMPONENT_SESSION_MODE_STYLE=""
    COMPONENT_SESSION_MODE_DISPLAY=""

    # Get output style from native JSON input
    if [[ -n "${STATUSLINE_INPUT_JSON:-}" ]]; then
        COMPONENT_SESSION_MODE_STYLE=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.output_style.name // empty' 2>/dev/null)
    fi

    # Default if not found
    if [[ -z "$COMPONENT_SESSION_MODE_STYLE" || "$COMPONENT_SESSION_MODE_STYLE" == "null" ]]; then
        COMPONENT_SESSION_MODE_STYLE="default"
    fi

    debug_log "session_mode data: style=${COMPONENT_SESSION_MODE_STYLE}" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Get emoji for output style
# Priority: 1) Custom style file frontmatter (emoji: or icon:), 2) Config.toml, 3) Built-in defaults
get_style_emoji() {
    local style="$1"

    # Built-in defaults from config
    local emoji_default="${CONFIG_SESSION_MODE_EMOJI_DEFAULT:-}"
    local emoji_explanatory="${CONFIG_SESSION_MODE_EMOJI_EXPLANATORY:-📚}"
    local emoji_learning="${CONFIG_SESSION_MODE_EMOJI_LEARNING:-🎓}"
    local emoji_custom="${CONFIG_SESSION_MODE_EMOJI_CUSTOM:-✨}"

    # For non-built-in styles, try to read emoji from the style file frontmatter
    case "$style" in
        "default"|"explanatory"|"learning")
            # Use built-in emojis for standard styles
            ;;
        *)
            # Try to find custom emoji from style file
            local style_file=""
            local custom_emoji=""

            # Check user-level output styles first
            if [[ -f "$HOME/.claude/output-styles/${style}.md" ]]; then
                style_file="$HOME/.claude/output-styles/${style}.md"
            # Then check project-level
            elif [[ -f ".claude/output-styles/${style}.md" ]]; then
                style_file=".claude/output-styles/${style}.md"
            fi

            if [[ -n "$style_file" && -f "$style_file" ]]; then
                # Extract emoji from frontmatter (supports: emoji: 🎨 or icon: 🎨)
                custom_emoji=$(sed -n '/^---$/,/^---$/p' "$style_file" 2>/dev/null | \
                    grep -E '^(emoji|icon):' | \
                    head -1 | \
                    sed 's/^[^:]*:[[:space:]]*//' | \
                    tr -d '"'"'" 2>/dev/null)

                if [[ -n "$custom_emoji" ]]; then
                    echo "$custom_emoji"
                    return 0
                fi
            fi
            ;;
    esac

    # Fall back to built-in/config emojis
    case "$style" in
        "default")
            echo "$emoji_default"
            ;;
        "explanatory")
            echo "$emoji_explanatory"
            ;;
        "learning")
            echo "$emoji_learning"
            ;;
        *)
            echo "$emoji_custom"
            ;;
    esac
}

# Render session mode display
render_session_mode() {
    local theme_enabled="${1:-true}"

    # Skip if no style data
    if [[ -z "$COMPONENT_SESSION_MODE_STYLE" ]]; then
        local show_when_empty="${CONFIG_SESSION_MODE_SHOW_WHEN_EMPTY:-false}"
        if [[ "$show_when_empty" != "true" ]]; then
            return 1
        fi
    fi

    # Get configuration
    local label="${CONFIG_SESSION_MODE_LABEL:-Style:}"
    local show_emoji="${CONFIG_SESSION_MODE_SHOW_EMOJI:-true}"
    local hide_default="${CONFIG_SESSION_MODE_HIDE_DEFAULT:-false}"

    # Optionally hide when style is "default" to reduce clutter
    if [[ "$hide_default" == "true" && "$COMPONENT_SESSION_MODE_STYLE" == "default" ]]; then
        return 1
    fi

    # Apply theme colors if enabled
    local style_color="" reset_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        # Color based on style
        case "$COMPONENT_SESSION_MODE_STYLE" in
            "explanatory")
                style_color="${CONFIG_CYAN:-}"
                ;;
            "learning")
                style_color="${CONFIG_PURPLE:-${CONFIG_MAGENTA:-}}"
                ;;
            "default")
                style_color="${CONFIG_GREEN:-}"
                ;;
            *)
                # Custom style
                style_color="${CONFIG_GOLD:-${CONFIG_YELLOW:-}}"
                ;;
        esac
        reset_code="${COLOR_RESET:-}"
    fi

    # Build output
    local output=""

    # Add emoji if enabled
    if [[ "$show_emoji" == "true" ]]; then
        local emoji
        emoji=$(get_style_emoji "$COMPONENT_SESSION_MODE_STYLE")
        if [[ -n "$emoji" ]]; then
            output="${emoji} "
        fi
    fi

    # Add label and style
    if [[ -n "$label" ]]; then
        output="${output}${label} "
    fi
    output="${output}${style_color}${COMPONENT_SESSION_MODE_STYLE}${reset_code}"

    printf '%s' "$output"
}

# Get session mode configuration
get_session_mode_config() {
    local key="${1:-component_name}"
    local default="${2:-}"

    case "$key" in
        "component_name"|"name")
            echo "session_mode"
            ;;
        "enabled")
            echo "${CONFIG_COMPONENTS_SESSION_MODE_ENABLED:-${default:-true}}"
            ;;
        "label")
            echo "${CONFIG_SESSION_MODE_LABEL:-${default:-Style:}}"
            ;;
        "show_emoji")
            echo "${CONFIG_SESSION_MODE_SHOW_EMOJI:-${default:-true}}"
            ;;
        "hide_default")
            echo "${CONFIG_SESSION_MODE_HIDE_DEFAULT:-${default:-false}}"
            ;;
        "description")
            echo "Output style (default, explanatory, learning)"
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
SESSION_MODE_COMPONENT_NAME="session_mode"
SESSION_MODE_COMPONENT_DESCRIPTION="Output style (default, explanatory, learning)"
SESSION_MODE_COMPONENT_VERSION="1.0.0"
SESSION_MODE_COMPONENT_DEPENDENCIES=()

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the session_mode component
register_component \
    "session_mode" \
    "Output style (default, explanatory, learning)" \
    "" \
    "true"

# Export component functions
export -f collect_session_mode_data render_session_mode get_session_mode_config get_style_emoji

debug_log "Session mode component loaded" "INFO"
