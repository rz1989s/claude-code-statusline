# 📚 Examples Directory - TOML Configuration Samples

**Ready-to-use TOML configuration examples for Claude Code Enhanced Statusline.**

This directory contains professionally crafted configuration templates that demonstrate the power and flexibility of the enterprise-grade TOML configuration system.

> 📍 **Note**: Configuration lives in a single location: `~/.claude/statusline/Config.toml` for simplicity and consistency.

## 🚀 **Quick Start with Examples**

### ⚛️ **Atomic Component System (v2.7.0 - LATEST & RECOMMENDED)**

**Ultimate customization with 16 atomic components - eliminate separator issues:**

```bash
# 🔬 ATOMIC SHOWCASE: Perfect demonstration of atomic components
cp ~/.claude/statusline/examples/Config.modular-atomic.toml ~/.claude/statusline/Config.toml

# 🎯 ATOMIC BENEFITS:
# • Clean visual separation: 30DAY $660.87 │ 7DAY $9.31 │ DAY $36.10  
# • Maximum control: Pick only commits OR submodules
# • Mix & match: Combine atomic and legacy components
# • Backward compatible: All old configs still work

# Test your atomic configuration
./statusline.sh
```

### 🧩 **Modular System Layouts (v2.6.0)**

**Revolutionary 1-9 line configurable system - choose your perfect layout:**

```bash
# Ultra-minimal: Perfect for beginners or performance focus  
cp ~/.claude/statusline/examples/Config.modular-minimal.toml ~/.claude/statusline/Config.toml

# Essential compact: Clean 3-line layout with core features
cp ~/.claude/statusline/examples/Config.modular-compact.toml ~/.claude/statusline/Config.toml

# Comprehensive: Full 7-line display with all features including prayer times
cp ~/.claude/statusline/examples/Config.modular-comprehensive.toml ~/.claude/statusline/Config.toml

# Extended: Strategic 8-line layout with breathing room
cp ~/.claude/statusline/examples/Config.modular-extended.toml ~/.claude/statusline/Config.toml

# Maximum: Ultimate 9-line display with maximum detail
cp ~/.claude/statusline/examples/Config.modular-maximum.toml ~/.claude/statusline/Config.toml

# Creative custom: Mix atomic & legacy components  
cp ~/.claude/statusline/examples/Config.modular-custom.toml ~/.claude/statusline/Config.toml

# Test your configuration
./statusline.sh
```

### 🎯 **Legacy Configuration Quick Start**

```bash
# Traditional feature-based configurations (sample-configs/)
cp ~/.claude/statusline/examples/sample-configs/developer-config.toml ~/.claude/statusline/Config.toml
cp ~/.claude/statusline/examples/sample-configs/work-profile.toml ~/.claude/statusline/Config.toml

# Test your configuration  
./statusline.sh
```

---

## 📁 **Directory Structure**

```
examples/
├── README.md                           # Comprehensive examples documentation
│
├── 🧩 MODULAR SYSTEM EXAMPLES (v2.6.0) - Revolutionary 1-9 Line Configuration
├── Config.modular-minimal.toml         # Ultra-minimal 2-line layout
├── Config.modular-compact.toml         # Essential 3-line layout  
├── Config.modular-standard.toml        # Standard 5-line reproduction
├── Config.modular-comprehensive.toml   # Full 7-line comprehensive display
├── Config.modular-extended.toml        # Extended 8-line strategic layout
├── Config.modular-maximum.toml         # Maximum 9-line ultimate display
├── Config.modular-custom.toml          # Creative 6-line component reordering
│
├── 🎯 TRADITIONAL CONFIGURATION EXAMPLES
├── Config.base.toml                    # Base configuration template
├── Config.advanced.toml                # Advanced features showcase
├── Config.prayer.toml                  # Islamic prayer times focused
├── Config.toml                         # Master configuration template (installed as default)
│
├── 📁 sample-configs/                  # Legacy profile-based configurations
│   ├── minimal-config.toml            # Performance-optimized, lightweight
│   ├── developer-config.toml          # Full-featured developer setup
│   ├── ocean-theme.toml               # Custom ocean theme template
│   ├── work-profile.toml              # Professional work environment
│   └── personal-profile.toml          # Relaxed personal project setup
│
└── 📸 screenshots/                     # Visual previews of different layouts
    ├── modular-minimal.png
    ├── modular-compact.png
    ├── modular-comprehensive.png
    ├── work-profile.png
    └── personal-profile.png
```

