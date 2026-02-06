#!/bin/bash

# ============================================================================
# Claude Code Statusline - CLI Reports Module
# ============================================================================
#
# Provides CLI report commands for cost analysis:
# - show_json_export()    - Enhanced JSON export (--json / --json --compact)
# - show_daily_report()   - Today's hourly cost breakdown (--daily)
# - show_weekly_report()  - 7-day cost breakdown with WoW comparison (--weekly)
# - show_monthly_report() - 30-day cost breakdown with bar chart (--monthly)
#
# Dependencies: report_format.sh, cost modules, core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CLI_REPORTS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CLI_REPORTS_LOADED=true

# Source formatting utilities
CLI_LIB_DIR="${BASH_SOURCE[0]%/*}"
source "${CLI_LIB_DIR}/report_format.sh" 2>/dev/null || true

# ============================================================================
# ENHANCED JSON EXPORT (Issue #205)
# ============================================================================

# Enhanced JSON export with schema v2.0
# Usage: show_json_export [compact]
# Args: compact - "true" for single-line output, "false" for pretty-printed
show_json_export() {
  local compact="${1:-false}"

  # Repository info
  local repo_name="" repo_branch="" repo_status="not_git"
  local repo_commits_today="0" repo_has_submodules="false"
  local current_dir="${PWD}"

  if declare -f is_module_loaded &>/dev/null && is_module_loaded "git" && declare -f is_git_repository &>/dev/null && is_git_repository; then
    repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
    repo_branch=$(get_git_branch 2>/dev/null)
    repo_status=$(get_git_status 2>/dev/null)
    repo_commits_today=$(get_commits_today 2>/dev/null)
    [[ -f ".gitmodules" ]] && repo_has_submodules="true"
  fi

  # Model info
  local model_display=""
  if [[ -n "${STATUSLINE_INPUT_JSON:-}" ]]; then
    model_display=$(echo "$STATUSLINE_INPUT_JSON" | jq -r 'if (.model | type) == "object" then .model.display_name else .model end // ""' 2>/dev/null)
  fi

  # Session info from native JSON
  local session_id="" session_cost="0" session_duration="0"
  local lines_added="0" lines_removed="0"
  if [[ -n "${STATUSLINE_INPUT_JSON:-}" ]]; then
    session_id=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.session_id // ""' 2>/dev/null)
    session_cost=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
    session_duration=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)
    lines_added=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_lines_added // 0' 2>/dev/null)
    lines_removed=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null)
  fi

  # Context window info
  local ctx_used="0" ctx_remaining="100" ctx_size="200000"
  if [[ -n "${STATUSLINE_INPUT_JSON:-}" ]]; then
    ctx_used=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
    ctx_remaining=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.context_window.remaining_percentage // 100' 2>/dev/null)
    ctx_size=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.context_window.context_window_size // 200000' 2>/dev/null)
  fi

  # Cost info (from native calc - use cached versions for performance)
  local cost_daily="0.00" cost_weekly="0.00" cost_monthly="0.00" cost_repo="0.00"
  if declare -f get_cached_native_usage_info &>/dev/null; then
    local usage_result
    usage_result=$(get_cached_native_usage_info "$current_dir" 2>/dev/null)
    if [[ -n "$usage_result" ]]; then
      IFS=':' read -r cost_repo cost_monthly cost_weekly cost_daily _ _ <<< "$usage_result"
    fi
  elif declare -f calculate_native_daily_cost &>/dev/null; then
    cost_daily=$(calculate_native_daily_cost 2>/dev/null || echo "0.00")
    cost_weekly=$(calculate_native_weekly_cost 2>/dev/null || echo "0.00")
    cost_monthly=$(calculate_native_monthly_cost 2>/dev/null || echo "0.00")
    cost_repo=$(calculate_native_repo_cost "$current_dir" 2>/dev/null || echo "0.00")
  fi

  # MCP info
  local mcp_connected="0" mcp_total="0" mcp_servers="[]"
  if declare -f is_module_loaded &>/dev/null && is_module_loaded "mcp" && declare -f is_claude_cli_available &>/dev/null && is_claude_cli_available; then
    local mcp_status_raw
    mcp_status_raw=$(get_mcp_status 2>/dev/null)
    if [[ "$mcp_status_raw" =~ ^([0-9]+)/([0-9]+)$ ]]; then
      mcp_connected="${BASH_REMATCH[1]}"
      mcp_total="${BASH_REMATCH[2]}"
    fi
    local servers_raw
    servers_raw=$(get_all_mcp_servers 2>/dev/null)
    if [[ -n "$servers_raw" && "$servers_raw" != "none" ]]; then
      mcp_servers=$(echo "$servers_raw" | tr ',' '\n' | jq -R . | jq -s .)
    fi
  fi

  # Prayer info
  local prayer_enabled="false" prayer_next="" prayer_time=""
  if declare -f is_module_loaded &>/dev/null && is_module_loaded "prayer" && [[ "${CONFIG_PRAYER_ENABLED:-false}" == "true" ]]; then
    prayer_enabled="true"
    if declare -f get_next_prayer_info &>/dev/null; then
      local prayer_info
      prayer_info=$(get_next_prayer_info 2>/dev/null)
      prayer_next=$(echo "$prayer_info" | cut -d'|' -f1)
      prayer_time=$(echo "$prayer_info" | cut -d'|' -f2)
    fi
  fi

  # System info
  local theme_name="default" modules_count="0"
  if declare -f get_current_theme &>/dev/null; then
    theme_name=$(get_current_theme 2>/dev/null || echo "default")
  fi
  if declare -p STATUSLINE_MODULES_LOADED &>/dev/null 2>&1; then
    modules_count="${#STATUSLINE_MODULES_LOADED[@]}"
  fi

  # Build JSON with jq
  local timestamp timestamp_iso
  timestamp=$(date +%s)
  if [[ "$(uname -s)" == "Darwin" ]]; then
    timestamp_iso=$(date -u -r "$timestamp" "+%Y-%m-%dT%H:%M:%SZ")
  else
    timestamp_iso=$(date -u -d "@$timestamp" "+%Y-%m-%dT%H:%M:%SZ")
  fi

  local json_str
  json_str=$(cat <<EOF
{
  "schema_version": "2.0",
  "version": "${STATUSLINE_VERSION:-unknown}",
  "timestamp": $timestamp,
  "timestamp_iso": "$timestamp_iso",
  "project": {
    "name": "$repo_name",
    "path": "$current_dir",
    "branch": "$repo_branch",
    "status": "$repo_status",
    "commits_today": $repo_commits_today,
    "has_submodules": $repo_has_submodules
  },
  "model": {
    "display_name": "$model_display"
  },
  "session": {
    "id": "$session_id",
    "cost_usd": $session_cost,
    "duration_ms": $session_duration,
    "lines_added": $lines_added,
    "lines_removed": $lines_removed
  },
  "context_window": {
    "used_percentage": $ctx_used,
    "remaining_percentage": $ctx_remaining,
    "size": $ctx_size
  },
  "cost": {
    "currency": "USD",
    "daily": $cost_daily,
    "weekly": $cost_weekly,
    "monthly": $cost_monthly,
    "repository": $cost_repo
  },
  "mcp": {
    "connected": $mcp_connected,
    "total": $mcp_total,
    "servers": $mcp_servers
  },
  "prayer": {
    "enabled": $prayer_enabled,
    "next": "$prayer_next",
    "time": "$prayer_time"
  },
  "system": {
    "theme": "$theme_name",
    "modules_loaded": $modules_count,
    "platform": "$(uname -s)"
  }
}
EOF
)

  if [[ "$compact" == "true" ]]; then
    echo "$json_str" | jq -c .
  else
    echo "$json_str" | jq .
  fi

  return 0
}

