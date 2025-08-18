# 🎨 Themes Showcase

Explore the beautiful themes available in Claude Code Enhanced Statusline and learn how to create your own.

## 🎯 Available Themes

The statusline comes with 3 carefully crafted themes, each designed for different aesthetics and terminal environments:

| Theme | Style | Colors | Best For |
|-------|-------|---------|-----------|
| **Classic** | Traditional ANSI | Standard terminal colors | Universal compatibility |  
| **Garden** | Soft Pastels | RGB gentle colors | Soothing interface |
| **Catppuccin** | Modern Dark | Catppuccin Mocha palette | Trendy, cohesive design |

## 🖥️ Theme Previews

### Classic Theme

**Style**: Traditional terminal colors with ANSI compatibility  
**Compatibility**: ✅ All terminals  
**Best for**: Users who prefer standard terminal appearance

```bash
CONFIG_THEME="classic"
```

**Color Palette**:
- 🔴 **Red** `#FF0000` - Mode indicators, errors
- 🔵 **Blue** `#0000FF` - Directory paths, info
- 🟢 **Green** `#00FF00` - Git clean status, success
- 🟡 **Yellow** `#FFFF00` - Git dirty status, warnings
- 🟣 **Magenta** `#FF00FF` - Git branches
- 🟦 **Cyan** `#00FFFF` - Model names
- ⚪ **White** `#FFFFFF` - General text

**Sample Output**:
```
~/dotfiles (main) ✅ │ Commits:3 │ ver1.0.81 │ SUB:2 │ 🕐 14:23
🎵 Sonnet 4 │ REPO $0.45 │ 30DAY $12.30 │ 7DAY $3.21 │ DAY $0.89 │ 🔥 LIVE $0.15
MCP (2/3): upstash-context-7-mcp, github, filesystem
RESET at 15.45 (2h 15m left)
```

---

### Garden Theme

**Style**: Soft pastel colors for a gentle, soothing interface  
**Compatibility**: ✅ Modern terminals with RGB support  
**Best for**: Users who want a calm, elegant appearance

```bash
CONFIG_THEME="garden"
```

**Color Palette**:
- 🌸 **Light Pink** `#FFB6C1` - Mode indicators, gentle alerts
- 🌌 **Powder Blue** `#B0C4DE` - Directory paths, information
- 🌿 **Sage Green** `#B0C490` - Git clean status, success states
- 🍑 **Peach** `#FFDAB9` - Git dirty status, soft warnings
- 💜 **Lavender** `#E6E6FA` - Git branches, highlights
- 🌊 **Pale Turquoise** `#AFEEEE` - Model names
- 🤍 **Soft White** `#F5F5F5` - General text
- 🌱 **Mint Green** `#BDFCC9` - MCP servers, positive indicators

**Sample Output**:
```
~/dotfiles (main) ✅ │ Commits:3 │ ver1.0.81 │ SUB:2 │ 🕐 14:23
🎵 Sonnet 4 │ REPO $0.45 │ 30DAY $12.30 │ 7DAY $3.21 │ DAY $0.89 │ 🔥 LIVE $0.15
MCP (2/3): upstash-context-7-mcp, github, filesystem  
RESET at 15.45 (2h 15m left)
```

---

### Catppuccin Theme

