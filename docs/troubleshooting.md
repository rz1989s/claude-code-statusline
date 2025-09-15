# 🐛 Troubleshooting Guide

**Common issues and solutions for Claude Code Enhanced Statusline with TOML Configuration.**

Comprehensive troubleshooting for installation, TOML configuration, themes, performance, and advanced features.

> 🏗️ **Modular Architecture**: The statusline now uses a modular architecture with the main script at `~/.claude/statusline.sh` and 9 modules in `~/.claude/lib/`. This section includes troubleshooting for both the main script and module-related issues.

## 🔧 Installation Issues

### `jq: command not found`

**Problem**: The `jq` JSON processor is not installed.

**Solutions**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt update && sudo apt install jq

# RHEL/CentOS/Fedora
sudo yum install jq  # or sudo dnf install jq

# Arch Linux
sudo pacman -S jq
```

**Verification**:
```bash
jq --version
```

---

### `gtimeout: command not found` (macOS)

**Problem**: GNU coreutils is not installed on macOS.

**Solution**:
```bash
# Install GNU coreutils
brew install coreutils

# Verify installation
gtimeout --version
```

**Note**: Modern statusline automatically handles timeout command detection and works without coreutils using runtime bash compatibility features.

---

## 🏗️ Modular Architecture Issues

### `FATAL ERROR: Core module not found`

**Problem**: The main script cannot find the required modules in `~/.claude/lib/`.

**Symptoms**:
```bash
$ ~/.claude/statusline.sh
FATAL ERROR: Core module not found at ~/.claude/lib/core.sh
Please ensure the lib/ directory is present with all required modules.
```

**Solutions**:
```bash
# Check if lib directory and modules exist
ls -la ~/.claude/lib/

# If missing, reinstall the modular statusline
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

### Module Loading Failures

**Problem**: Individual modules fail to load properly.

**Symptoms**:
```bash
$ ~/.claude/statusline.sh --modules
Loaded modules:
  ✓ core
  ✓ security
  ✗ config
Failed modules:
  config
```

**Diagnosis**:
```bash
# Check specific module file
ls -la ~/.claude/lib/config.sh

# Test module syntax
bash -n ~/.claude/lib/config.sh

# Enable debug mode to see detailed loading errors
STATUSLINE_DEBUG_MODE=true ~/.claude/statusline.sh --modules
```

**Solutions**:
```bash
# Re-download the specific failing module
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/lib/config.sh -o ~/.claude/lib/config.sh

# Verify module permissions
chmod 644 ~/.claude/lib/*.sh
```

### Version Mismatch Between Main Script and Modules

**Problem**: Main script and modules are from different versions.

**Symptoms**:
- Unexpected errors or behavior
- Functions not found
- Module loading warnings

**Solution**:
```bash
# Check versions
~/.claude/statusline.sh --version

# Reinstall both main script and all modules
curl -L https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# Download all modules (see above module reinstallation commands)
```

---

### `bunx ccusage --version` fails

**Problem**: Cost tracking tools are not properly installed.

**Solutions**:

1. **Check Node.js installation**:
   ```bash
   node --version
   npm --version
   ```

2. **Install/reinstall bunx**:
   ```bash
   npm install -g bunx
   npm install -g ccusage
   ```

3. **Clear npm cache**:
   ```bash
   npm cache clean --force
   npm install -g bunx ccusage
   ```

4. **Permission issues (Linux/macOS)**:
   ```bash
   sudo npm install -g bunx ccusage
   ```

---

## 🚀 **Dev6 Branch Issues**

### Enhanced Settings.json Management

**New in Dev6**: The `--preserve-statusline` flag allows installation without modifying Claude Code settings.json.

#### Installation Options

```bash
# Standard dev6 installation (configures settings.json)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6

# Preserve existing settings.json (skip Claude Code configuration)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6 --preserve-statusline
```

#### Settings.json Issues

**Problem**: Installation modifies settings.json unexpectedly.

