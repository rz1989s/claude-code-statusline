#!/bin/bash

# ============================================================================
# Claude Code Statusline - Profile System Module (Issue #84)
# ============================================================================
#
# This module handles automatic configuration switching based on context:
# - Directory-based detection (glob patterns)
# - Git remote-based detection (substring matching)
# - Time-based switching (work hours)
#
# Dependencies: core.sh, config.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PROFILES_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PROFILES_LOADED=true

# ============================================================================
# PROFILE CONFIGURATION DEFAULTS
# ============================================================================

CONFIG_PROFILES_ENABLED="${CONFIG_PROFILES_ENABLED:-false}"
CONFIG_PROFILES_DEFAULT="${CONFIG_PROFILES_DEFAULT:-personal}"
CONFIG_PROFILES_AUTO_SWITCH="${CONFIG_PROFILES_AUTO_SWITCH:-true}"

# Available profile names (populated during detection)
AVAILABLE_PROFILES=("work" "personal" "demo" "default")

# Current active profile
CURRENT_PROFILE=""

# ============================================================================
# PROFILE DETECTION - DIRECTORY MATCHING
# ============================================================================

# Expand ~ to home directory in path
expand_home_path() {
    local path="$1"
    echo "${path/#\~/$HOME}"
}

# Check if current directory matches a glob pattern
# Supports: *, ?, [abc] style globs
match_directory_pattern() {
    local current_dir="$1"
    local pattern="$2"

    # Expand ~ in pattern
    pattern=$(expand_home_path "$pattern")

    # Use bash's built-in pattern matching
    # shellcheck disable=SC2053
    [[ "$current_dir" == $pattern ]]
}

# Detect profile based on current directory
# Returns: profile name or empty string
detect_profile_by_directory() {
    local current_dir="${1:-$PWD}"

    for profile in "${AVAILABLE_PROFILES[@]}"; do
        # Get directory patterns for this profile
        local patterns_var="CONFIG_PROFILES_${profile^^}_DIRECTORIES"
        local patterns="${!patterns_var:-}"

        if [[ -z "$patterns" ]]; then
            continue
        fi

        # Parse patterns (comma or space separated, or JSON array format)
        # Handle both "dir1,dir2" and ["dir1","dir2"] formats
        patterns=$(echo "$patterns" | tr -d '[]"' | tr ',' ' ')

        for pattern in $patterns; do
            pattern=$(echo "$pattern" | xargs)  # Trim whitespace
            [[ -z "$pattern" ]] && continue

            if match_directory_pattern "$current_dir" "$pattern"; then
                debug_log "Directory match: '$current_dir' matches '$pattern' -> profile '$profile'" "INFO"
                echo "$profile"
                return 0
            fi
        done
    done

    echo ""
    return 1
}

# ============================================================================
# PROFILE DETECTION - GIT REMOTE MATCHING
# ============================================================================

# Get git remote URL for current repository
get_git_remote_url() {
    local remote="${1:-origin}"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo ""
        return 1
    fi

    git remote get-url "$remote" 2>/dev/null || echo ""
}

# Detect profile based on git remote URL
# Returns: profile name or empty string
detect_profile_by_git_remote() {
    local remote_url
    remote_url=$(get_git_remote_url)

    if [[ -z "$remote_url" ]]; then
        debug_log "No git remote found for profile detection" "INFO"
        return 1
    fi

    for profile in "${AVAILABLE_PROFILES[@]}"; do
        # Get git remote patterns for this profile
        local patterns_var="CONFIG_PROFILES_${profile^^}_GIT_REMOTES"
        local patterns="${!patterns_var:-}"

        if [[ -z "$patterns" ]]; then
            continue
        fi

        # Parse patterns
        patterns=$(echo "$patterns" | tr -d '[]"' | tr ',' ' ')

        for pattern in $patterns; do
            pattern=$(echo "$pattern" | xargs)
            [[ -z "$pattern" ]] && continue

            # Substring matching for git remotes
            if [[ "$remote_url" == *"$pattern"* ]]; then
                debug_log "Git remote match: '$remote_url' contains '$pattern' -> profile '$profile'" "INFO"
                echo "$profile"
                return 0
            fi
        done
    done

    echo ""
    return 1
}

# ============================================================================
# PROFILE DETECTION - TIME-BASED
# ============================================================================

# Get current day abbreviation (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
get_current_day_abbrev() {
    date +%a
}

