#!/usr/bin/env bats

# Unit tests for Prayer Break Reminders (Issue #212)

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Isolate cache to test directory
    export XDG_CACHE_HOME="$TEST_TMP_DIR/cache"
    mkdir -p "$XDG_CACHE_HOME"

    # Isolate config to prevent real JSONL scanning
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude_config"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects"

    # Load core for debug_log (optional, graceful if missing)
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true

    # Source the reminders module directly
    source "$STATUSLINE_ROOT/lib/prayer/reminders.sh" 2>/dev/null || true

    # Set default reminder config values
    export CONFIG_PRAYER_REMINDERS_HEADSUP_MINUTES=30
    export CONFIG_PRAYER_REMINDERS_PREPARE_MINUTES=15
    export CONFIG_PRAYER_REMINDERS_IMMINENT_MINUTES=5
    export CONFIG_PRAYER_REMINDERS_COOLDOWN_SECONDS=900
}

teardown() {
    common_teardown
}

# ============================================================================
# get_prayer_reminder_level TESTS
# ============================================================================

@test "get_prayer_reminder_level returns 'normal' for 45 minutes" {
    run get_prayer_reminder_level 45
    assert_success
    assert_output "normal"
}

@test "get_prayer_reminder_level returns 'headsup' for 22 minutes" {
    run get_prayer_reminder_level 22
    assert_success
    assert_output "headsup"
}

@test "get_prayer_reminder_level returns 'prepare' for 8 minutes" {
    run get_prayer_reminder_level 8
    assert_success
    assert_output "prepare"
}

@test "get_prayer_reminder_level returns 'imminent' for 3 minutes" {
    run get_prayer_reminder_level 3
    assert_success
    assert_output "imminent"
}

@test "get_prayer_reminder_level returns 'headsup' at exactly 30 minutes" {
    run get_prayer_reminder_level 30
    assert_success
    assert_output "headsup"
}

@test "get_prayer_reminder_level returns 'prepare' at exactly 15 minutes" {
    run get_prayer_reminder_level 15
    assert_success
    assert_output "prepare"
}

@test "get_prayer_reminder_level returns 'imminent' at exactly 5 minutes" {
    run get_prayer_reminder_level 5
    assert_success
    assert_output "imminent"
}

@test "get_prayer_reminder_level returns 'normal' at 31 minutes" {
    run get_prayer_reminder_level 31
    assert_success
    assert_output "normal"
}

@test "get_prayer_reminder_level returns 'imminent' for 0 minutes" {
    run get_prayer_reminder_level 0
    assert_success
    assert_output "imminent"
}

@test "get_prayer_reminder_level handles non-numeric input gracefully" {
    run get_prayer_reminder_level "abc"
    assert_output "normal"
}

@test "get_prayer_reminder_level handles empty input (defaults to 0 = imminent)" {
    run get_prayer_reminder_level ""
    # Empty string defaults to 0 via ${1:-0}, which is <= imminent threshold
    assert_output "imminent"
}

@test "get_prayer_reminder_level respects custom thresholds" {
    export CONFIG_PRAYER_REMINDERS_HEADSUP_MINUTES=60
    export CONFIG_PRAYER_REMINDERS_PREPARE_MINUTES=30
    export CONFIG_PRAYER_REMINDERS_IMMINENT_MINUTES=10

    run get_prayer_reminder_level 45
    assert_success
    assert_output "headsup"

    run get_prayer_reminder_level 20
    assert_success
    assert_output "prepare"

    run get_prayer_reminder_level 7
    assert_success
    assert_output "imminent"
}

# ============================================================================
# format_prayer_reminder TESTS
# ============================================================================

@test "format_prayer_reminder returns headsup message" {
    run format_prayer_reminder "Dhuhr" "22" "headsup"
    assert_success
    assert_output "Dhuhr in 22m"
}

@test "format_prayer_reminder returns prepare message with wrap-up hint" {
    run format_prayer_reminder "Asr" "8" "prepare"
    assert_success
    assert_output "Asr in 8m - wrap up current task"
}

@test "format_prayer_reminder returns imminent message" {
    run format_prayer_reminder "Maghrib" "3" "imminent"
    assert_success
    assert_output "Maghrib in 3m - time to prepare"
}

@test "format_prayer_reminder returns empty for normal level" {
    run format_prayer_reminder "Fajr" "45" "normal"
    assert_success
    assert_output ""
}

@test "format_prayer_reminder handles empty prayer name" {
    run format_prayer_reminder "" "10" "headsup"
    assert_success
    assert_output ""
}

@test "format_prayer_reminder output contains prayer name" {
    run format_prayer_reminder "Isha" "12" "prepare"
    assert_success
    [[ "$output" == *"Isha"* ]]
}

