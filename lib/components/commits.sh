#!/bin/bash

# ============================================================================
# Claude Code Statusline - Commits Component (Atomic)
# ============================================================================
# 
# This atomic component handles only commit count display.
# Part of the atomic component refactoring to provide granular control.
#
# Dependencies: git.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_COMMITS_COUNT=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect commit count data
collect_commits_data() {
    debug_log "Collecting commits component data" "INFO"
    
    # Initialize default
    COMPONENT_COMMITS_COUNT="0"
    
    # Get commit count if git module is loaded and we're in a git repo
    if is_module_loaded "git" && is_git_repository; then
        COMPONENT_COMMITS_COUNT=$(get_commits_today)
    fi
    
    debug_log "commits data: count=$COMPONENT_COMMITS_COUNT" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render commit count display
render_commits() {
    local show_commits
    show_commits=$(get_commits_config "enabled" "true")
    
    # Return empty if disabled
    if [[ "$show_commits" != "true" ]]; then
        debug_log "Commits component disabled" "INFO"
        return 0
    fi
    
    # Build commits display
    local commits_label="${CONFIG_COMMITS_LABEL}"
    local commits_display="${commits_label}${COMPONENT_COMMITS_COUNT}"
    
    echo "$commits_display"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get commits-specific configuration
get_commits_config() {
    local key="$1"
    local default="$2"
    get_component_config "commits" "$key" "$default"
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the commits component
register_component \
    "commits" \
    "Today's git commit count" \
    "display git" \
    "$(get_commits_config 'enabled' 'true')"

debug_log "Commits component (atomic) loaded successfully" "INFO"