# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.26.9] - 2026-06-20

### Changed
- **Claude Code v2.1.183 compatibility** (docs/version update): Verified the statusline against CC v2.1.183 (npm `latest`+`next`, published 2026-06-19; installed binary → 2.1.183). v2.1.183 is a 17-bullet auto-mode-safety + config-UX + bugfix release — auto-mode now blocks destructive commands you didn't ask for (`git reset --hard`, `git checkout -- .`, `git clean -fd`, `git stash drop`, non-agent `git commit --amend`, `terraform/pulumi/cdk destroy` without a named stack), a new `attribution.sessionUrl` setting to omit the claude.ai session link from commits/PRs, `/config --help` shorthand-key listing, a deprecated/auto-updated-model stderr warning in print mode `-p` and agent frontmatter, removal of the startup "setup issues" line, plus 16 bugfixes (`thinking.disabled.display` 400s on subagent spawn, WebSearch-empty-in-subagents, vim cursor stranding, Windows-Terminal fullscreen-TUI corruption under nested-subagent load, MCP auth-stub exposure in headless/SDK) — with **no statusline-stdin surface**: no new/changed/removed JSON fields, no new models or pricing, no env-var or render changes. The `attribution.sessionUrl` setting and the removed internal-CLI surface (`migrate` command, `CODEX_HOME`/`GEMINI_HOME` env vars, the `gemini-extension.json` Gemini-CLI shim — not an Anthropic model) are not stdin fields, and the lone statusline-adjacent bullet (the Windows-Terminal fullscreen-corruption fix) is CC's own fullscreen render, not this statusline script. The preceding **v2.1.182** (published 2026-06-18) was a published-but-unchangelogged intermediate — present in the npm `versions` list but with no standalone changelog on the docs site, GitHub releases, or `CHANGELOG.md` (all jump 181→183; superseded by v2.1.183 ~2h later) — a new pattern distinct from both the v2.1.160 `next`-only canary and the E404 skips (v2.1.151/155/164/171/180/184). Verified by two clean renders against v2.1.183 blobs (Opus 4.8 + 1M + vim VISUAL + effort/thinking + workspace.repo + pr + native rate_limits, and the Fable 5 $10/$50 tier), both `CC:2.1.183`, all 9 lines, exit 0. Supported range is now v2.1.6–v2.1.183.

## [2.26.8] - 2026-06-18

