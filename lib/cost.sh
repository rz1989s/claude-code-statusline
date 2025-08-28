#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Tracking Module
# ============================================================================
# 
# This module handles all cost tracking and billing information using
# ccusage integration, including session costs, daily/weekly/monthly totals,
# and active billing block management.
#

# CRITICAL EMERGENCY FIX: Set date format defaults immediately to fix DAY $0.00 bug
[[ -z "$CONFIG_DATE_FORMAT" ]] && export CONFIG_DATE_FORMAT="%Y-%m-%d"
[[ -z "$CONFIG_DATE_FORMAT_COMPACT" ]] && export CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# COST TRACKING CONSTANTS
# ============================================================================

# Cache settings for cost data - differentiated by data type
export COST_CACHE_DURATION_LIVE=30        # 30 seconds - active blocks (real-time)
export COST_CACHE_DURATION_SESSION=120    # 2 minutes - repository session cost
export COST_CACHE_DURATION_DAILY=60       # 1 minute - today's cost
export COST_CACHE_DURATION_WEEKLY=3600    # 1 hour - 7-day total (major reduction!)
export COST_CACHE_DURATION_MONTHLY=7200   # 2 hours - 30-day total (huge reduction!)
# Use the proper XDG-compliant cache directory from cache.sh module
export COST_CACHE_DIR="${CACHE_BASE_DIR:-/tmp/.claude_statusline_cache}"

# Instance-specific session marker (prevents race conditions between multiple Claude Code instances)
# Function to get current instance ID dynamically (checks env var each time)
get_instance_id() {
    # Priority: CLAUDE_INSTANCE_ID env var > PPID > current PID  
    echo "${CLAUDE_INSTANCE_ID:-${PPID:-$$}}"
}

# Function to get the current session marker (allows dynamic instance ID)
get_session_marker() {
    local instance_id
    instance_id=$(get_instance_id)
    echo "/tmp/.claude_statusline_session_${instance_id}"
}

# Cleanup old session markers (older than 24 hours) and orphaned markers
cleanup_old_session_markers() {
    # Remove old markers (older than 24 hours)
    find /tmp -name ".claude_statusline_session_*" -mtime +1 -delete 2>/dev/null || true
    
    # Remove orphaned markers (where the parent process no longer exists)
    local marker
    for marker in /tmp/.claude_statusline_session_*; do
        # Skip if glob didn't match any files
        [[ -f "$marker" ]] || continue
        
        local marker_pid="${marker##*_}"
        if [[ "$marker_pid" =~ ^[0-9]+$ ]] && ! kill -0 "$marker_pid" 2>/dev/null; then
            rm -f "$marker" 2>/dev/null
            debug_log "Removed orphaned session marker for dead process: $marker_pid" "INFO"
        fi
    done
}

# Validate cache file integrity (check if it contains valid JSON)
validate_cache_file() {
    local cache_file="$1"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    # Check if file is not empty and contains valid JSON
    if [[ -s "$cache_file" ]] && jq empty "$cache_file" 2>/dev/null; then
        return 0
    else
        debug_log "Invalid cache file detected: $(basename "$cache_file")" "WARN"
        return 1
    fi
}

# Cache file names
export BLOCKS_CACHE_FILE="$COST_CACHE_DIR/blocks.json"
export SESSION_CACHE_FILE="$COST_CACHE_DIR/session.json"
export DAILY_CACHE_FILE="$COST_CACHE_DIR/daily_7d.json"
export MONTHLY_CACHE_FILE="$COST_CACHE_DIR/monthly_30d.json"

# Default cost values
export DEFAULT_COST="0.00"

# ============================================================================
# CCUSAGE AVAILABILITY CHECKING
# ============================================================================

# Check if ccusage is available via bunx
is_ccusage_available() {
    if ! command_exists bunx; then
        debug_log "bunx not available for ccusage" "INFO"
        return 1
    fi
    
    # Use universal caching for ccusage availability check (6-hour cache)
    local ccusage_check_result
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        ccusage_check_result=$(cache_external_command "ccusage_availability" "$CACHE_DURATION_VERY_LONG" "validate_command_output" bash -c 'bunx ccusage --version >/dev/null 2>&1 && echo "available" || echo "unavailable"')
        if [[ "$ccusage_check_result" == "available" ]]; then
            debug_log "ccusage available via bunx (cached)" "INFO"
            return 0
        else
            debug_log "ccusage not available via bunx (cached)" "INFO"
            return 1
        fi
    else
        # Fallback to direct execution
        if bunx ccusage --version >/dev/null 2>&1; then
            debug_log "ccusage available via bunx" "INFO"
            return 0
        else
            debug_log "ccusage not available via bunx" "INFO"
            return 1
        fi
    fi
}

