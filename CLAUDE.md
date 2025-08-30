# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

**Essential Commands:**
```bash
npm test                              # Run all 77 tests
npm run lint:all                     # Lint everything 
npm run dev                          # Clean + test cycle
npm run ci                           # Full CI pipeline
npm run clean                        # Remove cache and test artifacts
npm run clean:processes              # Kill background test processes
npm run setup                        # Complete project setup
# Current config is automatically loaded, no validation command needed
ENV_CONFIG_THEME=garden ./statusline.sh  # Test theme override
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
```

**Cache Management:**
```bash
# Clear cache files
rm -rf ~/.cache/claude-code-statusline/
rm -rf ~/.local/share/claude-code-statusline/

# Debug cache behavior
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep "Using cached"
CACHE_INSTANCE_ID=DEBUG ./statusline.sh       # Custom cache instance

# View cache statistics
ls -la ~/.cache/claude-code-statusline/*.cache
ls -la ~/.local/share/claude-code-statusline/*.cache
```

**Performance Profiling:**
```bash
bats tests/benchmarks/test_performance.bats    # Performance benchmarks
bats tests/benchmarks/test_cache_performance.bats  # Cache performance tests
# Performance baseline in tests/benchmarks/performance_baseline.txt
```

## Project Architecture

**Modular System (91.5% code reduction from monolithic v1):**
- `statusline.sh` (332 lines) - Main orchestrator, loads modules via `load_module()`
- `lib/core.sh` - Base utilities, error handling, performance timing
- `lib/security.sh` - Input sanitization, path validation
- `lib/config.sh` - TOML parsing via `load_toml_configuration()`
- `lib/themes.sh` - Theme application via `apply_theme()`
- `lib/git.sh` - Repository status, commit counting
- `lib/mcp.sh` - MCP server monitoring via `get_mcp_status()`
- `lib/cost.sh` - ccusage integration, cost tracking
- `lib/display.sh` - Output formatting, color application
- `lib/cache.sh` - Intelligent caching system

**Data Flow:**
1. JSON input → Configuration loading → Theme application
2. Parallel data collection (git/mcp/cost) → Formatting → 4-line output

**Module Dependencies & Load Order:**
1. `core.sh` → Always loaded first (provides `load_module()`, logging, timers)
2. `security.sh` → Loaded after core (provides input sanitization)
3. `config.sh` → Depends on core + security (TOML parsing, config loading)
4. `themes.sh` → Depends on config (color theme application)
5. `cache.sh` → Depends on core + security (caching system)
6. `git.sh` → Independent module (git operations)
7. `mcp.sh` → Independent module (MCP server monitoring)
8. `cost.sh` → Independent module (cost tracking)
9. `display.sh` → Depends on themes + all data modules (output formatting)

**Key Functions:**
- `statusline.sh:load_module()` - Module loading with dependency checking
- `lib/config.sh:load_toml_configuration()` - Flat TOML parsing with dot notation
- `lib/themes.sh:apply_theme()` - Theme inheritance and color management
- `lib/mcp.sh:get_mcp_status()` - MCP server health monitoring
- `lib/cache.sh:execute_cached_command()` - Universal caching with TTL support

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

# Configuration discovery order testing
./Config.toml                       # Project-specific config (highest priority)
~/.claude/statusline/Config.toml    # User installation config
~/.config/claude-code-statusline/Config.toml  # XDG standard location

# TOML validation  
# Config is automatically validated during loading - errors reported in real-time
```

**Branch-Aware Development:**
```bash
# 1. Test dev branch changes before PR
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev

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

**Discovery Order:**
1. Environment variables (`ENV_CONFIG_*`)
2. `./Config.toml` (project-specific)
3. `~/.claude/statusline/Config.toml` (user installation)
4. `~/.config/claude-code-statusline/Config.toml` (XDG standard)
5. Inline defaults

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

**77-Test Comprehensive Suite:**
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
tests/unit/*.bats             # Function-level unit tests with mocks
tests/integration/*.bats      # End-to-end integration tests
tests/benchmarks/*.bats       # Performance regression tests
tests/race-conditions/        # Multi-instance concurrency tests
```

**Running Specific Test Types:**
```bash
bats tests/unit/test_cache_enhancements.bats     # Cache functionality tests
bats tests/integration/test_cache_integration.bats  # Cache integration tests
bats tests/benchmarks/test_performance.bats      # Performance benchmarks
tests/race-conditions/test-concurrent-access.sh  # Concurrency testing
```

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
- **Optional**: `ccusage` (cost tracking), `timeout/gtimeout` (platform-specific)
- **Auto-detection**: Dependencies validated in installer and runtime

## High-Priority Development Opportunities

**Ready for Implementation:**
1. **Custom Theme System** - Framework exists for additional themes beyond classic, garden, and catppuccin
2. **CI/CD Pipeline** - No `.github/workflows/` exists, critical infrastructure gap
3. **Profile System** - Conditional configuration for work/personal contexts

**Development Resources:**
- `TODOS.md` - 50+ categorized items with complexity estimates
- `CONTRIBUTING.md` - Complete development environment setup
- `examples/Config.toml` - Master configuration template (keep updated)

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
NEVER edit files under ~/.claude directory unless the user explicitly requests it.