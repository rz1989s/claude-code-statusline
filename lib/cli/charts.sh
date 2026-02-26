#!/bin/bash

# ============================================================================
# Claude Code Statusline - CLI Charts Module (Issue #217)
# ============================================================================
#
# Provides historical trend visualization with ASCII/Unicode charts:
# - parse_period_arg()           - Parse period strings (30d, 4w, 3m)
# - render_vertical_bar_chart()  - Unicode block bar chart
# - calculate_trend_percentage() - Calculate % change between values
# - show_trends_report()         - Main trends report with chart output
#
# Dependencies: report_format.sh, cost modules, core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CLI_CHARTS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CLI_CHARTS_LOADED=true

# Source formatting utilities
CHARTS_LIB_DIR="${BASH_SOURCE[0]%/*}"
source "${CHARTS_LIB_DIR}/report_format.sh" 2>/dev/null || true

# ============================================================================
# PERIOD PARSING
# ============================================================================

# Parse a period string into number of days
# Supports: "30d" (days), "4w" (weeks), "3m" (months), plain number (days)
# Usage: parse_period_arg "30d"  → outputs "30"
# Returns: exit 1 for invalid input
parse_period_arg() {
  local period="${1:-}"

  [[ -z "$period" ]] && return 1

  case "$period" in
    [0-9]*d)
      # Days: e.g., 30d, 7d, 90d
      local n="${period%d}"
      if [[ ! "$n" =~ ^[0-9]+$ ]] || [[ "$n" -le 0 ]]; then
        echo "Error: Invalid period '$period'. Use format: Nd (e.g., 7d, 30d)" >&2
        return 1
      fi
      echo "$n"
      ;;
    [0-9]*w)
      # Weeks: e.g., 4w, 2w
      local n="${period%w}"
      if [[ ! "$n" =~ ^[0-9]+$ ]] || [[ "$n" -le 0 ]]; then
        echo "Error: Invalid period '$period'. Use format: Nw (e.g., 2w, 4w)" >&2
        return 1
      fi
      echo $(( n * 7 ))
      ;;
    [0-9]*m)
      # Months: e.g., 3m, 6m (approximate: 30 days per month)
      local n="${period%m}"
      if [[ ! "$n" =~ ^[0-9]+$ ]] || [[ "$n" -le 0 ]]; then
        echo "Error: Invalid period '$period'. Use format: Nm (e.g., 1m, 3m)" >&2
        return 1
      fi
      echo $(( n * 30 ))
      ;;
    [0-9]*)
      # Plain number treated as days
      if [[ ! "$period" =~ ^[0-9]+$ ]] || [[ "$period" -le 0 ]]; then
        echo "Error: Invalid period '$period'. Use a positive number." >&2
        return 1
      fi
      echo "$period"
      ;;
    *)
      echo "Error: Invalid period format '$period'. Use: Nd (days), Nw (weeks), Nm (months), or N (days)" >&2
      return 1
      ;;
  esac
}

# ============================================================================
# TREND CALCULATION
# ============================================================================

# Calculate percentage change between two values
# Usage: calculate_trend_percentage "10" "8"  → outputs "+25%"
# Handles: division by zero (previous=0), negative changes
calculate_trend_percentage() {
  local current="${1:-0}"
  local previous="${2:-0}"

  # Handle zero/empty previous (no baseline)
  if awk "BEGIN { exit ($previous + 0 == 0) ? 0 : 1 }" 2>/dev/null; then
    if awk "BEGIN { exit ($current + 0 == 0) ? 0 : 1 }" 2>/dev/null; then
      echo "0%"
    else
      echo "+inf%"
    fi
    return 0
  fi

  local pct
  pct=$(awk "BEGIN {
    diff = ($current + 0) - ($previous + 0)
    pct = (diff / ($previous + 0)) * 100
    if (pct >= 0) {
      printf \"+%.0f%%\", pct
    } else {
      printf \"%.0f%%\", pct
    }
  }" 2>/dev/null) || pct="0%"

  echo "$pct"
}

