# MCP Components Split — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split MCP display into 3 explicit components (`mcp_status`, `mcp_servers`, `mcp_plugins`) so every MCP source is visible on the statusline.

**Architecture:** `mcp_status` stays as native-JSON consumer (future CC data). `mcp_servers` reads `.mcp.json` + settings `mcpServers` and probes SSH hosts. `mcp_plugins` reads `enabledPlugins` from settings, filters LSP noise. All 3 render on the same line (line8 default). Names truncated at configurable N chars.

**Tech Stack:** Bash 4+, jq, BATS (testing)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/mcp.sh` | Add `has_native_mcp_field()` (already done), add file-based MCP detection functions |
| Create | `lib/components/mcp_servers.sh` | Component: project MCP servers from `.mcp.json` + settings |
| Create | `lib/components/mcp_plugins.sh` | Component: enabled plugins from settings (minus LSP) |
| Modify | `lib/components/mcp_status.sh` | Fix empty-array handling (already done), no other changes |
| — | `lib/display.sh` | No changes needed — rendering handled inline per component |
| Modify | `lib/config/defaults.sh` | Add defaults for new components |
| Modify | `Config.toml` (template) | Add `mcp_servers`, `mcp_plugins` to line8, component reference |
| Create | `tests/unit/test_mcp_servers.bats` | Tests for mcp_servers component |
| Create | `tests/unit/test_mcp_plugins.bats` | Tests for mcp_plugins component |

---

### Task 1: Add file-based MCP server detection to `lib/mcp.sh`

**Files:**
- Modify: `lib/mcp.sh` (add functions after line ~340)
- Test: `tests/unit/test_mcp_servers.bats`

- [ ] **Step 1: Write failing tests for file-based detection**

Create `tests/unit/test_mcp_servers.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    # Create temp .mcp.json for testing
    export TEST_MCP_DIR="$TEST_TMP_DIR/mcp_test_repo"
    mkdir -p "$TEST_MCP_DIR"
}

teardown() {
    common_teardown
}

@test "get_configured_mcp_servers returns servers from .mcp.json" {
    cat > "$TEST_MCP_DIR/.mcp.json" << 'EOF'
{
  "mcpServers": {
    "prod-monitor": {
      "type": "stdio",
      "command": "ssh",
      "args": ["root@1.2.3.4", "cd /app && ./monitor"]
    },
    "staging-monitor": {
      "type": "stdio",
      "command": "ssh",
      "args": ["root@5.6.7.8", "cd /app && ./monitor"]
    }
  }
}
EOF

    source "$STATUSLINE_SCRIPT" < /dev/null
    run get_configured_mcp_servers "$TEST_MCP_DIR"

    assert_success
    assert_output --partial "prod-monitor"
    assert_output --partial "staging-monitor"
}

@test "get_configured_mcp_servers returns empty for missing .mcp.json" {
    source "$STATUSLINE_SCRIPT" < /dev/null
    run get_configured_mcp_servers "$TEST_MCP_DIR"

    assert_success
    assert_output ""
}

@test "get_configured_mcp_servers returns empty for empty mcpServers" {
    echo '{"mcpServers": {}}' > "$TEST_MCP_DIR/.mcp.json"

    source "$STATUSLINE_SCRIPT" < /dev/null
    run get_configured_mcp_servers "$TEST_MCP_DIR"

    assert_success
    assert_output ""
}

@test "probe_ssh_server returns connected for reachable host" {
    # Use localhost as a known-reachable host
    source "$STATUSLINE_SCRIPT" < /dev/null
    run probe_ssh_server "127.0.0.1" "1"

    assert_success
}

@test "probe_ssh_server returns failure for unreachable host" {
    source "$STATUSLINE_SCRIPT" < /dev/null
    run probe_ssh_server "192.0.2.1" "1"

    assert_failure
}

