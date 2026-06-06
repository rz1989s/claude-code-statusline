# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

**Current**: v2.25.10 | **Claude Code**: v2.1.6–v2.1.167 ✓ | **Branch**: feat/fix/chore → nightly → main
**Architecture**: Single Config.toml (240+ settings), modular cache (8 sub-modules), JSON abstraction layer, responsive width system
**Features**: 9-line statusline, native context % (v2.1.6+), prayer times, cost tracking, MCP, GPS location, wellness, CLI analytics, vim mode, agent display, usage limits, responsive width
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
  "workspace": { "current_dir": "/path/to/repo", "project_dir": "/path/to/repo", "added_dirs": [], "repo": { "host": "github.com", "owner": "owner", "name": "repo" } },
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
  "pr": { "number": 1234, "url": "https://github.com/owner/repo/pull/1234", "review_state": "approved" },
  "worktree": { "name": "my-feature", "branch": "worktree-my-feature", "path": "/path/.claude/worktrees/my-feature", "original_cwd": "/path/to/repo", "original_branch": "main" },
  "rate_limits": {
    "five_hour": { "used_percentage": 23.5, "resets_at": 1738425600 },
    "seven_day": { "used_percentage": 41.2, "resets_at": 1738857600 }
  }
}
```

**Path Migration**: `current_usage.*` moved to `context_window.current_usage.*` in v2.1.66. The `get_json_field()` abstraction handles both paths automatically.

**v2.1.69+ Additions**: `worktree` object (conditional — only present during `claude --worktree` sessions) with `name`, `path`, `original_cwd`, `original_branch` fields. No breaking changes from v2.1.66.

**v2.1.80+ Additions**: `rate_limits` object with `five_hour` and `seven_day` sub-objects. Each contains `used_percentage` (float 0-100) and `resets_at` (Unix epoch seconds). Only present for Claude.ai subscribers (Pro/Max) after the first API response. Each window may be independently absent. Also adds `worktree.branch` (string).

**v2.1.97+ Additions**: `workspace.git_worktree` (string, set when cwd is inside a linked git worktree via `git worktree add` — distinct from the top-level `worktree` object for `claude --worktree` sessions). Also introduces `refreshInterval` statusline setting (CC re-runs statusline every N seconds).

**v2.1.111 Opus 4.7 release**: `claude-opus-4-7` model ID (same pricing as Opus 4.6: $5/$25), `xhigh` effort level. Pricing pattern `claude-opus-4-7-*` added to `lib/cost/pricing.sh` in v2.24.1 to prevent bare-ID fallback to Sonnet default. Fast mode defaults to Opus 4.7 since v2.1.142.

**v2.1.118+ Vim Mode Expansion**: `vim.mode` can now emit `VISUAL`/`VISUAL_LINE` alongside `NORMAL`/`INSERT` (value-set expansion, not a schema change; the `vim_mode` component renders the strings opaquely).

**v2.1.119+ Additions**: `effort.level` (string, e.g. `"high"`/`"xhigh"`) and `thinking.enabled` (bool). Both optional and additive — `get_json_field()` reads only fields it cares about, so unknown fields are ignored gracefully.

**v2.1.132+ Correctness improvement (CC-side)**: `context_window.*` token counts now correctly reflect current context usage (previously cumulative session totals). Schema unchanged; the statusline picked up accurate values automatically with no code changes.

**v2.1.144+ Additions**: `workspace.repo` object (`host`, `owner`, `name` — repository identity parsed from the git `origin` remote; absent outside a git repo or with no `origin` remote) and top-level `pr` object (`number`, `url`, `review_state` — open pull request for the current branch). `review_state` is one of `approved`/`pending`/`changes_requested`/`draft`; each field is independently optional and the whole `pr` object is absent until a PR is found, then removed once it merges/closes. Both are additive, conditional, and backward-compatible — `get_json_field()` ignores them gracefully. No statusline component consumes them yet.

**v2.1.152–v2.1.167 (no new stdin fields)**: v2.1.154 released **Claude Opus 4.8** (`claude-opus-4-8`) at the same $5/$25 tier as Opus 4.6/4.7 — the `claude-opus-4-8` / `claude-opus-4-8-*` pattern was added to `lib/cost/pricing.sh` (case + awk block) in v2.25.0 to prevent the bare-ID→Sonnet-default fallback (same fix as 4.6/4.7); real transcripts emit the clean bare id, so cost tracking is fully covered. Opus 4.8 defaults to `high` effort (`xhigh` available); fast mode dropped to 2× the standard rate (not modeled in the cost calc). v2.1.153 began passing `COLUMNS`/`LINES` env vars to statusline commands — the responsive-width system's existing `$COLUMNS` detection now works natively on CC ≥ 2.1.153 (no logic change; see Responsive Width System). v2.1.152 fixed `cache_creation_input_tokens` under-reporting in transcript usage (passive correctness gain). v2.1.155 was skipped; v2.1.156 was a single-line Opus 4.8 thinking-block API-error fix; v2.1.157 (29 May 2026) is a plugins + worktrees + bugfix release (auto-loading `.claude/skills` plugins, `claude plugin init`, mid-session `EnterWorktree` switching, ~25 bug fixes) with no statusline-facing changes. **v2.1.158** (30 May 2026) extends **Auto mode** (automatic effort/model selection) to Bedrock, Vertex, and Foundry for Opus 4.7/4.8 behind the opt-in `CLAUDE_CODE_ENABLE_AUTO_MODE=1` env var — a backend cloud-provider routing feature, not a stdin field. **v2.1.159** (31 May 2026) is a no-op maintenance release ("Internal infrastructure improvements (no user-facing changes)" — the entire changelog/GitHub release body) with no schema, model, or statusline-facing changes; it remains the npm `latest` tag, render-verified. **v2.1.160** (1 Jun 2026) is published only on the npm `next` channel (the `latest` tag still points at v2.1.159) with no changelog on docs, GitHub releases, or `CHANGELOG.md`; a binary `strings` scan surfaces no new schema-field names and the prior release was itself a no-op, so it carries no statusline-facing changes — it is the installed binary (`claude --version` → 2.1.160), render-verified clean. **v2.1.161** (2 Jun 2026) and **v2.1.162** (3 Jun 2026) were both promoted to the npm `latest` tag (`{ latest: 2.1.162, next: 2.1.162 }`) — v2.1.162 is the installed binary (`claude --version` → 2.1.162). v2.1.161 is a developer-workflow/bugfix release (OTEL metric labels, `claude agents` UI, parallel-tool-call isolation, Linux clipboard, MCP secret redaction, render-perf); v2.1.162 is a CLI/UX + MCP/LSP bugfix release whose lone new JSON field — `waitingFor` — lives in the `claude agents --json` CLI subcommand output, **not** the statusline stdin schema, so it is non-actionable. **v2.1.163** (4 Jun 2026, npm `latest`+`next`, installed binary → 2.1.163) is a managed-settings + plugins + hooks + permission-rules + `claude agents` UX/bugfix release: it adds the `requiredMinimumVersion`/`requiredMaximumVersion` managed settings, `/plugin list`, and a `hookSpecificOutput.additionalContext` field that Stop/SubagentStop hooks may *return* (hook **output**, not statusline stdin), and now passes `CLAUDE_CODE_SESSION_ID` to stdio MCP servers (not to statusline commands) — none of which the statusline consumes. No new stdin JSON fields, no removed fields across the range. **v2.1.164** was never published (npm E404 — a skipped version number, like v2.1.151/v2.1.155). **v2.1.165** (5 Jun 2026, npm `latest`+`next`, installed binary → 2.1.165) is a maintenance release whose entire changelog body — verbatim and identical across the docs changelog, GitHub release, and `CHANGELOG.md` — is *"Bug fixes and reliability improvements"*: no new/changed/removed stdin fields, no new models or pricing, no env-var or render changes. **v2.1.166** (6 Jun 2026, npm `latest`+`next`, installed binary → 2.1.166) is a feature+bugfix release — a new `fallbackModel` setting / `--fallback-model` flag, deny-rule tool-name globs, cross-session-message auth hardening, a thinking-token toggle, and terminal/IDE bugfixes — all settings/CLI/permission/env-var/hook-output surface, **none touching the statusline stdin schema**: no new/changed/removed stdin fields, no new models or pricing, no env-var or render changes. **v2.1.167** (6 Jun 2026, npm `latest`+`next`, installed binary → 2.1.167) is a maintenance release whose entire changelog body — verbatim and identical across the docs changelog, GitHub release, and `CHANGELOG.md` — is *"Bug fixes and reliability improvements"* (the same one-liner as v2.1.165): no new/changed/removed stdin fields, no new models or pricing, no env-var or render changes.

**Compatibility**: Statusline fully compatible through v2.1.167 via feature detection (field existence), not version comparison. See [docs/CC_COMPATIBILITY.md](docs/CC_COMPATIBILITY.md) for per-version notes from v2.1.77 onward (skipped releases, polish/UX fixes, statusline-render fixes, and additional non-schema CC changes).

**1M Context Window (v2.1.75+)**: Opus 4.6 and Sonnet 4.6 support 1M context (1,000,000 tokens) at standard pricing. `context_window_size` will be `1000000` for these models. The statusline handles this dynamically via `get_native_context_window_size()`. The `exceeds_200k_tokens` field is still the only threshold marker — no `exceeds_1m_tokens` field exists.

**Usage Limits (Native + OAuth fallback)**: `rate_limits.five_hour/seven_day` data is provided natively in the JSON input since CC v2.1.80. The `usage_limits` component reads this as primary source (zero-latency, no network). For older CC versions, it falls back to `https://api.anthropic.com/api/oauth/usage` using the OAuth token from macOS Keychain. Note: native `resets_at` is Unix epoch (int), while OAuth returns ISO 8601 timestamps — both formats are supported.