# ============================================================================
# CACHE MANAGEMENT
# ============================================================================

# Initialize cost cache directory
init_cost_cache() {
    if [[ ! -d "$COST_CACHE_DIR" ]]; then
        mkdir -p "$COST_CACHE_DIR" 2>/dev/null
        chmod 700 "$COST_CACHE_DIR" 2>/dev/null # Secure permissions to prevent other users from reading cost data
        debug_log "Created cost cache directory: $COST_CACHE_DIR" "INFO"
    fi
}

# Enhanced ccusage execution with intelligent caching and startup detection
execute_ccusage_with_cache() {
    local cache_file="$1"
    local ccusage_command="$2"
    local cache_duration="$3"  # Now accepts custom cache duration!
    local timeout_duration="${4:-$CONFIG_CCUSAGE_TIMEOUT}"
    
    # Startup detection: Force refresh all data on first Claude Code startup
    cleanup_old_session_markers  # Clean up old markers first
    
    local force_refresh=false
    local session_marker instance_id
    session_marker=$(get_session_marker)
    instance_id=$(get_instance_id)
    
    if [[ ! -f "$session_marker" ]]; then
        force_refresh=true
        # Create persistent session marker for this Claude Code instance
        echo "$(date '+%Y-%m-%d %H:%M:%S') Instance: $instance_id PID: $PPID" > "$session_marker" 2>/dev/null
        debug_log "First startup for Claude Code instance $instance_id - forcing refresh of all ccusage data" "INFO"
    else
        debug_log "Subsequent call for instance $instance_id - using intelligent cache durations" "INFO"
    fi
    
    # Check if cache is fresh and valid (skip if force refresh)
    if [[ "$force_refresh" != "true" ]] && [[ -f "$cache_file" ]] && is_cache_fresh "$cache_file" "$cache_duration"; then
        # Validate cache file integrity before using
        if validate_cache_file "$cache_file"; then
            cat "$cache_file" 2>/dev/null
            debug_log "Using cached ccusage data: $(basename "$cache_file")" "INFO"
            return 0
        else
            debug_log "Cache file corrupted, forcing refresh: $(basename "$cache_file")" "WARN"
            rm -f "$cache_file" 2>/dev/null  # Remove corrupted cache
        fi
    fi
    
    local lock_file="${cache_file}.lock"
    
    # Clean up stale locks
    cleanup_stale_locks "$lock_file"
    
    # Enhanced lock acquisition with retry logic (prevents race conditions)
    local max_retries=3
    local retry_count=0
    local lock_acquired=false
    
    while [[ $retry_count -lt $max_retries ]]; do
        # Try to acquire lock atomically
        if (
            set -C  # noclobber mode prevents overwriting existing files
            echo "$$:$(date +%s):$CLAUDE_INSTANCE_ID" >"$lock_file" 2>/dev/null
        ); then
            lock_acquired=true
            break
        else
            retry_count=$((retry_count + 1))
            debug_log "Lock acquisition attempt $retry_count/$max_retries failed: $(basename "$cache_file")" "INFO"
            
            # Brief backoff to avoid thundering herd
            sleep "0.$(( (RANDOM % 5) + 1 ))"  # Random 0.1-0.5 second delay
        fi
    done
    
    if [[ "$lock_acquired" == "true" ]]; then
        debug_log "Acquired lock for ccusage: $(basename "$cache_file")" "INFO"
        
        # Execute ccusage command
        local fresh_data
        if command_exists timeout; then
            fresh_data=$(timeout "$timeout_duration" bunx ccusage $ccusage_command --json 2>/dev/null)
        elif command_exists gtimeout; then
            fresh_data=$(gtimeout "$timeout_duration" bunx ccusage $ccusage_command --json 2>/dev/null)
        else
            fresh_data=$(bunx ccusage $ccusage_command --json 2>/dev/null)
        fi
        
        # Cache the result if successful using atomic write
        if [[ $? -eq 0 && -n "$fresh_data" ]]; then
            # Atomic write: write to temp file, then rename
            local temp_file="${cache_file}.tmp.$$"
            if echo "$fresh_data" > "$temp_file" 2>/dev/null && mv "$temp_file" "$cache_file" 2>/dev/null; then
                debug_log "Cached fresh ccusage data: $(basename "$cache_file")" "INFO"
                echo "$fresh_data"
            else
                debug_log "Failed to write cache file: $(basename "$cache_file")" "WARN"
                rm -f "$temp_file" 2>/dev/null  # Cleanup failed temp file
                echo "$fresh_data"  # Still return the data even if caching failed
            fi
        else
            debug_log "Failed to get fresh ccusage data: $(basename "$cache_file")" "WARN"
            # Return cached data if available, even if stale
            if [[ -f "$cache_file" ]]; then
                cat "$cache_file" 2>/dev/null
            fi
        fi
        
        # Release lock
        rm -f "$lock_file" 2>/dev/null
    else
        debug_log "Lock acquisition failed after $max_retries attempts: $(basename "$cache_file")" "WARN"
        # Another instance is likely refreshing, use existing cache if valid
        if [[ -f "$cache_file" ]] && validate_cache_file "$cache_file"; then
            debug_log "Using existing cache while other instance refreshes: $(basename "$cache_file")" "INFO"
            cat "$cache_file" 2>/dev/null
        fi
    fi
}

