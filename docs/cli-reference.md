# 🔧 CLI Reference - Complete Command Documentation

**Comprehensive reference for all Claude Code Enhanced Statusline command-line interface options.**

Master the powerful CLI tools that make TOML configuration management effortless and professional.

> 🏗️ **Modular Architecture**: The CLI is now powered by the refactored modular system with the main script at `~/.claude/statusline.sh` orchestrating 8 specialized modules in `~/.claude/lib/`.

## 🚀 **Overview**

The enhanced statusline provides a rich command-line interface for:

- **Configuration Generation** - Create TOML files from current settings
- **Testing & Validation** - Verify configuration syntax and functionality  
- **Live Management** - Interactive configuration management and reloading
- **Comparison & Analysis** - Compare different configuration sources
- **Backup & Restore** - Protect and recover configurations
- **Help & Documentation** - Built-in comprehensive help system

---

## 📋 **Command Syntax**

```bash
# From project directory
./statusline.sh [OPTION] [ARGUMENTS]

# Using installed modular statusline
~/.claude/statusline.sh [OPTION] [ARGUMENTS]
```

### Global Options

| Option | Description |
|--------|-------------|
| `--help` | Show comprehensive help information |
| `--quiet`, `-q` | Run without diagnostic messages |
| `--version` | Display statusline version information |

---

## 🎯 **Configuration Generation Commands**

### `--generate-config [FILENAME]`

**Purpose**: Generate TOML configuration file from current inline settings.

**Syntax**:

```bash
./statusline.sh --generate-config [filename]
```

**Examples**:

```bash
# Generate Config.toml in current directory
./statusline.sh --generate-config

# Generate with custom filename
./statusline.sh --generate-config MyTheme.toml

# Generate in XDG standard location
./statusline.sh --generate-config ~/.config/claude-code-statusline/Config.toml

# Generate in home directory
./statusline.sh --generate-config ~/.claude-statusline.toml
```

**Output**:

- Creates TOML file with all current configuration settings
- Preserves inline customizations in structured format
- Includes comments explaining each section
- Sets appropriate file permissions (644)

**Error Handling**:

- Creates parent directories if they don't exist
- Reports permission errors with helpful solutions
- Validates generated TOML syntax before writing

---

## ✅ **Testing and Validation Commands**

### `--test-config [FILENAME]`

**Purpose**: Test configuration file loading and functionality.

**Syntax**:

```bash
./statusline.sh --test-config [filename]
```

**Examples**:

```bash
# Test current configuration (auto-discovery)
./statusline.sh --test-config

# Test specific configuration file
./statusline.sh --test-config MyTheme.toml

# Test configuration from examples
./statusline.sh --test-config examples/sample-configs/developer-config.toml
```

**Output**:

```
✅ Configuration loaded successfully
Theme: catppuccin
Features: commits=true, version=true, mcp=true, cost_tracking=true
Timeouts: mcp=3s, version=2s, ccusage=3s
```

### `--test-config-verbose [FILENAME]`

**Purpose**: Detailed testing with comprehensive diagnostic information.

**Examples**:

```bash
# Verbose testing of current configuration
./statusline.sh --test-config-verbose

# Verbose testing of specific file
./statusline.sh --test-config-verbose work-config.toml
```

**Output**:

```
🔍 Configuration Discovery:
  Checking ./Config.toml ... ✅ Found
  Loading configuration from: ./Config.toml

📋 Configuration Details:
  Theme: catppuccin
  Show commits: true
  Show version: true  
  Show MCP status: true
  Show cost tracking: true
  MCP timeout: 3s
  Version timeout: 2s
  CCUsage timeout: 3s

🎨 Theme Details:
  Theme name: catppuccin
  Color system: RGB true color
  Emoji support: enabled

⚡ Performance:
  Configuration load time: 0.02s
  Cache enabled: true
  Cache duration: 3600s

✅ All tests passed
```

### `--validate-config [FILENAME]`

**Purpose**: Validate TOML syntax without running full tests.

**Examples**:

