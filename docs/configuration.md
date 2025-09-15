# ⚙️ Single Source Configuration Guide (v2.9.0)

**Complete guide to the revolutionary single source configuration system - ONE Config.toml with all 227 settings.**

Transform your terminal with the **most significant configuration simplification** ever - no more hunting for parameter names across multiple files!

> 🎯 **Single Source Revolution**: The configuration system has been completely simplified and is **100% operational** (v2.9.0). Gone are 13 example files + hardcoded defaults + jq fallbacks. Now there's ONE comprehensive Config.toml with all 227 settings pre-filled. Users just edit values, not search for parameter names. Combined with the revolutionary 3-tier download system, installation and configuration are now bulletproof.

## 🚀 **Ultra-Simple Getting Started**

### Single Source Setup ✨

**Comprehensive Config.toml created automatically during installation:**
```bash
# 1. Install (creates Config.toml with ALL 227 settings automatically)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

# 2. Edit your comprehensive Config.toml (all settings included!)
nano ~/.claude/statusline/Config.toml

# 3. Use it immediately!
~/.claude/statusline.sh
```

**Dev6 Installation (Enhanced Settings.json Management):**
```bash
# Install dev6 with enhanced settings.json handling
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6

# Install dev6 with existing settings.json preservation
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6 --preserve-statusline
```

**🎯 No More Configuration Hunting!**
- ✅ All 227 settings in ONE file
- ✅ Parameters pre-filled with sensible defaults
- ✅ Just edit values, don't search for names
- ✅ Zero code defaults or jq fallbacks to confuse you

---

## 🧩 **Atomic Component System (v2.7.0)**

The statusline now uses an **atomic component architecture** where each component serves a single purpose, giving you maximum customization flexibility.

### 18 Available Components

**Repository & Git Components (4):**
- `repo_info` - Repository directory and git status
- `commits` - Commit count only (pure atomic)
- `submodules` - Submodule status only (pure atomic)
- `version_info` - Claude Code version display

**Model & Session Components (4):**
- `model_info` - Claude model with emoji
- `cost_repo` - Repository cost tracking
- `cost_live` - Live block cost monitoring
- `reset_timer` - Block reset countdown timer

**Cost Analytics Components (3):**
- `cost_monthly` - 30-day costs only (pure atomic)
- `cost_weekly` - 7-day costs only (pure atomic)
- `cost_daily` - Daily costs only (pure atomic)

**Block Metrics Components (4):**
- `burn_rate` - Token consumption rate and cost per hour
- `token_usage` - Total tokens consumed in current block
- `cache_efficiency` - Cache hit percentage for optimization
- `block_projection` - Projected cost and tokens for current block

**System Components (2):**
- `mcp_status` - MCP server health monitoring
- `time_display` - Current time formatting

**Spiritual Components (1):**
- `prayer_times` - Islamic prayer times integration

### Modular Display Configuration

Configure your statusline with **1-9 lines** and arrange components freely:

```toml
# === MODULAR DISPLAY CONFIGURATION ===
display.lines = 4                                    # Show 4 lines total

# Line 1: Repository info with separated git components
display.line1.components = ["repo_info", "commits", "submodules", "version_info"]
display.line1.separator = " │ "

# Line 2: Model and session info  
display.line2.components = ["model_info", "cost_session", "time_display"]
display.line2.separator = " │ "

# Line 3: Atomic cost breakdown - perfect separation!
display.line3.components = ["cost_monthly", "cost_weekly", "cost_daily"]
display.line3.separator = " │ "

# Line 4: Live operations
display.line4.components = ["cost_live", "mcp_status"]
display.line4.separator = " │ "
```

### Atomic Component Benefits

**Before (complex components):**
```
│ Commits:8 SUB:-- │ 30DAY $660.87 7DAY $9.31 DAY $36.10 │
```
*Missing separators within components*

**After (atomic components):**
```
│ Commits:8 │ SUB:-- │ 30DAY $660.87 │ 7DAY $9.31 │ DAY $36.10 │
```
*Perfect visual separation between all data points*

### Component Enabling/Disabling

Enable or disable any atomic component independently:

