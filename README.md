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

### v1.0 - Enhanced Statusline Release

- **🎨 Three Stunning Themes** - Classic, Garden (pastels), and Catppuccin Mocha
- **💰 Real-time Cost Tracking** - Complete integration with [ccusage](https://ccusage.com)
- **🔌 MCP Server Monitoring** - Live status of Model Context Protocol servers
- **⏰ Block Reset Timer** - Track your 5-hour conversation blocks with countdown
- **📊 Git Integration** - Repository status, commit counting, and branch information
- **⚡ Performance Optimized** - Smart caching and configurable timeouts
- **🔧 Highly Configurable** - Feature toggles, timeout controls, and customization options

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
- **⏱️ Configurable Timeouts** - Prevents hanging on slow networks  
- **📊 Real-time Updates** - Live cost and status monitoring
- **🌍 Cross-Platform** - Works seamlessly on macOS, Linux, and WSL
- **💾 Memory Efficient** - Minimal resource usage with maximum information

### 🔧 **Comprehensive Customization**

- **🎛️ Feature Toggles** - Enable/disable any display section
- **⏲️ Timeout Controls** - Fine-tune network timeout settings
- **🏷️ Label Customization** - Modify all display text and formats
- **😊 Emoji Customization** - Personalize status indicators
- **🎨 Theme System** - Easy theme switching and custom color schemes

---

## 🎨 Theme Gallery

Transform your terminal aesthetic with our carefully crafted theme collection. Each theme is optimized for readability and visual appeal across different terminal environments.

### 🌙 Catppuccin Mocha Theme

Rich, warm colors inspired by the beloved [Catppuccin](https://catppuccin.com/) palette. Perfect for dark mode enthusiasts.

![Catppuccin Mocha Theme](assets/screenshots/catppuccin-mocha-theme.png)

```bash
# Set in script configuration
CONFIG_THEME="catppuccin"
```

### 🌿 Garden Theme  

Soft, pastel colors that create a gentle and soothing terminal environment. Ideal for extended coding sessions.

![Garden Theme](assets/screenshots/garden-theme.png)

```bash
# Set in script configuration
CONFIG_THEME="garden"
```

### ⚡ Classic Theme

Traditional terminal colors with modern polish. ANSI-compatible and universally readable.

![Classic Theme](assets/screenshots/classic-theme.png)

```bash
# Set in script configuration  
CONFIG_THEME="classic"
```

### 🎨 Custom Theme

Complete creative control with full RGB/256-color/ANSI color customization capabilities.

```bash
# Set in script configuration
CONFIG_THEME="custom"
# Then customize individual CONFIG_* color variables
CONFIG_COLOR_DIRECTORY="\\033[38;2;255;182;193m"
CONFIG_COLOR_BRANCH="\\033[38;2;173;216;230m"
# ... and more
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

#### Method 1: Quick Install (Recommended)

```bash
# Download and install in one step
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# Configure Claude Code to use the statusline
claude config set statusline ~/.claude/statusline.sh
```

#### Method 2: GNU Stow Integration

Perfect for dotfiles management with [GNU Stow](https://www.gnu.org/software/stow/):

```bash
# Place in your dotfiles structure
mkdir -p ~/.dotfiles/claude/.claude/
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.dotfiles/claude/.claude/statusline.sh
chmod +x ~/.dotfiles/claude/.claude/statusline.sh

# Deploy with Stow
cd ~/.dotfiles && stow claude

# Configure Claude Code
claude config set statusline ~/.claude/statusline.sh
```

#### Method 3: Manual Installation

```bash
# Create directory if it doesn't exist
mkdir -p ~/.claude/

# Download the script
curl -O https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh
chmod +x statusline.sh
mv statusline.sh ~/.claude/

# Configure Claude Code
claude config set statusline ~/.claude/statusline.sh
```

### ✅ Verification

Test your installation:

```bash
# Check if the statusline script is executable
ls -la ~/.claude/statusline.sh

# Verify Claude Code configuration
claude config get statusline
```

> 💡 **Pro Tip**: Start a new Claude Code session to see your enhanced statusline in action!

---

## ⚙️ Configuration

Customize your statusline experience with our comprehensive configuration system. All settings are located at the top of the script for easy modification.

### 🎨 Theme Configuration

Choose from our beautiful pre-built themes or create your own:

```bash
# Theme Selection - Pick your favorite aesthetic
CONFIG_THEME="catppuccin"  # Options: classic, garden, catppuccin, custom

# For custom themes, set individual colors:
CONFIG_THEME="custom"
CONFIG_COLOR_DIRECTORY="\\033[38;2;255;182;193m"    # Soft pink
CONFIG_COLOR_BRANCH="\\033[38;2;173;216;230m"       # Light blue  
CONFIG_COLOR_STATUS="\\033[38;2;144;238;144m"       # Light green
CONFIG_COLOR_TIME="\\033[38;2;255;165;0m"           # Orange
```

### 🎛️ Feature Toggles

Enable or disable specific functionality to suit your workflow:

<details>
<summary><strong>Core Features</strong></summary>

```bash
# Repository Information
CONFIG_SHOW_COMMITS=true        # Show today's commit count
CONFIG_SHOW_VERSION=true        # Display Claude Code version
CONFIG_SHOW_SUBMODULES=true     # Show git submodule count

# Monitoring & Status
CONFIG_SHOW_MCP_STATUS=true     # MCP server health monitoring
CONFIG_SHOW_COST_TRACKING=true  # Financial cost tracking (ccusage)
CONFIG_SHOW_RESET_TIMER=true    # Block reset countdown

# Visual Elements
CONFIG_SHOW_EMOJIS=true         # Emoji indicators
CONFIG_SHOW_TIME=true           # Current time display
```
</details>

### ⏱️ Performance Tuning

Fine-tune timeouts to optimize for your network and system performance:

```bash
# Network Operation Timeouts
CONFIG_MCP_TIMEOUT="3s"         # MCP server status check timeout
CONFIG_VERSION_TIMEOUT="2s"     # Claude Code version check timeout
CONFIG_CCUSAGE_TIMEOUT="3s"     # Cost tracking API timeout

# Caching Configuration
CONFIG_VERSION_CACHE_TTL="3600" # Cache version info for 1 hour
CONFIG_GIT_CACHE_TTL="60"       # Cache git info for 1 minute
```

### 🏷️ Label Customization

Personalize the display text and indicators:

<details>
<summary><strong>Custom Labels & Emojis</strong></summary>

```bash
# Status Labels
CONFIG_LABEL_COMMITS="Commits"
CONFIG_LABEL_VERSION="ver"
CONFIG_LABEL_SUBMODULES="SUB"
CONFIG_LABEL_MCP="MCP"

# Status Emojis
CONFIG_EMOJI_CLEAN="✅"         # Clean git status
CONFIG_EMOJI_DIRTY="⚠️"         # Dirty git status  
CONFIG_EMOJI_TIME="🕐"          # Time indicator
CONFIG_EMOJI_LIVE="🔥"          # Live cost indicator
CONFIG_EMOJI_SONNET="🎵"        # Sonnet model indicator
```
</details>

### 🔧 Advanced Settings

<details>
<summary><strong>Expert Configuration</strong></summary>

```bash
# Display Formatting
CONFIG_SEPARATOR=" │ "          # Section separator
CONFIG_PADDING_LEFT=""          # Left padding
CONFIG_PADDING_RIGHT=""         # Right padding

# Color Reset
CONFIG_RESET="\\033[0m"         # Color reset sequence

# Debug Options
CONFIG_DEBUG=false              # Enable debug output
CONFIG_VERBOSE=false            # Verbose logging
```
</details>

> 📖 **Need Help?** Check out our [Configuration Guide](docs/configuration.md) for detailed setup instructions and advanced customization options.

> ⚡ **Pro Tip**: Changes take effect immediately - just start a new Claude Code session to see your modifications!

## 🔍 What Each Line Shows

Understand every element of your enhanced statusline with this detailed breakdown:

### 📁 **Line 1: Repository & Environment Info**

```
~/local-dev (main) ✅ │ Commits:0 │ ver1.0.83 │ SUB:— │ 🕐 08:22
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