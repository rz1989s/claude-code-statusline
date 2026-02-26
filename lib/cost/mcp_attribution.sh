#!/bin/bash
# ============================================================================
# MCP Cost Attribution (Issue #216)
# Attribute costs to MCP servers by scanning JSONL tool_use entries
# ============================================================================

[[ "${STATUSLINE_COST_MCP_ATTRIBUTION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_MCP_ATTRIBUTION_LOADED=true

# Extract MCP server name from tool name
# Args: $1=tool_name (e.g., "mcp__filesystem__read_file")
# Output: server name (e.g., "filesystem") or empty if not MCP
parse_mcp_server_from_tool() {
  local tool_name="$1"
  if [[ "$tool_name" == mcp__*__* ]]; then
    local without_prefix="${tool_name#mcp__}"
    echo "${without_prefix%%__*}"
  fi
}

# Calculate MCP server cost attribution from JSONL data
# Args: $1=project_filter
# Output: Lines of "server\tcalls\ttokens\tcost\tshare_percent"
calculate_mcp_costs() {
  local project_filter="${1:-}"

  local projects_dir
  projects_dir=$(get_claude_projects_dir 2>/dev/null)
  [[ -z "$projects_dir" || ! -d "$projects_dir" ]] && return 0

  local search_path="$projects_dir"
  if [[ -n "$project_filter" ]]; then
    search_path=$(resolve_project_filter "$project_filter" "$projects_dir" 2>/dev/null) || return 0
  fi

  # Scan JSONL files for tool_use entries with mcp__ prefix
  local mcp_data
  mcp_data=$(find "$search_path" -name "*.jsonl" -type f -mtime -30 2>/dev/null | while read -r f; do
    [[ -f "$f" ]] || continue
    jq -r 'select(.type == "assistant") | select(.message.content) |
      .message.content[] | select(.type == "tool_use") | select(.name | startswith("mcp__")) |
      .name' "$f" 2>/dev/null
  done)

  [[ -z "$mcp_data" ]] && return 0

  # Aggregate by server name
  echo "$mcp_data" | awk '
  {
    # Extract server name: mcp__SERVER__tool
    split($0, parts, "__")
    if (length(parts) >= 3) {
      server = parts[2]
      calls[server]++
      total++
    }
  }
  END {
    if (total == 0) exit
    for (server in calls) {
      share = (calls[server] / total) * 100
      # Estimate tokens per call (~500 avg) and cost (~$0.003 per call)
      tokens = calls[server] * 500
      cost = calls[server] * 0.003
      printf "%s\t%d\t%d\t%.2f\t%.0f\n", server, calls[server], tokens, cost, share
    }
  }' | sort -t$'\t' -k2 -rn
}

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "MCP cost attribution module loaded" "INFO" || true
