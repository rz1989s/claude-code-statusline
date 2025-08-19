# 📦 Installation Guide

Complete installation instructions for Claude Code Enhanced Statusline across all supported platforms.

## 🎯 Platform Support Matrix

| Platform | Status | Package Manager | Dependencies |
|----------|---------|-----------------|--------------|
| macOS | ✅ Full Support | Homebrew | `jq` + `coreutils` + `bunx ccusage` |
| Linux (Ubuntu/Debian) | ✅ Full Support | apt | `jq` + `bunx ccusage` |
| Linux (RHEL/CentOS/Fedora) | ✅ Full Support | yum/dnf | `jq` + `bunx ccusage` |
| Linux (Arch) | ✅ Full Support | pacman | `jq` + `bunx ccusage` |
| Windows WSL | ✅ Full Support | apt/WSL | `jq` + `bunx ccusage` |
| Windows Native | ❌ Not Supported | N/A | Bash script incompatible |

## 📋 Prerequisites

### Node.js and npm
All platforms need Node.js for `bunx ccusage`:

```bash
# Check if already installed
node --version && npm --version

# If not installed, visit: https://nodejs.org/
# Or use package managers:
# macOS: brew install node
# Ubuntu: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
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

### Step 3: Download and Install Script
```bash
# Create directory
mkdir -p ~/.claude/

# Download script
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh

# Make executable
chmod +x ~/.claude/statusline.sh

# Test the script
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

#### Step 3: Download and Install Script
```bash
# Create directory
mkdir -p ~/.claude/

# Download script
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh

# Make executable
chmod +x ~/.claude/statusline.sh
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

#### Step 2: Download and Install Script
```bash
# Create directory
mkdir -p ~/.claude/

# Download script
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh

# Make executable
chmod +x ~/.claude/statusline.sh
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

#### Step 2: Download and Install Script
```bash
# Create directory
mkdir -p ~/.claude/

# Download script
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh

# Make executable
chmod +x ~/.claude/statusline.sh
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

### Step 3: Install Script in WSL
```bash
# Inside WSL
mkdir -p ~/.claude/
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

## 🎯 GNU Stow Integration (Recommended)

If you use [GNU Stow](https://www.gnu.org/software/stow/) for dotfiles management:

### Step 1: Add to Dotfiles Structure
```bash
# In your dotfiles repository
mkdir -p claude/.claude/
cd claude/.claude/

# Download script
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o statusline.sh
chmod +x statusline.sh
```

### Step 2: Stow the Configuration
```bash
# From your dotfiles root directory
stow claude

# This creates symlink: ~/.claude/statusline.sh -> dotfiles/claude/.claude/statusline.sh
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

## 🧪 Testing Installation

### Basic Test
```bash
# Test script with minimal input
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test Model"}}' | ~/.claude/statusline.sh
```

### Full Feature Test
```bash
# Test with ccusage (if configured)
cd ~/some-git-repo
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Sonnet 4"}}' | ~/.claude/statusline.sh
```

### Expected Output
You should see 3-4 lines of formatted output with colors and status information.

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
1. Reduce timeouts in script configuration
2. Check network connectivity for MCP/ccusage calls
3. Disable features: Set `CONFIG_SHOW_MCP_STATUS=false`

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

After successful installation:

1. 🎨 **Customize your theme** - Edit `CONFIG_THEME` in the script
2. ⚙️ **Configure features** - Enable/disable sections as needed
3. 💰 **Set up cost tracking** - Configure ccusage with your API keys
4. 📝 **Read the docs** - Explore [configuration.md](configuration.md) and [themes.md](themes.md)

---

**Installation complete!** Your Claude Code statusline should now display rich information about your development environment.