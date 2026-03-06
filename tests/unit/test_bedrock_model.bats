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

# ============================================================================
# ARN DETECTION (6 tests)
# ============================================================================

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

# ============================================================================
# ARN PARSING (5 tests)
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

# ============================================================================
# SANITIZATION (4 tests)
# ============================================================================

@test "_sanitize_bedrock_value: passes clean region" {
    run _sanitize_bedrock_value "us-east-2"
    assert_success
    assert_output "us-east-2"
}

@test "_sanitize_bedrock_value: strips shell metacharacters" {
    run _sanitize_bedrock_value "us-east-2'; rm -rf /"
    assert_success
    assert_output "us-east-2rm-rf"
}

@test "_sanitize_bedrock_value: strips backticks and dollars" {
    run _sanitize_bedrock_value 'us-east-2`whoami`$HOME'
    assert_success
    assert_output "us-east-2whoamiHOME"
}

@test "_sanitize_bedrock_value: returns empty for empty input" {
    run _sanitize_bedrock_value ""
    assert_success
    assert_output ""
}

# ============================================================================
# MODEL NAME LOOKUP (4 tests)
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

@test "_lookup_model_name: falls back to cleanup when no list" {
    run _lookup_model_name "anthropic.claude-opus-4-6-v1:0" ""
    assert_success
    assert_output "Claude Opus 4 6"
}

# ============================================================================
# CLEANUP (2 tests)
# ============================================================================

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

# ============================================================================
# SETTINGS (3 tests)
# ============================================================================

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

# ============================================================================
# is_bedrock_enabled (3 tests)
# ============================================================================

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

# ============================================================================
# CONFIG (3 tests)
# ============================================================================

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

# ============================================================================
# RENDER (5 tests)
# ============================================================================

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
    CONFIG_BEDROCK_MODEL_EMOJI=""
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
    CONFIG_BEDROCK_MODEL_EMOJI=""
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
    [[ "$output" != *"☁️"* ]]
}

# ============================================================================
# COLLECT (4 tests)
# ============================================================================

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
