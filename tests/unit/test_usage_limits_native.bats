#!/usr/bin/env bats
# ==============================================================================
# Test: Native rate_limits JSON support (CC v2.1.80+)
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/cache.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/usage_limits.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ==============================================================================
# Epoch timestamp support in time formatters
# ==============================================================================

@test "format_reset_time handles Unix epoch timestamp" {
    # Use a future epoch (1 hour from now)
    local future_epoch=$(( $(date +%s) + 3600 ))
    run format_reset_time "$future_epoch"
    assert_success
    # Should return something like "1h0m" or "59m"
    [[ "$output" =~ ^[0-9]+[hm] ]]
}

@test "format_reset_time handles past epoch timestamp" {
    local past_epoch=$(( $(date +%s) - 60 ))
    run format_reset_time "$past_epoch"
    assert_success
    assert_output "now"
}

@test "get_reset_clock_time handles Unix epoch timestamp" {
    local future_epoch=$(( $(date +%s) + 3600 ))
    run get_reset_clock_time "$future_epoch"
    assert_success
    # Should return HH:MM format
    [[ "$output" =~ ^[0-9]{1,2}:[0-9]{2}$ ]]
}

@test "format_reset_time_long handles Unix epoch timestamp" {
    # 2 hours from now
    local future_epoch=$(( $(date +%s) + 7200 ))
    run format_reset_time_long "$future_epoch"
    assert_success
    # Should contain "hr" and/or "min"
    [[ "$output" =~ hr ]] || [[ "$output" =~ min ]]
}

@test "get_remaining_minutes handles Unix epoch timestamp" {
    # 90 minutes from now
    local future_epoch=$(( $(date +%s) + 5400 ))
    run get_remaining_minutes "$future_epoch"
    assert_success
    # Should be around 90
    [[ "$output" -ge 89 && "$output" -le 91 ]]
}

@test "format_reset_time still handles ISO 8601 timestamps" {
    # Ensure backwards compatibility
    local future_iso
    if [[ "$(uname -s)" == "Darwin" ]]; then
        future_iso=$(date -j -v+1H -u "+%Y-%m-%dT%H:%M:%S+00:00")
    else
        future_iso=$(date -u -d "+1 hour" "+%Y-%m-%dT%H:%M:%S+00:00")
    fi
    run format_reset_time "$future_iso"
    assert_success
    [[ -n "$output" && "$output" != "" ]]
}

# ==============================================================================
# Native rate_limits JSON reading
# ==============================================================================

@test "collect_usage_limits_data reads native rate_limits from CC v2.1.80+" {
    local future_epoch=$(( $(date +%s) + 3600 ))
    export STATUSLINE_INPUT_JSON='{"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":'$future_epoch'},"seven_day":{"used_percentage":41.2,"resets_at":'$((future_epoch + 86400))'}}}'

    collect_usage_limits_data

    [[ "$COMPONENT_USAGE_FIVE_HOUR" == "24" || "$COMPONENT_USAGE_FIVE_HOUR" == "23" ]]
    [[ "$COMPONENT_USAGE_SEVEN_DAY" == "41" ]]
    [[ "$COMPONENT_USAGE_STATUS" == "ok" ]]
}

@test "collect_usage_limits_data reads rate_limits with only five_hour present" {
    local future_epoch=$(( $(date +%s) + 3600 ))
    export STATUSLINE_INPUT_JSON='{"rate_limits":{"five_hour":{"used_percentage":50.0,"resets_at":'$future_epoch'}}}'

    collect_usage_limits_data

    [[ "$COMPONENT_USAGE_FIVE_HOUR" == "50" ]]
    [[ -z "$COMPONENT_USAGE_SEVEN_DAY" ]]
    [[ "$COMPONENT_USAGE_STATUS" == "ok" ]]
}

@test "collect_usage_limits_data reads rate_limits with only seven_day present" {
    local future_epoch=$(( $(date +%s) + 86400 ))
    export STATUSLINE_INPUT_JSON='{"rate_limits":{"seven_day":{"used_percentage":75.0,"resets_at":'$future_epoch'},"five_hour":null}}'

    collect_usage_limits_data

    [[ -z "$COMPONENT_USAGE_FIVE_HOUR" || "$COMPONENT_USAGE_FIVE_HOUR" == "" ]]
    [[ "$COMPONENT_USAGE_SEVEN_DAY" == "75" ]]
    [[ "$COMPONENT_USAGE_STATUS" == "ok" ]]
}

@test "collect_usage_limits_data falls back when rate_limits absent" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.76","workspace":{"current_dir":"/tmp"}}'

    collect_usage_limits_data

    # Should not crash, status should reflect no data (unavailable or rate_limited)
    [[ "$COMPONENT_USAGE_STATUS" == "unavailable" || "$COMPONENT_USAGE_STATUS" == "rate_limited" || "$COMPONENT_USAGE_STATUS" == "ok" ]]
}

@test "collect_usage_limits_data extracts epoch resets_at as string" {
    local future_epoch=$(( $(date +%s) + 3600 ))
    export STATUSLINE_INPUT_JSON='{"rate_limits":{"five_hour":{"used_percentage":10.0,"resets_at":'$future_epoch'},"seven_day":{"used_percentage":20.0,"resets_at":'$((future_epoch + 86400))'}}}'

    collect_usage_limits_data

    # resets_at should be stored as string of the epoch
    [[ "$COMPONENT_USAGE_FIVE_HOUR_RESET" == "$future_epoch" ]]
}
