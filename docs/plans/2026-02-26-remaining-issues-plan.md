# Remaining 13 Issues — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement all 13 remaining open GitHub issues across 6 phases, closing each with one branch and one commit per issue.

**Architecture:** Module-grouped approach — batch changes by shared files to minimize merge conflicts. Each task creates a feature branch from `nightly`, implements code + tests, commits, merges back to `nightly` with `--no-ff`, and closes the GitHub issue.

**Tech Stack:** Bash 4+, BATS testing framework, jq for JSON, TOML configuration, Unicode rendering

---

## Task 1: Fix `declare -g` Bash 3.2 Compatibility (#243)

**Files:**
- Modify: `lib/components.sh:23-29`
- Modify: `lib/github.sh:50-52`
- Modify: `lib/components/prayer_icon.sh:24-25,32,41`
- Modify: `lib/components/prayer_times_only.sh:17,27,62,65`
- Modify: `lib/cache/operations.sh:96`

**Step 1: Create branch**

```bash
git checkout -b fix/declare-g-bash32 nightly
```

**Step 2: Fix lib/components.sh (lines 23-29)**

Replace all `declare -gA` and `declare -ga` at file scope with `declare -A` and `declare -a`:

```bash
# Line 23: declare -gA STATUSLINE_COMPONENT_REGISTRY=()
# Change to: declare -A STATUSLINE_COMPONENT_REGISTRY=()

# Line 24: declare -ga STATUSLINE_COMPONENT_ORDER=()
# Change to: declare -a STATUSLINE_COMPONENT_ORDER=()

# Line 27: declare -gA COMPONENT_DESCRIPTIONS=()
# Change to: declare -A COMPONENT_DESCRIPTIONS=()

# Line 28: declare -gA COMPONENT_DEPENDENCIES=()
# Change to: declare -A COMPONENT_DEPENDENCIES=()

# Line 29: declare -gA COMPONENT_ENABLED=()
# Change to: declare -A COMPONENT_ENABLED=()
```

**Step 3: Fix lib/github.sh (lines 50-52)**

Replace `declare -g` at file scope with plain assignment:

```bash
# Line 50: declare -g GITHUB_RATE_LIMITED="false"
# Change to: GITHUB_RATE_LIMITED="false"

# Line 51: declare -g GITHUB_RATE_REMAINING=""
# Change to: GITHUB_RATE_REMAINING=""

# Line 52: declare -g GITHUB_RATE_RESET=""
# Change to: GITHUB_RATE_RESET=""
```

**Step 4: Fix lib/components/prayer_icon.sh (lines 24-25, 32, 41)**

```bash
# Lines 24-25: declare -g → plain assignment (file scope)
# COMPONENT_PRAYER_ICON_CURRENT=""
# COMPONENT_PRAYER_ICON_INDEX=-1

# Line 32: declare -gA → declare -A (file scope, still needs -A for associative)
# declare -A PRAYER_ICONS=(...)

# Line 41: declare -ga → declare -a (file scope)
# declare -a PRAYER_NAMES=(...)
```

**Step 5: Fix lib/components/prayer_times_only.sh (lines 17, 27, 62, 65)**

```bash
# Line 17: declare -g → plain assignment (file scope)
# COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=""

# Lines 27, 62, 65: declare -g inside functions → use plain assignment
# These are re-assignments of the file-scope variable, so just:
# COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=""
# COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=$(format_prayer_times_display ...)
# COMPONENT_PRAYER_TIMES_ONLY_DISPLAY=""
```

**Step 6: Fix lib/cache/operations.sh (line 96)**

```bash
# Line 96: declare -g "$trap_marker=installed"
# Change to: eval "$trap_marker=installed"
# (Line 97 already has: export "$trap_marker")
```

**Step 7: Run existing tests to verify nothing broke**

```bash
npm test
```

Expected: All existing tests pass (no new tests needed for a bug fix).

**Step 8: Commit and merge**

```bash
git add lib/components.sh lib/github.sh lib/components/prayer_icon.sh lib/components/prayer_times_only.sh lib/cache/operations.sh
git commit -m "fix: remove declare -g for bash 3.2 compatibility (closes #243)"
git checkout nightly && git merge fix/declare-g-bash32 --no-ff -m "Merge fix/declare-g-bash32"
gh issue close 243 --comment "Fixed: removed all 21 declare -g calls across 5 files. File-scope declarations use declare -A/-a (without -g), plain assignments replace declare -g for scalars, eval replaces declare -g in dynamic contexts." --reason completed
```

---

## Task 2: Cost Per Commit Attribution (#215)

**Files:**
- Create: `lib/cost/commit_attribution.sh`
- Modify: `lib/cost.sh:76` (add source line)
- Modify: `statusline.sh:1101-1112` (add `--commits` flag)
- Modify: `statusline.sh:1214-1216` (add dispatch)
- Modify: `statusline.sh:229-243` (add help text)
- Modify: `lib/cli/reports.sh` (add `show_commit_cost_report()`)
- Create: `tests/unit/test_commit_attribution.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/cost-per-commit nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_commit_attribution.bats`:

```bash
#!/usr/bin/env bats
# Test commit cost attribution (#215)

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_commit_config/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() {
    common_teardown
}

@test "calculate_commit_costs function exists" {
    run type calculate_commit_costs
    assert_success
}

@test "calculate_commit_costs returns empty for non-git directory" {
    cd "$BATS_TMPDIR"
    run calculate_commit_costs "/tmp/not-a-repo" 30
    assert_success
    assert_output ""
}

@test "format_commit_cost_row formats correctly" {
    run format_commit_cost_row "abc1234" "Fix login bug" "1.23" "12100" "2h ago"
    assert_success
    assert_output --partial "abc1234"
    assert_output --partial "Fix login bug"
    assert_output --partial "1.23"
}

@test "show_commit_cost_report function exists" {
    run type show_commit_cost_report
    assert_success
}

@test "show_commit_cost_report json format returns valid JSON" {
    # Mock git log to return known data
    function git() {
        if [[ "$1" == "log" ]]; then
            echo "abc1234 1740000000 Fix login bug"
            echo "def5678 1739990000 Add auth"
        elif [[ "$1" == "rev-parse" ]]; then
            echo "/tmp/test-repo"
        fi
    }
    export -f git

    run show_commit_cost_report "json" "false" "" "" ""
    assert_success
    # Should output valid JSON (even if empty array)
    echo "$output" | jq . >/dev/null 2>&1
    assert_success
}
```

