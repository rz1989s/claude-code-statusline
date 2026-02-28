#!/bin/bash

# ============================================================================
# Claude Code Statusline - Wellness Module (Unified)
# ============================================================================
#
# Tracks active coding time with idle detection and optional focus mode.
# Idle gap > threshold auto-resets the timer (break detected).
# Focus mode (--focus start) overrides the display threshold temporarily.
#
# Cache files:
#   wellness_session_start  - epoch when current coding stretch began
#   wellness_last_active    - epoch of last statusline invocation
#   focus_active.json       - active focus session (managed by focus CLI)
#   focus_history.json      - completed focus sessions
#
# Dependencies: core.sh, cache.sh
# ============================================================================

[[ "${STATUSLINE_WELLNESS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_WELLNESS_LOADED=true

WELLNESS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"

# ============================================================================
# ACTIVITY TRACKING
# ============================================================================

# Stamp last activity time (called every statusline invocation)
update_wellness_activity() {
  mkdir -p "$WELLNESS_CACHE_DIR"
  date +%s > "$WELLNESS_CACHE_DIR/wellness_last_active"
}

# Get session start time, creating if absent
get_wellness_session_start() {
  local session_file="$WELLNESS_CACHE_DIR/wellness_session_start"
  if [[ -f "$session_file" ]]; then
    cat "$session_file"
  else
    local now; now=$(date +%s)
    mkdir -p "$WELLNESS_CACHE_DIR"
    echo "$now" > "$session_file"
    echo "$now"
  fi
}

# Reset session timer to now
reset_wellness_session() {
  mkdir -p "$WELLNESS_CACHE_DIR"
  date +%s > "$WELLNESS_CACHE_DIR/wellness_session_start"
}

# ============================================================================
# IDLE DETECTION
# ============================================================================

# Get active coding minutes, auto-resetting if idle gap detected
# Returns: integer minutes of current coding stretch
get_wellness_active_minutes() {
  local now; now=$(date +%s)
  local idle_threshold="${CONFIG_WELLNESS_IDLE_RESET_MINUTES:-15}"
  local idle_threshold_secs=$((idle_threshold * 60))

  local last_active_file="$WELLNESS_CACHE_DIR/wellness_last_active"
  if [[ -f "$last_active_file" ]]; then
    local last_active; last_active=$(cat "$last_active_file")
    local gap=$((now - last_active))

    if [[ "$gap" -ge "$idle_threshold_secs" ]]; then
      # Idle gap detected - user took a break. Reset session.
      reset_wellness_session
      # Auto-stop abandoned focus sessions
      local abandon_threshold="${CONFIG_FOCUS_ABANDON_MINUTES:-120}"
      local abandon_secs=$((abandon_threshold * 60))
      if [[ "$gap" -ge "$abandon_secs" && -f "$WELLNESS_CACHE_DIR/focus_active.json" ]]; then
        _auto_stop_focus "$now"
      fi
      # Stamp activity and return 0 minutes
      update_wellness_activity
      echo "0"
      return 0
    fi
  fi

  # No idle gap - count from session start
  update_wellness_activity
  local session_start; session_start=$(get_wellness_session_start)
  local elapsed=$(( (now - session_start) / 60 ))
  echo "$elapsed"
}

# Auto-stop an abandoned focus session and save to history
_auto_stop_focus() {
  local now="${1:-$(date +%s)}"
  local focus_file="$WELLNESS_CACHE_DIR/focus_active.json"
  local history_file="$WELLNESS_CACHE_DIR/focus_history.json"

  [[ ! -f "$focus_file" ]] && return 0

  local start; start=$(jq -r '.start_time' "$focus_file" 2>/dev/null) || return 0
  local elapsed_minutes=$(( (now - start) / 60 ))

  local entry
  entry=$(jq --arg end "$now" --arg elapsed "$elapsed_minutes" --arg status "abandoned" \
    '. + {end_time: ($end | tonumber), elapsed_minutes: ($elapsed | tonumber), status: $status}' \
    "$focus_file" 2>/dev/null) || return 0

  if [[ -f "$history_file" ]]; then
    local existing; existing=$(cat "$history_file" 2>/dev/null)
    echo "$existing" | jq --argjson new "$entry" '. + [$new]' > "${history_file}.tmp" 2>/dev/null
    mv "${history_file}.tmp" "$history_file"
  else
    echo "[$entry]" | jq '.' > "$history_file" 2>/dev/null
  fi

  rm -f "$focus_file"
}

# ============================================================================
# WELLNESS LEVEL CALCULATION
# ============================================================================

# Get wellness level based on elapsed minutes
# Args: $1=minutes
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
# THRESHOLD CALCULATION (focus-aware)
# ============================================================================

# Get the next relevant threshold to display
# When focus is active and not yet hit, show focus target
# Otherwise show next wellness threshold
# Args: $1=elapsed minutes
get_wellness_threshold() {
  local minutes="${1:-0}"
  local gentle="${CONFIG_WELLNESS_GENTLE_MINUTES:-45}"
  local warn="${CONFIG_WELLNESS_WARN_MINUTES:-90}"
  local urgent="${CONFIG_WELLNESS_URGENT_MINUTES:-120}"

  local focus_file="$WELLNESS_CACHE_DIR/focus_active.json"
  if [[ -f "$focus_file" ]]; then
    local focus_duration
    focus_duration=$(jq -r '.duration_minutes' "$focus_file" 2>/dev/null) || focus_duration=""
    if [[ -n "$focus_duration" && "$minutes" -lt "$focus_duration" ]]; then
      echo "$focus_duration"
      return 0
    fi
  fi

  # No focus or past focus target - use wellness thresholds
  if [[ "$minutes" -lt "$gentle" ]]; then
    echo "$gentle"
  elif [[ "$minutes" -lt "$warn" ]]; then
    echo "$warn"
  elif [[ "$minutes" -lt "$urgent" ]]; then
    echo "$urgent"
  else
    echo "$urgent"
  fi
}

# ============================================================================
# FOCUS STATE HELPERS
# ============================================================================

# Check if focus is active
is_focus_active() {
  [[ -f "$WELLNESS_CACHE_DIR/focus_active.json" ]]
}

# Check if focus target has been reached
# Args: $1=elapsed minutes
is_focus_complete() {
  local minutes="${1:-0}"
  local focus_file="$WELLNESS_CACHE_DIR/focus_active.json"
  [[ ! -f "$focus_file" ]] && return 1

  local focus_duration
  focus_duration=$(jq -r '.duration_minutes' "$focus_file" 2>/dev/null) || return 1
  [[ "$minutes" -ge "$focus_duration" ]]
}

# Get focus target duration (or empty if no focus)
get_focus_duration() {
  local focus_file="$WELLNESS_CACHE_DIR/focus_active.json"
  [[ ! -f "$focus_file" ]] && return 1
  jq -r '.duration_minutes' "$focus_file" 2>/dev/null
}

# ============================================================================
# DISPLAY FORMATTING
# ============================================================================

# Format unified wellness display
# Args: $1=minutes, $2=level, $3=threshold
format_wellness_display() {
  local minutes="${1:-0}"
  local level="${2:-normal}"
  local threshold="${3:-45}"

  local base="☕ Coding ${minutes}m/${threshold}m"

  # Wellness level message
  local message=""
  case "$level" in
    "gentle")  message=" · Break soon" ;;
    "warn")    message=" · Take a break" ;;
    "urgent")  message=" · Break overdue!" ;;
  esac

  # Focus suffix
  local focus_suffix=""
  if is_focus_active 2>/dev/null; then
    local focus_dur; focus_dur=$(get_focus_duration 2>/dev/null) || focus_dur=""
    if [[ -n "$focus_dur" ]]; then
      if is_focus_complete "$minutes" 2>/dev/null; then
        focus_suffix=" │ FOCUS ${focus_dur}m ✓"
      else
        focus_suffix=" [FOCUS]"
      fi
    fi
  fi

  echo "${base}${message}${focus_suffix}"
}

# ============================================================================
# MODULE LOADED
# ============================================================================

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Wellness module loaded (unified)" "INFO" || true
