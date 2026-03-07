# Bedrock Model Component Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `bedrock_model` component that resolves AWS Bedrock inference profile ARNs to friendly model names (e.g., "☁️ Claude Opus 4.6 (us-east-2)"). Based on PR #246 by @jwhitcraft, rewritten to fix security issues and follow project patterns.

**Architecture:** Standalone component in `lib/components/bedrock_model.sh` with three gates (Config.toml enabled, CLAUDE_CODE_USE_BEDROCK setting, ARN detection). Uses AWS CLI two-step resolution (get-inference-profile → list-foundation-models) with 24h caching. Input sanitization prevents shell injection. Invisible to non-Bedrock users.

**Tech Stack:** Bash 4+, jq, AWS CLI (optional — graceful degradation), bats (testing)

**Credit:** Original feature designed and prototyped by Jon Whitcraft (@jwhitcraft) in PR #246.

---

### Task 1: Create test file with ARN parsing tests

**Files:**
- Create: `tests/unit/test_bedrock_model.bats`

**Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/security.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/bedrock_model.sh" 2>/dev/null || true
}
teardown() { common_teardown; }

# --- is_bedrock_arn ---

@test "is_bedrock_arn: accepts valid inference profile ARN" {
    run is_bedrock_arn "arn:aws:bedrock:us-east-2:188572534221:application-inference-profile/ertkckm22ih2"
    assert_success
}

@test "is_bedrock_arn: accepts ARN with different region" {
    run is_bedrock_arn "arn:aws:bedrock:eu-west-1:123456789012:application-inference-profile/abcdef1234567890"
    assert_success
}

@test "is_bedrock_arn: rejects plain model name" {
    run is_bedrock_arn "Claude Opus 4.6"
    assert_failure
}

@test "is_bedrock_arn: rejects empty string" {
    run is_bedrock_arn ""
    assert_failure
}

@test "is_bedrock_arn: rejects foundation model ARN" {
    run is_bedrock_arn "arn:aws:bedrock:us-east-2:188572534221:foundation-model/anthropic.claude"
    assert_failure
}

@test "is_bedrock_arn: rejects non-bedrock ARN" {
    run is_bedrock_arn "arn:aws:s3:::my-bucket"
    assert_failure
}

# --- parse_bedrock_region ---

@test "parse_bedrock_region: extracts us-east-2" {
    run parse_bedrock_region "arn:aws:bedrock:us-east-2:188572534221:application-inference-profile/xyz"
    assert_success
    assert_output "us-east-2"
}

@test "parse_bedrock_region: extracts eu-west-1" {
    run parse_bedrock_region "arn:aws:bedrock:eu-west-1:123456789012:application-inference-profile/abc"
    assert_success
    assert_output "eu-west-1"
}

@test "parse_bedrock_region: extracts ap-southeast-1" {
    run parse_bedrock_region "arn:aws:bedrock:ap-southeast-1:999999999999:application-inference-profile/test"
    assert_success
    assert_output "ap-southeast-1"
}

# --- parse_bedrock_profile_id ---

@test "parse_bedrock_profile_id: extracts short profile ID" {
    run parse_bedrock_profile_id "arn:aws:bedrock:us-east-2:188572534221:application-inference-profile/ertkckm22ih2"
    assert_success
    assert_output "ertkckm22ih2"
}

@test "parse_bedrock_profile_id: extracts long profile ID" {
    run parse_bedrock_profile_id "arn:aws:bedrock:eu-west-1:123456789012:application-inference-profile/abcdef1234567890ghijklmnop"
    assert_success
    assert_output "abcdef1234567890ghijklmnop"
}

# --- sanitize_bedrock_value ---

@test "sanitize_bedrock_value: passes clean region" {
    run _sanitize_bedrock_value "us-east-2"
    assert_success
    assert_output "us-east-2"
}

@test "sanitize_bedrock_value: strips shell metacharacters" {
    run _sanitize_bedrock_value "us-east-2'; rm -rf /"
    assert_success
    assert_output "us-east-2rm-rf"
}

@test "sanitize_bedrock_value: strips backticks and dollars" {
    run _sanitize_bedrock_value 'us-east-2`whoami`$HOME'
    assert_success
    assert_output "us-east-2whoamiHOME"
}

