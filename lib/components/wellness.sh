#!/bin/bash

# ============================================================================
# Claude Code Statusline - Wellness Display Component
# ============================================================================
#
# This component displays wellness/break reminder information based on
# session duration. Shows escalating messages as coding session lengthens.
#
# Dependencies: wellness.sh, display.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COMPONENT_WELLNESS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COMPONENT_WELLNESS_LOADED=true

# Component data storage
COMPONENT_WELLNESS_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect wellness data based on session duration
collect_wellness_data() {
  debug_log "Collecting wellness component data" "INFO"

  COMPONENT_WELLNESS_DISPLAY=""

  # Check if wellness is enabled
  if [[ "${CONFIG_WELLNESS_ENABLED:-true}" != "true" ]]; then
    debug_log "Wellness mode disabled in configuration" "INFO"
    return 0
  fi

  local session_start
  session_start=$(get_wellness_session_start 2>/dev/null) || return 0

  local now
  now=$(date +%s)
  local elapsed_seconds=$((now - session_start))
  local elapsed_minutes=$((elapsed_seconds / 60))

  local level
  level=$(get_wellness_level "$elapsed_minutes")

  COMPONENT_WELLNESS_DISPLAY=$(format_wellness_display "$elapsed_minutes" "$level")

  debug_log "wellness data: ${COMPONENT_WELLNESS_DISPLAY} (level=$level)" "INFO"
  return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render wellness display
render_wellness() {
  if [[ -n "$COMPONENT_WELLNESS_DISPLAY" ]]; then
    echo "$COMPONENT_WELLNESS_DISPLAY"
    return 0
  else
    return 1  # No content to render
  fi
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_wellness_config() {
  local config_key="$1"
  local default_value="$2"

  case "$config_key" in
    "enabled")
      get_component_config "wellness" "enabled" "${default_value:-true}"
      ;;
    "show_in_statusline")
      get_component_config "wellness" "show_in_statusline" "${default_value:-true}"
      ;;
    *)
      echo "$default_value"
      ;;
  esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the wellness component
register_component \
  "wellness" \
  "Session wellness and break reminders" \
  "wellness display" \
  "$(get_wellness_config 'enabled' 'true')"

debug_log "Wellness display component loaded" "INFO"
