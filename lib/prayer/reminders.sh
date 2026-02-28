#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Break Reminders Module
# ============================================================================
#
# Provides prayer break reminder functionality with configurable thresholds.
# Integrates with the prayer system to notify users of upcoming prayer times
# at headsup, prepare, and imminent levels.
#
# Dependencies: core.sh (debug_log)
# Configuration: prayer.reminders.* in Config.toml
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_REMINDERS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_REMINDERS_LOADED=true

# ============================================================================
# REMINDER LEVEL DETECTION
# ============================================================================

# Get prayer reminder level based on minutes until next prayer
# Args: $1=minutes_until_prayer
# Returns: normal/headsup/prepare/imminent
get_prayer_reminder_level() {
  local minutes="${1:-0}"
  local headsup="${CONFIG_PRAYER_REMINDERS_HEADSUP_MINUTES:-30}"
  local prepare="${CONFIG_PRAYER_REMINDERS_PREPARE_MINUTES:-15}"
  local imminent="${CONFIG_PRAYER_REMINDERS_IMMINENT_MINUTES:-5}"

  # Validate input is numeric
  if ! [[ "$minutes" =~ ^[0-9]+$ ]]; then
    echo "normal"
    return 1
  fi

  if [[ "$minutes" -le "$imminent" ]]; then
    echo "imminent"
  elif [[ "$minutes" -le "$prepare" ]]; then
    echo "prepare"
  elif [[ "$minutes" -le "$headsup" ]]; then
    echo "headsup"
  else
    echo "normal"
  fi
}

# ============================================================================
# REMINDER DISPLAY FORMATTING
# ============================================================================

# Format prayer reminder display string
# Args: $1=prayer_name, $2=minutes_until, $3=level
format_prayer_reminder() {
  local prayer_name="${1:-}"
  local minutes="${2:-0}"
  local level="${3:-normal}"

  [[ -z "$prayer_name" ]] && return 0

  local message=""
  case "$level" in
    "headsup")  message="$prayer_name in ${minutes}m" ;;
    "prepare")  message="$prayer_name in ${minutes}m - wrap up current task" ;;
    "imminent") message="$prayer_name in ${minutes}m - time to prepare" ;;
    *)          message="" ;;
  esac

  echo "$message"
}

# ============================================================================
# NOTIFICATION COOLDOWN MANAGEMENT
# ============================================================================

# Check notification cooldown to prevent spam
# Args: $1=prayer_name
# Returns: 0 if should notify, 1 if still in cooldown
should_send_prayer_notification() {
  local prayer_name="${1:-}"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
  local cooldown_file="$cache_dir/prayer_notify_${prayer_name}"
  local cooldown="${CONFIG_PRAYER_REMINDERS_COOLDOWN_SECONDS:-900}"

  [[ -z "$prayer_name" ]] && return 1

  if [[ -f "$cooldown_file" ]]; then
    local last_notified now diff
    last_notified=$(cat "$cooldown_file" 2>/dev/null)
    now=$(date +%s)

    # Validate last_notified is numeric
    if [[ "$last_notified" =~ ^[0-9]+$ ]]; then
      diff=$((now - last_notified))
      if [[ $diff -lt $cooldown ]]; then
        return 1
      fi
    fi
  fi

  return 0
}

# Mark a prayer as notified (set cooldown)
# Args: $1=prayer_name
mark_prayer_notified() {
  local prayer_name="${1:-}"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"

  [[ -z "$prayer_name" ]] && return 1

  mkdir -p "$cache_dir"
  date +%s > "$cache_dir/prayer_notify_${prayer_name}"
}

# ============================================================================
# MAIN INTEGRATION
# ============================================================================

# Process prayer reminders -- main integration function
# Called during statusline render if prayer reminders are enabled
# Args: $1=prayer_name, $2=minutes_until_prayer
process_prayer_reminders() {
  local prayer_name="${1:-}"
  local minutes_until="${2:-0}"

  [[ -z "$prayer_name" ]] && return 0
  [[ "$minutes_until" -le 0 ]] && return 0

  local level
  level=$(get_prayer_reminder_level "$minutes_until")

  [[ "$level" == "normal" ]] && return 0

  local reminder
  reminder=$(format_prayer_reminder "$prayer_name" "$minutes_until" "$level")

  [[ -n "$reminder" ]] && echo "$reminder"

  return 0
}

# ============================================================================
# MODULE LOADED
# ============================================================================

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Prayer reminders module loaded" "INFO" || true
