# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status (v2.5.0)

**🎯 CURRENT: Modular Component System** - Revolutionary architecture transformation! The statusline now supports configurable 1-9 lines with complete component flexibility. Users can reorder, show/hide, and customize any of the 11 available components on any line position. This replaces the legacy fixed 5-line system with a fully dynamic, user-controlled layout system.

**🏗️ ARCHITECTURE BREAKTHROUGH**: 91.5% code reduction from monolithic design to clean modular system with standardized component interfaces and registry-based management.

## Quick Reference

**Essential Commands:**
```bash
npm test                              # Run all 246 tests across 17 files
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

**Modular Configuration Testing (v2.6.0):**
```bash
# Test pre-built layout examples
cp ~/.claude/statusline/examples/Config.modular-compact.toml ~/.claude/statusline/Config.toml       # 3-line minimal layout
cp ~/.claude/statusline/examples/Config.modular-comprehensive.toml ~/.claude/statusline/Config.toml # 7-line comprehensive layout
cp ~/.claude/statusline/examples/Config.modular-custom.toml ~/.claude/statusline/Config.toml        # Custom component reordering
cp ~/.claude/statusline/examples/Config.modular-standard.toml ~/.claude/statusline/Config.toml      # Standard 5-line equivalent
cp ~/.claude/statusline/examples/Config.modular-minimal.toml ~/.claude/statusline/Config.toml       # Ultra-minimal 1-line layout

# Dynamic component arrangement testing
ENV_CONFIG_DISPLAY_LINES=2 ./statusline.sh            # Override line count
ENV_CONFIG_LINE1_COMPONENTS="mcp_status,prayer_times" ./statusline.sh  # Custom line 1
ENV_CONFIG_LINE2_COMPONENTS="repo_info,cost_live" ./statusline.sh      # Custom line 2

# Advanced modular testing examples
ENV_CONFIG_DISPLAY_LINES=4 \
ENV_CONFIG_LINE1_COMPONENTS="repo_info" \
ENV_CONFIG_LINE2_COMPONENTS="git_stats,version_info" \
ENV_CONFIG_LINE3_COMPONENTS="mcp_status" \
ENV_CONFIG_LINE4_COMPONENTS="prayer_times" \
./statusline.sh  # 4-line custom layout

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
- `statusline.sh` (368 lines) - Main orchestrator, loads modules via `load_module()`
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
- `lib/prayer/*.sh` - Modular prayer system (location, calculation, display)
- `lib/components/*.sh` - **NEW** Individual component modules (11 components)

**Component Architecture (v2.5.0):**
Each component follows a standardized interface:
- `collect_${component_name}_data()` - Gather component data
- `render_${component_name}()` - Format display output
- `get_${component_name}_config()` - Get component configuration

**Available Components:**
- `repo_info.sh` - Repository directory and git status
- `git_stats.sh` - Commits count and submodules
- `version_info.sh` - Claude Code version display
- `time_display.sh` - Current time formatting
- `model_info.sh` - Claude model with emoji
- `cost_session.sh` - Repository session cost
- `cost_period.sh` - 30day/7day/daily costs
- `cost_live.sh` - Live block cost
- `mcp_status.sh` - MCP server health monitoring
- `reset_timer.sh` - Block reset countdown
- `prayer_times.sh` - Islamic prayer times integration

**Data Flow (Updated v2.5.0):**
1. JSON input → Configuration loading → Theme application
2. **NEW** Component system initialization → Component data collection
3. Modular line building → 1-9 line dynamic output (vs legacy 5-line fixed)

**Key v2.5.0 Achievements:**
- ✅ **Complete Modular Transformation** - Fully functional 11-component system with registry management
- ✅ **1-9 Line Configurability** - Dynamic layouts from minimal to comprehensive displays  
- ✅ **Standardized Component Interface** - Consistent `collect_data()`, `render()`, `get_config()` pattern
- ✅ **Backward Compatibility** - Legacy 5-line system preserved as fallback
- ✅ **TOML Configuration Integration** - Full modular layout configuration via `display.lineN.components`
- ✅ **Environment Override Support** - All modular settings configurable via `ENV_CONFIG_*` variables
- ✅ **Component Registry System** - Advanced component management with dependency tracking
- ✅ **5 Example Configurations** - Pre-built layouts from minimal to comprehensive arrangements

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

**Branch-Aware Development:**
```bash
# 1. Test dev2 branch changes before PR
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev2/install.sh | bash -s -- --branch=dev2

# 2. Production deployment (after PR merge)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash
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

**Configuration Validation:**
- Automatic validation during loading
- Invalid values fall back to defaults
- Configuration errors reported with specific line numbers
- Environment overrides validated in real-time

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

## Configuration System

**TOML Structure (Flat with dot notation):**
- `theme.name = "catppuccin"` - Theme selection (classic/garden/catppuccin/custom)
- `colors.basic.*` - Basic ANSI colors for custom themes
- `features.show_mcp_status = true` - Feature toggles
- `timeouts.mcp_timeout = "5s"` - Performance tuning
- `cache.claude_version_ttl = "3600"` - Caching behavior
- `cache.isolation.*` - Instance-aware cache isolation settings

**Environment Overrides:**
Any TOML setting can be overridden: `ENV_CONFIG_THEME=garden ./statusline.sh`

**Configuration Order:**
1. Environment variables (`ENV_CONFIG_*`) - Override any setting temporarily
2. `~/.claude/statusline/Config.toml` - Your configuration file (single source of truth)
3. Inline defaults - Fallback when no config exists

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

**246-Test Comprehensive Suite (17 files):**
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

**Current Test Files (17 total, 246 test cases):**
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

## Recent Fixes & Known Issues (v2.5.0+)

**Critical Fixes Applied:**
```bash
# Fix 1: Label Configuration Loading (commit 6a4a677)
# Problem: TOML labels (commits, repo, monthly, etc.) not loaded from Config.toml
# Cause: extract_config_values() missing label extraction in jq query
# Solution: Added all 11 label types to jq query and case statements in lib/config.sh

# Fix 2: Cache Key Sanitization (commit 7c0037d) 
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

**Post-Fix Validation:**
- ✅ Labels display correctly: `│ Commits:2 │ ver1.0.98 │`  
- ✅ Zero commits show as: `│ Commits:0 │ ver1.0.98 │`
- ✅ Cache key sanitization prevents arithmetic errors
- ✅ All 11 label types (commits, repo, monthly, weekly, daily, submodule, mcp, version_prefix, session_prefix, live, reset) load from TOML
- ✅ Prayer system integration with auto-location detection
- ✅ API research framework for comprehensive statusline analysis

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