```toml
# === ATOMIC COMPONENT CONFIGURATION ===
components.commits.enabled = true          # Show commit count
components.submodules.enabled = false      # Hide submodules  
components.cost_monthly.enabled = true     # Show 30-day costs
components.cost_weekly.enabled = false     # Hide 7-day costs
components.cost_daily.enabled = true       # Show daily costs
```

---

## 📁 **Configuration Discovery**

Your configuration is loaded in this **priority order** (highest to lowest):

1. **Environment Variables** (`ENV_CONFIG_*`) - **Highest Priority**
2. **`./Config.toml`** - Project-specific configuration 
3. **`~/.config/claude-code-statusline/Config.toml`** - XDG standard location
4. **`~/.claude-statusline.toml`** - User home directory
5. **Inline Script Configuration** - **Fallback** (backwards compatible)

### File Discovery Examples

```bash
# Project-specific configuration (highest precedence)
cd ~/my-project/
cp examples/Config.toml ./Config.toml    # Copy template
./statusline.sh                          # Uses ./Config.toml

# User-wide configuration
cp examples/Config.toml ~/.config/claude-code-statusline/Config.toml
./statusline.sh                          # Uses ~/.config/.../Config.toml

# Environment override (overrides all files)
ENV_CONFIG_THEME=garden ./statusline.sh  # Temporarily uses garden theme
```

---

## 📋 **TOML Configuration Structure**

### Complete Configuration Template

```toml
# ============================================================================
# Claude Code Statusline Configuration (Config.toml)
# ============================================================================

# === THEME CONFIGURATION ===
# Available themes: "classic", "garden", "catppuccin", "custom"
theme.name = "catppuccin"

# === MODULAR DISPLAY CONFIGURATION (v2.7.0) ===
display.lines = 6                                    # Show 6 lines total

# Line 1: Repository with atomic git components
display.line1.components = ["repo_info", "commits", "submodules", "version_info"]
display.line1.separator = " │ "

# Line 2: Model and session info
display.line2.components = ["model_info", "cost_session", "time_display"]
display.line2.separator = " │ "

# Line 3: Atomic cost breakdown - perfect separation!
display.line3.components = ["cost_monthly", "cost_weekly", "cost_daily"]
display.line3.separator = " │ "

# Line 4: Live operations
display.line4.components = ["cost_live", "mcp_status"]
display.line4.separator = " │ "

# Line 5: Reset timer when available
display.line5.components = ["reset_timer"]
display.line5.show_when_empty = false

# Line 6: Prayer times
display.line6.components = ["prayer_times"]

# === ATOMIC COMPONENT CONFIGURATION ===
components.repo_info.enabled = true
components.commits.enabled = true
components.submodules.enabled = true
components.version_info.enabled = true
components.time_display.enabled = true
components.model_info.enabled = true
components.cost_session.enabled = true
components.cost_monthly.enabled = true
components.cost_weekly.enabled = true
components.cost_daily.enabled = true
components.cost_live.enabled = true
components.mcp_status.enabled = true
components.reset_timer.enabled = true
components.prayer_times.enabled = true

# === LEGACY COMPONENTS (Backward Compatibility) ===
components.commits.enabled = true
components.submodules.enabled = true
components.cost_monthly.enabled = true
components.cost_weekly.enabled = true
components.cost_daily.enabled = true

# === CORE FEATURE TOGGLES ===
features.show_commits = true          # Show today's commit count
features.show_version = true          # Display Claude Code version
features.show_submodules = true       # Show git submodule count
features.show_mcp_status = true       # MCP server health monitoring
features.show_cost_tracking = true    # Financial cost tracking (ccusage)
features.show_reset_info = true       # Block reset countdown
features.show_session_info = true     # Session information

# === MODEL EMOJIS ===
emojis.opus = "🧠"                  # Claude Opus
emojis.haiku = "⚡"                 # Claude Haiku
emojis.sonnet = "🎵"                # Claude Sonnet
emojis.default_model = "🤖"         # Other models
emojis.clean_status = "✅"          # Clean git repository
emojis.dirty_status = "📁"          # Dirty git repository
emojis.clock = "🕐"                 # Time display
emojis.live_block = "🔥"            # Active billing block

# === TIMEOUTS ===
timeouts.mcp = "3s"                   # MCP server status check timeout
timeouts.version = "2s"               # Claude Code version check timeout
timeouts.ccusage = "3s"               # Cost tracking API timeout

# === DISPLAY LABELS ===
labels.commits = "Commits:"         # Commit count label
labels.repo = "REPO"                # Repository cost label
labels.monthly = "30DAY"            # Monthly cost label
labels.weekly = "7DAY"              # Weekly cost label
labels.daily = "DAY"                # Daily cost label
labels.mcp = "MCP"                  # MCP server label
labels.version_prefix = "ver"       # Version prefix
labels.submodule = "SUB:"           # Submodule label
labels.session_prefix = "S:"        # Session prefix
labels.live = "LIVE"                # Live cost label
labels.reset = "RESET"              # Reset timer label

# === CACHE SETTINGS ===
cache.version_duration = 3600      # Cache Claude version for 1 hour
cache.version_file = "/tmp/.claude_version_cache"  # Version cache file location

# === CACHE ISOLATION (v2.1.0+) ===
# Prevents cache contamination when running multiple Claude Code instances
cache.isolation.mode = "repository"     # Default isolation mode
cache.isolation.mcp = "repository"      # MCP servers per repository  
cache.isolation.git = "repository"      # Git data per repository
cache.isolation.cost = "shared"         # Cost tracking user-wide
cache.isolation.session = "repository"  # Session costs per project

# === DISPLAY FORMATS ===
display.time_format = "%H:%M"        # 24-hour format (14:30)
display.date_format = "%Y-%m-%d"     # ISO format (2024-08-18)
display.date_format_compact = "%Y%m%d"  # Compact format (20240818)

# === ERROR/FALLBACK MESSAGES ===
messages.no_ccusage = "No ccusage"
messages.ccusage_install = "Install ccusage for cost tracking"
messages.no_active_block = "No active block"
messages.mcp_unknown = "unknown"
messages.mcp_none = "none"
messages.unknown_version = "?"
messages.no_submodules = "--"
```

