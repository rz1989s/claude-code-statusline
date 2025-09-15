# 📦 Installation Guide

**Complete installation instructions for Claude Code Enhanced Statusline with enterprise-grade TOML configuration system and revolutionary 3-tier download architecture.**

Get up and running with beautiful statuslines and powerful configuration management across all supported platforms. Our breakthrough **v2.9.0 Revolutionary 3-Tier Download System** eliminates GitHub rate limits forever and provides **100% download guarantee** with zero intervention required.

## 🎯 Platform Support Matrix

| Platform | Status | Package Manager | Dependencies (Auto-Detected) |
|----------|---------|-----------------|------------------------------|
| macOS (All Configurations) | ✅ **Universal Support** | Any (Homebrew/MacPorts/Custom) | `curl` `jq` `bun` `bc` `python3` |
| Linux (Ubuntu/Debian) | ✅ Full Support | apt | `curl` `jq` `bc` `python3` `coreutils` + bun via curl |
| Linux (RHEL/CentOS/Fedora) | ✅ Full Support | yum/dnf | `curl` `jq` `bc` `python3` `coreutils` + bun via curl |
| Linux (Arch) | ✅ Full Support | pacman | `curl` `jq` `bc` `python3` `coreutils` + bun via curl |
| Alpine Linux | ✅ Full Support | apk | `curl` `jq` `bc` `python3` `coreutils` + bun via curl |
| FreeBSD | ✅ Full Support | pkg | `curl` `jq` `bc` `python3` `coreutils` + bun via curl |
| Windows WSL | ✅ Full Support | apt/WSL | Same as Linux distributions |
| Windows Native | ❌ Not Supported | N/A | Bash script incompatible |

**🚀 Universal macOS Compatibility**: Runtime bash detection works across all Mac configurations (Apple Silicon + Homebrew, Intel + Homebrew, MacPorts, custom installations) with zero manual configuration required.

**Dependency Impact:**
- **Critical:** `curl` (installation) + `jq` (configuration) → 100% required
- **Important:** `bun/bunx` (cost tracking with ccusage) → 83% functionality without
- **Helpful:** `bc` (precise calculations) + `python3` (advanced TOML) → 67% functionality without  
- **Optional:** `timeout/gtimeout` (network protection) → 50% functionality without

## 🚀 Revolutionary 3-Tier Download System (Recommended) - v2.9.0

**Our breakthrough installer architecture eliminates GitHub rate limits forever with intelligent 3-tier download system and provides 100% download guarantee with zero intervention required.**

### Quick Installation

```bash
# Standard installation (backward compatible)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

# Enhanced mode - comprehensive dependency analysis
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --check-all-deps

# Interactive mode - user choice menu
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --interactive

# Full experience - analysis + choices
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --check-all-deps --interactive

# Preserve existing settings.json (skip Claude Code configuration)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --preserve-statusline
```

### Development Branch Installation

```bash
# 🚀 DEV6 (Current Development - Enhanced Settings.json Management)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6

# Dev6 with existing settings.json preservation
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6 --preserve-statusline

# 🌙 NIGHTLY (Experimental - Advanced Users Only)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/nightly/install.sh | bash -s -- --branch=nightly

# 🛠️ DEV (Stable Development)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev
```

### Enhanced Settings.json Management (Dev6)

**New --preserve-statusline Flag:**
- **Purpose**: Skip Claude Code settings.json configuration entirely
- **Use Case**: When you have existing statusline configurations or want manual control
- **Behavior**: Installs statusline files but doesn't modify settings.json
- **Safety**: Still creates backup with format: `settings.json.backup.YYYYMMDD_HHMMSS`

**Unified Backup Strategy:**
- **Always Backup**: Creates timestamped backup if settings.json exists
- **Canonical Command**: Sets `"statusLine": "bash ~/.claude/statusline/statusline.sh"`
- **Predictable**: Simple backup-then-replace behavior every installation
- **Safe**: Complete file backup provides 100% rollback capability

