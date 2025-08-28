# 📚 Examples Directory - TOML Configuration Samples

**Ready-to-use TOML configuration examples for Claude Code Enhanced Statusline.**

This directory contains professionally crafted configuration templates that demonstrate the power and flexibility of the enterprise-grade TOML configuration system.

## 🚀 **Quick Start with Examples**

```bash
# Copy any example to start customizing
cp examples/sample-configs/developer-config.toml Config.toml

# Test your configuration
./statusline.sh # Configuration is automatically loaded

# Use your customized statusline
./statusline.sh
```

---

## 📁 **Directory Structure**

```
examples/
├── README.md                       # This file
├── sample-configs/                 # Ready-to-use TOML configurations
│   ├── minimal-config.toml        # Performance-optimized, lightweight
│   ├── developer-config.toml      # Full-featured developer setup
│   ├── custom-theme.toml          # Custom theme template
│   ├── work-profile.toml          # Professional work environment
│   └── personal-profile.toml      # Relaxed personal project setup
└── screenshots/                   # Visual previews (to be added)
    ├── minimal-setup.png
    ├── developer-setup.png
    ├── custom-theme.png
    ├── work-profile.png
    └── personal-profile.png
```

---

## 🎨 **TOML Configuration Examples**

### 1. Minimal Configuration (`minimal-config.toml`)
**Purpose**: Lightning-fast performance with essential features only  
**Best for**: Slow systems, limited bandwidth, CI/CD environments  

**Key Features**:
- Classic ANSI theme for maximum compatibility
- Reduced timeouts (1s) for speed
- Network-dependent features disabled
- Simplified labels and minimal emojis
- Extended caching for performance

**Usage**:
```bash
cp examples/sample-configs/minimal-config.toml Config.toml
./statusline.sh # Configuration is automatically loaded
```

---

### 2. Developer Configuration (`developer-config.toml`)
**Purpose**: Maximum information display with all features enabled  
**Best for**: Active development, comprehensive monitoring  

**Key Features**:
- Catppuccin theme for modern aesthetics
- All features enabled (MCP, cost tracking, version info)
- Extended timeouts (5s) for comprehensive data gathering
- Descriptive labels and comprehensive error messages
- Detailed time format with seconds

**Usage**:
```bash
cp examples/sample-configs/developer-config.toml Config.toml
./statusline.sh # Configuration is automatically loaded
```

---

### 3. Custom Theme (`custom-theme.toml`)
**Purpose**: Template for creating beautiful custom themes  
**Best for**: Users who want calming, nature-inspired aesthetics  

**Key Features**:
- Custom color palette template (configurable colors)
- Custom emoji configuration examples
- Custom label templates  
- Balanced color combinations for readability
- Calming timeout settings

**Usage**:
```bash
cp examples/sample-configs/custom-theme.toml Config.toml
./statusline.sh # Configuration is automatically loaded
```

---

### 4. Work Profile (`work-profile.toml`)
**Purpose**: Professional configuration optimized for work environments  
**Best for**: Professional development, billing-conscious environments  

**Key Features**:
- Classic theme for professional compatibility
- Cost tracking emphasized for billing awareness
- Business-oriented labels ("PROJECT", "PRODUCTIVITY", "BILLING")
- Professional emojis (💼 for work, 💰 for billing)
- Optimized for work network environments

**Usage**:
```bash
cp examples/sample-configs/work-profile.toml Config.toml
./statusline.sh # Configuration is automatically loaded
```

---

### 5. Personal Profile (`personal-profile.toml`)
**Purpose**: Relaxed configuration for personal projects and hobbies  
**Best for**: Personal projects, learning, experimentation  

**Key Features**:
- Garden theme for gentle, soothing colors
- Cost tracking disabled (not needed for personal use)
- Fun, creative emojis (🎭 for Opus, 🦋 for Haiku, 🌿 for clean)
- Casual labels ("Today:", "HOBBY")
- 12-hour time format with AM/PM
- Performance mode for responsive feel

**Usage**:
```bash
cp examples/sample-configs/personal-profile.toml Config.toml
./statusline.sh # Configuration is automatically loaded
```

---

## 🔧 **How to Use TOML Examples**

### Method 1: Direct Copy (Recommended)
```bash
# Choose your preferred configuration
cp examples/sample-configs/developer-config.toml Config.toml

# Customize as needed
vim Config.toml

# Test your configuration
./statusline.sh # Configuration is automatically loaded
```

### Method 2: Generate Base + Merge Examples
```bash
# Generate your current config as base
cp examples/Config.toml ./Config.toml

# Then copy specific sections from examples
# For example, copy [theme] section from custom-theme.toml
```

### Method 3: Multiple Configuration Files
```bash
# Keep multiple configurations for different contexts
cp examples/sample-configs/work-profile.toml work-config.toml
cp examples/sample-configs/personal-profile.toml personal-config.toml

# Use specific configurations
./statusline.sh # Configuration is automatically loaded work-config.toml
./statusline.sh # Configuration is automatically loaded personal-config.toml
```

---

## 🌍 **Environment Variable Testing**

Test any configuration instantly without copying files:

```bash
# Test minimal performance setup
ENV_CONFIG_THEME=classic \
ENV_CONFIG_SHOW_MCP_STATUS=false \
ENV_CONFIG_SHOW_COST_TRACKING=false \
./statusline.sh

# Test work environment
ENV_CONFIG_THEME=classic \
ENV_CONFIG_SHOW_COST_TRACKING=true \
./statusline.sh

# Test personal setup  
ENV_CONFIG_THEME=garden \
ENV_CONFIG_SHOW_COST_TRACKING=false \
./statusline.sh
```