**Solutions**:
1. **Use preserve flag during installation**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6 --preserve-statusline
   ```

2. **Restore from automatic backup**:
   ```bash
   # Dev6 creates timestamped backups automatically
   ls ~/.claude/settings.json.backup.*
   cp ~/.claude/settings.json.backup.YYYYMMDD_HHMMSS ~/.claude/settings.json
   ```

3. **Manual settings.json configuration**:
   ```json
   {
     "statusLine": "bash ~/.claude/statusline/statusline.sh"
   }
   ```

**Problem**: Backup files accumulating over multiple installations.

**Solution**: Dev6 creates timestamped backups to prevent overwriting previous backups.
```bash
# Clean old backups if needed (optional)
find ~/.claude -name "settings.json.backup.*" -mtime +30 -delete
```

---

## 📋 **TOML Configuration Issues**

> **Note**: The examples below use `./statusline.sh` for project directory usage. If you're using the installed statusline, replace with `~/.claude/statusline.sh`.

The enterprise-grade TOML configuration system requires proper syntax and structure. Here are common configuration-related issues and solutions.

### TOML File Not Found

**Problem**: Configuration file is not being discovered or loaded.

**Diagnosis**:
```bash
# Check configuration discovery
./statusline.sh # Configuration is automatically loaded-verbose

# Expected output shows which config file is loaded:
# Loading configuration from: ./Config.toml
# Configuration loaded successfully
```

**Solutions**:

1. **Generate missing configuration**:
   ```bash
   # Generate Config.toml in current directory
   cp examples/Config.toml ./Config.toml
   
   # Or generate in specific location
   cp examples/Config.toml ./Config.toml ~/.config/claude-code-statusline/Config.toml
   ```

2. **Check configuration discovery order**:
   ```bash
   # Configuration is searched in this order:
   # 1. ./Config.toml (highest priority)
   # 2. ~/.config/claude-code-statusline/Config.toml
   # 3. ~/.claude-statusline.toml
   # 4. Inline configuration (fallback)
   ```

3. **Verify file permissions**:
   ```bash
   # Check if file is readable
   ls -la Config.toml
   
   # Should show readable permissions:
   # -rw-r--r-- 1 user group 1234 Config.toml
   
   # Fix permissions if needed
   chmod 644 Config.toml
   ```

---

### TOML Syntax Errors

**Problem**: Configuration file has invalid TOML syntax.

**Diagnosis**:
```bash
# Validate TOML syntax
./statusline.sh --validate-config