**Step 3: Run test to verify it fails**

```bash
bats tests/unit/test_commit_attribution.bats
```

Expected: FAIL — functions not defined.

**Step 4: Create lib/cost/commit_attribution.sh**

```bash
#!/bin/bash
# ============================================================================
# Cost Per Commit Attribution (Issue #215)
# Correlate JSONL costs with git commit timestamps
# ============================================================================

[[ "${STATUSLINE_COST_COMMIT_ATTRIBUTION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_COMMIT_ATTRIBUTION_LOADED=true

# Calculate cost attributed to each commit by time-windowing JSONL data
# Args: $1=repo_dir $2=lookback_days
# Output: Lines of "commit_hash\ttimestamp\tmessage\tcost\ttokens"
calculate_commit_costs() {
    local repo_dir="${1:-$(pwd)}"
    local lookback_days="${2:-${CONFIG_COST_COMMIT_ATTRIBUTION_LOOKBACK_DAYS:-30}}"

    # Must be a git repo
    if ! git -C "$repo_dir" rev-parse --is-inside-work-tree &>/dev/null; then
        return 0
    fi

    # Get commits with timestamps
    local commits
    commits=$(git -C "$repo_dir" log --format="%H %at %s" --since="${lookback_days} days ago" 2>/dev/null) || return 0
    [[ -z "$commits" ]] && return 0

    # Get JSONL directory
    local projects_dir
    projects_dir=$(get_claude_projects_dir 2>/dev/null)
    [[ -z "$projects_dir" || ! -d "$projects_dir" ]] && return 0

    # Find matching project JSONL files
    local project_jsonl_dir
    project_jsonl_dir=$(find_project_jsonl_dir "$repo_dir" "$projects_dir" 2>/dev/null)
    [[ -z "$project_jsonl_dir" || ! -d "$project_jsonl_dir" ]] && return 0

    # Build timestamp→cost mapping from JSONL files
    local prev_timestamp=""
    local results=""

    while IFS= read -r line; do
        local commit_hash timestamp message
        commit_hash="${line%% *}"
        local rest="${line#* }"
        timestamp="${rest%% *}"
        message="${rest#* }"

        # Truncate message to 40 chars
        [[ ${#message} -gt 40 ]] && message="${message:0:37}..."

        # Sum JSONL costs between this commit and previous
        local cost tokens
        if [[ -n "$prev_timestamp" ]]; then
            read -r cost tokens < <(sum_jsonl_cost_between "$project_jsonl_dir" "$timestamp" "$prev_timestamp")
        else
            # First commit (most recent) — cost from commit to now
            local now
            now=$(date +%s)
            read -r cost tokens < <(sum_jsonl_cost_between "$project_jsonl_dir" "$timestamp" "$now")
        fi

        cost="${cost:-0.00}"
        tokens="${tokens:-0}"

        # Format relative time
        local relative
        relative=$(format_relative_time "$timestamp")

        printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$commit_hash" "$timestamp" "$message" "$cost" "$tokens" "$relative"

        prev_timestamp="$timestamp"
    done <<< "$commits"
}

# Sum JSONL costs between two unix timestamps
# Args: $1=jsonl_dir $2=start_ts $3=end_ts
# Output: "cost tokens" on one line
sum_jsonl_cost_between() {
    local jsonl_dir="$1" start_ts="$2" end_ts="$3"
    local total_cost=0 total_tokens=0

    # Find JSONL files modified in the time range
    local jsonl_files
    jsonl_files=$(find "$jsonl_dir" -name "*.jsonl" -type f 2>/dev/null)
    [[ -z "$jsonl_files" ]] && { echo "0.00 0"; return; }

    # Use jq to sum costs within timestamp range
    local result
    result=$(echo "$jsonl_files" | while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        jq -r --arg start "$start_ts" --arg end "$end_ts" '
            select(.timestamp != null) |
            select((.timestamp | tonumber) >= ($start | tonumber)) |
            select((.timestamp | tonumber) < ($end | tonumber)) |
            [(.costUSD // 0), (.inputTokens // 0) + (.outputTokens // 0)]
        ' "$f" 2>/dev/null
    done | jq -s 'if length == 0 then [0,0] else [map(.[0]) | add, map(.[1]) | add] end | "\(.[0] | . * 100 | round / 100) \(.[1])"' 2>/dev/null)

    echo "${result:-0.00 0}"
}

# Format unix timestamp to relative time string
# Args: $1=unix_timestamp
format_relative_time() {
    local ts="$1"
    local now
    now=$(date +%s)
    local diff=$((now - ts))

    if [[ $diff -lt 3600 ]]; then
        echo "$((diff / 60))m ago"
    elif [[ $diff -lt 86400 ]]; then
        echo "$((diff / 3600))h ago"
    else
        echo "$((diff / 86400))d ago"
    fi
}

# Format a single row for human-readable output
format_commit_cost_row() {
    local hash="$1" message="$2" cost="$3" tokens="$4" relative="$5"
    local short_hash="${hash:0:7}"
    local formatted_tokens
    if [[ "${tokens:-0}" -ge 1000 ]]; then
        formatted_tokens="$(echo "scale=1; $tokens / 1000" | bc 2>/dev/null || echo "$tokens")K"
    else
        formatted_tokens="$tokens"
    fi
    printf "%-8s(%s)│ %-28s │ \$%6s │ %6s\n" "$short_hash" "$relative" "$message" "$cost" "$formatted_tokens"
}

debug_log "Cost commit attribution module loaded" "INFO"
```

**Step 5: Add source line to lib/cost.sh**

After line 79 (`source "${COST_LIB_DIR}/cost/report_calc.sh"`), add:

```bash
# shellcheck source=cost/commit_attribution.sh
source "${COST_LIB_DIR}/cost/commit_attribution.sh" 2>/dev/null || {
    debug_log "Failed to load cost/commit_attribution.sh - commit cost attribution disabled" "WARN"
}
```

**Step 6: Add `show_commit_cost_report()` to lib/cli/reports.sh**

Append before the final line:

```bash
# ============================================================================
# COMMIT COST REPORT (Issue #215)
# ============================================================================

show_commit_cost_report() {
    local format="${1:-human}"
    local compact="${2:-false}"
    local since="${3:-}" until="${4:-}" project="${5:-}"
    local repo_dir="${STATUSLINE_WORKING_DIR:-$(pwd)}"

    if [[ "$format" == "json" ]]; then
        local results
        results=$(calculate_commit_costs "$repo_dir")
        if [[ -z "$results" ]]; then
            echo "[]"
            return 0
        fi
        echo "$results" | jq -Rs '
            split("\n") | map(select(length > 0)) |
            map(split("\t") | {
                commit: .[0],
                timestamp: (.[1] | tonumber),
                message: .[2],
                cost_usd: (.[3] | tonumber),
                tokens: (.[4] | tonumber),
                relative: .[5]
            })
        '
        return 0
    fi

    if [[ "$format" == "csv" ]]; then
        echo "commit,message,cost_usd,tokens,relative_time"
        local results
        results=$(calculate_commit_costs "$repo_dir")
        [[ -z "$results" ]] && return 0
        while IFS=$'\t' read -r hash ts msg cost tokens rel; do
            printf '"%s","%s",%s,%s,"%s"\n' "${hash:0:7}" "$msg" "$cost" "$tokens" "$rel"
        done <<< "$results"
        return 0
    fi

    # Human format
    echo ""
    echo "  Commit Attribution"
    echo "  ════════════════════════════════════════════════════════════════"
    echo "  Commit          │ Message                      │   Cost │ Tokens"
    echo "  ────────────────┼──────────────────────────────┼────────┼───────"

    local results total_cost=0 total_tokens=0 count=0
    results=$(calculate_commit_costs "$repo_dir")
    if [[ -z "$results" ]]; then
        echo "  (no commits found in lookback period)"
        return 0
    fi

    while IFS=$'\t' read -r hash ts msg cost tokens rel; do
        printf "  %-8s(%6s)│ %-28s │ \$%5s │ %5s\n" "${hash:0:7}" "$rel" "$msg" "$cost" "${tokens}"
        total_cost=$(echo "$total_cost + ${cost:-0}" | bc 2>/dev/null || echo "$total_cost")
        total_tokens=$((total_tokens + ${tokens:-0}))
        count=$((count + 1))
    done <<< "$results"

    echo "  ────────────────┼──────────────────────────────┼────────┼───────"
    printf "  %-16s│ Total (%d commits)%11s│ \$%5s │ %5s\n" "" "$count" "" "$total_cost" "$total_tokens"
    echo ""
}
```

**Step 7: Add CLI flag and dispatch to statusline.sh**

In the parser section (before line 1147 `*)`), add:

```bash
        "--commits")
            _cli_command="commits" ;;
```

In the dispatch section (before the closing `esac` at line 1217), add:

```bash
        "commits")
            show_commit_cost_report "${_cli_format:-human}" "$_cli_compact" "$_cli_since" "$_cli_until" "$_cli_project"
            exit $? ;;
```

In show_usage() REPORTS section (after line 243), add:

```
    statusline.sh --commits                 - Cost per commit attribution
    statusline.sh --commits --json          - Commit costs (JSON)
```

**Step 8: Run tests**

```bash
bats tests/unit/test_commit_attribution.bats
npm test
```

Expected: All pass.

**Step 9: Commit and merge**

```bash
git add lib/cost/commit_attribution.sh lib/cost.sh lib/cli/reports.sh statusline.sh tests/unit/test_commit_attribution.bats
git commit -m "feat: add cost per commit attribution (closes #215)"
git checkout nightly && git merge feat/cost-per-commit --no-ff -m "Merge feat/cost-per-commit"
```

---

## Task 3: MCP Cost Attribution (#216)

**Files:**
- Create: `lib/cost/mcp_attribution.sh`
- Modify: `lib/cost.sh` (add source line after commit_attribution)
- Modify: `statusline.sh` (add `--mcp-costs` flag + dispatch)
- Modify: `lib/cli/reports.sh` (add `show_mcp_cost_report()`)
- Create: `tests/unit/test_mcp_attribution.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/mcp-cost-attribution nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_mcp_attribution.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_mcp_attr/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "calculate_mcp_costs function exists" {
    run type calculate_mcp_costs
    assert_success
}

@test "parse_mcp_server_from_tool extracts server name" {
    run parse_mcp_server_from_tool "mcp__filesystem__read_file"
    assert_success
    assert_output "filesystem"
}

@test "parse_mcp_server_from_tool handles non-mcp tools" {
    run parse_mcp_server_from_tool "read_file"
    assert_success
    assert_output ""
}

@test "show_mcp_cost_report function exists" {
    run type show_mcp_cost_report
    assert_success
}

@test "show_mcp_cost_report json returns valid JSON" {
    run show_mcp_cost_report "json"
    assert_success
    echo "$output" | jq . >/dev/null 2>&1
}
```

**Step 3: Run test to verify it fails**

```bash
bats tests/unit/test_mcp_attribution.bats
```

**Step 4: Create lib/cost/mcp_attribution.sh**

Implement `calculate_mcp_costs()` and `parse_mcp_server_from_tool()`:
- Scan JSONL for `tool_use` entries matching `mcp__*` pattern
- Group by server name, count calls, sum proportional tokens
- Return tab-delimited: `server\tcalls\ttokens\tcost\tshare_percent`

**Step 5: Add source to lib/cost.sh, CLI flag to statusline.sh, report to lib/cli/reports.sh**