```bash
# Validate current configuration
./statusline.sh --validate-config

# Validate specific file
./statusline.sh --validate-config Config.toml
```

**Output**:

```
✅ Configuration validation passed
📊 Statistics:
  - 5 sections parsed
  - 23 configuration keys
  - 0 syntax errors
  - 0 warnings
```

**Error Output**:

```
❌ Configuration validation failed
🐛 Errors found:
  Line 15: Invalid value for 'show_commits': 'yes' (expected: true/false)
  Line 23: Missing quotes around string value: catppuccin
  Line 31: Unknown section: [colour.basic] (did you mean [colors.basic]?)

💡 Auto-fix suggestions:
  Line 15: Change 'yes' to 'true'
  Line 23: Change catppuccin to "catppuccin"
  Line 31: Change [colour.basic] to [colors.basic]
```

---

## 📊 **Comparison and Analysis Commands**

### `--compare-config`

**Purpose**: Compare inline configuration with TOML configuration.

**Syntax**:

```bash
./statusline.sh --compare-config
```

**Output**:

```
📋 Configuration Comparison:

Inline Configuration (fallback):
  Theme: catppuccin
  Show commits: true
  Show version: false
  MCP timeout: 3s

TOML Configuration (active):
  Theme: catppuccin  
  Show commits: true
  Show version: true ⚠️  DIFFERENT
  MCP timeout: 3s

🔍 Differences Found:
  ⚠️  show_version: inline=false, TOML=true
  
✅ TOML configuration takes priority
```

**Use Cases**:

- Verify migration from inline to TOML
- Debug configuration conflicts
- Understand which settings are active

---

## 🔄 **Live Management Commands**

### `--reload-config`

**Purpose**: Reload configuration without restarting statusline.

**Examples**:

```bash
# Reload current configuration
./statusline.sh --reload-config

# Test after changing Config.toml
vim Config.toml  # Make changes
./statusline.sh --reload-config
```

### `--reload-interactive`

**Purpose**: Interactive configuration management menu.

**Example**:

```bash
./statusline.sh --reload-interactive
```

**Interactive Menu**:

```
🎛️  Claude Code Statusline - Interactive Configuration

Current Configuration: ./Config.toml
Status: ✅ Valid

Options:
1) 🔄 Reload configuration
2) ✅ Test configuration  
3) 🎨 Switch theme (current: catppuccin)
4) ⚙️  Toggle features
5) ⏱️  Adjust timeouts
6) 💾 Save current settings
7) 📋 Show configuration summary
8) 🚪 Exit

Select option (1-8): _
```

### `--watch-config [SECONDS]`

**Purpose**: Watch configuration file for changes and auto-reload.

**Examples**:

```bash
# Watch with default 3-second interval
./statusline.sh --watch-config

# Watch with custom interval
./statusline.sh --watch-config 5

# Watch with verbose output
./statusline.sh --watch-config 2 --verbose
```

**Output**:

```
👀 Watching configuration file: ./Config.toml
⏱️  Check interval: 3 seconds
🎯 Press Ctrl+C to stop

[14:30:15] Configuration unchanged
[14:30:18] Configuration unchanged  
[14:30:21] 🔄 Configuration changed - reloading...
[14:30:21] ✅ Configuration reloaded successfully
[14:30:24] Configuration unchanged
```

---

## 💾 **Backup and Restore Commands**

### `--backup-config DIRECTORY`

**Purpose**: Backup current configuration to specified directory.

**Examples**:

```bash
# Backup to directory with timestamp
./statusline.sh --backup-config backups/

# Backup to specific directory
./statusline.sh --backup-config ~/statusline-backups/$(date +%Y%m%d)
```

**Output**:

```
💾 Backing up configuration...

📁 Backup directory: backups/20240819_143022/
📄 Files backed up:
  ✅ Config.toml -> backups/20240819_143022/Config.toml
  ✅ inline-config.txt -> backups/20240819_143022/inline-config.txt
  ✅ metadata.json -> backups/20240819_143022/metadata.json

✅ Backup completed successfully
🔗 Restore command: ./statusline.sh --restore-config backups/20240819_143022/
```

