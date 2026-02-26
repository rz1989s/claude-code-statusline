#!/bin/bash
# ============================================================================
# Cost Per Commit Attribution (Issue #215)
# Correlate JSONL costs with git commit timestamps
# ============================================================================

[[ "${STATUSLINE_COST_COMMIT_ATTRIBUTION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_COMMIT_ATTRIBUTION_LOADED=true

# Calculate cost attributed to each commit by time-windowing JSONL data
# Args: $1=repo_dir $2=lookback_days
# Output: Lines of "commit_hash\ttimestamp\tmessage\tcost\ttokens\trelative"
calculate_commit_costs() {
  local repo_dir="${1:-$(pwd)}"
  local lookback_days="${2:-${CONFIG_COST_COMMIT_ATTRIBUTION_LOOKBACK_DAYS:-30}}"

  # Must be a git repo
  if ! git -C "$repo_dir" rev-parse --is-inside-work-tree &>/dev/null; then
    return 0
  fi

  # Get commits with timestamps (newest first)
  local commits
  commits=$(git -C "$repo_dir" log --format="%H %at %s" --since="${lookback_days} days ago" 2>/dev/null) || return 0
  [[ -z "$commits" ]] && return 0

  # Get JSONL directory
  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)
  [[ -z "$projects_dir" || ! -d "$projects_dir" ]] && return 0

  # Find matching project JSONL dir by encoding the repo path
  local repo_abs
  repo_abs=$(cd "$repo_dir" 2>/dev/null && pwd) || return 0
  local encoded_path
  encoded_path=$(echo "$repo_abs" | sed 's|/|-|g')
  local project_jsonl_dir="$projects_dir/$encoded_path"
  [[ -d "$project_jsonl_dir" ]] || return 0

  # Collect all JSONL cost entries with timestamps in one pass
  local cost_data
  cost_data=$(find "$project_jsonl_dir" -name "*.jsonl" -type f 2>/dev/null | while read -r f; do
    [[ -f "$f" ]] || continue
    jq -r 'select(.type == "assistant") | select(.message.usage) | select(.timestamp) |
      [(.timestamp | sub("\\.[0-9]+Z?$"; "") | sub("Z$"; "") | . + "Z" | fromdateiso8601 // 0),
       ((.message.usage.input_tokens // 0) + (.message.usage.output_tokens // 0))] | @tsv' "$f" 2>/dev/null
  done | sort -t$'\t' -k1 -n)

  # Build commit windows and attribute costs
  local prev_timestamp=""
  local commit_count=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local commit_hash timestamp message
    commit_hash="${line%% *}"
    local rest="${line#* }"
    timestamp="${rest%% *}"
    message="${rest#* }"

    # Truncate message to 40 chars
    [[ ${#message} -gt 40 ]] && message="${message:0:37}..."

    # Sum JSONL costs between this commit and previous
    local cost tokens
    if [[ -z "$prev_timestamp" ]]; then
      # First commit (most recent) — cost from commit to now
      local now
      now=$(date +%s)
      read -r cost tokens <<< "$(sum_cost_in_range "$cost_data" "$timestamp" "$now")"
    else
      read -r cost tokens <<< "$(sum_cost_in_range "$cost_data" "$timestamp" "$prev_timestamp")"
    fi

    cost="${cost:-0.00}"
    tokens="${tokens:-0}"

    # Format relative time
    local relative
    relative=$(format_commit_relative_time "$timestamp")

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$commit_hash" "$timestamp" "$message" "$cost" "$tokens" "$relative"

    prev_timestamp="$timestamp"
    commit_count=$((commit_count + 1))
  done <<< "$commits"
}

# Sum costs from pre-collected data within a timestamp range
# Args: $1=cost_data $2=start_ts $3=end_ts
# Output: "cost tokens"
sum_cost_in_range() {
  local cost_data="$1" start_ts="$2" end_ts="$3"
  [[ -z "$cost_data" ]] && { echo "0.00 0"; return; }

  echo "$cost_data" | awk -F'\t' -v start="$start_ts" -v end="$end_ts" '
  BEGIN { cost = 0; tokens = 0 }
  {
    ts = $1 + 0
    if (ts >= start && ts < end) {
      tokens += $2
    }
  }
  END {
    # Estimate cost from tokens using average rate ($3/MTok input, $15/MTok output)
    # Simplified: use blended rate of ~$6/MTok
    cost = tokens * 0.000006
    printf "%.2f %d\n", cost, tokens
  }'
}

# Format unix timestamp to relative time string
format_commit_relative_time() {
  local ts="$1"
  local now
  now=$(date +%s)
  local diff=$((now - ts))

  if [[ $diff -lt 60 ]]; then
    echo "now"
  elif [[ $diff -lt 3600 ]]; then
    echo "$((diff / 60))m ago"
  elif [[ $diff -lt 86400 ]]; then
    echo "$((diff / 3600))h ago"
  else
    echo "$((diff / 86400))d ago"
  fi
}

# Format a single row for human-readable output
format_commit_cost_row() {
  local hash="$1" message="$2" cost="$3" tokens="$4" relative="$5"
  local short_hash="${hash:0:7}"
  local formatted_tokens
  if [[ "${tokens:-0}" -ge 1000000 ]]; then
    formatted_tokens="$(awk "BEGIN { printf \"%.1f\", $tokens / 1000000 }")M"
  elif [[ "${tokens:-0}" -ge 1000 ]]; then
    formatted_tokens="$(awk "BEGIN { printf \"%.1f\", $tokens / 1000 }")K"
  else
    formatted_tokens="$tokens"
  fi
  printf "%-8s(%6s)│ %-28s │ \$%5s │ %6s\n" "$short_hash" "$relative" "$message" "$cost" "$formatted_tokens"
}

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cost commit attribution module loaded" "INFO"
