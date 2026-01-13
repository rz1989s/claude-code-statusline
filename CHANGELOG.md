# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Native context window percentages** (Claude Code v2.1.6+): Now uses official `used_percentage` and `remaining_percentage` fields from Claude Code's statusline input
- New functions: `get_native_context_used_percentage()`, `get_native_context_remaining_percentage()`, `get_native_context_window_size()`, `has_native_context_percentages()`, `get_context_window_percentage_smart()`
- Smart fallback: Automatically uses native percentages when available (v2.1.6+), falls back to transcript parsing for older versions
- `COMPONENT_CONTEXT_REMAINING` and `COMPONENT_CONTEXT_SOURCE` variables for richer context data
- **Usage limits component** (`usage_limits`): Display Claude Code rate limits (5h session, 7d weekly) from Anthropic OAuth API
- New functions: `get_claude_oauth_token()`, `fetch_usage_limits()`, `collect_usage_limits_data()`, `render_usage_limits()`
- Display format: `Quota: 5h:22% 7d:54%` with color-coded thresholds
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
