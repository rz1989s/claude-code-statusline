#!/bin/bash

# ============================================================================
# Claude Code Statusline - Theme System Module
# ============================================================================
# 
# This module handles theme management, color application, and theme
# inheritance system.
#
# Dependencies: core.sh, config.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_THEMES_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_THEMES_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# THEME DEFINITIONS
# ============================================================================

# Classic theme (traditional ANSI colors)
apply_classic_theme() {
    CONFIG_RED=$(printf '\033[31m')
    CONFIG_BLUE=$(printf '\033[34m')
    CONFIG_GREEN=$(printf '\033[32m')
    CONFIG_YELLOW=$(printf '\033[33m')
    CONFIG_MAGENTA=$(printf '\033[35m')
    CONFIG_CYAN=$(printf '\033[36m')
    CONFIG_WHITE=$(printf '\033[37m')
    CONFIG_ORANGE=$(printf '\033[38;5;208m')
    CONFIG_LIGHT_ORANGE=$(printf '\033[38;5;215m')
    CONFIG_LIGHT_GRAY=$(printf '\033[38;5;248m')
    CONFIG_BRIGHT_GREEN=$(printf '\033[92m')
    CONFIG_PURPLE=$(printf '\033[95m')
    CONFIG_TEAL=$(printf '\033[38;5;73m')
    CONFIG_GOLD=$(printf '\033[38;5;220m')
    CONFIG_PINK_BRIGHT=$(printf '\033[38;5;205m')
    CONFIG_INDIGO=$(printf '\033[38;5;105m')
    CONFIG_VIOLET=$(printf '\033[38;5;99m')
    CONFIG_LIGHT_BLUE=$(printf '\033[38;5;111m')
    CONFIG_DIM=$(printf '\033[2m')
    CONFIG_ITALIC=$(printf '\033[3m')
    CONFIG_STRIKETHROUGH=$(printf '\033[9m')
    CONFIG_RESET=$(printf '\033[0m')
    
    debug_log "Applied classic theme" "INFO"
}

# Garden theme (soft pastel colors)
apply_garden_theme() {
    CONFIG_RED=$(printf '\033[38;2;255;182;193m')          # Light Pink
    CONFIG_BLUE=$(printf '\033[38;2;173;216;230m')         # Powder Blue
    CONFIG_GREEN=$(printf '\033[38;2;176;196;145m')        # Sage Green
    CONFIG_YELLOW=$(printf '\033[38;2;255;218;185m')       # Peach
    CONFIG_MAGENTA=$(printf '\033[38;2;230;230;250m')      # Lavender
    CONFIG_CYAN=$(printf '\033[38;2;175;238;238m')         # Pale Turquoise
    CONFIG_WHITE=$(printf '\033[38;2;245;245;245m')        # Soft White
    CONFIG_ORANGE=$(printf '\033[38;2;255;200;173m')       # Pale Orange
    CONFIG_LIGHT_ORANGE=$(printf '\033[38;2;255;200;173m') # Pale Orange
    CONFIG_LIGHT_GRAY=$(printf '\033[38;2;169;169;169m')   # Light Gray
    CONFIG_BRIGHT_GREEN=$(printf '\033[38;2;189;252;201m') # Mint Green
    CONFIG_PURPLE=$(printf '\033[38;2;230;230;250m')       # Lavender
    CONFIG_TEAL=$(printf '\033[38;2;189;252;201m')         # Mint Green
    CONFIG_GOLD=$(printf '\033[38;2;255;218;185m')         # Peach
    CONFIG_PINK_BRIGHT=$(printf '\033[38;2;255;182;193m')  # Light Pink
    CONFIG_INDIGO=$(printf '\033[38;2;221;160;221m')       # Plum
    CONFIG_VIOLET=$(printf '\033[38;2;230;230;250m')       # Lavender
    CONFIG_LIGHT_BLUE=$(printf '\033[38;2;173;216;230m')   # Powder Blue
    CONFIG_DIM=$(printf '\033[2m')
    CONFIG_ITALIC=$(printf '\033[3m')
    CONFIG_STRIKETHROUGH=$(printf '\033[9m')
    CONFIG_RESET=$(printf '\033[0m')
    
    debug_log "Applied garden theme" "INFO"
}

