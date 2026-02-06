#!/bin/bash

# ============================================================================
# Claude Code Statusline - Report Cost Calculator
# ============================================================================
#
# Provides breakdown calculations for CLI reports:
# - calculate_hourly_breakdown()  - Hourly buckets for daily report
# - calculate_daily_breakdown()   - Daily buckets for weekly/monthly reports
#
# Output format (TSV):
#   HOUR\t{hour}\t{sessions}\t{input}\t{output}\t{cache_pct}\t{cost}
#   DAY\t{date}\t{weekday}\t{sessions}\t{cost}
#   MODEL\t{name}\t{sessions}\t{cost}
#
# Dependencies: pricing.sh, api_live.sh (get_claude_projects_dir)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_REPORT_CALC_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_REPORT_CALC_LOADED=true

# ============================================================================
# HOURLY BREAKDOWN (for --daily)
# ============================================================================

# Calculate hourly breakdown for today
# Output: TSV lines (HOUR and MODEL rows)
# HOUR\t{hour_num}\t{sessions}\t{input_tokens}\t{output_tokens}\t{cache_pct}\t{cost}
# MODEL\t{model_name}\t{sessions}\t{cost}
calculate_hourly_breakdown() {
  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)

  if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
    return 0
  fi

  local today_start
  today_start=$(get_today_start_iso)

  # Get UTC offset for hour bucketing in local time
  local utc_offset_seconds
  utc_offset_seconds=$(date +%z | awk '{
    sign = substr($0, 1, 1)
    hours = substr($0, 2, 2) + 0
    mins = substr($0, 4, 2) + 0
    total = hours * 3600 + mins * 60
    if (sign == "-") total = -total
    print total
  }')

  local awk_pricing
  awk_pricing=$(get_awk_pricing_block)

  # Single find+jq+awk pipeline bucketed by hour
  find "$projects_dir" -name "*.jsonl" -type f -mtime -1 2>/dev/null | while read -r jsonl_file; do
    [[ -z "$jsonl_file" ]] && continue
    jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
      [.timestamp, (.message.model // "default"),
       (.message.usage.input_tokens // 0),
       (.message.usage.output_tokens // 0),
       (.message.usage.cache_creation_input_tokens // 0),
       (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
  done | awk -F'\t' -v start="$today_start" -v tz_offset="$utc_offset_seconds" "
  BEGIN {
    # Pricing
$awk_pricing
  }
  {
    ts = \$1
    gsub(/\.[0-9]+Z?\$/, \"\", ts)

    # Filter to today only
    if (ts < start) next

    model = \$2
    input = \$3 + 0
    output = \$4 + 0
    cache_write = \$5 + 0
    cache_read = \$6 + 0

    # Calculate cost
    pricing = p[model]
    if (pricing == \"\") pricing = p[\"default\"]
    split(pricing, pr, \" \")
    cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000

    # Extract UTC hour from timestamp, convert to local
    # Format: 2026-02-06T15:30:00
    split(ts, dt, \"T\")
    split(dt[2], tm, \":\")
    utc_hour = tm[1] + 0
    utc_min = tm[2] + 0
    utc_sec = tm[3] + 0

    # Convert to local time (approximate - handles day boundary)
    local_seconds = utc_hour * 3600 + utc_min * 60 + utc_sec + tz_offset
    if (local_seconds < 0) local_seconds += 86400
    if (local_seconds >= 86400) local_seconds -= 86400
    local_hour = int(local_seconds / 3600)

    # Accumulate by hour
    h_sessions[local_hour]++
    h_input[local_hour] += input
    h_output[local_hour] += output
    h_cache_read[local_hour] += cache_read
    h_cache_write[local_hour] += cache_write
    h_cost[local_hour] += cost

    # Accumulate by model
    m_sessions[model]++
    m_cost[model] += cost
  }
  END {
    # Output hourly data (only hours with data)
    for (h = 0; h < 24; h++) {
      if (h_sessions[h] > 0) {
        total_cache = h_cache_read[h] + h_cache_write[h] + h_input[h]
        cache_pct = (total_cache > 0) ? int((h_cache_read[h] / total_cache) * 100) : 0
        printf \"HOUR\t%d\t%d\t%d\t%d\t%d\t%.2f\n\",
          h, h_sessions[h], h_input[h], h_output[h], cache_pct, h_cost[h]
      }
    }
    # Output model data
    for (m in m_sessions) {
      printf \"MODEL\t%s\t%d\t%.2f\n\", m, m_sessions[m], m_cost[m]
    }
  }"
}

# ============================================================================
# DAILY BREAKDOWN (for --weekly, --monthly)
# ============================================================================

# Calculate daily breakdown for the last N days
# Args: days (default: 7)
# Output: TSV lines (DAY and MODEL rows)
# DAY\t{date}\t{weekday}\t{sessions}\t{cost}
# MODEL\t{model_name}\t{sessions}\t{cost}
calculate_daily_breakdown() {
  local days="${1:-7}"

  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)

  if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
    return 0
  fi

  local range_start
  range_start=$(get_days_ago_start_iso "$days")

  # Get UTC offset for date bucketing in local time
  local utc_offset_seconds
  utc_offset_seconds=$(date +%z | awk '{
    sign = substr($0, 1, 1)
    hours = substr($0, 2, 2) + 0
    mins = substr($0, 4, 2) + 0
    total = hours * 3600 + mins * 60
    if (sign == "-") total = -total
    print total
  }')

  local awk_pricing
  awk_pricing=$(get_awk_pricing_block)

  # Build weekday lookup for the date range
  # We'll compute weekday names inside awk using a reference point approach
  local ref_date_epoch
  if [[ "$(uname -s)" == "Darwin" ]]; then
    ref_date_epoch=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m-%d)" "+%s" 2>/dev/null)
  else
    ref_date_epoch=$(date -d "$(date +%Y-%m-%d)" "+%s" 2>/dev/null)
  fi
  local ref_date_str
  ref_date_str=$(date +%Y-%m-%d)

  # Build date-to-weekday lookup using shell (avoids gawk asorti dependency)
  # Generate all dates in range and their weekday names (+1 day buffer for timezone edge)
  local -A weekday_map
  local i_day
  for ((i_day = 0; i_day <= days; i_day++)); do
    local d_date d_weekday
    if [[ "$(uname -s)" == "Darwin" ]]; then
      d_date=$(date -v-${i_day}d +%Y-%m-%d)
      d_weekday=$(date -v-${i_day}d +%A)
    else
      d_date=$(date -d "$i_day days ago" +%Y-%m-%d)
      d_weekday=$(date -d "$i_day days ago" +%A)
    fi
    weekday_map["$d_date"]="$d_weekday"
  done

  # Phase 1: Aggregate by date and model using awk (no asorti needed)
  local raw_data
  raw_data=$(find "$projects_dir" -name "*.jsonl" -type f -mtime -$((days + 1)) 2>/dev/null | while read -r jsonl_file; do
    [[ -z "$jsonl_file" ]] && continue
    jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
      [.timestamp, (.message.model // "default"),
       (.message.usage.input_tokens // 0),
       (.message.usage.output_tokens // 0),
       (.message.usage.cache_creation_input_tokens // 0),
       (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
  done | awk -F'\t' -v start="$range_start" -v tz_offset="$utc_offset_seconds" "
  BEGIN {
    # Pricing
$awk_pricing
  }
  {
    ts = \$1
    gsub(/\.[0-9]+Z?\$/, \"\", ts)

    # Filter to range
    if (ts < start) next

    model = \$2
    input = \$3 + 0
    output = \$4 + 0
    cache_write = \$5 + 0
    cache_read = \$6 + 0

    # Calculate cost
    pricing = p[model]
    if (pricing == \"\") pricing = p[\"default\"]
    split(pricing, pr, \" \")
    cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000

    # Extract date from timestamp, adjusting for timezone
    split(ts, dt, \"T\")
    split(dt[2], tm, \":\")
    utc_hour = tm[1] + 0
    utc_min = tm[2] + 0

    # Check if timezone offset shifts the date
    local_seconds = utc_hour * 3600 + utc_min * 60 + tz_offset
    local_date = dt[1]

    if (local_seconds < 0) {
      split(local_date, ymd, \"-\")
      y = ymd[1] + 0; m = ymd[2] + 0; d = ymd[3] + 0
      d--
      if (d < 1) {
        m--
        if (m < 1) { m = 12; y-- }
        if (m == 2) d = 28
        else if (m == 4 || m == 6 || m == 9 || m == 11) d = 30
        else d = 31
      }
      local_date = sprintf(\"%04d-%02d-%02d\", y, m, d)
    } else if (local_seconds >= 86400) {
      split(local_date, ymd, \"-\")
      y = ymd[1] + 0; m = ymd[2] + 0; d = ymd[3] + 0
      d++
      if (m == 2) max_d = 28
      else if (m == 4 || m == 6 || m == 9 || m == 11) max_d = 30
      else max_d = 31
      if (d > max_d) { d = 1; m++; if (m > 12) { m = 1; y++ } }
      local_date = sprintf(\"%04d-%02d-%02d\", y, m, d)
    }

    # Accumulate by date
    d_sessions[local_date]++
    d_cost[local_date] += cost

    # Accumulate by model
    m_sessions[model]++
    m_cost[model] += cost
  }
  END {
    # Output unsorted day rows (will be sorted externally)
    for (date in d_sessions) {
      printf \"_DAY\t%s\t%d\t%.2f\n\", date, d_sessions[date], d_cost[date]
    }
    # Output model data
    for (m in m_sessions) {
      printf \"MODEL\t%s\t%d\t%.2f\n\", m, m_sessions[m], m_cost[m]
    }
  }")

  # Phase 2: Sort day rows and attach weekday names from shell lookup
  local model_lines day_lines
  model_lines=$(echo "$raw_data" | grep "^MODEL" || true)
  day_lines=$(echo "$raw_data" | grep "^_DAY" | sort -t$'\t' -k2 || true)

  # Emit DAY lines with weekday names
  while IFS=$'\t' read -r _ date sessions cost; do
    [[ -z "$date" ]] && continue
    local weekday="${weekday_map[$date]:-Unknown}"
    printf "DAY\t%s\t%s\t%d\t%.2f\n" "$date" "$weekday" "$sessions" "$cost"
  done <<< "$day_lines"

  # Emit MODEL lines
  if [[ -n "$model_lines" ]]; then
    echo "$model_lines"
  fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f calculate_hourly_breakdown calculate_daily_breakdown
