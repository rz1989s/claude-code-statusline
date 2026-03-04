# v2.1.66 Compatibility Audit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Full v2.1.66 compatibility — JSON abstraction layer, 5 new components, OAuth hardening, path migration, updated docs.

**Architecture:** New `lib/json_fields.sh` module provides `get_json_field()` with path migration (tries canonical v2.1.66 path first, then legacy fallback). All JSON access goes through this layer. Five new atomic components follow existing pattern (collect/render/config + register_component). OAuth API gets HTTP status code handling and retry logic.

**Tech Stack:** Bash 4+, jq, BATS testing, TOML config

---

### Task 1: Create JSON Field Access Layer — Tests

**Files:**
- Create: `tests/unit/test_json_fields.bats`

**Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# ==============================================================================
# Test: JSON Field Access Abstraction Layer
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    # Source the module
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ==============================================================================
# get_json_field basic extraction
# ==============================================================================

@test "get_json_field extracts simple top-level field" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    run get_json_field "version"
    assert_success
    assert_output "2.1.66"
}

@test "get_json_field extracts nested field with dot notation" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus","id":"claude-opus-4-6"}}'
    run get_json_field "model.display_name"
    assert_success
    assert_output "Opus"
}

@test "get_json_field returns default when field missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    run get_json_field "version" "unknown"
    assert_success
    assert_output "unknown"
}

@test "get_json_field returns empty string when field missing and no default" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    run get_json_field "nonexistent"
    assert_success
    assert_output ""
}

@test "get_json_field handles null JSON values" {
    export STATUSLINE_INPUT_JSON='{"version":null}'
    run get_json_field "version" "fallback"
    assert_success
    assert_output "fallback"
}

@test "get_json_field handles empty STATUSLINE_INPUT_JSON" {
    export STATUSLINE_INPUT_JSON=""
    run get_json_field "version" "none"
    assert_success
    assert_output "none"
}

# ==============================================================================
# Path migration: current_usage -> context_window.current_usage
# ==============================================================================

@test "get_json_field migrates current_usage to context_window.current_usage (new path)" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"input_tokens":8500}}}'
    run get_json_field "current_usage.input_tokens"
    assert_success
    assert_output "8500"
}

@test "get_json_field falls back to legacy current_usage path" {
    export STATUSLINE_INPUT_JSON='{"current_usage":{"input_tokens":7000}}'
    run get_json_field "current_usage.input_tokens"
    assert_success
    assert_output "7000"
}

@test "get_json_field prefers new path over legacy" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"input_tokens":9000}},"current_usage":{"input_tokens":5000}}'
    run get_json_field "current_usage.input_tokens"
    assert_success
    assert_output "9000"
}

@test "get_json_field migrates cache_read_input_tokens" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"cache_read_input_tokens":3000}}}'
    run get_json_field "current_usage.cache_read_input_tokens"
    assert_success
    assert_output "3000"
}

@test "get_json_field migrates cache_creation_input_tokens" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"current_usage":{"cache_creation_input_tokens":2000}}}'
    run get_json_field "current_usage.cache_creation_input_tokens"
    assert_success
    assert_output "2000"
}

# ==============================================================================
# has_json_field
# ==============================================================================

@test "has_json_field returns 0 when field exists" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    run has_json_field "version"
    assert_success
}

@test "has_json_field returns 1 when field missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    run has_json_field "version"
    assert_failure
}

@test "has_json_field returns 1 for null field" {
    export STATUSLINE_INPUT_JSON='{"version":null}'
    run has_json_field "version"
    assert_failure
}

@test "has_json_field detects nested fields" {
    export STATUSLINE_INPUT_JSON='{"vim":{"mode":"NORMAL"}}'
    run has_json_field "vim.mode"
    assert_success
}

# ==============================================================================
# validate_json_schema
# ==============================================================================

@test "validate_json_schema detects Claude Code version" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66","workspace":{"current_dir":"/tmp"}}'
    validate_json_schema
    run get_detected_cc_version
    assert_success
    assert_output "2.1.66"
}

@test "validate_json_schema returns unknown for missing version" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'
    validate_json_schema
    run get_detected_cc_version
    assert_success
    assert_output "unknown"
}

# ==============================================================================
# Boolean field extraction
# ==============================================================================

@test "get_json_field_bool returns true for true boolean" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":true}'
    run get_json_field_bool "exceeds_200k_tokens"
    assert_success
    assert_output "true"
}

@test "get_json_field_bool returns false for false boolean" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":false}'
    run get_json_field_bool "exceeds_200k_tokens"
    assert_success
    assert_output "false"
}