```bash
# Install with settings.json preservation (new in dev6)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6 --preserve-statusline

# Standard dev6 installation with settings.json backup and configuration
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6
```

### Download & Inspect First

```bash
# Download installer for inspection
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh -o install.sh
chmod +x install.sh

# See all options
./install.sh --help

# Run with preferred options
./install.sh --check-all-deps --interactive
```

### Revolutionary 3-Tier Download System Features (v2.9.0)

**🚀 3-Tier Architecture - Eliminates GitHub Rate Limits:**
- **Tier 1: Direct Raw URLs** → Unlimited requests, no API usage, fastest installation method (99% success rate)
- **Tier 2: GitHub API Fallback** → Optional token support increases limits from 60/hour to 5,000/hour
- **Tier 3: Comprehensive Retry** → Exponential backoff and intelligent verification with detailed troubleshooting

**🛡️ 100% Download Guarantee:**
- Either all modules download successfully or clear failure with actionable guidance
- Zero intervention required for normal installations
- Enhanced error handling with comprehensive retry mechanisms

**🔍 Smart System Detection:**
- Automatically detects OS (macOS, Ubuntu, CentOS, Arch, Alpine, FreeBSD)
- Identifies package manager (brew, apt, yum, dnf, pacman, apk, pkg)
- **Runtime bash compatibility detection** for universal macOS support
- Provides platform-specific installation commands

**📊 Comprehensive Dependency Analysis:**
```
  ✅ curl     → Download & installation
  ✅ jq       → Configuration & JSON parsing  
  ❌ bunx     → Cost tracking with ccusage
  ❌ bc       → Precise cost calculations
  ❌ python3  → Advanced TOML features & date parsing
  ⚠️ timeout  → Network operation protection

  📊 Available Features: 4/6 (67% functionality)
```

**🎯 User-Friendly Installation Choices:**
1. **Install now, upgrade later** - Get 67-100% functionality immediately
2. **Show install commands only** - Copy-paste exact commands for your system  
3. **Exit to install manually** - For users who prefer full control

**💻 No Package Manager Handling:**
- **macOS without Homebrew:** Step-by-step Homebrew installation guidance
- **Restricted environments:** Manual installation instructions
- **Corporate networks:** Offline installation bundle guidance

### Example Installation Flows

**New macOS User (no dependencies):**
```bash
./install.sh --check-all-deps --interactive

# Output:
# 🔍 System Analysis:
#   • OS: macOS (arm64)  
#   • Package Manager: none
#
# ❌ No package manager detected on macOS
# Step 1: Install Homebrew first
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Step 2: Then install dependencies  
# brew install bun python3 bc jq coreutils
```

**Ubuntu Developer (some dependencies):**
```bash
./install.sh --check-all-deps --interactive

# 🎯 Choose your installation approach:
# 1) Install statusline now, upgrade dependencies later
#    └─ 67% functionality, can upgrade anytime
# 2) Show install commands only (copy-paste)  
# 3) Exit to install dependencies manually first
```

---

## 📋 Manual Installation Methods

**Note:** The Revolutionary 3-Tier Download System above is recommended for most users. The manual methods below are provided for advanced users, restricted environments, or educational purposes.

### Prerequisites (Manual Installation Only)

The Revolutionary 3-Tier Download System handles these automatically, but for manual installation:

#### Node.js and Bun (for cost tracking)
```bash
# Check if already installed
node --version && bun --version

# Install Node.js if not available
# macOS: brew install node
# Ubuntu: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs

# Install Bun (for ccusage cost tracking)
curl -fsSL https://bun.sh/install | bash
```

#### Core Dependencies
```bash
# The Revolutionary 3-Tier Download System detects and installs these automatically:
# - curl (for downloads)
# - jq (for JSON/TOML processing)  
# - bc (for precise calculations)
# - python3 (for advanced TOML features)
# - timeout/gtimeout (for network protection)
```