# Common error messages:
# ERROR: TOML parsing failed at line 15
# ERROR: Invalid value for key 'theme'
```

**Common Syntax Issues**:

1. **Unquoted string values**:
   ```toml
   # ❌ Incorrect:
   [theme]
   name = catppuccin
   
   # ✅ Correct:
   [theme]
   name = "catppuccin"
   ```

2. **Boolean value errors**:
   ```toml
   # ❌ Incorrect:
   [features]
   show_commits = yes
   show_version = 1
   
   # ✅ Correct:
   [features]
   show_commits = true
   show_version = false
   ```

3. **Section header typos**:
   ```toml
   # ❌ Incorrect:
   [color.basic]  # Missing 's'
   
   # ✅ Correct:
   [colors.basic]
   ```

4. **Color code escaping**:
   ```toml
   # ❌ Incorrect:
   [colors.basic]
   red = \033[31m
   
   # ✅ Correct:
   [colors.basic]
   red = "\\033[31m"  # Escaped backslashes and quoted
   ```

**Solutions**:
```bash
# 1. Use validation command
./statusline.sh --validate-config

# 2. Regenerate configuration if heavily corrupted
cp examples/Config.toml ./Config.toml Config-backup.toml
# Then copy working sections to your Config.toml

# 3. Test incrementally
./statusline.sh # Configuration is automatically loaded
```

---

### Environment Variable Overrides Not Working

**Problem**: ENV_CONFIG_* variables are not overriding TOML settings.

**Diagnosis**:
```bash
# Test environment override
ENV_CONFIG_THEME=garden ./statusline.sh # Configuration is automatically loaded

# Should show:
# Theme: garden (environment override)
# If not working, shows:
# Theme: catppuccin (from Config.toml)
```

**Solutions**:

1. **Check variable naming**:
   ```bash
   # ✅ Correct format:
   ENV_CONFIG_THEME=garden ./statusline.sh
   ENV_CONFIG_SHOW_MCP_STATUS=false ./statusline.sh
   
   # ❌ Incorrect (missing ENV_ prefix):
   CONFIG_THEME=garden ./statusline.sh
   ```

2. **Verify variable values**:
   ```bash
   # Boolean values must be lowercase
   ENV_CONFIG_SHOW_COMMITS=true ./statusline.sh   # ✅ Correct
   ENV_CONFIG_SHOW_COMMITS=TRUE ./statusline.sh   # ❌ Incorrect
   ENV_CONFIG_SHOW_COMMITS=false ./statusline.sh  # ✅ Correct
   ENV_CONFIG_SHOW_COMMITS=FALSE ./statusline.sh  # ❌ Incorrect
   ```

3. **Test override isolation**:
   ```bash
   # Test one variable at a time
   ENV_CONFIG_THEME=classic ./statusline.sh # Configuration is automatically loaded
   ENV_CONFIG_SHOW_COST_TRACKING=false ./statusline.sh # Configuration is automatically loaded
   ```

---

### Configuration Not Taking Effect

**Problem**: Changes to Config.toml are not reflected in statusline output.

**Diagnosis**:
```bash
# Test configuration loading
./statusline.sh # Configuration is automatically loaded-verbose

# Compare configurations
./statusline.sh --compare-config

# Check if correct file is loaded
ls -la Config.toml ~/.config/claude-code-statusline/Config.toml ~/.claude-statusline.toml
```

**Solutions**:

1. **Verify correct file location**:
   ```bash
   # Check which config file has highest priority in your directory
   pwd
   ls -la Config.toml  # This takes highest priority if it exists
   ```

2. **Test specific configuration file**:
   ```bash
   # Test specific config file explicitly
   ./statusline.sh # Configuration is automatically loaded ./Config.toml
   ./statusline.sh # Configuration is automatically loaded ~/.config/claude-code-statusline/Config.toml
   ```

3. **Clear cache if applicable**:
   ```bash
   # Clear version cache that might be interfering
   rm -f /tmp/.claude_version_cache
   ```

---

## 🔧 **Bash Compatibility Issues (Auto-Resolved)**

### Bash Version Compatibility 

**Previous Issue**: Statusline required modern bash (4.0+) but many systems have older bash.

**✅ Now Auto-Resolved**: The statusline now includes **universal bash compatibility**:

**Automatic Features:**
- **Runtime Detection**: Automatically finds and uses modern bash if available
- **Graceful Fallback**: Works with old bash (3.2+) in compatibility mode
- **Universal macOS Support**: Works across all Mac configurations without manual intervention

**What Happens Automatically:**
```bash
# Old bash detected -> automatic upgrade attempt
[INFO] Bash 3.2.57 detected, searching for modern bash...
[INFO] Found modern bash: /opt/homebrew/bin/bash
[INFO] Re-executing with modern bash for full functionality

# Or graceful fallback if no modern bash available
[WARN] Bash 3.2.57 detected. Advanced caching features disabled.
[INFO] For full functionality, install bash 4+: brew install bash
```

**No Action Required**: This happens automatically - no configuration needed!

---

## 🎨 **Theme and Display Issues**

### Colors Not Displaying Properly

**Problem**: Theme colors are not showing or appearing incorrectly.

**Diagnosis**:
```bash
# Check terminal capabilities
echo $TERM
echo $COLORTERM

# Test basic ANSI colors
echo -e "\\033[31mRed\\033[0m \\033[32mGreen\\033[0m \\033[34mBlue\\033[0m"

# Test theme loading
./statusline.sh # Configuration is automatically loaded-verbose
```

**Solutions**:

1. **Terminal compatibility**:
   ```bash
   # For terminals with limited color support
   [theme]
   name = "classic"  # Uses basic ANSI colors only
   ```

2. **RGB color issues**:
   ```bash
   # If RGB colors don't work, check COLORTERM
   echo $COLORTERM  # Should show 'truecolor' or '24bit'
   
   # Fallback to 256-color palette
   [colors.extended]
   red = "\\033[38;5;196m"  # 256-color instead of RGB
   ```

3. **Color code validation**:
   ```toml
   # Ensure proper escaping
   [colors.basic]
   red = "\\033[31m"        # ✅ Correct: escaped backslashes
   blue = "\033[34m"        # ❌ Incorrect: single backslash
   ```

---

### Custom Theme Not Loading

**Problem**: Custom theme colors are not being applied.

**Diagnosis**:
```bash
# Verify theme configuration
./statusline.sh # Configuration is automatically loaded-verbose | grep -i theme

# Check custom theme syntax
./statusline.sh --validate-config
```

**Solutions**:

1. **Verify custom theme structure**:
   ```toml
   # Required for custom themes
   [theme]
   name = "custom"  # Must be exactly "custom"
   
   # Required color sections
   [colors.basic]
   red = "\\033[31m"
   # ... other basic colors
   
   [colors.extended]
   orange = "\\033[38;5;208m"
   # ... other extended colors
   ```

2. **Test theme incrementally**:
   ```bash
   # Test with simple custom theme first
   cat > TestTheme.toml << 'EOF'
   [theme]
   name = "custom"
   
   [colors.basic]
   red = "\\033[91m"
   green = "\\033[92m"
   blue = "\\033[94m"
   EOF
   
   ./statusline.sh # Configuration is automatically loaded TestTheme.toml
   ```

---

### Emoji Display Issues

**Problem**: Emojis are not displaying correctly or appear as question marks.

**Diagnosis**:
```bash
# Test emoji support
echo "🎵 🧠 ⚡ ✅ 📁"

# Check locale settings
echo $LC_ALL
echo $LANG
```

**Solutions**:

1. **Terminal emoji support**:
   ```bash
   # For terminals without emoji support
   [emojis]
   clean_status = "+"       # Simple ASCII
   dirty_status = "!"       # Simple ASCII
   opus = "O"               # Letter indicators
   sonnet = "S"
   haiku = "H"
   ```

2. **Font configuration**:
   - Ensure terminal uses font with emoji support
   - Popular choices: SF Mono, Fira Code, JetBrains Mono

---

## ⚡ **Performance Issues**

### Slow Startup or Hanging

**Problem**: Statusline takes too long to load or hangs during execution.

**Diagnosis**:
```bash
# Time the execution
time ./statusline.sh

# Test with verbose output to see where it hangs
./statusline.sh # Configuration is automatically loaded-verbose
```

**Solutions**:

1. **Reduce timeouts via TOML**:
   ```toml
   [timeouts]
   mcp = "1s"           # Reduce from default 3s
   ccusage = "1s"       # Reduce from default 3s
   version = "1s"       # Reduce from default 2s
   ```

2. **Disable network-dependent features**:
   ```toml
   [features]
   show_mcp_status = false      # Disable MCP server checks
   show_cost_tracking = false   # Disable ccusage calls
   show_version = false         # Disable version checks
   ```

3. **Environment variable quick fixes**:
   ```bash
   # Temporarily disable features
   ENV_CONFIG_SHOW_MCP_STATUS=false \
   ENV_CONFIG_SHOW_COST_TRACKING=false \
   ENV_CONFIG_MCP_TIMEOUT=1s \
   ./statusline.sh
   ```

4. **Use minimal configuration**:
   ```bash
   # Copy minimal config for performance
   cp examples/sample-configs/minimal-config.toml Config.toml
   ./statusline.sh # Configuration is automatically loaded
   ```

---

### Network-Related Timeouts

**Problem**: Network operations (MCP, ccusage, version checks) are timing out.

**Diagnosis**:
```bash
# Test network connectivity
curl -s --max-time 3 https://api.anthropic.com || echo "Network issue"

# Test individual components
bunx ccusage --version
```

**Solutions**:

1. **Increase timeouts for slow networks**:
   ```toml
   [timeouts]
   mcp = "10s"          # Increase for slow networks
   ccusage = "8s"       # Increase for API delays
   version = "5s"       # Increase for slow connections
   ```

2. **Configure network-specific settings**:
   ```toml
   [performance]
   network_operation_timeout = "15s"  # Global network timeout
   max_concurrent_operations = 1      # Reduce concurrency
   ```

3. **Proxy configuration** (if behind corporate proxy):
   ```bash
   # Set proxy environment variables before running
   export HTTP_PROXY=http://proxy:8080
   export HTTPS_PROXY=https://proxy:8080
   ./statusline.sh
   ```

---

## 🔧 **Advanced Troubleshooting**

### Debug Mode

**Problem**: Need detailed information about statusline execution.

**Solutions**:
```bash
# Enable bash debug mode
bash -x ~/.claude/statusline/statusline.sh

# Use verbose configuration testing
./statusline.sh # Configuration is automatically loaded-verbose

# Check specific configuration sections
./statusline.sh --compare-config
```

---

### Configuration Conflicts

**Problem**: Multiple configuration sources are conflicting.

**Diagnosis**:
```bash
# Check configuration priority
./statusline.sh # Configuration is automatically loaded-verbose | grep -i "loading\|config\|override"

# List all potential config files
ls -la Config.toml ~/.config/claude-code-statusline/Config.toml ~/.claude-statusline.toml
```

**Solutions**:

1. **Clear configuration precedence**:
   ```bash
   # Remove lower-priority configs to avoid confusion
   rm -f ~/.claude-statusline.toml  # Remove if not needed
   ```

2. **Test configuration isolation**:
   ```bash
   # Test with only one config source
   mv Config.toml Config.toml.backup
   cp examples/Config.toml ./Config.toml Config.toml
   ./statusline.sh # Configuration is automatically loaded
   ```

---

### Cache-Related Issues

**Problem**: Cached data is stale or causing incorrect display.

**Solutions**:
```bash
# Clear all caches
rm -f /tmp/.claude_version_cache
rm -f /tmp/.claude_*_cache

# Disable caching temporarily
ENV_CONFIG_VERSION_CACHE_DURATION=0 ./statusline.sh

# Or configure cache duration in TOML
[cache]
version_duration = 0    # Disable caching
```

---

## 💊 **Common Solutions Summary**

### Quick Fixes

```bash
# 1. Regenerate configuration
cp examples/Config.toml ./Config.toml

# 2. Test configuration
./statusline.sh # Configuration is automatically loaded

# 3. Validate syntax
./statusline.sh --validate-config

# 4. Use minimal config for debugging
cp examples/sample-configs/minimal-config.toml Config.toml

# 5. Clear caches
rm -f /tmp/.claude_*_cache

# 6. Test with environment overrides
ENV_CONFIG_THEME=classic ENV_CONFIG_SHOW_COST_TRACKING=false ./statusline.sh
```

### Systematic Debugging Approach

```bash
# 1. Check dependencies
jq --version && echo "jq OK" || echo "jq MISSING"
gtimeout --version && echo "gtimeout OK" || echo "gtimeout MISSING"

# 2. Test basic functionality
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test"}}' | ./statusline.sh

# 3. Test configuration loading
./statusline.sh # Configuration is automatically loaded-verbose

# 4. Isolate issues
ENV_CONFIG_SHOW_MCP_STATUS=false ENV_CONFIG_SHOW_COST_TRACKING=false ./statusline.sh

# 5. Check logs (if available)
cat ~/.cache/claude-code-statusline/statusline.log
```

---

### Script not executable

**Problem**: Permission denied when running the script.

**Solution**:
```bash
chmod +x ~/.claude/statusline/statusline.sh
```

## 🎨 Display Issues

### Colors not showing properly

**Problem**: Terminal doesn't display colors correctly.

**Solutions**:

1. **Check terminal color support**:
   ```bash
   echo $TERM
   echo $COLORTERM
   ```

2. **Test basic colors**:
   ```bash
   echo -e "\033[31mRed\033[0m \033[32mGreen\033[0m \033[34mBlue\033[0m"
   ```

3. **Switch to compatible theme**:
   ```bash
   # Edit script and set:
   CONFIG_THEME="classic"
   ```

4. **Force terminal color support** (if needed):
   ```bash
   export TERM=xterm-256color
   ```

---

### Text appears garbled or with escape codes

**Problem**: Terminal doesn't interpret ANSI escape codes.

**Example output**:
```
\033[34m~/dotfiles\033[0m \033[32m(main)\033[0m
```

**Solutions**:

1. **Check terminal compatibility**:
   ```bash
   echo -e "This should be \033[31mred\033[0m"
   ```

2. **Update terminal application**:
   - macOS: Update Terminal.app or try iTerm2
   - Linux: Try different terminal emulator
   - Windows: Use modern terminal or WSL

3. **Use minimal theme**:
   ```bash
   # Set in script
   CONFIG_THEME="classic"
   ```

---

### Emojis not displaying

**Problem**: Terminal doesn't support Unicode emojis.

**Solutions**:

1. **Install emoji fonts**:
   ```bash
   # macOS: Usually pre-installed
   # Linux: Install emoji fonts
   sudo apt install fonts-noto-emoji  # Ubuntu/Debian
   ```

2. **Disable emojis** (edit script):
   ```bash
   CONFIG_CLEAN_STATUS_EMOJI="[OK]"
   CONFIG_DIRTY_STATUS_EMOJI="[MOD]"
   CONFIG_CLOCK_EMOJI=""
   CONFIG_LIVE_BLOCK_EMOJI="[LIVE]"
   ```

## ⚡ Performance Issues

### Script is slow or hangs

**Problem**: Network calls or commands are timing out.

**Solutions**:

1. **Check timeout settings** (edit script):
   ```bash
   CONFIG_MCP_TIMEOUT="1s"        # Reduce from 3s
   CONFIG_VERSION_TIMEOUT="1s"    # Reduce from 2s
   CONFIG_CCUSAGE_TIMEOUT="1s"    # Reduce from 3s
   ```

2. **Disable network-dependent features**:
   ```bash
   CONFIG_SHOW_MCP_STATUS=false
   CONFIG_SHOW_COST_TRACKING=false
   ```

3. **Clear cache files**:
   ```bash
   rm -f /tmp/.claude_version_cache
   ```

4. **Check network connectivity**:
   ```bash
   curl -I https://ccusage.com
   claude mcp list
   ```

---

### High memory usage

**Problem**: Script uses too much memory.

**Solutions**:

1. **Disable unused features**:
   ```bash
   CONFIG_SHOW_COMMITS=false
   CONFIG_SHOW_SUBMODULES=false
   ```

2. **Use ANSI colors** instead of RGB:
   ```bash
   CONFIG_THEME="classic"
   ```

3. **Reduce cache duration**:
   ```bash
   CONFIG_VERSION_CACHE_DURATION=60  # 1 minute instead of 1 hour
   ```

## 💰 Cost Tracking Issues

### "No ccusage" message appears

**Problem**: ccusage is not installed or configured.

**Solutions**:

1. **Install ccusage**:
   ```bash
   npm install -g bunx ccusage
   ```

2. **Configure ccusage**:
   ```bash
   # Follow ccusage setup instructions
   bunx ccusage --help
   ```

3. **Disable cost tracking** (if not needed):
   ```bash
   CONFIG_SHOW_COST_TRACKING=false
   ```

---

### Cost information shows "$0.00" for everything

**Problem**: ccusage is not properly configured with API credentials.

**Solutions**:

1. **Check ccusage configuration**:
   ```bash
   bunx ccusage session --help
   ```

2. **Verify API credentials**: Follow ccusage documentation for setup

3. **Test ccusage manually**:
   ```bash
   bunx ccusage daily --since "7 days ago"
   ```

---

### Reset Timer Shows "waiting API response..."

**Problem**: The reset timer displays "waiting API response..." instead of countdown.

**Expected Behavior**: This is **normal behavior** when ccusage API is calculating billing projections.

**When This Happens**:
- Fresh Claude Code session startup (API still calculating projections)
- Network delays in API responses
- ccusage service temporarily processing billing data

**Display States**:
```bash
RESET at 06.00 (4h 15m left)           # ✅ Normal: API has projection data
RESET at 06.00 (waiting API response...) # ⏳ Normal: API calculating projections
(No Line 4 displayed)                    # ✅ Normal: No active billing block
```

**Solutions** (Only if persistently stuck):

1. **Wait a moment**: Usually resolves within 10-30 seconds
2. **Test ccusage directly**:
   ```bash
   ccusage blocks --json | jq '.blocks[] | select(.isActive == true) | .projection.remainingMinutes'
   ```
3. **Check network connectivity**:
   ```bash
   curl -s --max-time 5 https://api.anthropic.com
   ```
4. **Increase timeout if slow network**:
   ```toml
   [timeouts]
   ccusage = "10s"  # Increase from default 8s
   ```

**Note**: This enhancement replaced the confusing "0m left" message that previously appeared during API delays.

## 🔗 MCP Server Issues

### "MCP (?/?)" shows unknown status

**Problem**: Cannot connect to MCP servers or Claude CLI.

**Solutions**:

1. **Check Claude CLI installation**:
   ```bash
   claude --version
   ```

2. **Test MCP connection**:
   ```bash
   claude mcp list
   ```

3. **Increase timeout**:
   ```bash
   CONFIG_MCP_TIMEOUT="10s"
   ```

4. **Disable MCP monitoring**:
   ```bash
   CONFIG_SHOW_MCP_STATUS=false
   ```

---

### MCP servers show as offline when they're online

**Problem**: Timeout or parsing issues with MCP status.

**Solutions**:

1. **Increase timeout**:
   ```bash
   CONFIG_MCP_TIMEOUT="5s"
   ```

2. **Test manually**:
   ```bash
   timeout 5s claude mcp list
   ```

3. **Check Claude CLI permissions**

## 📁 Git Repository Issues

### Git Branch/Status Not Displaying (Recently Fixed)

**Previous Issue**: Git branch and status information missing from statusline first line.

**✅ Now Auto-Fixed**: Recent update resolved cache function compatibility:
- **Root Cause**: Cache calls using `bash -c` wrappers where functions weren't available in subshells
- **Solution Applied**: Direct function calls in cache operations 
- **Result**: Git branch `(dev)` and status `✅` now display correctly

**If still experiencing issues**:
```bash
# Check git functionality directly
git branch && git status --porcelain

# Verify statusline git detection
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test"}}' | ~/.claude/statusline/statusline.sh
```

### Commit count always shows "0"

**Problem**: Git commands failing or not in a git repository.

**Solutions**:

1. **Verify git repository**:
   ```bash
   git status
   ```

2. **Check git permissions**:
   ```bash
   ls -la .git/
   ```

3. **Test git log command**:
   ```bash
   git log --since="today 00:00" --oneline
   ```

---

### Branch name not showing

**Problem**: Git branch detection failing.

**Solutions**:

1. **Check current branch**:
   ```bash
   git branch
   ```

2. **Verify git repository state**:
   ```bash
   git status
   ```

## 🛠️ Debug Mode

### Enable detailed debugging

**Problem**: Need to see what's happening inside the script.

**Solution**:
```bash
# Run with bash debug mode
bash -x ~/.claude/statusline/statusline.sh

# Or add to beginning of script temporarily:
set -x  # Enable debug output
```

### Test individual components

```bash
# Test git status detection
git diff --quiet && echo "Clean" || echo "Dirty"

# Test MCP status
timeout 3s claude mcp list

# Test ccusage
bunx ccusage daily --since "1 day ago" --json

# Test version cache
cat /tmp/.claude_version_cache
```

## 📝 Creating Debug Reports

When reporting issues, include:

1. **System information**:
   ```bash
   echo "OS: $(uname -s)"
   echo "Shell: $SHELL"
   echo "Terminal: $TERM"
   echo "Claude version: $(claude --version)"
   ```

2. **Dependency versions**:
   ```bash
   jq --version
   timeout --version  # or gtimeout --version
   node --version
   npm --version
   bunx ccusage --version
   ```

3. **Script configuration**:
   ```bash
   # Show current theme and key settings
   grep "CONFIG_THEME=" ~/.claude/statusline/statusline.sh
   grep "CONFIG_.*_TIMEOUT=" ~/.claude/statusline/statusline.sh
   ```

4. **Error output**:
   ```bash
   # Run with debug output
   bash -x ~/.claude/statusline/statusline.sh 2>&1 | head -50
   ```

## 🆘 Getting Help

1. **Check documentation**:
   - [Installation Guide](installation.md)
   - [Configuration Guide](configuration.md)
   - [Themes Guide](themes.md)

2. **Search existing issues**: Check GitHub issues for similar problems

3. **Create a detailed issue**:
   - Include system information
   - Provide error messages  
   - Describe expected vs actual behavior
   - Include debug output if relevant

4. **Community support**: Ask in project discussions or relevant forums

## 💡 Prevention Tips

1. **Keep dependencies updated**:
   ```bash
   brew update && brew upgrade  # macOS
   sudo apt update && sudo apt upgrade  # Linux
   npm update -g  # Node packages
   ```

2. **Regular maintenance**:
   ```bash
   # Clear old cache files
   find /tmp -name ".claude_*" -mtime +7 -delete
   ```

3. **Backup working configurations**:
   ```bash
   cp ~/.claude/statusline/statusline.sh ~/.claude/statusline/statusline.sh.backup
   ```

4. **Test after changes**: Always test the statusline after configuration changes

---

**Still having issues?** Please create a detailed issue report on GitHub with your system information and error messages.