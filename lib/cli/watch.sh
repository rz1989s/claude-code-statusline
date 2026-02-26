#!/bin/bash

# ============================================================================
# Claude Code Statusline - Watch Mode (Live Monitoring)
# ============================================================================
#
# Provides live monitoring dashboard with auto-refresh:
# - show_watch_mode()          - Main loop with configurable refresh
# - render_watch_dashboard()   - Single-frame dashboard render
# - validate_refresh_interval() - Validate and clamp refresh rate
#
# Dependencies: cost modules, report_format.sh (optional)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CLI_WATCH_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CLI_WATCH_LOADED=true

# Source formatting utilities if available
_WATCH_LIB_DIR="${BASH_SOURCE[0]%/*}"
source "${_WATCH_LIB_DIR}/report_format.sh" 2>/dev/null || true

# ============================================================================
# REFRESH INTERVAL VALIDATION
# ============================================================================

# Validate and clamp refresh interval
# Usage: validate_refresh_interval "10"
# Returns: validated number on stdout, exit 1 for non-numeric
# Min: 0.5s, Max: 300s
validate_refresh_interval() {
  local interval="$1"

  # Check for empty input
  if [[ -z "$interval" ]]; then
    echo "Error: refresh interval cannot be empty" >&2
    return 1
  fi

  # Check if numeric (integer or decimal, positive)
  # Use regex to validate before passing to awk
  if ! [[ "$interval" =~ ^[0-9]*\.?[0-9]+$ ]]; then
    echo "Error: refresh interval must be a number, got '$interval'" >&2
    return 1
  fi

  # Clamp to minimum 0.5, maximum 300
  local clamped
  clamped=$(awk "BEGIN { v = $interval; if (v < 0.5) v = 0.5; if (v > 300) v = 300; print v }")

  echo "$clamped"
  return 0
}

# ============================================================================
# DASHBOARD RENDERING
# ============================================================================

# Render a single frame of the watch dashboard
# Outputs a compact cost/session summary with timestamp header
render_watch_dashboard() {
  local refresh_interval="${1:-10}"
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")

  # Header
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  Claude Code Statusline - Live Monitor                     ║"
  echo "║  $timestamp  (refresh: ${refresh_interval}s)               ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""

  # Cost data section
  local usage_info=""
  if declare -f get_claude_usage_info &>/dev/null; then
    usage_info=$(get_claude_usage_info 2>/dev/null) || true
  fi

  if [[ -n "$usage_info" && "$usage_info" != *"-.--"* ]]; then
    # Parse usage info (format: session:month:week:today:block:reset)
    local session_cost month_cost week_cost today_cost block_info reset_info
    IFS=':' read -r session_cost month_cost week_cost today_cost block_info reset_info <<< "$usage_info"

    echo "  Cost Summary"
    if declare -f draw_table_separator &>/dev/null; then
      echo -n "  "
      draw_table_separator 50
    else
      echo "  ──────────────────────────────────────────────────"
    fi
    printf "  %-20s %s\n" "Session:" "\$${session_cost}"
    printf "  %-20s %s\n" "Today:" "\$${today_cost}"
    printf "  %-20s %s\n" "This Week:" "\$${week_cost}"
    printf "  %-20s %s\n" "This Month:" "\$${month_cost}"
    echo ""

    # Block info if available
    if [[ -n "$block_info" && "$block_info" != "No data" && "$block_info" != "Native calc unavailable" ]]; then
      echo "  Block Status: $block_info"
    fi

    # Reset info if available
    if [[ -n "$reset_info" && "$reset_info" != "Mock mode" && "$reset_info" != "Native calc unavailable" ]]; then
      echo "  Reset: $reset_info"
    fi
  else
    echo "  No cost data available"
    echo "  Run from within a Claude Code session for live data"
  fi

  echo ""
  echo "  Press Ctrl+C to exit"
}

# ============================================================================
# MAIN WATCH LOOP
# ============================================================================

# Main watch mode entry point
# Usage: show_watch_mode [refresh_interval]
# In test mode (STATUSLINE_TESTING=true), renders one frame and returns
show_watch_mode() {
  local raw_interval="${1:-10}"

  # Validate refresh interval
  local interval
  interval=$(validate_refresh_interval "$raw_interval") || {
    echo "Error: Invalid refresh interval '$raw_interval'" >&2
    return 1
  }

  # Test mode: render one frame and return immediately
  if [[ "${STATUSLINE_TESTING:-}" == "true" ]]; then
    render_watch_dashboard "$interval"
    return 0
  fi

  # Production mode: loop with clear + render + sleep
  trap 'echo ""; echo "Watch mode stopped."; exit 0' INT TERM

  while true; do
    # Clear screen
    tput clear 2>/dev/null || printf '\033[2J\033[H'

    render_watch_dashboard "$interval"

    sleep "$interval" 2>/dev/null || sleep 10
  done
}

# ============================================================================
# MODULE FOOTER
# ============================================================================

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Watch mode module loaded" "INFO" || true
