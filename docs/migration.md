# 🚀 Migration Guide - From Inline to TOML Configuration

**Complete step-by-step guide to migrating from inline script configuration to the enterprise-grade TOML configuration system.**

Transform your statusline configuration from scattered inline variables to structured, maintainable TOML files with zero downtime and full backwards compatibility.

## 🎯 **Migration Overview**

### Why Migrate to TOML?

**From This (Inline Configuration)**:
```bash
# Scattered throughout statusline.sh script:
CONFIG_THEME="catppuccin"
CONFIG_SHOW_COMMITS=true
CONFIG_MCP_TIMEOUT="3s"
CONFIG_RED="\\033[38;2;255;0;0m"
# ... 50+ more variables
```

**To This (TOML Configuration)**:
```toml
# Organized Config.toml file:
theme.name = "catppuccin"

features.show_commits = true

timeouts.mcp = "3s"

colors.basic.red = "\\033[38;2;255;0;0m"
```

### Benefits of TOML Configuration

✅ **Structured Organization** - Related settings grouped logically  
✅ **Validation & Testing** - Built-in syntax checking and testing tools  
✅ **Multiple Configurations** - Easy switching between work/personal profiles  
✅ **Version Control Friendly** - Clean diffs and merge-friendly structure  
✅ **Environment Overrides** - `ENV_CONFIG_*` variables for dynamic settings  
✅ **Professional Management** - Enterprise-grade configuration tools  
✅ **Backwards Compatible** - Your inline config continues to work as fallback  

---

## 🔄 **Migration Strategy**

### Zero-Downtime Migration

Your **existing configuration continues to work unchanged** during and after migration. The TOML system uses this priority order:

1. **Environment Variables** (`ENV_CONFIG_*`) - Highest priority
2. **TOML Configuration Files** - New system  
3. **Inline Script Configuration** - Your current setup (fallback)

This means you can migrate **gradually** and **safely** without any risk of breaking your existing setup.

---

## 📋 **Step-by-Step Migration Process**

### Phase 1: Assessment and Preparation

#### Step 1.1: Assess Your Current Configuration

```bash
# 1. Check your current statusline script location
ls -la ~/.claude/statusline/statusline.sh

# 2. Identify your current customizations
grep -n "CONFIG_" ~/.claude/statusline/statusline.sh | head -20

# 3. Test your current setup
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test"}}' | ~/.claude/statusline/statusline.sh
```

#### Step 1.2: Backup Your Current Configuration

```bash
# Create backup directory
mkdir -p ~/.claude/backups/$(date +%Y%m%d_%H%M%S)

# Backup your current script
cp ~/.claude/statusline/statusline.sh ~/.claude/backups/$(date +%Y%m%d_%H%M%S)/statusline.sh

# Document your current settings
grep "CONFIG_" ~/.claude/statusline/statusline.sh > ~/.claude/backups/$(date +%Y%m%d_%H%M%S)/current-config.txt
```

### Phase 2: Generate TOML Configuration

#### Step 2.1: Generate Base TOML Configuration

```bash
# Navigate to your preferred configuration location
cd ~/  # For user-wide config, or cd ~/project/ for project-specific

# Generate Config.toml from your current inline configuration
~/.claude/statusline/statusline.sh --generate-config

# This creates Config.toml with all your current settings
ls -la Config.toml
```

#### Step 2.2: Verify TOML Generation

```bash
# Test the generated configuration
~/.claude/statusline/statusline.sh --test-config

# Compare inline vs TOML to ensure accuracy
~/.claude/statusline/statusline.sh --compare-config

# Expected output shows your settings in both formats
```

### Phase 3: Test and Validate

#### Step 3.1: Validate TOML Syntax

```bash
# Validate the generated TOML syntax
~/.claude/statusline/statusline.sh --validate-config

# Should show: "Configuration validation passed"
```

#### Step 3.2: Test Functionality

```bash
# Test basic functionality
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test Model"}}' | ~/.claude/statusline/statusline.sh

# Test in a git repository
cd ~/some-git-repo
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Sonnet 4"}}' | ~/.claude/statusline/statusline.sh

# Verify output matches your previous setup
```

