#!/bin/bash

# ============================================================================
# Claude Code Statusline - AWS Bedrock Model Component
# ============================================================================
#
# Resolves AWS Bedrock inference profile ARNs to friendly model names.
# e.g., arn:aws:bedrock:us-east-2:...:application-inference-profile/xyz
# becomes: "Claude Opus 4.6 (us-east-2)"
#
# Original feature by Jon Whitcraft (@jwhitcraft) - PR #246.
#
# Dependencies: json_fields.sh, display.sh, cache.sh, security.sh
# Optional: aws CLI, jq (graceful degradation without them)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_BEDROCK_MODEL_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_BEDROCK_MODEL_LOADED=true

# Component data storage
COMPONENT_BEDROCK_MODEL_NAME=""
COMPONENT_BEDROCK_MODEL_REGION=""
COMPONENT_BEDROCK_MODEL_PROFILE_ID=""
COMPONENT_BEDROCK_MODEL_IS_BEDROCK=""

# Claude Code settings cache (populated once per session)
_BEDROCK_SETTINGS_LOADED=""
_BEDROCK_SETTINGS_USE_BEDROCK=""
_BEDROCK_SETTINGS_AWS_PROFILE=""
_BEDROCK_SETTINGS_AWS_REGION=""

# ============================================================================
# INPUT SANITIZATION
# ============================================================================

# Sanitize a value for safe use in shell commands.
# Allows only alphanumeric chars, hyphens, underscores, and dots.
_sanitize_bedrock_value() {
  local input="$1"
  printf '%s' "$input" | tr -cd '[:alnum:]\-_.'
}

# ============================================================================
# ARN DETECTION & PARSING
# ============================================================================

