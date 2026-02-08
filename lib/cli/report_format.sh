#!/bin/bash

# ============================================================================
# Claude Code Statusline - CLI Report Formatting Utilities
# ============================================================================
#
# Provides ASCII drawing and formatting functions for CLI report output:
# - Table separators and alignment
# - Unicode bar charts
# - Number formatting (USD, tokens)
#
# Dependencies: None (standalone utility module)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CLI_REPORT_FORMAT_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CLI_REPORT_FORMAT_LOADED=true

# ============================================================================
# TABLE DRAWING
# ============================================================================

# Draw a table separator line
# Usage: draw_table_separator 60
draw_table_separator() {
  local width="${1:-60}"
  printf '%*s\n' "$width" '' | tr ' ' '─'
}

# ============================================================================
# BAR CHART
# ============================================================================

# Draw a proportional unicode bar
# Usage: draw_bar 5.00 10.00 20
# Args: value, max_value, bar_width (chars)
draw_bar() {
  local value="${1:-0}"
  local max_value="${2:-1}"
  local bar_width="${3:-20}"

  # Avoid division by zero
  if awk "BEGIN { exit ($max_value <= 0) ? 0 : 1 }" 2>/dev/null; then
    echo ""
    return
  fi

  local filled
  filled=$(awk "BEGIN {
    ratio = $value / $max_value
    filled = int(ratio * $bar_width + 0.5)
    if (filled > $bar_width) filled = $bar_width
    if (filled < 0) filled = 0
    print filled
  }")

  local bar=""
  local i
  for ((i = 0; i < filled; i++)); do
    bar+="█"
  done

  echo "$bar"
}

# ============================================================================
# PROGRESS BAR
# ============================================================================

# Render a styled progress bar with percentage label
# Usage: render_progress_bar 75 20 "block"
# Args: percentage (0-100), width (chars), style (block|gradient|simple|minimal)
# Styles:
#   block:    ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░ 50%
#   gradient: ████████▒▒░░░░░░░░░░ 50%
#   simple:   [=========>          ] 50%
#   minimal:  |●●●●●○○○○○| 50%
render_progress_bar() {
  local percentage="${1:-0}"
  local width="${2:-20}"
  local style="${3:-block}"

  # Clamp percentage to 0-100
  if [[ "$percentage" -lt 0 ]]; then percentage=0; fi
  if [[ "$percentage" -gt 100 ]]; then percentage=100; fi

  local filled=$(( percentage * width / 100 ))
  local empty=$(( width - filled ))

  local bar=""
  local i

  case "$style" in
    "block")
      for ((i = 0; i < filled; i++)); do bar+="▓"; done
      for ((i = 0; i < empty; i++)); do bar+="░"; done
      printf '%s %d%%' "$bar" "$percentage"
      ;;
    "gradient")
      # Full blocks for most, half blocks at transition
      local full_blocks=$((filled > 0 ? filled - 1 : 0))
      local transition=$((filled > 0 ? 1 : 0))
      for ((i = 0; i < full_blocks; i++)); do bar+="█"; done
      if [[ "$transition" -gt 0 ]]; then bar+="▒"; fi
      for ((i = 0; i < empty; i++)); do bar+="░"; done
      printf '%s %d%%' "$bar" "$percentage"
      ;;
    "simple")
      bar="["
      for ((i = 0; i < filled; i++)); do
        if [[ $i -eq $((filled - 1)) && "$filled" -lt "$width" ]]; then
          bar+=">"
        else
          bar+="="
        fi
      done
      for ((i = 0; i < empty; i++)); do bar+=" "; done
      bar+="]"
      printf '%s %d%%' "$bar" "$percentage"
      ;;
    "minimal")
      bar="|"
      for ((i = 0; i < filled; i++)); do bar+="●"; done
      for ((i = 0; i < empty; i++)); do bar+="○"; done
      bar+="|"
      printf '%s %d%%' "$bar" "$percentage"
      ;;
    *)
      # Default to block style
      for ((i = 0; i < filled; i++)); do bar+="▓"; done
      for ((i = 0; i < empty; i++)); do bar+="░"; done
      printf '%s %d%%' "$bar" "$percentage"
      ;;
  esac
}

# ============================================================================
# NUMBER FORMATTING
# ============================================================================

# Format a number as USD
# Usage: format_usd 12.456  →  $12.46
format_usd() {
  local amount="${1:-0}"
  printf '$%.2f' "$amount"
}

