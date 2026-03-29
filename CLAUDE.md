# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

**Current**: v2.21.7 | **Claude Code**: v2.1.6–v2.1.86 ✓ | **Branch**: feat/fix/chore → nightly → main
**Architecture**: Single Config.toml (240+ settings), modular cache (8 sub-modules), JSON abstraction layer
**Features**: 9-line statusline, native context % (v2.1.6+), prayer times, cost tracking, MCP, GPS location, wellness, CLI analytics, vim mode, agent display, usage limits
**Platforms**: macOS, Ubuntu, Arch, Fedora, Alpine Linux

## Essential Commands

```bash
# Testing & Development
npm test                              # Run all 940 tests across 56 files
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

# Installation
curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/nightly/install.sh | bash -s -- --branch=nightly

# Cross-Platform Testing
curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev11/install.sh | bash -s -- --branch=dev11 --check-all-deps --interactive
bats tests/unit/test_platform_compatibility.bats
```

## Architecture

**Core Modules** (16): core → security → json_fields → config → themes → cache → git → mcp → cost → prayer → wellness → focus → components → responsive → display

**Atomic Components** (37):
- **Repository & Git** (5): repo_info, commits, submodules, version_info, github
- **Model & Session** (5): model_info, bedrock_model, cost_repo, cost_live, reset_timer
- **Cost Analytics** (3): cost_monthly, cost_weekly, cost_daily
- **Block Metrics** (5): burn_rate, token_usage, cache_efficiency, block_projection, code_productivity
- **System & Context** (4): time_display, version_display, context_alert, context_window
- **MCP & Extensions** (3): mcp_status, mcp_servers, mcp_plugins
- **Session State** (4): vim_mode, agent_display, session_info, session_mode
- **Cumulative Metrics** (2): total_tokens, usage_limits
- **Wellness** (1): wellness (idle detection, focus mode, break reminders)
- **Spiritual** (5): prayer_times, prayer_times_only, prayer_icon, hijri_calendar, location_display
- **CLI Analytics** (10 commands): --commits, --mcp-costs, --recommendations, --trends, --limits, --watch, --csv, --focus

**Data Flow**: JSON input → Schema validation → Config loading → Theme application → Atomic component data collection → 1-9 line dynamic output (default: 9-line with wellness + GPS location)

**Key Functions**:
- `load_module()` - Module loading with dependency checking
- `get_json_field()` - Safe JSON extraction with path migration (v2.1.66+)
- `validate_json_schema()` - Startup schema validation and version detection
- `load_toml_configuration()` - Single-source TOML parsing
- `apply_theme()` - Color theme management
- `execute_cached_command()` - Universal caching with TTL
- `get_context_window_percentage_smart()` - Native percentages (v2.1.6+) with transcript fallback

## Development Workflow

```bash
# Branch Strategy: feat/*, fix/*, chore/* → nightly → main
# Feature Development
git checkout -b feat/my-feature nightly   # Create feature branch
git push origin feat/my-feature           # Push feature

# Integration
git checkout nightly && git merge feat/my-feature --no-ff  # Merge to nightly

# Testing
bats tests/unit/test_*.bats           # Unit tests (45 files)
bats tests/integration/test_*.bats    # Integration tests (7 files)
bats tests/benchmarks/test_*.bats     # Performance tests (4 files)

# Pre-commit hooks (optional but recommended)
pip install pre-commit && pre-commit install
pre-commit run --all-files            # Manual check

# Installation Testing
curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev6/install.sh | bash -s -- --branch=dev6 --preserve-statusline
```

## Configuration

**Single Source**: `~/.claude/statusline/Config.toml` (227 settings, all pre-filled)

**Key Settings**:
```toml
# Theme and Display
theme.name = "catppuccin"            # classic/garden/catppuccin/custom
display.lines = 7                    # 1-9 lines supported (7-line default)
display.line1.components = ["repo_info"]  # Repository identity only
display.line2.components = ["commits", "submodules", "version_info", "time_display"]  # Git metrics & versions
display.line7.components = ["location_display"]  # GPS-accurate location display

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

# Location Display (GPS-Accurate)
location.enabled = true              # GPS-first location detection
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
ENV_CONFIG_PRAYER_LOCATION_MODE=local_gps ./statusline.sh
ENV_CONFIG_LOCATION_FORMAT=full ./statusline.sh
```

## Claude Code JSON Input Format (stdin)

The statusline reads JSON from stdin (`input=$(cat)`), exported as `STATUSLINE_INPUT_JSON` for all components. Only `workspace.current_dir` is required; all other fields are optional with graceful fallbacks. Field access uses `get_json_field()` abstraction with automatic path migration for backward compatibility.

