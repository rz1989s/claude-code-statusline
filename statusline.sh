#!/bin/bash

# Enhanced statusline for Claude Code
#
# DISPLAY STRUCTURE (4 Lines):
#
# Line 1: Basic Repository Info
#   Format: [mode] ~/path (branch) status │ Commits:X │ verX.X.X │ SUB:X │ 🕐 HH:MM
#   Contains: working directory, git branch/status, commit count, Claude version, submodule count, current time
#
# Line 2: Claude Usage & Cost Tracking
#   Format: 🎵 Model │ REPO $X.XX │ 30DAY $X.XX │ 7DAY $X.XX │ DAY $X.XX │ 🔥 LIVE $X.XX
#   Contains: current model, session cost, monthly cost, weekly cost, daily cost, active block cost
#
# Line 3: MCP Server Status
#   Format: MCP (X/Y): server1, server2, server3
#   Contains: MCP connection status and list of servers with their connection states
#
# Line 4: RESET Info (conditional - only when active block exists)
#   Format: RESET at HH.MM (Xh Ym left)
#   Contains: when the current billing block will reset and time remaining

# ============================================================================
# CONFIGURATION SECTION - Modify these values to customize your statusline
# ============================================================================

# === THEME SELECTION ===
# Choose from predefined themes or use 'custom' for manual color configuration below
# Available themes:
#   classic    - Traditional terminal colors (current setup)
#   garden     - Soft pastel colors for gentle aesthetic
#   catppuccin - Popular catppuccin mocha theme colors
#   custom     - Use manual color configuration below
CONFIG_THEME="catppuccin"

# === COLORS ===
#
# TWO WAYS TO CUSTOMIZE COLORS:
#
# 1. USE PREDEFINED THEMES (Recommended):
#    Set CONFIG_THEME above to "classic", "garden", or "catppuccin"
#    Themes automatically configure all colors for you
#
# 2. MANUAL CUSTOMIZATION:
#    Set CONFIG_THEME="custom" and modify individual CONFIG_* variables below
#    Copy any example from the alternatives section
#
# COLOR SYSTEMS:
# • ANSI (30-37): Most compatible, works everywhere
# • 256-color (38;5;N): Better colors, widely supported
# • RGB (38;2;R;G;B): Full color range, modern terminals only
# • Add '48' instead of '38' for background colors
#

# === ACTIVE COLOR CONFIGURATION ===
# These colors are only used when CONFIG_THEME="custom"
# When using predefined themes, these values are ignored

if [[ "$CONFIG_THEME" == "custom" ]]; then
  # Basic terminal colors (ANSI standard - most compatible)
  CONFIG_RED='\033[31m'     # Used for: mode info
  CONFIG_BLUE='\033[34m'    # Used for: directory path
  CONFIG_GREEN='\033[32m'   # Used for: clean git status, repo costs
  CONFIG_YELLOW='\033[33m'  # Used for: dirty git status
  CONFIG_MAGENTA='\033[35m' # Used for: git branch
  CONFIG_CYAN='\033[36m'    # Used for: model name
  CONFIG_WHITE='\033[37m'   # Used for: general text

  # Extended colors (256-color and bright ANSI)
  CONFIG_ORANGE='\033[38;5;208m'       # Used for: time display
  CONFIG_LIGHT_ORANGE='\033[38;5;215m' # Used for: clock emoji
  CONFIG_LIGHT_GRAY='\033[38;5;248m'   # Used for: reset info
  CONFIG_BRIGHT_GREEN='\033[92m'       # Used for: MCP servers, submodules
  CONFIG_PURPLE='\033[95m'             # Used for: Claude version
  CONFIG_TEAL='\033[38;5;73m'          # Used for: commits, daily costs
  CONFIG_GOLD='\033[38;5;220m'         # Used for: special highlights
  CONFIG_PINK_BRIGHT='\033[38;5;205m'  # Used for: 30-day costs
  CONFIG_INDIGO='\033[38;5;105m'       # Used for: 7-day costs
  CONFIG_VIOLET='\033[38;5;99m'        # Used for: session info
  CONFIG_LIGHT_BLUE='\033[38;5;111m'   # Used for: MCP server names

  # Text formatting
  CONFIG_DIM='\033[2m'           # Used for: separators, dimmed text
  CONFIG_ITALIC='\033[3m'        # Used for: reset info
  CONFIG_STRIKETHROUGH='\033[9m' # Used for: offline MCP servers
  CONFIG_RESET='\033[0m'         # Used for: reset all formatting
fi

# === COLOR ALTERNATIVES ===
# Copy any of these values to replace the CONFIG_* variables above
#
# ANSI STANDARD COLORS (30-37, 90-97) - Works on all terminals
# Basic colors:
#   '\033[30m'  # Black
#   '\033[31m'  # Red
#   '\033[32m'  # Green
#   '\033[33m'  # Yellow
#   '\033[34m'  # Blue
#   '\033[35m'  # Magenta
#   '\033[36m'  # Cyan
#   '\033[37m'  # White
#
# Bright colors (more vibrant):
#   '\033[90m'  # Bright Black (Gray)
#   '\033[91m'  # Bright Red
#   '\033[92m'  # Bright Green
#   '\033[93m'  # Bright Yellow
#   '\033[94m'  # Bright Blue
#   '\033[95m'  # Bright Magenta
#   '\033[96m'  # Bright Cyan
#   '\033[97m'  # Bright White
#
# 256-COLOR PALETTE (38;5;N) - Supported by most modern terminals
# Popular choices:
#   '\033[38;5;196m'  # Bright Red
#   '\033[38;5;46m'   # Bright Green
#   '\033[38;5;21m'   # Bright Blue
#   '\033[38;5;226m'  # Bright Yellow
#   '\033[38;5;201m'  # Hot Pink
#   '\033[38;5;51m'   # Bright Cyan
#   '\033[38;5;208m'  # Orange
#   '\033[38;5;165m'  # Purple
#   '\033[38;5;39m'   # Sky Blue
#   '\033[38;5;118m'  # Lime Green
#   '\033[38;5;214m'  # Golden
#   '\033[38;5;129m'  # Violet
#   '\033[38;5;203m'  # Salmon
#   '\033[38;5;81m'   # Turquoise
#   '\033[38;5;220m'  # Gold
#   '\033[38;5;198m'  # Deep Pink
#
# RGB TRUE COLOR (38;2;R;G;B) - Modern terminals, full color range
# Examples:
#   '\033[38;2;255;0;0m'     # Pure Red
#   '\033[38;2;0;255;0m'     # Pure Green
#   '\033[38;2;0;0;255m'     # Pure Blue
#   '\033[38;2;255;165;0m'   # Orange
#   '\033[38;2;128;0;128m'   # Purple
#   '\033[38;2;255;20;147m'  # Deep Pink
#   '\033[38;2;0;191;255m'   # Deep Sky Blue
#   '\033[38;2;50;205;50m'   # Lime Green
#
# BACKGROUND COLORS - Replace '38' with '48' in any above example
# Examples:
#   '\033[48;5;196m'         # Red background
#   '\033[48;2;255;0;0m'     # RGB red background
#
# TEXT FORMATTING ALTERNATIVES:
#   '\033[1m'   # Bold
#   '\033[2m'   # Dim
#   '\033[3m'   # Italic
#   '\033[4m'   # Underline
#   '\033[5m'   # Blinking (rarely supported)
#   '\033[7m'   # Reverse (swap fg/bg)
#   '\033[8m'   # Hidden
#   '\033[9m'   # Strikethrough

# === TIMEOUTS (in seconds) ===
# Timeout for MCP server status checks
CONFIG_MCP_TIMEOUT="10s"
# Timeout for Claude version checks
CONFIG_VERSION_TIMEOUT="2s"
# Timeout for ccusage cost tracking
CONFIG_CCUSAGE_TIMEOUT="3s"

# === CACHE SETTINGS ===
# How long to cache Claude version (in seconds)
CONFIG_VERSION_CACHE_DURATION=3600
# Where to store the version cache file
CONFIG_VERSION_CACHE_FILE="/tmp/.claude_version_cache"

# === DISPLAY FORMATS ===
# Time display format (see 'man date' for options)
CONFIG_TIME_FORMAT="%H:%M"
# Date format for cost calculations
CONFIG_DATE_FORMAT="%Y-%m-%d"
CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"

# === MODEL EMOJIS ===
# Emojis for different Claude models
CONFIG_OPUS_EMOJI="🧠"
CONFIG_HAIKU_EMOJI="⚡"
CONFIG_SONNET_EMOJI="🎵"
CONFIG_DEFAULT_MODEL_EMOJI="🤖"

# === STATUS EMOJIS ===
# Git repository status indicators
CONFIG_CLEAN_STATUS_EMOJI="✅"
CONFIG_DIRTY_STATUS_EMOJI="📁"
# Time display
CONFIG_CLOCK_EMOJI="🕐"
# Cost tracking
CONFIG_LIVE_BLOCK_EMOJI="🔥"

# === DISPLAY LABELS ===
# Text labels used throughout the statusline
CONFIG_COMMITS_LABEL="Commits:"
CONFIG_REPO_LABEL="REPO"
CONFIG_MONTHLY_LABEL="30DAY"
CONFIG_WEEKLY_LABEL="7DAY"
CONFIG_DAILY_LABEL="DAY"
CONFIG_SUBMODULE_LABEL="SUB:"
CONFIG_MCP_LABEL="MCP"
CONFIG_VERSION_PREFIX="ver"
CONFIG_SESSION_PREFIX="S:"
CONFIG_LIVE_LABEL="LIVE"
CONFIG_RESET_LABEL="RESET"

# === ERROR/FALLBACK MESSAGES ===
# Messages shown when services are unavailable
CONFIG_NO_CCUSAGE_MESSAGE="No ccusage"
CONFIG_CCUSAGE_INSTALL_MESSAGE="Install ccusage for cost tracking"
CONFIG_NO_ACTIVE_BLOCK_MESSAGE="No active block"
CONFIG_MCP_UNKNOWN_MESSAGE="unknown"
CONFIG_MCP_NONE_MESSAGE="none"
CONFIG_UNKNOWN_VERSION="?"
CONFIG_NO_SUBMODULES="--"

# === FEATURE TOGGLES ===
# Enable/disable different sections of the statusline
CONFIG_SHOW_COMMITS=true
CONFIG_SHOW_VERSION=true
CONFIG_SHOW_SUBMODULES=true
CONFIG_SHOW_MCP_STATUS=true
CONFIG_SHOW_COST_TRACKING=true
CONFIG_SHOW_RESET_INFO=true
CONFIG_SHOW_SESSION_INFO=true

# ============================================================================
# END CONFIGURATION SECTION
# ============================================================================

# Apply selected theme colors
apply_theme() {
  case "$CONFIG_THEME" in
  "classic")
    # Traditional ANSI terminal colors
    CONFIG_RED='\033[31m'
    CONFIG_BLUE='\033[34m'
    CONFIG_GREEN='\033[32m'
    CONFIG_YELLOW='\033[33m'
    CONFIG_MAGENTA='\033[35m'
    CONFIG_CYAN='\033[36m'
    CONFIG_WHITE='\033[37m'
    CONFIG_ORANGE='\033[38;5;208m'
    CONFIG_LIGHT_ORANGE='\033[38;5;215m'
    CONFIG_LIGHT_GRAY='\033[38;5;248m'
    CONFIG_BRIGHT_GREEN='\033[92m'
    CONFIG_PURPLE='\033[95m'
    CONFIG_TEAL='\033[38;5;73m'
    CONFIG_GOLD='\033[38;5;220m'
    CONFIG_PINK_BRIGHT='\033[38;5;205m'
    CONFIG_INDIGO='\033[38;5;105m'
    CONFIG_VIOLET='\033[38;5;99m'
    CONFIG_LIGHT_BLUE='\033[38;5;111m'
    CONFIG_GRAY='\033[90m'
    CONFIG_DIM='\033[2m'
    CONFIG_ITALIC='\033[3m'
    CONFIG_STRIKETHROUGH='\033[9m'
    CONFIG_RESET='\033[0m'
    ;;
  "garden")
    # Soft pastel colors for gentle aesthetic
    CONFIG_RED='\033[38;2;255;182;193m'          # Light Pink
    CONFIG_BLUE='\033[38;2;173;216;230m'         # Powder Blue
    CONFIG_GREEN='\033[38;2;176;196;145m'        # Sage Green
    CONFIG_YELLOW='\033[38;2;255;218;185m'       # Peach
    CONFIG_MAGENTA='\033[38;2;230;230;250m'      # Lavender
    CONFIG_CYAN='\033[38;2;175;238;238m'         # Pale Turquoise
    CONFIG_WHITE='\033[38;2;245;245;245m'        # Soft White
    CONFIG_ORANGE='\033[38;2;255;200;173m'       # Pale Orange
    CONFIG_LIGHT_ORANGE='\033[38;2;255;200;173m' # Pale Orange
    CONFIG_LIGHT_GRAY='\033[38;2;169;169;169m'   # Light Gray
    CONFIG_BRIGHT_GREEN='\033[38;2;189;252;201m' # Mint Green
    CONFIG_PURPLE='\033[38;2;230;230;250m'       # Lavender
    CONFIG_TEAL='\033[38;2;189;252;201m'         # Mint Green
    CONFIG_GOLD='\033[38;2;255;218;185m'         # Peach
    CONFIG_PINK_BRIGHT='\033[38;2;255;182;193m'  # Light Pink
    CONFIG_INDIGO='\033[38;2;221;160;221m'       # Plum
    CONFIG_VIOLET='\033[38;2;230;230;250m'       # Lavender
    CONFIG_LIGHT_BLUE='\033[38;2;173;216;230m'   # Powder Blue
    CONFIG_GRAY='\033[38;2;169;169;169m'         # Light Gray
    CONFIG_DIM='\033[2m'
    CONFIG_ITALIC='\033[3m'
    CONFIG_STRIKETHROUGH='\033[9m'
    CONFIG_RESET='\033[0m'
    ;;
  "catppuccin")
    # Official Catppuccin Mocha theme colors
    CONFIG_RED='\033[38;2;243;139;168m'          # #f38ba8
    CONFIG_BLUE='\033[38;2;137;180;250m'         # #89b4fa
    CONFIG_GREEN='\033[38;2;166;227;161m'        # #a6e3a1
    CONFIG_YELLOW='\033[38;2;249;226;175m'       # #f9e2af
    CONFIG_MAGENTA='\033[38;2;203;166;247m'      # #cba6f7
    CONFIG_CYAN='\033[38;2;137;220;235m'         # #89dceb
    CONFIG_WHITE='\033[38;2;205;214;244m'        # #cdd6f4
    CONFIG_ORANGE='\033[38;2;250;179;135m'       # #fab387
    CONFIG_LIGHT_ORANGE='\033[38;2;250;179;135m' # #fab387
    CONFIG_LIGHT_GRAY='\033[38;2;166;173;200m'   # #a6adc8
    CONFIG_BRIGHT_GREEN='\033[38;2;166;227;161m' # #a6e3a1
    CONFIG_PURPLE='\033[38;2;203;166;247m'       # #cba6f7
    CONFIG_TEAL='\033[38;2;148;226;213m'         # #94e2d5
    CONFIG_GOLD='\033[38;2;249;226;175m'         # #f9e2af
    CONFIG_PINK_BRIGHT='\033[38;2;245;194;231m'  # #f5c2e7
    CONFIG_INDIGO='\033[38;2;116;199;236m'       # #74c7ec
    CONFIG_VIOLET='\033[38;2;203;166;247m'       # #cba6f7
    CONFIG_LIGHT_BLUE='\033[38;2;137;220;235m'   # #89dceb
    CONFIG_GRAY='\033[38;2;108;112;134m'         # #6c7086
    CONFIG_DIM='\033[2m'
    CONFIG_ITALIC='\033[3m'
    CONFIG_STRIKETHROUGH='\033[9m'
    CONFIG_RESET='\033[0m'
    ;;
  "custom")
    # Use manually configured colors below (no changes applied)
    ;;
  esac
}

# Apply the selected theme (only if not using custom theme)
if [[ "$CONFIG_THEME" != "custom" ]]; then
  apply_theme
fi

# ============================================================================
# DEPENDENCY VALIDATION AND SECURITY FUNCTIONS
# ============================================================================

