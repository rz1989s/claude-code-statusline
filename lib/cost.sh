#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cost Tracking Module
# ============================================================================
#
# This module handles all cost tracking and billing information using
# ccusage integration, including session costs, daily/weekly/monthly totals,
# and active billing block management.
#
# Error Suppression Patterns (Issue #76):
# - jq empty 2>/dev/null: JSON validation where invalid data returns fallback
# - date -d/-r 2>/dev/null: Cross-platform date (GNU -d vs BSD -r)
# - bunx ccusage 2>/dev/null: External tool may not be installed
# - printf "%.2f" 2>/dev/null: Numeric formatting with fallback on invalid input
# - kill -0 2>/dev/null: Process existence check (expected to fail for dead PIDs)
# - rm/mkdir/chmod 2>/dev/null: Best-effort filesystem ops (race conditions)
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
        # Note: Chained date calls try GNU (-d @epoch) then BSD (-r epoch) then today as final fallback
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
# UNIFIED BLOCK METRICS DATA COLLECTION (v2.10.0)
# ============================================================================

# Format tokens for display (compact format)
format_tokens_compact() {
    local tokens="$1"
    
    if [[ -z "$tokens" || "$tokens" == "null" || "$tokens" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # Convert to millions/thousands with appropriate suffix
    # Use awk for all arithmetic to handle floating point properly
    local result
    result=$(awk "BEGIN {
        tokens = $tokens;
        if (tokens >= 1000000) {
            printf \"%.1fM\", tokens / 1000000;
        } else if (tokens >= 1000) {
            printf \"%.1fk\", tokens / 1000;
        } else {
            printf \"%.0f\", tokens;
        }
    }" 2>/dev/null)
    
    if [[ -n "$result" ]]; then
        echo "$result"
    else
        # Fallback for very old awk versions
        echo "$tokens"
    fi
}

# Format tokens for burn rate (per minute format)
format_tokens_per_minute() {
    local tokens_per_min="$1"
    
    if [[ -z "$tokens_per_min" || "$tokens_per_min" == "null" || "$tokens_per_min" == "0" ]]; then
        echo "0/min"
        return 0
    fi
    
    local formatted=$(format_tokens_compact "$tokens_per_min")
    echo "${formatted}/min"
}

# Get unified block metrics - ONE ccusage call for ALL components
get_unified_block_metrics() {
    debug_log "Getting unified block metrics..." "INFO"
    
    # Check if ccusage is available
    if ! is_ccusage_available; then
        # Return default values for all metrics (colon-separated)
        echo "0:0:0:0:0:0:0"
        return 1
    fi
    
    # Use cache with 30s TTL for rapidly changing block data
    local cache_file="$COST_CACHE_DIR/unified_block_metrics.cache"
    
    # Check cache first
    if [[ -f "$cache_file" ]] && is_cache_fresh "$cache_file" 30; then
        local cached_data=$(cat "$cache_file" 2>/dev/null)
        if [[ -n "$cached_data" ]]; then
            debug_log "Using cached unified block metrics" "INFO"
            echo "$cached_data"
            return 0
        fi
    fi
    
    # Get fresh block data using existing function
    local block_data
    block_data=$(get_active_blocks_data)
    
    if [[ -z "$block_data" ]] || ! echo "$block_data" | jq empty 2>/dev/null; then
        debug_log "No valid block data available" "WARN"
        echo "0:0:0:0:0:0:0"
        return 1
    fi
    
    # Parse ALL metrics at once from the block data
    local burn_rate cost_per_hour total_tokens cache_read cache_creation proj_cost proj_tokens
    
    # Extract burn rate metrics
    burn_rate=$(echo "$block_data" | jq -r '.blocks[0].burnRate.tokensPerMinute // 0' 2>/dev/null)
    cost_per_hour=$(echo "$block_data" | jq -r '.blocks[0].burnRate.costPerHour // 0' 2>/dev/null)
    
    # Extract token usage
    total_tokens=$(echo "$block_data" | jq -r '.blocks[0].totalTokens // 0' 2>/dev/null)
    
    # Extract cache metrics
    cache_read=$(echo "$block_data" | jq -r '.blocks[0].tokenCounts.cacheReadInputTokens // 0' 2>/dev/null)
    cache_creation=$(echo "$block_data" | jq -r '.blocks[0].tokenCounts.cacheCreationInputTokens // 0' 2>/dev/null)
    
    # Extract projection metrics
    proj_cost=$(echo "$block_data" | jq -r '.blocks[0].projection.totalCost // 0' 2>/dev/null)
    proj_tokens=$(echo "$block_data" | jq -r '.blocks[0].projection.totalTokens // 0' 2>/dev/null)
    
    # Format the unified metrics string (colon-separated)
    local unified_metrics="${burn_rate}:${cost_per_hour}:${total_tokens}:${cache_read}:${cache_creation}:${proj_cost}:${proj_tokens}"
    
    # Cache the results for 30 seconds
    echo "$unified_metrics" > "$cache_file" 2>/dev/null
    
    debug_log "Unified block metrics cached: burn_rate=${burn_rate}, tokens=${total_tokens}" "INFO"
    echo "$unified_metrics"
    return 0
}

# ============================================================================
# NATIVE COST EXTRACTION (Issue #99)
# ============================================================================
# Extract cost data directly from Anthropic's native statusline JSON input.
# This provides zero-latency cost data without external ccusage calls.
# Available in Claude Code v1.0.85+

# Extract native session cost from Anthropic JSON input
# Returns: cost value or empty string if unavailable
get_native_session_cost() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        debug_log "No native JSON input available for cost extraction" "INFO"
        echo ""
        return 1
    fi

    local native_cost
    native_cost=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)

    if [[ -n "$native_cost" && "$native_cost" != "null" ]]; then
        # Format to 2 decimal places
        printf "%.2f" "$native_cost" 2>/dev/null || echo ""
        return 0
    else
        echo ""
        return 1
    fi
}

