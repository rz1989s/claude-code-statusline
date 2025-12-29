#!/bin/bash

# ============================================================================
# Claude Code Statusline - Code Productivity Component (Issue #100)
# ============================================================================
#
# This component displays lines added/removed from Anthropic's native
# statusline JSON input. Shows real-time code productivity metrics.
#
# Display Format: +156/-23 (green for added, red for removed)
#
# Dependencies: cost.sh (get_native_lines_added/removed)
# ============================================================================

# Component data storage
COMPONENT_CODE_PRODUCTIVITY_ADDED=""
COMPONENT_CODE_PRODUCTIVITY_REMOVED=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect code productivity data from native JSON input
collect_code_productivity_data() {
    debug_log "Collecting code_productivity component data" "INFO"

    COMPONENT_CODE_PRODUCTIVITY_ADDED="0"
    COMPONENT_CODE_PRODUCTIVITY_REMOVED="0"

    if is_module_loaded "cost"; then
        COMPONENT_CODE_PRODUCTIVITY_ADDED=$(get_native_lines_added)
        COMPONENT_CODE_PRODUCTIVITY_REMOVED=$(get_native_lines_removed)

        # Handle null/empty values
        [[ -z "$COMPONENT_CODE_PRODUCTIVITY_ADDED" || "$COMPONENT_CODE_PRODUCTIVITY_ADDED" == "null" ]] && COMPONENT_CODE_PRODUCTIVITY_ADDED="0"
        [[ -z "$COMPONENT_CODE_PRODUCTIVITY_REMOVED" || "$COMPONENT_CODE_PRODUCTIVITY_REMOVED" == "null" ]] && COMPONENT_CODE_PRODUCTIVITY_REMOVED="0"
    fi

    debug_log "code_productivity data: +$COMPONENT_CODE_PRODUCTIVITY_ADDED/-$COMPONENT_CODE_PRODUCTIVITY_REMOVED" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render code productivity display
render_code_productivity() {
    local theme_enabled="${1:-true}"
    local added="$COMPONENT_CODE_PRODUCTIVITY_ADDED"
    local removed="$COMPONENT_CODE_PRODUCTIVITY_REMOVED"

    # Skip if no changes (configurable)
    local show_zero="${CONFIG_CODE_PRODUCTIVITY_SHOW_ZERO:-false}"
    if [[ "$show_zero" != "true" && "$added" == "0" && "$removed" == "0" ]]; then
        return 1  # No content - skip this component
    fi

    # Apply theme colors if enabled
    local green_code="" red_code="" reset_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        green_code="${CONFIG_GREEN:-}"
        red_code="${CONFIG_RED:-}"
        reset_code="${COLOR_RESET:-}"
    fi

    # Format: Line: +X/-Y with colors
    local label="${CONFIG_CODE_PRODUCTIVITY_LABEL:-Line:}"
    local output="${label} ${green_code}+${added}${reset_code}/${red_code}-${removed}${reset_code}"

    echo "$output"
}

# Get code productivity configuration
get_code_productivity_config() {
    local key="${1:-component_name}"
    local default="${2:-}"

    case "$key" in
        "component_name"|"name")
            echo "code_productivity"
            ;;
        "enabled")
            echo "${CONFIG_FEATURES_SHOW_CODE_PRODUCTIVITY:-${default:-true}}"
            ;;
        "show_zero")
            echo "${CONFIG_CODE_PRODUCTIVITY_SHOW_ZERO:-${default:-false}}"
            ;;
        "emoji")
            echo "${CONFIG_CODE_PRODUCTIVITY_EMOJI:-${default:-}}"
            ;;
        "description")
            echo "Lines added/removed in session"
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
CODE_PRODUCTIVITY_COMPONENT_NAME="code_productivity"
CODE_PRODUCTIVITY_COMPONENT_DESCRIPTION="Lines added/removed in session"
CODE_PRODUCTIVITY_COMPONENT_VERSION="2.13.0"
CODE_PRODUCTIVITY_COMPONENT_DEPENDENCIES=("cost")

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the code_productivity component
register_component \
    "code_productivity" \
    "Lines added/removed in session" \
    "cost" \
    "true"

# Export component functions
export -f collect_code_productivity_data render_code_productivity get_code_productivity_config

debug_log "Code productivity component loaded" "INFO"