# Catppuccin theme (official Catppuccin Mocha colors)
apply_catppuccin_theme() {
    CONFIG_RED=$(printf '\033[38;2;243;139;168m')          # #f38ba8
    CONFIG_BLUE=$(printf '\033[38;2;137;180;250m')         # #89b4fa
    CONFIG_GREEN=$(printf '\033[38;2;166;227;161m')        # #a6e3a1
    CONFIG_YELLOW=$(printf '\033[38;2;249;226;175m')       # #f9e2af
    CONFIG_MAGENTA=$(printf '\033[38;2;203;166;247m')      # #cba6f7
    CONFIG_CYAN=$(printf '\033[38;2;137;220;235m')         # #89dceb
    CONFIG_WHITE=$(printf '\033[38;2;205;214;244m')        # #cdd6f4
    CONFIG_ORANGE=$(printf '\033[38;2;250;179;135m')       # #fab387
    CONFIG_LIGHT_ORANGE=$(printf '\033[38;2;250;179;135m') # #fab387
    CONFIG_LIGHT_GRAY=$(printf '\033[38;2;166;173;200m')   # #a6adc8
    CONFIG_BRIGHT_GREEN=$(printf '\033[38;2;166;227;161m') # #a6e3a1
    CONFIG_PURPLE=$(printf '\033[38;2;203;166;247m')       # #cba6f7
    CONFIG_TEAL=$(printf '\033[38;2;148;226;213m')         # #94e2d5
    CONFIG_GOLD=$(printf '\033[38;2;249;226;175m')         # #f9e2af
    CONFIG_PINK_BRIGHT=$(printf '\033[38;2;245;194;231m')  # #f5c2e7
    CONFIG_INDIGO=$(printf '\033[38;2;116;199;236m')       # #74c7ec
    CONFIG_VIOLET=$(printf '\033[38;2;203;166;247m')       # #cba6f7
    CONFIG_LIGHT_BLUE=$(printf '\033[38;2;137;220;235m')   # #89dceb
    CONFIG_DIM=$(printf '\033[2m')
    CONFIG_ITALIC=$(printf '\033[3m')
    CONFIG_STRIKETHROUGH=$(printf '\033[9m')
    CONFIG_RESET=$(printf '\033[0m')
    
    debug_log "Applied catppuccin theme" "INFO"
}

# Ocean theme (deep sea blues and teals)
apply_ocean_theme() {
    CONFIG_RED=$(printf '\033[38;2;255;107;107m')          # #ff6b6b Coral Red
    CONFIG_BLUE=$(printf '\033[38;2;72;202;228m')          # #48cae4 Ocean Blue
    CONFIG_GREEN=$(printf '\033[38;2;76;201;176m')         # #4cc9b0 Sea Green
    CONFIG_YELLOW=$(printf '\033[38;2;255;209;102m')       # #ffd166 Sandy Gold
    CONFIG_MAGENTA=$(printf '\033[38;2;189;147;249m')      # #bd93f9 Sea Lavender
    CONFIG_CYAN=$(printf '\033[38;2;0;180;216m')           # #00b4d8 Bright Cyan
    CONFIG_WHITE=$(printf '\033[38;2;202;220;230m')        # #cadce6 Seafoam White
    CONFIG_ORANGE=$(printf '\033[38;2;255;159;67m')        # #ff9f43 Sunset Orange
    CONFIG_LIGHT_ORANGE=$(printf '\033[38;2;255;183;107m') # #ffb76b Light Coral
    CONFIG_LIGHT_GRAY=$(printf '\033[38;2;144;164;174m')   # #90a4ae Mist Gray
    CONFIG_BRIGHT_GREEN=$(printf '\033[38;2;0;245;212m')   # #00f5d4 Aquamarine
    CONFIG_PURPLE=$(printf '\033[38;2;168;130;214m')       # #a882d6 Deep Purple
    CONFIG_TEAL=$(printf '\033[38;2;0;150;136m')           # #009688 Deep Teal
    CONFIG_GOLD=$(printf '\033[38;2;255;193;7m')           # #ffc107 Treasure Gold
    CONFIG_PINK_BRIGHT=$(printf '\033[38;2;255;138;174m')  # #ff8aae Coral Pink
    CONFIG_INDIGO=$(printf '\033[38;2;67;97;238m')         # #4361ee Deep Indigo
    CONFIG_VIOLET=$(printf '\033[38;2;114;137;218m')       # #7289da Twilight Violet
    CONFIG_LIGHT_BLUE=$(printf '\033[38;2;144;224;239m')   # #90e0ef Light Aqua
    CONFIG_DIM=$(printf '\033[2m')
    CONFIG_ITALIC=$(printf '\033[3m')
    CONFIG_STRIKETHROUGH=$(printf '\033[9m')
    CONFIG_RESET=$(printf '\033[0m')

    debug_log "Applied ocean theme" "INFO"
}

