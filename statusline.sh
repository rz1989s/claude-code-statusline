#!/usr/bin/env bash

# ============================================================================
# Bash Compatibility Check and Auto-Upgrade
# ============================================================================

# Wrapped in function to satisfy ShellCheck SC2168 (local only valid in functions)
_upgrade_bash_if_needed() {
    # Check if we need modern bash for associative arrays (bash 4.0+)
    [[ "${BASH_VERSION%%.*}" -ge 4 ]] && return 0

    # Try to find and use modern bash automatically - platform-aware
    local bash_candidates=()

    # Platform-aware bash candidate prioritization
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS: try system bash first, then Homebrew installations
        bash_candidates=($(command -v bash 2>/dev/null | head -5) /opt/homebrew/bin/bash /usr/local/bin/bash /opt/local/bin/bash)
    else
        # Linux: try system paths first
        bash_candidates=($(command -v bash 2>/dev/null | head -5) /usr/bin/bash /bin/bash /usr/local/bin/bash)
    fi

    for bash_candidate in "${bash_candidates[@]}"; do
        [[ -z "$bash_candidate" ]] && continue  # Skip empty entries
        if [[ -x "$bash_candidate" ]] && [[ "$("$bash_candidate" -c 'echo ${BASH_VERSION%%.*}' 2>/dev/null)" -ge 4 ]]; then
            # Re-execute script with modern bash
            exec "$bash_candidate" "$0" "$@"
        fi
    done

    # If no modern bash found, warn but continue with degraded functionality
    echo "WARNING: Bash ${BASH_VERSION} detected. Advanced caching features disabled." >&2

    # Platform-specific installation suggestion
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "For full functionality, install bash 4+: brew install bash" >&2
    else
        echo "For full functionality, install bash 4+: sudo apt install bash (or equivalent)" >&2
    fi
    export STATUSLINE_COMPATIBILITY_MODE=true
}
_upgrade_bash_if_needed "$@"

# ============================================================================
# Claude Code Enhanced Statusline - Main Orchestrator (v2.1.0-refactored)
# ============================================================================
# 
# This is the main orchestrator for the modularized Claude Code statusline.
# It loads and coordinates all modules to provide a comprehensive 4-line
# statusline display with git status, MCP monitoring, cost tracking, and
# beautiful themes.
#
# Refactored from monolithic 3930-line script to modular architecture.
# Original functionality preserved with improved maintainability.
# ============================================================================

# Set script directory for module loading
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define critical paths for configuration management
CONFIG_PATH="$HOME/.claude/statusline/Config.toml"
EXAMPLES_DIR="$HOME/.claude/statusline/examples"
SAMPLE_CONFIGS_DIR="$EXAMPLES_DIR/sample-configs"

# ============================================================================
# CORE MODULE LOADING
# ============================================================================

# Load core module first (provides module loading infrastructure)
if [[ -f "$SCRIPT_DIR/lib/core.sh" ]]; then
    source "$SCRIPT_DIR/lib/core.sh"
else
    echo "FATAL ERROR: Core module not found at $SCRIPT_DIR/lib/core.sh" >&2
    echo "Please ensure the lib/ directory is present with all required modules." >&2
    exit 1
fi

# Verify core module loaded successfully
if [[ "${STATUSLINE_CORE_LOADED:-}" != "true" ]]; then
    echo "FATAL ERROR: Core module failed to initialize properly" >&2
    exit 1
fi

# Enable strict mode for fail-fast behavior (Issue #77)
# This enables: set -euo pipefail with ERR trap for better debugging
enable_strict_mode

# ============================================================================
# MODULE LOADING SEQUENCE
# ============================================================================

# Load modules in dependency order
debug_log "Starting module loading sequence..." "INFO"
start_timer "module_loading"

# Load security module (required by most other modules)
# Security-first sanitization and validation for all inputs
load_module "security" || {
    handle_error "Failed to load security module - statusline disabled. Check lib/security.sh exists and is readable." 1 "main"
    exit 1
}

