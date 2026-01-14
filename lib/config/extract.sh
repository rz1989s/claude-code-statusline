#!/bin/bash

# ============================================================================
# Claude Code Statusline - Configuration Value Extraction Module
# ============================================================================
#
# This module handles extraction of configuration values from parsed JSON.
# It maps JSON keys to CONFIG_* environment variables.
#
# Dependencies: core.sh, config/constants.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_EXTRACT_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_EXTRACT_LOADED=true

# ============================================================================
# VALUE EXTRACTION FUNCTIONS
# ============================================================================

# Extract configuration values from JSON using optimized jq operation
extract_config_values() {
    local config_json="$1"

    if [[ -z "$config_json" || "$config_json" == "{}" ]]; then
        handle_error "Empty or invalid JSON configuration" 1 "extract_config_values"
        return 1
    fi

    # Pure extraction from Config.toml - no fallbacks (single source of truth)
    local config_data
    config_data=$(echo "$config_json" | jq -r '{
            theme_name: ."theme.name",
            feature_show_commits: ."features.show_commits",
            feature_show_version: ."features.show_version",
            feature_show_submodules: ."features.show_submodules",
            feature_hide_submodules_when_empty: ."features.hide_submodules_when_empty",
            feature_show_mcp: ."features.show_mcp_status",
            feature_show_cost: ."features.show_cost_tracking",
            feature_show_reset: ."features.show_reset_info",
            feature_show_session: ."features.show_session_info",
            timeout_mcp: ."timeouts.mcp",
            timeout_version: ."timeouts.version",
            timeout_ccusage: ."timeouts.ccusage",
            cost_session_source: ."cost.session_source",
            cache_efficiency_source: ."cache.efficiency_source",
            feature_show_code_productivity: ."features.show_code_productivity",
            code_productivity_show_zero: ."code_productivity.show_zero",
            code_productivity_emoji: ."code_productivity.emoji",
            feature_show_context_window: ."features.show_context_window",
            context_window_emoji: ."context_window.emoji",
            context_window_show_tokens: ."context_window.show_tokens",
            context_window_show_when_empty: ."context_window.show_when_empty",
            context_window_warn_threshold: ."context_window.warn_threshold",
            context_window_critical_threshold: ."context_window.critical_threshold",
            context_window_medium_threshold: ."context_window.medium_threshold",
            session_info_show_id: ."session_info.show_id",
            session_info_show_project: ."session_info.show_project",
            session_info_id_length: ."session_info.id_length",
            session_info_separator: ."session_info.separator",
            session_info_emoji_session: ."session_info.emoji_session",
            session_info_emoji_project: ."session_info.emoji_project",
            session_info_show_when_empty: ."session_info.show_when_empty",
            cache_version_duration: ."cache.version_duration",
            cache_version_file: ."cache.version_file",
            display_time_format: ."display.time_format",
            display_date_format: ."display.date_format",
            display_date_format_compact: ."display.date_format_compact",
            label_commits: ."labels.commits",
            label_repo: ."labels.repo",
            label_monthly: ."labels.monthly",
            label_weekly: ."labels.weekly",
            label_daily: ."labels.daily",
            label_submodule: ."labels.submodule",
            label_mcp: ."labels.mcp",
            label_version_prefix: ."labels.version_prefix",
            label_claude_code_prefix: ."labels.claude_code_prefix",
            label_statusline_prefix: ."labels.statusline_prefix",
            label_session_prefix: ."labels.session_prefix",
            label_live: ."labels.live",
            label_reset: ."labels.reset",
            display_lines: ."display.lines",
            line1_components: (."display.line1.components" | join(",")),
            line2_components: (."display.line2.components" | join(",")),
            line3_components: (."display.line3.components" | join(",")),
            line4_components: (."display.line4.components" | join(",")),
            line5_components: (."display.line5.components" | join(",")),
            line6_components: (."display.line6.components" | join(",")),
            line7_components: (."display.line7.components" | join(",")),
            line8_components: (."display.line8.components" | join(",")),
            line9_components: (."display.line9.components" | join(",")),
            line1_separator: ."display.line1.separator",
            line2_separator: ."display.line2.separator",
            line3_separator: ."display.line3.separator",
            line4_separator: ."display.line4.separator",
            line5_separator: ."display.line5.separator",
            line6_separator: ."display.line6.separator",
            line7_separator: ."display.line7.separator",
            line8_separator: ."display.line8.separator",
            line9_separator: ."display.line9.separator",
            line1_show_when_empty: ."display.line1.show_when_empty",
            line2_show_when_empty: ."display.line2.show_when_empty",
            line3_show_when_empty: ."display.line3.show_when_empty",
            line4_show_when_empty: ."display.line4.show_when_empty",
            line5_show_when_empty: ."display.line5.show_when_empty",
            line6_show_when_empty: ."display.line6.show_when_empty",
            line7_show_when_empty: ."display.line7.show_when_empty",
            line8_show_when_empty: ."display.line8.show_when_empty",
            line9_show_when_empty: ."display.line9.show_when_empty"
        } | to_entries | map("\(.key)=\(.value)") | .[]' 2>/dev/null)

    if [[ -z "$config_data" ]]; then
        handle_warning "Failed to extract config values from JSON" "extract_config_values"
        return 1
    fi

    # Parse the extracted config values and apply them
    while IFS='=' read -r key value; do
        case "$key" in
        theme_name)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_THEME="$value"
            ;;
        feature_show_commits)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_COMMITS="$value"
            ;;
        feature_show_version)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_VERSION="$value"
            ;;
        feature_show_submodules)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_SUBMODULES="$value"
            ;;
        feature_hide_submodules_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_HIDE_SUBMODULES_WHEN_EMPTY="$value"
            ;;
        feature_show_mcp)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_MCP_STATUS="$value"
            ;;
        feature_show_cost)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_COST_TRACKING="$value"
            ;;
        feature_show_reset)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_RESET_INFO="$value"
            ;;
        feature_show_session)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SHOW_SESSION_INFO="$value"
            ;;
        timeout_mcp)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_MCP_TIMEOUT="$value"
            ;;
        timeout_version)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_TIMEOUT="$value"
            ;;
        timeout_ccusage)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_CCUSAGE_TIMEOUT="$value"
            ;;
        cost_session_source)
            # Issue #99: Cost session source (auto | native | ccusage)
            [[ "$value" == "auto" || "$value" == "native" || "$value" == "ccusage" ]] && CONFIG_COST_SESSION_SOURCE="$value"
            ;;
        cache_efficiency_source)
            # Issue #103: Cache efficiency source (auto | native | ccusage)
            [[ "$value" == "auto" || "$value" == "native" || "$value" == "ccusage" ]] && CONFIG_CACHE_EFFICIENCY_SOURCE="$value"
            ;;
        feature_show_code_productivity)
            # Issue #100: Show code productivity metrics
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_FEATURES_SHOW_CODE_PRODUCTIVITY="$value"
            ;;
        code_productivity_show_zero)
            # Issue #100: Show when +0/-0
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_CODE_PRODUCTIVITY_SHOW_ZERO="$value"
            ;;
        code_productivity_emoji)
            # Issue #100: Emoji prefix
            [[ "$value" != "null" ]] && CONFIG_CODE_PRODUCTIVITY_EMOJI="$value"
            ;;
        feature_show_context_window)
            # Issue #101: Show context window
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_FEATURES_SHOW_CONTEXT_WINDOW="$value"
            ;;
        context_window_emoji)
            # Issue #101: Context window emoji
            [[ "$value" != "null" ]] && CONFIG_CONTEXT_EMOJI="$value"
            ;;
        context_window_show_tokens)
            # Issue #101: Show token counts
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_CONTEXT_SHOW_TOKENS="$value"
            ;;
        context_window_show_when_empty)
            # Issue #101: Show when no data
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_CONTEXT_SHOW_WHEN_EMPTY="$value"
            ;;
        context_window_warn_threshold)
            # Issue #101: Warning threshold percentage
            [[ "$value" =~ ^[0-9]+$ ]] && CONFIG_CONTEXT_WARN_THRESHOLD="$value"
            ;;
        context_window_critical_threshold)
            # Issue #101: Critical threshold percentage
            [[ "$value" =~ ^[0-9]+$ ]] && CONFIG_CONTEXT_CRITICAL_THRESHOLD="$value"
            ;;
        context_window_medium_threshold)
            # Issue #101: Medium threshold percentage
            [[ "$value" =~ ^[0-9]+$ ]] && CONFIG_CONTEXT_MEDIUM_THRESHOLD="$value"
            ;;
        session_info_show_id)
            # Issue #102: Show session ID
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SESSION_INFO_SHOW_ID="$value"
            ;;
        session_info_show_project)
            # Issue #102: Show project name
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SESSION_INFO_SHOW_PROJECT="$value"
            ;;
        session_info_id_length)
            # Issue #102: Session ID length
            [[ "$value" =~ ^[0-9]+$ ]] && CONFIG_SESSION_INFO_ID_LENGTH="$value"
            ;;
        session_info_separator)
            # Issue #102: Separator between ID and project
            [[ "$value" != "null" ]] && CONFIG_SESSION_INFO_SEPARATOR="$value"
            ;;
        session_info_emoji_session)
            # Issue #102: Session emoji
            [[ "$value" != "null" ]] && CONFIG_SESSION_INFO_EMOJI_SESSION="$value"
            ;;
        session_info_emoji_project)
            # Issue #102: Project emoji
            [[ "$value" != "null" ]] && CONFIG_SESSION_INFO_EMOJI_PROJECT="$value"
            ;;
        session_info_show_when_empty)
            # Issue #102: Show when no data
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_SESSION_INFO_SHOW_WHEN_EMPTY="$value"
            ;;
        cache_version_duration)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_CACHE_DURATION="$value"
            ;;
        cache_version_file)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_CACHE_FILE="$value"
            ;;
        display_time_format)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_TIME_FORMAT="$value"
            ;;
        display_date_format)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DATE_FORMAT="$value"
            ;;
        display_date_format_compact)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DATE_FORMAT_COMPACT="$value"
            ;;
        label_commits)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_COMMITS_LABEL="$value"
            ;;
        label_repo)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_REPO_LABEL="$value"
            ;;
        label_monthly)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_MONTHLY_LABEL="$value"
            ;;
        label_weekly)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_WEEKLY_LABEL="$value"
            ;;
        label_daily)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DAILY_LABEL="$value"
            ;;
        label_submodule)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_SUBMODULE_LABEL="$value"
            ;;
        label_mcp)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_MCP_LABEL="$value"
            ;;
        label_version_prefix)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_VERSION_PREFIX="$value"
            ;;
        label_claude_code_prefix)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_CLAUDE_CODE_PREFIX="$value"
            ;;
        label_statusline_prefix)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_STATUSLINE_PREFIX="$value"
            ;;
        label_session_prefix)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_SESSION_PREFIX="$value"
            ;;
        label_live)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LIVE_LABEL="$value"
            ;;
        label_reset)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_RESET_LABEL="$value"
            ;;
        display_lines)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_DISPLAY_LINES="$value"
            ;;
        line1_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE1_COMPONENTS="$value"
            ;;
        line2_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE2_COMPONENTS="$value"
            ;;
        line3_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE3_COMPONENTS="$value"
            ;;
        line4_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE4_COMPONENTS="$value"
            ;;
        line5_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE5_COMPONENTS="$value"
            ;;
        line6_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE6_COMPONENTS="$value"
            ;;
        line7_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE7_COMPONENTS="$value"
            ;;
        line8_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE8_COMPONENTS="$value"
            ;;
        line9_components)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE9_COMPONENTS="$value"
            ;;
        line1_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE1_SEPARATOR="$value"
            ;;
        line2_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE2_SEPARATOR="$value"
            ;;
        line3_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE3_SEPARATOR="$value"
            ;;
        line4_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE4_SEPARATOR="$value"
            ;;
        line5_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE5_SEPARATOR="$value"
            ;;
        line6_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE6_SEPARATOR="$value"
            ;;
        line7_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE7_SEPARATOR="$value"
            ;;
        line8_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE8_SEPARATOR="$value"
            ;;
        line9_separator)
            [[ "$value" != "null" && "$value" != "" ]] && CONFIG_LINE9_SEPARATOR="$value"
            ;;
        line1_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE1_SHOW_WHEN_EMPTY="$value"
            ;;
        line2_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE2_SHOW_WHEN_EMPTY="$value"
            ;;
        line3_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE3_SHOW_WHEN_EMPTY="$value"
            ;;
        line4_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE4_SHOW_WHEN_EMPTY="$value"
            ;;
        line5_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE5_SHOW_WHEN_EMPTY="$value"
            ;;
        line6_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE6_SHOW_WHEN_EMPTY="$value"
            ;;
        line7_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE7_SHOW_WHEN_EMPTY="$value"
            ;;
        line8_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE8_SHOW_WHEN_EMPTY="$value"
            ;;
        line9_show_when_empty)
            [[ "$value" == "true" || "$value" == "false" ]] && CONFIG_LINE9_SHOW_WHEN_EMPTY="$value"
            ;;
        esac
    done <<<"$config_data"

    return 0
}

# Export function
export -f extract_config_values
