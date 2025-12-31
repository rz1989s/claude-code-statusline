#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Integrity Module
# ============================================================================
#
# This module provides cache integrity features including SHA-256 checksums,
# corruption detection, error handling, and recovery mechanisms.
#
# Error Suppression Patterns (Issue #108):
# - mkdir -p 2>/dev/null: Creating fallback dirs (may already exist)
# - chmod 700 2>/dev/null: Best-effort secure permissions
# - rm -f 2>/dev/null: Removing corrupted/stale cache files (may not exist)
# - shasum/md5 2>/dev/null: Checksum tools may vary by platform
# - cat/read 2>/dev/null: File may be deleted by concurrent process
#
# All failures are reported via report_cache_error() with recovery suggestions.
#
# Dependencies: config.sh (for CACHE_CONFIG_*), validation.sh, security.sh (for get_file_mtime)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_INTEGRITY_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_INTEGRITY_LOADED=true

# ============================================================================
# ENHANCED ERROR HANDLING & RECOVERY SYSTEM
# ============================================================================

# Enhanced error reporting with actionable suggestions
report_cache_error() {
    local error_type="$1"
    local context="$2"
    local suggested_action="$3"
    local error_code="${4:-1}"

    local error_message="Cache Error ($error_type): $context"
    if [[ -n "$suggested_action" ]]; then
        error_message="$error_message | Suggestion: $suggested_action"
    fi

    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "$error_message" "ERROR"
    return "$error_code"
}

# Enhanced warning with recovery suggestions
report_cache_warning() {
    local warning_type="$1"
    local context="$2"
    local recovery_action="$3"

    local warning_message="Cache Warning ($warning_type): $context"
    if [[ -n "$recovery_action" ]]; then
        warning_message="$warning_message | Recovery: $recovery_action"
    fi

    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "$warning_message" "WARN"
}

# Intelligent cache directory recovery
recover_cache_directory() {
    local failed_dir="$1"
    local fallback_reason="$2"

    report_cache_warning "DIRECTORY_RECOVERY" \
        "Failed to use cache directory: $failed_dir" \
        "Attempting fallback directory selection"

    # Try alternative cache locations (Issue #110: XDG-compliant with TMPDIR)
    local temp_base="${TMPDIR:-/tmp}"
    local alternatives=(
        "${HOME:-}/.cache/claude-code-statusline-fallback"
        "${temp_base}/.claude_statusline_fallback_${USER:-$(id -u)}"
        "${temp_base}/.claude_statusline_emergency_$$"
    )

    for alt_dir in "${alternatives[@]}"; do
        # Note: mkdir stderr suppressed - expected to fail for some alternatives
        if [[ -n "$alt_dir" ]] && mkdir -p "$alt_dir" 2>/dev/null; then
            # Note: chmod stderr suppressed - non-fatal, directory still usable
            chmod 700 "$alt_dir" 2>/dev/null
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Successfully recovered using fallback directory: $alt_dir" "INFO"
            echo "$alt_dir"
            return 0
        fi
    done

    report_cache_error "DIRECTORY_RECOVERY_FAILED" \
        "All cache directory alternatives failed" \
        "Check filesystem permissions and available space" \
        2

    return 2
}

# Cache corruption detection and recovery
detect_and_recover_corruption() {
    local cache_file="$1"
    local operation_type="$2"

    if [[ ! -f "$cache_file" ]]; then
        return 0  # File doesn't exist, no corruption to detect
    fi

    # Basic corruption checks
    if [[ ! -r "$cache_file" ]]; then
        report_cache_warning "CORRUPTION_DETECTED" \
            "Cache file not readable: $(basename "$cache_file")" \
            "Removing corrupted file and regenerating cache"
        # Note: rm stderr suppressed - file may have been removed by another process
        rm -f "$cache_file" 2>/dev/null
        return 1
    fi

    # Check for empty or invalid files
    # Note: head stderr suppressed - file may be unreadable or removed between checks
    if [[ ! -s "$cache_file" ]] || [[ "$(head -c 1 "$cache_file" 2>/dev/null | wc -c)" -eq 0 ]]; then
        report_cache_warning "CORRUPTION_DETECTED" \
            "Cache file empty or invalid: $(basename "$cache_file")" \
            "Removing empty file and regenerating cache"
        rm -f "$cache_file" 2>/dev/null
        return 1
    fi

    # Check for null bytes or control characters (basic corruption detection)
    # Note: grep stderr suppressed - binary file warning expected for corrupted files
    if grep -q $'\\0\\|\\x1\\|\\x2\\|\\x3' "$cache_file" 2>/dev/null; then
        report_cache_warning "CORRUPTION_DETECTED" \
            "Cache file contains invalid characters: $(basename "$cache_file")" \
            "Removing corrupted file and regenerating cache"
        rm -f "$cache_file" 2>/dev/null
        return 1
    fi

    return 0  # File appears valid
}

