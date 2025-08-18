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
CONFIG_MCP_TIMEOUT="3s"
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

input=$(cat)
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')

# Navigate to the directory
cd "$current_dir" 2>/dev/null || cd ~

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

  # Use gtimeout on macOS (via brew coreutils) or built-in timeout on Linux, fallback to basic command
  local timeout_cmd=""
  if command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout $CONFIG_MCP_TIMEOUT"
  elif command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout $CONFIG_MCP_TIMEOUT"
  fi

  if mcp_list_output=$($timeout_cmd claude mcp list 2>/dev/null); then
    # Count connected servers (lines with "✓ Connected")
    connected_count=$(echo "$mcp_list_output" | grep "✓ Connected" | wc -l | tr -d ' ')

    # Count total servers (lines with server names, excluding the "Checking..." line)
    # Look for lines that have server names followed by ":" and a command/URL
    total_count=$(echo "$mcp_list_output" | grep -E "^[a-zA-Z0-9_-]+:" | wc -l | tr -d ' ')

    # Return connected/total format
    echo "${connected_count}/${total_count}"
  else
    echo "?/?"
  fi
}

# Get all MCP servers with their status
get_all_mcp_servers() {
  local timeout_cmd=""
  if command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout $CONFIG_MCP_TIMEOUT"
  elif command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout $CONFIG_MCP_TIMEOUT"
  fi

  local mcp_list_output
  if mcp_list_output=$($timeout_cmd claude mcp list 2>/dev/null); then
    local all_servers=""
    while IFS= read -r line; do
      # Look for lines with server names (format: "server-name: ...")
      if echo "$line" | grep -q "^[a-zA-Z0-9_-]*:"; then
        local server_name=$(echo "$line" | grep -o "^[a-zA-Z0-9_-]*" | head -1)
        if [ -n "$server_name" ]; then
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
  local timeout_cmd=""
  if command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout $CONFIG_MCP_TIMEOUT"
  elif command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout $CONFIG_MCP_TIMEOUT"
  fi

  local mcp_list_output
  if mcp_list_output=$($timeout_cmd claude mcp list 2>/dev/null); then
    # Extract server names that are connected (have "✓ Connected" status)
    local active_servers=""
    while IFS= read -r line; do
      if echo "$line" | grep -q "✓ Connected"; then
        # Extract server name (everything before the first colon)
        local server_name=$(echo "$line" | grep -o "^[a-zA-Z0-9_-]*" | head -1)
        if [ -n "$server_name" ]; then
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
  local current_session_id=$(echo "$current_dir" | sed 's|/|-|g')

  # Use timeout to avoid blocking
  local timeout_cmd=""
  if command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout $CONFIG_CCUSAGE_TIMEOUT"
  elif command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout $CONFIG_CCUSAGE_TIMEOUT"
  fi

  # Get current session cost
  local session_cost="0.00"
  if session_data=$($timeout_cmd bunx ccusage session --since "$seven_days_ago" --json 2>/dev/null); then
    session_cost=$(echo "$session_data" | jq -r --arg session_id "$current_session_id" '.sessions[] | select(.sessionId == $session_id) | .totalCost // 0' 2>/dev/null | head -1)
    if [ -z "$session_cost" ] || [ "$session_cost" = "null" ]; then
      session_cost="0.00"
    fi
  fi

  # Get today's cost and weekly cost
  local today_cost="0.00"
  local week_cost="0.00"
  if daily_data=$($timeout_cmd bunx ccusage daily --since "$seven_days_ago" --json 2>/dev/null); then
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
    week_cost=$(echo "$total_cost - $today_cost" | bc -l 2>/dev/null || echo "0.00")
    # Ensure week_cost is formatted properly
    week_cost=$(printf "%.2f" "$week_cost" 2>/dev/null || echo "0.00")
  fi

  # Get 30-day cost
  local month_cost="0.00"
  if monthly_data=$($timeout_cmd bunx ccusage daily --since "$thirty_days_ago" --json 2>/dev/null); then
    month_cost=$(echo "$monthly_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)
    if [ -z "$month_cost" ] || [ "$month_cost" = "null" ]; then
      month_cost="0.00"
    fi
  fi

  # Get active block info
  local block_cost_info="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
  local reset_time_info="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"

  if block_data=$($timeout_cmd bunx ccusage blocks --active --json 2>/dev/null); then
    local block_cost=$(echo "$block_data" | jq -r '.blocks[0].costUSD // 0' 2>/dev/null)
    local remaining_minutes=$(echo "$block_data" | jq -r '.blocks[0].projection.remainingMinutes // 0' 2>/dev/null)

    if [ -n "$block_cost" ] && [ "$block_cost" != "null" ] && [ "$block_cost" != "0" ]; then
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
        reset_time=$(python3 -c "import datetime; utc_time = datetime.datetime.fromisoformat('$end_time'.replace('Z', '+00:00')); local_time = utc_time.replace(tzinfo=datetime.timezone.utc).astimezone(); print(local_time.strftime('%H.%M'))" 2>/dev/null)
      fi

      block_cost_info=$(printf "$CONFIG_LIVE_BLOCK_EMOJI $CONFIG_LIVE_LABEL \$%.2f" "$block_cost")
      if [ -n "$reset_time" ]; then
        reset_time_info=$(printf "$CONFIG_RESET_LABEL at %s (%s)" "$reset_time" "$time_str")
      else
        reset_time_info=$(printf "$CONFIG_RESET_LABEL (%s)" "$time_str")
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
  local timeout_cmd=""
  if command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout $CONFIG_VERSION_TIMEOUT"
  elif command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout $CONFIG_VERSION_TIMEOUT"
  fi

  local version
  if version=$($timeout_cmd claude --version 2>/dev/null | head -1); then
    # Extract just the version number (e.g., "1.0.81" from "1.0.81 (Claude Code)")
    local clean_version
    clean_version=$(echo "$version" | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
    if [ -n "$clean_version" ]; then
      echo "$clean_version" >"$cache_file" 2>/dev/null
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
