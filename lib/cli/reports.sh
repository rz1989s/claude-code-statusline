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
# - show_trends_report()  - Historical cost trends with ASCII chart (--trends)
#
# Dependencies: report_format.sh, charts.sh, cost modules, core.sh
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

  # Build JSON safely using jq --arg for string escaping
  local timestamp
  timestamp=$(date +%s)
  local timestamp_iso
  if [[ "$(uname -s)" == "Darwin" ]]; then
    timestamp_iso=$(date -u -r "$timestamp" "+%Y-%m-%dT%H:%M:%SZ")
  else
    timestamp_iso=$(date -u -d "@$timestamp" "+%Y-%m-%dT%H:%M:%SZ")
  fi

  local platform
  platform=$(uname -s)

  jq -n \
    --arg schema_version "2.0" \
    --arg version "${STATUSLINE_VERSION:-unknown}" \
    --argjson timestamp "$timestamp" \
    --arg timestamp_iso "$timestamp_iso" \
    --arg proj_name "$repo_name" \
    --arg proj_path "$current_dir" \
    --arg proj_branch "$repo_branch" \
    --arg proj_status "$repo_status" \
    --argjson proj_commits "$repo_commits_today" \
    --argjson proj_submodules "$repo_has_submodules" \
    --arg model_name "$model_display" \
    --arg sess_id "$session_id" \
    --argjson sess_cost "$session_cost" \
    --argjson sess_duration "$session_duration" \
    --argjson sess_added "$lines_added" \
    --argjson sess_removed "$lines_removed" \
    --argjson ctx_used "$ctx_used" \
    --argjson ctx_remaining "$ctx_remaining" \
    --argjson ctx_size "$ctx_size" \
    --argjson cost_d "$cost_daily" \
    --argjson cost_w "$cost_weekly" \
    --argjson cost_m "$cost_monthly" \
    --argjson cost_r "$cost_repo" \
    --argjson mcp_conn "$mcp_connected" \
    --argjson mcp_tot "$mcp_total" \
    --argjson mcp_srv "$mcp_servers" \
    --argjson prayer_on "$prayer_enabled" \
    --arg prayer_nxt "$prayer_next" \
    --arg prayer_tm "$prayer_time" \
    --arg sys_theme "$theme_name" \
    --argjson sys_modules "$modules_count" \
    --arg sys_platform "$platform" \
    '{
      schema_version: $schema_version,
      version: $version,
      timestamp: $timestamp,
      timestamp_iso: $timestamp_iso,
      project: {
        name: $proj_name,
        path: $proj_path,
        branch: $proj_branch,
        status: $proj_status,
        commits_today: $proj_commits,
        has_submodules: $proj_submodules
      },
      model: {
        display_name: $model_name
      },
      session: {
        id: $sess_id,
        cost_usd: $sess_cost,
        duration_ms: $sess_duration,
        lines_added: $sess_added,
        lines_removed: $sess_removed
      },
      context_window: {
        used_percentage: $ctx_used,
        remaining_percentage: $ctx_remaining,
        size: $ctx_size
      },
      cost: {
        currency: "USD",
        daily: $cost_d,
        weekly: $cost_w,
        monthly: $cost_m,
        repository: $cost_r
      },
      mcp: {
        connected: $mcp_conn,
        total: $mcp_tot,
        servers: $mcp_srv
      },
      prayer: {
        enabled: $prayer_on,
        next: $prayer_nxt,
        time: $prayer_tm
      },
      system: {
        theme: $sys_theme,
        modules_loaded: $sys_modules,
        platform: $sys_platform
      }
    }' | if [[ "$compact" == "true" ]]; then jq -c .; else cat; fi

  return 0
}

# ============================================================================
# DAILY REPORT (Issue #200)
# ============================================================================

# Show today's cost report with hourly breakdown
# Usage: show_daily_report [format] [compact] [since] [until]
show_daily_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  # Collect hourly breakdown data
  local hourly_data model_data
  hourly_data=$(calculate_hourly_breakdown "$since" "$until" "$project" 2>/dev/null)
  model_data=$(echo "$hourly_data" | grep "^MODEL" || true)
  hourly_data=$(echo "$hourly_data" | grep "^HOUR" || true)

  # Calculate totals
  local total_cost="0.00" total_sessions="0"
  if [[ -n "$hourly_data" ]]; then
    total_cost=$(echo "$hourly_data" | awk -F'\t' '{ cost += $7; sessions += $3 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$hourly_data" | awk -F'\t' '{ sessions += $3 } END { printf "%d", sessions }')
  fi

  # Get date info
  local report_date report_weekday
  if [[ -n "$since" ]]; then
    report_date="$since"
  else
    report_date=$(date +%Y-%m-%d)
  fi
  if [[ "$(uname -s)" == "Darwin" ]]; then
    report_weekday=$(date -j -f "%Y-%m-%d" "$report_date" "+%A" 2>/dev/null || date +%A)
  else
    report_weekday=$(date -d "$report_date" +%A 2>/dev/null || date +%A)
  fi

  # Build period label for custom ranges
  local period_label="$report_date ($report_weekday)"
  if [[ -n "$since" && -n "$until" && "$since" != "$until" ]]; then
    period_label="$since to $until"
  fi

  if [[ "$format" == "csv" ]]; then
    echo "date,day,sessions,cost_usd,tokens"
    if [[ -n "$hourly_data" ]]; then
      local total_tokens
      total_tokens=$(echo "$hourly_data" | awk -F'\t' '{ t += $4 + $5 } END { printf "%d", t }')
      printf '%s,%s,%s,%s,%s\n' \
        "$(csv_escape_field "$report_date")" \
        "$(csv_escape_field "$report_weekday")" \
        "$total_sessions" "$total_cost" "$total_tokens"
    fi
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    _daily_report_json "$report_date" "$total_cost" "$total_sessions" "$hourly_data" "$model_data" "$compact"
  else
    _daily_report_human "$report_date" "$report_weekday" "$total_cost" "$total_sessions" "$hourly_data" "$model_data" "$period_label"
  fi

  return 0
}