---

## 🧩 **Modular System Examples (v2.6.0)**

**Revolutionary component-based configuration system with 1-9 line flexibility!**

### 1. Ultra-Minimal Configuration (`Config.modular-minimal.toml`)
**Purpose**: Absolute minimum viable statusline with 2-line layout  
**Best for**: Extreme minimalists, low-resource systems, first-time users  

**Key Features**:
- **📐 2-line layout** with essential components only
- **🧩 Components**: `repo_info`, `model_info`, `cost_session`
- **⚡ Classic theme** for maximum compatibility
- **🚀 Ultra-fast execution** with minimal overhead
- **Perfect introduction** to the modular system

**Layout Preview**:
```toml
display.lines = 2
display.line1.components = ["repo_info", "model_info"]     # Repository + Model
display.line2.components = ["cost_session"]                # Session cost only
```

**Usage**:
```bash
cp ~/.claude/statusline/examples/Config.modular-minimal.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

---

### 2. Essential Compact Configuration (`Config.modular-compact.toml`)
**Purpose**: Clean 3-line layout with core features  
**Best for**: Users wanting essential info without clutter  

**Key Features**:
- **📐 3-line layout** with core components
- **🧩 Components**: Repository, git stats, model, session cost, MCP status
- **🎯 Focused display** - each line serves a specific purpose
- **⚡ Fast performance** with intelligent component selection

**Layout Preview**:
```toml
display.lines = 3
display.line1.components = ["repo_info", "git_stats"]      # Repository info
display.line2.components = ["model_info", "cost_session"]  # Model + costs
display.line3.components = ["mcp_status"]                  # MCP monitoring
```

**Usage**:
```bash
cp ~/.claude/statusline/examples/Config.modular-compact.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

---

### 3. Standard Reproduction Configuration (`Config.modular-standard.toml`)
**Purpose**: Reproduces classic 5-line layout using modular system  
**Best for**: Users migrating from legacy system  

**Key Features**:
- **📐 5-line layout** matching original statusline
- **🧩 All components** in familiar arrangement
- **🔄 Perfect migration path** from legacy system
- **✨ Modern benefits** with modular flexibility
- **🕌 Islamic prayer times** integration

**Layout Preview**:
```toml
display.lines = 5
display.line1.components = ["repo_info", "git_stats", "version_info", "time_display"]
display.line2.components = ["model_info", "cost_session", "cost_period", "cost_live"]
display.line3.components = ["mcp_status"]
display.line4.components = ["reset_timer"]
display.line5.components = ["prayer_times"]
```

**Usage**:
```bash
cp examples/Config.modular-standard.toml Config.toml
./statusline.sh
```

---

### 4. Comprehensive Full Configuration (`Config.modular-comprehensive.toml`)
**Purpose**: Maximum information display with strategic 7-line arrangement  
**Best for**: Power users wanting complete monitoring dashboard  

**Key Features**:
- **📐 7-line layout** with comprehensive information
- **🕌 Islamic prayer times priority** display (line 1)
- **📊 Strategic component grouping** for optimal readability
- **🎨 Garden theme** for soothing aesthetics
- **🌟 Custom separators** for visual variety

**Layout Preview**:
```toml
display.lines = 7
display.line1.components = ["prayer_times"]                           # Prayer priority
display.line2.components = ["repo_info", "git_stats"]                 # Repository
display.line3.components = ["model_info", "version_info", "time_display"] # System
display.line4.components = ["cost_session", "cost_live"]              # Live costs
display.line5.components = ["cost_period"]                            # Period costs
display.line6.components = ["mcp_status"]                             # MCP monitoring
display.line7.components = ["reset_timer"]                            # Reset timer
```

