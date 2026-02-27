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

# ============================================================================
# DISCLAIMER: MCP Cost Estimation
# ============================================================================
# The per-call cost and token estimates below are ROUGH APPROXIMATIONS intended
# for relative comparison between MCP servers only. They do NOT represent actual
# billing data from Anthropic or any MCP provider. Real costs vary significantly
# based on model, prompt size, tool output length, and provider pricing.
#
# Configurable via:
#   CONFIG_MCP_ESTIMATED_COST_PER_CALL  (default: 0.003)
#   CONFIG_MCP_ESTIMATED_TOKENS_PER_CALL (default: 500)
# ============================================================================

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
  # Use xargs for batch processing instead of per-file jq calls
  local mcp_data
  mcp_data=$(find "$search_path" -name "*.jsonl" -type f -mtime -30 2>/dev/null | \
    xargs -P4 -L50 jq -r 'select(.type == "assistant") | select(.message.content) |
      .message.content[] | select(.type == "tool_use") | select(.name | startswith("mcp__")) |
      .name' 2>/dev/null)

  [[ -z "$mcp_data" ]] && return 0

  # Read configurable estimation parameters (see DISCLAIMER above)
  local est_cost_per_call="${CONFIG_MCP_ESTIMATED_COST_PER_CALL:-0.003}"
  local est_tokens_per_call="${CONFIG_MCP_ESTIMATED_TOKENS_PER_CALL:-500}"

  # Aggregate by server name
  echo "$mcp_data" | awk -v est_tokens="$est_tokens_per_call" -v est_cost="$est_cost_per_call" '
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
      # ESTIMATE ONLY: rough approximation for relative comparison, not actual billing
      tokens = calls[server] * est_tokens
      cost = calls[server] * est_cost
      printf "%s\t%d\t%d\t%.2f\t%.0f\n", server, calls[server], tokens, cost, share
    }
  }' | sort -t$'\t' -k2 -rn
}

[[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "MCP cost attribution module loaded" "INFO" || true