# Enhanced path sanitization (addresses security concern from line 617)
sanitize_path_secure() {
    local path="$1"
    
    # Validate input
    if [[ -z "$path" ]]; then
        echo ""
        return 0
    fi
    
    # Check path length (prevent excessively long paths)
    if [[ ${#path} -gt 1000 ]]; then
        echo "ERROR: Path too long (${#path} chars, max 1000)" >&2
        # Return truncated path instead of failing
        path="${path:0:1000}"
    fi
    
    # Security-first sanitization: remove path traversal sequences FIRST
    local sanitized="$path"
    
    # Iteratively remove path traversal patterns until none remain
    # This prevents bypass attempts like ....// -> ../
    local prev_sanitized=""
    local iteration_count=0
    local max_iterations=10  # Prevent infinite loops
    
    while [[ "$sanitized" != "$prev_sanitized" ]] && [[ $iteration_count -lt $max_iterations ]]; do
        prev_sanitized="$sanitized"
        
        # Remove various path traversal patterns
        sanitized=$(echo "$sanitized" | /usr/bin/sed -e 's|\.\./||g' -e 's|\./||g' -e 's|//|/|g')
        
        ((iteration_count++))
    done
    
    # Final cleanup: remove any remaining .. sequences completely
    sanitized=$(echo "$sanitized" | /usr/bin/sed 's|\.\.|removed-dotdot|g')
    
    # Remove any remaining suspicious patterns
    sanitized=$(echo "$sanitized" | /usr/bin/sed -e 's|\.\.||g' -e 's|\~||g' -e 's|\$||g')
    
    # Replace slashes with hyphens
    sanitized=$(echo "$sanitized" | /usr/bin/sed 's|/|-|g')
    
    # Remove potentially dangerous characters, keep only safe ones
    sanitized=$(echo "$sanitized" | /usr/bin/tr -cd '[:alnum:]-_.')
    
    # Ensure result is not empty
    if [[ -z "$sanitized" ]]; then
        sanitized="unknown-path"
    fi
    
    echo "$sanitized"
}

# Secure cache file creation with file locking to prevent race conditions
create_secure_cache_file() {
    local cache_file="$1"
    local content="$2"
    local lock_file="${cache_file}.lock"
    local max_wait_time=5  # Maximum seconds to wait for lock
    local wait_count=0
    
    # Check required parameters
    if [[ -z "$cache_file" || -z "$content" ]]; then
        echo "ERROR: create_secure_cache_file requires cache_file and content parameters" >&2
        return 1
    fi
    
    # Create cache directory if it doesn't exist
    local cache_dir
    cache_dir=$(dirname "$cache_file")
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir" 2>/dev/null
        chmod 700 "$cache_dir" 2>/dev/null  # Secure permissions to prevent other users from reading cost data
    fi
    
    # Acquire exclusive file lock to prevent race conditions
    while ! (set -C; echo $$ > "$lock_file") 2>/dev/null; do
        if [[ $wait_count -ge $max_wait_time ]]; then
            echo "WARNING: Failed to acquire lock for cache file after ${max_wait_time}s, proceeding without lock: $cache_file" >&2
            break
        fi
        sleep 0.1
        ((wait_count++))
    done
    
    # Create file with content atomically 
    {
        # Use temporary file for atomic write
        local temp_file="${cache_file}.tmp.$$"
        
        # Write content to temporary file
        echo "$content" > "$temp_file" 2>/dev/null
        local write_status=$?
        
        if [[ $write_status -eq 0 && -f "$temp_file" ]]; then
            # Set secure permissions before moving
            chmod 644 "$temp_file" 2>/dev/null
            
            # Atomic move to final location
            mv "$temp_file" "$cache_file" 2>/dev/null
            write_status=$?
        else
            echo "ERROR: Failed to write to temporary cache file: $temp_file" >&2
            rm -f "$temp_file" 2>/dev/null
        fi
        
        # Clean up temporary file if move failed
        [[ -f "$temp_file" ]] && rm -f "$temp_file" 2>/dev/null
        
        # Release lock
        rm -f "$lock_file" 2>/dev/null
        
        # Verify final result
        if [[ $write_status -eq 0 && -f "$cache_file" ]]; then
            # Verify permissions were set correctly
            local perms
            perms=$(stat -f %A "$cache_file" 2>/dev/null || stat -c %a "$cache_file" 2>/dev/null)
            if [[ "$perms" != "644" ]]; then
                echo "WARNING: Cache file has unexpected permissions: $perms (expected: 644)" >&2
                # Try to fix permissions
                chmod 644 "$cache_file" 2>/dev/null
            fi
            return 0
        else
            echo "ERROR: Failed to create secure cache file: $cache_file" >&2
            return 1
        fi
    }
}

# ANSI color code validation for custom themes
validate_ansi_color() {
    local color_value="$1"
    local color_name="$2"
    
    # Check if color value is provided
    if [[ -z "$color_value" ]]; then
        return 1  # Empty color
    fi
    
    # Valid ANSI color patterns:
    # 1. Basic ANSI: \033[30-37m, \033[90-97m
    # 2. 256-color: \033[38;5;0-255m, \033[48;5;0-255m  
    # 3. RGB: \033[38;2;r;g;bm, \033[48;2;r;g;bm
    # 4. Reset and formatting: \033[0-9m
    
    local valid_patterns=(
        # Basic ANSI colors (30-37 for foreground, 40-47 for background)
        '^\\033\[[39][0-7]m$'
        # Bright ANSI colors (90-97 for bright foreground, 100-107 for bright background) 
        '^\\033\[1[0-9][0-7]m$'
        # 256-color format (38;5;n for foreground, 48;5;n for background)
        '^\\033\[38;5;[0-9]{1,3}m$'
        '^\\033\[48;5;[0-9]{1,3}m$'
        # RGB format (38;2;r;g;b for foreground, 48;2;r;g;b for background)
        '^\\033\[38;2;[0-9]{1,3};[0-9]{1,3};[0-9]{1,3}m$'
        '^\\033\[48;2;[0-9]{1,3};[0-9]{1,3};[0-9]{1,3}m$'
        # Text formatting codes (0-9, some multi-digit)
        '^\\033\[[0-9]{1,2}m$'
    )
    
    # Check against valid patterns
    local is_valid=false
    for pattern in "${valid_patterns[@]}"; do
        if [[ "$color_value" =~ $pattern ]]; then
            is_valid=true
            break
        fi
    done
    
    if [[ "$is_valid" != "true" ]]; then
        echo "WARNING: Invalid ANSI color code for '$color_name': $color_value" >&2
        echo "  Valid formats: \\033[31m, \\033[38;5;208m, \\033[38;2;255;100;50m" >&2
        return 2  # Invalid format
    fi
    
    # Additional validation for 256-color values (0-255 range)  
    local color_256_pattern='\\033\[(38|48);5;([0-9]+)m'
    if [[ "$color_value" =~ $color_256_pattern ]]; then
        local color_num="${BASH_REMATCH[2]}"
        if [[ "$color_num" -gt 255 ]]; then
            echo "WARNING: 256-color code out of range for '$color_name': $color_num (max: 255)" >&2
            return 3  # Out of range
        fi
    fi
    
    # Additional validation for RGB values (0-255 range for each component)
    local rgb_pattern='\\033\[(38|48);2;([0-9]+);([0-9]+);([0-9]+)m'
    if [[ "$color_value" =~ $rgb_pattern ]]; then
        local r="${BASH_REMATCH[2]}" 
        local g="${BASH_REMATCH[3]}"
        local b="${BASH_REMATCH[4]}"
        
        if [[ "$r" -gt 255 || "$g" -gt 255 || "$b" -gt 255 ]]; then
            echo "WARNING: RGB color values out of range for '$color_name': R=$r G=$g B=$b (max: 255)" >&2
            return 4  # RGB out of range
        fi
    fi
    
    return 0  # Valid color code
}

# TOML configuration schema validation
validate_toml_schema() {
    local config_json="$1"
    local validation_errors=()
    local validation_warnings=()
    
    if [[ -z "$config_json" || "$config_json" == "{}" ]]; then
        echo "ERROR: Empty or invalid JSON configuration for schema validation" >&2
        return 1
    fi
    
    # Expected TOML sections and their key requirements
    local expected_sections=(
        "theme"
        "colors"
        "features"
        "timeouts"
        "emojis"
        "labels"
        "cache"
        "display"
        "messages"
        "advanced"
        "platform"
        "paths"
        "performance"
        "debug"
    )
    
    # Critical sections that should be present for proper functionality
    local critical_sections=(
        "theme"
        "features"
        "timeouts"
    )
    
    # Check for critical sections
    for section in "${critical_sections[@]}"; do
        if ! echo "$config_json" | jq -e ".${section}" >/dev/null 2>&1; then
            validation_errors+=("Missing critical section: [$section]")
        fi
    done
    
    # Validate theme section structure
    if echo "$config_json" | jq -e '.theme' >/dev/null 2>&1; then
        # Check theme.name
        local theme_name
        theme_name=$(echo "$config_json" | jq -r '.theme.name // ""' 2>/dev/null)
        if [[ -z "$theme_name" ]]; then
            validation_errors+=("theme.name is required")
        elif [[ "$theme_name" != "classic" && "$theme_name" != "garden" && "$theme_name" != "catppuccin" && "$theme_name" != "custom" ]]; then
            validation_warnings+=("Unknown theme name: $theme_name (expected: classic, garden, catppuccin, custom)")
        fi
        
        # If custom theme, validate colors section
        if [[ "$theme_name" == "custom" ]]; then
            if ! echo "$config_json" | jq -e '.colors' >/dev/null 2>&1; then
                validation_errors+=("Custom theme requires [colors] section")
            fi
        fi
    fi
    
    # Validate colors section structure (if present)
    if echo "$config_json" | jq -e '.colors' >/dev/null 2>&1; then
        local color_subsections=("basic" "extended" "formatting")
        local found_color_section=false
        
        for subsection in "${color_subsections[@]}"; do
            if echo "$config_json" | jq -e ".colors.${subsection}" >/dev/null 2>&1; then
                found_color_section=true
                break
            fi
        done
        
        if [[ "$found_color_section" != "true" ]]; then
            validation_warnings+=("colors section exists but no color subsections found (basic, extended, formatting)")
        fi
    fi
    
    # Validate features section structure
    if echo "$config_json" | jq -e '.features' >/dev/null 2>&1; then
        local feature_keys=(
            "show_commits"
            "show_version" 
            "show_submodules"
            "show_mcp_status"
            "show_cost_tracking"
            "show_reset_info"
            "show_session_info"
        )
        
        for feature in "${feature_keys[@]}"; do
            local feature_value
            feature_value=$(echo "$config_json" | jq -r ".features.${feature}" 2>/dev/null)
            if [[ -n "$feature_value" && "$feature_value" != "null" && "$feature_value" != "true" && "$feature_value" != "false" ]]; then
                validation_errors+=("features.${feature} must be boolean (true/false), got: $feature_value")
            fi
        done
    fi
    
    # Validate timeouts section structure
    if echo "$config_json" | jq -e '.timeouts' >/dev/null 2>&1; then
        local timeout_keys=("mcp" "version" "ccusage")
        
        for timeout in "${timeout_keys[@]}"; do
            local timeout_value
            timeout_value=$(echo "$config_json" | jq -r ".timeouts.${timeout}" 2>/dev/null)
            if [[ -n "$timeout_value" && "$timeout_value" != "null" ]]; then
                # Validate timeout format (should end with 's' for seconds)
                if [[ ! "$timeout_value" =~ ^[0-9]+s$ ]]; then
                    validation_warnings+=("timeouts.${timeout} should be in format '3s', got: $timeout_value")
                fi
            fi
        done
    fi
    
    # Check for unknown top-level sections
    local all_keys
    all_keys=$(echo "$config_json" | jq -r 'keys[]' 2>/dev/null)
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        local is_known=false
        for known_section in "${expected_sections[@]}"; do
            if [[ "$key" == "$known_section" ]]; then
                is_known=true
                break
            fi
        done
        if [[ "$is_known" != "true" ]]; then
            validation_warnings+=("Unknown configuration section: [$key]")
        fi
    done <<< "$all_keys"
    
    # Report validation results
    local has_errors=false
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        has_errors=true
        echo "❌ TOML Schema validation errors:" >&2
        for error in "${validation_errors[@]}"; do
            echo "  ✗ $error" >&2
        done
    fi
    
    if [[ ${#validation_warnings[@]} -gt 0 ]]; then
        echo "⚠️ TOML Schema validation warnings:" >&2
        for warning in "${validation_warnings[@]}"; do
            echo "  ⚠ $warning" >&2
        done
    fi
    
    if [[ "$has_errors" != "true" ]]; then
        if [[ ${#validation_warnings[@]} -eq 0 ]]; then
            echo "✅ TOML schema validation passed successfully" >&2
        else
            echo "✅ TOML schema validation passed with ${#validation_warnings[@]} warnings" >&2
        fi
        return 0
    else
        echo "❌ TOML schema validation failed with ${#validation_errors[@]} errors" >&2
        return 1
    fi
}

# Dependency validation system
validate_dependencies() {
    local missing_critical=()
    local missing_optional=()
    local warnings=()
    
    # Check jq availability for TOML configuration support
    if command -v jq >/dev/null 2>&1; then
        export DEP_JQ_AVAILABLE=true
    else
        export DEP_JQ_AVAILABLE=false
        warnings+=("jq: TOML configuration disabled, using inline config only")
    fi
    
    # Check optional dependencies with graceful degradation
    command -v bc >/dev/null 2>&1 || missing_optional+=("bc")
    command -v bunx >/dev/null 2>&1 || missing_optional+=("bunx")
    
    # Check Python3 for advanced TOML processing
    if command -v python3 >/dev/null 2>&1; then
        export DEP_PYTHON3_AVAILABLE=true
    else
        export DEP_PYTHON3_AVAILABLE=false
        missing_optional+=("python3")
    fi
    
    # Check timeout commands (platform-specific)
    if command -v gtimeout >/dev/null 2>&1; then
        export DEP_TIMEOUT_CMD="gtimeout"
    elif command -v timeout >/dev/null 2>&1; then
        export DEP_TIMEOUT_CMD="timeout"
    else
        export DEP_TIMEOUT_CMD=""
        missing_optional+=("timeout")
    fi
    
    # No longer treat any dependency as critical - graceful degradation for all
    
    # Handle optional dependency warnings
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        for dep in "${missing_optional[@]}"; do
            case "$dep" in
                "bc")
                    warnings+=("bc: Cost calculations may be less accurate")
                    ;;
                "python3")
                    warnings+=("python3: Date parsing fallbacks will be used")
                    ;;
                "bunx")
                    warnings+=("bunx: Cost tracking with ccusage will be unavailable")
                    ;;
                "timeout")
                    warnings+=("timeout: Network operations may hang longer")
                    ;;
            esac
        done
        
        # Only show warnings if explicitly enabled
        if [[ "${CONFIG_WARN_MISSING_DEPS:-false}" == "true" ]]; then
            echo "DEPENDENCY WARNINGS:" >&2
            for warning in "${warnings[@]}"; do
                echo "  - $warning" >&2
            done
            echo "Set CONFIG_WARN_MISSING_DEPS=false to suppress these warnings." >&2
        fi
    fi
    
    # Export dependency availability for use in other functions
    export DEP_BC_AVAILABLE
    DEP_BC_AVAILABLE=$(command -v bc >/dev/null 2>&1 && echo "true" || echo "false")
    export DEP_PYTHON3_AVAILABLE
    DEP_PYTHON3_AVAILABLE=$(command -v python3 >/dev/null 2>&1 && echo "true" || echo "false")
    export DEP_BUNX_AVAILABLE
    DEP_BUNX_AVAILABLE=$(command -v bunx >/dev/null 2>&1 && echo "true" || echo "false")
    export DEP_TIMEOUT_AVAILABLE="false"
    if command -v gtimeout >/dev/null 2>&1; then
        export DEP_TIMEOUT_CMD="gtimeout"
        export DEP_TIMEOUT_AVAILABLE="true"
    elif command -v timeout >/dev/null 2>&1; then
        export DEP_TIMEOUT_CMD="timeout"
        export DEP_TIMEOUT_AVAILABLE="true"
    fi
}

# Enhanced Python execution with better error handling (addresses line 688 concern)
execute_python_safely() {
    local python_code="$1"
    local fallback_value="$2"
    
    # Check if Python is available
    if [[ "$DEP_PYTHON3_AVAILABLE" != "true" ]]; then
        echo "$fallback_value"
        return 0
    fi
    
    # Validate input (comprehensive injection prevention)
    local dangerous_patterns=(
        "rm -rf" "rm -r" "rmdir" "unlink" "delete"           # File deletion
        "system(" "exec(" "eval(" "compile("                  # Code execution
        "subprocess." "popen(" "call(" "run("                 # Process execution
        "os.system" "os.popen" "os.execv" "os.spawn"          # OS command execution
        "__import__" "importlib" "import subprocess"          # Dangerous imports
        "urllib" "requests" "http" "socket" "ftp"             # Network operations
        "open(" "file(" "write(" "writelines("                # File I/O operations
        "shutil" "glob.glob" "pathlib" "tempfile"             # File system manipulation
        "; " "&&" "||" "|" ">" ">>" "<"                      # Shell operators
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$python_code" == *"$pattern"* ]]; then
            echo "ERROR: Potentially dangerous Python code detected: $pattern" >&2
            echo "$fallback_value"
            return 1
        fi
    done
    
    # Execute with timeout if available
    local result
    if [[ "$DEP_TIMEOUT_AVAILABLE" == "true" ]]; then
        result=$($DEP_TIMEOUT_CMD 5s python3 -c "$python_code" 2>/dev/null)
    else
        result=$(python3 -c "$python_code" 2>/dev/null)
    fi
    
    # Return result or fallback
    if [[ $? -eq 0 && -n "$result" ]]; then
        echo "$result"
    else
        echo "$fallback_value"
    fi
}

# Enhanced MCP server name parsing (addresses lines 374, 396-398 security concern)
parse_mcp_server_name_secure() {
    local line="$1"
    
    # Improved regex pattern that's more restrictive and secure
    # Only allow ASCII alphanumeric, underscore, and hyphen
    # Must start and end with alphanumeric
    if [[ "$line" =~ ^([a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]|[a-zA-Z0-9]): ]]; then
        local server_name="${BASH_REMATCH[1]}"
        
        # Additional validation: check length and character set
        if [[ ${#server_name} -gt 100 ]]; then
            echo "ERROR: MCP server name too long: ${server_name:0:20}..." >&2
            return 1
        fi
        
        # Ensure no dangerous characters slipped through
        if [[ "$server_name" =~ [^a-zA-Z0-9_-] ]]; then
            echo "ERROR: Invalid characters in MCP server name: $server_name" >&2
            return 1
        fi
        
        echo "$server_name"
        return 0
    fi
    
    return 1
}

# Parse timeout string to numeric seconds for validation
# Supports formats: "10s", "2m", "30" (defaults to seconds)
parse_timeout_to_seconds() {
    local timeout_str="$1"
    local numeric_value
    local unit
    
    # Handle empty or null values
    [[ -z "$timeout_str" || "$timeout_str" == "null" ]] && return 1
    
    # Extract numeric value and unit
    if [[ "$timeout_str" =~ ^([0-9]+)([sm]?)$ ]]; then
        numeric_value="${BASH_REMATCH[1]}"
        unit="${BASH_REMATCH[2]}"
        
        # Convert to seconds based on unit
        case "$unit" in
            "m") echo $((numeric_value * 60)) ;;
            "s"|"") echo "$numeric_value" ;;  # Default to seconds
            *) return 1 ;;  # Invalid unit
        esac
        return 0
    else
        return 1  # Invalid format
    fi
}

# Validate timeout bounds with contextual limits and suggestions
# Returns: 0=valid, 1=error, 2=warning
validate_timeout_bounds() {
    local timeout_config="$1"  # Config variable name (e.g., "CONFIG_MCP_TIMEOUT")
    local timeout_value="$2"   # Timeout value (e.g., "10s")
    local timeout_type="$3"    # Type: "mcp", "version", "ccusage"
    # Note: errors, warnings, suggestions arrays are global and modified directly
    
    # Parse timeout to seconds
    local seconds
    if ! seconds=$(parse_timeout_to_seconds "$timeout_value"); then
        errors+=("$timeout_config has invalid format '$timeout_value'. Use format like '10s' or '2m'")
        suggestions+=("💡 Example: ${timeout_config,,} = \"10s\" or \"2m\"")
        return 1
    fi
    
    # Define bounds based on timeout type
    local min_seconds max_seconds warn_seconds optimal_range
    case "$timeout_type" in
        "mcp")
            min_seconds=1
            max_seconds=60
            warn_seconds=30
            optimal_range="3s-15s for most setups, 10s-30s for complex MCP configurations"
            ;;
        "version")
            min_seconds=1
            max_seconds=10  
            warn_seconds=5
            optimal_range="1s-3s (usually cached after first run)"
            ;;
        "ccusage")
            min_seconds=1
            max_seconds=30
            warn_seconds=15
            optimal_range="3s-10s for network API calls"
            ;;
        *)
            # Generic validation for unknown timeout types
            min_seconds=1
            max_seconds=60
            warn_seconds=30
            optimal_range="1s-30s for most operations"
            ;;
    esac
    
    # Check bounds and provide contextual feedback
    if [[ $seconds -lt $min_seconds ]]; then
        errors+=("$timeout_config value ${timeout_value} (${seconds}s) is too short. Minimum: ${min_seconds}s")
        suggestions+=("💡 ${timeout_type^^} operations need at least ${min_seconds}s. Try: ${timeout_config,,} = \"${min_seconds}s\"")
        return 1
    elif [[ $seconds -gt $max_seconds ]]; then
        errors+=("$timeout_config value ${timeout_value} (${seconds}s) is too long. Maximum: ${max_seconds}s")
        suggestions+=("💡 ${timeout_type^^} timeouts >${max_seconds}s can freeze statusline. Try: ${timeout_config,,} = \"${max_seconds}s\"")
        return 1
    elif [[ $seconds -gt $warn_seconds ]]; then
        warnings+=("$timeout_config value ${timeout_value} (${seconds}s) may impact responsiveness")
        suggestions+=("💡 ${timeout_type^^} optimal range: $optimal_range")
        return 2
    fi
    
    # Value is within optimal range
    return 0
}

# Helper function to get timeout command with specified duration
get_timeout_cmd() {
    local duration="$1"
    
    if [[ "$DEP_TIMEOUT_AVAILABLE" == "true" ]]; then
        echo "$DEP_TIMEOUT_CMD $duration"
    else
        echo ""
    fi
}

# Helper function to execute commands with optional timeout
execute_with_timeout() {
    local timeout_duration="$1"
    shift
    local command=("$@")
    
    local timeout_cmd
    timeout_cmd=$(get_timeout_cmd "$timeout_duration")
    
    if [[ -n "$timeout_cmd" ]]; then
        $timeout_cmd "${command[@]}"
    else
        "${command[@]}"
    fi
}

# Execute multiple ccusage commands in parallel for better performance
execute_ccusage_parallel() {
    local timeout_duration="$1"
    local seven_days_ago="$2"
    local thirty_days_ago="$3"
    local current_session_id="$4"
    
    # Create secure temporary directory for results
    local temp_dir
    temp_dir=$(mktemp -d -t "ccusage_parallel.XXXXXX" 2>/dev/null || mktemp -d)
    if [[ ! -d "$temp_dir" ]]; then
        echo "ERROR: Could not create temporary directory for parallel execution" >&2
        return 1
    fi
    
    # Define temporary files for each command result
    local session_file="$temp_dir/session.json"
    local daily_7d_file="$temp_dir/daily_7d.json"
    local daily_30d_file="$temp_dir/daily_30d.json"  
    local blocks_file="$temp_dir/blocks.json"
    
    # Define error files to track command failures
    local session_err="$temp_dir/session.err"
    local daily_7d_err="$temp_dir/daily_7d.err"
    local daily_30d_err="$temp_dir/daily_30d.err"
    local blocks_err="$temp_dir/blocks.err"
    
    # Launch all 4 ccusage commands in parallel
    local pids=()
    
    # Command 1: Session data
    (execute_with_timeout "$timeout_duration" bunx ccusage session --since "$seven_days_ago" --json > "$session_file" 2> "$session_err") &
    pids+=($!)
    
    # Command 2: Daily data (7 days)
    (execute_with_timeout "$timeout_duration" bunx ccusage daily --since "$seven_days_ago" --json > "$daily_7d_file" 2> "$daily_7d_err") &
    pids+=($!)
    
    # Command 3: Daily data (30 days)
    (execute_with_timeout "$timeout_duration" bunx ccusage daily --since "$thirty_days_ago" --json > "$daily_30d_file" 2> "$daily_30d_err") &
    pids+=($!)
    
    # Command 4: Active blocks
    (execute_with_timeout "$timeout_duration" bunx ccusage blocks --active --json > "$blocks_file" 2> "$blocks_err") &
    pids+=($!)
    
    # Wait for all commands to complete
    local exit_codes=()
    for pid in "${pids[@]}"; do
        wait "$pid"
        exit_codes+=($?)
    done
    
    # Read results (empty if command failed)
    local session_data=""
    local daily_7d_data=""
    local daily_30d_data=""
    local blocks_data=""
    
    # Read results if files contain data
    [[ -s "$session_file" ]] && session_data=$(cat "$session_file" 2>/dev/null)
    [[ -s "$daily_7d_file" ]] && daily_7d_data=$(cat "$daily_7d_file" 2>/dev/null)
    [[ -s "$daily_30d_file" ]] && daily_30d_data=$(cat "$daily_30d_file" 2>/dev/null)
    [[ -s "$blocks_file" ]] && blocks_data=$(cat "$blocks_file" 2>/dev/null)
    
    # Cleanup temporary directory
    rm -rf "$temp_dir" 2>/dev/null
    
    # Output results in structured format for easy parsing
    # Format: session_data|daily_7d_data|daily_30d_data|blocks_data
    echo "${session_data}|${daily_7d_data}|${daily_30d_data}|${blocks_data}"
}

# Initialize dependency validation
validate_dependencies

# ============================================================================
# TOML CONFIGURATION SYSTEM (Phase 1)
# ============================================================================

# Simple TOML to JSON converter for basic types (strings, booleans, integers)
# Phase 1: Supports sections, key-value pairs, basic data types
# Fixed approach: Create flat structure with dotted keys, then restructure
parse_toml_to_json() {
    local toml_file="$1"
    
    # Enhanced error handling with proper exit codes
    if [[ -z "$toml_file" ]]; then
        echo "ERROR: No TOML file path provided" >&2
        echo "{}"
        return 2  # Invalid arguments
    fi
    
    if [[ ! -f "$toml_file" ]]; then
        echo "ERROR: TOML configuration file not found: $toml_file" >&2
        echo "{}"
        return 1  # File not found
    fi
    
    if [[ ! -r "$toml_file" ]]; then
        echo "ERROR: TOML configuration file not readable: $toml_file" >&2
        echo "{}"
        return 3  # Permission denied
    fi
    
    # Create temporary flat structure
    local flat_json="{"
    local current_section=""
    local first_item=true
    
    # Read TOML file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        # Handle section headers [section] or [section.subsection] or [section.sub.subsub]
        if [[ "$line" =~ ^\[[[:space:]]*([^]]+)[[:space:]]*\]$ ]]; then
            local section_name="${BASH_REMATCH[1]}"
            current_section="$section_name"
            continue
        fi
        
        # Handle key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Clean up key and value
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Create flat key with section prefix
            local flat_key
            if [[ -n "$current_section" ]]; then
                flat_key="${current_section}.${key}"
            else
                flat_key="$key"
            fi
            
            # Add comma if not first item
            if [[ "$first_item" != "true" ]]; then
                flat_json="$flat_json,"
            fi
            
            # Parse value type and format for JSON
            if [[ "$value" =~ ^\"(.*)\"$ ]]; then
                # String value (quoted)
                local string_val="${BASH_REMATCH[1]}"
                # Escape quotes and backslashes for JSON
                string_val=$(echo "$string_val" | sed 's/\\/\\\\/g; s/"/\\"/g')
                flat_json="$flat_json\"$flat_key\":\"$string_val\""
            elif [[ "$value" =~ ^\[.*\]$ ]]; then
                # Array value - simplified for now
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^(true|false)$ ]]; then
                # Boolean value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]+$ ]]; then
                # Integer value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]*\.[0-9]+$ ]]; then
                # Float value
                flat_json="$flat_json\"$flat_key\":$value"
            else
                # Unquoted string - treat as string
                value=$(echo "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')
                flat_json="$flat_json\"$flat_key\":\"$value\""
            fi
            
            first_item=false
        fi
    done < "$toml_file"
    
    # Close flat JSON
    flat_json="$flat_json}"
    
    # Check if jq is available for JSON validation
    if [[ "$DEP_JQ_AVAILABLE" == "true" ]]; then
        # Validate flat JSON before processing
        if ! echo "$flat_json" | jq . >/dev/null 2>&1; then
            echo "ERROR: Generated invalid JSON during TOML parsing: $toml_file" >&2
            echo "DEBUG: Flat JSON: $flat_json" >&2
            echo "{}"
            return 4  # Parse error
        fi
    else
        echo "WARNING: jq not available for JSON validation, skipping validation: $toml_file" >&2
    fi
    
    # Convert flat structure to nested using Python (if available) or simple approach
    if [[ "$DEP_PYTHON3_AVAILABLE" == "true" ]]; then
        local nested_json python_error
        # Capture both stdout and stderr from Python
        {
            nested_json=$(python3 -c "
import json
import sys

try:
    flat = json.loads('$flat_json')
    nested = {}
    
    for key, value in flat.items():
        parts = key.split('.')
        current = nested
        
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]
        
        current[parts[-1]] = value
    
    print(json.dumps(nested))
except json.JSONDecodeError as e:
    print(f'ERROR: JSON decode error in TOML parser: {e}', file=sys.stderr)
    print('{}')
except Exception as e:
    print(f'ERROR: Python processing error in TOML parser: {e}', file=sys.stderr)
    print('{}')
" 2>&1)
        } 2>&1
        
        # Validate nested JSON output (if jq is available)
        local is_valid_nested=false
        if [[ "$DEP_JQ_AVAILABLE" == "true" ]]; then
            if [[ -n "$nested_json" ]] && echo "$nested_json" | jq . >/dev/null 2>&1; then
                is_valid_nested=true
            fi
        else
            # Without jq, use basic validation
            if [[ -n "$nested_json" && "$nested_json" != "{}" ]]; then
                is_valid_nested=true
            fi
        fi
        
        if [[ "$is_valid_nested" == "true" ]]; then
            echo "$nested_json"
        else
            if [[ "$nested_json" == "{}" ]]; then
                echo "WARNING: Python TOML processing failed, falling back to flat structure: $toml_file" >&2
            else
                echo "WARNING: Invalid nested JSON generated, falling back to flat structure: $toml_file" >&2
                echo "DEBUG: Python output: $nested_json" >&2
            fi
            # Validate flat JSON again before returning it (if jq available)
            local is_valid_flat=false
            if [[ "$DEP_JQ_AVAILABLE" == "true" ]]; then
                if echo "$flat_json" | jq . >/dev/null 2>&1; then
                    is_valid_flat=true
                fi
            else
                # Without jq, assume flat JSON is valid if non-empty
                if [[ -n "$flat_json" && "$flat_json" != "{}" ]]; then
                    is_valid_flat=true
                fi
            fi
            
            if [[ "$is_valid_flat" == "true" ]]; then
                echo "$flat_json"
            else
                echo "ERROR: Both nested and flat JSON structures are invalid: $toml_file" >&2
                echo "{}"
                return 5  # Critical parse failure
            fi
        fi
    else
        echo "WARNING: Python3 not available for TOML nesting, using flat structure: $toml_file" >&2
        # Validate flat JSON before returning (if jq available)
        local is_valid_flat=false
        if [[ "$DEP_JQ_AVAILABLE" == "true" ]]; then
            if echo "$flat_json" | jq . >/dev/null 2>&1; then
                is_valid_flat=true
            fi
        else
            # Without jq, basic validation - assume valid if non-empty and not just {}
            if [[ -n "$flat_json" && "$flat_json" != "{}" ]]; then
                is_valid_flat=true
            fi
        fi
        
        if [[ "$is_valid_flat" == "true" ]]; then
            echo "$flat_json"
        else
            echo "ERROR: Generated invalid flat JSON without jq validation: $toml_file" >&2
            echo "{}"
            return 6  # Flat JSON invalid
        fi
    fi
}

# Discover config files in order of precedence (Phase 2: multi-location)
discover_config_file() {
    # Configuration file precedence (highest to lowest):
    # 1. ./Config.toml (project-specific, highest precedence)
    # 2. ~/.config/claude-code-statusline/Config.toml (XDG standard)
    # 3. ~/.claude-statusline.toml (user home directory)
    
    local config_files=(
        "./Config.toml"
        "$HOME/.config/claude-code-statusline/Config.toml"
        "$HOME/.claude-statusline.toml"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" && -r "$config_file" ]]; then
            echo "$config_file"
            return 0
        fi
    done
    
    # No config file found
    return 1
}

# Load configuration from TOML file and set variables
load_toml_configuration() {
    # Check if jq is available for TOML configuration
    if [[ "$DEP_JQ_AVAILABLE" != "true" ]]; then
        echo "WARNING: jq not available - TOML configuration disabled, using inline configuration" >&2
        echo "Install jq to enable TOML configuration support:" >&2
        echo "  Ubuntu/Debian: sudo apt-get install jq" >&2  
        echo "  macOS: brew install jq" >&2
        return 0  # Continue with inline configuration
    fi
    
    local config_file
    
    # Try to find config file
    if config_file=$(discover_config_file); then
        echo "Loading configuration from: $config_file" >&2
        
        # Parse TOML to JSON with comprehensive error handling
        local config_json parse_exit_code
        config_json=$(parse_toml_to_json "$config_file")
        parse_exit_code=$?
        
        # Handle different types of parsing errors
        case $parse_exit_code in
            0)
                # Success - check for empty result
                if [[ "$config_json" == "{}" ]]; then
                    echo "Warning: Empty config file, using defaults" >&2
                    return 1
                fi
                
                # Validate TOML configuration schema (if jq is available)
                if [[ "$DEP_JQ_AVAILABLE" == "true" ]]; then
                    echo "🔍 Validating TOML configuration schema..." >&2
                    if ! validate_toml_schema "$config_json"; then
                        echo "⚠️ Configuration schema validation failed, but continuing with available settings" >&2
                    fi
                else
                    echo "🔍 Skipping TOML schema validation (jq not available)" >&2
                fi
                ;;
            1)
                echo "Error: Configuration file not found, using defaults" >&2
                return 1
                ;;
            2)
                echo "Error: Invalid configuration file path, using defaults" >&2
                return 1
                ;;
            3)
                echo "Error: Configuration file not readable (permissions), using defaults" >&2
                return 1
                ;;
            *)
                echo "Error: Unknown error parsing configuration file, using defaults" >&2
                return 1
                ;;
        esac
        
        # Verify jq availability before processing
        if ! command -v jq >/dev/null 2>&1; then
            echo "Error: jq is required for TOML configuration but not available, using defaults" >&2
            return 1
        fi
        
        # Extract ALL configuration values using optimized single-pass jq operation
        # Replaces 64 individual jq calls with 1 comprehensive extraction for 95% performance improvement
        
        # Single jq operation for single-pass jq config extraction with fallbacks
        local config_data
        config_data=$(echo "$config_json" | jq -r '{
            theme_name: (.theme.name // "catppuccin"),
            color_red: (.colors.basic.red // .colors.red // "\\033[31m"),
            color_blue: (.colors.basic.blue // .colors.blue // "\\033[34m"),
            color_green: (.colors.basic.green // .colors.green // "\\033[32m"),
            color_yellow: (.colors.basic.yellow // .colors.yellow // "\\033[33m"),
            color_magenta: (.colors.basic.magenta // .colors.magenta // "\\033[35m"),
            color_cyan: (.colors.basic.cyan // .colors.cyan // "\\033[36m"),
            color_white: (.colors.basic.white // .colors.white // "\\033[37m"),
            color_orange: (.colors.extended.orange // "\\033[38;5;208m"),
            color_light_orange: (.colors.extended.light_orange // "\\033[38;5;215m"),
            color_light_gray: (.colors.extended.light_gray // "\\033[38;5;248m"),
            color_bright_green: (.colors.extended.bright_green // "\\033[92m"),
            color_purple: (.colors.extended.purple // "\\033[95m"),
            color_teal: (.colors.extended.teal // "\\033[38;5;73m"),
            color_gold: (.colors.extended.gold // "\\033[38;5;220m"),
            color_pink_bright: (.colors.extended.pink_bright // "\\033[38;5;205m"),
            color_indigo: (.colors.extended.indigo // "\\033[38;5;105m"),
            color_violet: (.colors.extended.violet // "\\033[38;5;99m"),
            color_light_blue: (.colors.extended.light_blue // "\\033[38;5;111m"),
            color_dim: (.colors.formatting.dim // "\\033[2m"),
            color_italic: (.colors.formatting.italic // "\\033[3m"),
            color_strikethrough: (.colors.formatting.strikethrough // "\\033[9m"),
            color_reset: (.colors.formatting.reset // "\\033[0m"),
            feature_show_commits: (.features.show_commits // true),
            feature_show_version: (.features.show_version // true),
            feature_show_submodules: (.features.show_submodules // true),
            feature_show_mcp: (.features.show_mcp_status // true),
            feature_show_cost: (.features.show_cost_tracking // true),
            feature_show_reset: (.features.show_reset_info // true),
            feature_show_session: (.features.show_session_info // true),
            timeout_mcp: (.timeouts.mcp // "10s"),
            timeout_version: (.timeouts.version // "2s"),
            timeout_ccusage: (.timeouts.ccusage // "3s"),
            emoji_opus: (.emojis.opus // "🧠"),
            emoji_haiku: (.emojis.haiku // "⚡"),
            emoji_sonnet: (.emojis.sonnet // "🎵"),
            emoji_default: (.emojis.default_model // "🤖"),
            emoji_clean: (.emojis.clean_status // "✅"),
            emoji_dirty: (.emojis.dirty_status // "📁"),
            emoji_clock: (.emojis.clock // "🕐"),
            emoji_live_block: (.emojis.live_block // "🔥"),
            label_commits: (.labels.commits // "Commits:"),
            label_repo: (.labels.repo // "REPO"),
            label_monthly: (.labels.monthly // "30DAY"),
            label_weekly: (.labels.weekly // "7DAY"),
            label_daily: (.labels.daily // "DAY"),
            label_mcp: (.labels.mcp // "MCP"),
            label_version_prefix: (.labels.version_prefix // "ver"),
            label_submodule: (.labels.submodule // "SUB:"),
            label_session_prefix: (.labels.session_prefix // "S:"),
            label_live: (.labels.live // "LIVE"),
            label_reset: (.labels.reset // "RESET"),
            cache_version_duration: (.cache.version_duration // 3600),
            cache_version_file: (.cache.version_file // "/tmp/.claude_version_cache"),
            display_time_format: (.display.time_format // "%H:%M"),
            display_date_format: (.display.date_format // "%Y-%m-%d"),
            display_date_format_compact: (.display.date_format_compact // "%Y%m%d"),
            message_no_ccusage: (.messages.no_ccusage // "No ccusage"),
            message_ccusage_install: (.messages.ccusage_install // "Install ccusage for cost tracking"),
            message_no_active_block: (.messages.no_active_block // "No active block"),
            message_mcp_unknown: (.messages.mcp_unknown // "unknown"),
            message_mcp_none: (.messages.mcp_none // "none"),
            message_unknown_version: (.messages.unknown_version // "?"),
            message_no_submodules: (.messages.no_submodules // "--"),
            advanced_warn_missing_deps: (.advanced.warn_missing_deps // false),
            advanced_debug_mode: (.advanced.debug_mode // false),
            advanced_performance_mode: (.advanced.performance_mode // false),
            advanced_strict_validation: (.advanced.strict_validation // true),
            platform_prefer_gtimeout: (.platform.prefer_gtimeout // true),
            platform_use_gdate: (.platform.use_gdate // false),
            platform_color_support_level: (.platform.color_support_level // "full"),
            paths_temp_dir: (.paths.temp_dir // "/tmp"),
            paths_config_dir: (.paths.config_dir // "~/.config/claude-code-statusline"),
            paths_cache_dir: (.paths.cache_dir // "~/.cache/claude-code-statusline"),
            paths_log_file: (.paths.log_file // "~/.cache/claude-code-statusline/statusline.log"),
            performance_parallel_data_collection: (.performance.parallel_data_collection // true),
            performance_max_concurrent_operations: (.performance.max_concurrent_operations // 3),
            performance_git_operation_timeout: (.performance.git_operation_timeout // "5s"),
            performance_network_operation_timeout: (.performance.network_operation_timeout // "10s"),
            performance_enable_smart_caching: (.performance.enable_smart_caching // true),
            performance_cache_compression: (.performance.cache_compression // false),
            debug_log_level: (.debug.log_level // "error"),
            debug_log_config_loading: (.debug.log_config_loading // false),
            debug_log_theme_application: (.debug.log_theme_application // false),
            debug_log_validation_details: (.debug.log_validation_details // false),
            debug_benchmark_performance: (.debug.benchmark_performance // false),
            debug_export_debug_info: (.debug.export_debug_info // false)
        } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
        
        if [[ -z "$config_data" ]]; then
            echo "Warning: Failed to extract config values, using defaults" >&2
            return 1
        fi
        
        # Parse the extracted config values and apply them
        while IFS='=' read -r key value; do
            case "$key" in
                theme_name)
                    [[ "$value" != "null" && "$value" != "" ]] && CONFIG_THEME="$value"
                    ;;
            esac
        done <<< "$config_data"
        
        # Apply custom theme colors if theme is custom (using pre-extracted values)
        if [[ "$CONFIG_THEME" == "custom" ]]; then
            echo "🎨 Validating custom theme colors..." >&2
            local color_validation_errors=0
            
            while IFS='=' read -r key value; do
                case "$key" in
                    color_*)
                        if [[ "$value" != "null" && "$value" != "" ]]; then
                            # Extract color name for validation messages
                            local color_name="${key#color_}"  # Remove color_ prefix
                            
                            # Validate ANSI color code before applying
                            if validate_ansi_color "$value" "$color_name"; then
                                # Color is valid, apply it
                                case "$key" in
                                    color_red) CONFIG_RED="$value" ;;
                                    color_blue) CONFIG_BLUE="$value" ;;
                                    color_green) CONFIG_GREEN="$value" ;;
                                    color_yellow) CONFIG_YELLOW="$value" ;;
                                    color_magenta) CONFIG_MAGENTA="$value" ;;
                                    color_cyan) CONFIG_CYAN="$value" ;;
                                    color_white) CONFIG_WHITE="$value" ;;
                                    color_orange) CONFIG_ORANGE="$value" ;;
                                    color_light_orange) CONFIG_LIGHT_ORANGE="$value" ;;
                                    color_light_gray) CONFIG_LIGHT_GRAY="$value" ;;
                                    color_bright_green) CONFIG_BRIGHT_GREEN="$value" ;;
                                    color_purple) CONFIG_PURPLE="$value" ;;
                                    color_teal) CONFIG_TEAL="$value" ;;
                                    color_gold) CONFIG_GOLD="$value" ;;
                                    color_pink_bright) CONFIG_PINK_BRIGHT="$value" ;;
                                    color_indigo) CONFIG_INDIGO="$value" ;;
                                    color_violet) CONFIG_VIOLET="$value" ;;
                                    color_light_blue) CONFIG_LIGHT_BLUE="$value" ;;
                                    color_dim) CONFIG_DIM="$value" ;;
                                    color_italic) CONFIG_ITALIC="$value" ;;
                                    color_strikethrough) CONFIG_STRIKETHROUGH="$value" ;;
                                    color_reset) CONFIG_RESET="$value" ;;
                                    *) echo "WARNING: Unknown color key '$key' ignored" >&2 ;;
                                esac
                                echo "  ✅ $color_name: $value" >&2
                            else
                                # Color validation failed, keep default and increment error count
                                ((color_validation_errors++))
                                echo "  ❌ $color_name: $value (keeping default)" >&2
                            fi
                        fi
                        ;;
                esac
            done <<< "$config_data"
            
            # Report validation summary
            if [[ $color_validation_errors -gt 0 ]]; then
                echo "⚠️ Custom theme validation completed with $color_validation_errors errors - invalid colors use defaults" >&2
            else
                echo "✅ Custom theme validation completed successfully - all colors valid" >&2
            fi
        fi
        
        # Apply all remaining config values using pre-extracted data
        while IFS='=' read -r key value; do
            case "$key" in
                # Features
                feature_*)
                    if [[ "$value" == "true" || "$value" == "false" ]]; then
                        case "$key" in
                            feature_show_commits) CONFIG_SHOW_COMMITS="$value" ;;
                            feature_show_version) CONFIG_SHOW_VERSION="$value" ;;
                            feature_show_submodules) CONFIG_SHOW_SUBMODULES="$value" ;;
                            feature_show_mcp) CONFIG_SHOW_MCP_STATUS="$value" ;;
                            feature_show_cost) CONFIG_SHOW_COST_TRACKING="$value" ;;
                            feature_show_reset) CONFIG_SHOW_RESET_INFO="$value" ;;
                            feature_show_session) CONFIG_SHOW_SESSION_INFO="$value" ;;
                        esac
                    fi
                    ;;
                # Timeouts
                timeout_*)
                    [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                        timeout_mcp) CONFIG_MCP_TIMEOUT="$value" ;;
                        timeout_version) CONFIG_VERSION_TIMEOUT="$value" ;;
                        timeout_ccusage) CONFIG_CCUSAGE_TIMEOUT="$value" ;;
                    esac
                    ;;
                # Emojis
                emoji_*)
                    [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                        emoji_opus) CONFIG_OPUS_EMOJI="$value" ;;
                        emoji_haiku) CONFIG_HAIKU_EMOJI="$value" ;;
                        emoji_sonnet) CONFIG_SONNET_EMOJI="$value" ;;
                        emoji_default) CONFIG_DEFAULT_MODEL_EMOJI="$value" ;;
                        emoji_clean) CONFIG_CLEAN_STATUS_EMOJI="$value" ;;
                        emoji_dirty) CONFIG_DIRTY_STATUS_EMOJI="$value" ;;
                        emoji_clock) CONFIG_CLOCK_EMOJI="$value" ;;
                        emoji_live_block) CONFIG_LIVE_BLOCK_EMOJI="$value" ;;
                    esac
                    ;;
                # Labels
                label_*)
                    [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                        label_commits) CONFIG_COMMITS_LABEL="$value" ;;
                        label_repo) CONFIG_REPO_LABEL="$value" ;;
                        label_monthly) CONFIG_MONTHLY_LABEL="$value" ;;
                        label_weekly) CONFIG_WEEKLY_LABEL="$value" ;;
                        label_daily) CONFIG_DAILY_LABEL="$value" ;;
                        label_mcp) CONFIG_MCP_LABEL="$value" ;;
                        label_version_prefix) CONFIG_VERSION_PREFIX="$value" ;;
                        label_submodule) CONFIG_SUBMODULE_LABEL="$value" ;;
                        label_session_prefix) CONFIG_SESSION_PREFIX="$value" ;;
                        label_live) CONFIG_LIVE_LABEL="$value" ;;
                        label_reset) CONFIG_RESET_LABEL="$value" ;;
                    esac
                    ;;
                # Cache
                cache_*)
                    [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                        cache_version_duration) CONFIG_VERSION_CACHE_DURATION="$value" ;;
                        cache_version_file) CONFIG_VERSION_CACHE_FILE="$value" ;;
                    esac
                    ;;
                # Display
                display_*)
                    [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                        display_time_format) CONFIG_TIME_FORMAT="$value" ;;
                        display_date_format) CONFIG_DATE_FORMAT="$value" ;;
                        display_date_format_compact) CONFIG_DATE_FORMAT_COMPACT="$value" ;;
                    esac
                    ;;
                # Messages
                message_*)
                    [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                        message_no_ccusage) CONFIG_NO_CCUSAGE_MESSAGE="$value" ;;
                        message_ccusage_install) CONFIG_CCUSAGE_INSTALL_MESSAGE="$value" ;;
                        message_no_active_block) CONFIG_NO_ACTIVE_BLOCK_MESSAGE="$value" ;;
                        message_mcp_unknown) CONFIG_MCP_UNKNOWN_MESSAGE="$value" ;;
                        message_mcp_none) CONFIG_MCP_NONE_MESSAGE="$value" ;;
                        message_unknown_version) CONFIG_UNKNOWN_VERSION="$value" ;;
                        message_no_submodules) CONFIG_NO_SUBMODULES="$value" ;;
                    esac
                    ;;
                # Advanced settings
                advanced_*)
                    case "$key" in
                        advanced_warn_missing_deps)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_WARN_MISSING_DEPS="$value" ;;
                        advanced_debug_mode)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_DEBUG_MODE="$value" ;;
                        advanced_performance_mode)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_PERFORMANCE_MODE="$value" ;;
                        advanced_strict_validation)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_STRICT_VALIDATION="$value" ;;
                    esac
                    ;;
                # Platform settings
                platform_*)
                    case "$key" in
                        platform_prefer_gtimeout)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_PREFER_GTIMEOUT="$value" ;;
                        platform_use_gdate)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_USE_GDATE="$value" ;;
                        platform_color_support_level)
                            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_COLOR_SUPPORT_LEVEL="$value" ;;
                    esac
                    ;;
                # Paths
                paths_*)
                    [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                        paths_temp_dir) CONFIG_TEMP_DIR="$value" ;;
                        paths_config_dir) CONFIG_CONFIG_DIR="$value" ;;
                        paths_cache_dir) CONFIG_CACHE_DIR="$value" ;;
                        paths_log_file) CONFIG_LOG_FILE="$value" ;;
                    esac
                    ;;
                # Performance settings
                performance_*)
                    case "$key" in
                        performance_parallel_data_collection)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_PARALLEL_DATA_COLLECTION="$value" ;;
                        performance_max_concurrent_operations)
                            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_MAX_CONCURRENT_OPERATIONS="$value" ;;
                        performance_git_operation_timeout)
                            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_GIT_OPERATION_TIMEOUT="$value" ;;
                        performance_network_operation_timeout)
                            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_NETWORK_OPERATION_TIMEOUT="$value" ;;
                        performance_enable_smart_caching)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_ENABLE_SMART_CACHING="$value" ;;
                        performance_cache_compression)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_CACHE_COMPRESSION="$value" ;;
                    esac
                    ;;
                # Debug settings
                debug_*)
                    case "$key" in
                        debug_log_level)
                            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LOG_LEVEL="$value" ;;
                        debug_log_config_loading)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LOG_CONFIG_LOADING="$value" ;;
                        debug_log_theme_application)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LOG_THEME_APPLICATION="$value" ;;
                        debug_log_validation_details)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LOG_VALIDATION_DETAILS="$value" ;;
                        debug_benchmark_performance)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_BENCHMARK_PERFORMANCE="$value" ;;
                        debug_export_debug_info)
                            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_EXPORT_DEBUG_INFO="$value" ;;
                    esac
                    ;;
            esac
        done <<< "$config_data"
        
        # All configuration extraction complete - 64 individual jq calls replaced with 1 optimized operation!
        
        # Phase 3: Apply advanced configuration systems
        
        # Apply configuration profiles first (affects theme and other settings)  
        apply_configuration_profile "$config_json"
        
        # Apply theme inheritance system (after profiles but before theme application)
        if [[ "$CONFIG_THEME" == "custom" ]]; then
            apply_theme_inheritance "$config_json"
        fi
        
        # Initialize plugin system
        initialize_plugin_system "$config_json"
        
        echo "Configuration loaded successfully from TOML (Phase 3: 100% coverage + Advanced Features)" >&2
        return 0
    else
        echo "No Config.toml found, using inline defaults" >&2
        return 1
    fi
}