**Usage**:
```bash
cp ~/.claude/statusline/examples/Config.modular-comprehensive.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

---

### 5. Extended Strategic Configuration (`Config.modular-extended.toml`)
**Purpose**: Extended 8-line layout with strategic component separation and breathing room  
**Best for**: Users wanting comprehensive information with clear visual organization  

**Key Features**:
- **📐 8-line layout** with strategic component grouping
- **🕌 Prayer times priority** - Dedicated line 1 for Islamic timekeeping
- **🌿 Garden theme** - Soft pastels for comfortable reading with many lines
- **⚡ Strategic separators** - Different icons for different content types
- **🕐 Time separator line** - Clean visual break between sections
- **💰 Cost grouping** - Session, period, and live costs logically organized
- **🔌 MCP monitoring** - Combined with live operations for efficiency

**Layout Preview**:
```toml
display.lines = 8
display.line1.components = ["prayer_times"]                    # Prayer priority
display.line2.components = ["repo_info", "git_stats"]          # Repository context
display.line3.components = ["model_info", "version_info"]      # System info
display.line4.components = ["time_display"]                    # Clean separator
display.line5.components = ["cost_session"]                    # Session tracking
display.line6.components = ["cost_period"]                     # Period analysis
display.line7.components = ["cost_live", "mcp_status"]         # Live operations
display.line8.components = ["reset_timer"]                     # Reset timer
```

**Usage**:
```bash
cp ~/.claude/statusline/examples/Config.modular-extended.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

---

### 6. Maximum Ultimate Configuration (`Config.modular-maximum.toml`)
**Purpose**: Maximum 9-line layout demonstrating ultimate information density and system capability  
**Best for**: Power users with large monitors wanting complete information visibility  

**Key Features**:
- **📐 9-line layout** - Maximum system capability demonstration
- **🎨 Catppuccin theme** - Rich colors optimized for high information density
- **🔍 Component isolation** - Each major component type on its own line
- **📊 Ultimate detail** - Extended timeouts for comprehensive data collection
- **🏷️ Rich labeling** - Descriptive emoji labels for visual appeal
- **⚙️ Advanced settings** - All configuration options enabled
- **🕐 Precision timing** - Second-level timestamps for detailed tracking

**Layout Preview**:
```toml
display.lines = 9
display.line1.components = ["prayer_times"]                    # Priority prayer times
display.line2.components = ["repo_info"]                       # Repository only
display.line3.components = ["git_stats"]                       # Git stats only
display.line4.components = ["model_info"]                      # Model standalone
display.line5.components = ["version_info", "time_display"]    # System info
display.line6.components = ["cost_session"]                    # Session cost
display.line7.components = ["cost_period"]                     # Period costs
display.line8.components = ["mcp_status"]                      # MCP monitoring
display.line9.components = ["cost_live", "reset_timer"]        # Live operations
```

**Usage**:
```bash
cp ~/.claude/statusline/examples/Config.modular-maximum.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

---

### 7. Creative Custom Configuration (`Config.modular-custom.toml`)
**Purpose**: Demonstrates flexible component reordering and creative arrangements  
**Best for**: Users wanting personalized layouts and component mixing  

**Key Features**:
- **📐 6-line layout** with creative component reordering
- **🔌 MCP status first** - developer priority example
- **🕌 Prayer times second** - Islamic timekeeping prominence
- **🎨 Catppuccin theme** with custom separators
- **💡 Shows modular flexibility** in action

**Layout Preview**:
```toml
display.lines = 6
display.line1.components = ["mcp_status", "version_info"]           # MCP first!
display.line2.components = ["prayer_times", "time_display"]         # Prayer priority
display.line3.components = ["repo_info", "model_info"]              # Repository + model
display.line4.components = ["git_stats"]                            # Git stats isolated
display.line5.components = ["cost_session", "cost_period", "cost_live"] # All costs together
display.line6.components = ["reset_timer"]                          # Timer when active
```

**Usage**:
```bash
cp ~/.claude/statusline/examples/Config.modular-custom.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