# Check if current time is within a time range
# Args: start_time end_time (HH:MM format)
is_within_time_range() {
    local start_time="$1"
    local end_time="$2"

    # Convert to minutes since midnight for comparison
    local current_mins start_mins end_mins

    local current_hour current_min
    current_hour=$(date +%H | sed 's/^0//')
    current_min=$(date +%M | sed 's/^0//')
    current_mins=$((current_hour * 60 + current_min))

    local start_hour start_min
    start_hour=$(echo "$start_time" | cut -d: -f1 | sed 's/^0//')
    start_min=$(echo "$start_time" | cut -d: -f2 | sed 's/^0//')
    start_mins=$((start_hour * 60 + start_min))

    local end_hour end_min
    end_hour=$(echo "$end_time" | cut -d: -f1 | sed 's/^0//')
    end_min=$(echo "$end_time" | cut -d: -f2 | sed 's/^0//')
    end_mins=$((end_hour * 60 + end_min))

    [[ $current_mins -ge $start_mins && $current_mins -lt $end_mins ]]
}

# Check if current day is in a list of days
# Args: days (comma/space separated: Mon,Tue,Wed or Mon Tue Wed)
is_current_day_in_list() {
    local days="$1"
    local current_day
    current_day=$(get_current_day_abbrev)

    # Parse days list
    days=$(echo "$days" | tr -d '[]"' | tr ',' ' ')

    for day in $days; do
        day=$(echo "$day" | xargs)
        [[ -z "$day" ]] && continue

        if [[ "$current_day" == "$day" ]]; then
            return 0
        fi
    done

    return 1
}

# Detect profile based on time (work hours)
# Returns: profile name or empty string
detect_profile_by_time() {
    for profile in "${AVAILABLE_PROFILES[@]}"; do
        # Get time settings for this profile
        local start_var="CONFIG_PROFILES_${profile^^}_TIME_START"
        local end_var="CONFIG_PROFILES_${profile^^}_TIME_END"
        local days_var="CONFIG_PROFILES_${profile^^}_TIME_DAYS"

        local start_time="${!start_var:-}"
        local end_time="${!end_var:-}"
        local days="${!days_var:-}"

        # Skip if no time configuration
        if [[ -z "$start_time" || -z "$end_time" ]]; then
            continue
        fi

        # Check day restriction if specified
        if [[ -n "$days" ]]; then
            if ! is_current_day_in_list "$days"; then
                debug_log "Time check: Not a matching day for profile '$profile'" "INFO"
                continue
            fi
        fi

        # Check time range
        if is_within_time_range "$start_time" "$end_time"; then
            debug_log "Time match: Current time within $start_time-$end_time -> profile '$profile'" "INFO"
            echo "$profile"
            return 0
        fi
    done

    echo ""
    return 1
}

# ============================================================================
# PROFILE DETECTION - MAIN LOGIC
# ============================================================================

# Detect active profile based on configured priority
# Priority order: git_remote -> directory -> time -> default
detect_active_profile() {
    if [[ "${CONFIG_PROFILES_ENABLED:-false}" != "true" ]]; then
        debug_log "Profiles disabled, using default config" "INFO"
        echo ""
        return 0
    fi

    if [[ "${CONFIG_PROFILES_AUTO_SWITCH:-true}" != "true" ]]; then
        debug_log "Auto-switch disabled, using default profile" "INFO"
        echo "${CONFIG_PROFILES_DEFAULT:-personal}"
        return 0
    fi

    local detected_profile=""

    # Detection priority (configurable, default: git_remote, directory, time)
    local priority="${CONFIG_PROFILES_DETECTION_PRIORITY:-git_remote,directory,time}"
    priority=$(echo "$priority" | tr -d '[]"' | tr ',' ' ')

    for method in $priority; do
        method=$(echo "$method" | xargs)
        [[ -z "$method" ]] && continue

        case "$method" in
            "git_remote"|"git")
                detected_profile=$(detect_profile_by_git_remote)
                ;;
            "directory"|"dir")
                detected_profile=$(detect_profile_by_directory)
                ;;
            "time")
                detected_profile=$(detect_profile_by_time)
                ;;
            *)
                debug_log "Unknown detection method: $method" "WARN"
                ;;
        esac

        if [[ -n "$detected_profile" ]]; then
            debug_log "Profile detected via $method: $detected_profile" "INFO"
            CURRENT_PROFILE="$detected_profile"
            echo "$detected_profile"
            return 0
        fi
    done

    # Fallback to default profile
    detected_profile="${CONFIG_PROFILES_DEFAULT:-personal}"
    debug_log "No profile match, using default: $detected_profile" "INFO"
    CURRENT_PROFILE="$detected_profile"
    echo "$detected_profile"
}

