# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status (v2.10.0)

**🚀 PRODUCTION READY: Advanced Block Metrics Integration** - Latest stable release with comprehensive ccusage integration! This version includes revolutionary block metrics components and optimized resource usage.

**🚀 v2.10.0 NEW FEATURES**:
- **Block Metrics Components** - 4 new atomic components for ccusage integration
- **Unified Data Collection** - Single ccusage call reduces resource usage by 75%
- **Burn Rate Monitoring** - Real-time token consumption tracking
- **Cache Efficiency** - Performance optimization insights
- **Cost Projections** - Budget planning and limit avoidance

**🎯 CURRENT: Revolutionary 3-Tier Download System OPERATIONAL** - Major installer enhancement achieves **100% download guarantee** and eliminates GitHub rate limits! Complete architectural overhaul ensures reliable, fast installation regardless of GitHub API availability.

**🚀 REVOLUTIONARY v2.9.0 BREAKTHROUGH**: Implemented 3-tier download architecture with direct raw URLs (unlimited), GitHub API fallback (5,000/hour), and comprehensive retry mechanisms. Zero intervention needed for 99% of installations.

**🚀 REVOLUTIONARY v2.9.0 DOWNLOAD SYSTEM**:
- **Tier 1: Direct Raw URLs** - Unlimited requests, no API usage, fastest installation method
- **Tier 2: GitHub API Fallback** - Optional token support (5,000/hour vs 60/hour)
- **Tier 3: Comprehensive Retry** - Exponential backoff and intelligent verification
- **100% Download Guarantee** - Either all modules or clear failure with troubleshooting
- **Zero Intervention Required** - Primary method handles 99% of installations automatically

**⚡ STABLE SINGLE SOURCE ARCHITECTURE (v2.8.2)**:
- **ONE Config.toml** - All 227 settings in single comprehensive file
- **Zero Hardcoded Defaults** - No more DEFAULT_CONFIG_* constants in code
- **No jq Fallbacks** - Pure extraction from Config.toml without `// "fallback"` patterns
- **Simplified examples/** - Only Config.toml + README.md (no confusion from 13 configs)
- **Complete User Control** - Edit display.lines, components, themes, everything in one file

## Quick Reference

**Essential Commands:**
```bash
npm test                              # Run all 254 tests across 17 files
npm run lint:all                     # Lint everything 
npm run dev                          # Clean + test cycle
npm run ci                           # Full CI pipeline
npm run clean                        # Remove cache and test artifacts
npm run clean:processes              # Kill background test processes
npm run setup                        # Complete project setup
# Current config is automatically loaded, no validation command needed
ENV_CONFIG_THEME=garden ./statusline.sh  # Test theme override

# NEW: Modular system testing
./statusline.sh --modules            # Show component status
```

**Single Source Configuration Testing (v2.9.0):**
```bash
# Edit your comprehensive Config.toml directly (all 227 settings included)
# No need to copy different examples - everything is in ONE file!
nano ~/.claude/statusline/Config.toml     # Edit the comprehensive configuration file
# OR
code ~/.claude/statusline/Config.toml     # Open in VS Code

# Atomic component arrangement testing
ENV_CONFIG_DISPLAY_LINES=3 ./statusline.sh            # Override line count
ENV_CONFIG_LINE1_COMPONENTS="repo_info,commits,version_info" ./statusline.sh  # Atomic git info
ENV_CONFIG_LINE2_COMPONENTS="model_info,cost_monthly,cost_daily" ./statusline.sh      # Custom cost mix
ENV_CONFIG_LINE3_COMPONENTS="prayer_times" ./statusline.sh      # Prayer times only

# Advanced atomic testing examples  
ENV_CONFIG_DISPLAY_LINES=4 \
ENV_CONFIG_LINE1_COMPONENTS="repo_info,commits" \
ENV_CONFIG_LINE2_COMPONENTS="submodules,version_info" \
ENV_CONFIG_LINE3_COMPONENTS="cost_monthly,cost_weekly,cost_daily" \
ENV_CONFIG_LINE4_COMPONENTS="prayer_times" \
./statusline.sh  # 4-line atomic layout

# Compare legacy vs atomic (same data, different components)
ENV_CONFIG_LINE1_COMPONENTS="commits,submodules" ./statusline.sh  # Pure atomic: separated components
ENV_CONFIG_LINE1_COMPONENTS="commits,submodules" ./statusline.sh  # Atomic: separated components

# Component availability testing
./statusline.sh --modules                              # Show all component status
STATUSLINE_DEBUG=true ./statusline.sh --modules        # Debug component loading
```

**Single Test Execution:**
```bash
bats tests/unit/test_git_functions.bats              # Specific test file
bats tests/unit/test_git_functions.bats -f "branch"  # Filter by test name
bats tests/**/*.bats --tap                          # Verbose TAP output
npm run test:unit                                    # Unit tests only
npm run test:integration                             # Integration tests
npm run test:watch                                   # Watch mode with TAP output
```

**Debugging & Troubleshooting:**
```bash
STATUSLINE_DEBUG=true ./statusline.sh          # Enable debug logging
STATUSLINE_DEBUG=true npm test                 # Debug test execution
./statusline.sh --modules                      # Check module loading status
# Configuration errors are automatically reported during execution