---

## 🎯 **Legacy Configuration Examples**

**Traditional feature-based configuration for specific use cases:**

### Master Configuration Template (`Config.toml`)
**Purpose**: Comprehensive default configuration template installed with the system  
**Best for**: Base template for all installations, learning TOML structure, complete reference  

**Key Features**:
- **📋 Complete configuration template** - Shows all available settings with examples
- **🎨 Catppuccin theme default** - Modern theme with excellent terminal compatibility
- **📖 Extensive documentation** - Inline comments explaining every setting
- **🔧 Dot notation TOML** - Uses flat structure (theme.name = "value") for reliable parsing
- **⚙️ Configuration precedence guide** - Documents ENV_CONFIG_*, project configs, user configs
- **🌈 Custom color examples** - Full ANSI, 256-color, and RGB color palette templates
- **🎯 Installation default** - This file becomes ~/.claude/statusline/Config.toml during installation

**Usage**:
```bash
# Already installed as default user configuration
# Copy to project directory for project-specific customization
cp examples/Config.toml Config.toml
./statusline.sh
```

### Work Profile (`sample-configs/work-profile.toml`)
**Purpose**: Professional configuration optimized for work environments  
**Best for**: Professional development, billing-conscious environments  

**Usage**:
```bash
cp ~/.claude/statusline/examples/sample-configs/work-profile.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

### Personal Profile (`sample-configs/personal-profile.toml`)
**Purpose**: Relaxed configuration for personal projects  
**Best for**: Hobby projects, learning, experimentation  

**Usage**:
```bash
cp examples/sample-configs/personal-profile.toml Config.toml
./statusline.sh
```

### Ocean Theme (`sample-configs/ocean-theme.toml`)
**Purpose**: Custom theme template with ocean-inspired colors  
**Best for**: Users wanting calming, nature-inspired aesthetics  

**Usage**:
```bash
cp examples/sample-configs/ocean-theme.toml Config.toml
./statusline.sh
```

### Developer Profile (`sample-configs/developer-config.toml`)
**Purpose**: Maximum information display with comprehensive feature set  
**Best for**: Power developers, debugging sessions, comprehensive monitoring  

**Key Features**:
- **🤖 Catppuccin theme** - Modern dark theme optimized for developers
- **📊 All features enabled** - Complete information display including commits, versions, MCP status, cost tracking
- **⏱️ Extended timeouts** - Longer timeouts (5s MCP, 3s version, 5s cost) for detailed information gathering
- **🎯 Precision timestamps** - Includes seconds (%H:%M:%S) for accurate time tracking
- **📝 Descriptive labels** - Full descriptive labels like "Today's Commits:", "Repository Cost", "MCP Servers"
- **🔥 Developer emojis** - Brain (🧠), lightning (⚡), music (🎵), fire (🔥) for visual coding context

**Usage**:
```bash
cp ~/.claude/statusline/examples/sample-configs/developer-config.toml ~/.claude/statusline/Config.toml
./statusline.sh
```

### Minimal Profile (`sample-configs/minimal-config.toml`)
**Purpose**: Performance-optimized configuration for ultra-fast execution  
**Best for**: CI/CD pipelines, limited bandwidth environments, quick status checks  

**Key Features**:
- **⚡ Classic theme** - Maximum compatibility with all terminal types
- **🚀 Reduced feature set** - Only essential features enabled (commits tracking only)
- **⏱️ Ultra-fast timeouts** - 1s timeouts for lightning-fast execution
- **📋 Short labels** - Minimal labels (C:, R, M, W, D) to reduce screen space
- **✓ Simple emojis** - Basic checkmark (✓) and exclamation (!) for status
- **💾 Extended caching** - 2-hour version cache for maximum performance
- **🎯 Performance-first** - Designed for sub-second statusline responses

**Usage**:
```bash
cp examples/sample-configs/minimal-config.toml Config.toml
./statusline.sh
```

---

## 🔧 **How to Use Examples**

### 🧩 **Method 1: Modular System (Recommended)**
**Start with revolutionary 1-9 line configuration system:**

```bash
# Choose your perfect layout
cp ~/.claude/statusline/examples/Config.modular-minimal.toml ~/.claude/statusline/Config.toml        # 2-line minimal
cp ~/.claude/statusline/examples/Config.modular-compact.toml ~/.claude/statusline/Config.toml        # 3-line compact
cp ~/.claude/statusline/examples/Config.modular-comprehensive.toml ~/.claude/statusline/Config.toml  # 7-line comprehensive

