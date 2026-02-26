# Design: Remaining 13 Issues — Full Implementation

**Date**: 2026-02-26
**Author**: CIPHER + RECTOR
**Branch Strategy**: One `feat/` or `fix/` branch per issue → merge to `nightly`
**Approach**: Module-Grouped (minimize merge conflicts, batch by shared files)

---

## Overview

13 open issues across 6 phases:

| Phase | Issues | Category |
|-------|--------|----------|
| 1 | #243 | Bug fix (declare -g bash 3.2) |
| 2 | #215, #216, #221 | Cost pipeline (new data analysis) |
| 3 | #208, #217, #218 | CLI commands (new flags + reports) |
| 4 | #210, #219, #220 | Alerts & wellness |
| 5 | #212 | Islamic features (prayer reminders) |
| 6 | #190, #191 | Close epics (meta-trackers) |

**Estimated total**: ~10 new files, ~1,640 lines implementation, ~8 new test files.

---

## Phase 1: Bug Fix — #243 `declare -g` Bash 3.2 Compatibility

**Branch**: `fix/declare-g-bash32`

### Problem

21 `declare -g` calls across 5 files crash on macOS Bash 3.2 when no modern bash is found. `declare -g` was introduced in Bash 4.2.

### Solution

Replace all `declare -g` with POSIX-compatible alternatives:

| Current | Replacement | Context |
|---------|-------------|---------|
| `declare -g VAR="val"` | `VAR="val"` | At file scope, `-g` is redundant |
| `declare -gA ASSOC=()` | `declare -A ASSOC=()` | At file scope, drop `-g` only |
| `declare -g VAR="val"` (in function) | `export VAR="val"` or refactor | Function scope needs export/eval |

### Files

1. `lib/components.sh` — 6 calls, all file scope → drop `-g`
2. `lib/github.sh` — 3 calls, file scope → drop `-g`
3. `lib/components/prayer_icon.sh` — 6 calls, file + function scope
4. `lib/components/prayer_times_only.sh` — 4 calls, function scope → refactor
5. `lib/cache/operations.sh` — 1 call, trap handler → use `export`

### Safety

Auto-upgrade mechanism (`_upgrade_bash_if_needed`) stays as-is. This fix ensures the script doesn't crash if the upgrade fails and compatibility mode kicks in.

### Tests

Existing tests must continue to pass. No new test file needed.

---

## Phase 2: Cost Pipeline — #215, #216, #221

### 2a: #215 Cost Per Commit Attribution

**Branch**: `feat/cost-per-commit`
**New file**: `lib/cost/commit_attribution.sh` (~150 lines)

#### Logic

1. `git log --format="%H %at %s" --since="30 days ago"` — get commit timestamps
2. For each commit gap (time between consecutive commits), sum JSONL costs in that time window
3. Cache results in `~/.cache/claude-code-statusline/commit_costs_<repo_hash>.json`
4. Cache TTL: 5 minutes

#### CLI

- Flag: `--commits`
- Function: `show_commit_cost_report()` in `lib/cli/reports.sh`
- Supports: `--json`, `--csv` output formats
- Supports: `--since`, `--until` date filters

#### Display

```
Commit Attribution (Last 30 Days)
Commit          │ Message                    │ Cost   │ Tokens
────────────────┼────────────────────────────┼────────┼────────
a1b2c3d (2h ago)│ Add user authentication    │  $4.56 │  45.2K
d4e5f6g (5h ago)│ Fix login bug              │  $1.23 │  12.1K
h7i8j9k (1d ago)│ Update README              │  $0.34 │   3.4K
────────────────┼────────────────────────────┼────────┼────────
                │ Total (3 commits)          │  $6.13 │  60.7K
```

#### Config

```toml
[cost.commit_attribution]
enabled = true
lookback_days = 30
```

---

### 2b: #216 MCP Cost Attribution

