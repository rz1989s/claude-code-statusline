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

# ============================================================================
# TOML CONFIGURATION INTEGRATION
# ============================================================================

# Load cache configuration from TOML with intelligent defaults
load_cache_configuration() {
    # Initialize cache configuration variables with defaults
    export CACHE_CONFIG_ENABLE_UNIVERSAL=${ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING:-"true"}
    export CACHE_CONFIG_ENABLE_STATISTICS=${ENV_CONFIG_CACHE_ENABLE_STATISTICS:-"true"}
    export CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION=${ENV_CONFIG_CACHE_ENABLE_CORRUPTION_DETECTION:-"true"}
    export CACHE_CONFIG_CLEANUP_STALE=${ENV_CONFIG_CACHE_CLEANUP_STALE_FILES:-"true"}
    export CACHE_CONFIG_MIGRATE_LEGACY=${ENV_CONFIG_CACHE_MIGRATE_LEGACY_CACHE:-"true"}
    
    # Performance configuration
    export CACHE_CONFIG_MAX_LOCK_RETRIES=${ENV_CONFIG_CACHE_PERFORMANCE_MAX_LOCK_RETRIES:-10}
    export CACHE_CONFIG_LOCK_RETRY_DELAY=${ENV_CONFIG_CACHE_PERFORMANCE_LOCK_RETRY_DELAY_MS:-"100-500"}
    export CACHE_CONFIG_ATOMIC_TIMEOUT=${ENV_CONFIG_CACHE_PERFORMANCE_ATOMIC_WRITE_TIMEOUT:-10}
    export CACHE_CONFIG_CLEANUP_INTERVAL=${ENV_CONFIG_CACHE_PERFORMANCE_CACHE_CLEANUP_INTERVAL:-300}
    export CACHE_CONFIG_MAX_AGE_HOURS=${ENV_CONFIG_CACHE_PERFORMANCE_MAX_CACHE_AGE_HOURS:-168}
    
    # Security configuration
    export CACHE_CONFIG_DIR_PERMISSIONS=${ENV_CONFIG_CACHE_SECURITY_DIRECTORY_PERMISSIONS:-"700"}
    export CACHE_CONFIG_FILE_PERMISSIONS=${ENV_CONFIG_CACHE_SECURITY_FILE_PERMISSIONS:-"600"}
    export CACHE_CONFIG_ENABLE_CHECKSUMS=${ENV_CONFIG_CACHE_SECURITY_ENABLE_CHECKSUMS:-"true"}
    export CACHE_CONFIG_VALIDATE_ON_READ=${ENV_CONFIG_CACHE_SECURITY_VALIDATE_ON_READ:-"true"}
    
    # Instance isolation configuration
    export CACHE_CONFIG_ISOLATION_MODE=${ENV_CONFIG_CACHE_ISOLATION_MODE:-"repository"}
    export CACHE_CONFIG_MCP_ISOLATION=${ENV_CONFIG_CACHE_MCP_ISOLATION:-"repository"}
    export CACHE_CONFIG_GIT_ISOLATION=${ENV_CONFIG_CACHE_GIT_ISOLATION:-"repository"}
    export CACHE_CONFIG_COST_ISOLATION=${ENV_CONFIG_CACHE_COST_ISOLATION:-"shared"}
    export CACHE_CONFIG_SESSION_ISOLATION=${ENV_CONFIG_CACHE_SESSION_ISOLATION:-"repository"}
    
    # Load TOML configuration if available and no environment overrides
    if [[ "${STATUSLINE_CONFIG_LOADED:-}" == "true" ]] && command -v jq >/dev/null 2>&1; then
        local toml_data="${STATUSLINE_TOML_DATA:-}"
        
        if [[ -n "$toml_data" ]]; then
            # Parse cache configuration from TOML
            local cache_config
            cache_config=$(echo "$toml_data" | jq -r '.cache // {}' 2>/dev/null)
            
            if [[ "$cache_config" != "null" && "$cache_config" != "{}" ]]; then
                # Load basic cache settings
                [[ -z "${ENV_CONFIG_CACHE_ENABLE_UNIVERSAL_CACHING:-}" ]] && \
                    CACHE_CONFIG_ENABLE_UNIVERSAL=$(echo "$cache_config" | jq -r '.enable_universal_caching // true')
                [[ -z "${ENV_CONFIG_CACHE_ENABLE_STATISTICS:-}" ]] && \
                    CACHE_CONFIG_ENABLE_STATISTICS=$(echo "$cache_config" | jq -r '.enable_statistics // true')
                [[ -z "${ENV_CONFIG_CACHE_ENABLE_CORRUPTION_DETECTION:-}" ]] && \
                    CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION=$(echo "$cache_config" | jq -r '.enable_corruption_detection // true')
                    
                # Load performance settings
                local perf_config
                perf_config=$(echo "$cache_config" | jq -r '.performance // {}' 2>/dev/null)
                if [[ "$perf_config" != "null" && "$perf_config" != "{}" ]]; then
                    [[ -z "${ENV_CONFIG_CACHE_PERFORMANCE_MAX_LOCK_RETRIES:-}" ]] && \
                        CACHE_CONFIG_MAX_LOCK_RETRIES=$(echo "$perf_config" | jq -r '.max_lock_retries // 10')
                    [[ -z "${ENV_CONFIG_CACHE_PERFORMANCE_ATOMIC_WRITE_TIMEOUT:-}" ]] && \
                        CACHE_CONFIG_ATOMIC_TIMEOUT=$(echo "$perf_config" | jq -r '.atomic_write_timeout // 10')
                fi
                
                # Load security settings
                local sec_config
                sec_config=$(echo "$cache_config" | jq -r '.security // {}' 2>/dev/null)
                if [[ "$sec_config" != "null" && "$sec_config" != "{}" ]]; then
                    [[ -z "${ENV_CONFIG_CACHE_SECURITY_ENABLE_CHECKSUMS:-}" ]] && \
                        CACHE_CONFIG_ENABLE_CHECKSUMS=$(echo "$sec_config" | jq -r '.enable_checksums // true')
                    [[ -z "${ENV_CONFIG_CACHE_SECURITY_VALIDATE_ON_READ:-}" ]] && \
                        CACHE_CONFIG_VALIDATE_ON_READ=$(echo "$sec_config" | jq -r '.validate_on_read // true')
                fi
                
                # Load isolation settings
                local isolation_config
                isolation_config=$(echo "$cache_config" | jq -r '.isolation // {}' 2>/dev/null)
                if [[ "$isolation_config" != "null" && "$isolation_config" != "{}" ]]; then
                    [[ -z "${ENV_CONFIG_CACHE_ISOLATION_MODE:-}" ]] && \
                        CACHE_CONFIG_ISOLATION_MODE=$(echo "$isolation_config" | jq -r '.mode // "repository"')
                    [[ -z "${ENV_CONFIG_CACHE_MCP_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_MCP_ISOLATION=$(echo "$isolation_config" | jq -r '.mcp // "repository"')
                    [[ -z "${ENV_CONFIG_CACHE_GIT_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_GIT_ISOLATION=$(echo "$isolation_config" | jq -r '.git // "repository"')
                    [[ -z "${ENV_CONFIG_CACHE_COST_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_COST_ISOLATION=$(echo "$isolation_config" | jq -r '.cost // "shared"')
                    [[ -z "${ENV_CONFIG_CACHE_SESSION_ISOLATION:-}" ]] && \
                        CACHE_CONFIG_SESSION_ISOLATION=$(echo "$isolation_config" | jq -r '.session // "repository"')
                fi
                
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Loaded cache configuration from TOML" "INFO"
            fi
        fi
    fi
    
    # Convert string booleans to bash-compatible format
    [[ "$CACHE_CONFIG_ENABLE_UNIVERSAL" == "false" ]] && CACHE_CONFIG_ENABLE_UNIVERSAL=""
    [[ "$CACHE_CONFIG_ENABLE_STATISTICS" == "false" ]] && CACHE_CONFIG_ENABLE_STATISTICS=""
    [[ "$CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION" == "false" ]] && CACHE_CONFIG_ENABLE_CORRUPTION_DETECTION=""
    [[ "$CACHE_CONFIG_ENABLE_CHECKSUMS" == "false" ]] && CACHE_CONFIG_ENABLE_CHECKSUMS=""
    [[ "$CACHE_CONFIG_VALIDATE_ON_READ" == "false" ]] && CACHE_CONFIG_VALIDATE_ON_READ=""
    
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache configuration loaded and applied" "INFO"
}

# ============================================================================
# XDG-COMPLIANT CACHE DIRECTORY CONFIGURATION  
# ============================================================================

# Determine XDG-compliant cache directory with intelligent fallback
# Priority: CLAUDE_CACHE_DIR -> XDG_CACHE_HOME -> HOME/.cache -> /tmp (secure fallback)
determine_cache_base_dir() {
    local cache_dir=""
    
    # Priority 1: User-specified cache directory
    if [[ -n "${CLAUDE_CACHE_DIR:-}" ]]; then
        cache_dir="$CLAUDE_CACHE_DIR"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using CLAUDE_CACHE_DIR: $cache_dir" "INFO"
    # Priority 2: XDG Base Directory specification
    elif [[ -n "${XDG_CACHE_HOME:-}" ]]; then
        cache_dir="$XDG_CACHE_HOME/claude-code-statusline"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using XDG_CACHE_HOME: $cache_dir" "INFO"
    # Priority 3: Standard user cache directory
    elif [[ -n "${HOME:-}" ]] && [[ -w "${HOME:-}" ]]; then
        cache_dir="$HOME/.cache/claude-code-statusline"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using HOME/.cache: $cache_dir" "INFO"
    # Priority 4: Secure fallback to /tmp with user isolation
    else
        cache_dir="/tmp/.claude_statusline_cache_${USER:-$(id -u)}"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using secure /tmp fallback: $cache_dir" "WARN"
    fi
    
    echo "$cache_dir"
}

# Load configuration before initializing cache system
load_cache_configuration

# Initialize cache directory with migration support  
CACHE_BASE_DIR="$(determine_cache_base_dir)"
export CACHE_BASE_DIR

# Cache duration constants (in seconds)
export CACHE_DURATION_SESSION=0          # Session-wide (never expires during session)
export CACHE_DURATION_PERMANENT=86400    # 24 hours (system info that never changes)
export CACHE_DURATION_CLAUDE_VERSION=900 # 15 minutes (claude --version) - detect updates quickly
export CACHE_DURATION_VERY_LONG=21600    # 6 hours (other long-term caches)
export CACHE_DURATION_LONG=3600          # 1 hour (git config, version files)
export CACHE_DURATION_MEDIUM=300         # 5 minutes (git submodules, directory info)
export CACHE_DURATION_SHORT=30           # 30 seconds (git repo check, branches)
export CACHE_DURATION_VERY_SHORT=10      # 10 seconds (git status, current branch)
export CACHE_DURATION_REALTIME=5         # 5 seconds (current directory, file status)
export CACHE_DURATION_LIVE=2             # 2 seconds (for high-frequency operations)

# Prayer & Location System Cache Durations (travel-friendly)
# These durations are optimized for travelers who may cross timezones/countries quickly
export CACHE_DURATION_PRAYER_TIMES=3600      # 1 hour - prayer times refresh for travelers
export CACHE_DURATION_PRAYER_LOCATION=1800   # 30 minutes - location display refresh
export CACHE_DURATION_PRAYER_CALCULATION=3600 # 1 hour - calculation method changes by country

# ============================================================================
# UNIFIED CACHE KEY GENERATION
# ============================================================================

# Get repository identifier for cache isolation
get_repo_identifier() {
    local repo_path="${1:-$PWD}"
    local hash_method="${2:-path}"
    
    # Validate path length - switch to hash method for extremely long paths
    if [[ ${#repo_path} -gt 200 ]]; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && \
            debug_log "Repository path too long (${#repo_path} chars), using hash method" "INFO"
        hash_method="hash"
    fi
    
    case "$hash_method" in
        "hash")
            # Use SHA-256 hash for shorter keys
            echo "$repo_path" | sha256sum 2>/dev/null | cut -d' ' -f1 | cut -c1-8
            ;;
        "path"|*)
            # Use sanitized path with safer delimiter to prevent collisions
            # Double underscore reduces collision risk between paths like:
            # /home/user_project vs /home/user/project
            echo "${repo_path//\//__}"
            ;;
    esac
}

# Generate instance-aware cache key with configurable isolation
generate_instance_cache_key() {
    local base_key="$1"
    local isolation_mode="${2:-$CACHE_CONFIG_ISOLATION_MODE}"
    local repo_path="${3:-$PWD}"
    
    # Validate isolation mode
    case "$isolation_mode" in
        "repository")
            local repo_id
            repo_id=$(get_repo_identifier "$repo_path" "path")
            echo "${base_key}_${repo_id}"
            ;;
        "instance")
            echo "${base_key}_${CACHE_INSTANCE_ID}"
            ;;
        "shared")
            echo "$base_key"
            ;;
        *)
            # Default to repository isolation for safety
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && \
                debug_log "Unknown isolation mode '$isolation_mode', defaulting to repository" "WARN"
            local repo_id
            repo_id=$(get_repo_identifier "$repo_path" "path")
            echo "${base_key}_${repo_id}"
            ;;
    esac
}

# Generate cache key for specific data types with their configured isolation
generate_typed_cache_key() {
    local base_key="$1"
    local data_type="$2"  # mcp, git, cost, session
    local repo_path="${3:-$PWD}"
    
    local isolation_mode
    case "$data_type" in
        "mcp")
            isolation_mode="$CACHE_CONFIG_MCP_ISOLATION"
            ;;
        "git")
            isolation_mode="$CACHE_CONFIG_GIT_ISOLATION"
            ;;
        "cost")
            isolation_mode="$CACHE_CONFIG_COST_ISOLATION"
            ;;
        "session")
            isolation_mode="$CACHE_CONFIG_SESSION_ISOLATION"
            ;;
        *)
            isolation_mode="$CACHE_CONFIG_ISOLATION_MODE"
            ;;
    esac
    
    generate_instance_cache_key "$base_key" "$isolation_mode" "$repo_path"
}

