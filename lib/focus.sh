#!/bin/bash

# ============================================================================
# Claude Code Statusline - Focus Session Tracking Module
# ============================================================================
#
# Provides focus session management for tracking concentrated work periods.
# Sessions are stored as JSON in the cache directory for persistence.
#
# Features:
# - Start/stop timed focus sessions with configurable duration
# - Session status with elapsed/remaining time
# - Persistent history with human and JSON output formats
#
# Dependencies: jq (JSON parsing), date (time calculations)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_FOCUS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_FOCUS_LOADED=true

# ============================================================================
# FOCUS SESSION PATHS
# ============================================================================

FOCUS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline"
FOCUS_SESSION_FILE="$FOCUS_CACHE_DIR/focus_active.json"
FOCUS_HISTORY_FILE="$FOCUS_CACHE_DIR/focus_history.json"

# ============================================================================
# FOCUS SESSION MANAGEMENT
# ============================================================================

# Start a focus session
# Usage: focus_start
# Creates a new focus session with the configured default duration.
# Returns 1 if a session is already active.
focus_start() {
  mkdir -p "$FOCUS_CACHE_DIR"

  if [[ -f "$FOCUS_SESSION_FILE" ]]; then
    echo "Error: Focus session already active. Use --focus stop first." >&2
    return 1
  fi

  local now
  now=$(date +%s)
  local duration="${CONFIG_FOCUS_DEFAULT_DURATION:-50}"

  jq -n \
    --arg start "$now" \
    --arg duration "$duration" \
    --arg repo "$(pwd)" \
    '{start_time: ($start | tonumber), duration_minutes: ($duration | tonumber), repo: $repo, cost_start: 0, lines_added: 0, lines_removed: 0}' \
    > "$FOCUS_SESSION_FILE"

  echo "Focus session started (${duration}m target)"
}

# Stop active focus session
# Usage: focus_stop
# Ends the active session, saves to history, and displays a summary.
# Returns 1 if no session is active.
focus_stop() {
  if [[ ! -f "$FOCUS_SESSION_FILE" ]]; then
    echo "Error: No active focus session." >&2
    return 1
  fi

  local now start elapsed_seconds elapsed_minutes
  now=$(date +%s)
  start=$(jq -r '.start_time' "$FOCUS_SESSION_FILE" 2>/dev/null)
  elapsed_seconds=$((now - start))
  elapsed_minutes=$((elapsed_seconds / 60))

  # Build history entry with end time and elapsed
  local entry
  entry=$(jq --arg end "$now" --arg elapsed "$elapsed_minutes" \
    '. + {end_time: ($end | tonumber), elapsed_minutes: ($elapsed | tonumber)}' \
    "$FOCUS_SESSION_FILE" 2>/dev/null)

  # Append to history file
  if [[ -f "$FOCUS_HISTORY_FILE" ]]; then
    local existing
    existing=$(cat "$FOCUS_HISTORY_FILE" 2>/dev/null)
    echo "$existing" | jq --argjson new "$entry" '. + [$new]' > "${FOCUS_HISTORY_FILE}.tmp" 2>/dev/null
    mv "${FOCUS_HISTORY_FILE}.tmp" "$FOCUS_HISTORY_FILE"
  else
    echo "[$entry]" | jq '.' > "$FOCUS_HISTORY_FILE" 2>/dev/null
  fi

  rm -f "$FOCUS_SESSION_FILE"

  echo ""
  echo "  Focus Session Complete"
  echo "  ======================="
  echo "  Duration: ${elapsed_minutes}m"
  echo ""
}

# Show current focus session status
# Usage: focus_status
# Displays elapsed time and remaining time for the active session.
focus_status() {
  if [[ ! -f "$FOCUS_SESSION_FILE" ]]; then
    echo "No active focus session."
    return 0
  fi

  local now start elapsed_seconds elapsed_minutes duration
  now=$(date +%s)
  start=$(jq -r '.start_time' "$FOCUS_SESSION_FILE" 2>/dev/null)
  duration=$(jq -r '.duration_minutes' "$FOCUS_SESSION_FILE" 2>/dev/null)
  elapsed_seconds=$((now - start))
  elapsed_minutes=$((elapsed_seconds / 60))

  local remaining=$((duration - elapsed_minutes))
  [[ $remaining -lt 0 ]] && remaining=0

  echo ""
  echo "  FOCUS Session Active"
  echo "  ======================="
  echo "  Elapsed: ${elapsed_minutes}m / ${duration}m target"
  echo "  Remaining: ${remaining}m"
  echo ""
}

# Show focus session history
# Usage: focus_history [format]
# format: "human" (default) or "json"
focus_history() {
  local format="${1:-human}"

  if [[ ! -f "$FOCUS_HISTORY_FILE" ]]; then
    if [[ "$format" == "json" ]]; then
      echo "[]"
    else
      echo "No focus session history found."
    fi
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    cat "$FOCUS_HISTORY_FILE"
    return 0
  fi

  echo ""
  echo "  Focus Session History"
  echo "  ======================================="
  echo "  Date                | Duration | Repo"
  echo "  --------------------+----------+----------"

  jq -r '.[] | "\(.start_time)\t\(.elapsed_minutes)\t\(.repo)"' "$FOCUS_HISTORY_FILE" 2>/dev/null | while IFS=$'\t' read -r ts minutes repo; do
    local date_str
    # macOS date vs GNU date
    if date -j -f "%s" "$ts" "+%Y-%m-%d %H:%M" >/dev/null 2>&1; then
      date_str=$(date -j -f "%s" "$ts" "+%Y-%m-%d %H:%M" 2>/dev/null)
    else
      date_str=$(date -d "@$ts" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "unknown")
    fi
    local repo_name
    repo_name=$(basename "$repo")
    printf "  %-19s | %5sm   | %s\n" "$date_str" "$minutes" "$repo_name"
  done
  echo ""
}

# ============================================================================
# MODULE LOAD CONFIRMATION
# ============================================================================

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Focus module loaded" "INFO" || true