# ============================================================================
# DAILY REPORT (Issue #200)
# ============================================================================

# Show today's cost report with hourly breakdown
# Usage: show_daily_report [format] [compact]
show_daily_report() {
  local format="${1:-human}"
  local compact="${2:-false}"

  # Collect hourly breakdown data
  local hourly_data model_data
  hourly_data=$(calculate_hourly_breakdown 2>/dev/null)
  model_data=$(echo "$hourly_data" | grep "^MODEL" || true)
  hourly_data=$(echo "$hourly_data" | grep "^HOUR" || true)

  # Calculate totals
  local total_cost="0.00" total_sessions="0"
  if [[ -n "$hourly_data" ]]; then
    total_cost=$(echo "$hourly_data" | awk -F'\t' '{ cost += $7; sessions += $3 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$hourly_data" | awk -F'\t' '{ sessions += $3 } END { printf "%d", sessions }')
  fi

  # Get today's date info
  local today_date today_weekday
  today_date=$(date +%Y-%m-%d)
  if [[ "$(uname -s)" == "Darwin" ]]; then
    today_weekday=$(date +%A)
  else
    today_weekday=$(date +%A)
  fi

  if [[ "$format" == "json" ]]; then
    _daily_report_json "$today_date" "$total_cost" "$total_sessions" "$hourly_data" "$model_data" "$compact"
  else
    _daily_report_human "$today_date" "$today_weekday" "$total_cost" "$total_sessions" "$hourly_data" "$model_data"
  fi

  return 0
}

# Human-readable daily report
_daily_report_human() {
  local date="$1" weekday="$2" total_cost="$3" total_sessions="$4"
  local hourly_data="$5" model_data="$6"

  echo "Claude Code - Daily Cost Report"
  echo "================================"
  echo "Date: $date ($weekday)"
  echo "Total: $(format_usd "$total_cost") across $total_sessions sessions"
  echo ""

  if [[ -z "$hourly_data" ]]; then
    echo "No usage data for today."
    return 0
  fi

  # Table header
  printf "%-5s  %8s  %8s  %8s  %6s  %8s\n" "Hour" "Sessions" "Input" "Output" "Cache%" "Cost"
  draw_table_separator 55

  # Table rows (only hours with data)
  while IFS=$'\t' read -r _ hour sessions input output cache_pct cost; do
    [[ -z "$hour" ]] && continue
    local label
    label=$(printf "%02d:00" "$hour")
    printf "%-5s  %8d  %8s  %8s  %5s%%  %8s\n" \
      "$label" "$sessions" \
      "$(format_tokens_short "$input")" \
      "$(format_tokens_short "$output")" \
      "$cache_pct" \
      "$(format_usd "$cost")"
  done <<< "$hourly_data"

  draw_table_separator 55
  printf "%-5s  %8d  %8s  %8s  %6s  %8s\n" \
    "TOTAL" "$total_sessions" "" "" "" "$(format_usd "$total_cost")"

  # Model distribution
  if [[ -n "$model_data" ]]; then
    echo ""
    echo "Model Distribution:"
    local max_model_cost
    max_model_cost=$(echo "$model_data" | awk -F'\t' 'BEGIN { max = 0 } { if ($4 + 0 > max) max = $4 + 0 } END { printf "%.2f", max }')

    while IFS=$'\t' read -r _ model m_sessions m_cost; do
      [[ -z "$model" ]] && continue
      local pct bar
      if awk "BEGIN { exit ($total_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
        pct=$(awk "BEGIN { printf \"%d\", ($m_cost / $total_cost) * 100 }")
      else
        pct="0"
      fi
      bar=$(draw_bar "$m_cost" "$max_model_cost" 16)
      printf "  %-25s %s  %3d calls  %s (%d%%)\n" "$model" "$bar" "$m_sessions" "$(format_usd "$m_cost")" "$pct"
    done <<< "$model_data"
  fi
}

# JSON daily report
_daily_report_json() {
  local date="$1" total_cost="$2" total_sessions="$3"
  local hourly_data="$4" model_data="$5" compact="$6"

  # Build hours array
  local hours_json="[]"
  if [[ -n "$hourly_data" ]]; then
    hours_json=$(echo "$hourly_data" | awk -F'\t' '
    BEGIN { printf "[" ; first = 1 }
    {
      if (!first) printf ","
      first = 0
      printf "{\"hour\":%d,\"label\":\"%02d:00\",\"sessions\":%d,\"input_tokens\":%d,\"output_tokens\":%d,\"cache_hit_percent\":%d,\"cost_usd\":%.2f}",
        $2, $2, $3, $4, $5, $6, $7
    }
    END { printf "]" }')
  fi

  # Build models array
  local models_json="[]"
  if [[ -n "$model_data" ]]; then
    models_json=$(echo "$model_data" | awk -F'\t' -v total="$total_cost" '
    BEGIN { printf "[" ; first = 1 }
    {
      if (!first) printf ","
      first = 0
      pct = (total + 0 > 0) ? ($4 / total) * 100 : 0
      printf "{\"model\":\"%s\",\"sessions\":%d,\"cost_usd\":%.2f,\"percent_of_total\":%.1f}",
        $2, $3, $4, pct
    }
    END { printf "]" }')
  fi

  local json_str
  json_str=$(cat <<EOF
{
  "report": "daily",
  "schema_version": "2.0",
  "date": "$date",
  "summary": {
    "total_cost_usd": $total_cost,
    "total_sessions": $total_sessions,
    "currency": "USD"
  },
  "hours": $hours_json,
  "models": $models_json
}
EOF
)

  if [[ "$compact" == "true" ]]; then
    echo "$json_str" | jq -c .
  else
    echo "$json_str" | jq .
  fi
}

# ============================================================================
# WEEKLY REPORT (Issue #202)
# ============================================================================

# Show 7-day cost report with week-over-week comparison
# Usage: show_weekly_report [format] [compact]
show_weekly_report() {
  local format="${1:-human}"
  local compact="${2:-false}"

  # Get current week data (7 days)
  local daily_data model_data
  daily_data=$(calculate_daily_breakdown 7 2>/dev/null)
  model_data=$(echo "$daily_data" | grep "^MODEL" || true)
  daily_data=$(echo "$daily_data" | grep "^DAY" || true)

  # Get previous week data (days 8-14) for comparison
  local prev_data
  prev_data=$(calculate_daily_breakdown 14 2>/dev/null | grep "^DAY" || true)
  # Filter to only days 8-14 (previous week)
  local week_start_date
  if [[ "$(uname -s)" == "Darwin" ]]; then
    week_start_date=$(date -v-7d +%Y-%m-%d)
  else
    week_start_date=$(date -d "7 days ago" +%Y-%m-%d)
  fi
  local prev_week_data
  prev_week_data=$(echo "$prev_data" | awk -F'\t' -v cutoff="$week_start_date" '$2 < cutoff')

  # Calculate totals
  local total_cost="0.00" total_sessions="0"
  if [[ -n "$daily_data" ]]; then
    total_cost=$(echo "$daily_data" | awk -F'\t' '{ cost += $5; sessions += $4 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$daily_data" | awk -F'\t' '{ sessions += $4 } END { printf "%d", sessions }')
  fi

  # Previous week total
  local prev_cost="0.00"
  if [[ -n "$prev_week_data" ]]; then
    prev_cost=$(echo "$prev_week_data" | awk -F'\t' '{ cost += $5 } END { printf "%.2f", cost }')
  fi

  # Period dates
  local period_start period_end
  if [[ "$(uname -s)" == "Darwin" ]]; then
    period_start=$(date -v-6d +%Y-%m-%d)
  else
    period_start=$(date -d "6 days ago" +%Y-%m-%d)
  fi
  period_end=$(date +%Y-%m-%d)

  if [[ "$format" == "json" ]]; then
    _weekly_report_json "$period_start" "$period_end" "$total_cost" "$total_sessions" \
      "$daily_data" "$model_data" "$prev_cost" "$compact"
  else
    _weekly_report_human "$period_start" "$period_end" "$total_cost" "$total_sessions" \
      "$daily_data" "$model_data" "$prev_cost"
  fi

  return 0
}

# Human-readable weekly report
_weekly_report_human() {
  local start="$1" end="$2" total_cost="$3" total_sessions="$4"
  local daily_data="$5" model_data="$6" prev_cost="$7"

  echo "Claude Code - Weekly Cost Report (Last 7 Days)"
  echo "================================================"
  echo "Period: $start to $end"
  echo "Total: $(format_usd "$total_cost") across $total_sessions sessions"
  echo ""

  if [[ -z "$daily_data" ]]; then
    echo "No usage data for this period."
    return 0
  fi

  # Find max cost for bar scaling
  local max_cost
  max_cost=$(echo "$daily_data" | awk -F'\t' 'BEGIN { max = 0 } { if ($5 + 0 > max) max = $5 + 0 } END { printf "%.2f", max }')

  # Table header
  printf "%-10s  %-9s  %8s  %8s  %-20s\n" "Date" "Day" "Sessions" "Cost" "Bar"
  draw_table_separator 62

  while IFS=$'\t' read -r _ date weekday sessions cost; do
    [[ -z "$date" ]] && continue
    local bar
    bar=$(draw_bar "$cost" "$max_cost" 20)
    printf "%-10s  %-9s  %8d  %8s  %s\n" "$date" "$weekday" "$sessions" "$(format_usd "$cost")" "$bar"
  done <<< "$daily_data"

  draw_table_separator 62

  # Stats
  local daily_avg
  daily_avg=$(awk "BEGIN { printf \"%.2f\", $total_cost / 7 }")

  # Most active day (by sessions)
  local most_active_day
  most_active_day=$(echo "$daily_data" | sort -t$'\t' -k4 -rn | head -1 | awk -F'\t' '{ print $3 }')

  echo ""
  echo "Stats:"
  echo "  Daily Average:    $(format_usd "$daily_avg")"
  echo "  Most Active Day:  ${most_active_day:-N/A}"

  # Week-over-week comparison
  echo ""
  echo "Week-over-Week:"
  echo "  This Week:  $(format_usd "$total_cost")"
  echo "  Last Week:  $(format_usd "$prev_cost")"

  local change_usd change_pct change_sign
  change_usd=$(awk "BEGIN { printf \"%.2f\", $total_cost - $prev_cost }")
  if awk "BEGIN { exit ($prev_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
    change_pct=$(awk "BEGIN { printf \"%.1f\", (($total_cost - $prev_cost) / $prev_cost) * 100 }")
  else
    change_pct="0.0"
  fi

  if awk "BEGIN { exit ($change_usd + 0 >= 0) ? 0 : 1 }" 2>/dev/null; then
    change_sign="+"
  else
    change_sign=""
  fi
  echo "  Change:     ${change_sign}\$${change_usd} (${change_sign}${change_pct}%)"

  # Model distribution
  if [[ -n "$model_data" ]]; then
    _print_model_distribution "$model_data" "$total_cost"
  fi
}

# JSON weekly report
_weekly_report_json() {
  local start="$1" end="$2" total_cost="$3" total_sessions="$4"
  local daily_data="$5" model_data="$6" prev_cost="$7" compact="$8"

  local daily_avg
  daily_avg=$(awk "BEGIN { printf \"%.2f\", $total_cost / 7 }")

  local most_active_day
  if [[ -n "$daily_data" ]]; then
    most_active_day=$(echo "$daily_data" | sort -t$'\t' -k4 -rn | head -1 | awk -F'\t' '{ print $3 }')
  fi

  # Change calculation
  local change_usd change_pct prev_available="true"
  change_usd=$(awk "BEGIN { printf \"%.2f\", $total_cost - $prev_cost }")
  if awk "BEGIN { exit ($prev_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
    change_pct=$(awk "BEGIN { printf \"%.1f\", (($total_cost - $prev_cost) / $prev_cost) * 100 }")
  else
    change_pct="0.0"
    prev_available="false"
  fi

  # Build days array
  local days_json="[]"
  if [[ -n "$daily_data" ]]; then
    days_json=$(echo "$daily_data" | awk -F'\t' '
    BEGIN { printf "[" ; first = 1 }
    {
      if (!first) printf ","
      first = 0
      printf "{\"date\":\"%s\",\"weekday\":\"%s\",\"sessions\":%d,\"cost_usd\":%.2f}",
        $2, $3, $4, $5
    }
    END { printf "]" }')
  fi

  # Build models array
  local models_json
  models_json=$(_models_to_json "$model_data" "$total_cost")

  local json_str
  json_str=$(cat <<EOF
{
  "report": "weekly",
  "schema_version": "2.0",
  "period": {
    "start": "$start",
    "end": "$end",
    "days": 7
  },
  "summary": {
    "total_cost_usd": $total_cost,
    "total_sessions": $total_sessions,
    "daily_average_usd": $daily_avg,
    "most_active_day": "${most_active_day:-}"
  },
  "comparison": {
    "previous_week_cost_usd": $prev_cost,
    "change_usd": $change_usd,
    "change_percent": $change_pct,
    "available": $prev_available
  },
  "days": $days_json,
  "models": $models_json
}
EOF
)

  if [[ "$compact" == "true" ]]; then
    echo "$json_str" | jq -c .
  else
    echo "$json_str" | jq .
  fi
}

# ============================================================================
# MONTHLY REPORT (Issue #201)
# ============================================================================

# Show 30-day cost report with daily breakdown
# Usage: show_monthly_report [format] [compact]
show_monthly_report() {
  local format="${1:-human}"
  local compact="${2:-false}"

  # Get 30-day breakdown
  local daily_data model_data
  daily_data=$(calculate_daily_breakdown 30 2>/dev/null)
  model_data=$(echo "$daily_data" | grep "^MODEL" || true)
  daily_data=$(echo "$daily_data" | grep "^DAY" || true)

  # Calculate totals
  local total_cost="0.00" total_sessions="0"
  if [[ -n "$daily_data" ]]; then
    total_cost=$(echo "$daily_data" | awk -F'\t' '{ cost += $5; sessions += $4 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$daily_data" | awk -F'\t' '{ sessions += $4 } END { printf "%d", sessions }')
  fi

  # Period dates
  local period_start period_end
  if [[ "$(uname -s)" == "Darwin" ]]; then
    period_start=$(date -v-29d +%Y-%m-%d)
  else
    period_start=$(date -d "29 days ago" +%Y-%m-%d)
  fi
  period_end=$(date +%Y-%m-%d)

  if [[ "$format" == "json" ]]; then
    _monthly_report_json "$period_start" "$period_end" "$total_cost" "$total_sessions" \
      "$daily_data" "$model_data" "$compact"
  else
    _monthly_report_human "$period_start" "$period_end" "$total_cost" "$total_sessions" \
      "$daily_data" "$model_data"
  fi

  return 0
}

# Human-readable monthly report
_monthly_report_human() {
  local start="$1" end="$2" total_cost="$3" total_sessions="$4"
  local daily_data="$5" model_data="$6"

  echo "Claude Code - Monthly Cost Report (Last 30 Days)"
  echo "=================================================="
  echo "Period: $start to $end"
  echo "Total: $(format_usd "$total_cost") across $total_sessions sessions"
  echo ""

  if [[ -z "$daily_data" ]]; then
    echo "No usage data for this period."
    return 0
  fi

  # Find max cost for bar scaling
  local max_cost
  max_cost=$(echo "$daily_data" | awk -F'\t' 'BEGIN { max = 0 } { if ($5 + 0 > max) max = $5 + 0 } END { printf "%.2f", max }')

  # Table header
  printf "%-10s  %-3s  %8s  %8s  %-20s\n" "Date" "Day" "Sessions" "Cost" "Bar"
  draw_table_separator 58

  while IFS=$'\t' read -r _ date weekday sessions cost; do
    [[ -z "$date" ]] && continue
    local bar short_day
    bar=$(draw_bar "$cost" "$max_cost" 20)
    short_day=$(echo "$weekday" | cut -c1-3)
    printf "%-10s  %-3s  %8d  %8s  %s\n" "$date" "$short_day" "$sessions" "$(format_usd "$cost")" "$bar"
  done <<< "$daily_data"

  draw_table_separator 58

  # Stats
  local daily_avg peak_day peak_cost active_days
  daily_avg=$(awk "BEGIN { printf \"%.2f\", $total_cost / 30 }")

  local peak_line
  peak_line=$(echo "$daily_data" | sort -t$'\t' -k5 -rn | head -1)
  peak_day=$(echo "$peak_line" | awk -F'\t' '{ printf "%s (%s)", $2, $3 }')
  peak_cost=$(echo "$peak_line" | awk -F'\t' '{ printf "%.2f", $5 }')

  active_days=$(echo "$daily_data" | awk -F'\t' '$4 > 0 { count++ } END { print count + 0 }')

  echo ""
  echo "Stats:"
  echo "  Daily Average:  $(format_usd "$daily_avg")"
  echo "  Peak Day:       $peak_day - $(format_usd "$peak_cost")"
  echo "  Active Days:    $active_days / 30"

  # Model distribution
  if [[ -n "$model_data" ]]; then
    _print_model_distribution "$model_data" "$total_cost"
  fi
}

# JSON monthly report
_monthly_report_json() {
  local start="$1" end="$2" total_cost="$3" total_sessions="$4"
  local daily_data="$5" model_data="$6" compact="$7"

  local daily_avg active_days peak_day
  daily_avg=$(awk "BEGIN { printf \"%.2f\", $total_cost / 30 }")

  if [[ -n "$daily_data" ]]; then
    active_days=$(echo "$daily_data" | awk -F'\t' '$4 > 0 { count++ } END { print count + 0 }')
    peak_day=$(echo "$daily_data" | sort -t$'\t' -k5 -rn | head -1 | awk -F'\t' '{ print $2 }')
  else
    active_days="0"
    peak_day=""
  fi

  # Build days array
  local days_json="[]"
  if [[ -n "$daily_data" ]]; then
    days_json=$(echo "$daily_data" | awk -F'\t' '
    BEGIN { printf "[" ; first = 1 }
    {
      if (!first) printf ","
      first = 0
      printf "{\"date\":\"%s\",\"weekday\":\"%s\",\"sessions\":%d,\"cost_usd\":%.2f}",
        $2, $3, $4, $5
    }
    END { printf "]" }')
  fi

  # Build models array
  local models_json
  models_json=$(_models_to_json "$model_data" "$total_cost")

  local json_str
  json_str=$(cat <<EOF
{
  "report": "monthly",
  "schema_version": "2.0",
  "period": {
    "start": "$start",
    "end": "$end",
    "days": 30
  },
  "summary": {
    "total_cost_usd": $total_cost,
    "total_sessions": $total_sessions,
    "daily_average_usd": $daily_avg,
    "peak_day": "$peak_day",
    "active_days": $active_days
  },
  "days": $days_json,
  "models": $models_json
}
EOF
)

  if [[ "$compact" == "true" ]]; then
    echo "$json_str" | jq -c .
  else
    echo "$json_str" | jq .
  fi
}

# ============================================================================
# SHARED HELPERS
# ============================================================================

# Print model distribution table (reused by weekly and monthly reports)
_print_model_distribution() {
  local model_data="$1" total_cost="$2"

  echo ""
  echo "Model Distribution:"

  local max_model_cost
  max_model_cost=$(echo "$model_data" | awk -F'\t' 'BEGIN { max = 0 } { if ($4 + 0 > max) max = $4 + 0 } END { printf "%.2f", max }')

  while IFS=$'\t' read -r _ model m_sessions m_cost; do
    [[ -z "$model" ]] && continue
    local pct bar
    if awk "BEGIN { exit ($total_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
      pct=$(awk "BEGIN { printf \"%d\", ($m_cost / $total_cost) * 100 }")
    else
      pct="0"
    fi
    bar=$(draw_bar "$m_cost" "$max_model_cost" 16)
    printf "  %-25s %s  %3d calls  %s (%d%%)\n" "$model" "$bar" "$m_sessions" "$(format_usd "$m_cost")" "$pct"
  done <<< "$model_data"
}

# Convert model data to JSON array
_models_to_json() {
  local model_data="$1" total_cost="$2"

  if [[ -z "$model_data" ]]; then
    echo "[]"
    return
  fi

  echo "$model_data" | awk -F'\t' -v total="$total_cost" '
  BEGIN { printf "[" ; first = 1 }
  {
    if (!first) printf ","
    first = 0
    pct = (total + 0 > 0) ? ($4 / total) * 100 : 0
    printf "{\"model\":\"%s\",\"sessions\":%d,\"cost_usd\":%.2f,\"percent_of_total\":%.1f}",
      $2, $3, $4, pct
  }
  END { printf "]" }'
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f show_json_export show_daily_report show_weekly_report show_monthly_report
