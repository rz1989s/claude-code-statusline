#!/bin/bash

# ============================================================================
# Claude Code Statusline - AWS Bedrock Model Component
# ============================================================================
#
# Resolves AWS Bedrock inference profile ARNs to friendly model names.
# For example: arn:aws:bedrock:us-east-2:...:application-inference-profile/xyz
# becomes: "Claude Opus 4.6 (us-east-2)"
#
# Uses the AWS CLI to resolve inference profiles, with aggressive caching
# (24 hours) since profile-to-model mappings essentially never change.
#
# Dependencies: cache.sh, display.sh
# Optional: aws CLI, jq (graceful degradation without them)
# ============================================================================

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
# CLAUDE CODE SETTINGS INTEGRATION
# ============================================================================

# Read Claude Code's ~/.claude/settings.json to extract Bedrock env vars.
# This gives us CLAUDE_CODE_USE_BEDROCK (gate), AWS_PROFILE (auth), and
# AWS_REGION (fallback). Results are cached for the session lifetime.
_load_claude_settings() {
    # Only load once per session
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

    # Extract env vars in a single jq call
    local env_json
    env_json=$(jq -r '.env // empty' "$settings_file" 2>/dev/null)
    if [[ -z "$env_json" || "$env_json" == "null" ]]; then
        debug_log "No env block in Claude settings" "INFO"
        return 1
    fi

    _BEDROCK_SETTINGS_USE_BEDROCK=$(echo "$env_json" | jq -r '.CLAUDE_CODE_USE_BEDROCK // empty' 2>/dev/null)
    _BEDROCK_SETTINGS_AWS_PROFILE=$(echo "$env_json" | jq -r '.AWS_PROFILE // empty' 2>/dev/null)
    _BEDROCK_SETTINGS_AWS_REGION=$(echo "$env_json" | jq -r '.AWS_REGION // empty' 2>/dev/null)

    debug_log "Claude settings: use_bedrock=$_BEDROCK_SETTINGS_USE_BEDROCK profile=$_BEDROCK_SETTINGS_AWS_PROFILE region=$_BEDROCK_SETTINGS_AWS_REGION" "INFO"
    return 0
}

# Check if Bedrock is enabled via Claude Code settings
is_bedrock_enabled() {
    _load_claude_settings
    [[ "$_BEDROCK_SETTINGS_USE_BEDROCK" == "true" ]]
}

# Get the AWS profile from Claude Code settings (empty string if not set)
get_bedrock_aws_profile() {
    _load_claude_settings
    echo "${_BEDROCK_SETTINGS_AWS_PROFILE:-}"
}

# ============================================================================
# ARN DETECTION & PARSING
# ============================================================================

