# 🐛 Troubleshooting Guide

Common issues and solutions for Claude Code Enhanced Statusline.

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

**Alternative**: Edit the script to use `timeout` instead of `gtimeout`.

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

### Script not executable

**Problem**: Permission denied when running the script.

**Solution**:
```bash
chmod +x ~/.claude/statusline-enhanced.sh
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
bash -x ~/.claude/statusline-enhanced.sh

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
   grep "CONFIG_THEME=" ~/.claude/statusline-enhanced.sh
   grep "CONFIG_.*_TIMEOUT=" ~/.claude/statusline-enhanced.sh
   ```

4. **Error output**:
   ```bash
   # Run with debug output
   bash -x ~/.claude/statusline-enhanced.sh 2>&1 | head -50
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
   cp ~/.claude/statusline-enhanced.sh ~/.claude/statusline-enhanced.sh.backup
   ```

4. **Test after changes**: Always test the statusline after configuration changes

---

**Still having issues?** Please create a detailed issue report on GitHub with your system information and error messages.