# ============================================================================
# VERTICAL BAR CHART
# ============================================================================

# Render a vertical Unicode block bar chart
# Usage: render_vertical_bar_chart "1.5,3.2,0.8,2.1" "Mon,Tue,Wed,Thu" 8 "Daily Cost"
# Args:
#   data   - comma-separated numeric values
#   labels - comma-separated label strings
#   height - chart height in rows (default 8)
#   title  - chart title string
# Uses Unicode blocks: ▁▂▃▄▅▆▇█ for proportional rendering
render_vertical_bar_chart() {
  local data_str="${1:-}"
  local labels_str="${2:-}"
  local height="${3:-8}"
  local title="${4:-}"

  [[ -z "$data_str" ]] && return 0

  # Split data into array using IFS
  local IFS=','
  local data_items=()
  local label_items=()
  read -ra data_items <<< "$data_str"
  read -ra label_items <<< "$labels_str"

  local count=${#data_items[@]}
  [[ "$count" -eq 0 ]] && return 0

  # Find max value for scaling
  local max_val="0"
  local total="0"
  local i
  for i in "${data_items[@]}"; do
    local val
    val=$(awk "BEGIN { printf \"%.4f\", $i + 0 }" 2>/dev/null) || val="0"
    max_val=$(awk "BEGIN { if ($val > $max_val) print $val; else print $max_val }" 2>/dev/null) || max_val="$val"
    total=$(awk "BEGIN { printf \"%.4f\", $total + $val }" 2>/dev/null) || total="0"
  done

  # Print title
  if [[ -n "$title" ]]; then
    echo ""
    echo "  $title"
    echo "  $(printf '%*s' ${#title} '' | tr ' ' '─')"
  fi

  # Unicode block characters (8 levels)
  local blocks=" ▁▂▃▄▅▆▇█"

  # Guard against zero max
  if awk "BEGIN { exit ($max_val + 0 <= 0) ? 0 : 1 }" 2>/dev/null; then
    # All values are zero — render flat chart
    local row
    for ((row = height; row >= 1; row--)); do
      local y_label
      y_label=$(printf "%6s" "0.00")
      if [[ "$row" -eq "$height" ]]; then
        y_label=$(printf "%6s" "0.00")
      elif [[ "$row" -eq 1 ]]; then
        y_label=$(printf "%6s" "0.00")
      else
        y_label=$(printf "%6s" "")
      fi
      printf "  %s │" "$y_label"
      local col
      for ((col = 0; col < count; col++)); do
        printf "   "
      done
      echo ""
    done
  else
    # Render chart rows from top to bottom
    local row
    for ((row = height; row >= 1; row--)); do
      # Y-axis label (show value at top and bottom)
      local y_val y_label
      if [[ "$row" -eq "$height" ]]; then
        y_label=$(awk "BEGIN { printf \"%6.2f\", $max_val + 0 }" 2>/dev/null)
      elif [[ "$row" -eq 1 ]]; then
        y_label=$(printf "%6s" "0.00")
      else
        y_label=$(printf "%6s" "")
      fi
      printf "  %s │" "$y_label"

      # Render each column for this row
      local col
      for ((col = 0; col < count; col++)); do
        local val
        val=$(awk "BEGIN { printf \"%.4f\", ${data_items[$col]} + 0 }" 2>/dev/null) || val="0"

        # Calculate how many full rows this value fills
        local scaled
        scaled=$(awk "BEGIN {
          s = ($val / $max_val) * $height
          printf \"%.4f\", s
        }" 2>/dev/null) || scaled="0"

        local full_rows
        full_rows=$(awk "BEGIN { printf \"%d\", int($scaled) }" 2>/dev/null) || full_rows="0"

        local frac
        frac=$(awk "BEGIN {
          s = ($val / $max_val) * $height
          f = s - int(s)
          printf \"%.4f\", f
        }" 2>/dev/null) || frac="0"

        if [[ "$row" -le "$full_rows" ]]; then
          # Full block
          printf " █ "
        elif [[ "$row" -eq $((full_rows + 1)) ]]; then
          # Fractional block
          local block_idx
          block_idx=$(awk "BEGIN { printf \"%d\", int($frac * 8 + 0.5) }" 2>/dev/null) || block_idx="0"
          if [[ "$block_idx" -gt 8 ]]; then block_idx=8; fi
          if [[ "$block_idx" -le 0 ]]; then
            printf "   "
          else
            local block_char
            block_char=$(echo "$blocks" | cut -c$((block_idx + 1)))
            printf " %s " "$block_char"
          fi
        else
          printf "   "
        fi
      done
      echo ""
    done
  fi

  # X-axis separator
  printf "  %6s └" ""
  for ((i = 0; i < count; i++)); do
    printf "───"
  done
  echo ""

  # X-axis labels
  printf "  %6s  " ""
  for ((i = 0; i < count; i++)); do
    local lbl="${label_items[$i]:-}"
    # Truncate label to 3 chars for alignment
    if [[ ${#lbl} -gt 3 ]]; then
      lbl="${lbl:0:3}"
    fi
    printf "%-3s" "$lbl"
  done
  echo ""

  # Summary line
  local avg
  avg=$(awk "BEGIN { printf \"%.2f\", $total / $count }" 2>/dev/null) || avg="0.00"
  echo ""
  printf "  Avg: \$%s  |  Peak: \$%s  |  Total: \$%s\n" "$avg" "$(awk "BEGIN { printf \"%.2f\", $max_val }" 2>/dev/null)" "$(awk "BEGIN { printf \"%.2f\", $total }" 2>/dev/null)"
}

# ============================================================================
# TRENDS REPORT
# ============================================================================

# Main trends report — shows historical cost trends with ASCII chart
# Usage: show_trends_report [format] [compact] [since] [until] [project] [period]
# Args:
#   format  - "human" for ASCII output, "json" for JSON array
#   compact - "true" for single-line JSON output
#   since   - YYYY-MM-DD start date filter
#   until   - YYYY-MM-DD end date filter
#   project - project name filter
#   period  - period string (default: 30d)
show_trends_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"
  local period="${6:-30d}"

  # Parse period to days
  local days
  days=$(parse_period_arg "$period") || return 1

  # Use --since/--until if provided, otherwise derive from period
  local effective_since="$since"
  if [[ -z "$effective_since" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
      effective_since=$(date -v-${days}d +%Y-%m-%d 2>/dev/null)
    else
      effective_since=$(date -d "$days days ago" +%Y-%m-%d 2>/dev/null)
    fi
  fi

  local effective_until="$until"
  if [[ -z "$effective_until" ]]; then
    effective_until=$(date +%Y-%m-%d 2>/dev/null)
  fi

  # Source cost modules for data access
  local lib_dir="${CHARTS_LIB_DIR%/cli}"
  source "${lib_dir}/cost.sh" 2>/dev/null || true
  source "${lib_dir}/cost/api_live.sh" 2>/dev/null || true
  source "${lib_dir}/cost/report_calc.sh" 2>/dev/null || true
  source "${lib_dir}/cost/native_calc.sh" 2>/dev/null || true
  source "${lib_dir}/cost/pricing.sh" 2>/dev/null || true

  # Get daily breakdown data
  local daily_data=""
  if declare -f calculate_daily_breakdown &>/dev/null; then
    daily_data=$(calculate_daily_breakdown "$days" "$effective_since" "$effective_until" "$project" 2>/dev/null) || daily_data=""
  fi

  if [[ -z "$daily_data" ]]; then
    if [[ "$format" == "json" ]]; then
      if [[ "$compact" == "true" ]]; then
        echo '{"period":"'"$period"'","days":'"$days"',"data":[],"message":"No trend data available"}'
      else
        echo '{'
        echo '  "period": "'"$period"'",'
        echo '  "days": '"$days"','
        echo '  "data": [],'
        echo '  "message": "No trend data available"'
        echo '}'
      fi
    else
      echo ""
      echo "  Historical Cost Trends"
      echo "  ══════════════════════"
      echo ""
      echo "  No trend data available for the selected period ($period)."
      echo "  Cost data is collected from Claude Code JSONL session files."
      echo ""
    fi
    return 0
  fi

  # Parse daily_data into arrays
  # Expected format: DATE\tWEEKDAY\tCOST\tTOKENS\tSESSIONS
  local dates=()
  local costs=()
  local tokens_list=()
  local sessions_list=()

  while IFS=$'\t' read -r d_date d_weekday d_cost d_tokens d_sessions; do
    [[ -z "$d_date" ]] && continue
    dates+=("$d_date")
    costs+=("${d_cost:-0}")
    tokens_list+=("${d_tokens:-0}")
    sessions_list+=("${d_sessions:-0}")
  done <<< "$daily_data"

  local data_count=${#dates[@]}

  if [[ "$data_count" -eq 0 ]]; then
    if [[ "$format" == "json" ]]; then
      if [[ "$compact" == "true" ]]; then
        echo '{"period":"'"$period"'","days":'"$days"',"data":[],"message":"No trend data available"}'
      else
        echo '{'
        echo '  "period": "'"$period"'",'
        echo '  "days": '"$days"','
        echo '  "data": [],'
        echo '  "message": "No trend data available"'
        echo '}'
      fi
    else
      echo ""
      echo "  Historical Cost Trends"
      echo "  ══════════════════════"
      echo ""
      echo "  No trend data available for the selected period ($period)."
      echo ""
    fi
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    # JSON output
    local json_entries=""
    local idx
    for ((idx = 0; idx < data_count; idx++)); do
      local entry
      entry=$(printf '{"date":"%s","cost":%s,"tokens":%s,"sessions":%s}' \
        "${dates[$idx]}" "${costs[$idx]}" "${tokens_list[$idx]}" "${sessions_list[$idx]}")
      if [[ -n "$json_entries" ]]; then
        json_entries="${json_entries},${entry}"
      else
        json_entries="$entry"
      fi
    done

    # Calculate totals
    local total_cost="0" total_tokens="0" total_sessions="0"
    for ((idx = 0; idx < data_count; idx++)); do
      total_cost=$(awk "BEGIN { printf \"%.2f\", $total_cost + ${costs[$idx]} }" 2>/dev/null) || true
      total_tokens=$(awk "BEGIN { printf \"%d\", $total_tokens + ${tokens_list[$idx]} }" 2>/dev/null) || true
      total_sessions=$(awk "BEGIN { printf \"%d\", $total_sessions + ${sessions_list[$idx]} }" 2>/dev/null) || true
    done

    local avg_cost
    avg_cost=$(awk "BEGIN { printf \"%.2f\", $total_cost / $data_count }" 2>/dev/null) || avg_cost="0.00"

    # Calculate trend (compare first half vs second half)
    local half=$((data_count / 2))
    local first_half_cost="0" second_half_cost="0"
    for ((idx = 0; idx < half; idx++)); do
      first_half_cost=$(awk "BEGIN { printf \"%.2f\", $first_half_cost + ${costs[$idx]} }" 2>/dev/null) || true
    done
    for ((idx = half; idx < data_count; idx++)); do
      second_half_cost=$(awk "BEGIN { printf \"%.2f\", $second_half_cost + ${costs[$idx]} }" 2>/dev/null) || true
    done
    local trend_pct
    trend_pct=$(calculate_trend_percentage "$second_half_cost" "$first_half_cost")

    if [[ "$compact" == "true" ]]; then
      printf '{"period":"%s","days":%d,"trend":"%s","total_cost":%.2f,"avg_daily_cost":%.2f,"data":[%s]}\n' \
        "$period" "$days" "$trend_pct" "$total_cost" "$avg_cost" "$json_entries"
    else
      echo '{'
      printf '  "period": "%s",\n' "$period"
      printf '  "days": %d,\n' "$days"
      printf '  "trend": "%s",\n' "$trend_pct"
      printf '  "total_cost": %.2f,\n' "$total_cost"
      printf '  "avg_daily_cost": %.2f,\n' "$avg_cost"
      echo '  "data": ['
      local first=true
      for ((idx = 0; idx < data_count; idx++)); do
        if [[ "$first" == "true" ]]; then
          first=false
        else
          echo ","
        fi
        printf '    {"date": "%s", "cost": %s, "tokens": %s, "sessions": %s}' \
          "${dates[$idx]}" "${costs[$idx]}" "${tokens_list[$idx]}" "${sessions_list[$idx]}"
      done
      echo ""
      echo '  ]'
      echo '}'
    fi
  else
    # Human-readable output with ASCII chart
    echo ""
    echo "  Historical Cost Trends ($period)"
    echo "  ══════════════════════════════════"
    echo ""

    # Build comma-separated values and labels for the chart
    local cost_csv="" label_csv=""
    for ((idx = 0; idx < data_count; idx++)); do
      local short_date
      # Use last 2 chars of date as label (day of month)
      short_date="${dates[$idx]:8:2}"

      if [[ -n "$cost_csv" ]]; then
        cost_csv="${cost_csv},${costs[$idx]}"
        label_csv="${label_csv},${short_date}"
      else
        cost_csv="${costs[$idx]}"
        label_csv="${short_date}"
      fi
    done

    # Determine chart height based on data count
    local chart_height=8
    if [[ "$data_count" -le 5 ]]; then
      chart_height=5
    elif [[ "$data_count" -ge 20 ]]; then
      chart_height=10
    fi

    render_vertical_bar_chart "$cost_csv" "$label_csv" "$chart_height" "Daily Cost (\$)"

    echo ""

    # Summary statistics
    local total_cost="0" peak_cost="0" peak_date=""
    for ((idx = 0; idx < data_count; idx++)); do
      total_cost=$(awk "BEGIN { printf \"%.2f\", $total_cost + ${costs[$idx]} }" 2>/dev/null) || true
      local is_peak
      is_peak=$(awk "BEGIN { print (${costs[$idx]} > $peak_cost) ? 1 : 0 }" 2>/dev/null) || is_peak="0"
      if [[ "$is_peak" == "1" ]]; then
        peak_cost="${costs[$idx]}"
        peak_date="${dates[$idx]}"
      fi
    done

    local avg_cost
    avg_cost=$(awk "BEGIN { printf \"%.2f\", $total_cost / $data_count }" 2>/dev/null) || avg_cost="0.00"

    # Calculate trend (first half vs second half)
    local half=$((data_count / 2))
    local first_half_cost="0" second_half_cost="0"
    for ((idx = 0; idx < half; idx++)); do
      first_half_cost=$(awk "BEGIN { printf \"%.2f\", $first_half_cost + ${costs[$idx]} }" 2>/dev/null) || true
    done
    for ((idx = half; idx < data_count; idx++)); do
      second_half_cost=$(awk "BEGIN { printf \"%.2f\", $second_half_cost + ${costs[$idx]} }" 2>/dev/null) || true
    done
    local trend_pct
    trend_pct=$(calculate_trend_percentage "$second_half_cost" "$first_half_cost")

    echo "  Period:    ${effective_since} to ${effective_until} ($data_count days)"
    echo "  Total:     \$${total_cost}"
    echo "  Average:   \$${avg_cost}/day"
    if [[ -n "$peak_date" ]]; then
      echo "  Peak:      \$${peak_cost} on ${peak_date}"
    fi
    echo "  Trend:     ${trend_pct} (2nd half vs 1st half)"
    echo ""
  fi
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f parse_period_arg render_vertical_bar_chart calculate_trend_percentage
export -f show_trends_report

# ============================================================================
# MODULE LOADED
# ============================================================================

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Charts module loaded" "INFO" || true
