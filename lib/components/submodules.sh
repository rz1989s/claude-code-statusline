#!/bin/bash

# ============================================================================
# Claude Code Statusline - Submodules Component (Atomic)
# ============================================================================
# 
# This atomic component handles only submodule status display.
# Part of the atomic component refactoring to provide granular control.
#
# Dependencies: git.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_SUBMODULES_STATUS=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect submodule status data
collect_submodules_data() {
    debug_log "Collecting submodules component data" "INFO"
    
    # Initialize default
    COMPONENT_SUBMODULES_STATUS="${CONFIG_SUBMODULE_LABEL}${CONFIG_NO_SUBMODULES}"
    
    # Get submodule status if git module is loaded and we're in a git repo
    if is_module_loaded "git" && is_git_repository; then
        COMPONENT_SUBMODULES_STATUS=$(get_submodule_status)
    fi
    
    debug_log "submodules data: status=$COMPONENT_SUBMODULES_STATUS" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render submodule status display
render_submodules() {
    local show_submodules
    show_submodules=$(get_submodules_config "enabled" "true")

    # Return empty if disabled
    if [[ "$show_submodules" != "true" ]]; then
        debug_log "Submodules component disabled" "INFO"
        return 0
    fi

    # Hide when no submodules (shows "--" or empty count)
    local hide_when_empty
    hide_when_empty="${CONFIG_HIDE_SUBMODULES_WHEN_EMPTY:-true}"
    if [[ "$hide_when_empty" == "true" ]]; then
        # Check if status contains "--" (no submodules indicator)
        if [[ "$COMPONENT_SUBMODULES_STATUS" == *"${CONFIG_NO_SUBMODULES}"* ]]; then
            debug_log "Submodules hidden (no submodules present)" "INFO"
            return 0
        fi
    fi

    # Display submodule status
    echo "$COMPONENT_SUBMODULES_STATUS"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get submodules-specific configuration
get_submodules_config() {
    local key="$1"
    local default="$2"
    get_component_config "submodules" "$key" "$default"
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the submodules component
register_component \
    "submodules" \
    "Git submodules status information" \
    "display git" \
    "$(get_submodules_config 'enabled' 'true')"

debug_log "Submodules component (atomic) loaded successfully" "INFO"