# Load universal caching module (provides performance optimization for all external commands)
# Secure file operations via create_secure_cache_file for all cache management
load_module "cache" || {
    handle_warning "Cache module failed to load - performance optimizations disabled. All commands will run directly." "main"
}

# Load configuration module
# Performance optimization: single-pass jq config extraction
load_module "config" || {
    handle_error "Failed to load config module - configuration parsing disabled. Check lib/config.sh and TOML dependencies." 1 "main"
    exit 1
}

# Load theme module
load_module "themes" || {
    handle_error "Failed to load themes module - theme system disabled. Check lib/themes.sh for color support." 1 "main"
    exit 1
}

# Load git integration module
load_module "git" || {
    handle_warning "Git module failed to load - git features disabled. Repository status unavailable." "main"
}

# Load MCP monitoring module
load_module "mcp" || {
    handle_warning "MCP module failed to load - MCP monitoring disabled. Server status unavailable." "main"
}

# Load cost tracking module
load_module "cost" || {
    handle_warning "Cost module failed to load - cost tracking disabled. ccusage integration unavailable." "main"
}

# Load prayer times and Hijri calendar module
load_module "prayer" || {
    handle_warning "Prayer module failed to load - prayer times and Hijri calendar disabled." "main"
}

# Load component system module (required for modular display)
load_module "components" || {
    handle_warning "Components module failed to load - modular display disabled. Falling back to legacy display." "main"
}

# Initialize the component system after loading the module
if is_module_loaded "components"; then
    init_component_system
fi

# Load display/formatting module
load_module "display" || {
    handle_error "Failed to load display module - output formatting disabled. Check lib/display.sh." 1 "main"
    exit 1
}

module_load_time=$(end_timer "module_loading")
debug_log "Module loading completed in ${module_load_time}s" "INFO"

# ============================================================================
# CONFIGURATION INITIALIZATION
# ============================================================================

debug_log "Initializing configuration..." "INFO"
start_timer "config_init"

# Load configuration from all sources (defaults -> TOML -> env overrides)
load_configuration || {
    handle_warning "Configuration loading failed, using defaults" "main"
}

# Apply theme
apply_theme || {
    handle_warning "Theme application failed, using defaults" "main"
}

config_time=$(end_timer "config_init")
debug_log "Configuration initialization completed in ${config_time}s" "INFO"

# ============================================================================
# COMMAND-LINE INTERFACE
# ============================================================================

# Handle command-line arguments (preserved from original)
show_usage() {
    cat <<'EOF'
Claude Code Statusline (Refactored v2.1.0)
==========================================

USAGE:
    statusline.sh [options]                 - Run statusline (default)
    statusline.sh --help                    - Show this help message
    statusline.sh --version                 - Show version information
    statusline.sh --test-display            - Test display formatting
    statusline.sh --modules                 - Show loaded modules
    statusline.sh --health                  - Show system health status
    statusline.sh --health=json             - Show health status (JSON format)
    statusline.sh --metrics                 - Show performance metrics (JSON)
    statusline.sh --metrics=prometheus      - Show metrics (Prometheus format)
    statusline.sh --list-themes             - List available themes
    statusline.sh --preview-theme <name>    - Preview a theme's colors

THEMES:
    Available: classic, garden, catppuccin, custom

    ENV_CONFIG_THEME=classic ./statusline.sh    - Use classic theme
    ENV_CONFIG_THEME=garden ./statusline.sh     - Use garden theme
    ENV_CONFIG_THEME=catppuccin ./statusline.sh - Use catppuccin theme

DEBUGGING:
    STATUSLINE_DEBUG=true ./statusline.sh        - Enable debug logging
    STATUSLINE_LOG_FORMAT=json STATUSLINE_DEBUG=true ./statusline.sh - JSON logs

FEATURES:
    - 4-line statusline with git status, MCP monitoring, and cost tracking
    - TOML configuration support (Config.toml)  
    - 3 built-in themes + custom theme support
    - Intelligent caching for performance
    - Modular architecture for maintainability

For detailed configuration, see: https://github.com/rz1989s/claude-code-statusline
EOF
}

