# Developer Configuration
# Maximum information display with extended features
# Copy these values into your statusline-enhanced.sh

CONFIG_THEME="catppuccin"

# === EXTENDED TIMEOUTS FOR DETAILED INFO ===
CONFIG_MCP_TIMEOUT="5s"        # Longer timeout for MCP discovery
CONFIG_VERSION_TIMEOUT="3s"    # Allow time for version check
CONFIG_CCUSAGE_TIMEOUT="5s"    # Detailed cost analysis

# === COMPREHENSIVE CACHING ===
CONFIG_VERSION_CACHE_DURATION=1800  # 30 minutes - balance freshness/performance
CONFIG_VERSION_CACHE_FILE="/tmp/.claude_version_cache"

# === ALL FEATURES ENABLED ===
CONFIG_SHOW_COMMITS=true           # Show today's commit activity
CONFIG_SHOW_VERSION=true           # Show Claude Code version
CONFIG_SHOW_SUBMODULES=true        # Show git submodule information
CONFIG_SHOW_MCP_STATUS=true        # Show MCP server connectivity
CONFIG_SHOW_COST_TRACKING=true     # Show detailed cost breakdown
CONFIG_SHOW_RESET_INFO=true        # Show billing block reset timer
CONFIG_SHOW_SESSION_INFO=true      # Show session information

# === DETAILED DISPLAY FORMATS ===
CONFIG_TIME_FORMAT="%H:%M:%S"      # Include seconds for precision
CONFIG_DATE_FORMAT="%Y-%m-%d"      # ISO standard date format
CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"

# === DEVELOPER-FRIENDLY EMOJIS ===
CONFIG_OPUS_EMOJI="🧠"             # Claude Opus
CONFIG_HAIKU_EMOJI="⚡"             # Claude Haiku  
CONFIG_SONNET_EMOJI="🎵"           # Claude Sonnet
CONFIG_DEFAULT_MODEL_EMOJI="🤖"    # Other models

CONFIG_CLEAN_STATUS_EMOJI="✅"      # Clean repository
CONFIG_DIRTY_STATUS_EMOJI="📝"     # Modified files (more dev-appropriate)
CONFIG_CLOCK_EMOJI="⏱️"            # Precise time indicator
CONFIG_LIVE_BLOCK_EMOJI="🔥"       # Active billing

# === DETAILED LABELS ===
CONFIG_COMMITS_LABEL="Commits Today:"
CONFIG_REPO_LABEL="SESSION"        # More descriptive
CONFIG_MONTHLY_LABEL="30D"         # Compact but clear
CONFIG_WEEKLY_LABEL="7D"
CONFIG_DAILY_LABEL="TODAY"
CONFIG_SUBMODULE_LABEL="SUBS:"
CONFIG_MCP_LABEL="MCP Servers"     # More descriptive
CONFIG_VERSION_PREFIX="Claude "    # Full prefix
CONFIG_SESSION_PREFIX="Session:"
CONFIG_LIVE_LABEL="ACTIVE"
CONFIG_RESET_LABEL="Block Reset"

# === INFORMATIVE ERROR MESSAGES ===
CONFIG_NO_CCUSAGE_MESSAGE="ccusage not configured"
CONFIG_CCUSAGE_INSTALL_MESSAGE="Run: npm install -g bunx ccusage"
CONFIG_NO_ACTIVE_BLOCK_MESSAGE="No active billing block"
CONFIG_MCP_UNKNOWN_MESSAGE="MCP status unknown"
CONFIG_MCP_NONE_MESSAGE="No MCP servers configured"
CONFIG_UNKNOWN_VERSION="version unknown"
CONFIG_NO_SUBMODULES="no submodules"