@test "get_json_field_bool returns default for missing field" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    run get_json_field_bool "exceeds_200k_tokens" "false"
    assert_success
    assert_output "false"
}
```

**Step 2: Run tests to verify they fail**

Run: `bats tests/unit/test_json_fields.bats`
Expected: FAIL — `lib/json_fields.sh` does not exist

**Step 3: Commit test file**

```bash
git add tests/unit/test_json_fields.bats
git commit -m "test: add JSON field access layer tests for v2.1.66 compat"
```

---

### Task 2: Create JSON Field Access Layer — Implementation

**Files:**
- Create: `lib/json_fields.sh`

**Step 1: Implement the module**

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - JSON Field Access Abstraction Layer
# ============================================================================
#
# Provides safe, version-aware JSON field extraction from STATUSLINE_INPUT_JSON.
# Handles path migration (e.g., current_usage -> context_window.current_usage)
# and schema validation for Claude Code v2.1.6 through v2.1.66+.
#
# Dependencies: core.sh (debug_log)
# Load order: AFTER security, BEFORE config
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_JSON_FIELDS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_JSON_FIELDS_LOADED=true

# Detected Claude Code version (set by validate_json_schema)
_DETECTED_CC_VERSION="unknown"

# ============================================================================
# PATH MIGRATION MAP
# ============================================================================
# Maps legacy field paths to their new canonical paths in v2.1.66+
# Format: "legacy_prefix:canonical_prefix"

_JSON_MIGRATION_PATHS=(
    "current_usage:context_window.current_usage"
)

# ============================================================================
# CORE FIELD EXTRACTION
# ============================================================================

# Extract a field from STATUSLINE_INPUT_JSON with path migration support
# Args: field_path [default_value]
# Returns: field value, default_value if missing, or empty string
get_json_field() {
    local field_path="$1"
    local default_value="${2:-}"

    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "$default_value"
        return 0
    fi

    local result=""

    # Check if this path needs migration
    local migrated=false
    for mapping in "${_JSON_MIGRATION_PATHS[@]}"; do
        local legacy_prefix="${mapping%%:*}"
        local canonical_prefix="${mapping##*:}"

        if [[ "$field_path" == "$legacy_prefix"* ]]; then
            # Build canonical path
            local suffix="${field_path#"$legacy_prefix"}"
            local canonical_path="${canonical_prefix}${suffix}"

            # Try canonical path first (new v2.1.66+ location)
            result=$(echo "$STATUSLINE_INPUT_JSON" | jq -r ".${canonical_path} // empty" 2>/dev/null)
            if [[ -n "$result" && "$result" != "null" ]]; then
                migrated=true
                break
            fi

            # Fall back to legacy path
            result=$(echo "$STATUSLINE_INPUT_JSON" | jq -r ".${field_path} // empty" 2>/dev/null)
            if [[ -n "$result" && "$result" != "null" ]]; then
                migrated=true
                break
            fi
        fi
    done

    # No migration needed — direct extraction
    if [[ "$migrated" == "false" ]]; then
        result=$(echo "$STATUSLINE_INPUT_JSON" | jq -r ".${field_path} // empty" 2>/dev/null)
    fi

    # Return result or default
    if [[ -n "$result" && "$result" != "null" ]]; then
        echo "$result"
    else
        echo "$default_value"
    fi
}

# Check if a JSON field exists and is not null
# Args: field_path
# Returns: 0 if exists, 1 if missing/null
has_json_field() {
    local field_path="$1"

    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        return 1
    fi

    # Check with migration support
    local result
    result=$(get_json_field "$field_path")

    if [[ -n "$result" ]]; then
        return 0
    else
        return 1
    fi
}

# Extract a boolean field (returns "true" or "false")
# Args: field_path [default_value]
get_json_field_bool() {
    local field_path="$1"
    local default_value="${2:-false}"

    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "$default_value"
        return 0
    fi

    local result
    result=$(echo "$STATUSLINE_INPUT_JSON" | jq -r "if .${field_path} == true then \"true\" elif .${field_path} == false then \"false\" else empty end" 2>/dev/null)

    if [[ -n "$result" ]]; then
        echo "$result"
    else
        echo "$default_value"
    fi
}

# Extract a numeric field with default
# Args: field_path [default_value]
get_json_field_num() {
    local field_path="$1"
    local default_value="${2:-0}"

    local result
    result=$(get_json_field "$field_path" "$default_value")

    # Validate it's numeric
    if [[ "$result" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
        echo "$result"
    else
        echo "$default_value"
    fi
}

# ============================================================================
# SCHEMA VALIDATION
# ============================================================================

# Validate JSON schema and detect Claude Code version
# Called once after JSON is loaded in statusline.sh
validate_json_schema() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        debug_log "No JSON input to validate" "WARN"
        _DETECTED_CC_VERSION="unknown"
        return 0
    fi

    # Detect Claude Code version
    local version
    version=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.version // empty' 2>/dev/null)
    if [[ -n "$version" && "$version" != "null" ]]; then
        _DETECTED_CC_VERSION="$version"
        debug_log "Detected Claude Code version: $version" "INFO"
    else
        _DETECTED_CC_VERSION="unknown"
        debug_log "Claude Code version not available in JSON (pre-v2.1.50)" "INFO"
    fi

    # Check required field
    local current_dir
    current_dir=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
    if [[ -z "$current_dir" ]]; then
        debug_log "Required field missing: workspace.current_dir" "WARN"
    fi

    # Log available optional fields for debugging
    local available_fields=""
    has_json_field "version" && available_fields+="version "
    has_json_field "model.id" && available_fields+="model.id "
    has_json_field "exceeds_200k_tokens" && available_fields+="exceeds_200k "
    has_json_field "vim.mode" && available_fields+="vim.mode "
    has_json_field "agent.name" && available_fields+="agent.name "
    has_json_field "context_window.total_input_tokens" && available_fields+="total_tokens "
    has_json_field "workspace.added_dirs" && available_fields+="added_dirs "

    if [[ -n "$available_fields" ]]; then
        debug_log "Available v2.1.66 fields: $available_fields" "INFO"
    fi

    return 0
}

# Get detected Claude Code version
get_detected_cc_version() {
    echo "$_DETECTED_CC_VERSION"
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f get_json_field has_json_field get_json_field_bool get_json_field_num
export -f validate_json_schema get_detected_cc_version

debug_log "JSON fields abstraction layer loaded" "INFO"
```

**Step 2: Run tests to verify they pass**

Run: `bats tests/unit/test_json_fields.bats`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add lib/json_fields.sh
git commit -m "feat: add JSON field access abstraction layer for v2.1.66 compat"
```

---

### Task 3: Integrate json_fields into statusline.sh

**Files:**
- Modify: `statusline.sh:99` (module loading section, after security, before config)
- Modify: `statusline.sh:1345` (after JSON export, add schema validation)

**Step 1: Add module loading**

After line 99 (`load_module "security"`), add:

```bash
load_module "json_fields" || {
    debug_log "Failed to load JSON fields module" "WARN"
}
```

**Step 2: Add schema validation after JSON export**

After line 1345 (`export STATUSLINE_INPUT_JSON="$input"`), add:

```bash
# Validate JSON schema and detect Claude Code version
if is_module_loaded "json_fields"; then
    validate_json_schema
fi
```

**Step 3: Run existing test suite**

Run: `npm test`
Expected: All existing 838+ tests PASS (no regressions)

**Step 4: Commit**

```bash
git add statusline.sh
git commit -m "feat: integrate JSON fields module into statusline boot sequence"
```

---

### Task 4: Migrate native.sh to use get_json_field

**Files:**
- Modify: `lib/cost/native.sh:99,111` (current_usage extractions)

**Step 1: Replace direct jq calls with get_json_field**

In `get_native_cache_read_tokens()` (line 99), replace:
```bash
tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_read_input_tokens // 0' 2>/dev/null)
```
With:
```bash
tokens=$(get_json_field "current_usage.cache_read_input_tokens" "0")
```

In `get_native_cache_creation_tokens()` (line 111), replace:
```bash
tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_creation_input_tokens // 0' 2>/dev/null)
```
With:
```bash
tokens=$(get_json_field "current_usage.cache_creation_input_tokens" "0")
```

**Step 2: Run tests**

Run: `npm test`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add lib/cost/native.sh
git commit -m "refactor: migrate native.sh to use get_json_field for current_usage path compat"
```

