#!/bin/bash

# ============================================================================
# Claude Code Statusline - Smart Cost Recommendations Module
# ============================================================================
#
# Heuristic-based cost optimization recommendations that analyze usage
# patterns and suggest actionable improvements.
#
# Checks:
# - Cache efficiency: warns if cache hit rate is below threshold
# - Session spikes: detects sessions costing >2x average
# - Budget pacing: flags daily spend trending over budget
# - High average cost: flags expensive sessions
# - Idle burn: detects long idle gaps with high token usage
#
# Dependencies: core.sh, cost/core.sh, cost/native_calc.sh, cost/report_calc.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_RECOMMENDATIONS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_RECOMMENDATIONS_LOADED=true

# ============================================================================
# CONFIGURATION DEFAULTS
# ============================================================================

CONFIG_RECOMMENDATIONS_CACHE_MIN_HIT_RATE="${CONFIG_RECOMMENDATIONS_CACHE_MIN_HIT_RATE:-70}"
CONFIG_RECOMMENDATIONS_SPIKE_MULTIPLIER="${CONFIG_RECOMMENDATIONS_SPIKE_MULTIPLIER:-2}"
CONFIG_RECOMMENDATIONS_DAILY_BUDGET="${CONFIG_RECOMMENDATIONS_DAILY_BUDGET:-5.00}"
CONFIG_RECOMMENDATIONS_HIGH_AVG_THRESHOLD="${CONFIG_RECOMMENDATIONS_HIGH_AVG_THRESHOLD:-1.50}"
CONFIG_RECOMMENDATIONS_IDLE_GAP_MINUTES="${CONFIG_RECOMMENDATIONS_IDLE_GAP_MINUTES:-30}"

# ============================================================================
# SHARED JSONL SCANNING HELPER
# ============================================================================