# Instance-specific cache management with XDG compliance
# Use a more stable session identifier for better cache sharing across statusline calls
export CACHE_INSTANCE_ID="${CACHE_INSTANCE_ID:-${CLAUDE_INSTANCE_ID:-${USER}_claude_statusline}}"

# Update session marker location to be more secure
if [[ "$CACHE_BASE_DIR" =~ ^/tmp ]]; then
    export CACHE_SESSION_MARKER="/tmp/.cache_session_${CACHE_INSTANCE_ID}"
else
    export CACHE_SESSION_MARKER="${CACHE_BASE_DIR}/.session_${CACHE_INSTANCE_ID}"
fi

# Legacy cache directory for migration
export LEGACY_CACHE_DIR="/tmp/.claude_statusline_cache"

# ============================================================================
# CACHE FILE MANAGEMENT
# ============================================================================

# Migrate cache files from legacy location to XDG-compliant location
migrate_legacy_cache() {
    local legacy_dir="$LEGACY_CACHE_DIR"
    local new_dir="$CACHE_BASE_DIR"
    
    # Skip migration if legacy directory doesn't exist or is the same as new directory
    if [[ ! -d "$legacy_dir" ]] || [[ "$legacy_dir" == "$new_dir" ]]; then
        return 0
    fi
    
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Migrating cache from $legacy_dir to $new_dir" "INFO"
    
    # Create new directory structure
    if ! mkdir -p "$new_dir" 2>/dev/null; then
        report_cache_error "MIGRATION_FAILED" \
            "Failed to create new cache directory: $new_dir" \
            "Check directory permissions and available space"
        return 1
    fi
    
    # Set proper permissions
    chmod 700 "$new_dir" 2>/dev/null
    
    # Migrate valid cache files with integrity verification
    local migrated_count=0
    local failed_count=0
    
    for cache_file in "$legacy_dir"/*; do
        [[ ! -f "$cache_file" ]] && continue
        
        local basename_file
        basename_file="$(basename "$cache_file")"
        local new_file="$new_dir/$basename_file"
        
        # Skip session markers and lock files
        [[ "$basename_file" =~ \.(lock|tmp\.) ]] && continue
        [[ "$basename_file" =~ ^\. ]] && continue
        
        # Verify cache file is readable and has content
        if [[ -r "$cache_file" ]] && [[ -s "$cache_file" ]]; then
            # Atomic migration with verification
            if cp "$cache_file" "$new_file.migrating" 2>/dev/null && 
               mv "$new_file.migrating" "$new_file" 2>/dev/null; then
                migrated_count=$((migrated_count + 1))
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Migrated cache file: $basename_file" "INFO"
            else
                failed_count=$((failed_count + 1))
                rm -f "$new_file.migrating" 2>/dev/null
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Failed to migrate: $basename_file" "WARN"
            fi
        fi
    done
    
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Migration completed: $migrated_count files migrated, $failed_count failed" "INFO"
    
    # Clean up legacy directory if migration was successful and we migrated files
    if [[ $failed_count -eq 0 ]] && [[ $migrated_count -gt 0 ]]; then
        # Only remove non-session files to avoid interfering with other instances
        find "$legacy_dir" -type f ! -name '.*session*' ! -name '*.lock' -delete 2>/dev/null
        # Try to remove directory if empty (will fail gracefully if not empty)
        rmdir "$legacy_dir" 2>/dev/null && 
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleaned up legacy cache directory" "INFO"
    fi
    
    return 0
}

# Initialize cache directory structure with migration support
init_cache_directory() {
    # Perform migration from legacy location if needed
    migrate_legacy_cache
    
    if [[ ! -d "$CACHE_BASE_DIR" ]]; then
        if mkdir -p "$CACHE_BASE_DIR" 2>/dev/null; then
            chmod 700 "$CACHE_BASE_DIR" 2>/dev/null
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Created XDG-compliant cache directory: $CACHE_BASE_DIR" "INFO"
        else
            # Attempt directory recovery
            local recovered_dir
            recovered_dir="$(recover_cache_directory "$CACHE_BASE_DIR" "primary directory creation failed")"
            if [[ -n "$recovered_dir" ]]; then
                CACHE_BASE_DIR="$recovered_dir"
                export CACHE_BASE_DIR
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache directory recovered: $CACHE_BASE_DIR" "INFO"
            else
                report_cache_error "DIRECTORY_CREATION_FAILED" \
                    "Failed to create any cache directory" \
                    "Check filesystem permissions, available space, and user access rights"
                return 1
            fi
        fi
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
            # Enhanced branch name validation using Git's own validation rules
            # Supports Unicode, emojis, and all valid Git branch naming conventions
            validate_git_branch_name "$cache_file"
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

# Enhanced Git branch name validation using Git's own validation rules
validate_git_branch_name() {
    local cache_file="$1"
    
    # First perform basic cache validation
    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi
    
    local branch_name
    branch_name="$(cat "$cache_file" 2>/dev/null)"
    
    # Handle empty branch names (can happen during git operations)
    if [[ -z "$branch_name" ]]; then
        report_cache_warning "VALIDATION_FAILED" \
            "Empty branch name in cache file: $(basename "$cache_file")" \
            "Git repository may be in detached HEAD state or cache corruption"
        return 1
    fi
    
    # Use Git's own validation for branch names (supports Unicode, emojis, etc.)
    if command -v git >/dev/null 2>&1; then
        if git check-ref-format --branch "$branch_name" 2>/dev/null; then
            return 0
        else
            report_cache_warning "GIT_VALIDATION_FAILED" \
                "Invalid Git branch name: $branch_name" \
                "Branch name violates Git naming rules - clearing cache for regeneration"
            rm -f "$cache_file" 2>/dev/null  # Remove invalid cache to force regeneration
            return 1
        fi
    else
        # Fallback validation if git is not available (should be rare)
        # Allow most characters but reject obvious invalid cases
        if [[ "$branch_name" =~ ^[[:space:]]*$ ]] || \
           [[ "$branch_name" =~ \\.\\. ]] || \
           [[ "$branch_name" =~ [[:cntrl:]] ]] || \
           [[ "$branch_name" =~ ^\\.$ ]] || \
           [[ "$branch_name" =~ \\.$$ ]]; then
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Branch name failed fallback validation: $branch_name" "WARN"
            return 1
        fi
        
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Used fallback branch validation for: $branch_name" "INFO"
        return 0
    fi
}

# System info validation (should never change)
validate_system_cache() {
    local cache_file="$1"
    validate_basic_cache "$cache_file"
}

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
    
    # Try alternative cache locations
    local alternatives=(
        "${HOME:-}/.cache/claude-code-statusline-fallback"
        "/tmp/.claude_statusline_fallback_${USER:-$(id -u)}"
        "/tmp/.claude_statusline_emergency_$$"
    )
    
    for alt_dir in "${alternatives[@]}"; do
        if [[ -n "$alt_dir" ]] && mkdir -p "$alt_dir" 2>/dev/null; then
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
        rm -f "$cache_file" 2>/dev/null
        return 1
    fi
    
    # Check for empty or invalid files
    if [[ ! -s "$cache_file" ]] || [[ "$(head -c 1 "$cache_file" 2>/dev/null | wc -c)" -eq 0 ]]; then
        report_cache_warning "CORRUPTION_DETECTED" \
            "Cache file empty or invalid: $(basename "$cache_file")" \
            "Removing empty file and regenerating cache"
        rm -f "$cache_file" 2>/dev/null
        return 1
    fi
    
    # Check for null bytes or control characters (basic corruption detection)
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
        if [[ "$(uname)" == "Darwin" ]]; then
            lock_age=$(( $(date +%s) - $(stat -f %m "$lock_file" 2>/dev/null || echo 0) ))
        else
            lock_age=$(( $(date +%s) - $(stat -c %Y "$lock_file" 2>/dev/null || echo 0) ))
        fi
        
        if [[ $lock_age -gt $max_age_seconds ]]; then
            report_cache_warning "STALE_LOCK_RECOVERY" \
                "Removing stale lock (age: ${lock_age}s): $(basename "$lock_file")" \
                "Lock was older than ${max_age_seconds}s threshold"
            rm -f "$lock_file" 2>/dev/null
            return 0
        fi
    fi
    
    # Check if lock process still exists
    if [[ -r "$lock_file" ]]; then
        local lock_content
        lock_content="$(cat "$lock_file" 2>/dev/null || echo "")"
        local lock_pid
        lock_pid="$(echo "$lock_content" | cut -d':' -f2 2>/dev/null || echo "")"
        
        if [[ -n "$lock_pid" ]] && [[ "$lock_pid" =~ ^[0-9]+$ ]]; then
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
# CACHE PERFORMANCE MONITORING & ANALYTICS SYSTEM
# ============================================================================

# Bash compatibility check - disable advanced features for old bash
if [[ "${STATUSLINE_COMPATIBILITY_MODE:-}" == "true" ]] || [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    # Disable associative arrays for bash < 4.0
    export STATUSLINE_CACHE_COMPATIBLE_MODE=true
    debug_log "Cache module running in compatibility mode (bash ${BASH_VERSION})" "INFO"
else
    # Performance statistics tracking (requires bash 4.0+ for associative arrays)
    declare -A CACHE_STATS_HITS=()
    declare -A CACHE_STATS_MISSES=()
    declare -A CACHE_STATS_ERRORS=()
    declare -A CACHE_STATS_RESPONSE_TIMES=()
    declare -A CACHE_STATS_TOTAL_CALLS=()
fi

# Sanitize cache key to avoid bash arithmetic evaluation issues
# Replaces patterns like "1m", "2k", etc. that bash may try to evaluate as numbers
sanitize_cache_key() {
    local key="$1"
    # Replace all hyphens with double underscores to completely avoid arithmetic parsing issues
    # The hyphen after number+letter patterns seems to confuse bash's parser
    echo "$key" | tr '-' '_'
}

# Initialize cache statistics for a key
init_cache_stats() {
    local cache_key=$(sanitize_cache_key "$1")
    CACHE_STATS_HITS["$cache_key"]=0
    CACHE_STATS_MISSES["$cache_key"]=0
    CACHE_STATS_ERRORS["$cache_key"]=0
    CACHE_STATS_RESPONSE_TIMES["$cache_key"]=0
    CACHE_STATS_TOTAL_CALLS["$cache_key"]=0
}

# Record a cache hit with response time
record_cache_hit() {
    local cache_key=$(sanitize_cache_key "$1")
    local response_time_ms="${2:-0}"

    # Initialize stats for this key (idempotent, safe to call multiple times)
    : "${CACHE_STATS_HITS["$cache_key"]:=0}"
    : "${CACHE_STATS_MISSES["$cache_key"]:=0}"
    : "${CACHE_STATS_ERRORS["$cache_key"]:=0}"
    : "${CACHE_STATS_RESPONSE_TIMES["$cache_key"]:=0}"
    : "${CACHE_STATS_TOTAL_CALLS["$cache_key"]:=0}"

    CACHE_STATS_HITS["$cache_key"]=$((${CACHE_STATS_HITS["$cache_key"]} + 1))
    CACHE_STATS_TOTAL_CALLS["$cache_key"]=$((${CACHE_STATS_TOTAL_CALLS["$cache_key"]} + 1))

    # Update average response time (use local vars to avoid bash arithmetic parsing issues)
    local current_avg="${CACHE_STATS_RESPONSE_TIMES["$cache_key"]}"
    local total_calls="${CACHE_STATS_TOTAL_CALLS["$cache_key"]}"
    CACHE_STATS_RESPONSE_TIMES["$cache_key"]=$(( (current_avg * (total_calls - 1) + response_time_ms) / total_calls ))
}

# Record a cache miss with response time
record_cache_miss() {
    local cache_key=$(sanitize_cache_key "$1")
    local response_time_ms="${2:-0}"

    # Initialize stats for this key (idempotent, safe to call multiple times)
    : "${CACHE_STATS_HITS["$cache_key"]:=0}"
    : "${CACHE_STATS_MISSES["$cache_key"]:=0}"
    : "${CACHE_STATS_ERRORS["$cache_key"]:=0}"
    : "${CACHE_STATS_RESPONSE_TIMES["$cache_key"]:=0}"
    : "${CACHE_STATS_TOTAL_CALLS["$cache_key"]:=0}"

    CACHE_STATS_MISSES["$cache_key"]=$((${CACHE_STATS_MISSES["$cache_key"]} + 1))
    CACHE_STATS_TOTAL_CALLS["$cache_key"]=$((${CACHE_STATS_TOTAL_CALLS["$cache_key"]} + 1))

    # Update average response time (use local vars to avoid bash arithmetic parsing issues)
    local current_avg="${CACHE_STATS_RESPONSE_TIMES["$cache_key"]}"
    local total_calls="${CACHE_STATS_TOTAL_CALLS["$cache_key"]}"
    CACHE_STATS_RESPONSE_TIMES["$cache_key"]=$(( (current_avg * (total_calls - 1) + response_time_ms) / total_calls ))
}

# Record a cache error
record_cache_error() {
    local cache_key=$(sanitize_cache_key "$1")

    # Initialize stats for this key (idempotent, safe to call multiple times)
    : "${CACHE_STATS_HITS["$cache_key"]:=0}"
    : "${CACHE_STATS_MISSES["$cache_key"]:=0}"
    : "${CACHE_STATS_ERRORS["$cache_key"]:=0}"
    : "${CACHE_STATS_RESPONSE_TIMES["$cache_key"]:=0}"
    : "${CACHE_STATS_TOTAL_CALLS["$cache_key"]:=0}"

    CACHE_STATS_ERRORS["$cache_key"]=$((${CACHE_STATS_ERRORS["$cache_key"]} + 1))
    CACHE_STATS_TOTAL_CALLS["$cache_key"]=$((${CACHE_STATS_TOTAL_CALLS["$cache_key"]} + 1))
}

# Calculate cache hit ratio for a specific key
get_cache_hit_ratio() {
    local cache_key=$(sanitize_cache_key "$1")
    local hits=${CACHE_STATS_HITS["$cache_key"]:-0}
    local total=${CACHE_STATS_TOTAL_CALLS["$cache_key"]:-0}

    if [[ $total -eq 0 ]]; then
        echo "0.00"
        return
    fi

    local ratio
    ratio=$(awk -v h="$hits" -v t="$total" 'BEGIN { printf "%.2f", (h/t)*100 }')
    echo "$ratio"
}

# Get comprehensive cache performance report
get_cache_performance_report() {
    local show_details="${1:-false}"
    
    echo "=== Cache Performance Analytics ==="
    echo "Instance ID: $CACHE_INSTANCE_ID"
    echo "Cache Directory: $CACHE_BASE_DIR"
    echo ""
    
    # Overall statistics
    local total_hits=0
    local total_misses=0
    local total_errors=0
    local total_calls=0
    
    for key in "${!CACHE_STATS_TOTAL_CALLS[@]}"; do
        total_hits=$((total_hits + ${CACHE_STATS_HITS["$key"]:-0}))
        total_misses=$((total_misses + ${CACHE_STATS_MISSES["$key"]:-0}))
        total_errors=$((total_errors + ${CACHE_STATS_ERRORS["$key"]:-0}))
        total_calls=$((total_calls + ${CACHE_STATS_TOTAL_CALLS["$key"]:-0}))
    done
    
    if [[ $total_calls -gt 0 ]]; then
        local overall_hit_ratio
        overall_hit_ratio=$(awk -v h="$total_hits" -v t="$total_calls" 'BEGIN { printf "%.2f", (h/t)*100 }')
        
        echo "Overall Performance:"
        echo "  Total Operations: $total_calls"
        echo "  Cache Hits: $total_hits (${overall_hit_ratio}%)"
        echo "  Cache Misses: $total_misses"
        echo "  Cache Errors: $total_errors"
        echo ""
        
        # Performance classification
        if (( $(echo "$overall_hit_ratio >= 80" | bc -l) )); then
            echo "  Cache Efficiency: EXCELLENT (≥80%)"
        elif (( $(echo "$overall_hit_ratio >= 60" | bc -l) )); then
            echo "  Cache Efficiency: GOOD (60-79%)"
        elif (( $(echo "$overall_hit_ratio >= 40" | bc -l) )); then
            echo "  Cache Efficiency: MODERATE (40-59%)"
        else
            echo "  Cache Efficiency: POOR (<40%) - Consider tuning cache durations"
        fi
    else
        echo "No cache operations recorded yet."
    fi
    
    # Detailed per-key statistics
    if [[ "$show_details" == "true" ]] && [[ ${#CACHE_STATS_TOTAL_CALLS[@]} -gt 0 ]]; then
        echo ""
        echo "Per-Key Performance:"
        echo "  Key                          | Hits  | Misses| Hit %| Avg RT(ms)| Total"
        echo "  -----------------------------|-------|-------|------|-----------|------"
        
        for key in $(printf '%s\n' "${!CACHE_STATS_TOTAL_CALLS[@]}" | sort); do
            local hits=${CACHE_STATS_HITS["$key"]:-0}
            local misses=${CACHE_STATS_MISSES["$key"]:-0}
            local total=${CACHE_STATS_TOTAL_CALLS["$key"]:-0}
            local avg_rt=${CACHE_STATS_RESPONSE_TIMES["$key"]:-0}
            local hit_ratio
            hit_ratio=$(get_cache_hit_ratio "$key")
            
            printf "  %-28s | %5d | %5d | %4s%% | %9d | %5d\n" \
                "${key:0:28}" "$hits" "$misses" "$hit_ratio" "$avg_rt" "$total"
        done
    fi
    
    echo ""
}

# Get cache memory usage statistics
get_cache_memory_stats() {
    if [[ ! -d "$CACHE_BASE_DIR" ]]; then
        echo "Cache directory not found"
        return 1
    fi
    
    echo "=== Cache Memory Usage ==="
    echo "Cache Directory: $CACHE_BASE_DIR"
    
    # Count files and calculate total size
    local file_count=0
    local total_size=0
    
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            file_count=$((file_count + 1))
            if command -v stat >/dev/null 2>&1; then
                local file_size
                if [[ "$(uname)" == "Darwin" ]]; then
                    file_size=$(stat -f %z "$file" 2>/dev/null || echo 0)
                else
                    file_size=$(stat -c %s "$file" 2>/dev/null || echo 0)
                fi
                total_size=$((total_size + file_size))
            fi
        fi
    done < <(find "$CACHE_BASE_DIR" -type f -print0 2>/dev/null)
    
    echo "  Cache Files: $file_count"
    
    # Convert bytes to human-readable format
    if [[ $total_size -gt 1048576 ]]; then
        local size_mb
        size_mb=$(awk -v s="$total_size" 'BEGIN { printf "%.2f", s/1048576 }')
        echo "  Total Size: ${size_mb}MB"
    elif [[ $total_size -gt 1024 ]]; then
        local size_kb
        size_kb=$(awk -v s="$total_size" 'BEGIN { printf "%.2f", s/1024 }')
        echo "  Total Size: ${size_kb}KB"
    else
        echo "  Total Size: ${total_size} bytes"
    fi
    
    # Show oldest and newest files
    if [[ $file_count -gt 0 ]]; then
        local oldest_file newest_file
        oldest_file=$(find "$CACHE_BASE_DIR" -type f -printf '%T+ %p\n' 2>/dev/null | sort | head -1 | cut -d' ' -f2- | xargs basename 2>/dev/null || echo "unknown")
        newest_file=$(find "$CACHE_BASE_DIR" -type f -printf '%T+ %p\n' 2>/dev/null | sort -r | head -1 | cut -d' ' -f2- | xargs basename 2>/dev/null || echo "unknown")
        
        echo "  Oldest File: $oldest_file"
        echo "  Newest File: $newest_file"
    fi
    
    echo ""
}

# Clear performance statistics
clear_cache_stats() {
    local cache_key="${1:-}"
    
    if [[ -n "$cache_key" ]]; then
        # Clear statistics for specific key
        unset "CACHE_STATS_HITS[$cache_key]"
        unset "CACHE_STATS_MISSES[$cache_key]"
        unset "CACHE_STATS_ERRORS[$cache_key]"
        unset "CACHE_STATS_RESPONSE_TIMES[$cache_key]"
        unset "CACHE_STATS_TOTAL_CALLS[$cache_key]"
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleared statistics for cache key: $cache_key" "INFO"
    else
        # Clear all statistics
        CACHE_STATS_HITS=()
        CACHE_STATS_MISSES=()
        CACHE_STATS_ERRORS=()
        CACHE_STATS_RESPONSE_TIMES=()
        CACHE_STATS_TOTAL_CALLS=()
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleared all cache statistics" "INFO"
    fi
}

# Measure execution time in milliseconds (if available)
measure_execution_time() {
    local start_time end_time duration_ms
    
    # Use high-precision timing if available
    if command -v python3 >/dev/null 2>&1; then
        start_time=$(python3 -c "import time; print(int(time.time() * 1000))")
        "$@"
        local exit_code=$?
        end_time=$(python3 -c "import time; print(int(time.time() * 1000))")
        duration_ms=$((end_time - start_time))
    else
        # Fallback to second precision
        start_time=$(date +%s)
        "$@"
        local exit_code=$?
        end_time=$(date +%s)
        duration_ms=$(( (end_time - start_time) * 1000 ))
    fi
    
    echo "$duration_ms" >&3
    return $exit_code
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

# Content-specific validation functions
validate_git_branch_content() {
    local content="$1"
    [[ -n "$content" ]] && [[ ! "$content" =~ $'\n' ]] && [[ ${#content} -lt 256 ]]
}

validate_json_content() {
    local content="$1"
    echo "$content" | jq . >/dev/null 2>&1
}

validate_command_output_content() {
    local content="$1"
    [[ -n "$content" ]] && [[ ${#content} -lt 10240 ]]  # Reasonable size limit
}

validate_basic_content() {
    local content="$1"
    [[ -n "$content" ]] && [[ ! "$content" =~ $'\0' ]]  # No null bytes
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

# ============================================================================
# COMPREHENSIVE RESOURCE CLEANUP SYSTEM
# ============================================================================

# Instance-specific cleanup registry for temporary files
declare -a CACHE_TEMP_FILES=()
declare -a CACHE_CLEANUP_REGISTERED=()

# Register a temporary file for cleanup on exit
register_temp_file() {
    local temp_file="$1"
    if [[ -n "$temp_file" ]]; then
        CACHE_TEMP_FILES+=("$temp_file")
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Registered temp file for cleanup: $(basename "$temp_file")" "INFO"
    fi
}

# Comprehensive cleanup function for cache resources
cleanup_cache_resources() {
    local cleanup_count=0
    
    # Clean up temporary files created by this instance
    for temp_file in "${CACHE_TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file" 2>/dev/null
            if [[ ! -f "$temp_file" ]]; then
                cleanup_count=$((cleanup_count + 1))
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cleaned up temp file: $(basename "$temp_file")" "INFO"
            fi
        fi
    done
    
    # Clean up any orphaned temporary files from this instance
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        find "$CACHE_BASE_DIR" -name "*.tmp.$$" -type f -exec rm -f {} \; 2>/dev/null
        find "$CACHE_BASE_DIR" -name "*.migrating" -type f -mmin +5 -exec rm -f {} \; 2>/dev/null
    fi
    
    # Release any locks held by this instance
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        find "$CACHE_BASE_DIR" -name "*.lock" -type f -exec sh -c '
            for lock in "$@"; do
                if [[ -f "$lock" ]] && grep -q "^'"$CACHE_INSTANCE_ID"':" "$lock" 2>/dev/null; then
                    rm -f "$lock" 2>/dev/null
                fi
            done
        ' _ {} + 2>/dev/null
    fi
    
    # Clear the temporary files registry
    CACHE_TEMP_FILES=()
    
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && [[ $cleanup_count -gt 0 ]] && \
        debug_log "Cache cleanup completed: $cleanup_count files removed" "INFO"
}

# Install cleanup traps for comprehensive resource management
install_cleanup_traps() {
    # Only install traps once per instance
    local trap_marker="CACHE_CLEANUP_TRAP_${CACHE_INSTANCE_ID}"
    if [[ "${!trap_marker:-}" == "installed" ]]; then
        return 0
    fi
    
    # Install signal traps for comprehensive cleanup
    # EXIT: Normal script termination
    # INT: Ctrl+C (SIGINT)
    # TERM: Termination request (SIGTERM)
    # HUP: Terminal hangup (SIGHUP)
    trap 'cleanup_cache_resources' EXIT INT TERM HUP
    
    # Mark traps as installed for this instance
    declare -g "$trap_marker=installed"
    export "$trap_marker"
    
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Installed cache cleanup traps for instance $CACHE_INSTANCE_ID" "INFO"
}

# ============================================================================
# ENHANCED LOCKING SYSTEM
# ============================================================================

# Acquire cache lock with retry logic
acquire_cache_lock() {
    local cache_file="$1"
    local max_retries="${2:-${CACHE_CONFIG_MAX_LOCK_RETRIES:-10}}"
    local lock_file="${cache_file}.lock"
    
    cleanup_stale_locks "$lock_file"
    
    local retry_count=0
    while [[ $retry_count -lt $max_retries ]]; do
        # Additional aggressive cleanup right before lock attempt
        [[ -f "$lock_file" ]] && rm -f "$lock_file" 2>/dev/null
        
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
    
    report_cache_warning "LOCK_ACQUISITION_FAILED" \
        "Failed to acquire cache lock after $max_retries attempts: $(basename "$cache_file")" \
        "High cache contention or stale locks - consider increasing max_lock_retries or clearing stale locks"
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
            [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Using cached result: $cache_key" "INFO"
            
            # Record cache hit if statistics are enabled
            [[ "${CACHE_CONFIG_ENABLE_STATISTICS:-}" == "true" ]] && record_cache_hit "$cache_key" 0
            
            cat "$cache_file" 2>/dev/null
            return 0
        fi
    fi
    
    # Ensure cleanup traps are installed for this instance
    install_cleanup_traps
    
    # Acquire lock for cache update
    if acquire_cache_lock "$cache_file"; then
        local temp_file="${cache_file}.tmp.$$"
        local command_output
        
        # Register temporary file for cleanup
        register_temp_file "$temp_file"
        
        # Execute the command
        if command_output=$("${command[@]}" 2>/dev/null); then
            # Atomic write to cache
            if echo "$command_output" > "$temp_file" 2>/dev/null && mv "$temp_file" "$cache_file" 2>/dev/null; then
                [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cached fresh result: $cache_key" "INFO"
                
                # Record cache miss (successful regeneration) if statistics are enabled
                [[ "${CACHE_CONFIG_ENABLE_STATISTICS:-}" == "true" ]] && record_cache_miss "$cache_key" 0
                
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
            report_cache_warning "COMMAND_EXECUTION_FAILED" \
                "Command execution failed for cache key: $cache_key" \
                "Using stale cache if available, otherwise falling back to direct execution"
            
            # Record cache error if statistics are enabled
            [[ "${CACHE_CONFIG_ENABLE_STATISTICS:-}" == "true" ]] && record_cache_error "$cache_key"
            
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
export -f get_repo_identifier generate_instance_cache_key generate_typed_cache_key
export -f validate_basic_cache validate_json_cache validate_command_output
export -f validate_git_cache validate_git_branch_name validate_system_cache
export -f clear_all_cache clear_instance_cache show_cache_stats
export -f init_cache_directory cleanup_cache_files is_first_startup
export -f register_temp_file cleanup_cache_resources install_cleanup_traps
export -f load_cache_configuration
export -f report_cache_error report_cache_warning recover_cache_directory
export -f detect_and_recover_corruption recover_stale_locks
export -f init_cache_stats record_cache_hit record_cache_miss record_cache_error
export -f get_cache_hit_ratio get_cache_performance_report get_cache_memory_stats
export -f clear_cache_stats measure_execution_time
export -f generate_cache_checksum write_cache_with_checksum read_cache_with_checksum
export -f validate_cache_with_checksum migrate_to_checksum_cache audit_cache_integrity
export -f validate_git_branch_content validate_json_content validate_command_output_content validate_basic_content