# Show health status for diagnostics and monitoring
show_health_status() {
    local format="${1:-human}"
    local status="healthy"
    local exit_code=0
    local issues=()

    # Collect dependency versions
    local bash_version="${BASH_VERSION%%(*}"
    local jq_version
    local curl_version
    local git_version

    jq_version=$(jq --version 2>/dev/null | sed 's/jq-//')
    curl_version=$(curl --version 2>/dev/null | head -1 | awk '{print $2}')
    git_version=$(git --version 2>/dev/null | awk '{print $3}')

    # Check critical dependencies
    local deps_ok=true
    [[ -z "$jq_version" ]] && deps_ok=false && issues+=("jq not found")
    [[ -z "$curl_version" ]] && deps_ok=false && issues+=("curl not found")
    [[ "${BASH_VERSINFO[0]}" -lt 4 ]] && deps_ok=false && issues+=("bash < 4.0")

    # Check modules
    local modules_loaded=${#STATUSLINE_MODULES_LOADED[@]}
    local modules_failed=${#STATUSLINE_MODULES_FAILED[@]}
    [[ $modules_failed -gt 0 ]] && issues+=("$modules_failed module(s) failed to load")

    # Check config file
    local config_status="valid"
    local config_path="${CONFIG_PATH:-$HOME/.claude/statusline/Config.toml}"
    if [[ ! -f "$config_path" ]]; then
        config_status="missing"
        issues+=("Config.toml not found")
    fi

    # Check cache directory
    local cache_status="writable"
    local cache_dir="${CLAUDE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline}"
    if [[ ! -d "$cache_dir" ]]; then
        cache_status="missing"
    elif [[ ! -w "$cache_dir" ]]; then
        cache_status="read-only"
        issues+=("Cache directory not writable")
    fi

    # Check optional dependencies
    local ccusage_status="not installed"
    command -v ccusage >/dev/null 2>&1 && ccusage_status="available"
    command -v bunx >/dev/null 2>&1 && [[ "$ccusage_status" == "not installed" ]] && ccusage_status="available (via bunx)"

    # Determine overall status
    [[ ${#issues[@]} -gt 0 ]] && status="degraded"
    [[ "$deps_ok" == "false" ]] && status="unhealthy" && exit_code=1

    # Output based on format
    if [[ "$format" == "json" ]]; then
        # Properly quote string values, handle null for missing deps
        local jq_val="${jq_version:-null}"
        local curl_val="${curl_version:-null}"
        local git_val="${git_version:-null}"
        [[ "$jq_val" != "null" ]] && jq_val="\"$jq_val\""
        [[ "$curl_val" != "null" ]] && curl_val="\"$curl_val\""
        [[ "$git_val" != "null" ]] && git_val="\"$git_val\""

        cat <<EOF
{
  "status": "$status",
  "version": "$STATUSLINE_VERSION",
  "modules_loaded": $modules_loaded,
  "modules_failed": $modules_failed,
  "dependencies": {
    "bash": "$bash_version",
    "jq": $jq_val,
    "curl": $curl_val,
    "git": $git_val
  },
  "optional": {
    "ccusage": "$ccusage_status"
  },
  "config": "$config_status",
  "cache": "$cache_status"
}
EOF
    else
        # Human-readable output
        echo "Claude Code Statusline Health Check"
        echo "===================================="
        echo ""
        echo "Status: $status"
        echo "Version: ${STATUSLINE_VERSION:-unknown}"
        echo ""
        echo "Dependencies:"
        [[ -n "$bash_version" && "${BASH_VERSINFO[0]}" -ge 4 ]] && echo "  ✓ bash $bash_version" || echo "  ✗ bash ${bash_version:-unknown} (requires 4.0+)"
        [[ -n "$jq_version" ]] && echo "  ✓ jq $jq_version" || echo "  ✗ jq not found"
        [[ -n "$curl_version" ]] && echo "  ✓ curl $curl_version" || echo "  ✗ curl not found"
        [[ -n "$git_version" ]] && echo "  ✓ git $git_version" || echo "  ⚠ git not found (optional)"
        echo ""
        echo "Optional:"
        if [[ "$ccusage_status" != "not installed" ]]; then
            echo "  ✓ ccusage: $ccusage_status"
        else
            echo "  ⚠ ccusage: not installed (cost tracking disabled)"
        fi
        echo ""
        echo "Modules: $modules_loaded loaded, $modules_failed failed"
        echo "Config: $config_status"
        echo "Cache: $cache_status"

        if [[ ${#issues[@]} -gt 0 ]]; then
            echo ""
            echo "Issues:"
            for issue in "${issues[@]}"; do
                echo "  • $issue"
            done
        fi
    fi

    return $exit_code
}

# Show performance metrics for monitoring and analytics
show_metrics() {
    local format="${1:-json}"
    local timestamp
    timestamp=$(date +%s)

    # Module stats
    local modules_loaded=${#STATUSLINE_MODULES_LOADED[@]}
    local modules_failed=${#STATUSLINE_MODULES_FAILED[@]}

    # Cache stats
    local cache_hits=0
    local cache_misses=0
    local cache_hit_rate="0.00"
    local cache_size_bytes=0
    local cache_file_count=0

    if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
        # Aggregate cache stats from tracking arrays
        if declare -p CACHE_STATS_HITS &>/dev/null 2>&1; then
            for key in "${!CACHE_STATS_HITS[@]}"; do
                cache_hits=$((cache_hits + ${CACHE_STATS_HITS[$key]:-0}))
            done
        fi
        if declare -p CACHE_STATS_MISSES &>/dev/null 2>&1; then
            for key in "${!CACHE_STATS_MISSES[@]}"; do
                cache_misses=$((cache_misses + ${CACHE_STATS_MISSES[$key]:-0}))
            done
        fi
        local total=$((cache_hits + cache_misses))
        if [[ $total -gt 0 ]]; then
            cache_hit_rate=$(awk "BEGIN {printf \"%.2f\", ($cache_hits / $total) * 100}")
        fi

        # Get cache directory stats
        local cache_dir="${CLAUDE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-statusline}"
        if [[ -d "$cache_dir" ]]; then
            cache_file_count=$(find "$cache_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
            # Use du -sk for cross-platform compatibility, convert to bytes
            local size_kb
            size_kb=$(du -sk "$cache_dir" 2>/dev/null | cut -f1 || echo "0")
            cache_size_bytes=$((size_kb * 1024))
        fi
    fi

    # Component stats
    local components_enabled=0
    local components_total=0
    if [[ "${STATUSLINE_COMPONENTS_LOADED:-}" == "true" ]]; then
        if declare -p STATUSLINE_COMPONENT_REGISTRY &>/dev/null 2>&1; then
            components_total=${#STATUSLINE_COMPONENT_REGISTRY[@]}
        fi
        if declare -p COMPONENT_ENABLED &>/dev/null 2>&1; then
            for comp in "${!COMPONENT_ENABLED[@]}"; do
                [[ "${COMPONENT_ENABLED[$comp]}" == "true" ]] && components_enabled=$((components_enabled + 1))
            done
        fi
    fi

    # Output based on format
    case "$format" in
        json)
            cat <<EOF
{
  "timestamp": $timestamp,
  "version": "$STATUSLINE_VERSION",
  "modules": {
    "loaded": $modules_loaded,
    "failed": $modules_failed
  },
  "cache": {
    "hits": $cache_hits,
    "misses": $cache_misses,
    "hit_rate_percent": $cache_hit_rate,
    "file_count": $cache_file_count,
    "size_bytes": $cache_size_bytes
  },
  "components": {
    "enabled": $components_enabled,
    "total": $components_total
  }
}
EOF
            ;;
        prometheus|prom)
            cat <<EOF
# HELP statusline_info Statusline version info
# TYPE statusline_info gauge
statusline_info{version="$STATUSLINE_VERSION"} 1

# HELP statusline_modules_loaded Number of successfully loaded modules
# TYPE statusline_modules_loaded gauge
statusline_modules_loaded $modules_loaded

# HELP statusline_modules_failed Number of failed modules
# TYPE statusline_modules_failed gauge
statusline_modules_failed $modules_failed

# HELP statusline_cache_hits_total Total cache hits
# TYPE statusline_cache_hits_total counter
statusline_cache_hits_total $cache_hits

# HELP statusline_cache_misses_total Total cache misses
# TYPE statusline_cache_misses_total counter
statusline_cache_misses_total $cache_misses

# HELP statusline_cache_hit_rate Cache hit rate percentage
# TYPE statusline_cache_hit_rate gauge
statusline_cache_hit_rate $cache_hit_rate

# HELP statusline_cache_size_bytes Cache directory size in bytes
# TYPE statusline_cache_size_bytes gauge
statusline_cache_size_bytes $cache_size_bytes

# HELP statusline_cache_file_count Number of cache files
# TYPE statusline_cache_file_count gauge
statusline_cache_file_count $cache_file_count

# HELP statusline_components_enabled Number of enabled components
# TYPE statusline_components_enabled gauge
statusline_components_enabled $components_enabled

# HELP statusline_components_total Total number of components
# TYPE statusline_components_total gauge
statusline_components_total $components_total
EOF
            ;;
        *)
            echo "Unknown format: $format" >&2
            echo "Supported formats: json, prometheus" >&2
            return 1
            ;;
    esac

    return 0
}

# ============================================================================
# SOURCE GUARD - Allow tests to source the script for function access
# ============================================================================
# When sourced (not executed directly), return after loading modules/functions
# This enables testing individual functions without triggering stdin reads
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    debug_log "Script sourced - returning after module initialization" "INFO"
    return 0 2>/dev/null || true
fi

# Parse command-line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
    "--help"|"-h")
        show_usage
        exit 0
        ;;
    "--version"|"-v")
        echo "Claude Code Statusline v$STATUSLINE_VERSION"
        echo "Architecture: $STATUSLINE_ARCHITECTURE_VERSION (modular refactor)"
        echo "Compatible with original v$STATUSLINE_COMPATIBILITY_VERSION"
        echo "Modules loaded: ${#STATUSLINE_MODULES_LOADED[@]}"
        echo "Current theme: $(get_current_theme)"
        exit 0
        ;;
    "--test-display")
        echo "Testing display formatting..."
        test_display_formatting
        exit 0
        ;;
    "--modules")
        echo "Loaded modules:"
        for module in "${STATUSLINE_MODULES_LOADED[@]}"; do
            echo "  ✓ $module"
        done
        if [[ ${#STATUSLINE_MODULES_FAILED[@]} -gt 0 ]]; then
            echo "Failed modules:"
            for module in "${STATUSLINE_MODULES_FAILED[@]}"; do
                echo "  ✗ $module"
            done
        fi
        exit 0
        ;;
    "--health")
        show_health_status
        exit $?
        ;;
    "--health=json"|"--health-json")
        show_health_status "json"
        exit $?
        ;;
    "--metrics")
        show_metrics
        exit $?
        ;;
    "--metrics=json")
        show_metrics "json"
        exit $?
        ;;
    "--metrics=prometheus"|"--metrics=prom")
        show_metrics "prometheus"
        exit $?
        ;;
    "--list-themes")
        echo "Available themes:"
        for theme in $(get_available_themes); do
            if [[ "$theme" == "$(get_current_theme)" ]]; then
                echo "  ✓ $theme (current)"
            else
                echo "    $theme"
            fi
        done
        exit 0
        ;;
    "--preview-theme")
        if [[ -z "${2:-}" ]]; then
            echo "Error: --preview-theme requires a theme name" >&2
            echo "Usage: statusline.sh --preview-theme <theme>" >&2
            echo "Available themes: $(get_available_themes)" >&2
            exit 1
        fi
        if ! is_valid_theme "$2"; then
            echo "Error: Unknown theme '$2'" >&2
            echo "Available themes: $(get_available_themes)" >&2
            exit 1
        fi
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║              THEME PREVIEW: $2"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        preview_theme_colors "$2"
        echo ""
        echo "To use this theme permanently:"
        echo "  ENV_CONFIG_THEME=$2 ./statusline.sh"
        echo "  Or set in Config.toml: theme.name = \"$2\""
        exit 0
        ;;
    --preview-theme=*)
        theme_name="${1#--preview-theme=}"
        if [[ -z "$theme_name" ]]; then
            echo "Error: --preview-theme requires a theme name" >&2
            exit 1
        fi
        if ! is_valid_theme "$theme_name"; then
            echo "Error: Unknown theme '$theme_name'" >&2
            echo "Available themes: $(get_available_themes)" >&2
            exit 1
        fi
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║              THEME PREVIEW: $theme_name"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        preview_theme_colors "$theme_name"
        echo ""
        echo "To use this theme permanently:"
        echo "  ENV_CONFIG_THEME=$theme_name ./statusline.sh"
        echo "  Or set in Config.toml: theme.name = \"$theme_name\""
        exit 0
        ;;
    *)
        echo "Unknown option: $1" >&2
        echo "Use --help for usage information" >&2
        exit 1
        ;;
    esac
