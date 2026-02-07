#!/bin/bash

# ============================================================================
# Claude Code Statusline - Configuration Constants Module
# ============================================================================
#
# This module defines all configuration variable declarations and exports.
# These are the global CONFIG_* variables used throughout the statusline.
#
# Dependencies: None (loaded first)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_CONSTANTS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_CONSTANTS_LOADED=true

# ============================================================================
# CONFIGURATION PATHS
# ============================================================================

# Single configuration file location (source of truth)
export CONFIG_FILE_PATHS=(
    "$HOME/.claude/statusline/Config.toml"
)

# ============================================================================
# CORE CONFIGURATION VARIABLES
# ============================================================================

# Theme configuration
export CONFIG_THEME="catppuccin"

# Feature toggles
export CONFIG_SHOW_COMMITS=""
export CONFIG_SHOW_VERSION=""
export CONFIG_SHOW_SUBMODULES=""
export CONFIG_HIDE_SUBMODULES_WHEN_EMPTY=""
export CONFIG_SHOW_WORKTREE=""
export CONFIG_SHOW_MCP_STATUS=""
export CONFIG_SHOW_COST_TRACKING=""
export CONFIG_SHOW_RESET_INFO=""
export CONFIG_SHOW_SESSION_INFO=""

# Timeout configuration
export CONFIG_MCP_TIMEOUT=""
export CONFIG_VERSION_TIMEOUT=""

# ============================================================================
# COST AND CACHE CONFIGURATION
# ============================================================================

# Issue #99: Cost session source (auto | native)
export CONFIG_COST_SESSION_SOURCE="auto"

# Issue #103: Cache efficiency source (auto | native)
export CONFIG_CACHE_EFFICIENCY_SOURCE="auto"

# ============================================================================
# CODE PRODUCTIVITY CONFIGURATION (Issue #100)
# ============================================================================

export CONFIG_FEATURES_SHOW_CODE_PRODUCTIVITY="true"
export CONFIG_CODE_PRODUCTIVITY_SHOW_ZERO="false"
export CONFIG_CODE_PRODUCTIVITY_EMOJI=""

# ============================================================================
# CONTEXT WINDOW CONFIGURATION (Issue #101)
# ============================================================================

export CONFIG_FEATURES_SHOW_CONTEXT_WINDOW="true"
export CONFIG_CONTEXT_EMOJI="🧠"
export CONFIG_CONTEXT_SHOW_TOKENS="true"
export CONFIG_CONTEXT_SHOW_WHEN_EMPTY="false"
export CONFIG_CONTEXT_WARN_THRESHOLD="75"
export CONFIG_CONTEXT_CRITICAL_THRESHOLD="90"
export CONFIG_CONTEXT_MEDIUM_THRESHOLD="50"

# ============================================================================
# SESSION INFO CONFIGURATION (Issue #102)
# ============================================================================

export CONFIG_SESSION_INFO_SHOW_ID="true"
export CONFIG_SESSION_INFO_SHOW_PROJECT="true"
export CONFIG_SESSION_INFO_ID_LENGTH="8"
export CONFIG_SESSION_INFO_SEPARATOR=" • "
export CONFIG_SESSION_INFO_EMOJI_SESSION="🔗"
export CONFIG_SESSION_INFO_EMOJI_PROJECT="📁"
export CONFIG_SESSION_INFO_SHOW_WHEN_EMPTY="false"

# ============================================================================
# CACHE CONFIGURATION
# ============================================================================

export CONFIG_VERSION_CACHE_DURATION=""
export CONFIG_VERSION_CACHE_FILE=""

# ============================================================================
# FORMAT CONFIGURATION
# ============================================================================

export CONFIG_TIME_FORMAT=""
export CONFIG_DATE_FORMAT=""
export CONFIG_DATE_FORMAT_COMPACT=""

# ============================================================================
# COLOR CONFIGURATION (Set by theme system)
# ============================================================================

export CONFIG_RED=""
export CONFIG_BLUE=""
export CONFIG_GREEN=""
export CONFIG_YELLOW=""
export CONFIG_MAGENTA=""
export CONFIG_CYAN=""
export CONFIG_WHITE=""
export CONFIG_ORANGE=""
export CONFIG_LIGHT_ORANGE=""
export CONFIG_LIGHT_GRAY=""
export CONFIG_BRIGHT_GREEN=""
export CONFIG_PURPLE=""
export CONFIG_TEAL=""
export CONFIG_GOLD=""
export CONFIG_PINK_BRIGHT=""
export CONFIG_INDIGO=""
export CONFIG_VIOLET=""
export CONFIG_LIGHT_BLUE=""
export CONFIG_DIM=""
export CONFIG_NC=""