# Intelligent lock recovery system
recover_stale_locks() {
    local lock_file="$1"
    local max_age_seconds="${2:-300}"  # 5 minutes default

    if [[ ! -f "$lock_file" ]]; then
        return 0  # No lock file to recover
    fi

    # Check lock age
    local lock_age
    if command -v stat >/dev/null 2>&1; then
        local lock_mtime=$(get_file_mtime "$lock_file")
        lock_age=$(( $(date +%s) - lock_mtime ))

        if [[ $lock_age -gt $max_age_seconds ]]; then
            report_cache_warning "STALE_LOCK_RECOVERY" \
                "Removing stale lock (age: ${lock_age}s): $(basename "$lock_file")" \
                "Lock was older than ${max_age_seconds}s threshold"
            # Note: rm stderr suppressed - lock may have been removed by another process
            rm -f "$lock_file" 2>/dev/null
            return 0
        fi
    fi

    # Check if lock process still exists
    if [[ -r "$lock_file" ]]; then
        local lock_content
        # Note: cat stderr suppressed - lock file may be removed/unreadable mid-check
        lock_content="$(cat "$lock_file" 2>/dev/null || echo "")"
        local lock_pid
        # Note: cut stderr suppressed - defensive against malformed lock content
        lock_pid="$(echo "$lock_content" | cut -d':' -f2 2>/dev/null || echo "")"

        if [[ -n "$lock_pid" ]] && [[ "$lock_pid" =~ ^[0-9]+$ ]]; then
            # Note: kill -0 stderr suppressed - expected to fail for non-existent processes
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                report_cache_warning "ORPHANED_LOCK_RECOVERY" \
                    "Removing orphaned lock (PID $lock_pid not found): $(basename "$lock_file")" \
                    "Process that created lock is no longer running"
                rm -f "$lock_file" 2>/dev/null
                return 0
            fi
        fi
    fi

    return 1  # Lock appears to be active
}

# ============================================================================
# ADVANCED CACHE CORRUPTION DETECTION WITH SHA-256 CHECKSUMS
# ============================================================================

# Generate SHA-256 checksum for cache content
generate_cache_checksum() {
    local content="$1"

    # Try different checksum tools in order of preference
    if command -v sha256sum >/dev/null 2>&1; then
        echo "$content" | sha256sum | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        echo "$content" | shasum -a 256 | cut -d' ' -f1
    elif command -v openssl >/dev/null 2>&1; then
        echo "$content" | openssl dgst -sha256 | cut -d' ' -f2
    elif command -v python3 >/dev/null 2>&1; then
        echo "$content" | python3 -c "import sys, hashlib; print(hashlib.sha256(sys.stdin.read().encode()).hexdigest())"
    else
        # Fallback: use a simple hash if no SHA-256 tools available
        echo "$content" | cksum | cut -d' ' -f1
    fi
}

# Write cache with checksum protection
write_cache_with_checksum() {
    local cache_file="$1"
    local content="$2"
    local temp_file="${cache_file}.tmp.$$"

    # Generate checksum for content
    local checksum
    checksum=$(generate_cache_checksum "$content")

    if [[ -z "$checksum" ]]; then
        report_cache_warning "CHECKSUM_GENERATION_FAILED" \
            "Failed to generate checksum for cache: $(basename "$cache_file")" \
            "Falling back to standard cache write without integrity protection"
        echo "$content" > "$cache_file" 2>/dev/null
        return $?
    fi

    # Write content with embedded checksum metadata
    {
        echo "# Cache Integrity Checksum: $checksum"
        echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "# Content:"
        echo "$content"
    } > "$temp_file" 2>/dev/null

    # Atomic move to final location
    if mv "$temp_file" "$cache_file" 2>/dev/null; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache written with checksum protection: $(basename "$cache_file")" "INFO"
        return 0
    else
        report_cache_error "CACHE_WRITE_FAILED" \
            "Failed to write protected cache file: $(basename "$cache_file")" \
            "Check filesystem permissions and available space"
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
}