---

### Task 5: Migrate recommendations.sh to use get_json_field

**Files:**
- Modify: `lib/cost/recommendations.sh:363-364`

**Step 1: Replace direct jq calls**

At line 363-364, replace:
```bash
cache_read=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_read_input_tokens // 0' 2>/dev/null) || cache_read=0
input_tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.input_tokens // 0' 2>/dev/null) || input_tokens=0
```
With:
```bash
cache_read=$(get_json_field "current_usage.cache_read_input_tokens" "0") || cache_read=0
input_tokens=$(get_json_field "current_usage.input_tokens" "0") || input_tokens=0
```

**Step 2: Run tests**

Run: `npm test`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add lib/cost/recommendations.sh
git commit -m "refactor: migrate recommendations.sh to use get_json_field for current_usage path compat"
```

---

### Task 6: Harden OAuth API — Tests

**Files:**
- Create: `tests/unit/test_oauth_usage.bats`

**Step 1: Write failing tests**

```bash
#!/usr/bin/env bats
# ==============================================================================
# Test: OAuth Usage Limits API Hardening
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/security.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/cache.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/usage_limits.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ==============================================================================
# Native JSON priority (when five_hour/seven_day present)
# ==============================================================================

@test "collect_usage_limits_data uses native JSON when five_hour.utilization present" {
    export STATUSLINE_INPUT_JSON='{"five_hour":{"utilization":22.5,"resets_at":"2026-03-04T19:00:00Z"},"seven_day":{"utilization":54.0,"resets_at":"2026-03-08T08:00:00Z"}}'
    collect_usage_limits_data
    [[ "$COMPONENT_USAGE_FIVE_HOUR" == "23" || "$COMPONENT_USAGE_FIVE_HOUR" == "22" ]]
}

@test "collect_usage_limits_data sets empty when no data available" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'
    # Mock curl to fail
    create_failing_mock_command "curl" "Connection refused"
    # Mock security to fail
    create_failing_mock_command "security" "SecItemNotFound"
    collect_usage_limits_data
    [[ -z "$COMPONENT_USAGE_FIVE_HOUR" ]]
}

# ==============================================================================
# Usage reset rendering
# ==============================================================================

@test "render_usage_reset shows countdown when data available" {
    export STATUSLINE_INPUT_JSON='{"five_hour":{"utilization":22.5,"resets_at":"2026-03-04T23:00:00Z"},"seven_day":{"utilization":54.0,"resets_at":"2026-03-08T08:00:00Z"}}'
    collect_usage_limits_data
    run render_usage_reset "false"
    assert_success
    assert_output --partial "5H"
}

@test "render_usage_reset returns 1 when no data" {
    COMPONENT_USAGE_FIVE_HOUR=""
    COMPONENT_USAGE_SEVEN_DAY=""
    run render_usage_reset "false"
    assert_failure
}

# ==============================================================================
# Error status communication
# ==============================================================================

@test "COMPONENT_USAGE_STATUS is set to ok on success" {
    export STATUSLINE_INPUT_JSON='{"five_hour":{"utilization":22.5,"resets_at":"2026-03-04T19:00:00Z"}}'
    collect_usage_limits_data
    [[ "$COMPONENT_USAGE_STATUS" == "ok" ]]
}

@test "COMPONENT_USAGE_STATUS is set to unavailable on failure" {
    export STATUSLINE_INPUT_JSON='{"workspace":{"current_dir":"/tmp"}}'
    create_failing_mock_command "curl" "Connection refused"
    create_failing_mock_command "security" "SecItemNotFound"
    collect_usage_limits_data
    [[ "$COMPONENT_USAGE_STATUS" == "unavailable" ]]
}
```

**Step 2: Run to verify fails**

Run: `bats tests/unit/test_oauth_usage.bats`
Expected: Some tests FAIL (COMPONENT_USAGE_STATUS not defined yet)

**Step 3: Commit**

```bash
git add tests/unit/test_oauth_usage.bats
git commit -m "test: add OAuth usage limits API hardening tests"
```

---

### Task 7: Harden OAuth API — Implementation

**Files:**
- Modify: `lib/components/usage_limits.sh:19-22,294-393`

**Step 1: Add status variable (after line 22)**

```bash
COMPONENT_USAGE_STATUS="unknown"
```

**Step 2: Rewrite `fetch_usage_limits()` with HTTP status handling**

Replace the function (lines 294-335) with:

```bash
fetch_usage_limits() {
    local token
    token=$(get_claude_oauth_token)

    if [[ -z "$token" ]]; then
        debug_log "No OAuth token available for usage limits" "INFO"
        echo ""
        return 1
    fi

    # Check cache first
    local cache_key="usage_limits_api"
    local cached_result
    cached_result=$(get_cached_value "$cache_key" "$USAGE_LIMITS_CACHE_TTL" 2>/dev/null)

    if [[ -n "$cached_result" ]]; then
        debug_log "Using cached usage limits" "INFO"
        echo "$cached_result"
        return 0
    fi

    # Fetch from API with HTTP status code capture
    local response http_code body
    response=$(curl -s -w "\n%{http_code}" --max-time 5 \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Accept: application/json" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || {
        debug_log "OAuth API connection failed (curl error)" "WARN"
        echo ""
        return 1
    }

    # Split response body and HTTP status code
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    case "$http_code" in
        200)
            if [[ -n "$body" ]] && echo "$body" | jq -e '.five_hour' &>/dev/null; then
                set_cached_value "$cache_key" "$body" 2>/dev/null
                debug_log "Fetched fresh usage limits from API (200 OK)" "INFO"
                echo "$body"
                return 0
            else
                debug_log "OAuth API returned 200 but invalid JSON body" "WARN"
            fi
            ;;
        401)
            debug_log "OAuth token expired/invalid (401) - re-authenticate Claude Code" "WARN"
            ;;
        403)
            debug_log "OAuth access forbidden (403)" "WARN"
            ;;
        429)
            debug_log "OAuth API rate limited (429) - using cached data if available" "WARN"
            ;;
        5[0-9][0-9])
            debug_log "OAuth API server error ($http_code) - retrying once" "WARN"
            # Single retry after 2s
            sleep 2
            response=$(curl -s -w "\n%{http_code}" --max-time 5 \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json" \
                -H "anthropic-beta: oauth-2025-04-20" \
                -H "Accept: application/json" \
                "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || true
            http_code=$(echo "$response" | tail -n1)
            body=$(echo "$response" | sed '$d')
            if [[ "$http_code" == "200" ]] && echo "$body" | jq -e '.five_hour' &>/dev/null; then
                set_cached_value "$cache_key" "$body" 2>/dev/null
                debug_log "OAuth API retry succeeded" "INFO"
                echo "$body"
                return 0
            fi
            debug_log "OAuth API retry failed ($http_code)" "WARN"
            ;;
        "")
            debug_log "OAuth API timeout or no response" "WARN"
            ;;
        *)
            debug_log "OAuth API unexpected status: $http_code" "WARN"
            ;;
    esac

    echo ""
    return 1
}
```

**Step 3: Update `collect_usage_limits_data()` to set status**

At end of `collect_usage_limits_data()`, before `return 0`, add status tracking:

Replace lines 387-392:
```bash
        debug_log "usage_limits data: 5h=${COMPONENT_USAGE_FIVE_HOUR}%, 7d=${COMPONENT_USAGE_SEVEN_DAY}%" "INFO"
    else
        debug_log "No usage limits data available (no native JSON, no OAuth)" "INFO"
    fi

    return 0