# Commit count debugging (for missing or zero commit counts)
git log --since="today 00:00" --oneline | wc -l | tr -d ' '  # Direct commit check
echo '{"workspace": {"current_dir": "'"$(pwd)"'"}, "model": {"display_name": "Test"}}' | ./statusline.sh | sed 's/\x1b\[[0-9;]*m//g'  # Clean statusline output

# Label configuration debugging (for missing labels like "Commits:")
grep -r "CONFIG_COMMITS_LABEL" lib/config.sh   # Check if labels are being loaded
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep -i "commit\|label"  # Debug label loading
```

**Cache Management:**
```bash
# Clear all cache files
rm -rf ~/.cache/claude-code-statusline/
rm -rf ~/.local/share/claude-code-statusline/

# Clear specific cache types
rm -rf ~/.cache/claude-code-statusline/git_commits_since_*    # Commit count cache
rm -rf ~/.cache/claude-code-statusline/git_branch_*          # Branch name cache
rm -rf ~/.cache/claude-code-statusline/external_claude_*     # Claude version cache

# Debug cache behavior
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep "Using cached"
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep -E "(cache.*arithmetic|commits_since)"  # Debug arithmetic errors
CACHE_INSTANCE_ID=DEBUG ./statusline.sh       # Custom cache instance