# Check if a string is a Bedrock inference profile ARN
is_bedrock_arn() {
    [[ "$1" == arn:aws:bedrock:*:*:application-inference-profile/* ]]
}

# Parse the AWS region from a Bedrock ARN (field 4, colon-delimited)
parse_bedrock_region() {
    local arn="$1"
    echo "$arn" | cut -d':' -f4
}

# Parse the inference profile ID from a Bedrock ARN (everything after last /)
parse_bedrock_profile_id() {
    local arn="$1"
    echo "${arn##*/}"
}

# ============================================================================
# FRIENDLY NAME RESOLUTION (Dynamic via AWS API)
# ============================================================================

# Fetch the foundation model list from Bedrock and return modelId→modelName
# mapping as "modelId|modelName" lines. Cached for 24 hours.
_fetch_foundation_model_list() {
    local region="$1"
    local aws_profile="${2:-}"
    local timeout_duration="${3:-10s}"

    local -a aws_args=(bedrock list-foundation-models
        --region "$region"
        --by-provider anthropic
        --output json)
    if [[ -n "$aws_profile" ]]; then
        aws_args+=(--profile "$aws_profile")
    fi

    local api_output
    if command_exists timeout; then
        api_output=$(timeout "$timeout_duration" aws "${aws_args[@]}" 2>/dev/null)
    elif command_exists gtimeout; then
        api_output=$(gtimeout "$timeout_duration" aws "${aws_args[@]}" 2>/dev/null)
    else
        api_output=$(aws "${aws_args[@]}" 2>/dev/null)
    fi

    if [[ -z "$api_output" ]]; then
        debug_log "Empty response from list-foundation-models" "WARN"
        return 1
    fi

    # Output "modelId|modelName" lines for lookup
    echo "$api_output" | jq -r '.modelSummaries[] | "\(.modelId)|\(.modelName)"' 2>/dev/null
}

# Cached wrapper for foundation model list (shared across all profiles in a region)
_fetch_foundation_model_list_cached() {
    local region="$1"
    local aws_profile="${2:-}"
    local timeout_duration="${3:-10s}"

    if [[ "${STATUSLINE_CACHE_LOADED:-}" != "true" ]]; then
        _fetch_foundation_model_list "$region" "$aws_profile" "$timeout_duration"
        return $?
    fi

    local cache_key="bedrock_models_${region}"

    # Build --profile flag for the self-contained script
    local profile_flag=""
    if [[ -n "$aws_profile" ]]; then
        profile_flag="--profile '${aws_profile}' "
    fi

    # Build timeout prefix
    local timeout_prefix=""
    if command_exists timeout; then
        timeout_prefix="timeout ${timeout_duration} "
    elif command_exists gtimeout; then
        timeout_prefix="gtimeout ${timeout_duration} "
    fi

    execute_cached_command \
        "$cache_key" \
        "$CACHE_DURATION_PERMANENT" \
        "validate_command_output" \
        "false" \
        "false" \
        bash -c "${timeout_prefix}aws bedrock list-foundation-models --region '${region}' --by-provider anthropic ${profile_flag}--output json 2>/dev/null | jq -r '.modelSummaries[] | \"\(.modelId)|\(.modelName)\"' 2>/dev/null"
}

# Look up a model ID in the foundation model list and return its friendly name.
# Model IDs from inference profiles may have version suffixes (e.g. ":0") that
# don't appear in the list, so we do a prefix match.
# Falls back to best-effort cleanup of the raw model ID.
_lookup_model_name() {
    local model_id="$1"
    local model_list="$2"

    if [[ -n "$model_list" ]]; then
        # Try exact match first (strip trailing :N version suffix for matching)
        local base_id="${model_id%%:*}"
        local match
        match=$(echo "$model_list" | grep -F "${base_id}|" | head -1)
        if [[ -n "$match" ]]; then
            echo "${match#*|}"
            return 0
        fi

        # Try prefix match (model list ID might also have :N suffix)
        match=$(echo "$model_list" | grep -F "${base_id}" | head -1)
        if [[ -n "$match" ]]; then
            echo "${match#*|}"
            return 0
        fi
    fi

    # Fallback: best-effort cleanup of raw model ID
    debug_log "Model ID not found in list, using best-effort cleanup: $model_id" "INFO"
    local cleaned="$model_id"
    cleaned="${cleaned#anthropic.}"
    cleaned="${cleaned#us.anthropic.}"
    cleaned="${cleaned%%:*}"
    cleaned="${cleaned%%-v[0-9]*}"
    # Replace hyphens with spaces and title-case (POSIX-compatible, works on BSD/GNU)
    echo "$cleaned" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

# ============================================================================
# AWS CLI RESOLUTION
# ============================================================================

# Resolve a Bedrock inference profile ARN to its friendly model name.
# Two API calls (both cached 24h):
#   1. get-inference-profile → foundation model ID
#   2. list-foundation-models → modelId-to-modelName lookup
resolve_bedrock_profile() {
    local arn="$1"
    local region="$2"
    local aws_profile="${3:-}"

    # Check for required tools
    if ! command_exists aws; then
        debug_log "AWS CLI not available for Bedrock resolution" "WARN"
        return 1
    fi

    if ! command_exists jq; then
        debug_log "jq not available for Bedrock JSON parsing" "WARN"
        return 1
    fi

    local timeout_duration
    timeout_duration=$(get_bedrock_model_config 'timeout' '10s')

    # Step 1: Resolve inference profile → foundation model ID
    local -a aws_args=(bedrock get-inference-profile
        --inference-profile-identifier "$arn"
        --region "$region"
        --output json)
    if [[ -n "$aws_profile" ]]; then
        aws_args+=(--profile "$aws_profile")
    fi

    local api_output
    if command_exists timeout; then
        api_output=$(timeout "$timeout_duration" aws "${aws_args[@]}" 2>/dev/null)
    elif command_exists gtimeout; then
        api_output=$(gtimeout "$timeout_duration" aws "${aws_args[@]}" 2>/dev/null)
    else
        api_output=$(aws "${aws_args[@]}" 2>/dev/null)
    fi

    if [[ -z "$api_output" ]]; then
        debug_log "Empty response from get-inference-profile" "WARN"
        return 1
    fi

    local model_arn
    model_arn=$(echo "$api_output" | jq -r '.models[0].modelArn // empty' 2>/dev/null)

    if [[ -z "$model_arn" ]]; then
        debug_log "Could not extract modelArn from Bedrock API response" "WARN"
        return 1
    fi

    # Parse foundation model ID from the model ARN
    # Format: arn:aws:bedrock:region::foundation-model/anthropic.claude-opus-4-6-v1:0
    local model_id="${model_arn##*/}"
    debug_log "Foundation model ID: $model_id" "INFO"

    # Step 2: Look up friendly name from foundation model list
    local model_list
    model_list=$(_fetch_foundation_model_list_cached "$region" "$aws_profile" "$timeout_duration")

    _lookup_model_name "$model_id" "$model_list"
}

# Cached wrapper: resolves inference profile → friendly name in one shot.
# The outer cache key is per-profile-ID; the model list has its own cache key.
resolve_bedrock_profile_cached() {
    local arn="$1"
    local region="$2"
    local profile_id="$3"
    local aws_profile="${4:-}"

    if [[ "${STATUSLINE_CACHE_LOADED:-}" != "true" ]]; then
        resolve_bedrock_profile "$arn" "$region" "$aws_profile"
        return $?
    fi

    local cache_key="bedrock_profile_${profile_id}"
    local timeout_duration
    timeout_duration=$(get_bedrock_model_config 'timeout' '10s')

    # Build timeout prefix for self-contained script
    local timeout_prefix=""
    if command_exists timeout; then
        timeout_prefix="timeout ${timeout_duration} "
    elif command_exists gtimeout; then
        timeout_prefix="gtimeout ${timeout_duration} "
    fi

    # Build --profile flag
    local profile_flag=""
    if [[ -n "$aws_profile" ]]; then
        profile_flag="--profile '${aws_profile}' "
    fi

    # Self-contained script: get inference profile → get model ID → look up in
    # foundation model list → return friendly name. No framework deps needed.
    # ARN format validated by is_bedrock_arn upstream — no special shell chars.
    local script
    script="$(cat <<SCRIPT
model_arn=\$(${timeout_prefix}aws bedrock get-inference-profile --inference-profile-identifier '${arn}' --region '${region}' ${profile_flag}--output json 2>/dev/null | jq -r '.models[0].modelArn // empty' 2>/dev/null)
[ -z "\$model_arn" ] && exit 1
model_id="\${model_arn##*/}"
base_id="\${model_id%%:*}"
model_list=\$(${timeout_prefix}aws bedrock list-foundation-models --region '${region}' --by-provider anthropic ${profile_flag}--output json 2>/dev/null | jq -r '.modelSummaries[] | "\(.modelId)|\(.modelName)"' 2>/dev/null)
match=\$(echo "\$model_list" | grep -F "\${base_id}|" | head -1)
if [ -n "\$match" ]; then
  echo "\${match#*|}"
  exit 0
fi
match=\$(echo "\$model_list" | grep -F "\${base_id}" | head -1)
if [ -n "\$match" ]; then
  echo "\${match#*|}"
  exit 0
fi
cleaned="\${model_id#anthropic.}"; cleaned="\${cleaned#us.anthropic.}"; cleaned="\${cleaned%%:*}"; cleaned="\${cleaned%%-v[0-9]*}"
echo "\$cleaned" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) \$i=toupper(substr(\$i,1,1)) substr(\$i,2)}1'
SCRIPT
)"

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