---

## 🎨 **Theme Configuration**

### Pre-built Themes

```toml
# === CLASSIC THEME ===
theme.name = "classic"        # Traditional ANSI terminal colors

# === GARDEN THEME ===
theme.name = "garden"         # Soft pastel colors for gentle aesthetic

# === CATPPUCCIN THEME ===
theme.name = "catppuccin"     # Popular catppuccin mocha theme colors
```

### Custom Theme Configuration

```toml
# === CUSTOM THEME ===
theme.name = "custom"

# Basic ANSI colors (most compatible)
colors.basic.red = "\\033[31m"       # Used for: mode info, alerts
colors.basic.blue = "\\033[34m"      # Used for: directory path, information
colors.basic.green = "\\033[32m"     # Used for: clean git status, success
colors.basic.yellow = "\\033[33m"    # Used for: dirty git status, warnings
colors.basic.magenta = "\\033[35m"   # Used for: git branch, highlights
colors.basic.cyan = "\\033[36m"      # Used for: model name, secondary info
colors.basic.white = "\\033[37m"     # Used for: general text

# Extended colors (256-color and RGB)
colors.extended.orange = "\\033[38;5;208m"       # Used for: time display
colors.extended.light_orange = "\\033[38;5;215m" # Used for: clock emoji
colors.extended.light_gray = "\\033[38;5;248m"   # Used for: reset info
colors.extended.bright_green = "\\033[92m"       # Used for: MCP servers, submodules
colors.extended.purple = "\\033[95m"             # Used for: Claude version
colors.extended.teal = "\\033[38;5;73m"          # Used for: commits, daily costs
colors.extended.gold = "\\033[38;5;220m"         # Used for: special highlights
colors.extended.pink_bright = "\\033[38;5;205m"  # Used for: 30-day costs
colors.extended.indigo = "\\033[38;5;105m"       # Used for: 7-day costs
colors.extended.violet = "\\033[38;5;99m"        # Used for: session info
colors.extended.light_blue = "\\033[38;5;111m"   # Used for: MCP server names

# Text formatting
colors.formatting.dim = "\\033[2m"           # Used for: separators, dimmed text
colors.formatting.italic = "\\033[3m"        # Used for: reset info
colors.formatting.strikethrough = "\\033[9m" # Used for: offline MCP servers
colors.formatting.reset = "\\033[0m"         # Used for: reset all formatting
```

### Theme Examples

