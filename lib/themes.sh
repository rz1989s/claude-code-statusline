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

# Apply theme based on CONFIG_THEME
apply_theme() {
    local theme="${1:-$CONFIG_THEME}"
    
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
    
    # Apply the theme
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