**Manual Test Command** (simulates v2.1.167 input with Opus 4.8 + 1M context + rate_limits + vim VISUAL mode + effort/thinking + workspace.repo + pr fields):
```bash
echo '{"version":"2.1.167","workspace":{"current_dir":"'$(pwd)'","repo":{"host":"github.com","owner":"rz1989s","name":"claude-code-statusline"}},"model":{"id":"claude-opus-4-8","display_name":"Claude Opus 4.8"},"context_window":{"used_percentage":12,"remaining_percentage":88,"context_window_size":1000000,"current_usage":{"cache_read_input_tokens":5000,"input_tokens":10000},"total_input_tokens":45000,"total_output_tokens":12000},"cost":{"total_cost_usd":0.45,"total_lines_added":120,"total_lines_removed":30},"session_id":"test","mcp":{"servers":[]},"vim":{"mode":"VISUAL"},"effort":{"level":"high"},"thinking":{"enabled":true},"pr":{"number":1234,"url":"https://github.com/rz1989s/claude-code-statusline/pull/1234","review_state":"approved"},"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":'$(( $(date +%s) + 3600 ))'},"seven_day":{"used_percentage":41.2,"resets_at":'$(( $(date +%s) + 86400 ))'}}}' | /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh
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

**Width Detection**: `ENV_CONFIG_TERMINAL_WIDTH` → `$COLUMNS` → fallback 120. Claude Code **v2.1.153+ passes `COLUMNS`/`LINES`** to statusline commands, so auto-detection works natively on current CC. On older CC (or when `$COLUMNS` is unset) it falls back to 120 — set `ENV_CONFIG_TERMINAL_WIDTH=N` to force a width for narrow panes.

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