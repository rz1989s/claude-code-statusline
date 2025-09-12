#!/bin/bash

# ============================================================================
# Claude Code Statusline - Security Module
# ============================================================================
# 
# This module contains all security-related functions including input 
# sanitization, secure file operations, and validation routines.
#
# Dependencies: core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_SECURITY_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_SECURITY_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# SECURITY CONSTANTS
# ============================================================================

# Maximum allowed path length
export MAX_PATH_LENGTH=1000

# Maximum iterations for path sanitization loops
export MAX_SANITIZATION_ITERATIONS=10

# Dangerous patterns for Python code validation
export DANGEROUS_PYTHON_PATTERNS=(
    "rm -rf" "rm -r" "rmdir" "unlink" "delete"
    "system(" "exec(" "eval(" "compile("
    "subprocess." "popen(" "call(" "run("
    "os.system" "os.popen" "os.execv" "os.spawn"
    "__import__" "importlib" "import subprocess"
    "urllib" "requests" "http" "socket" "ftp"
    "open(" "file(" "write(" "writelines("
    "shutil" "glob.glob" "pathlib" "tempfile"
    "; " "&&" "||" "|" ">" ">>" "<"
)

# ============================================================================
# PATH SANITIZATION FUNCTIONS
# ============================================================================

# Enhanced path sanitization (addresses security concern from original line 617)
sanitize_path_secure() {
    local path="$1"

    # Validate input
    if [[ -z "$path" ]]; then
        echo ""
        return 0
    fi

    # Check path length (prevent excessively long paths)
    if [[ ${#path} -gt $MAX_PATH_LENGTH ]]; then
        handle_warning "Path too long (${#path} chars, max $MAX_PATH_LENGTH)" "sanitize_path_secure"
        # Return truncated path instead of failing
        path="${path:0:$MAX_PATH_LENGTH}"
    fi

    # Security-first sanitization: remove path traversal sequences FIRST
    local sanitized="$path"

    # Iteratively remove path traversal patterns until none remain
    # This prevents bypass attempts like ....// -> ../
    local prev_sanitized=""
    local iteration_count=0

    while [[ "$sanitized" != "$prev_sanitized" ]] && [[ $iteration_count -lt $MAX_SANITIZATION_ITERATIONS ]]; do
        prev_sanitized="$sanitized"

        # Remove various path traversal patterns - using safe parameter expansion
        sanitized="${sanitized//..\/}"    # Remove ../
        sanitized="${sanitized//.\/}"     # Remove ./  
        sanitized="${sanitized//\/\///}"  # Remove double slashes -> single slash

        ((iteration_count++))
    done

    # Final cleanup: remove any remaining .. sequences completely
    sanitized="${sanitized//../removed-dotdot}"

    # Remove any remaining suspicious patterns using safe parameter expansion
    sanitized="${sanitized//..}"       # Remove any remaining ..
    sanitized="${sanitized//\~}"       # Remove ~
    sanitized="${sanitized//\$}"       # Remove $

    # Replace slashes with hyphens using safe parameter expansion  
    sanitized="${sanitized//\//-}"

    # Remove potentially dangerous characters, keep only safe ones (no dots for cache key compatibility)
    # Using printf to avoid echo vulnerabilities with tr
    sanitized=$(printf '%s' "$sanitized" | /usr/bin/tr -cd '[:alnum:]-_')

    # Ensure result is not empty
    if [[ -z "$sanitized" ]]; then
        sanitized="unknown-path"
    fi

    echo "$sanitized"
}

# ============================================================================
# SECURE FILE OPERATIONS
# ============================================================================

# Secure cache file creation with file locking to prevent race conditions
create_secure_cache_file() {
    local cache_file="$1"
    local content="$2"
    local lock_file="${cache_file}.lock"
    local max_wait_time=5 # Maximum seconds to wait for lock
    local wait_count=0

    # Check required parameters
    if [[ -z "$cache_file" || -z "$content" ]]; then
        handle_error "create_secure_cache_file requires cache_file and content parameters" 1 "create_secure_cache_file"
        return 1
    fi

    # Create cache directory if it doesn't exist
    local cache_dir
    cache_dir=$(dirname "$cache_file")
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir" 2>/dev/null
        chmod 700 "$cache_dir" 2>/dev/null # Secure permissions to prevent other users from reading cost data
    fi

    # Acquire exclusive file lock to prevent race conditions
    while ! (
        set -C
        echo $$ >"$lock_file"
    ) 2>/dev/null; do
        if [[ $wait_count -ge $max_wait_time ]]; then
            handle_warning "Failed to acquire lock for cache file after ${max_wait_time}s, proceeding without lock: $cache_file" "create_secure_cache_file"
            break
        fi
        sleep 0.1
        ((wait_count++))
    done

    # Create file with content atomically
    local write_status=1
    {
        # Use temporary file for atomic write
        local temp_file="${cache_file}.tmp.$$"

        # Write content to temporary file
        echo "$content" >"$temp_file" 2>/dev/null
        write_status=$?

        if [[ $write_status -eq 0 && -f "$temp_file" ]]; then
            # Set secure permissions before moving
            chmod 644 "$temp_file" 2>/dev/null

            # Atomic move to final location
            mv "$temp_file" "$cache_file" 2>/dev/null
            write_status=$?
        else
            handle_error "Failed to write to temporary cache file: $temp_file" 1 "create_secure_cache_file"
            rm -f "$temp_file" 2>/dev/null
        fi

        # Clean up temporary file if move failed
        [[ -f "$temp_file" ]] && rm -f "$temp_file" 2>/dev/null

        # Release lock
        rm -f "$lock_file" 2>/dev/null

        # Verify final result
        if [[ $write_status -eq 0 && -f "$cache_file" ]]; then
            # Verify permissions were set correctly
            local perms
            perms=$(stat -f %A "$cache_file" 2>/dev/null || stat -c %a "$cache_file" 2>/dev/null)
            if [[ "$perms" != "644" ]]; then
                handle_warning "Cache file has unexpected permissions: $perms (expected: 644)" "create_secure_cache_file"
                # Try to fix permissions
                chmod 644 "$cache_file" 2>/dev/null
            fi
            return 0
        else
            handle_error "Failed to create secure cache file: $cache_file" 1 "create_secure_cache_file"
            return 1
        fi
    }
}

# ============================================================================
# INPUT VALIDATION FUNCTIONS
# ============================================================================

# ANSI color code validation for custom themes
validate_ansi_color() {
    local color_value="$1"
    local color_name="${2:-unknown}"

    # Check if color value is provided
    if [[ -z "$color_value" ]]; then
        return 1 # Empty color
    fi

    # Valid ANSI color patterns:
    # 1. Basic ANSI: \\033[30-37m, \\033[90-97m
    # 2. 256-color: \\033[38;5;0-255m, \\033[48;5;0-255m
    # 3. RGB: \\033[38;2;r;g;bm, \\033[48;2;r;g;bm
    # 4. Reset and formatting: \\033[0-9m

    local valid_patterns=(
        # Basic ANSI colors (30-37 for foreground, 40-47 for background)
        '^\\033\[[39][0-7]m$'
        # Bright ANSI colors (90-97 for bright foreground, 100-107 for bright background)
        '^\\033\[1[0-9][0-7]m$'
        # 256-color format (38;5;n for foreground, 48;5;n for background)
        '^\\033\[38;5;[0-9]{1,3}m$'
        '^\\033\[48;5;[0-9]{1,3}m$'
        # RGB format (38;2;r;g;b for foreground, 48;2;r;g;b for background)
        '^\\033\[38;2;[0-9]{1,3};[0-9]{1,3};[0-9]{1,3}m$'
        '^\\033\[48;2;[0-9]{1,3};[0-9]{1,3};[0-9]{1,3}m$'
        # Text formatting codes (0-9, some multi-digit)
        '^\\033\[[0-9]{1,2}m$'
    )

    # Check against valid patterns
    local is_valid=false
    for pattern in "${valid_patterns[@]}"; do
        if [[ "$color_value" =~ $pattern ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" != "true" ]]; then
        handle_warning "Invalid ANSI color code for '$color_name': $color_value" "validate_ansi_color"
        debug_log "Valid formats: \\033[31m, \\033[38;5;208m, \\033[38;2;255;100;50m" "INFO"
        return 2 # Invalid format
    fi

    # Additional validation for 256-color values (0-255 range)
    local color_256_pattern='\\033\[(38|48);5;([0-9]+)m'
    if [[ "$color_value" =~ $color_256_pattern ]]; then
        local color_num="${BASH_REMATCH[2]}"
        if [[ "$color_num" -gt 255 ]]; then
            handle_warning "256-color code out of range for '$color_name': $color_num (max: 255)" "validate_ansi_color"
            return 3 # Out of range
        fi
    fi

    # Additional validation for RGB values (0-255 range for each component)
    local rgb_pattern='\\033\[(38|48);2;([0-9]+);([0-9]+);([0-9]+)m'
    if [[ "$color_value" =~ $rgb_pattern ]]; then
        local r="${BASH_REMATCH[2]}"
        local g="${BASH_REMATCH[3]}"
        local b="${BASH_REMATCH[4]}"

        if [[ "$r" -gt 255 || "$g" -gt 255 || "$b" -gt 255 ]]; then
            handle_warning "RGB color values out of range for '$color_name': R=$r G=$g B=$b (max: 255)" "validate_ansi_color"
            return 4 # RGB out of range
        fi
    fi

    return 0 # Valid color code
}

# Enhanced Python execution with better error handling
execute_python_safely() {
    local python_code="$1"
    local fallback_value="$2"

    # Check if Python is available
    if ! command_exists python3; then
        debug_log "Python3 not available, using fallback" "WARN"
        echo "$fallback_value"
        return 0
    fi

    # Validate input (comprehensive injection prevention)
    for pattern in "${DANGEROUS_PYTHON_PATTERNS[@]}"; do
        if [[ "$python_code" == *"$pattern"* ]]; then
            handle_error "Potentially dangerous Python code detected: $pattern" 1 "execute_python_safely"
            echo "$fallback_value"
            return 1
        fi
    done

    # Execute with timeout if available
    local result
    if command_exists timeout; then
        result=$(timeout 5s python3 -c "$python_code" 2>/dev/null)
    elif command_exists gtimeout; then
        result=$(gtimeout 5s python3 -c "$python_code" 2>/dev/null)
    else
        result=$(python3 -c "$python_code" 2>/dev/null)
    fi

    # Return result or fallback
    if [[ $? -eq 0 && -n "$result" ]]; then
        echo "$result"
    else
        echo "$fallback_value"
    fi
}

# Enhanced MCP server name parsing (addresses lines 374, 396-398 security concern)
parse_mcp_server_name_secure() {
    local line="$1"

    # Improved regex pattern that's more restrictive and secure
    # Only allow ASCII alphanumeric, underscore, and hyphen
    # Must start and end with alphanumeric
    if [[ "$line" =~ ^([a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]|[a-zA-Z0-9]): ]]; then
        local server_name="${BASH_REMATCH[1]}"

        # Additional validation: check length and character set
        if [[ ${#server_name} -gt 100 ]]; then
            handle_error "MCP server name too long: ${server_name:0:20}..." 1 "parse_mcp_server_name_secure"
            return 1
        fi

        # Ensure no dangerous characters slipped through
        if [[ "$server_name" =~ [^a-zA-Z0-9_-] ]]; then
            handle_error "Invalid characters in MCP server name: $server_name" 1 "parse_mcp_server_name_secure"
            return 1
        fi

        echo "$server_name"
        return 0
    fi

    return 1
}

# ============================================================================
# TIMEOUT VALIDATION
# ============================================================================

# Parse timeout string to numeric seconds for validation
# Supports formats: "10s", "2m", "30" (defaults to seconds)
parse_timeout_to_seconds() {
    local timeout_str="$1"
    local numeric_value
    local unit

    # Handle empty or null values
    [[ -z "$timeout_str" || "$timeout_str" == "null" ]] && return 1

    # Extract numeric value and unit
    if [[ "$timeout_str" =~ ^([0-9]+)([sm]?)$ ]]; then
        numeric_value="${BASH_REMATCH[1]}"
        unit="${BASH_REMATCH[2]}"

        # Convert to seconds based on unit
        case "$unit" in
        "m") echo $((numeric_value * 60)) ;;
        "s" | "") echo "$numeric_value" ;; # Default to seconds
        *) return 1 ;;                     # Invalid unit
        esac
        return 0
    else
        return 1 # Invalid format
    fi
}

# ============================================================================
# CACHE VALIDATION
# ============================================================================

# Check if cache file is fresh (not expired)
is_cache_fresh() {
    local cache_file="$1"
    local cache_duration="${2:-30}" # Default 30 seconds
    
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(get_timestamp) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        [[ $cache_age -lt $cache_duration ]]
    else
        return 1
    fi
}

# Remove stale lock files from dead processes
cleanup_stale_locks() {
    local lock_file="$1"
    local max_age="${2:-120}" # Default 2 minutes
    
    if [[ -f "$lock_file" ]]; then
        local lock_content=$(cat "$lock_file" 2>/dev/null)
        local lock_age=$(($(get_timestamp) - $(stat -f %m "$lock_file" 2>/dev/null || stat -c %Y "$lock_file" 2>/dev/null || echo 0)))

        # Extract PID from lock file format: "instance:PID:timestamp" or "PID:timestamp:instance"
        local lock_pid
        if [[ "$lock_content" =~ :([0-9]+): ]]; then
            lock_pid="${BASH_REMATCH[1]}"  # PID is in the middle
        elif [[ "$lock_content" =~ ^([0-9]+): ]]; then
            lock_pid="${BASH_REMATCH[1]}"  # PID is at the start
        else
            lock_pid="$lock_content"       # Fallback: assume entire content is PID
        fi

        # Remove lock if process is dead OR lock is older than max_age
        if [[ -n "$lock_pid" ]] && (! kill -0 "$lock_pid" 2>/dev/null || [[ $lock_age -gt $max_age ]]); then
            rm -f "$lock_file" 2>/dev/null
            debug_log "Removed stale lock file: $lock_file (PID: $lock_pid, age: ${lock_age}s)" "INFO"
        fi
    fi
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the security module
init_security_module() {
    debug_log "Security module initialized" "INFO"
    return 0
}

# Initialize the module
init_security_module

# Export security functions
export -f sanitize_path_secure create_secure_cache_file validate_ansi_color
export -f execute_python_safely parse_mcp_server_name_secure
export -f parse_timeout_to_seconds is_cache_fresh cleanup_stale_locks