# Minimal Configuration
# Optimized for performance and simplicity
# Copy these values into your statusline.sh

CONFIG_THEME="classic"

# === PERFORMANCE OPTIMIZATIONS ===
# Reduced timeouts for faster response
CONFIG_MCP_TIMEOUT="1s"
CONFIG_VERSION_TIMEOUT="1s" 
CONFIG_CCUSAGE_TIMEOUT="1s"

# Shorter cache duration to reduce memory
CONFIG_VERSION_CACHE_DURATION=300  # 5 minutes instead of 1 hour

# === FEATURE TOGGLES - MINIMAL SETUP ===
CONFIG_SHOW_COMMITS=true           # Keep - lightweight
CONFIG_SHOW_VERSION=false          # Disable - requires network call
CONFIG_SHOW_SUBMODULES=false       # Disable - not always needed
CONFIG_SHOW_MCP_STATUS=false       # Disable - requires network call
CONFIG_SHOW_COST_TRACKING=false    # Disable - requires network/deps
CONFIG_SHOW_RESET_INFO=false       # Disable - depends on cost tracking
CONFIG_SHOW_SESSION_INFO=false     # Disable - not essential

# === SIMPLIFIED LABELS ===
CONFIG_COMMITS_LABEL="C:"
CONFIG_VERSION_PREFIX="v"
CONFIG_SUBMODULE_LABEL="S:"

# === SIMPLE EMOJIS (optional - can be disabled) ===
CONFIG_CLEAN_STATUS_EMOJI="✓"
CONFIG_DIRTY_STATUS_EMOJI="±"
CONFIG_CLOCK_EMOJI="⏰"

# === FALLBACK MESSAGES ===
CONFIG_NO_CCUSAGE_MESSAGE="--"
CONFIG_MCP_UNKNOWN_MESSAGE="--"
CONFIG_MCP_NONE_MESSAGE="--"
CONFIG_UNKNOWN_VERSION="--"
CONFIG_NO_SUBMODULES="--"