@test "get_configured_mcp_servers parses server command type" {
    cat > "$TEST_MCP_DIR/.mcp.json" << 'EOF'
{
  "mcpServers": {
    "local-tool": {
      "type": "stdio",
      "command": "node",
      "args": ["server.js"]
    }
  }
}
EOF

    source "$STATUSLINE_SCRIPT" < /dev/null
    run get_configured_mcp_servers "$TEST_MCP_DIR"

    assert_success
    assert_output --partial "local-tool"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/unit/test_mcp_servers.bats`
Expected: FAIL — `get_configured_mcp_servers` and `probe_ssh_server` not defined

- [ ] **Step 3: Implement file-based detection functions in `lib/mcp.sh`**

Add these functions at the end of `lib/mcp.sh` (before the final line), after `get_all_mcp_servers()`:

```bash
# ============================================================================
# FILE-BASED MCP SERVER DETECTION
# ============================================================================
# Reads .mcp.json and settings mcpServers to discover configured servers
# without relying on CC native JSON or claude mcp list CLI.

# Get configured MCP servers from .mcp.json and settings
# Args: $1 = directory to search for .mcp.json (default: current working dir)
# Returns: "name:command:ssh_host" per line (ssh_host empty if not SSH-based)
get_configured_mcp_servers() {
    local search_dir="${1:-${STATUSLINE_CURRENT_DIR:-$(pwd)}}"
    local mcp_json_file="$search_dir/.mcp.json"
    local servers=""

    # Source 1: Project .mcp.json
    if [[ -f "$mcp_json_file" ]]; then
        local file_servers
        file_servers=$(jq -r '
            .mcpServers // {} | to_entries[] |
            .key as $name |
            .value |
            ($name + ":" + (.command // "unknown") + ":" +
                (if .command == "ssh" then (.args[0] // "" | split("@") | if length > 1 then .[1] else .[0] end) else "" end))
        ' "$mcp_json_file" 2>/dev/null)
        if [[ -n "$file_servers" ]]; then
            servers="$file_servers"
        fi
    fi

    # Source 2: Global settings.json mcpServers
    local global_settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
    if [[ -f "$global_settings" ]]; then
        local settings_servers
        settings_servers=$(jq -r '
            .mcpServers // {} | to_entries[] |
            .key as $name |
            .value |
            ($name + ":" + (.command // "unknown") + ":" +
                (if .command == "ssh" then (.args[0] // "" | split("@") | if length > 1 then .[1] else .[0] end) else "" end))
        ' "$global_settings" 2>/dev/null)
        if [[ -n "$settings_servers" ]]; then
            if [[ -n "$servers" ]]; then
                servers="$servers"$'\n'"$settings_servers"
            else
                servers="$settings_servers"
            fi
        fi
    fi

    echo "$servers"
}

# Probe SSH host reachability via TCP check on port 22
# Args: $1 = host, $2 = timeout in seconds (default: 1)
# Returns: 0 if reachable, 1 if not
probe_ssh_server() {
    local host="$1"
    local timeout_sec="${2:-1}"

    if [[ -z "$host" ]]; then
        return 1
    fi

    # Use nc with timeout (most reliable cross-platform)
    if command_exists nc; then
        nc -z -w "$timeout_sec" "$host" 22 &>/dev/null
        return $?
    fi

    # Fallback: bash /dev/tcp with background + kill timeout
    (echo >/dev/tcp/"$host"/22) &>/dev/null &
    local pid=$!
    local elapsed=0
    while kill -0 "$pid" 2>/dev/null && [[ $elapsed -lt $timeout_sec ]]; do
        sleep 0.2
        elapsed=$((elapsed + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        return 1
    fi
    wait "$pid" 2>/dev/null
    return $?
}

# Get configured servers with probed status
# Returns: "name:connected" or "name:failed" comma-separated
get_configured_mcp_servers_with_status() {
    local search_dir="${1:-${STATUSLINE_CURRENT_DIR:-$(pwd)}}"
    local result=""
    # Cross-platform hash: md5sum (Linux) or md5 (macOS)
    local dir_hash
    dir_hash=$(printf '%s' "$search_dir" | md5sum 2>/dev/null | cut -c1-8) ||
    dir_hash=$(printf '%s' "$search_dir" | md5 -q 2>/dev/null | cut -c1-8) ||
    dir_hash="default"
    local cache_key="mcp_configured_servers_${dir_hash}"

    # Check cache (5 min TTL)
    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        local cached
        cached=$(get_cached_value "$cache_key" "300" 2>/dev/null)
        if [[ -n "$cached" ]]; then
            debug_log "MCP configured servers from cache: $cached" "INFO"
            echo "$cached"
            return 0
        fi
    fi

    local servers
    servers=$(get_configured_mcp_servers "$search_dir")

    if [[ -z "$servers" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local name="${line%%:*}"
        local rest="${line#*:}"
        local command="${rest%%:*}"
        local ssh_host="${rest#*:}"

        local status="configured"
        if [[ "$command" == "ssh" && -n "$ssh_host" ]]; then
            if probe_ssh_server "$ssh_host" "1"; then
                status="connected"
            else
                status="failed"
            fi
        elif command_exists "$command"; then
            status="connected"
        else
            status="failed"
        fi

        if [[ -n "$result" ]]; then
            result="$result,$name:$status"
        else
            result="$name:$status"
        fi
    done <<< "$servers"

    # Cache result
    if [[ -n "$result" && "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        set_cached_value "$cache_key" "$result" 2>/dev/null
    fi

    debug_log "MCP configured servers probed: $result" "INFO"
    echo "$result"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/unit/test_mcp_servers.bats`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/mcp.sh tests/unit/test_mcp_servers.bats
git commit -m "feat: add file-based MCP server detection with SSH probing"
```

---

### Task 2: Add plugin detection functions to `lib/mcp.sh`

**Files:**
- Modify: `lib/mcp.sh` (add functions after file-based detection)
- Test: `tests/unit/test_mcp_plugins.bats`

- [ ] **Step 1: Write failing tests for plugin detection**

Create `tests/unit/test_mcp_plugins.bats`:

```bash
#!/usr/bin/env bats

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    export TEST_SETTINGS_DIR="$TEST_TMP_DIR/claude_settings"
    mkdir -p "$TEST_SETTINGS_DIR"
}

teardown() {
    common_teardown
}

@test "get_enabled_mcp_plugins returns non-LSP plugins" {
    cat > "$TEST_SETTINGS_DIR/settings.json" << 'EOF'
{
  "enabledPlugins": {
    "context7@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "ralph-wiggum@claude-code-plugins": true
  }
}
EOF

    source "$STATUSLINE_SCRIPT" < /dev/null
    CLAUDE_CONFIG_DIR="$TEST_SETTINGS_DIR" run get_enabled_mcp_plugins

    assert_success
    assert_output --partial "context7"
    assert_output --partial "superpowers"
    assert_output --partial "ralph-wiggum"
    refute_output --partial "typescript-lsp"
}

@test "get_enabled_mcp_plugins filters all LSP servers" {
    cat > "$TEST_SETTINGS_DIR/settings.json" << 'EOF'
{
  "enabledPlugins": {
    "rust-analyzer-lsp@claude-plugins-official": true,
    "pyright-lsp@claude-plugins-official": true,
    "gopls-lsp@claude-plugins-official": true
  }
}
EOF

    source "$STATUSLINE_SCRIPT" < /dev/null
    CLAUDE_CONFIG_DIR="$TEST_SETTINGS_DIR" run get_enabled_mcp_plugins

    assert_success
    assert_output ""
}

@test "get_enabled_mcp_plugins returns empty for no plugins" {
    echo '{}' > "$TEST_SETTINGS_DIR/settings.json"

    source "$STATUSLINE_SCRIPT" < /dev/null
    CLAUDE_CONFIG_DIR="$TEST_SETTINGS_DIR" run get_enabled_mcp_plugins

    assert_success
    assert_output ""
}

@test "get_enabled_mcp_plugins skips disabled plugins" {
    cat > "$TEST_SETTINGS_DIR/settings.json" << 'EOF'
{
  "enabledPlugins": {
    "context7@claude-plugins-official": true,
    "superpowers@claude-plugins-official": false
  }
}
EOF

    source "$STATUSLINE_SCRIPT" < /dev/null
    CLAUDE_CONFIG_DIR="$TEST_SETTINGS_DIR" run get_enabled_mcp_plugins

    assert_success
    assert_output --partial "context7"
    refute_output --partial "superpowers"
}

@test "truncate_mcp_name shortens long names" {
    source "$STATUSLINE_SCRIPT" < /dev/null
    run truncate_mcp_name "frontend-design" "10"

    assert_success
    assert_output "frontend-d"
}

@test "truncate_mcp_name preserves short names" {
    source "$STATUSLINE_SCRIPT" < /dev/null
    run truncate_mcp_name "ctx7" "10"

    assert_success
    assert_output "ctx7"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bats tests/unit/test_mcp_plugins.bats`
Expected: FAIL — `get_enabled_mcp_plugins` and `truncate_mcp_name` not defined

- [ ] **Step 3: Implement plugin detection and name truncation in `lib/mcp.sh`**

Add after the file-based detection functions:

```bash
# ============================================================================
# PLUGIN DETECTION
# ============================================================================
# Reads enabledPlugins from settings.json, filters out LSP servers.

# Get enabled MCP plugins (non-LSP) from settings
# Returns: comma-separated "name1,name2,name3"
get_enabled_mcp_plugins() {
    local settings_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        return 0
    fi

    local plugins
    plugins=$(jq -r '
        .enabledPlugins // {} | to_entries[]
        | select(.value == true)
        | .key
        | select(test("-lsp@") | not)
        | split("@") | .[0]
    ' "$settings_file" 2>/dev/null)

    if [[ -z "$plugins" ]]; then
        return 0
    fi

    # Convert newline-separated to comma-separated
    local result=""
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if [[ -n "$result" ]]; then
            result="$result,$name"
        else
            result="$name"
        fi
    done <<< "$plugins"

    echo "$result"
}

# ============================================================================
# NAME FORMATTING
# ============================================================================

# Truncate MCP server/plugin name to max length
# Args: $1 = name, $2 = max_length (default: 15)
truncate_mcp_name() {
    local name="$1"
    local max_len="${2:-15}"

    if [[ ${#name} -le $max_len ]]; then
        echo "$name"
    else
        echo "${name:0:$max_len}"
    fi
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/unit/test_mcp_plugins.bats`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/mcp.sh tests/unit/test_mcp_plugins.bats
git commit -m "feat: add plugin detection and name truncation for MCP display"
```

---

### Task 3: Create `mcp_servers` component

**Files:**
- Create: `lib/components/mcp_servers.sh`

- [ ] **Step 1: Create the mcp_servers component**

Create `lib/components/mcp_servers.sh`:

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Servers Component
# ============================================================================
#
# Displays project-level MCP servers from .mcp.json and settings mcpServers.
# Uses TCP probe for SSH-based servers, command existence for stdio.
#
# Dependencies: mcp.sh, display.sh
# ============================================================================

[[ "${STATUSLINE_MCP_SERVERS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_MCP_SERVERS_LOADED=true

COMPONENT_MCP_SERVERS_DATA=""
COMPONENT_MCP_SERVERS_COUNT=0

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_mcp_servers_data() {
    debug_log "Collecting mcp_servers component data" "INFO"

    COMPONENT_MCP_SERVERS_DATA=""
    COMPONENT_MCP_SERVERS_COUNT=0

    if ! is_module_loaded "mcp"; then
        debug_log "MCP module not loaded, skipping mcp_servers" "INFO"
        return 0
    fi

    local servers_data
    servers_data=$(get_configured_mcp_servers_with_status)

    if [[ -n "$servers_data" ]]; then
        COMPONENT_MCP_SERVERS_DATA="$servers_data"
        # Count servers (comma-separated entries)
        local count=1
        local tmp="$servers_data"
        while [[ "$tmp" == *","* ]]; do
            count=$((count + 1))
            tmp="${tmp#*,}"
        done
        COMPONENT_MCP_SERVERS_COUNT=$count
    fi

    debug_log "mcp_servers data: count=$COMPONENT_MCP_SERVERS_COUNT, data=$COMPONENT_MCP_SERVERS_DATA" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_mcp_servers() {
    if [[ -z "$COMPONENT_MCP_SERVERS_DATA" || "$COMPONENT_MCP_SERVERS_COUNT" -eq 0 ]]; then
        return 1
    fi

    local max_name_len
    max_name_len=$(get_mcp_servers_config "max_name_length" "15")
    local label
    label=$(get_mcp_servers_config "label" "Srv")

    local formatted=""
    local temp_servers="${COMPONENT_MCP_SERVERS_DATA},"
    local parse_count=0

    while [[ "$temp_servers" == *","* ]] && [[ $parse_count -lt 50 ]]; do
        local entry="${temp_servers%%,*}"
        temp_servers="${temp_servers#*,}"
        parse_count=$((parse_count + 1))

        [[ -z "$entry" ]] && continue

        local name="${entry%%:*}"
        local status="${entry#*:}"
        local display_name
        display_name=$(truncate_mcp_name "$name" "$max_name_len")

        local formatted_entry
        case "$status" in
            "connected")
                formatted_entry="${CONFIG_BRIGHT_GREEN}${display_name}${CONFIG_RESET}"
                ;;
            "failed")
                formatted_entry="${CONFIG_RED}${display_name}${CONFIG_RESET}"
                ;;
            *)
                formatted_entry="${CONFIG_YELLOW}${display_name}${CONFIG_RESET}"
                ;;
        esac

        if [[ -n "$formatted" ]]; then
            formatted="$formatted, $formatted_entry"
        else
            formatted="$formatted_entry"
        fi
    done

    echo "${CONFIG_DIM}${label}:${CONFIG_RESET} ${formatted}"
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

get_mcp_servers_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "mcp_servers" "enabled" "${default_value:-true}"
            ;;
        "label")
            get_component_config "mcp_servers" "label" "${default_value:-Srv}"
            ;;
        "max_name_length")
            get_component_config "mcp_servers" "max_name_length" "${default_value:-15}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

register_component \
    "mcp_servers" \
    "Project MCP servers from .mcp.json and settings" \
    "mcp display" \
    "$(get_mcp_servers_config 'enabled' 'true')"

debug_log "MCP servers component loaded" "INFO"
```

- [ ] **Step 2: Run full MCP tests to verify no regressions**

Run: `bats tests/unit/test_mcp_parsing.bats tests/unit/test_mcp_servers.bats`
Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add lib/components/mcp_servers.sh
git commit -m "feat: add mcp_servers component for project-level MCP display"
```

---

### Task 4: Create `mcp_plugins` component

**Files:**
- Create: `lib/components/mcp_plugins.sh`

- [ ] **Step 1: Create the mcp_plugins component**

Create `lib/components/mcp_plugins.sh`:

```bash
#!/bin/bash

# ============================================================================
# Claude Code Statusline - MCP Plugins Component
# ============================================================================
#
# Displays enabled CC plugins (non-LSP) from settings.json enabledPlugins.
# These are CC-managed and always active when CC is running.
#
# Dependencies: mcp.sh, display.sh
# ============================================================================

[[ "${STATUSLINE_MCP_PLUGINS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_MCP_PLUGINS_LOADED=true

COMPONENT_MCP_PLUGINS_DATA=""
COMPONENT_MCP_PLUGINS_COUNT=0

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

collect_mcp_plugins_data() {
    debug_log "Collecting mcp_plugins component data" "INFO"

    COMPONENT_MCP_PLUGINS_DATA=""
    COMPONENT_MCP_PLUGINS_COUNT=0

    local plugins_data
    plugins_data=$(get_enabled_mcp_plugins)

    if [[ -n "$plugins_data" ]]; then
        COMPONENT_MCP_PLUGINS_DATA="$plugins_data"
        # Count plugins (comma-separated entries)
        local count=1
        local tmp="$plugins_data"
        while [[ "$tmp" == *","* ]]; do
            count=$((count + 1))
            tmp="${tmp#*,}"
        done
        COMPONENT_MCP_PLUGINS_COUNT=$count
    fi

    debug_log "mcp_plugins data: count=$COMPONENT_MCP_PLUGINS_COUNT, data=$COMPONENT_MCP_PLUGINS_DATA" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

render_mcp_plugins() {
    if [[ -z "$COMPONENT_MCP_PLUGINS_DATA" || "$COMPONENT_MCP_PLUGINS_COUNT" -eq 0 ]]; then
        return 1
    fi

    local max_name_len
    max_name_len=$(get_mcp_plugins_config "max_name_length" "15")
    local label
    label=$(get_mcp_plugins_config "label" "Ext")

    local formatted=""
    local temp_plugins="${COMPONENT_MCP_PLUGINS_DATA},"
    local parse_count=0

    while [[ "$temp_plugins" == *","* ]] && [[ $parse_count -lt 50 ]]; do
        local name="${temp_plugins%%,*}"
        temp_plugins="${temp_plugins#*,}"
        parse_count=$((parse_count + 1))

        [[ -z "$name" ]] && continue

        local display_name
        display_name=$(truncate_mcp_name "$name" "$max_name_len")

        # Plugins are CC-managed — always active (green) when CC is running
        local formatted_entry="${CONFIG_BRIGHT_GREEN}${display_name}${CONFIG_RESET}"

        if [[ -n "$formatted" ]]; then
            formatted="$formatted, $formatted_entry"
        else
            formatted="$formatted_entry"
        fi
    done

    echo "${CONFIG_DIM}${label}:${CONFIG_RESET} ${formatted}"
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

get_mcp_plugins_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "mcp_plugins" "enabled" "${default_value:-true}"
            ;;
        "label")
            get_component_config "mcp_plugins" "label" "${default_value:-Ext}"
            ;;
        "max_name_length")
            get_component_config "mcp_plugins" "max_name_length" "${default_value:-15}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

register_component \
    "mcp_plugins" \
    "Enabled CC plugins (non-LSP) from settings" \
    "mcp display" \
    "$(get_mcp_plugins_config 'enabled' 'true')"

debug_log "MCP plugins component loaded" "INFO"
```

- [ ] **Step 2: Run all MCP tests**

Run: `bats tests/unit/test_mcp_parsing.bats tests/unit/test_mcp_servers.bats tests/unit/test_mcp_plugins.bats`
Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add lib/components/mcp_plugins.sh
git commit -m "feat: add mcp_plugins component for enabled plugin display"
```

---

### Task 5: Update config defaults and Config.toml

**Files:**
- Modify: `lib/config/defaults.sh`
- Modify: `~/.claude/statusline/Config.toml` (user's installed config)

- [ ] **Step 1: Add defaults for new components in `lib/config/defaults.sh`**

After `CONFIG_MCP_NONE_MESSAGE="none"` (line 92), add:

```bash
    # MCP servers component defaults
    CONFIG_MCP_SERVERS_LABEL="Srv"
    CONFIG_MCP_SERVERS_MAX_NAME_LENGTH="15"
    CONFIG_MCP_SERVERS_PROBE_TIMEOUT="1"
    CONFIG_MCP_SERVERS_CACHE_TTL="300"

    # MCP plugins component defaults
    CONFIG_MCP_PLUGINS_LABEL="Ext"
    CONFIG_MCP_PLUGINS_MAX_NAME_LENGTH="15"
```

- [ ] **Step 2: Update line8 in `lib/config/defaults.sh` test mode**

Change line 111:

```bash
        CONFIG_LINE3_COMPONENTS="mcp_status,mcp_servers,mcp_plugins,reset_timer"
```

- [ ] **Step 3: Update Config.toml template to include new components on line8**

In the Config.toml (template in repo root), update:

```toml
display.line8.components = ["mcp_status", "mcp_servers", "mcp_plugins", "session_mode"]
```

And add to the component reference section:

```toml
# - "mcp_servers"       - Project MCP servers from .mcp.json (with probe status)
# - "mcp_plugins"       - Enabled CC plugins/extensions (non-LSP)
```

- [ ] **Step 4: Update the user's installed Config.toml**

Update `~/.claude/statusline/Config.toml` line 557:

```toml
display.line8.components = ["mcp_status", "mcp_servers", "mcp_plugins", "session_mode"]
```

- [ ] **Step 5: Run the statusline with simulated input to verify all 3 components render**

```bash
echo '{"version":"2.1.87","workspace":{"current_dir":"'"$(pwd)"'"},"model":{"id":"claude-opus-4-6-20250415","display_name":"Claude Opus 4.6"},"context_window":{"used_percentage":12,"remaining_percentage":88,"context_window_size":1000000,"current_usage":{"cache_read_input_tokens":5000,"input_tokens":10000},"total_input_tokens":45000,"total_output_tokens":12000},"cost":{"total_cost_usd":0.45},"session_id":"test","mcp":{"servers":[]}}' | STATUSLINE_DEBUG=true /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh 2>&1 | grep -i 'mcp\|srv\|ext'
```

Expected: Line8 shows `MCP: --- │ Ext: context7, superpowers, ralph-wiggum, frontend-design, agent-sdk-dev, ralph-loop`
(No `Srv:` because this repo has no `.mcp.json`)

- [ ] **Step 6: Commit**

```bash
git add lib/config/defaults.sh
git commit -m "feat: add config defaults for mcp_servers and mcp_plugins components"
```

---

### Task 6: Update Config.toml template in repo and CLAUDE.md docs

**Files:**
- Modify: `Config.toml` (repo template)
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update Config.toml in repo root**

Add `mcp_servers` and `mcp_plugins` to the line8 components list and add their entries to the component reference section.

- [ ] **Step 2: Update CLAUDE.md architecture section**

In the "Atomic Components" section, update the count from 35 to 37 and add under "System & Context":

```
- **MCP & Extensions** (3): mcp_status, mcp_servers, mcp_plugins
```

Remove `mcp_status` from wherever it was listed before (likely System & Context with 5 items, now 4).

- [ ] **Step 3: Commit**

```bash
git add Config.toml CLAUDE.md
git commit -m "docs: add mcp_servers and mcp_plugins to component reference"
```

---

### Task 7: Integration test — full statusline render with all 3 MCP components

**Files:**
- No new files — manual verification

- [ ] **Step 1: Test with Dex-Bot-V2 context (has .mcp.json)**

```bash
echo '{"version":"2.1.87","workspace":{"current_dir":"/Users/rector/local-dev/vot-labs/Dex-Bot-V2"},"model":{"id":"claude-opus-4-6-20250415","display_name":"Claude Opus 4.6"},"context_window":{"used_percentage":4,"remaining_percentage":96,"context_window_size":1000000,"current_usage":{"input_tokens":10000},"total_input_tokens":45000,"total_output_tokens":12000},"cost":{"total_cost_usd":4.87},"session_id":"test","mcp":{"servers":[]}}' | /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh
```

Expected line8: `MCP: --- │ Srv: prod-monitor (red), staging-monitor (red) │ Ext: context7, superpowers, ... │ Style: default`

- [ ] **Step 2: Test with this repo context (no .mcp.json)**

```bash
echo '{"version":"2.1.87","workspace":{"current_dir":"'"$(pwd)"'"},"model":{"id":"claude-opus-4-6-20250415","display_name":"Claude Opus 4.6"},"context_window":{"used_percentage":12,"remaining_percentage":88,"context_window_size":1000000,"current_usage":{"input_tokens":10000},"total_input_tokens":45000,"total_output_tokens":12000},"cost":{"total_cost_usd":0.45},"session_id":"test","mcp":{"servers":[]}}' | /opt/homebrew/bin/bash ~/.claude/statusline/statusline.sh
```

Expected line8: `MCP: --- │ Ext: context7, superpowers, ralph-wiggum, frontend-design, agent-sdk-dev, ralph-loop │ Style: default`

- [ ] **Step 3: Run full test suite**

Run: `npm test`
Expected: All 940+ tests pass, plus new tests for mcp_servers and mcp_plugins

- [ ] **Step 4: Commit any fixes**

If any tests needed adjustment, commit fixes.