# Extract native duration from Anthropic JSON input
# Returns: duration in ms or empty string if unavailable
get_native_session_duration() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_duration_ms // empty' 2>/dev/null
}

# Extract native API duration from Anthropic JSON input
# Returns: API duration in ms or empty string if unavailable
get_native_api_duration() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_api_duration_ms // empty' 2>/dev/null
}

# Debug comparison: Log native vs ccusage cost side-by-side
# This helps validate that native data matches ccusage before production use
compare_native_vs_ccusage_cost() {
    local native_cost ccusage_cost

    # Get native cost
    native_cost=$(get_native_session_cost)

    # Get ccusage cost (extract from full usage info)
    if is_ccusage_available; then
        local usage_info
        usage_info=$(get_claude_usage_info)
        ccusage_cost="${usage_info%%:*}"
    else
        ccusage_cost="N/A"
    fi

    # Format for comparison
    local native_display="${native_cost:-N/A}"
    local ccusage_display="${ccusage_cost:-N/A}"

    # Calculate difference if both are available
    local diff_display="N/A"
    if [[ -n "$native_cost" && "$ccusage_cost" != "N/A" && "$ccusage_cost" != "-.--" ]]; then
        local diff
        diff=$(awk "BEGIN {printf \"%.4f\", $native_cost - $ccusage_cost}" 2>/dev/null)
        if [[ -n "$diff" ]]; then
            diff_display="$diff"
        fi
    fi

    # Log the comparison (always visible in debug mode)
    debug_log "[COST COMPARE] Native: \$$native_display | ccusage: \$$ccusage_display | Diff: \$$diff_display" "INFO"

    # Return comparison data for further processing
    echo "${native_display}:${ccusage_display}:${diff_display}"
}