# ============================================================================
# THEME APPLICATION
# ============================================================================

# Apply theme based on CONFIG_THEME (with dynamic theme support)
apply_theme() {
    local theme="${1:-}"

    # If no theme provided, use dynamic theme resolution
    if [[ -z "$theme" ]]; then
        theme=$(get_dynamic_theme)
    fi

    debug_log "Applying theme: $theme" "INFO"
    
    case "$theme" in
    "classic")
        apply_classic_theme
        ;;
    "garden")
        apply_garden_theme
        ;;
    "catppuccin")
        apply_catppuccin_theme
        ;;
    "ocean")
        apply_ocean_theme
        ;;
    "custom")
        debug_log "Custom theme selected - colors should be set by configuration" "INFO"
        # Custom colors are handled by the configuration system
        # Set defaults for any missing custom colors
        apply_custom_theme_defaults
        ;;
    *)
        handle_warning "Unknown theme '$theme', falling back to catppuccin" "apply_theme"
        apply_catppuccin_theme
        ;;
    esac
    
    debug_log "Theme application completed: $theme" "INFO"
}

# Apply defaults for custom theme (in case some colors are not defined)
apply_custom_theme_defaults() {
    # Only set defaults for colors that are empty
    [[ -z "$CONFIG_RED" ]] && CONFIG_RED='\033[31m'
    [[ -z "$CONFIG_BLUE" ]] && CONFIG_BLUE='\033[34m'
    [[ -z "$CONFIG_GREEN" ]] && CONFIG_GREEN='\033[32m'
    [[ -z "$CONFIG_YELLOW" ]] && CONFIG_YELLOW='\033[33m'
    [[ -z "$CONFIG_MAGENTA" ]] && CONFIG_MAGENTA='\033[35m'
    [[ -z "$CONFIG_CYAN" ]] && CONFIG_CYAN='\033[36m'
    [[ -z "$CONFIG_WHITE" ]] && CONFIG_WHITE='\033[37m'
    [[ -z "$CONFIG_ORANGE" ]] && CONFIG_ORANGE='\033[38;5;208m'
    [[ -z "$CONFIG_LIGHT_ORANGE" ]] && CONFIG_LIGHT_ORANGE='\033[38;5;215m'
    [[ -z "$CONFIG_LIGHT_GRAY" ]] && CONFIG_LIGHT_GRAY='\033[38;5;248m'
    [[ -z "$CONFIG_BRIGHT_GREEN" ]] && CONFIG_BRIGHT_GREEN='\033[92m'
    [[ -z "$CONFIG_PURPLE" ]] && CONFIG_PURPLE='\033[95m'
    [[ -z "$CONFIG_TEAL" ]] && CONFIG_TEAL='\033[38;5;73m'
    [[ -z "$CONFIG_GOLD" ]] && CONFIG_GOLD='\033[38;5;220m'
    [[ -z "$CONFIG_PINK_BRIGHT" ]] && CONFIG_PINK_BRIGHT='\033[38;5;205m'
    [[ -z "$CONFIG_INDIGO" ]] && CONFIG_INDIGO='\033[38;5;105m'
    [[ -z "$CONFIG_VIOLET" ]] && CONFIG_VIOLET='\033[38;5;99m'
    [[ -z "$CONFIG_LIGHT_BLUE" ]] && CONFIG_LIGHT_BLUE='\033[38;5;111m'
    [[ -z "$CONFIG_DIM" ]] && CONFIG_DIM='\033[2m'
    [[ -z "$CONFIG_ITALIC" ]] && CONFIG_ITALIC='\033[3m'
    [[ -z "$CONFIG_STRIKETHROUGH" ]] && CONFIG_STRIKETHROUGH='\033[9m'
    [[ -z "$CONFIG_RESET" ]] && CONFIG_RESET='\033[0m'
    
    debug_log "Applied custom theme defaults for missing colors" "INFO"
}