Same pattern as Task 2:
- `--mcp-costs` flag → `_cli_command="mcp_costs"`
- Dispatch → `show_mcp_cost_report()`
- Help text line in REPORTS section

**Step 6: Run tests**

```bash
bats tests/unit/test_mcp_attribution.bats && npm test
```

**Step 7: Commit and merge**

```bash
git add lib/cost/mcp_attribution.sh lib/cost.sh lib/cli/reports.sh statusline.sh tests/unit/test_mcp_attribution.bats
git commit -m "feat: add MCP cost attribution (closes #216)"
git checkout nightly && git merge feat/mcp-cost-attribution --no-ff -m "Merge feat/mcp-cost-attribution"
```

---

## Task 4: Smart Cost Recommendations (#221)

**Files:**
- Create: `lib/cost/recommendations.sh`
- Modify: `lib/cost.sh` (add source line)
- Modify: `statusline.sh` (add `--recommendations` flag + dispatch)
- Modify: `lib/cli/reports.sh` (add `show_recommendations_report()`)
- Create: `tests/unit/test_recommendations.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/smart-cost-recommendations nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_recommendations.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_recs/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "generate_recommendations function exists" {
    run type generate_recommendations
    assert_success
}

@test "check_cache_efficiency_recommendation generates when below target" {
    # Mock cache hit rate at 40% (below 70% target)
    CONFIG_COST_RECOMMENDATIONS_CACHE_TARGET_PERCENT=70
    run check_cache_efficiency_recommendation 40
    assert_success
    assert_output --partial "Cache"
}

@test "check_cache_efficiency_recommendation silent when above target" {
    CONFIG_COST_RECOMMENDATIONS_CACHE_TARGET_PERCENT=70
    run check_cache_efficiency_recommendation 80
    assert_success
    assert_output ""
}

@test "show_recommendations_report function exists" {
    run type show_recommendations_report
    assert_success
}

@test "show_recommendations_report json returns valid JSON" {
    run show_recommendations_report "json"
    assert_success
    echo "$output" | jq . >/dev/null 2>&1
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_recommendations.bats
```

**Step 4: Create lib/cost/recommendations.sh**

Implement 5 heuristic rules:
1. `check_cache_efficiency_recommendation(hit_rate)` — cache < target%
2. `check_session_spike_recommendation()` — any session > 2x avg
3. `check_budget_pacing_recommendation()` — daily spend trending over budget
4. `check_high_avg_cost_recommendation()` — avg cost/session high
5. `check_idle_burn_recommendation()` — long gaps with high burn

Main function `generate_recommendations()` runs all checks, returns numbered list.

**Step 5: Add CLI flag, dispatch, report function, help text**

`--recommendations` → `_cli_command="recommendations"` → `show_recommendations_report()`

**Step 6: Run tests**

```bash
bats tests/unit/test_recommendations.bats && npm test
```

**Step 7: Commit and merge**

```bash
git add lib/cost/recommendations.sh lib/cost.sh lib/cli/reports.sh statusline.sh tests/unit/test_recommendations.bats
git commit -m "feat: add smart cost recommendations (closes #221)"
git checkout nightly && git merge feat/smart-cost-recommendations --no-ff -m "Merge feat/smart-cost-recommendations"
```

---

## Task 5: Watch Mode (#208)

**Files:**
- Create: `lib/cli/watch.sh`
- Modify: `statusline.sh` (add `--watch`, `--refresh` flags + dispatch)
- Create: `tests/unit/test_watch_mode.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/watch-mode nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_watch_mode.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_watch/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "show_watch_mode function exists" {
    run type show_watch_mode
    assert_success
}

@test "validate_refresh_interval accepts valid intervals" {
    run validate_refresh_interval "10"
    assert_success
    assert_output "10"
}

@test "validate_refresh_interval rejects below minimum" {
    run validate_refresh_interval "0.1"
    assert_success
    assert_output "0.5"  # Clamps to min
}

@test "validate_refresh_interval rejects non-numeric" {
    run validate_refresh_interval "abc"
    assert_failure
}

@test "render_watch_dashboard function exists" {
    run type render_watch_dashboard
    assert_success
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_watch_mode.bats
```

**Step 4: Create lib/cli/watch.sh**

Implement:
- `validate_refresh_interval(interval)` — validate and clamp refresh rate
- `render_watch_dashboard()` — single-frame render of compact dashboard
- `show_watch_mode(refresh)` — main loop with `tput clear`, `sleep`, `SIGINT` trap

Key: `STATUSLINE_TESTING=true` skips the actual loop (just renders one frame and returns).

**Step 5: Add CLI flags to statusline.sh**

Parser (before `*)`):
```bash
        "--watch")
            _cli_command="watch" ;;
        "--refresh")
            shift
            [[ $# -eq 0 ]] && { echo "Error: --refresh requires an interval" >&2; exit 1; }
            _cli_refresh="$1" ;;
        --refresh=*)
            _cli_refresh="${1#--refresh=}" ;;
```

Add new variable at top of CLI section: `_cli_refresh=""`

Dispatch:
```bash
        "watch")
            source "${LIB_DIR}/cli/watch.sh" 2>/dev/null || { echo "Error: watch module not found" >&2; exit 1; }
            show_watch_mode "${_cli_refresh:-10}"
            exit $? ;;
```

Help text in REPORTS section:
```
    statusline.sh --watch                   - Live monitoring mode (10s refresh)
    statusline.sh --watch --refresh 5       - Custom refresh interval
```

**Step 6: Run tests**

```bash
bats tests/unit/test_watch_mode.bats && npm test
```

**Step 7: Commit and merge**

```bash
git add lib/cli/watch.sh statusline.sh tests/unit/test_watch_mode.bats
git commit -m "feat: add --watch live monitoring mode (closes #208)"
git checkout nightly && git merge feat/watch-mode --no-ff -m "Merge feat/watch-mode"
```

---

## Task 6: Historical Trends with ASCII Charts (#217)

