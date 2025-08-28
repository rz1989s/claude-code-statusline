# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

**Essential Commands:**
```bash
npm test                              # Run all 77 tests
npm run lint:all                     # Lint everything 
npm run dev                          # Clean + test cycle
./statusline.sh --test-config        # Validate current config
ENV_CONFIG_THEME=garden ./statusline.sh  # Test theme override
```

**Single Test Execution:**
```bash
bats tests/unit/test_git_functions.bats              # Specific test file
bats tests/unit/test_git_functions.bats -f "branch"  # Filter by test name
bats tests/**/*.bats --tap                          # Verbose output
```

**Debugging & Troubleshooting:**
```bash
STATUSLINE_DEBUG=true ./statusline.sh          # Enable debug logging
STATUSLINE_DEBUG=true npm test                 # Debug test execution
./statusline.sh --validate-config              # Check config syntax
./statusline.sh --help config                  # Config-specific help
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

**Key Functions:**
- `statusline.sh:load_module()` - Module loading with dependency checking
- `lib/config.sh:load_toml_configuration()` - Flat TOML parsing with dot notation
- `lib/themes.sh:apply_theme()` - Theme inheritance and color management
- `lib/mcp.sh:get_mcp_status()` - MCP server health monitoring

## Development Workflow

**Core Commands:**
```bash
# Development testing
npm run test:unit                    # Unit tests only
npm run test:integration             # Integration tests
npm run clean                       # Remove cache and test artifacts
npm run ci                          # Full CI pipeline

# Configuration management  
./statusline.sh --generate-config   # Create Config.toml from settings
./statusline.sh --reload-config     # Reload configuration
./statusline.sh --compare-config    # Compare inline vs TOML

# Performance profiling
bats tests/benchmarks/test_performance.bats    # Performance benchmarks
```

**Branch-Aware Development:**
```bash
# 1. Test dev branch changes before PR
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev

# 2. Production deployment (after PR merge)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash
```

## Configuration System

**TOML Structure (Flat with dot notation):**
- `theme.name = "catppuccin"` - Theme selection (classic/garden/catppuccin/custom)
- `colors.basic.*` - Basic ANSI colors for custom themes
- `features.show_mcp_status = true` - Feature toggles
- `timeouts.mcp_timeout = "5s"` - Performance tuning
- `cache.claude_version_ttl = "3600"` - Caching behavior

**Environment Overrides:**
Any TOML setting can be overridden: `ENV_CONFIG_THEME=garden ./statusline.sh`

**Discovery Order:**
1. Environment variables (`ENV_CONFIG_*`)
2. `./Config.toml` (project-specific)
3. `~/.claude/statusline/Config.toml` (user installation)
4. `~/.config/claude-code-statusline/Config.toml` (XDG standard)
5. Inline defaults

## Testing Architecture

**77-Test Comprehensive Suite:**
- `tests/unit/` - Function-level testing with mocked dependencies
- `tests/integration/` - End-to-end statusline functionality  
- `tests/benchmarks/` - Performance regression prevention
- `tests/fixtures/` - Mock data and sample outputs

**Test Development:**
```bash
# Mock external dependencies in tests/helpers/test_helpers.bash
# Use fixtures from tests/fixtures/sample_outputs/
# Performance baseline in tests/benchmarks/performance_baseline.txt
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
1. **Ocean Theme** - Complete theme in `examples/sample-configs/ocean-theme.toml`, needs integration to `lib/themes.sh:apply_theme()`
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