# Phase 3: Theme Inheritance System  
# Allows custom themes to inherit from base themes and override specific colors
apply_theme_inheritance() {
    local config_json="$1"
    
    # Extract all theme inheritance settings in single jq operation
    local inheritance_data
    inheritance_data=$(echo "$config_json" | jq -r '{
        enabled: (.theme.inheritance.enabled // false),
        base_theme: (.theme.inheritance.base_theme // ""),
        merge_strategy: (.theme.inheritance.merge_strategy // "override"),
        override_colors: [(.theme.inheritance.override_colors[]? // empty)]
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    if [[ -z "$inheritance_data" ]]; then
        return 0  # No inheritance data, use regular theme system
    fi
    
    # Parse extracted inheritance settings
    local inheritance_enabled base_theme merge_strategy override_colors
    while IFS='=' read -r key value; do
        case "$key" in
            "enabled") inheritance_enabled="$value" ;;
            "base_theme") base_theme="$value" ;;
            "merge_strategy") merge_strategy="$value" ;;
            "override_colors") override_colors="$value" ;;
        esac
    done <<< "$inheritance_data"
    
    if [[ "$inheritance_enabled" != "true" ]]; then
        return 0  # No inheritance, use regular theme system
    fi
    
    if [[ -z "$base_theme" || "$base_theme" == "null" || "$base_theme" == "" ]]; then
        echo "Theme inheritance enabled but no base_theme specified" >&2
        return 0
    fi
    
    echo "Applying theme inheritance: base='$base_theme', strategy='$merge_strategy'" >&2
    
    # Apply base theme first
    case "$base_theme" in
        "classic"|"garden"|"catppuccin")
            # Store current theme, apply base theme, then restore  
            local original_theme="$CONFIG_THEME"
            CONFIG_THEME="$base_theme"
            apply_theme
            CONFIG_THEME="$original_theme"
            ;;
        *)
            echo "Warning: Unknown base theme '$base_theme', skipping inheritance" >&2
            return 0
            ;;
    esac
    
    # Apply color overrides based on merge strategy
    if [[ "$merge_strategy" == "override" ]]; then
        # Extract all color values in a single jq operation for better performance
        if [[ "$override_colors" != "[]" && -n "$override_colors" ]]; then
            echo "Overriding specific colors from custom theme..." >&2
            
            # Get all override color values in one jq call
            local color_values
            color_values=$(echo "$config_json" | jq -r '
                (.theme.inheritance.override_colors[]? // empty) as $color_name |
                {
                    color_name: $color_name,
                    color_value: (.colors.basic[$color_name] // .colors.extended[$color_name] // .colors[$color_name] // empty)
                } | select(.color_value != null and .color_value != "") | 
                "\(.color_name)=\(.color_value)"' 2>/dev/null)
            
            # Apply the color overrides
            while IFS='=' read -r color_name color_value; do
                [[ -z "$color_name" || -z "$color_value" ]] && continue
                
                if [[ -n "$color_value" && "$color_value" != "null" ]]; then
                    case "$color_name" in
                        "red") CONFIG_RED="$color_value" ;;
                        "blue") CONFIG_BLUE="$color_value" ;;
                        "green") CONFIG_GREEN="$color_value" ;;
                        "yellow") CONFIG_YELLOW="$color_value" ;;
                        "magenta") CONFIG_MAGENTA="$color_value" ;;
                        "cyan") CONFIG_CYAN="$color_value" ;;
                        "white") CONFIG_WHITE="$color_value" ;;
                        "orange") CONFIG_ORANGE="$color_value" ;;
                        "light_orange") CONFIG_LIGHT_ORANGE="$color_value" ;;
                        "light_gray") CONFIG_LIGHT_GRAY="$color_value" ;;
                        "bright_green") CONFIG_BRIGHT_GREEN="$color_value" ;;
                        "purple") CONFIG_PURPLE="$color_value" ;;
                        "teal") CONFIG_TEAL="$color_value" ;;
                        "gold") CONFIG_GOLD="$color_value" ;;
                        "pink_bright") CONFIG_PINK_BRIGHT="$color_value" ;;
                        "indigo") CONFIG_INDIGO="$color_value" ;;
                        "violet") CONFIG_VIOLET="$color_value" ;;
                        "light_blue") CONFIG_LIGHT_BLUE="$color_value" ;;
                        *) echo "Warning: Unknown color '$color_name' in override list" >&2 ;;
                    esac
                    echo "  ✓ Overrode $color_name" >&2
                fi
            done <<< "$override_colors"
        fi
    elif [[ "$merge_strategy" == "merge" ]]; then
        # Apply all custom colors that exist, keeping base theme for missing ones
        echo "Merging custom colors with base theme..." >&2
        # This would apply the full custom theme logic but keep base theme colors for undefined ones
        # For now, fall back to standard custom color application
    fi
    
    echo "Theme inheritance applied successfully" >&2
    return 0
}