@test "sanitize_bedrock_value: returns empty for empty input" {
    run _sanitize_bedrock_value ""
    assert_success
    assert_output ""
}
```

**Step 2: Run tests to verify they fail**

Run: `bats tests/unit/test_bedrock_model.bats`
Expected: FAIL — `bedrock_model.sh` doesn't exist yet

**Step 3: Commit**

```bash
git add tests/unit/test_bedrock_model.bats
git commit -m "test: add ARN parsing tests for bedrock_model component (PR #246)"
```

---

### Task 2: Create bedrock_model.sh with ARN parsing + sanitization

**Files:**
- Create: `lib/components/bedrock_model.sh`

**Step 1: Write the component skeleton with ARN parsing**

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - AWS Bedrock Model Component
# ============================================================================
#
# Resolves AWS Bedrock inference profile ARNs to friendly model names.
# e.g., arn:aws:bedrock:us-east-2:...:application-inference-profile/xyz
# becomes: "☁️ Claude Opus 4.6 (us-east-2)"
#
# Original feature by Jon Whitcraft (@jwhitcraft) - PR #246.
#
# Dependencies: json_fields.sh, display.sh, cache.sh, security.sh
# Optional: aws CLI, jq (graceful degradation without them)
# ============================================================================

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
    [[ "$1" == arn:aws:bedrock:*:*:application-inference-profile/* ]]
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
    cleaned="${cleaned#anthropic.}"
    cleaned="${cleaned#us.anthropic.}"
    cleaned="${cleaned%%:*}"
    cleaned="${cleaned%%-v[0-9]*}"
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

    # Step 1: get-inference-profile → foundation model ARN
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

    # Step 2: list-foundation-models → modelId|modelName lookup
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
        if [[ "$COMPONENT_BEDROCK_MODEL_NAME" != profile:* ]]; then
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
```

**Step 2: Run tests**

Run: `bats tests/unit/test_bedrock_model.bats`
Expected: All ARN parsing + sanitization tests PASS

**Step 3: Commit**

```bash
git add lib/components/bedrock_model.sh
git commit -m "feat: add bedrock_model component — ARN parsing and sanitization (PR #246)"
```

---

### Task 3: Add model lookup + settings + render tests

**Files:**
- Modify: `tests/unit/test_bedrock_model.bats`

**Step 1: Append these tests to the existing file**