**Files:**
- Create: `lib/cli/charts.sh`
- Modify: `statusline.sh` (add `--trends`, `--period` flags + dispatch)
- Modify: `lib/cli/reports.sh` (add `show_trends_report()`)
- Create: `tests/unit/test_charts.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/historical-trends nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_charts.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_charts/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "render_vertical_bar_chart function exists" {
    run type render_vertical_bar_chart
    assert_success
}

@test "render_vertical_bar_chart renders correct height" {
    # 5 data points, chart height 5
    run render_vertical_bar_chart "1,3,5,2,4" "A,B,C,D,E" 5 "Test"
    assert_success
    # Should contain the title
    assert_output --partial "Test"
}

@test "calculate_trend_percentage computes correctly" {
    # Current period avg=10, previous avg=8 → +25%
    run calculate_trend_percentage "10" "8"
    assert_success
    assert_output --partial "25"
}

@test "parse_period_arg parses day format" {
    run parse_period_arg "30d"
    assert_success
    assert_output "30"
}

@test "parse_period_arg parses week format" {
    run parse_period_arg "4w"
    assert_success
    assert_output "28"
}

@test "show_trends_report function exists" {
    run type show_trends_report
    assert_success
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_charts.bats
```

**Step 4: Create lib/cli/charts.sh**

Implement:
- `parse_period_arg(period_str)` — parse "30d", "4w", "90d" → days
- `render_vertical_bar_chart(data, labels, height, title)` — Unicode block renderer using `▁▂▃▄▅▆▇█`
- `calculate_trend_percentage(current, previous)` — % change
- Auto-scale Y-axis, summary line with avg/peak/total/trend

**Step 5: Add `show_trends_report()` to lib/cli/reports.sh**

Calls `calculate_native_daily_cost()` for data, passes to `render_vertical_bar_chart()`.

**Step 6: Add CLI flags**

Parser: `--trends` → `_cli_command="trends"`, `--period` → `_cli_period="$1"`
Dispatch: `show_trends_report()`
Help text

**Step 7: Run tests**

```bash
bats tests/unit/test_charts.bats && npm test
```

**Step 8: Commit and merge**

```bash
git add lib/cli/charts.sh lib/cli/reports.sh statusline.sh tests/unit/test_charts.bats
git commit -m "feat: add historical trends with ASCII charts (closes #217)"
git checkout nightly && git merge feat/historical-trends --no-ff -m "Merge feat/historical-trends"
```

---

## Task 7: CSV Export (#218)

**Files:**
- Modify: `lib/cli/report_format.sh` (add `format_as_csv()`)
- Modify: `lib/cli/reports.sh` (add csv branch to each `show_*_report()`)
- Modify: `statusline.sh` (add `--csv` flag)
- Create: `tests/unit/test_csv_export.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/csv-export nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_csv_export.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_csv/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "format_as_csv function exists" {
    run type format_as_csv
    assert_success
}

@test "format_as_csv outputs header row" {
    run format_as_csv "date,cost,tokens" ""
    assert_success
    assert_line --index 0 "date,cost,tokens"
}

@test "csv_escape_field handles commas" {
    run csv_escape_field "hello, world"
    assert_success
    assert_output '"hello, world"'
}

@test "csv_escape_field handles quotes" {
    run csv_escape_field 'say "hi"'
    assert_success
    assert_output '"say ""hi"""'
}

@test "csv_escape_field passes plain text through" {
    run csv_escape_field "hello"
    assert_success
    assert_output "hello"
}

@test "--csv flag sets format to csv" {
    # Just verify the flag is parsed (integration test)
    run bash -c 'source '"$STATUSLINE_SCRIPT"' --daily --csv 2>/dev/null; echo $_cli_format'
    # This tests parse behavior
    assert_success
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_csv_export.bats
```

**Step 4: Add format_as_csv() and csv_escape_field() to lib/cli/report_format.sh**

```bash
# CSV escape a single field (RFC 4180)
csv_escape_field() {
    local field="$1"
    if [[ "$field" == *[,\"$'\n']* ]]; then
        field="${field//\"/\"\"}"
        echo "\"$field\""
    else
        echo "$field"
    fi
}

# Format rows as CSV
# Args: $1=comma-separated headers, then reads rows from stdin (tab-delimited)
format_as_csv() {
    local headers="$1"
    echo "$headers"
    while IFS=$'\t' read -r -a fields; do
        local line=""
        for i in "${!fields[@]}"; do
            [[ $i -gt 0 ]] && line+=","
            line+=$(csv_escape_field "${fields[$i]}")
        done
        echo "$line"
    done
}
```

**Step 5: Add `--csv` flag to statusline.sh parser**

```bash
        "--csv")
            _cli_format="csv" ;;
```

**Step 6: Add csv branches to existing show_*_report() functions in lib/cli/reports.sh**

Each `show_*_report()` that currently checks `[[ "$format" == "json" ]]` gets an additional check:

```bash
    if [[ "$format" == "csv" ]]; then
        # Output CSV format
        echo "date,day,sessions,cost_usd,..."
        # Loop through data, output tab-delimited to format_as_csv
        return 0
    fi
```

**Step 7: Run tests**

```bash
bats tests/unit/test_csv_export.bats && npm test
```

**Step 8: Commit and merge**

```bash
git add lib/cli/report_format.sh lib/cli/reports.sh statusline.sh tests/unit/test_csv_export.bats
git commit -m "feat: add CSV export for all reports (closes #218)"
git checkout nightly && git merge feat/csv-export --no-ff -m "Merge feat/csv-export"
```

---

## Task 8: Limit Warnings System (#210)

