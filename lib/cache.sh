#!/bin/bash

# ============================================================================
# Claude Code Statusline - Universal Intelligent Caching Module
# ============================================================================
# 
# This module provides a comprehensive caching system for ALL external 
# operations including command existence checks, git operations, system info,
# and external command outputs. Features multi-instance safety, intelligent
# duration-based caching, and automatic validation.
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_LOADED=true

# ============================================================================
# CACHE CONFIGURATION CONSTANTS
# ============================================================================

# Base cache directory
export CACHE_BASE_DIR="/tmp/.claude_statusline_cache"

# Cache duration constants (in seconds)
export CACHE_DURATION_SESSION=0          # Session-wide (never expires during session)
export CACHE_DURATION_PERMANENT=86400    # 24 hours (system info that never changes)
export CACHE_DURATION_VERY_LONG=21600    # 6 hours (claude --version)
export CACHE_DURATION_LONG=3600          # 1 hour (git config, version files)
export CACHE_DURATION_MEDIUM=300         # 5 minutes (git submodules, directory info)
export CACHE_DURATION_SHORT=30           # 30 seconds (git repo check, branches)
export CACHE_DURATION_VERY_SHORT=10      # 10 seconds (git status, current branch)
export CACHE_DURATION_REALTIME=5         # 5 seconds (current directory, file status)
export CACHE_DURATION_LIVE=2             # 2 seconds (for high-frequency operations)

# Instance-specific cache management
export CACHE_INSTANCE_ID="${CACHE_INSTANCE_ID:-${CLAUDE_INSTANCE_ID:-${PPID:-$$}}}"
export CACHE_SESSION_MARKER="/tmp/.cache_session_${CACHE_INSTANCE_ID}"

# ============================================================================
# CACHE FILE MANAGEMENT
# ============================================================================

# Initialize cache directory structure
init_cache_directory() {
    if [[ ! -d "$CACHE_BASE_DIR" ]]; then
        mkdir -p "$CACHE_BASE_DIR" 2>/dev/null
        chmod 700 "$CACHE_BASE_DIR" 2>/dev/null
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Created universal cache directory: $CACHE_BASE_DIR" "INFO"
    fi
}

# Get cache file path for a specific operation
get_cache_file_path() {
    local cache_key="$1"
    local instance_specific="${2:-true}"
    
    init_cache_directory
    
    if [[ "$instance_specific" == "true" ]]; then
        echo "$CACHE_BASE_DIR/${cache_key}_${CACHE_INSTANCE_ID}.cache"
    else
        # Shared cache (for system info that's the same across instances)
        echo "$CACHE_BASE_DIR/${cache_key}_shared.cache"
    fi
}

# Clean up old cache files and orphaned session markers
cleanup_cache_files() {
    # Remove cache files older than 24 hours
    find "$CACHE_BASE_DIR" -name "*.cache" -mtime +1 -delete 2>/dev/null || true
    
    # Remove orphaned session markers (where process no longer exists)
    for marker in /tmp/.cache_session_*; do
        [[ -f "$marker" ]] || continue
        
        local marker_pid="${marker##*_}"
        if [[ "$marker_pid" =~ ^[0-9]+$ ]] && ! kill -0 "$marker_pid" 2>/dev/null; then
            rm -f "$marker" 2>/dev/null
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Removed orphaned cache session marker: $marker_pid" "INFO"
        fi
    done
}

# ============================================================================
# STARTUP DETECTION AND SESSION MANAGEMENT
# ============================================================================

# Check if this is the first startup for this instance
is_first_startup() {
    local session_marker="$CACHE_SESSION_MARKER"
    
    if [[ ! -f "$session_marker" ]]; then
        # Create session marker
        echo "$(date '+%Y-%m-%d %H:%M:%S') Cache Instance: $CACHE_INSTANCE_ID PID: $PPID" > "$session_marker" 2>/dev/null
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "First startup detected for cache instance $CACHE_INSTANCE_ID" "INFO"
        return 0
    else
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Subsequent call for cache instance $CACHE_INSTANCE_ID" "INFO"
        return 1
    fi
}

# Force refresh for first startup
should_force_refresh() {
    local force_refresh="${1:-false}"
    
    if [[ "$force_refresh" == "true" ]]; then
        return 0
    fi
    
    # Force refresh on first startup
    is_first_startup
}

# ============================================================================
# CACHE VALIDATION FUNCTIONS  
# ============================================================================

# Generic cache validation (non-empty file)
validate_basic_cache() {
    local cache_file="$1"
    [[ -f "$cache_file" && -s "$cache_file" ]]
}