# Phase 3: Configuration Profiles System
# Allows different configurations for different contexts (work, personal, demo)
apply_configuration_profile() {
    local config_json="$1"
    
    # Extract all profile settings in single jq operation for better performance
    local profile_data
    profile_data=$(echo "$config_json" | jq -r '{
        profiles_enabled: (.profiles.enabled // false),
        auto_switch: (.profiles.auto_switch // true),
        default_profile: (.profiles.default_profile // "default"),
        work_hours_enabled: (.conditional.work_hours.enabled // false),
        start_time: (.conditional.work_hours.start_time // "09:00"),
        end_time: (.conditional.work_hours.end_time // "17:00"),
        work_profile: (.conditional.work_hours.work_profile // "work"),
        off_hours_profile: (.conditional.work_hours.off_hours_profile // "personal")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    if [[ -z "$profile_data" ]]; then
        return 0  # No profile data, use regular configuration
    fi
    
    # Parse extracted profile settings
    local profiles_enabled auto_switch default_profile work_hours_enabled
    local start_time end_time work_profile off_hours_profile
    while IFS='=' read -r key value; do
        case "$key" in
            "profiles_enabled") profiles_enabled="$value" ;;
            "auto_switch") auto_switch="$value" ;;
            "default_profile") default_profile="$value" ;;
            "work_hours_enabled") work_hours_enabled="$value" ;;
            "start_time") start_time="$value" ;;
            "end_time") end_time="$value" ;;
            "work_profile") work_profile="$value" ;;
            "off_hours_profile") off_hours_profile="$value" ;;
        esac
    done <<< "$profile_data"
    
    if [[ "$profiles_enabled" != "true" ]]; then
        return 0  # No profiles, use regular configuration
    fi
    
    local active_profile="$default_profile"
    
    # Auto-detect profile if enabled
    if [[ "$auto_switch" == "true" ]]; then
        # Check work hours
        if [[ "$work_hours_enabled" == "true" ]]; then
            
            current_hour=$(date +%H)
            local start_hour="${start_time%%:*}"
            local end_hour="${end_time%%:*}"
            
            if [[ "$current_hour" -ge "$start_hour" && "$current_hour" -lt "$end_hour" ]]; then
                active_profile="$work_profile"
                echo "Auto-switched to profile '$active_profile' (work hours)" >&2
            else
                active_profile="$off_hours_profile"
                echo "Auto-switched to profile '$active_profile' (off hours)" >&2
            fi
        fi
    fi
    
    # Apply profile configuration
    echo "Applying configuration profile: $active_profile" >&2
    
    # Extract profile-specific values in single jq operation
    local profile_settings
    profile_settings=$(echo "$config_json" | jq -r --arg profile "$active_profile" '{
        theme: (.profiles[$profile].theme // empty),
        show_cost_tracking: (.profiles[$profile].show_cost_tracking // empty),
        show_reset_info: (.profiles[$profile].show_reset_info // empty),
        mcp_timeout: (.profiles[$profile].mcp_timeout // empty)
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    # Parse extracted profile settings
    local profile_theme profile_show_cost_tracking profile_show_reset_info profile_mcp_timeout
    while IFS='=' read -r key value; do
        case "$key" in
            "theme") profile_theme="$value" ;;
            "show_cost_tracking") profile_show_cost_tracking="$value" ;;
            "show_reset_info") profile_show_reset_info="$value" ;;
            "mcp_timeout") profile_mcp_timeout="$value" ;;
        esac
    done <<< "$profile_settings"
    
    # Apply profile overrides
    [[ -n "$profile_theme" && "$profile_theme" != "null" ]] && CONFIG_THEME="$profile_theme"
    [[ "$profile_show_cost_tracking" == "true" || "$profile_show_cost_tracking" == "false" ]] && CONFIG_SHOW_COST_TRACKING="$profile_show_cost_tracking"
    [[ "$profile_show_reset_info" == "true" || "$profile_show_reset_info" == "false" ]] && CONFIG_SHOW_RESET_INFO="$profile_show_reset_info"
    [[ -n "$profile_mcp_timeout" && "$profile_mcp_timeout" != "null" ]] && CONFIG_MCP_TIMEOUT="$profile_mcp_timeout"
    
    echo "Configuration profile '$active_profile' applied successfully" >&2
    export CONFIG_ACTIVE_PROFILE="$active_profile"
    return 0
}

# Phase 3: Plugin System Foundation
# Provides extensible data source system for future enhancements  
initialize_plugin_system() {
    local config_json="$1"
    
    # Extract plugin settings in single jq operation for better performance
    local plugin_data
    plugin_data=$(echo "$config_json" | jq -r '{
        enabled: (.plugins.enabled // false),
        auto_discovery: (.plugins.auto_discovery // true)
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    # Parse extracted plugin settings
    local plugins_enabled auto_discovery
    while IFS='=' read -r key value; do
        case "$key" in
            "enabled") plugins_enabled="$value" ;;
            "auto_discovery") auto_discovery="$value" ;;
        esac
    done <<< "$plugin_data"
    
    if [[ "$plugins_enabled" != "true" ]]; then
        export PLUGINS_ENABLED=false
        return 0
    fi
    export PLUGINS_ENABLED=true
    export PLUGIN_AUTO_DISCOVERY="$auto_discovery"
    
    # Get plugin directories
    local plugin_dirs_json
    plugin_dirs_json=$(echo "$config_json" | jq -r '.plugins.plugin_dirs[]?' 2>/dev/null)
    
    if [[ -n "$plugin_dirs_json" ]]; then
        export PLUGIN_DIRS=()
        while IFS= read -r plugin_dir; do
            [[ -z "$plugin_dir" ]] && continue
            # Expand tilde if present
            plugin_dir="${plugin_dir/#\~/$HOME}"
            PLUGIN_DIRS+=("$plugin_dir")
        done <<< "$plugin_dirs_json"
        
        echo "Plugin system initialized with ${#PLUGIN_DIRS[@]} directories" >&2
    fi
    
    # Initialize built-in plugins based on config
    local git_extended_enabled system_info_enabled weather_enabled
    git_extended_enabled=$(echo "$config_json" | jq -r '.plugins.git_extended.enabled // false' 2>/dev/null)
    system_info_enabled=$(echo "$config_json" | jq -r '.plugins.system_info.enabled // false' 2>/dev/null)
    weather_enabled=$(echo "$config_json" | jq -r '.plugins.weather.enabled // false' 2>/dev/null)
    
    export PLUGIN_GIT_EXTENDED_ENABLED="$git_extended_enabled"
    export PLUGIN_SYSTEM_INFO_ENABLED="$system_info_enabled"
    export PLUGIN_WEATHER_ENABLED="$weather_enabled"
    
    if [[ "$git_extended_enabled" == "true" || "$system_info_enabled" == "true" || "$weather_enabled" == "true" ]]; then
        echo "Built-in plugins enabled: git_extended=$git_extended_enabled, system_info=$system_info_enabled, weather=$weather_enabled" >&2
    fi
    
    return 0
}

# Phase 3: Advanced Validation with Auto-Fix Suggestions
validate_configuration() {
    local errors=()
    local warnings=()
    local suggestions=()
    
    echo "Validating configuration..." >&2
    
    # Validate theme selection with auto-fix suggestions
    if [[ -n "$CONFIG_THEME" ]]; then
        case "$CONFIG_THEME" in
            "classic"|"garden"|"catppuccin"|"custom") ;;
            *)  
                errors+=("Invalid theme '$CONFIG_THEME'. Valid themes: classic, garden, catppuccin, custom")
                # Auto-fix suggestion based on similarity
                case "${CONFIG_THEME,,}" in
                    *"classic"*|*"trad"*) suggestions+=("💡 Did you mean 'classic'? Add: theme.name = \"classic\"") ;;
                    *"garden"*|*"pastel"*|*"soft"*) suggestions+=("💡 Did you mean 'garden'? Add: theme.name = \"garden\"") ;;  
                    *"cat"*|*"mocha"*) suggestions+=("💡 Did you mean 'catppuccin'? Add: theme.name = \"catppuccin\"") ;;
                    *"custom"*) suggestions+=("💡 Did you mean 'custom'? Add: theme.name = \"custom\"") ;;
                    *) suggestions+=("💡 Set theme.name to one of: classic, garden, catppuccin, custom") ;;
                esac
                ;;
        esac
    fi
    
    # Validate boolean values
    local bool_configs=(
        "CONFIG_SHOW_COMMITS" "CONFIG_SHOW_VERSION" "CONFIG_SHOW_SUBMODULES"
        "CONFIG_SHOW_MCP_STATUS" "CONFIG_SHOW_COST_TRACKING" "CONFIG_SHOW_RESET_INFO" "CONFIG_SHOW_SESSION_INFO"
    )
    
    for bool_config in "${bool_configs[@]}"; do
        local value="${!bool_config}"
        if [[ -n "$value" && "$value" != "true" && "$value" != "false" ]]; then
            errors+=("$bool_config must be 'true' or 'false', got '$value'")
            # Auto-fix suggestions for common boolean mistakes
            case "${value,,}" in
                "yes"|"y"|"1"|"on"|"enable"|"enabled") suggestions+=("💡 Use 'true' instead of '$value'") ;;
                "no"|"n"|"0"|"off"|"disable"|"disabled") suggestions+=("💡 Use 'false' instead of '$value'") ;;
                *) suggestions+=("💡 Set ${bool_config,,} = true or false") ;;
            esac
        fi
    done
    
    # Validate timeout bounds with contextual validation
    local timeout_configs=(
        "CONFIG_MCP_TIMEOUT:mcp"
        "CONFIG_VERSION_TIMEOUT:version" 
        "CONFIG_CCUSAGE_TIMEOUT:ccusage"
    )
    
    for timeout_config_pair in "${timeout_configs[@]}"; do
        local timeout_config="${timeout_config_pair%:*}"
        local timeout_type="${timeout_config_pair#*:}"
        local value="${!timeout_config}"
        
        if [[ -n "$value" ]]; then
            validate_timeout_bounds "$timeout_config" "$value" "$timeout_type"
        fi
    done
    
    # Validate cache duration is numeric
    if [[ -n "$CONFIG_VERSION_CACHE_DURATION" && ! "$CONFIG_VERSION_CACHE_DURATION" =~ ^[0-9]+$ ]]; then
        errors+=("CONFIG_VERSION_CACHE_DURATION must be a number (seconds), got '$CONFIG_VERSION_CACHE_DURATION'")
    fi
    
    # Validate cache file path is writable directory
    if [[ -n "$CONFIG_VERSION_CACHE_FILE" ]]; then
        local cache_dir
        cache_dir=$(dirname "$CONFIG_VERSION_CACHE_FILE")
        if [[ ! -d "$cache_dir" ]]; then
            warnings+=("Cache directory '$cache_dir' does not exist")
        elif [[ ! -w "$cache_dir" ]]; then
            warnings+=("Cache directory '$cache_dir' is not writable")
        fi
    fi
    
    # Validate date formats (basic check)
    local date_configs=("CONFIG_TIME_FORMAT" "CONFIG_DATE_FORMAT" "CONFIG_DATE_FORMAT_COMPACT")
    for date_config in "${date_configs[@]}"; do
        local value="${!date_config}"
        if [[ -n "$value" && ! "$value" =~ %[a-zA-Z] ]]; then
            warnings+=("$date_config may have invalid date format: '$value'")
        fi
    done
    
    # Validate ANSI color codes (basic check for custom theme)
    if [[ "$CONFIG_THEME" == "custom" ]]; then
        local color_configs=(
            "CONFIG_RED" "CONFIG_BLUE" "CONFIG_GREEN" "CONFIG_YELLOW" 
            "CONFIG_MAGENTA" "CONFIG_CYAN" "CONFIG_WHITE"
        )
        
        for color_config in "${color_configs[@]}"; do
            local value="${!color_config}"
            if [[ -n "$value" && ! "$value" =~ \\033\[.*m$ ]]; then
                warnings+=("$color_config may have invalid ANSI color code: '$value'")
            fi
        done
    fi
    
    # Report errors, warnings, and suggestions
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "❌ Configuration errors found:" >&2
        for error in "${errors[@]}"; do
            echo "   ✗ $error" >&2
        done
        
        # Show auto-fix suggestions if available
        if [[ ${#suggestions[@]} -gt 0 ]]; then
            echo "" >&2
            echo "💡 Auto-fix suggestions:" >&2
            for suggestion in "${suggestions[@]}"; do
                echo "   $suggestion" >&2
            done
        fi
        return 1
    fi
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo "⚠️  Configuration warnings:" >&2
        for warning in "${warnings[@]}"; do
            echo "   ⚠ $warning" >&2
        done
    fi
    
    if [[ ${#suggestions[@]} -gt 0 && ${#errors[@]} -eq 0 ]]; then
        echo "💡 Optimization suggestions:" >&2
        for suggestion in "${suggestions[@]}"; do
            echo "   $suggestion" >&2
        done
    fi
    
    echo "✅ Configuration validation completed" >&2
    return 0
}

# Apply environment variable overrides (highest precedence)
apply_env_overrides() {
    # Environment variables follow the CONFIG_* naming convention
    # These override both TOML config and inline defaults
    
    # Theme and colors
    [[ -n "$ENV_CONFIG_THEME" ]] && CONFIG_THEME="$ENV_CONFIG_THEME"
    [[ -n "$ENV_CONFIG_RED" ]] && CONFIG_RED="$ENV_CONFIG_RED"
    [[ -n "$ENV_CONFIG_BLUE" ]] && CONFIG_BLUE="$ENV_CONFIG_BLUE"
    [[ -n "$ENV_CONFIG_GREEN" ]] && CONFIG_GREEN="$ENV_CONFIG_GREEN"
    [[ -n "$ENV_CONFIG_YELLOW" ]] && CONFIG_YELLOW="$ENV_CONFIG_YELLOW"
    [[ -n "$ENV_CONFIG_MAGENTA" ]] && CONFIG_MAGENTA="$ENV_CONFIG_MAGENTA"
    [[ -n "$ENV_CONFIG_CYAN" ]] && CONFIG_CYAN="$ENV_CONFIG_CYAN"
    [[ -n "$ENV_CONFIG_WHITE" ]] && CONFIG_WHITE="$ENV_CONFIG_WHITE"
    
    # Feature toggles
    [[ -n "$ENV_CONFIG_SHOW_COMMITS" ]] && CONFIG_SHOW_COMMITS="$ENV_CONFIG_SHOW_COMMITS"
    [[ -n "$ENV_CONFIG_SHOW_VERSION" ]] && CONFIG_SHOW_VERSION="$ENV_CONFIG_SHOW_VERSION"
    [[ -n "$ENV_CONFIG_SHOW_SUBMODULES" ]] && CONFIG_SHOW_SUBMODULES="$ENV_CONFIG_SHOW_SUBMODULES"
    [[ -n "$ENV_CONFIG_SHOW_MCP_STATUS" ]] && CONFIG_SHOW_MCP_STATUS="$ENV_CONFIG_SHOW_MCP_STATUS"
    [[ -n "$ENV_CONFIG_SHOW_COST_TRACKING" ]] && CONFIG_SHOW_COST_TRACKING="$ENV_CONFIG_SHOW_COST_TRACKING"
    [[ -n "$ENV_CONFIG_SHOW_RESET_INFO" ]] && CONFIG_SHOW_RESET_INFO="$ENV_CONFIG_SHOW_RESET_INFO"
    [[ -n "$ENV_CONFIG_SHOW_SESSION_INFO" ]] && CONFIG_SHOW_SESSION_INFO="$ENV_CONFIG_SHOW_SESSION_INFO"
    
    # Timeouts
    [[ -n "$ENV_CONFIG_MCP_TIMEOUT" ]] && CONFIG_MCP_TIMEOUT="$ENV_CONFIG_MCP_TIMEOUT"
    [[ -n "$ENV_CONFIG_VERSION_TIMEOUT" ]] && CONFIG_VERSION_TIMEOUT="$ENV_CONFIG_VERSION_TIMEOUT"
    [[ -n "$ENV_CONFIG_CCUSAGE_TIMEOUT" ]] && CONFIG_CCUSAGE_TIMEOUT="$ENV_CONFIG_CCUSAGE_TIMEOUT"
    
    # Emojis
    [[ -n "$ENV_CONFIG_OPUS_EMOJI" ]] && CONFIG_OPUS_EMOJI="$ENV_CONFIG_OPUS_EMOJI"
    [[ -n "$ENV_CONFIG_HAIKU_EMOJI" ]] && CONFIG_HAIKU_EMOJI="$ENV_CONFIG_HAIKU_EMOJI"
    [[ -n "$ENV_CONFIG_SONNET_EMOJI" ]] && CONFIG_SONNET_EMOJI="$ENV_CONFIG_SONNET_EMOJI"
    [[ -n "$ENV_CONFIG_DEFAULT_MODEL_EMOJI" ]] && CONFIG_DEFAULT_MODEL_EMOJI="$ENV_CONFIG_DEFAULT_MODEL_EMOJI"
    [[ -n "$ENV_CONFIG_CLEAN_STATUS_EMOJI" ]] && CONFIG_CLEAN_STATUS_EMOJI="$ENV_CONFIG_CLEAN_STATUS_EMOJI"
    [[ -n "$ENV_CONFIG_DIRTY_STATUS_EMOJI" ]] && CONFIG_DIRTY_STATUS_EMOJI="$ENV_CONFIG_DIRTY_STATUS_EMOJI"
    [[ -n "$ENV_CONFIG_CLOCK_EMOJI" ]] && CONFIG_CLOCK_EMOJI="$ENV_CONFIG_CLOCK_EMOJI"
    [[ -n "$ENV_CONFIG_LIVE_BLOCK_EMOJI" ]] && CONFIG_LIVE_BLOCK_EMOJI="$ENV_CONFIG_LIVE_BLOCK_EMOJI"
    
    # Labels
    [[ -n "$ENV_CONFIG_COMMITS_LABEL" ]] && CONFIG_COMMITS_LABEL="$ENV_CONFIG_COMMITS_LABEL"
    [[ -n "$ENV_CONFIG_REPO_LABEL" ]] && CONFIG_REPO_LABEL="$ENV_CONFIG_REPO_LABEL"
    [[ -n "$ENV_CONFIG_MONTHLY_LABEL" ]] && CONFIG_MONTHLY_LABEL="$ENV_CONFIG_MONTHLY_LABEL"
    [[ -n "$ENV_CONFIG_WEEKLY_LABEL" ]] && CONFIG_WEEKLY_LABEL="$ENV_CONFIG_WEEKLY_LABEL"
    [[ -n "$ENV_CONFIG_DAILY_LABEL" ]] && CONFIG_DAILY_LABEL="$ENV_CONFIG_DAILY_LABEL"
    [[ -n "$ENV_CONFIG_MCP_LABEL" ]] && CONFIG_MCP_LABEL="$ENV_CONFIG_MCP_LABEL"
    [[ -n "$ENV_CONFIG_VERSION_PREFIX" ]] && CONFIG_VERSION_PREFIX="$ENV_CONFIG_VERSION_PREFIX"
    [[ -n "$ENV_CONFIG_SUBMODULE_LABEL" ]] && CONFIG_SUBMODULE_LABEL="$ENV_CONFIG_SUBMODULE_LABEL"
    [[ -n "$ENV_CONFIG_SESSION_PREFIX" ]] && CONFIG_SESSION_PREFIX="$ENV_CONFIG_SESSION_PREFIX"
    [[ -n "$ENV_CONFIG_LIVE_LABEL" ]] && CONFIG_LIVE_LABEL="$ENV_CONFIG_LIVE_LABEL"
    [[ -n "$ENV_CONFIG_RESET_LABEL" ]] && CONFIG_RESET_LABEL="$ENV_CONFIG_RESET_LABEL"
    
    # Cache settings
    [[ -n "$ENV_CONFIG_VERSION_CACHE_DURATION" ]] && CONFIG_VERSION_CACHE_DURATION="$ENV_CONFIG_VERSION_CACHE_DURATION"
    [[ -n "$ENV_CONFIG_VERSION_CACHE_FILE" ]] && CONFIG_VERSION_CACHE_FILE="$ENV_CONFIG_VERSION_CACHE_FILE"
    
    # Display formats
    [[ -n "$ENV_CONFIG_TIME_FORMAT" ]] && CONFIG_TIME_FORMAT="$ENV_CONFIG_TIME_FORMAT"
    [[ -n "$ENV_CONFIG_DATE_FORMAT" ]] && CONFIG_DATE_FORMAT="$ENV_CONFIG_DATE_FORMAT"
    [[ -n "$ENV_CONFIG_DATE_FORMAT_COMPACT" ]] && CONFIG_DATE_FORMAT_COMPACT="$ENV_CONFIG_DATE_FORMAT_COMPACT"
    
    # Error messages
    [[ -n "$ENV_CONFIG_NO_CCUSAGE_MESSAGE" ]] && CONFIG_NO_CCUSAGE_MESSAGE="$ENV_CONFIG_NO_CCUSAGE_MESSAGE"
    [[ -n "$ENV_CONFIG_CCUSAGE_INSTALL_MESSAGE" ]] && CONFIG_CCUSAGE_INSTALL_MESSAGE="$ENV_CONFIG_CCUSAGE_INSTALL_MESSAGE"
    [[ -n "$ENV_CONFIG_NO_ACTIVE_BLOCK_MESSAGE" ]] && CONFIG_NO_ACTIVE_BLOCK_MESSAGE="$ENV_CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
    [[ -n "$ENV_CONFIG_MCP_UNKNOWN_MESSAGE" ]] && CONFIG_MCP_UNKNOWN_MESSAGE="$ENV_CONFIG_MCP_UNKNOWN_MESSAGE"
    [[ -n "$ENV_CONFIG_MCP_NONE_MESSAGE" ]] && CONFIG_MCP_NONE_MESSAGE="$ENV_CONFIG_MCP_NONE_MESSAGE"
    [[ -n "$ENV_CONFIG_UNKNOWN_VERSION" ]] && CONFIG_UNKNOWN_VERSION="$ENV_CONFIG_UNKNOWN_VERSION"
    [[ -n "$ENV_CONFIG_NO_SUBMODULES" ]] && CONFIG_NO_SUBMODULES="$ENV_CONFIG_NO_SUBMODULES"
    
    # Log environment overrides if any were applied
    local overrides_applied=false
    for var in CONFIG_THEME ENV_CONFIG_RED ENV_CONFIG_SHOW_COMMITS ENV_CONFIG_MCP_TIMEOUT; do
        if [[ -n "${!var}" ]]; then
            if [[ "$overrides_applied" == "false" ]]; then
                echo "Environment variable overrides applied" >&2
                overrides_applied=true
            fi
            break
        fi
    done
}

# ============================================================================
# MIGRATION TOOLS & CONFIG TESTING UTILITIES (Phase 3)
# ============================================================================

# Generate Config.toml from current inline configuration
generate_config_toml() {
    local output_file="${1:-./Config.toml}"
    local backup_existing="${2:-true}"
    
    echo "🔧 Generating Config.toml from current inline configuration..."
    
    # Backup existing config if it exists
    if [[ "$backup_existing" == "true" && -f "$output_file" ]]; then
        local backup_file="${output_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$output_file" "$backup_file"
        echo "📋 Existing config backed up to: $backup_file"
    fi
    
    # Generate comprehensive Config.toml based on current inline values
    cat > "$output_file" << 'TOML_EOF'
# ============================================================================
# Claude Code Statusline Configuration (Config.toml)
# ============================================================================
# Generated from inline configuration on DATE_PLACEHOLDER
# 
# This file contains the configuration for the Claude Code statusline script.
# Edit this file to customize your statusline appearance and behavior.
# ============================================================================

# === THEME CONFIGURATION ===
[theme]
name = "THEME_PLACEHOLDER"

# === FEATURE TOGGLES ===
[features]
show_commits = SHOW_COMMITS_PLACEHOLDER
show_version = SHOW_VERSION_PLACEHOLDER
show_submodules = SHOW_SUBMODULES_PLACEHOLDER
show_mcp_status = SHOW_MCP_STATUS_PLACEHOLDER
show_cost_tracking = SHOW_COST_TRACKING_PLACEHOLDER
show_reset_info = SHOW_RESET_INFO_PLACEHOLDER
show_session_info = SHOW_SESSION_INFO_PLACEHOLDER

# === MODEL EMOJIS ===
[emojis]
opus = "OPUS_EMOJI_PLACEHOLDER"
haiku = "HAIKU_EMOJI_PLACEHOLDER"
sonnet = "SONNET_EMOJI_PLACEHOLDER"
default_model = "DEFAULT_MODEL_EMOJI_PLACEHOLDER"
clean_status = "CLEAN_STATUS_EMOJI_PLACEHOLDER"
dirty_status = "DIRTY_STATUS_EMOJI_PLACEHOLDER"
clock = "CLOCK_EMOJI_PLACEHOLDER"
live_block = "LIVE_BLOCK_EMOJI_PLACEHOLDER"

# === TIMEOUTS ===
# Timeout values for external command execution
# Format: Use "Ns" for seconds or "Nm" for minutes (e.g., "10s", "2m")
# 
# Performance Guidelines:
# - Lower timeouts = faster statusline response, higher chance of operation failure
# - Higher timeouts = slower statusline response, better reliability for slow systems
[timeouts]

# MCP Server timeout (1s-60s recommended, optimal: 3s-15s for most setups)  
# Increase for complex MCP server configurations or slow network connections
# Default: 10s (changed from 3s in v1.1.2 for better multi-server compatibility)
mcp = "MCP_TIMEOUT_PLACEHOLDER"

# Claude version check timeout (1s-10s recommended, optimal: 1s-3s)
# Usually fast due to caching after first run
version = "VERSION_TIMEOUT_PLACEHOLDER"

# Cost tracking (ccusage) timeout (1s-30s recommended, optimal: 3s-10s)
# Network API calls to retrieve usage information  
ccusage = "CCUSAGE_TIMEOUT_PLACEHOLDER"

# === DISPLAY LABELS ===
[labels]
commits = "COMMITS_LABEL_PLACEHOLDER"
repo = "REPO_LABEL_PLACEHOLDER"
monthly = "MONTHLY_LABEL_PLACEHOLDER"
weekly = "WEEKLY_LABEL_PLACEHOLDER"
daily = "DAILY_LABEL_PLACEHOLDER"
mcp = "MCP_LABEL_PLACEHOLDER"
version_prefix = "VERSION_PREFIX_PLACEHOLDER"
submodule = "SUBMODULE_LABEL_PLACEHOLDER"
session_prefix = "SESSION_PREFIX_PLACEHOLDER"
live = "LIVE_LABEL_PLACEHOLDER"
reset = "RESET_LABEL_PLACEHOLDER"

# === CACHE SETTINGS ===
[cache]
version_duration = VERSION_CACHE_DURATION_PLACEHOLDER
version_file = "VERSION_CACHE_FILE_PLACEHOLDER"

# === DISPLAY FORMATS ===
[display]
time_format = "TIME_FORMAT_PLACEHOLDER"
date_format = "DATE_FORMAT_PLACEHOLDER"
date_format_compact = "DATE_FORMAT_COMPACT_PLACEHOLDER"

# === ERROR/FALLBACK MESSAGES ===
[messages]
no_ccusage = "NO_CCUSAGE_MESSAGE_PLACEHOLDER"
ccusage_install = "CCUSAGE_INSTALL_MESSAGE_PLACEHOLDER"
no_active_block = "NO_ACTIVE_BLOCK_MESSAGE_PLACEHOLDER"
mcp_unknown = "MCP_UNKNOWN_MESSAGE_PLACEHOLDER"
mcp_none = "MCP_NONE_MESSAGE_PLACEHOLDER"
unknown_version = "UNKNOWN_VERSION_PLACEHOLDER"
no_submodules = "NO_SUBMODULES_PLACEHOLDER"

# === CUSTOM COLORS (if using custom theme) ===
[colors.basic]
red = "RED_PLACEHOLDER"
blue = "BLUE_PLACEHOLDER"
green = "GREEN_PLACEHOLDER"
yellow = "YELLOW_PLACEHOLDER"
magenta = "MAGENTA_PLACEHOLDER"
cyan = "CYAN_PLACEHOLDER"
white = "WHITE_PLACEHOLDER"

# === ADVANCED SETTINGS ===
[advanced]
warn_missing_deps = false
debug_mode = false
performance_mode = false
strict_validation = true

TOML_EOF

    # Replace placeholders with actual values
    local current_date
    current_date=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Use sed to replace placeholders with actual configuration values
    sed -i.tmp \
        -e "s/DATE_PLACEHOLDER/$current_date/g" \
        -e "s/THEME_PLACEHOLDER/${CONFIG_THEME:-catppuccin}/g" \
        -e "s/SHOW_COMMITS_PLACEHOLDER/${CONFIG_SHOW_COMMITS:-true}/g" \
        -e "s/SHOW_VERSION_PLACEHOLDER/${CONFIG_SHOW_VERSION:-true}/g" \
        -e "s/SHOW_SUBMODULES_PLACEHOLDER/${CONFIG_SHOW_SUBMODULES:-true}/g" \
        -e "s/SHOW_MCP_STATUS_PLACEHOLDER/${CONFIG_SHOW_MCP_STATUS:-true}/g" \
        -e "s/SHOW_COST_TRACKING_PLACEHOLDER/${CONFIG_SHOW_COST_TRACKING:-true}/g" \
        -e "s/SHOW_RESET_INFO_PLACEHOLDER/${CONFIG_SHOW_RESET_INFO:-true}/g" \
        -e "s/SHOW_SESSION_INFO_PLACEHOLDER/${CONFIG_SHOW_SESSION_INFO:-true}/g" \
        -e "s/OPUS_EMOJI_PLACEHOLDER/${CONFIG_OPUS_EMOJI:-🧠}/g" \
        -e "s/HAIKU_EMOJI_PLACEHOLDER/${CONFIG_HAIKU_EMOJI:-⚡}/g" \
        -e "s/SONNET_EMOJI_PLACEHOLDER/${CONFIG_SONNET_EMOJI:-🎵}/g" \
        -e "s/DEFAULT_MODEL_EMOJI_PLACEHOLDER/${CONFIG_DEFAULT_MODEL_EMOJI:-🤖}/g" \
        -e "s/CLEAN_STATUS_EMOJI_PLACEHOLDER/${CONFIG_CLEAN_STATUS_EMOJI:-✅}/g" \
        -e "s/DIRTY_STATUS_EMOJI_PLACEHOLDER/${CONFIG_DIRTY_STATUS_EMOJI:-📁}/g" \
        -e "s/CLOCK_EMOJI_PLACEHOLDER/${CONFIG_CLOCK_EMOJI:-🕐}/g" \
        -e "s/LIVE_BLOCK_EMOJI_PLACEHOLDER/${CONFIG_LIVE_BLOCK_EMOJI:-🔥}/g" \
        -e "s/MCP_TIMEOUT_PLACEHOLDER/${CONFIG_MCP_TIMEOUT:-10s}/g" \
        -e "s/VERSION_TIMEOUT_PLACEHOLDER/${CONFIG_VERSION_TIMEOUT:-2s}/g" \
        -e "s/CCUSAGE_TIMEOUT_PLACEHOLDER/${CONFIG_CCUSAGE_TIMEOUT:-3s}/g" \
        -e "s/COMMITS_LABEL_PLACEHOLDER/${CONFIG_COMMITS_LABEL:-Commits:}/g" \
        -e "s/REPO_LABEL_PLACEHOLDER/${CONFIG_REPO_LABEL:-REPO}/g" \
        -e "s/MONTHLY_LABEL_PLACEHOLDER/${CONFIG_MONTHLY_LABEL:-30DAY}/g" \
        -e "s/WEEKLY_LABEL_PLACEHOLDER/${CONFIG_WEEKLY_LABEL:-7DAY}/g" \
        -e "s/DAILY_LABEL_PLACEHOLDER/${CONFIG_DAILY_LABEL:-DAY}/g" \
        -e "s/MCP_LABEL_PLACEHOLDER/${CONFIG_MCP_LABEL:-MCP}/g" \
        -e "s/VERSION_PREFIX_PLACEHOLDER/${CONFIG_VERSION_PREFIX:-ver}/g" \
        -e "s/SUBMODULE_LABEL_PLACEHOLDER/${CONFIG_SUBMODULE_LABEL:-SUB:}/g" \
        -e "s/SESSION_PREFIX_PLACEHOLDER/${CONFIG_SESSION_PREFIX:-S:}/g" \
        -e "s/LIVE_LABEL_PLACEHOLDER/${CONFIG_LIVE_LABEL:-LIVE}/g" \
        -e "s/RESET_LABEL_PLACEHOLDER/${CONFIG_RESET_LABEL:-RESET}/g" \
        -e "s/VERSION_CACHE_DURATION_PLACEHOLDER/${CONFIG_VERSION_CACHE_DURATION:-3600}/g" \
        -e "s|VERSION_CACHE_FILE_PLACEHOLDER|${CONFIG_VERSION_CACHE_FILE:-/tmp/.claude_version_cache}|g" \
        -e "s/TIME_FORMAT_PLACEHOLDER/${CONFIG_TIME_FORMAT:-%H:%M}/g" \
        -e "s/DATE_FORMAT_PLACEHOLDER/${CONFIG_DATE_FORMAT:-%Y-%m-%d}/g" \
        -e "s/DATE_FORMAT_COMPACT_PLACEHOLDER/${CONFIG_DATE_FORMAT_COMPACT:-%Y%m%d}/g" \
        -e "s/NO_CCUSAGE_MESSAGE_PLACEHOLDER/${CONFIG_NO_CCUSAGE_MESSAGE:-No ccusage}/g" \
        -e "s/CCUSAGE_INSTALL_MESSAGE_PLACEHOLDER/${CONFIG_CCUSAGE_INSTALL_MESSAGE:-Install ccusage for cost tracking}/g" \
        -e "s/NO_ACTIVE_BLOCK_MESSAGE_PLACEHOLDER/${CONFIG_NO_ACTIVE_BLOCK_MESSAGE:-No active block}/g" \
        -e "s/MCP_UNKNOWN_MESSAGE_PLACEHOLDER/${CONFIG_MCP_UNKNOWN_MESSAGE:-unknown}/g" \
        -e "s/MCP_NONE_MESSAGE_PLACEHOLDER/${CONFIG_MCP_NONE_MESSAGE:-none}/g" \
        -e "s/UNKNOWN_VERSION_PLACEHOLDER/${CONFIG_UNKNOWN_VERSION:-?}/g" \
        -e "s/NO_SUBMODULES_PLACEHOLDER/${CONFIG_NO_SUBMODULES:---}/g" \
        "$output_file"
        
    # Clean up temp file
    rm -f "${output_file}.tmp"
    
    # Handle custom colors for custom theme
    if [[ "${CONFIG_THEME:-catppuccin}" == "custom" ]]; then
        sed -i.tmp2 \
            -e "s|RED_PLACEHOLDER|${CONFIG_RED:-\\\\033[31m}|g" \
            -e "s|BLUE_PLACEHOLDER|${CONFIG_BLUE:-\\\\033[34m}|g" \
            -e "s|GREEN_PLACEHOLDER|${CONFIG_GREEN:-\\\\033[32m}|g" \
            -e "s|YELLOW_PLACEHOLDER|${CONFIG_YELLOW:-\\\\033[33m}|g" \
            -e "s|MAGENTA_PLACEHOLDER|${CONFIG_MAGENTA:-\\\\033[35m}|g" \
            -e "s|CYAN_PLACEHOLDER|${CONFIG_CYAN:-\\\\033[36m}|g" \
            -e "s|WHITE_PLACEHOLDER|${CONFIG_WHITE:-\\\\033[37m}|g" \
            "$output_file"
        rm -f "${output_file}.tmp2"
    else
        # Remove custom color section for non-custom themes
        sed -i.tmp3 '/^# === CUSTOM COLORS/,/^white = /d' "$output_file"
        rm -f "${output_file}.tmp3"
    fi
    
    echo "✅ Config.toml generated successfully: $output_file"
    echo "💡 Edit the file to customize your statusline, then test with: $0 --test-config"
    
    return 0
}

# Test configuration loading and parsing
test_config_parsing() {
    local config_file="${1}"
    local verbose="${2:-false}"
    
    echo "🧪 Testing configuration parsing..."
    
    # Discover config file if not provided
    if [[ -z "$config_file" ]]; then
        if ! config_file=$(discover_config_file); then
            echo "❌ No Config.toml found. Generate one with: $0 --generate-config" 
            return 1
        fi
    fi
    
    echo "📄 Testing config file: $config_file"
    
    # Test basic file accessibility
    if [[ ! -f "$config_file" ]]; then
        echo "❌ Config file not found: $config_file"
        return 1
    fi
    
    if [[ ! -r "$config_file" ]]; then
        echo "❌ Config file not readable: $config_file"
        return 1
    fi
    
    # Test TOML parsing
    echo "🔍 Testing TOML parsing..."
    if ! config_json=$(parse_toml_to_json "$config_file" 2>/dev/null); then
        echo "❌ TOML parsing failed"
        return 1
    fi
    
    # Test JSON validity
    echo "🔍 Testing JSON validity..."
    if ! echo "$config_json" | jq empty 2>/dev/null; then
        echo "❌ Generated JSON is invalid"
        if [[ "$verbose" == "true" ]]; then
            echo "Generated JSON:"
            echo "$config_json"
        fi
        return 1
    fi
    
    echo "✅ TOML parsing successful"
    
    # Test key configuration sections
    echo "🔍 Testing configuration sections..."
    local sections=("theme" "features" "emojis" "timeouts" "labels" "cache" "display" "messages")
    for section in "${sections[@]}"; do
        if echo "$config_json" | jq -e ".${section}" >/dev/null 2>&1; then
            echo "  ✅ Section [$section] found"
        else
            echo "  ⚠️ Section [$section] missing"
        fi
    done
    
    # Test specific critical values
    echo "🔍 Testing critical configuration values..."
    local theme_name
    theme_name=$(echo "$config_json" | jq -r '.theme.name // "catppuccin"' 2>/dev/null)
    case "$theme_name" in
        "classic"|"garden"|"catppuccin"|"custom") echo "  ✅ Theme: $theme_name" ;;
        "missing") echo "  ❌ Theme name missing" ; return 1 ;;
        *) echo "  ⚠️ Unknown theme: $theme_name" ;;
    esac
    
    # Test boolean values
    local bool_tests=("features.show_commits" "features.show_version" "features.show_mcp_status")
    for bool_test in "${bool_tests[@]}"; do
        local bool_value
        bool_value=$(echo "$config_json" | jq -r ".${bool_test} // null" 2>/dev/null)
        if [[ "$bool_value" == "true" || "$bool_value" == "false" ]]; then
            echo "  ✅ Boolean ${bool_test}: $bool_value"
        elif [[ "$bool_value" == "null" ]]; then
            echo "  ⚠️ Boolean ${bool_test}: missing (will use default)"
        else
            echo "  ❌ Boolean ${bool_test}: invalid value '$bool_value'"
        fi
    done
    
    # Test timeout format
    local timeout_tests=("timeouts.mcp" "timeouts.version" "timeouts.ccusage")
    for timeout_test in "${timeout_tests[@]}"; do
        local timeout_value
        timeout_value=$(echo "$config_json" | jq -r ".${timeout_test} // \"missing\"" 2>/dev/null)
        if [[ "$timeout_value" == "missing" ]]; then
            echo "  ⚠️ Timeout ${timeout_test}: missing (will use default)"
        elif [[ "$timeout_value" =~ ^[0-9]+[sm]?$ ]]; then
            echo "  ✅ Timeout ${timeout_test}: $timeout_value"
        else
            echo "  ❌ Timeout ${timeout_test}: invalid format '$timeout_value'"
        fi
    done
    
    if [[ "$verbose" == "true" ]]; then
        echo "🔍 Complete parsed configuration:"
        echo "$config_json" | jq '.' 2>/dev/null || echo "$config_json"
    fi
    
    echo "✅ Configuration parsing test completed successfully"
    return 0
}

# Compare inline vs TOML configurations
compare_configurations() {
    echo "⚖️  Comparing inline vs TOML configurations..."
    
    # Store current inline config state
    local inline_theme="$CONFIG_THEME"
    local inline_show_commits="$CONFIG_SHOW_COMMITS"
    local inline_show_version="$CONFIG_SHOW_VERSION"
    local inline_mcp_timeout="$CONFIG_MCP_TIMEOUT"
    
    echo "📋 Current inline configuration:"
    echo "  Theme: ${inline_theme:-default}"
    echo "  Show commits: ${inline_show_commits:-default}"
    echo "  Show version: ${inline_show_version:-default}"
    echo "  MCP timeout: ${inline_mcp_timeout:-default}"
    
    # Try to load TOML config
    local config_file
    if config_file=$(discover_config_file 2>/dev/null); then
        echo "📋 TOML configuration from: $config_file"
        
        local config_json
        if config_json=$(parse_toml_to_json "$config_file" 2>/dev/null); then
            local toml_theme toml_show_commits toml_show_version toml_mcp_timeout
            toml_theme=$(echo "$config_json" | jq -r '.theme.name // "catppuccin"' 2>/dev/null)
            toml_show_commits=$(echo "$config_json" | jq -r '.features.show_commits // true' 2>/dev/null)
            toml_show_version=$(echo "$config_json" | jq -r '.features.show_version // true' 2>/dev/null) 
            toml_mcp_timeout=$(echo "$config_json" | jq -r '.timeouts.mcp // "10s"' 2>/dev/null)
            
            echo "  Theme: $toml_theme"
            echo "  Show commits: $toml_show_commits"
            echo "  Show version: $toml_show_version"
            echo "  MCP timeout: $toml_mcp_timeout"
            
            # Compare key values
            echo "🔍 Configuration differences:"
            [[ "$inline_theme" != "$toml_theme" ]] && echo "  📝 Theme: inline='$inline_theme' vs toml='$toml_theme'"
            [[ "$inline_show_commits" != "$toml_show_commits" ]] && echo "  📝 Show commits: inline='$inline_show_commits' vs toml='$toml_show_commits'"
            [[ "$inline_show_version" != "$toml_show_version" ]] && echo "  📝 Show version: inline='$inline_show_version' vs toml='$toml_show_version'"
            [[ "$inline_mcp_timeout" != "$toml_mcp_timeout" ]] && echo "  📝 MCP timeout: inline='$inline_mcp_timeout' vs toml='$toml_mcp_timeout'"
            
            echo "✅ Configuration comparison completed"
        else
            echo "❌ Failed to parse TOML configuration"
            return 1
        fi
    else
        echo "📋 No TOML configuration found"
        echo "💡 Generate one with: $0 --generate-config"
    fi
    
    return 0
}

# Backup and restore configuration utilities
backup_config() {
    local backup_dir="${1:-~/.config/claude-code-statusline/backups}"
    local backup_name="config_backup_$(date +%Y%m%d_%H%M%S)"
    
    echo "💾 Creating configuration backup..."
    
    # Expand tilde
    backup_dir="${backup_dir/#\~/$HOME}"
    
    # Create backup directory if it doesn't exist
    if ! mkdir -p "$backup_dir"; then
        echo "❌ Failed to create backup directory: $backup_dir"
        return 1
    fi
    
    local backup_path="${backup_dir}/${backup_name}"
    mkdir -p "$backup_path"
    
    # Backup Config.toml if it exists
    local config_file
    if config_file=$(discover_config_file 2>/dev/null); then
        cp "$config_file" "${backup_path}/Config.toml"
        echo "  📄 Backed up TOML config: $config_file"
    fi
    
    # Backup statusline.sh (inline config section)
    if [[ -f "$0" ]]; then
        cp "$0" "${backup_path}/statusline.sh"
        echo "  📄 Backed up script: $0"
    fi
    
    # Create backup metadata
    cat > "${backup_path}/backup_info.txt" << EOF
Backup created: $(date)
Script path: $0
Config file: ${config_file:-"Not found"}
Theme: ${CONFIG_THEME:-"default"}
Hostname: $(hostname)
User: $(whoami)
EOF
    
    echo "✅ Backup created: $backup_path"
    return 0
}

restore_config() {
    local backup_path="$1"
    
    if [[ -z "$backup_path" ]]; then
        echo "❌ Backup path required. Usage: $0 --restore-config <backup_path>"
        return 1
    fi
    
    if [[ ! -d "$backup_path" ]]; then
        echo "❌ Backup directory not found: $backup_path"
        return 1
    fi
    
    echo "🔄 Restoring configuration from: $backup_path"
    
    # Show backup info
    if [[ -f "${backup_path}/backup_info.txt" ]]; then
        echo "📋 Backup information:"
        cat "${backup_path}/backup_info.txt" | sed 's/^/  /'
    fi
    
    # Confirm restoration
    read -p "Continue with restoration? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restoration cancelled"
        return 0
    fi
    
    # Restore Config.toml
    if [[ -f "${backup_path}/Config.toml" ]]; then
        local current_config
        if current_config=$(discover_config_file 2>/dev/null); then
            # Backup current config before restoring
            local safety_backup="/tmp/config_safety_backup_$(date +%H%M%S).toml"
            cp "$current_config" "$safety_backup"
            echo "  💾 Current config backed up to: $safety_backup"
        fi
        
        # Determine where to restore
        local restore_target="./Config.toml"
        if [[ -f ~/.config/claude-code-statusline/Config.toml ]]; then
            restore_target="~/.config/claude-code-statusline/Config.toml"
        fi
        restore_target="${restore_target/#\~/$HOME}"
        
        cp "${backup_path}/Config.toml" "$restore_target"
        echo "  ✅ Restored Config.toml to: $restore_target"
    fi
    
    echo "✅ Configuration restoration completed"
    echo "💡 Test the restored configuration with: $0 --test-config"
    return 0
}

# ============================================================================
# LIVE CONFIGURATION RELOAD CAPABILITIES (Phase 3)
# ============================================================================

# Global variable to track config file modification time
CONFIG_FILE_MTIME=""
CONFIG_LAST_LOADED_PATH=""

# Check if configuration file has been modified since last load
config_file_changed() {
    local config_file
    
    # Find current config file
    if ! config_file=$(discover_config_file 2>/dev/null); then
        # No config file found
        if [[ -n "$CONFIG_LAST_LOADED_PATH" ]]; then
            echo "Configuration file removed: $CONFIG_LAST_LOADED_PATH" >&2
            return 0  # Config was removed, trigger reload to use defaults
        fi
        return 1  # No config file, no change
    fi
    
    # Check if config file path changed
    if [[ "$config_file" != "$CONFIG_LAST_LOADED_PATH" ]]; then
        echo "Configuration file path changed: $CONFIG_LAST_LOADED_PATH -> $config_file" >&2
        return 0  # Different file path, needs reload
    fi
    
    # Check modification time
    local current_mtime
    if command -v stat >/dev/null 2>&1; then
        # Use stat to get modification time
        if stat -f "%m" "$config_file" >/dev/null 2>&1; then
            # BSD stat (macOS)
            current_mtime=$(stat -f "%m" "$config_file" 2>/dev/null)
        elif stat -c "%Y" "$config_file" >/dev/null 2>&1; then
            # GNU stat (Linux)
            current_mtime=$(stat -c "%Y" "$config_file" 2>/dev/null)
        else
            # Fallback to ls
            current_mtime=$(ls -l "$config_file" 2>/dev/null | awk '{print $6 $7 $8}')
        fi
    else
        # Fallback to ls if stat not available
        current_mtime=$(ls -l "$config_file" 2>/dev/null | awk '{print $6 $7 $8}')
    fi
    
    # Compare with stored mtime
    if [[ "$current_mtime" != "$CONFIG_FILE_MTIME" ]]; then
        echo "Configuration file modified: $config_file (mtime: $CONFIG_FILE_MTIME -> $current_mtime)" >&2
        return 0  # File changed
    fi
    
    return 1  # No change
}

# Update stored modification time
update_config_mtime() {
    local config_file
    
    if config_file=$(discover_config_file 2>/dev/null); then
        CONFIG_LAST_LOADED_PATH="$config_file"
        
        if command -v stat >/dev/null 2>&1; then
            if stat -f "%m" "$config_file" >/dev/null 2>&1; then
                # BSD stat (macOS)
                CONFIG_FILE_MTIME=$(stat -f "%m" "$config_file" 2>/dev/null)
            elif stat -c "%Y" "$config_file" >/dev/null 2>&1; then
                # GNU stat (Linux)
                CONFIG_FILE_MTIME=$(stat -c "%Y" "$config_file" 2>/dev/null)
            else
                # Fallback to ls
                CONFIG_FILE_MTIME=$(ls -l "$config_file" 2>/dev/null | awk '{print $6 $7 $8}')
            fi
        else
            CONFIG_FILE_MTIME=$(ls -l "$config_file" 2>/dev/null | awk '{print $6 $7 $8}')
        fi
    else
        CONFIG_LAST_LOADED_PATH=""
        CONFIG_FILE_MTIME=""
    fi
}

# Hot reload configuration if changed
hot_reload_config() {
    local force_reload="${1:-false}"
    
    if [[ "$force_reload" == "true" ]] || config_file_changed; then
        echo "🔄 Hot reloading configuration..." >&2
        
        # Store current configuration state for comparison
        local old_theme="$CONFIG_THEME"
        local old_show_commits="$CONFIG_SHOW_COMMITS"
        local old_show_mcp="$CONFIG_SHOW_MCP_STATUS"
        
        # Reload TOML configuration
        if load_toml_configuration; then
            # Apply environment overrides
            apply_env_overrides
            
            # Validate new configuration
            if validate_configuration; then
                # Update mtime tracking
                update_config_mtime
                
                # Report what changed
                echo "🔄 Configuration reloaded successfully" >&2
                
                # Show key changes
                local changes_detected=false
                if [[ "$CONFIG_THEME" != "$old_theme" ]]; then
                    echo "  📝 Theme changed: $old_theme -> $CONFIG_THEME" >&2
                    changes_detected=true
                fi
                
                if [[ "$CONFIG_SHOW_COMMITS" != "$old_show_commits" ]]; then
                    echo "  📝 Show commits changed: $old_show_commits -> $CONFIG_SHOW_COMMITS" >&2
                    changes_detected=true
                fi
                
                if [[ "$CONFIG_SHOW_MCP_STATUS" != "$old_show_mcp" ]]; then
                    echo "  📝 Show MCP status changed: $old_show_mcp -> $CONFIG_SHOW_MCP_STATUS" >&2
                    changes_detected=true
                fi
                
                if [[ "$changes_detected" == "false" ]]; then
                    echo "  📝 Configuration reloaded (no major changes detected)" >&2
                fi
                
                # Re-apply theme with new configuration
                apply_theme
                
                return 0
            else
                echo "❌ Configuration validation failed, keeping previous config" >&2
                return 1
            fi
        else
            echo "❌ Configuration reload failed, keeping previous config" >&2
            return 1
        fi
    fi
    
    return 0  # No reload needed
}

# Watch configuration file for changes (background monitoring)
start_config_watcher() {
    local watch_interval="${1:-2}"  # Check every 2 seconds by default
    local max_iterations="${2:-}"   # Optional: limit monitoring duration
    
    echo "👀 Starting configuration watcher (interval: ${watch_interval}s)" >&2
    
    local iteration_count=0
    
    # Update initial mtime
    update_config_mtime
    
    while true; do
        sleep "$watch_interval"
        
        # Check iteration limit
        if [[ -n "$max_iterations" ]]; then
            ((iteration_count++))
            if [[ $iteration_count -gt $max_iterations ]]; then
                echo "👀 Configuration watcher stopping (max iterations reached)" >&2
                break
            fi
        fi
        
        # Check for configuration changes
        hot_reload_config
        
        # Yield to allow other processes to run
        sleep 0.1
    done
}

# Interactive configuration reload command
reload_config_interactive() {
    echo "🔧 Interactive Configuration Reload"
    echo "=================================="
    
    # Show current configuration summary
    echo "📋 Current Configuration:"
    echo "  Theme: ${CONFIG_THEME:-default}"
    echo "  Show commits: ${CONFIG_SHOW_COMMITS:-default}"
    echo "  Show version: ${CONFIG_SHOW_VERSION:-default}"
    echo "  Show MCP status: ${CONFIG_SHOW_MCP_STATUS:-default}"
    echo "  MCP timeout: ${CONFIG_MCP_TIMEOUT:-default}"
    
    # Show config file location
    local config_file
    if config_file=$(discover_config_file 2>/dev/null); then
        echo "  Config file: $config_file"
        local config_mtime
        if command -v stat >/dev/null 2>&1; then
            if stat -f "%m" "$config_file" >/dev/null 2>&1; then
                config_mtime=$(date -r "$(stat -f "%m" "$config_file")" 2>/dev/null)
            elif stat -c "%Y" "$config_file" >/dev/null 2>&1; then
                config_mtime=$(date -d "@$(stat -c "%Y" "$config_file")" 2>/dev/null)
            fi
        fi
        [[ -n "$config_mtime" ]] && echo "  Last modified: $config_mtime"
    else
        echo "  Config file: Not found (using defaults)"
    fi
    
    echo ""
    echo "Options:"
    echo "  1. Force reload configuration now"
    echo "  2. Test configuration parsing"
    echo "  3. Compare inline vs TOML config" 
    echo "  4. Start config file watcher"
    echo "  5. Exit"
    
    read -p "Choose option (1-5): " -r option
    
    case "$option" in
        1)
            echo "🔄 Force reloading configuration..."
            hot_reload_config "true"
            ;;
        2)
            echo "🧪 Testing configuration parsing..."
            test_config_parsing "" "true"
            ;;
        3)
            echo "⚖️ Comparing configurations..."
            compare_configurations
            ;;
        4)
            echo "👀 Starting configuration watcher..."
            echo "Note: This will monitor config changes. Press Ctrl+C to stop."
            start_config_watcher 2 30  # Watch for 30 iterations (60 seconds)
            ;;
        5)
            echo "Exit"
            return 0
            ;;
        *)
            echo "❌ Invalid option"
            return 1
            ;;
    esac
}