# ============================================================================
# EMOJI CONFIGURATION
# ============================================================================

export CONFIG_OPUS_EMOJI=""
export CONFIG_HAIKU_EMOJI=""
export CONFIG_SONNET_EMOJI=""
export CONFIG_DEFAULT_MODEL_EMOJI=""
export CONFIG_CLEAN_STATUS_EMOJI=""
export CONFIG_DIRTY_STATUS_EMOJI=""
export CONFIG_CLOCK_EMOJI=""
export CONFIG_LIVE_BLOCK_EMOJI=""

# ============================================================================
# LABEL CONFIGURATION
# ============================================================================

export CONFIG_COMMITS_LABEL=""
export CONFIG_REPO_LABEL=""
export CONFIG_MONTHLY_LABEL=""
export CONFIG_WEEKLY_LABEL=""
export CONFIG_DAILY_LABEL=""
export CONFIG_SUBMODULE_LABEL=""
export CONFIG_MCP_LABEL=""
export CONFIG_VERSION_PREFIX=""
export CONFIG_CLAUDE_CODE_PREFIX=""
export CONFIG_STATUSLINE_PREFIX=""
export CONFIG_SESSION_PREFIX=""
export CONFIG_LIVE_LABEL=""
export CONFIG_RESET_LABEL=""

# ============================================================================
# MESSAGE CONFIGURATION
# ============================================================================

export CONFIG_NO_ACTIVE_BLOCK_MESSAGE=""
export CONFIG_MCP_UNKNOWN_MESSAGE=""
export CONFIG_MCP_NONE_MESSAGE=""
export CONFIG_UNKNOWN_VERSION=""
export CONFIG_NO_SUBMODULES=""

# ============================================================================
# PRAYER CONFIGURATION
# ============================================================================

export CONFIG_PRAYER_ENABLED=""
export CONFIG_PRAYER_LOCATION_MODE=""
export CONFIG_PRAYER_LATITUDE=""
export CONFIG_PRAYER_LONGITUDE=""
export CONFIG_PRAYER_CALCULATION_METHOD=""
export CONFIG_PRAYER_MADHAB=""
export CONFIG_PRAYER_TIMEZONE=""

# ============================================================================
# DISPLAY LINE CONFIGURATION
# ============================================================================

export CONFIG_DISPLAY_LINES=""

# Line component configuration
export CONFIG_LINE1_COMPONENTS=""
export CONFIG_LINE2_COMPONENTS=""
export CONFIG_LINE3_COMPONENTS=""
export CONFIG_LINE4_COMPONENTS=""
export CONFIG_LINE5_COMPONENTS=""
export CONFIG_LINE6_COMPONENTS=""
export CONFIG_LINE7_COMPONENTS=""
export CONFIG_LINE8_COMPONENTS=""
export CONFIG_LINE9_COMPONENTS=""

# Line separator configuration
export CONFIG_LINE1_SEPARATOR=""
export CONFIG_LINE2_SEPARATOR=""
export CONFIG_LINE3_SEPARATOR=""
export CONFIG_LINE4_SEPARATOR=""
export CONFIG_LINE5_SEPARATOR=""
export CONFIG_LINE6_SEPARATOR=""
export CONFIG_LINE7_SEPARATOR=""
export CONFIG_LINE8_SEPARATOR=""
export CONFIG_LINE9_SEPARATOR=""

# Line show_when_empty configuration
export CONFIG_LINE1_SHOW_WHEN_EMPTY=""
export CONFIG_LINE2_SHOW_WHEN_EMPTY=""
export CONFIG_LINE3_SHOW_WHEN_EMPTY=""
export CONFIG_LINE4_SHOW_WHEN_EMPTY=""
export CONFIG_LINE5_SHOW_WHEN_EMPTY=""
export CONFIG_LINE6_SHOW_WHEN_EMPTY=""
export CONFIG_LINE7_SHOW_WHEN_EMPTY=""
export CONFIG_LINE8_SHOW_WHEN_EMPTY=""
export CONFIG_LINE9_SHOW_WHEN_EMPTY=""