**Style**: Official [Catppuccin Mocha](https://catppuccin.com/) theme colors  
**Compatibility**: ✅ Modern terminals with RGB support  
**Best for**: Catppuccin enthusiasts and cohesive design lovers

```bash
CONFIG_THEME="catppuccin"
```

**Color Palette** (Catppuccin Mocha):
- 🌹 **Red** `#f38ba8` - Mode indicators, important alerts
- 🌀 **Blue** `#89b4fa` - Directory paths, primary information
- 🌱 **Green** `#a6e3a1` - Git clean status, success indicators  
- 🌟 **Yellow** `#f9e2af` - Git dirty status, warnings
- 🦄 **Magenta** `#cba6f7` - Git branches, highlights
- 🌊 **Cyan** `#89dceb` - Model names, secondary info
- ☁️ **White** `#cdd6f4` - General text
- 🧡 **Orange** `#fab387` - Time display, accents
- 💎 **Teal** `#94e2d5` - Commits, special counters
- 🌸 **Pink** `#f5c2e7` - Cost tracking, statistics

**Sample Output**:
```
~/dotfiles (main) ✅ │ Commits:3 │ ver1.0.81 │ SUB:2 │ 🕐 14:23
🎵 Sonnet 4 │ REPO $0.45 │ 30DAY $12.30 │ 7DAY $3.21 │ DAY $0.89 │ 🔥 LIVE $0.15
MCP (2/3): upstash-context-7-mcp, github, filesystem
RESET at 15.45 (2h 15m left)
```

## 🎨 Custom Theme Creation

### Step-by-Step Guide

#### 1. Enable Custom Theme Mode
```bash
# Edit ~/.claude/statusline-enhanced.sh
CONFIG_THEME="custom"
```

#### 2. Define Your Color Palette

Start with a base palette and assign colors logically:

```bash
# Example: Cyberpunk Theme
CONFIG_THEME="custom"

# Primary colors
CONFIG_RED='\033[38;2;255;0;102m'      # Electric pink
CONFIG_BLUE='\033[38;2;0;255;255m'     # Cyan blue
CONFIG_GREEN='\033[38;2;0;255;0m'      # Matrix green
CONFIG_YELLOW='\033[38;2;255;255;0m'   # Electric yellow
CONFIG_MAGENTA='\033[38;2;255;0;255m'  # Neon magenta
CONFIG_CYAN='\033[38;2;0;255;255m'     # Neon cyan
CONFIG_WHITE='\033[38;2;255;255;255m'  # Bright white

# Extended colors
CONFIG_ORANGE='\033[38;2;255;165;0m'   # Neon orange
CONFIG_TEAL='\033[38;2;0;128;128m'     # Dark teal
CONFIG_PURPLE='\033[38;2;128;0;128m'   # Electric purple
```

#### 3. Test Your Theme
```bash
# Quick test
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test Model"}}' | ~/.claude/statusline-enhanced.sh
```

### 🎯 Theme Design Principles

#### Color Harmony
- **Analogous**: Use colors next to each other on the color wheel
- **Complementary**: Use opposite colors for contrast
- **Monochromatic**: Use different shades of the same color
- **Triadic**: Use three evenly spaced colors

#### Accessibility
- **Contrast**: Ensure sufficient contrast for readability
- **Color blindness**: Test with colorblind-friendly tools
- **Terminal support**: Consider ANSI fallbacks

#### Information Hierarchy
- **Critical info**: Bright, attention-grabbing colors
- **Secondary info**: Muted, complementary colors  
- **Separators**: Dim, low-contrast colors
- **Status indicators**: Consistent color coding (green=good, red=error)

## 🌈 Community Themes

### Ocean Theme
Inspired by deep ocean waters:

```bash
CONFIG_THEME="custom"

# Ocean palette
CONFIG_BLUE='\033[38;2;0;119;190m'      # Deep ocean
CONFIG_TEAL='\033[38;2;0;150;136m'      # Teal depths
CONFIG_CYAN='\033[38;2;0;188;212m'      # Surface water
CONFIG_GREEN='\033[38;2;76;175;80m'     # Seaweed
CONFIG_WHITE='\033[38;2;224;247;250m'   # Sea foam
CONFIG_YELLOW='\033[38;2;255;193;7m'    # Sandy shore
```

### Sunset Theme
Warm evening colors:

```bash
CONFIG_THEME="custom"

# Sunset palette
CONFIG_ORANGE='\033[38;2;255;87;51m'    # Sunset orange
CONFIG_RED='\033[38;2;255;61;0m'        # Deep sunset
CONFIG_YELLOW='\033[38;2;255;179;0m'    # Golden hour
CONFIG_PINK_BRIGHT='\033[38;2;255;105;180m' # Evening pink
CONFIG_PURPLE='\033[38;2;138;43;226m'   # Twilight purple
CONFIG_BLUE='\033[38;2;30;144;255m'     # Evening sky
```

### Matrix Theme
Green terminal aesthetic:

```bash
CONFIG_THEME="custom"

# Matrix palette
CONFIG_GREEN='\033[38;2;0;255;0m'       # Bright matrix green
CONFIG_TEAL='\033[38;2;0;200;150m'      # Code stream
CONFIG_WHITE='\033[38;2;200;255;200m'   # Light green text
CONFIG_DIM='\033[38;2;0;150;0m'         # Dark green separators
CONFIG_BRIGHT_GREEN='\033[38;2;150;255;150m' # Highlighted text
```

## 🔧 Advanced Theming

### Conditional Theming
Apply different themes based on context:

```bash
# Time-based theming
HOUR=$(date +%H)
if [[ $HOUR -ge 6 && $HOUR -lt 18 ]]; then
    CONFIG_THEME="garden"    # Day theme
else
    CONFIG_THEME="catppuccin"  # Night theme
fi

# Project-based theming
if [[ $(pwd) =~ "work" ]]; then
    CONFIG_THEME="classic"   # Professional theme
else
    CONFIG_THEME="garden"    # Personal theme
fi
```

### Terminal-Specific Themes
```bash
case "$TERM_PROGRAM" in
    "iTerm.app")
        CONFIG_THEME="catppuccin"
        ;;
    "Terminal")
        CONFIG_THEME="classic"
        ;;
    *)
        CONFIG_THEME="garden"
        ;;
esac
```

## 📸 Screenshot Gallery

*Note: Screenshots will be added to `examples/screenshots/` showing each theme in action.*

### File Structure for Screenshots
```
examples/screenshots/
├── classic-theme-preview.png
├── garden-theme-preview.png
├── catppuccin-theme-preview.png
├── custom-ocean-theme.png
├── custom-sunset-theme.png
└── custom-matrix-theme.png
```

## 🎨 Color Reference

### ANSI Color Codes
```bash
# Basic colors (30-37)
\033[30m  # Black
\033[31m  # Red
\033[32m  # Green  
\033[33m  # Yellow
\033[34m  # Blue
\033[35m  # Magenta
\033[36m  # Cyan
\033[37m  # White

# Bright colors (90-97)
\033[90m  # Bright Black (Gray)
\033[91m  # Bright Red
\033[92m  # Bright Green
\033[93m  # Bright Yellow
\033[94m  # Bright Blue
\033[95m  # Bright Magenta
\033[96m  # Bright Cyan
\033[97m  # Bright White
```

### 256-Color Examples
```bash
# Popular 256-color codes
\033[38;5;196m  # Bright Red
\033[38;5;46m   # Bright Green
\033[38;5;21m   # Bright Blue
\033[38;5;226m  # Bright Yellow
\033[38;5;201m  # Hot Pink
\033[38;5;51m   # Bright Cyan
```

### RGB True Color
```bash
# RGB format: \033[38;2;R;G;Bm
\033[38;2;255;0;0m     # Pure Red (255,0,0)
\033[38;2;0;255;0m     # Pure Green (0,255,0)
\033[38;2;0;0;255m     # Pure Blue (0,0,255)
```

## 🛠️ Testing Your Theme

### Quick Test Commands
```bash
# Test basic functionality
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test"}}' | ~/.claude/statusline-enhanced.sh

# Test with git repository
cd /path/to/git/repo
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Sonnet 4"}}' | ~/.claude/statusline-enhanced.sh

# Test color output
echo -e "\033[38;2;255;0;0mThis should be red\033[0m"
```

### Terminal Compatibility Check
```bash
# Check color support
echo $TERM
echo $COLORTERM

# Test 256-color support
for i in {0..255}; do
    printf "\033[48;5;%sm%3d\033[0m " "$i" "$i"
    if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
        printf "\n";
    fi
done
```

## 💡 Theme Tips

1. **Start with existing themes**: Modify existing themes rather than starting from scratch
2. **Consider your terminal**: Different terminals render colors differently
3. **Test in different lighting**: Ensure readability in various conditions
4. **Save your work**: Keep backups of working themes
5. **Share with community**: Consider contributing your themes to the project

## 📚 Resources

- [Catppuccin Color Palette](https://catppuccin.com/palette)
- [Terminal Color Reference](https://misc.flogisoft.com/bash/tip_colors_and_formatting)
- [Color Blindness Testing](https://www.color-blindness.com/coblis-color-blindness-simulator/)
- [RGB Color Picker](https://htmlcolorcodes.com/)

---

**Express your style!** Create themes that reflect your personality and make your terminal truly yours.