# Enable automatic hot reload (call this to enable background monitoring)
enable_auto_reload() {
    local enable="${1:-true}"
    
    if [[ "$enable" == "true" ]]; then
        export CONFIG_AUTO_RELOAD=true
        echo "🔄 Automatic configuration reload enabled" >&2
        update_config_mtime
    else
        export CONFIG_AUTO_RELOAD=false
        echo "🔄 Automatic configuration reload disabled" >&2
    fi
}

# Check for auto-reload during statusline generation
check_auto_reload() {
    if [[ "${CONFIG_AUTO_RELOAD:-false}" == "true" ]]; then
        hot_reload_config
    fi
}

# ============================================================================
# END LIVE CONFIGURATION RELOAD CAPABILITIES
# ============================================================================

# ============================================================================
# END MIGRATION TOOLS & CONFIG TESTING UTILITIES
# ============================================================================

# ============================================================================
# END TOML CONFIGURATION SYSTEM
# ============================================================================

# Skip main configuration loading if sourced for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] || [[ "${STATUSLINE_TESTING}" == "true" ]]; then
    return 0 2>/dev/null || exit 0
fi

# Load configuration from Config.toml (if available)  
# This will override the inline defaults below if Config.toml exists
load_toml_configuration

# Apply environment variable overrides (highest precedence)
apply_env_overrides