# Customize component arrangements
vim Config.toml
# Edit display.lineN.components arrays to reorder components

# Test instantly
./statusline.sh
```

**🚀 Instant Layout Testing:**
```bash
# Test different line counts without copying files
ENV_CONFIG_DISPLAY_LINES=2 ./statusline.sh   # Test 2-line minimal
ENV_CONFIG_DISPLAY_LINES=5 ./statusline.sh   # Test 5-line standard
ENV_CONFIG_DISPLAY_LINES=7 ./statusline.sh   # Test 7-line comprehensive

# Test custom component arrangements
ENV_CONFIG_LINE1_COMPONENTS="mcp_status,prayer_times" \
ENV_CONFIG_LINE2_COMPONENTS="repo_info,model_info" \
./statusline.sh
```

### 🎯 **Method 2: Legacy Profiles**
**Traditional feature-based configurations:**

```bash
# Choose your use case
cp ~/.claude/statusline/examples/sample-configs/work-profile.toml ~/.claude/statusline/Config.toml     # Professional work
cp examples/sample-configs/personal-profile.toml Config.toml # Personal projects
cp examples/sample-configs/ocean-theme.toml Config.toml     # Custom theme

# Customize features
vim Config.toml
# Edit features.* and theme.* sections

# Test configuration
./statusline.sh
```

### 🔧 **Method 3: Hybrid Approach**
**Combine modular layouts with legacy features:**

```bash
# Start with modular layout
cp ~/.claude/statusline/examples/Config.modular-compact.toml ~/.claude/statusline/Config.toml

# Add theme and features from legacy examples
# Copy [theme] section from ocean-theme.toml
# Copy [features] section from work-profile.toml

# Test your hybrid configuration
./statusline.sh
```

### 📋 **Method 4: Multiple Context Configurations**
```bash
# Create different configs for different contexts
cp examples/Config.modular-minimal.toml work-config.toml     # Minimal for work
cp examples/Config.modular-comprehensive.toml home-config.toml # Full for personal

# Use specific configurations by copying when needed
cp work-config.toml Config.toml   # Switch to work mode
cp home-config.toml Config.toml   # Switch to personal mode
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

### 🧩 **Modular System Comparison (v2.6.0)**

| Feature | Minimal | Compact | Standard | Comprehensive | Extended | Maximum | Custom |
|---------|---------|---------|----------|---------------|----------|---------|--------|
| **Lines** | 2 | 3 | 5 | 7 | 8 | 9 | 6 |
| **Components** | 3 | 5 | 11 | 11 | 11 | 11 | 10 |
| **Theme** | Classic | Classic | Catppuccin | Garden | Garden | Catppuccin | Catppuccin |
| **Prayer Times** | ❌ | ❌ | ✅ | ✅ (Priority) | ✅ (Priority) | ✅ (Priority) | ✅ |
| **MCP Status** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ (Dedicated) | ✅ (First!) |
| **Cost Tracking** | Session Only | Session Only | Full | Full | Full (Grouped) | Full (Separated) | Full |
| **Component Separation** | Minimal | Compact | Standard | Grouped | Strategic | Ultimate | Creative |
| **Performance** | Ultra-Fast | Fast | Standard | Comprehensive | Extended | Ultimate | Custom |
| **Best For** | Beginners, CI/CD | Essential Info | Migration | Power Users | Large Monitors | Maximum Detail | Personalization |