# Get session cost with source preference
# Supports: auto | native | ccusage
get_session_cost_with_source() {
    local source="${1:-auto}"

    case "$source" in
        "native")
            local native_cost
            native_cost=$(get_native_session_cost)
            if [[ -n "$native_cost" ]]; then
                echo "$native_cost"
            else
                echo "$DEFAULT_COST"
            fi
            ;;
        "ccusage")
            if is_ccusage_available; then
                local usage_info
                usage_info=$(get_claude_usage_info)
                echo "${usage_info%%:*}"
            else
                echo "$DEFAULT_COST"
            fi
            ;;
        "auto"|*)
            # Prefer native if available, fallback to ccusage
            local native_cost
            native_cost=$(get_native_session_cost)

            if [[ -n "$native_cost" && "$native_cost" != "0.00" ]]; then
                debug_log "Using native cost source: \$$native_cost" "INFO"
                echo "$native_cost"
            elif is_ccusage_available; then
                local usage_info
                usage_info=$(get_claude_usage_info)
                local ccusage_cost="${usage_info%%:*}"
                debug_log "Using ccusage cost source: \$$ccusage_cost" "INFO"
                echo "$ccusage_cost"
            else
                echo "$DEFAULT_COST"
            fi
            ;;
    esac
}

# Export native cost functions
export -f get_native_session_cost get_native_session_duration get_native_api_duration
export -f compare_native_vs_ccusage_cost get_session_cost_with_source

# ============================================================================
# NATIVE CACHE EFFICIENCY EXTRACTION (Issue #103)
# ============================================================================
# Extract cache token data from Anthropic's native current_usage field.
# This provides real-time cache efficiency without ccusage calls.

# Extract native cache read tokens from Anthropic JSON input
get_native_cache_read_tokens() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local tokens
    tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_read_input_tokens // 0' 2>/dev/null)
    echo "${tokens:-0}"
}

# Extract native cache creation tokens from Anthropic JSON input
get_native_cache_creation_tokens() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local tokens
    tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_creation_input_tokens // 0' 2>/dev/null)
    echo "${tokens:-0}"
}

# Calculate cache efficiency from native data
# Returns: efficiency percentage (0-100)
get_native_cache_efficiency() {
    local cache_read cache_creation total efficiency

    cache_read=$(get_native_cache_read_tokens)
    cache_creation=$(get_native_cache_creation_tokens)

    # Handle null/empty values
    [[ -z "$cache_read" || "$cache_read" == "null" ]] && cache_read=0
    [[ -z "$cache_creation" || "$cache_creation" == "null" ]] && cache_creation=0

    total=$((cache_read + cache_creation))

    if [[ "$total" -gt 0 ]]; then
        efficiency=$(awk "BEGIN {printf \"%.0f\", $cache_read * 100 / $total}" 2>/dev/null)
        echo "${efficiency:-0}"
    else
        echo "0"
    fi
}

# Debug comparison: Log native vs ccusage cache efficiency side-by-side
compare_native_vs_ccusage_cache() {
    local native_read native_creation native_eff
    local ccusage_read ccusage_creation ccusage_eff

    # Get native values
    native_read=$(get_native_cache_read_tokens)
    native_creation=$(get_native_cache_creation_tokens)

    # Calculate native efficiency
    local native_total=$((native_read + native_creation))
    if [[ "$native_total" -gt 0 ]]; then
        native_eff=$(awk "BEGIN {printf \"%.0f\", $native_read * 100 / $native_total}" 2>/dev/null)
    else
        native_eff="N/A"
    fi

    # Get ccusage values
    if is_ccusage_available; then
        local metrics
        metrics=$(get_unified_block_metrics)

        if [[ -n "$metrics" && "$metrics" != "0:0:0:0:0:0:0" ]]; then
            ccusage_read=$(echo "$metrics" | cut -d: -f4)
            ccusage_creation=$(echo "$metrics" | cut -d: -f5)

            local ccusage_total=$((ccusage_read + ccusage_creation))
            if [[ "$ccusage_total" -gt 0 ]]; then
                ccusage_eff=$(awk "BEGIN {printf \"%.0f\", $ccusage_read * 100 / $ccusage_total}" 2>/dev/null)
            else
                ccusage_eff="N/A"
            fi
        else
            ccusage_read="N/A"
            ccusage_creation="N/A"
            ccusage_eff="N/A"
        fi
    else
        ccusage_read="N/A"
        ccusage_creation="N/A"
        ccusage_eff="N/A"
    fi

    # Format displays
    local native_display="${native_eff}% (read:${native_read}/create:${native_creation})"
    local ccusage_display="${ccusage_eff}% (read:${ccusage_read}/create:${ccusage_creation})"

    # Log the comparison
    debug_log "[CACHE COMPARE] Native: $native_display | ccusage: $ccusage_display" "INFO"

    # Return comparison data
    echo "${native_eff}:${native_read}:${native_creation}:${ccusage_eff}:${ccusage_read}:${ccusage_creation}"
}

