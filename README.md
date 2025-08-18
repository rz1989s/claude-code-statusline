# Claude Code Enhanced Statusline

An enhanced 4-line statusline for [Claude Code](https://claude.ai/code) that transforms your terminal experience with rich information display, beautiful themes, and comprehensive monitoring capabilities.

## ✨ Features

### 🎨 **Beautiful Themed Interface**
- **3 Predefined Themes**: Classic, Garden (pastels), and Catppuccin
- **Custom Theme Support**: Full RGB/256-color/ANSI color customization
- **Cross-Platform Colors**: Optimized for macOS, Linux, and WSL

### 📊 **Comprehensive Information Display**

**Line 1: Repository Overview**
```
~/dotfiles (main) ✅ │ Commits:5 │ ver1.0.81 │ SUB:3 │ 🕐 14:23
```

**Line 2: Cost Tracking**
```
🎵 Sonnet 4 │ REPO $0.45 │ 30DAY $12.30 │ 7DAY $3.21 │ DAY $0.89 │ 🔥 LIVE $0.15
```

**Line 3: MCP Server Status**
```
MCP (2/3): upstash-context-7-mcp, github, filesystem
```

**Line 4: Block Reset Timer** *(when active)*
```
RESET at 15.45 (2h 15m left)
```

### ⚡ **Smart Monitoring**
- **Real-time Cost Tracking** with [ccusage](https://ccusage.com) integration
- **MCP Server Health** with connection status indicators
- **Git Repository Status** with commit counting
- **Performance Optimized** with intelligent caching and timeouts

### 🔧 **Highly Configurable**
- **Feature Toggles**: Enable/disable any section
- **Timeout Controls**: Prevent hanging on slow networks
- **Label Customization**: Modify all display text
- **Emoji Customization**: Personalize status indicators

## 🚀 Quick Start

### Prerequisites

**macOS:**
```bash
brew install jq coreutils
npm install -g bunx ccusage
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update && sudo apt install jq
npm install -g bunx ccusage
```

**Windows (WSL):**
```bash
sudo apt update && sudo apt install jq
npm install -g bunx ccusage
```

### Installation

1. **Download the script:**
```bash
curl -O https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline-enhanced.sh
chmod +x statusline-enhanced.sh
```

2. **For GNU Stow users (recommended):**
```bash
# Place in your dotfiles structure
mkdir -p ~/.dotfiles/claude/.claude/
mv statusline-enhanced.sh ~/.dotfiles/claude/.claude/
cd ~/.dotfiles && stow claude
```

3. **Direct installation:**
```bash
mkdir -p ~/.claude/
mv statusline-enhanced.sh ~/.claude/
```

4. **Configure Claude Code to use the statusline:**
Add to your Claude Code settings or run:
```bash
claude config set statusline ~/.claude/statusline-enhanced.sh
```

## 🎨 Theme Gallery

### Classic Theme
Traditional terminal colors with ANSI compatibility
```bash
# Set in script
CONFIG_THEME="classic"
```

### Garden Theme  
Soft pastel colors for a gentle aesthetic
```bash
# Set in script
CONFIG_THEME="garden"
```

### Catppuccin Theme
Official [Catppuccin Mocha](https://catppuccin.com/) colors
```bash
# Set in script  
CONFIG_THEME="catppuccin"
```

### Custom Theme
Full control over every color
```bash
# Set in script
CONFIG_THEME="custom"
# Then modify individual CONFIG_* variables
```

## ⚙️ Configuration

The script features a comprehensive configuration section at the top. Key settings:

### Theme Selection
```bash
CONFIG_THEME="catppuccin"  # classic, garden, catppuccin, custom
```

### Feature Toggles
```bash
CONFIG_SHOW_COMMITS=true
CONFIG_SHOW_VERSION=true
CONFIG_SHOW_MCP_STATUS=true
CONFIG_SHOW_COST_TRACKING=true
```

### Timeouts
```bash
CONFIG_MCP_TIMEOUT="3s"
CONFIG_VERSION_TIMEOUT="2s"
CONFIG_CCUSAGE_TIMEOUT="3s"
```

For detailed configuration options, see [docs/configuration.md](docs/configuration.md).

## 🔍 What Each Line Shows

### Line 1: Repository Info
- **Mode**: Current Claude mode (if available)
- **Directory**: Working directory with `~` notation
- **Git Status**: Branch name and clean/dirty status
- **Commits**: Today's commit count
- **Version**: Claude Code version (cached)
- **Submodules**: Git submodule count
- **Time**: Current time

### Line 2: Cost Tracking
- **Model**: Current Claude model with emoji
- **REPO**: Session cost for current repository
- **30DAY**: Monthly spending total
- **7DAY**: Weekly spending total  
- **DAY**: Today's spending
- **LIVE**: Active billing block cost (when available)

### Line 3: MCP Servers
- **Status**: Connected/total server count
- **Servers**: List with color coding (🟢 connected, 🔴 disconnected)

### Line 4: Reset Timer
- **Reset Time**: When current billing block ends
- **Time Remaining**: Hours and minutes left

## 📋 System Requirements

### ✅ **Supported Platforms**
| Platform | Status | Dependencies |
|----------|---------|--------------|
| macOS | ✅ Full Support | `jq` + `coreutils` + `bunx ccusage` |
| Linux | ✅ Full Support | `jq` + `bunx ccusage` |
| Windows WSL | ✅ Full Support | `jq` + `bunx ccusage` |
| Windows Native | ❌ Not Supported | Bash script incompatible |

### Required Tools
- `jq` - JSON processing
- `bunx ccusage` - Cost tracking (optional but recommended)
- `gtimeout`/`timeout` - Command timeouts
- Standard UNIX tools: `git`, `grep`, `sed`, `date`

## 📖 Documentation

- [📦 Installation Guide](docs/installation.md) - Platform-specific setup instructions
- [⚙️ Configuration Guide](docs/configuration.md) - Detailed customization options  
- [🎨 Themes Guide](docs/themes.md) - Theme showcase and custom theme creation
- [🐛 Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## 🤝 Contributing

Contributions are welcome! Please feel free to:

- 🐛 Report bugs
- 💡 Suggest features  
- 🎨 Create new themes
- 📖 Improve documentation
- 🔧 Submit code improvements

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Claude Code](https://claude.ai/code) - The amazing AI development tool
- [ccusage](https://ccusage.com) - Cost tracking integration
- [Catppuccin](https://catppuccin.com) - Beautiful theme colors
- [GNU Stow](https://www.gnu.org/software/stow/) - Dotfiles management

---

**Made with ❤️ for the Claude Code community**

*If you find this useful, please consider starring the repository!* ⭐