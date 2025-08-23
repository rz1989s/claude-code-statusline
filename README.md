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

### v1.4.0 - Centralized Version Management System 🎯

- **📍 Single Source of Truth** - Introduced `version.txt` as master version file for entire codebase
- **🛠️ Version Management Scripts** - Automated tools for version synchronization and consistency checks
- **🔄 Dynamic Version Reading** - All components now read version from centralized source
- **📦 Automated Package Sync** - Scripts maintain package.json synchronization with version.txt
- **✅ System Verification** - Comprehensive testing tools for version consistency
- **📚 Complete Documentation** - Full guide for centralized version management workflow

### v1.3.1 - Enhanced Error Messages & Documentation 🔧

- **📝 Improved Error Messages** - Enhanced module loading error messages with specific troubleshooting guidance  
- **📚 Function Documentation** - Added comprehensive documentation to core.sh functions
- **🧪 Enhanced Testing** - New test coverage for module loading functionality
- **🔍 Better Diagnostics** - Clearer error messages help users resolve issues faster

### v1.3.0 - Modular Architecture Implementation 🏗️ 

*Contains internal v2.0.0-refactored architecture while maintaining v1.3.x compatibility*

- **🏗️ Modular Architecture** - Complete refactor from 3930-line monolithic script to clean modular system
- **📦 8 Specialized Modules** - Core, security, config, themes, git, MCP, cost, and display modules  
- **🎯 91.4% Code Reduction** - Main orchestrator reduced to 338 lines with preserved functionality
- **🔧 Enhanced Maintainability** - Clear separation of concerns and dependency management
- **⚡ Improved Performance** - Optimized module loading and reduced complexity
- **🔄 100% Backward Compatible** - All existing functionality and configuration preserved

### v1.2 - Enhanced Timeout Validation & Configuration Improvements 🚀

- **✅ Comprehensive Timeout Validation** - Enhanced bounds checking with contextual suggestions
- **🔧 Smart Configuration Validation** - Prevents dangerous timeout values (0s, >60s)
- **📖 Enhanced CLI Documentation** - Detailed timeout configuration guidance
- **🛠️ New Helper Functions** - `parse_timeout_to_seconds()` and `validate_timeout_bounds()`
- **💡 Contextual Error Messages** - Specific suggestions for optimal timeout ranges
- **🔄 Backward Compatible** - All existing configurations continue to work

### v1.1 - Enhanced Directory Structure & TOML Configuration

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

**Line 1: Repository Overview** *(lib/display.sh, lib/git.sh)*
- Working directory with elegant `~` notation
- Git branch with clean/dirty status indicators
- Today's commit count tracking
- Claude Code version (intelligently cached)
- Git submodule count
- Current time display

![Cost Tracking Integration](assets/screenshots/ccusage-info.png)

