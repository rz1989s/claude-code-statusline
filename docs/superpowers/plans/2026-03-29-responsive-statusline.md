# Responsive Statusline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the statusline width-aware — detect terminal width, drop lower-priority components per line until the line fits, and apply ANSI-safe truncation as a safety net.

**Architecture:** New `lib/responsive.sh` module with 5 functions (detect width, measure width, get priority, filter components, truncate). One integration point in `build_component_line()` (`lib/components.sh:263-308`). Zero changes to existing component files.

**Tech Stack:** Bash 4+, BATS testing framework, sed for ANSI stripping, wc -m for character counting.

**Spec:** `docs/superpowers/specs/2026-03-29-responsive-statusline-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/responsive.sh` | CREATE | All responsive logic: width detection, measurement, priority table, filtering, truncation |
| `lib/components.sh` | MODIFY (lines 263-308) | Add `filter_line_components()` call inside `build_component_line()` |
| `statusline.sh` | MODIFY (line ~181) | Add `load_module "responsive"` before `display` module |
| `tests/unit/test_responsive.bats` | CREATE | Unit tests for all responsive.sh functions |
| `tests/integration/test_responsive_integration.bats` | CREATE | End-to-end width constraint tests |

---

## Task 1: Create `lib/responsive.sh` scaffold with include guard and width detection

**Files:**
- Create: `lib/responsive.sh`
- Test: `tests/unit/test_responsive.bats`

- [ ] **Step 1: Write failing tests for `detect_terminal_width()`**

Create `tests/unit/test_responsive.bats`:

```bash
#!/usr/bin/env bats
# ==============================================================================
# Test: Responsive statusline — width detection, measurement, filtering
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/responsive.sh" 2>/dev/null || true
    # Clear cached width between tests
    unset STATUSLINE_TERMINAL_WIDTH
}

teardown() {
    common_teardown
    unset STATUSLINE_TERMINAL_WIDTH
    unset ENV_CONFIG_TERMINAL_WIDTH
    unset COLUMNS
}

# ==============================================================================
# Width Detection
# ==============================================================================

@test "detect_terminal_width returns COLUMNS when set" {
    export COLUMNS=142
    run detect_terminal_width
    assert_success
    assert_output "142"
}

@test "detect_terminal_width ENV_CONFIG override takes priority over COLUMNS" {
    export COLUMNS=142
    export ENV_CONFIG_TERMINAL_WIDTH=90
    run detect_terminal_width
    assert_success
    assert_output "90"
}

@test "detect_terminal_width falls back to 120 when nothing set" {
    unset COLUMNS
    unset ENV_CONFIG_TERMINAL_WIDTH
    # Force tput to fail by unsetting TERM
    export TERM=""
    run detect_terminal_width
    assert_success
    # Should be 120 (fallback) or whatever tput returns
    [[ "$output" -ge 1 ]]
}

@test "detect_terminal_width rejects invalid negative value" {
    export COLUMNS="-1"
    unset ENV_CONFIG_TERMINAL_WIDTH
    run detect_terminal_width
    assert_success
    assert_output "120"
}

@test "detect_terminal_width caches result across calls" {
    export COLUMNS=100
    detect_terminal_width > /dev/null
    # Change COLUMNS — cached value should persist
    export COLUMNS=200
    run detect_terminal_width
    assert_success
    assert_output "100"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/unit/test_responsive.bats`
Expected: FAIL — `lib/responsive.sh` does not exist, source fails, functions not found.

- [ ] **Step 3: Create `lib/responsive.sh` with include guard and `detect_terminal_width()`**

Create `lib/responsive.sh`:

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - Responsive Module
# ============================================================================
#
# Width-aware component filtering. Detects terminal width, drops lower-priority
# components per line until the line fits, and applies ANSI-safe truncation
# as a safety net.
#
# Dependencies: core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_RESPONSIVE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_RESPONSIVE_LOADED=true

# ============================================================================
# WIDTH DETECTION
# ============================================================================

