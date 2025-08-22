# 🎨 Themes Guide - TOML Configuration

**Transform your terminal with beautiful themes using the modern TOML configuration system.**

Create stunning visual experiences with structured theme configuration - from pre-built themes to custom color palettes, all managed through elegant TOML files.

> 🏗️ **Modular Architecture**: The theme system is now powered by `lib/themes.sh` which provides enhanced theme loading, validation, and color management within our modular architecture.

## 🚀 **Quick Start with TOML Themes**

### Instant Theme Setup

**From project directory:**
```bash
# 1. Generate your base Config.toml
./statusline.sh --generate-config

# 2. Choose your theme in Config.toml
vim Config.toml
# Change: name = "catppuccin"  # or "classic", "garden", "custom"

# 3. Test your theme
./statusline.sh --test-config

# 4. Use your themed statusline!
./statusline.sh
```

**Using installed statusline:**
```bash
# 1. Generate your base Config.toml
~/.claude/statusline.sh --generate-config

# 2. Choose your theme in Config.toml
vim Config.toml
# Change: name = "catppuccin"  # or "classic", "garden", "custom"

# 3. Test your theme
~/.claude/statusline.sh --test-config

# 4. Use your themed statusline!
~/.claude/statusline.sh
```

### Quick Theme Testing

```bash
# Try themes instantly without editing files
ENV_CONFIG_THEME=garden ./statusline.sh      # Test garden theme (local)
ENV_CONFIG_THEME=classic ~/.claude/statusline.sh     # Test classic theme (installed)
ENV_CONFIG_THEME=catppuccin ~/.claude/statusline.sh  # Test catppuccin theme (installed)
```

---

## 🎯 **Available Themes**

All themes are now configured through TOML with rich customization options:

| Theme | Style | TOML Configuration | Best For |
|-------|-------|-------------------|-----------|
| **Classic** | Traditional ANSI | `name = "classic"` | Universal compatibility, professional environments |  
| **Garden** | Soft Pastels | `name = "garden"` | Soothing interface, long coding sessions |
| **Catppuccin** | Modern Dark | `name = "catppuccin"` | Trendy design, dark mode enthusiasts |
| **Custom** | Full Control | `name = "custom"` | Complete creative freedom, branded environments |

---

## 🖥️ **Pre-built Themes with TOML**

### Classic Theme

**Style**: Traditional terminal colors with ANSI compatibility  
**Compatibility**: ✅ All terminals  
**Best for**: Professional environments, universal readability

**TOML Configuration:**
```toml
# In your Config.toml
[theme]
name = "classic"

# Optional: Customize features with classic theme
[features]
show_commits = true
show_version = true
show_mcp_status = true

[emojis]
clean_status = "✅"
dirty_status = "⚠️"
```

**Color Palette**:
- 🔴 **Red** `#FF0000` - Alerts, mode indicators
- 🔵 **Blue** `#0000FF` - Directory paths, information  
- 🟢 **Green** `#00FF00` - Success states, clean git status
- 🟡 **Yellow** `#FFFF00` - Warnings, dirty git status
- 🟣 **Magenta** `#FF00FF` - Git branches, highlights
- 🟦 **Cyan** `#00FFFF` - Model names, secondary info
- ⚪ **White** `#FFFFFF` - General text

**Environment Override:**
```bash
# Use classic theme temporarily
ENV_CONFIG_THEME=classic ./statusline.sh
```

---

### Garden Theme

**Style**: Soft pastel colors for a gentle, soothing interface  
**Compatibility**: ✅ Modern terminals with RGB support  
**Best for**: Extended coding sessions, gentle aesthetics

**TOML Configuration:**
```toml
# In your Config.toml
[theme]
name = "garden"

# Garden theme works beautifully with these settings
[features]
show_commits = true
show_cost_tracking = true
show_mcp_status = true

[emojis]
clean_status = "🌿"
dirty_status = "🌱"
clock = "🌸"
sonnet = "🎭"

[labels]
commits = "Blooms:"
mcp = "Gardens"
```

