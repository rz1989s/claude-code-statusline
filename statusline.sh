#!/bin/bash

# ============================================================================
# Claude Code Enhanced Statusline - Main Orchestrator (v2.0.0-refactored)
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

# ============================================================================
# MODULE LOADING SEQUENCE
# ============================================================================

# Load modules in dependency order
debug_log "Starting module loading sequence..." "INFO"
start_timer "module_loading"

# Load security module (required by most other modules)
load_module "security" || {
    handle_error "Failed to load security module - statusline disabled. Check lib/security.sh exists and is readable." 1 "main"
    exit 1
}

# Load configuration module
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
Claude Code Statusline (Refactored v2.0.0)
==========================================

USAGE:
    statusline.sh [options]                 - Run statusline (default)
    statusline.sh --help                    - Show this help message
    statusline.sh --version                 - Show version information
    statusline.sh --test-display            - Test display formatting
    statusline.sh --modules                 - Show loaded modules

THEMES:
    ENV_CONFIG_THEME=classic ./statusline.sh    - Use classic theme
    ENV_CONFIG_THEME=garden ./statusline.sh     - Use garden theme  
    ENV_CONFIG_THEME=catppuccin ./statusline.sh  - Use catppuccin theme

DEBUGGING:
    STATUSLINE_DEBUG_MODE=true ./statusline.sh   - Enable debug logging

FEATURES:
    - 4-line statusline with git status, MCP monitoring, and cost tracking
    - TOML configuration support (Config.toml)  
    - 3 built-in themes + custom theme support
    - Intelligent caching for performance
    - Modular architecture for maintainability

For detailed configuration, see: https://github.com/rz1989s/claude-code-statusline
EOF
}

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

debug_log "Starting statusline generation..." "INFO"
start_timer "statusline_generation"

# Read input from Claude Code
input=$(cat)
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
# DATA COLLECTION PHASE
# ============================================================================

debug_log "Collecting statusline data..." "INFO"
start_timer "data_collection"

# 1. Format directory path
dir_display=$(format_directory_path "$current_dir")

# 2. Get git information (if git module loaded)
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

# 3. Get Claude version (with caching)
claude_version="$CONFIG_UNKNOWN_VERSION"
if command_exists claude; then
    # Simple version check with caching logic (simplified from original)
    cache_file="${CONFIG_VERSION_CACHE_FILE:-/tmp/.claude_version_cache}"
    if [[ -f "$cache_file" ]] && is_cache_fresh "$cache_file" "${CONFIG_VERSION_CACHE_DURATION:-3600}"; then
        claude_version=$(cat "$cache_file" 2>/dev/null || echo "$CONFIG_UNKNOWN_VERSION")
    else
        if claude_version_raw=$(claude --version 2>/dev/null | head -1); then
            claude_version=$(echo "$claude_version_raw" | sed 's/ *(Claude Code).*$//' | sed 's/^[^0-9]*//')
            [[ -n "$claude_version" ]] && echo "$claude_version" > "$cache_file" 2>/dev/null
        else
            claude_version="$CONFIG_UNKNOWN_VERSION"
        fi
    fi
fi

# 4. Get MCP server information (if MCP module loaded)
mcp_status="0/0"
mcp_servers="$CONFIG_MCP_NONE_MESSAGE"

if is_module_loaded "mcp" && is_claude_cli_available; then
    mcp_status=$(get_mcp_status)
    mcp_servers=$(get_all_mcp_servers)
    debug_log "MCP data: status=$mcp_status, servers=$mcp_servers" "INFO"
fi

# 5. Get cost tracking information (if cost module loaded)
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

# ============================================================================
# STATUSLINE GENERATION AND OUTPUT
# ============================================================================

debug_log "Generating statusline output..." "INFO"

# Build and output statusline using display module
if is_module_loaded "display"; then
    # Use modular display functions
    
    line1=$(build_line1 "" "$dir_display" "$branch" "$git_status" "$commits_count" "$claude_version" "$submodule_display")
    line2=$(build_line2 "$model_name" "$session_cost" "$month_cost" "$week_cost" "$today_cost" "$block_info")  
    line3=$(build_line3 "$mcp_status" "$mcp_servers")
    line4=$(build_line4 "$reset_info")
    
    # Output the statusline
    echo "$line1"
    echo "$line2"
    echo "$line3"
    [[ -n "$line4" ]] && echo "$line4"
else
    # Fallback: basic output without formatting (should not happen)
    echo "ERROR: Display module not loaded - cannot generate statusline" >&2
    exit 1
fi

generation_time=$(end_timer "statusline_generation")
debug_log "Statusline generation completed in ${generation_time}s" "INFO"

# ============================================================================
# CLEANUP AND EXIT
# ============================================================================

# Cleanup (handled by core module signal handlers)
debug_log "Statusline generation successful - exiting" "INFO"
exit 0