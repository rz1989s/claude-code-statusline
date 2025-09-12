# 🔧 CLI Reference - Complete Command Documentation

**Comprehensive reference for all Claude Code Enhanced Statusline command-line interface options.**

The statusline provides a focused set of commands for essential operations with automatic configuration discovery and intelligent defaults.

> 🏗️ **Atomic Component Architecture**: The CLI is powered by the atomic component system (v2.7.0) with 20 configurable components arranged on 1-9 customizable lines. The main script orchestrates specialized modules in the `lib/` directory with standardized component interfaces.

## 🚀 **Overview**

The enhanced statusline provides a streamlined command-line interface for:

- **Help & Information** - Get usage information and version details
- **Display Testing** - Verify visual formatting and theme rendering
- **Module Diagnostics** - Check module loading status and debug issues
- **Automatic Configuration** - TOML configuration is automatically discovered and loaded

---

## 📋 **Command Syntax**

```bash
# From project directory
./statusline.sh [OPTION]

# Using installed statusline
~/.claude/statusline.sh [OPTION]
```

---

## 🎯 **Available Commands**

### `--help` / `-h`

**Purpose**: Display comprehensive help information.

**Syntax**:

```bash
./statusline.sh --help
./statusline.sh -h
```

**Output**:
- Shows all available command-line options
- Lists supported themes and usage examples
- Provides debugging information
- Includes links to documentation

**Example**:

```bash
$ ./statusline.sh --help
Claude Code Statusline v2.9.0
==========================================

USAGE:
    statusline.sh [options]                 - Run statusline (default)
    statusline.sh --help                    - Show this help message
    statusline.sh --version                 - Show version information
    statusline.sh --test-display            - Test display formatting
    statusline.sh --modules                 - Show loaded modules

THEMES:
    ENV_CONFIG_THEME=classic ./statusline.sh    - Use classic theme
    ENV_CONFIG_THEME=garden ./statusline.sh     - Use garden theme  
    ENV_CONFIG_THEME=catppuccin ./statusline.sh  - Use catppuccin theme
```

---

### `--version` / `-v`

**Purpose**: Display detailed version information.

**Syntax**:

```bash
./statusline.sh --version
./statusline.sh -v
```

**Output**:
- Current statusline version
- Architecture version information  
- Module loading statistics
- Active theme information

**Example**:

```bash
$ ./statusline.sh --version
Claude Code Statusline v2.9.0
Architecture: 2.0.0-refactored (modular refactor)
Compatible with original v1.3.0
Modules loaded: 9
Current theme: catppuccin
```

---

### `--test-display`

**Purpose**: Test display formatting and theme rendering.

**Syntax**:

```bash
./statusline.sh --test-display
```

**Output**:
- Tests color rendering for current theme
- Validates emoji and special character display
- Shows sample statusline output
- Helps verify terminal compatibility

**Use Cases**:
- Debugging display issues
- Verifying theme changes
- Testing terminal compatibility
- Validating configuration changes

**Example**:

```bash
$ ./statusline.sh --test-display
Testing display formatting...
[Displays sample statusline with current theme colors]
```

---

### `--modules`

**Purpose**: Display module loading status and diagnostics.

**Syntax**:

```bash
./statusline.sh --modules
```

**Output**:
- List of successfully loaded modules
- Any modules that failed to load
- Module dependencies and status
- Helpful for troubleshooting

**Example**:

```bash
$ ./statusline.sh --modules
Loaded modules:
  ✓ security
  ✓ cache
  ✓ config
  ✓ themes
  ✓ git
  ✓ mcp
  ✓ cost
  ✓ display
  ✓ components (20 atomic components registered)
```

---

## 🧩 **Atomic Component Testing (v2.7.0)**

The atomic component system provides specialized testing commands for component validation and modular display configuration.

### Component Status Check

**Purpose**: Display all 20 component registration status and availability.

**Syntax**:
```bash
./statusline.sh --modules                      # Shows component status
STATUSLINE_DEBUG=true ./statusline.sh --modules   # Debug component loading
```