---

## 🎨 **Creating Your Own Configuration**

### Step 1: Start with Base Example
```bash
# Choose the closest example to your needs
cp examples/sample-configs/developer-config.toml MyConfig.toml
```

### Step 2: Customize Incrementally
```bash
# Edit specific sections
vim MyConfig.toml

# Test each change
./statusline.sh # Configuration is automatically loaded MyConfig.toml
```

### Step 3: Mix and Match Features
```toml
# Combine features from different examples
[theme]
name = "catppuccin"  # From developer-config.toml

[features]
show_cost_tracking = false  # From personal-profile.toml

[emojis]
clean_status = "🌊"  # From custom-theme.toml
```

---

## 📊 **Configuration Comparison**

| Feature | Minimal | Developer | Ocean | Work | Personal |
|---------|---------|-----------|--------|------|----------|
| **Theme** | Classic | Catppuccin | Custom Ocean | Classic | Garden |
| **Cost Tracking** | ❌ | ✅ | ✅ | ✅ | ❌ |
| **MCP Status** | ❌ | ✅ | ✅ | ✅ | ❌ |
| **Version Info** | ❌ | ✅ | ✅ | ✅ | ❌ |
| **Timeouts** | 1s (Fast) | 5s (Comprehensive) | 4s (Calm) | 3s (Professional) | 2s (Quick) |
| **Labels** | Short | Descriptive | Ocean-themed | Business | Casual |
| **Best For** | Performance | Development | Aesthetics | Work | Personal |

---

## 🔧 **Configuration Management Commands**

### Testing Examples
```bash
# Test any example configuration
./statusline.sh # Configuration is automatically loaded examples/sample-configs/developer-config.toml

# Detailed testing with verbose output
./statusline.sh # Configuration is automatically loaded-verbose examples/sample-configs/custom-theme.toml

# Compare example with your current setup
cp examples/sample-configs/work-profile.toml Config.toml
./statusline.sh --compare-config
```

### Configuration Validation
```bash
# Validate any TOML configuration
./statusline.sh --validate-config examples/sample-configs/minimal-config.toml

# Test specific configurations
for config in examples/sample-configs/*.toml; do
    echo "Testing $config..."
    ./statusline.sh # Configuration is automatically loaded "$config"
done
```

---

## 🎯 **Use Case Recommendations**

### 🚀 **Performance-Critical Environments**
- **Use**: `minimal-config.toml`
- **Why**: Reduced network calls, shorter timeouts, essential features only
- **Perfect for**: CI/CD, slow networks, resource-constrained systems

### 💻 **Active Development**
- **Use**: `developer-config.toml`
- **Why**: All features enabled, comprehensive monitoring, detailed information
- **Perfect for**: Daily development, debugging, feature-rich environments

### 🎨 **Aesthetic Focus**
- **Use**: `custom-theme.toml` or create custom themes
- **Why**: Beautiful custom colors, themed emojis, cohesive design
- **Perfect for**: Personal branding, visual appeal, unique workflows

### 💼 **Professional Work**
- **Use**: `work-profile.toml`
- **Why**: Cost tracking, professional appearance, business terminology
- **Perfect for**: Client work, billing tracking, corporate environments

### 🏠 **Personal Projects**
- **Use**: `personal-profile.toml`
- **Why**: Fun emojis, relaxed settings, no cost tracking
- **Perfect for**: Hobby projects, learning, experimentation

---

## 🐛 **Example-Specific Troubleshooting**

### Configuration Not Loading
```bash
# Check if TOML syntax is valid
./statusline.sh --validate-config examples/sample-configs/developer-config.toml

# Test configuration loading
./statusline.sh # Configuration is automatically loaded-verbose examples/sample-configs/custom-theme.toml
```

### Colors Not Displaying (Ocean Theme)
```bash
# Test terminal color support
echo $COLORTERM

# Fallback to basic theme if RGB not supported
ENV_CONFIG_THEME=classic ./statusline.sh
```

### Performance Issues (Developer Config)
```bash
# Reduce timeouts if needed
ENV_CONFIG_MCP_TIMEOUT=2s \
ENV_CONFIG_CCUSAGE_TIMEOUT=2s \
./statusline.sh # Configuration is automatically loaded examples/sample-configs/developer-config.toml
```

---

## 💡 **Tips for Custom Configurations**

1. **Start Simple**: Begin with minimal-config.toml and add features incrementally
2. **Test Thoroughly**: Use `--test-config` after every change
3. **Mix and Match**: Combine theme from one example with features from another
4. **Document Changes**: Add comments to your Config.toml explaining customizations
5. **Backup Working Configs**: Save successful configurations with descriptive names
6. **Environment Testing**: Use ENV_CONFIG_* variables to test before committing changes

---

## 📚 **Related Documentation**

- ⚙️ **[Configuration Guide](../docs/configuration.md)** - Complete TOML configuration reference
- 🎨 **[Themes Guide](../docs/themes.md)** - Theme creation and customization
- 📦 **[Installation Guide](../docs/installation.md)** - Setup with TOML configuration
- 🚀 **[Migration Guide](../docs/migration.md)** - Migrate from inline configuration
- 🔧 **[CLI Reference](../docs/cli-reference.md)** - Configuration management commands

---

**MashaAllah!** These examples showcase the power and flexibility of TOML configuration. Choose your starting point and customize to create your perfect development environment! 🌟