# ============================================================================
# THEME VALIDATION
# ============================================================================

# Validate that all required theme colors are set
validate_theme() {
    local missing_colors=()
    
    # Check all required color variables
    local required_colors=(
        "CONFIG_RED" "CONFIG_BLUE" "CONFIG_GREEN" "CONFIG_YELLOW"
        "CONFIG_MAGENTA" "CONFIG_CYAN" "CONFIG_WHITE" "CONFIG_ORANGE"
        "CONFIG_LIGHT_ORANGE" "CONFIG_LIGHT_GRAY" "CONFIG_BRIGHT_GREEN"
        "CONFIG_PURPLE" "CONFIG_TEAL" "CONFIG_GOLD" "CONFIG_PINK_BRIGHT"
        "CONFIG_INDIGO" "CONFIG_VIOLET" "CONFIG_LIGHT_BLUE"
        "CONFIG_DIM" "CONFIG_ITALIC" "CONFIG_STRIKETHROUGH" "CONFIG_RESET"
    )
    
    for color_var in "${required_colors[@]}"; do
        if [[ -z "${!color_var}" ]]; then
            missing_colors+=("$color_var")
        fi
    done
    
    if [[ ${#missing_colors[@]} -gt 0 ]]; then
        handle_warning "Missing theme colors: ${missing_colors[*]}" "validate_theme"
        return 1
    fi
    
    debug_log "Theme validation passed - all colors defined" "INFO"
    return 0
}

# ============================================================================
# THEME UTILITIES
# ============================================================================

# Get list of available themes
get_available_themes() {
    echo "classic garden catppuccin ocean custom"
}

# Check if a theme is valid
is_valid_theme() {
    local theme="$1"
    local available_themes
    available_themes=$(get_available_themes)
    
    [[ " $available_themes " =~ " $theme " ]]
}

# Get current theme name
get_current_theme() {
    echo "${CONFIG_THEME:-catppuccin}"
}

# Preview theme colors (for testing/debugging)
preview_theme_colors() {
    local theme="${1:-$CONFIG_THEME}"
    
    echo "Theme: $theme"
    echo "=============================================="
    
    # Apply theme temporarily
    local original_theme="$CONFIG_THEME"
    apply_theme "$theme"
    
    # Display color samples
    echo -e "RED:           ${CONFIG_RED}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "BLUE:          ${CONFIG_BLUE}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "GREEN:         ${CONFIG_GREEN}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "YELLOW:        ${CONFIG_YELLOW}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "MAGENTA:       ${CONFIG_MAGENTA}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "CYAN:          ${CONFIG_CYAN}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "WHITE:         ${CONFIG_WHITE}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "ORANGE:        ${CONFIG_ORANGE}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "LIGHT_ORANGE:  ${CONFIG_LIGHT_ORANGE}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "LIGHT_GRAY:    ${CONFIG_LIGHT_GRAY}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "BRIGHT_GREEN:  ${CONFIG_BRIGHT_GREEN}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "PURPLE:        ${CONFIG_PURPLE}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "TEAL:          ${CONFIG_TEAL}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "GOLD:          ${CONFIG_GOLD}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "PINK_BRIGHT:   ${CONFIG_PINK_BRIGHT}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "INDIGO:        ${CONFIG_INDIGO}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "VIOLET:        ${CONFIG_VIOLET}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "LIGHT_BLUE:    ${CONFIG_LIGHT_BLUE}■■■ Sample Text ${CONFIG_RESET}"
    echo ""
    echo -e "FORMATTING:"
    echo -e "DIM:           ${CONFIG_DIM}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "ITALIC:        ${CONFIG_ITALIC}■■■ Sample Text ${CONFIG_RESET}"
    echo -e "STRIKETHROUGH: ${CONFIG_STRIKETHROUGH}■■■ Sample Text ${CONFIG_RESET}"
    
    # Restore original theme
    apply_theme "$original_theme"
}

# ============================================================================
# DYNAMIC THEME SYSTEM (Issue #94)
# ============================================================================

# Configuration variables for dynamic themes
CONFIG_THEME_DYNAMIC_ENABLED="${CONFIG_THEME_DYNAMIC_ENABLED:-false}"
CONFIG_THEME_DYNAMIC_MODE="${CONFIG_THEME_DYNAMIC_MODE:-time}"
CONFIG_THEME_DYNAMIC_DAY_THEME="${CONFIG_THEME_DYNAMIC_DAY_THEME:-garden}"
CONFIG_THEME_DYNAMIC_NIGHT_THEME="${CONFIG_THEME_DYNAMIC_NIGHT_THEME:-catppuccin}"
CONFIG_THEME_DYNAMIC_DAY_START="${CONFIG_THEME_DYNAMIC_DAY_START:-06:00}"
CONFIG_THEME_DYNAMIC_NIGHT_START="${CONFIG_THEME_DYNAMIC_NIGHT_START:-18:00}"
CONFIG_THEME_DYNAMIC_SUNRISE_OFFSET="${CONFIG_THEME_DYNAMIC_SUNRISE_OFFSET:-30}"
CONFIG_THEME_DYNAMIC_SUNSET_OFFSET="${CONFIG_THEME_DYNAMIC_SUNSET_OFFSET:-30}"
CONFIG_THEME_DYNAMIC_PRAYER_DAY_TRIGGER="${CONFIG_THEME_DYNAMIC_PRAYER_DAY_TRIGGER:-fajr}"
CONFIG_THEME_DYNAMIC_PRAYER_NIGHT_TRIGGER="${CONFIG_THEME_DYNAMIC_PRAYER_NIGHT_TRIGGER:-maghrib}"
CONFIG_THEME_DYNAMIC_MANUAL_OVERRIDE="${CONFIG_THEME_DYNAMIC_MANUAL_OVERRIDE:-}"

# Check if dynamic themes are enabled
is_dynamic_theme_enabled() {
    [[ "${CONFIG_THEME_DYNAMIC_ENABLED:-false}" == "true" ]]
}

# Get current time in minutes since midnight
get_minutes_since_midnight() {
    local current_hour current_min
    current_hour=$(date +%H | sed 's/^0//')
    current_min=$(date +%M | sed 's/^0//')
    echo $(( current_hour * 60 + current_min ))
}

# Convert HH:MM time string to minutes since midnight
time_to_minutes() {
    local time_str="$1"
    local hours mins
    hours=$(echo "$time_str" | cut -d: -f1 | sed 's/^0//')
    mins=$(echo "$time_str" | cut -d: -f2 | sed 's/^0//')
    echo $(( hours * 60 + mins ))
}

# Determine if currently daytime based on time-based mode
is_daytime_by_time() {
    local current_mins day_start_mins night_start_mins
    current_mins=$(get_minutes_since_midnight)
    day_start_mins=$(time_to_minutes "$CONFIG_THEME_DYNAMIC_DAY_START")
    night_start_mins=$(time_to_minutes "$CONFIG_THEME_DYNAMIC_NIGHT_START")

    # Handle normal case (day starts before night, e.g., 06:00-18:00)
    if [[ $day_start_mins -lt $night_start_mins ]]; then
        [[ $current_mins -ge $day_start_mins && $current_mins -lt $night_start_mins ]]
    else
        # Handle inverted case (day starts after night, e.g., 18:00-06:00 - unlikely but supported)
        [[ $current_mins -ge $day_start_mins || $current_mins -lt $night_start_mins ]]
    fi
}

# Determine if currently daytime based on sunrise/sunset
# Uses prayer system sunrise/sunset if available
is_daytime_by_sun() {
    local sunrise_mins sunset_mins current_mins
    local sunrise_offset="${CONFIG_THEME_DYNAMIC_SUNRISE_OFFSET:-30}"
    local sunset_offset="${CONFIG_THEME_DYNAMIC_SUNSET_OFFSET:-30}"

    # Try to get sunrise/sunset from prayer cache
    local prayer_cache_file
    prayer_cache_file="${CACHE_BASE_DIR:-$HOME/.cache/claude-code-statusline}/prayer_times_today.json"

    if [[ -f "$prayer_cache_file" ]]; then
        local sunrise sunset
        sunrise=$(jq -r '.data.timings.Sunrise // empty' "$prayer_cache_file" 2>/dev/null)
        sunset=$(jq -r '.data.timings.Sunset // empty' "$prayer_cache_file" 2>/dev/null)

        if [[ -n "$sunrise" && -n "$sunset" ]]; then
            sunrise_mins=$(time_to_minutes "$sunrise")
            sunset_mins=$(time_to_minutes "$sunset")
            current_mins=$(get_minutes_since_midnight)

            # Add offsets
            sunrise_mins=$(( sunrise_mins + sunrise_offset ))
            sunset_mins=$(( sunset_mins + sunset_offset ))

            debug_log "Sun mode: sunrise=$sunrise (+${sunrise_offset}m), sunset=$sunset (+${sunset_offset}m), current=$current_mins" "INFO"

            [[ $current_mins -ge $sunrise_mins && $current_mins -lt $sunset_mins ]]
            return $?
        fi
    fi

    # Fallback to time-based if no sunrise/sunset data
    debug_log "No sunrise/sunset data available, falling back to time-based mode" "WARN"
    is_daytime_by_time
}

# Determine if currently daytime based on prayer times
# Day = after Fajr until Maghrib, Night = after Maghrib until Fajr
is_daytime_by_prayer() {
    local prayer_cache_file current_mins
    local day_trigger="${CONFIG_THEME_DYNAMIC_PRAYER_DAY_TRIGGER:-fajr}"
    local night_trigger="${CONFIG_THEME_DYNAMIC_PRAYER_NIGHT_TRIGGER:-maghrib}"

    prayer_cache_file="${CACHE_BASE_DIR:-$HOME/.cache/claude-code-statusline}/prayer_times_today.json"

    if [[ -f "$prayer_cache_file" ]]; then
        local day_time night_time

        # Get prayer times based on triggers (capitalize first letter)
        local day_prayer night_prayer
        day_prayer="$(echo "${day_trigger:0:1}" | tr '[:lower:]' '[:upper:]')${day_trigger:1}"
        night_prayer="$(echo "${night_trigger:0:1}" | tr '[:lower:]' '[:upper:]')${night_trigger:1}"

        day_time=$(jq -r ".data.timings.$day_prayer // empty" "$prayer_cache_file" 2>/dev/null)
        night_time=$(jq -r ".data.timings.$night_prayer // empty" "$prayer_cache_file" 2>/dev/null)

        if [[ -n "$day_time" && -n "$night_time" ]]; then
            local day_mins night_mins
            day_mins=$(time_to_minutes "$day_time")
            night_mins=$(time_to_minutes "$night_time")
            current_mins=$(get_minutes_since_midnight)

            debug_log "Prayer mode: $day_prayer=$day_time, $night_prayer=$night_time, current=$current_mins" "INFO"

            [[ $current_mins -ge $day_mins && $current_mins -lt $night_mins ]]
            return $?
        fi
    fi

    # Fallback to time-based if no prayer data
    debug_log "No prayer data available, falling back to time-based mode" "WARN"
    is_daytime_by_time
}

# Check if currently daytime based on configured mode
is_daytime() {
    case "${CONFIG_THEME_DYNAMIC_MODE:-time}" in
        "time")
            is_daytime_by_time
            ;;
        "sunrise_sunset"|"sun")
            is_daytime_by_sun
            ;;
        "prayer")
            is_daytime_by_prayer
            ;;
        *)
            debug_log "Unknown dynamic theme mode: $CONFIG_THEME_DYNAMIC_MODE, defaulting to time" "WARN"
            is_daytime_by_time
            ;;
    esac
}