# Human-readable daily report
_daily_report_human() {
  local date="$1" weekday="$2" total_cost="$3" total_sessions="$4"
  local hourly_data="$5" model_data="$6" period_label="${7:-}"

  echo "Claude Code - Daily Cost Report"
  echo "================================"
  echo "Date: ${period_label:-$date ($weekday)}"
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
# Usage: show_weekly_report [format] [compact] [since] [until]
show_weekly_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  # Determine period
  local period_start period_end period_days=7
  if [[ -n "$since" ]]; then
    period_start="$since"
    period_end="${until:-$(date +%Y-%m-%d)}"
    # Calculate days in range
    local s_epoch e_epoch
    if [[ "$(uname -s)" == "Darwin" ]]; then
      s_epoch=$(date -j -f "%Y-%m-%d" "$period_start" "+%s" 2>/dev/null)
      e_epoch=$(date -j -f "%Y-%m-%d" "$period_end" "+%s" 2>/dev/null)
    else
      s_epoch=$(date -d "$period_start" "+%s" 2>/dev/null)
      e_epoch=$(date -d "$period_end" "+%s" 2>/dev/null)
    fi
    period_days=$(( (e_epoch - s_epoch) / 86400 + 1 ))
  else
    if [[ "$(uname -s)" == "Darwin" ]]; then
      period_start=$(date -v-6d +%Y-%m-%d)
    else
      period_start=$(date -d "6 days ago" +%Y-%m-%d)
    fi
    period_end=$(date +%Y-%m-%d)
  fi

  # Get data for the period
  local daily_data model_data
  daily_data=$(calculate_daily_breakdown "$period_days" "$since" "$until" "$project" 2>/dev/null)
  model_data=$(echo "$daily_data" | grep "^MODEL" || true)
  daily_data=$(echo "$daily_data" | grep "^DAY" || true)

  # Get previous period data for comparison (only for default 7-day mode)
  local prev_cost="0.00"
  if [[ -z "$since" ]]; then
    local prev_data
    prev_data=$(calculate_daily_breakdown 14 "" "" "$project" 2>/dev/null | grep "^DAY" || true)
    local week_start_date
    if [[ "$(uname -s)" == "Darwin" ]]; then
      week_start_date=$(date -v-7d +%Y-%m-%d)
    else
      week_start_date=$(date -d "7 days ago" +%Y-%m-%d)
    fi
    local prev_week_data
    prev_week_data=$(echo "$prev_data" | awk -F'\t' -v cutoff="$week_start_date" '$2 < cutoff')
    if [[ -n "$prev_week_data" ]]; then
      prev_cost=$(echo "$prev_week_data" | awk -F'\t' '{ cost += $5 } END { printf "%.2f", cost }')
    fi
  fi

  # Calculate totals
  local total_cost="0.00" total_sessions="0"
  if [[ -n "$daily_data" ]]; then
    total_cost=$(echo "$daily_data" | awk -F'\t' '{ cost += $5; sessions += $4 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$daily_data" | awk -F'\t' '{ sessions += $4 } END { printf "%d", sessions }')
  fi

  if [[ "$format" == "csv" ]]; then
    echo "week_start,week_end,date,day,sessions,cost_usd"
    if [[ -n "$daily_data" ]]; then
      while IFS=$'\t' read -r _ date weekday sessions cost; do
        [[ -z "$date" ]] && continue
        printf '%s,%s,%s,%s,%s,%s\n' \
          "$(csv_escape_field "$period_start")" \
          "$(csv_escape_field "$period_end")" \
          "$(csv_escape_field "$date")" \
          "$(csv_escape_field "$weekday")" \
          "$sessions" "$cost"
      done <<< "$daily_data"
    fi
    return 0
  fi

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
# Usage: show_monthly_report [format] [compact] [since] [until]
show_monthly_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  # Determine period
  local period_start period_end period_days=30
  if [[ -n "$since" ]]; then
    period_start="$since"
    period_end="${until:-$(date +%Y-%m-%d)}"
    local s_epoch e_epoch
    if [[ "$(uname -s)" == "Darwin" ]]; then
      s_epoch=$(date -j -f "%Y-%m-%d" "$period_start" "+%s" 2>/dev/null)
      e_epoch=$(date -j -f "%Y-%m-%d" "$period_end" "+%s" 2>/dev/null)
    else
      s_epoch=$(date -d "$period_start" "+%s" 2>/dev/null)
      e_epoch=$(date -d "$period_end" "+%s" 2>/dev/null)
    fi
    period_days=$(( (e_epoch - s_epoch) / 86400 + 1 ))
  else
    if [[ "$(uname -s)" == "Darwin" ]]; then
      period_start=$(date -v-29d +%Y-%m-%d)
    else
      period_start=$(date -d "29 days ago" +%Y-%m-%d)
    fi
    period_end=$(date +%Y-%m-%d)
  fi

  # Get data for the period
  local daily_data model_data
  daily_data=$(calculate_daily_breakdown "$period_days" "$since" "$until" "$project" 2>/dev/null)
  model_data=$(echo "$daily_data" | grep "^MODEL" || true)
  daily_data=$(echo "$daily_data" | grep "^DAY" || true)

  # Calculate totals
  local total_cost="0.00" total_sessions="0"
  if [[ -n "$daily_data" ]]; then
    total_cost=$(echo "$daily_data" | awk -F'\t' '{ cost += $5; sessions += $4 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$daily_data" | awk -F'\t' '{ sessions += $4 } END { printf "%d", sessions }')
  fi

  if [[ "$format" == "csv" ]]; then
    echo "month,date,day,sessions,cost_usd"
    if [[ -n "$daily_data" ]]; then
      local month_label="${period_start:0:7}"
      while IFS=$'\t' read -r _ date weekday sessions cost; do
        [[ -z "$date" ]] && continue
        printf '%s,%s,%s,%s,%s\n' \
          "$(csv_escape_field "$month_label")" \
          "$(csv_escape_field "$date")" \
          "$(csv_escape_field "$weekday")" \
          "$sessions" "$cost"
      done <<< "$daily_data"
    fi
    return 0
  fi

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
# BREAKDOWN REPORT (Issue #203)
# ============================================================================

# Show per-model cost breakdown
# Usage: show_breakdown_report [format] [compact] [since] [until]
show_breakdown_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  local breakdown_data
  breakdown_data=$(calculate_model_breakdown "$since" "$until" "$project" 2>/dev/null)

  # Calculate totals
  local total_cost="0.00" total_sessions="0"
  if [[ -n "$breakdown_data" ]]; then
    total_cost=$(echo "$breakdown_data" | awk -F'\t' '{ cost += $7; sessions += $3 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$breakdown_data" | awk -F'\t' '{ sessions += $3 } END { printf "%d", sessions }')
  fi

  # Period label
  local period_label="Last 30 Days"
  if [[ -n "$since" && -n "$until" ]]; then
    period_label="$since to $until"
  elif [[ -n "$since" ]]; then
    period_label="Since $since"
  fi

  if [[ "$format" == "csv" ]]; then
    echo "model,sessions,cost_usd,tokens,share_pct"
    if [[ -n "$breakdown_data" ]]; then
      local sorted_data
      sorted_data=$(echo "$breakdown_data" | sort -t$'\t' -k7 -rn)
      while IFS=$'\t' read -r _ model sessions input output cache_read cost; do
        [[ -z "$model" ]] && continue
        local total_tokens pct
        total_tokens=$((input + output))
        if awk "BEGIN { exit ($total_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
          pct=$(awk "BEGIN { printf \"%.1f\", ($cost / $total_cost) * 100 }")
        else
          pct="0.0"
        fi
        printf '%s,%s,%s,%s,%s\n' \
          "$(csv_escape_field "$model")" \
          "$sessions" "$cost" "$total_tokens" "$pct"
      done <<< "$sorted_data"
    fi
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    _breakdown_report_json "$total_cost" "$total_sessions" "$breakdown_data" "$period_label" "$compact"
  else
    _breakdown_report_human "$total_cost" "$total_sessions" "$breakdown_data" "$period_label"
  fi

  return 0
}

# Human-readable breakdown report
_breakdown_report_human() {
  local total_cost="$1" total_sessions="$2" breakdown_data="$3" period_label="$4"

  echo "Claude Code - Model Cost Breakdown"
  echo "==================================="
  echo "Period: $period_label"
  echo "Total: $(format_usd "$total_cost") across $total_sessions sessions"
  echo ""

  if [[ -z "$breakdown_data" ]]; then
    echo "No usage data for this period."
    return 0
  fi

  # Sort by cost descending
  local sorted_data
  sorted_data=$(echo "$breakdown_data" | sort -t$'\t' -k7 -rn)

  # Table header
  printf "%-28s  %8s  %10s  %10s  %8s  %5s\n" "Model" "Sessions" "Input" "Output" "Cost" "Share"
  draw_table_separator 77

  while IFS=$'\t' read -r _ model sessions input output cache_read cost; do
    [[ -z "$model" ]] && continue
    local pct
    if awk "BEGIN { exit ($total_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
      pct=$(awk "BEGIN { printf \"%d\", ($cost / $total_cost) * 100 }")
    else
      pct="0"
    fi
    printf "%-28s  %8d  %10s  %10s  %8s  %4d%%\n" \
      "$model" "$sessions" \
      "$(format_tokens_short "$input")" \
      "$(format_tokens_short "$output")" \
      "$(format_usd "$cost")" "$pct"
  done <<< "$sorted_data"

  draw_table_separator 77
  printf "%-28s  %8d  %10s  %10s  %8s  %5s\n" \
    "TOTAL" "$total_sessions" "" "" "$(format_usd "$total_cost")" "100%"

  # Cost efficiency metrics
  echo ""
  echo "Cost Efficiency:"
  while IFS=$'\t' read -r _ model sessions input output cache_read cost; do
    [[ -z "$model" ]] && continue
    local total_tokens
    total_tokens=$((input + output))
    local efficiency="N/A"
    if [[ "$total_tokens" -gt 0 ]]; then
      efficiency=$(awk "BEGIN { printf \"\$%.4f\", ($cost / ($total_tokens / 1000)) }")
    fi
    printf "  %-28s %s/1K tokens\n" "$model" "$efficiency"
  done <<< "$sorted_data"
}

# JSON breakdown report
_breakdown_report_json() {
  local total_cost="$1" total_sessions="$2" breakdown_data="$3"
  local period_label="$4" compact="$5"

  local models_json="[]"
  if [[ -n "$breakdown_data" ]]; then
    models_json=$(echo "$breakdown_data" | sort -t$'\t' -k7 -rn | awk -F'\t' -v total="$total_cost" '
    BEGIN { printf "[" ; first = 1 }
    {
      if (!first) printf ","
      first = 0
      pct = (total + 0 > 0) ? ($7 / total) * 100 : 0
      total_tok = $4 + $5
      eff = (total_tok > 0) ? ($7 / (total_tok / 1000)) : 0
      printf "{\"model\":\"%s\",\"sessions\":%d,\"input_tokens\":%d,\"output_tokens\":%d,\"cache_read_tokens\":%d,\"cost_usd\":%.2f,\"percent_of_total\":%.1f,\"cost_per_1k_tokens\":%.4f}",
        $2, $3, $4, $5, $6, $7, pct, eff
    }
    END { printf "]" }')
  fi

  local json_str
  json_str=$(jq -n \
    --arg period "$period_label" \
    --argjson total_cost "$total_cost" \
    --argjson total_sessions "$total_sessions" \
    --argjson models "$models_json" \
    '{
      report: "breakdown",
      schema_version: "2.0",
      period: $period,
      summary: {
        total_cost_usd: $total_cost,
        total_sessions: $total_sessions,
        currency: "USD"
      },
      models: $models
    }')

  if [[ "$compact" == "true" ]]; then
    echo "$json_str" | jq -c .
  else
    echo "$json_str"
  fi
}

# ============================================================================
# INSTANCES REPORT (Issue #204)
# ============================================================================

# Show multi-project cost summary
# Usage: show_instances_report [format] [compact] [since] [until]
show_instances_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  local project_data
  project_data=$(calculate_project_breakdown "$since" "$until" "$project" 2>/dev/null)

  # Calculate totals
  local total_cost="0.00" total_sessions="0" project_count="0"
  if [[ -n "$project_data" ]]; then
    total_cost=$(echo "$project_data" | awk -F'\t' '{ cost += $5 } END { printf "%.2f", cost }')
    total_sessions=$(echo "$project_data" | awk -F'\t' '{ sessions += $3 } END { printf "%d", sessions }')
    project_count=$(echo "$project_data" | wc -l | tr -d ' ')
  fi

  # Period label
  local period_label="Last 30 Days"
  if [[ -n "$since" && -n "$until" ]]; then
    period_label="$since to $until"
  elif [[ -n "$since" ]]; then
    period_label="Since $since"
  fi

  if [[ "$format" == "csv" ]]; then
    echo "project,sessions,cost_usd,tokens,share_pct"
    if [[ -n "$project_data" ]]; then
      local sorted_data
      sorted_data=$(echo "$project_data" | sort -t$'\t' -k5 -rn)
      while IFS=$'\t' read -r _ name sessions tokens cost; do
        [[ -z "$name" ]] && continue
        local pct
        if awk "BEGIN { exit ($total_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
          pct=$(awk "BEGIN { printf \"%.1f\", ($cost / $total_cost) * 100 }")
        else
          pct="0.0"
        fi
        printf '%s,%s,%s,%s,%s\n' \
          "$(csv_escape_field "$name")" \
          "$sessions" "$cost" "$tokens" "$pct"
      done <<< "$sorted_data"
    fi
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    _instances_report_json "$total_cost" "$total_sessions" "$project_count" \
      "$project_data" "$period_label" "$compact"
  else
    _instances_report_human "$total_cost" "$total_sessions" "$project_count" \
      "$project_data" "$period_label"
  fi

  return 0
}

# Human-readable instances report
_instances_report_human() {
  local total_cost="$1" total_sessions="$2" project_count="$3"
  local project_data="$4" period_label="$5"

  echo "Claude Code - Multi-Project Cost Summary"
  echo "========================================="
  echo "Period: $period_label"
  echo "Total: $(format_usd "$total_cost") across $total_sessions sessions ($project_count projects)"
  echo ""

  if [[ -z "$project_data" ]]; then
    echo "No project data found."
    return 0
  fi

  # Sort by cost descending
  local sorted_data
  sorted_data=$(echo "$project_data" | sort -t$'\t' -k5 -rn)

  # Find max cost for bar scaling
  local max_cost
  max_cost=$(echo "$sorted_data" | awk -F'\t' 'BEGIN { max = 0 } { if ($5 + 0 > max) max = $5 + 0 } END { printf "%.2f", max }')

  # Table header
  printf "%-30s  %8s  %10s  %8s  %5s  %s\n" "Project" "Sessions" "Tokens" "Cost" "Share" "Bar"
  draw_table_separator 80

  while IFS=$'\t' read -r _ name sessions tokens cost; do
    [[ -z "$name" ]] && continue
    local pct bar
    if awk "BEGIN { exit ($total_cost + 0 > 0) ? 0 : 1 }" 2>/dev/null; then
      pct=$(awk "BEGIN { printf \"%d\", ($cost / $total_cost) * 100 }")
    else
      pct="0"
    fi
    bar=$(draw_bar "$cost" "$max_cost" 12)
    printf "%-30s  %8d  %10s  %8s  %4d%%  %s\n" \
      "$name" "$sessions" \
      "$(format_tokens_short "$tokens")" \
      "$(format_usd "$cost")" "$pct" "$bar"
  done <<< "$sorted_data"

  draw_table_separator 80
  printf "%-30s  %8d  %10s  %8s  %5s\n" \
    "TOTAL ($project_count projects)" "$total_sessions" "" "$(format_usd "$total_cost")" "100%"

  # Most active and most expensive
  local most_expensive most_active
  most_expensive=$(echo "$sorted_data" | head -1 | awk -F'\t' '{ print $2 }')
  most_active=$(echo "$sorted_data" | sort -t$'\t' -k3 -rn | head -1 | awk -F'\t' '{ print $2 }')
  local most_expensive_cost
  most_expensive_cost=$(echo "$sorted_data" | head -1 | awk -F'\t' '{ printf "%.2f", $5 }')

  echo ""
  echo "Most Expensive:  $most_expensive ($(format_usd "$most_expensive_cost"))"
  echo "Most Active:     $most_active"
}

# JSON instances report
_instances_report_json() {
  local total_cost="$1" total_sessions="$2" project_count="$3"
  local project_data="$4" period_label="$5" compact="$6"

  local projects_json="[]"
  if [[ -n "$project_data" ]]; then
    projects_json=$(echo "$project_data" | sort -t$'\t' -k5 -rn | awk -F'\t' -v total="$total_cost" '
    BEGIN { printf "[" ; first = 1 }
    {
      if (!first) printf ","
      first = 0
      pct = (total + 0 > 0) ? ($5 / total) * 100 : 0
      gsub(/"/, "\\\"", $2)
      printf "{\"project\":\"%s\",\"sessions\":%d,\"total_tokens\":%d,\"cost_usd\":%.2f,\"percent_of_total\":%.1f}",
        $2, $3, $4, $5, pct
    }
    END { printf "]" }')
  fi

  local json_str
  json_str=$(jq -n \
    --arg period "$period_label" \
    --argjson total_cost "$total_cost" \
    --argjson total_sessions "$total_sessions" \
    --argjson project_count "$project_count" \
    --argjson projects "$projects_json" \
    '{
      report: "instances",
      schema_version: "2.0",
      period: $period,
      summary: {
        total_cost_usd: $total_cost,
        total_sessions: $total_sessions,
        project_count: $project_count,
        currency: "USD"
      },
      projects: $projects
    }')

  if [[ "$compact" == "true" ]]; then
    echo "$json_str" | jq -c .
  else
    echo "$json_str"
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
# BURN RATE REPORT
# ============================================================================

show_burn_rate_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  local burn_data
  burn_data=$(calculate_burn_rate_analysis "$since" "$until" "$project" 2>/dev/null)

  local rate_line prediction_line
  rate_line=$(echo "$burn_data" | grep "^RATE" || true)
  prediction_line=$(echo "$burn_data" | grep "^PREDICTION" || true)

  # Parse rate data
  local total_cost="0.00" total_tokens="0" elapsed_min="0"
  local cost_per_min="0.0000" tokens_per_min="0" cost_per_hour="0.00"
  if [[ -n "$rate_line" ]]; then
    IFS=$'\t' read -r _ total_cost total_tokens elapsed_min cost_per_min tokens_per_min cost_per_hour <<< "$rate_line"
  fi

  # Parse prediction
  local five_hour_cost="0.00" time_to_five="0"
  if [[ -n "$prediction_line" ]]; then
    IFS=$'\t' read -r _ five_hour_cost time_to_five <<< "$prediction_line"
  fi

  # Period label
  local period_label="Today"
  if [[ -n "$since" && -n "$until" ]]; then
    period_label="$since to $until"
  elif [[ -n "$since" ]]; then
    period_label="Since $since"
  fi

  if [[ "$format" == "csv" ]]; then
    echo "metric,value"
    printf '%s,%s\n' "total_cost_usd" "$total_cost"
    printf '%s,%s\n' "total_tokens" "$total_tokens"
    printf '%s,%s\n' "elapsed_minutes" "$elapsed_min"
    printf '%s,%s\n' "cost_per_minute" "$cost_per_min"
    printf '%s,%s\n' "tokens_per_minute" "$tokens_per_min"
    printf '%s,%s\n' "cost_per_hour" "$cost_per_hour"
    printf '%s,%s\n' "five_hour_block_cost" "$five_hour_cost"
    printf '%s,%s\n' "minutes_to_five_dollars" "$time_to_five"
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    _burn_rate_report_json "$total_cost" "$total_tokens" "$elapsed_min" \
      "$cost_per_min" "$tokens_per_min" "$cost_per_hour" \
      "$five_hour_cost" "$time_to_five" "$period_label" "$compact" "$burn_data"
  else
    _burn_rate_report_human "$total_cost" "$total_tokens" "$elapsed_min" \
      "$cost_per_min" "$tokens_per_min" "$cost_per_hour" \
      "$five_hour_cost" "$time_to_five" "$period_label" "$burn_data"
  fi

  return 0
}

# Human-readable burn rate report
_burn_rate_report_human() {
  local total_cost="$1" total_tokens="$2" elapsed_min="$3"
  local cost_per_min="$4" tokens_per_min="$5" cost_per_hour="$6"
  local five_hour_cost="$7" time_to_five="$8" period_label="$9"
  local burn_data="${10}"

  echo "Claude Code - Burn Rate Analysis"
  echo "================================="
  echo "Period: $period_label"
  echo "Total: $(format_usd "$total_cost") | $(format_tokens_short "$total_tokens") tokens | ${elapsed_min}min active"
  echo ""

  if [[ "$elapsed_min" == "0" || "$cost_per_min" == "0.0000" ]]; then
    echo "No active usage data for this period."
    return 0
  fi

  # Current rates
  echo "Current Rates:"
  echo "  Cost:    $(format_usd "$cost_per_min")/min  |  $(format_usd "$cost_per_hour")/hr"
  echo "  Tokens:  ${tokens_per_min}/min  |  $((tokens_per_min * 60))/hr"
  echo ""

  # Predictions
  echo "Predictions (at current rate):"
  echo "  Est. 5hr Block Cost:  $(format_usd "$five_hour_cost")"
  if [[ "$time_to_five" -gt 0 ]]; then
    local hours=$((time_to_five / 60))
    local mins=$((time_to_five % 60))
    if [[ "$hours" -gt 0 ]]; then
      echo "  Time to \$5.00:        ${hours}h ${mins}m"
    else
      echo "  Time to \$5.00:        ${mins}m"
    fi
  fi
  echo ""

  # Trend chart (5-minute windows)
  local window_data
  window_data=$(echo "$burn_data" | grep "^WINDOW" || true)
  if [[ -n "$window_data" ]]; then
    local max_cost
    max_cost=$(echo "$window_data" | awk -F'\t' 'BEGIN { max = 0 } { if ($3 + 0 > max) max = $3 + 0 } END { printf "%.4f", max }')

    echo "Activity (5-min windows):"
    draw_table_separator 50
    while IFS=$'\t' read -r _ bucket cost tokens; do
      [[ -z "$bucket" ]] && continue
      local h=$((bucket / 60))
      local m=$((bucket % 60))
      local time_str
      time_str=$(printf "%02d:%02d" "$h" "$m")
      local bar
      bar=$(draw_bar "$cost" "$max_cost" 25)
      printf "  %s  %s  %s\n" "$time_str" "$bar" "$(format_usd "$cost")"
    done <<< "$window_data"
  fi
}

# JSON burn rate report
_burn_rate_report_json() {
  local total_cost="$1" total_tokens="$2" elapsed_min="$3"
  local cost_per_min="$4" tokens_per_min="$5" cost_per_hour="$6"
  local five_hour_cost="$7" time_to_five="$8" period_label="$9"
  local compact="${10}" burn_data="${11}"

  local window_json="[]"
  local window_data
  window_data=$(echo "$burn_data" | grep "^WINDOW" || true)
  if [[ -n "$window_data" ]]; then
    window_json=$(echo "$window_data" | awk -F'\t' '
    BEGIN { printf "["; first = 1 }
    {
      if (!first) printf ","
      first = 0
      h = int($2 / 60); m = $2 % 60
      printf "{\"time\":\"%02d:%02d\",\"cost_usd\":%.4f,\"tokens\":%d}", h, m, $3, $4
    }
    END { printf "]" }')
  fi

  if [[ "$compact" == "true" ]]; then
    jq -n -c \
      --arg report "burn_rate" \
      --arg period "$period_label" \
      --argjson total_cost "$total_cost" \
      --argjson total_tokens "$total_tokens" \
      --argjson elapsed_min "$elapsed_min" \
      --argjson cost_per_min "$cost_per_min" \
      --argjson tokens_per_min "$tokens_per_min" \
      --argjson cost_per_hour "$cost_per_hour" \
      --argjson five_hour_cost "$five_hour_cost" \
      --argjson time_to_five_min "$time_to_five" \
      --argjson windows "$window_json" \
      '{report:$report,period:$period,rates:{cost_per_minute:$cost_per_min,cost_per_hour:$cost_per_hour,tokens_per_minute:$tokens_per_min},predictions:{five_hour_block_cost:$five_hour_cost,minutes_to_five_dollars:$time_to_five_min},summary:{total_cost_usd:$total_cost,total_tokens:$total_tokens,elapsed_minutes:$elapsed_min},windows:$windows}'
  else
    jq -n \
      --arg report "burn_rate" \
      --arg period "$period_label" \
      --argjson total_cost "$total_cost" \
      --argjson total_tokens "$total_tokens" \
      --argjson elapsed_min "$elapsed_min" \
      --argjson cost_per_min "$cost_per_min" \
      --argjson tokens_per_min "$tokens_per_min" \
      --argjson cost_per_hour "$cost_per_hour" \
      --argjson five_hour_cost "$five_hour_cost" \
      --argjson time_to_five_min "$time_to_five" \
      --argjson windows "$window_json" \
      '{report:$report,period:$period,rates:{cost_per_minute:$cost_per_min,cost_per_hour:$cost_per_hour,tokens_per_minute:$tokens_per_min},predictions:{five_hour_block_cost:$five_hour_cost,minutes_to_five_dollars:$time_to_five_min},summary:{total_cost_usd:$total_cost,total_tokens:$total_tokens,elapsed_minutes:$elapsed_min},windows:$windows}'
  fi
}

# ============================================================================
# ============================================================================
# COMMIT COST REPORT (Issue #215)
# ============================================================================

show_commit_cost_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"
  local repo_dir="${STATUSLINE_WORKING_DIR:-$(pwd)}"

  if [[ "$format" == "json" ]]; then
    local results
    results=$(calculate_commit_costs "$repo_dir")
    if [[ -z "$results" ]]; then
      echo "[]"
      return 0
    fi
    echo "$results" | jq -Rs '
      split("\n") | map(select(length > 0)) |
      map(split("\t") | {
        commit: .[0],
        timestamp: (.[1] | tonumber),
        message: .[2],
        cost_usd: (.[3] | tonumber),
        tokens: (.[4] | tonumber),
        relative: .[5]
      })
    '
    return 0
  fi

  if [[ "$format" == "csv" ]]; then
    echo "commit,message,cost_usd,tokens,relative_time"
    local results
    results=$(calculate_commit_costs "$repo_dir")
    [[ -z "$results" ]] && return 0
    while IFS=$'\t' read -r hash ts msg cost tokens rel; do
      printf '"%s","%s",%s,%s,"%s"\n' "${hash:0:7}" "$msg" "$cost" "$tokens" "$rel"
    done <<< "$results"
    return 0
  fi

  # Human format
  echo ""
  echo "  Commit Attribution"
  echo "  ════════════════════════════════════════════════════════════════"
  echo "  Commit          │ Message                      │   Cost │ Tokens"
  echo "  ────────────────┼──────────────────────────────┼────────┼───────"

  local results total_cost=0 total_tokens=0 count=0
  results=$(calculate_commit_costs "$repo_dir")
  if [[ -z "$results" ]]; then
    echo "  (no commits found in lookback period)"
    echo ""
    return 0
  fi

  while IFS=$'\t' read -r hash ts msg cost tokens rel; do
    [[ -z "$hash" ]] && continue
    printf "  %-8s(%6s)│ %-28s │ \$%5s │ %5s\n" "${hash:0:7}" "$rel" "$msg" "$cost" "${tokens}"
    total_cost=$(awk "BEGIN { printf \"%.2f\", $total_cost + ${cost:-0} }")
    total_tokens=$((total_tokens + ${tokens:-0}))
    count=$((count + 1))
  done <<< "$results"

  echo "  ────────────────┼──────────────────────────────┼────────┼───────"
  printf "  %-16s│ Total (%d commits)%11s│ \$%5s │ %5s\n" "" "$count" "" "$total_cost" "$total_tokens"
  echo ""
}

# ============================================================================
# MCP COST REPORT (Issue #216)
# ============================================================================

show_mcp_cost_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  if [[ "$format" == "json" ]]; then
    local results
    results=$(calculate_mcp_costs "$project")
    if [[ -z "$results" ]]; then
      echo "[]"
      return 0
    fi
    echo "$results" | jq -Rs '
      split("\n") | map(select(length > 0)) |
      map(split("\t") | {
        server: .[0],
        calls: (.[1] | tonumber),
        tokens: (.[2] | tonumber),
        cost_usd: (.[3] | tonumber),
        share_percent: (.[4] | tonumber)
      })
    '
    return 0
  fi

  if [[ "$format" == "csv" ]]; then
    echo "server,calls,tokens,cost_usd,share_percent"
    local results
    results=$(calculate_mcp_costs "$project")
    [[ -z "$results" ]] && return 0
    while IFS=$'\t' read -r server calls tokens cost share; do
      printf '"%s",%s,%s,%s,%s\n' "$server" "$calls" "$tokens" "$cost" "$share"
    done <<< "$results"
    return 0
  fi

  # Human format
  echo ""
  echo "  MCP Cost Attribution"
  echo "  ════════════════════════════════════════════════════════════════"
  echo "  MCP Server      │ Calls │  Tokens │   Cost │ Share"
  echo "  ────────────────┼───────┼─────────┼────────┼──────"

  local results total_calls=0 total_tokens=0 total_cost=0
  results=$(calculate_mcp_costs "$project")
  if [[ -z "$results" ]]; then
    echo "  (no MCP tool usage found)"
    echo ""
    return 0
  fi

  while IFS=$'\t' read -r server calls tokens cost share; do
    [[ -z "$server" ]] && continue
    local formatted_tokens
    if [[ "${tokens:-0}" -ge 1000000 ]]; then
      formatted_tokens="$(awk "BEGIN { printf \"%.1f\", $tokens / 1000000 }")M"
    elif [[ "${tokens:-0}" -ge 1000 ]]; then
      formatted_tokens="$(awk "BEGIN { printf \"%.1f\", $tokens / 1000 }")K"
    else
      formatted_tokens="$tokens"
    fi
    printf "  %-16s│ %5s │ %7s │ \$%5s │ %3s%%\n" "$server" "$calls" "$formatted_tokens" "$cost" "$share"
    total_calls=$((total_calls + calls))
    total_tokens=$((total_tokens + tokens))
    total_cost=$(awk "BEGIN { printf \"%.2f\", $total_cost + ${cost:-0} }")
  done <<< "$results"

  echo "  ────────────────┼───────┼─────────┼────────┼──────"
  printf "  %-16s│ %5s │ %7s │ \$%5s │ 100%%\n" "Total" "$total_calls" "$total_tokens" "$total_cost"
  echo ""
}

# ============================================================================
# RECOMMENDATIONS REPORT (Issue #221)
# ============================================================================

show_recommendations_report() {
  local format="${1:-human}"
  local compact="${2:-false}"
  local since="${3:-}" until="${4:-}" project="${5:-}"

  local rec_data
  rec_data=$(generate_recommendations "$since" "$until" "$project" 2>/dev/null) || true

  if [[ "$format" == "csv" ]]; then
    echo "priority,category,message,savings_estimate"
    if [[ -n "$rec_data" ]]; then
      while IFS=$'\t' read -r priority category message savings; do
        [[ -z "$priority" ]] && continue
        printf '%s,%s,%s,%s\n' \
          "$(csv_escape_field "$priority")" \
          "$(csv_escape_field "$category")" \
          "$(csv_escape_field "$message")" \
          "$(csv_escape_field "${savings:--}")"
      done <<< "$rec_data"
    fi
    return 0
  fi

  if [[ "$format" == "json" ]]; then
    _recommendations_report_json "$rec_data" "$compact"
  else
    _recommendations_report_human "$rec_data"
  fi

  return 0
}

# Human-readable recommendations report
_recommendations_report_human() {
  local rec_data="$1"

  echo "Claude Code - Smart Cost Recommendations"
  echo "========================================="
  echo ""

  if [[ -z "$rec_data" ]]; then
    echo "No recommendations at this time. Your usage patterns look efficient."
    echo ""
    echo "Checks performed:"
    echo "  - Cache efficiency"
    echo "  - Session cost spikes"
    echo "  - Budget pacing"
    echo "  - Average session cost"
    echo "  - Idle time detection"
    return 0
  fi

  local count=0
  local high_count=0 medium_count=0 low_count=0

  while IFS=$'\t' read -r priority category message savings; do
    [[ -z "$priority" ]] && continue
    count=$((count + 1))

    local icon="  "
    case "$priority" in
      HIGH)   icon="!!"; high_count=$((high_count + 1)) ;;
      MEDIUM) icon="! "; medium_count=$((medium_count + 1)) ;;
      LOW)    icon="i "; low_count=$((low_count + 1)) ;;
    esac

    printf "[%s] %-7s [%-10s] %s\n" "$icon" "$priority" "$category" "$message"
    if [[ -n "$savings" && "$savings" != "-" ]]; then
      printf "    %s Potential savings: %s\n" "" "$savings"
    fi
    echo ""
  done <<< "$rec_data"

  echo "-----------------------------------------"
  printf "Total: %d recommendation(s)" "$count"
  if [[ "$high_count" -gt 0 ]]; then
    printf " (%d high" "$high_count"
    if [[ "$medium_count" -gt 0 || "$low_count" -gt 0 ]]; then
      printf ", %d medium, %d low" "$medium_count" "$low_count"
    fi
    printf ")"
  fi
  echo ""
}