### `--restore-config DIRECTORY`

**Purpose**: Restore configuration from backup directory.

**Examples**:

```bash
# Restore from backup
./statusline.sh --restore-config backups/20240819_143022/

# List available backups first
ls backups/
./statusline.sh --restore-config backups/20240818_091544/
```

**Interactive Restore**:

```
🔄 Configuration Restore

Backup directory: backups/20240819_143022/
Backup date: 2024-08-19 14:30:22
Files found:
  📄 Config.toml (1.2KB)
  📄 inline-config.txt (850B)  
  📄 metadata.json (245B)

⚠️  This will overwrite your current Config.toml
Current Config.toml will be backed up as Config.toml.backup

Continue with restore? [y/N]: y

✅ Configuration restored successfully
🔄 Backup created: Config.toml.backup
```

---

## 🌍 **Environment Integration Commands**

### Environment Variable Testing

**Test Environment Overrides**:

```bash
# Test theme override
ENV_CONFIG_THEME=garden ./statusline.sh --test-config

# Test feature toggles
ENV_CONFIG_SHOW_COST_TRACKING=false ./statusline.sh --test-config

# Test multiple overrides
ENV_CONFIG_THEME=classic \
ENV_CONFIG_SHOW_MCP_STATUS=false \
ENV_CONFIG_MCP_TIMEOUT=1s \
./statusline.sh --test-config
```

**Environment Override Validation**:

```bash
# Show which environment variables would override TOML
ENV_CONFIG_THEME=garden ./statusline.sh --test-config-verbose

# Output shows:
# 🌍 Environment Overrides Active:
#   ENV_CONFIG_THEME=garden (overriding TOML: catppuccin)
```

---

## ℹ️ **Help and Information Commands**

### `--help`

**Purpose**: Display comprehensive help information.

**Examples**:

```bash
# General help
./statusline.sh --help

# Configuration-specific help
./statusline.sh --help config

# Theme-specific help  
./statusline.sh --help themes

# CLI command help
./statusline.sh --help commands
```

**Output Structure**:

```
🎨 Claude Code Enhanced Statusline - Help

SYNOPSIS:
    ./statusline.sh [OPTIONS] [ARGUMENTS]

DESCRIPTION:
    Enterprise-grade statusline with TOML configuration system.
    Provides beautiful, informative status display for Claude Code.

EXECUTION OPTIONS:
    --quiet, -q                 Run without diagnostic messages
    
CONFIGURATION COMMANDS:
    --generate-config [file]     Generate TOML config from current settings
    --test-config [file]         Test configuration loading and functionality
    --validate-config [file]     Validate TOML syntax
    --compare-config            Compare inline vs TOML configuration
    
MANAGEMENT COMMANDS:
    --reload-config             Reload configuration files
    --reload-interactive        Interactive configuration management
    --watch-config [seconds]    Watch config file for changes
    
BACKUP COMMANDS:
    --backup-config <dir>       Backup current configuration
    --restore-config <dir>      Restore from backup
    
INFORMATION:
    --help                      Show this help
    --version                   Show version information

EXAMPLES:
    # Generate TOML configuration
    ./statusline.sh --generate-config
    
    # Test configuration with verbose output
    ./statusline.sh --test-config-verbose
    
    # Interactive configuration management
    ./statusline.sh --reload-interactive

CONFIGURATION FILES:
    Configuration is loaded in this priority order:
    1. Environment variables (ENV_CONFIG_*)
    2. ./Config.toml (project-specific)
    3. ~/.config/claude-code-statusline/Config.toml (user-wide)
    4. ~/.claude-statusline.toml (home directory)
    5. Inline configuration (fallback)

DOCUMENTATION:
    📖 Configuration: docs/configuration.md
    🎨 Themes: docs/themes.md
    🚀 Migration: docs/migration.md
    🐛 Troubleshooting: docs/troubleshooting.md

For more detailed help: ./statusline.sh --help <topic>
```

