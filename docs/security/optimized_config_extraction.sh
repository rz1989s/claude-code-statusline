#!/bin/bash

# Optimized single-pass config extraction function
# Replaces 64 individual jq calls with 1 comprehensive extraction
extract_all_config_values() {
    local config_json="$1"
    
    # Single jq operation to extract ALL configuration values with fallbacks
    # Returns a bash-parseable format with key=value pairs
    echo "$config_json" | jq -r '
    {
        theme_name: (.theme.name // "catppuccin"),
        color_red: (.colors.basic.red // .colors.red // "\\033[31m"),
        color_blue: (.colors.basic.blue // .colors.blue // "\\033[34m"),
        color_green: (.colors.basic.green // .colors.green // "\\033[32m"),
        color_yellow: (.colors.basic.yellow // .colors.yellow // "\\033[33m"),
        color_magenta: (.colors.basic.magenta // .colors.magenta // "\\033[35m"),
        color_cyan: (.colors.basic.cyan // .colors.cyan // "\\033[36m"),
        color_white: (.colors.basic.white // .colors.white // "\\033[37m"),
        color_orange: (.colors.extended.orange // "\\033[38;5;208m"),
        color_light_orange: (.colors.extended.light_orange // "\\033[38;5;215m"),
        color_light_gray: (.colors.extended.light_gray // "\\033[38;5;248m"),
        color_bright_green: (.colors.extended.bright_green // "\\033[92m"),
        color_purple: (.colors.extended.purple // "\\033[95m"),
        color_teal: (.colors.extended.teal // "\\033[38;5;73m"),
        color_gold: (.colors.extended.gold // "\\033[38;5;220m"),
        color_pink_bright: (.colors.extended.pink_bright // "\\033[38;5;205m"),
        color_indigo: (.colors.extended.indigo // "\\033[38;5;105m"),
        color_violet: (.colors.extended.violet // "\\033[38;5;99m"),
        color_light_blue: (.colors.extended.light_blue // "\\033[38;5;111m"),
        color_dim: (.colors.formatting.dim // "\\033[2m"),
        color_italic: (.colors.formatting.italic // "\\033[3m"),
        color_strikethrough: (.colors.formatting.strikethrough // "\\033[9m"),
        color_reset: (.colors.formatting.reset // "\\033[0m"),
        feature_show_commits: (.features.show_commits // true),
        feature_show_version: (.features.show_version // true),
        feature_show_submodules: (.features.show_submodules // true),
        feature_show_mcp: (.features.show_mcp_status // true),
        feature_show_cost: (.features.show_cost_tracking // true),
        feature_show_reset: (.features.show_reset_info // true),
        feature_show_session: (.features.show_session_info // true),
        timeout_mcp: (.timeouts.mcp // "3s"),
        timeout_version: (.timeouts.version // "2s"),
        timeout_ccusage: (.timeouts.ccusage // "3s"),
        emoji_opus: (.emojis.opus // "🧠"),
        emoji_haiku: (.emojis.haiku // "⚡"),
        emoji_sonnet: (.emojis.sonnet // "🎵"),
        emoji_default: (.emojis.default_model // "🤖"),
        emoji_clean: (.emojis.clean_status // "✅"),
        emoji_dirty: (.emojis.dirty_status // "📁"),
        emoji_clock: (.emojis.clock // "🕐"),
        emoji_live_block: (.emojis.live_block // "🔥"),
        label_commits: (.labels.commits // "Commits:"),
        label_repo: (.labels.repo // "REPO"),
        label_monthly: (.labels.monthly // "30DAY"),
        label_weekly: (.labels.weekly // "7DAY"),
        label_daily: (.labels.daily // "DAY"),
        label_mcp: (.labels.mcp // "MCP"),
        label_version_prefix: (.labels.version_prefix // "ver"),
        label_submodule: (.labels.submodule // "SUB:"),
        label_session_prefix: (.labels.session_prefix // "S:"),
        label_live: (.labels.live // "LIVE"),
        label_reset: (.labels.reset // "RESET"),
        cache_version_duration: (.cache.version_duration // 3600),
        cache_version_file: (.cache.version_file // "/tmp/.claude_version_cache"),
        display_time_format: (.display.time_format // "%H:%M"),
        display_date_format: (.display.date_format // "%Y-%m-%d"),
        display_date_format_compact: (.display.date_format_compact // "%Y%m%d"),
        message_no_ccusage: (.messages.no_ccusage // "No ccusage"),
        message_ccusage_install: (.messages.ccusage_install // "Install ccusage for cost tracking"),
        message_no_active_block: (.messages.no_active_block // "No active block"),
        message_mcp_unknown: (.messages.mcp_unknown // "unknown"),
        message_mcp_none: (.messages.mcp_none // "none"),
        message_unknown_version: (.messages.unknown_version // "?"),
        message_no_submodules: (.messages.no_submodules // "--")
    } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null
}

# Function to parse the extracted config values into bash variables
apply_extracted_config() {
    local config_json="$1"
    
    # Extract all values in a single operation
    local config_data
    config_data=$(extract_all_config_values "$config_json")
    
    if [[ -z "$config_data" ]]; then
        echo "Warning: Failed to extract config values" >&2
        return 1
    fi
    
    # Parse the key=value pairs and apply them
    while IFS='=' read -r key value; do
        case "$key" in
            theme_name)
                [[ "$value" != "null" && "$value" != "" ]] && CONFIG_THEME="$value"
                ;;
            # Colors - only apply if theme is custom
            color_*)
                if [[ "$CONFIG_THEME" == "custom" && "$value" != "null" && "$value" != "" ]]; then
                    case "$key" in
                        color_red) CONFIG_RED="$value" ;;
                        color_blue) CONFIG_BLUE="$value" ;;
                        color_green) CONFIG_GREEN="$value" ;;
                        color_yellow) CONFIG_YELLOW="$value" ;;
                        color_magenta) CONFIG_MAGENTA="$value" ;;
                        color_cyan) CONFIG_CYAN="$value" ;;
                        color_white) CONFIG_WHITE="$value" ;;
                        color_orange) CONFIG_ORANGE="$value" ;;
                        color_light_orange) CONFIG_LIGHT_ORANGE="$value" ;;
                        color_light_gray) CONFIG_LIGHT_GRAY="$value" ;;
                        color_bright_green) CONFIG_BRIGHT_GREEN="$value" ;;
                        color_purple) CONFIG_PURPLE="$value" ;;
                        color_teal) CONFIG_TEAL="$value" ;;
                        color_gold) CONFIG_GOLD="$value" ;;
                        color_pink_bright) CONFIG_PINK_BRIGHT="$value" ;;
                        color_indigo) CONFIG_INDIGO="$value" ;;
                        color_violet) CONFIG_VIOLET="$value" ;;
                        color_light_blue) CONFIG_LIGHT_BLUE="$value" ;;
                        color_dim) CONFIG_DIM="$value" ;;
                        color_italic) CONFIG_ITALIC="$value" ;;
                        color_strikethrough) CONFIG_STRIKETHROUGH="$value" ;;
                        color_reset) CONFIG_RESET="$value" ;;
                    esac
                fi
                ;;
            # Features
            feature_*)
                if [[ "$value" == "true" || "$value" == "false" ]]; then
                    case "$key" in
                        feature_show_commits) CONFIG_SHOW_COMMITS="$value" ;;
                        feature_show_version) CONFIG_SHOW_VERSION="$value" ;;
                        feature_show_submodules) CONFIG_SHOW_SUBMODULES="$value" ;;
                        feature_show_mcp) CONFIG_SHOW_MCP_STATUS="$value" ;;
                        feature_show_cost) CONFIG_SHOW_COST_TRACKING="$value" ;;
                        feature_show_reset) CONFIG_SHOW_RESET_INFO="$value" ;;
                        feature_show_session) CONFIG_SHOW_SESSION_INFO="$value" ;;
                    esac
                fi
                ;;
            # Timeouts
            timeout_*)
                [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                    timeout_mcp) CONFIG_MCP_TIMEOUT="$value" ;;
                    timeout_version) CONFIG_VERSION_TIMEOUT="$value" ;;
                    timeout_ccusage) CONFIG_CCUSAGE_TIMEOUT="$value" ;;
                esac
                ;;
            # Emojis
            emoji_*)
                [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                    emoji_opus) CONFIG_OPUS_EMOJI="$value" ;;
                    emoji_haiku) CONFIG_HAIKU_EMOJI="$value" ;;
                    emoji_sonnet) CONFIG_SONNET_EMOJI="$value" ;;
                    emoji_default) CONFIG_DEFAULT_MODEL_EMOJI="$value" ;;
                    emoji_clean) CONFIG_CLEAN_STATUS_EMOJI="$value" ;;
                    emoji_dirty) CONFIG_DIRTY_STATUS_EMOJI="$value" ;;
                    emoji_clock) CONFIG_CLOCK_EMOJI="$value" ;;
                    emoji_live_block) CONFIG_LIVE_BLOCK_EMOJI="$value" ;;
                esac
                ;;
            # Labels
            label_*)
                [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                    label_commits) CONFIG_COMMITS_LABEL="$value" ;;
                    label_repo) CONFIG_REPO_LABEL="$value" ;;
                    label_monthly) CONFIG_MONTHLY_LABEL="$value" ;;
                    label_weekly) CONFIG_WEEKLY_LABEL="$value" ;;
                    label_daily) CONFIG_DAILY_LABEL="$value" ;;
                    label_mcp) CONFIG_MCP_LABEL="$value" ;;
                    label_version_prefix) CONFIG_VERSION_PREFIX="$value" ;;
                    label_submodule) CONFIG_SUBMODULE_LABEL="$value" ;;
                    label_session_prefix) CONFIG_SESSION_PREFIX="$value" ;;
                    label_live) CONFIG_LIVE_LABEL="$value" ;;
                    label_reset) CONFIG_RESET_LABEL="$value" ;;
                esac
                ;;
            # Cache
            cache_*)
                [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                    cache_version_duration) CONFIG_VERSION_CACHE_DURATION="$value" ;;
                    cache_version_file) CONFIG_VERSION_CACHE_FILE="$value" ;;
                esac
                ;;
            # Display
            display_*)
                [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                    display_time_format) CONFIG_TIME_FORMAT="$value" ;;
                    display_date_format) CONFIG_DATE_FORMAT="$value" ;;
                    display_date_format_compact) CONFIG_DATE_FORMAT_COMPACT="$value" ;;
                esac
                ;;
            # Messages
            message_*)
                [[ "$value" != "null" && "$value" != "" ]] && case "$key" in
                    message_no_ccusage) CONFIG_NO_CCUSAGE_MESSAGE="$value" ;;
                    message_ccusage_install) CONFIG_CCUSAGE_INSTALL_MESSAGE="$value" ;;
                    message_no_active_block) CONFIG_NO_ACTIVE_BLOCK_MESSAGE="$value" ;;
                    message_mcp_unknown) CONFIG_MCP_UNKNOWN_MESSAGE="$value" ;;
                    message_mcp_none) CONFIG_MCP_NONE_MESSAGE="$value" ;;
                    message_unknown_version) CONFIG_UNKNOWN_VERSION="$value" ;;
                    message_no_submodules) CONFIG_NO_SUBMODULES="$value" ;;
                esac
                ;;
        esac
    done <<< "$config_data"
    
    return 0
}