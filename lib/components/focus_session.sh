#!/bin/bash

# ============================================================================
# Claude Code Statusline - Focus Session Component
# ============================================================================
#
# Displays the current focus session status in the statusline.
# Shows elapsed time and target duration when a session is active.
#
# Dependencies: focus.sh (session file paths)
# ============================================================================

# Component data storage
COMPONENT_FOCUS_SESSION_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect focus session data for statusline display
collect_focus_session_data() {
  debug_log "Collecting focus_session component data" "INFO"

  COMPONENT_FOCUS_SESSION_DISPLAY=""

  # Check for active focus session file
  local session_file="${FOCUS_SESSION_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline/focus_active.json}"

  if [[ ! -f "$session_file" ]]; then
    debug_log "focus_session: no active session" "DEBUG"
    return 0
  fi

  local now start elapsed duration
  now=$(date +%s)
  start=$(jq -r '.start_time' "$session_file" 2>/dev/null) || return 0
  elapsed=$(( (now - start) / 60 ))
  duration=$(jq -r '.duration_minutes' "$session_file" 2>/dev/null) || duration=50

  COMPONENT_FOCUS_SESSION_DISPLAY="FOCUS | ${elapsed}m/${duration}m"

  debug_log "focus_session data: display=$COMPONENT_FOCUS_SESSION_DISPLAY" "INFO"
  return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render focus session component
render_focus_session() {
  if [[ -z "$COMPONENT_FOCUS_SESSION_DISPLAY" ]]; then
    return 1  # No content to render
  fi

  echo "$COMPONENT_FOCUS_SESSION_DISPLAY"
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_focus_session_config() {
  local config_key="$1"
  local default_value="$2"

  case "$config_key" in
    "enabled")
      get_component_config "focus_session" "enabled" "${default_value:-true}"
      ;;
    "hide_when_inactive")
      get_component_config "focus_session" "hide_when_inactive" "${default_value:-true}"
      ;;
    *)
      echo "$default_value"
      ;;
  esac
}

# ============================================================================
# COMPONENT INTERFACE COMPLIANCE
# ============================================================================

# Component metadata
FOCUS_SESSION_COMPONENT_NAME="focus_session"
FOCUS_SESSION_COMPONENT_DESCRIPTION="Focus session timer display"
FOCUS_SESSION_COMPONENT_VERSION="2.19.0"
FOCUS_SESSION_COMPONENT_DEPENDENCIES=()

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the focus_session component
register_component \
  "focus_session" \
  "Focus session timer display" \
  "none" \
  "$(get_focus_session_config 'enabled' 'true')"

debug_log "Focus session component loaded" "INFO"
