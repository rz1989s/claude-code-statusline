# Responsive Statusline Design

**Issue**: #289 — feat: responsive statusline — adapt to terminal width
**Version**: v2.23.0 (target)
**Date**: 2026-03-29

## Problem

When the terminal pane is narrow (split tmux, side-by-side layout), statusline lines wrap and consume more vertical space than CC allocates. CC reserves fixed vertical space based on `display.lines` — wrapping breaks this contract, pushing lines off-screen and making the statusline partially or entirely invisible.

## Solution

Width-aware component filtering. Detect terminal width, drop lower-priority components per line until the line fits, and apply ANSI-safe truncation as a safety net for edge cases where even a single component exceeds the terminal width.

**Always-on. Zero configuration required.**

## Architecture

### New Module: `lib/responsive.sh`

Single new module following existing patterns (include guard, `load_module`). Sourced by `display.sh` after `components.sh`.

```
lib/responsive.sh
  ├── detect_terminal_width()        # Cached width detection chain
  ├── measure_visible_width()        # ANSI-strip + character count
  ├── get_component_priority()       # Lookup from priority table
  ├── filter_line_components()       # Drop-by-priority loop
  └── truncate_line_ansi_safe()      # Safety-net hard-cut with …
```

### Integration Point

One modification in `build_component_line()` (`lib/display.sh`). After rendering all components, call `filter_line_components()` to remove components that don't fit before joining with separators.

```
BEFORE: render all → join with separator → echo
AFTER:  render all → filter_line_components() → join survivors → echo
```

No changes to any of the 38 existing component files. No changes to `register_component()` API. No new component render functions.

## Width Detection

```bash
detect_terminal_width()
```

Priority chain:

| Priority | Source | Notes |
|----------|--------|-------|
| 1 | `ENV_CONFIG_TERMINAL_WIDTH` | User override, follows existing `ENV_CONFIG_*` pattern |
| 2 | `$COLUMNS` | Works when user exports it in shell profile |
| 3 | `tput cols` | Mirrors `$COLUMNS` when set, else returns 80 default |
| 4 | Fallback: **120** | Generous default — don't penalize wide-terminal majority |

**Caching**: Result stored in `STATUSLINE_TERMINAL_WIDTH` for the duration of one statusline invocation. Called once, reused across all 8 lines.

**Limitation**: CC spawns the statusline as a piped subprocess (`echo JSON | bash statusline.sh`). In this context, `$COLUMNS` is unset by default and `/dev/tty` is not available. Users who need accurate auto-detection should add `export COLUMNS` to their `.zshrc`/`.bashrc`. Without it, the 120-column fallback applies.

**Future-proof**: If CC adds a `terminal_width` field to the JSON input, it would slot in at priority 1.5 (after user override, before `$COLUMNS`).

## Width Measurement

```bash
measure_visible_width "$text"
```

Three-step measurement:

1. **Strip ANSI escape sequences**: `sed 's/\x1b\[[0-9;]*m//g'` — removes all color/style codes
2. **Count characters**: `printf '%s' "$stripped" | wc -m` — Unicode-aware character count (not byte count)
3. **Emoji correction**: Count double-width emoji in the statusline's character ranges (U+1F300–U+1F9FF, U+2600–U+27BF), add 1 per occurrence

**Accuracy**: Within +/-1-2 columns. Not a full Unicode East Asian Width implementation (impossible in pure bash). The safety-net truncation handles the remaining edge.

## Component Priority Table

Four priority levels:

| Level | Meaning | Behavior |
|-------|---------|----------|
| 1 | Essential | Never dropped (only truncated as last resort) |
| 2 | Important | Dropped under moderate pressure |
| 3 | Nice-to-have | Dropped early |
| 4 | First to go | Sacrificed first when space is tight |

### Default Priorities

**Line 1 — Repository identity:**

| Component | Priority |
|-----------|----------|
| repo_info | 1 |

**Line 2 — Model & git metrics:**

| Component | Priority |
|-----------|----------|
| model_info | 1 |
| bedrock_model | 2 |
| commits | 2 |
| submodules | 3 |
| version_info | 3 |
| time_display | 4 |

**Line 3 — Cost analytics:**

| Component | Priority |
|-----------|----------|
| cost_repo | 1 |
| cost_monthly | 2 |
| cost_live | 2 |
| cost_weekly | 3 |
| cost_daily | 4 |

**Line 4 — Block metrics:**

| Component | Priority |
|-----------|----------|
| context_window | 1 |
| burn_rate | 2 |
| cache_efficiency | 3 |
| block_projection | 3 |
| code_productivity | 4 |

**Line 5 — Usage limits:**

| Component | Priority |
|-----------|----------|
| usage_limits | 1 |
| usage_reset | 2 |

**Line 6 — Calendar & wellness:**

| Component | Priority |
|-----------|----------|
| hijri_calendar | 2 |
| wellness | 3 |

**Line 7 — Prayer:**

| Component | Priority |
|-----------|----------|
| prayer_times | 1 |
| prayer_times_only | 1 |
| prayer_icon | 2 |

**Line 8 — MCP:**

| Component | Priority |
|-----------|----------|
| mcp_status | 1 |
| mcp_native | 2 |
| mcp_servers | 2 |
| mcp_plugins | 3 |

**Other components (used in alternate configurations):**

| Component | Priority |
|-----------|----------|
| context_alert | 1 |
| vim_mode | 2 |
| agent_display | 2 |
| session_info | 2 |
| session_mode | 3 |
| total_tokens | 3 |
| token_usage | 3 |
| github | 3 |
| location_display | 3 |
| version_display | 3 |

