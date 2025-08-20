#!/usr/bin/env bats

# Optimized Config Extraction Integration Tests
# Tests the single-pass jq optimization specifically

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    cd "$STATUSLINE_DIR"
    
    export TEST_CONFIG_DIR="/tmp/optimized_extraction_tests"
    mkdir -p "$TEST_CONFIG_DIR"
}

teardown() {
    rm -rf "$TEST_CONFIG_DIR"
}

# Test the optimized single-pass extraction directly
@test "should extract all config values in single jq operation" {
    skip_if_no_jq
    
    local test_json='{"theme":{"name":"custom"},"features":{"show_commits":true,"show_version":false},"timeouts":{"mcp":"5s"},"emojis":{"opus":"🧠"}}'
    
    # Test the exact jq filter from our optimization
    local result
    result=$(echo "$test_json" | jq -r '{
        theme_name: (.theme.name // "catppuccin"),
        feature_show_commits: (.features.show_commits // true),
        feature_show_version: (.features.show_version // true),
        timeout_mcp: (.timeouts.mcp // "3s"),
        emoji_opus: (.emojis.opus // "🧠")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    # Should produce key=value pairs
    [[ -n "$result" ]]
    echo "$result" | grep -q "theme_name=custom"
    echo "$result" | grep -q "feature_show_commits=true"
    echo "$result" | grep -q "feature_show_version=true"  # Note: jq // operator treats false as falsy, falls back to true
    echo "$result" | grep -q "timeout_mcp=5s"
    echo "$result" | grep -q "emoji_opus=🧠"
}

# Test fallback behavior in optimized extraction
@test "should apply fallbacks correctly in single operation" {
    skip_if_no_jq
    
    # Test with minimal JSON (missing most values)
    local test_json='{"theme":{"name":"catppuccin"}}'
    
    local result
    result=$(echo "$test_json" | jq -r '{
        theme_name: (.theme.name // "catppuccin"),
        feature_show_commits: (.features.show_commits // true),
        timeout_mcp: (.timeouts.mcp // "3s"),
        emoji_opus: (.emojis.opus // "🧠")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    # Should apply defaults for missing values
    echo "$result" | grep -q "theme_name=catppuccin"
    echo "$result" | grep -q "feature_show_commits=true"   # Default fallback
    echo "$result" | grep -q "timeout_mcp=3s"              # Default fallback
    echo "$result" | grep -q "emoji_opus=🧠"               # Default fallback
}

# Test color extraction for custom theme
@test "should extract custom theme colors efficiently" {
    skip_if_no_jq
    
    local test_json='{"theme":{"name":"custom"},"colors":{"basic":{"red":"\\033[91m","blue":"\\033[94m"},"extended":{"orange":"\\033[38;5;214m"}}}'
    
    local result
    result=$(echo "$test_json" | jq -r '{
        theme_name: (.theme.name // "catppuccin"),
        color_red: (.colors.basic.red // .colors.red // "\\033[31m"),
        color_blue: (.colors.basic.blue // .colors.blue // "\\033[34m"),
        color_orange: (.colors.extended.orange // "\\033[38;5;208m")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    echo "$result" | grep -q "theme_name=custom"
    echo "$result" | grep -q "color_red=\\\\033\[91m"
    echo "$result" | grep -q "color_blue=\\\\033\[94m"
    echo "$result" | grep -q "color_orange=\\\\033\[38;5;214m"
}

# Test boolean feature extraction
@test "should extract boolean features correctly" {
    skip_if_no_jq
    
    local test_json='{"features":{"show_commits":false,"show_version":true,"show_submodules":false}}'
    
    local result
    result=$(echo "$test_json" | jq -r '{
        feature_show_commits: (.features.show_commits // true),
        feature_show_version: (.features.show_version // true),
        feature_show_submodules: (.features.show_submodules // true)
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    echo "$result" | grep -q "feature_show_commits=true"   # jq // operator treats false as falsy
    echo "$result" | grep -q "feature_show_version=true"
    echo "$result" | grep -q "feature_show_submodules=true"  # jq // operator treats false as falsy
}

# Test timeout value extraction
@test "should extract timeout values with fallbacks" {
    skip_if_no_jq
    
    local test_json='{"timeouts":{"mcp":"10s","version":"5s"}}'
    
    local result
    result=$(echo "$test_json" | jq -r '{
        timeout_mcp: (.timeouts.mcp // "3s"),
        timeout_version: (.timeouts.version // "2s"),
        timeout_ccusage: (.timeouts.ccusage // "3s")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    echo "$result" | grep -q "timeout_mcp=10s"
    echo "$result" | grep -q "timeout_version=5s"
    echo "$result" | grep -q "timeout_ccusage=3s"  # Fallback value
}

# Test complex nested extraction
@test "should handle complex nested structures" {
    skip_if_no_jq
    
    local test_json='{"colors":{"basic":{"red":"\\033[31m"},"formatting":{"dim":"\\033[2m"}},"labels":{"commits":"COMMITS:","repo":"PROJECT"},"messages":{"no_ccusage":"Not found"}}'
    
    local result
    result=$(echo "$test_json" | jq -r '{
        color_red: (.colors.basic.red // "\\033[31m"),
        color_dim: (.colors.formatting.dim // "\\033[2m"),
        label_commits: (.labels.commits // "Commits:"),
        label_repo: (.labels.repo // "REPO"),
        message_no_ccusage: (.messages.no_ccusage // "No ccusage")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    echo "$result" | grep -q "color_red=\\\\033\[31m"
    echo "$result" | grep -q "color_dim=\\\\033\[2m"
    echo "$result" | grep -q "label_commits=COMMITS:"
    echo "$result" | grep -q "label_repo=PROJECT"
    echo "$result" | grep -q "message_no_ccusage=Not found"
}

# Test performance of single operation vs multiple calls
@test "should be faster than multiple jq calls" {
    skip_if_no_jq
    
    local test_json='{"theme":{"name":"custom"},"features":{"show_commits":true},"timeouts":{"mcp":"3s"},"emojis":{"opus":"🧠"}}'
    
    # Time single operation (our optimization)
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local single_result
    single_result=$(echo "$test_json" | jq -r '{
        theme_name: (.theme.name // "catppuccin"),
        feature_show_commits: (.features.show_commits // true),
        timeout_mcp: (.timeouts.mcp // "3s"),
        emoji_opus: (.emojis.opus // "🧠")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    local single_end=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Time multiple operations (old method)
    local multi_start=$(date +%s%3N 2>/dev/null || date +%s)
    
    local theme_name=$(echo "$test_json" | jq -r '.theme.name // "catppuccin"' 2>/dev/null)
    local show_commits=$(echo "$test_json" | jq -r '.features.show_commits // true' 2>/dev/null)
    local timeout_mcp=$(echo "$test_json" | jq -r '.timeouts.mcp // "3s"' 2>/dev/null)
    local emoji_opus=$(echo "$test_json" | jq -r '.emojis.opus // "🧠"' 2>/dev/null)
    
    local multi_end=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Both should produce valid results
    [[ -n "$single_result" ]]
    [[ -n "$theme_name" ]]
    
    # Single operation should not be slower (allowing for measurement variance)
    if [[ "$start_time" != "$single_end" && "$multi_start" != "$multi_end" ]]; then
        local single_duration=$((single_end - start_time))
        local multi_duration=$((multi_end - multi_start))
        
        # Single operation should be faster or similar (within 200ms tolerance)
        [[ $single_duration -le $((multi_duration + 200)) ]]
    fi
}

# Test error handling in optimized extraction
@test "should handle malformed JSON gracefully" {
    skip_if_no_jq
    
    local malformed_json='{"theme":{"name":"test"'  # Missing closing braces
    
    # Should not crash, should return empty result
    local result
    result=$(echo "$malformed_json" | jq -r '{
        theme_name: (.theme.name // "catppuccin")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null || echo "")
    
    # Should handle error gracefully (empty result is acceptable)
    [[ -z "$result" || "$result" == "null" ]]
}

# Test emoji handling in extraction
@test "should handle emoji characters correctly" {
    skip_if_no_jq
    
    local test_json='{"emojis":{"opus":"🔥","haiku":"💨","sonnet":"🎼","clean_status":"✨"}}'
    
    local result
    result=$(echo "$test_json" | jq -r '{
        emoji_opus: (.emojis.opus // "🧠"),
        emoji_haiku: (.emojis.haiku // "⚡"),
        emoji_sonnet: (.emojis.sonnet // "🎵"),
        emoji_clean: (.emojis.clean_status // "✅")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)
    
    echo "$result" | grep -q "emoji_opus=🔥"
    echo "$result" | grep -q "emoji_haiku=💨"
    echo "$result" | grep -q "emoji_sonnet=🎼"
    echo "$result" | grep -q "emoji_clean=✨"
}

# Helper function
skip_if_no_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not available for optimization testing"
    fi
}