**Color Palette**:
- 🌸 **Light Pink** `#FFB6C1` - Mode indicators, gentle alerts
- 🌌 **Powder Blue** `#B0C4DE` - Directory paths, information  
- 🌿 **Sage Green** `#B0C490` - Success states, clean git status
- 🍑 **Peach** `#FFDAB9` - Warnings, dirty git status
- 💜 **Lavender** `#E6E6FA` - Git branches, highlights
- 🌊 **Pale Turquoise** `#AFEEEE` - Model names, secondary info
- 🤍 **Soft White** `#F5F5F5` - General text
- 🌱 **Mint Green** `#BDFCC9` - MCP servers, positive indicators

**Environment Override:**
```bash
# Use garden theme temporarily  
ENV_CONFIG_THEME=garden ./statusline.sh
```

---

### Catppuccin Theme

**Style**: Official [Catppuccin Mocha](https://catppuccin.com/) theme colors  
**Compatibility**: ✅ Modern terminals with RGB support  
**Best for**: Dark mode enthusiasts, cohesive design systems

**TOML Configuration:**
```toml
# In your Config.toml
[theme]
name = "catppuccin"

# Catppuccin pairs beautifully with these settings
[features]
show_commits = true
show_version = true
show_mcp_status = true
show_cost_tracking = true
show_reset_info = true

[emojis]
opus = "🧠"
sonnet = "🎵"
haiku = "⚡"
clean_status = "✅"
dirty_status = "📁"
live_block = "🔥"

[labels]
commits = "Commits:"
repo = "REPO"
mcp = "MCP"
```

**Color Palette** (Catppuccin Mocha):
- 🌹 **Red** `#f38ba8` - Alerts, important indicators
- 🌀 **Blue** `#89b4fa` - Directory paths, primary information
- 🌱 **Green** `#a6e3a1` - Success states, clean git status  
- 🌟 **Yellow** `#f9e2af` - Warnings, dirty git status
- 🦄 **Magenta** `#cba6f7` - Git branches, highlights
- 🌊 **Cyan** `#89dceb` - Model names, secondary info
- ☁️ **White** `#cdd6f4` - General text
- 🧡 **Orange** `#fab387` - Time display, accents
- 💎 **Teal** `#94e2d5` - Commits, special counters
- 🌸 **Pink** `#f5c2e7` - Cost tracking, statistics

**Environment Override:**
```bash
# Use catppuccin theme temporarily
ENV_CONFIG_THEME=catppuccin ./statusline.sh
```

---

## 🎨 **Custom Theme Creation with TOML**

Create completely custom themes with full control over every color and element.

### Basic Custom Theme

```toml
# In your Config.toml
[theme]
name = "custom"

# Define your basic color palette
[colors.basic]
red = "\\033[31m"       # ANSI red - alerts, mode info
blue = "\\033[34m"      # ANSI blue - directories, info
green = "\\033[32m"     # ANSI green - success, clean status
yellow = "\\033[33m"    # ANSI yellow - warnings, dirty status
magenta = "\\033[35m"   # ANSI magenta - branches, highlights
cyan = "\\033[36m"      # ANSI cyan - models, secondary info
white = "\\033[37m"     # ANSI white - general text
```

### Advanced Custom Theme

```toml
# In your Config.toml
[theme]
name = "custom"

# Basic ANSI colors (most compatible)
[colors.basic]
red = "\\033[38;2;255;87;87m"       # Soft red
blue = "\\033[38;2;135;206;235m"     # Sky blue
green = "\\033[38;2;152;251;152m"    # Pale green
yellow = "\\033[38;2;255;218;185m"   # Peach puff
magenta = "\\033[38;2;221;160;221m"  # Plum
cyan = "\\033[38;2;175;238;238m"     # Pale turquoise
white = "\\033[38;2;248;248;255m"    # Ghost white

# Extended colors (256-color and RGB)
[colors.extended]
orange = "\\033[38;2;255;165;0m"         # Orange - time display
light_orange = "\\033[38;2;255;218;185m" # Light orange - accents
light_gray = "\\033[38;2;211;211;211m"   # Light gray - separators
bright_green = "\\033[38;2;50;205;50m"   # Lime green - MCP servers
purple = "\\033[38;2;147;112;219m"       # Medium slate blue - version
teal = "\\033[38;2;72;209;204m"          # Medium turquoise - commits
gold = "\\033[38;2;255;215;0m"           # Gold - highlights
pink_bright = "\\033[38;2;255;192;203m"  # Pink - cost tracking
indigo = "\\033[38;2;75;0;130m"          # Indigo - weekly costs
violet = "\\033[38;2;138;43;226m"        # Blue violet - session info
light_blue = "\\033[38;2;173;216;230m"   # Light blue - MCP names

# Text formatting
[colors.formatting]
dim = "\\033[2m"           # Dim text - separators
italic = "\\033[3m"        # Italic text - reset info
strikethrough = "\\033[9m" # Strikethrough - offline servers
reset = "\\033[0m"         # Reset formatting
```

### Custom Theme Testing

```bash
# Test your custom theme before committing
./statusline.sh --test-config

# Test specific config file with custom theme
./statusline.sh --generate-config MyCustomTheme.toml
# Edit MyCustomTheme.toml with your colors
./statusline.sh --test-config MyCustomTheme.toml
```

---

## 🌈 **Community Theme Examples**

### Ocean Theme

Deep ocean-inspired colors with blues and teals:

```toml
[theme]
name = "custom"

[colors.basic]
blue = "\\033[38;2;0;119;190m"      # Deep ocean blue - directories
teal = "\\033[38;2;0;150;136m"      # Teal depths - commits  
cyan = "\\033[38;2;0;188;212m"      # Surface water - models
green = "\\033[38;2;76;175;80m"     # Seaweed green - success states
yellow = "\\033[38;2;255;193;7m"    # Sandy shore - warnings
red = "\\033[38;2;220;53;69m"       # Coral red - alerts
white = "\\033[38;2;224;247;250m"   # Sea foam - text

[colors.extended]
orange = "\\033[38;2;255;165;0m"    # Sunset orange - time
purple = "\\033[38;2;72;61;139m"    # Dark slate blue - version
light_gray = "\\033[38;2;176;196;222m" # Light steel blue - separators

[emojis]
clean_status = "🌊"
dirty_status = "🏖️"
clock = "⏰"
sonnet = "🐠"

[labels]
commits = "Waves:"
repo = "OCEAN"
mcp = "DEPTHS"
```

### Cyberpunk Theme

Electric neon colors for a futuristic aesthetic:

```toml
[theme]
name = "custom"

[colors.basic]
red = "\\033[38;2;255;0;102m"      # Electric pink - alerts
blue = "\\033[38;2;0;255;255m"     # Neon cyan - directories
green = "\\033[38;2;0;255;0m"      # Matrix green - success
yellow = "\\033[38;2;255;255;0m"   # Electric yellow - warnings
magenta = "\\033[38;2;255;0;255m"  # Neon magenta - branches
cyan = "\\033[38;2;0;255;255m"     # Bright cyan - models  
white = "\\033[38;2;255;255;255m"  # Bright white - text

[colors.extended]
orange = "\\033[38;2;255;165;0m"   # Neon orange - time
purple = "\\033[38;2;128;0;128m"   # Electric purple - version
teal = "\\033[38;2;0;255;128m"     # Cyber teal - commits
gold = "\\033[38;2;255;215;0m"     # Electric gold - highlights

[emojis]
clean_status = "⚡"
dirty_status = "🔥"
clock = "⏰"
sonnet = "🤖"
opus = "🧠"

[labels]
commits = "HACKS:"
repo = "MATRIX"
mcp = "NEURAL"
version_prefix = "v"
```

### Sunset Theme

Warm evening colors inspired by golden hour:

```toml
[theme]
name = "custom"

[colors.basic]
red = "\\033[38;2;255;61;0m"        # Deep sunset red
orange = "\\033[38;2;255;87;51m"    # Sunset orange  
yellow = "\\033[38;2;255;179;0m"    # Golden hour yellow
magenta = "\\033[38;2;255;105;180m" # Evening pink
purple = "\\033[38;2;138;43;226m"   # Twilight purple
blue = "\\033[38;2;30;144;255m"     # Evening sky blue
white = "\\033[38;2;255;248;220m"   # Cornsilk white

[colors.extended]
pink_bright = "\\033[38;2;255;192;203m" # Soft pink - costs
gold = "\\033[38;2;255;215;0m"          # Gold - highlights
teal = "\\033[38;2;255;140;105m"        # Warm teal - commits

[emojis]
clean_status = "🌅"
dirty_status = "🌇"
clock = "🌆"
sonnet = "🎭"

[labels]
commits = "Rays:"
repo = "HORIZON"
mcp = "GLOW"
```

### Matrix Theme  

Green terminal aesthetic inspired by The Matrix:

```toml
[theme]
name = "custom"

[colors.basic]
green = "\\033[38;2;0;255;0m"       # Bright matrix green - success
teal = "\\033[38;2;0;200;150m"      # Code stream - commits
white = "\\033[38;2;200;255;200m"   # Light green text
red = "\\033[38;2;255;50;50m"       # Alert red - errors
yellow = "\\033[38;2;200;255;0m"    # Matrix yellow - warnings
blue = "\\033[38;2;0;255;200m"      # Matrix cyan - info
magenta = "\\033[38;2;150;255;150m" # Bright green - highlights

[colors.extended]
bright_green = "\\033[38;2;150;255;150m" # Highlighted text
light_gray = "\\033[38;2;0;150;0m"       # Dark green separators
orange = "\\033[38;2;200;255;0m"         # Matrix lime - time
purple = "\\033[38;2;100;200;100m"       # Medium green - version

[colors.formatting]
dim = "\\033[38;2;0;100;0m"         # Very dark green - separators

[emojis]
clean_status = "💚"
dirty_status = "🔋"
sonnet = "🤖"
opus = "🧠"

[labels]
commits = "CODE:"
repo = "MATRIX"
mcp = "NEURAL"
version_prefix = "v"
```

---

## 🔧 **Theme Management with CLI**

### Theme Generation and Testing

```bash
# === THEME CONFIGURATION GENERATION ===
./statusline.sh --generate-config                    # Generate base Config.toml
./statusline.sh --generate-config MyTheme.toml       # Generate custom theme file

# === THEME TESTING ===
./statusline.sh --test-config                        # Test current theme
./statusline.sh --test-config MyTheme.toml           # Test specific theme file
./statusline.sh --test-config-verbose                # Detailed theme testing

# === THEME COMPARISON ===
./statusline.sh --compare-config                     # Compare theme settings
```

### Theme Configuration Management

```bash
# === LIVE THEME MANAGEMENT ===
./statusline.sh --reload-config                      # Reload theme changes
./statusline.sh --reload-interactive                 # Interactive theme management
./statusline.sh --watch-config 3                     # Watch for theme changes

# === THEME BACKUP & RESTORE ===
./statusline.sh --backup-config themes-backup/       # Backup theme configurations
./statusline.sh --restore-config themes-backup/      # Restore theme from backup
```

---

## 🌍 **Environment Theme Overrides**

Perfect for testing themes or temporary changes without editing configuration files:

### Quick Theme Changes

```bash
# === INSTANT THEME SWITCHING ===
ENV_CONFIG_THEME=classic ./statusline.sh             # Professional classic theme
ENV_CONFIG_THEME=garden ./statusline.sh              # Soothing garden theme
ENV_CONFIG_THEME=catppuccin ./statusline.sh          # Modern catppuccin theme
ENV_CONFIG_THEME=custom ./statusline.sh              # Your custom theme
```

### Advanced Theme Overrides

```bash
# === CUSTOM COLOR OVERRIDES ===
ENV_CONFIG_THEME=custom \
ENV_CONFIG_RED="\\033[38;2;255;0;0m" \
ENV_CONFIG_BLUE="\\033[38;2;0;0;255m" \
ENV_CONFIG_GREEN="\\033[38;2;0;255;0m" \
./statusline.sh

# === THEME + FEATURE COMBINATIONS ===
ENV_CONFIG_THEME=classic \
ENV_CONFIG_SHOW_COST_TRACKING=false \
ENV_CONFIG_SHOW_MCP_STATUS=false \
./statusline.sh
```

### CI/CD and Automation

```bash
# === AUTOMATED ENVIRONMENT THEMING ===
# Production: Clean, professional
ENV_CONFIG_THEME=classic \
ENV_CONFIG_SHOW_COST_TRACKING=false \
./statusline.sh

# Development: Full-featured with custom colors
ENV_CONFIG_THEME=catppuccin \
ENV_CONFIG_SHOW_VERSION=true \
ENV_CONFIG_SHOW_MCP_STATUS=true \
./statusline.sh

# Demo: Simple and clean
ENV_CONFIG_THEME=garden \
ENV_CONFIG_SHOW_COMMITS=false \
ENV_CONFIG_SHOW_COST_TRACKING=false \
./statusline.sh
```

---

## 🔬 **Advanced Theme Features**

### Theme Inheritance (Future Feature)

Create themes that extend existing themes with selective overrides:

```toml
[theme]
name = "custom"

# Theme inheritance system
[theme.inheritance]
enabled = true
base_theme = "catppuccin"       # Inherit all colors from catppuccin
override_colors = ["red", "blue"]  # Only override specific colors

# Custom overrides (inherits all other colors from catppuccin)
[colors.basic]
red = "\\033[38;2;255;100;100m"    # Custom red
blue = "\\033[38;2;100;150;255m"   # Custom blue
# All other colors inherited from catppuccin theme
```

### Conditional Theming

Apply different themes based on context:

```toml
# Time-based theming
[conditional.time_based]
enabled = true
day_theme = "garden"        # 6 AM - 6 PM
night_theme = "catppuccin"  # 6 PM - 6 AM

# Project-based theming
[conditional.git_context]
enabled = true
work_repos = ["/home/user/work/*"]
personal_repos = ["/home/user/personal/*"] 
work_theme = "classic"
personal_theme = "garden"

# Directory-based theming
[conditional.directory]
enabled = true
"/opt/work/*" = "classic"
"/home/user/projects/*" = "catppuccin"
```

### Theme Profiles

Different theme configurations for different use cases:

```toml
# Profile-based themes
[profiles]
enabled = true
default_profile = "development"

[profiles.work]
theme = "classic"
show_cost_tracking = true

[profiles.personal]
theme = "garden"
show_cost_tracking = false

[profiles.presentation]
theme = "custom"
show_commits = false
show_version = false

# Automatic profile switching
[conditional.work_hours]
enabled = true
start_time = "09:00"
end_time = "17:00" 
work_profile = "work"
off_hours_profile = "personal"
```

---

## 📊 **Color System Reference**

### ANSI Color Codes for TOML

```toml
# === BASIC ANSI COLORS (30-37) ===
[colors.basic]
black = "\\033[30m"
red = "\\033[31m"
green = "\\033[32m"
yellow = "\\033[33m"
blue = "\\033[34m"
magenta = "\\033[35m"
cyan = "\\033[36m"
white = "\\033[37m"

# === BRIGHT ANSI COLORS (90-97) ===
[colors.bright]
black = "\\033[90m"    # Bright Black (Gray)
red = "\\033[91m"      # Bright Red
green = "\\033[92m"    # Bright Green
yellow = "\\033[93m"   # Bright Yellow
blue = "\\033[94m"     # Bright Blue
magenta = "\\033[95m"  # Bright Magenta
cyan = "\\033[96m"     # Bright Cyan
white = "\\033[97m"    # Bright White
```

### 256-Color Palette for TOML

```toml
# === 256-COLOR EXAMPLES ===
[colors.extended]
bright_red = "\\033[38;5;196m"      # Color 196
bright_green = "\\033[38;5;46m"     # Color 46
bright_blue = "\\033[38;5;21m"      # Color 21
bright_yellow = "\\033[38;5;226m"   # Color 226
hot_pink = "\\033[38;5;201m"        # Color 201
bright_cyan = "\\033[38;5;51m"      # Color 51
orange = "\\033[38;5;208m"          # Color 208
purple = "\\033[38;5;129m"          # Color 129
```

### RGB True Color for TOML

```toml
# === RGB TRUE COLOR (38;2;R;G;B) ===
[colors.rgb]
pure_red = "\\033[38;2;255;0;0m"      # RGB(255,0,0)
pure_green = "\\033[38;2;0;255;0m"    # RGB(0,255,0)
pure_blue = "\\033[38;2;0;0;255m"     # RGB(0,0,255)
custom_purple = "\\033[38;2;128;0;128m" # RGB(128,0,128)
ocean_blue = "\\033[38;2;0;119;190m"   # RGB(0,119,190)
sunset_orange = "\\033[38;2;255;87;51m" # RGB(255,87,51)
```

### Background Colors for TOML

```toml
# === BACKGROUND COLORS ===
[colors.backgrounds]
red_bg = "\\033[41m"                      # ANSI red background
blue_bg = "\\033[44m"                     # ANSI blue background
red_256_bg = "\\033[48;5;196m"           # 256-color red background
blue_rgb_bg = "\\033[48;2;0;0;255m"      # RGB blue background
```

---

## 🛠️ **Theme Testing & Validation**

### Terminal Compatibility Testing

```bash
# === CHECK COLOR SUPPORT ===
echo $TERM                  # Check terminal type
echo $COLORTERM            # Check color capabilities

# === TEST BASIC ANSI COLORS ===
echo -e "\\033[31mRed\\033[0m \\033[32mGreen\\033[0m \\033[34mBlue\\033[0m"

# === TEST 256-COLOR SUPPORT ===
for i in {0..255}; do
    printf "\\033[48;5;%sm%3d\\033[0m " "$i" "$i"
    if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
        printf "\\n";
    fi
done

# === TEST RGB TRUE COLOR ===
echo -e "\\033[38;2;255;0;0mTrue Color Red\\033[0m"
```

### Theme Testing Commands

```bash
# === THEME VALIDATION ===
./statusline.sh --test-config                        # Test current theme
./statusline.sh --validate-config                    # Validate TOML syntax

# === THEME COMPARISON ===
./statusline.sh --compare-config                     # Compare themes

# === INTERACTIVE THEME TESTING ===
ENV_CONFIG_THEME=classic ./statusline.sh --test-config       # Test classic
ENV_CONFIG_THEME=garden ./statusline.sh --test-config        # Test garden  
ENV_CONFIG_THEME=catppuccin ./statusline.sh --test-config    # Test catppuccin
```

---

## 🔄 **Migration from Old Theme Syntax**

Your existing theme configuration **continues to work unchanged**! When you're ready to migrate to TOML:

### Step 1: Current Theme Detection

```bash
# Generate TOML from your current theme settings
./statusline.sh --generate-config

# This preserves your current theme choice in TOML format
```

### Step 2: Migration Examples

#### Before (Old Inline Syntax)
```bash
# In statusline.sh script:
CONFIG_THEME="catppuccin"
```

#### After (TOML Configuration)
```toml
# In Config.toml file:
[theme]
name = "catppuccin"
```

#### Before (Old Custom Theme)
```bash
# In statusline.sh script:
CONFIG_THEME="custom"
CONFIG_RED="\\033[38;2;255;0;0m"
CONFIG_BLUE="\\033[38;2;0;0;255m"
```

#### After (TOML Custom Theme)
```toml
# In Config.toml file:
[theme]
name = "custom"

[colors.basic]
red = "\\033[38;2;255;0;0m"
blue = "\\033[38;2;0;0;255m"
```

### Step 3: Theme Validation

```bash
# Compare old vs new theme configuration
./statusline.sh --compare-config

# Test your migrated theme
./statusline.sh --test-config
```

---

## 🐛 **Theme Troubleshooting**

### Colors Not Displaying

```bash
# === CHECK TERMINAL CAPABILITIES ===
echo $TERM                 # Should show terminal type
echo $COLORTERM           # Should show color support

# === VALIDATE THEME CONFIGURATION ===
./statusline.sh --test-config-verbose

# Expected output:
# Loading configuration from: ./Config.toml
# Theme: catppuccin loaded successfully
```

### TOML Theme Syntax Errors

```bash
# === COMMON THEME SYNTAX ISSUES ===

# ❌ Incorrect: name = catppuccin  
# ✅ Correct:   name = "catppuccin"

# ❌ Incorrect: [color.basic]
# ✅ Correct:   [colors.basic]

# ❌ Incorrect: red = \\033[31m
# ✅ Correct:   red = "\\033[31m"

# === VALIDATE THEME SYNTAX ===
./statusline.sh --validate-config
```

### Theme Override Issues

```bash
# === TEST ENVIRONMENT THEME OVERRIDES ===
ENV_CONFIG_THEME=garden ./statusline.sh --test-config

# Check if override is working:
# Theme: garden (environment override)

# === TEST CUSTOM COLOR OVERRIDES ===
ENV_CONFIG_THEME=custom \
ENV_CONFIG_RED="\\033[91m" \
./statusline.sh --test-config
```

### Terminal-Specific Issues

```bash
# === FALLBACK TO BASIC COLORS ===
# If RGB colors don't work, use basic ANSI
[theme]
name = "classic"  # Uses only ANSI colors

# === TEST COLOR LEVELS ===
ENV_CONFIG_THEME=classic ./statusline.sh      # Test ANSI colors
ENV_CONFIG_THEME=garden ./statusline.sh       # Test RGB colors
```

---

## 💡 **Theme Creation Best Practices**

### 1. Start with Base Themes
```toml
# Begin by modifying existing themes
[theme]
name = "catppuccin"  # Use as starting point

# Then gradually move to custom
[theme]
name = "custom"      # Full control
```

### 2. Test Color Compatibility
```bash
# Test across different terminals
ENV_CONFIG_THEME=custom ./statusline.sh  # iTerm2
ENV_CONFIG_THEME=custom ./statusline.sh  # Terminal.app
ENV_CONFIG_THEME=custom ./statusline.sh  # VS Code terminal
```

### 3. Consider Accessibility
```toml
# Ensure sufficient contrast
[colors.basic]
red = "\\033[38;2;220;50;47m"     # High contrast red
green = "\\033[38;2;133;153;0m"   # High contrast green
blue = "\\033[38;2;38;139;210m"   # High contrast blue
```

### 4. Document Your Theme
```toml
# Add comments to your custom theme
[theme]
name = "custom"  # Ocean-inspired theme for calming effect

[colors.basic]
blue = "\\033[38;2;0;119;190m"  # Deep ocean blue for directories
teal = "\\033[38;2;0;150;136m"  # Teal depths for commit counts
```

### 5. Version Your Themes
```bash
# Backup successful theme configurations
cp Config.toml Ocean-Theme-v1.0.toml
cp Config.toml Cyberpunk-Theme-v2.1.toml
```

---

## 📚 **Related Documentation**

- ⚙️ **[Configuration Guide](configuration.md)** - Complete TOML configuration system
- 📦 **[Installation Guide](installation.md)** - Platform setup with theme support  
- 🚀 **[Migration Guide](migration.md)** - Detailed theme migration from inline configuration
- 🔧 **[CLI Reference](cli-reference.md)** - Complete theme management commands
- 🐛 **[Troubleshooting](troubleshooting.md)** - Theme-specific troubleshooting

---

## 🎨 **Theme Gallery**

Check out these additional theme resources:
- **Community Themes**: Share your themes in GitHub Discussions
- **Theme Templates**: Ready-to-use TOML theme files in `/examples/themes/`
- **Color Generators**: Tools for creating harmonious color palettes
- **Terminal Testing**: Cross-terminal compatibility guides

---

**Subhanallah!** Your terminal is now a canvas for beautiful, structured themes! Express your creativity with the power of TOML configuration. 🌟