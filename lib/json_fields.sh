#!/bin/bash

# ============================================================================
# Claude Code Statusline - JSON Field Access Abstraction Layer
# ============================================================================
#
# Provides a unified interface for extracting fields from the Claude Code
# JSON input, with automatic path migration for schema changes across
# versions (e.g., v2.1.66 moved current_usage under context_window).
#
# Path Migration Map:
#   current_usage.* -> context_window.current_usage.* (v2.1.66+)
#
# Dependencies: core.sh (optional - degrades gracefully if unavailable)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_JSON_FIELDS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_JSON_FIELDS_LOADED=true

# ============================================================================
# SAFETY: Ensure debug_log is available (may load before core.sh)
# ============================================================================

if ! declare -f debug_log &>/dev/null; then
  debug_log() { :; }
fi

# ============================================================================
# INTERNAL: Detected Claude Code version (set by validate_json_schema)
# ============================================================================

export _STATUSLINE_DETECTED_CC_VERSION="unknown"

# ============================================================================
# PATH MIGRATION REGISTRY
# ============================================================================
# Format: "legacy_prefix|canonical_prefix"
# When a field_path starts with legacy_prefix, try canonical_prefix first,
# then fall back to the legacy path.

_JSON_FIELD_MIGRATIONS=(
  "current_usage|context_window.current_usage"
)

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

# Convert dot-notation path to jq filter
# Usage: _dot_to_jq "model.display_name" => ".model.display_name"
_dot_to_jq() {
  local path="$1"
  echo ".${path//./.}"
}

# Extract a raw value from STATUSLINE_INPUT_JSON using a jq filter
# Returns empty string if extraction fails or value is null
# Usage: _jq_extract ".model.display_name"
_jq_extract() {
  local jq_filter="$1"
  local json="${STATUSLINE_INPUT_JSON:-}"

  [[ -z "$json" ]] && return 1

  local result
  result=$(echo "$json" | jq -r "$jq_filter // empty" 2>/dev/null) || return 1

  if [[ -z "$result" || "$result" == "null" ]]; then
    return 1
  fi

  echo "$result"
  return 0
}

# get_json_field - Extract a field from the Claude Code JSON input
#
# Handles path migration transparently: if the requested path matches a
# known migration prefix, tries the canonical (new) path first, then
# falls back to the legacy path.
#
# Usage: get_json_field "field.path" [default_value]
# Examples:
#   get_json_field "model.display_name"              => "Opus"
#   get_json_field "version" "unknown"                => "2.1.66" or "unknown"
#   get_json_field "current_usage.input_tokens"       => tries context_window.current_usage.input_tokens first
get_json_field() {
  local field_path="$1"
  local default_value="${2:-}"
  local json="${STATUSLINE_INPUT_JSON:-}"

  # Fast path: empty JSON -> return default immediately
  if [[ -z "$json" ]]; then
    echo "$default_value"
    return 0
  fi

  # Check if field_path matches a migration prefix
  local migration
  for migration in "${_JSON_FIELD_MIGRATIONS[@]}"; do
    local legacy_prefix="${migration%%|*}"
    local canonical_prefix="${migration##*|}"

    if [[ "$field_path" == "$legacy_prefix" || "$field_path" == "$legacy_prefix".* ]]; then
      # Build the canonical path by replacing the legacy prefix
      local suffix="${field_path#"$legacy_prefix"}"
      local canonical_path="${canonical_prefix}${suffix}"

      debug_log "json_fields: migrating '$field_path' -> trying '$canonical_path' first" "DEBUG"

      # Try canonical path first (new schema)
      local result
      if result=$(_jq_extract "$(_dot_to_jq "$canonical_path")"); then
        echo "$result"
        return 0
      fi

      # Fall back to legacy path
      debug_log "json_fields: canonical path empty, trying legacy '$field_path'" "DEBUG"
      if result=$(_jq_extract "$(_dot_to_jq "$field_path")"); then
        echo "$result"
        return 0
      fi

      # Neither path had data
      echo "$default_value"
      return 0
    fi
  done

  # No migration needed - direct extraction
  local result
  if result=$(_jq_extract "$(_dot_to_jq "$field_path")"); then
    echo "$result"
    return 0
  fi

  echo "$default_value"
  return 0
}