### 🎯 **Legacy Profiles Comparison**

| Feature | Config.toml | Work Profile | Personal Profile | Developer Profile | Minimal Profile | Ocean Theme |
|---------|-------------|-------------|------------------|-------------------|----------------|-------------|
| **Theme** | Catppuccin | Classic | Garden | Catppuccin | Classic | Custom Ocean |
| **Cost Tracking** | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| **MCP Status** | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| **Timeouts** | Standard | Standard | Standard | Extended (5s) | Ultra-Fast (1s) | Standard |
| **Labels** | Standard | Business | Casual | Descriptive | Minimal | Ocean-themed |
| **Best For** | Template/Default | Professional | Hobby Projects | Power Development | Performance/CI | Aesthetics |

---

## 🔧 **Configuration Management Commands**

### 🧩 **Testing Modular Examples**
```bash
# Test any modular configuration instantly
cp ~/.claude/statusline/examples/Config.modular-minimal.toml ~/.claude/statusline/Config.toml && ./statusline.sh
cp ~/.claude/statusline/examples/Config.modular-compact.toml ~/.claude/statusline/Config.toml && ./statusline.sh
cp ~/.claude/statusline/examples/Config.modular-comprehensive.toml ~/.claude/statusline/Config.toml && ./statusline.sh
cp ~/.claude/statusline/examples/Config.modular-extended.toml ~/.claude/statusline/Config.toml && ./statusline.sh
cp ~/.claude/statusline/examples/Config.modular-maximum.toml ~/.claude/statusline/Config.toml && ./statusline.sh

# Test with environment variables (no file changes needed)
ENV_CONFIG_DISPLAY_LINES=2 ./statusline.sh  # Test 2-line layout
ENV_CONFIG_DISPLAY_LINES=7 ./statusline.sh  # Test 7-line layout  
ENV_CONFIG_DISPLAY_LINES=8 ./statusline.sh  # Test 8-line layout
ENV_CONFIG_DISPLAY_LINES=9 ./statusline.sh  # Test 9-line layout

# Test custom component arrangements
ENV_CONFIG_LINE1_COMPONENTS="mcp_status,version_info" ./statusline.sh
```

### 🎯 **Testing Legacy Examples**
```bash
# Test master configuration template
cp examples/Config.toml Config.toml && ./statusline.sh

# Test legacy profile configurations
cp ~/.claude/statusline/examples/sample-configs/work-profile.toml ~/.claude/statusline/Config.toml && ./statusline.sh
cp examples/sample-configs/personal-profile.toml Config.toml && ./statusline.sh
cp ~/.claude/statusline/examples/sample-configs/developer-config.toml ~/.claude/statusline/Config.toml && ./statusline.sh
cp examples/sample-configs/minimal-config.toml Config.toml && ./statusline.sh
cp examples/sample-configs/ocean-theme.toml Config.toml && ./statusline.sh

# Compare example with your current setup
./statusline.sh --compare-config
```

### 📋 **Configuration Validation**
```bash
# Validate any TOML configuration
./statusline.sh --validate-config examples/Config.modular-minimal.toml
./statusline.sh --validate-config examples/sample-configs/work-profile.toml

# Test all modular configurations
for config in examples/Config.modular-*.toml; do
    echo "Testing $config..."
    cp "$config" Config.toml && ./statusline.sh
done

# Test all legacy configurations  
for config in examples/sample-configs/*.toml; do
    echo "Testing $config..."
    cp "$config" Config.toml && ./statusline.sh
done
```

---

## 🎯 **Use Case Recommendations**

### 🧩 **Modular System Recommendations (v2.6.0)**