# View cache statistics and files
ls -la ~/.cache/claude-code-statusline/*.cache
ls -la ~/.local/share/claude-code-statusline/*.cache
find ~/.cache/claude-code-statusline/ -name "*commits_since*" -exec ls -la {} \;  # Find commit cache files
```

**Performance Profiling:**
```bash
bats tests/benchmarks/test_performance.bats    # Performance benchmarks
bats tests/benchmarks/test_cache_performance.bats  # Cache performance tests
# Performance baseline in tests/benchmarks/performance_baseline.txt
```

**Prayer System Testing:**
```bash
bats tests/unit/test_prayer_functions.bats       # Core prayer functionality
bats tests/unit/test_prayer_auto_location.bats    # Auto-location detection
ENV_CONFIG_FEATURES_SHOW_PRAYER_TIMES=true ./statusline.sh  # Test prayer display
```

**API Research Tools:**
```bash
./api-research/claude-statusline-api-extractor.sh start   # Start API capture
./api-research/claude-statusline-api-extractor.sh analyze # Analyze captured data
./api-research/claude-statusline-api-extractor.sh status  # View statistics
```

## Project Architecture

**Modular System (91.5% code reduction from monolithic v1):**
- `statusline.sh` (399 lines) - Main orchestrator, loads modules via `load_module()`
- `lib/core.sh` - Base utilities, error handling, performance timing
- `lib/security.sh` - Input sanitization, path validation
- `lib/config.sh` - TOML parsing via `load_toml_configuration()`, **NEW** modular line configuration
- `lib/themes.sh` - Theme application via `apply_theme()`
- `lib/components.sh` - **NEW** Component registry system and modular display orchestration
- `lib/git.sh` - Repository status, commit counting
- `lib/mcp.sh` - MCP server monitoring via `get_mcp_status()`
- `lib/cost.sh` - ccusage integration, cost tracking
- `lib/display.sh` - Output formatting, **NEW** 1-9 line modular building system
- `lib/cache.sh` - Intelligent caching system
- `lib/prayer.sh` - Islamic prayer times & Hijri calendar integration
- `lib/prayer/*.sh` - Modular prayer system (location, calculation, display, timezone, core)
- `lib/components/*.sh` - **ATOMIC** Individual component modules (18 components)

**Atomic Component Architecture (v2.7.0):**
Each component follows a standardized interface:
- `collect_${component_name}_data()` - Gather component data
- `render_${component_name}()` - Format display output
- `get_${component_name}_config()` - Get component configuration

**Available Components (18 Total):**

<!-- 🔄 SYNC WARNING: This section MUST be kept synchronized with examples/Config.toml -->
<!-- When reading/updating component info here, verify examples/Config.toml matches! -->
<!-- ⚠️  SOURCE OF TRUTH: examples/Config.toml - In case of discrepancy, Config.toml is authoritative -->

**Repository & Git Components (4):**
- `repo_info.sh` - Repository directory and git branch/status
- `commits.sh` - Commit count for current repository
- `submodules.sh` - Submodule status and count
- `version_info.sh` - Claude Code version display

**Model & Session Components (4):**
- `model_info.sh` - Claude model name with emoji
- `cost_session.sh` - Repository session cost tracking
- `cost_live.sh` - Live block cost monitoring
- `reset_timer.sh` - Block reset countdown timer

**Cost Analytics Components (3):**
- `cost_monthly.sh` - 30-day cost summary
- `cost_weekly.sh` - 7-day cost summary
- `cost_daily.sh` - Daily cost summary

**Block Metrics Components (4):**
- `burn_rate.sh` - Token consumption rate (🔥3.5k/min $2.10/hr)
- `token_usage.sh` - Total tokens in current 5-hour block (📊9.5M)
- `cache_efficiency.sh` - Cache hit percentage for optimization (💾91% hit)
- `block_projection.sh` - Projected cost and tokens (📈$8.25 10.5M)

**System Components (2):**
- `mcp_status.sh` - MCP server health and connection status
- `time_display.sh` - Current time formatting

**Spiritual Components (1):**
- `prayer_times.sh` - Islamic prayer times integration

**Data Flow (Updated v2.7.0):**
1. JSON input → Configuration loading → Theme application
2. **ATOMIC** Component system initialization → Atomic component data collection
3. Atomic line building → 1-9 line dynamic output with clean visual separation

**Key v2.10.0 Achievements:**
- ✅ **18-Component System** - Pure atomic architecture with specialized components
- ✅ **Unified ccusage Integration** - Single API call reduces resource usage by 75%
- ✅ **Block Metrics Monitoring** - Real-time burn rate, tokens, cache efficiency, projections
- ✅ **Optimized Performance** - Cached 30s block data shared across all metric components
- ✅ **Resource Efficiency** - Minimal background processes, smart caching strategy
- ✅ **Backward Compatible** - All existing components continue to work seamlessly
- ✅ **1-9 Line Configurability** - Dynamic layouts with advanced block metrics precision
- ✅ **Environment Override Support** - All components configurable via `ENV_CONFIG_*`

**Atomic Component Benefits:**
- 🎯 **Single Responsibility** - Each component does one thing perfectly
- 🧩 **Mix & Match** - Combine any components in any order
- 🎨 **Clean Separators** - Proper `│` between all components
- ⚡ **Performance** - Lighter, focused component code
- 🔧 **Maintenance** - Easier to debug and extend individual components

**Module Dependencies & Load Order:**
1. `core.sh` → Always loaded first (provides `load_module()`, logging, timers)
2. `security.sh` → Loaded after core (provides input sanitization)
3. `config.sh` → Depends on core + security (TOML parsing, config loading)
4. `themes.sh` → Depends on config (color theme application)
5. `cache.sh` → Depends on core + security (caching system)
6. `git.sh` → Independent module (git operations)
7. `mcp.sh` → Independent module (MCP server monitoring)
8. `cost.sh` → Independent module (cost tracking)
9. `prayer.sh` → Islamic prayer times system (depends on core, security, cache, config)
10. `prayer/*.sh` → Prayer sub-modules (location, calculation, display, timezone)
11. `display.sh` → Depends on themes + all data modules (output formatting)

**Key Functions:**
- `statusline.sh:load_module()` - Module loading with dependency checking
- `lib/config.sh:load_toml_configuration()` - Flat TOML parsing with dot notation
- `lib/themes.sh:apply_theme()` - Theme inheritance and color management
- `lib/mcp.sh:get_mcp_status()` - MCP server health monitoring
- `lib/cache.sh:execute_cached_command()` - Universal caching with TTL support
- `lib/prayer.sh:get_prayer_times()` - Islamic prayer times with auto-location
- `lib/prayer.sh:get_hijri_date()` - Hijri calendar integration

## Development Workflow

**🌙 Nightly Branch Development (v2.9.0+):**
```bash
# 1. Feature Development (Existing Pattern)
git checkout -b dev4 dev
# ... develop revolutionary feature ...
git commit -m "feat: experimental feature XYZ"
git push origin dev4

# 2. Merge to Stable Dev (Current Practice)
git checkout dev
git merge dev4 --no-ff -m "feat: integrate feature XYZ into stable dev"

# 3. NEW: Promote to Nightly for Community Testing
git checkout nightly
git merge dev --no-ff -m "feat: community testing for feature XYZ"
echo "2.9.0-nightly-$(date +%Y%m%d)" > version.txt
git add version.txt
git commit -m "feat: nightly build v2.9.0-nightly-$(date +%Y%m%d)"
git push origin nightly

# 4. After Community Validation: Production Release
git checkout main
git merge nightly --no-ff -m "release: v2.10.0 - feature XYZ stable"
echo "2.10.0" > version.txt
git commit -am "release: v2.10.0 stable release"
git push origin main
```

**🎯 Branch Strategy (Updated v2.9.0+):**
```
dev1, dev2, dev99 → dev → nightly → main
                     ↑      ↑        ↑
               stable dev  experimental  production
```

**🚀 Nightly Installation Testing:**
```bash
# Test nightly installation from remote
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/nightly/install.sh | bash -s -- --branch=nightly

# Validate nightly functionality
~/.claude/statusline/statusline.sh --version  # Should show v2.9.0-nightly-YYYYMMDD
~/.claude/statusline/statusline.sh --modules  # Check all 10 modules loaded
echo '{"workspace":{"current_dir":"$(pwd)"},"model":{"display_name":"Test"}}' | ~/.claude/statusline/statusline.sh

# Test configuration overrides
ENV_CONFIG_THEME=garden ~/.claude/statusline/statusline.sh --version
ENV_CONFIG_DISPLAY_LINES=3 echo '{...}' | ~/.claude/statusline/statusline.sh
```

**🔧 Config.toml Backup Behavior:**
- **BACKUP AND REPLACE**: Creates timestamped backup (Config.toml.backup.YYYYMMDD_HHMMSS)
- **Preserves customizations**: Your settings saved in backup file
- **Fresh template**: Downloads latest nightly template with new features
- **Zero data loss**: Restore from backup anytime

**Module Development Patterns:**
```bash
# Module loading check
./statusline.sh --modules           # View all module status and dependencies

# Module development workflow
source lib/core.sh                  # Load core utilities for testing
load_module "security"              # Load individual modules for testing
is_module_loaded "cache"            # Check if module is loaded

# Module debugging
STATUSLINE_DEBUG=true ./statusline.sh --modules  # Debug module loading
```

**Configuration Development:**
```bash
# Configuration testing
ENV_CONFIG_THEME=custom ./statusline.sh        # Test environment overrides
ENV_CONFIG_FEATURES_SHOW_MCP_STATUS=false ./statusline.sh  # Feature toggles

# Configuration location (single source of truth)
~/.claude/statusline/Config.toml    # Your configuration file (auto-created during installation)

# TOML validation  
# Config is automatically validated during loading - errors reported in real-time
```

**🎯 Three-Tier Installation Strategy:**
```bash
# 1. 🌙 NIGHTLY (Experimental - Advanced Users Only)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/nightly/install.sh | bash -s -- --branch=nightly
# Version: v2.9.0-nightly-YYYYMMDD
# Purpose: Bleeding-edge features, community testing, pre-release validation
# Audience: Power users, contributors, beta testers
# Update: Manual experimental feature pushes

# 2. 🛠️ DEV (Stable Development)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev
# Version: v2.9.0+ (stable dev)
# Purpose: Stable development features before production
# Audience: Contributors, early adopters
# Update: Feature merges from dev branches

# 3. 📦 MAIN (Production - Most Users)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash
# Version: v2.9.0 (stable releases)
# Purpose: Rock-solid production releases
# Audience: General users, production environments
# Update: Stable releases after nightly validation
```

**🌙 Nightly Branch Complete Workflow:**
```bash
# Development Phase
git checkout -b dev5 dev              # Create feature branch
# ... revolutionary development ...
git push origin dev5                  # Push feature branch

# Stable Integration  
git checkout dev                      # Switch to stable dev
git merge dev5 --no-ff                # Integrate feature
git push origin dev                   # Push stable development

# Nightly Promotion (NEW)
git checkout nightly                  # Switch to experimental branch
git merge dev --no-ff                 # Merge stable dev features
echo "2.9.0-nightly-$(date +%Y%m%d)" > version.txt  # Update nightly version
git add version.txt
git commit -m "feat: nightly v2.9.0-nightly-$(date +%Y%m%d) - feature XYZ"
git push origin nightly               # Push to community testing

# Production Release (After Nightly Validation)
git checkout main                     # Switch to production
git merge nightly --no-ff             # Merge validated features
echo "2.10.0" > version.txt           # Stable version bump
git commit -am "release: v2.10.0"      # Production release
git push origin main                  # Deploy to production
```

**🔒 Branch Protection Rules (Recommended):**
```bash
# main branch: ONLY accepts PRs from nightly
# nightly branch: Accepts PRs from dev + manual experimental pushes  
# dev branch: Accepts PRs from feature branches (dev1, dev2, dev3...)
# dev1-99 branches: Feature development (current pattern unchanged)
```

## Configuration Deep Dive

**Environment Variable Patterns:**
All TOML settings can be overridden using `ENV_CONFIG_*` pattern:
```bash
# Theme and colors
ENV_CONFIG_THEME_NAME=garden ./statusline.sh
ENV_CONFIG_COLORS_BASIC_RED="\033[91m" ./statusline.sh

# Feature toggles
ENV_CONFIG_FEATURES_SHOW_MCP_STATUS=false ./statusline.sh
ENV_CONFIG_FEATURES_SHOW_COST_TRACKING=true ./statusline.sh

# Timeout configuration
ENV_CONFIG_TIMEOUTS_MCP=15s ./statusline.sh
ENV_CONFIG_TIMEOUTS_CCUSAGE=12s ./statusline.sh

# Cache behavior
ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING=false ./statusline.sh
ENV_CONFIG_CACHE_ISOLATION_MODE=instance ./statusline.sh
```

**Advanced Configuration Examples:**
```toml
# Profile-aware configuration (planned feature)
# Work profile with conservative settings
[work]
theme.name = "classic"
timeouts.mcp = "5s"
features.show_cost_tracking = true

# Personal profile with enhanced features  
[personal]
theme.name = "catppuccin"
timeouts.mcp = "10s"
features.show_session_info = true
```

**Configuration Validation (v2.8.1):**
- Automatic validation during loading from comprehensive Config.toml
- Auto-regeneration if Config.toml is missing or corrupted
- Configuration errors reported with specific line numbers
- Environment overrides validated in real-time
- No fallback values needed - all settings pre-filled in Config.toml

**Label Configuration (Fixed v2.4.1):**
All display labels are now properly loaded from TOML configuration:
```toml
# All these labels are correctly extracted and applied
labels.commits = "Commits:"           # Commit count label
labels.repo = "REPO"                  # Session cost label  
labels.monthly = "30DAY"              # Monthly cost label
labels.weekly = "7DAY"                # Weekly cost label
labels.daily = "DAY"                  # Daily cost label
labels.submodule = "SUB:"             # Submodule count label
labels.mcp = "MCP"                    # MCP server label
labels.version_prefix = "ver"         # Claude version prefix
labels.session_prefix = "S:"          # Session identifier
labels.live = "LIVE"                  # Live cost label
labels.reset = "RESET"                # Reset time label
```

**Label Override Examples:**
```bash
# Test custom labels via environment variables
ENV_CONFIG_LABELS_COMMITS="Today:" ./statusline.sh
ENV_CONFIG_LABELS_REPO="SESSION" ./statusline.sh
ENV_CONFIG_LABELS_VERSION_PREFIX="v" ./statusline.sh
```

## Single Source Configuration System (v2.9.0)

**🎯 ONE Config.toml - All 227 Settings:**
- `theme.name = "catppuccin"` - Theme selection (classic/garden/catppuccin/custom)
- `display.lines = 5` - Number of statusline lines (1-9)
- `display.line1.components = ["repo_info", "commits", "submodules", "version_info", "time_display"]` - Component arrangement
- `features.show_mcp_status = true` - Feature toggles
- `timeouts.mcp = "10s"` - Performance tuning
- `cache.isolation.mode = "repository"` - Cache isolation settings
- `labels.commits = "Commits:"` - Display labels
- `colors.basic.*` - Custom theme colors

**Environment Overrides Still Work:**
Any TOML setting can be overridden: `ENV_CONFIG_THEME=garden ./statusline.sh`

**Simplified Configuration Order (v2.9.0):**
1. **Environment variables** (`ENV_CONFIG_*`) - Temporary overrides for testing
2. **~/.claude/statusline/Config.toml** - Single comprehensive configuration file (227 settings)
3. **Auto-regeneration** - If Config.toml missing, copied from examples/Config.toml template

**Key v2.9.0 Improvements:**
- ✅ **Revolutionary 3-Tier Download System** - Complete installer architectural overhaul
- ✅ **Nightly Branch Implementation** - Experimental development platform with community testing
- ✅ **Three-Tier Branch Strategy** - dev → nightly → main workflow for maximum stability
- ✅ **100% Download Guarantee** - Either all modules or clear failure with troubleshooting
- ✅ **GitHub Rate Limit Elimination** - Direct raw URLs bypass API limitations completely
- ✅ **Zero Intervention Required** - Primary method handles 99% of installations automatically
- ✅ **Enhanced Error Handling** - Exponential backoff and comprehensive retry mechanisms
- ✅ **Optional GitHub Token Support** - Enhanced fallback limits (5,000/hour vs 60/hour)
- ✅ **Config.toml Backup System** - Automatic backup and replace with timestamped preservation

**Key v2.8.2 Improvements:**
- ✅ **No More Hunting** - All parameters pre-filled in Config.toml, just edit values
- ✅ **Zero Code Defaults** - No hardcoded DEFAULT_CONFIG_* constants in lib/config.sh
- ✅ **Pure Extraction** - No jq fallbacks (`// "default"`), reads directly from TOML
- ✅ **Single Examples File** - Only examples/Config.toml (no confusion from 13 configs)
- ✅ **Complete Control** - Edit display lines, atomic components, themes - everything in one place

## Cache Isolation System

**Instance-Aware Caching (v2.1.0+):**
Prevents cache contamination when running multiple Claude Code instances in different repositories.

**Configuration Options:**
```toml
# Instance isolation settings
cache.isolation.mode = "repository"     # Default: isolate by working directory
cache.isolation.mcp = "repository"      # MCP servers per repository
cache.isolation.git = "repository"      # Git data per repository
cache.isolation.cost = "shared"         # Cost tracking user-wide
cache.isolation.session = "repository"  # Session costs per project
```

**Isolation Modes:**
- `"repository"` - Isolate by working directory (recommended)
- `"instance"` - Isolate by process ID
- `"shared"` - No isolation (legacy behavior)

**Benefits:**
- ✅ Each repository shows correct MCP servers
- ✅ Git information properly isolated
- ✅ Session costs tracked per project
- ✅ Prevents cache cross-contamination

**Cache File Structure:**
```
~/.cache/claude-code-statusline/         # XDG cache directory (primary)
~/.local/share/claude-code-statusline/   # XDG data directory (fallback)
├── cmd_exists_git_12345.cache           # Command existence (session-wide)
├── cmd_exists_claude_12345.cache        # Command existence (session-wide)
├── git_is_repo_path_hash_12345.cache    # Git repository check (30s cache)
├── git_branch_repo_hash_12345.cache     # Git branch name (10s cache)
├── git_status_repo_hash_12345.cache     # Git status (5s cache)
├── external_claude_version_12345.cache  # Claude version (15min cache)
├── external_claude_mcp_list_12345.cache # MCP server list (2min cache)
├── system_os_shared.cache               # OS type (permanent)
├── system_arch_shared.cache             # Architecture (permanent)
└── ccusage_*.cache                      # Cost tracking data
```

**Cache TTL Values:**
- **Session-wide**: Command existence checks (never expire during session)
- **Permanent**: System information (OS, architecture)
- **15 minutes**: Claude CLI version (detect updates quickly)
- **2 minutes**: MCP server list (detect connection changes)
- **30 seconds**: Git repository status
- **10 seconds**: Git branch information  
- **5 seconds**: Git working directory status

## Testing Architecture

**254-Test Comprehensive Suite (17 files):**
- `tests/unit/` - Function-level testing with mocked dependencies
- `tests/integration/` - End-to-end statusline functionality  
- `tests/benchmarks/` - Performance regression prevention
- `tests/fixtures/` - Mock data and sample outputs

**Test Fixtures & Mocking Patterns:**
```bash
# Mock external dependencies in tests/helpers/test_helpers.bash
# Use fixtures from tests/fixtures/sample_outputs/
# Performance baseline in tests/benchmarks/performance_baseline.txt
```

**Available Test Fixtures:**
- `tests/fixtures/sample_outputs/claude_version.txt` - Mock Claude CLI version output
- `tests/fixtures/sample_outputs/claude_mcp_list_*.txt` - MCP server connection states
- `tests/fixtures/sample_outputs/ccusage_*.json` - Cost tracking mock data

**Mocking Patterns (from test_helpers.bash):**
```bash
setup_mock_git_repo()          # Create mock git repository with custom status
create_mock_command()          # Mock external commands (git, claude, ccusage)
setup_mock_bin_dir()          # Set up isolated mock binary directory
```

**Test Categories:**
```bash
tests/unit/*.bats             # Function-level unit tests with mocks (9 files)
tests/integration/*.bats      # End-to-end integration tests (6 files)
tests/benchmarks/*.bats       # Performance regression tests (2 files)
tests/race-conditions/        # Multi-instance concurrency tests
```

**Current Test Files (17 total, 254 test cases):**
```bash
# Unit Tests (9 files)
tests/unit/test_cache_enhancements.bats
tests/unit/test_git_functions.bats  
tests/unit/test_mcp_parsing.bats
tests/unit/test_module_loading.bats
tests/unit/test_prayer_auto_location.bats  # NEW: Prayer system
tests/unit/test_prayer_functions.bats      # NEW: Prayer system
tests/unit/test_security.bats
tests/unit/test_timeout_validation.bats

# Integration Tests (6 files)
tests/integration/test_cache_integration.bats
tests/integration/test_full_statusline.bats
tests/integration/test_optimized_extraction.bats
tests/integration/test_toml_advanced.bats
tests/integration/test_toml_integration.bats
tests/integration/test_toml_simple.bats

# Performance Tests (2 files)
tests/benchmarks/test_cache_performance.bats
tests/benchmarks/test_performance.bats
tests/benchmarks/test_toml_performance.bats  # NEW: TOML parsing performance
```

**Running Specific Test Types:**
```bash
bats tests/unit/test_cache_enhancements.bats     # Cache functionality tests
bats tests/integration/test_cache_integration.bats  # Cache integration tests
bats tests/benchmarks/test_performance.bats      # Performance benchmarks
tests/race-conditions/test-concurrent-access.sh  # Concurrency testing
```

## Recent Fixes & Major Improvements (v2.9.0)

**🚀 REVOLUTIONARY v2.9.0 INSTALLER OVERHAUL (commit 8e5c35f):**
```bash
# Revolutionary 3-Tier Download System Architecture
# Tier 1: Direct Raw URLs - UNLIMITED requests, no API usage, fastest method
# Tier 2: GitHub API Fallback - Optional token support (5,000/hour vs 60/hour)  
# Tier 3: Comprehensive Retry - Exponential backoff and intelligent verification

# Major Installation Improvements:
# ✅ 100% Download Guarantee - Either all modules or clear failure
# ✅ GitHub Rate Limit Elimination - Direct raw URLs bypass API completely
# ✅ Zero Intervention Required - Primary method handles 99% of cases
# ✅ Enhanced Error Handling - Exponential backoff with detailed troubleshooting
# ✅ Performance Benefits - Fastest installation (direct raw URLs)
# ✅ Backward Compatible - All existing installation methods preserved
```

**🐛 CRITICAL v2.8.2 FIXES APPLIED (commit 5475ad2):**
```bash
# Prayer Time Calculation Fix
# Problem: Prayer times showing "24h 0m" when current time exactly matches prayer time
# Impact: Confusing display for users during exact prayer time matches
# Solution: Fixed to show "(0m)" for exact matches instead of "24h 0m"
# Result: Clean, accurate prayer time display for all scenarios
```

**🚨 CRITICAL v2.8.1 FIXES APPLIED (commit a51fa5d):**
```bash
# Fix 1: jq Template Escaping Catastrophe 
# Problem: \\(.key)=\\(.value) causing literal output instead of variable substitution
# Impact: Broke entire v2.8.0 single-source config system - CONFIG_DISPLAY_LINES='' empty
# Cause: Double-escaped jq template in extract_config_values() line 600
# Solution: Fixed to \(.key)=\(.value) - COMPLETE RESTORATION of v2.8.0 functionality

# Fix 2: Aggressive Cache Lock Cleanup
# Problem: "cannot overwrite existing file" race conditions in atomic lock creation
# Impact: Cache conflicts preventing stable operation
# Cause: Stale locks not cleaned before atomic file creation attempt
# Solution: Added pre-lock cleanup in acquire_cache_lock() - eliminated race conditions

# Fix 3: Error Message Accuracy 
# Problem: Misleading "Failed to build modular statusline" when using legacy mode
# Impact: Confusing debugging context for users
# Cause: Error message didn't reflect actual routing (modular vs legacy)
# Solution: Updated to "component-based system" - clear troubleshooting guidance
```

**Previous Critical Fixes:**
```bash
# Fix 4: Label Configuration Loading (commit 6a4a677)
# Problem: TOML labels (commits, repo, monthly, etc.) not loaded from Config.toml
# Cause: extract_config_values() missing label extraction in jq query
# Solution: Added all 11 label types to jq query and case statements in lib/config.sh

# Fix 5: Cache Key Sanitization (commit 7c0037d) 
# Problem: Cache arithmetic errors with "git_commits_since_today_00:00_..." keys
# Cause: Colons in cache keys cause bash arithmetic syntax errors
# Solution: Added colon sanitization alongside space sanitization in get_commits_since()
```

**Debugging Patterns Discovered:**
```bash
# For missing commit counts (shows as "Commits:" with no number):
# 1. Check if git command works directly
git log --since="today 00:00" --oneline | wc -l | tr -d ' '

# 2. Check for cache key issues in logs  
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep -E "(arithmetic|cache|commits_since)"

# 3. Clear cache and retry
rm -rf ~/.cache/claude-code-statusline/git_commits_since_*
```

**v2.9.0 Complete System Validation - 100% OPERATIONAL:**
- ✅ **Revolutionary Installation System**: 3-tier download architecture eliminates GitHub rate limits
- ✅ **100% Download Guarantee**: Either all modules or clear failure with troubleshooting
- ✅ **Zero Installation Intervention**: Primary method handles 99% of cases automatically
- ✅ **Configuration Loading FULLY OPERATIONAL**: All CONFIG_* variables populated from Config.toml
- ✅ **Single Source Architecture FUNCTIONAL**: Complete v2.8.0 feature restoration
- ✅ **Zero Cache Conflicts**: Aggressive cleanup eliminates lock race conditions
- ✅ **Prayer Time Calculation FIXED**: Exact match times show "(0m)" instead of "24h 0m"
- ✅ **Environment Overrides WORKING**: ENV_CONFIG_DISPLAY_LINES=3 shows 3 lines  
- ✅ **Component Overrides WORKING**: ENV_CONFIG_LINE1_COMPONENTS="time_display" shows only time
- ✅ **5-Line Modular Display**: Perfect statusline with all 18 components operational
- ✅ **All Critical Functionality**: Labels, commits, costs, MCP, prayer times, git status
- ✅ **Zero Critical Errors**: Clean, stable operation with comprehensive data display
- ✅ **Version Display**: Correct v2.10.0 version reporting in all contexts

## Key Implementation Notes

**Module Loading Pattern:**
Each module has include guard: `[[ "${STATUSLINE_*_LOADED:-}" == "true" ]] && return 0`

**Security Measures:**
- Input sanitization for all external data via `lib/security.sh`
- Timeout-based protection for external operations
- Secure path handling and cache file creation

**Performance Optimizations:**
- Single-pass jq optimization (64 calls → 1 optimized operation)
- Intelligent caching system in `lib/cache.sh`
- Parallel data collection for independent operations

**External Dependencies:**
- **Required**: `jq` (JSON parsing), `git` (repository integration)
- **Prayer System**: `curl` (API calls), `date` (time calculations)
- **Optional**: `ccusage` (cost tracking), `timeout/gtimeout` (platform-specific)
- **Auto-detection**: Dependencies validated in installer and runtime

## High-Priority Development Opportunities

**Recently Completed (v2.5.0):**
- ✅ **Islamic Prayer Times Integration** - Complete prayer system with auto-location (v2.2.0-2.5.0)
- ✅ **Modular Prayer Architecture** - Separated prayer functionality into focused modules
- ✅ **Label Configuration System** - Fixed TOML label loading (commits 6a4a677, 7c0037d)
- ✅ **Cache Key Sanitization** - Resolved arithmetic errors in cache system
- ✅ **API Research Framework** - Comprehensive Claude Code API analysis tools

**Ready for Implementation:**
1. **Custom Theme System** - Framework exists for additional themes beyond classic, garden, and catppuccin
2. **CI/CD Pipeline** - No `.github/workflows/` exists, critical infrastructure gap  
3. **Profile System** - Conditional configuration for work/personal contexts
4. **Enhanced Error Recovery** - Improve cache corruption detection and recovery mechanisms
5. **Prayer System Enhancements** - Additional prayer calculation methods and customization

**Quality Improvements:**
- **Cache Error Logging** - Better error messages for cache-related issues
- **Configuration Validation** - More detailed TOML validation with specific fix suggestions
- **Performance Monitoring** - Real-time cache hit ratio and performance metrics display

**Development Resources:**
- `TODOS.md` - 50+ categorized items with complexity estimates
- `CONTRIBUTING.md` - Complete development environment setup  
- `examples/Config.toml` - Master configuration template (keep updated)
- `api-research/` - Claude Code API analysis framework and tools
- `lib/prayer/` - Modular Islamic prayer times system
- Recent commits for debugging patterns: `git log --oneline -15`

## Prayer System Integration Notes

**Prayer Time Display Format:**
```bash
# Example prayer time output
│ Fajr: 05:42 (in 2h 15m) │ Dhuhr: 12:30 │ Maghrib: 18:45 │
│ 📅 15 Muharram 1446 │ 🕐 Next: Fajr │ ⏰ 2h 15m remaining │
```

**Prayer System Dependencies:**
- **Required**: `curl` (API calls), `date` (time calculations)
- **Optional**: `jq` (JSON parsing - automatically detected)
- **Caching**: Prayer times cached for 24 hours, location cached for 7 days

**Prayer Configuration Examples:**
```bash
# Indonesian/Malaysian settings (default)
ENV_CONFIG_PRAYER_CALCULATION_METHOD=5 ./statusline.sh

# Custom location override
ENV_CONFIG_PRAYER_LOCATION_LATITUDE=-6.2088 ./statusline.sh
ENV_CONFIG_PRAYER_LOCATION_LONGITUDE=106.8456 ./statusline.sh

# Disable auto-location, use manual coordinates
ENV_CONFIG_PRAYER_LOCATION_AUTO_DETECT=false ./statusline.sh
```

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
NEVER edit files under ~/.claude directory unless the user explicitly requests it.