# JSON recommendations report
_recommendations_report_json() {
  local rec_data="$1"
  local compact="${2:-false}"

  local items_json="[]"
  if [[ -n "$rec_data" ]]; then
    items_json=$(echo "$rec_data" | grep -v '^$' | awk -F'\t' '
    BEGIN { printf "["; first = 1 }
    {
      if (!first) printf ","
      first = 0
      gsub(/"/, "\\\"", $3)
      gsub(/"/, "\\\"", $4)
      printf "{\"priority\":\"%s\",\"category\":\"%s\",\"message\":\"%s\",\"savings_estimate\":\"%s\"}", $1, $2, $3, $4
    }
    END { printf "]" }')
  fi

  local count
  count=$(echo "$items_json" | jq 'length' 2>/dev/null) || count=0
  local high_count
  high_count=$(echo "$items_json" | jq '[.[] | select(.priority == "HIGH")] | length' 2>/dev/null) || high_count=0

  if [[ "$compact" == "true" ]]; then
    jq -n -c \
      --arg report "recommendations" \
      --argjson count "$count" \
      --argjson high_priority "$high_count" \
      --argjson items "$items_json" \
      '{report:$report,count:$count,high_priority:$high_priority,recommendations:$items}'
  else
    jq -n \
      --arg report "recommendations" \
      --argjson count "$count" \
      --argjson high_priority "$high_count" \
      --argjson items "$items_json" \
      '{report:$report,count:$count,high_priority:$high_priority,recommendations:$items}'
  fi
}

# ============================================================================
# HISTORICAL TRENDS REPORT (Issue #217)
# ============================================================================

# Show historical cost trends with ASCII chart
# Delegates to charts.sh module for rendering
# Usage: show_trends_report [format] [compact] [since] [until] [project] [period]
# show_trends_report() is defined in lib/cli/charts.sh and sourced on demand
# This wrapper ensures the charts module is loaded
if ! declare -f show_trends_report &>/dev/null; then
  show_trends_report() {
    local format="${1:-human}"
    local compact="${2:-false}"
    local since="${3:-}" until="${4:-}" project="${5:-}"
    local period="${6:-30d}"

    # Source charts module which defines the real show_trends_report
    source "${CLI_LIB_DIR}/charts.sh" 2>/dev/null || {
      echo "Error: charts module not available" >&2
      return 1
    }

    # Safety: verify the real function was loaded to prevent infinite recursion
    if [[ "${STATUSLINE_CLI_CHARTS_LOADED:-}" != "true" ]]; then
      echo "Error: charts module failed to initialize" >&2
      return 1
    fi

    # Delegate to the real implementation from charts.sh
    show_trends_report "$format" "$compact" "$since" "$until" "$project" "$period"
  }
fi

# EXPORTS
# ============================================================================

export -f show_json_export show_daily_report show_weekly_report show_monthly_report
export -f show_breakdown_report show_instances_report show_burn_rate_report
export -f show_commit_cost_report show_mcp_cost_report
export -f show_recommendations_report show_trends_report