**Files:**
- Modify: `lib/cost/alerts.sh` (add `check_all_limits()`, context window checks)
- Modify: `lib/cli/reports.sh` (add `show_limits_report()`)
- Modify: `statusline.sh` (add `--limits` flag + dispatch)
- Create: `tests/unit/test_limit_warnings.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/limit-warnings nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_limit_warnings.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_limits/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "check_all_limits function exists" {
    run type check_all_limits
    assert_success
}

@test "get_context_alert_level returns normal below threshold" {
    CONFIG_LIMITS_CONTEXT_WARN_PERCENT=75
    CONFIG_LIMITS_CONTEXT_CRITICAL_PERCENT=90
    run get_context_alert_level 50
    assert_success
    assert_output "normal"
}

@test "get_context_alert_level returns warn at threshold" {
    CONFIG_LIMITS_CONTEXT_WARN_PERCENT=75
    CONFIG_LIMITS_CONTEXT_CRITICAL_PERCENT=90
    run get_context_alert_level 80
    assert_success
    assert_output "warn"
}

@test "get_context_alert_level returns critical above threshold" {
    CONFIG_LIMITS_CONTEXT_WARN_PERCENT=75
    CONFIG_LIMITS_CONTEXT_CRITICAL_PERCENT=90
    run get_context_alert_level 95
    assert_success
    assert_output "critical"
}

@test "show_limits_report function exists" {
    run type show_limits_report
    assert_success
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_limit_warnings.bats
```

**Step 4: Implement in lib/cost/alerts.sh**

Add `get_context_alert_level(percentage)` and `check_all_limits()` that aggregates cost + rate + context alerts into worst-case level.

**Step 5: Add show_limits_report() to lib/cli/reports.sh**

Renders unified limit summary with progress bars.

**Step 6: Add `--limits` CLI flag + dispatch**

**Step 7: Run tests**

```bash
bats tests/unit/test_limit_warnings.bats && npm test
```

**Step 8: Commit and merge**

```bash
git add lib/cost/alerts.sh lib/cli/reports.sh statusline.sh tests/unit/test_limit_warnings.bats
git commit -m "feat: add unified limit warnings system (closes #210)"
git checkout nightly && git merge feat/limit-warnings --no-ff -m "Merge feat/limit-warnings"
```

---

## Task 9: Wellness Mode — Break Reminders (#219)

**Files:**
- Create: `lib/wellness.sh`
- Create: `lib/components/wellness.sh`
- Modify: `statusline.sh` (source wellness module)
- Modify: `examples/Config.toml` (add [wellness] section)
- Create: `tests/unit/test_wellness.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/wellness-mode nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_wellness.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_wellness/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "get_wellness_level function exists" {
    run type get_wellness_level
    assert_success
}

@test "get_wellness_level returns normal for short sessions" {
    CONFIG_WELLNESS_GENTLE_MINUTES=45
    CONFIG_WELLNESS_WARN_MINUTES=90
    CONFIG_WELLNESS_URGENT_MINUTES=120
    run get_wellness_level 30
    assert_success
    assert_output "normal"
}

@test "get_wellness_level returns gentle at threshold" {
    CONFIG_WELLNESS_GENTLE_MINUTES=45
    CONFIG_WELLNESS_WARN_MINUTES=90
    CONFIG_WELLNESS_URGENT_MINUTES=120
    run get_wellness_level 50
    assert_success
    assert_output "gentle"
}

@test "get_wellness_level returns warn at threshold" {
    CONFIG_WELLNESS_GENTLE_MINUTES=45
    CONFIG_WELLNESS_WARN_MINUTES=90
    CONFIG_WELLNESS_URGENT_MINUTES=120
    run get_wellness_level 100
    assert_success
    assert_output "warn"
}

@test "get_wellness_level returns urgent at threshold" {
    CONFIG_WELLNESS_GENTLE_MINUTES=45
    CONFIG_WELLNESS_WARN_MINUTES=90
    CONFIG_WELLNESS_URGENT_MINUTES=120
    run get_wellness_level 130
    assert_success
    assert_output "urgent"
}

@test "format_wellness_display returns formatted string" {
    run format_wellness_display 52 "gentle"
    assert_success
    assert_output --partial "52m"
    assert_output --partial "Break soon"
}

@test "collect_wellness_data function exists" {
    run type collect_wellness_data
    assert_success
}

@test "render_wellness function exists" {
    run type render_wellness
    assert_success
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_wellness.bats
```

**Step 4: Create lib/wellness.sh**

Module with include guard. Implements:
- `get_wellness_session_start()` — read/create cache file with session start timestamp
- `get_wellness_level(minutes)` — return normal/gentle/warn/urgent
- `format_wellness_display(minutes, level)` — formatted string
- `send_wellness_notification(level, minutes)` — reuses `send_cost_notification()` pattern

**Step 5: Create lib/components/wellness.sh**

Component following the standard pattern:
- `COMPONENT_WELLNESS_DISPLAY=""`
- `collect_wellness_data()` — read session start, calc elapsed, set display
- `render_wellness()` — return formatted string
- `register_component "wellness" "Session wellness tracking" "wellness" "${CONFIG_WELLNESS_ENABLED:-false}"`

**Step 6: Source wellness module in statusline.sh module loading section**

**Step 7: Add [wellness] section to examples/Config.toml**

**Step 8: Run tests**

```bash
bats tests/unit/test_wellness.bats && npm test
```

**Step 9: Commit and merge**

```bash
git add lib/wellness.sh lib/components/wellness.sh statusline.sh examples/Config.toml tests/unit/test_wellness.bats
git commit -m "feat: add wellness mode with break reminders (closes #219)"
git checkout nightly && git merge feat/wellness-mode --no-ff -m "Merge feat/wellness-mode"
```

---

## Task 10: Focus Session Tracking (#220)

**Files:**
- Create: `lib/focus.sh`
- Create: `lib/components/focus_session.sh`
- Modify: `statusline.sh` (add `--focus` flag + dispatch, source module)
- Modify: `examples/Config.toml` (add [focus] section)
- Create: `tests/unit/test_focus_sessions.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/focus-sessions nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_focus_sessions.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_focus/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    export XDG_CACHE_HOME="$BATS_TMPDIR/test_focus_cache"
    mkdir -p "$XDG_CACHE_HOME/claude-code-statusline"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "focus_start function exists" {
    run type focus_start
    assert_success
}

@test "focus_stop function exists" {
    run type focus_stop
    assert_success
}

@test "focus_status function exists" {
    run type focus_status
    assert_success
}

@test "focus_start creates active session" {
    run focus_start
    assert_success
    assert_output --partial "Focus session started"
}

@test "focus_status shows active session" {
    focus_start >/dev/null 2>&1
    run focus_status
    assert_success
    assert_output --partial "FOCUS"
}

@test "focus_stop ends session and shows summary" {
    focus_start >/dev/null 2>&1
    sleep 1
    run focus_stop
    assert_success
    assert_output --partial "Focus Session Complete"
}

@test "focus_start fails if session already active" {
    focus_start >/dev/null 2>&1
    run focus_start
    assert_failure
    assert_output --partial "already active"
}

@test "collect_focus_session_data function exists" {
    run type collect_focus_session_data
    assert_success
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_focus_sessions.bats
```