# JSON cache validation
validate_json_cache() {
    local cache_file="$1"
    
    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi
    
    if command_exists jq; then
        jq empty "$cache_file" 2>/dev/null
    else
        # Basic JSON syntax check
        [[ "$(head -c1 "$cache_file")" =~ ^[\{\[] ]]
    fi
}

# Command output validation (exit code based)
validate_command_output() {
    local cache_file="$1"
    local expected_pattern="${2:-.*}"
    
    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi
    
    # Check if content matches expected pattern
    grep -q "$expected_pattern" "$cache_file" 2>/dev/null
}

# Git output validation
validate_git_cache() {
    local cache_file="$1"
    local git_operation="${2:-status}"
    
    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi
    
    case "$git_operation" in
        "branch")
            # Branch names should not contain invalid characters
            [[ "$(cat "$cache_file")" =~ ^[a-zA-Z0-9/_-]+$ ]]
            ;;
        "status")
            # Status should be clean, dirty, or not_git
            grep -qE "^(clean|dirty|not_git)$" "$cache_file" 2>/dev/null
            ;;
        "config")
            # Config values can be anything, just check non-empty
            validate_basic_cache "$cache_file"
            ;;
        *)
            validate_basic_cache "$cache_file"
            ;;
    esac
}

# System info validation (should never change)
validate_system_cache() {
    local cache_file="$1"
    validate_basic_cache "$cache_file"
}

# ============================================================================
# ENHANCED LOCKING SYSTEM
# ============================================================================

# Acquire cache lock with retry logic
acquire_cache_lock() {
    local cache_file="$1"
    local max_retries="${2:-3}"
    local lock_file="${cache_file}.lock"
    
    cleanup_stale_locks "$lock_file"
    
    local retry_count=0
    while [[ $retry_count -lt $max_retries ]]; do
        # Try to acquire lock atomically
        if (
            set -C
            echo "$CACHE_INSTANCE_ID:$$:$(date +%s)" >"$lock_file" 2>/dev/null
        ); then
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Acquired cache lock: $(basename "$cache_file")" "INFO"
            return 0
        else
            retry_count=$((retry_count + 1))
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache lock attempt $retry_count/$max_retries failed: $(basename "$cache_file")" "INFO"
            
            # Random backoff to prevent thundering herd
            sleep "0.$(( (RANDOM % 5) + 1 ))"
        fi
    done
    
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Failed to acquire cache lock after $max_retries attempts: $(basename "$cache_file")" "WARN"
    return 1
}

# Release cache lock
release_cache_lock() {
    local cache_file="$1"
    local lock_file="${cache_file}.lock"
    rm -f "$lock_file" 2>/dev/null
}

# ============================================================================
# UNIVERSAL COMMAND CACHING FUNCTION
# ============================================================================

# Execute command with intelligent caching
execute_cached_command() {
    local cache_key="$1"
    local cache_duration="$2"
    local validator_func="${3:-validate_basic_cache}"
    local instance_specific="${4:-true}"
    local force_refresh="${5:-false}"
    shift 5
    local command=("$@")
    
    local cache_file
    cache_file=$(get_cache_file_path "$cache_key" "$instance_specific")
    
    # Cleanup old cache files periodically
    cleanup_cache_files
    
    # Check if we should force refresh (first startup)
    if should_force_refresh "$force_refresh"; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Force refresh triggered for cache: $cache_key" "INFO"
    else
        # Check if cache is fresh and valid
        if is_cache_fresh "$cache_file" "$cache_duration" && "$validator_func" "$cache_file"; then
            cat "$cache_file" 2>/dev/null
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using cached result: $cache_key" "INFO"
            return 0
        fi
    fi
    
    # Acquire lock for cache update
    if acquire_cache_lock "$cache_file"; then
        local temp_file="${cache_file}.tmp.$$"
        local command_output
        
        # Execute the command
        if command_output=$("${command[@]}" 2>/dev/null); then
            # Atomic write to cache
            if echo "$command_output" > "$temp_file" 2>/dev/null && mv "$temp_file" "$cache_file" 2>/dev/null; then
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cached fresh result: $cache_key" "INFO"
                echo "$command_output"
                release_cache_lock "$cache_file"
                return 0
            else
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Failed to write cache file: $cache_key" "WARN"
                rm -f "$temp_file" 2>/dev/null
                echo "$command_output"
                release_cache_lock "$cache_file"
                return 0
            fi
        else
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Command execution failed: $cache_key" "WARN"
            
            # Use stale cache if available and valid
            if "$validator_func" "$cache_file"; then
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using stale cache due to command failure: $cache_key" "INFO"
                cat "$cache_file" 2>/dev/null
                release_cache_lock "$cache_file"
                return 1
            fi
            
            release_cache_lock "$cache_file"
            return 1
        fi
    else
        # Lock acquisition failed, try to use existing cache
        if "$validator_func" "$cache_file"; then
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using existing cache while other instance updates: $cache_key" "INFO"
            cat "$cache_file" 2>/dev/null
            return 0
        fi
        
        # No cache available and no lock - execute directly
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Direct execution due to lock failure: $cache_key" "INFO"
        "${command[@]}" 2>/dev/null
        return $?
    fi
}

