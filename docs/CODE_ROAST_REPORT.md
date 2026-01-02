# CODE ROAST REPORT

**Roast Date**: 2026-01-01
**Repository**: claude-code-statusline
**Branch**: dev
**Mode**: --no-mercy (Maximum Brutality)
**Verdict**: **NEEDS WORK** (You fixed some things, broke others)

---

## EXECUTIVE SUMMARY

Previous roast: 37/60. Let's see if you've improved or regressed.

**Good News**: Some cleanup happened. Timezone mapping DRY'd up (Issue #106 referenced). Cache architecture is solid.

**Bad News**: New sins emerged. `eval` is back (plugins.sh), HTTP APIs in 2026, and you're STILL suppressing errors like they're government secrets.

---

## CAREER ENDERS

### 1. Plugin System Uses `eval` to Define Functions

**File**: `lib/plugins.sh:416`
**Sin**: Dynamic function creation using `eval` - the nuclear option of shell scripting
**Evidence**:
```bash
# shellcheck disable=SC1090
if source "$plugin_script" 2>/dev/null; then
    ...
    eval "${component_func}() { get_component; }"
```
**Why it's bad**: This is textbook "eval is evil." An attacker who can inject a malicious plugin name could execute arbitrary code. Yes, there's validation before this, but defense in depth says NEVER use eval when alternatives exist. You even have signature verification (Issue #120) but made it OPTIONAL (`CONFIG_PLUGINS_REQUIRE_SIGNATURE="${CONFIG_PLUGINS_REQUIRE_SIGNATURE:-false}"`).
**The Fix**:
1. Use `declare -f` with proper quoting
2. Make signature verification required by default, not optional
3. Or better: redesign to avoid dynamic function creation entirely

---

### 2. HTTP Used for IP Geolocation API

**File**: `lib/prayer/location.sh:118`
**Sin**: Sending requests over unencrypted HTTP in 2026
**Evidence**:
```bash
local api_url="http://ip-api.com/json/?fields=status,message,country,countryCode,region,regionName,city,lat,lon,timezone,query"
```
**Why it's bad**: Location data (IP address, coordinates, timezone) transmitted in plaintext. Any MITM can intercept and modify responses. Your User-Agent even identifies itself as "Claude-Code-Statusline/2.4.0" (also outdated - you're at v2.12.0).
**The Fix**:
1. Use `https://` (ip-api.com supports it)
2. Or switch to ipinfo.io which has free HTTPS tier
3. Update the version string to read from VERSION file

---

### 3. Error Swallowing at Industrial Scale

**Files**: Throughout `lib/*.sh`
**Sin**: 79+ instances of error suppression patterns
**Evidence**:
```bash
# Counted patterns:
# - 2>/dev/null: 79 instances
# - || true: abundant
# - || :: plentiful
```
**Sample from lib/install.sh:1430**:
```bash
if rm -rf "$dir_path" 2>/dev/null; then
```
**Why it's bad**: When things break in production, you'll have ZERO diagnostics. You're rm -rf'ing directories and saying "I don't care if this fails." That's not "best-effort," that's negligence.

**The Silver Lining**: You DO document WHY some are suppressed:
```bash
# Error Suppression Patterns (Issue #108):
# - mkdir -p 2>/dev/null: Creating secure dirs (race condition safe)
```
That's better than most, but the comment doesn't make the silent failure less dangerous.

**The Fix**: Log errors before suppressing them. `|| debug_log "thing failed" "WARN"` costs nothing.

---

## EMBARRASSING MOMENTS

### 4. Legacy `/tmp` Path Still Hardcoded

**File**: `lib/cache/directory.sh:57`
**Sin**: Hardcoded world-writable temp directory STILL exists
**Evidence**:
```bash
export LEGACY_CACHE_DIR="/tmp/.claude_statusline_cache"
```
**Why it's bad**:
1. `/tmp` is world-readable on most systems
2. Other users can create symlinks to hijack cache files
3. You HAVE XDG-compliant paths elsewhere - this is technical debt you're carrying

**The Fix**: Remove legacy path references. Migrate fully to `$XDG_CACHE_HOME`.

---

### 5. 1740-Line God File: cost.sh

