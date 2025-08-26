# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Claude Code Enhanced Statusline project (v2.0.0) - a sophisticated 4-line statusline with modular architecture. The system consists of a main orchestrator script (`statusline.sh`) that coordinates 9 specialized modules in `lib/` directory, providing rich information display for Claude Code sessions including git status, MCP server monitoring, cost tracking, and beautiful themes.

**📋 Key Resources for Development:**
- **TODOS.md** - Comprehensive development roadmap with 50+ actionable items, complexity estimates, and implementation hints
- **CONTRIBUTING.md** - Professional contribution guidelines covering development setup, testing requirements, and code standards  
- **examples/Config.toml** - Master configuration template (287 lines) used by installer - keep updated with new features
- **Ocean Theme Ready** - Complete theme in `examples/sample-configs/ocean-theme.toml` ready for integration (High Priority)

**Architecture**: 
- **Main Script**: `statusline.sh` (332 lines) - orchestrates modules and handles input/output
- **9 Modules**: `lib/core.sh`, `lib/security.sh`, `lib/config.sh`, `lib/themes.sh`, `lib/git.sh`, `lib/mcp.sh`, `lib/cost.sh`, `lib/display.sh`, `lib/cache.sh`
- **91.5% Code Reduction**: Refactored from 3930-line monolithic script to clean modular system

## Build, Test & Development Commands

### Testing Commands
```bash
# Run complete test suite (77 tests total)
npm test

# Run specific test categories
npm run test:unit          # Unit tests only (individual functions)
npm run test:integration   # Integration tests (end-to-end functionality)

# Code quality and linting
npm run lint               # ShellCheck the main script
npm run lint:tests         # ShellCheck test files
npm run lint:all           # Lint everything

# Development workflow
npm run clean              # Remove test artifacts and cache files
npm run dev                # Clean + test cycle
npm run ci                 # Full CI pipeline (lint + test)

# Direct Bats testing
bats tests/**/*.bats       # Run all tests directly
bats tests/unit/test_git_functions.bats  # Specific test file
```

### Configuration Management Commands
```bash
# TOML configuration generation and testing
./statusline.sh --generate-config              # Create Config.toml from current settings
./statusline.sh --test-config                  # Test current configuration
./statusline.sh --validate-config              # Validate configuration syntax
./statusline.sh --compare-config               # Compare inline vs TOML settings

# Configuration reload and management
./statusline.sh --reload-config                # Reload configuration now
./statusline.sh --watch-config 3               # Watch for config changes every 3 seconds
./statusline.sh --reload-interactive           # Interactive config management menu

# Theme testing
ENV_CONFIG_THEME=garden ./statusline.sh        # Test specific theme temporarily
ENV_CONFIG_THEME=catppuccin ./statusline.sh    # Test catppuccin theme
```

### Installation and Setup

**Branch-Aware Installer (v2.0.0+)**

**Production Installation (Main Branch):**
```bash
# Standard installation (stable, production-ready)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

# Enhanced dependency analysis mode
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --check-all-deps

# Interactive installation with user choices
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --interactive

# Full experience: comprehensive analysis + user menu
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --check-all-deps --interactive
```

**Development Testing (Dev Branch):**
```bash
# Test dev branch changes before PR (RECOMMENDED WORKFLOW)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev

# Dev branch with enhanced dependency analysis
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev --check-all-deps

# Dev branch with interactive mode
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev --interactive

# Alternative: Environment variable approach
CLAUDE_INSTALL_BRANCH=dev curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash
```

**Manual Installation & Inspection:**
```bash
# Download and inspect installer first (enables auto-detection)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh -o install.sh
chmod +x install.sh
./install.sh --help                           # See all installer options
./install.sh --check-all-deps --interactive   # Auto-detects dev branch when downloaded from dev
```

