#!/bin/bash

# ============================================================================
# Claude Code Statusline - Context Window Component (Issue #101)
# ============================================================================
#
# This component displays accurate context window percentage.
#
# Data Sources (priority order):
#   1. Native percentages (Claude Code v2.1.6+): used_percentage, remaining_percentage
#   2. Fallback: Transcript JSONL parsing (pre-v2.1.6 compatibility)
#
# Display Format: 🧠 45% (90K/200K) or 🧠 85% ⚠️
#
# Color Thresholds:
#   - Green: 0-50%
#   - Yellow: 50-75%
#   - Red: 75%+ (with warning indicator)
#
# Dependencies: cost.sh (transcript parsing functions, native percentage extraction)
# Reference: https://codelynx.dev/posts/calculate-claude-code-context
# ============================================================================

# Component data storage
COMPONENT_CONTEXT_PERCENTAGE=""
COMPONENT_CONTEXT_TOKENS=""
COMPONENT_CONTEXT_DISPLAY=""
COMPONENT_CONTEXT_REMAINING=""   # New in v2.15.0: remaining percentage (v2.1.6+)
COMPONENT_CONTEXT_SOURCE=""       # "native" (v2.1.6+) or "transcript" (fallback)

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect context window data - native (v2.1.6+) with transcript fallback
collect_context_window_data() {
    debug_log "Collecting context_window component data" "INFO"

    COMPONENT_CONTEXT_PERCENTAGE="0"
    COMPONENT_CONTEXT_TOKENS="0"
    COMPONENT_CONTEXT_DISPLAY="N/A"
    COMPONENT_CONTEXT_REMAINING=""
    COMPONENT_CONTEXT_SOURCE=""

    if is_module_loaded "cost"; then
        # Method 1: Try native percentages (Claude Code v2.1.6+)
        if has_native_context_percentages 2>/dev/null; then
            COMPONENT_CONTEXT_PERCENTAGE=$(get_native_context_used_percentage)
            COMPONENT_CONTEXT_REMAINING=$(get_native_context_remaining_percentage)
            COMPONENT_CONTEXT_SOURCE="native"

            # Get context window size for display
            local ctx_size
            ctx_size=$(get_native_context_window_size)

            if [[ -n "$COMPONENT_CONTEXT_PERCENTAGE" && "$COMPONENT_CONTEXT_PERCENTAGE" != "0" ]]; then
                # Calculate approximate tokens for display (optional)
                local approx_tokens=$((ctx_size * COMPONENT_CONTEXT_PERCENTAGE / 100))
                COMPONENT_CONTEXT_TOKENS="$approx_tokens"
                COMPONENT_CONTEXT_DISPLAY="${COMPONENT_CONTEXT_PERCENTAGE}%"
            fi

            debug_log "context_window via native v2.1.6+: ${COMPONENT_CONTEXT_PERCENTAGE}% used, ${COMPONENT_CONTEXT_REMAINING}% remaining" "INFO"
        else
            # Method 2: Fall back to transcript parsing (pre-v2.1.6)
            COMPONENT_CONTEXT_SOURCE="transcript"
            local transcript_path
            transcript_path=$(get_transcript_path)

            if [[ -n "$transcript_path" ]]; then
                COMPONENT_CONTEXT_TOKENS=$(get_context_tokens_from_transcript)
                COMPONENT_CONTEXT_PERCENTAGE=$(get_context_window_percentage)
                COMPONENT_CONTEXT_DISPLAY=$(get_context_window_display)

                # Calculate remaining from used
                if [[ -n "$COMPONENT_CONTEXT_PERCENTAGE" && "$COMPONENT_CONTEXT_PERCENTAGE" =~ ^[0-9]+$ ]]; then
                    COMPONENT_CONTEXT_REMAINING=$((100 - COMPONENT_CONTEXT_PERCENTAGE))
                fi

                debug_log "context_window via transcript: ${COMPONENT_CONTEXT_PERCENTAGE}% (${COMPONENT_CONTEXT_TOKENS} tokens)" "INFO"
            else
                debug_log "No transcript path available for context window" "INFO"
            fi
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

    # Show just percentage (compact)
    output="${output}${color_code}${percentage}%${reset_code}"

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
CONTEXT_WINDOW_COMPONENT_DESCRIPTION="Context window usage percentage (native v2.1.6+ or transcript fallback)"
CONTEXT_WINDOW_COMPONENT_VERSION="2.15.0"
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