# Format token count in short form
# Usage: format_tokens_short 150000  →  150.0K
#        format_tokens_short 1200000 →  1.2M
format_tokens_short() {
  local count="${1:-0}"
  awk "BEGIN {
    c = $count + 0
    if (c >= 1000000) {
      printf \"%.1fM\", c / 1000000
    } else if (c >= 1000) {
      printf \"%.1fK\", c / 1000
    } else {
      printf \"%d\", c
    }
  }"
}

# ============================================================================
# STRING ALIGNMENT
# ============================================================================

# Pad string to the right (left-align)
# Usage: pad_right "hello" 10  →  "hello     "
pad_right() {
  local str="$1"
  local width="${2:-10}"
  printf "%-${width}s" "$str"
}

# Pad string to the left (right-align)
# Usage: pad_left "42" 8  →  "      42"
pad_left() {
  local str="$1"
  local width="${2:-10}"
  printf "%${width}s" "$str"
}

# ============================================================================
# PERCENTAGE FORMATTING
# ============================================================================

# Format a percentage value
# Usage: format_percent 82.5  →  82%
format_percent() {
  local value="${1:-0}"
  awk "BEGIN { printf \"%d%%\", $value + 0.5 }"
}

# ============================================================================
# EXPORTS
# ============================================================================

# ============================================================================
# DATE PARSING
# ============================================================================

# Parse a date argument into YYYY-MM-DD format
# Supports: YYYYMMDD, YYYY-MM-DD, today, yesterday, 7d, 30d, week, month
# Returns: YYYY-MM-DD on stdout, exit 1 on invalid input
parse_date_arg() {
  local input="${1:-}"

  [[ -z "$input" ]] && return 1

  case "$input" in
    today)
      date +%Y-%m-%d
      ;;
    yesterday)
      if [[ "$(uname -s)" == "Darwin" ]]; then
        date -v-1d +%Y-%m-%d
      else
        date -d "1 day ago" +%Y-%m-%d
      fi
      ;;
    week)
      if [[ "$(uname -s)" == "Darwin" ]]; then
        date -v-7d +%Y-%m-%d
      else
        date -d "7 days ago" +%Y-%m-%d
      fi
      ;;
    month)
      if [[ "$(uname -s)" == "Darwin" ]]; then
        date -v-30d +%Y-%m-%d
      else
        date -d "30 days ago" +%Y-%m-%d
      fi
      ;;
    [0-9]*d)
      # Relative: Nd (e.g., 7d, 30d, 90d)
      local n="${input%d}"
      if [[ ! "$n" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid relative date '$input'. Use format: Nd (e.g., 7d, 30d)" >&2
        return 1
      fi
      if [[ "$(uname -s)" == "Darwin" ]]; then
        date -v-${n}d +%Y-%m-%d
      else
        date -d "$n days ago" +%Y-%m-%d
      fi
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      # ISO format: YYYY-MM-DD — validate
      if [[ "$(uname -s)" == "Darwin" ]]; then
        date -j -f "%Y-%m-%d" "$input" "+%Y-%m-%d" 2>/dev/null || {
          echo "Error: Invalid date '$input'" >&2; return 1
        }
      else
        date -d "$input" "+%Y-%m-%d" 2>/dev/null || {
          echo "Error: Invalid date '$input'" >&2; return 1
        }
      fi
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      # Compact format: YYYYMMDD
      local y="${input:0:4}" m="${input:4:2}" d="${input:6:2}"
      local formatted="${y}-${m}-${d}"
      if [[ "$(uname -s)" == "Darwin" ]]; then
        date -j -f "%Y-%m-%d" "$formatted" "+%Y-%m-%d" 2>/dev/null || {
          echo "Error: Invalid date '$input'" >&2; return 1
        }
      else
        date -d "$formatted" "+%Y-%m-%d" 2>/dev/null || {
          echo "Error: Invalid date '$input'" >&2; return 1
        }
      fi
      ;;
    *)
      echo "Error: Invalid date format '$input'. Use YYYYMMDD, YYYY-MM-DD, or relative (7d, 30d, week, month, today, yesterday)" >&2
      return 1
      ;;
  esac
}