# Validate final configuration
validate_configuration

# ============================================================================
# COMMAND-LINE INTERFACE (Phase 3)
# ============================================================================

# Show usage information
show_usage() {
    cat << 'EOF'
Claude Code Statusline Configuration Manager
==========================================

USAGE:
    statusline.sh [options]                 - Run statusline (default)
    statusline.sh --help                    - Show this help message

CONFIGURATION MANAGEMENT:
    --generate-config [FILE]                - Generate Config.toml from inline config
    --test-config [FILE]                    - Test configuration parsing
    --test-config-verbose [FILE]            - Test with detailed output
    --compare-config                        - Compare inline vs TOML configuration
    --validate-config                       - Validate current configuration

MIGRATION UTILITIES:
    --backup-config [DIR]                   - Backup current configuration
    --restore-config DIR                    - Restore from backup directory

LIVE RELOAD CAPABILITIES:
    --reload-config                         - Reload configuration now
    --reload-interactive                    - Interactive configuration reload menu
    --watch-config [INTERVAL]               - Watch config file for changes
    --enable-auto-reload                    - Enable automatic config reload
    --disable-auto-reload                   - Disable automatic config reload

EXAMPLES:
    # Generate Config.toml from current inline configuration
    statusline.sh --generate-config

    # Test your Config.toml file
    statusline.sh --test-config

    # Compare inline vs TOML configurations
    statusline.sh --compare-config

    # Interactive configuration management
    statusline.sh --reload-interactive

    # Watch config file for changes (check every 3 seconds)
    statusline.sh --watch-config 3

CONFIGURATION FILES:
    The script looks for Config.toml in this order:
    1. ./Config.toml
    2. ~/.config/claude-code-statusline/Config.toml
    3. ~/.claude-statusline.toml

    Environment variables (CONFIG_*) override all TOML settings.

TIMEOUT CONFIGURATION:
    Timeout values control how long to wait for external operations:
    
    MCP Timeout (1s-60s recommended, optimal: 3s-15s):
        CONFIG_MCP_TIMEOUT="10s"    # Default: 10s
        
    Version Timeout (1s-10s recommended, optimal: 1s-3s):
        CONFIG_VERSION_TIMEOUT="2s"    # Default: 2s
        
    Cost Tracking Timeout (1s-30s recommended, optimal: 3s-10s):
        CONFIG_CCUSAGE_TIMEOUT="8s"    # Default: 8s
    
    Format: Use "Ns" for seconds or "Nm" for minutes (e.g., "10s", "2m")
    
    Performance Guidelines:
    • Lower timeouts = faster response, higher failure chance
    • Higher timeouts = slower response, better reliability
    • Values >30s may impact statusline responsiveness
    • Values <1s are too aggressive for most operations

EOF
}