# ============================================================================
# DATE CALCULATION UTILITIES
# ============================================================================

# Calculate dates for cost queries
calculate_cost_dates() {
    local seven_days_ago thirty_days_ago today
    
    # CRITICAL FIX: Ensure date format variables are never empty (fallback to hardcoded defaults)
    # This fixes the DAY $0.00 issue when TOML configuration fails to load
    # Apply fallbacks whenever the variables are empty, even if they were set to empty strings by config loading
    if [[ -z "$CONFIG_DATE_FORMAT" || "$CONFIG_DATE_FORMAT" == "" ]]; then
        export CONFIG_DATE_FORMAT="%Y-%m-%d"
        debug_log "Applied fallback for CONFIG_DATE_FORMAT: %Y-%m-%d" "INFO"
    fi
    if [[ -z "$CONFIG_DATE_FORMAT_COMPACT" || "$CONFIG_DATE_FORMAT_COMPACT" == "" ]]; then
        export CONFIG_DATE_FORMAT_COMPACT="%Y%m%d"
        debug_log "Applied fallback for CONFIG_DATE_FORMAT_COMPACT: %Y%m%d" "INFO"
    fi
    
    # Calculate dates with proper fallbacks
    if date -d '7 days ago' "+$CONFIG_DATE_FORMAT_COMPACT" >/dev/null 2>&1; then
        # GNU date (Linux)
        seven_days_ago=$(date -d '7 days ago' "+$CONFIG_DATE_FORMAT_COMPACT")
        thirty_days_ago=$(date -d '30 days ago' "+$CONFIG_DATE_FORMAT_COMPACT")
    elif date -v-7d "+$CONFIG_DATE_FORMAT_COMPACT" >/dev/null 2>&1; then
        # BSD date (macOS)
        seven_days_ago=$(date -v-7d "+$CONFIG_DATE_FORMAT_COMPACT")
        thirty_days_ago=$(date -v-30d "+$CONFIG_DATE_FORMAT_COMPACT")
    else
        # Fallback for systems without proper date arithmetic
        local current_epoch=$(date +%s)
        local seven_days_epoch=$((current_epoch - 7 * 24 * 3600))
        local thirty_days_epoch=$((current_epoch - 30 * 24 * 3600))
        seven_days_ago=$(date -d "@$seven_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || date -r "$seven_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || echo "$(date "+$CONFIG_DATE_FORMAT_COMPACT")")
        thirty_days_ago=$(date -d "@$thirty_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || date -r "$thirty_days_epoch" "+$CONFIG_DATE_FORMAT_COMPACT" 2>/dev/null || echo "$(date "+$CONFIG_DATE_FORMAT_COMPACT")")
    fi
    
    today=$(date "+$CONFIG_DATE_FORMAT")
    
    # Export for use by other functions
    export COST_SEVEN_DAYS_AGO="$seven_days_ago"
    export COST_THIRTY_DAYS_AGO="$thirty_days_ago"
    export COST_TODAY="$today"
    
    debug_log "Cost dates calculated - today: $today, 7d: $seven_days_ago, 30d: $thirty_days_ago" "INFO"
}

# ============================================================================
# INDIVIDUAL COST DATA RETRIEVAL
# ============================================================================

# Get active billing blocks information
get_active_blocks_data() {
    if ! is_ccusage_available; then
        return 1
    fi
    
    execute_ccusage_with_cache "$BLOCKS_CACHE_FILE" "blocks --active" "$COST_CACHE_DURATION_LIVE"
}

# Get session cost data
get_session_cost_data() {
    if ! is_ccusage_available; then
        return 1
    fi
    
    calculate_cost_dates
    
    # Use repository-aware session cache file to prevent cross-contamination
    local session_cache_file
    if [[ "${CACHE_CONFIG_SESSION_ISOLATION:-}" == "repository" ]]; then
        local repo_id
        repo_id=$(get_repo_identifier "$PWD" "path")
        session_cache_file="$COST_CACHE_DIR/session_${repo_id}.json"
        debug_log "Using repository-aware session cache: $(basename "$session_cache_file")" "INFO"
    else
        session_cache_file="$SESSION_CACHE_FILE"
        debug_log "Using shared session cache: $(basename "$session_cache_file")" "INFO"
    fi
    
    execute_ccusage_with_cache "$session_cache_file" "session --since $COST_SEVEN_DAYS_AGO" "$COST_CACHE_DURATION_SESSION"
}

# Get daily cost data (7 days)
get_daily_cost_data() {
    if ! is_ccusage_available; then
        return 1
    fi
    
    calculate_cost_dates
    execute_ccusage_with_cache "$DAILY_CACHE_FILE" "daily --since $COST_SEVEN_DAYS_AGO" "$COST_CACHE_DURATION_DAILY"
}

# Get monthly cost data (30 days)
get_monthly_cost_data() {
    if ! is_ccusage_available; then
        return 1
    fi
    
    calculate_cost_dates
    execute_ccusage_with_cache "$MONTHLY_CACHE_FILE" "daily --since $COST_THIRTY_DAYS_AGO" "$COST_CACHE_DURATION_MONTHLY"
}

# ============================================================================
# COST DATA PROCESSING
# ============================================================================

# Extract session cost for current directory
extract_session_cost() {
    local session_data="$1"
    local current_dir="${2:-$(pwd)}"
    local session_id
    
    session_id=$(sanitize_path_secure "$current_dir")
    
    if [[ -z "$session_data" ]] || ! echo "$session_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi
    
    local session_cost
    session_cost=$(echo "$session_data" | jq -r --arg session_id "$session_id" '.sessions[] | select(.sessionId == $session_id) | .totalCost // 0' 2>/dev/null | head -1)
    
    if [[ -z "$session_cost" || "$session_cost" == "null" ]]; then
        session_cost="$DEFAULT_COST"
    fi
    
    printf "%.2f" "$session_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# Extract today's cost from daily data
extract_today_cost() {
    local daily_data="$1"
    
    if [[ -z "$daily_data" ]] || ! echo "$daily_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi
    
    calculate_cost_dates
    local today_cost
    today_cost=$(echo "$daily_data" | jq -r --arg today "$COST_TODAY" '.daily[] | select(.date == $today) | .totalCost // 0' 2>/dev/null | head -1)
    
    if [[ -z "$today_cost" || "$today_cost" == "null" ]]; then
        today_cost="$DEFAULT_COST"
    fi
    
    printf "%.2f" "$today_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# Extract weekly cost (excluding today)
extract_weekly_cost() {
    local daily_data="$1"
    local today_cost="${2:-0.00}"
    
    if [[ -z "$daily_data" ]] || ! echo "$daily_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi
    
    local total_cost
    total_cost=$(echo "$daily_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)
    
    if [[ -z "$total_cost" || "$total_cost" == "null" ]]; then
        total_cost="$DEFAULT_COST"
    fi
    
    # Subtract today's cost to get only the last 7 days without today
    local week_cost
    if command_exists bc; then
        week_cost=$(echo "$total_cost - $today_cost" | bc -l 2>/dev/null || echo "0.00")
    else
        # Fallback using shell arithmetic (less precise for floating point)
        week_cost=$(awk "BEGIN {printf \"%.2f\", $total_cost - $today_cost}" 2>/dev/null || echo "0.00")
    fi
    
    printf "%.2f" "$week_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# Extract monthly cost
extract_monthly_cost() {
    local monthly_data="$1"
    
    if [[ -z "$monthly_data" ]] || ! echo "$monthly_data" | jq empty 2>/dev/null; then
        echo "$DEFAULT_COST"
        return 1
    fi
    
    local month_cost
    month_cost=$(echo "$monthly_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)
    
    if [[ -z "$month_cost" || "$month_cost" == "null" ]]; then
        month_cost="$DEFAULT_COST"
    fi
    
    printf "%.2f" "$month_cost" 2>/dev/null || echo "$DEFAULT_COST"
}

# ============================================================================
# ACTIVE BLOCK PROCESSING
# ============================================================================

# Process active billing block information
process_active_blocks() {
    local block_data="$1"
    
    if [[ -z "$block_data" ]] || ! echo "$block_data" | jq empty 2>/dev/null; then
        echo "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE:$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
        return 1
    fi
    
    local block_cost remaining_minutes is_active
    block_cost=$(echo "$block_data" | jq -r '.blocks[0].costUSD // 0' 2>/dev/null)
    remaining_minutes=$(echo "$block_data" | jq -r '.blocks[0].projection.remainingMinutes // null' 2>/dev/null)
    is_active=$(echo "$block_data" | jq -r '.blocks[0].isActive // false' 2>/dev/null)
    
    # Enhanced block detection with three states
    if [[ "$is_active" == "true" ]]; then
        # Get reset time from endTime and convert to local time (always needed)
        local end_time reset_time
        end_time=$(echo "$block_data" | jq -r '.blocks[0].endTime // ""' 2>/dev/null)
        
        if [[ -n "$end_time" && "$end_time" != "null" ]]; then
            reset_time=$(execute_python_safely "
import datetime
utc_time = datetime.datetime.fromisoformat('$end_time'.replace('Z', '+00:00'))
local_time = utc_time.replace(tzinfo=datetime.timezone.utc).astimezone()
print(local_time.strftime('%H.%M'))
" "")
        fi
        
        local block_info reset_info time_str
        block_info=$(printf "%s%s \$%.2f" "$CONFIG_LIVE_BLOCK_EMOJI" "$CONFIG_LIVE_LABEL" "$block_cost")
        
        # Check if we have valid projection data
        if [[ "$remaining_minutes" != "null" && "$remaining_minutes" -gt 0 ]]; then
            # Valid projection: show normal countdown
            local hours=$((remaining_minutes / 60))
            local mins=$((remaining_minutes % 60))
            
            if [[ "$hours" -gt 0 ]]; then
                time_str="${hours}h ${mins}m left"
            else
                time_str="${mins}m left"
            fi
        else
            # Active block but no projection: API still calculating
            time_str="waiting API response..."
        fi
        
        # Format reset info
        if [[ -n "$reset_time" ]]; then
            reset_info=$(printf "$CONFIG_RESET_LABEL at %s (%s)" "$reset_time" "$time_str")
        else
            reset_info=$(printf "$CONFIG_RESET_LABEL (%s)" "$time_str")
        fi
        
        echo "$block_info:$reset_info"
    else
        echo "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE:$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
    fi
}

# ============================================================================
# MAIN COST INFORMATION FUNCTION
# ============================================================================

# Get comprehensive Claude usage information
get_claude_usage_info() {
    start_timer "cost_tracking"
    
    # Check if ccusage is available
    if ! is_ccusage_available; then
        local no_ccusage_info="-.--:-.--:-.--:-.--:$CONFIG_NO_CCUSAGE_MESSAGE:$CONFIG_CCUSAGE_INSTALL_MESSAGE"
        end_timer "cost_tracking"
        echo "$no_ccusage_info"
        return 0
    fi
    
    # Initialize cache
    init_cost_cache
    
    # Get all cost data in parallel (via caching system)
    local session_data daily_data monthly_data block_data
    
    debug_log "Fetching cost data..." "INFO"
    
    session_data=$(get_session_cost_data)
    daily_data=$(get_daily_cost_data)
    monthly_data=$(get_monthly_cost_data)
    block_data=$(get_active_blocks_data)
    
    # Process costs
    local session_cost today_cost week_cost month_cost
    
    session_cost=$(extract_session_cost "$session_data")
    today_cost=$(extract_today_cost "$daily_data")
    week_cost=$(extract_weekly_cost "$daily_data" "$today_cost")
    month_cost=$(extract_monthly_cost "$monthly_data")
    
    # Process active block info
    local block_info
    block_info=$(process_active_blocks "$block_data")
    local block_cost_info="${block_info%:*}"
    local reset_info="${block_info#*:}"
    
    local tracking_time
    tracking_time=$(end_timer "cost_tracking")
    debug_log "Cost tracking completed in ${tracking_time}s" "INFO"
    
    # Return the formatted string
    echo "${session_cost}:${month_cost}:${week_cost}:${today_cost}:${block_cost_info}:${reset_info}"
}

# ============================================================================
# COST UTILITIES
# ============================================================================

# Format cost for display
format_cost() {
    local cost="$1"
    local prefix="${2:-\$}"
    
    if [[ "$cost" == "-.--" ]] || [[ -z "$cost" ]]; then
        echo "${prefix}-.--"
    else
        printf "%s%.2f" "$prefix" "$cost" 2>/dev/null || echo "${prefix}-.--"
    fi
}

# Get cost trend (increase/decrease from previous period)
get_cost_trend() {
    local current_cost="$1"
    local previous_cost="$2"
    
    if [[ "$current_cost" == "-.--" ]] || [[ "$previous_cost" == "-.--" ]]; then
        echo "unknown"
        return 1
    fi
    
    if command_exists bc; then
        local diff
        diff=$(echo "$current_cost - $previous_cost" | bc -l 2>/dev/null)
        
        if [[ "$diff" =~ ^- ]]; then
            echo "down"
        elif [[ "$diff" =~ ^0.?0*$ ]]; then
            echo "stable"
        else
            echo "up"
        fi
    else
        echo "unknown"
    fi
}

# Clear cost cache (for testing/troubleshooting)
clear_cost_cache() {
    debug_log "Clearing cost cache..." "INFO"
    rm -f "$COST_CACHE_DIR"/*.json 2>/dev/null
    rm -f "$COST_CACHE_DIR"/*.lock 2>/dev/null
    debug_log "Cost cache cleared" "INFO"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the cost tracking module
init_cost_module() {
    debug_log "Cost tracking module initialized" "INFO"
    
    # Check ccusage availability
    if ! is_ccusage_available; then
        handle_warning "ccusage not available - cost tracking disabled" "init_cost_module"
        debug_log "To enable cost tracking: npm install -g ccusage" "INFO"
        return 1
    fi
    
    # Initialize cache
    init_cost_cache
    
    # Log ccusage version for debugging (using universal caching)
    local ccusage_version
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        ccusage_version=$(cache_external_command "ccusage_version" "$CACHE_DURATION_VERY_LONG" "validate_command_output" bunx ccusage --version)
        debug_log "ccusage version: $ccusage_version (cached)" "INFO"
    else
        ccusage_version=$(bunx ccusage --version 2>/dev/null)
        debug_log "ccusage version: $ccusage_version" "INFO"
    fi
    
    return 0
}

# Initialize the module
init_cost_module

# Export cost tracking functions
export -f is_ccusage_available init_cost_cache execute_ccusage_with_cache
export -f cleanup_old_session_markers validate_cache_file get_instance_id get_session_marker
export -f calculate_cost_dates get_active_blocks_data get_session_cost_data
export -f get_daily_cost_data get_monthly_cost_data
export -f extract_session_cost extract_today_cost extract_weekly_cost extract_monthly_cost
export -f process_active_blocks get_claude_usage_info
export -f format_cost get_cost_trend clear_cost_cache