**Branch**: `feat/mcp-cost-attribution`
**New file**: `lib/cost/mcp_attribution.sh` (~120 lines)

#### Logic

1. Scan JSONL files for `tool_use` entries with `mcp__` prefix
2. Group by server name (extract from `mcp__<server>__<tool>` pattern)
3. Attribute proportional token cost per server based on call frequency + context size
4. Cache results: 5 min TTL

#### CLI

- Flag: `--mcp-costs`
- Function: `show_mcp_cost_report()` in `lib/cli/reports.sh`
- Supports: `--json`, `--csv` output formats

#### Display

```
MCP Cost Attribution
MCP Server      │ Calls │ Tokens  │ Cost   │ Share
────────────────┼───────┼─────────┼────────┼──────
filesystem      │  234  │  456K   │  $5.67 │  45%
github          │  123  │  234K   │  $3.45 │  28%
sqlite          │   89  │  167K   │  $2.34 │  19%
context7        │   45  │   78K   │  $1.00 │   8%
────────────────┼───────┼─────────┼────────┼──────
Total           │  491  │  935K   │ $12.46 │ 100%
```

#### Config

```toml
[cost.mcp_attribution]
enabled = true
```

---

### 2c: #221 Smart Cost Recommendations

**Branch**: `feat/smart-cost-recommendations`
**New file**: `lib/cost/recommendations.sh` (~200 lines)

#### Rules Engine (5 heuristic rules)

1. **Cache optimization**: Cache hit rate < 60% → suggest grouping queries
2. **Session cost spikes**: Any session > 2x average → flag for review
3. **Daily budget pacing**: On track to exceed daily budget by 50% of day → warn
4. **High avg cost**: Avg cost/session in top quartile → suggest shorter context
5. **Idle burn**: Sessions with long gaps + high token burn → suggest smaller context

#### CLI

- Flag: `--recommendations`
- Function: `show_recommendations_report()` in `lib/cli/reports.sh`
- Supports: `--json` output

#### Display

```
Cost Recommendations

1. Cache Efficiency Low (45% → target 70%)
   Group related queries to improve cache reuse
   Potential savings: ~$5.67/week

2. Session Cost Spike Detected
   Yesterday 3pm session cost $8.45 (3x your average)
   Review: ./statusline.sh --instances --since yesterday

3. Daily Budget Pacing
   Current rate: $18.90/day (budget: $30.00)
   On track to use 63% of budget — looking good
```

#### Config

```toml
[cost.recommendations]
enabled = true
cache_target_percent = 70
session_spike_multiplier = 2.0
```

---

## Phase 3: CLI Commands — #208, #217, #218

### 3a: #208 `--watch` Live Monitoring Mode

**Branch**: `feat/watch-mode`
**New file**: `lib/cli/watch.sh` (~180 lines)

#### CLI

```bash
./statusline.sh --watch                  # Default 10s refresh
./statusline.sh --watch --refresh 5      # 5 second refresh
./statusline.sh --watch --refresh 0.5    # Sub-second
```

#### Logic

1. `_cli_command="watch"` + `_cli_refresh=10` in parser
2. `show_watch_mode()` enters loop:
   - `tput clear` + `tput cup 0 0` for flicker-free updates
   - Header: `LIVE MONITORING | <repo> | Refresh: 10s | Ctrl+C to exit`
   - Re-run data collection (JSONL-based, no stdin dependency)
   - Render compact dashboard: session cost, daily cost + progress bar, tokens, cache efficiency, burn rate, limits
   - Show delta since last refresh: `(+$0.12 last 10s)`
   - `sleep $refresh_interval`
   - Trap `SIGINT` → clean exit with summary

3. No stdin dependency — reads JSONL directly for standalone terminal use

#### Config

```toml
[watch]
enabled = true
default_refresh = 10
min_refresh = 0.5
```

---

### 3b: #217 Historical Trends with ASCII Charts

