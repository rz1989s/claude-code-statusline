# Config Loading Performance Optimization Plan

## Current State Analysis
- **Total jq calls in config loading**: 64 individual process spawns
- **Performance impact**: ~100-200ms per statusline generation
- **Root cause**: Each config value extracted via separate `echo "$config_json" | jq -r` call

## Categories of Config Values Extracted:
1. **Theme**: name (1 call)
2. **Colors** (18 calls):
   - Basic: red, blue, green, yellow, magenta, cyan, white (7 calls)
   - Extended: orange, light_orange, light_gray, bright_green, purple, teal, gold, pink_bright, indigo, violet, light_blue (11 calls)
3. **Features** (7 calls): show_commits, show_version, show_submodules, show_mcp, show_cost, show_reset, show_session
4. **Timeouts** (3 calls): mcp, version, ccusage
5. **Emojis** (8 calls): opus, haiku, sonnet, default_model, clean_status, dirty_status, clock, live_block
6. **Labels** (10 calls): commits, repo, monthly, weekly, daily, mcp, version_prefix, submodule, session_prefix, live, reset
7. **Cache** (2 calls): version_duration, version_file
8. **Display** (3 calls): time_format, date_format, date_format_compact
9. **Messages** (7 calls): no_ccusage, ccusage_install, no_active_block, mcp_unknown, mcp_none, unknown_version, no_submodules

## Optimization Strategy: Single JSON Extraction
Replace 64 individual jq calls with ONE comprehensive jq operation that extracts all values into a structured format, then parse in bash.

### Approach:
1. Create single jq filter that extracts all needed values with fallbacks
2. Output as bash-friendly format (key=value pairs or structured JSON)
3. Parse the result in bash without additional jq calls
4. Maintain exact same logic and fallback behavior

### Benefits:
- **Performance**: ~95% reduction in process spawning (64→1 jq calls)
- **Reliability**: Single point of JSON parsing reduces error surface
- **Maintainability**: Centralized config extraction logic