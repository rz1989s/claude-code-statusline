# v2.1.66 Compatibility Audit + Future-Proof Architecture

**Date**: 2026-03-04
**Version**: v2.20.0
**Branch**: feat/v2166-compat
**Scope**: Full audit, new JSON abstraction layer, 5 new components, OAuth hardening, path migration

## Problem Statement

Claude Code v2.1.66 introduced schema changes and new fields not handled by the statusline:
1. `five_hour`/`seven_day` usage data is NOT in the official statusline JSON schema - OAuth API is the only source
2. `current_usage` path moved from top-level to `context_window.current_usage`
3. New fields available: `version`, `model.id`, `exceeds_200k_tokens`, `vim.mode`, `agent.name`, cumulative token counts, `workspace.added_dirs`
4. OAuth API fails silently with no error visibility
5. Tested version range outdated (v2.1.42)

## Architecture

### 1. JSON Field Access Abstraction Layer

New module: `lib/json_fields.sh`

**Functions:**
- `get_json_field(path, [default])` - Safe extraction with path migration. Tries canonical path first, then legacy fallback.
- `has_json_field(path)` - Boolean existence check
- `validate_json_schema()` - Startup validation, detect Claude Code version, log missing optional fields
- `get_detected_cc_version()` - Returns detected Claude Code version from `.version` field

**Path Migration Map:**
```
current_usage.input_tokens        -> context_window.current_usage.input_tokens
current_usage.output_tokens       -> context_window.current_usage.output_tokens
current_usage.cache_read_input_tokens    -> context_window.current_usage.cache_read_input_tokens
current_usage.cache_creation_input_tokens -> context_window.current_usage.cache_creation_input_tokens
```

**Schema Compatibility Matrix:**
```
model.id                              v2.1.6+
model.display_name                    v2.1.0+
version                               v2.1.50+
cwd                                   v2.1.0+
workspace.current_dir                 v2.1.0+
workspace.project_dir                 v2.1.0+
workspace.added_dirs                  v2.1.63+
context_window.used_percentage        v2.1.6+
context_window.remaining_percentage   v2.1.6+
context_window.context_window_size    v2.1.6+
context_window.current_usage          v2.1.50+
context_window.total_input_tokens     v2.1.50+
context_window.total_output_tokens    v2.1.50+
current_usage (top-level)             v2.1.6+ (deprecated, migrated to context_window.current_usage)
cost.total_cost_usd                   v2.1.0+
cost.total_duration_ms                v2.1.0+
cost.total_api_duration_ms            v2.1.0+
cost.total_lines_added                v2.1.0+
cost.total_lines_removed              v2.1.0+
exceeds_200k_tokens                   v2.1.50+
session_id                            v2.1.0+
transcript_path                       v2.1.0+
output_style.name                     v2.1.0+
vim.mode                              v2.1.50+ (only when vim mode enabled)
agent.name                            v2.1.50+ (only with --agent flag)
mcp.servers                           undocumented (present in practice)
five_hour/seven_day                   NOT in statusline JSON (OAuth API only)
```

**Module Loading Order:**
`json_fields` loads AFTER `security` and BEFORE `config` (needs early access to JSON).

### 2. OAuth API Hardening

File: `lib/components/usage_limits.sh`

**Changes to `fetch_usage_limits()`:**
- Capture HTTP status code: `curl -s -w "\n%{http_code}" --max-time 5`
- Parse response body and status separately
- Error handling per status code:
  - 200: Parse and cache response
  - 401: Log "OAuth token expired/invalid - re-authenticate Claude Code"
  - 403: Log "OAuth access forbidden"
  - 429: Log "Rate limited - using cached data"
  - 5xx: Single retry after 2s, then "API unavailable"
  - Timeout: Log "API timeout (5s)"
  - Connection error: Log "Cannot reach API"
- Show "Limit: --" instead of blank line when data unavailable
- Add `COMPONENT_USAGE_STATUS` variable for error state communication

### 3. Five New Atomic Components

#### 3.1 `version_display` (`lib/components/version_display.sh`)
- **Source**: `get_json_field "version"`
- **Format**: `v2.1.66` (short) or `CC v2.1.66` (full, configurable)
- **Color**: Teal (informational, distinct from model)
- **Config**: `features.show_version_display = true`, `version_display.format = "short"`
- **Default Line**: 2 (after model_info)
- **Fallback**: Hidden when field absent (pre-v2.1.50)

#### 3.2 `vim_mode` (`lib/components/vim_mode.sh`)
- **Source**: `get_json_field "vim.mode"`
- **Format**: `VIM:NORMAL` (green) / `VIM:INSERT` (yellow)
- **Config**: `features.show_vim_mode = true`
- **Default Line**: 8 (with session_mode)
- **Fallback**: Hidden when vim mode not enabled (field absent)

#### 3.3 `agent_display` (`lib/components/agent_display.sh`)
- **Source**: `get_json_field "agent.name"`
- **Format**: `Agent: security-reviewer`
- **Color**: Purple (distinguishes from other metadata)
- **Config**: `features.show_agent_display = true`
- **Default Line**: 8 (with session_mode)
- **Fallback**: Hidden when not in agent mode (field absent)