is_bedrock_arn() {
  [[ -n "${1:-}" && "$1" == arn:aws:bedrock:*:*:application-inference-profile/* ]]
}

parse_bedrock_region() {
  local arn="$1"
  local region
  region=$(echo "$arn" | cut -d':' -f4)
  _sanitize_bedrock_value "$region"
}

parse_bedrock_profile_id() {
  local arn="$1"
  local profile_id="${arn##*/}"
  _sanitize_bedrock_value "$profile_id"
}

# ============================================================================
# CLAUDE CODE SETTINGS INTEGRATION
# ============================================================================

_load_claude_settings() {
  if [[ "$_BEDROCK_SETTINGS_LOADED" == "true" ]]; then
    return 0
  fi
  _BEDROCK_SETTINGS_LOADED="true"

  local settings_file="$HOME/.claude/settings.json"
  if [[ ! -f "$settings_file" ]]; then
    debug_log "Claude settings not found at $settings_file" "INFO"
    return 1
  fi

  if ! command_exists jq; then
    debug_log "jq not available, cannot parse Claude settings" "WARN"
    return 1
  fi

  local env_json
  env_json=$(jq -r '.env // empty' "$settings_file" 2>/dev/null)
  if [[ -z "$env_json" || "$env_json" == "null" ]]; then
    debug_log "No env block in Claude settings" "INFO"
    return 1
  fi

  _BEDROCK_SETTINGS_USE_BEDROCK=$(echo "$env_json" | jq -r '.CLAUDE_CODE_USE_BEDROCK // empty' 2>/dev/null)
  _BEDROCK_SETTINGS_AWS_PROFILE=$(_sanitize_bedrock_value "$(echo "$env_json" | jq -r '.AWS_PROFILE // empty' 2>/dev/null)")
  _BEDROCK_SETTINGS_AWS_REGION=$(_sanitize_bedrock_value "$(echo "$env_json" | jq -r '.AWS_REGION // empty' 2>/dev/null)")

  debug_log "Claude settings: use_bedrock=$_BEDROCK_SETTINGS_USE_BEDROCK profile=$_BEDROCK_SETTINGS_AWS_PROFILE region=$_BEDROCK_SETTINGS_AWS_REGION" "INFO"
  return 0
}

is_bedrock_enabled() {
  _load_claude_settings
  [[ "$_BEDROCK_SETTINGS_USE_BEDROCK" == "true" ]]
}

get_bedrock_aws_profile() {
  _load_claude_settings
  echo "${_BEDROCK_SETTINGS_AWS_PROFILE:-}"
}

# ============================================================================
# FRIENDLY NAME RESOLUTION
# ============================================================================

# Best-effort cleanup of raw model ID to readable name
_cleanup_model_id() {
  local model_id="$1"
  local cleaned="$model_id"
  # Strip provider prefixes
  cleaned="${cleaned#anthropic.}"
  cleaned="${cleaned#us.anthropic.}"
  # Strip version suffixes (:N and -vN)
  cleaned="${cleaned%%:*}"
  cleaned="${cleaned%%-v[0-9]*}"
  # Replace hyphens with spaces and title-case each word
  echo "$cleaned" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

# Look up a model ID in "modelId|modelName" lines. Falls back to cleanup.
_lookup_model_name() {
  local model_id="$1"
  local model_list="$2"

  if [[ -n "$model_list" ]]; then
    local base_id="${model_id%%:*}"
    local match
    # Exact match (base_id followed by pipe)
    match=$(echo "$model_list" | grep -F "${base_id}|" | head -1)
    if [[ -n "$match" ]]; then
      echo "${match#*|}"
      return 0
    fi
    # Prefix match
    match=$(echo "$model_list" | grep -F "${base_id}" | head -1)
    if [[ -n "$match" ]]; then
      echo "${match#*|}"
      return 0
    fi
  fi

  debug_log "Model ID not in list, using cleanup: $model_id" "INFO"
  _cleanup_model_id "$model_id"
}

# Resolve a Bedrock inference profile ARN to friendly model name via AWS CLI.
# Single code path used by both cached and uncached modes.
_resolve_bedrock_profile() {
  local arn="$1"
  local region="$2"
  local aws_profile="${3:-}"
  local timeout_duration="${4:-10s}"

  if ! command_exists aws || ! command_exists jq; then
    debug_log "aws/jq not available for Bedrock resolution" "WARN"
    return 1
  fi

  # Build common AWS args
  local -a profile_args=()
  if [[ -n "$aws_profile" ]]; then
    profile_args=(--profile "$aws_profile")
  fi

  # Build timeout command
  local -a timeout_cmd=()
  if command_exists timeout; then
    timeout_cmd=(timeout "$timeout_duration")
  elif command_exists gtimeout; then
    timeout_cmd=(gtimeout "$timeout_duration")
  fi

  # Step 1: get-inference-profile -> foundation model ARN
  local api_output
  api_output=$("${timeout_cmd[@]}" aws bedrock get-inference-profile \
    --inference-profile-identifier "$arn" \
    --region "$region" \
    --output json \
    "${profile_args[@]}" 2>/dev/null) || true

  if [[ -z "$api_output" ]]; then
    debug_log "Empty response from get-inference-profile" "WARN"
    return 1
  fi

  local model_arn
  model_arn=$(echo "$api_output" | jq -r '.models[0].modelArn // empty' 2>/dev/null)
  if [[ -z "$model_arn" ]]; then
    debug_log "Could not extract modelArn from response" "WARN"
    return 1
  fi

  local model_id="${model_arn##*/}"
  debug_log "Foundation model ID: $model_id" "INFO"

  # Step 2: list-foundation-models -> modelId|modelName lookup
  local model_list
  model_list=$("${timeout_cmd[@]}" aws bedrock list-foundation-models \
    --region "$region" \
    --by-provider anthropic \
    --output json \
    "${profile_args[@]}" 2>/dev/null | jq -r '.modelSummaries[] | "\(.modelId)|\(.modelName)"' 2>/dev/null) || true

  _lookup_model_name "$model_id" "$model_list"
}

# Cached wrapper using execute_cached_command.
# Writes a self-contained script with sanitized values only.
_resolve_bedrock_profile_cached() {
  local arn="$1"
  local region="$2"
  local profile_id="$3"
  local aws_profile="${4:-}"

  if [[ "${STATUSLINE_CACHE_LOADED:-}" != "true" ]]; then
    _resolve_bedrock_profile "$arn" "$region" "$aws_profile"
    return $?
  fi

  local cache_key="bedrock_profile_${profile_id}"
  local timeout_duration
  timeout_duration=$(get_bedrock_model_config 'timeout' '10s')

  # All values already sanitized by parse_bedrock_* and _load_claude_settings.
  # Build timeout prefix
  local timeout_prefix=""
  if command_exists timeout; then
    timeout_prefix="timeout ${timeout_duration} "
  elif command_exists gtimeout; then
    timeout_prefix="gtimeout ${timeout_duration} "
  fi

  local profile_flag=""
  if [[ -n "$aws_profile" ]]; then
    profile_flag="--profile ${aws_profile} "
  fi

  local script
  script="$(cat <<'OUTER'
model_arn=$(TIMEOUT_PREFIXaws bedrock get-inference-profile --inference-profile-identifier 'ARN_VALUE' --region 'REGION_VALUE' PROFILE_FLAG--output json 2>/dev/null | jq -r '.models[0].modelArn // empty' 2>/dev/null)
[ -z "$model_arn" ] && exit 1
model_id="${model_arn##*/}"
base_id="${model_id%%:*}"
model_list=$(TIMEOUT_PREFIXaws bedrock list-foundation-models --region 'REGION_VALUE' --by-provider anthropic PROFILE_FLAG--output json 2>/dev/null | jq -r '.modelSummaries[] | "\(.modelId)|\(.modelName)"' 2>/dev/null)
match=$(echo "$model_list" | grep -F "${base_id}|" | head -1)
if [ -n "$match" ]; then echo "${match#*|}"; exit 0; fi
match=$(echo "$model_list" | grep -F "${base_id}" | head -1)
if [ -n "$match" ]; then echo "${match#*|}"; exit 0; fi
cleaned="${model_id#anthropic.}"; cleaned="${cleaned#us.anthropic.}"; cleaned="${cleaned%%:*}"; cleaned="${cleaned%%-v[0-9]*}"
echo "$cleaned" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
OUTER
)"
  # Substitute sanitized values into the template
  script="${script//TIMEOUT_PREFIX/$timeout_prefix}"
  script="${script//ARN_VALUE/$arn}"
  script="${script//REGION_VALUE/$region}"
  script="${script//PROFILE_FLAG/$profile_flag}"

  execute_cached_command \
    "$cache_key" \
    "$CACHE_DURATION_PERMANENT" \
    "validate_command_output" \
    "false" \
    "false" \
    bash -c "$script"
}

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_bedrock_model_data() {
  debug_log "Collecting bedrock_model component data" "INFO"

  COMPONENT_BEDROCK_MODEL_IS_BEDROCK="false"
  COMPONENT_BEDROCK_MODEL_NAME=""
  COMPONENT_BEDROCK_MODEL_REGION=""
  COMPONENT_BEDROCK_MODEL_PROFILE_ID=""

  # Gate 1: Config.toml enabled check
  if [[ "$(get_bedrock_model_config 'enabled' 'false')" != "true" ]]; then
    return 0
  fi

  # Gate 2: CLAUDE_CODE_USE_BEDROCK setting
  if ! is_bedrock_enabled; then
    return 0
  fi

  # Extract raw model value from JSON input
  local raw_model=""
  if [[ -n "${STATUSLINE_INPUT_JSON:-}" ]] && command_exists jq; then
    raw_model=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '
      if (.model | type) == "object" then
        (.model.model_id // .model.api_model_id // .model.model // .model.display_name)
      else .model end // empty
    ' 2>/dev/null)
  fi

  # Fall back to model_name global (same as model_info.sh)
  if [[ -z "$raw_model" ]]; then
    raw_model="${model_name:-}"
  fi

  # Gate 3: Must be a Bedrock ARN
  if ! is_bedrock_arn "$raw_model"; then
    return 0
  fi

  COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
  COMPONENT_BEDROCK_MODEL_REGION=$(parse_bedrock_region "$raw_model")
  COMPONENT_BEDROCK_MODEL_PROFILE_ID=$(parse_bedrock_profile_id "$raw_model")

  debug_log "Bedrock ARN detected: region=$COMPONENT_BEDROCK_MODEL_REGION profile=$COMPONENT_BEDROCK_MODEL_PROFILE_ID" "INFO"

  local aws_profile
  aws_profile=$(get_bedrock_aws_profile)

  local resolved_name
  resolved_name=$(_resolve_bedrock_profile_cached "$raw_model" "$COMPONENT_BEDROCK_MODEL_REGION" "$COMPONENT_BEDROCK_MODEL_PROFILE_ID" "$aws_profile") || true

  if [[ -n "$resolved_name" ]]; then
    COMPONENT_BEDROCK_MODEL_NAME="$resolved_name"
  else
    COMPONENT_BEDROCK_MODEL_NAME="profile:${COMPONENT_BEDROCK_MODEL_PROFILE_ID}"
  fi

  debug_log "Bedrock model resolved: $COMPONENT_BEDROCK_MODEL_NAME" "INFO"
  return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_bedrock_model() {
  if [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" != "true" ]]; then
    return 0
  fi

  local output=""
  local show_emoji
  show_emoji=$(get_bedrock_model_config 'show_emoji' 'true')

  if [[ "$show_emoji" == "true" ]]; then
    local model_emoji=""
    if [[ "$COMPONENT_BEDROCK_MODEL_NAME" != profile:* ]] && declare -f get_model_emoji &>/dev/null; then
      model_emoji=$(get_model_emoji "$COMPONENT_BEDROCK_MODEL_NAME")
    fi

    local cloud_emoji
    cloud_emoji=$(get_bedrock_model_config 'emoji' '')

    if [[ -n "$model_emoji" ]]; then
      output="${model_emoji} "
    fi
    if [[ -n "$cloud_emoji" ]]; then
      output="${output}${cloud_emoji} "
    fi
  fi

  output="${output}${CONFIG_CYAN:-}${COMPONENT_BEDROCK_MODEL_NAME}${CONFIG_RESET:-}"

  local show_region
  show_region=$(get_bedrock_model_config 'show_region' 'true')
  if [[ "$show_region" == "true" && -n "$COMPONENT_BEDROCK_MODEL_REGION" ]]; then
    output="${output} ${CONFIG_DIM:-}(${COMPONENT_BEDROCK_MODEL_REGION})${CONFIG_RESET:-}"
  fi

  echo "$output"
  return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

get_bedrock_model_config() {
  local key="${1:-component_name}"
  local default="${2:-}"
  case "$key" in
    "component_name"|"name") echo "bedrock_model" ;;
    "enabled") echo "${CONFIG_BEDROCK_MODEL_ENABLED:-${default:-false}}" ;;
    "show_emoji") echo "${CONFIG_BEDROCK_MODEL_SHOW_EMOJI:-${default:-true}}" ;;
    "emoji") echo "${CONFIG_BEDROCK_MODEL_EMOJI:-${default:-}}" ;;
    "show_region") echo "${CONFIG_BEDROCK_MODEL_SHOW_REGION:-${default:-true}}" ;;
    "timeout") echo "${CONFIG_BEDROCK_MODEL_TIMEOUT:-${default:-10s}}" ;;
    "description") echo "AWS Bedrock inference profile to friendly model name" ;;
    *) echo "$default" ;;
  esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

BEDROCK_MODEL_COMPONENT_NAME="bedrock_model"
BEDROCK_MODEL_COMPONENT_VERSION="2.21.0"
BEDROCK_MODEL_COMPONENT_DEPENDENCIES=("json_fields" "display" "cache")

register_component "bedrock_model" "AWS Bedrock inference profile to friendly model name" "display cache" "$(get_bedrock_model_config 'enabled' 'false')"
export -f collect_bedrock_model_data render_bedrock_model get_bedrock_model_config is_bedrock_arn parse_bedrock_region parse_bedrock_profile_id _sanitize_bedrock_value
debug_log "Bedrock model component loaded" "INFO"