# Get the dynamically resolved theme name
get_dynamic_theme() {
    # Check for manual override first
    if [[ -n "${CONFIG_THEME_DYNAMIC_MANUAL_OVERRIDE:-}" ]]; then
        debug_log "Dynamic theme: using manual override '${CONFIG_THEME_DYNAMIC_MANUAL_OVERRIDE}'" "INFO"
        echo "${CONFIG_THEME_DYNAMIC_MANUAL_OVERRIDE}"
        return 0
    fi

    # Check if dynamic themes are enabled
    if ! is_dynamic_theme_enabled; then
        # Return the static theme
        echo "${CONFIG_THEME:-catppuccin}"
        return 0
    fi

    # Determine day/night and return appropriate theme
    if is_daytime; then
        debug_log "Dynamic theme: daytime, using '${CONFIG_THEME_DYNAMIC_DAY_THEME}'" "INFO"
        echo "${CONFIG_THEME_DYNAMIC_DAY_THEME:-garden}"
    else
        debug_log "Dynamic theme: nighttime, using '${CONFIG_THEME_DYNAMIC_NIGHT_THEME}'" "INFO"
        echo "${CONFIG_THEME_DYNAMIC_NIGHT_THEME:-catppuccin}"
    fi
}

# Get current theme period (day/night) for display purposes
get_current_theme_period() {
    if ! is_dynamic_theme_enabled; then
        echo "static"
        return 0
    fi

    if is_daytime; then
        echo "day"
    else
        echo "night"
    fi
}