# Detect terminal width with caching.
# Priority: ENV_CONFIG_TERMINAL_WIDTH > $COLUMNS > tput cols > fallback 120
detect_terminal_width() {
    # Return cached value if already detected this invocation
    if [[ -n "${STATUSLINE_TERMINAL_WIDTH:-}" ]]; then
        echo "$STATUSLINE_TERMINAL_WIDTH"
        return 0
    fi

    local width=""

    # 1. User override (highest priority)
    if [[ -n "${ENV_CONFIG_TERMINAL_WIDTH:-}" ]]; then
        width="$ENV_CONFIG_TERMINAL_WIDTH"
    fi

    # 2. $COLUMNS (works when user exports it in shell profile)
    if [[ -z "$width" && -n "${COLUMNS:-}" ]]; then
        width="$COLUMNS"
    fi

    # 3. tput cols (mirrors $COLUMNS when set, else returns 80 default)
    if [[ -z "$width" ]]; then
        width=$(tput cols 2>/dev/null) || width=""
    fi

    # 4. Fallback: 120 (generous — don't penalize wide-terminal majority)
    if [[ -z "$width" ]] || ! [[ "$width" =~ ^[0-9]+$ ]] || [[ "$width" -lt 1 ]]; then
        width=120
    fi

    # Cache for this invocation
    export STATUSLINE_TERMINAL_WIDTH="$width"
    debug_log "[responsive] terminal width: $width (source: $(
        if [[ -n "${ENV_CONFIG_TERMINAL_WIDTH:-}" ]]; then echo "ENV_CONFIG_TERMINAL_WIDTH"
        elif [[ -n "${COLUMNS:-}" ]]; then echo "COLUMNS"
        else echo "fallback"
        fi
    ))" "INFO"

    echo "$width"
    return 0
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/unit/test_responsive.bats`
Expected: All 5 width detection tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/responsive.sh tests/unit/test_responsive.bats
git commit -m "feat: add responsive module with width detection (closes #289, step 1/6)"
```

---

## Task 2: Add `measure_visible_width()` function

**Files:**
- Modify: `lib/responsive.sh`
- Modify: `tests/unit/test_responsive.bats`

- [ ] **Step 1: Write failing tests for `measure_visible_width()`**

Append to `tests/unit/test_responsive.bats`:

```bash
# ==============================================================================
# Width Measurement
# ==============================================================================

@test "measure_visible_width counts plain text correctly" {
    run measure_visible_width "hello"
    assert_success
    assert_output "5"
}

@test "measure_visible_width strips ANSI color codes" {
    run measure_visible_width $'\e[32mhello\e[0m'
    assert_success
    assert_output "5"
}

@test "measure_visible_width strips nested ANSI codes" {
    run measure_visible_width $'\e[1m\e[32mbold green\e[0m'
    assert_success
    assert_output "10"
}

@test "measure_visible_width counts emoji as double-width" {
    run measure_visible_width "🧠 Opus"
    assert_success
    # 🧠 = 2 cols, space = 1, O-p-u-s = 4 → total 7
    assert_output "7"
}

@test "measure_visible_width returns 0 for empty string" {
    run measure_visible_width ""
    assert_success
    assert_output "0"
}

@test "measure_visible_width handles separator pipe character" {
    run measure_visible_width " │ "
    assert_success
    assert_output "3"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/unit/test_responsive.bats`
Expected: 6 new tests FAIL — `measure_visible_width` not defined.

- [ ] **Step 3: Implement `measure_visible_width()` in `lib/responsive.sh`**

Append after `detect_terminal_width()`:

```bash
# ============================================================================
# WIDTH MEASUREMENT
# ============================================================================

# Measure the visible width of a string (strips ANSI, accounts for emoji).
# Returns the number of terminal columns the string occupies.
measure_visible_width() {
    local text="$1"

    if [[ -z "$text" ]]; then
        echo "0"
        return 0
    fi

    # 1. Strip ANSI escape sequences (colors, bold, dim, reset)
    local stripped
    stripped=$(printf '%s' "$text" | sed $'s/\x1b\[[0-9;]*m//g')

    # 2. Count characters (not bytes — handles Unicode correctly)
    local char_count
    char_count=$(printf '%s' "$stripped" | wc -m | tr -d ' ')

    # 3. Emoji correction: common double-width emoji add 1 extra column each
    #    Ranges: Emoticons (U+1F600-1F64F), Symbols (U+1F300-1F5FF),
    #    Transport (U+1F680-1F6FF), Misc (U+1F900-1F9FF), Dingbats (U+2700-27BF)
    local emoji_count=0
    if command -v perl &>/dev/null; then
        emoji_count=$(printf '%s' "$stripped" | perl -CS -ne 'print while /[\x{1F300}-\x{1F9FF}\x{2600}-\x{27BF}]/g' | wc -m | tr -d ' ')
    fi

    echo $(( char_count + emoji_count ))
    return 0
}
```

Note: Uses `perl` for reliable Unicode emoji matching (available on macOS and all Linux distros). Falls back to 0 emoji correction if perl is missing — the safety-net truncation handles any overflow.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/unit/test_responsive.bats`
Expected: All 11 tests PASS (5 detection + 6 measurement).

- [ ] **Step 5: Commit**

```bash
git add lib/responsive.sh tests/unit/test_responsive.bats
git commit -m "feat: add visible width measurement with ANSI/emoji support (#289, step 2/6)"
```

---

## Task 3: Add priority table and `get_component_priority()`

**Files:**
- Modify: `lib/responsive.sh`
- Modify: `tests/unit/test_responsive.bats`

- [ ] **Step 1: Write failing tests for `get_component_priority()`**

Append to `tests/unit/test_responsive.bats`:

```bash
# ==============================================================================
# Component Priority
# ==============================================================================

@test "get_component_priority returns 1 for essential components" {
    run get_component_priority "repo_info"
    assert_success
    assert_output "1"
}

@test "get_component_priority returns 4 for low-priority components" {
    run get_component_priority "time_display"
    assert_success
    assert_output "4"
}

