# ⚙️ TOML Configuration Guide

**Complete guide to configuring your Claude Code Enhanced Statusline with the modern TOML configuration system.**

Transform your terminal with enterprise-grade configuration management - structured, validated, and powerful, with full backwards compatibility.

## 🚀 **Getting Started**

### Quick Start with TOML

```bash
# 1. Generate your Config.toml
./statusline.sh --generate-config

# 2. Customize it
vim Config.toml

# 3. Test it
./statusline.sh --test-config

# 4. Use it!
./statusline.sh
```

The statusline automatically discovers and loads your TOML configuration - no additional setup required!

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
./statusline.sh --generate-config        # Creates ./Config.toml
./statusline.sh                          # Uses ./Config.toml

# User-wide configuration
./statusline.sh --generate-config ~/.config/claude-code-statusline/Config.toml
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
[theme]
# Available themes: "classic", "garden", "catppuccin", "custom"
name = "catppuccin"

# === CORE FEATURE TOGGLES ===
[features]
show_commits = true          # Show today's commit count
show_version = true          # Display Claude Code version
show_submodules = true       # Show git submodule count
show_mcp_status = true       # MCP server health monitoring
show_cost_tracking = true    # Financial cost tracking (ccusage)
show_reset_info = true       # Block reset countdown
show_session_info = true     # Session information

# === MODEL EMOJIS ===
[emojis]
opus = "🧠"                  # Claude Opus
haiku = "⚡"                 # Claude Haiku
sonnet = "🎵"                # Claude Sonnet
default_model = "🤖"         # Other models
clean_status = "✅"          # Clean git repository
dirty_status = "📁"          # Dirty git repository
clock = "🕐"                 # Time display
live_block = "🔥"            # Active billing block

# === TIMEOUTS ===
[timeouts]
mcp = "3s"                   # MCP server status check timeout
version = "2s"               # Claude Code version check timeout
ccusage = "3s"               # Cost tracking API timeout

# === DISPLAY LABELS ===
[labels]
commits = "Commits:"         # Commit count label
repo = "REPO"                # Repository cost label
monthly = "30DAY"            # Monthly cost label
weekly = "7DAY"              # Weekly cost label
daily = "DAY"                # Daily cost label
mcp = "MCP"                  # MCP server label
version_prefix = "ver"       # Version prefix
submodule = "SUB:"           # Submodule label
session_prefix = "S:"        # Session prefix
live = "LIVE"                # Live cost label
reset = "RESET"              # Reset timer label

# === CACHE SETTINGS ===
[cache]
version_duration = 3600      # Cache Claude version for 1 hour
version_file = "/tmp/.claude_version_cache"  # Version cache file location

# === DISPLAY FORMATS ===
[display]
time_format = "%H:%M"        # 24-hour format (14:30)
date_format = "%Y-%m-%d"     # ISO format (2024-08-18)
date_format_compact = "%Y%m%d"  # Compact format (20240818)

# === ERROR/FALLBACK MESSAGES ===
[messages]
no_ccusage = "No ccusage"
ccusage_install = "Install ccusage for cost tracking"
no_active_block = "No active block"
mcp_unknown = "unknown"
mcp_none = "none"
unknown_version = "?"
no_submodules = "--"
```

---

## 🎨 **Theme Configuration**

### Pre-built Themes

```toml
# === CLASSIC THEME ===
[theme]
name = "classic"        # Traditional ANSI terminal colors

# === GARDEN THEME ===
[theme]
name = "garden"         # Soft pastel colors for gentle aesthetic

# === CATPPUCCIN THEME ===
[theme]
name = "catppuccin"     # Popular catppuccin mocha theme colors
```

### Custom Theme Configuration

```toml
# === CUSTOM THEME ===
[theme]
name = "custom"

# Basic ANSI colors (most compatible)
[colors.basic]
red = "\\033[31m"       # Used for: mode info, alerts
blue = "\\033[34m"      # Used for: directory path, information
green = "\\033[32m"     # Used for: clean git status, success
yellow = "\\033[33m"    # Used for: dirty git status, warnings
magenta = "\\033[35m"   # Used for: git branch, highlights
cyan = "\\033[36m"      # Used for: model name, secondary info
white = "\\033[37m"     # Used for: general text