fi

# ============================================================================
# MAIN STATUSLINE GENERATION
# ============================================================================

# Skip main execution when sourced for testing
if [[ "${STATUSLINE_TESTING:-}" == "true" ]]; then
    debug_log "Test mode enabled - skipping main execution" "INFO"
    return 0 2>/dev/null || exit 0
fi

debug_log "Starting statusline generation..." "INFO"
start_timer "statusline_generation"

# Read input from Claude Code
# Performance optimization: 64 individual jq calls replaced with 1 optimized operation
input=$(cat)

# ============================================================================
# STORE RAW JSON INPUT GLOBALLY (Issue #99)
# ============================================================================
# Export the full JSON input for component access to native Anthropic data.
# This enables components to extract native fields like:
# - cost.total_cost_usd (native session cost)
# - cost.total_lines_added/removed (code productivity)
# - current_usage.cache_read_input_tokens (cache efficiency)
# - session_id, transcript_path (session info)
# See: https://github.com/rz1989s/claude-code-statusline/issues/99
export STATUSLINE_INPUT_JSON="$input"

current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')

# Validate input
if [[ -z "$current_dir" || "$current_dir" == "null" ]]; then
    handle_error "Invalid input: missing workspace.current_dir" 1 "main"
    exit 1
fi

if [[ -z "$model_name" || "$model_name" == "null" ]]; then
    handle_warning "Invalid input: missing model.display_name, using default" "main"
    model_name="Claude"