---

## 🔇 **Quiet Mode Commands**

### `--quiet` / `-q`

**Purpose**: Run statusline without diagnostic messages for clean output.

**Use Cases**:

- **Production environments** - Clean output without debug information
- **Script integration** - When statusline is part of automation
- **CI/CD pipelines** - Reduced noise in build outputs
- **Background processing** - Silent operation

**Examples**:

```bash
# Run with quiet mode (full syntax)
./statusline.sh --quiet

# Run with quiet mode (short syntax)
./statusline.sh -q

# Perfect for Claude Code integration
{
  "statusLine": {
    "type": "command", 
    "command": "bash ~/.claude/statusline/statusline.sh --quiet"
  }
}
```

**What Gets Suppressed**:

- Configuration loading messages
- TOML validation warnings  
- Schema validation output
- Environment override notifications
- Debug output from parsing operations

**What Remains Visible**:

- The 4-line statusline output (unchanged)
- Critical error messages that affect functionality
- User-requested help or validation output

**Comparison**:

```bash
# Normal mode (with diagnostic messages)
$ ./statusline.sh
Loading configuration from: ./Config.toml
🔍 Validating TOML configuration schema...
✅ Configuration loaded successfully
[statusline output here]

# Quiet mode (clean output only)
$ ./statusline.sh --quiet
[statusline output here]
```

**Best Practices**:

- Use quiet mode in production Claude Code settings
- Combine with specific configurations: `ENV_CONFIG_THEME=classic ./statusline.sh --quiet`
- Test both modes during development to ensure functionality

### `--version`

**Purpose**: Display version and system information.

**Output**:

```
🎨 Claude Code Enhanced Statusline

Version: 2.0.0-TOML
Build: 2024-08-19 14:30:22
Configuration System: TOML v1.0

Features:
  ✅ TOML Configuration System
  ✅ Environment Variable Overrides  
  ✅ Multi-location Discovery
  ✅ Configuration Validation
  ✅ Interactive Management
  ✅ Live Reload
  ✅ Backup & Restore

Dependencies:
  ✅ jq: 1.6 (JSON processor)
  ✅ gtimeout: 9.1 (GNU coreutils)
  ⚠️  bunx: not found (cost tracking disabled)
  ⚠️  ccusage: not found (cost tracking disabled)

System:
  Platform: macOS 14.6.0
  Shell: bash 3.2.57
  Terminal: iTerm.app
  Colors: RGB true color (24-bit)

Configuration:
  Current config: ./Config.toml
  Status: ✅ Valid
  Theme: catppuccin
```

---

## 🔧 **Advanced CLI Features**

### Command Chaining

**Chain Multiple Commands**:

```bash
# Generate, test, and backup in sequence
./statusline.sh --generate-config && \
./statusline.sh --test-config && \
./statusline.sh --backup-config backups/

# Validate, test verbose, and compare
./statusline.sh --validate-config && \
./statusline.sh --test-config-verbose && \
./statusline.sh --compare-config
```

### Scripting Integration

**Example Integration Script**:

```bash
#!/bin/bash
# statusline-setup.sh - Automated statusline configuration

set -e

STATUSLINE="$HOME/.claude/statusline.sh"
CONFIG_DIR="$HOME/.config/claude-code-statusline"

echo "🎨 Setting up Claude Code Enhanced Statusline..."

# Create config directory
mkdir -p "$CONFIG_DIR"

# Generate base configuration
"$STATUSLINE" --generate-config "$CONFIG_DIR/Config.toml"

# Validate configuration  
if "$STATUSLINE" --validate-config "$CONFIG_DIR/Config.toml"; then
    echo "✅ Configuration generated and validated"
else
    echo "❌ Configuration validation failed"
    exit 1
fi

# Test configuration
if "$STATUSLINE" --test-config "$CONFIG_DIR/Config.toml"; then
    echo "✅ Configuration test passed"
else
    echo "❌ Configuration test failed"
    exit 1
fi

# Backup original
"$STATUSLINE" --backup-config "$HOME/.statusline-backups"

echo "🚀 Statusline setup completed successfully!"
```