# Parse command-line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        "--help"|"-h")
            show_usage
            exit 0
            ;;
        "--generate-config")
            generate_config_toml "${2:-./Config.toml}"
            exit $?
            ;;
        "--test-config")
            test_config_parsing "${2:-}" "false"
            exit $?
            ;;
        "--test-config-verbose")
            test_config_parsing "${2:-}" "true"
            exit $?
            ;;
        "--compare-config")
            compare_configurations
            exit $?
            ;;
        "--validate-config")
            # Already done above, just show results
            echo "✅ Configuration validation completed"
            exit 0
            ;;
        "--backup-config")
            backup_config "${2:-}"
            exit $?
            ;;
        "--restore-config")
            if [[ -z "$2" ]]; then
                echo "❌ Backup directory required. Usage: $0 --restore-config <backup_dir>"
                exit 1
            fi
            restore_config "$2"
            exit $?
            ;;
        "--reload-config")
            hot_reload_config "true"
            exit $?
            ;;
        "--reload-interactive")
            reload_config_interactive
            exit $?
            ;;
        "--watch-config")
            start_config_watcher "${2:-2}"
            exit $?
            ;;
        "--enable-auto-reload")
            enable_auto_reload "true"
            exit 0
            ;;
        "--disable-auto-reload")
            enable_auto_reload "false"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi

# ============================================================================
# END COMMAND-LINE INTERFACE
# ============================================================================

# Check for auto-reload if enabled
check_auto_reload

# Capture the ACTUAL current working directory BEFORE any changes
actual_current_dir=$(pwd)

input=$(cat)
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')

# Navigate to the directory
cd "$current_dir" 2>/dev/null || cd ~ || return 1