#### Step 3.3: Test Configuration Priority

```bash
# TOML should now take priority over inline config
# Test by temporarily changing theme in Config.toml
sed -i.bak 's/name = "catppuccin"/name = "garden"/' Config.toml

# Test the change
~/.claude/statusline/statusline.sh --test-config

# Should show garden theme, proving TOML takes priority
# Restore original if you prefer
mv Config.toml.bak Config.toml
```

### Phase 4: Customize and Enhance

#### Step 4.1: Organize Your Configuration

```toml
# Edit Config.toml to organize settings logically
vim Config.toml

# Example organized structure:
theme.name =
name = "catppuccin"

# Features section converted to flat format
show_commits = true
show_version = true
show_mcp_status = true
show_cost_tracking = true

# Timeouts section converted to flat format
mcp = "3s"
ccusage = "3s"
version = "2s"

# Emojis section converted to flat format
opus = "🧠"
sonnet = "🎵"
clean_status = "✅"
```

#### Step 4.2: Test Enhanced Features

```bash
# Test your organized configuration
~/.claude/statusline/statusline.sh --test-config

# Test environment overrides (new TOML feature)
ENV_CONFIG_THEME=classic ~/.claude/statusline/statusline.sh

# Test multiple configuration files (new TOML feature)
cp Config.toml work-config.toml
cp examples/sample-configs/personal-profile.toml personal-config.toml
~/.claude/statusline/statusline.sh --test-config work-config.toml
```

---

## 📊 **Detailed Migration Examples**

### Example 1: Basic Theme Migration

#### Before (Inline Configuration)
```bash
# In statusline.sh around line 34:
CONFIG_THEME="catppuccin"
```

#### After (TOML Configuration)
```toml
# In Config.toml:
theme.name =
name = "catppuccin"
```

#### Migration Commands
```bash
# Generate TOML
~/.claude/statusline/statusline.sh --generate-config

# Verify migration
~/.claude/statusline/statusline.sh --compare-config
# Should show both configurations match
```

### Example 2: Custom Colors Migration

#### Before (Inline Configuration)
```bash
# In statusline.sh:
CONFIG_THEME="custom"
CONFIG_RED="\\033[38;2;255;100;100m"
CONFIG_BLUE="\\033[38;2;100;150;255m"
CONFIG_GREEN="\\033[38;2;100;255;100m"
```

#### After (TOML Configuration)
```toml
# In Config.toml:
theme.name =
name = "custom"

# Colors.basic section converted to flat format
red = "\\033[38;2;255;100;100m"
blue = "\\033[38;2;100;150;255m"
green = "\\033[38;2;100;255;100m"
```

#### Migration Commands
```bash
# Generate base TOML
~/.claude/statusline/statusline.sh --generate-config

# Test custom theme
~/.claude/statusline/statusline.sh --test-config

# Should show your custom colors
```

### Example 3: Feature Toggles Migration

#### Before (Inline Configuration)
```bash
# In statusline.sh:
CONFIG_SHOW_COMMITS=true
CONFIG_SHOW_VERSION=false
CONFIG_SHOW_MCP_STATUS=true
CONFIG_SHOW_COST_TRACKING=false
```

#### After (TOML Configuration)
```toml
# In Config.toml:
# Features section converted to flat format
show_commits = true
show_version = false
show_mcp_status = true
show_cost_tracking = false
```

#### Migration Commands
```bash
# Generate and verify
~/.claude/statusline/statusline.sh --generate-config
~/.claude/statusline/statusline.sh --compare-config

# Test feature toggles
~/.claude/statusline/statusline.sh --test-config-verbose
```

### Example 4: Performance Settings Migration

#### Before (Inline Configuration)
```bash
# In statusline.sh:
CONFIG_MCP_TIMEOUT="5s"
CONFIG_VERSION_TIMEOUT="3s"
CONFIG_CCUSAGE_TIMEOUT="4s"
CONFIG_VERSION_CACHE_DURATION=3600
```