**Branch**: `feat/historical-trends`
**New file**: `lib/cli/charts.sh` (~200 lines)

#### CLI

```bash
./statusline.sh --trends                 # Default 30 days
./statusline.sh --trends --period 7d     # Last 7 days
./statusline.sh --trends --period 90d    # Last 90 days
./statusline.sh --trends --json          # JSON output
```

#### Chart Rendering

Vertical bar chart using Unicode block elements (`▁▂▃▄▅▆▇█`):

```
Daily Cost ($) — Last 30 Days
   │
15 │                                    ▄
12 │              ▄   ▄▄    ▄        ██
 9 │  ▄     ▄  ▄▄ ██▄ ███   ██   ▄  ▄██
 6 │ ██ ▄▄ ██ ███████████▄▄███▄▄██▄████
 3 │ ▄██████████████████████████████████
 0 ├────────────────────────────────────
    Feb 01              Feb 15         Feb 26

Summary: Avg $7.23/day | Peak $15.40 (Feb 22) | Total $217.00
Trend: +12% vs previous period
```

#### Implementation

1. Reuse `calculate_native_daily_cost()` from `lib/cost/report_calc.sh`
2. `render_vertical_bar_chart(data[], labels[], height, title)` — core renderer
3. Auto-scale Y-axis to max value
4. 8-level granularity per character cell
5. Summary line: avg, peak, total, trend (% change vs previous period)

#### Config

```toml
[trends]
default_period = "30d"
chart_height = 10
```

---

### 3c: #218 CSV Export

**Branch**: `feat/csv-export`
**Extend**: `lib/cli/reports.sh` + `lib/cli/report_format.sh` (~80 lines)

#### CLI

`--csv` works as output modifier on any existing report:

```bash
./statusline.sh --daily --csv
./statusline.sh --weekly --csv
./statusline.sh --monthly --csv
./statusline.sh --commits --csv          # From #215
./statusline.sh --mcp-costs --csv        # From #216
./statusline.sh --instances --csv
./statusline.sh --burn-rate --csv
```

#### Implementation

1. New `_cli_format="csv"` option alongside `"json"` and `"human"`
2. `format_as_csv(headers[], rows[][])` utility in `lib/cli/report_format.sh`
3. Proper CSV escaping (RFC 4180: double-quote fields containing commas/quotes/newlines)
4. Header row always included
5. Each `show_*_report()` gains a `csv` branch in its format switch

#### Example Output

```csv
date,day,sessions,cost_usd,tokens_input,tokens_output
2026-02-26,Thu,15,12.45,456789,234567
2026-02-25,Wed,8,6.78,234567,123456
```

---

## Phase 4: Alerts & Wellness — #210, #219, #220

### 4a: #210 Limit Warnings System

**Branch**: `feat/limit-warnings`
**Extend**: `lib/cost/alerts.sh` + `lib/components/usage_limits.sh` (~60 lines)

#### What's New (beyond existing #214 implementation)

1. **Context window alerts** — warn at configurable thresholds
2. **Unified limit check** — `check_all_limits()` returns worst level across all limit types
3. **CLI summary** — `--limits` flag

```bash
check_all_limits() → evaluates:
  - Cost thresholds (existing: session/daily/weekly/monthly)
  - Rate limits (existing: 5h/7d utilization)
  - Context window (NEW: warn at 75%, critical at 90%)
  → Returns: "normal" | "warn" | "critical"
```

#### CLI

```bash
./statusline.sh --limits                 # Human-readable summary
./statusline.sh --limits --json          # JSON output
```

```
Limit Status:
  Cost (daily):   $12.45 / $30.00  ▓▓▓▓▓▓▓▓░░░░  41%  OK
  Rate (5h):      15.0%            ▓▓▓░░░░░░░░░  15%  OK
  Rate (7d):      67.0%            ▓▓▓▓▓▓▓▓░░░░  67%  WARN
  Context:        89%              ▓▓▓▓▓▓▓▓▓▓░░  89%  CRITICAL
```

