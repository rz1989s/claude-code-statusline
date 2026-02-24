#!/usr/bin/env bats

# Unit tests for AWS Bedrock model component (lib/components/bedrock_model.sh)

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Stub out framework functions that bedrock_model.sh depends on
    # but that we don't want to pull in from the full statusline.
    debug_log() { :; }
    export -f debug_log

    command_exists() { command -v "$1" &>/dev/null; }
    export -f command_exists

    register_component() { :; }
    export -f register_component

    get_model_emoji() {
        case "$1" in
            *Opus*|*opus*)   echo "🧠" ;;
            *Haiku*|*haiku*) echo "⚡" ;;
            *Sonnet*|*sonnet*) echo "🎵" ;;
            *) echo "🤖" ;;
        esac
    }
    export -f get_model_emoji

    # Provide color variables used by render
    CONFIG_CYAN=""
    CONFIG_DIM=""
    CONFIG_RESET=""

    # Default component config vars (disabled so collect bails early)
    CONFIG_BEDROCK_MODEL_ENABLED="false"
    CONFIG_BEDROCK_MODEL_SHOW_EMOJI="true"
    CONFIG_BEDROCK_MODEL_EMOJI="☁️"
    CONFIG_BEDROCK_MODEL_SHOW_REGION="true"
    CONFIG_BEDROCK_MODEL_TIMEOUT="10s"

    # Cache not loaded (skip cached wrappers)
    STATUSLINE_CACHE_LOADED="false"

    # Source the component under test
    source "$STATUSLINE_ROOT/lib/components/bedrock_model.sh"
}

teardown() {
    common_teardown
}

# ============================================================================
# is_bedrock_arn()
# ============================================================================

@test "is_bedrock_arn: accepts valid Bedrock inference profile ARN" {
    run is_bedrock_arn "arn:aws:bedrock:us-east-2:188572534221:application-inference-profile/ertkckm22ih2"
    assert_success
}

@test "is_bedrock_arn: accepts ARN with long profile ID" {
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

@test "is_bedrock_arn: rejects partial ARN missing profile segment" {
    run is_bedrock_arn "arn:aws:bedrock:us-east-2:188572534221:foundation-model/anthropic.claude"
    assert_failure
}

@test "is_bedrock_arn: rejects non-bedrock ARN" {
    run is_bedrock_arn "arn:aws:s3:::my-bucket"
    assert_failure
}

# ============================================================================
# parse_bedrock_region()
# ============================================================================

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

# ============================================================================
# parse_bedrock_profile_id()
# ============================================================================

@test "parse_bedrock_profile_id: extracts profile ID from ARN" {
    run parse_bedrock_profile_id "arn:aws:bedrock:us-east-2:188572534221:application-inference-profile/ertkckm22ih2"
    assert_success
    assert_output "ertkckm22ih2"
}

@test "parse_bedrock_profile_id: handles longer profile IDs" {
    run parse_bedrock_profile_id "arn:aws:bedrock:eu-west-1:123456789012:application-inference-profile/abcdef1234567890ghijklmnop"
    assert_success
    assert_output "abcdef1234567890ghijklmnop"
}

# ============================================================================
# get_bedrock_model_config()
# ============================================================================

@test "get_bedrock_model_config: returns config value when set" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    run get_bedrock_model_config "enabled" "false"
    assert_success
    assert_output "true"
}

@test "get_bedrock_model_config: returns default when config var empty" {
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

# ============================================================================
# _lookup_model_name()
# ============================================================================

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

@test "_lookup_model_name: best-effort cleanup when not in list" {
    run _lookup_model_name "anthropic.claude-opus-4-6-v1:0" ""
    assert_success
    # Should strip anthropic. prefix, :0 suffix, -v1 suffix, then title-case
    assert_output "Claude Opus 4 6"
}

@test "_lookup_model_name: best-effort cleanup strips us.anthropic prefix" {
    run _lookup_model_name "us.anthropic.claude-haiku-3-5-v2:0" ""
    assert_success
    assert_output "Claude Haiku 3 5"
}

# ============================================================================
# render_bedrock_model()
# ============================================================================

@test "render_bedrock_model: outputs nothing when not Bedrock" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="false"
    run render_bedrock_model
    assert_success
    assert_output ""
}

@test "render_bedrock_model: renders model name when Bedrock active" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="Claude Opus 4.6"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"

    run render_bedrock_model
    assert_success
    # Output should contain the model name and region
    assert_output_contains "Claude Opus 4.6"
    assert_output_contains "us-east-2"
}

@test "render_bedrock_model: hides region when show_region=false" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="Claude Opus 4.6"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"
    CONFIG_BEDROCK_MODEL_SHOW_REGION="false"

    run render_bedrock_model
    assert_success
    assert_output_contains "Claude Opus 4.6"
    # Region should NOT appear
    if [[ "$output" == *"us-east-2"* ]]; then
        echo "Expected output NOT to contain region when show_region=false"
        echo "Actual: $output"
        return 1
    fi
}

