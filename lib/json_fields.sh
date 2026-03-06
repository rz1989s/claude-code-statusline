#!/bin/bash

# ============================================================================
# Claude Code Statusline - JSON Field Access Abstraction Layer
# ============================================================================
#
# Provides a unified interface for extracting fields from the Claude Code
# JSON input, with automatic path migration for schema changes across
# versions (e.g., v2.1.66 moved current_usage under context_window).
# Supports v2.1.6 through v2.1.69+ using feature detection (not version comparison).
#
# Path Migration Map:
#   current_usage.* -> context_window.current_usage.* (v2.1.66+)
#
# v2.1.69 Additions (no migration needed — new optional fields):
#   worktree.name, worktree.path, worktree.original_cwd, worktree.original_branch
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
  echo ".$path"
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

# Resolve a field path through the migration registry
#
# If the path matches a migration prefix, outputs two lines:
#   1. canonical path (new schema, tried first)
#   2. legacy path (original, tried second)
# If no migration matches, outputs the original path on one line.
#
# Usage: readarray -t paths < <(_resolve_migrated_path "current_usage.input_tokens")
_resolve_migrated_path() {
  local field_path="$1"

  local migration
  for migration in "${_JSON_FIELD_MIGRATIONS[@]}"; do
    local legacy_prefix="${migration%%|*}"
    local canonical_prefix="${migration##*|}"

    if [[ "$field_path" == "$legacy_prefix" || "$field_path" == "$legacy_prefix".* ]]; then
      local suffix="${field_path#"$legacy_prefix"}"
      local canonical_path="${canonical_prefix}${suffix}"

      debug_log "json_fields: migrating '$field_path' -> trying '$canonical_path' first" "DEBUG"

      echo "$canonical_path"
      echo "$field_path"
      return 0
    fi
  done

  # No migration match — return original path
  echo "$field_path"
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

  # Resolve through migration registry (may return 1 or 2 paths)
  local paths
  readarray -t paths < <(_resolve_migrated_path "$field_path")

  local p result
  for p in "${paths[@]}"; do
    if result=$(_jq_extract "$(_dot_to_jq "$p")"); then
      echo "$result"
      return 0
    fi
  done

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

  # Resolve through migration registry
  local paths
  readarray -t paths < <(_resolve_migrated_path "$field_path")

  local p jq_filter result
  for p in "${paths[@]}"; do
    jq_filter="$(_dot_to_jq "$p")"
    result=$(echo "$json" | jq -e "$jq_filter != null and $jq_filter != \"\" " 2>/dev/null) || continue
    [[ "$result" == "true" ]] && return 0
  done

  return 1
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

  # Resolve through migration registry
  local paths
  readarray -t paths < <(_resolve_migrated_path "$field_path")

  local p jq_filter result
  for p in "${paths[@]}"; do
    jq_filter="$(_dot_to_jq "$p")"
    result=$(echo "$json" | jq -r "if $jq_filter == true then \"true\" elif $jq_filter == false then \"false\" else empty end" 2>/dev/null) || true
    if [[ -n "$result" ]]; then
      echo "$result"
      return 0
    fi
  done

  echo "$default_value"
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

  # Resolve through migration registry
  local paths
  readarray -t paths < <(_resolve_migrated_path "$field_path")

  local p jq_filter result
  for p in "${paths[@]}"; do
    jq_filter="$(_dot_to_jq "$p")"
    result=$(echo "$json" | jq -r "if ($jq_filter | type) == \"number\" then $jq_filter | tostring else empty end" 2>/dev/null) || true
    if [[ -n "$result" ]]; then
      echo "$result"
      return 0
    fi
  done

  echo "$default_value"
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

export -f _dot_to_jq _jq_extract _resolve_migrated_path
export -f get_json_field has_json_field
export -f get_json_field_bool get_json_field_num
export -f validate_json_schema get_detected_cc_version