# Read and validate cache with checksum verification
read_cache_with_checksum() {
    local cache_file="$1"
    local validate_checksum="${2:-true}"

    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    # Read cache file content
    local cache_content
    cache_content="$(cat "$cache_file" 2>/dev/null)" || return 1

    # Check if file has checksum metadata
    if [[ "$cache_content" =~ ^#\ Cache\ Integrity\ Checksum: ]]; then
        # Extract stored checksum
        local stored_checksum
        stored_checksum="$(echo "$cache_content" | head -1 | sed 's/^# Cache Integrity Checksum: //')"

        # Extract actual content (skip metadata lines)
        local actual_content
        actual_content="$(echo "$cache_content" | sed '/^# Cache Integrity Checksum:/d; /^# Generated:/d; /^# Content:/d')"

        # Validate checksum if requested and checksums are enabled
        if [[ "$validate_checksum" == "true" ]] && [[ "${CACHE_CONFIG_ENABLE_CHECKSUMS:-}" == "true" ]]; then
            local calculated_checksum
            calculated_checksum=$(generate_cache_checksum "$actual_content")

            if [[ -n "$calculated_checksum" ]] && [[ "$stored_checksum" != "$calculated_checksum" ]]; then
                report_cache_warning "CORRUPTION_DETECTED" \
                    "Checksum mismatch in cache file: $(basename "$cache_file")" \
                    "Expected: $stored_checksum, Got: $calculated_checksum - Removing corrupted cache"
                rm -f "$cache_file" 2>/dev/null
                return 1
            fi

            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache checksum validated successfully: $(basename "$cache_file")" "INFO"
        fi

        # Return actual content without metadata
        echo "$actual_content"
        return 0
    else
        # Legacy cache file without checksum - return as-is
        echo "$cache_content"
        return 0
    fi
}

# Enhanced cache validation with checksum support
validate_cache_with_checksum() {
    local cache_file="$1"
    local operation_type="${2:-generic}"

    # Basic file existence and readability check
    if [[ ! -f "$cache_file" ]] || [[ ! -r "$cache_file" ]]; then
        return 1
    fi

    # Use checksum validation if enabled
    if [[ "${CACHE_CONFIG_ENABLE_CHECKSUMS:-}" == "true" ]] && [[ "${CACHE_CONFIG_VALIDATE_ON_READ:-}" == "true" ]]; then
        local content
        if ! content="$(read_cache_with_checksum "$cache_file" "true")"; then
            return 1  # Checksum validation failed or file corrupted
        fi

        # Additional validation based on operation type
        case "$operation_type" in
            "git_branch")
                validate_git_branch_content "$content"
                ;;
            "json")
                validate_json_content "$content"
                ;;
            "command_output")
                validate_command_output_content "$content"
                ;;
            *)
                validate_basic_content "$content"
                ;;
        esac
    else
        # Fallback to basic validation
        validate_basic_cache "$cache_file"
    fi
}

# Migrate legacy cache files to checksum-protected format
migrate_to_checksum_cache() {
    local cache_file="$1"

    if [[ ! -f "$cache_file" ]]; then
        return 0
    fi

    # Check if already has checksum protection
    if head -1 "$cache_file" 2>/dev/null | grep -q "^# Cache Integrity Checksum:"; then
        return 0  # Already migrated
    fi

    # Read legacy content
    local legacy_content
    legacy_content="$(cat "$cache_file" 2>/dev/null)" || return 1

    # Write with checksum protection
    if write_cache_with_checksum "$cache_file" "$legacy_content"; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Migrated cache to checksum protection: $(basename "$cache_file")" "INFO"
        return 0
    else
        report_cache_warning "MIGRATION_FAILED" \
            "Failed to migrate cache to checksum protection: $(basename "$cache_file")" \
            "Cache will continue to work without checksum validation"
        return 1
    fi
}

# Comprehensive cache integrity audit
audit_cache_integrity() {
    local show_details="${1:-false}"

    if [[ ! -d "$CACHE_BASE_DIR" ]]; then
        echo "Cache directory not found: $CACHE_BASE_DIR"
        return 1
    fi

    echo "=== Cache Integrity Audit ==="
    echo "Cache Directory: $CACHE_BASE_DIR"
    echo "Checksum Protection: ${CACHE_CONFIG_ENABLE_CHECKSUMS:-disabled}"
    echo ""

    local total_files=0
    local protected_files=0
    local corrupted_files=0
    local migration_candidates=0

    while IFS= read -r -d '' cache_file; do
        [[ -f "$cache_file" ]] || continue
        total_files=$((total_files + 1))

        # Check if file has checksum protection
        if head -1 "$cache_file" 2>/dev/null | grep -q "^# Cache Integrity Checksum:"; then
            protected_files=$((protected_files + 1))

            # Validate checksum if enabled
            if [[ "${CACHE_CONFIG_ENABLE_CHECKSUMS:-}" == "true" ]]; then
                if ! read_cache_with_checksum "$cache_file" "true" >/dev/null 2>&1; then
                    corrupted_files=$((corrupted_files + 1))
                    [[ "$show_details" == "true" ]] && echo "  CORRUPTED: $(basename "$cache_file")"
                fi
            fi
        else
            migration_candidates=$((migration_candidates + 1))
            [[ "$show_details" == "true" ]] && echo "  LEGACY: $(basename "$cache_file")"
        fi
    done < <(find "$CACHE_BASE_DIR" -name "*.cache" -o -name "*_*" -type f -print0 2>/dev/null)

    echo "Audit Results:"
    echo "  Total Cache Files: $total_files"
    echo "  Checksum Protected: $protected_files"
    echo "  Legacy Files: $migration_candidates"
    echo "  Corrupted Files: $corrupted_files"

    if [[ $migration_candidates -gt 0 ]]; then
        echo ""
        echo "  Recommendation: Run cache migration to add checksum protection"
        echo "  Command: ./statusline.sh --migrate-cache-checksums"
    fi

    if [[ $corrupted_files -gt 0 ]]; then
        echo ""
        echo "  Warning: $corrupted_files corrupted cache files detected"
        echo "  Recommendation: Clear corrupted files with --clear-corrupted-cache"
    fi

    echo ""
}

# Export functions
export -f report_cache_error report_cache_warning recover_cache_directory
export -f detect_and_recover_corruption recover_stale_locks
export -f generate_cache_checksum write_cache_with_checksum read_cache_with_checksum
export -f validate_cache_with_checksum migrate_to_checksum_cache audit_cache_integrity