### Exit Codes

**Standard Exit Codes**:

- `0` - Success
- `1` - General error  
- `2` - Configuration syntax error
- `3` - File not found
- `4` - Permission error
- `5` - Network timeout
- `6` - Validation failed

**Example Usage**:

```bash
# Check exit code in scripts
if ./statusline.sh --test-config; then
    echo "Configuration is valid"
else
    case $? in
        2) echo "Syntax error in configuration" ;;
        3) echo "Configuration file not found" ;;
        *) echo "Unknown error occurred" ;;
    esac
fi
```

---

## 🎯 **Common Command Patterns**

### Daily Development Workflow

```bash
# Morning setup
./statusline.sh --test-config                    # Verify config
ENV_CONFIG_THEME=garden ./statusline.sh         # Try different theme

# Project-specific configuration
cd ~/important-project
./statusline.sh --generate-config ./Config.toml  # Project-specific config
vim Config.toml                                  # Customize for project
./statusline.sh --test-config                    # Test changes

# End of day
./statusline.sh --backup-config ~/backups/      # Backup configurations
```

### Configuration Development

```bash
# Create and test new configuration
cp examples/sample-configs/developer-config.toml MyConfig.toml
vim MyConfig.toml                               # Customize
./statusline.sh --validate-config MyConfig.toml # Check syntax
./statusline.sh --test-config MyConfig.toml     # Test functionality
./statusline.sh --test-config-verbose MyConfig.toml # Detailed testing

# Compare with current
cp MyConfig.toml Config.toml
./statusline.sh --compare-config                # See differences
```

### Team Configuration Management

```bash
# Team lead: Create standard configuration
./statusline.sh --generate-config team-standard.toml
./statusline.sh --validate-config team-standard.toml
git add team-standard.toml
git commit -m "Add team statusline configuration"

# Team members: Deploy team configuration
git pull
cp team-standard.toml Config.toml
./statusline.sh --test-config
./statusline.sh --backup-config ~/.statusline-backups/
```

### Troubleshooting Workflow

```bash
# Systematic troubleshooting
./statusline.sh --validate-config               # Check syntax
./statusline.sh --test-config-verbose           # Detailed testing
./statusline.sh --compare-config                # Check precedence

# Reset to working state
./statusline.sh --restore-config ~/.statusline-backups/latest/

# Test with minimal config
cp examples/sample-configs/minimal-config.toml Config.toml
./statusline.sh --test-config
```

---

## 🔍 **Command Reference Quick Index**

### Configuration Generation

- `--generate-config [filename]` - Generate TOML from inline settings

### Testing & Validation  

- `--test-config [filename]` - Test configuration loading
- `--test-config-verbose [filename]` - Detailed configuration testing
- `--validate-config [filename]` - Validate TOML syntax

### Comparison & Analysis

- `--compare-config` - Compare inline vs TOML configuration

### Live Management

- `--reload-config` - Reload configuration  
- `--reload-interactive` - Interactive management menu
- `--watch-config [seconds]` - Watch for configuration changes

### Backup & Restore

- `--backup-config <directory>` - Backup current configuration
- `--restore-config <directory>` - Restore from backup

### Information & Help

- `--help [topic]` - Show help information
- `--version` - Display version and system info

---

## 📚 **Related Documentation**

- ⚙️ **[Configuration Guide](configuration.md)** - Complete TOML configuration reference
- 🎨 **[Themes Guide](themes.md)** - Theme creation and customization
- 📦 **[Installation Guide](installation.md)** - Platform-specific setup
- 🚀 **[Migration Guide](migration.md)** - Migrate from inline to TOML configuration
- 🐛 **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
- 📚 **[Examples](../examples/README.md)** - Ready-to-use configuration templates

---

**Alhamdulillah!** You now have access to enterprise-grade command-line tools for statusline configuration management. Master these commands to unlock the full potential of the TOML configuration system! 🚀