# Export native cache functions
export -f get_native_cache_read_tokens get_native_cache_creation_tokens
export -f get_native_cache_efficiency compare_native_vs_ccusage_cache

# ============================================================================
# NATIVE CODE PRODUCTIVITY EXTRACTION (Issue #100)
# ============================================================================
# Extract lines added/removed from Anthropic's native cost object.
# Provides real-time code productivity metrics.

# Extract lines added from Anthropic JSON input
get_native_lines_added() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local lines
    lines=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_lines_added // 0' 2>/dev/null)
    echo "${lines:-0}"
}

# Extract lines removed from Anthropic JSON input
get_native_lines_removed() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo "0"
        return 1
    fi

    local lines
    lines=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null)
    echo "${lines:-0}"
}

# Get formatted code productivity string
# Returns: "+X/-Y" format
get_code_productivity_display() {
    local added removed

    added=$(get_native_lines_added)
    removed=$(get_native_lines_removed)

    # Handle null/empty values
    [[ -z "$added" || "$added" == "null" ]] && added=0
    [[ -z "$removed" || "$removed" == "null" ]] && removed=0

    echo "+${added}/-${removed}"
}

# Export native code productivity functions
export -f get_native_lines_added get_native_lines_removed get_code_productivity_display

# ============================================================================
# CONTEXT WINDOW VIA TRANSCRIPT PARSING (Issue #101)
# ============================================================================
# Parse transcript JSONL file to get accurate context window percentage.
# This avoids the bug in native context_window JSON (cumulative vs current).
# Reference: https://codelynx.dev/posts/calculate-claude-code-context

# Context window constants
export CONTEXT_WINDOW_SIZE=200000  # Claude's context window size

# Get transcript path from Anthropic JSON input or auto-discover
get_transcript_path() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        debug_log "No JSON input for transcript path" "INFO"
        echo ""
        return 1
    fi

    # Method 1: Try native transcript_path from JSON
    local transcript_path
    transcript_path=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.transcript_path // empty' 2>/dev/null)

    if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
        debug_log "Found transcript via native JSON path: $transcript_path" "INFO"
        echo "$transcript_path"
        return 0
    fi

    # Method 2: Auto-discover using session_id
    local session_id
    session_id=$(get_native_session_id)

    if [[ -n "$session_id" ]]; then
        # Search in Claude projects directory for this session's transcript
        local claude_projects_dir="$HOME/.claude/projects"

        if [[ -d "$claude_projects_dir" ]]; then
            # Find transcript file matching session_id (with .jsonl extension)
            local found_path
            found_path=$(find "$claude_projects_dir" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)

            if [[ -n "$found_path" && -f "$found_path" ]]; then
                debug_log "Auto-discovered transcript: $found_path" "INFO"
                echo "$found_path"
                return 0
            fi
        fi
    fi

    debug_log "Could not find transcript path" "INFO"
    echo ""
    return 1
}

