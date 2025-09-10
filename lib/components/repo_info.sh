#!/bin/bash

# ============================================================================
# Claude Code Statusline - Repository Info Component
# ============================================================================
# 
# This component handles repository information display including:
# - Directory path (with ~ notation)  
# - Git branch name
# - Git status (clean/dirty) with emoji indicators
#
# Dependencies: git.sh, display.sh
# ============================================================================

# Component data storage
COMPONENT_REPO_INFO_DIRECTORY=""
COMPONENT_REPO_INFO_BRANCH=""
COMPONENT_REPO_INFO_STATUS=""
COMPONENT_REPO_INFO_MODE=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect repository information data
collect_repo_info_data() {
    debug_log "Collecting repo_info component data" "INFO"
    
    # Get current directory (already set in main script)
    COMPONENT_REPO_INFO_DIRECTORY="${current_dir:-$(pwd)}"
    
    # Get git information if git module is loaded and we're in a git repo
    COMPONENT_REPO_INFO_BRANCH=""
    COMPONENT_REPO_INFO_STATUS="not_git"
    COMPONENT_REPO_INFO_MODE=""
    
    if is_module_loaded "git" && is_git_repository; then
        COMPONENT_REPO_INFO_BRANCH=$(get_git_branch)
        COMPONENT_REPO_INFO_STATUS=$(get_git_status)
        
        # Check for any special modes (like merge, rebase, etc.)
        if [[ -d ".git/rebase-merge" ]] || [[ -d ".git/rebase-apply" ]]; then
            COMPONENT_REPO_INFO_MODE="REBASE"
        elif [[ -f ".git/MERGE_HEAD" ]]; then
            COMPONENT_REPO_INFO_MODE="MERGE"
        elif [[ -f ".git/CHERRY_PICK_HEAD" ]]; then
            COMPONENT_REPO_INFO_MODE="CHERRY"
        fi
    fi
    
    debug_log "repo_info data: dir=$COMPONENT_REPO_INFO_DIRECTORY, branch=$COMPONENT_REPO_INFO_BRANCH, status=$COMPONENT_REPO_INFO_STATUS" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render repository information display
render_repo_info() {
    local output=""
    
    # Add mode info if present (rebase, merge, etc.)
    if [[ -n "$COMPONENT_REPO_INFO_MODE" ]]; then
        output="${CONFIG_RED}[$COMPONENT_REPO_INFO_MODE]${CONFIG_RESET} "
    fi
    
    # Format directory path with ~ notation
    local dir_display
    dir_display=$(format_directory_path "$COMPONENT_REPO_INFO_DIRECTORY")
    output="${output}${CONFIG_BLUE}${dir_display}${CONFIG_RESET}"
    
    # Add git info if available
    if [[ -n "$COMPONENT_REPO_INFO_BRANCH" ]]; then
        local git_info
        git_info=$(format_git_info "$COMPONENT_REPO_INFO_BRANCH" "$COMPONENT_REPO_INFO_STATUS")
        output="${output} ${git_info}"
    fi
    
    echo "$output"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_repo_info_config() {
    local config_key="$1"
    local default_value="$2"
    
    case "$config_key" in
        "enabled")
            get_component_config "repo_info" "enabled" "${default_value:-true}"
            ;;
        "show_mode")
            get_component_config "repo_info" "show_mode" "${default_value:-true}"
            ;;
        "show_git_status")
            get_component_config "repo_info" "show_git_status" "${default_value:-true}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the repo_info component
register_component \
    "repo_info" \
    "Repository directory and git status information" \
    "display git" \
    "$(get_repo_info_config 'enabled' 'true')"

debug_log "Repository info component loaded" "INFO"