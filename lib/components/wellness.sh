#!/bin/bash

# ============================================================================
# Claude Code Statusline - Wellness Display Component (Unified)
# ============================================================================
#
# Renders the unified wellness line: coding timer + threshold + focus mode.
# Format: ☕ Coding 20m/45m │ FOCUS 23m/50m
#
# Dependencies: wellness.sh
# ============================================================================

[[ "${STATUSLINE_COMPONENT_WELLNESS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COMPONENT_WELLNESS_LOADED=true

COMPONENT_WELLNESS_DISPLAY=""

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_wellness_data() {
  debug_log "Collecting wellness component data" "INFO"
  COMPONENT_WELLNESS_DISPLAY=""

  if [[ "${CONFIG_WELLNESS_ENABLED:-true}" != "true" ]]; then
    debug_log "Wellness disabled in configuration" "INFO"
    return 0
  fi

  # Get active minutes (handles idle detection + auto-reset + activity stamping)
  local minutes
  minutes=$(get_wellness_active_minutes 2>/dev/null) || minutes=0

  local level
  level=$(get_wellness_level "$minutes")

  # Get focus-aware threshold
  local threshold
  threshold=$(get_wellness_threshold "$minutes")

  COMPONENT_WELLNESS_DISPLAY=$(format_wellness_display "$minutes" "$level" "$threshold")

  debug_log "wellness data: ${COMPONENT_WELLNESS_DISPLAY} (level=$level, threshold=$threshold)" "INFO"
  return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_wellness() {
  if [[ -n "$COMPONENT_WELLNESS_DISPLAY" ]]; then
    echo "$COMPONENT_WELLNESS_DISPLAY"
    return 0
  else
    return 1
  fi
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

get_wellness_config() {
  local config_key="$1"
  local default_value="$2"
  case "$config_key" in
    "enabled")
      get_component_config "wellness" "enabled" "${default_value:-true}" ;;
    "show_in_statusline")
      get_component_config "wellness" "show_in_statusline" "${default_value:-true}" ;;
    *)
      echo "$default_value" ;;
  esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

register_component \
  "wellness" \
  "Session wellness with idle detection and focus mode" \
  "wellness display" \
  "$(get_wellness_config 'enabled' 'true')"

debug_log "Wellness display component loaded (unified)" "INFO"