# ============================================================================
# THEME INHERITANCE SYSTEM (Advanced)
# ============================================================================

# Apply theme inheritance (from original Phase 3 system)
apply_theme_inheritance() {
    local config_json="$1"

    if [[ -z "$config_json" ]]; then
        debug_log "No config JSON provided for theme inheritance" "INFO"
        return 0
    fi

    # This would be implemented if theme inheritance is needed
    # For now, it's a placeholder for future enhancement
    debug_log "Theme inheritance system ready (not implemented in refactor)" "INFO"
    return 0
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the themes module
init_themes_module() {
    debug_log "Themes module initialized" "INFO"

    # Apply default theme if none is set
    if [[ -z "$CONFIG_THEME" ]]; then
        CONFIG_THEME="catppuccin"
    fi

    # Log dynamic theme status
    if is_dynamic_theme_enabled; then
        local period theme_name
        period=$(get_current_theme_period)
        theme_name=$(get_dynamic_theme)
        debug_log "Dynamic themes enabled: mode=${CONFIG_THEME_DYNAMIC_MODE}, period=${period}, theme=${theme_name}" "INFO"
    fi

    # Apply the theme (uses dynamic resolution if enabled)
    apply_theme

    # Validate the theme
    validate_theme || handle_warning "Theme validation failed" "init_themes_module"

    return 0
}

# Initialize the module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_themes_module
fi

# Export theme functions
export -f apply_theme apply_classic_theme apply_garden_theme apply_catppuccin_theme apply_ocean_theme
export -f apply_custom_theme_defaults validate_theme get_available_themes
export -f is_valid_theme get_current_theme preview_theme_colors apply_theme_inheritance
# Dynamic theme exports
export -f is_dynamic_theme_enabled get_dynamic_theme get_current_theme_period
export -f is_daytime is_daytime_by_time is_daytime_by_sun is_daytime_by_prayer
export -f get_minutes_since_midnight time_to_minutes