**Core Fields** (v2.1.76 schema):
```json
{
  "version": "2.1.76",
  "cwd": "/path/to/repo",
  "workspace": { "current_dir": "/path/to/repo", "project_dir": "/path/to/repo", "added_dirs": [] },
  "model": { "id": "claude-opus-4-6-20250415", "display_name": "Claude Opus 4.6" },
  "session_id": "uuid-string",
  "transcript_path": "/path/to/transcript.jsonl",
  "output_style": { "name": "default" },
  "context_window": {
    "used_percentage": 12, "remaining_percentage": 88, "context_window_size": 1000000,
    "current_usage": { "input_tokens": 10000, "cache_read_input_tokens": 5000, "cache_creation_input_tokens": 2000 },
    "total_input_tokens": 45000, "total_output_tokens": 12000
  },
  "exceeds_200k_tokens": false,
  "cost": { "total_cost_usd": 0.45, "total_duration_ms": 60000, "total_api_duration_ms": 30000, "total_lines_added": 120, "total_lines_removed": 30 },
  "vim": { "mode": "NORMAL" },
  "agent": { "name": "security-reviewer" },
  "mcp": { "servers": [] },
  "worktree": { "name": "my-feature", "branch": "worktree-my-feature", "path": "/path/.claude/worktrees/my-feature", "original_cwd": "/path/to/repo", "original_branch": "main" },
  "rate_limits": {
    "five_hour": { "used_percentage": 23.5, "resets_at": 1738425600 },
    "seven_day": { "used_percentage": 41.2, "resets_at": 1738857600 }
  }
}
```

**Path Migration**: `current_usage.*` moved to `context_window.current_usage.*` in v2.1.66. The `get_json_field()` abstraction handles both paths automatically.

**v2.1.69+ Additions**: `worktree` object (conditional — only present during `claude --worktree` sessions) with `name`, `path`, `original_cwd`, `original_branch` fields. No breaking changes from v2.1.66.

**v2.1.80+ Additions**: `rate_limits` object with `five_hour` and `seven_day` sub-objects. Each contains `used_percentage` (float 0-100) and `resets_at` (Unix epoch seconds). Only present for Claude.ai subscribers (Pro/Max) after the first API response. Each window may be independently absent. Also adds `worktree.branch` (string). v2.1.77-v2.1.79 and v2.1.81 add no new statusline-relevant fields. v2.1.82 was skipped (no public release). v2.1.83-v2.1.85 add no new statusline-relevant JSON fields. v2.1.86 fixed model field bleed across concurrent sessions (CC-side fix) — zero JSON schema changes.

**1M Context Window (v2.1.75+)**: Opus 4.6 and Sonnet 4.6 support 1M context (1,000,000 tokens) at standard pricing. `context_window_size` will be `1000000` for these models. The statusline handles this dynamically via `get_native_context_window_size()`. The `exceeds_200k_tokens` field is still the only threshold marker — no `exceeds_1m_tokens` field exists.

**Usage Limits (Native + OAuth fallback)**: `rate_limits.five_hour/seven_day` data is provided natively in the JSON input since CC v2.1.80. The `usage_limits` component reads this as primary source (zero-latency, no network). For older CC versions, it falls back to `https://api.anthropic.com/api/oauth/usage` using the OAuth token from macOS Keychain. Note: native `resets_at` is Unix epoch (int), while OAuth returns ISO 8601 timestamps — both formats are supported.

**Manual Test Command** (simulates v2.1.86 input with 1M context + rate_limits):
```bash
echo '{"version":"2.1.86","workspace":{"current_dir":"'$(pwd)'"},"model":{"id":"claude-opus-4-6-20250415","display_name":"Claude Opus 4.6"},"context_window":{"used_percentage":12,"remaining_percentage":88,"context_window_size":1000000,"current_usage":{"cache_read_input_tokens":5000,"input_tokens":10000},"total_input_tokens":45000,"total_output_tokens":12000},"cost":{"total_cost_usd":0.45,"total_lines_added":120,"total_lines_removed":30},"session_id":"test","mcp":{"servers":[]},"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":'$(( $(date +%s) + 3600 ))'},"seven_day":{"used_percentage":41.2,"resets_at":'$(( $(date +%s) + 86400 ))'}}}' | /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh
```

**macOS Note**: Requires bash 4+ (`brew install bash`). Settings.json should use `/opt/homebrew/bin/bash` (Apple Silicon) or `/usr/local/bin/bash` (Intel) instead of `bash`.

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

# GPS & Location Testing (NEW)
ENV_CONFIG_PRAYER_LOCATION_MODE=local_gps ./statusline.sh  # Test GPS-first mode
ENV_CONFIG_LOCATION_FORMAT=full ./statusline.sh            # Test full format display
STATUSLINE_DEBUG=true ./statusline.sh 2>&1 | grep -i "gps\|location\|coordinates"  # Debug GPS detection

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

## Responsive Width System

**Always-on. Zero config.** Detects terminal width, drops lower-priority components per line, truncates as safety net.

**Width Detection**: `ENV_CONFIG_TERMINAL_WIDTH` → `$COLUMNS` → `tput cols` → fallback 120. For accurate auto-detection, add `export COLUMNS` to shell profile.

