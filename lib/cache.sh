#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Module Facade
# ============================================================================
#
# This is the main entry point for the cache module. It sources all cache
# sub-modules and provides backward compatibility by re-exporting all
# functions. The actual implementation is split across:
#
#   lib/cache/
#   ├── config.sh       # TOML configuration loading
#   ├── directory.sh    # XDG paths, init, migration
#   ├── keys.sh         # Key generation, isolation modes
#   ├── validation.sh   # All validation functions
#   ├── statistics.sh   # Stats tracking and reporting
#   ├── integrity.sh    # Checksums, corruption detection
#   ├── locking.sh      # Lock acquisition/release
#   └── operations.sh   # Core cache operations
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_LOADED=true

# Get the directory containing this script for sourcing sub-modules
CACHE_MODULE_DIR="${BASH_SOURCE[0]%/*}/cache"

# ============================================================================
# ENSURE DEPENDENCIES ARE LOADED
# ============================================================================

# Security module provides: sanitize_variable_name, is_cache_fresh, cleanup_stale_locks
if [[ "${STATUSLINE_SECURITY_LOADED:-}" != "true" ]]; then
    source "${BASH_SOURCE[0]%/*}/security.sh"
fi

# ============================================================================
# SOURCE SUB-MODULES IN DEPENDENCY ORDER
# ============================================================================

source "${CACHE_MODULE_DIR}/config.sh"
source "${CACHE_MODULE_DIR}/directory.sh"
source "${CACHE_MODULE_DIR}/keys.sh"
source "${CACHE_MODULE_DIR}/validation.sh"
source "${CACHE_MODULE_DIR}/statistics.sh"
source "${CACHE_MODULE_DIR}/integrity.sh"
source "${CACHE_MODULE_DIR}/locking.sh"
source "${CACHE_MODULE_DIR}/operations.sh"

# ============================================================================
# CACHE CONFIGURATION CONSTANTS
# ============================================================================

# Load configuration (must be called before determining cache directory)
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
# INSTANCE MANAGEMENT
# ============================================================================

# Instance-specific cache management with XDG compliance
# Use PPID (parent process ID) for unique per-Claude-Code-instance isolation (Issue #142)
# This ensures each Claude Code instance gets its own cache files and locks
# Sanitize USER to ensure valid variable names (issue #51: dots in username)
SANITIZED_USER=$(sanitize_variable_name "${USER}")
export CACHE_INSTANCE_ID="${CACHE_INSTANCE_ID:-${CLAUDE_INSTANCE_ID:-${SANITIZED_USER}_claude_${PPID}}}"

# Session marker uses XDG-compliant runtime directory (Issue #110)
# get_secure_runtime_dir() provides XDG_RUNTIME_DIR -> CACHE_BASE_DIR -> secure fallback
if declare -f get_secure_runtime_dir >/dev/null 2>&1; then
    export CACHE_SESSION_MARKER="$(get_secure_runtime_dir)/.session_${CACHE_INSTANCE_ID}"
else
    # Fallback if security module not loaded yet
    export CACHE_SESSION_MARKER="${CACHE_BASE_DIR}/.session_${CACHE_INSTANCE_ID}"
fi

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

# Initialize the module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_cache_module
fi

# ============================================================================
# EXPORTS (for backward compatibility)
# ============================================================================

# All functions are already exported by their respective sub-modules.
# This section documents what functions are available from this facade:
#
# From config.sh:
#   load_cache_configuration
#
# From directory.sh:
#   determine_cache_base_dir, migrate_legacy_cache, init_cache_directory
#   get_cache_file_path, cleanup_cache_files, is_first_startup, should_force_refresh
#
# From keys.sh:
#   get_repo_identifier, generate_instance_cache_key, generate_typed_cache_key
#   sanitize_cache_key
#
# From validation.sh:
#   validate_basic_cache, validate_json_cache, validate_command_output
#   validate_git_cache, validate_git_branch_name, validate_system_cache
#   validate_git_branch_content, validate_json_content
#   validate_command_output_content, validate_basic_content
#
# From statistics.sh:
#   init_cache_stats, record_cache_hit, record_cache_miss, record_cache_error
#   get_cache_hit_ratio, get_cache_performance_report, get_cache_memory_stats
#   clear_cache_stats, measure_execution_time, show_cache_stats
#
# From integrity.sh:
#   report_cache_error, report_cache_warning, recover_cache_directory
#   detect_and_recover_corruption, recover_stale_locks
#   generate_cache_checksum, write_cache_with_checksum, read_cache_with_checksum
#   validate_cache_with_checksum, migrate_to_checksum_cache, audit_cache_integrity
#
# From locking.sh:
#   acquire_cache_lock, release_cache_lock
#
# From operations.sh:
#   register_temp_file, cleanup_cache_resources, install_cleanup_traps
#   execute_cached_command, cache_command_exists, cache_system_info
#   cache_git_operation, cache_external_command
#   clear_all_cache, clear_instance_cache