**File**: `lib/cost.sh`
**Sin**: A single file with 1,740 lines of bash
**Evidence**:
```bash
$ wc -l lib/cost.sh
1740
```
**Why it's bad**:
- No single person can hold this in their head
- Testing is a nightmare
- The file contains: ccusage integration, cache management, session tracking, cost formatting, alerts, notifications...
- "I'll refactor it later" energy is strong

**The Fix**: Split into:
- `lib/cost/tracking.sh` - Core cost tracking
- `lib/cost/ccusage.sh` - ccusage integration
- `lib/cost/formatting.sh` - Display formatting
- `lib/cost/alerts.sh` - Alert/notification system

---

### 6. Global Namespace Pollution Festival

**Files**: `lib/mcp.sh:457-460`, `lib/cache/*.sh`, `lib/cost.sh:1693`
**Sin**: 40+ `export -f` statements polluting global namespace
**Evidence**:
```bash
export -f is_claude_cli_available execute_mcp_list parse_mcp_server_list
export -f get_mcp_status get_all_mcp_servers get_active_mcp_servers
export -f format_mcp_servers get_mcp_display get_mcp_health
export -f get_mcp_server_details get_cached_mcp_status
...
export -f send_cost_notification is_notification_cooldown_expired update_notification_timestamp
```
**Why it's bad**: Every exported function bleeds into child processes. If ANY other tool on the system has a `get_mcp_status` function? Undefined behavior.
**The Fix**: Namespace your exports: `statusline_mcp_get_status` or reduce exports to absolute minimum.

---

### 7. Sourcing User-Provided Scripts

**File**: `lib/plugins.sh:407`
**Sin**: Sourcing arbitrary user-provided plugin scripts
**Evidence**:
```bash
# shellcheck disable=SC1090
if source "$plugin_script" 2>/dev/null; then
```
**Why it's notable**: Even with pattern-based validation, you're executing user code in your process. The `DANGEROUS_PATTERNS` array is good but not comprehensive.
**Missing patterns**:
- `base64 -d` (decode & execute)
- `/dev/tcp` (bash network redirects)
- `$()` command substitution abuse

---

## EYE ROLL COLLECTION

### 8. Version String Hardcoded in User-Agent

**File**: `lib/prayer/location.sh:130`
**Sin**: Hardcoded version in User-Agent header
**Evidence**:
```bash
-H "User-Agent: Claude-Code-Statusline/2.4.0" \
```
**Why it's bad**: Your docs say v2.12.0. Your User-Agent claims 2.4.0. That's 8 versions behind.
**The Fix**: Read from VERSION file or `STATUSLINE_VERSION` variable.

---

### 9. CRITICAL EMERGENCY FIX Still Lives

**File**: `lib/cost.sh:20`
**Sin**: "Emergency fix" that's become permanent
**Evidence**:
```bash
# CRITICAL EMERGENCY FIX: Set date format defaults immediately to fix DAY $0.00 bug
[[ -z "$CONFIG_DATE_FORMAT" ]] && export CONFIG_DATE_FORMAT="%Y-%m-%d"
[[ -z "$CONFIG_DATE_FORMAT_COMPACT" ]] && export CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"
```
**Why it's bad**: If it's critical AND emergency, it should be temporary. If it's permanent, it should be properly integrated and documented, not left as a "fix."
**The Fix**: Integrate into proper config initialization or document why this specific placement is required.

---

### 10. Magic Sleep for Race Conditions

**File**: `lib/security.sh:194`
**Sin**: Using sleep to "fix" race conditions
**Evidence**:
```bash
sleep 0.1
```
**Why it's bad**: This is not a fix, it's a prayer. Race conditions need proper synchronization (which you have elsewhere - `create_secure_cache_file` uses file locking). Be consistent.
**The Fix**: Use the same file locking pattern from cache system.

---

### 11. Echo Pipes to Grep (UUOC)

**File**: `lib/mcp.sh:106-111`
**Sin**: Useless use of echo/cat
**Evidence**:
```bash
if echo "$line" | grep -q "$MCP_CONNECTED_PATTERN"; then
    server_status="$MCP_STATUS_CONNECTED"
elif echo "$line" | grep -q "$MCP_DISCONNECTED_PATTERN"; then
```
**Why it's bad**: Spawning a subshell + grep for each pattern check is wasteful.
**The Fix**:
```bash
if [[ "$line" =~ $MCP_CONNECTED_PATTERN ]]; then
```

