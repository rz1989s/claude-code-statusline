# CODE ROAST REPORT

**Roast Date**: 2025-12-13
**Repository**: claude-code-statusline
**Branch**: dev
**Verdict**: **NEEDS WORK** (but you can ship with fixes)

---

## CAREER ENDERS

### 1. Backup File Committed to Repo
**File**: `lib/prayer_original_backup.sh`
**Sin**: A 1529-line backup file is committed to the repository
**Evidence**:
```bash
$ find . -name "*backup*"
./lib/prayer_original_backup.sh
```
**Why it's bad**: This is 1529 lines of dead code sitting in your repo. Backup files in production codebases scream "I don't trust git" or "I was too scared to delete this." This bloats your repo, confuses onboarding devs, and is just lazy housekeeping.
**The Fix**: Delete it. Git is your backup. If you need historical reference, that's what `git log` and branches are for.

---

### 2. Eval Usage in install.sh
**File**: `install.sh:818`
**Sin**: Using `eval curl` with dynamically constructed auth headers
**Evidence**:
```bash
contents=$(eval curl -fsSL $auth_header "$api_url" 2>/dev/null)
```
**Why it's bad**: `eval` is the nuclear option of shell scripting. Combined with user-supplied `GITHUB_TOKEN`, this is a command injection waiting to happen. A malicious token value could execute arbitrary commands.
**The Fix**: Use arrays properly or pass the header as a separate variable without eval:
```bash
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    contents=$(curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$api_url" 2>/dev/null)
else
    contents=$(curl -fsSL "$api_url" 2>/dev/null)
fi
```

---

## EMBARRASSING MOMENTS

### 3. Massive God Files
**Files**: `lib/cache.sh` (1644 lines), `lib/prayer_original_backup.sh` (1529 lines)
**Sin**: Files that are way too long for a single responsibility
**Evidence**:
```bash
$ wc -l lib/*.sh | sort -rn | head -5
   1644 lib/cache.sh
   1529 lib/prayer_original_backup.sh
    857 lib/config.sh
    770 lib/cost.sh
    733 lib/display.sh
```
**Why it's bad**: `cache.sh` at 1644 lines is trying to be everything - configuration loading, XDG compliance, cache key generation, isolation modes, statistics, cleanup, and more. This violates Single Responsibility Principle harder than a junior dev's first PR. Your tests are probably a nightmare to write.
**The Fix**: Split `cache.sh` into:
- `cache/config.sh` - Configuration loading
- `cache/keys.sh` - Key generation and isolation
- `cache/operations.sh` - Read/write/cleanup
- `cache/statistics.sh` - Stats tracking

---

### 4. 364 Error Suppressions
**Sin**: Massive overuse of `2>/dev/null` and `|| true`
**Evidence**:
```bash
$ grep -rn "|| true\||| :\|2>/dev/null\|&>/dev/null" --include="*.sh" | wc -l
364
```
**Why it's bad**: Silencing errors is like putting tape over your check engine light. Some examples:
```bash
chmod -R u+w "$dir_path" 2>/dev/null || true
rm -rf "$CACHE_BASE_DIR"/*cache* 2>/dev/null || true
```
You're hiding potential failures that could leave your system in an inconsistent state.
**The Fix**: Be explicit about which errors you expect and handle them. Use proper error checking:
```bash
if ! chmod -R u+w "$dir_path" 2>/dev/null; then
    debug_log "Could not set permissions on $dir_path, continuing anyway" "WARN"
fi
```

---

### 5. 58 Skipped Tests
**Sin**: Tests marked as skip that may never get fixed
**Evidence**:
```bash
$ grep -rn "skip\|skip_if" tests/ --include="*.bats" | wc -l
58
```
**Why it's bad**: Skipped tests are technical debt wearing a mask. They're either:
- Tests for features that don't exist yet (delete them)
- Tests for broken code (fix the code)
- Tests that are flaky (fix them)
- Tests that require specific environments (document this)

With 273 total tests and 58 skips, that's ~21% of your test suite potentially hiding issues.
**The Fix**: Audit every skip. Either fix it, delete it, or document why it's skipped with an issue number.

---

### 6. No `set -e` in Most Files
**File**: Most `.sh` files except `install.sh`
**Sin**: Scripts don't fail fast on errors
**Evidence**:
```bash
$ grep -l "set -e\|set -o errexit" lib/*.sh
# (no results from lib/)
```
Only `install.sh` and a test file have `set -euo pipefail`.
**Why it's bad**: Without `set -e`, your scripts will happily continue executing after a command fails, potentially corrupting state or producing incorrect output.
**The Fix**: Add `set -euo pipefail` to the top of all executable scripts, or deliberately handle errors inline.

---

## EYE ROLL COLLECTION