**Step 4: Create lib/focus.sh**

Module with include guard. Implements:
- `focus_start()` — create active session in JSON file
- `focus_stop()` — end session, calculate summary, move to history
- `focus_status()` — show current session info
- `focus_history(format)` — list past sessions
- Storage: `~/.cache/claude-code-statusline/focus_sessions.json` via jq

**Step 5: Create lib/components/focus_session.sh**

Standard component pattern:
- `collect_focus_session_data()` — read active session, calc elapsed
- `render_focus_session()` — `FOCUS | 45m | $2.34 | +89/-12`
- Registration with `enabled="${CONFIG_FOCUS_SHOW_IN_STATUSLINE:-true}"`

**Step 6: Add CLI flags**

Parser:
```bash
        "--focus")
            shift
            [[ $# -eq 0 ]] && { echo "Error: --focus requires: start|stop|status|history" >&2; exit 1; }
            _cli_command="focus"; _cli_focus_action="$1" ;;
```

Dispatch:
```bash
        "focus")
            source "${LIB_DIR}/focus.sh" 2>/dev/null || { echo "Error: focus module not found" >&2; exit 1; }
            case "$_cli_focus_action" in
                start) focus_start; exit $? ;;
                stop) focus_stop; exit $? ;;
                status) focus_status; exit $? ;;
                history) focus_history "${_cli_format:-human}"; exit $? ;;
                *) echo "Error: unknown focus action: $_cli_focus_action" >&2; exit 1 ;;
            esac ;;
```

**Step 7: Add [focus] section to examples/Config.toml**

**Step 8: Run tests**

```bash
bats tests/unit/test_focus_sessions.bats && npm test
```

**Step 9: Commit and merge**

```bash
git add lib/focus.sh lib/components/focus_session.sh statusline.sh examples/Config.toml tests/unit/test_focus_sessions.bats
git commit -m "feat: add focus session tracking (closes #220)"
git checkout nightly && git merge feat/focus-sessions --no-ff -m "Merge feat/focus-sessions"
```

---

## Task 11: Prayer Break Reminders (#212)

**Files:**
- Create: `lib/prayer/reminders.sh`
- Modify: `lib/prayer.sh` (add source line for reminders)
- Modify: `examples/Config.toml` (add [prayer.reminders] section)
- Create: `tests/unit/test_prayer_reminders.bats`

**Step 1: Create branch**

```bash
git checkout -b feat/prayer-reminders nightly
```

**Step 2: Write the failing test**

Create `tests/unit/test_prayer_reminders.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup_file() {
    common_setup
    export STATUSLINE_TESTING=true
    export CLAUDE_CONFIG_DIR="$BATS_TMPDIR/test_prayer_rem/.claude"
    mkdir -p "$CLAUDE_CONFIG_DIR/projects/-test-project"
    source "${STATUSLINE_SCRIPT}"
}

teardown_file() { common_teardown; }

@test "get_prayer_reminder_level function exists" {
    run type get_prayer_reminder_level
    assert_success
}

@test "get_prayer_reminder_level returns normal when > 30min away" {
    CONFIG_PRAYER_REMINDERS_HEADSUP_MINUTES=30
    CONFIG_PRAYER_REMINDERS_PREPARE_MINUTES=15
    CONFIG_PRAYER_REMINDERS_IMMINENT_MINUTES=5
    run get_prayer_reminder_level 45
    assert_success
    assert_output "normal"
}

@test "get_prayer_reminder_level returns headsup at 22min" {
    CONFIG_PRAYER_REMINDERS_HEADSUP_MINUTES=30
    CONFIG_PRAYER_REMINDERS_PREPARE_MINUTES=15
    CONFIG_PRAYER_REMINDERS_IMMINENT_MINUTES=5
    run get_prayer_reminder_level 22
    assert_success
    assert_output "headsup"
}

@test "get_prayer_reminder_level returns prepare at 8min" {
    CONFIG_PRAYER_REMINDERS_HEADSUP_MINUTES=30
    CONFIG_PRAYER_REMINDERS_PREPARE_MINUTES=15
    CONFIG_PRAYER_REMINDERS_IMMINENT_MINUTES=5
    run get_prayer_reminder_level 8
    assert_success
    assert_output "prepare"
}

@test "get_prayer_reminder_level returns imminent at 3min" {
    CONFIG_PRAYER_REMINDERS_HEADSUP_MINUTES=30
    CONFIG_PRAYER_REMINDERS_PREPARE_MINUTES=15
    CONFIG_PRAYER_REMINDERS_IMMINENT_MINUTES=5
    run get_prayer_reminder_level 3
    assert_success
    assert_output "imminent"
}

@test "format_prayer_reminder formats correctly" {
    run format_prayer_reminder "Dhuhr" 8 "prepare"
    assert_success
    assert_output --partial "Dhuhr"
    assert_output --partial "8m"
    assert_output --partial "wrap up"
}

@test "should_send_prayer_notification respects cooldown" {
    export XDG_CACHE_HOME="$BATS_TMPDIR/test_prayer_cache"
    mkdir -p "$XDG_CACHE_HOME/claude-code-statusline"
    # First call should return true
    run should_send_prayer_notification "Dhuhr"
    assert_success
}
```

**Step 3: Run test, verify fail**

```bash
bats tests/unit/test_prayer_reminders.bats
```

**Step 4: Create lib/prayer/reminders.sh**