#### Ocean Theme
```toml
[theme]
name = "custom"

[colors.basic]
blue = "\\033[38;2;0;119;190m"      # Deep ocean blue
teal = "\\033[38;2;0;150;136m"      # Teal depths
cyan = "\\033[38;2;0;188;212m"      # Surface water
green = "\\033[38;2;76;175;80m"     # Seaweed green
yellow = "\\033[38;2;255;193;7m"    # Sandy shore
white = "\\033[38;2;224;247;250m"   # Sea foam
```

#### Cyberpunk Theme
```toml
theme.name = "custom"

colors.basic.red = "\\033[38;2;255;0;102m"      # Electric pink
colors.basic.blue = "\\033[38;2;0;255;255m"     # Neon cyan
colors.basic.green = "\\033[38;2;0;255;0m"      # Matrix green
colors.basic.yellow = "\\033[38;2;255;255;0m"   # Electric yellow
colors.basic.magenta = "\\033[38;2;255;0;255m"  # Neon magenta
colors.basic.cyan = "\\033[38;2;0;255;255m"     # Bright cyan
colors.basic.white = "\\033[38;2;255;255;255m"  # Bright white
```

---

## 🔧 **Rich CLI Interface**

### Configuration Generation

```bash
# === GENERATE CONFIG FILES ===
cp examples/Config.toml ./Config.toml # Copy template                    # Creates Config.toml in current directory
cp examples/Config.toml ./Config.toml # Copy template MyTheme.toml       # Creates custom-named config file
cp examples/Config.toml ./Config.toml # Copy template ~/.config/claude-code-statusline/Config.toml  # XDG location
```

### Configuration Testing & Validation

```bash
# === TEST CONFIGURATIONS ===
./statusline.sh # Configuration is automatically loaded                        # Test current configuration
./statusline.sh # Configuration is automatically loaded MyTheme.toml           # Test specific config file
./statusline.sh # Configuration is automatically loaded-verbose                # Detailed testing output
./statusline.sh                                      # Configuration validation happens automatically

# === CONFIGURATION COMPARISON ===
# Configuration values are shown in debug mode: STATUSLINE_DEBUG=true ./statusline.sh                     # Compare inline vs TOML settings
```

### Live Configuration Management

```bash
# === LIVE RELOAD & MANAGEMENT ===
./statusline.sh                                      # Configuration automatically reloaded
# Configuration is automatically discovered and loaded on each run
# Edit your TOML file and the changes will be applied immediately

# === CONFIGURATION BACKUP & RESTORE ===
cp Config.toml backup-dir/Config.toml.backup         # Backup current configuration
cp backup-dir/Config.toml.backup Config.toml         # Restore from backup
```

### Help System

```bash
# === HELP & DOCUMENTATION ===
./statusline.sh --help                               # Complete help documentation
./statusline.sh --help                               # General help information
```

---

## 🌍 **Environment Variable Overrides**

Override **any** TOML setting with environment variables using the `ENV_CONFIG_*` prefix:

### Theme Overrides

```bash
# === THEME CHANGES ===
ENV_CONFIG_THEME=garden ./statusline.sh              # Use garden theme temporarily
ENV_CONFIG_THEME=classic ./statusline.sh             # Use classic theme temporarily
ENV_CONFIG_THEME=catppuccin ./statusline.sh          # Use catppuccin theme temporarily
```

### Feature Toggles

```bash
# === FEATURE OVERRIDES ===
ENV_CONFIG_SHOW_MCP_STATUS=false ./statusline.sh     # Disable MCP status display
ENV_CONFIG_SHOW_COST_TRACKING=false ./statusline.sh  # Disable cost tracking
ENV_CONFIG_SHOW_VERSION=false ./statusline.sh        # Hide version information
```

### Modular Display Overrides (v2.7.0)

```bash
# === ATOMIC COMPONENT OVERRIDES ===
ENV_CONFIG_DISPLAY_LINES=3 ./statusline.sh           # Show only 3 lines
ENV_CONFIG_LINE1_COMPONENTS="repo_info,commits" ./statusline.sh              # Custom line 1
ENV_CONFIG_LINE2_COMPONENTS="cost_monthly,cost_weekly,cost_daily" ./statusline.sh  # Atomic costs on line 2
ENV_CONFIG_LINE4_COMPONENTS="mcp_status" ./statusline.sh         # MCP status on line 4

# === ATOMIC COMPONENT TOGGLES ===
ENV_CONFIG_COMPONENTS_COMMITS_ENABLED=false ./statusline.sh      # Hide commit count
ENV_CONFIG_COMPONENTS_SUBMODULES_ENABLED=false ./statusline.sh   # Hide submodules
ENV_CONFIG_COMPONENTS_COST_WEEKLY_ENABLED=false ./statusline.sh  # Hide 7-day costs
ENV_CONFIG_COMPONENTS_COST_MONTHLY_ENABLED=false ./statusline.sh # Hide 30-day costs
```