```
With:
```bash
        debug_log "usage_limits data: 5h=${COMPONENT_USAGE_FIVE_HOUR}%, 7d=${COMPONENT_USAGE_SEVEN_DAY}%" "INFO"
        COMPONENT_USAGE_STATUS="ok"
    else
        debug_log "No usage limits data available (no native JSON, no OAuth)" "INFO"
        COMPONENT_USAGE_STATUS="unavailable"
    fi

    return 0
```

**Step 4: Run tests**

Run: `bats tests/unit/test_oauth_usage.bats && npm test`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/components/usage_limits.sh
git commit -m "feat: harden OAuth API with HTTP status codes, retry logic, and status tracking"
```

---

### Task 8: Create version_display Component — Tests

**Files:**
- Create: `tests/unit/test_version_display.bats`

**Step 1: Write failing tests**

```bash
#!/usr/bin/env bats
# ==============================================================================
# Test: Version Display Component
# ==============================================================================

load "../setup_suite"

setup() {
    common_setup
    STATUSLINE_TESTING="true"
    export STATUSLINE_TESTING
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/version_display.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

@test "collect_version_display_data extracts version from JSON" {
    export STATUSLINE_INPUT_JSON='{"version":"2.1.66"}'
    collect_version_display_data
    [[ "$COMPONENT_VERSION_DISPLAY_VALUE" == "2.1.66" ]]
}

@test "collect_version_display_data sets empty when version absent" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_version_display_data
    [[ -z "$COMPONENT_VERSION_DISPLAY_VALUE" ]]
}

@test "render_version_display shows short format" {
    COMPONENT_VERSION_DISPLAY_VALUE="2.1.66"
    CONFIG_VERSION_DISPLAY_FORMAT="short"
    run render_version_display "false"
    assert_success
    assert_output "v2.1.66"
}

@test "render_version_display shows full format" {
    COMPONENT_VERSION_DISPLAY_VALUE="2.1.66"
    CONFIG_VERSION_DISPLAY_FORMAT="full"
    run render_version_display "false"
    assert_success
    assert_output "CC v2.1.66"
}

@test "render_version_display returns 1 when no version" {
    COMPONENT_VERSION_DISPLAY_VALUE=""
    run render_version_display "false"
    assert_failure
}
```

**Step 2: Commit**

```bash
git add tests/unit/test_version_display.bats
git commit -m "test: add version_display component tests"
```

---

### Task 9: Create version_display Component — Implementation

**Files:**
- Create: `lib/components/version_display.sh`

**Step 1: Implement**

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - Version Display Component
# ============================================================================
#
# Displays the Claude Code CLI version from native JSON input.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

COMPONENT_VERSION_DISPLAY_VALUE=""

collect_version_display_data() {
    debug_log "Collecting version_display component data" "INFO"
    COMPONENT_VERSION_DISPLAY_VALUE=""

    if declare -f get_json_field &>/dev/null; then
        COMPONENT_VERSION_DISPLAY_VALUE=$(get_json_field "version")
    fi

    debug_log "version_display data: value=$COMPONENT_VERSION_DISPLAY_VALUE" "INFO"
    return 0
}

render_version_display() {
    local theme_enabled="${1:-true}"

    if [[ -z "$COMPONENT_VERSION_DISPLAY_VALUE" ]]; then
        return 1
    fi

    local format="${CONFIG_VERSION_DISPLAY_FORMAT:-short}"
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_TEAL:-}"
    fi

    local output
    case "$format" in
        full) output="CC v${COMPONENT_VERSION_DISPLAY_VALUE}" ;;
        *)    output="v${COMPONENT_VERSION_DISPLAY_VALUE}" ;;
    esac

    echo "${color_code}${output}${COLOR_RESET}"
}

get_version_display_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "version_display" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_VERSION_DISPLAY:-${default:-true}}" ;;
        "format") echo "${CONFIG_VERSION_DISPLAY_FORMAT:-${default:-short}}" ;;
        "description") echo "Claude Code CLI version" ;;
        *) echo "$default" ;;
    esac
}

VERSION_DISPLAY_COMPONENT_NAME="version_display"
VERSION_DISPLAY_COMPONENT_VERSION="2.20.0"
VERSION_DISPLAY_COMPONENT_DEPENDENCIES=("json_fields")

register_component \
    "version_display" \
    "Claude Code CLI version" \
    "display" \
    "true"