**Component Priority**: 1 (essential) → 4 (first to go). Unregistered components default to 3. Priority table in `lib/responsive.sh`.

**Override**: `ENV_CONFIG_TERMINAL_WIDTH=80 ./statusline.sh`

## Technical Implementation

**Dependencies**:
- **Required**: jq (JSON parsing), git (repository integration)
- **Prayer System**: curl (API calls), date (time calculations)
- **GPS Location (Recommended)**:
  - macOS: CoreLocationCLI (`brew install corelocationcli`)
  - Linux: geoclue2 (`sudo apt install geoclue-2-demo`)
- **Optional**: timeout/gtimeout (platform-specific)

**Security**: Input sanitization via lib/security.sh, timeout protection, secure path handling

**Performance**: Single-pass jq optimization (64→1 calls), intelligent caching, parallel operations

**Module Loading**: Include guards `[[ "${STATUSLINE_*_LOADED:-}" == "true" ]] && return 0`

## Installation System

**Two Installation Methods Available:**

| Feature | curl installer (Recommended) | Homebrew (macOS) |
|---------|------------------------------|------------------|
| Platform | macOS, Linux, WSL | macOS only |
| Auto settings.json | ✅ Automatic | ❌ Manual setup |
| Updates | Re-run installer | `brew upgrade` |
| Uninstall | Manual cleanup | `brew uninstall` |
| Branch selection | ✅ Any branch | main only |

**Method 1: curl Installer (Recommended)**
```bash
# Production (main branch) - Full automatic setup
curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/main/install.sh | bash

# Nightly (experimental features)
curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/nightly/install.sh | bash -s -- --branch=nightly

# Development branch
curl -sSfL https://raw.githubusercontent.com/rz1989s/claude-code-statusline/dev/install.sh | bash -s -- --branch=dev
```

**Method 2: Homebrew (macOS)**
```bash
# Install via Homebrew tap
brew tap rz1989s/tap && brew install claude-code-statusline

# After install, manually add to Claude Code settings.json:
# "env": { "CLAUDE_CODE_STATUSLINE": "~/.claude/statusline/statusline.sh" }

# Updates
brew update && brew upgrade claude-code-statusline
```

**Homebrew Tap Repository**: https://github.com/rz1989s/homebrew-tap

**3-Tier Download Architecture** (curl installer):
- **Tier 1**: Direct raw URLs (unlimited, fastest)
- **Tier 2**: GitHub API fallback (5,000/hour with token)
- **Tier 3**: Comprehensive retry with exponential backoff
- **Result**: 100% download guarantee, zero intervention required

## Prayer System Integration

**Display Format**: `🕌 24 Rabi' al-awwal 1447 🌙 │ Fajr 04:28 (8h 19m) │ Dhuhr 11:47 ✓`

**Configuration**:
```bash
ENV_CONFIG_PRAYER_LOCATION_MODE=local_gps ./statusline.sh      # GPS-first mode
ENV_CONFIG_PRAYER_CALCULATION_METHOD=5 ./statusline.sh         # Indonesian/Malaysian
ENV_CONFIG_PRAYER_LOCATION_AUTO_DETECT=false ./statusline.sh   # Manual coordinates
```

**Caching**: Prayer times cached 24h, GPS coordinates cached fresh

## GPS-Accurate Location Detection

**Fresh GPS Coverage**: Supports 2+ billion Muslims worldwide with device-accurate coordinates

**Location Detection Hierarchy**:
1. **Local System GPS** (95% accuracy) - Fresh device coordinates (VPN-independent)
   - macOS: CoreLocationCLI integration
   - Linux: geoclue2 system integration
   - Windows: Native Location API (future)
2. **IP Geolocation** (85% accuracy) - Network-based fallback
3. **Timezone Mapping** (70% accuracy) - Regional estimation
4. **Manual Override** (100% accuracy) - User-specified coordinates

**Supported Regions**:
- **Southeast Asia** (450M): Jakarta, Bekasi, Surabaya, Kuala Lumpur, Singapore
- **South Asia** (620M): Karachi, Lahore, Delhi, Mumbai, Dhaka, Islamabad
- **Middle East** (120M): Riyadh, Dubai, Istanbul, Tehran, Baghdad, Amman
- **North Africa** (280M): Cairo, Casablanca, Algiers, Tunis, Khartoum, Lagos
- **Europe** (60M): London, Paris, Berlin, Moscow, Sarajevo, Tirana
- **Americas** (15M): New York, Toronto, Los Angeles, São Paulo, Montreal

**Example Outputs**:
```bash
📍 Loc: Jakarta                     # GPS-accurate location
📍 Loc: Istanbul                    # Fresh coordinates from device
📍 Loc: Riyadh                      # Local system GPS detection
📍 Loc: Southeast Asia              # Regional fallback when GPS unavailable
```