<div align="center">

<pre>
███████╗███╗   ██╗██╗  ██╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗ 
██╔════╝████╗  ██║██║  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗
█████╗  ██╔██╗ ██║███████║███████║██╔██╗ ██║██║     █████╗  ██║  ██║
██╔══╝  ██║╚██╗██║██╔══██║██╔══██║██║╚██╗██║██║     ██╔══╝  ██║  ██║
███████╗██║ ╚████║██║  ██║██║  ██║██║ ╚████║╚██████╗███████╗██████╔╝
╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═════╝ 

███████╗████████╗ █████╗ ████████╗██╗   ██╗███████╗██╗     ██╗███╗   ██╗███████╗
██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██╔════╝██║     ██║████╗  ██║██╔════╝
███████╗   ██║   ███████║   ██║   ██║   ██║███████╗██║     ██║██╔██╗ ██║█████╗  
╚════██║   ██║   ██╔══██║   ██║   ██║   ██║╚════██║██║     ██║██║╚██╗██║██╔══╝  
███████║   ██║   ██║  ██║   ██║   ╚██████╔╝███████║███████╗██║██║ ╚████║███████╗
╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
</pre>

# Claude Code Enhanced Statusline

**🎨 Transform your terminal with a beautiful 4-line statusline experience**  
*Rich information display • Stunning themes • Real-time monitoring • MCP integration*

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform Support](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20WSL-green.svg)](#-system-requirements)
[![Shell](https://img.shields.io/badge/Shell-Bash-lightgrey.svg)]()
[![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-9333EA.svg)](https://claude.ai/code)
[![GitHub stars](https://img.shields.io/github/stars/rz1989s/claude-code-statusline?style=social)](https://github.com/rz1989s/claude-code-statusline/stargazers)

![Hero Screenshot](assets/screenshots/catppuccin-mocha-theme.png)

</div>

## 📚 Table of Contents

- [Recent Updates](#-recent-updates)
- [Features](#-features)
- [Theme Gallery](#-theme-gallery)
- [Screenshot Showcase](#-screenshot-showcase)
- [Quick Start](#-quick-start)
- [Configuration](#️-configuration)
- [What Each Line Shows](#-what-each-line-shows)
- [System Requirements](#-system-requirements)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
  - [Development Setup](#-development-setup)
  - [Testing](#testing-information)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

---

## 🆕 Recent Updates

### v2.0 - Enterprise TOML Configuration System 🚀

- **📋 TOML Configuration Files** - Modern, structured configuration with `Config.toml`
- **🔧 Rich CLI Interface** - Generate, test, validate, and manage configurations
- **📁 Multi-location Discovery** - `./Config.toml` → `~/.config/claude-code-statusline/` → `~/.claude-statusline.toml`
- **🌐 Environment Overrides** - `ENV_CONFIG_*` variables override all settings
- **🔄 Live Reload** - Hot configuration reloading with `--watch-config`
- **🎨 Theme System** - Built-in themes with full custom color support
- **✅ Configuration Validation** - Built-in testing and error checking with auto-fix suggestions
- **📦 Migration Tools** - Seamless migration from inline configuration
- **⚡ 100% Backwards Compatible** - Existing inline configuration continues to work

### v1.0 - Enhanced Statusline Foundation

- **🎨 Three Stunning Themes** - Classic, Garden (pastels), and Catppuccin Mocha
- **💰 Real-time Cost Tracking** - Complete integration with [ccusage](https://ccusage.com)
- **🔌 MCP Server Monitoring** - Live status of Model Context Protocol servers
- **⏰ Block Reset Timer** - Track your 5-hour conversation blocks with countdown
- **📊 Git Integration** - Repository status, commit counting, and branch information
- **⚡ Performance Optimized** - Smart caching and configurable timeouts

---

## ✨ Features

### 🎨 **Stunning Visual Interface**

Experience three beautifully crafted themes that transform your terminal into a work of art:

- **🌙 Catppuccin Mocha** - Rich, warm colors with excellent contrast
- **🌿 Garden Theme** - Soft pastels for a gentle, soothing aesthetic  
- **⚡ Classic Theme** - Traditional terminal colors with modern polish
- **🎨 Custom Themes** - Full RGB/256-color/ANSI color customization

### 📊 **4-Line Information Display**

![Repository Information](assets/screenshots/basic-repo-info.png)

**Line 1: Repository Overview**
- Working directory with elegant `~` notation
- Git branch with clean/dirty status indicators
- Today's commit count tracking
- Claude Code version (intelligently cached)
- Git submodule count
- Current time display

![Cost Tracking Integration](assets/screenshots/ccusage-info.png)

**Line 2: Cost Tracking & Model Info**
- Current Claude model with emoji indicators
- Repository session costs
- 30-day, 7-day, and daily spending totals
- Live billing block costs with [ccusage](https://ccusage.com) integration
- Real-time financial monitoring

![MCP Server Monitoring](assets/screenshots/mcp-info.png)

**Line 3: MCP Server Health**
- Connected vs total server count
- Server names with connection status
- Color-coded indicators (🟢 connected, 🔴 disconnected)
- Real-time health monitoring

**Line 4: Block Reset Timer** *(when billing block is active)*
- Next reset time display
- Countdown to block expiration
- Smart detection and tracking

### ⚡ **Smart Performance & Monitoring**

- **🚀 Intelligent Caching** - Reduces API calls and improves responsiveness
- **🔄 Sequential API Execution** - Prevents rate limiting with intelligent request sequencing
- **📦 30-Second Smart Caching** - Reduces API calls with file locking mechanism
- **🔒 Stale Lock Detection** - Automatic cleanup of dead processes and locks
- **⏱️ Configurable Timeouts** - Prevents hanging on slow networks  
- **📊 Real-time Updates** - Live cost and status monitoring
- **🌍 Cross-Platform** - Works seamlessly on macOS, Linux, and WSL
- **💾 Memory Efficient** - Minimal resource usage with maximum information

### 🔧 **Enterprise-Grade Configuration**

- **📋 TOML Configuration System** - Modern structured configuration files
- **🔧 Rich CLI Tools** - Generate, test, validate, and manage configurations
- **🎛️ Feature Toggles** - Enable/disable any display section via TOML
- **🌐 Environment Overrides** - `ENV_CONFIG_*` variables for dynamic settings
- **🎨 Advanced Theme System** - Theme inheritance, profiles, and custom color schemes
- **🔄 Live Configuration Reload** - Hot reload with file watching capabilities
- **⏲️ Timeout Controls** - Fine-tune network timeout settings
- **🏷️ Label Customization** - Modify all display text and formats via TOML
- **😊 Emoji Customization** - Personalize status indicators
- **✅ Configuration Validation** - Built-in testing with auto-fix suggestions

---

## 🎨 Theme Gallery

Transform your terminal aesthetic with our carefully crafted theme collection. Each theme is optimized for readability and visual appeal across different terminal environments.

### 🌙 Catppuccin Mocha Theme

Rich, warm colors inspired by the beloved [Catppuccin](https://catppuccin.com/) palette. Perfect for dark mode enthusiasts.

![Catppuccin Mocha Theme](assets/screenshots/catppuccin-mocha-theme.png)

**TOML Configuration (Recommended):**
```toml
# In your Config.toml file
[theme]
name = "catppuccin"
```

**Environment Override:**
```bash
# Temporary theme change
ENV_CONFIG_THEME=catppuccin ~/.claude/statusline/statusline.sh
```

**CLI Generation:**
```bash
# Generate Config.toml with catppuccin theme
~/.claude/statusline/statusline.sh --generate-config
# Then edit Config.toml to set theme.name = "catppuccin"
```

### 🌿 Garden Theme  

Soft, pastel colors that create a gentle and soothing terminal environment. Ideal for extended coding sessions.

![Garden Theme](assets/screenshots/garden-theme.png)

**TOML Configuration (Recommended):**
```toml
# In your Config.toml file
[theme]
name = "garden"
```

**Environment Override:**
```bash
# Temporary theme change
ENV_CONFIG_THEME=garden ~/.claude/statusline/statusline.sh
```

### ⚡ Classic Theme

Traditional terminal colors with modern polish. ANSI-compatible and universally readable.

![Classic Theme](assets/screenshots/classic-theme.png)

**TOML Configuration (Recommended):**
```toml
# In your Config.toml file
[theme]
name = "classic"
```

**Environment Override:**
```bash
# Temporary theme change
ENV_CONFIG_THEME=classic ~/.claude/statusline/statusline.sh
```

### 🎨 Custom Theme

Complete creative control with full RGB/256-color/ANSI color customization capabilities.

**TOML Configuration (Recommended):**
```toml
# In your Config.toml file
[theme]
name = "custom"

# Define your custom color palette
[colors.basic]
red = "\\033[38;2;255;182;193m"    # Soft pink
blue = "\\033[38;2;173;216;230m"   # Light blue
green = "\\033[38;2;144;238;144m"  # Light green
yellow = "\\033[38;2;255;165;0m"   # Orange
magenta = "\\033[38;2;221;160;221m" # Plum
cyan = "\\033[38;2;175;238;238m"    # Pale turquoise

[colors.extended]
orange = "\\033[38;2;255;140;0m"
light_gray = "\\033[38;2;211;211;211m"
purple = "\\033[38;2;147;112;219m"
```

**Advanced Custom Configuration:**
```bash
# Generate base config then customize
~/.claude/statusline/statusline.sh --generate-config MyTheme.toml
# Edit MyTheme.toml with your custom colors
~/.claude/statusline/statusline.sh --test-config MyTheme.toml
```

---

## 📸 Screenshot Showcase

### Git Status Monitoring

![Git Clean Status](assets/screenshots/git-info-clean.png)

Clean repository with detailed branch and status information.

---

## 🚀 Quick Start

Get your enhanced statusline running in minutes with our streamlined installation process.

### 📋 Prerequisites

Choose your platform and install the required dependencies:

<details>
<summary><strong>🍎 macOS</strong></summary>

```bash
# Install dependencies via Homebrew
brew install jq coreutils

# Install optional but recommended tools
npm install -g bunx ccusage
```
</details>

<details>
<summary><strong>🐧 Linux (Ubuntu/Debian)</strong></summary>

```bash
# Install required dependencies
sudo apt update && sudo apt install jq

# Install optional but recommended tools  
npm install -g bunx ccusage
```
</details>

<details>
<summary><strong>🪟 Windows (WSL)</strong></summary>

```bash
# Install required dependencies
sudo apt update && sudo apt install jq

# Install optional but recommended tools
npm install -g bunx ccusage
```
</details>

### 📦 Installation Methods

#### Method 1: Automated Install Script (Recommended)

```bash
# Download and run the automated installer
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

# Or download and inspect before running
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

#### Method 2: GNU Stow Integration

Perfect for dotfiles management with [GNU Stow](https://www.gnu.org/software/stow/):

```bash
# Place in your dotfiles structure
mkdir -p ~/.dotfiles/claude/.claude/statusline/
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.dotfiles/claude/.claude/statusline/statusline.sh
chmod +x ~/.dotfiles/claude/.claude/statusline/statusline.sh

# Deploy with Stow
cd ~/.dotfiles && stow claude

# Configure Claude Code (manual JSON editing)
# Add to ~/.claude/settings.json:
# "statusLine": {"type": "command", "command": "bash ~/.claude/statusline/statusline.sh"}
```

#### Method 3: Manual Installation

```bash
# Create directory if it doesn't exist
mkdir -p ~/.claude/statusline/

# Download the script
curl -O https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh
chmod +x statusline.sh
mv statusline.sh ~/.claude/statusline/

# Configure Claude Code (manual JSON editing)
# Add to ~/.claude/settings.json:
# "statusLine": {"type": "command", "command": "bash ~/.claude/statusline/statusline.sh"}
```

> 💡 **Why use the Automated Installer?** The install script automatically handles JSON configuration, dependency checking, and verification - no manual editing of settings.json required!

### ✅ Verification

Test your installation:

```bash
# Check if the statusline script is executable
ls -la ~/.claude/statusline/statusline.sh

# Verify Claude Code configuration (check settings.json)
cat ~/.claude/settings.json | jq '.statusLine'

# Test the statusline directly
~/.claude/statusline/statusline.sh --help
```

### 🎨 **Configuration Setup (TOML System)**

**Skip this step if you want to use defaults** - the statusline works immediately with beautiful built-in themes!

#### Generate Your Configuration File (Recommended)

```bash
# Navigate to your preferred location
cd ~/  # or any project directory

# Generate Config.toml with current settings
~/.claude/statusline/statusline.sh --generate-config

# Customize your configuration
vim Config.toml

# Test your new configuration  
~/.claude/statusline/statusline.sh --test-config
```

#### Quick Theme Change

```bash
# Change theme temporarily (no file needed)
ENV_CONFIG_THEME=garden ~/.claude/statusline/statusline.sh

# Or create a simple Config.toml
cat > Config.toml << 'EOF'
[theme]
name = "catppuccin"

[features]
show_commits = true
show_cost_tracking = true
EOF

# Test your theme
~/.claude/statusline/statusline.sh --test-config
```

#### Configuration Discovery

The statusline automatically finds your config file:
- **`./Config.toml`** - Project-specific (highest priority)
- **`~/.claude/statusline/Config.toml`** - Primary user config location
- **`~/.config/claude-code-statusline/Config.toml`** - XDG standard location
- **`~/.claude-statusline.toml`** - Legacy fallback

> 💡 **Pro Tip**: Start with `~/.claude/statusline/statusline.sh --generate-config` to create your base configuration, then customize from there!

### 🚀 **Ready to Use!**

Start a new Claude Code session to see your enhanced statusline in action! Your configuration will be automatically detected and applied.

---

## ⚙️ Configuration

Transform your statusline with our **enterprise-grade TOML configuration system**. Modern, structured, and powerful - with full backwards compatibility for existing inline configurations.

## 🚀 **Getting Started with TOML Configuration**

### Quick Setup (Recommended)

```bash
# 1. Generate your Config.toml file
~/.claude/statusline/statusline.sh --generate-config

# 2. Customize your Config.toml file  
vim Config.toml

# 3. Test your configuration
~/.claude/statusline/statusline.sh --test-config

# 4. Start using your enhanced statusline!
~/.claude/statusline/statusline.sh
```

### Configuration Discovery

The statusline automatically discovers your configuration in this order:

1. **`./Config.toml`** - Project-specific configuration (highest priority)
2. **`~/.claude/statusline/Config.toml`** - Primary user config location
3. **`~/.config/claude-code-statusline/Config.toml`** - XDG standard location
4. **`~/.claude-statusline.toml`** - Legacy fallback
5. **Environment variables** (`ENV_CONFIG_*`) - Override any TOML setting
6. **Inline script configuration** - Built-in defaults (backwards compatible)

## 📋 **TOML Configuration Structure**

### Core Configuration Sections

```toml
# === THEME CONFIGURATION ===
[theme]
name = "catppuccin"  # Options: classic, garden, catppuccin, custom

# === FEATURE TOGGLES ===
[features]
show_commits = true
show_version = true
show_mcp_status = true
show_cost_tracking = true

# === TIMEOUTS & PERFORMANCE ===
[timeouts]
mcp = "8s"
version = "2s" 
ccusage = "8s"

# === CUSTOMIZATION ===
[emojis]
opus = "🧠"
haiku = "⚡"
sonnet = "🎵"
clean_status = "✅"

[labels]
commits = "Commits:"
repo = "REPO"
mcp = "MCP"
```

### Advanced Custom Colors

```toml
# === CUSTOM THEME COLORS ===
[theme]
name = "custom"

[colors.basic]
red = "\\033[31m"
blue = "\\033[34m"
green = "\\033[32m"
yellow = "\\033[33m"

[colors.extended]
orange = "\\033[38;5;208m"
light_gray = "\\033[38;5;248m"
purple = "\\033[95m"
teal = "\\033[38;5;73m"
```

## 🔧 **Rich CLI Interface**

### Configuration Management Commands

```bash
# === CONFIGURATION GENERATION ===
~/.claude/statusline/statusline.sh --generate-config              # Create Config.toml from current settings
~/.claude/statusline/statusline.sh --generate-config MyTheme.toml # Generate custom config file

# === TESTING & VALIDATION ===
~/.claude/statusline/statusline.sh --test-config                  # Test current configuration
~/.claude/statusline/statusline.sh --test-config MyTheme.toml     # Test specific config file
~/.claude/statusline/statusline.sh --test-config-verbose          # Detailed testing output
~/.claude/statusline/statusline.sh --validate-config              # Validate configuration syntax

# === COMPARISON & ANALYSIS ===
~/.claude/statusline/statusline.sh --compare-config               # Compare inline vs TOML settings
```

### Live Reload & Management

```bash
# === LIVE CONFIGURATION RELOAD ===
~/.claude/statusline/statusline.sh --reload-config                # Reload configuration now
~/.claude/statusline/statusline.sh --reload-interactive           # Interactive config management menu
~/.claude/statusline/statusline.sh --watch-config 3               # Watch for changes every 3 seconds

# === MIGRATION & BACKUP ===
~/.claude/statusline/statusline.sh --backup-config backup-dir/    # Backup current configuration
~/.claude/statusline/statusline.sh --restore-config backup-dir/   # Restore from backup
```

### Help & Documentation

```bash
# === HELP SYSTEM ===
~/.claude/statusline/statusline.sh --help                         # Complete help documentation
~/.claude/statusline/statusline.sh --help config                  # Configuration-specific help

# === ADDITIONAL COMMANDS ===
~/.claude/statusline/statusline.sh                               # Run statusline with current configuration
```

> 💡 **Pro Tip**: Use environment overrides for temporary configuration changes without modifying your Config.toml file.

## 🌍 **Environment Variable Overrides**

Temporarily override any TOML setting with environment variables:

```bash
# === TEMPORARY THEME CHANGES ===
ENV_CONFIG_THEME=garden ~/.claude/statusline/statusline.sh        # Use garden theme once
ENV_CONFIG_THEME=classic ~/.claude/statusline/statusline.sh       # Use classic theme once

# === FEATURE OVERRIDES ===
ENV_CONFIG_SHOW_MCP_STATUS=false ~/.claude/statusline/statusline.sh     # Disable MCP status
ENV_CONFIG_MCP_TIMEOUT=10s ~/.claude/statusline/statusline.sh           # Increase MCP timeout

# === PERFECT FOR CI/CD & AUTOMATION ===
ENV_CONFIG_SHOW_COST_TRACKING=false \
ENV_CONFIG_SHOW_RESET_INFO=false \
ENV_CONFIG_THEME=classic \
~/.claude/statusline/statusline.sh
```

## 🎛️ **Configuration Examples**

### Minimal Configuration

```toml
# Minimal Config.toml for performance
[theme]
name = "classic"

[features]
show_commits = true
show_version = false
show_mcp_status = false
show_cost_tracking = false

[timeouts]
mcp = "1s"
ccusage = "1s"
```

### Developer Full-Featured

```toml
# Developer Config.toml with all features
[theme]
name = "catppuccin"

[features]
show_commits = true
show_version = true  
show_mcp_status = true
show_cost_tracking = true
show_reset_info = true

[timeouts]
mcp = "8s"
version = "3s"
ccusage = "8s"

[labels]
commits = "Today's Commits:"
mcp = "MCP Servers"
repo = "Repository Cost"
```

### Multiple Configuration Files

```toml
# Create different config files for different contexts
# work-config.toml - Professional setup
[theme]
name = "classic"

[features]
show_cost_tracking = true
show_reset_info = true

# personal-config.toml - Personal projects  
[theme]
name = "catppuccin"

[features]
show_cost_tracking = false
show_reset_info = false
```

> 💡 **Note**: Profile-based automatic switching is planned for a future release. Currently, use different config files for different contexts.

## 💡 **Migration from Inline Configuration**

Your existing inline configuration **continues to work unchanged**! When you're ready:

```bash
# 1. Generate TOML from your current inline settings
~/.claude/statusline/statusline.sh --generate-config

# 2. Compare to see the differences  
~/.claude/statusline/statusline.sh --compare-config

# 3. Test the new TOML configuration
~/.claude/statusline/statusline.sh --test-config

# 4. Your inline config becomes the fallback
# TOML configuration takes precedence automatically
```

## 🔗 **Documentation Links**

- 📖 **[Complete Configuration Guide](docs/configuration.md)** - Detailed TOML configuration reference
- 🎨 **[Themes Guide](docs/themes.md)** - Theme creation and customization with TOML
- 🚀 **[Migration Guide](docs/migration.md)** - Step-by-step migration from inline configuration  
- 🔧 **[CLI Reference](docs/cli-reference.md)** - Complete command-line interface documentation
- 🐛 **[Troubleshooting](docs/troubleshooting.md)** - TOML configuration troubleshooting

> ⚡ **Pro Tip**: Start with `~/.claude/statusline/statusline.sh --generate-config` to create your base Config.toml, then customize from there! Changes are validated automatically.

## 🔍 What Each Line Shows

Understand every element of your enhanced statusline with this detailed breakdown:

### 📁 **Line 1: Repository & Environment Info**

```
~/local-dev (main) ✅ │ Commits:0 │ ver2.1.45 │ SUB:— │ 🕐 08:22
```

- **📂 Directory**: Current working directory with elegant `~` notation
- **🌿 Git Branch**: Active branch name with visual status indicators
- **✅ Status**: Clean (✅) or dirty (⚠️) repository state
- **📝 Commits**: Today's commit count for productivity tracking
- **🔢 Version**: Claude Code version (intelligently cached for performance)
- **📦 Submodules**: Git submodule count (shows `—` when none)
- **🕐 Time**: Current system time for session awareness

### 💰 **Line 2: Cost Tracking & Model Info**

```
🎵 Sonnet 4 │ REPO $3.87 │ 30DAY $108.81 │ 7DAY $66.48 │ DAY $9.35 │ 🔥 LIVE $6.74
```

- **🎵 Model**: Current Claude model with distinctive emoji indicator
- **📊 REPO**: Total cost for current repository session
- **📅 30DAY**: Monthly spending total across all sessions
- **📈 7DAY**: Weekly spending for budget tracking
- **🌅 DAY**: Today's accumulated costs
- **🔥 LIVE**: Active billing block cost (when block is active)

*Powered by [ccusage](https://ccusage.com) for accurate cost monitoring*

### 🔌 **Line 3: MCP Server Health**

```
MCP (3/4): upstash-context-7-mcp, supabase-mcp-server, firecrawl-mcp, sqlscan-mcp
```

- **📡 Status Count**: Connected servers vs total configured servers
- **📋 Server List**: Individual MCP server names
- **🟢 Connection Status**: Color-coded health indicators
  - 🟢 **Connected**: Server is healthy and responding
  - 🔴 **Disconnected**: Server is down or unreachable
- **⚡ Real-time**: Updates automatically as servers come online/offline

### ⏰ **Line 4: Block Reset Timer** *(Context-Aware Display)*

```
RESET at 11.00 (2h 37m left)
```

- **🕒 Reset Time**: When current 5-hour conversation block expires
- **⏳ Countdown**: Time remaining in human-readable format
- **🎯 Smart Detection**: Only appears when billing block is active
- **📅 Context Aware**: Automatically tracks block boundaries from conversation history

---

## 📋 System Requirements

### ✅ **Platform Compatibility**

We support all major Unix-like systems with comprehensive testing and optimization:

| Platform | Support Level | Core Dependencies | Optional Tools |
|----------|---------------|-------------------|----------------|
| 🍎 **macOS** | ✅ **Full Support** | `jq` `coreutils` | `bunx` `ccusage` |
| 🐧 **Linux** | ✅ **Full Support** | `jq` | `bunx` `ccusage` |
| 🪟 **Windows WSL** | ✅ **Full Support** | `jq` | `bunx` `ccusage` |
| 🪟 **Windows Native** | ❌ **Not Supported** | N/A | *Bash incompatible* |

### 🛠️ **Required Dependencies**

#### Core Requirements
- **`jq`** - JSON processing and data parsing
  - macOS: `brew install jq`
  - Linux: `sudo apt install jq` or `sudo yum install jq`
  - Purpose: Parse Claude Code JSON data and MCP server responses

#### System Tools *(Usually Pre-installed)*
- **`bash`** - Shell execution environment (v4.0+)
- **`git`** - Version control integration
- **`grep`**, **`sed`**, **`date`** - Text processing and utilities
- **`timeout`** / **`gtimeout`** - Command timeout management

### 🚀 **Recommended Enhancements**

#### Cost Tracking Integration
- **`bunx`** - Bun package runner for ccusage execution
  - Install: `npm install -g bunx`
- **`ccusage`** - Claude Code usage and cost monitoring
  - Install: `npm install -g ccusage`
  - Purpose: Real-time cost tracking and billing information

#### Performance Optimizations
- **GNU Coreutils** (macOS) - Enhanced command compatibility
  - Install: `brew install coreutils`
  - Provides `gtimeout` and other GNU-style commands

### ⚙️ **Version Requirements**

| Tool | Minimum Version | Recommended | Notes |
|------|----------------|-------------|-------|
| Bash | 4.0+ | 5.0+ | Pre-installed on most systems |
| jq | 1.5+ | 1.6+ | JSON processing performance |
| Git | 2.0+ | 2.30+ | Modern git features |
| Node.js | 16+ | 18+ | For ccusage integration |

### 🔧 **Quick Dependency Check**

Verify your system is ready:

```bash
# Check core requirements
bash --version && echo "✅ Bash OK" || echo "❌ Bash missing"
jq --version && echo "✅ jq OK" || echo "❌ jq missing" 
git --version && echo "✅ Git OK" || echo "❌ Git missing"

# Check optional tools
bunx --version && echo "✅ bunx OK" || echo "⚠️ bunx missing (install with: npm install -g bunx)"
ccusage --version && echo "✅ ccusage OK" || echo "⚠️ ccusage missing (install with: npm install -g ccusage)"
```

## 📖 Documentation

- [📦 Installation Guide](docs/installation.md) - Platform-specific setup instructions
- [⚙️ Configuration Guide](docs/configuration.md) - Detailed customization options  
- [🎨 Themes Guide](docs/themes.md) - Theme showcase and custom theme creation
- [🐛 Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## 🤝 Contributing

We welcome contributions from the community! Help make this statusline even better:

### 🌟 Ways to Contribute

- **🐛 Bug Reports** - Found an issue? [Open an issue](https://github.com/rz1989s/claude-code-statusline/issues/new?template=bug_report.md)
- **💡 Feature Requests** - Have an idea? [Suggest a feature](https://github.com/rz1989s/claude-code-statusline/issues/new?template=feature_request.md)
- **🎨 Theme Creation** - Design new themes and share them with the community
- **📖 Documentation** - Improve guides, add examples, or fix typos
- **🔧 Code Improvements** - Optimize performance, add features, or fix bugs

### 🔧 Development Setup

#### Prerequisites for Contributors

1. **Install Testing Framework** (required for running tests):
   ```bash
   # macOS with Homebrew
   brew install bats-core shellcheck
   
   # Ubuntu/Debian
   apt-get install bats shellcheck
   
   # Alternative: Install via npm
   npm install -g bats
   ```

2. **Install Project Dependencies**:
   ```bash
   npm install
   ```

#### Development Workflow

```bash
# Run the complete test suite
npm test

# Check code quality with shellcheck  
npm run lint

# Clean up test artifacts
npm run clean

# Development cycle (clean + test)
npm run dev

# Run tests in specific categories
npm run test:unit        # Unit tests only
npm run test:integration # Integration tests only
```

#### Testing Information

- **77 comprehensive tests** covering security, functionality, and integration
- **Automated CI/CD** with GitHub Actions
- **Cross-platform testing** on macOS and Linux
- **Detailed test documentation** in [`tests/README.md`](tests/README.md)

### 📝 Contribution Process

1. **Fork** the repository
2. **Set up development environment** (see above)
3. **Create** your feature branch (`git checkout -b feature/amazing-feature`)
4. **Run tests** to ensure everything works (`npm test`)
5. **Commit** your changes (`git commit -m 'Add amazing feature'`)
6. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### 🏆 Contributors

Thanks to all our contributors who help make this project better!

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Special thanks to the amazing projects and communities that make this statusline possible:

### 🛠️ Core Technologies
- **[Claude Code](https://claude.ai/code)** - The revolutionary AI development tool that inspired this project
- **[ccusage](https://ccusage.com)** - Excellent cost tracking and monitoring integration
- **[jq](https://jqlang.github.io/jq/)** - Powerful JSON processing for data parsing

### 🎨 Design & Aesthetics  
- **[Catppuccin](https://catppuccin.com/)** - Beautiful color palette that inspired our Catppuccin theme
- **[Nerd Fonts](https://www.nerdfonts.com/)** - Icon fonts that enhance the visual experience
- **Terminal Color Standards** - ANSI, 256-color, and RGB color support communities

### 🔧 Development Tools
- **[GNU Stow](https://www.gnu.org/software/stow/)** - Elegant dotfiles management solution
- **[Bash](https://www.gnu.org/software/bash/)** - The shell that powers our cross-platform compatibility
- **[Git](https://git-scm.com/)** - Version control integration and repository monitoring

### 💡 Inspiration
- **Open Source Community** - For fostering innovation and collaboration
- **Terminal Enthusiasts** - For pushing the boundaries of command-line aesthetics
- **Claude Code Users** - For feedback and feature requests that drive improvements

---

<div align="center">

### 🌟 Show Your Support

**Love this project? Give it a star!** ⭐

[![GitHub stars](https://img.shields.io/github/stars/rz1989s/claude-code-statusline?style=social)](https://github.com/rz1989s/claude-code-statusline/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/rz1989s/claude-code-statusline?style=social)](https://github.com/rz1989s/claude-code-statusline/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/rz1989s/claude-code-statusline?style=social)](https://github.com/rz1989s/claude-code-statusline/watchers)

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform Support](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20WSL-green.svg)](#-system-requirements)
[![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-9333EA.svg)](https://claude.ai/code)
[![Shell](https://img.shields.io/badge/Shell-Bash-lightgrey.svg)]()

### 💬 Connect & Support

[🐛 Report Bug](https://github.com/rz1989s/claude-code-statusline/issues) • [💡 Request Feature](https://github.com/rz1989s/claude-code-statusline/issues) • [📖 Documentation](docs/) • [💬 Discussions](https://github.com/rz1989s/claude-code-statusline/discussions)

**Made with ❤️ for the Claude Code community**

</div>