## 🍎 macOS Installation

### Step 1: Install Homebrew Dependencies
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required dependencies
brew install jq coreutils

# Verify installation
jq --version
gtimeout --version
```

### Step 2: Install Cost Tracking Tools
```bash
# Install bunx and ccusage
npm install -g bunx ccusage

# Verify installation
bunx ccusage --version
```

### Step 3: Download and Install Modular Statusline
```bash
# Create Claude directory
mkdir -p ~/.claude/

# Download main orchestrator script
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

# Test the modular statusline
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test Model"}}' | ~/.claude/statusline.sh
```

## 🐧 Linux Installation

### Ubuntu/Debian

#### Step 1: Update Package Index
```bash
sudo apt update
```

#### Step 2: Install Dependencies
```bash
# Install jq
sudo apt install -y jq

# Install Node.js and npm (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install bunx and ccusage
npm install -g bunx ccusage

# Verify installations
jq --version
timeout --version
bunx ccusage --version
```

#### Step 3: Download and Install Modular Statusline
```bash
# Create Claude directory
mkdir -p ~/.claude/

# Download main orchestrator script
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
```

### RHEL/CentOS/Fedora

#### Step 1: Install Dependencies
```bash
# RHEL/CentOS 7/8
sudo yum install -y jq

# Fedora
sudo dnf install -y jq

# Install Node.js (use NodeSource repository)
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
sudo yum install -y nodejs  # or sudo dnf install -y nodejs

# Install bunx and ccusage
npm install -g bunx ccusage
```

#### Step 2: Download and Install Modular Statusline
```bash
# Create Claude directory
mkdir -p ~/.claude/

# Download main orchestrator script
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
```

### Arch Linux

#### Step 1: Install Dependencies
```bash
# Update system
sudo pacman -Syu

# Install jq
sudo pacman -S jq

# Install Node.js and npm
sudo pacman -S nodejs npm

# Install bunx and ccusage
npm install -g bunx ccusage
```

#### Step 2: Download and Install Modular Statusline
```bash
# Create Claude directory
mkdir -p ~/.claude/

# Download main orchestrator script
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
```

## 🪟 Windows WSL Installation

### Step 1: Enable WSL
```powershell
# In PowerShell as Administrator
wsl --install
```

### Step 2: Install Ubuntu/Debian in WSL
```bash
# After WSL installation, launch Ubuntu/Debian
# Follow Ubuntu installation steps above
sudo apt update
sudo apt install -y jq nodejs npm
npm install -g bunx ccusage
```

### Step 3: Install Modular Statusline in WSL
```bash
# Inside WSL - Create Claude directory
mkdir -p ~/.claude/

# Download main orchestrator script
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
```

## 🎯 GNU Stow Integration (Recommended)

If you use [GNU Stow](https://www.gnu.org/software/stow/) for dotfiles management:

### Step 1: Add to Dotfiles Structure
```bash
# In your dotfiles repository
mkdir -p claude/.claude/
mkdir -p claude/.claude/lib/
cd claude/.claude/

# Download main orchestrator script
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o statusline.sh
chmod +x statusline.sh

# Download all modules
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/core.sh -o lib/core.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/security.sh -o lib/security.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/config.sh -o lib/config.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/themes.sh -o lib/themes.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/git.sh -o lib/git.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/mcp.sh -o lib/mcp.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/cost.sh -o lib/cost.sh
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/display.sh -o lib/display.sh
```

### Step 2: Stow the Configuration
```bash
# From your dotfiles root directory
stow claude

# This creates symlinks: ~/.claude/statusline.sh and ~/.claude/lib/ -> dotfiles/claude/.claude/
```

## ⚙️ Configure Claude Code

After installation, configure Claude Code to use the statusline:

```bash
# Method 1: Via Claude Code command
claude config set statusline ~/.claude/statusline.sh