# ============================================================================
# PROFILE APPLICATION
# ============================================================================

# Apply profile settings to configuration
# This overrides current CONFIG_* variables with profile-specific values
apply_profile() {
    local profile="${1:-}"

    if [[ -z "$profile" ]]; then
        profile=$(detect_active_profile)
    fi

    if [[ -z "$profile" ]]; then
        debug_log "No profile to apply" "INFO"
        return 0
    fi

    debug_log "Applying profile: $profile" "INFO"
    CURRENT_PROFILE="$profile"

    # Apply theme if specified
    local theme_var="CONFIG_PROFILES_${profile^^}_THEME"
    local profile_theme="${!theme_var:-}"
    if [[ -n "$profile_theme" ]]; then
        export CONFIG_THEME="$profile_theme"
        debug_log "Profile theme: $profile_theme" "INFO"
    fi

    # Apply show_cost_tracking
    local cost_var="CONFIG_PROFILES_${profile^^}_SHOW_COST_TRACKING"
    local show_cost="${!cost_var:-}"
    if [[ -n "$show_cost" ]]; then
        export CONFIG_SHOW_COST_TRACKING="$show_cost"
    fi

    # Apply show_reset_info
    local reset_var="CONFIG_PROFILES_${profile^^}_SHOW_RESET_INFO"
    local show_reset="${!reset_var:-}"
    if [[ -n "$show_reset" ]]; then
        export CONFIG_SHOW_RESET_INFO="$show_reset"
    fi

    # Apply show_commits
    local commits_var="CONFIG_PROFILES_${profile^^}_SHOW_COMMITS"
    local show_commits="${!commits_var:-}"
    if [[ -n "$show_commits" ]]; then
        export CONFIG_SHOW_COMMITS="$show_commits"
    fi

    # Apply mcp_timeout
    local timeout_var="CONFIG_PROFILES_${profile^^}_MCP_TIMEOUT"
    local mcp_timeout="${!timeout_var:-}"
    if [[ -n "$mcp_timeout" ]]; then
        export CONFIG_MCP_TIMEOUT="$mcp_timeout"
    fi

    debug_log "Profile '$profile' applied successfully" "INFO"
    return 0
}

# ============================================================================
# PROFILE UTILITIES
# ============================================================================

# Get current active profile name
get_current_profile() {
    if [[ -n "$CURRENT_PROFILE" ]]; then
        echo "$CURRENT_PROFILE"
    else
        detect_active_profile
    fi
}

# Check if profiles are enabled
is_profiles_enabled() {
    [[ "${CONFIG_PROFILES_ENABLED:-false}" == "true" ]]
}

# Get list of available profiles
get_available_profiles() {
    echo "${AVAILABLE_PROFILES[*]}"
}

# Force a specific profile (manual override)
set_profile() {
    local profile="$1"

    if [[ -z "$profile" ]]; then
        debug_log "No profile specified for set_profile" "WARN"
        return 1
    fi

    export CURRENT_PROFILE="$profile"
    apply_profile "$profile"
    debug_log "Profile manually set to: $profile" "INFO"
}

# Get profile detection reason (for debugging/display)
get_profile_detection_reason() {
    local profile
    profile=$(get_current_profile)

    if [[ -z "$profile" ]]; then
        echo "disabled"
        return 0
    fi

    # Try each detection method to find which one matched
    local git_match dir_match time_match

    git_match=$(detect_profile_by_git_remote)
    if [[ "$git_match" == "$profile" ]]; then
        echo "git_remote"
        return 0
    fi

    dir_match=$(detect_profile_by_directory)
    if [[ "$dir_match" == "$profile" ]]; then
        echo "directory"
        return 0
    fi

    time_match=$(detect_profile_by_time)
    if [[ "$time_match" == "$profile" ]]; then
        echo "time"
        return 0
    fi

    echo "default"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the profiles module
init_profiles_module() {
    debug_log "Profiles module initialized" "INFO"

    if is_profiles_enabled; then
        debug_log "Profiles enabled, auto-detecting active profile" "INFO"
        apply_profile
    else
        debug_log "Profiles disabled" "INFO"
    fi

    return 0
}

# Initialize the module (skip during testing)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_profiles_module
fi

# Export profile functions
export -f expand_home_path match_directory_pattern detect_profile_by_directory
export -f get_git_remote_url detect_profile_by_git_remote
export -f get_current_day_abbrev is_within_time_range is_current_day_in_list detect_profile_by_time
export -f detect_active_profile apply_profile
export -f get_current_profile is_profiles_enabled get_available_profiles set_profile
export -f get_profile_detection_reason
