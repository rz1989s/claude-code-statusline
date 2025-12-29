#!/bin/bash

# ============================================================================
# Claude Code Statusline - Context Window Component (Issue #101)
# ============================================================================
#
# This component displays accurate context window percentage by parsing
# the transcript JSONL file, avoiding the bug in native context_window JSON.
#
# Display Format: 🧠 45% (90K/200K) or 🧠 85% ⚠️
#
# Color Thresholds:
#   - Green: 0-50%
#   - Yellow: 50-75%
#   - Red: 75%+ (with warning indicator)
#
# Dependencies: cost.sh (transcript parsing functions)
# Reference: https://codelynx.dev/posts/calculate-claude-code-context
# ============================================================================

# Component data storage
COMPONENT_CONTEXT_PERCENTAGE=""
COMPONENT_CONTEXT_TOKENS=""
COMPONENT_CONTEXT_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect context window data from transcript
collect_context_window_data() {
    debug_log "Collecting context_window component data" "INFO"

    COMPONENT_CONTEXT_PERCENTAGE="0"
    COMPONENT_CONTEXT_TOKENS="0"
    COMPONENT_CONTEXT_DISPLAY="N/A"

    if is_module_loaded "cost"; then
        local transcript_path
        transcript_path=$(get_transcript_path)

        if [[ -n "$transcript_path" ]]; then
            COMPONENT_CONTEXT_TOKENS=$(get_context_tokens_from_transcript)
            COMPONENT_CONTEXT_PERCENTAGE=$(get_context_window_percentage)
            COMPONENT_CONTEXT_DISPLAY=$(get_context_window_display)

            debug_log "context_window data: ${COMPONENT_CONTEXT_PERCENTAGE}% (${COMPONENT_CONTEXT_TOKENS} tokens)" "INFO"
        else
            debug_log "No transcript path available for context window" "INFO"
        fi
    fi

    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render context window display
render_context_window() {
    local theme_enabled="${1:-true}"
    local percentage="$COMPONENT_CONTEXT_PERCENTAGE"
    local display="$COMPONENT_CONTEXT_DISPLAY"

    # Skip if no data available
    if [[ "$display" == "N/A" || -z "$percentage" || "$percentage" == "0" ]]; then
        local show_when_empty="${CONFIG_CONTEXT_SHOW_WHEN_EMPTY:-false}"
        if [[ "$show_when_empty" != "true" ]]; then
            return 1  # No content - skip this component
        fi
    fi

    # Get thresholds from config
    local warn_threshold="${CONFIG_CONTEXT_WARN_THRESHOLD:-75}"
    local critical_threshold="${CONFIG_CONTEXT_CRITICAL_THRESHOLD:-90}"
    local medium_threshold="${CONFIG_CONTEXT_MEDIUM_THRESHOLD:-50}"

    # Apply theme colors if enabled
    local color_code="" reset_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        # Determine color based on percentage
        if [[ "$percentage" -ge "$critical_threshold" ]]; then
            color_code="${CONFIG_RED:-}"
        elif [[ "$percentage" -ge "$warn_threshold" ]]; then
            color_code="${CONFIG_YELLOW:-}"
        elif [[ "$percentage" -ge "$medium_threshold" ]]; then
            color_code="${CONFIG_YELLOW:-}"
        else
            color_code="${CONFIG_GREEN:-}"
        fi
        reset_code="${COLOR_RESET:-}"
    fi

    # Format output with Ctx: prefix
    local label="${CONFIG_CONTEXT_LABEL:-Ctx:}"
    local output="${label} "

    # Show tokens or just percentage based on config
    local show_tokens="${CONFIG_CONTEXT_SHOW_TOKENS:-true}"
    if [[ "$show_tokens" == "true" ]]; then
        output="${output}${color_code}${display}${reset_code}"
    else
        output="${output}${color_code}${percentage}%${reset_code}"
    fi

    echo "$output"
}

# Get context window configuration
get_context_window_config() {
    local key="${1:-component_name}"
    local default="${2:-}"

    case "$key" in
        "component_name"|"name")
            echo "context_window"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_CONTEXT_WINDOW:-${default:-true}}"
            ;;
        "emoji")
            echo "${CONFIG_CONTEXT_EMOJI:-${default:-🧠}}"
            ;;
        "show_tokens")
            echo "${CONFIG_CONTEXT_SHOW_TOKENS:-${default:-true}}"
            ;;
        "warn_threshold")
            echo "${CONFIG_CONTEXT_WARN_THRESHOLD:-${default:-75}}"
            ;;
        "critical_threshold")
            echo "${CONFIG_CONTEXT_CRITICAL_THRESHOLD:-${default:-90}}"
            ;;
        "description")
            echo "Context window usage percentage"
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
CONTEXT_WINDOW_COMPONENT_NAME="context_window"
CONTEXT_WINDOW_COMPONENT_DESCRIPTION="Context window usage percentage"
CONTEXT_WINDOW_COMPONENT_VERSION="2.13.0"
CONTEXT_WINDOW_COMPONENT_DEPENDENCIES=("cost")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the context_window component
register_component \
    "context_window" \
    "Context window usage percentage" \
    "cost" \
    "true"

# Export component functions
export -f collect_context_window_data render_context_window get_context_window_config

debug_log "Context window component loaded" "INFO"