# Parse the last usage entry from transcript JSONL file
# Returns: JSON object with usage data or empty
parse_transcript_last_usage() {
    local transcript_path="$1"

    if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
        echo ""
        return 1
    fi

    # Use tac (reverse cat) to efficiently find last usage entry
    # Look for entries with "usage" field, excluding sidechains
    local last_usage

    # Performance optimization: use tac and grep -m1 for large files
    if command_exists tac; then
        last_usage=$(tac "$transcript_path" 2>/dev/null | \
            grep -m1 '"usage"' 2>/dev/null | \
            jq -r '.usage // empty' 2>/dev/null)
    else
        # Fallback for systems without tac (macOS uses tail -r)
        if command_exists tail; then
            # Try tail -r (BSD/macOS)
            last_usage=$(tail -r "$transcript_path" 2>/dev/null | \
                grep -m1 '"usage"' 2>/dev/null | \
                jq -r '.usage // empty' 2>/dev/null)
        fi

        # Final fallback: use awk to get last line with usage
        if [[ -z "$last_usage" ]]; then
            last_usage=$(awk '/"usage"/' "$transcript_path" 2>/dev/null | \
                tail -1 | \
                jq -r '.usage // empty' 2>/dev/null)
        fi
    fi

    if [[ -n "$last_usage" && "$last_usage" != "null" ]]; then
        echo "$last_usage"
        return 0
    else
        debug_log "No usage data found in transcript" "INFO"
        echo ""
        return 1
    fi
}

# Get context window token count from transcript
# Returns: total tokens (input + cache_read + cache_creation)
get_context_tokens_from_transcript() {
    local transcript_path
    transcript_path=$(get_transcript_path)

    if [[ -z "$transcript_path" ]]; then
        echo "0"
        return 1
    fi

    local usage_data
    usage_data=$(parse_transcript_last_usage "$transcript_path")

    if [[ -z "$usage_data" ]]; then
        echo "0"
        return 1
    fi

    # Extract token counts
    local input_tokens cache_read cache_creation
    input_tokens=$(echo "$usage_data" | jq -r '.input_tokens // 0' 2>/dev/null)
    cache_read=$(echo "$usage_data" | jq -r '.cache_read_input_tokens // 0' 2>/dev/null)
    cache_creation=$(echo "$usage_data" | jq -r '.cache_creation_input_tokens // 0' 2>/dev/null)

    # Handle null/empty values
    [[ -z "$input_tokens" || "$input_tokens" == "null" ]] && input_tokens=0
    [[ -z "$cache_read" || "$cache_read" == "null" ]] && cache_read=0
    [[ -z "$cache_creation" || "$cache_creation" == "null" ]] && cache_creation=0

    # Calculate total: input_tokens + cache_read + cache_creation
    local total=$((input_tokens + cache_read + cache_creation))

    debug_log "Context tokens: input=$input_tokens, cache_read=$cache_read, cache_creation=$cache_creation, total=$total" "INFO"
    echo "$total"
}

# Get context window percentage from transcript
# Returns: percentage (0-100+)
get_context_window_percentage() {
    local total_tokens
    total_tokens=$(get_context_tokens_from_transcript)

    if [[ "$total_tokens" -eq 0 ]]; then
        echo "0"
        return 1
    fi

    # Calculate percentage
    local percentage
    percentage=$(awk "BEGIN {printf \"%.0f\", $total_tokens * 100 / $CONTEXT_WINDOW_SIZE}" 2>/dev/null)

    echo "${percentage:-0}"
}