#### After (TOML Configuration)
```toml
# In Config.toml:
# Timeouts section converted to flat format
mcp = "5s"
version = "3s"
ccusage = "4s"

[cache]
version_duration = 3600
```

#### Migration Commands
```bash
# Generate configuration
~/.claude/statusline/statusline.sh --generate-config

# Test performance settings
time ~/.claude/statusline/statusline.sh --test-config
```

---

## 🎯 **Advanced Migration Scenarios**

### Scenario 1: Multiple Environment Migration

**Use Case**: Different configurations for work, personal, and demo environments.

#### Migration Strategy
```bash
# 1. Generate base configuration
~/.claude/statusline/statusline.sh --generate-config base-config.toml

# 2. Create environment-specific configurations
cp base-config.toml work-config.toml
cp examples/sample-configs/work-profile.toml work-config.toml

cp base-config.toml personal-config.toml
cp examples/sample-configs/personal-profile.toml personal-config.toml

# 3. Test each environment
~/.claude/statusline/statusline.sh --test-config work-config.toml
~/.claude/statusline/statusline.sh --test-config personal-config.toml

# 4. Deploy based on context
cp work-config.toml Config.toml  # For work projects
# or
cp personal-config.toml Config.toml  # For personal projects
```

### Scenario 2: Git-Based Configuration Migration

**Use Case**: Different configurations for different git repositories.

#### Migration Strategy
```bash
# 1. Generate user-wide default configuration
cd ~
~/.claude/statusline/statusline.sh --generate-config ~/.config/claude-code-statusline/Config.toml

# 2. Create project-specific configurations
cd ~/work/important-project
~/.claude/statusline/statusline.sh --generate-config ./Config.toml
# Edit to enable cost tracking, professional theme

cd ~/personal/hobby-project  
~/.claude/statusline/statusline.sh --generate-config ./Config.toml
# Edit to disable cost tracking, fun theme

# 3. Test project-specific configs
cd ~/work/important-project
~/.claude/statusline/statusline.sh --test-config  # Uses ./Config.toml

cd ~/personal/hobby-project
~/.claude/statusline/statusline.sh --test-config  # Uses ./Config.toml

cd ~/other-project
~/.claude/statusline/statusline.sh --test-config  # Uses ~/.config/.../Config.toml
```

### Scenario 3: Team Configuration Migration

**Use Case**: Standardized configuration across team members.

#### Migration Strategy
```bash
# 1. Create team standard configuration
~/.claude/statusline/statusline.sh --generate-config team-standard.toml

# 2. Customize for team needs (e.g., work profile)
cp examples/sample-configs/work-profile.toml team-standard.toml

# 3. Add to version control
git add team-standard.toml
git commit -m "Add team statusline configuration"

# 4. Team members deploy
cp team-standard.toml Config.toml
~/.claude/statusline/statusline.sh --test-config

# 5. Allow personal overrides via environment variables
ENV_CONFIG_THEME=garden ~/.claude/statusline/statusline.sh  # Personal preference
```

---

## 🔧 **Migration Tools and Commands**

### Configuration Generation Tools

```bash
# === BASIC GENERATION ===
~/.claude/statusline/statusline.sh --generate-config              # Current directory
~/.claude/statusline/statusline.sh --generate-config MyConfig.toml # Custom filename

# === LOCATION-SPECIFIC GENERATION ===
~/.claude/statusline/statusline.sh --generate-config ~/.config/claude-code-statusline/Config.toml  # XDG standard
~/.claude/statusline/statusline.sh --generate-config ~/.claude-statusline.toml                     # Home directory

# === TEMPLATE GENERATION ===
cp examples/sample-configs/developer-config.toml Config.toml    # Use example as base
cp examples/sample-configs/minimal-config.toml Config.toml      # Minimal base
```

### Validation and Testing Tools