# Method 2: Edit settings manually
# Add to your Claude Code settings.json:
{
  "statusline": "~/.claude/statusline.sh"
}
```

## 🧪 Testing Installation & TOML Configuration

### Basic Installation Test
```bash
# Check if the statusline script and modules are present
ls -la ~/.claude/statusline.sh ~/.claude/lib/

# Verify Claude Code configuration
claude config get statusline

# Test the modular statusline help system
~/.claude/statusline.sh --help
```

### 🎨 **TOML Configuration Setup (Recommended)**

The statusline now features an **enterprise-grade TOML configuration system**. Set it up for the best experience:

#### Quick TOML Configuration Setup

```bash
# Navigate to your preferred config location
cd ~/  # For user-wide config

# Generate your Config.toml file
cp ~/.claude/statusline/examples/Config.toml ./Config.toml

# Customize your configuration
vim Config.toml

# Test your configuration
~/.claude/statusline.sh # Configuration is automatically loaded
```

#### Configuration File Locations

The statusline automatically discovers configuration in this order:

1. **`./Config.toml`** - Project-specific (highest priority)
2. **`~/.config/claude-code-statusline/Config.toml`** - XDG standard location  
3. **`~/.claude-statusline.toml`** - User home directory

#### Generate Configuration in Specific Locations

```bash
# User-wide XDG-compliant configuration
mkdir -p ~/.config/claude-code-statusline
cp ~/.claude/statusline/examples/Config.toml ./Config.toml ~/.config/claude-code-statusline/Config.toml

# Project-specific configuration
cd ~/my-project
cp ~/.claude/statusline/examples/Config.toml ./Config.toml ./Config.toml

# Home directory configuration
cp ~/.claude/statusline/examples/Config.toml ./Config.toml ~/.claude-statusline.toml
```

#### Quick Theme Setup

```bash
# Test different themes instantly (no files needed)
ENV_CONFIG_THEME=garden ~/.claude/statusline.sh      # Soft pastels
ENV_CONFIG_THEME=catppuccin ~/.claude/statusline.sh  # Dark modern
ENV_CONFIG_THEME=classic ~/.claude/statusline.sh     # Traditional

# Or create a simple Config.toml
cat > Config.toml << 'EOF'
theme.name =
name = "catppuccin"

# Features section converted to flat format
show_commits = true
show_cost_tracking = true
show_mcp_status = true
EOF

# Test your theme
~/.claude/statusline.sh # Configuration is automatically loaded
```

### Statusline Functionality Test

```bash
# Test script with minimal input
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test Model"}}' | ~/.claude/statusline.sh

# Test with git repository
cd ~/some-git-repo
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Sonnet 4"}}' | ~/.claude/statusline.sh
```

### TOML Configuration Testing

```bash
# Comprehensive configuration testing
~/.claude/statusline.sh # Configuration is automatically loaded-verbose     # Detailed testing output
~/.claude/statusline.sh --validate-config         # Validate TOML syntax
~/.claude/statusline.sh --compare-config          # Compare inline vs TOML settings
```

### Expected Output
- **3-4 lines** of beautifully formatted statusline with colors
- **TOML configuration loading** messages showing which config file is used
- **Theme application** with your chosen color scheme
- **Feature status** showing enabled/disabled components

## 🔧 Troubleshooting

### Common Issues

#### `jq: command not found`
**Solution**: Install jq using your platform's package manager (see above).

#### `gtimeout: command not found` (macOS)
**Solution**: Install GNU coreutils:
```bash
brew install coreutils
```

#### `bunx ccusage --version` fails
**Solutions**:
1. Check Node.js installation: `node --version`
2. Reinstall bunx: `npm install -g bunx`
3. Clear npm cache: `npm cache clean --force`

#### Colors not displaying properly
**Solutions**:
1. Check terminal color support: `echo $TERM`
2. Try different theme: Edit `CONFIG_THEME="classic"` in script
3. Use ANSI colors: Set `CONFIG_THEME="custom"` and modify color variables

#### Script hangs or is slow
**Solutions**:
1. **TOML Configuration**: Create Config.toml with reduced timeouts:
   ```toml
   [timeouts]
   mcp = "1s"
   ccusage = "1s"
   version = "1s"
   ```
2. **Environment Override**: `ENV_CONFIG_MCP_TIMEOUT=1s ~/.claude/statusline.sh`
3. **Disable features**: 
   ```toml
   [features]
   show_mcp_status = false
   show_cost_tracking = false
   ```

#### TOML Configuration Issues

**TOML file not found**:
```bash
# Check configuration discovery
~/.claude/statusline.sh # Configuration is automatically loaded-verbose