# Extended colors (256-color and RGB)
[colors.extended]
orange = "\\033[38;5;208m"       # Used for: time display
light_orange = "\\033[38;5;215m" # Used for: clock emoji
light_gray = "\\033[38;5;248m"   # Used for: reset info
bright_green = "\\033[92m"       # Used for: MCP servers, submodules
purple = "\\033[95m"             # Used for: Claude version
teal = "\\033[38;5;73m"          # Used for: commits, daily costs
gold = "\\033[38;5;220m"         # Used for: special highlights
pink_bright = "\\033[38;5;205m"  # Used for: 30-day costs
indigo = "\\033[38;5;105m"       # Used for: 7-day costs
violet = "\\033[38;5;99m"        # Used for: session info
light_blue = "\\033[38;5;111m"   # Used for: MCP server names

# Text formatting
[colors.formatting]
dim = "\\033[2m"           # Used for: separators, dimmed text
italic = "\\033[3m"        # Used for: reset info
strikethrough = "\\033[9m" # Used for: offline MCP servers
reset = "\\033[0m"         # Used for: reset all formatting
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
[theme]
name = "custom"

[colors.basic]
red = "\\033[38;2;255;0;102m"      # Electric pink
blue = "\\033[38;2;0;255;255m"     # Neon cyan
green = "\\033[38;2;0;255;0m"      # Matrix green
yellow = "\\033[38;2;255;255;0m"   # Electric yellow
magenta = "\\033[38;2;255;0;255m"  # Neon magenta
cyan = "\\033[38;2;0;255;255m"     # Bright cyan
white = "\\033[38;2;255;255;255m"  # Bright white
```

---

## 🔧 **Rich CLI Interface**

### Configuration Generation

```bash
# === GENERATE CONFIG FILES ===
./statusline.sh --generate-config                    # Creates Config.toml in current directory
./statusline.sh --generate-config MyTheme.toml       # Creates custom-named config file
./statusline.sh --generate-config ~/.config/claude-code-statusline/Config.toml  # XDG location
```

### Configuration Testing & Validation

```bash
# === TEST CONFIGURATIONS ===
./statusline.sh --test-config                        # Test current configuration
./statusline.sh --test-config MyTheme.toml           # Test specific config file
./statusline.sh --test-config-verbose                # Detailed testing output
./statusline.sh --validate-config                    # Validate configuration syntax

# === CONFIGURATION COMPARISON ===
./statusline.sh --compare-config                     # Compare inline vs TOML settings
```

### Live Configuration Management

```bash
# === LIVE RELOAD & MANAGEMENT ===
./statusline.sh --reload-config                      # Reload configuration now
./statusline.sh --reload-interactive                 # Interactive config management menu
./statusline.sh --watch-config 3                     # Watch for changes every 3 seconds

# === CONFIGURATION BACKUP & RESTORE ===
./statusline.sh --backup-config backup-dir/          # Backup current configuration
./statusline.sh --restore-config backup-dir/         # Restore from backup directory
```

### Help System

```bash
# === HELP & DOCUMENTATION ===
./statusline.sh --help                               # Complete help documentation
./statusline.sh --help config                        # Configuration-specific help
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

### Minimal Performance Configuration

```toml
# === MINIMAL CONFIG (FAST) ===
[theme]
name = "classic"

[features]
show_commits = true
show_version = false
show_submodules = false
show_mcp_status = false
show_cost_tracking = false
show_reset_info = false

[timeouts]
mcp = "1s"
version = "1s"
ccusage = "1s"

[labels]
commits = "C:"
repo = "R"
```

### Developer Full-Featured Configuration

```toml
# === DEVELOPER CONFIG (FULL FEATURES) ===
[theme]
name = "catppuccin"

[features]
show_commits = true
show_version = true
show_submodules = true
show_mcp_status = true
show_cost_tracking = true
show_reset_info = true
show_session_info = true

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
./statusline.sh --generate-config

# This creates Config.toml with all your current settings
```

### Step 2: Compare Configurations

```bash
# See the differences between inline and TOML settings
./statusline.sh --compare-config

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
./statusline.sh --test-config

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
./statusline.sh --test-config-verbose

# Expected output shows which config file is loaded:
# Loading configuration from: ./Config.toml
# Configuration loaded successfully
```

### TOML Syntax Errors

```bash
# Validate TOML syntax
./statusline.sh --validate-config

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
ENV_CONFIG_THEME=garden ./statusline.sh --test-config

# Check if override is working:
# Environment variable overrides applied
```

### Configuration Comparison

```bash
# Compare inline vs TOML to find discrepancies
./statusline.sh --compare-config

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
./statusline.sh --test-config
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