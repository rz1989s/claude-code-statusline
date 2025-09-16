# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

**Current**: v2.12.0 with simplified installation (auto-install default) and 18-component atomic architecture
**Branch Strategy**: dev6 (settings.json) → dev → nightly → main
**Architecture**: Single Config.toml (227 settings), modular system (91.5% code reduction from v1)
**Key Features**: 5-line statusline, Islamic prayer times (IP-based + manual override), cost tracking, MCP monitoring, cache isolation

## Essential Commands

```bash
# Testing & Development
npm test                              # Run all 254 tests across 17 files
npm run lint:all                     # Lint everything
./statusline.sh --modules             # Show component status
STATUSLINE_DEBUG=true ./statusline.sh # Debug mode

# Configuration Testing
ENV_CONFIG_THEME=garden ./statusline.sh
ENV_CONFIG_DISPLAY_LINES=3 ./statusline.sh
ENV_CONFIG_LINE1_COMPONENTS="repo_info,commits" ./statusline.sh

# Cache Management
rm -rf ~/.cache/claude-code-statusline/
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep "cache"

# Simple Installation (auto-install is now default)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/nightly/install.sh | bash -s -- --branch=nightly

# Dependency Testing
./install.sh --check-all-deps          # Check dependency status
./install.sh --interactive             # Test with interactive choices
```

## Architecture

**Core Modules** (11): core → security → config → themes → cache → git → mcp → cost → prayer → components → display

**Atomic Components** (21):
- **Repository & Git** (4): repo_info, commits, submodules, version_info
- **Model & Session** (4): model_info, cost_repo, cost_live, reset_timer
- **Cost Analytics** (3): cost_monthly, cost_weekly, cost_daily
- **Block Metrics** (4): burn_rate, token_usage, cache_efficiency, block_projection
- **System** (2): mcp_status, time_display
- **Spiritual** (2): prayer_times, location_display

**Data Flow**: JSON input → Config loading → Theme application → Atomic component data collection → 1-9 line dynamic output (default: 6-line with privacy-friendly location display)

**Key Functions**:
- `load_module()` - Module loading with dependency checking
- `load_toml_configuration()` - Single-source TOML parsing
- `apply_theme()` - Color theme management
- `execute_cached_command()` - Universal caching with TTL

## Development Workflow

```bash
# Branch Strategy: dev1-99 → dev → nightly → main
# Feature Development
git checkout -b dev7 dev              # Create feature branch
git push origin dev7                  # Push feature

# Integration
git checkout dev && git merge dev7 --no-ff    # Merge to stable dev
git checkout nightly && git merge dev --no-ff # Promote to nightly

# Testing
bats tests/unit/test_*.bats           # Unit tests (9 files)
bats tests/integration/test_*.bats    # Integration tests (6 files)
bats tests/benchmarks/test_*.bats     # Performance tests (2 files)

# Installation Testing
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6 --preserve-statusline
```

## Configuration

**Single Source**: `~/.claude/statusline/Config.toml` (227 settings, all pre-filled)

**Key Settings**:
```toml
# Theme and Display
theme.name = "catppuccin"            # classic/garden/catppuccin/custom
display.lines = 6                    # 1-9 lines supported (now includes location display)
display.line1.components = ["repo_info", "commits", "version_info", "time_display"]
display.line6.components = ["location_display"]  # Privacy-friendly location display

# Features
features.show_mcp_status = true
features.show_prayer_times = true

# Cache Isolation
cache.isolation.mode = "repository"  # repository/instance/shared
cache.isolation.mcp = "repository"

# Prayer System
prayer.enabled = true
prayer.calculation_method = 5        # Indonesian/Malaysian method
prayer.location.auto_detect = true

# Location Display (Privacy-Friendly)
location.enabled = true              # IP-based with manual override
location.format = "short"            # short: "Bekasi", full: "Bekasi, West Java, Indonesia"

# Labels
labels.commits = "Commits:"
labels.repo = "REPO"
labels.monthly = "30DAY"
```

**Environment Overrides**: Any TOML setting can be overridden using `ENV_CONFIG_*` pattern:
```bash
ENV_CONFIG_THEME_NAME=garden ./statusline.sh
ENV_CONFIG_DISPLAY_LINES=3 ./statusline.sh
ENV_CONFIG_FEATURES_SHOW_MCP_STATUS=false ./statusline.sh
ENV_CONFIG_PRAYER_LOCATION_MODE=auto ./statusline.sh
ENV_CONFIG_LOCATION_FORMAT=full ./statusline.sh
```

## Testing & Debugging

```bash
# Debugging Patterns
STATUSLINE_DEBUG=true ./statusline.sh          # Enable debug logging
./statusline.sh --modules                      # Check module status

# Commit Count Issues
git log --since="today 00:00" --oneline | wc -l | tr -d ' '  # Direct check
rm -rf ~/.cache/claude-code-statusline/git_commits_since_*   # Clear cache

# Label Loading Issues
grep -r "CONFIG_COMMITS_LABEL" lib/config.sh
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep -i "commit\|label"

# Performance Testing
bats tests/benchmarks/test_performance.bats
bats tests/benchmarks/test_cache_performance.bats

# Prayer System Testing
bats tests/unit/test_prayer_functions.bats
ENV_CONFIG_PRAYER_ENABLED=true ./statusline.sh

# Location Testing (Privacy-Friendly)
ENV_CONFIG_PRAYER_LOCATION_MODE=auto ./statusline.sh       # Test IP-based mode
ENV_CONFIG_LOCATION_FORMAT=full ./statusline.sh            # Test full format display
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep -i "location\|coordinates"  # Debug location detection

# Global City Detection Testing
source lib/components/location_display.sh
get_city_from_coordinates 24.7136 46.6753    # Should detect "Riyadh"
get_city_from_coordinates 41.0082 28.9784     # Should detect "Istanbul"
get_city_from_coordinates 51.5074 -0.1278     # Should detect "London"
```