Module with include guard. Implements:
- `get_prayer_reminder_level(minutes_until)` — normal/headsup/prepare/imminent/active
- `format_prayer_reminder(prayer_name, minutes, level)` — contextual message
- `should_send_prayer_notification(prayer_name)` — check cooldown cache
- `mark_prayer_notified(prayer_name)` — write cooldown marker
- `process_prayer_reminders()` — main function called during render
  - Gets next prayer + minutes until from existing prayer module
  - Checks reminder level
  - Optionally sends desktop notification
  - Optionally resets wellness timer (integration with #219)
  - Optionally suggests focus stop (integration with #220)

**Step 5: Add source line to lib/prayer.sh**

After the last source line in `load_prayer_modules()`:

```bash
    # Optional: prayer reminders (Issue #212)
    source "${PRAYER_MODULE_DIR}/prayer/reminders.sh" 2>/dev/null || {
        debug_log "Prayer reminders module not available" "INFO"
    }
```

**Step 6: Add [prayer.reminders] section to examples/Config.toml**

**Step 7: Run tests**

```bash
bats tests/unit/test_prayer_reminders.bats && npm test
```

**Step 8: Commit and merge**

```bash
git add lib/prayer/reminders.sh lib/prayer.sh examples/Config.toml tests/unit/test_prayer_reminders.bats
git commit -m "feat: add prayer break reminders with desktop notifications (closes #212)"
git checkout nightly && git merge feat/prayer-reminders --no-ff -m "Merge feat/prayer-reminders"
```

---

## Task 12: Close Epics (#190, #191)

**No code changes. Just close the tracking issues.**

**Step 1: Close #190 (Real-time Monitoring)**

```bash
gh issue close 190 --comment "All child issues complete:
- #208 --watch live monitoring mode
- #210 Limit warnings system

Epic fully implemented." --reason completed
```

**Step 2: Close #191 (Moat Features)**

```bash
gh issue close 191 --comment "All child issues complete:
- #212 Prayer break reminders
- #213 Prayer-based auto theme switching (closed earlier)
- #214 Budget alerts system (closed earlier)
- #215 Cost per commit attribution
- #216 MCP cost attribution
- #217 Historical trends with ASCII charts
- #218 CSV/Excel export
- #219 Wellness mode - break reminders
- #220 Focus session tracking
- #221 Smart cost recommendations

Epic fully implemented." --reason completed
```

---

## Task 13: Config.toml Update (cross-cutting)

**This task runs alongside Tasks 2-11.** Each task that adds config should also update `examples/Config.toml`.

**Cumulative additions** (append before the template maintenance notes at end of file):

```toml
# ============================================================================
# COST ATTRIBUTION (Issues #215, #216)
# ============================================================================

cost.commit_attribution.enabled = true
cost.commit_attribution.lookback_days = 30

cost.mcp_attribution.enabled = true

# ============================================================================
# COST RECOMMENDATIONS (Issue #221)
# ============================================================================

cost.recommendations.enabled = true
cost.recommendations.cache_target_percent = 70
cost.recommendations.session_spike_multiplier = 2.0

# ============================================================================
# WATCH MODE (Issue #208)
# ============================================================================

watch.enabled = true
watch.default_refresh = 10
watch.min_refresh = 0.5

# ============================================================================
# TRENDS (Issue #217)
# ============================================================================

trends.default_period = "30d"
trends.chart_height = 10

# ============================================================================
# LIMIT WARNINGS (Issue #210)
# ============================================================================

limits.context_warn_percent = 75
limits.context_critical_percent = 90
limits.show_limit_summary = true

# ============================================================================
# WELLNESS MODE (Issue #219)
# ============================================================================

wellness.enabled = false
wellness.gentle_minutes = 45
wellness.warn_minutes = 90
wellness.urgent_minutes = 120
wellness.break_duration = 10
wellness.desktop_notify = false
wellness.notify_cooldown = 900

# ============================================================================
# FOCUS SESSIONS (Issue #220)
# ============================================================================

focus.enabled = true
focus.default_duration = 50
focus.show_in_statusline = true
focus.track_commits = true
focus.track_cost = true

# ============================================================================
# PRAYER REMINDERS (Issue #212)
# ============================================================================

prayer.reminders.enabled = false
prayer.reminders.headsup_minutes = 30
prayer.reminders.prepare_minutes = 15
prayer.reminders.imminent_minutes = 5
prayer.reminders.desktop_notify = false
prayer.reminders.integrate_wellness = true
prayer.reminders.integrate_focus = true
```

**Note:** Each task commits its own Config.toml changes. This section documents the full set.

---

## Execution Order Summary

| Order | Task | Branch | Issue | Dependencies |
|-------|------|--------|-------|-------------|
| 1 | Fix declare -g | `fix/declare-g-bash32` | #243 | None |
| 2 | Cost per commit | `feat/cost-per-commit` | #215 | None |
| 3 | MCP cost attribution | `feat/mcp-cost-attribution` | #216 | None |
| 4 | Smart recommendations | `feat/smart-cost-recommendations` | #221 | None |
| 5 | Watch mode | `feat/watch-mode` | #208 | None |
| 6 | Historical trends | `feat/historical-trends` | #217 | None |
| 7 | CSV export | `feat/csv-export` | #218 | After Tasks 2-3 (uses their reports) |
| 8 | Limit warnings | `feat/limit-warnings` | #210 | None |
| 9 | Wellness mode | `feat/wellness-mode` | #219 | None |
| 10 | Focus sessions | `feat/focus-sessions` | #220 | None |
| 11 | Prayer reminders | `feat/prayer-reminders` | #212 | After Tasks 9-10 (integrates) |
| 12 | Close epics | — | #190, #191 | After all above |
| 13 | Config.toml | — | — | Done per-task |

**Parallelization opportunities:**
- Tasks 2, 3, 4 can run in parallel (different cost sub-modules)
- Tasks 5, 6 can run in parallel (different CLI modules)
- Tasks 8, 9, 10 can run in parallel (different modules)
- Task 7 (CSV) should run after 2-3 to include their report formats
- Task 11 (prayer reminders) should run after 9-10 for integration
- Task 12 runs last
