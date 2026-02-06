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

export -f draw_table_separator draw_bar format_usd format_tokens_short
export -f pad_right pad_left format_percent