**Unregistered components**: Default to priority 3.

## Filter Logic

```bash
filter_line_components "$width_budget" "$separator" "${components[@]}"
```

### Algorithm

```
1. Receive: width budget, separator string, array of (component_name, rendered_output) pairs
2. Measure visible width of each rendered component
3. Calculate total: sum(component_widths) + (N-1) * separator_visible_width
4. While total > budget AND component_count > 1:
   a. Find lowest-priority component (highest priority number)
   b. Tie-break: drop rightmost (users read left-to-right)
   c. Remove it, recalculate total
5. Return surviving component names
```

### Key Behaviors

- **Never drops the last component**: A line with 1 component is better than an empty line. If even that overflows, truncation handles it.
- **Separator-aware**: Removing a component saves `component_width + separator_width`. Removing the last remaining separator saves only `component_width`.
- **Tie-breaking**: Same priority → rightmost dropped first. Leftmost components feel more "primary" due to reading order.
- **Short-circuit**: If total width <= budget before the loop, zero overhead.

## Safety-Net Truncation

```bash
truncate_line_ansi_safe "$line" "$max_width"
```

Only fires when a single component exceeds the full terminal width (rare — mainly `repo_info` with long paths/branches).

### Algorithm

1. If visible width <= max_width: return as-is (common fast path)
2. Walk string character by character:
   - Track "inside ANSI escape sequence" state — pass through without counting width
   - Track visible column position
   - At column `(max_width - 1)`: append `…` (Unicode ellipsis, 1 column) + `\e[0m` (reset)
   - Stop
3. Return truncated string

### Behaviors

- Preserves all ANSI sequences up to the cut point
- Closes any open color/style sequences with `\e[0m` to prevent terminal bleed
- The `…` character visually signals truncation to the user
- Dropped components produce NO indicator (silent)

## Debug Logging

When `STATUSLINE_DEBUG=true`, log responsive decisions to stderr:

```
[responsive] terminal width: 85 (source: COLUMNS)
[responsive] line2: dropped time_display (pri:4), dropped version_info (pri:3)
[responsive] line2: 3/5 components, 72 cols (budget: 85)
[responsive] line4: truncated at col 85 (safety net)
```

## Configuration

### v1: Zero Config

Always-on. No new Config.toml settings.

One environment override for manual width control:

```bash
ENV_CONFIG_TERMINAL_WIDTH=100 ./statusline.sh
```

### Future (v2): Optional Config.toml Section

```toml
[responsive]
# enabled = true          # Toggle responsive mode
# fallback_width = 120    # Default when detection fails
```

Not implemented in v1. Reserved for future use.

## Testing

### New Test File: `tests/unit/test_responsive.bats`

**Width detection** (~5 tests):
- `COLUMNS=100` → returns 100
- `ENV_CONFIG_TERMINAL_WIDTH=90` overrides `COLUMNS=100` → returns 90
- Empty `COLUMNS`, no override → returns 120 (fallback)
- Invalid `COLUMNS=-1` → returns 120 (fallback)
- Cached across calls within same invocation

**Width measurement** (~6 tests):
- Plain text: `"hello"` → 5
- ANSI-colored: `"\e[32mhello\e[0m"` → 5
- Nested ANSI: `"\e[1m\e[32mbold green\e[0m"` → 10
- Emoji: `"🧠 Opus"` → 7 (emoji = 2 cols)
- Empty string → 0
- Mixed ANSI + emoji: accurate combined measurement

**Component filtering** (~10 tests):
- All fit → no dropping (pass-through)
- Progressive dropping by priority (4 first, then 3, then 2)
- Tie-breaking: same priority → rightmost dropped
- Never drop last component
- Separator width accounting (N-1 separators)
- Single component wider than budget → returns it (defer to truncation)
- Empty component list → empty return

**ANSI-safe truncation** (~5 tests):
- Plain text truncation: `"hello world"` at 8 → `"hello w…"`
- ANSI-aware: `"\e[32mhello\e[0m"` at 4 → `"\e[32mhel\e[0m…"`
- Emoji-aware: `"🧠 Opus 4.6"` at 6 → `"🧠 Op…"`
- No-op when within budget: `"short"` at 80 → `"short"`
- Closes open ANSI sequences with reset

**Integration** (~4 tests in `tests/integration/`):
- Full statusline at `COLUMNS=120` → all components present
- Full statusline at `COLUMNS=60` → fewer components, no wrapping
- Full statusline at `COLUMNS=40` → minimal components, truncation visible
- **Invariant**: every output line's visible width <= `COLUMNS`

**Estimated**: ~25-30 new tests.

## Files Changed

| File | Change |
|------|--------|
| `lib/responsive.sh` | **NEW** — entire responsive module |
| `lib/display.sh` | Modify `build_component_line()` to call `filter_line_components()` |
| `statusline.sh` | Add `load_module "responsive"` |
| `tests/unit/test_responsive.bats` | **NEW** — unit tests |
| `tests/integration/test_responsive_integration.bats` | **NEW** — integration tests |
| `CLAUDE.md` | Update architecture section |
| `examples/Config.toml` | Add commented-out `[responsive]` section |

**No changes to**: Any of the 38 component files, `lib/components.sh`, `register_component()` API, `lib/config/`.

## Out of Scope (v2 candidates)

- **Compact render modes**: Components rendering shorter variants before being dropped
- **Component self-registration with priority**: Extending `register_component()` to accept priority
- **User-configurable priority**: Per-component priority overrides in Config.toml
- **CC upstream**: Requesting `terminal_width` field in CC's JSON input
- **CJK full-width support**: Full Unicode East Asian Width tables
