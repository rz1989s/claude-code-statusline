#!/bin/bash

# ============================================================================
# Claude Code Statusline - Git Statistics Component
# ============================================================================
# 
# This component handles git statistics display including:
# - Today's commit count
# - Submodule information
#
# Dependencies: git.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_GIT_STATS_COMMITS=""
COMPONENT_GIT_STATS_SUBMODULES=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect git statistics data
collect_git_stats_data() {
    debug_log "Collecting git_stats component data" "INFO"
    
    # Initialize defaults
    COMPONENT_GIT_STATS_COMMITS="0"
    COMPONENT_GIT_STATS_SUBMODULES="${CONFIG_SUBMODULE_LABEL}${CONFIG_NO_SUBMODULES}"
    
    # Get git statistics if git module is loaded and we're in a git repo
    if is_module_loaded "git" && is_git_repository; then
        COMPONENT_GIT_STATS_COMMITS=$(get_commits_today)
        COMPONENT_GIT_STATS_SUBMODULES=$(get_submodule_status)
    fi
    
    debug_log "git_stats data: commits=$COMPONENT_GIT_STATS_COMMITS, submodules=$COMPONENT_GIT_STATS_SUBMODULES" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render git statistics display
render_git_stats() {
    local output=""
    local show_commits show_submodules
    
    show_commits=$(get_git_stats_config "show_commits" "true")
    show_submodules=$(get_git_stats_config "show_submodules" "true") 
    
    # Add commits count if enabled
    if [[ "$show_commits" == "true" ]]; then
        local commits_display="${CONFIG_TEAL}${CONFIG_COMMITS_LABEL}${COMPONENT_GIT_STATS_COMMITS}${CONFIG_RESET}"
        
        if [[ -n "$output" ]]; then
            output="${output} ${commits_display}"
        else
            output="$commits_display"
        fi
    fi
    
    # Add submodule information if enabled
    if [[ "$show_submodules" == "true" ]]; then
        local formatted_submodules
        formatted_submodules=$(format_submodule_display "$COMPONENT_GIT_STATS_SUBMODULES")
        
        if [[ -n "$output" ]]; then
            output="${output} ${formatted_submodules}"
        else
            output="$formatted_submodules"
        fi
    fi
    
    echo "$output"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_git_stats_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "git_stats" "enabled" "${default_value:-true}"
            ;;
        "show_commits")
            get_component_config "git_stats" "show_commits" "${default_value:-true}"
            ;;
        "show_submodules")
            get_component_config "git_stats" "show_submodules" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the git_stats component
register_component \
    "git_stats" \
    "Git statistics (commits, submodules)" \
    "git display" \
    "$(get_git_stats_config 'enabled' 'true')"

debug_log "Git statistics component loaded" "INFO"