export -f collect_version_display_data render_version_display get_version_display_config
debug_log "Version display component loaded" "INFO"
```

**Step 2: Run tests**

Run: `bats tests/unit/test_version_display.bats`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add lib/components/version_display.sh
git commit -m "feat: add version_display component for Claude Code CLI version"
```

---

### Task 10: Create vim_mode Component

**Files:**
- Create: `tests/unit/test_vim_mode.bats`
- Create: `lib/components/vim_mode.sh`

**Step 1: Write tests**

```bash
#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/vim_mode.sh" 2>/dev/null || true
}

teardown() { common_teardown; }

@test "collect_vim_mode_data extracts NORMAL mode" {
    export STATUSLINE_INPUT_JSON='{"vim":{"mode":"NORMAL"}}'
    collect_vim_mode_data
    [[ "$COMPONENT_VIM_MODE_VALUE" == "NORMAL" ]]
}

@test "collect_vim_mode_data extracts INSERT mode" {
    export STATUSLINE_INPUT_JSON='{"vim":{"mode":"INSERT"}}'
    collect_vim_mode_data
    [[ "$COMPONENT_VIM_MODE_VALUE" == "INSERT" ]]
}

@test "collect_vim_mode_data empty when vim not enabled" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_vim_mode_data
    [[ -z "$COMPONENT_VIM_MODE_VALUE" ]]
}

@test "render_vim_mode shows VIM:NORMAL" {
    COMPONENT_VIM_MODE_VALUE="NORMAL"
    run render_vim_mode "false"
    assert_success
    assert_output "VIM:NORMAL"
}

@test "render_vim_mode shows VIM:INSERT" {
    COMPONENT_VIM_MODE_VALUE="INSERT"
    run render_vim_mode "false"
    assert_success
    assert_output "VIM:INSERT"
}

@test "render_vim_mode returns 1 when disabled" {
    COMPONENT_VIM_MODE_VALUE=""
    run render_vim_mode "false"
    assert_failure
}
```

**Step 2: Implement**

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - Vim Mode Component
# ============================================================================
#
# Displays vim mode state (NORMAL/INSERT) when vim mode is enabled.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

COMPONENT_VIM_MODE_VALUE=""

collect_vim_mode_data() {
    debug_log "Collecting vim_mode component data" "INFO"
    COMPONENT_VIM_MODE_VALUE=""

    if declare -f get_json_field &>/dev/null; then
        COMPONENT_VIM_MODE_VALUE=$(get_json_field "vim.mode")
    fi

    debug_log "vim_mode data: value=$COMPONENT_VIM_MODE_VALUE" "INFO"
    return 0
}

render_vim_mode() {
    local theme_enabled="${1:-true}"

    if [[ -z "$COMPONENT_VIM_MODE_VALUE" ]]; then
        return 1
    fi

    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        case "$COMPONENT_VIM_MODE_VALUE" in
            NORMAL) color_code="${CONFIG_GREEN:-}" ;;
            INSERT) color_code="${CONFIG_YELLOW:-}" ;;
            *) color_code="" ;;
        esac
    fi

    echo "${color_code}VIM:${COMPONENT_VIM_MODE_VALUE}${COLOR_RESET}"
}

get_vim_mode_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "vim_mode" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_VIM_MODE:-${default:-true}}" ;;
        "description") echo "Vim mode state (NORMAL/INSERT)" ;;
        *) echo "$default" ;;
    esac
}

VIM_MODE_COMPONENT_NAME="vim_mode"
VIM_MODE_COMPONENT_VERSION="2.20.0"
VIM_MODE_COMPONENT_DEPENDENCIES=("json_fields")

register_component "vim_mode" "Vim mode state (NORMAL/INSERT)" "display" "true"
export -f collect_vim_mode_data render_vim_mode get_vim_mode_config
debug_log "Vim mode component loaded" "INFO"
```

**Step 3: Run tests**

Run: `bats tests/unit/test_vim_mode.bats`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add tests/unit/test_vim_mode.bats lib/components/vim_mode.sh
git commit -m "feat: add vim_mode component for vim mode indicator"
```

---

### Task 11: Create agent_display Component

**Files:**
- Create: `tests/unit/test_agent_display.bats`
- Create: `lib/components/agent_display.sh`

**Step 1: Write tests**

```bash
#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/agent_display.sh" 2>/dev/null || true
}

teardown() { common_teardown; }

@test "collect_agent_display_data extracts agent name" {
    export STATUSLINE_INPUT_JSON='{"agent":{"name":"security-reviewer"}}'
    collect_agent_display_data
    [[ "$COMPONENT_AGENT_DISPLAY_NAME" == "security-reviewer" ]]
}

@test "collect_agent_display_data empty when no agent" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_agent_display_data
    [[ -z "$COMPONENT_AGENT_DISPLAY_NAME" ]]
}

@test "render_agent_display shows agent name" {
    COMPONENT_AGENT_DISPLAY_NAME="security-reviewer"
    run render_agent_display "false"
    assert_success
    assert_output "Agent: security-reviewer"
}

@test "render_agent_display returns 1 when no agent" {
    COMPONENT_AGENT_DISPLAY_NAME=""
    run render_agent_display "false"
    assert_failure
}
```

**Step 2: Implement**

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - Agent Display Component
# ============================================================================
#
# Displays the agent name when running with --agent flag.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

COMPONENT_AGENT_DISPLAY_NAME=""

collect_agent_display_data() {
    debug_log "Collecting agent_display component data" "INFO"
    COMPONENT_AGENT_DISPLAY_NAME=""

    if declare -f get_json_field &>/dev/null; then
        COMPONENT_AGENT_DISPLAY_NAME=$(get_json_field "agent.name")
    fi

    debug_log "agent_display data: name=$COMPONENT_AGENT_DISPLAY_NAME" "INFO"
    return 0
}

render_agent_display() {
    local theme_enabled="${1:-true}"

    if [[ -z "$COMPONENT_AGENT_DISPLAY_NAME" ]]; then
        return 1
    fi

    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_PURPLE:-\033[95m}"
    fi

    echo "${color_code}Agent: ${COMPONENT_AGENT_DISPLAY_NAME}${COLOR_RESET}"
}

get_agent_display_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "agent_display" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_AGENT_DISPLAY:-${default:-true}}" ;;
        "description") echo "Agent name when running with --agent" ;;
        *) echo "$default" ;;
    esac
}