# Convert a YYYY-MM-DD date to ISO UTC timestamp (local midnight → UTC)
# Usage: date_to_iso_utc "2026-01-15"
# Returns: 2026-01-14T17:00:00 (for UTC+7)
date_to_iso_utc() {
  local date_str="${1:-}"
  [[ -z "$date_str" ]] && return 1

  local epoch
  if [[ "$(uname -s)" == "Darwin" ]]; then
    epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$date_str 00:00:00" "+%s" 2>/dev/null) || return 1
    date -u -r "$epoch" "+%Y-%m-%dT%H:%M:%S"
  else
    epoch=$(date -d "$date_str" "+%s" 2>/dev/null) || return 1
    date -u -d "@$epoch" "+%Y-%m-%dT%H:%M:%S"
  fi
}

# Convert a YYYY-MM-DD date to end-of-day ISO UTC timestamp (next day midnight → UTC)
# Usage: date_to_iso_utc_end "2026-01-15"
# Returns: 2026-01-15T17:00:00 (for UTC+7, meaning end of local Jan 15)
date_to_iso_utc_end() {
  local date_str="${1:-}"
  [[ -z "$date_str" ]] && return 1

  # Get the next day and use its midnight as the upper bound
  local next_day
  if [[ "$(uname -s)" == "Darwin" ]]; then
    next_day=$(date -j -f "%Y-%m-%d" -v+1d "$date_str" "+%Y-%m-%d" 2>/dev/null) || return 1
  else
    next_day=$(date -d "$date_str + 1 day" "+%Y-%m-%d" 2>/dev/null) || return 1
  fi

  date_to_iso_utc "$next_day"
}

# ============================================================================
# PROJECT FILTERING
# ============================================================================

# Resolve a project name query to matching search path(s)
# Supports exact match, fuzzy (substring) match, and ambiguity detection
# Args: query — project name or partial name
# Returns (stdout): path to scan (projects_dir or specific project_dir)
# Returns (exit): 0=success, 1=no match, 2=ambiguous
resolve_project_filter() {
  local query="${1:-}"
  local projects_dir="${2:-}"

  [[ -z "$query" || -z "$projects_dir" || ! -d "$projects_dir" ]] && return 1

  local -a exact_matches=()
  local -a fuzzy_matches=()

  local project_dir dir_name project_name
  for project_dir in "$projects_dir"/*/; do
    [[ ! -d "$project_dir" ]] && continue
    dir_name=$(basename "$project_dir")
    # Extract last path component as project name
    project_name=$(echo "$dir_name" | sed 's/^-//;s/-/\//g' | awk -F'/' '{print $NF}')
    [[ -z "$project_name" ]] && project_name="$dir_name"

    if [[ "$project_name" == "$query" ]]; then
      exact_matches+=("$project_dir")
    elif [[ "$project_name" == *"$query"* ]]; then
      fuzzy_matches+=("$project_dir")
    fi
  done

  # Exact match takes priority
  if [[ ${#exact_matches[@]} -eq 1 ]]; then
    echo "${exact_matches[0]}"
    return 0
  elif [[ ${#exact_matches[@]} -gt 1 ]]; then
    # Multiple exact matches (unlikely but handle)
    echo "${exact_matches[0]}"
    return 0
  fi

  # Fuzzy match
  if [[ ${#fuzzy_matches[@]} -eq 1 ]]; then
    echo "${fuzzy_matches[0]}"
    return 0
  elif [[ ${#fuzzy_matches[@]} -gt 1 ]]; then
    # Ambiguous — print matches to stderr, return path list to stdout
    echo "AMBIGUOUS" >&2
    for project_dir in "${fuzzy_matches[@]}"; do
      dir_name=$(basename "$project_dir")
      project_name=$(echo "$dir_name" | sed 's/^-//;s/-/\//g' | awk -F'/' '{print $NF}')
      echo "  - $project_name" >&2
    done
    return 2
  fi

  # No match — list available projects
  echo "NO_MATCH" >&2
  for project_dir in "$projects_dir"/*/; do
    [[ ! -d "$project_dir" ]] && continue
    dir_name=$(basename "$project_dir")
    project_name=$(echo "$dir_name" | sed 's/^-//;s/-/\//g' | awk -F'/' '{print $NF}')
    [[ -n "$project_name" ]] && echo "  - $project_name" >&2
  done
  return 1
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f draw_table_separator draw_bar render_progress_bar format_usd format_tokens_short
export -f pad_right pad_left format_percent
export -f parse_date_arg date_to_iso_utc date_to_iso_utc_end
export -f resolve_project_filter