### Performance Tuning

```bash
# === TIMEOUT OVERRIDES ===
ENV_CONFIG_MCP_TIMEOUT=10s ./statusline.sh           # Increase MCP timeout to 10 seconds
ENV_CONFIG_CCUSAGE_TIMEOUT=1s ./statusline.sh        # Reduce ccusage timeout to 1 second
ENV_CONFIG_VERSION_TIMEOUT=5s ./statusline.sh        # Increase version timeout to 5 seconds
```

### Color Customization

```bash
# === CUSTOM COLOR OVERRIDES ===
ENV_CONFIG_RED="\\033[38;2;255;0;0m" ./statusline.sh # Custom red color (RGB)
ENV_CONFIG_BLUE="\\033[94m" ./statusline.sh          # Custom blue color (ANSI bright)
ENV_CONFIG_GREEN="\\033[38;5;46m" ./statusline.sh    # Custom green color (256-color)
```

### Multi-Variable Configuration

```bash
# === COMPLEX ENVIRONMENT CONFIGURATION ===
ENV_CONFIG_THEME=classic \
ENV_CONFIG_SHOW_COST_TRACKING=false \
ENV_CONFIG_SHOW_RESET_INFO=false \
ENV_CONFIG_MCP_TIMEOUT=1s \
./statusline.sh
```

---

## 🎛️ **Configuration Examples**

### Minimal Performance Configuration (Atomic Components)

```toml
# === MINIMAL ATOMIC CONFIG (FAST) ===
[theme]
name = "classic"

[display]
lines = 2                                             # Just 2 lines

[display.line1]
components = ["repo_info", "commits"]                 # Minimal line 1
separator = " │ "

[display.line2]
components = ["model_info", "time_display"]           # Minimal line 2
separator = " │ "

[components]
commits.enabled = true                                # Only commit count
submodules.enabled = false                            # No submodules
version_info.enabled = false                          # No version
mcp_status.enabled = false                            # No MCP status
cost_monthly.enabled = false                          # No cost tracking
cost_weekly.enabled = false
cost_daily.enabled = false
cost_live.enabled = false
reset_timer.enabled = false

[timeouts]
mcp = "1s"
version = "1s" 
ccusage = "1s"

[labels]
commits = "C:"
repo = "R"
```

### Developer Full-Featured Configuration (Atomic Components)

```toml
# === DEVELOPER ATOMIC CONFIG (FULL FEATURES) ===
[theme]
name = "catppuccin"

[display]
lines = 7                                             # Comprehensive 7-line layout

[display.line1]
components = ["repo_info", "commits", "submodules", "version_info"]
separator = " │ "

[display.line2]
components = ["model_info", "cost_session", "time_display"]
separator = " │ "

[display.line3]
components = ["cost_monthly", "cost_weekly", "cost_daily"]  # Atomic cost breakdown
separator = " │ "

[display.line4]
components = ["cost_live", "mcp_status"]
separator = " │ "

[display.line5]
components = ["reset_timer"]
show_when_empty = false

[display.line6]
components = ["prayer_times"]

[display.line7]
components = ["time_display"]                         # Precision time on separate line
separator = ""

[components]
# All atomic components enabled for maximum information
commits.enabled = true
submodules.enabled = true
cost_monthly.enabled = true
cost_weekly.enabled = true
cost_daily.enabled = true
version_info.enabled = true
mcp_status.enabled = true
reset_timer.enabled = true

[timeouts]
mcp = "5s"
version = "3s"
ccusage = "5s"

[display]
time_format = "%H:%M:%S"        # Include seconds for precision

[labels]
commits = "Today's Commits:"
mcp = "MCP Servers"
repo = "Repository Cost"
version_prefix = "version"
monthly = "MONTHLY"
weekly = "WEEKLY"
daily = "TODAY"
```