**Installation Modes:**
- `--branch=BRANCH`: Install from specific branch (dev, main, feature/*)
- `--check-all-deps`: Shows all 6 dependencies with feature impact analysis
- `--interactive`: Provides user choice menu (install now vs install deps first)
- `--minimal`: Original behavior (curl + jq dependency check only)
- `--skip-deps`: Skip all dependency checks (install anyway)
- `--help`: Complete installer documentation

**Branch-Aware Features:**
- **Auto-detection**: Installer detects source branch when downloaded locally
- **Environment Override**: `CLAUDE_INSTALL_BRANCH=dev` sets branch globally
- **Explicit Selection**: `--branch=dev` parameter for precise control
- **Transparency**: Shows "🔧 Installing from branch: dev" when using non-main branches

**Manual Testing & Configuration**
```bash
# Manual testing
./statusline.sh --help                         # Complete help documentation
./statusline.sh --help config                  # Configuration-specific help
```

## High-Level Architecture

### Core Components

**statusline.sh (Main Script)**
- Single bash script (332 lines) providing 4-line statusline output
- Modular function-based architecture with clear separation of concerns
- TOML configuration system with fallback to inline configuration
- Theme system with inheritance and custom color support
- Comprehensive error handling and security measures

**Configuration System**
- **Config.toml**: Modern TOML-based configuration with ~100 settings
- **Theme System**: 3 built-in themes (classic, garden, catppuccin) + custom theme support + Ocean theme ready to implement
- **Configuration Discovery**: `./Config.toml` → `~/.config/claude-code-statusline/Config.toml` → `~/.claude-statusline.toml`
- **Environment Overrides**: Any TOML setting can be overridden with `ENV_CONFIG_*` variables
- **Profile System**: Conditional configuration for work/personal/demo contexts

**Core Functions (statusline.sh)**
- `load_toml_configuration()`: TOML parsing and config loading
- `apply_theme()`: Theme application and color management  
- `get_mcp_status()`: MCP server monitoring and parsing
- `apply_configuration_profile()`: Profile-based conditional configuration
- `validate_dependencies()`: Dependency checking and validation
- `generate_config_toml()`: Configuration generation and management

### Data Flow Architecture

1. **Input Processing**: Claude Code JSON input via stdin
2. **Configuration Loading**: Discover and load Config.toml with environment overrides
3. **Theme Application**: Apply selected theme with inheritance support
4. **Data Collection**: Parallel collection of git status, MCP servers, cost tracking
5. **Formatting**: Apply colors, emojis, and layout formatting
6. **Output Generation**: 4-line structured output with conditional sections

### Output Structure

**Line 1**: Repository & Environment
- Working directory, git branch/status, commit count, Claude version, submodule count, time

**Line 2**: Cost Tracking & Model Info  
- Claude model, repository costs, 30-day/7-day/daily totals, live block costs

**Line 3**: MCP Server Health
- Connected/total server count, server names with connection status

**Line 4**: Block Reset Timer (conditional)
- Reset time and countdown for active billing blocks

### External Integrations

**ccusage Integration**: Cost tracking and billing information
- Repository session costs, daily/weekly/monthly totals
- Active billing block detection and countdown timers
- Requires: `npm install -g ccusage`

**MCP Server Monitoring**: Real-time Model Context Protocol server status
- Connection health monitoring with color-coded indicators  
- Server name parsing and status detection
- Timeout-based health checks

**Git Integration**: Repository status and commit tracking
- Clean/dirty status detection, branch information
- Today's commit counting, submodule detection
- Branch-based conditional configuration support

### Security & Performance

**Security Measures**
- Input sanitization for all external data sources
- Secure path handling and cache file creation
- Command injection prevention with parameter validation
- Timeout-based protection against hanging operations

**Performance Optimizations**
- Intelligent caching system for expensive operations (Claude version)
- Parallel data collection for independent operations
- Single-pass jq optimization (64 individual jq calls → 1 optimized operation)
- Configurable timeouts for all external operations

### Testing Architecture

**Comprehensive Test Suite (77 tests)**
- **Unit Tests**: Individual function testing with mocked dependencies
- **Integration Tests**: End-to-end statusline functionality testing  
- **Security Tests**: Input validation and path sanitization
- **Performance Tests**: Response time and timeout validation
- **TOML Tests**: Configuration parsing and validation

**Test Structure**
```
tests/
├── unit/              # Function-level testing
├── integration/       # End-to-end scenarios  
├── benchmarks/        # Performance monitoring
├── fixtures/          # Mock data and sample outputs
└── helpers/           # Test utilities and setup
```

## Configuration Guidelines

### TOML Configuration Structure
The Config.toml file supports extensive customization across these main sections:
- `[theme]`: Visual theme selection and custom colors
- `[features]`: Feature toggles for major statusline sections  
- `[timeouts]`: Performance tuning for external operations
- `[emojis]`: Custom emoji indicators for different states
- `[labels]`: Text customization for all display elements
- `[cache]`: Caching behavior and file locations
- `[profiles]`: Conditional configuration for different contexts

### Theme Development
When working with themes:
- Built-in themes: `classic`, `garden`, `catppuccin`
- **Ocean Theme**: Complete implementation ready in `examples/sample-configs/ocean-theme.toml` - just needs integration into `lib/themes.sh`
- Custom theme: Set `theme.name = "custom"` and define colors in `[colors.basic]` and `[colors.extended]`
- Theme inheritance: Custom themes can inherit from base themes and override specific colors
- Color systems: Supports ANSI, 256-color, and RGB color specifications

### Environment Override Pattern
Any TOML configuration can be temporarily overridden:
```bash
ENV_CONFIG_THEME=garden ./statusline.sh
ENV_CONFIG_SHOW_MCP_STATUS=false ./statusline.sh
ENV_CONFIG_MCP_TIMEOUT=10s ./statusline.sh
```

## Development Workflow

### **🚀 Recommended Dev-to-Production Workflow**

**1. Development & Testing:**
```bash
# Make your changes in dev branch
git checkout dev
# ... make code changes ...
git add . && git commit -m "feat: your changes"
git push origin dev

# Test your changes with dev branch installer
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev

# Validate everything works (cost tracking, MCP, themes, etc.)
```

**2. Create Pull Request:**
```bash
# Only after dev branch testing succeeds
gh pr create --title "Your changes" --body "Description" --base main --head dev
```

**3. Production Deployment:**
```bash
# After PR is merged to main
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash
```

**Key Benefits:**
- ✅ **Complete Integration Testing**: Dev installer + dev modules ensures no mixing
- ✅ **Safe Workflow**: Never merge untested changes to main
- ✅ **Version Consistency**: Proper version tracking per branch
- ✅ **Production Safety**: Main branch always contains tested, validated code

### Making Changes
1. **Edit Configuration**: Modify Config.toml for settings, statusline.sh for functionality
2. **Test Configuration**: Use `./statusline.sh --test-config` to validate changes
3. **Run Tests**: Use `npm test` or `npm run dev` for comprehensive testing
4. **Lint Code**: Use `npm run lint:all` before committing
5. **Test Themes**: Use environment overrides to test theme changes quickly

### Adding Features
1. **Update Config Schema**: Add new settings to Config.toml template
2. **Implement Parsing**: Add TOML parsing logic in `load_toml_configuration()`
3. **Add Functionality**: Implement feature logic with proper error handling
4. **Write Tests**: Add unit and integration tests for new functionality
5. **Update Documentation**: Update README.md and relevant docs/ files

### Working with External Dependencies
- **ccusage**: Optional cost tracking integration, gracefully degrades if not installed
- **jq**: Required for JSON parsing, dependency validation included  
- **git**: Required for repository integration, basic git commands expected
- **timeout/gtimeout**: Platform-specific timeout commands, auto-detection included

The codebase includes comprehensive dependency validation and graceful degradation when optional tools are not available.

## High-Priority Development Opportunities

### Immediate Implementation Ready:
1. **Ocean Theme Integration** - Complete theme exists in `examples/sample-configs/ocean-theme.toml`, needs integration to `lib/themes.sh`
2. **Profile System** - Explicitly planned feature mentioned in README.md, medium complexity
3. **CI/CD Pipeline** - Critical infrastructure gap, no `.github/workflows/` exists yet

### Development Resources:
- **TODOS.md** - 50+ categorized development items with complexity ratings and implementation hints
- **CONTRIBUTING.md** - Complete contributor onboarding with development environment setup
- **Comprehensive Documentation** - Extensive `docs/` directory with guides for installation, configuration, themes, troubleshooting, security, and migration