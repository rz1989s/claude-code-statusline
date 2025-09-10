# 📚 Single Source Configuration - Examples Directory

**Revolutionary single source configuration system - ONE comprehensive Config.toml with all 227 settings!**

No more confusion from 13 different example files. Edit ONE comprehensive Config.toml with all settings pre-filled. Bismillah!

> 🎯 **Configuration Revolution (v2.8.1)**: Gone are the days of hunting for parameter names across multiple files. The configuration system has been completely simplified and is **100% operational** - ONE Config.toml file contains all 227 settings that users need.

## 🚀 **Ultra-Simple Configuration**

### Your ONE Comprehensive Config.toml

**All 227 settings in ONE place - just edit values!**

```bash
# Edit your comprehensive configuration file (auto-created during installation)
nano ~/.claude/statusline/Config.toml

# OR use your favorite editor
code ~/.claude/statusline/Config.toml
vim ~/.claude/statusline/Config.toml
```

### 📁 **Directory Structure (v2.8.1)**

```
examples/
├── Config.toml                         # 🎯 THE comprehensive configuration template (227 settings)
├── README.md                           # This documentation
└── 📸 screenshots/                     # Visual previews of different layouts
    └── (layout screenshots)
```

**🎯 Revolutionary Simplification:**
- ❌ **Before**: 13 different config files to choose from (confusing!)
- ✅ **After**: ONE comprehensive Config.toml with ALL settings (clear!)

---

## 🎯 **Configuration Benefits (v2.8.1)**

### ✅ Single Source Advantages

- **🎯 No More Hunting** - All 227 settings in ONE file, just edit values
- **📋 Pre-filled Parameters** - All parameter names already included with sensible defaults
- **🧹 Zero Confusion** - No need to choose from 13 different example files
- **🔧 Complete Control** - Edit display lines, components, themes, labels - everything
- **⚡ User-Friendly** - Open one file, see all options, edit what you need
- **🔄 Maintainable** - Single source of truth eliminates redundancy

### 🎨 Comprehensive Configuration Sections

Your **ONE Config.toml** includes all these sections:

```toml
# === THEME CONFIGURATION ===
theme.name = "catppuccin"  # classic, garden, catppuccin, custom

# === MODULAR DISPLAY CONFIGURATION ===
display.lines = 5                      # Number of lines (1-9)
display.line1.components = ["repo_info", "git_stats", "version_info", "time_display"]
display.line1.separator = " │ "
display.line1.show_when_empty = true

# === FEATURE TOGGLES ===
features.show_commits = true
features.show_version = true
features.show_mcp_status = true
features.show_cost_tracking = true

# === DISPLAY LABELS ===
labels.commits = "Commits:"
labels.repo = "REPO"
labels.monthly = "30DAY"
# ... ALL labels included!

# === TIMEOUTS & PERFORMANCE ===
timeouts.mcp = "10s"
timeouts.version = "10s"
timeouts.ccusage = "10s"

# === CACHE SETTINGS ===
cache.isolation.mode = "repository"
# ... ALL cache settings included!

# === PRAYER TIMES CONFIGURATION ===
prayer.enabled = true
prayer.location_mode = "auto"
# ... COMPLETE prayer system configuration!

# Plus 200+ more settings - ALL in ONE file!
```

---

## 🧩 **Layout Configuration Examples**

Edit your Config.toml to create any layout you want:

### Ultra-Minimal (1-line)
```toml
display.lines = 1
display.line1.components = ["repo_info", "model_info"]
```

### Essential Compact (3-line)
```toml
display.lines = 3
display.line1.components = ["repo_info", "commits", "version_info"]
display.line2.components = ["model_info", "cost_session", "cost_live"]
display.line3.components = ["mcp_status"]
```

### Standard Familiar (5-line) - Default
```toml
display.lines = 5
display.line1.components = ["repo_info", "git_stats", "version_info", "time_display"]
display.line2.components = ["model_info", "cost_session", "cost_period", "cost_live"]
display.line3.components = ["prayer_times"]
display.line4.components = ["mcp_status"]
display.line5.components = ["reset_timer"]
```

### Atomic Components (separate git data)
```toml
display.line1.components = ["repo_info", "commits", "submodules", "version_info"]
display.line2.components = ["model_info", "cost_monthly", "cost_weekly", "cost_daily"]
```

### Maximum Ultimate (9-line)
```toml
display.lines = 9
display.line1.components = ["prayer_times"]
display.line2.components = ["repo_info"]
display.line3.components = ["commits", "submodules"]
display.line4.components = ["model_info", "version_info"]
display.line5.components = ["cost_session", "cost_live"]
display.line6.components = ["cost_monthly", "cost_weekly", "cost_daily"]
display.line7.components = ["mcp_status"]
display.line8.components = ["reset_timer"]
display.line9.components = ["time_display"]
```

---

## ⚡ **Quick Testing with Environment Variables**

Test any layout instantly without editing your Config.toml:

```bash
# Test different line counts
ENV_CONFIG_DISPLAY_LINES=1 ./statusline.sh   # Ultra-minimal
ENV_CONFIG_DISPLAY_LINES=3 ./statusline.sh   # Compact
ENV_CONFIG_DISPLAY_LINES=5 ./statusline.sh   # Standard
ENV_CONFIG_DISPLAY_LINES=9 ./statusline.sh   # Maximum

# Test custom component arrangements
ENV_CONFIG_LINE1_COMPONENTS="repo_info,commits,version_info" ./statusline.sh

# Test different themes
ENV_CONFIG_THEME_NAME=garden ./statusline.sh
ENV_CONFIG_THEME_NAME=classic ./statusline.sh

# Test atomic vs legacy components
ENV_CONFIG_LINE1_COMPONENTS="git_stats" ./statusline.sh           # Legacy combined
ENV_CONFIG_LINE1_COMPONENTS="commits,submodules" ./statusline.sh  # Atomic separated
```

---

## 🧩 **Available Components**

Your Config.toml can use any of these 16 components:

### Core Components (11)
- `repo_info` - Repository directory and git status
- `version_info` - Claude Code version display
- `time_display` - Current time formatting
- `model_info` - Claude model name with emoji
- `cost_session` - Repository session cost tracking
- `cost_live` - Live block cost monitoring
- `mcp_status` - MCP server health and connection status
- `reset_timer` - Block reset countdown timer
- `prayer_times` - Islamic prayer times integration

### Legacy Components (2) - Backward Compatibility
- `git_stats` - Combined commits + submodules (legacy)
- `cost_period` - Combined 30day/7day/daily costs (legacy)

### Atomic Components (5) - NEW v2.7.0
- `commits` - Shows ONLY commit count (atomic from git_stats)
- `submodules` - Shows ONLY submodule status (atomic from git_stats)
- `cost_monthly` - Shows ONLY 30-day costs (atomic from cost_period)
- `cost_weekly` - Shows ONLY 7-day costs (atomic from cost_period)
- `cost_daily` - Shows ONLY daily costs (atomic from cost_period)

---

## 🎨 **Theme Options**

Edit `theme.name` in your Config.toml:

```toml
theme.name = "catppuccin"  # Modern dark theme (default)
theme.name = "garden"      # Soft pastel colors
theme.name = "classic"     # Traditional ANSI colors
theme.name = "custom"      # Use custom colors you define
```

For custom themes, all color settings are included in your Config.toml:
```toml
colors.basic.red = "\\033[31m"
colors.basic.blue = "\\033[34m"
# ... all custom colors included!
```

---

## 🔧 **Configuration Management**

### Edit Your Configuration
```bash
# Open your comprehensive Config.toml
nano ~/.claude/statusline/Config.toml
code ~/.claude/statusline/Config.toml
vim ~/.claude/statusline/Config.toml
```

### Validate Configuration
```bash
# Test your configuration
./statusline.sh

# Debug configuration loading
STATUSLINE_DEBUG=true ./statusline.sh
```

### Backup Your Configuration
```bash
# Backup your customized Config.toml
cp ~/.claude/statusline/Config.toml ~/my-statusline-config-backup.toml

# Restore from backup
cp ~/my-statusline-config-backup.toml ~/.claude/statusline/Config.toml
```

---

## 🐛 **Troubleshooting**

### Configuration Not Loading
```bash
# Check if Config.toml exists
ls -la ~/.claude/statusline/Config.toml

# Regenerate Config.toml if missing/corrupted (auto-happens during load)
./statusline.sh  # Will auto-regenerate if needed

# Debug configuration parsing
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep -i config
```

### Component Not Displaying
```bash
# Test specific component
ENV_CONFIG_LINE1_COMPONENTS="repo_info" ./statusline.sh

# Check component availability
./statusline.sh --modules

# Debug component loading
STATUSLINE_DEBUG=true ./statusline.sh --modules
```

---

## 💡 **Best Practices**

1. **Start with Defaults** - The installed Config.toml has sensible defaults, just edit what you need
2. **Test with Environment Variables** - Use `ENV_CONFIG_*` to test changes before editing Config.toml
3. **One Change at a Time** - Edit one setting, test, repeat
4. **Use Comments** - Add `# comments` in your Config.toml to document your changes
5. **Backup Working Configs** - Save your working Config.toml before major changes
6. **Check Component Status** - Use `./statusline.sh --modules` to verify component availability

---

## 📚 **Related Documentation**

- ⚙️ **[Configuration Guide](../docs/configuration.md)** - Complete configuration reference
- 🎨 **[Themes Guide](../docs/themes.md)** - Theme customization
- 📦 **[Installation Guide](../docs/installation.md)** - Setup and installation
- 🔧 **[CLI Reference](../docs/cli-reference.md)** - Command line options

---

**Alhamdulillah!** The single source configuration system makes customization incredibly simple - ONE file with ALL settings. Edit what you need, keep what works! 🌟