# ============================================================================
# SPECIALIZED CACHING FUNCTIONS
# ============================================================================

# Cache command existence checks (session-wide)
cache_command_exists() {
    local command_name="$1"
    
    execute_cached_command \
        "cmd_exists_${command_name}" \
        "$CACHE_DURATION_SESSION" \
        "validate_basic_cache" \
        "true" \
        "false" \
        bash -c "command -v '$command_name' >/dev/null 2>&1 && echo 'true' || echo 'false'"
}

# Cache system information (permanent)
cache_system_info() {
    local info_type="$1"
    
    case "$info_type" in
        "os")
            execute_cached_command \
                "system_os" \
                "$CACHE_DURATION_PERMANENT" \
                "validate_system_cache" \
                "false" \
                "false" \
                uname -s
            ;;
        "arch")
            execute_cached_command \
                "system_arch" \
                "$CACHE_DURATION_PERMANENT" \
                "validate_system_cache" \
                "false" \
                "false" \
                uname -m
            ;;
        *)
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Unknown system info type: $info_type" "WARN"
            return 1
            ;;
    esac
}

# Cache git operations with appropriate durations
cache_git_operation() {
    local git_operation="$1"
    local cache_duration="$2"
    shift 2
    local git_command=("$@")
    
    execute_cached_command \
        "git_${git_operation}" \
        "$cache_duration" \
        "validate_git_cache" \
        "true" \
        "false" \
        "${git_command[@]}"
}

# Cache external command outputs
cache_external_command() {
    local command_name="$1"
    local cache_duration="$2"
    local validator_func="${3:-validate_command_output}"
    shift 3
    local command=("$@")
    
    execute_cached_command \
        "external_${command_name}" \
        "$cache_duration" \
        "$validator_func" \
        "true" \
        "false" \
        "${command[@]}"
}

# ============================================================================
# CACHE MANAGEMENT UTILITIES
# ============================================================================

# Clear all cache files
clear_all_cache() {
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        rm -rf "$CACHE_BASE_DIR"/*cache* 2>/dev/null || true
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleared all cache files" "INFO"
    fi
}

# Clear cache for specific instance
clear_instance_cache() {
    local instance_id="${1:-$CACHE_INSTANCE_ID}"
    
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        rm -f "$CACHE_BASE_DIR"/*"_${instance_id}.cache" 2>/dev/null || true
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleared cache for instance: $instance_id" "INFO"
    fi
}

# Show cache statistics
show_cache_stats() {
    if [[ ! -d "$CACHE_BASE_DIR" ]]; then
        echo "Cache directory not found"
        return
    fi
    
    echo "Cache Statistics:"
    echo "=================="
    echo "Cache directory: $CACHE_BASE_DIR"
    echo "Instance ID: $CACHE_INSTANCE_ID"
    echo "Total cache files: $(find "$CACHE_BASE_DIR" -name "*.cache" 2>/dev/null | wc -l)"
    echo "Instance cache files: $(find "$CACHE_BASE_DIR" -name "*_${CACHE_INSTANCE_ID}.cache" 2>/dev/null | wc -l)"
    echo "Shared cache files: $(find "$CACHE_BASE_DIR" -name "*_shared.cache" 2>/dev/null | wc -l)"
    echo ""
    echo "Cache files:"
    ls -la "$CACHE_BASE_DIR"/*.cache 2>/dev/null | head -10 || echo "No cache files found"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the cache module
init_cache_module() {
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Universal cache module initialized" "INFO"
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache instance ID: $CACHE_INSTANCE_ID" "INFO"
    
    init_cache_directory
    cleanup_cache_files
    
    # Set up cleanup on exit
    trap 'cleanup_cache_files' EXIT
    
    return 0
}

# Initialize the module
init_cache_module

# ============================================================================
# EXPORTS
# ============================================================================

# Export cache functions for use by other modules
export -f execute_cached_command cache_command_exists cache_system_info
export -f cache_git_operation cache_external_command
export -f get_cache_file_path acquire_cache_lock release_cache_lock
export -f validate_basic_cache validate_json_cache validate_command_output
export -f validate_git_cache validate_system_cache
export -f clear_all_cache clear_instance_cache show_cache_stats
export -f init_cache_directory cleanup_cache_files is_first_startup