# Get formatted context window display
# Returns: "45% (90K/200K)" or "85% ⚠️" format
get_context_window_display() {
    local warn_threshold="${CONFIG_CONTEXT_WARN_THRESHOLD:-75}"
    local critical_threshold="${CONFIG_CONTEXT_CRITICAL_THRESHOLD:-90}"

    local total_tokens percentage
    total_tokens=$(get_context_tokens_from_transcript)

    if [[ "$total_tokens" -eq 0 ]]; then
        echo "N/A"
        return 1
    fi

    percentage=$(awk "BEGIN {printf \"%.0f\", $total_tokens * 100 / $CONTEXT_WINDOW_SIZE}" 2>/dev/null)

    # Format tokens for display (K/M suffix)
    local formatted_tokens formatted_max
    formatted_tokens=$(format_tokens_compact "$total_tokens")
    formatted_max=$(format_tokens_compact "$CONTEXT_WINDOW_SIZE")

    # Add warning indicator based on threshold
    local indicator=""
    if [[ "$percentage" -ge "$critical_threshold" ]]; then
        indicator=" 🔴"
    elif [[ "$percentage" -ge "$warn_threshold" ]]; then
        indicator=" ⚠️"
    fi

    echo "${percentage}% (${formatted_tokens}/${formatted_max})${indicator}"
}

# Export transcript parsing functions
export -f get_transcript_path parse_transcript_last_usage
export -f get_context_tokens_from_transcript get_context_window_percentage
export -f get_context_window_display

# ============================================================================
# SESSION INFO EXTRACTION (Issue #102)
# ============================================================================
# Extract session ID and project name from Anthropic's native JSON input.
# Provides session identification for multi-session awareness.

# Get full session ID from Anthropic JSON input
get_native_session_id() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    local session_id
    session_id=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.session_id // empty' 2>/dev/null)
    echo "${session_id:-}"
}

# Get short session ID (first N characters)
# Default: 8 characters for easy resume: claude -r abc12345
get_short_session_id() {
    local length="${1:-8}"
    local full_id
    full_id=$(get_native_session_id)

    if [[ -n "$full_id" ]]; then
        echo "${full_id:0:$length}"
    else
        echo ""
    fi
}

# Get project directory from workspace
get_native_project_dir() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    local project_dir
    project_dir=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.workspace.project_dir // empty' 2>/dev/null)
    echo "${project_dir:-}"
}

# Get project name (basename of project directory)
get_native_project_name() {
    local project_dir
    project_dir=$(get_native_project_dir)

    if [[ -n "$project_dir" ]]; then
        basename "$project_dir"
    else
        echo ""
    fi
}

# Get current working directory from workspace
get_native_current_dir() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    local current_dir
    current_dir=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
    echo "${current_dir:-}"
}

# Get formatted session info display
# Format: "abc12345 • project-name"
get_session_info_display() {
    local separator="${CONFIG_SESSION_INFO_SEPARATOR:- • }"
    local id_length="${CONFIG_SESSION_INFO_ID_LENGTH:-8}"

    local short_id project_name
    short_id=$(get_short_session_id "$id_length")
    project_name=$(get_native_project_name)

    local output=""

    if [[ -n "$short_id" ]]; then
        output="$short_id"
    fi

    if [[ -n "$project_name" ]]; then
        if [[ -n "$output" ]]; then
            output="${output}${separator}${project_name}"
        else
            output="$project_name"
        fi
    fi

    echo "$output"
}

# Export session info functions
export -f get_native_session_id get_short_session_id
export -f get_native_project_dir get_native_project_name get_native_current_dir
export -f get_session_info_display

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

# Initialize the module (skip during testing to allow sourcing without side effects)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_cost_module
fi

# Export cost tracking functions
export -f is_ccusage_available init_cost_cache execute_ccusage_with_cache
export -f cleanup_old_session_markers validate_cache_file get_instance_id get_session_marker
export -f calculate_cost_dates get_active_blocks_data get_session_cost_data
export -f get_daily_cost_data get_monthly_cost_data
export -f extract_session_cost extract_today_cost extract_weekly_cost extract_monthly_cost
export -f process_active_blocks get_claude_usage_info
export -f format_cost get_cost_trend clear_cost_cache
# Export unified block metrics functions (v2.10.0)
export -f format_tokens_compact format_tokens_per_minute get_unified_block_metrics