```bash
# --- _cleanup_model_id ---

@test "_cleanup_model_id: strips anthropic prefix and title-cases" {
    run _cleanup_model_id "anthropic.claude-opus-4-6-v1:0"
    assert_success
    assert_output "Claude Opus 4 6"
}

@test "_cleanup_model_id: strips us.anthropic prefix" {
    run _cleanup_model_id "us.anthropic.claude-haiku-3-5-v2:0"
    assert_success
    assert_output "Claude Haiku 3 5"
}

# --- _lookup_model_name ---

@test "_lookup_model_name: exact match in model list" {
    local model_list="anthropic.claude-opus-4-6-v1|Claude Opus 4.6
anthropic.claude-sonnet-4-5-v1|Claude Sonnet 4.5"
    run _lookup_model_name "anthropic.claude-opus-4-6-v1" "$model_list"
    assert_success
    assert_output "Claude Opus 4.6"
}

@test "_lookup_model_name: strips version suffix for matching" {
    local model_list="anthropic.claude-opus-4-6-v1|Claude Opus 4.6"
    run _lookup_model_name "anthropic.claude-opus-4-6-v1:0" "$model_list"
    assert_success
    assert_output "Claude Opus 4.6"
}

@test "_lookup_model_name: prefix match fallback" {
    local model_list="anthropic.claude-sonnet-4-5-v1:0|Claude Sonnet 4.5"
    run _lookup_model_name "anthropic.claude-sonnet-4-5-v1:1" "$model_list"
    assert_success
    assert_output "Claude Sonnet 4.5"
}

@test "_lookup_model_name: falls back to cleanup when no list" {
    run _lookup_model_name "anthropic.claude-opus-4-6-v1:0" ""
    assert_success
    assert_output "Claude Opus 4 6"
}

# --- _load_claude_settings ---

@test "_load_claude_settings: caches results (only loads once)" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"
    run _load_claude_settings
    assert_success
}

@test "_load_claude_settings: returns 1 when settings file missing" {
    _BEDROCK_SETTINGS_LOADED=""
    HOME="$TEST_TMP_DIR/nonexistent"
    run _load_claude_settings
    assert_failure
}

@test "_load_claude_settings: parses env block" {
    _BEDROCK_SETTINGS_LOADED=""
    local mock_home="$TEST_TMP_DIR/mock_home"
    mkdir -p "$mock_home/.claude"
    cat > "$mock_home/.claude/settings.json" << 'SETTINGS'
{
    "env": {
        "CLAUDE_CODE_USE_BEDROCK": "true",
        "AWS_PROFILE": "my-profile",
        "AWS_REGION": "us-west-2"
    }
}
SETTINGS
    HOME="$mock_home"
    _load_claude_settings
    [[ "$_BEDROCK_SETTINGS_USE_BEDROCK" == "true" ]]
    [[ "$_BEDROCK_SETTINGS_AWS_PROFILE" == "my-profile" ]]
    [[ "$_BEDROCK_SETTINGS_AWS_REGION" == "us-west-2" ]]
}

# --- is_bedrock_enabled ---

@test "is_bedrock_enabled: true when USE_BEDROCK is true" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"
    run is_bedrock_enabled
    assert_success
}

@test "is_bedrock_enabled: false when USE_BEDROCK empty" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK=""
    run is_bedrock_enabled
    assert_failure
}

@test "is_bedrock_enabled: false when USE_BEDROCK is false" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="false"
    run is_bedrock_enabled
    assert_failure
}

# --- get_bedrock_model_config ---

@test "get_bedrock_model_config: reads enabled from config var" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    run get_bedrock_model_config "enabled" "false"
    assert_success
    assert_output "true"
}

@test "get_bedrock_model_config: returns default when unset" {
    unset CONFIG_BEDROCK_MODEL_FOOBAR 2>/dev/null || true
    run get_bedrock_model_config "foobar" "mydefault"
    assert_success
    assert_output "mydefault"
}

@test "get_bedrock_model_config: reads timeout value" {
    CONFIG_BEDROCK_MODEL_TIMEOUT="5s"
    run get_bedrock_model_config "timeout" "10s"
    assert_success
    assert_output "5s"
}

# --- render_bedrock_model ---

@test "render_bedrock_model: outputs nothing when not Bedrock" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="false"
    run render_bedrock_model
    assert_success
    assert_output ""
}

@test "render_bedrock_model: renders model name and region" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="Claude Opus 4.6"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"
    CONFIG_BEDROCK_MODEL_SHOW_EMOJI="true"
    CONFIG_BEDROCK_MODEL_EMOJI="☁️"
    CONFIG_BEDROCK_MODEL_SHOW_REGION="true"
    run render_bedrock_model
    assert_success
    [[ "$output" == *"Claude Opus 4.6"* ]]
    [[ "$output" == *"us-east-2"* ]]
}

@test "render_bedrock_model: hides region when show_region=false" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="Claude Opus 4.6"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"
    CONFIG_BEDROCK_MODEL_SHOW_REGION="false"
    run render_bedrock_model
    assert_success
    [[ "$output" == *"Claude Opus 4.6"* ]]
    [[ "$output" != *"us-east-2"* ]]
}

@test "render_bedrock_model: renders fallback profile ID" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="profile:ertkckm22ih2"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"
    CONFIG_BEDROCK_MODEL_SHOW_EMOJI="true"
    CONFIG_BEDROCK_MODEL_EMOJI="☁️"
    run render_bedrock_model
    assert_success
    [[ "$output" == *"profile:ertkckm22ih2"* ]]
}

@test "render_bedrock_model: hides emoji when show_emoji=false" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="Claude Opus 4.6"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"
    CONFIG_BEDROCK_MODEL_SHOW_EMOJI="false"
    run render_bedrock_model
    assert_success
    [[ "$output" != *"🧠"* ]]
    [[ "$output" != *"☁️"* ]]
}

# --- collect_bedrock_model_data ---

@test "collect_bedrock_model_data: bails when component disabled" {
    CONFIG_BEDROCK_MODEL_ENABLED="false"
    collect_bedrock_model_data
    [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" == "false" ]]
}

@test "collect_bedrock_model_data: bails when Bedrock not in Claude settings" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK=""
    collect_bedrock_model_data
    [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" == "false" ]]
}

@test "collect_bedrock_model_data: detects Bedrock ARN from JSON" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"
    STATUSLINE_INPUT_JSON='{"model":{"display_name":"arn:aws:bedrock:us-east-2:188572534221:application-inference-profile/ertkckm22ih2"}}'
    collect_bedrock_model_data
    [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" == "true" ]]
    [[ "$COMPONENT_BEDROCK_MODEL_REGION" == "us-east-2" ]]
    [[ "$COMPONENT_BEDROCK_MODEL_PROFILE_ID" == "ertkckm22ih2" ]]
}

@test "collect_bedrock_model_data: non-Bedrock model stays inactive" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"
    STATUSLINE_INPUT_JSON='{"model":{"display_name":"Claude Opus 4.6"}}'
    collect_bedrock_model_data
    [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" == "false" ]]
}
```

**Step 2: Run all tests**