@test "render_bedrock_model: renders fallback profile ID display" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="profile:ertkckm22ih2"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"

    run render_bedrock_model
    assert_success
    assert_output_contains "profile:ertkckm22ih2"
}

@test "render_bedrock_model: hides emoji when show_emoji=false" {
    COMPONENT_BEDROCK_MODEL_IS_BEDROCK="true"
    COMPONENT_BEDROCK_MODEL_NAME="Claude Opus 4.6"
    COMPONENT_BEDROCK_MODEL_REGION="us-east-2"
    CONFIG_BEDROCK_MODEL_SHOW_EMOJI="false"

    run render_bedrock_model
    assert_success
    # Should NOT contain emoji characters
    if [[ "$output" == *"🧠"* ]] || [[ "$output" == *"☁️"* ]]; then
        echo "Expected no emojis when show_emoji=false"
        echo "Actual: $output"
        return 1
    fi
}

# ============================================================================
# collect_bedrock_model_data()
# ============================================================================

@test "collect_bedrock_model_data: bails when component disabled" {
    CONFIG_BEDROCK_MODEL_ENABLED="false"
    run collect_bedrock_model_data
    assert_success
    # Component vars should remain empty/false
    [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" != "true" ]]
}

@test "collect_bedrock_model_data: bails when Bedrock not enabled in Claude settings" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    # Reset settings cache so it reloads
    _BEDROCK_SETTINGS_LOADED=""
    _BEDROCK_SETTINGS_USE_BEDROCK=""

    # No settings file -> is_bedrock_enabled returns false
    run collect_bedrock_model_data
    assert_success
}

@test "collect_bedrock_model_data: detects Bedrock ARN from JSON input" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"

    # Simulate JSON input with a Bedrock ARN
    STATUSLINE_INPUT_JSON='{"model":{"display_name":"arn:aws:bedrock:us-east-2:188572534221:application-inference-profile/ertkckm22ih2"}}'

    # Mock aws as unavailable so we hit fallback
    command_exists() {
        [[ "$1" == "jq" ]] && return 0
        return 1
    }

    collect_bedrock_model_data

    [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" == "true" ]]
    [[ "$COMPONENT_BEDROCK_MODEL_REGION" == "us-east-2" ]]
    [[ "$COMPONENT_BEDROCK_MODEL_PROFILE_ID" == "ertkckm22ih2" ]]
}

@test "collect_bedrock_model_data: non-Bedrock model leaves component inactive" {
    CONFIG_BEDROCK_MODEL_ENABLED="true"
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"

    STATUSLINE_INPUT_JSON='{"model":{"display_name":"Claude Opus 4.6"}}'

    collect_bedrock_model_data

    [[ "$COMPONENT_BEDROCK_MODEL_IS_BEDROCK" == "false" ]]
    [[ -z "$COMPONENT_BEDROCK_MODEL_NAME" ]]
}

# ============================================================================
# _load_claude_settings()
# ============================================================================

@test "_load_claude_settings: caches results (only loads once)" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"

    # Even with no settings file, should return 0 because already loaded
    run _load_claude_settings
    assert_success
    [[ "$_BEDROCK_SETTINGS_USE_BEDROCK" == "true" ]]
}

@test "_load_claude_settings: returns 1 when settings file missing" {
    _BEDROCK_SETTINGS_LOADED=""
    HOME="$TEST_TMP_DIR/nonexistent"

    run _load_claude_settings
    assert_failure
}

@test "_load_claude_settings: parses env block from settings.json" {
    _BEDROCK_SETTINGS_LOADED=""

    # Create mock settings file
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

# ============================================================================
# is_bedrock_enabled()
# ============================================================================

@test "is_bedrock_enabled: returns true when USE_BEDROCK is true" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="true"

    run is_bedrock_enabled
    assert_success
}

@test "is_bedrock_enabled: returns false when USE_BEDROCK is not set" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK=""

    run is_bedrock_enabled
    assert_failure
}

@test "is_bedrock_enabled: returns false when USE_BEDROCK is false" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_USE_BEDROCK="false"

    run is_bedrock_enabled
    assert_failure
}

# ============================================================================
# get_bedrock_aws_profile()
# ============================================================================

@test "get_bedrock_aws_profile: returns profile when set" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_AWS_PROFILE="production"

    run get_bedrock_aws_profile
    assert_success
    assert_output "production"
}

@test "get_bedrock_aws_profile: returns empty when not set" {
    _BEDROCK_SETTINGS_LOADED="true"
    _BEDROCK_SETTINGS_AWS_PROFILE=""

    run get_bedrock_aws_profile
    assert_success
    assert_output ""
}