@test "format_prayer_reminder output contains minutes" {
    run format_prayer_reminder "Fajr" "7" "prepare"
    assert_success
    [[ "$output" == *"7m"* ]]
}

# ============================================================================
# should_send_prayer_notification TESTS
# ============================================================================

@test "should_send_prayer_notification returns 0 (should notify) on first call" {
    run should_send_prayer_notification "Fajr"
    assert_success
}

@test "should_send_prayer_notification returns 1 for empty prayer name" {
    run should_send_prayer_notification ""
    assert_failure
}

@test "should_send_prayer_notification returns 1 when within cooldown" {
    local cache_dir="$XDG_CACHE_HOME/claude-code-statusline"
    mkdir -p "$cache_dir"

    # Write current timestamp as cooldown marker
    date +%s > "$cache_dir/prayer_notify_Dhuhr"

    run should_send_prayer_notification "Dhuhr"
    assert_failure
}

@test "should_send_prayer_notification returns 0 when cooldown expired" {
    local cache_dir="$XDG_CACHE_HOME/claude-code-statusline"
    mkdir -p "$cache_dir"

    # Write old timestamp (well past cooldown)
    echo "1000000000" > "$cache_dir/prayer_notify_Asr"

    run should_send_prayer_notification "Asr"
    assert_success
}

# ============================================================================
# mark_prayer_notified TESTS
# ============================================================================

@test "mark_prayer_notified creates cooldown file" {
    mark_prayer_notified "Maghrib"

    local cooldown_file="$XDG_CACHE_HOME/claude-code-statusline/prayer_notify_Maghrib"
    [ -f "$cooldown_file" ]
}

@test "mark_prayer_notified writes a timestamp" {
    mark_prayer_notified "Isha"

    local cooldown_file="$XDG_CACHE_HOME/claude-code-statusline/prayer_notify_Isha"
    local content
    content=$(cat "$cooldown_file")
    [[ "$content" =~ ^[0-9]+$ ]]
}

@test "mark_prayer_notified returns failure for empty name" {
    run mark_prayer_notified ""
    assert_failure
}

@test "mark_prayer_notified creates cache directory if missing" {
    rm -rf "$XDG_CACHE_HOME/claude-code-statusline"

    mark_prayer_notified "Fajr"

    [ -d "$XDG_CACHE_HOME/claude-code-statusline" ]
    [ -f "$XDG_CACHE_HOME/claude-code-statusline/prayer_notify_Fajr" ]
}

# ============================================================================
# process_prayer_reminders TESTS
# ============================================================================

@test "process_prayer_reminders returns empty for normal level (45 min)" {
    run process_prayer_reminders "Fajr" 45
    assert_success
    assert_output ""
}

@test "process_prayer_reminders returns message for headsup level" {
    run process_prayer_reminders "Dhuhr" 22
    assert_success
    [[ "$output" == *"Dhuhr"* ]]
    [[ "$output" == *"22m"* ]]
}

@test "process_prayer_reminders returns message for prepare level" {
    run process_prayer_reminders "Asr" 8
    assert_success
    [[ "$output" == *"Asr"* ]]
    [[ "$output" == *"wrap up"* ]]
}

@test "process_prayer_reminders returns message for imminent level" {
    run process_prayer_reminders "Maghrib" 3
    assert_success
    [[ "$output" == *"Maghrib"* ]]
    [[ "$output" == *"time to prepare"* ]]
}

@test "process_prayer_reminders handles empty prayer name gracefully" {
    run process_prayer_reminders "" 10
    assert_success
    assert_output ""
}

@test "process_prayer_reminders handles zero minutes" {
    run process_prayer_reminders "Isha" 0
    assert_success
    assert_output ""
}

@test "process_prayer_reminders handles negative minutes" {
    run process_prayer_reminders "Fajr" -5
    assert_success
    assert_output ""
}

# ============================================================================
# MODULE GUARD TESTS
# ============================================================================

@test "prayer reminders module sets loaded flag" {
    [ "$STATUSLINE_PRAYER_REMINDERS_LOADED" = "true" ]
}

# ============================================================================
# INTEGRATION: cooldown + notification flow
# ============================================================================

@test "mark then check cooldown prevents re-notification" {
    mark_prayer_notified "Dhuhr"

    run should_send_prayer_notification "Dhuhr"
    assert_failure
}

@test "different prayers have independent cooldowns" {
    mark_prayer_notified "Fajr"

    # Fajr should be in cooldown
    run should_send_prayer_notification "Fajr"
    assert_failure

    # Dhuhr should be available (no cooldown set)
    run should_send_prayer_notification "Dhuhr"
    assert_success
}
