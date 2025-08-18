# 📚 Examples Directory

This directory contains sample configurations, screenshots, and usage examples for Claude Code Enhanced Statusline.

## 📁 Directory Structure

```
examples/
├── README.md                    # This file
├── sample-configs/             # Ready-to-use configuration snippets
│   ├── ocean-theme.sh         # Ocean-inspired color theme
│   ├── minimal-config.sh      # Lightweight, performance-optimized
│   └── developer-config.sh    # Full-featured developer setup
└── screenshots/               # Visual previews (to be added)
    ├── classic-theme.png
    ├── garden-theme.png
    ├── catppuccin-theme.png
    └── custom-themes/
```

## 🎨 Sample Configurations

### Ocean Theme (`sample-configs/ocean-theme.sh`)
**Purpose**: Beautiful ocean-inspired color palette  
**Best for**: Users who want a calming, nature-inspired interface  
**Features**: 
- Custom RGB colors inspired by deep sea waters
- Coral and seaweed-inspired accents
- Sea foam and sandy shore highlights

**Usage**:
```bash
# Copy the color definitions from ocean-theme.sh
# into your statusline-enhanced.sh configuration section
```

### Minimal Config (`sample-configs/minimal-config.sh`)  
**Purpose**: Lightweight, performance-optimized setup  
**Best for**: Slow systems, limited bandwidth, or users who prefer simplicity  
**Features**:
- Reduced timeouts for faster response
- Disabled network-dependent features
- Simplified labels and minimal emojis
- Classic theme for maximum compatibility

**Usage**:
```bash
# Replace configuration section in your statusline-enhanced.sh
# with settings from minimal-config.sh
```

### Developer Config (`sample-configs/developer-config.sh`)
**Purpose**: Maximum information display with all features enabled  
**Best for**: Developers who want comprehensive monitoring  
**Features**:
- All features enabled (MCP, cost tracking, version info)
- Extended timeouts for detailed information gathering
- Descriptive labels and comprehensive error messages
- Catppuccin theme for modern aesthetics

**Usage**:
```bash
# Replace configuration section in your statusline-enhanced.sh  
# with settings from developer-config.sh
```

## 🖼️ Screenshots

*Screenshots will be added to demonstrate each theme and configuration in action.*

### Planned Screenshots:
- `classic-theme.png` - Traditional ANSI colors
- `garden-theme.png` - Soft pastel theme  
- `catppuccin-theme.png` - Popular dark theme
- `ocean-theme.png` - Custom ocean theme example
- `minimal-setup.png` - Lightweight configuration
- `developer-setup.png` - Full-featured display

## 🔧 How to Use Sample Configs

### Method 1: Copy Specific Settings
```bash
# 1. Open your statusline script
vim ~/.claude/statusline-enhanced.sh

# 2. Find the configuration section (around line 23)
# 3. Copy desired settings from sample config files
# 4. Save and test
```

### Method 2: Replace Entire Configuration Section
```bash
# 1. Backup your current config
cp ~/.claude/statusline-enhanced.sh ~/.claude/statusline-enhanced.sh.backup

# 2. Open both files
vim ~/.claude/statusline-enhanced.sh
vim examples/sample-configs/developer-config.sh

# 3. Replace the configuration section (lines 23-231) 
# 4. Save and test
```

### Method 3: Scripted Application
```bash
# Create a script to apply configurations
cat > apply-config.sh << 'EOF'
#!/bin/bash
CONFIG_FILE="$1"
STATUSLINE_FILE="$HOME/.claude/statusline-enhanced.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

# Backup current config
cp "$STATUSLINE_FILE" "${STATUSLINE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Apply new configuration
# (This would need more sophisticated sed/awk to replace sections)
echo "Manual replacement required - see documentation"
EOF

chmod +x apply-config.sh
```

## 🎨 Creating Your Own Examples

### Contributing Sample Configs
We welcome contributions of new sample configurations! 

**Requirements**:
1. **Clear purpose**: What problem does this config solve?
2. **Documentation**: Include comments explaining choices
3. **Testing**: Verify the config works across different terminals
4. **Naming**: Use descriptive filenames (e.g., `high-contrast-theme.sh`)

**Template**:
```bash
# [Theme/Config Name]
# [Brief description of purpose and best use cases]
# Copy these values into your statusline-enhanced.sh

CONFIG_THEME="custom"  # or predefined theme

# === SECTION NAME ===
# Comment explaining this section
CONFIG_SETTING=value

# [Continue with organized sections...]
```

### Screenshot Guidelines
When contributing screenshots:
1. **Resolution**: 1200x400 minimum for readability
2. **Terminal**: Use popular terminals (iTerm2, Terminal.app, GNOME Terminal)
3. **Content**: Show realistic development scenario
4. **Format**: PNG for clarity, JPG for smaller files
5. **Naming**: Descriptive names matching config files

## 💡 Tips for Custom Configurations

1. **Start with samples**: Modify existing configs rather than starting from scratch
2. **Test thoroughly**: Verify colors work in your terminal environment
3. **Document changes**: Add comments explaining your customizations
4. **Backup working configs**: Save configurations that work well for you
5. **Share useful configs**: Consider contributing back to the project

## 🔗 Related Documentation

- [Configuration Guide](../docs/configuration.md) - Detailed configuration options
- [Themes Guide](../docs/themes.md) - Theme creation and customization
- [Installation Guide](../docs/installation.md) - Setup instructions
- [Troubleshooting](../docs/troubleshooting.md) - Common issues and solutions

---

**Explore and customize!** These examples are starting points for creating your perfect statusline setup.