#### Config

```toml
[limits]
context_warn_percent = 75
context_critical_percent = 90
show_limit_summary = true
```

---

### 4b: #219 Wellness Mode — Break Reminders

**Branch**: `feat/wellness-mode`
**New files**: `lib/wellness.sh` (~140 lines) + `lib/components/wellness.sh` (~80 lines)

#### Design

Passive wellness tracking. Triggers on each statusline render (every Claude Code interaction). Not a daemon.

#### Logic

1. Track session start via cache file (`wellness_session_start_<pid>`)
2. On each render, calculate elapsed time since start
3. Compare against thresholds
4. Show indicator in statusline component
5. Optional desktop notification (reuses `send_cost_notification()` pattern)

#### Thresholds

| Duration | Level | Display |
|----------|-------|---------|
| < 45min | Normal | `Session: 32m` |
| 45-90min | Gentle | `Session: 52m — Break soon` |
| 90-120min | Warn | `Session: 1h 35m — Break recommended` |
| > 120min | Urgent | `Session: 2h 10m — Take a break!` |

#### Component

```bash
collect_wellness_data()  # Read session start, calculate elapsed
render_wellness()        # "Session: 1h 15m — Break in 15m"
```

#### Config

```toml
[wellness]
enabled = false              # Opt-in
gentle_minutes = 45
warn_minutes = 90
urgent_minutes = 120
break_duration = 10
desktop_notify = false
notify_cooldown = 900
```

---

### 4c: #220 Focus Session Tracking

**Branch**: `feat/focus-sessions`
**New files**: `lib/focus.sh` (~150 lines) + `lib/components/focus_session.sh` (~100 lines)

#### CLI

```bash
./statusline.sh --focus start            # Start focus session
./statusline.sh --focus stop             # End + show summary
./statusline.sh --focus status           # Current session info
./statusline.sh --focus history          # Past sessions table
./statusline.sh --focus history --json   # JSON export
```

#### Storage

`~/.cache/claude-code-statusline/focus_sessions.json`:

```json
{
  "active": {
    "start": 1740000000,
    "repo": "statusline",
    "goal": "implement #220"
  },
  "history": [
    {
      "start": 1739990000,
      "end": 1739993600,
      "duration_minutes": 60,
      "cost": 4.56,
      "lines_added": 120,
      "lines_removed": 30,
      "commits": 3
    }
  ]
}
```

#### Component

```
collect_focus_session_data()  # Read active session, calculate metrics
render_focus_session()        # "FOCUS | 45m | $2.34 | +89/-12 | 2 commits"
```

#### Stop Summary

```
Focus Session Complete
  Duration:  1h 15m
  Cost:      $4.56
  Lines:     +234 / -45
  Commits:   3
  Avg Cost:  $3.65/hr
```

#### Config

```toml
[focus]
enabled = true
default_duration = 50
show_in_statusline = true
track_commits = true
track_cost = true
```

---

## Phase 5: Islamic Features — #212 Prayer Break Reminders

**Branch**: `feat/prayer-reminders`
**New file**: `lib/prayer/reminders.sh` (~150 lines)

### Reminder Levels

| Time to prayer | Level | Display |
|----------------|-------|---------|
| > 30min | Normal | (standard prayer display) |
| 15-30min | Heads up | `Dhuhr in 22m — plan a stopping point` |
| 5-15min | Prepare | `Dhuhr in 8m — wrap up current task` |
| < 5min | Imminent | `Dhuhr in 3m — time to pray` |
| Active (< 30min past) | Active | `Dhuhr time — take your break` |

### Integration