## Cache System

**Structure**: XDG-compliant with repository isolation
```bash
~/.cache/claude-code-statusline/         # Primary cache location
~/.local/share/claude-code-statusline/   # Fallback location
```

**TTL Values**: Session-wide (command existence), 15min (Claude version), 2min (MCP list), 30s (git status), 10s (branch), 5s (working dir)

**Isolation Modes**:
- `repository` - Isolate by working directory (recommended)
- `instance` - Isolate by process ID
- `shared` - No isolation (legacy)

## Technical Implementation

**Dependencies**:
- **Critical (auto-installed)**: curl, jq, git
- **Important (auto-installed)**: bun/bunx (cost tracking), bc (calculations), python3 (TOML features)
- **Helpful (auto-installed)**: timeout/gtimeout (network protection)
- **Location Detection**: IP geolocation with manual coordinate override for privacy

**Auto-Install System**:
- **Platform Support**: macOS (Homebrew), Linux (apt/yum/dnf/pacman), WSL (Linux packages)
- **Zero Configuration**: Detects platform, package manager, installs dependencies automatically
- **Permissions**: Handles sudo requirements intelligently (macOS uses brew without sudo)
- **Verification**: Confirms successful installation before proceeding

**Security**: Input sanitization via lib/security.sh, timeout protection, secure path handling

**Performance**: Single-pass jq optimization (64→1 calls), intelligent caching, parallel operations

**Module Loading**: Include guards `[[ "${STATUSLINE_*_LOADED:-}" == "true" ]] && return 0`

## Installation System

**3-Tier Download Architecture** (v2.9.0):
- **Tier 1**: Direct raw URLs (unlimited, fastest)
- **Tier 2**: GitHub API fallback (5,000/hour with token)
- **Tier 3**: Comprehensive retry with exponential backoff
- **Result**: 100% download guarantee, zero intervention required

**Installation Commands**:
```bash
# Simple installation (auto-install is now default!)
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

# Interactive confirmation
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash -s -- --interactive

# Platform-specific examples
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/nightly/install.sh | bash -s -- --branch=nightly
curl -fsSL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev --preserve-statusline
```

## Prayer System Integration

**Display Format**: `🕌 24 Rabi' al-awwal 1447 🌙 │ Fajr 04:28 (8h 19m) │ Dhuhr 11:47 ✓`

**Configuration**:
```bash
ENV_CONFIG_PRAYER_LOCATION_MODE=auto ./statusline.sh           # IP-based with fallbacks
ENV_CONFIG_PRAYER_CALCULATION_METHOD=5 ./statusline.sh         # Indonesian/Malaysian
ENV_CONFIG_PRAYER_LOCATION_AUTO_DETECT=false ./statusline.sh   # Manual coordinates
```

**Caching**: Prayer times cached 24h, IP location cached 30min

## Privacy-Friendly Location Detection

**Privacy-First Approach**: No GPS permissions required - uses IP geolocation with manual coordinate override

**Location Detection Hierarchy**:
1. **Manual Coordinates** (100% accuracy) - User-specified coordinates (privacy-friendly)
2. **IP Geolocation** (85% accuracy) - Network-based detection (VPN-aware)
3. **Timezone Mapping** (70% accuracy) - Regional estimation
4. **Cache Fallback** (80% accuracy) - Previously detected location

**Supported Regions**:
- **Southeast Asia** (450M): Jakarta, Bekasi, Surabaya, Kuala Lumpur, Singapore
- **South Asia** (620M): Karachi, Lahore, Delhi, Mumbai, Dhaka, Islamabad
- **Middle East** (120M): Riyadh, Dubai, Istanbul, Tehran, Baghdad, Amman
- **North Africa** (280M): Cairo, Casablanca, Algiers, Tunis, Khartoum, Lagos
- **Europe** (60M): London, Paris, Berlin, Moscow, Sarajevo, Tirana
- **Americas** (15M): New York, Toronto, Los Angeles, São Paulo, Montreal

**VPN Behavior (Expected)**:
```bash
# Without VPN
📍 Loc: Bekasi                      # Accurate via IP geolocation
🕌 Fajr 04:28 (Bekasi time)         # Accurate prayer times

# With VPN (shows VPN location)
📍 Loc: Jakarta                     # Expected: Shows VPN server location
🕌 Fajr 04:18 (Jakarta time)        # Expected: VPN server prayer times

# Manual Override (VPN-independent)
📍 Loc: Bekasi                      # Accurate: Manual coordinates
🕌 Fajr 04:28 (Bekasi time)         # Accurate: Manual coordinates
```