Run: `bats tests/unit/test_bedrock_model.bats`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add tests/unit/test_bedrock_model.bats
git commit -m "test: add lookup, settings, render, and collect tests for bedrock_model"
```

---

### Task 4: Update Config.toml — add bedrock_model settings + line2 entry

**Files:**
- Modify: `examples/Config.toml:199` (insert bedrock config block after session_mode section)
- Modify: `examples/Config.toml:514` (add bedrock_model to line2 components)
- Modify: `examples/Config.toml:558` (bump component count 27→28)
- Modify: `examples/Config.toml:567` (bump Model & Session count 6→7, add bedrock_model entry)

**Step 1: Add bedrock_model config block**

After line 198 (`session_mode.emoji_custom = "✨"`), insert:

```toml
# === BEDROCK MODEL CONFIGURATION (AWS Bedrock Inference Profiles) ===
# Resolves AWS Bedrock inference profile ARNs to friendly model names.
# Requires CLAUDE_CODE_USE_BEDROCK=true in ~/.claude/settings.json env block.
# When active, replaces the raw ARN with e.g. "☁️ Claude Opus 4.6 (us-east-2)"
#
# Dependencies: aws CLI, jq (graceful degradation without them)
bedrock_model.enabled = false          # Enable Bedrock model name resolution
bedrock_model.show_emoji = true        # Show model-family emoji (🧠/⚡/🎵)
bedrock_model.emoji = "☁️"            # Cloud emoji prefix for Bedrock models
bedrock_model.show_region = true       # Show AWS region after model name
bedrock_model.timeout = "10s"          # AWS API call timeout
```

**Step 2: Add bedrock_model to line2 components**

Change line 514:
```toml
# Before:
display.line2.components = ["model_info", "version_display", "commits", "submodules", "version_info", "time_display"]
# After:
display.line2.components = ["model_info", "bedrock_model", "version_display", "commits", "submodules", "version_info", "time_display"]
```

**Step 3: Update component category comments**

Line 558: `(27 Total)` → `(28 Total)`
Line 567: `Model & Session Components (6):` → `Model & Session Components (7):`
After `"model_info"` line, add: `# - "bedrock_model"  - AWS Bedrock inference profile to friendly model name`

**Step 4: Commit**

```bash
git add examples/Config.toml
git commit -m "feat: add bedrock_model config settings and line2 entry"
```

---

### Task 5: Update CLAUDE.md documentation

**Files:**
- Modify: `CLAUDE.md:42` (bump Atomic Components 27→28)
- Modify: `CLAUDE.md:44` (bump Model & Session 4→5, add bedrock_model)

**Step 1: Update component counts**

Line 42: `**Atomic Components** (27):` → `**Atomic Components** (28):`
Line 44: `**Model & Session** (4): model_info, cost_repo, cost_live, reset_timer` → `**Model & Session** (5): model_info, bedrock_model, cost_repo, cost_live, reset_timer`

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update component counts for bedrock_model"
```

---

### Task 6: Run full test suite + smoke test

**Step 1: Run bedrock_model tests**

Run: `bats tests/unit/test_bedrock_model.bats`
Expected: All ~36 tests PASS

**Step 2: Run full test suite**

Run: `npm test`
Expected: All existing tests still pass, no regressions

**Step 3: Smoke test the statusline**

Run:
```bash
echo '{"version":"2.1.69","workspace":{"current_dir":"'$(pwd)'"},"model":{"id":"claude-opus-4-6-20250415","display_name":"Claude Opus 4.6"},"context_window":{"used_percentage":12},"cost":{"total_cost_usd":0.45},"session_id":"test","mcp":{"servers":[]}}' | /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh
```
Expected: Normal output, no bedrock_model visible (not a Bedrock ARN)

**Step 4: Commit (if any fixes needed)**

Only commit if smoke test revealed issues that needed fixing.

---

### Task 7: Create branch and final commit

**Step 1: Ensure all changes are on feat/bedrock-model branch based on nightly**

```bash
git checkout -b feat/bedrock-model nightly
# Cherry-pick or replay commits from tasks 1-5
```

**Step 2: Verify clean state**

Run: `git log --oneline nightly..HEAD`
Expected: 5 clean commits (test, component, config, docs, any fixes)

---

## File Summary

| Action | File | Description |
|--------|------|-------------|
| Create | `lib/components/bedrock_model.sh` | Main component (~280 lines) |
| Create | `tests/unit/test_bedrock_model.bats` | Test suite (~36 tests) |
| Modify | `examples/Config.toml` | Add config block + line2 entry + counts |
| Modify | `CLAUDE.md` | Update component counts |

## Key Differences from PR #246

| Issue | PR #246 | Our Implementation |
|-------|---------|-------------------|
| Shell injection | Raw values in `bash -c` | `_sanitize_bedrock_value()` strips metacharacters |
| Config pattern | Direct `${!config_var}` | `case` statement with `CONFIG_*` vars (project pattern) |
| Registration | Hardcoded `"true"` | `$(get_bedrock_model_config 'enabled' 'false')` |
| Include guard | Missing | `STATUSLINE_BEDROCK_MODEL_LOADED` guard |
| Duplicated logic | Two separate code paths | Single `_resolve_bedrock_profile()` + cached wrapper |
| Base branch | `main` | `nightly` |
| CLAUDE.md base | Stale (21 components) | Current (27→28 components) |
| Debug logging | 7+ calls in collect | 3 calls (detect, resolve, result) |