- **Wellness** (#219): Prayer breaks reset the session timer
- **Focus** (#220): Suggest ending focus session if prayer < 15min away

### Desktop Notifications

Reuses `send_cost_notification()` pattern. One notification per prayer time per day (tracked via cache file `prayer_notified_<prayer>_<date>`).

### Config

```toml
[prayer.reminders]
enabled = false              # Opt-in
headsup_minutes = 30
prepare_minutes = 15
imminent_minutes = 5
desktop_notify = false
integrate_wellness = true
integrate_focus = true
```

---

## Phase 6: Close Epics — #190, #191

No implementation. Close with summary comment after all children ship:

- **#191 (Moat Features)**: Children — #212, #213 (done), #214 (done), #215, #216, #217, #218, #219, #220, #221
- **#190 (Real-time Monitoring)**: Children — #208, #210

---

## Config.toml Additions Summary

~50 new settings total:

```toml
# Phase 2
[cost.commit_attribution]
enabled = true
lookback_days = 30

[cost.mcp_attribution]
enabled = true

[cost.recommendations]
enabled = true
cache_target_percent = 70
session_spike_multiplier = 2.0

# Phase 3
[watch]
enabled = true
default_refresh = 10
min_refresh = 0.5

[trends]
default_period = "30d"
chart_height = 10

# Phase 4
[limits]
context_warn_percent = 75
context_critical_percent = 90
show_limit_summary = true

[wellness]
enabled = false
gentle_minutes = 45
warn_minutes = 90
urgent_minutes = 120
break_duration = 10
desktop_notify = false
notify_cooldown = 900

[focus]
enabled = true
default_duration = 50
show_in_statusline = true
track_commits = true
track_cost = true

# Phase 5
[prayer.reminders]
enabled = false
headsup_minutes = 30
prepare_minutes = 15
imminent_minutes = 5
desktop_notify = false
integrate_wellness = true
integrate_focus = true
```

---

## New CLI Flags Summary

| Flag | Phase | Report | Formats |
|------|-------|--------|---------|
| `--commits` | 2a | Commit cost attribution | human, json, csv |
| `--mcp-costs` | 2b | MCP server cost breakdown | human, json, csv |
| `--recommendations` | 2c | Smart cost suggestions | human, json |
| `--watch [--refresh N]` | 3a | Live monitoring dashboard | terminal |
| `--trends [--period Nd]` | 3b | Historical ASCII charts | human, json |
| `--csv` | 3c | CSV output modifier | csv |
| `--limits` | 4a | Unified limit summary | human, json |
| `--focus start/stop/status/history` | 4c | Focus session management | human, json |

---

## New Files Summary

| File | Phase | Lines (est.) |
|------|-------|-------------|
| `lib/cost/commit_attribution.sh` | 2a | ~150 |
| `lib/cost/mcp_attribution.sh` | 2b | ~120 |
| `lib/cost/recommendations.sh` | 2c | ~200 |
| `lib/cli/watch.sh` | 3a | ~180 |
| `lib/cli/charts.sh` | 3b | ~200 |
| `lib/wellness.sh` | 4b | ~140 |
| `lib/components/wellness.sh` | 4b | ~80 |
| `lib/focus.sh` | 4c | ~150 |
| `lib/components/focus_session.sh` | 4c | ~100 |
| `lib/prayer/reminders.sh` | 5 | ~150 |
| **Total** | | **~1,470** |

## Test Files Summary

| File | Covers |
|------|--------|
| `tests/unit/test_commit_attribution.bats` | #215 |
| `tests/unit/test_mcp_attribution.bats` | #216 |
| `tests/unit/test_recommendations.bats` | #221 |
| `tests/unit/test_watch_mode.bats` | #208 |
| `tests/unit/test_charts.bats` | #217 |
| `tests/unit/test_csv_export.bats` | #218 |
| `tests/unit/test_wellness.bats` | #219 |
| `tests/unit/test_focus_sessions.bats` | #220 |
| `tests/unit/test_prayer_reminders.bats` | #212 |
| Extend `test_limit_warnings.bats` or existing | #210 |