AGENT_DISPLAY_COMPONENT_NAME="agent_display"
AGENT_DISPLAY_COMPONENT_VERSION="2.20.0"
AGENT_DISPLAY_COMPONENT_DEPENDENCIES=("json_fields")

register_component "agent_display" "Agent name when running with --agent" "display" "true"
export -f collect_agent_display_data render_agent_display get_agent_display_config
debug_log "Agent display component loaded" "INFO"
```

**Step 3: Run tests and commit**

Run: `bats tests/unit/test_agent_display.bats`

```bash
git add tests/unit/test_agent_display.bats lib/components/agent_display.sh
git commit -m "feat: add agent_display component for --agent mode indicator"
```

---

### Task 12: Create context_alert Component

**Files:**
- Create: `tests/unit/test_context_alert.bats`
- Create: `lib/components/context_alert.sh`

**Step 1: Write tests**

```bash
#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/context_alert.sh" 2>/dev/null || true
}

teardown() { common_teardown; }

@test "collect_context_alert_data detects exceeded true" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":true}'
    collect_context_alert_data
    [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" == "true" ]]
}

@test "collect_context_alert_data detects exceeded false" {
    export STATUSLINE_INPUT_JSON='{"exceeds_200k_tokens":false}'
    collect_context_alert_data
    [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" == "false" ]]
}

@test "collect_context_alert_data defaults false when missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_context_alert_data
    [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" == "false" ]]
}

@test "render_context_alert shows warning when exceeded" {
    COMPONENT_CONTEXT_ALERT_EXCEEDED="true"
    run render_context_alert "false"
    assert_success
    assert_output --partial ">200K"
}

@test "render_context_alert returns 1 when not exceeded" {
    COMPONENT_CONTEXT_ALERT_EXCEEDED="false"
    run render_context_alert "false"
    assert_failure
}

@test "render_context_alert returns 1 when field absent" {
    COMPONENT_CONTEXT_ALERT_EXCEEDED=""
    run render_context_alert "false"
    assert_failure
}
```

**Step 2: Implement**

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - Context Alert Component
# ============================================================================
#
# Shows a warning when token usage exceeds 200K threshold.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

COMPONENT_CONTEXT_ALERT_EXCEEDED=""

collect_context_alert_data() {
    debug_log "Collecting context_alert component data" "INFO"
    COMPONENT_CONTEXT_ALERT_EXCEEDED="false"

    if declare -f get_json_field_bool &>/dev/null; then
        COMPONENT_CONTEXT_ALERT_EXCEEDED=$(get_json_field_bool "exceeds_200k_tokens" "false")
    fi

    debug_log "context_alert data: exceeded=$COMPONENT_CONTEXT_ALERT_EXCEEDED" "INFO"
    return 0
}

render_context_alert() {
    local theme_enabled="${1:-true}"

    if [[ "$COMPONENT_CONTEXT_ALERT_EXCEEDED" != "true" ]]; then
        return 1
    fi

    local color_code="" bold=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_RED:-}"
        bold="${CONFIG_BOLD:-\033[1m}"
    fi

    local label="${CONFIG_CONTEXT_ALERT_THRESHOLD_LABEL:-">200K"}"
    echo "${bold}${color_code}${label}${COLOR_RESET}"
}

get_context_alert_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "context_alert" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_CONTEXT_ALERT:-${default:-true}}" ;;
        "description") echo "Warning when tokens exceed 200K threshold" ;;
        *) echo "$default" ;;
    esac
}

CONTEXT_ALERT_COMPONENT_NAME="context_alert"
CONTEXT_ALERT_COMPONENT_VERSION="2.20.0"
CONTEXT_ALERT_COMPONENT_DEPENDENCIES=("json_fields")

register_component "context_alert" "Warning when tokens exceed 200K threshold" "display" "true"
export -f collect_context_alert_data render_context_alert get_context_alert_config
debug_log "Context alert component loaded" "INFO"
```

**Step 3: Run tests and commit**

Run: `bats tests/unit/test_context_alert.bats`

```bash
git add tests/unit/test_context_alert.bats lib/components/context_alert.sh
git commit -m "feat: add context_alert component for >200K token warning"
```

---

### Task 13: Create total_tokens Component

**Files:**
- Create: `tests/unit/test_total_tokens.bats`
- Create: `lib/components/total_tokens.sh`

**Step 1: Write tests**

```bash
#!/usr/bin/env bats
load "../setup_suite"

setup() {
    common_setup
    export STATUSLINE_TESTING="true"
    export STATUSLINE_SOURCING=true
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/json_fields.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/components/total_tokens.sh" 2>/dev/null || true
}

teardown() { common_teardown; }

@test "collect_total_tokens_data extracts cumulative tokens" {
    export STATUSLINE_INPUT_JSON='{"context_window":{"total_input_tokens":15234,"total_output_tokens":4521}}'
    collect_total_tokens_data
    [[ "$COMPONENT_TOTAL_TOKENS_INPUT" == "15234" ]]
    [[ "$COMPONENT_TOTAL_TOKENS_OUTPUT" == "4521" ]]
}

@test "collect_total_tokens_data defaults to 0 when missing" {
    export STATUSLINE_INPUT_JSON='{"model":{"display_name":"Opus"}}'
    collect_total_tokens_data
    [[ "$COMPONENT_TOTAL_TOKENS_INPUT" == "0" ]]
    [[ "$COMPONENT_TOTAL_TOKENS_OUTPUT" == "0" ]]
}

@test "render_total_tokens split format" {
    COMPONENT_TOTAL_TOKENS_INPUT="15234"
    COMPONENT_TOTAL_TOKENS_OUTPUT="4521"
    CONFIG_TOTAL_TOKENS_FORMAT="split"
    run render_total_tokens "false"
    assert_success
    assert_output --partial "15.2K in"
    assert_output --partial "4.5K out"
}

@test "render_total_tokens compact format" {
    COMPONENT_TOTAL_TOKENS_INPUT="15234"
    COMPONENT_TOTAL_TOKENS_OUTPUT="4521"
    CONFIG_TOTAL_TOKENS_FORMAT="compact"
    run render_total_tokens "false"
    assert_success
    assert_output --partial "19.8K total"
}

@test "render_total_tokens returns 1 when both zero" {
    COMPONENT_TOTAL_TOKENS_INPUT="0"
    COMPONENT_TOTAL_TOKENS_OUTPUT="0"
    run render_total_tokens "false"
    assert_failure
}

@test "render_total_tokens handles millions" {
    COMPONENT_TOTAL_TOKENS_INPUT="1523400"
    COMPONENT_TOTAL_TOKENS_OUTPUT="452100"
    CONFIG_TOTAL_TOKENS_FORMAT="compact"
    run render_total_tokens "false"
    assert_success
    assert_output --partial "M total"
}
```

**Step 2: Implement**

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - Total Tokens Component
# ============================================================================
#
# Displays cumulative input/output token counts for the session.
# Available in Claude Code v2.1.50+
#
# Dependencies: json_fields.sh, display.sh
# ============================================================================

COMPONENT_TOTAL_TOKENS_INPUT="0"
COMPONENT_TOTAL_TOKENS_OUTPUT="0"

# Format token count to human-readable (1.5K, 2.3M)
_format_tokens_human() {
    local count="${1:-0}"
    if [[ "$count" -ge 1000000 ]]; then
        awk -v c="$count" 'BEGIN { printf "%.1fM", c / 1000000 }' 2>/dev/null
    elif [[ "$count" -ge 1000 ]]; then
        awk -v c="$count" 'BEGIN { printf "%.1fK", c / 1000 }' 2>/dev/null
    else
        echo "$count"
    fi
}

collect_total_tokens_data() {
    debug_log "Collecting total_tokens component data" "INFO"
    COMPONENT_TOTAL_TOKENS_INPUT="0"
    COMPONENT_TOTAL_TOKENS_OUTPUT="0"

    if declare -f get_json_field_num &>/dev/null; then
        COMPONENT_TOTAL_TOKENS_INPUT=$(get_json_field_num "context_window.total_input_tokens" "0")
        COMPONENT_TOTAL_TOKENS_OUTPUT=$(get_json_field_num "context_window.total_output_tokens" "0")
    fi

    debug_log "total_tokens data: in=$COMPONENT_TOTAL_TOKENS_INPUT out=$COMPONENT_TOTAL_TOKENS_OUTPUT" "INFO"
    return 0
}

render_total_tokens() {
    local theme_enabled="${1:-true}"

    local total=$(( COMPONENT_TOTAL_TOKENS_INPUT + COMPONENT_TOTAL_TOKENS_OUTPUT ))
    if [[ "$total" -eq 0 ]]; then
        return 1
    fi

    local format="${CONFIG_TOTAL_TOKENS_FORMAT:-split}"
    local color_code=""
    if [[ "$theme_enabled" == "true" ]] && is_module_loaded "themes"; then
        color_code="${CONFIG_BLUE:-}"
    fi

    local output
    case "$format" in
        compact)
            local total_fmt
            total_fmt=$(_format_tokens_human "$total")
            output="Tokens: ${total_fmt} total"
            ;;
        *)
            local in_fmt out_fmt
            in_fmt=$(_format_tokens_human "$COMPONENT_TOTAL_TOKENS_INPUT")
            out_fmt=$(_format_tokens_human "$COMPONENT_TOTAL_TOKENS_OUTPUT")
            output="Tokens: ${in_fmt} in / ${out_fmt} out"
            ;;
    esac

    echo "${color_code}${output}${COLOR_RESET}"
}

