#!/usr/bin/env bats

# Unit tests for get_model_emoji() — model name → emoji mapping (lib/display.sh)
# Guards the per-model icons, including Claude Fable 5 (🔮), so the flagship
# model never silently falls back to the generic 🤖 default.

load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/config/constants.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/config/defaults.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/display.sh" 2>/dev/null || true
    init_default_config 2>/dev/null || true
}

teardown() { common_teardown; }

@test "Fable display name maps to crystal ball emoji" {
    run get_model_emoji "Claude Fable 5"
    assert_success
    assert_output "🔮"
}

@test "Fable lowercase/bare id also maps to crystal ball" {
    run get_model_emoji "claude-fable-5"
    assert_output "🔮"
}

@test "Fable does NOT fall through to the generic bot default" {
    run get_model_emoji "Claude Fable 5"
    [[ "$output" != "🤖" ]]
}

@test "Opus still maps to brain (regression)" {
    run get_model_emoji "Claude Opus 4.8"
    assert_output "🧠"
}

@test "Sonnet still maps to music note (regression)" {
    run get_model_emoji "Claude Sonnet 4.6"
    assert_output "🎵"
}

@test "Haiku still maps to lightning (regression)" {
    run get_model_emoji "Claude Haiku 4.5"
    assert_output "⚡"
}

@test "Unknown model falls through to the default bot emoji" {
    run get_model_emoji "Some Unknown Model"
    assert_output "🤖"
}