@test "get_component_priority returns 3 for unregistered components" {
    run get_component_priority "some_unknown_component"
    assert_success
    assert_output "3"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/unit/test_responsive.bats`
Expected: 3 new tests FAIL — `get_component_priority` not defined.

- [ ] **Step 3: Implement priority table and `get_component_priority()` in `lib/responsive.sh`**

Append after `measure_visible_width()`:

```bash
# ============================================================================
# COMPONENT PRIORITY
# ============================================================================

# Priority levels:
#   1 = Essential (never dropped, only truncated as last resort)
#   2 = Important (dropped under moderate pressure)
#   3 = Nice-to-have (dropped early) — also the default for unregistered components
#   4 = First to go (sacrificed first when space is tight)

declare -gA RESPONSIVE_COMPONENT_PRIORITY=(
    # Line 1: Repository identity
    [repo_info]=1

    # Line 2: Model & git metrics
    [model_info]=1
    [bedrock_model]=2
    [commits]=2
    [submodules]=3
    [version_info]=3
    [time_display]=4

    # Line 3: Cost analytics
    [cost_repo]=1
    [cost_monthly]=2
    [cost_live]=2
    [cost_weekly]=3
    [cost_daily]=4

    # Line 4: Block metrics
    [context_window]=1
    [burn_rate]=2
    [cache_efficiency]=3
    [block_projection]=3
    [code_productivity]=4

    # Line 5: Usage limits
    [usage_limits]=1
    [usage_reset]=2

    # Line 6: Calendar & wellness
    [hijri_calendar]=2
    [wellness]=3

    # Line 7: Prayer
    [prayer_times]=1
    [prayer_times_only]=1
    [prayer_icon]=2

    # Line 8: MCP
    [mcp_status]=1
    [mcp_native]=2
    [mcp_servers]=2
    [mcp_plugins]=3

    # Other components (alternate configurations)
    [context_alert]=1
    [vim_mode]=2
    [agent_display]=2
    [session_info]=2
    [session_mode]=3
    [total_tokens]=3
    [token_usage]=3
    [github]=3
    [location_display]=3
    [version_display]=3
)

# Get the priority for a component. Returns 3 (nice-to-have) for unknown components.
get_component_priority() {
    local component_name="$1"
    echo "${RESPONSIVE_COMPONENT_PRIORITY[$component_name]:-3}"
    return 0
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/unit/test_responsive.bats`
Expected: All 14 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/responsive.sh tests/unit/test_responsive.bats
git commit -m "feat: add component priority table for responsive filtering (#289, step 3/6)"
```

---

## Task 4: Add `filter_line_components()` and `truncate_line_ansi_safe()`

**Files:**
- Modify: `lib/responsive.sh`
- Modify: `tests/unit/test_responsive.bats`

- [ ] **Step 1: Write failing tests for `filter_line_components()`**

Append to `tests/unit/test_responsive.bats`:

```bash
# ==============================================================================
# Component Filtering
# ==============================================================================

@test "filter_line_components passes all through when width sufficient" {
    # Simulate: 3 short components, wide terminal
    local names=("aaa" "bbb" "ccc")
    local outputs=("AAAA" "BBBB" "CCCC")
    run filter_line_components 120 " │ " names outputs
    assert_success
    # All 3 survive
    assert_output "aaa,bbb,ccc"
}

@test "filter_line_components drops lowest priority first" {
    # time_display (pri 4) should be dropped before model_info (pri 1)
    local names=("model_info" "time_display")
    # Each 40 chars wide — total with separator = 83 > budget 50
    local outputs=("$(printf '%0.s=' {1..40})" "$(printf '%0.s=' {1..40})")
    run filter_line_components 50 " │ " names outputs
    assert_success
    assert_output "model_info"
}

@test "filter_line_components tie-breaks by dropping rightmost" {
    # Two priority-3 components — rightmost should be dropped
    local names=("submodules" "version_info")
    local outputs=("$(printf '%0.s=' {1..40})" "$(printf '%0.s=' {1..40})")
    run filter_line_components 50 " │ " names outputs
    assert_success
    assert_output "submodules"
}

@test "filter_line_components never drops last component" {
    # Single wide component exceeding budget — should survive
    local names=("repo_info")
    local outputs=("$(printf '%0.s=' {1..200})")
    run filter_line_components 50 " │ " names outputs
    assert_success
    assert_output "repo_info"
}

@test "filter_line_components accounts for separator width" {
    # 3 components: each 25 chars. Separators: 2 × 3 = 6. Total = 81.
    # Budget 80 — should drop one. Budget 81 — should keep all.
    local names=("cost_repo" "cost_monthly" "cost_live")
    local outputs=("$(printf '%0.s=' {1..25})" "$(printf '%0.s=' {1..25})" "$(printf '%0.s=' {1..25})")
    run filter_line_components 80 " │ " names outputs
    assert_success
    # cost_live and cost_monthly are both priority 2 — rightmost (cost_live) dropped
    assert_output "cost_repo,cost_monthly"
}

@test "filter_line_components handles empty component list" {
    local names=()
    local outputs=()
    run filter_line_components 120 " │ " names outputs
    assert_success
    assert_output ""
}

@test "filter_line_components skips empty rendered outputs" {
    local names=("model_info" "bedrock_model" "commits")
    local outputs=("ModelOutput" "" "Commits:3")
    run filter_line_components 120 " │ " names outputs
    assert_success
    # bedrock_model has empty output — should be excluded from width calc
    assert_output "model_info,commits"
}
```

- [ ] **Step 2: Write failing tests for `truncate_line_ansi_safe()`**

Append to `tests/unit/test_responsive.bats`:

```bash
# ==============================================================================
# ANSI-Safe Truncation
# ==============================================================================

@test "truncate_line_ansi_safe no-op when within budget" {
    run truncate_line_ansi_safe "short" 80
    assert_success
    assert_output "short"
}

@test "truncate_line_ansi_safe truncates plain text with ellipsis" {
    run truncate_line_ansi_safe "hello world" 8
    assert_success
    assert_output "hello w…"
}

@test "truncate_line_ansi_safe preserves ANSI and adds reset" {
    local input=$'\e[32mhello world\e[0m'
    run truncate_line_ansi_safe "$input" 8
    assert_success
    # Should keep color, truncate visible text, close with reset
    [[ "$output" == $'\e[32mhello w\e[0m…' ]] || [[ "$output" == *"hello w"*"…" ]]
}

@test "truncate_line_ansi_safe handles width of 1" {
    run truncate_line_ansi_safe "hello" 1
    assert_success
    assert_output "…"
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bats tests/unit/test_responsive.bats`
Expected: 11 new tests FAIL — functions not defined.

- [ ] **Step 4: Implement `filter_line_components()` in `lib/responsive.sh`**

Append after `get_component_priority()`:

```bash
# ============================================================================
# COMPONENT FILTERING
# ============================================================================

# Filter components for a line to fit within width budget.
# Drops lowest-priority components (rightmost on tie) until the line fits.
# Never drops the last component — truncation handles overflow.
#
# Args:
#   $1 - width_budget (integer)
#   $2 - separator string (e.g., " │ ")
#   $3 - nameref to array of component names
#   $4 - nameref to array of rendered outputs (parallel to names)
#
# Output: comma-separated surviving component names
filter_line_components() {
    local width_budget="$1"
    local separator="$2"
    local -n _names="$3"
    local -n _outputs="$4"

    local sep_width
    sep_width=$(measure_visible_width "$separator")

    # Build parallel arrays of active components (skip empty outputs)
    local active_names=()
    local active_widths=()
    local i
    for i in "${!_names[@]}"; do
        local w
        w=$(measure_visible_width "${_outputs[$i]}")
        if [[ "$w" -gt 0 ]]; then
            active_names+=("${_names[$i]}")
            active_widths+=("$w")
        fi
    done

    if [[ ${#active_names[@]} -eq 0 ]]; then
        echo ""
        return 0
    fi

    # Calculate total visible width: sum(widths) + (N-1) * sep_width
    _calculate_total_width() {
        local total=0
        local count=${#active_widths[@]}
        for w in "${active_widths[@]}"; do
            total=$((total + w))
        done
        if [[ $count -gt 1 ]]; then
            total=$((total + (count - 1) * sep_width))
        fi
        echo "$total"
    }

    local total
    total=$(_calculate_total_width)

    # Drop loop: remove lowest-priority (rightmost on tie) until fits
    while [[ "$total" -gt "$width_budget" ]] && [[ ${#active_names[@]} -gt 1 ]]; do
        # Find index of lowest-priority component (highest number, rightmost on tie)
        local drop_idx=0
        local drop_pri
        drop_pri=$(get_component_priority "${active_names[0]}")

        for i in "${!active_names[@]}"; do
            local pri
            pri=$(get_component_priority "${active_names[$i]}")
            # Higher number = lower priority. On tie (>=), prefer rightmost (later index)
            if [[ "$pri" -ge "$drop_pri" ]]; then
                drop_idx="$i"
                drop_pri="$pri"
            fi
        done

        debug_log "[responsive] dropped ${active_names[$drop_idx]} (pri:$drop_pri)" "INFO"

        # Remove the component at drop_idx
        unset 'active_names[drop_idx]'
        unset 'active_widths[drop_idx]'
        # Re-index arrays (bash arrays get sparse after unset)
        active_names=("${active_names[@]}")
        active_widths=("${active_widths[@]}")

        total=$(_calculate_total_width)
    done

    # Return surviving names as comma-separated string
    local result=""
    for name in "${active_names[@]}"; do
        if [[ -n "$result" ]]; then
            result="${result},${name}"
        else
            result="$name"
        fi
    done

    echo "$result"
    return 0
}
```

- [ ] **Step 5: Implement `truncate_line_ansi_safe()` in `lib/responsive.sh`**

Append after `filter_line_components()`:

```bash
# ============================================================================
# ANSI-SAFE TRUNCATION (Safety Net)
# ============================================================================

# Truncate a line to max_width visible columns, preserving ANSI sequences.
# Appends "…" and closes any open ANSI sequences with reset.
# Only fires when a single component exceeds terminal width (rare edge case).
truncate_line_ansi_safe() {
    local line="$1"
    local max_width="$2"

    if [[ -z "$line" ]] || [[ "$max_width" -lt 1 ]]; then
        echo ""
        return 0
    fi

    # Fast path: if visible width fits, return as-is
    local visible_width
    visible_width=$(measure_visible_width "$line")
    if [[ "$visible_width" -le "$max_width" ]]; then
        echo "$line"
        return 0
    fi

    debug_log "[responsive] truncating line at col $max_width (safety net)" "INFO"

    # Character-by-character walk: track visible column, preserve ANSI sequences
    local result=""
    local col=0
    local in_escape=false
    local target=$((max_width - 1))  # Reserve 1 column for "…"
    local i char

    for (( i=0; i<${#line}; i++ )); do
        char="${line:$i:1}"

        if [[ "$in_escape" == true ]]; then
            result+="$char"
            # End of ANSI sequence: letter terminates it
            if [[ "$char" =~ [a-zA-Z] ]]; then
                in_escape=false
            fi
            continue
        fi

        # Start of ANSI escape sequence
        if [[ "$char" == $'\e' ]] && [[ "${line:$((i+1)):1}" == "[" ]]; then
            in_escape=true
            result+="$char"
            continue
        fi

        # Visible character — check if we've hit the budget
        if [[ "$col" -ge "$target" ]]; then
            break
        fi

        result+="$char"
        col=$((col + 1))
    done

    # Close any open ANSI sequences and append ellipsis
    printf '%s\e[0m…' "$result"
    return 0
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bats tests/unit/test_responsive.bats`
Expected: All 25 tests PASS (5 detection + 6 measurement + 3 priority + 7 filtering + 4 truncation).

- [ ] **Step 7: Commit**

```bash
git add lib/responsive.sh tests/unit/test_responsive.bats
git commit -m "feat: add component filtering and ANSI-safe truncation (#289, step 4/6)"
```

---

## Task 5: Integrate responsive module into `build_component_line()`

**Files:**
- Modify: `statusline.sh` (line ~181)
- Modify: `lib/components.sh` (lines 263-308)
- Create: `tests/integration/test_responsive_integration.bats`

- [ ] **Step 1: Write failing integration tests**

Create `tests/integration/test_responsive_integration.bats`:

```bash
#!/usr/bin/env bats
# ==============================================================================
# Integration: Responsive statusline — end-to-end width constraint tests
# ==============================================================================

setup() {
    export STATUSLINE_DIR="$BATS_TEST_DIRNAME/../.."
    cd "$STATUSLINE_DIR"
    export STATUSLINE_SCRIPT="$STATUSLINE_DIR/statusline.sh"
    export STATUSLINE_TESTING="true"

    export TEST_TMP_DIR="/tmp/responsive_integration_$$"
    mkdir -p "$TEST_TMP_DIR/projects/test/sessions"
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR"
    export XDG_CACHE_HOME="$TEST_TMP_DIR/cache"
    mkdir -p "$XDG_CACHE_HOME"
}

teardown() {
    rm -rf "$TEST_TMP_DIR"
    unset STATUSLINE_TERMINAL_WIDTH
    unset ENV_CONFIG_TERMINAL_WIDTH
    unset COLUMNS
}

_build_test_json() {
    cat <<'ENDJSON'
{"version":"2.1.86","workspace":{"current_dir":"/tmp/test-repo"},"model":{"id":"claude-opus-4-6-20250415","display_name":"Claude Opus 4.6"},"context_window":{"used_percentage":12,"remaining_percentage":88,"context_window_size":1000000,"current_usage":{"cache_read_input_tokens":5000,"input_tokens":10000},"total_input_tokens":45000,"total_output_tokens":12000},"cost":{"total_cost_usd":0.45,"total_lines_added":120,"total_lines_removed":30},"session_id":"test-responsive","mcp":{"servers":[]}}
ENDJSON
}

# Helper: get visible width of a line (strip ANSI, count chars)
_visible_width() {
    printf '%s' "$1" | sed $'s/\x1b\[[0-9;]*m//g' | wc -m | tr -d ' '
}

@test "wide terminal (120 cols) renders all components" {
    export COLUMNS=120
    local output
    output=$(_build_test_json | /opt/homebrew/bin/bash "$STATUSLINE_SCRIPT" < /dev/null 2>/dev/null)
    [[ -n "$output" ]]
    # At least 2 lines of output
    local line_count
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    [[ "$line_count" -ge 2 ]]
}

@test "narrow terminal (60 cols) — no line exceeds width" {
    export COLUMNS=60
    local output
    output=$(_build_test_json | /opt/homebrew/bin/bash "$STATUSLINE_SCRIPT" < /dev/null 2>/dev/null)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local w
        w=$(_visible_width "$line")
        # Allow ±2 columns tolerance for emoji measurement
        [[ "$w" -le 62 ]]
    done <<< "$output"
}

@test "very narrow terminal (40 cols) — output exists and fits" {
    export COLUMNS=40
    local output
    output=$(_build_test_json | /opt/homebrew/bin/bash "$STATUSLINE_SCRIPT" < /dev/null 2>/dev/null)
    [[ -n "$output" ]]
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local w
        w=$(_visible_width "$line")
        # Allow ±2 columns tolerance
        [[ "$w" -le 42 ]]
    done <<< "$output"
}

@test "ENV_CONFIG_TERMINAL_WIDTH overrides COLUMNS" {
    export COLUMNS=200
    export ENV_CONFIG_TERMINAL_WIDTH=50
    local output
    output=$(_build_test_json | /opt/homebrew/bin/bash "$STATUSLINE_SCRIPT" < /dev/null 2>/dev/null)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local w
        w=$(_visible_width "$line")
        [[ "$w" -le 52 ]]
    done <<< "$output"
}
```

- [ ] **Step 2: Run integration tests to verify they fail**

Run: `bats tests/integration/test_responsive_integration.bats`
Expected: Tests may partially pass (120-col test passes since no filtering happens), but narrow tests fail because responsive module isn't loaded/integrated yet.

- [ ] **Step 3: Add `load_module "responsive"` to `statusline.sh`**

In `statusline.sh`, add after the `plugins` module load (line 180) and before the `display` module load (line 183):

```bash
# Load responsive module (width-aware component filtering)
load_module "responsive" || {
    handle_warning "Responsive module failed to load - width filtering disabled." "main"
}
```

This places it after `components` and `plugins` (which register components) and before `display` (which renders them).

- [ ] **Step 4: Modify `build_component_line()` in `lib/components.sh`**

Replace the function at lines 263-308 with responsive-aware version. The key change: after rendering all components, call `filter_line_components()` to drop those that don't fit, then rebuild the line from survivors.

Replace `lib/components.sh` lines 263-308:

```bash
# Build a statusline from configured components for a specific line
build_component_line() {
    local line_number="$1"
    local components_config="$2"
    local separator="${3:- │ }"

    if [[ -z "$components_config" ]]; then
        debug_log "No components configured for line $line_number" "INFO"
        return 0
    fi

    # Parse components list (comma-separated)
    local component_names=()
    local component_outputs=()
    IFS=',' read -ra component_list <<< "$components_config"

    for component_name in "${component_list[@]}"; do
        # Trim whitespace
        component_name=$(echo "$component_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$component_name" ]] && continue

        # Render component
        local component_output
        component_output=$(render_component "$component_name")
        if [[ $? -eq 0 && -n "$component_output" ]]; then
            component_names+=("$component_name")
            component_outputs+=("$component_output")
        fi
    done

    if [[ ${#component_names[@]} -eq 0 ]]; then
        debug_log "No components rendered for line $line_number" "INFO"
        return 1
    fi

    # Responsive filtering: drop components that don't fit terminal width
    local surviving_csv
    if type filter_line_components &>/dev/null; then
        local width_budget
        width_budget=$(detect_terminal_width)
        surviving_csv=$(filter_line_components "$width_budget" "$separator" component_names component_outputs)
    else
        # Fallback if responsive module not loaded
        surviving_csv=$(IFS=','; echo "${component_names[*]}")
    fi

    # Rebuild line from surviving components
    local line_output=""
    local rendered_count=0
    IFS=',' read -ra survivors <<< "$surviving_csv"

    for survivor in "${survivors[@]}"; do
        # Find the rendered output for this component
        local idx
        for idx in "${!component_names[@]}"; do
            if [[ "${component_names[$idx]}" == "$survivor" ]]; then
                if [[ -n "$line_output" ]]; then
                    line_output="${line_output}${separator}${component_outputs[$idx]}"
                else
                    line_output="${component_outputs[$idx]}"
                fi
                rendered_count=$((rendered_count + 1))
                break
            fi
        done
    done

    # Safety-net truncation: hard-cut if line still exceeds width
    if type truncate_line_ansi_safe &>/dev/null && [[ -n "$line_output" ]]; then
        local width_budget
        width_budget=$(detect_terminal_width)
        line_output=$(truncate_line_ansi_safe "$line_output" "$width_budget")
    fi

    if [[ $rendered_count -gt 0 ]]; then
        echo "$line_output"
        return 0
    else
        debug_log "No components rendered for line $line_number" "INFO"
        return 1
    fi
}
```

- [ ] **Step 5: Run all existing tests to verify no regressions**

Run: `bats tests/unit/test_responsive.bats && bats tests/integration/test_responsive_integration.bats`
Expected: All unit tests and integration tests PASS.

- [ ] **Step 6: Run full test suite to check for regressions**

Run: `npm test`
Expected: All ~940+ existing tests still pass. The fallback guard (`type filter_line_components &>/dev/null`) ensures tests that don't load the responsive module still work.

- [ ] **Step 7: Commit**

```bash
git add statusline.sh lib/components.sh tests/integration/test_responsive_integration.bats
git commit -m "feat: integrate responsive filtering into build_component_line (#289, step 5/6)"
```

---

## Task 6: Update documentation and clean up

**Files:**
- Modify: `CLAUDE.md`
- Modify: `examples/Config.toml`

- [ ] **Step 1: Update CLAUDE.md architecture section**

In `CLAUDE.md`, update the **Core Modules** count from 15 to 16 and add `responsive` to the module list:

Find the line:
```
**Core Modules** (15): core → security → json_fields → config → themes → cache → git → mcp → cost → prayer → wellness → focus → components → display
```

Replace with:
```
**Core Modules** (16): core → security → json_fields → config → themes → cache → git → mcp → cost → prayer → wellness → focus → components → responsive → display
```

- [ ] **Step 2: Add responsive section to CLAUDE.md**

Add after the **Cache System** section in CLAUDE.md:

```markdown
## Responsive Width System

**Always-on. Zero config.** Detects terminal width, drops lower-priority components per line, truncates as safety net.

**Width Detection**: `ENV_CONFIG_TERMINAL_WIDTH` → `$COLUMNS` → `tput cols` → fallback 120. For accurate auto-detection, add `export COLUMNS` to shell profile.

**Component Priority**: 1 (essential) → 4 (first to go). Unregistered components default to 3. Priority table in `lib/responsive.sh`.

**Override**: `ENV_CONFIG_TERMINAL_WIDTH=80 ./statusline.sh`
```

- [ ] **Step 3: Add commented-out responsive section to `examples/Config.toml`**

Find an appropriate location (after the `[cache]` section) and add:

```toml
# ==============================================================================
# Responsive Width (always-on, zero config required)
# ==============================================================================
# The statusline automatically adapts to terminal width by dropping
# lower-priority components. Override detected width if needed:
#
# [responsive]
# fallback_width = 120    # Default when auto-detection fails
```

- [ ] **Step 4: Clean up test script**

Remove the temporary test script created during brainstorming:

```bash
rm scripts/test-width-detection.sh
```

- [ ] **Step 5: Run full test suite one final time**

Run: `npm test`
Expected: All tests pass, including the new responsive tests.

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md examples/Config.toml
git rm scripts/test-width-detection.sh
git commit -m "docs: update architecture and config for responsive statusline (#289, step 6/6)"
```