get_total_tokens_config() {
    local key="${1:-component_name}"
    local default="${2:-}"
    case "$key" in
        "component_name"|"name") echo "total_tokens" ;;
        "enabled") echo "${CONFIG_FEATURES_SHOW_TOTAL_TOKENS:-${default:-true}}" ;;
        "format") echo "${CONFIG_TOTAL_TOKENS_FORMAT:-${default:-split}}" ;;
        "description") echo "Cumulative session token counts" ;;
        *) echo "$default" ;;
    esac
}

TOTAL_TOKENS_COMPONENT_NAME="total_tokens"
TOTAL_TOKENS_COMPONENT_VERSION="2.20.0"
TOTAL_TOKENS_COMPONENT_DEPENDENCIES=("json_fields")

register_component "total_tokens" "Cumulative session token counts" "display" "true"
export -f collect_total_tokens_data render_total_tokens get_total_tokens_config _format_tokens_human
debug_log "Total tokens component loaded" "INFO"
```

**Step 3: Run tests and commit**

Run: `bats tests/unit/test_total_tokens.bats`

```bash
git add tests/unit/test_total_tokens.bats lib/components/total_tokens.sh
git commit -m "feat: add total_tokens component for cumulative session token display"
```

---

### Task 14: Update Config.toml

**Files:**
- Modify: `examples/Config.toml`

**Step 1: Add new component configuration**

Add after the existing `usage_limits` config section:

```toml
# === v2.20.0 NEW COMPONENTS ===
# Version Display (Claude Code CLI version from native JSON)
features.show_version_display = true
version_display.format = "short"

# Vim Mode (shows VIM:NORMAL or VIM:INSERT when enabled)
features.show_vim_mode = true

# Agent Display (shows agent name when running with --agent)
features.show_agent_display = true

# Context Alert (warns when tokens exceed 200K)
features.show_context_alert = true
context_alert.show_only_when_exceeded = true
context_alert.threshold_label = ">200K"

# Total Tokens (cumulative session token counts)
features.show_total_tokens = true
total_tokens.format = "split"
```

**Step 2: Update default display line configurations**

Update the display line component arrays to include new components:

Line 2 — add `version_display` after `model_info`:
```toml
display.line2.components = ["model_info", "version_display", "commits", "submodules", "version_info", "time_display"]
```

Line 4 — add `total_tokens` and `context_alert`:
```toml
display.line4.components = ["burn_rate", "cache_efficiency", "block_projection", "total_tokens", "context_alert", "context_window"]
```

Line 8 — add `vim_mode` and `agent_display`:
```toml
display.line8.components = ["mcp_status", "session_mode", "vim_mode", "agent_display"]
```

**Step 3: Run tests**

Run: `npm test`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add examples/Config.toml
git commit -m "feat: add v2.20.0 component configs and updated default line layouts"
```

---