# Collect Bedrock model information
collect_bedrock_model_data() {
    debug_log "Collecting bedrock_model component data" "INFO"

    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="false"
    COMPONENT_BEDROCK_MODEL_NAME=""
    COMPONENT_BEDROCK_MODEL_REGION=""
    COMPONENT_BEDROCK_MODEL_PROFILE_ID=""

    # Gate 1: check if component is enabled in Config.toml (runtime check since
    # config isn't loaded at component source/registration time)
    if [[ "$(get_bedrock_model_config 'enabled' 'false')" != "true" ]]; then
        debug_log "bedrock_model component disabled in Config.toml" "INFO"
        return 0
    fi

    # Gate 2: check if Bedrock is enabled in Claude Code settings
    # ~/.claude/settings.json -> env.CLAUDE_CODE_USE_BEDROCK must be "true"
    if ! is_bedrock_enabled; then
        debug_log "Bedrock not enabled in Claude settings (CLAUDE_CODE_USE_BEDROCK != true)" "INFO"
        return 0
    fi

    # Extract the raw model value from multiple possible locations in the JSON
    local raw_model=""
    if [[ -n "${STATUSLINE_INPUT_JSON:-}" ]]; then
        # Try to find the ARN: check multiple fields where Bedrock ARN might live
        raw_model=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '
            if (.model | type) == "object" then
                (.model.model_id // .model.api_model_id // .model.model // .model.display_name)
            else .model end // empty
        ' 2>/dev/null)

        # Debug: log what we found for troubleshooting
        debug_log "bedrock_model raw_model from JSON: ${raw_model:-EMPTY}" "INFO"
        local model_type
        model_type=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.model | type' 2>/dev/null)
        debug_log "bedrock_model .model type: ${model_type:-UNKNOWN}" "INFO"
        if [[ "$model_type" == "object" ]]; then
            local model_keys
            model_keys=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.model | keys | join(",")' 2>/dev/null)
            debug_log "bedrock_model .model keys: ${model_keys:-NONE}" "INFO"
        fi
    fi

    # Fall back to model_name set by statusline.sh main script (same as model_info.sh)
    if [[ -z "$raw_model" ]]; then
        raw_model="${model_name:-}"
        debug_log "bedrock_model fell back to model_name: ${raw_model:-EMPTY}" "INFO"
    fi

    # Check if this is a Bedrock inference profile ARN
    if ! is_bedrock_arn "$raw_model"; then
        debug_log "Not a Bedrock ARN: ${raw_model:-empty}" "INFO"
        return 0
    fi

    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_REGION=$(parse_bedrock_region "$raw_model")
    COMPONENT_BEDROCK_MODEL_PROFILE_ID=$(parse_bedrock_profile_id "$raw_model")

    debug_log "Bedrock ARN detected: region=$COMPONENT_BEDROCK_MODEL_REGION profile=$COMPONENT_BEDROCK_MODEL_PROFILE_ID" "INFO"

    # Get AWS profile from Claude Code settings for authentication
    local aws_profile
    aws_profile=$(get_bedrock_aws_profile)
    if [[ -n "$aws_profile" ]]; then
        debug_log "Using AWS profile from Claude settings: $aws_profile" "INFO"
    fi

    # Attempt to resolve the friendly name
    local resolved_name
    resolved_name=$(resolve_bedrock_profile_cached "$raw_model" "$COMPONENT_BEDROCK_MODEL_REGION" "$COMPONENT_BEDROCK_MODEL_PROFILE_ID" "$aws_profile") || true

    if [[ -n "$resolved_name" ]]; then
        COMPONENT_BEDROCK_MODEL_NAME="$resolved_name"
        debug_log "Resolved Bedrock model: $COMPONENT_BEDROCK_MODEL_NAME" "INFO"
    else
        # Degraded mode: show profile ID
        COMPONENT_BEDROCK_MODEL_NAME="profile:${COMPONENT_BEDROCK_MODEL_PROFILE_ID}"
        debug_log "Using fallback profile ID display" "WARN"
    fi

    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render Bedrock model display
render_bedrock_model() {
    # If not a Bedrock ARN, output nothing (component is invisible)
    if [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" != "true" ]]; then
        return 0
    fi

    local output=""

    # Get model-family emoji if we have a resolved name (not fallback)
    local show_emoji
    show_emoji=$(get_bedrock_model_config 'show_emoji' 'true')

    if [[ "$show_emoji" == "true" ]]; then
        local model_emoji
        if [[ "$COMPONENT_BEDROCK_MODEL_NAME" != profile:* ]]; then
            model_emoji=$(get_model_emoji "$COMPONENT_BEDROCK_MODEL_NAME")
        else
            model_emoji=""
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

    # Model name in cyan
    output="${output}${CONFIG_CYAN}${COMPONENT_BEDROCK_MODEL_NAME}${CONFIG_RESET}"

    # Region in dim text (toggleable)
    local show_region
    show_region=$(get_bedrock_model_config 'show_region' 'true')

    if [[ "$show_region" == "true" && -n "$COMPONENT_BEDROCK_MODEL_REGION" ]]; then
        output="${output} ${CONFIG_DIM}(${COMPONENT_BEDROCK_MODEL_REGION})${CONFIG_RESET}"
    fi

    echo "$output"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
# Note: Config.toml compiles "bedrock_model.foo" to CONFIG_BEDROCK_MODEL_FOO,
# NOT CONFIG_COMPONENT_BEDROCK_MODEL_FOO. We read the actual compiled vars directly.
get_bedrock_model_config() {
    local config_key="$1"
    local default_value="$2"

    # Build the actual config variable name that the TOML compiler generates
    # bedrock_model.enabled -> CONFIG_BEDROCK_MODEL_ENABLED
    local config_var="CONFIG_BEDROCK_MODEL_${config_key^^}"
    local value="${!config_var:-}"

    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "${default_value}"
    fi
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the bedrock_model component as enabled at source time.
# Config is not yet loaded when components are sourced, so we always register
# as enabled here and check the actual config + CLAUDE_CODE_USE_BEDROCK gate
# at collect time in collect_bedrock_model_data().
register_component \
    "bedrock_model" \
    "AWS Bedrock inference profile to friendly model name" \
    "display cache" \
    "true"

debug_log "Bedrock model component loaded" "INFO"