# Shared pipeline: find JSONL → extract token TSV → awk cost calculation
# Eliminates ~120 lines of copy-paste across check_session_spike_recommendation,
# check_budget_pacing_recommendation, and check_high_avg_cost_recommendation.
#
# Args:
#   $1 = search_path     - directory to scan for JSONL files
#   $2 = find_days       - mtime filter for find (integer)
#   $3 = range_start     - ISO timestamp lower bound (empty = no filter)
#   $4 = range_end_iso   - ISO timestamp upper bound (empty = no filter)
#   $5 = awk_end_block   - custom awk END { ... } block (caller's aggregation logic)
#   $6 = awk_pricing     - pricing lookup awk source (from get_awk_pricing_block)
#
# The caller provides ONLY the END block. The helper handles:
#   - find + jq token extraction
#   - awk BEGIN block (pricing init + user vars)
#   - awk main block (timestamp filtering, model lookup, cost calc)
#
# Output: whatever the caller's END block prints
_scan_jsonl_costs() {
  local search_path="$1" find_days="$2" range_start="${3:-}" range_end_iso="${4:-}"
  local awk_end_block="$5" awk_pricing="$6"

  find "$search_path" -name "*.jsonl" -type f -mtime -$((find_days + 1)) 2>/dev/null | \
    xargs -P4 -L50 jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
      [.timestamp, (.message.model // "default"),
       (.message.usage.input_tokens // 0),
       (.message.usage.output_tokens // 0),
       (.message.usage.cache_creation_input_tokens // 0),
       (.message.usage.cache_read_input_tokens // 0)] | @tsv' 2>/dev/null | awk -F'\t' -v start="$range_start" -v end_ts="$range_end_iso" "
BEGIN {
$awk_pricing
  total_cost = 0
}
{
  ts = \$1
  gsub(/\.[0-9]+Z?\$/, \"\", ts)
  if (start != \"\" && ts < start) next
  if (end_ts != \"\" && ts >= end_ts) next

  model = \$2
  input = \$3 + 0; output = \$4 + 0
  cache_write = \$5 + 0; cache_read = \$6 + 0

  pricing = p[model]
  if (pricing == \"\") pricing = p[\"default\"]
  split(pricing, pr, \" \")
  cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000

  total_cost += cost

  split(FILENAME, fp, \"/\")
  session_id = fp[length(fp)]
  session_costs[session_id] += cost
  session_count++
}
$awk_end_block" 2>/dev/null
}

# Compute find_days from since_date (cross-platform)
# Args: $1 = since_date (YYYY-MM-DD or empty)
# Output: integer days to pass to find -mtime
_compute_find_days() {
  local since_date="${1:-}"
  if [[ -z "$since_date" ]]; then
    echo 1
    return
  fi

  local since_epoch today_epoch
  if [[ "$(uname -s)" == "Darwin" ]]; then
    since_epoch=$(date -j -f "%Y-%m-%d" "$since_date" "+%s" 2>/dev/null) || since_epoch=0
    today_epoch=$(date "+%s")
  else
    since_epoch=$(date -d "$since_date" "+%s" 2>/dev/null) || since_epoch=0
    today_epoch=$(date "+%s")
  fi

  if [[ "$since_epoch" -gt 0 ]]; then
    echo $(( (today_epoch - since_epoch) / 86400 + 2 ))
  else
    echo 1
  fi
}

# Resolve common parameters for JSONL scan functions
# Sets: search_path, range_start, range_end_iso, awk_pricing, find_days
# Args: $1 = since_date, $2 = until_date, $3 = project_filter
# Returns 1 if prerequisites not met (caller should return 0)
_resolve_scan_params() {
  local since_date="${1:-}" until_date="${2:-}" project_filter="${3:-}"

  _scan_projects_dir=$(get_claude_projects_dir 2>/dev/null) || return 1
  [[ -z "$_scan_projects_dir" || ! -d "$_scan_projects_dir" ]] && return 1

  _scan_search_path="$_scan_projects_dir"
  if [[ -n "$project_filter" ]]; then
    _scan_search_path=$(resolve_project_filter "$project_filter" "$_scan_projects_dir" 2>/dev/null) || return 1
  fi

  if [[ -n "$since_date" ]]; then
    _scan_range_start=$(date_to_iso_utc "$since_date" 2>/dev/null) || _scan_range_start=""
  else
    _scan_range_start=$(get_today_start_iso 2>/dev/null) || _scan_range_start=""
  fi

  _scan_range_end_iso=""
  if [[ -n "$until_date" ]]; then
    _scan_range_end_iso=$(date_to_iso_utc_end "$until_date" 2>/dev/null) || _scan_range_end_iso=""
  fi

  _scan_awk_pricing=$(get_awk_pricing_block 2>/dev/null) || return 1
  _scan_find_days=$(_compute_find_days "$since_date")
}

# ============================================================================
# RECOMMENDATION CHECKS
# ============================================================================

# Check cache efficiency and recommend improvements
# Args: $1 = cache hit rate (0-100)
# Output: tab-separated line: PRIORITY\tCATEGORY\tMESSAGE\tSAVINGS_ESTIMATE
check_cache_efficiency_recommendation() {
  local hit_rate="${1:-0}"
  local min_rate="${CONFIG_RECOMMENDATIONS_CACHE_MIN_HIT_RATE:-70}"

  # Validate numeric input
  if ! [[ "$hit_rate" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    return 0
  fi

  local hit_rate_int
  hit_rate_int=$(printf "%.0f" "$hit_rate" 2>/dev/null) || return 0

  if [[ "$hit_rate_int" -lt "$min_rate" ]]; then
    local severity="MEDIUM"
    if [[ "$hit_rate_int" -lt 50 ]]; then
      severity="HIGH"
    fi
    local gap=$((min_rate - hit_rate_int))
    local savings_pct=$((gap / 2))
    printf "%s\tcache\tCache hit rate is %d%% (target: %d%%). Use longer conversations to build cache. Estimated %d%% cost reduction possible.\t%d%%\n" \
      "$severity" "$hit_rate_int" "$min_rate" "$savings_pct" "$savings_pct"
  fi
}

# Check for cost spikes in session data
# Reads JSONL data from stdin or uses project dir
# Args: $1 = since_date (optional), $2 = until_date (optional), $3 = project_filter (optional)
# Output: tab-separated recommendations for any detected spikes
check_session_spike_recommendation() {
  local since_date="${1:-}" until_date="${2:-}" project_filter="${3:-}"

  _resolve_scan_params "$since_date" "$until_date" "$project_filter" || return 0

  local spike_multiplier="${CONFIG_RECOMMENDATIONS_SPIKE_MULTIPLIER:-2}"
  local end_block
  end_block=$(cat <<AWKEOF
END {
  if (session_count == 0 || length(session_costs) == 0) exit
  avg = total_cost / length(session_costs)
  for (sid in session_costs) {
    if (avg > 0 && session_costs[sid] > avg * $spike_multiplier) {
      printf "SPIKE\t%s\t%.4f\t%.4f\n", sid, session_costs[sid], avg
    }
  }
}
AWKEOF
)

  local session_data
  session_data=$(_scan_jsonl_costs "$_scan_search_path" "$_scan_find_days" \
    "$_scan_range_start" "$_scan_range_end_iso" "$end_block" "$_scan_awk_pricing")

  if [[ -n "$session_data" ]]; then
    local spike_count
    spike_count=$(echo "$session_data" | wc -l | tr -d ' ')
    local max_cost avg_cost
    max_cost=$(echo "$session_data" | awk -F'\t' 'BEGIN{m=0}{if($3+0>m)m=$3+0}END{printf "%.2f",m}')
    avg_cost=$(echo "$session_data" | awk -F'\t' '{print $4}' | head -1)
    printf "HIGH\tsessions\tDetected %d session(s) costing >%dx average (\$%.2f avg). Most expensive: \$%s. Review large sessions for optimization.\t10-20%%\n" \
      "$spike_count" "${CONFIG_RECOMMENDATIONS_SPIKE_MULTIPLIER:-2}" "${avg_cost:-0}" "$max_cost"
  fi
}

# Check budget pacing against daily target
# Args: $1 = since_date, $2 = until_date, $3 = project_filter
# Output: recommendation if daily spend exceeds budget
check_budget_pacing_recommendation() {
  local since_date="${1:-}" until_date="${2:-}" project_filter="${3:-}"
  local daily_budget="${CONFIG_RECOMMENDATIONS_DAILY_BUDGET:-5.00}"

  # Budget pacing always checks today only — override since_date
  _resolve_scan_params "" "" "$project_filter" || return 0

  local end_block='END { printf "%.2f", total_cost }'

  local today_cost
  today_cost=$(_scan_jsonl_costs "$_scan_search_path" 1 \
    "$_scan_range_start" "" "$end_block" "$_scan_awk_pricing")

  today_cost="${today_cost:-0.00}"

  local is_over
  is_over=$(awk -v tc="$today_cost" -v db="$daily_budget" 'BEGIN { print (tc > db) ? 1 : 0 }' 2>/dev/null)

  if [[ "$is_over" == "1" ]]; then
    local overage
    overage=$(awk -v tc="$today_cost" -v db="$daily_budget" 'BEGIN { printf "%.2f", tc - db }' 2>/dev/null)
    printf "HIGH\tbudget\tDaily spend (\$%s) exceeds budget (\$%s) by \$%s. Consider batching requests or using lighter models.\t\$%s\n" \
      "$today_cost" "$daily_budget" "$overage" "$overage"
  else
    local pct
    pct=$(awk -v tc="$today_cost" -v db="$daily_budget" 'BEGIN { if (db > 0) printf "%.0f", (tc / db) * 100; else print 0 }' 2>/dev/null)
    if [[ "${pct:-0}" -ge 80 ]]; then
      printf "MEDIUM\tbudget\tDaily spend (\$%s) is at %s%% of budget (\$%s). Monitor usage to stay within limits.\t-\n" \
        "$today_cost" "$pct" "$daily_budget"
    fi
  fi
}

# Check if average session cost is unusually high
# Args: $1 = since_date, $2 = until_date, $3 = project_filter
check_high_avg_cost_recommendation() {
  local since_date="${1:-}" until_date="${2:-}" project_filter="${3:-}"
  local threshold="${CONFIG_RECOMMENDATIONS_HIGH_AVG_THRESHOLD:-1.50}"

  _resolve_scan_params "$since_date" "$until_date" "$project_filter" || return 0

  local end_block='END {
  file_count = length(session_costs)
  if (file_count > 0) {
    avg = total_cost / file_count
    printf "%.4f\t%d\t%.4f", avg, file_count, total_cost
  }
}'

  local avg_data
  avg_data=$(_scan_jsonl_costs "$_scan_search_path" "$_scan_find_days" \
    "$_scan_range_start" "$_scan_range_end_iso" "$end_block" "$_scan_awk_pricing")

  if [[ -n "$avg_data" ]]; then
    local avg_cost session_count total_cost
    IFS=$'\t' read -r avg_cost session_count total_cost <<< "$avg_data"

    local is_high
    is_high=$(awk -v ac="${avg_cost:-0}" -v th="$threshold" 'BEGIN { print (ac > th) ? 1 : 0 }' 2>/dev/null)

    if [[ "$is_high" == "1" ]]; then
      printf "MEDIUM\tefficiency\tAverage session cost (\$%.2f) exceeds \$%.2f threshold across %d sessions. Break large tasks into smaller focused sessions.\t15-25%%\n" \
        "${avg_cost:-0}" "$threshold" "${session_count:-0}"
    fi
  fi
}

# Check for idle time with token burn (long gaps between interactions)
# Args: $1 = since_date, $2 = until_date, $3 = project_filter
check_idle_burn_recommendation() {
  local since_date="${1:-}" until_date="${2:-}" project_filter="${3:-}"
  local idle_threshold="${CONFIG_RECOMMENDATIONS_IDLE_GAP_MINUTES:-30}"

  # Reuse shared param resolution (we only need search_path, range, and find_days — not awk_pricing)
  _resolve_scan_params "$since_date" "$until_date" "$project_filter" || return 0

  local idle_data
  idle_data=$(find "$_scan_search_path" -name "*.jsonl" -type f -mtime -$((_scan_find_days + 1)) 2>/dev/null | \
    xargs -P4 -L50 jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
      .timestamp' 2>/dev/null | sort | awk -v start="${_scan_range_start:-}" -v end_ts="${_scan_range_end_iso:-}" -v idle_min="$idle_threshold" '
BEGIN { prev = ""; gaps = 0; max_gap = 0 }
{
  ts = $1
  gsub(/\.[0-9]+Z?$/, "", ts)
  if (start != "" && ts < start) next
  if (end_ts != "" && ts >= end_ts) next

  if (prev != "") {
    # Parse timestamps to compute gap in minutes (simplified: compare hour:minute)
    split(ts, a, "T")
    split(a[2], at, ":")
    split(prev, b, "T")
    split(b[2], bt, ":")

    # Same day comparison
    if (a[1] == b[1]) {
      curr_min = at[1] * 60 + at[2]
      prev_min = bt[1] * 60 + bt[2]
      gap = curr_min - prev_min
      if (gap > idle_min) {
        gaps++
        if (gap > max_gap) max_gap = gap
      }
    }
  }
  prev = ts
}
END {
  if (gaps > 0) printf "%d\t%d\n", gaps, max_gap
}' 2>/dev/null)

  if [[ -n "$idle_data" ]]; then
    local gap_count max_gap
    IFS=$'\t' read -r gap_count max_gap <<< "$idle_data"
    if [[ "${gap_count:-0}" -gt 0 ]]; then
      printf "LOW\tidle\tDetected %d idle gap(s) >%dmin (longest: %dmin). Close idle sessions to avoid context window waste.\t5-10%%\n" \
        "$gap_count" "$idle_threshold" "$max_gap"
    fi
  fi
}

# ============================================================================
# MAIN RECOMMENDATION GENERATOR
# ============================================================================

# Generate all recommendations
# Args: $1 = since_date, $2 = until_date, $3 = project_filter
# Output: sorted recommendations (HIGH first, then MEDIUM, then LOW)
generate_recommendations() {
  local since_date="${1:-}" until_date="${2:-}" project_filter="${3:-}"

  local recommendations=""
  local rec_line

  # Check 1: Cache efficiency (from current stdin JSON if available)
  local cache_hit_rate="0"
  if [[ -n "${STATUSLINE_INPUT_JSON:-}" ]]; then
    local cache_read input_tokens
    cache_read=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.cache_read_input_tokens // 0' 2>/dev/null) || cache_read=0
    input_tokens=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.current_usage.input_tokens // 0' 2>/dev/null) || input_tokens=0
    if [[ "$input_tokens" -gt 0 ]] 2>/dev/null; then
      cache_hit_rate=$(awk -v cr="$cache_read" -v it="$input_tokens" 'BEGIN { printf "%.0f", (cr / it) * 100 }' 2>/dev/null) || cache_hit_rate=0
    fi
  fi

  rec_line=$(check_cache_efficiency_recommendation "$cache_hit_rate" 2>/dev/null) || true
  if [[ -n "$rec_line" ]]; then
    recommendations+="$rec_line"$'\n'
  fi

  # Check 2: Session cost spikes
  rec_line=$(check_session_spike_recommendation "$since_date" "$until_date" "$project_filter" 2>/dev/null) || true
  if [[ -n "$rec_line" ]]; then
    recommendations+="$rec_line"$'\n'
  fi

  # Check 3: Budget pacing
  rec_line=$(check_budget_pacing_recommendation "$since_date" "$until_date" "$project_filter" 2>/dev/null) || true
  if [[ -n "$rec_line" ]]; then
    recommendations+="$rec_line"$'\n'
  fi

  # Check 4: High average cost
  rec_line=$(check_high_avg_cost_recommendation "$since_date" "$until_date" "$project_filter" 2>/dev/null) || true
  if [[ -n "$rec_line" ]]; then
    recommendations+="$rec_line"$'\n'
  fi

  # Check 5: Idle burn detection
  rec_line=$(check_idle_burn_recommendation "$since_date" "$until_date" "$project_filter" 2>/dev/null) || true
  if [[ -n "$rec_line" ]]; then
    recommendations+="$rec_line"$'\n'
  fi

  # Sort by priority: HIGH > MEDIUM > LOW
  if [[ -n "$recommendations" ]]; then
    echo "$recommendations" | grep -v '^$' | sort -t$'\t' -k1,1 | awk -F'\t' '
    BEGIN { order["HIGH"] = 1; order["MEDIUM"] = 2; order["LOW"] = 3 }
    { print order[$1] "\t" $0 }' | sort -t$'\t' -k1,1n | cut -f2-
  fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f _scan_jsonl_costs
export -f _compute_find_days
export -f _resolve_scan_params
export -f check_cache_efficiency_recommendation
export -f check_session_spike_recommendation
export -f check_budget_pacing_recommendation
export -f check_high_avg_cost_recommendation
export -f check_idle_burn_recommendation
export -f generate_recommendations

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Recommendations module loaded" "INFO" || true