# has_json_field - Check if a field exists and is non-null
#
# Usage: has_json_field "field.path"
# Returns: 0 if field exists and is non-null, 1 otherwise
has_json_field() {
  local field_path="$1"
  local json="${STATUSLINE_INPUT_JSON:-}"

  [[ -z "$json" ]] && return 1

  local jq_filter
  jq_filter="$(_dot_to_jq "$field_path")"

  local result
  result=$(echo "$json" | jq -e "$jq_filter != null and $jq_filter != \"\" " 2>/dev/null) || return 1

  [[ "$result" == "true" ]]
}

# get_json_field_bool - Extract a boolean field
#
# Usage: get_json_field_bool "field.path" [default]
# Returns: "true" or "false" (string)
get_json_field_bool() {
  local field_path="$1"
  local default_value="${2:-}"
  local json="${STATUSLINE_INPUT_JSON:-}"

  if [[ -z "$json" ]]; then
    echo "$default_value"
    return 0
  fi

  local jq_filter
  jq_filter="$(_dot_to_jq "$field_path")"

  local result
  result=$(echo "$json" | jq -r "if $jq_filter == true then \"true\" elif $jq_filter == false then \"false\" else empty end" 2>/dev/null) || true

  if [[ -n "$result" ]]; then
    echo "$result"
  else
    echo "$default_value"
  fi
  return 0
}

# get_json_field_num - Extract a numeric field
#
# Usage: get_json_field_num "field.path" [default]
# Returns: numeric value as string, or default
get_json_field_num() {
  local field_path="$1"
  local default_value="${2:-}"
  local json="${STATUSLINE_INPUT_JSON:-}"

  if [[ -z "$json" ]]; then
    echo "$default_value"
    return 0
  fi

  local jq_filter
  jq_filter="$(_dot_to_jq "$field_path")"

  local result
  result=$(echo "$json" | jq -r "if ($jq_filter | type) == \"number\" then $jq_filter | tostring else empty end" 2>/dev/null) || true

  if [[ -n "$result" ]]; then
    echo "$result"
  else
    echo "$default_value"
  fi
  return 0
}

# validate_json_schema - Detect Claude Code version from input JSON
#
# Sets _STATUSLINE_DETECTED_CC_VERSION for downstream consumers.
# Call once after STATUSLINE_INPUT_JSON is populated.
#
# Usage: validate_json_schema
validate_json_schema() {
  local json="${STATUSLINE_INPUT_JSON:-}"

  if [[ -z "$json" ]]; then
    export _STATUSLINE_DETECTED_CC_VERSION="unknown"
    return 0
  fi

  local version
  version=$(echo "$json" | jq -r '.version // empty' 2>/dev/null) || true

  if [[ -n "$version" && "$version" != "null" ]]; then
    export _STATUSLINE_DETECTED_CC_VERSION="$version"
    debug_log "json_fields: detected Claude Code version: $version" "INFO"
  else
    export _STATUSLINE_DETECTED_CC_VERSION="unknown"
    debug_log "json_fields: no version field in input JSON" "DEBUG"
  fi

  return 0
}

# get_detected_cc_version - Return the detected Claude Code version
#
# Must call validate_json_schema first.
# Usage: version=$(get_detected_cc_version)
get_detected_cc_version() {
  echo "${_STATUSLINE_DETECTED_CC_VERSION:-unknown}"
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f _dot_to_jq _jq_extract
export -f get_json_field has_json_field
export -f get_json_field_bool get_json_field_num
export -f validate_json_schema get_detected_cc_version