# Generate configuration if missing
cp ~/.claude/statusline/examples/Config.toml ./Config.toml
```

**TOML syntax errors**:
```bash
# Validate TOML syntax
~/.claude/statusline.sh --validate-config

# Common syntax issues:
# ❌ Incorrect: theme = catppuccin
# ✅ Correct:   theme = "catppuccin"
```

**Environment overrides not working**:
```bash
# Test environment override
ENV_CONFIG_THEME=garden ~/.claude/statusline.sh # Configuration is automatically loaded

# Should show: Theme: garden (environment override)
```

### Debug Mode
Add debug output by running:
```bash
# Enable bash debug mode
bash -x ~/.claude/statusline.sh
```

### Getting Help

1. 📖 Check [configuration.md](configuration.md) for customization options
2. 🎨 See [themes.md](themes.md) for theme-specific issues  
3. 🐛 Open an issue on [GitHub](https://github.com/rz1989s/claude-code-statusline/issues)

## 🚀 Next Steps

After successful installation, explore the **powerful TOML configuration system**:

### 🎨 **Configuration & Themes**
1. **Generate Config.toml** - `cp ~/.claude/statusline/examples/Config.toml ./Config.toml`
2. **Choose your theme** - Edit `[theme] name = "catppuccin"` in Config.toml  
3. **Customize features** - Enable/disable sections in `[features]`
4. **Test changes** - `~/.claude/statusline.sh # Configuration is automatically loaded`

### 💰 **Cost Tracking Setup**
5. **Configure ccusage** - Set up with your Claude API keys
6. **Enable cost features** - `show_cost_tracking = true` in Config.toml

### 📚 **Documentation & Advanced Features**
7. **Read comprehensive guides**:
   - 📖 **[TOML Configuration Guide](configuration.md)** - Complete configuration reference
   - 🎨 **[Themes Guide](themes.md)** - Theme creation and customization
   - 🚀 **[Migration Guide](migration.md)** - Migrate from inline configuration
   - 🔧 **[CLI Reference](cli-reference.md)** - Complete command documentation

### 🎯 **Quick Start Examples**

```bash
# Minimal setup - just choose a theme
cat > Config.toml << 'EOF'
theme.name =
name = "catppuccin"
EOF

# Developer setup - all features enabled
cat > Config.toml << 'EOF'
theme.name =
name = "catppuccin"

# Features section converted to flat format
show_commits = true
show_version = true
show_mcp_status = true
show_cost_tracking = true

# Timeouts section converted to flat format
mcp = "3s"
ccusage = "3s"
EOF

# Test your configuration
~/.claude/statusline.sh # Configuration is automatically loaded
```

### 🌍 **Environment Variable Shortcuts**

```bash
# Try themes instantly without editing files
ENV_CONFIG_THEME=garden ~/.claude/statusline.sh
ENV_CONFIG_THEME=classic ~/.claude/statusline.sh

# Disable features temporarily
ENV_CONFIG_SHOW_COST_TRACKING=false ~/.claude/statusline.sh
```

---

**Installation complete!** Your Claude Code statusline should now display rich information about your development environment.