# ⚙️ Configuration Guide

Complete guide to customizing your Claude Code Enhanced Statusline with themes, colors, features, and advanced options.

## 🎨 Theme Configuration

### Quick Theme Selection

The easiest way to customize appearance is using predefined themes:

```bash
# Edit the script file
vi ~/.claude/statusline.sh

# Find this line (around line 34):
CONFIG_THEME="catppuccin"

# Change to your preferred theme:
CONFIG_THEME="classic"     # Traditional terminal colors
CONFIG_THEME="garden"      # Soft pastel colors  
CONFIG_THEME="catppuccin"  # Catppuccin Mocha theme
CONFIG_THEME="custom"      # Manual color configuration
```

### Theme Details

#### Classic Theme
- **Style**: Traditional ANSI terminal colors
- **Compatibility**: Works on all terminals
- **Best for**: Users who prefer standard terminal appearance

#### Garden Theme  
- **Style**: Soft pastel colors with RGB values
- **Compatibility**: Modern terminals with RGB support
- **Best for**: Users who want a gentle, soothing interface

#### Catppuccin Theme
- **Style**: Official [Catppuccin Mocha](https://catppuccin.com/) colors
- **Compatibility**: Modern terminals with RGB support
- **Best for**: Catppuccin theme enthusiasts

## 🎯 Custom Color Configuration

For complete control, set `CONFIG_THEME="custom"` and modify individual color variables:

### Basic Colors (ANSI Standard)
```bash
CONFIG_RED='\033[31m'       # Used for: mode info
CONFIG_BLUE='\033[34m'      # Used for: directory path
CONFIG_GREEN='\033[32m'     # Used for: clean git status, repo costs
CONFIG_YELLOW='\033[33m'    # Used for: dirty git status
CONFIG_MAGENTA='\033[35m'   # Used for: git branch
CONFIG_CYAN='\033[36m'      # Used for: model name
CONFIG_WHITE='\033[37m'     # Used for: general text
```

### Extended Colors
```bash
CONFIG_ORANGE='\033[38;5;208m'       # Used for: time display
CONFIG_LIGHT_ORANGE='\033[38;5;215m' # Used for: clock emoji
CONFIG_LIGHT_GRAY='\033[38;5;248m'   # Used for: reset info
CONFIG_BRIGHT_GREEN='\033[92m'       # Used for: MCP servers, submodules
CONFIG_PURPLE='\033[95m'             # Used for: Claude version
CONFIG_TEAL='\033[38;5;73m'          # Used for: commits, daily costs
CONFIG_GOLD='\033[38;5;220m'         # Used for: special highlights
CONFIG_PINK_BRIGHT='\033[38;5;205m'  # Used for: 30-day costs
CONFIG_INDIGO='\033[38;5;105m'       # Used for: 7-day costs
CONFIG_VIOLET='\033[38;5;99m'        # Used for: session info
CONFIG_LIGHT_BLUE='\033[38;5;111m'   # Used for: MCP server names
```

### Text Formatting
```bash
CONFIG_DIM='\033[2m'           # Used for: separators, dimmed text
CONFIG_ITALIC='\033[3m'        # Used for: reset info
CONFIG_STRIKETHROUGH='\033[9m' # Used for: offline MCP servers
CONFIG_RESET='\033[0m'         # Used for: reset all formatting
```

### Color System Options

#### ANSI Standard (30-37, 90-97)
Most compatible, works on all terminals:
```bash
CONFIG_RED='\033[31m'    # Basic red
CONFIG_RED='\033[91m'    # Bright red
```

#### 256-Color Palette (38;5;N)
Better colors, widely supported:
```bash
CONFIG_RED='\033[38;5;196m'    # Bright red (color 196)
CONFIG_BLUE='\033[38;5;21m'    # Bright blue (color 21)
```

#### RGB True Color (38;2;R;G;B)
Full color range, modern terminals only:
```bash
CONFIG_RED='\033[38;2;255;0;0m'      # Pure red
CONFIG_BLUE='\033[38;2;0;0;255m'     # Pure blue
```

#### Background Colors
Replace '38' with '48' for background colors:
```bash
CONFIG_RED='\033[48;5;196m'          # Red background
CONFIG_BLUE='\033[48;2;0;0;255m'     # RGB blue background
```

## 🔧 Feature Configuration

### Feature Toggles
Enable or disable entire sections:

```bash
# Repository information
CONFIG_SHOW_COMMITS=true        # Show daily commit count
CONFIG_SHOW_VERSION=true        # Show Claude Code version
CONFIG_SHOW_SUBMODULES=true     # Show git submodule count

# Cost and monitoring
CONFIG_SHOW_COST_TRACKING=true  # Show ccusage cost information
CONFIG_SHOW_MCP_STATUS=true     # Show MCP server status
CONFIG_SHOW_RESET_INFO=true     # Show billing block reset timer
CONFIG_SHOW_SESSION_INFO=true   # Show session information
```

### Performance Configuration

#### Timeouts
Prevent hanging on slow networks:

```bash
CONFIG_MCP_TIMEOUT="3s"        # MCP server status check timeout
CONFIG_VERSION_TIMEOUT="2s"    # Claude version check timeout  
CONFIG_CCUSAGE_TIMEOUT="3s"    # Cost tracking timeout
```

#### Caching
Improve performance with intelligent caching:

```bash
CONFIG_VERSION_CACHE_DURATION=3600        # Cache Claude version for 1 hour
CONFIG_VERSION_CACHE_FILE="/tmp/.claude_version_cache"  # Cache file location
```

## 📝 Display Customization

### Time and Date Formats
```bash
CONFIG_TIME_FORMAT="%H:%M"              # 24-hour format (14:30)
# CONFIG_TIME_FORMAT="%I:%M %p"         # 12-hour format (2:30 PM)

CONFIG_DATE_FORMAT="%Y-%m-%d"           # ISO format (2024-08-18)
CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"     # Compact format (20240818)
```

### Model Emojis
Customize emojis for different Claude models:

```bash
CONFIG_OPUS_EMOJI="🧠"      # Claude Opus
CONFIG_HAIKU_EMOJI="⚡"     # Claude Haiku
CONFIG_SONNET_EMOJI="🎵"    # Claude Sonnet
CONFIG_DEFAULT_MODEL_EMOJI="🤖"  # Other models
```

### Status Emojis
```bash
CONFIG_CLEAN_STATUS_EMOJI="✅"    # Clean git repository
CONFIG_DIRTY_STATUS_EMOJI="📁"    # Dirty git repository
CONFIG_CLOCK_EMOJI="🕐"           # Time display
CONFIG_LIVE_BLOCK_EMOJI="🔥"      # Active billing block
```

### Display Labels
Customize all text labels:

```bash
CONFIG_COMMITS_LABEL="Commits:"
CONFIG_REPO_LABEL="REPO"
CONFIG_MONTHLY_LABEL="30DAY"
CONFIG_WEEKLY_LABEL="7DAY"
CONFIG_DAILY_LABEL="DAY"
CONFIG_SUBMODULE_LABEL="SUB:"
CONFIG_MCP_LABEL="MCP"
CONFIG_VERSION_PREFIX="ver"
CONFIG_SESSION_PREFIX="S:"
CONFIG_LIVE_LABEL="LIVE"
CONFIG_RESET_LABEL="RESET"
```

### Error Messages
Customize fallback messages:

```bash
CONFIG_NO_CCUSAGE_MESSAGE="No ccusage"
CONFIG_CCUSAGE_INSTALL_MESSAGE="Install ccusage for cost tracking"
CONFIG_NO_ACTIVE_BLOCK_MESSAGE="No active block"
CONFIG_MCP_UNKNOWN_MESSAGE="unknown"
CONFIG_MCP_NONE_MESSAGE="none"
CONFIG_UNKNOWN_VERSION="?"
CONFIG_NO_SUBMODULES="--"
```

## 🎨 Creating Custom Themes

### Step 1: Set Custom Theme Mode
```bash
CONFIG_THEME="custom"
```

### Step 2: Define Your Color Palette
Create a cohesive color scheme:

```bash
# Example: Ocean Theme
CONFIG_BLUE='\033[38;2;0;119;190m'      # Ocean blue
CONFIG_TEAL='\033[38;2;0;150;136m'      # Teal green
CONFIG_CYAN='\033[38;2;0;188;212m'      # Light cyan
CONFIG_GREEN='\033[38;2;76;175;80m'     # Ocean green
CONFIG_YELLOW='\033[38;2;255;193;7m'    # Sandy yellow
CONFIG_RED='\033[38;2;244;67;54m'       # Coral red
CONFIG_PURPLE='\033[38;2;156;39;176m'   # Deep purple
CONFIG_ORANGE='\033[38;2;255;152;0m'    # Sunset orange
```

### Step 3: Test Your Theme
```bash
# Test with sample input
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test"}}' | ~/.claude/statusline.sh
```

### Step 4: Fine-tune Colors
Adjust individual color assignments based on your preferences and terminal capabilities.

## 🔍 Advanced Configuration

### Conditional Configuration
You can make configuration dynamic based on environment:

```bash
# Example: Different themes for different environments
if [[ "$USER" == "production" ]]; then
    CONFIG_THEME="classic"
elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    CONFIG_THEME="catppuccin" 
else
    CONFIG_THEME="garden"
fi
```

### Environment-Based Settings
```bash
# Adjust timeouts based on network conditions
if [[ -n "$SLOW_NETWORK" ]]; then
    CONFIG_MCP_TIMEOUT="10s"
    CONFIG_CCUSAGE_TIMEOUT="10s"
fi
```

### Platform-Specific Configuration
```bash
# macOS vs Linux differences
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific settings
    CONFIG_VERSION_CACHE_FILE="/tmp/.claude_version_cache"
else
    # Linux specific settings  
    CONFIG_VERSION_CACHE_FILE="/tmp/.claude_version_cache"
fi
```

## 📊 Performance Optimization

### Reducing Latency
1. **Disable unused features**:
   ```bash
   CONFIG_SHOW_MCP_STATUS=false    # Skip MCP checks
   CONFIG_SHOW_COST_TRACKING=false # Skip cost tracking
   ```

2. **Reduce timeouts**:
   ```bash
   CONFIG_MCP_TIMEOUT="1s"
   CONFIG_CCUSAGE_TIMEOUT="1s"
   ```

3. **Increase cache duration**:
   ```bash
   CONFIG_VERSION_CACHE_DURATION=7200  # Cache for 2 hours
   ```

### Memory Usage
The script is lightweight, but you can minimize memory usage:

1. Use ANSI colors instead of RGB
2. Disable unused feature toggles
3. Reduce cache file size by clearing periodically

## 🐛 Troubleshooting Configuration

### Colors Not Showing
1. **Check terminal support**:
   ```bash
   echo $TERM
   echo $COLORTERM
   ```

2. **Test basic colors**:
   ```bash
   echo -e "\033[31mRed\033[0m \033[32mGreen\033[0m \033[34mBlue\033[0m"
   ```

3. **Fall back to ANSI**:
   ```bash
   CONFIG_THEME="classic"  # Uses basic ANSI colors
   ```

### Performance Issues
1. **Check timeout settings**
2. **Disable network-dependent features**
3. **Clear cache files**:
   ```bash
   rm -f /tmp/.claude_version_cache
   ```

### Feature Not Working
1. **Check feature toggle**: Ensure `CONFIG_SHOW_*=true`
2. **Verify dependencies**: Check if required tools are installed
3. **Test individual components**: Run parts of the script manually

## 💡 Configuration Tips

1. **Start simple**: Begin with predefined themes
2. **Test incrementally**: Change one setting at a time  
3. **Backup originals**: Keep a copy of working configuration
4. **Document changes**: Comment your customizations
5. **Share themes**: Consider contributing new themes to the project

## 📚 Examples

See [examples/sample-configs/](../examples/sample-configs/) for ready-to-use configuration snippets and theme variations.

---

**Happy customizing!** Your statusline should now reflect your personal style and preferences.