### Changed
- **Claude Code v2.1.181 compatibility** (docs/version update): Verified the statusline against CC v2.1.181 (npm `latest`+`next`, published 2026-06-17). v2.1.181 is a sizable feature+bugfix release (~10 feature/setting/env bullets + ~31 fixes) — `/config key=value` to set any setting from the prompt, a `sandbox.allowAppleEvents` opt-in setting, the new `CLAUDE_CLIENT_PRESENCE_FILE` env var (read by CC to suppress mobile push notifications while you're at the machine), a bundled Bun 1.4 upgrade, line-by-line streaming of long paragraphs, mid-thinking auto-retry, subagent-panel polish, and fixes spanning prompt-caching on custom `ANTHROPIC_BASE_URL`/Foundry, a ~120ms startup regression, network-drive Write/Edit truncation, and `claude mcp get`/`list` connection-status accuracy — with **no statusline-stdin surface**: no new/changed/removed JSON fields, no new models or pricing, no env-var or render changes. The new `CLAUDE_CLIENT_PRESENCE_FILE` is consumed by CC itself, **not** forwarded to the statusline command (COLUMNS/LINES, added v2.1.153, remain the only statusline-forwarded env vars). The preceding **v2.1.180 was skipped** (npm E404 — like v2.1.151/155/164/171). Verified by a clean render against a v2.1.181 blob (Opus 4.8 + 1M + vim VISUAL + effort/thinking + workspace.repo + pr + native rate_limits), `CC:2.1.181`, all 9 lines, exit 0. Supported range is now v2.1.6–v2.1.181.

## [2.26.7] - 2026-06-17

### Changed
- **Claude Code v2.1.179 compatibility** (docs/version update): Verified the statusline against CC v2.1.179 (npm `latest`+`next`, published 2026-06-16). v2.1.179 is a 9-bullet maintenance (bug-fix + reliability/perf) release — mid-stream connection-drop response preservation + stuck-spinner fix, WSL2 mouse-wheel scrolling (a v2.1.172 regression), a Linux sandbox `denyRead`/`allowRead` glob-over-large-tree fix, a feedback-survey single-digit-as-rating fix, welcome-screen promo-banner de-stacking, Ctrl+O subagent-transcript view, prompt-input refocus, remote-session background-task status, and remote plugin-loading perf — with **no statusline-stdin surface**: no new/changed/removed JSON fields, no new models or pricing, no env-var or render changes. The lone render-adjacent bullet (welcome-screen banner de-duplication) is CC's own welcome UI, distinct from this statusline. All four sources (docs changelog, GitHub release, `CHANGELOG.md`, WebSearch) carry the v2.1.179 entry in sync. Verified by two clean renders against v2.1.179 blobs (Opus 4.8 + 1M + vim VISUAL + effort/thinking + workspace.repo + pr + native rate_limits, and the Fable 5 $10/$50 tier), both `CC:2.1.179`, all 9 lines, exit 0. Supported range is now v2.1.6–v2.1.179.

## [2.26.6] - 2026-06-16

### Changed
- **Claude Code v2.1.178 compatibility** (docs/version update): Verified the statusline against CC v2.1.178 (npm `latest`+`next`, published 2026-06-15). v2.1.178 is a 22-bullet feature+bugfix release — new permission-rule `Tool(param:value)` matching syntax (e.g. `Agent(model:opus)`), nested `.claude/skills`/`.claude/` closest-wins resolution, auto-mode now gating subagent spawns before launch, and ~14 bugfixes — with **no statusline-stdin surface**: no new/changed/removed JSON fields, no new models or pricing, no env-var or render changes. Its lone "statusline" bullet fixes clickable custom-URI-scheme links (e.g. `vscode://`) inside the `claude agents` TUI, a CC-side render surface distinct from this statusline. Verified by three clean renders against v2.1.178 blobs (Opus 4.6 standard, Opus 4.8 + 1M + vim VISUAL + effort/thinking + workspace.repo + pr + native rate_limits, and the Fable 5 $10/$50 tier). Supported range is now v2.1.6–v2.1.178.

## [2.26.5] - 2026-06-16

### Fixed
- **Location city detection rewritten to numeric bounding boxes**: `get_city_from_coordinates()` matched each city with a bash string glob on the coordinate's decimal digits (e.g. `-6.1[7-2]*,106.8[2-6]*`). Reversed character ranges like `[7-2]` match nothing in bash, and a glob cannot express a box spanning a decimal boundary, so ~21 cities (Medan, Bangalore, Beirut, Miami, Bishkek, Dar es Salaam, …) silently collapsed to their broad regional label — a North-Jakarta IP coordinate (`-6.1474,106.8711`) rendered "Southeast Asia" instead of "Jakarta". Replaced with a single-pass numeric bounding-box lookup (one `awk` pass over a city table, cities first in priority order then regional fallbacks as catch-all). Well-formed ranges were converted to their exact numeric equivalents (behaviour-preserving); the broken cities were given correct real-world boxes. Verified by an OLD-vs-NEW differential over every city centre and by installing from `nightly`.

### Added
- `tests/unit/test_location_city_matching.bats`: 37 regression tests for the city matcher (CI-safe, pure function, no network/mocks).

## [2.15.1] - 2025-01-16

### Fixed
- **Installer stale module references**: Removed `cost/ccusage.sh`, `cost/blocks.sh`, `cost/aggregation.sh` from installer module lists (these were removed in native cost calculation refactoring)
- Updated `lib/cost/session.sh` dependency comment to reference `api_live.sh` instead of removed `blocks.sh`

## [2.15.0] - 2025-01-15

### Added
- **Native context window percentages** (Claude Code v2.1.6+): Now uses official `used_percentage` and `remaining_percentage` fields from Claude Code's statusline input
- New functions: `get_native_context_used_percentage()`, `get_native_context_remaining_percentage()`, `get_native_context_window_size()`, `has_native_context_percentages()`, `get_context_window_percentage_smart()`
- Smart fallback: Automatically uses native percentages when available (v2.1.6+), falls back to transcript parsing for older versions
- `COMPONENT_CONTEXT_REMAINING` and `COMPONENT_CONTEXT_SOURCE` variables for richer context data
- **Usage limits component** (`usage_limits`): Display Claude Code rate limits (5h session, 7d weekly) from Anthropic OAuth API
- **Usage reset component** (`usage_reset`): Separate component for reset countdown display
- New functions: `get_claude_oauth_token()`, `fetch_usage_limits()`, `collect_usage_limits_data()`, `render_usage_limits()`, `render_usage_reset()`, `format_reset_time()`
- Display format (Line 3): `Limit: 5h:22% 7d:54%` with color-coded thresholds
- Display format (Line 4): `Reset: 5h:2h15m 7d:Jan18` with reset countdown
- Reset time formatting: Shows relative time (<24h: "2h15m") or date (>24h: "Jan18")
- GitHub Actions CI/CD workflow for automated testing
- Pre-commit hooks configuration (.pre-commit-config.yaml)
- Architecture documentation with Mermaid diagrams
- `is_debug_mode()` helper function for standardized debug checks

### Changed
- Context window component updated to v2.15.0 with native percentage support
- Schema.json updated with new `context_window` object including `used_percentage`, `remaining_percentage`, `tokens_used`, `context_window_size`, and `source` fields
- Standardized debug variable to `STATUSLINE_DEBUG` (removed `STATUSLINE_DEBUG_MODE`)

### Fixed
- Context window accuracy: Native percentages avoid the cumulative token bug in pre-v2.1.6 implementations
- Documented all intentional error suppressions (Issue #76)

## [2.11.6] - 2025-12-15

### Fixed
- Prayer time status caching bug causing incorrect next prayer display
- Test suite mocking and path issues (Issue #62)
- Source-safe behavior for statusline.sh testing

### Changed
- Added fail-fast behavior with `set -eo pipefail` (Issue #77)

### Removed
- Dead code: lib/prayer_original_backup.sh

## [2.11.5] - 2025-12-14

### Fixed
- Comprehensive settings.json handling improvements
- Cross-platform compatibility (macOS, Ubuntu, Arch, Fedora, Alpine)
- Stat command syntax errors on Linux (Issue #57)
- Cache key sanitization for bash arithmetic evaluation
- Username sanitization for valid bash variable names
- Windows compatibility for dependency detection

### Added
- Length limit and debug logging for variable name sanitization

## [2.11.4] - 2025-12-13

### Fixed
- Installation hanging issue with robust directory removal
- Portable arithmetic operations (replaced `((count++))` patterns)
- `sh -c` argument syntax in installation commands

## [2.11.3] - 2025-12-12

### Fixed
- Installation hang on first run
- Curl pipe installation commands with proper `sh -c` pattern

## [2.11.2] - 2025-12-11

### Fixed
- Bekasi location detection precision
- Installation hang with enhanced debugging

## [2.11.1] - 2025-12-10

### Added
- Cache cleanup during installation to prevent format issues
- Travel-friendly prayer cache for faster location detection

## [2.11.0] - 2025-12-09

### Added
- GPS-first location detection for precise prayer times
- VPN-aware location display component
- Worldwide Islamic center location detection
- Location display component with GPS-accurate coordinates

### Fixed
- VPN false positive by including countryCode in API request
- Manual prayer coordinates override to prevent VPN interference
- Duplicate location display with early returns
- Jakarta coordinate patterns for VPN detection

## [2.10.0] - 2025-12-01

### Added
- 5-line statusline display (configurable 1-9 lines)
- Prayer times integration with Islamic calendar
- Cost tracking components (daily, weekly, monthly)
- Block metrics (burn rate, token usage, cache efficiency)
- MCP server monitoring

### Changed
- Modular architecture with 11 core modules
- Single Config.toml configuration (227 settings)
- 91.5% code reduction from v1

## [2.9.0] - 2025-11-15

### Added
- 3-tier download architecture for 100% install reliability
- Direct raw URLs, GitHub API fallback, retry with backoff

### Changed
- Installation script reliability improvements

## [2.8.0] - 2025-11-01

### Added
- Theme system (classic, garden, catppuccin, custom)
- XDG-compliant cache directory structure
- Repository-isolated caching

## [2.7.0] - 2025-10-15

### Added
- Atomic components architecture (21 components)
- Component registry system

## [2.0.0] - 2025-09-01

### Added
- Complete rewrite with modular architecture
- TOML configuration support
- Intelligent caching with TTL management
- Cross-platform compatibility layer

### Changed
- Migrated from monolithic to modular design
- Single-pass jq optimization (64→1 calls)

## [1.0.0] - 2025-08-01

### Added
- Initial release
- Basic statusline with git status
- Simple configuration

---

[Unreleased]: https://github.com/rz1989s/claude-code-statusline/compare/v2.11.6...HEAD
[2.11.6]: https://github.com/rz1989s/claude-code-statusline/compare/v2.11.5...v2.11.6
[2.11.5]: https://github.com/rz1989s/claude-code-statusline/compare/v2.11.0...v2.11.5
[2.11.0]: https://github.com/rz1989s/claude-code-statusline/compare/v2.10.0...v2.11.0
[2.10.0]: https://github.com/rz1989s/claude-code-statusline/compare/v2.9.0...v2.10.0
[2.9.0]: https://github.com/rz1989s/claude-code-statusline/compare/v2.8.0...v2.9.0
[2.8.0]: https://github.com/rz1989s/claude-code-statusline/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/rz1989s/claude-code-statusline/compare/v2.0.0...v2.7.0
[2.0.0]: https://github.com/rz1989s/claude-code-statusline/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/rz1989s/claude-code-statusline/releases/tag/v1.0.0
