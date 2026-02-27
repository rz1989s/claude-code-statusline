#!/bin/bash

# ============================================================================
# Claude Code Statusline - Wellness Mode Module
# ============================================================================
#
# Provides break reminder functionality based on session duration.
# Tracks session start time and provides escalating break reminders
# at configurable intervals (gentle -> warn -> urgent).
#
# Dependencies: core.sh, cache.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_WELLNESS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_WELLNESS_LOADED=true

# ============================================================================
# SESSION TRACKING
# ============================================================================

# Get session start time from cache
# Creates a new session timestamp if none exists
get_wellness_session_start() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
  local session_file="$cache_dir/wellness_session_start"

  if [[ -f "$session_file" ]]; then
    cat "$session_file"
  else
    # Create new session start
    local now
    now=$(date +%s)
    mkdir -p "$cache_dir"
    echo "$now" > "$session_file"
    echo "$now"
  fi
}

# Reset wellness session timer
# Called when user takes a break or explicitly resets
reset_wellness_session() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
  local session_file="$cache_dir/wellness_session_start"
  local now
  now=$(date +%s)
  mkdir -p "$cache_dir"
  echo "$now" > "$session_file"
}

# ============================================================================
# WELLNESS LEVEL CALCULATION
# ============================================================================

# Get wellness level based on session duration in minutes
# Args: $1=minutes elapsed
# Returns: normal/gentle/warn/urgent
get_wellness_level() {
  local minutes="${1:-0}"
  local gentle="${CONFIG_WELLNESS_GENTLE_MINUTES:-45}"
  local warn="${CONFIG_WELLNESS_WARN_MINUTES:-90}"
  local urgent="${CONFIG_WELLNESS_URGENT_MINUTES:-120}"

  if [[ "$minutes" -ge "$urgent" ]]; then
    echo "urgent"
  elif [[ "$minutes" -ge "$warn" ]]; then
    echo "warn"
  elif [[ "$minutes" -ge "$gentle" ]]; then
    echo "gentle"
  else
    echo "normal"
  fi
}

# ============================================================================
# DISPLAY FORMATTING
# ============================================================================

# Format wellness display string
# Args: $1=minutes, $2=level
format_wellness_display() {
  local minutes="${1:-0}"
  local level="${2:-normal}"

  local message=""
  case "$level" in
    "gentle")  message="Break soon" ;;
    "warn")    message="Take a break" ;;
    "urgent")  message="Break overdue!" ;;
    *)         message="" ;;
  esac

  if [[ -n "$message" ]]; then
    echo "${minutes}m | $message"
  else
    echo "${minutes}m"
  fi
}

# ============================================================================
# MODULE LOADED
# ============================================================================

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Wellness module loaded" "INFO" || true