---

### 12. Tests Skip Happy

**Files**: `tests/**/*.bats`
**Sin**: 20+ skip patterns hiding potential issues
**Evidence**:
```bash
source "$PROJECT_ROOT/lib/core.sh" || skip "Core module not available"
skip_if_no_jq
skip "Git not available for integration testing"
```
**Why it's bad**: Some are legitimate environment checks. Others might be hiding broken tests.
**The Fix**: Audit each skip. Document which are environment-dependent vs. which are TODO.

---

## WHAT YOU DID RIGHT

1. **Include Guards**: `[[ "${STATUSLINE_*_LOADED:-}" == "true" ]] && return 0` everywhere. Professional.

2. **Timeout Protection**: curl calls have `--max-time` and `--connect-timeout`. Nice.

3. **Error Documentation**: Those `# Error Suppression Patterns (Issue #XX)` comments are better than most projects.

4. **383 Tests**: Impressive for a bash project. 21 test files, good coverage.

5. **Plugin Security Validation**: DANGEROUS_PATTERNS array is a good start.

6. **Cross-Platform Support**: Platform detection for macOS vs Linux is handled properly.

7. **Timezone Mapping DRY'd Up**: `get_coordinates_from_timezone()` function exists now (Issue #106).

8. **Cache Architecture**: 8 sub-modules with proper separation of concerns.

---

## FINAL ROAST SCORE

| Category | Score | Notes |
|----------|-------|-------|
| Security | 5/10 | eval usage, HTTP API, plugin sourcing risks |
| Scalability | 7/10 | Good caching, but 1740-line god file |
| Code Quality | 6/10 | Modular architecture undermined by cost.sh |
| Testing | 7/10 | 383 tests, some skips, good coverage |
| Documentation | 7/10 | Good inline docs, outdated version strings |
| Error Handling | 4/10 | 79+ suppressions = debugging blind |

**Overall**: 36/60

---

## ROASTER'S CLOSING STATEMENT

Bismillah. Let me be direct.

This codebase is in the 70th percentile of bash projects. You have tests. You have modules. You have documentation. That's more than most.

**But you asked for --no-mercy, so here's the truth:**

The `eval` in your plugin system is unacceptable. Full stop. You have signature verification code but disabled it by default - that's security theater. The HTTP usage for location data in 2026 is embarrassing. Your 1,740-line cost.sh is the new god file after you slayed cache.sh.

The 79+ error-swallowing patterns mean when production breaks at 3 AM, you'll have zero diagnostics. "Best-effort" is developer speak for "I don't want to handle errors."

**The Good**: You clearly improved from the previous roast. The cache architecture is solid. The timezone DRY cleanup happened. Include guards everywhere.

**The Path Forward**:
1. Kill the `eval` in plugins.sh - this week
2. Switch ip-api to HTTPS - today
3. Make signature verification required by default
4. Split cost.sh into 4 modules - this month
5. Add error logging before every `2>/dev/null`

Ship it if you must. But don't call it production-ready until the Career Enders are resolved.

Wallahu a'lam.

---

*Generated by /audit:roast --no-mercy*
*May Allah guide this code to production-worthiness.*

---

## CHANGELOG FROM PREVIOUS ROAST

| Issue | Status |
|-------|--------|
| cache.sh god file | FIXED (split to 8 modules) |
| Timezone copy-paste crimes | FIXED (Issue #106) |
| 58 skipped tests | IMPROVED (now ~22) |
| eval in install.sh | FIXED (array-based approach) |
| NEW: eval in plugins.sh | FOUND |
| NEW: HTTP for ip-api | FOUND |
| config.sh split | DONE (defaults.sh, constants.sh, etc.) |

## PRIORITY ACTIONS

1. **CRITICAL**: Remove `eval` from `lib/plugins.sh:416`
2. **CRITICAL**: Change `http://ip-api.com` to HTTPS
3. **HIGH**: Make plugin signature verification required by default
4. **HIGH**: Split `lib/cost.sh` (1740 lines) into modules
5. **MEDIUM**: Update User-Agent version string
6. **MEDIUM**: Audit and remove legacy `/tmp` paths
7. **LOW**: Fix UUOC patterns in mcp.sh