### 7. Inconsistent Include Guards
**Files**: Various lib/*.sh files
**Sin**: Different patterns for preventing multiple includes
**Evidence**:
```bash
# Some files use:
[[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_LOADED=true

# Some use:
[[ "${STATUSLINE_SECURITY_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_SECURITY_LOADED=true
```
**Why it's bad**: It's not terrible, but the naming convention isn't standardized. You have `STATUSLINE_*_LOADED` which is fine, but no enforcement or documentation.
**The Fix**: Document the pattern, maybe create a helper macro.

---

### 8. Magic Numbers in Cache Durations
**File**: `lib/cache.sh:162-179`
**Sin**: Cache durations as magic numbers instead of named constants
**Evidence**:
```bash
export CACHE_DURATION_SESSION=0          # Session-wide
export CACHE_DURATION_PERMANENT=86400    # 24 hours
export CACHE_DURATION_CLAUDE_VERSION=900 # 15 minutes
export CACHE_DURATION_VERY_LONG=21600    # 6 hours
# ... etc
```
**Why it's bad**: Actually this is GOOD - you have named constants. But `86400` appearing inline elsewhere in the code would be bad. Keep consistent.
**The Fix**: Already handled well. Keep it up.

---

### 9. Hardcoded API Endpoint
**File**: `lib/prayer_original_backup.sh:33`
**Sin**: API endpoint hardcoded instead of configurable
**Evidence**:
```bash
export ALADHAN_API_BASE="https://api.aladhan.com/v1"
```
**Why it's bad**: Minor issue - if the API changes or you want to use a local proxy/mirror, you'd need to modify code.
**The Fix**: Make it configurable via TOML or environment variable with this as default.

---

### 10. Complex Function with Too Many Local Variables
**File**: `lib/cache.sh`
**Sin**: 118 local/declare variable declarations in one file
**Evidence**:
```bash
$ grep -rn "^\s*\(local\|declare\)\s\+[a-z_]*=" lib/cache.sh | wc -l
118
```
**Why it's bad**: This indicates functions are doing too much. A function with 10+ local variables is probably violating SRP.
**The Fix**: Break down complex functions into smaller, focused helpers.

---

### 11. Unused Debug Mode Checks
**Files**: Multiple files
**Sin**: Debug mode checks that might not be consistently used
**Evidence**:
```bash
if [[ "${STATUSLINE_DEBUG:-false}" != "true" ]]; then
    # ... hide something
fi
```
**Why it's bad**: The debug mode implementation is scattered. Some files use `STATUSLINE_DEBUG`, others use `STATUSLINE_DEBUG_MODE`.
**The Fix**: Standardize on one variable name and create a `is_debug_mode()` helper function.

---

### 12. IFS Manipulation Without Restoration
**File**: `lib/prayer/display.sh`
**Sin**: Multiple IFS reassignments that could affect subsequent commands
**Evidence**:
```bash
IFS=$'\t' read -r prayer_times prayer_statuses hijri_date current_time <<< "$prayer_data"
IFS=',' read -r fajr dhuhr asr maghrib isha <<< "$prayer_times"
# ... more IFS changes
```
**Why it's bad**: While `read` with IFS in the same line is safe (IFS only affects that command), having so many IFS-dependent operations in sequence is fragile and hard to debug.
**The Fix**: Consider using arrays or `cut`/`awk` for consistent parsing.

---

## THINGS DONE RIGHT (Credit Where Due)

1. **Security Module**: `lib/security.sh` is actually solid - path sanitization, injection prevention, cross-platform stat helpers
2. **Input Validation**: 114 sanitization/validation calls found
3. **Default Values**: 344 uses of `${var:-default}` pattern - good defensive coding
4. **Trap Handlers**: Proper cleanup traps in install.sh and cache.sh
5. **Include Guards**: Prevent double-sourcing of modules
6. **Atomic File Operations**: Using temp files + mv for atomic writes
7. **File Locking**: Proper locking for concurrent access in cache operations
8. **Cross-Platform Support**: BSD/GNU stat detection, platform-aware timeouts
9. **Comprehensive Test Suite**: 273 tests across unit, integration, and benchmark categories

---

## FINAL ROAST SCORE

| Category | Score | Notes |
|----------|-------|-------|
| Security | 7/10 | Solid security.sh, but `eval` in install.sh is a red flag |
| Scalability | 8/10 | Good caching, but god files need splitting |
| Code Quality | 6/10 | Backup file, 364 error suppressions, no `set -e` |
| Testing | 7/10 | 273 tests is respectable, but 58 skips need attention |
| Documentation | 8/10 | Good inline comments, CLAUDE.md is comprehensive |

**Overall**: 36/50

---

## ROASTER'S CLOSING STATEMENT

Bismillah, RECTOR. This codebase shows the work of someone who **knows what they're doing** but **got lazy in spots**. The security module is genuinely impressive - cross-platform stat handling, injection prevention, atomic writes. That's senior-level stuff.

BUT.

You have a 1529-line backup file sitting in your repo like a forgotten lunch in the office fridge. You have `eval curl` with user-supplied tokens. You have 364 places where you're silencing errors because "it works on my machine." You have 58 skipped tests that are basically IOUs to your future self.

The architecture is solid - modular design, TOML configuration, component-based statusline generation. But the execution got sloppy. The cache.sh file is trying to do everything and became a 1644-line monster.

**The Good News**: None of these are architectural issues. They're cleanup tasks. A weekend of focused work could knock out most of these:
1. Delete the backup file (5 minutes)
2. Fix the eval issue (10 minutes)
3. Audit and fix/remove skipped tests (2-4 hours)
4. Add proper error handling where you have `2>/dev/null` (ongoing)
5. Split cache.sh into smaller modules (2-3 hours)

Ship it after fixing the Career Enders. The rest can be addressed iteratively.

**Tawfeeq min Allah** - may your deploys be smooth and your logs be quiet.

---

*Roast generated with maximum brutality (--no-mercy mode) by CIPHER*
*"The best code review is an honest one"*