#### 3.4 `context_alert` (`lib/components/context_alert.sh`)
- **Source**: `get_json_field "exceeds_200k_tokens"`
- **Format**: `>200K` (red, bold) - only shows when true
- **Config**: `features.show_context_alert = true`, `context_alert.show_only_when_exceeded = true`
- **Default Line**: 4 (adjacent to context_window)
- **Fallback**: Hidden when false or field absent

#### 3.5 `total_tokens` (`lib/components/total_tokens.sh`)
- **Source**: `get_json_field "context_window.total_input_tokens"` + `get_json_field "context_window.total_output_tokens"`
- **Format**: `Tokens: 15.2K in / 4.5K out` or compact `19.7K total`
- **Color**: Blue (matches token_usage theme)
- **Config**: `features.show_total_tokens = true`, `total_tokens.format = "split"` (split/compact)
- **Default Line**: 4 (with block metrics)
- **Fallback**: Hidden when fields absent

### 4. Config.toml Updates

New entries in `examples/Config.toml`:
```toml
# === v2.20.0 NEW COMPONENTS ===
features.show_version_display = true
features.show_vim_mode = true
features.show_agent_display = true
features.show_context_alert = true
features.show_total_tokens = true

version_display.format = "short"
total_tokens.format = "split"
context_alert.show_only_when_exceeded = true
context_alert.threshold_label = ">200K"

# Updated default lines
display.line2.components = ["model_info", "version_display", "commits", "submodules", "version_info", "time_display"]
display.line4.components = ["burn_rate", "cache_efficiency", "block_projection", "total_tokens", "context_alert", "context_window"]
display.line8.components = ["mcp_status", "session_mode", "vim_mode", "agent_display"]
```

### 5. Module Refactoring

All 6 modules that directly access `STATUSLINE_INPUT_JSON` via jq will be refactored to use `get_json_field()`:

| Module | Fields Accessed | Migration Needed |
|--------|----------------|------------------|
| `lib/cost/native.sh` | `.current_usage.*`, `.cost.*` | YES - current_usage path |
| `lib/cost/session.sh` | `.context_window.*`, `.transcript_path`, `.session_id`, `.workspace.*` | NO - paths correct |
| `lib/cost/recommendations.sh` | `.current_usage.*` | YES - current_usage path |
| `lib/cost/api_live.sh` | `.five_hour.resets_at` | NO - OAuth-only field, skip abstraction |
| `lib/cli/reports.sh` | Multiple fields | PARTIAL - add get_json_field for new fields |
| `lib/mcp.sh` | `.mcp.servers` | NO - undocumented but working |

### 6. Documentation Updates

**CLAUDE.md:**
- Update JSON schema to match official v2.1.66 docs
- Update tested version: `v2.1.6-v2.1.66`
- Add new components (22 -> 27) to architecture
- Add JSON field access layer to key functions
- Add migration notes

### 7. Test Coverage

| Test File | Tests | Priority |
|-----------|-------|----------|
| `tests/unit/test_json_fields.bats` | get_json_field, has_json_field, path migration, schema validation, version detection | HIGH |
| `tests/unit/test_oauth_usage.bats` | Token retrieval, API responses (200/401/403/429/5xx), retry, cache, timeout | HIGH |
| `tests/unit/test_version_display.bats` | Collect/render with version present/absent, format options | MEDIUM |
| `tests/unit/test_vim_mode.bats` | NORMAL/INSERT rendering, absent field handling | MEDIUM |
| `tests/unit/test_agent_display.bats` | Agent present/absent, rendering | MEDIUM |
| `tests/unit/test_context_alert.bats` | Exceeded true/false/absent, conditional display | MEDIUM |
| `tests/unit/test_total_tokens.bats` | Split/compact format, zero/null handling | MEDIUM |

## Files Summary

**New (13):**
- `lib/json_fields.sh`
- `lib/components/version_display.sh`
- `lib/components/vim_mode.sh`
- `lib/components/agent_display.sh`
- `lib/components/context_alert.sh`
- `lib/components/total_tokens.sh`
- `tests/unit/test_json_fields.bats`
- `tests/unit/test_oauth_usage.bats`
- `tests/unit/test_version_display.bats`
- `tests/unit/test_vim_mode.bats`
- `tests/unit/test_agent_display.bats`
- `tests/unit/test_context_alert.bats`
- `tests/unit/test_total_tokens.bats`

**Modified (10):**
- `statusline.sh` (load json_fields, schema validation)
- `lib/cost/native.sh` (use get_json_field for current_usage)
- `lib/cost/session.sh` (use get_json_field)
- `lib/cost/recommendations.sh` (use get_json_field for current_usage)
- `lib/cli/reports.sh` (use get_json_field, add new field extraction)
- `lib/components/usage_limits.sh` (OAuth hardening)
- `examples/Config.toml` (new components + updated lines)
- `CLAUDE.md` (schema, version, architecture)
- `lib/components.sh` (register new components in load order)
- `lib/display.sh` (handle new components in rendering)

**Total: 23 files (13 new + 10 modified)**

## Compatibility

- Backward compatible with v2.1.6+ (path migration handles both old and new JSON)
- New components gracefully hidden when fields absent
- OAuth API fallback preserved for limit data
- No breaking changes to existing configuration