```bash
# === VALIDATION TOOLS ===
~/.claude/statusline/statusline.sh --validate-config                      # Validate syntax
~/.claude/statusline/statusline.sh --validate-config MyConfig.toml        # Validate specific file

# === TESTING TOOLS ===
~/.claude/statusline/statusline.sh --test-config                          # Test current config
~/.claude/statusline/statusline.sh --test-config MyConfig.toml            # Test specific config
~/.claude/statusline/statusline.sh --test-config-verbose                  # Detailed testing

# === COMPARISON TOOLS ===
~/.claude/statusline/statusline.sh --compare-config                       # Compare inline vs TOML
```

### Migration Verification Tools

```bash
# === VERIFICATION COMMANDS ===
# 1. Check which config file is loaded
~/.claude/statusline/statusline.sh --test-config-verbose | grep -i "loading\|config"

# 2. Compare configurations
~/.claude/statusline/statusline.sh --compare-config

# 3. Test environment overrides
ENV_CONFIG_THEME=garden ~/.claude/statusline/statusline.sh --test-config

# 4. Test specific features
echo '{"workspace":{"current_dir":"'$(pwd)'"},"model":{"display_name":"Test"}}' | ~/.claude/statusline/statusline.sh
```

---

## 🐛 **Migration Troubleshooting**

### Issue 1: Configuration Not Generated

**Problem**: `--generate-config` doesn't create Config.toml file.

**Diagnosis**:
```bash
# Check for errors
~/.claude/statusline/statusline.sh --generate-config 2>&1

# Check permissions
ls -la ~/.claude/statusline/statusline.sh
ls -ld $(pwd)
```

**Solutions**:
```bash
# 1. Check script permissions
chmod +x ~/.claude/statusline/statusline.sh

# 2. Check directory permissions
chmod 755 $(pwd)

# 3. Generate with explicit path
~/.claude/statusline/statusline.sh --generate-config ./Config.toml
```

### Issue 2: TOML Not Taking Priority

**Problem**: Changes to Config.toml don't affect statusline output.

**Diagnosis**:
```bash
# Check configuration discovery
~/.claude/statusline/statusline.sh --test-config-verbose

# Should show: "Loading configuration from: ./Config.toml"
```

**Solutions**:
```bash
# 1. Verify file location precedence
ls -la Config.toml  # Highest priority (current directory)
ls -la ~/.config/claude-code-statusline/Config.toml
ls -la ~/.claude-statusline.toml

# 2. Test specific file
~/.claude/statusline/statusline.sh --test-config ./Config.toml

# 3. Clear any cached data
rm -f /tmp/.claude_*_cache
```

### Issue 3: Syntax Errors in Generated TOML

**Problem**: Generated TOML has syntax errors.

**Diagnosis**:
```bash
# Validate generated TOML
~/.claude/statusline/statusline.sh --validate-config

# Check for common issues
cat Config.toml | grep -E '^[^#]*=' | grep -v '".*"$'
```

**Solutions**:
```bash
# 1. Regenerate configuration
mv Config.toml Config.toml.bad
~/.claude/statusline/statusline.sh --generate-config

# 2. Use example as base if generation fails
cp examples/sample-configs/developer-config.toml Config.toml
~/.claude/statusline/statusline.sh --test-config

# 3. Fix common syntax issues manually
# Ensure all string values are quoted: name = "catppuccin"
# Ensure booleans are lowercase: show_commits = true
```

### Issue 4: Lost Customizations

**Problem**: Some inline customizations didn't migrate to TOML.

**Diagnosis**:
```bash
# Compare configurations
~/.claude/statusline/statusline.sh --compare-config

# Check for differences
diff <(grep CONFIG_ ~/.claude/statusline/statusline.sh) <(~/.claude/statusline/statusline.sh --generate-config --stdout 2>/dev/null)
```

**Solutions**:
```bash
# 1. Identify missing settings from backup
grep "CONFIG_" ~/.claude/backups/*/current-config.txt

# 2. Add missing settings manually to Config.toml
vim Config.toml

# 3. Test after adding each setting
~/.claude/statusline/statusline.sh --test-config
```

---

## ✅ **Migration Verification Checklist**