**Output**:
- Lists all 18 components across 6 categories
- Shows component registration status
- Displays component dependencies
- Identifies any failed component loads

### Modular Display Testing

**Purpose**: Test custom line configurations and atomic component arrangements.

**Syntax**:
```bash
# Test custom line count
ENV_CONFIG_DISPLAY_LINES=3 ./statusline.sh

# Test atomic component arrangement
ENV_CONFIG_LINE1_COMPONENTS="repo_info,commits" ./statusline.sh
ENV_CONFIG_LINE2_COMPONENTS="cost_monthly,cost_weekly,cost_daily" ./statusline.sh
ENV_CONFIG_LINE3_COMPONENTS="mcp_status" ./statusline.sh

# Test component enable/disable
ENV_CONFIG_COMPONENTS_SUBMODULES_ENABLED=false ./statusline.sh
ENV_CONFIG_COMPONENTS_COST_WEEKLY_ENABLED=false ./statusline.sh
```

**Use Cases**:
- Testing atomic component separation
- Validating custom line configurations
- Debugging component arrangement issues
- Verifying 1-9 line layouts

### Pre-built Configuration Testing

**Purpose**: Test example atomic component configurations.

**Syntax**:
```bash
# Test atomic configurations
cp examples/Config.modular-atomic.toml Config.toml       # Atomic showcase
cp examples/Config.modular-compact.toml Config.toml      # 3-line minimal
cp examples/Config.modular-comprehensive.toml Config.toml # 7-line full

# Test and verify
./statusline.sh                                          # Apply configuration
```

---

## 🎨 **Theme Usage**

Themes are applied using environment variables:

```bash
# Available themes: classic, garden, catppuccin, custom
ENV_CONFIG_THEME=classic ./statusline.sh
ENV_CONFIG_THEME=garden ./statusline.sh  
ENV_CONFIG_THEME=catppuccin ./statusline.sh
```

---

## ⚙️ **Configuration**

The statusline automatically discovers and loads TOML configuration files in this order:

1. `./Config.toml` (project-specific)
2. `~/.claude/statusline/Config.toml` (user installation)
3. `~/.config/claude-code-statusline/Config.toml` (XDG standard)
4. `~/.claude-statusline.toml` (legacy location)

**No configuration commands are needed** - simply create or edit a TOML file and the statusline will automatically use it.

### Configuration Template

```bash
# Copy the master template
cp examples/Config.toml ./Config.toml

# Edit with your preferences
vim Config.toml

# The statusline will automatically use your configuration
./statusline.sh
```

---

## 🐛 **Debugging**

Enable debug mode for troubleshooting:

```bash
STATUSLINE_DEBUG=true ./statusline.sh
```

**Debug information includes**:
- Module loading details
- Configuration discovery process
- External command execution
- Performance timing information
- Error diagnostics

---

## 🚀 **Normal Operation**

For normal use, simply run without arguments:

```bash
# Default operation - generates configurable 1-9 line statusline
./statusline.sh
```

The statusline will:
1. Automatically discover and load configuration
2. Apply the configured theme (or default to catppuccin) 
3. Initialize all 20 atomic components and collect data
4. Build modular display with configured line arrangements
5. Generate beautiful output with perfect component separation for Claude Code

**Atomic Component Benefits**:
- **Perfect Separation**: `│ Commits:8 │ SUB:-- │ 30DAY $660.87 │ 7DAY $9.31 │ DAY $36.10 │`
- **Maximum Customization**: Show/hide individual data points
- **1-9 Line Flexibility**: From minimal to comprehensive displays

---

## 📖 **Additional Documentation**

- [Configuration Guide](configuration.md) - Complete TOML configuration reference
- [Themes Guide](themes.md) - Theme customization and color options  
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Installation Guide](installation.md) - Setup and installation instructions

---

## 💡 **Tips**

- **Configuration is automatic** - No setup commands needed
- **Use environment variables** for temporary theme changes
- **Run `--modules`** to debug loading issues
- **Use `--test-display`** to verify theme changes
- **Enable debug mode** for detailed troubleshooting