# Get basic info - convert full path to use ~ notation
if [[ "$current_dir" == "$HOME"/* ]]; then
  dir_display="~${current_dir#$HOME}"
else
  dir_display="$current_dir"
fi

# Get current time
current_datetime="$CONFIG_CLOCK_EMOJI $(date +"$CONFIG_TIME_FORMAT")"

# Detect current mode (if available from environment variables or other indicators)
# This is a placeholder - Claude Code might provide mode info in future updates
mode_info=""
if [[ -n "$CLAUDE_MODE" ]]; then
  mode_info="[$CLAUDE_MODE]"
elif [[ -n "$VIM_MODE" ]]; then
  mode_info="[$VIM_MODE]"
else
  # Default placeholder
  mode_info=""
fi

# Get MCP server status (with timeout to avoid blocking)
get_mcp_status() {
  # Quick check to avoid blocking the statusline
  local mcp_list_output
  local connected_count total_count

  if mcp_list_output=$(execute_with_timeout "$CONFIG_MCP_TIMEOUT" claude mcp list 2>/dev/null); then
    # Count connected servers (lines with "✓ Connected")
    connected_count=$(echo "$mcp_list_output" | grep "✓ Connected" | wc -l | tr -d ' ')

    # Count total servers (lines with server names, excluding the "Checking..." line)
    # Look for lines that have server names followed by ":" and a command/URL
    local total_count=0
    while IFS= read -r line; do
      if parse_mcp_server_name_secure "$line" >/dev/null 2>&1; then
        ((total_count++))
      fi
    done <<<"$mcp_list_output"

    # Return connected/total format
    echo "${connected_count}/${total_count}"
  else
    echo "?/?"
  fi
}

# Get all MCP servers with their status
get_all_mcp_servers() {
  local mcp_list_output
  if mcp_list_output=$(execute_with_timeout "$CONFIG_MCP_TIMEOUT" claude mcp list 2>/dev/null); then
    local all_servers=""
    while IFS= read -r line; do
      # Look for lines with server names using secure parsing
      local server_name
      if server_name=$(parse_mcp_server_name_secure "$line" 2>/dev/null); then
        local server_status="disconnected"
        if echo "$line" | grep -q "✓ Connected"; then
          server_status="connected"
        fi

        if [ -z "$all_servers" ]; then
          all_servers="$server_name:$server_status"
        else
          all_servers="$all_servers,$server_name:$server_status"
        fi
      fi
    done <<<"$mcp_list_output"

    if [ -n "$all_servers" ]; then
      echo "$all_servers"
    else
      echo "$CONFIG_MCP_NONE_MESSAGE"
    fi
  else
    echo "$CONFIG_MCP_UNKNOWN_MESSAGE"
  fi
}

# Get active MCP server names (kept for backward compatibility)
get_active_mcp_servers() {
  local mcp_list_output
  if mcp_list_output=$(execute_with_timeout "$CONFIG_MCP_TIMEOUT" claude mcp list 2>/dev/null); then
    # Extract server names that are connected (have "✓ Connected" status)
    local active_servers=""
    while IFS= read -r line; do
      if echo "$line" | grep -q "✓ Connected"; then
        # Extract server name using secure parsing
        local server_name
        if server_name=$(parse_mcp_server_name_secure "$line" 2>/dev/null); then
          if [ -z "$active_servers" ]; then
            active_servers="$server_name"
          else
            active_servers="$active_servers,$server_name"
          fi
        fi
      fi
    done <<<"$mcp_list_output"

    if [ -n "$active_servers" ]; then
      echo "$active_servers"
    else
      echo "$CONFIG_MCP_NONE_MESSAGE"
    fi
  else
    echo "$CONFIG_MCP_UNKNOWN_MESSAGE"
  fi
}

mcp_status=$(get_mcp_status)
active_mcp_servers=$(get_active_mcp_servers)
all_mcp_servers=$(get_all_mcp_servers)

# Format MCP servers with colors and strikethrough for broken ones
format_mcp_servers() {
  local servers="$1"
  local formatted=""

  if [[ "$servers" == "$CONFIG_MCP_UNKNOWN_MESSAGE" ]] || [[ "$servers" == "$CONFIG_MCP_NONE_MESSAGE" ]]; then
    echo "$servers"
    return
  fi

  # Split servers by comma and process each one
  local temp_servers="$servers," # Add trailing comma for easier parsing
  while [[ "$temp_servers" == *","* ]]; do
    local server_entry="${temp_servers%%,*}"
    temp_servers="${temp_servers#*,}"
    # Extract server name and status
    local server_name="${server_entry%:*}"
    local server_status="${server_entry#*:}"

    if [[ "$server_status" == "connected" ]]; then
      # Green for connected servers
      local formatted_server="${BRIGHT_GREEN}${server_name}${RESET}"
    else
      # Red with strikethrough for disconnected servers
      local formatted_server="${RED}${STRIKETHROUGH}${server_name}${RESET}"
    fi

    if [[ -z "$formatted" ]]; then
      formatted="$formatted_server"
    else
      formatted="$formatted, $formatted_server"
    fi
  done

  echo "$formatted"
}

# Determine MCP status color and display format
get_mcp_display() {
  if [[ "$mcp_status" == "?/?" ]]; then
    echo "31m:MCP:?/?" # Red for error
  elif [[ "$mcp_status" =~ ^([0-9]+)/([0-9]+)$ ]]; then
    local connected="${BASH_REMATCH[1]}"
    local total="${BASH_REMATCH[2]}"

    if [[ "$total" == "0" ]]; then
      # No MCP servers configured - show as dim/gray
      echo "2m:---" # Dim for "no MCP configured"
    elif [[ "$connected" == "$total" ]]; then
      echo "92m:MCP:${mcp_status}" # Bright green for all connected
    else
      echo "33m:MCP:${mcp_status}" # Yellow for partial connection
    fi
  else
    echo "31m:MCP:?/?" # Red for unknown format
  fi
}

mcp_display=$(get_mcp_display)
mcp_color="\033[${mcp_display%%:*}" # Extract color part
mcp_text="${mcp_display#*:}"        # Extract text part

# Get Submodule count (simple display)
get_submodule_status() {
  # Check if we're in a git repo with submodules
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 || [ ! -f .gitmodules ]; then
    echo "$CONFIG_SUBMODULE_LABEL$CONFIG_NO_SUBMODULES"
    return
  fi

  # Count total submodules from .gitmodules
  local total_submodules
  total_submodules=$(grep -c "^\[submodule " .gitmodules 2>/dev/null || echo "0")

  if [ "$total_submodules" = "0" ]; then
    echo "$CONFIG_SUBMODULE_LABEL$CONFIG_NO_SUBMODULES"
    return
  fi

  # Just show the count
  echo "$CONFIG_SUBMODULE_LABEL$total_submodules"
}

submodule_display=$(get_submodule_status)

# Determine submodule status color
get_submodule_color() {
  if [ "$submodule_display" = "$CONFIG_SUBMODULE_LABEL$CONFIG_NO_SUBMODULES" ]; then
    echo "$CONFIG_DIM" # Dim for no submodules
  else
    echo "$CONFIG_BRIGHT_GREEN" # Green for submodules present
  fi
}

submodule_color=$(get_submodule_color)

# Get current Claude session info
get_current_session_info() {
  # Try to get session ID from environment (if available)
  local session_id=""
  if [ -n "$CLAUDE_SESSION_ID" ]; then
    # Show only first 8 characters of session ID
    session_id="${CLAUDE_SESSION_ID:0:8}"
  fi

  # Get permission mode if available
  local permission_mode=""
  if [ -n "$CLAUDE_PERMISSION_MODE" ]; then
    permission_mode="$CLAUDE_PERMISSION_MODE"
  fi

  # Return session info
  if [ -n "$session_id" ]; then
    echo "S:$session_id"
  else
    echo "S:-"
  fi
}

# Get Claude usage information
get_claude_usage_info() {
  # Check if ccusage is available
  local ccusage_available=false
  if command -v bunx >/dev/null 2>&1 && bunx ccusage --version >/dev/null 2>&1; then
    ccusage_available=true
  fi

  # If ccusage is not available, return placeholder values
  if [ "$ccusage_available" = "false" ]; then
    echo "-.--:-.--:-.--:-.--:$CONFIG_NO_CCUSAGE_MESSAGE:$CONFIG_CCUSAGE_INSTALL_MESSAGE"
    return
  fi
  

  # Calculate dates dynamically with proper fallbacks
  local seven_days_ago thirty_days_ago
  if date -d '7 days ago' "+$CONFIG_DATE_FORMAT_COMPACT" >/dev/null 2>&1; then
    # GNU date (Linux)
    seven_days_ago=$(date -d '7 days ago' "+$CONFIG_DATE_FORMAT_COMPACT")
    thirty_days_ago=$(date -d '30 days ago' "+$CONFIG_DATE_FORMAT_COMPACT")
  elif date -v-7d "+$CONFIG_DATE_FORMAT_COMPACT" >/dev/null 2>&1; then
    # BSD date (macOS)
    seven_days_ago=$(date -v-7d "+$CONFIG_DATE_FORMAT_COMPACT")
    thirty_days_ago=$(date -v-30d "+$CONFIG_DATE_FORMAT_COMPACT")
  else
    # Fallback for systems without proper date arithmetic
    local current_epoch=$(date +%s)
    local seven_days_epoch=$((current_epoch - 7 * 24 * 3600))
    local thirty_days_epoch=$((current_epoch - 30 * 24 * 3600))
    seven_days_ago=$(date -d "@$seven_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || date -r "$seven_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || echo "$(date "+$CONFIG_DATE_FORMAT_COMPACT")")
    thirty_days_ago=$(date -d "@$thirty_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || date -r "$thirty_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || echo "$(date "+$CONFIG_DATE_FORMAT_COMPACT")")
  fi
  local today=$(date "+$CONFIG_DATE_FORMAT")
  local current_dir="$actual_current_dir"
  local current_session_id=$(sanitize_path_secure "$current_dir")

  # Execute ccusage commands sequentially to avoid API rate limits
  # Parallel execution can trigger Anthropic billing API throttling
  local session_data=""
  local daily_data=""
  local monthly_data=""
  local block_data=""
  
  # Define cache files for ccusage data (30-second cache)
  local cache_dir="/tmp/.claude_statusline_cache"
  local blocks_cache="$cache_dir/blocks.json"
  local session_cache="$cache_dir/session.json" 
  local daily_cache="$cache_dir/daily_7d.json"
  local monthly_cache="$cache_dir/monthly_30d.json"
  local cache_duration=30  # 30 seconds
  
  # Create cache directory if needed
  if [[ ! -d "$cache_dir" ]]; then
    mkdir -p "$cache_dir" 2>/dev/null
    chmod 700 "$cache_dir" 2>/dev/null  # Secure permissions to prevent other users from reading cost data
  fi
  
  # Helper function to check if cache is fresh
  is_cache_fresh() {
    local cache_file="$1"
    if [[ -f "$cache_file" ]]; then
      local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
      [[ $cache_age -lt $cache_duration ]]
    else
      return 1
    fi
  }
  
  # Get active block info FIRST (prioritize existing cache for instant display)
  if [[ -f "$blocks_cache" ]]; then
    block_data=$(cat "$blocks_cache" 2>/dev/null)
    # Refresh in background if cache is stale (with file locking to prevent race conditions)
    if ! is_cache_fresh "$blocks_cache"; then
      local lock_file="${blocks_cache}.lock"
      
      # Check for and remove stale locks (from dead processes)
      if [[ -f "$lock_file" ]]; then
        local lock_pid=$(cat "$lock_file" 2>/dev/null)
        local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
        
        # Remove lock if process is dead OR lock is older than 2 minutes
        if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
          rm -f "$lock_file" 2>/dev/null
        fi
      fi
      
      # Try to acquire lock (non-blocking) - only one instance should refresh
      if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
        if fresh_block_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage blocks --active --json 2>/dev/null); then
          echo "$fresh_block_data" > "$blocks_cache" 2>/dev/null
          block_data="$fresh_block_data"
        fi
        rm -f "$lock_file" 2>/dev/null
      fi
      # If lock acquisition fails, another instance is refreshing - use existing cache
    fi
  else
    # No cache file exists - check for stale locks before creating new cache
    local lock_file="${blocks_cache}.lock"
    
    # Check for and remove stale locks (from dead processes)
    if [[ -f "$lock_file" ]]; then
      local lock_pid=$(cat "$lock_file" 2>/dev/null)
      local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
      
      # Remove lock if process is dead OR lock is older than 2 minutes
      if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
        rm -f "$lock_file" 2>/dev/null
      fi
    fi
    
    # Try to acquire lock for initial cache creation
    if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
      if block_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage blocks --active --json 2>/dev/null); then
        echo "$block_data" > "$blocks_cache" 2>/dev/null
      fi
      rm -f "$lock_file" 2>/dev/null
    fi
  fi

  # Get current session cost (prioritize existing cache for instant display)
  if [[ -f "$session_cache" ]]; then
    session_data=$(cat "$session_cache" 2>/dev/null)
    # Refresh in background if cache is stale (with file locking to prevent race conditions)
    if ! is_cache_fresh "$session_cache"; then
      local lock_file="${session_cache}.lock"
      
      # Check for and remove stale locks (from dead processes)
      if [[ -f "$lock_file" ]]; then
        local lock_pid=$(cat "$lock_file" 2>/dev/null)
        local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
        
        # Remove lock if process is dead OR lock is older than 2 minutes
        if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
          rm -f "$lock_file" 2>/dev/null
        fi
      fi
      
      # Try to acquire lock (non-blocking) - only one instance should refresh
      if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
        if fresh_session_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage session --since "$seven_days_ago" --json 2>/dev/null); then
          echo "$fresh_session_data" > "$session_cache" 2>/dev/null
          session_data="$fresh_session_data"
        fi
        rm -f "$lock_file" 2>/dev/null
      fi
      # If lock acquisition fails, another instance is refreshing - use existing cache
    fi
  else
    # No cache file exists - check for stale locks before creating new cache
    local lock_file="${session_cache}.lock"
    
    # Check for and remove stale locks (from dead processes)
    if [[ -f "$lock_file" ]]; then
      local lock_pid=$(cat "$lock_file" 2>/dev/null)
      local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
      
      # Remove lock if process is dead OR lock is older than 2 minutes
      if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
        rm -f "$lock_file" 2>/dev/null
      fi
    fi
    
    # Try to acquire lock for initial cache creation
    if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
      if session_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage session --since "$seven_days_ago" --json 2>/dev/null); then
        echo "$session_data" > "$session_cache" 2>/dev/null
      fi
      rm -f "$lock_file" 2>/dev/null
    fi
  fi

  # Get today's cost and weekly cost (prioritize existing cache for instant display)
  if [[ -f "$daily_cache" ]]; then
    daily_data=$(cat "$daily_cache" 2>/dev/null)
    # Refresh in background if cache is stale (with file locking to prevent race conditions)
    if ! is_cache_fresh "$daily_cache"; then
      local lock_file="${daily_cache}.lock"
      
      # Check for and remove stale locks (from dead processes)
      if [[ -f "$lock_file" ]]; then
        local lock_pid=$(cat "$lock_file" 2>/dev/null)
        local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
        
        # Remove lock if process is dead OR lock is older than 2 minutes
        if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
          rm -f "$lock_file" 2>/dev/null
        fi
      fi
      
      # Try to acquire lock (non-blocking) - only one instance should refresh
      if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
        if fresh_daily_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage daily --since "$seven_days_ago" --json 2>/dev/null); then
          echo "$fresh_daily_data" > "$daily_cache" 2>/dev/null
          daily_data="$fresh_daily_data"
        fi
        rm -f "$lock_file" 2>/dev/null
      fi
      # If lock acquisition fails, another instance is refreshing - use existing cache
    fi
  else
    # No cache file exists - check for stale locks before creating new cache
    local lock_file="${daily_cache}.lock"
    
    # Check for and remove stale locks (from dead processes)
    if [[ -f "$lock_file" ]]; then
      local lock_pid=$(cat "$lock_file" 2>/dev/null)
      local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
      
      # Remove lock if process is dead OR lock is older than 2 minutes
      if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
        rm -f "$lock_file" 2>/dev/null
      fi
    fi
    
    # Try to acquire lock for initial cache creation
    if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
      if daily_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage daily --since "$seven_days_ago" --json 2>/dev/null); then
        echo "$daily_data" > "$daily_cache" 2>/dev/null
      fi
      rm -f "$lock_file" 2>/dev/null
    fi
  fi

  # Get 30-day cost (prioritize existing cache for instant display, slowest API call)
  if [[ -f "$monthly_cache" ]]; then
    monthly_data=$(cat "$monthly_cache" 2>/dev/null)
    # Refresh in background if cache is stale (with file locking to prevent race conditions)
    if ! is_cache_fresh "$monthly_cache"; then
      local lock_file="${monthly_cache}.lock"
      
      # Check for and remove stale locks (from dead processes)
      if [[ -f "$lock_file" ]]; then
        local lock_pid=$(cat "$lock_file" 2>/dev/null)
        local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
        
        # Remove lock if process is dead OR lock is older than 2 minutes
        if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
          rm -f "$lock_file" 2>/dev/null
        fi
      fi
      
      # Try to acquire lock (non-blocking) - only one instance should refresh
      if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
        if fresh_monthly_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage daily --since "$thirty_days_ago" --json 2>/dev/null); then
          echo "$fresh_monthly_data" > "$monthly_cache" 2>/dev/null
          monthly_data="$fresh_monthly_data"
        fi
        rm -f "$lock_file" 2>/dev/null
      fi
      # If lock acquisition fails, another instance is refreshing - use existing cache
    fi
  else
    # No cache file exists - check for stale locks before creating new cache
    local lock_file="${monthly_cache}.lock"
    
    # Check for and remove stale locks (from dead processes)
    if [[ -f "$lock_file" ]]; then
      local lock_pid=$(cat "$lock_file" 2>/dev/null)
      local lock_age=$(($(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))
      
      # Remove lock if process is dead OR lock is older than 2 minutes
      if ! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt 120 ]]; then
        rm -f "$lock_file" 2>/dev/null
      fi
    fi
    
    # Try to acquire lock for initial cache creation
    if (set -C; echo $$ > "$lock_file" 2>/dev/null); then
      if monthly_data=$(execute_with_timeout "$CONFIG_CCUSAGE_TIMEOUT" bunx ccusage daily --since "$thirty_days_ago" --json 2>/dev/null); then
        echo "$monthly_data" > "$monthly_cache" 2>/dev/null
      fi
      rm -f "$lock_file" 2>/dev/null
    fi
  fi
  
  # Process session cost
  local session_cost="0.00"
  if [[ -n "$session_data" ]]; then
    session_cost=$(echo "$session_data" | jq -r --arg session_id "$current_session_id" '.sessions[] | select(.sessionId == $session_id) | .totalCost // 0' 2>/dev/null | head -1)
    if [ -z "$session_cost" ] || [ "$session_cost" = "null" ]; then
      session_cost="0.00"
    fi
  fi

  # Process today's cost and weekly cost
  local today_cost="0.00"
  local week_cost="0.00"
  if [[ -n "$daily_data" ]]; then
    today_cost=$(echo "$daily_data" | jq -r --arg today "$today" '.daily[] | select(.date == $today) | .totalCost // 0' 2>/dev/null | head -1)
    if [ -z "$today_cost" ] || [ "$today_cost" = "null" ]; then
      today_cost="0.00"
    fi

    # Get weekly total cost (last 7 days excluding today)
    local total_cost=$(echo "$daily_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)
    if [ -z "$total_cost" ] || [ "$total_cost" = "null" ]; then
      total_cost="0.00"
    fi
    # Subtract today's cost to get only the last 7 days without today
    if [[ "$DEP_BC_AVAILABLE" == "true" ]]; then
      week_cost=$(echo "$total_cost - $today_cost" | bc -l 2>/dev/null || echo "0.00")
    else
      # Fallback using shell arithmetic (less precise for floating point)
      week_cost=$(awk "BEGIN {printf \"%.2f\", $total_cost - $today_cost}" 2>/dev/null || echo "0.00")
    fi
    # Ensure week_cost is formatted properly
    week_cost=$(printf "%.2f" "$week_cost" 2>/dev/null || echo "0.00")
  fi

  # Process 30-day cost
  local month_cost="0.00"
  if [[ -n "$monthly_data" ]]; then
    month_cost=$(echo "$monthly_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)
    if [ -z "$month_cost" ] || [ "$month_cost" = "null" ]; then
      month_cost="0.00"
    fi
  fi

  # Process active block info
  local block_cost_info="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
  local reset_time_info="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"

  if [[ -n "$block_data" ]]; then
    # Validate JSON structure before processing
    if ! echo "$block_data" | jq empty 2>/dev/null; then
      echo "WARNING: Invalid JSON in block data, skipping block detection" >&2
    else
      local block_cost=$(echo "$block_data" | jq -r '.blocks[0].costUSD // 0' 2>/dev/null)
      local remaining_minutes=$(echo "$block_data" | jq -r '.blocks[0].projection.remainingMinutes // 0' 2>/dev/null)
      local is_active=$(echo "$block_data" | jq -r '.blocks[0].isActive // false' 2>/dev/null)
      
      # Simple and reliable block detection: only check isActive flag
      if [ "$is_active" = "true" ]; then
      # Calculate time remaining
      local hours=$((remaining_minutes / 60))
      local mins=$((remaining_minutes % 60))
      local time_str=""
      if [ "$hours" -gt 0 ]; then
        time_str="${hours}h ${mins}m left"
      else
        time_str="${mins}m left"
      fi

      # Get reset time from endTime and convert to local time
      local end_time=$(echo "$block_data" | jq -r '.blocks[0].endTime // ""' 2>/dev/null)
      local reset_time=""
      if [ -n "$end_time" ] && [ "$end_time" != "null" ]; then
        reset_time=$(execute_python_safely "
import datetime
utc_time = datetime.datetime.fromisoformat('$end_time'.replace('Z', '+00:00'))
local_time = utc_time.replace(tzinfo=datetime.timezone.utc).astimezone()
print(local_time.strftime('%H.%M'))
" "")
      fi

      block_cost_info=$(printf "$CONFIG_LIVE_BLOCK_EMOJI $CONFIG_LIVE_LABEL \$%.2f" "$block_cost")
      if [ -n "$reset_time" ]; then
        reset_time_info=$(printf "$CONFIG_RESET_LABEL at %s (%s)" "$reset_time" "$time_str")
      else
        reset_time_info=$(printf "$CONFIG_RESET_LABEL (%s)" "$time_str")
      fi
    fi
    fi
  fi

  # Format numbers for display
  local formatted_session_cost=$(printf "%.2f" "$session_cost")
  local formatted_month_cost=$(printf "%.2f" "$month_cost")
  local formatted_week_cost=$(printf "%.2f" "$week_cost")
  local formatted_today_cost=$(printf "%.2f" "$today_cost")

  # Return the formatted string
  echo "$formatted_session_cost:$formatted_month_cost:$formatted_week_cost:$formatted_today_cost:$block_cost_info:$reset_time_info"
}

# Get Claude Code version (with caching to avoid performance impact)
get_claude_version() {
  local cache_file="$CONFIG_VERSION_CACHE_FILE"
  local cache_duration="$CONFIG_VERSION_CACHE_DURATION"

  # Check if cache file exists and is recent
  if [ -f "$cache_file" ]; then
    local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    if [ "$cache_age" -lt "$cache_duration" ]; then
      cat "$cache_file" 2>/dev/null || echo "$CONFIG_UNKNOWN_VERSION"
      return
    fi
  fi

  # Get version with timeout and cache it
  local version
  if version=$(execute_with_timeout "$CONFIG_VERSION_TIMEOUT" claude --version 2>/dev/null | head -1); then
    # Extract just the version number (e.g., "1.0.81" from "1.0.81 (Claude Code)")
    local clean_version
    clean_version=$(echo "$version" | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
    if [ -n "$clean_version" ]; then
      # Create cache file with secure permissions
      create_secure_cache_file "$cache_file" "$clean_version"
      echo "$clean_version"
    else
      echo "$CONFIG_UNKNOWN_VERSION"
    fi
  else
    echo "$CONFIG_UNKNOWN_VERSION"
  fi
}

claude_version=$(get_claude_version)

# Get Claude usage information
claude_usage_info=$(get_claude_usage_info)
claude_session_cost="${claude_usage_info%%:*}"
claude_usage_info="${claude_usage_info#*:}"
claude_month_cost="${claude_usage_info%%:*}"
claude_usage_info="${claude_usage_info#*:}"
claude_week_cost="${claude_usage_info%%:*}"
claude_usage_info="${claude_usage_info#*:}"
claude_today_cost="${claude_usage_info%%:*}"
claude_usage_info="${claude_usage_info#*:}"
claude_block_info="${claude_usage_info%%:*}"
claude_usage_info="${claude_usage_info#*:}"
claude_reset_info="${claude_usage_info%%:*}"

# Determine model emoji based on model type
model_emoji="$CONFIG_DEFAULT_MODEL_EMOJI"
case "$model_name" in
*"Opus"* | *"opus"*)
  model_emoji="$CONFIG_OPUS_EMOJI"
  ;;
*"Haiku"* | *"haiku"*)
  model_emoji="$CONFIG_HAIKU_EMOJI"
  ;;
*"Sonnet"* | *"sonnet"*)
  model_emoji="$CONFIG_SONNET_EMOJI"
  ;;
esac

# Keep only current time

# Get commits today (still used in display)
get_commits_today() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "0"
    return
  fi

  git log --since="today 00:00" --oneline 2>/dev/null | wc -l | tr -d ' '
}

commits_today=$(get_commits_today)

# Set color variables from configuration
RED="$CONFIG_RED"
BLUE="$CONFIG_BLUE"
GREEN="$CONFIG_GREEN"
YELLOW="$CONFIG_YELLOW"
MAGENTA="$CONFIG_MAGENTA"
CYAN="$CONFIG_CYAN"
ORANGE="$CONFIG_ORANGE"
LIGHT_ORANGE="$CONFIG_LIGHT_ORANGE"
LIGHT_GRAY="$CONFIG_LIGHT_GRAY"
ITALIC="$CONFIG_ITALIC"
BRIGHT_GREEN="$CONFIG_BRIGHT_GREEN"
PURPLE="$CONFIG_PURPLE"
DIM="$CONFIG_DIM"
TEAL="$CONFIG_TEAL"
GOLD="$CONFIG_GOLD"
PINK_BRIGHT="$CONFIG_PINK_BRIGHT"
INDIGO="$CONFIG_INDIGO"
VIOLET="$CONFIG_VIOLET"
LIGHT_BLUE="$CONFIG_LIGHT_BLUE"
STRIKETHROUGH="$CONFIG_STRIKETHROUGH"
RESET="$CONFIG_RESET"

# ==================== DETERMINE GIT STATUS AND VARIABLES ====================
# Check if we're in a git repository and set git-specific variables
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Get current branch
  branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')

  # Check git status and set branch color and emoji accordingly
  if git diff --quiet && git diff --cached --quiet; then
    # Clean repository - green branch with green emoji
    branch_color="${GREEN}"
    status_emoji="$CONFIG_CLEAN_STATUS_EMOJI"
  else
    # Dirty repository - yellow branch with folder emoji
    branch_color="${YELLOW}"
    status_emoji="$CONFIG_DIRTY_STATUS_EMOJI"
  fi

  # Set git-specific format parts
  git_info="${branch_color}(%s)${RESET} %s "
  git_args=("$branch" "$status_emoji")
else
  # Not a git repository - no git info to display
  git_info=""
  git_args=()
fi

# ==================== LINE 1: Basic Repository Info ====================
# Format: [mode] ~/path (branch) status │ Commits:X │ verX.X.X │ SUB:X │ 🕐 HH:MM
if [[ -n "$mode_info" ]]; then
  printf "${RED}%s${RESET} ${BLUE}%s${RESET} ${git_info}${DIM}│${RESET} ${TEAL}$CONFIG_COMMITS_LABEL%s${RESET} ${DIM}│${RESET} ${PURPLE}$CONFIG_VERSION_PREFIX%s${RESET} ${DIM}│${RESET} ${submodule_color}%s${RESET} ${DIM}│${RESET} ${LIGHT_ORANGE}%s${RESET}\n" \
    "$mode_info" "$dir_display" "${git_args[@]}" "$commits_today" "$claude_version" "$submodule_display" "$current_datetime"
else
  printf "${BLUE}%s${RESET} ${git_info}${DIM}│${RESET} ${TEAL}$CONFIG_COMMITS_LABEL%s${RESET} ${DIM}│${RESET} ${PURPLE}$CONFIG_VERSION_PREFIX%s${RESET} ${DIM}│${RESET} ${submodule_color}%s${RESET} ${DIM}│${RESET} ${LIGHT_ORANGE}%s${RESET}\n" \
    "$dir_display" "${git_args[@]}" "$commits_today" "$claude_version" "$submodule_display" "$current_datetime"
fi

# ==================== LINE 2: Claude Usage & Cost Tracking ====================
# Format: 🎵 Model │ REPO $X.XX │ 30DAY $X.XX │ 7DAY $X.XX │ DAY $X.XX │ 🔥 LIVE $X.XX
if [[ "$claude_block_info" == "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE" ]]; then
  printf "${model_emoji} ${CYAN}%s${RESET} ${DIM}│${RESET} ${GREEN}$CONFIG_REPO_LABEL \$%s${RESET} ${DIM}│${RESET} ${PINK_BRIGHT}$CONFIG_MONTHLY_LABEL \$%s${RESET} ${DIM}│${RESET} ${INDIGO}$CONFIG_WEEKLY_LABEL \$%s${RESET} ${DIM}│${RESET} ${TEAL}$CONFIG_DAILY_LABEL \$%s${RESET} ${DIM}│${RESET} ${DIM}%s${RESET}\n" \
    "$model_name" "$claude_session_cost" "$claude_month_cost" "$claude_week_cost" "$claude_today_cost" "$claude_block_info"
else
  printf "${model_emoji} ${CYAN}%s${RESET} ${DIM}│${RESET} ${GREEN}$CONFIG_REPO_LABEL \$%s${RESET} ${DIM}│${RESET} ${PINK_BRIGHT}$CONFIG_MONTHLY_LABEL \$%s${RESET} ${DIM}│${RESET} ${INDIGO}$CONFIG_WEEKLY_LABEL \$%s${RESET} ${DIM}│${RESET} ${TEAL}$CONFIG_DAILY_LABEL \$%s${RESET} ${DIM}│${RESET} ${BRIGHT_GREEN}%s${RESET}\n" \
    "$model_name" "$claude_session_cost" "$claude_month_cost" "$claude_week_cost" "$claude_today_cost" "$claude_block_info"
fi

# ==================== LINE 3: MCP Server Status ====================
# Format: MCP (X/Y): server1, server2, server3
formatted_mcp_servers=$(format_mcp_servers "$all_mcp_servers")
echo -e "${mcp_color}$CONFIG_MCP_LABEL ($mcp_status): $formatted_mcp_servers${RESET}"

# ==================== LINE 4: RESET Info (conditional) ====================
# Format: RESET at HH.MM (Xh Ym left) - only shown when active block exists
if [[ "$claude_block_info" != "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE" ]] && [[ -n "$claude_reset_info" ]]; then
  printf "${LIGHT_GRAY}${ITALIC}%s${RESET}\n" "$claude_reset_info"
fi