**Line 2: Cost Tracking & Model Info** *(lib/display.sh, lib/cost.sh)*
- Current Claude model with emoji indicators
- Repository session costs
- 30-day, 7-day, and daily spending totals
- Live billing block costs with [ccusage](https://ccusage.com) integration
- Real-time financial monitoring

![MCP Server Monitoring](assets/screenshots/mcp-info.png)

**Line 3: MCP Server Health** *(lib/display.sh, lib/mcp.sh)*
- Connected vs total server count
- Server names with connection status
- Color-coded indicators (🟢 connected, 🔴 disconnected)
- Real-time health monitoring

**Line 4: Block Reset Timer** *(lib/display.sh, lib/cost.sh)*
- Next reset time display
- Countdown to block expiration
- Smart detection and tracking

### 🏗️ **Modular Architecture**

- **📦 8 Specialized Modules** - Clean separation of concerns with dedicated modules for each feature
  - `core.sh` - Base utilities, module loading, and performance timing
  - `security.sh` - Input sanitization and secure file operations  
  - `config.sh` - TOML configuration parsing and management
  - `themes.sh` - Color theme system with inheritance support
  - `git.sh` - Repository status, branch detection, and commit tracking
  - `mcp.sh` - MCP server monitoring and health checking
  - `cost.sh` - Cost tracking integration with ccusage
  - `display.sh` - Output formatting and 4-line statusline generation
- **🎯 91.4% Code Reduction** - Main orchestrator script reduced from 3930 to 338 lines
- **🔧 Enhanced Maintainability** - Modular design enables easier testing, debugging, and feature development
- **⚡ Improved Performance** - Optimized module loading and reduced script complexity

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
- **⏲️ Enhanced Timeout Controls** - Comprehensive validation with contextual bounds checking
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
ENV_CONFIG_THEME=catppuccin ~/.claude/statusline.sh
```

**CLI Generation:**
```bash
# Generate Config.toml with catppuccin theme
~/.claude/statusline.sh --generate-config
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
ENV_CONFIG_THEME=garden ~/.claude/statusline.sh
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
ENV_CONFIG_THEME=classic ~/.claude/statusline.sh
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
~/.claude/statusline.sh --generate-config MyTheme.toml
# Edit MyTheme.toml with your custom colors
~/.claude/statusline.sh --test-config MyTheme.toml
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

#### Method 1: Enhanced Automated Installer (Recommended)

Our intelligent installer provides comprehensive dependency management, downloads all necessary files including `version.txt` for centralized version management, and offers user choice:

```bash
# Standard installation (minimal dependency check)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

# Enhanced mode - shows all 6 dependencies with feature impact
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --check-all-deps

# Interactive mode - gives you installation choices
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --interactive

# Full analysis with user menu
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --check-all-deps --interactive
```

<details>
<summary><strong>🔍 Enhanced Installer Features</strong></summary>

**Smart System Detection:**
- Automatically detects your OS and package manager (brew, apt, yum, dnf, pacman)
- Provides platform-specific installation commands

**Comprehensive Dependency Analysis:**
- `curl` + `jq` → Core installation and configuration
- `bun/bunx` → Cost tracking with ccusage integration  
- `bc` → Precise cost calculations
- `python3` → Advanced TOML features and date parsing
- `timeout/gtimeout` → Network operation protection

**User-Friendly Options:**
- **Install now, upgrade later** - Get 67-100% functionality immediately
- **Show commands only** - Copy-paste exact commands for your system
- **Exit to install manually** - For users who prefer full control

**No Package Manager? No Problem:**
- Homebrew installation guidance for macOS users
- Manual installation instructions for restricted environments

</details>

**Quick Download & Inspect:**
```bash
# Download and inspect before running
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh -o install.sh
chmod +x install.sh

# See all available options
./install.sh --help

# Run with your preferred mode
./install.sh --check-all-deps --interactive
```

#### Method 2: GNU Stow Integration

Perfect for dotfiles management with [GNU Stow](https://www.gnu.org/software/stow/):

```bash
# Place in your dotfiles structure
mkdir -p ~/.dotfiles/claude/.claude/
mkdir -p ~/.dotfiles/claude/.claude/lib/

# Download main script and all modules
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.dotfiles/claude/.claude/statusline.sh
chmod +x ~/.dotfiles/claude/.claude/statusline.sh

curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/core.sh -o ~/.dotfiles/claude/.claude/lib/core.sh
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/security.sh -o ~/.dotfiles/claude/.claude/lib/security.sh
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/config.sh -o ~/.dotfiles/claude/.claude/lib/config.sh
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/themes.sh -o ~/.dotfiles/claude/.claude/lib/themes.sh
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/git.sh -o ~/.dotfiles/claude/.claude/lib/git.sh
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/mcp.sh -o ~/.dotfiles/claude/.claude/lib/mcp.sh
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/cost.sh -o ~/.dotfiles/claude/.claude/lib/cost.sh
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/display.sh -o ~/.dotfiles/claude/.claude/lib/display.sh

# Deploy with Stow
cd ~/.dotfiles && stow claude

# Configure Claude Code (manual JSON editing)
# Add to ~/.claude/settings.json:
# "statusLine": {"type": "command", "command": "bash ~/.claude/statusline.sh"}
```

#### Method 3: Manual Installation

```bash
# Create Claude directory if it doesn't exist
mkdir -p ~/.claude/

# Download the main orchestrator script
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# Create lib directory and download all modules
mkdir -p ~/.claude/lib/
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/core.sh -o ~/.claude/lib/core.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/security.sh -o ~/.claude/lib/security.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/config.sh -o ~/.claude/lib/config.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/themes.sh -o ~/.claude/lib/themes.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/git.sh -o ~/.claude/lib/git.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/mcp.sh -o ~/.claude/lib/mcp.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/cost.sh -o ~/.claude/lib/cost.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/display.sh -o ~/.claude/lib/display.sh

# Configure Claude Code (manual JSON editing)
# Add to ~/.claude/settings.json:
# "statusLine": {"type": "command", "command": "bash ~/.claude/statusline.sh"}
```

> 💡 **Why use the Enhanced Installer?** 
> - **Smart dependency analysis** - Know exactly what features you'll get
> - **Platform-aware guidance** - Tailored commands for your system  
> - **Zero manual JSON editing** - Automatic settings.json configuration
> - **User choice** - Install now or install dependencies first
> - **Backward compatible** - Existing workflow unchanged

### ✅ Verification

Test your installation:

```bash
# Check if the statusline script and lib directory are present
ls -la ~/.claude/statusline.sh ~/.claude/lib/

# Verify Claude Code configuration (check settings.json)
cat ~/.claude/settings.json | jq '.statusLine'

# Test the statusline directly
~/.claude/statusline.sh --help
```

### 🎨 **Configuration Setup (TOML System)**

**Skip this step if you want to use defaults** - the statusline works immediately with beautiful built-in themes!

#### Generate Your Configuration File (Recommended)

```bash
# Navigate to your preferred location
cd ~/  # or any project directory

# Generate Config.toml with current settings
~/.claude/statusline.sh --generate-config

# Customize your configuration
vim Config.toml

# Test your new configuration  
~/.claude/statusline.sh --test-config
```

#### Quick Theme Change

```bash
# Change theme temporarily (no file needed)
ENV_CONFIG_THEME=garden ~/.claude/statusline.sh

# Or create a simple Config.toml
cat > Config.toml << 'EOF'
[theme]
name = "catppuccin"

[features]
show_commits = true
show_cost_tracking = true
EOF

# Test your theme
~/.claude/statusline.sh --test-config
```

#### Configuration Discovery

The statusline automatically finds your config file:
- **`./Config.toml`** - Project-specific (highest priority)
- **`~/.claude/statusline/Config.toml`** - Primary user config location
- **`~/.config/claude-code-statusline/Config.toml`** - XDG standard location
- **`~/.claude-statusline.toml`** - Legacy fallback

> 💡 **Pro Tip**: Start with `~/.claude/statusline.sh --generate-config` to create your base configuration, then customize from there!

### 🚀 **Ready to Use!**

Start a new Claude Code session to see your enhanced statusline in action! Your configuration will be automatically detected and applied.

---

## ⚙️ Configuration

Transform your statusline with our **enterprise-grade TOML configuration system**. Modern, structured, and powerful - with full backwards compatibility for existing inline configurations.

## 🚀 **Getting Started with TOML Configuration**

### Quick Setup (Recommended)

```bash
# 1. Generate your Config.toml file
~/.claude/statusline.sh --generate-config

# 2. Customize your Config.toml file  
vim Config.toml

# 3. Test your configuration
~/.claude/statusline.sh --test-config

# 4. Start using your enhanced statusline!
~/.claude/statusline.sh
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
# Enhanced validation with contextual bounds checking (v1.2+)
[timeouts]
mcp = "10s"      # 1s-60s recommended, optimal: 3s-15s
version = "2s"   # 1s-10s recommended, optimal: 1s-3s
ccusage = "8s"   # 1s-30s recommended, optimal: 3s-10s

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
~/.claude/statusline.sh --generate-config              # Create Config.toml from current settings
~/.claude/statusline.sh --generate-config MyTheme.toml # Generate custom config file

# === TESTING & VALIDATION ===
~/.claude/statusline.sh --test-config                  # Test current configuration
~/.claude/statusline.sh --test-config MyTheme.toml     # Test specific config file
~/.claude/statusline.sh --test-config-verbose          # Detailed testing output
~/.claude/statusline.sh --validate-config              # Validate configuration with enhanced timeout bounds checking

# === COMPARISON & ANALYSIS ===
~/.claude/statusline.sh --compare-config               # Compare inline vs TOML settings
```

### Live Reload & Management

```bash
# === LIVE CONFIGURATION RELOAD ===
~/.claude/statusline.sh --reload-config                # Reload configuration now
~/.claude/statusline.sh --reload-interactive           # Interactive config management menu
~/.claude/statusline.sh --watch-config 3               # Watch for changes every 3 seconds

# === MIGRATION & BACKUP ===
~/.claude/statusline.sh --backup-config backup-dir/    # Backup current configuration
~/.claude/statusline.sh --restore-config backup-dir/   # Restore from backup
```

### Help & Documentation

```bash
# === HELP SYSTEM ===
~/.claude/statusline.sh --help                         # Complete help documentation with timeout guidance
~/.claude/statusline.sh --help config                  # Configuration-specific help

# === ADDITIONAL COMMANDS ===
~/.claude/statusline.sh                               # Run statusline with current configuration
```

> 💡 **Pro Tip**: Use environment overrides for temporary configuration changes without modifying your Config.toml file.

## 🌍 **Environment Variable Overrides**

Temporarily override any TOML setting with environment variables:

```bash
# === TEMPORARY THEME CHANGES ===
ENV_CONFIG_THEME=garden ~/.claude/statusline.sh        # Use garden theme once
ENV_CONFIG_THEME=classic ~/.claude/statusline.sh       # Use classic theme once

# === FEATURE OVERRIDES ===
ENV_CONFIG_SHOW_MCP_STATUS=false ~/.claude/statusline.sh     # Disable MCP status
ENV_CONFIG_MCP_TIMEOUT=15s ~/.claude/statusline.sh           # Increase MCP timeout (validated: 1s-60s)

# === PERFECT FOR CI/CD & AUTOMATION ===
ENV_CONFIG_SHOW_COST_TRACKING=false \
ENV_CONFIG_SHOW_RESET_INFO=false \
ENV_CONFIG_THEME=classic \
~/.claude/statusline.sh
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
mcp = "10s"      # Enhanced validation: 1s-60s range
version = "2s"   # Enhanced validation: 1s-10s range  
ccusage = "8s"   # Enhanced validation: 1s-30s range

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
~/.claude/statusline.sh --generate-config

# 2. Compare to see the differences  
~/.claude/statusline.sh --compare-config

# 3. Test the new TOML configuration
~/.claude/statusline.sh --test-config

# 4. Your inline config becomes the fallback
# TOML configuration takes precedence automatically
```

## 🔗 **Documentation Links**

- 📖 **[Complete Configuration Guide](docs/configuration.md)** - Detailed TOML configuration reference
- 🎨 **[Themes Guide](docs/themes.md)** - Theme creation and customization with TOML
- 🚀 **[Migration Guide](docs/migration.md)** - Step-by-step migration from inline configuration  
- 🔧 **[CLI Reference](docs/cli-reference.md)** - Complete command-line interface documentation
- 🐛 **[Troubleshooting](docs/troubleshooting.md)** - TOML configuration troubleshooting

> ⚡ **Pro Tip**: Start with `~/.claude/statusline.sh --generate-config` to create your base Config.toml, then customize from there! Changes are validated automatically.

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

**We welcome contributions from the community!** 🌟

Whether you're interested in:
- 🐛 **Bug fixes** and issue reports
- 💡 **New features** and enhancements  
- 🎨 **Theme creation** and design
- 📖 **Documentation** improvements
- 🧪 **Testing** and quality assurance

**Please see our comprehensive [CONTRIBUTING.md](CONTRIBUTING.md)** for detailed guidelines on:
- Development environment setup
- Code standards and testing requirements  
- Pull request process and review workflow
- Community guidelines and project structure

### 🚀 Quick Start for Contributors
```bash
# Fork and clone the repository
git clone https://github.com/YOUR-USERNAME/claude-code-statusline.git
cd claude-code-statusline

# Install dependencies and verify setup
npm install
npm test

# Check our development roadmap
cat TODOS.md
```

**Jazakallahu khairan** for helping make this project better for the Claude Code community! 🙏

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