### Work Profile Configuration

```toml
# === WORK PROFILE ===
[theme]
name = "classic"

[features]
show_commits = true
show_version = true
show_mcp_status = true
show_cost_tracking = true       # Important for work billing
show_reset_info = true
show_session_info = false

[timeouts]
mcp = "3s"
version = "2s"
ccusage = "3s"

[labels]
commits = "Commits:"
repo = "PROJECT"
monthly = "MONTH"
weekly = "WEEK"
daily = "TODAY"
```

### Personal/Hobby Configuration

```toml
# === PERSONAL PROFILE ===
[theme]
name = "garden"

[features]
show_commits = true
show_version = false
show_mcp_status = false
show_cost_tracking = false      # Don't show costs for personal projects
show_reset_info = false

[timeouts]
mcp = "2s"
version = "1s"
ccusage = "1s"

[emojis]
clean_status = "🌿"
dirty_status = "🌱"
sonnet = "🎭"
haiku = "🦋"

[labels]
commits = "Today:"
```

---

## 🔬 **Advanced Configuration Features**

### Configuration Profiles (Future Feature)

```toml
# === PROFILE SYSTEM ===
[profiles]
enabled = true
default_profile = "default"

[profiles.work]
theme = "classic"
show_cost_tracking = true

[profiles.personal]
theme = "catppuccin"
show_cost_tracking = false

# Conditional profile switching
[conditional.work_hours]
enabled = true
start_time = "09:00"
end_time = "17:00"
work_profile = "work"
off_hours_profile = "personal"
```

### Theme Inheritance (Future Feature)

```toml
# === THEME INHERITANCE ===
[theme]
name = "custom"

[theme.inheritance]
enabled = true
base_theme = "catppuccin"       # Inherit from catppuccin
override_colors = ["red", "blue"]  # Only override specific colors

[colors.basic]
red = "\\033[38;2;255;100;100m"    # Custom red (inherits other colors from catppuccin)
blue = "\\033[38;2;100;100;255m"   # Custom blue
```

### Platform-Specific Configuration

```toml
# === PLATFORM SETTINGS ===
[platform]
prefer_gtimeout = true          # Use gtimeout over timeout on macOS
use_gdate = false               # Use gdate for GNU date compatibility
color_support_level = "full"    # "basic", "256", "full" (RGB)

[paths]
temp_dir = "/tmp"
config_dir = "~/.config/claude-code-statusline"
cache_dir = "~/.cache/claude-code-statusline"
log_file = "~/.cache/claude-code-statusline/statusline.log"
```

### Performance Optimization

```toml
# === PERFORMANCE TUNING ===
[performance]
parallel_data_collection = true
max_concurrent_operations = 3
git_operation_timeout = "5s"
network_operation_timeout = "10s"
enable_smart_caching = true
cache_compression = false

[debug]
log_level = "error"             # "debug", "info", "warn", "error", "none"
log_config_loading = false
benchmark_performance = false
```

---

## 🔄 **Migration from Inline Configuration**

Your **existing inline configuration continues to work** with zero changes required! When you're ready to migrate:

### Step 1: Generate TOML from Inline Settings

```bash
# Generate Config.toml based on your current inline configuration
cp examples/Config.toml ./Config.toml # Copy template

# This creates Config.toml with all your current settings
```

### Step 2: Compare Configurations

```bash
# See the differences between inline and TOML settings
# Configuration values are shown in debug mode: STATUSLINE_DEBUG=true ./statusline.sh

# Output shows:
# 📋 Current inline configuration:
#   Theme: catppuccin
#   Show commits: true
# 📋 TOML configuration:
#   Theme: catppuccin  
#   Show commits: true
```

### Step 3: Test TOML Configuration

```bash
# Test your new TOML configuration
./statusline.sh # Configuration is automatically loaded

# If tests pass, your migration is complete!
```

### Step 4: Gradual Migration Benefits

- ✅ **Immediate**: TOML configuration takes precedence automatically
- ✅ **Safe**: Inline configuration remains as fallback
- ✅ **Gradual**: Migrate settings piece by piece if desired
- ✅ **Reversible**: Delete Config.toml to revert to inline configuration

### Migration Examples

