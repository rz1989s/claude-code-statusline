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

# Calculate hourly breakdown for a date (defaults to today)
# Args: [since_date] [until_date] — YYYY-MM-DD format, optional
# Output: TSV lines (HOUR and MODEL rows)
# HOUR\t{hour_num}\t{sessions}\t{input_tokens}\t{output_tokens}\t{cache_pct}\t{cost}
# MODEL\t{model_name}\t{sessions}\t{cost}
calculate_hourly_breakdown() {
  local since_date="${1:-}" until_date="${2:-}"

  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)

  if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
    return 0
  fi

  local today_start range_end_iso=""
  if [[ -n "$since_date" ]]; then
    today_start=$(date_to_iso_utc "$since_date" 2>/dev/null)
  else
    today_start=$(get_today_start_iso)
  fi
  if [[ -n "$until_date" ]]; then
    range_end_iso=$(date_to_iso_utc_end "$until_date" 2>/dev/null)
  fi

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
  done | awk -F'\t' -v start="$today_start" -v end_ts="${range_end_iso:-}" -v tz_offset="$utc_offset_seconds" "
  BEGIN {
    # Pricing
$awk_pricing
  }
  {
    ts = \$1
    gsub(/\.[0-9]+Z?\$/, \"\", ts)

    # Filter to range
    if (ts < start) next
    if (end_ts != \"\" && ts >= end_ts) next

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

# Calculate daily breakdown for a date range or last N days
# Args: days [since_date] [until_date] — YYYY-MM-DD format, optional
# If since_date is set, days is ignored and range is since→until (or since→today)
# Output: TSV lines (DAY and MODEL rows)
# DAY\t{date}\t{weekday}\t{sessions}\t{cost}
# MODEL\t{model_name}\t{sessions}\t{cost}
calculate_daily_breakdown() {
  local days="${1:-7}"
  local since_date="${2:-}" until_date="${3:-}"

  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)

  if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
    return 0
  fi

  local range_start range_end_iso=""
  if [[ -n "$since_date" ]]; then
    range_start=$(date_to_iso_utc "$since_date" 2>/dev/null)
    # Calculate days for find -mtime
    local since_epoch today_epoch
    if [[ "$(uname -s)" == "Darwin" ]]; then
      since_epoch=$(date -j -f "%Y-%m-%d" "$since_date" "+%s" 2>/dev/null)
      today_epoch=$(date "+%s")
    else
      since_epoch=$(date -d "$since_date" "+%s" 2>/dev/null)
      today_epoch=$(date "+%s")
    fi
    days=$(( (today_epoch - since_epoch) / 86400 + 2 ))
  else
    range_start=$(get_days_ago_start_iso "$days")
  fi
  if [[ -n "$until_date" ]]; then
    range_end_iso=$(date_to_iso_utc_end "$until_date" 2>/dev/null)
  fi

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
  local i_day map_days=$((days + 1))
  for ((i_day = 0; i_day <= map_days; i_day++)); do
    local d_date d_weekday
    if [[ -n "$since_date" ]]; then
      # When using --since, generate forward from since_date
      if [[ "$(uname -s)" == "Darwin" ]]; then
        d_date=$(date -j -f "%Y-%m-%d" -v+${i_day}d "$since_date" "+%Y-%m-%d" 2>/dev/null)
        d_weekday=$(date -j -f "%Y-%m-%d" -v+${i_day}d "$since_date" "+%A" 2>/dev/null)
      else
        d_date=$(date -d "$since_date + $i_day days" +%Y-%m-%d)
        d_weekday=$(date -d "$since_date + $i_day days" +%A)
      fi
    else
      if [[ "$(uname -s)" == "Darwin" ]]; then
        d_date=$(date -v-${i_day}d +%Y-%m-%d)
        d_weekday=$(date -v-${i_day}d +%A)
      else
        d_date=$(date -d "$i_day days ago" +%Y-%m-%d)
        d_weekday=$(date -d "$i_day days ago" +%A)
      fi
    fi
    [[ -n "$d_date" ]] && weekday_map["$d_date"]="$d_weekday"
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
  done | awk -F'\t' -v start="$range_start" -v end_ts="${range_end_iso:-}" -v tz_offset="$utc_offset_seconds" "
  BEGIN {
    # Pricing
$awk_pricing
  }
  {
    ts = \$1
    gsub(/\.[0-9]+Z?\$/, \"\", ts)

    # Filter to range
    if (ts < start) next
    if (end_ts != \"\" && ts >= end_ts) next

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
        is_leap = ((y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)) ? 1 : 0
        if (m == 2) d = is_leap ? 29 : 28
        else if (m == 4 || m == 6 || m == 9 || m == 11) d = 30
        else d = 31
      }
      local_date = sprintf(\"%04d-%02d-%02d\", y, m, d)
    } else if (local_seconds >= 86400) {
      split(local_date, ymd, \"-\")
      y = ymd[1] + 0; m = ymd[2] + 0; d = ymd[3] + 0
      d++
      is_leap = ((y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)) ? 1 : 0
      if (m == 2) max_d = is_leap ? 29 : 28
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
# MODEL BREAKDOWN (for --breakdown)
# ============================================================================

# Calculate per-model cost breakdown with token details
# Args: [since_date] [until_date] — YYYY-MM-DD format, optional
# Output: TSV lines
# BREAKDOWN\t{model}\t{sessions}\t{input_tokens}\t{output_tokens}\t{cache_read}\t{cost}
calculate_model_breakdown() {
  local since_date="${1:-}" until_date="${2:-}"

  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)

  if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
    return 0
  fi

  # Determine time range
  local range_start range_end_iso="" find_days=30
  if [[ -n "$since_date" ]]; then
    range_start=$(date_to_iso_utc "$since_date" 2>/dev/null)
    local since_epoch today_epoch
    if [[ "$(uname -s)" == "Darwin" ]]; then
      since_epoch=$(date -j -f "%Y-%m-%d" "$since_date" "+%s" 2>/dev/null)
      today_epoch=$(date "+%s")
    else
      since_epoch=$(date -d "$since_date" "+%s" 2>/dev/null)
      today_epoch=$(date "+%s")
    fi
    find_days=$(( (today_epoch - since_epoch) / 86400 + 2 ))
  else
    range_start=$(get_days_ago_start_iso 30)
  fi
  if [[ -n "$until_date" ]]; then
    range_end_iso=$(date_to_iso_utc_end "$until_date" 2>/dev/null)
  fi

  local awk_pricing
  awk_pricing=$(get_awk_pricing_block)

  find "$projects_dir" -name "*.jsonl" -type f -mtime -$((find_days + 1)) 2>/dev/null | while read -r jsonl_file; do
    [[ -z "$jsonl_file" ]] && continue
    jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
      [.timestamp, (.message.model // "default"),
       (.message.usage.input_tokens // 0),
       (.message.usage.output_tokens // 0),
       (.message.usage.cache_creation_input_tokens // 0),
       (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
  done | awk -F'\t' -v start="$range_start" -v end_ts="${range_end_iso:-}" "
  BEGIN {
$awk_pricing
  }
  {
    ts = \$1
    gsub(/\.[0-9]+Z?\$/, \"\", ts)

    if (ts < start) next
    if (end_ts != \"\" && ts >= end_ts) next

    model = \$2
    input = \$3 + 0
    output = \$4 + 0
    cache_write = \$5 + 0
    cache_read = \$6 + 0

    pricing = p[model]
    if (pricing == \"\") pricing = p[\"default\"]
    split(pricing, pr, \" \")
    cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000

    m_sessions[model]++
    m_input[model] += input
    m_output[model] += output
    m_cache_read[model] += cache_read
    m_cost[model] += cost
  }
  END {
    for (m in m_sessions) {
      printf \"BREAKDOWN\t%s\t%d\t%d\t%d\t%d\t%.2f\n\",
        m, m_sessions[m], m_input[m], m_output[m], m_cache_read[m], m_cost[m]
    }
  }"
}

# ============================================================================
# PROJECT BREAKDOWN (for --instances)
# ============================================================================

# Calculate per-project cost breakdown
# Args: [since_date] [until_date] — YYYY-MM-DD format, optional
# Output: TSV lines
# PROJECT\t{sanitized_name}\t{sessions}\t{total_tokens}\t{cost}
calculate_project_breakdown() {
  local since_date="${1:-}" until_date="${2:-}"

  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)

  if [[ -z "$projects_dir" || ! -d "$projects_dir" ]]; then
    return 0
  fi

  # Determine time range
  local range_start range_end_iso="" find_days=30
  if [[ -n "$since_date" ]]; then
    range_start=$(date_to_iso_utc "$since_date" 2>/dev/null)
    local since_epoch today_epoch
    if [[ "$(uname -s)" == "Darwin" ]]; then
      since_epoch=$(date -j -f "%Y-%m-%d" "$since_date" "+%s" 2>/dev/null)
      today_epoch=$(date "+%s")
    else
      since_epoch=$(date -d "$since_date" "+%s" 2>/dev/null)
      today_epoch=$(date "+%s")
    fi
    find_days=$(( (today_epoch - since_epoch) / 86400 + 2 ))
  else
    range_start=$(get_days_ago_start_iso 30)
  fi
  if [[ -n "$until_date" ]]; then
    range_end_iso=$(date_to_iso_utc_end "$until_date" 2>/dev/null)
  fi

  local awk_pricing
  awk_pricing=$(get_awk_pricing_block)

  # Iterate over project directories
  local project_dir
  for project_dir in "$projects_dir"/*/; do
    [[ ! -d "$project_dir" ]] && continue

    # Sanitize project name from directory path
    # Directory names are URL-encoded paths like "-Users-rector-local-dev-foo"
    local dir_name
    dir_name=$(basename "$project_dir")
    local project_name
    # Extract the last path component as the project name
    project_name=$(echo "$dir_name" | sed 's/^-//;s/-/\//g' | awk -F'/' '{print $NF}')
    [[ -z "$project_name" ]] && project_name="$dir_name"

    # Calculate cost for this project
    local project_result
    project_result=$(find "$project_dir" -name "*.jsonl" -type f -mtime -$((find_days + 1)) 2>/dev/null | while read -r jsonl_file; do
      [[ -z "$jsonl_file" ]] && continue
      jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
        [.timestamp, (.message.model // "default"),
         (.message.usage.input_tokens // 0),
         (.message.usage.output_tokens // 0),
         (.message.usage.cache_creation_input_tokens // 0),
         (.message.usage.cache_read_input_tokens // 0)] | @tsv' "$jsonl_file" 2>/dev/null
    done | awk -F'\t' -v start="$range_start" -v end_ts="${range_end_iso:-}" "
    BEGIN {
$awk_pricing
      sessions = 0; total_tokens = 0; total_cost = 0
    }
    {
      ts = \$1
      gsub(/\.[0-9]+Z?\$/, \"\", ts)

      if (ts < start) next
      if (end_ts != \"\" && ts >= end_ts) next

      model = \$2
      input = \$3 + 0
      output = \$4 + 0
      cache_write = \$5 + 0
      cache_read = \$6 + 0

      pricing = p[model]
      if (pricing == \"\") pricing = p[\"default\"]
      split(pricing, pr, \" \")
      cost = (input * pr[1] + output * pr[2] + cache_write * pr[3] + cache_read * pr[4]) / 1000000

      sessions++
      total_tokens += input + output
      total_cost += cost
    }
    END {
      if (sessions > 0)
        printf \"%d\t%d\t%.2f\n\", sessions, total_tokens, total_cost
    }")

    if [[ -n "$project_result" ]]; then
      local p_sessions p_tokens p_cost
      IFS=$'\t' read -r p_sessions p_tokens p_cost <<< "$project_result"
      printf "PROJECT\t%s\t%d\t%d\t%.2f\n" "$project_name" "$p_sessions" "$p_tokens" "$p_cost"
    fi
  done
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f calculate_hourly_breakdown calculate_daily_breakdown
export -f calculate_model_breakdown calculate_project_breakdown