fi

# Capture the actual current working directory BEFORE any changes
actual_current_dir=$(pwd)

# Navigate to the target directory
cd "$current_dir" 2>/dev/null || {
    handle_warning "Failed to navigate to $current_dir, using current directory" "main"
    current_dir="$actual_current_dir"
}

# ============================================================================
# COMPONENT-BASED DATA COLLECTION AND DISPLAY
# ============================================================================

debug_log "Starting component-based statusline generation..." "INFO"
start_timer "statusline_generation"

# Check if we should use modular display system
if is_module_loaded "components" && is_module_loaded "display"; then
    debug_log "Using component-based system" "INFO"
    
    # Collect data for all components
    collect_all_component_data
    
    # Build and output modular statusline
    if ! build_statusline; then
        handle_error "Failed to build statusline (using component-based system)" 1 "main"
        exit 1
    fi
else
    debug_log "Components module not available, falling back to legacy system" "WARN"
    
    # Legacy data collection
    debug_log "Collecting legacy statusline data..." "INFO"
    start_timer "data_collection"

    # Format directory path
    dir_display=$(format_directory_path "$current_dir")

    # Get git information (if git module loaded)
    branch=""
    git_status="not_git"
    commits_count="0"
    submodule_display="${CONFIG_SUBMODULE_LABEL}${CONFIG_NO_SUBMODULES}"

    if is_module_loaded "git" && is_git_repository; then
        branch=$(get_git_branch)
        git_status=$(get_git_status)
        commits_count=$(get_commits_today)
        submodule_display=$(get_submodule_status)
        debug_log "Git data: branch=$branch, status=$git_status, commits=$commits_count" "INFO"
    fi

    # Get Claude version (with intelligent caching)
    claude_version="$CONFIG_UNKNOWN_VERSION"
    if command_exists claude; then
        # Use universal caching system (15-minute cache - detect updates quickly)
        if [[ "${STATUSLINE_CACHE_LOADED:-}" == "true" ]]; then
            claude_raw=$(execute_cached_command "external_claude_version" "$CACHE_DURATION_CLAUDE_VERSION" "validate_command_output" "false" "false" claude --version)
            if [[ -n "$claude_raw" ]]; then
                # Extract version number from output
                claude_version=$(echo "$claude_raw" | head -1 | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
                [[ -z "$claude_version" ]] && claude_version="$CONFIG_UNKNOWN_VERSION"
            fi
        else
            # Fallback to direct execution
            if claude_version_raw=$(claude --version 2>/dev/null | head -1); then
                claude_version=$(echo "$claude_version_raw" | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
            else
                claude_version="$CONFIG_UNKNOWN_VERSION"
            fi
        fi
    fi

    # Get MCP server information (if MCP module loaded)
    mcp_status="0/0"
    mcp_servers="$CONFIG_MCP_NONE_MESSAGE"

    if is_module_loaded "mcp" && is_claude_cli_available; then
        mcp_status=$(get_mcp_status)
        mcp_servers=$(get_all_mcp_servers)
        debug_log "MCP data: status=$mcp_status, servers=$mcp_servers" "INFO"
    fi

    # Get cost tracking information (if cost module loaded)
    session_cost="-.--"
    month_cost="-.--"
    week_cost="-.--"
    today_cost="-.--"
    block_info="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"
    reset_info="$CONFIG_NO_ACTIVE_BLOCK_MESSAGE"

    if is_module_loaded "cost" && is_ccusage_available; then
        usage_info=$(get_claude_usage_info)
        
        # Parse usage info (format: session:month:week:today:block:reset)
        session_cost="${usage_info%%:*}"
        usage_info="${usage_info#*:}"
        month_cost="${usage_info%%:*}"
        usage_info="${usage_info#*:}"
        week_cost="${usage_info%%:*}"
        usage_info="${usage_info#*:}"
        today_cost="${usage_info%%:*}"
        usage_info="${usage_info#*:}"
        block_info="${usage_info%%:*}"
        usage_info="${usage_info#*:}"
        reset_info="${usage_info%%:*}"
        
        debug_log "Cost data: session=$session_cost, month=$month_cost, week=$week_cost, today=$today_cost" "INFO"
    fi

    collection_time=$(end_timer "data_collection")
    debug_log "Data collection completed in ${collection_time}s" "INFO"
    
    # Legacy display output
    if is_module_loaded "display"; then
        line1=$(build_line1 "" "$dir_display" "$branch" "$git_status" "$commits_count" "$claude_version" "$submodule_display")
        line2=$(build_line2 "$model_name" "$session_cost" "$month_cost" "$week_cost" "$today_cost" "$block_info")  
        line3=$(build_line3 "$mcp_status" "$mcp_servers")
        line4=$(build_line4 "$reset_info")
        line5=$(build_line5_prayer "true")
        
        # Output the statusline
        echo "$line1"
        echo "$line2"
        echo "$line3"
        [[ -n "$line4" ]] && echo "$line4"
        [[ -n "$line5" ]] && echo "$line5"
    else
        # Fallback: basic output without formatting (should not happen)
        echo "ERROR: Display module not loaded - cannot generate statusline" >&2
        exit 1
    fi
fi

generation_time=$(end_timer "statusline_generation")
debug_log "Statusline generation completed in ${generation_time}s" "INFO"

# ============================================================================
# CLEANUP AND EXIT
# ============================================================================

# Cleanup (handled by core module signal handlers)
debug_log "Statusline generation successful - exiting" "INFO"
exit 0