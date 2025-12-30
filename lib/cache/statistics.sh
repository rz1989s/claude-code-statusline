#!/bin/bash

# ============================================================================
# Claude Code Statusline - Cache Statistics Module
# ============================================================================
#
# This module provides cache performance monitoring and analytics including
# hit/miss tracking, response times, and memory usage statistics.
#
# Error Suppression Patterns (Issue #108):
# - declare 2>/dev/null: Dynamic variable creation (may already exist)
# - du 2>/dev/null: Disk usage where cache dir may not exist yet
# - wc 2>/dev/null: Counting files that may be deleted during count
#
# Dependencies: keys.sh (for sanitize_cache_key)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CACHE_STATISTICS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CACHE_STATISTICS_LOADED=true

# ============================================================================
# CACHE PERFORMANCE MONITORING & ANALYTICS SYSTEM
# ============================================================================

# Bash compatibility check - disable advanced features for old bash
if [[ "${STATUSLINE_COMPATIBILITY_MODE:-}" == "true" ]] || [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    # Disable associative arrays for bash < 4.0
    export STATUSLINE_CACHE_COMPATIBLE_MODE=true
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache module running in compatibility mode (bash ${BASH_VERSION})" "INFO"
else
    # Performance statistics tracking (requires bash 4.0+ for associative arrays)
    declare -A CACHE_STATS_HITS=()
    declare -A CACHE_STATS_MISSES=()
    declare -A CACHE_STATS_ERRORS=()
    declare -A CACHE_STATS_RESPONSE_TIMES=()
    declare -A CACHE_STATS_TOTAL_CALLS=()
fi

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
            echo "  Cache Efficiency: EXCELLENT (>=80%)"
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
                local file_size=$(get_file_size "$file")
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

# Show cache statistics (simple version for CLI)
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

# Export functions
export -f init_cache_stats record_cache_hit record_cache_miss record_cache_error
export -f get_cache_hit_ratio get_cache_performance_report get_cache_memory_stats
export -f clear_cache_stats measure_execution_time show_cache_stats