### Task 15: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update version range**

Change:
```
**Current**: v2.19.0 | **Claude Code**: v2.1.6–v2.1.42 ✓
```
To:
```
**Current**: v2.20.0 | **Claude Code**: v2.1.6–v2.1.66 ✓
```

**Step 2: Update component count and architecture**

Change `22` atomic components to `27`. Add to the component list:

Under **System** section, change `(2)` to `(4)` and add:
```
- **System** (4): mcp_status, time_display, version_display, context_alert
```

Add new section:
```
- **Session** (2): vim_mode, agent_display
- **Cumulative** (1): total_tokens
```

**Step 3: Update JSON schema in CLAUDE.md**

Update the JSON input format section to match the official v2.1.66 schema:

```json
{
  "cwd": "/current/working/directory",
  "version": "2.1.66",
  "workspace": { "current_dir": "/path/to/repo", "project_dir": "/path/to/repo", "added_dirs": [] },
  "model": { "id": "claude-opus-4-6", "display_name": "Claude Opus 4.5" },
  "session_id": "uuid-string",
  "transcript_path": "/path/to/transcript.jsonl",
  "output_style": { "name": "default" },
  "context_window": {
    "total_input_tokens": 15234,
    "total_output_tokens": 4521,
    "context_window_size": 200000,
    "used_percentage": 12,
    "remaining_percentage": 88,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  },
  "cost": { "total_cost_usd": 0.45, "total_duration_ms": 60000, "total_api_duration_ms": 30000, "total_lines_added": 120, "total_lines_removed": 30 },
  "exceeds_200k_tokens": false,
  "vim": { "mode": "NORMAL" },
  "agent": { "name": "security-reviewer" },
  "mcp": { "servers": [] }
}
```

Add note:
```
**Note**: `five_hour`/`seven_day` usage limit data is NOT available in the statusline JSON. Usage limits are fetched via OAuth API fallback (`https://api.anthropic.com/api/oauth/usage`).
```

**Step 4: Update Key Functions list**

Add:
```
- `get_json_field()` - Safe JSON extraction with path migration
- `validate_json_schema()` - Startup schema validation and version detection
```

**Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for v2.20.0 with v2.1.66 schema and new components"
```

---

### Task 16: Run Full Test Suite and Verify

**Files:** None (verification only)

**Step 1: Run all tests**

Run: `npm test`
Expected: All 838+ tests PASS, plus new tests (~30 new tests across 7 files)

**Step 2: Run lint**

Run: `npm run lint:all`
Expected: No new lint errors

**Step 3: Run manual integration test with v2.1.66 JSON**

```bash
echo '{"cwd":"/tmp","version":"2.1.66","workspace":{"current_dir":"'"$(pwd)"'","project_dir":"'"$(pwd)"'"},"model":{"id":"claude-opus-4-6","display_name":"Claude Opus 4.5"},"context_window":{"total_input_tokens":15234,"total_output_tokens":4521,"context_window_size":200000,"used_percentage":12,"remaining_percentage":88,"current_usage":{"input_tokens":8500,"output_tokens":1200,"cache_creation_input_tokens":5000,"cache_read_input_tokens":2000}},"cost":{"total_cost_usd":0.45,"total_duration_ms":60000,"total_api_duration_ms":30000,"total_lines_added":120,"total_lines_removed":30},"exceeds_200k_tokens":false,"vim":{"mode":"NORMAL"},"agent":{"name":"security-reviewer"},"session_id":"test-v2166","mcp":{"servers":[]}}' | /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh
```

Expected: All 8 lines render with new components visible:
- Line 2: model + **v2.1.66** + commits + submodules + version + time
- Line 4: burn_rate + cache + projection + **Tokens: 15.2K in / 4.5K out** + context
- Line 8: mcp + session_mode + **VIM:NORMAL** + **Agent: security-reviewer**

**Step 4: Run with legacy JSON (backward compat test)**

```bash
echo '{"workspace":{"current_dir":"'"$(pwd)"'"},"model":{"display_name":"Claude Opus 4.5"},"context_window":{"used_percentage":12},"cost":{"total_cost_usd":0.45},"current_usage":{"cache_read_input_tokens":5000,"input_tokens":10000},"session_id":"test-legacy","mcp":{"servers":[]}}' | /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh
```

Expected: All existing lines render correctly. New components hidden (fields absent). No errors.

**Step 5: Commit final**

If any fixes needed, fix and commit. Then:

```bash
git log --oneline -15  # Review all commits
```

---

### Task 17: Update Memory

**Files:**
- Modify: `~/.claude/projects/-Users-rector-local-dev-claude-code-statusline/memory/MEMORY.md`

**Step 1: Update memory with new patterns**

Add to memory:
- JSON field access layer (`get_json_field` with path migration)
- v2.1.66 official schema (no `five_hour`/`seven_day` in statusline JSON)
- `current_usage` path migration (`context_window.current_usage` canonical, top-level legacy)
- OAuth API status codes and retry logic
- New component count: 27
- Tested version: v2.1.6–v2.1.66

**Step 2: Commit (no git commit needed - memory files are not in repo)**

---

## Execution Summary

| Task | Action | Files | Est. Tests |
|------|--------|-------|------------|
| 1 | JSON fields tests | 1 new | 16 tests |
| 2 | JSON fields impl | 1 new | — |
| 3 | Integrate into statusline.sh | 1 modify | — |
| 4 | Migrate native.sh | 1 modify | — |
| 5 | Migrate recommendations.sh | 1 modify | — |
| 6 | OAuth tests | 1 new | 6 tests |
| 7 | OAuth hardening | 1 modify | — |
| 8 | version_display tests | 1 new | 5 tests |
| 9 | version_display impl | 1 new | — |
| 10 | vim_mode test+impl | 2 new | 6 tests |
| 11 | agent_display test+impl | 2 new | 4 tests |
| 12 | context_alert test+impl | 2 new | 6 tests |
| 13 | total_tokens test+impl | 2 new | 6 tests |
| 14 | Config.toml | 1 modify | — |
| 15 | CLAUDE.md | 1 modify | — |
| 16 | Full verification | 0 | Verify all |
| 17 | Update memory | 1 modify | — |

**Total: 23 files (13 new + 10 modified), ~49 new tests, 17 commits**