### 🚀 **First-Time Users / Performance Focus**
- **Use**: `Config.modular-minimal.toml`
- **Why**: Ultra-minimal 2-line layout, fastest execution, perfect introduction to modular system
- **Perfect for**: Beginners, CI/CD, low-resource systems, quick setup

### 💻 **Essential Information Display**
- **Use**: `Config.modular-compact.toml`
- **Why**: Clean 3-line layout with core features, balanced information without clutter
- **Perfect for**: Daily development, focused workflows, essential monitoring

### 🔄 **Legacy System Migration**
- **Use**: `Config.modular-standard.toml`
- **Why**: Reproduces familiar 5-line layout with modular system benefits
- **Perfect for**: Existing users, gradual transition, maintaining familiar workflow

### 🌟 **Power User Dashboard**
- **Use**: `Config.modular-comprehensive.toml`
- **Why**: Complete 7-line information display with Islamic prayer times priority
- **Perfect for**: Power users, comprehensive monitoring, complete feature usage

### 🎨 **Personalization & Experimentation**
- **Use**: `Config.modular-custom.toml`
- **Why**: Creative component reordering example, shows full modular flexibility
- **Perfect for**: Customization enthusiasts, workflow optimization, learning modular system

### 🎯 **Legacy Profile Recommendations**

### 💼 **Professional Work Environment**
- **Use**: `sample-configs/work-profile.toml`
- **Why**: Professional themes, cost tracking emphasis, business terminology
- **Perfect for**: Client work, billing tracking, corporate environments

### 🏠 **Personal Projects & Learning**
- **Use**: `sample-configs/personal-profile.toml`
- **Why**: Relaxed settings, fun emojis, cost tracking disabled
- **Perfect for**: Hobby projects, learning, experimentation

### 🌊 **Custom Theme Focus**
- **Use**: `sample-configs/ocean-theme.toml`
- **Why**: Custom ocean-inspired color palette, themed aesthetics
- **Perfect for**: Visual appeal, custom color schemes, aesthetic preferences

---

## 🐛 **Example-Specific Troubleshooting**

### 🧩 **Modular Configuration Issues**

#### Modular Layout Not Displaying
```bash
# Validate modular configuration syntax
./statusline.sh --validate-config examples/Config.modular-comprehensive.toml

# Test modular configuration loading
cp ~/.claude/statusline/examples/Config.modular-minimal.toml ~/.claude/statusline/Config.toml
./statusline.sh

# Check if components are properly configured
ENV_CONFIG_DISPLAY_LINES=3 ./statusline.sh  # Force 3-line layout
```

#### Component Arrangement Problems
```bash
# Test individual component arrangement
ENV_CONFIG_LINE1_COMPONENTS="repo_info" ./statusline.sh
ENV_CONFIG_LINE2_COMPONENTS="model_info,cost_session" ./statusline.sh

# Debug component loading
STATUSLINE_DEBUG=true ./statusline.sh
```

### 🎯 **Legacy Configuration Issues**

#### Configuration Not Loading
```bash
# Check if TOML syntax is valid for legacy configs
./statusline.sh --validate-config examples/sample-configs/work-profile.toml

# Test configuration loading
cp examples/sample-configs/ocean-theme.toml Config.toml
./statusline.sh
```

#### Colors Not Displaying (Ocean Theme)
```bash
# Test terminal color support
echo $COLORTERM

# Fallback to basic theme if RGB not supported
ENV_CONFIG_THEME=classic ./statusline.sh

# Test ocean theme specifically
cp examples/sample-configs/ocean-theme.toml Config.toml
./statusline.sh
```

#### Performance Issues
```bash
# Use minimal configuration for performance
cp ~/.claude/statusline/examples/Config.modular-minimal.toml ~/.claude/statusline/Config.toml

# Or reduce timeouts in existing config
ENV_CONFIG_TIMEOUTS_MCP=2s \
ENV_CONFIG_TIMEOUTS_CCUSAGE=2s \
./statusline.sh
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