#### Before (Inline Configuration)
```bash
# In statusline.sh script:
CONFIG_THEME="catppuccin"
CONFIG_SHOW_COMMITS=true
CONFIG_MCP_TIMEOUT="3s"
```

#### After (TOML Configuration)
```toml
# In Config.toml file:
[theme]
name = "catppuccin"

[features]
show_commits = true

[timeouts]
mcp = "3s"
```

---

## 🐛 **Troubleshooting TOML Configuration**

### Configuration Not Loading

```bash
# Check configuration discovery
./statusline.sh # Configuration is automatically loaded-verbose

# Expected output shows which config file is loaded:
# Loading configuration from: ./Config.toml
# Configuration loaded successfully
```

### TOML Syntax Errors

```bash
# Validate TOML syntax
./statusline.sh # Configuration errors are reported automatically

# Common syntax issues:
# ❌ Incorrect: theme = catppuccin
# ✅ Correct:   theme = "catppuccin"

# ❌ Incorrect: show_commits = yes  
# ✅ Correct:   show_commits = true
```

### File Permission Issues

```bash
# Check file permissions
ls -la Config.toml

# Should be readable:
# -rw-r--r-- 1 user group 1234 Config.toml

# Fix permissions if needed:
chmod 644 Config.toml
```

### Environment Override Issues

```bash
# Test environment overrides
ENV_CONFIG_THEME=garden ./statusline.sh # Configuration is automatically loaded

# Check if override is working:
# Environment variable overrides applied
```

### Configuration Comparison

```bash
# Compare inline vs TOML to find discrepancies
# Configuration values are shown in debug mode: STATUSLINE_DEBUG=true ./statusline.sh

# Shows exact differences between configurations
```

---

## 📊 **Color System Reference**

### ANSI Standard Colors (Most Compatible)

```toml
[colors.basic]
red = "\\033[31m"        # Basic red (30-37)
red = "\\033[91m"        # Bright red (90-97)
```

### 256-Color Palette

```toml
[colors.extended]
red = "\\033[38;5;196m"      # Color 196 (bright red)
blue = "\\033[38;5;21m"      # Color 21 (bright blue)
green = "\\033[38;5;46m"     # Color 46 (bright green)
```

### RGB True Color (Modern Terminals)

```toml
[colors.extended]
red = "\\033[38;2;255;0;0m"      # Pure red RGB(255,0,0)
blue = "\\033[38;2;0;0;255m"     # Pure blue RGB(0,0,255)
purple = "\\033[38;2;128;0;128m" # Custom purple RGB(128,0,128)
```

### Background Colors

```toml
[colors.backgrounds]
red_bg = "\\033[48;5;196m"           # Red background (256-color)
blue_bg = "\\033[48;2;0;0;255m"      # Blue background (RGB)
```

---

## 💡 **Configuration Best Practices**

### 1. Start Simple
```toml
# Begin with minimal configuration
[theme]
name = "catppuccin"

[features]  
show_commits = true
show_cost_tracking = true
```

### 2. Test Incrementally
```bash
# Test each change
./statusline.sh # Configuration is automatically loaded
```

### 3. Use Environment Overrides for Experimentation
```bash
# Try settings before committing to TOML
ENV_CONFIG_THEME=garden ./statusline.sh
```

### 4. Backup Working Configurations
```bash
# Backup before major changes
cp Config.toml Config.toml.backup.$(date +%Y%m%d)
```

### 5. Document Your Customizations
```toml
# Add comments to your Config.toml
[theme]
name = "custom"  # Using ocean theme for blue color palette

[colors.basic]
blue = "\\033[38;2;0;119;190m"  # Deep ocean blue for directory paths
```

---

## 📚 **Related Documentation**

- 🎨 **[Themes Guide](themes.md)** - Complete theme customization with TOML
- 📦 **[Installation Guide](installation.md)** - Platform-specific setup with TOML
- 🚀 **[Migration Guide](migration.md)** - Detailed migration from inline configuration
- 🔧 **[CLI Reference](cli-reference.md)** - Complete command-line interface documentation  
- 🐛 **[Troubleshooting](troubleshooting.md)** - Common issues and TOML-specific solutions

---

**MashaAllah!** Your statusline is now powered by enterprise-grade TOML configuration. Enjoy the structured, validated, and powerful configuration system! 🚀