### Pre-Migration Checklist

- [ ] **Backup created**: Current statusline.sh backed up
- [ ] **Current settings documented**: CONFIG_* variables listed
- [ ] **Basic functionality tested**: Statusline works with current setup

### Post-Migration Checklist

- [ ] **Config.toml generated**: File exists and is readable
- [ ] **TOML syntax valid**: `--validate-config` passes
- [ ] **Configuration loads**: `--test-config-verbose` shows TOML loading
- [ ] **Output matches**: Visual output matches pre-migration appearance
- [ ] **Features work**: All enabled features function correctly
- [ ] **Environment overrides work**: `ENV_CONFIG_*` variables override TOML
- [ ] **Performance maintained**: No significant slowdown in execution

### Advanced Verification

- [ ] **Multiple configs tested**: Different TOML files work correctly
- [ ] **Git repo tested**: Works in git repositories with project-specific config
- [ ] **Network features tested**: MCP status, cost tracking, version info work
- [ ] **Theme system tested**: All themes (classic, garden, catppuccin, custom) work
- [ ] **Error handling tested**: Invalid TOML files are handled gracefully

---

## 🎯 **Post-Migration Optimization**

### Cleanup Old Configuration

```bash
# Once migration is successful and verified:

# 1. Document your inline configuration (for reference)
grep "CONFIG_" ~/.claude/statusline/statusline.sh > ~/.claude/inline-config-reference.txt

# 2. Consider removing inline overrides (optional)
# This step is OPTIONAL - inline config serves as fallback
# Only do this if you're confident in your TOML setup

# 3. Update your documentation/notes about the new system
```

### Leverage New TOML Features

```bash
# 1. Use environment overrides for temporary changes
ENV_CONFIG_THEME=garden ~/.claude/statusline/statusline.sh

# 2. Create multiple configurations for different contexts
cp Config.toml work-config.toml
cp examples/sample-configs/personal-profile.toml personal-config.toml

# 3. Use configuration management commands
~/.claude/statusline/statusline.sh --reload-interactive
~/.claude/statusline/statusline.sh --backup-config ~/statusline-backups/
```

### Share Your Configuration

```bash
# 1. Add to dotfiles repository
git add Config.toml
git commit -m "Add TOML statusline configuration"

# 2. Create team configurations
cp Config.toml team-statusline-config.toml

# 3. Contribute themes to community
# Consider sharing custom themes in GitHub discussions
```

---

## 🎉 **Migration Success!**

**Alhamdulillah!** You've successfully migrated to the enterprise-grade TOML configuration system! 

### What You've Gained

✅ **Structured Configuration** - Organized, maintainable settings  
✅ **Professional Tools** - Validation, testing, comparison commands  
✅ **Flexible Management** - Multiple configs, environment overrides  
✅ **Future-Proof Setup** - Ready for advanced features and enhancements  
✅ **Team Collaboration** - Shareable, version-controllable configurations  
✅ **Backwards Compatibility** - Your original setup remains as fallback  

### Next Steps

1. **📖 Explore Advanced Features** - Read [configuration.md](configuration.md) for advanced options
2. **🎨 Customize Your Themes** - Check [themes.md](themes.md) for theme creation
3. **🔧 Master CLI Tools** - See [cli-reference.md](cli-reference.md) for all commands
4. **🤝 Share Your Setup** - Contribute themes and configurations to the community

**Your statusline is now powered by enterprise-grade configuration management!** 🚀

---

## 📚 **Related Documentation**

- ⚙️ **[Configuration Guide](configuration.md)** - Complete TOML configuration reference
- 🎨 **[Themes Guide](themes.md)** - Theme creation and customization with TOML
- 📦 **[Installation Guide](installation.md)** - Platform-specific setup with TOML
- 🔧 **[CLI Reference](cli-reference.md)** - Complete command-line interface documentation
- 🐛 **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
- 📚 **[Examples](../examples/README.md)** - Ready-to-use TOML configuration templates

**MashaAllah!** Welcome to the future of statusline configuration management! 🌟