#!/bin/bash

# ============================================================================
# Claude Code Statusline - Display/Formatting Module
# ============================================================================
# 
# This module handles all display formatting, output generation, and
# visual presentation of the statusline information.
#
# Dependencies: core.sh, config.sh, themes.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_DISPLAY_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_DISPLAY_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# DISPLAY CONSTANTS
# ============================================================================

# Display symbols
export DISPLAY_SEPARATOR="│"
export DISPLAY_SPACE=" "
export DISPLAY_NEWLINE=$'\n'

# ============================================================================
# PATH FORMATTING
# ============================================================================

# Format directory path for display (convert full path to use ~ notation)
format_directory_path() {
    local current_dir="$1"
    local home_dir="${2:-$HOME}"
    
    if [[ "$current_dir" == "$home_dir"/* ]]; then
        echo "~${current_dir#$home_dir}"
    else
        echo "$current_dir"
    fi
}

# ============================================================================
# MODEL FORMATTING
# ============================================================================

# Get emoji for Claude model based on model name
get_model_emoji() {
    local model_name="$1"
    
    case "$model_name" in
        *"Opus"*|*"opus"*)
            echo "$CONFIG_OPUS_EMOJI"
            ;;
        *"Haiku"*|*"haiku"*)
            echo "$CONFIG_HAIKU_EMOJI"
            ;;
        *"Sonnet"*|*"sonnet"*)
            echo "$CONFIG_SONNET_EMOJI"
            ;;
        *)
            echo "$CONFIG_DEFAULT_MODEL_EMOJI"
            ;;
    esac
}

# Format model name for display
format_model_name() {
    local model_name="$1"
    local emoji
    emoji=$(get_model_emoji "$model_name")
    
    echo "${emoji} ${CONFIG_CYAN}${model_name}${CONFIG_RESET}"
}

# ============================================================================
# GIT FORMATTING
# ============================================================================

# Format git branch with color based on status
format_git_branch() {
    local branch="$1"
    local git_status="$2"
    
    case "$git_status" in
        "clean")
            echo "${CONFIG_GREEN}(${branch})${CONFIG_RESET}"
            ;;
        "dirty")
            echo "${CONFIG_YELLOW}(${branch})${CONFIG_RESET}"
            ;;
        *)
            echo "${CONFIG_MAGENTA}(${branch})${CONFIG_RESET}"
            ;;
    esac
}

# Format git status emoji
format_git_status_emoji() {
    local git_status="$1"
    
    case "$git_status" in
        "clean")
            echo "$CONFIG_CLEAN_STATUS_EMOJI"
            ;;
        "dirty")
            echo "$CONFIG_DIRTY_STATUS_EMOJI"
            ;;
        *)
            echo "$CONFIG_DIRTY_STATUS_EMOJI"
            ;;
    esac
}

# Format complete git information
format_git_info() {
    local branch="$1"
    local git_status="$2"
    
    if [[ -z "$branch" ]]; then
        echo ""
        return 0
    fi
    
    local formatted_branch formatted_emoji
    formatted_branch=$(format_git_branch "$branch" "$git_status")
    formatted_emoji=$(format_git_status_emoji "$git_status")
    
    echo "$formatted_branch $formatted_emoji "
}

# ============================================================================
# COST FORMATTING
# ============================================================================

# Format individual cost value
format_cost_value() {
    local cost="$1"
    local label="$2"
    local color="${3:-$CONFIG_GREEN}"
    
    if [[ "$cost" == "-.--" ]] || [[ -z "$cost" ]]; then
        echo "${color}${label} \$-.--${CONFIG_RESET}"
    else
        printf "${color}%s \$%.2f${CONFIG_RESET}\n" "$label" "$cost"
    fi
}

# Format session cost
format_session_cost() {
    local cost="$1"
    format_cost_value "$cost" "$CONFIG_REPO_LABEL" "$CONFIG_GREEN"
}

# Format monthly cost
format_monthly_cost() {
    local cost="$1"
    format_cost_value "$cost" "$CONFIG_MONTHLY_LABEL" "$CONFIG_PINK_BRIGHT"
}

# Format weekly cost
format_weekly_cost() {
    local cost="$1"
    format_cost_value "$cost" "$CONFIG_WEEKLY_LABEL" "$CONFIG_INDIGO"
}

# Format daily cost
format_daily_cost() {
    local cost="$1"
    format_cost_value "$cost" "$CONFIG_DAILY_LABEL" "$CONFIG_TEAL"
}

# Format live block cost
format_live_block_cost() {
    local block_info="$1"
    
    if [[ "$block_info" == "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE" ]]; then
        echo "${CONFIG_DIM}${block_info}${CONFIG_RESET}"
    else
        echo "${CONFIG_BRIGHT_GREEN}${block_info}${CONFIG_RESET}"
    fi
}

# ============================================================================
# MCP FORMATTING
# ============================================================================

# Get MCP status color and format
get_mcp_status_format() {
    local mcp_status="$1"
    
    if [[ "$mcp_status" == "?/?" ]]; then
        echo "${CONFIG_RED}MCP:?/?${CONFIG_RESET}"
    elif [[ "$mcp_status" =~ ^([0-9]+)/([0-9]+)$ ]]; then
        local connected="${BASH_REMATCH[1]}"
        local total="${BASH_REMATCH[2]}"

        if [[ "$total" == "0" ]]; then
            # No MCP servers configured
            echo "${CONFIG_DIM}---${CONFIG_RESET}"
        elif [[ "$connected" == "$total" ]]; then
            echo "${CONFIG_BRIGHT_GREEN}MCP:${mcp_status}${CONFIG_RESET}"
        else
            echo "${CONFIG_YELLOW}MCP:${mcp_status}${CONFIG_RESET}"
        fi
    else
        echo "${CONFIG_RED}MCP:?/?${CONFIG_RESET}"
    fi
}

# Format MCP server list with colors
format_mcp_server_list() {
    local servers_data="$1"
    local formatted=""

    if [[ "$servers_data" == "$CONFIG_MCP_UNKNOWN_MESSAGE" ]] || [[ "$servers_data" == "$CONFIG_MCP_NONE_MESSAGE" ]]; then
        echo "$servers_data"
        return
    fi

    # Split servers by comma and process each one
    local temp_servers="${servers_data},"
    while [[ "$temp_servers" == *","* ]]; do
        local server_entry="${temp_servers%%,*}"
        temp_servers="${temp_servers#*,}"
        
        # Extract server name and status
        local server_name="${server_entry%:*}"
        local server_status="${server_entry#*:}"

        local formatted_server
        case "$server_status" in
            "connected")
                formatted_server="${CONFIG_BRIGHT_GREEN}${server_name}${CONFIG_RESET}"
                ;;
            *)
                formatted_server="${CONFIG_RED}${CONFIG_STRIKETHROUGH}${server_name}${CONFIG_RESET}"
                ;;
        esac

        if [[ -z "$formatted" ]]; then
            formatted="$formatted_server"
        else
            formatted="$formatted, $formatted_server"
        fi
    done

    echo "$formatted"
}

# ============================================================================
# VERSION FORMATTING
# ============================================================================

# Format Claude version
format_claude_version() {
    local version="$1"
    echo "${CONFIG_PURPLE}${CONFIG_VERSION_PREFIX}${version}${CONFIG_RESET}"
}

# ============================================================================
# SUBMODULE FORMATTING
# ============================================================================

# Format submodule display with appropriate color
format_submodule_display() {
    local submodule_display="$1"
    
    if [[ "$submodule_display" == "${CONFIG_SUBMODULE_LABEL}${CONFIG_NO_SUBMODULES}" ]]; then
        echo "${CONFIG_DIM}${submodule_display}${CONFIG_RESET}"
    else
        echo "${CONFIG_BRIGHT_GREEN}${submodule_display}${CONFIG_RESET}"
    fi
}

# ============================================================================
# TIME FORMATTING
# ============================================================================

# Format current time display
format_current_time() {
    local time_format="${1:-$CONFIG_TIME_FORMAT}"
    local current_time
    current_time=$(date "+$time_format")
    echo "${CONFIG_LIGHT_ORANGE}${CONFIG_CLOCK_EMOJI} ${current_time}${CONFIG_RESET}"
}

# ============================================================================
# SEPARATOR FORMATTING
# ============================================================================

# Format separator with dim color
format_separator() {
    echo "${CONFIG_DIM}${DISPLAY_SEPARATOR}${CONFIG_RESET}"
}

# ============================================================================
# LINE BUILDERS
# ============================================================================

# Build Line 1: Basic Repository Info
# Format: [mode] ~/path (branch) status │ Commits:X │ verX.X.X │ SUB:X │ 🕐 HH:MM
build_line1() {
    local mode_info="$1"
    local dir_display="$2"
    local branch="$3"
    local git_status="$4"
    local commits_count="$5"
    local claude_version="$6"
    local submodule_display="$7"
    
    local line1=""
    
    # Add mode info if present
    if [[ -n "$mode_info" ]]; then
        line1="${CONFIG_RED}${mode_info}${CONFIG_RESET} "
    fi
    
    # Add directory
    line1="${line1}${CONFIG_BLUE}${dir_display}${CONFIG_RESET} "
    
    # Add git info if available
    if [[ -n "$branch" ]]; then
        local git_info
        git_info=$(format_git_info "$branch" "$git_status")
        line1="${line1}${git_info}"
    fi
    
    # Add separator
    line1="${line1}$(format_separator) "
    
    # Add commits
    line1="${line1}${CONFIG_TEAL}${CONFIG_COMMITS_LABEL}${commits_count}${CONFIG_RESET} "
    
    # Add separator
    line1="${line1}$(format_separator) "
    
    # Add Claude version
    local formatted_version
    formatted_version=$(format_claude_version "$claude_version")
    line1="${line1}${formatted_version} "
    
    # Add separator
    line1="${line1}$(format_separator) "
    
    # Add submodule info
    local formatted_submodules
    formatted_submodules=$(format_submodule_display "$submodule_display")
    line1="${line1}${formatted_submodules} "
    
    # Add separator
    line1="${line1}$(format_separator) "
    
    # Add time
    local formatted_time
    formatted_time=$(format_current_time)
    line1="${line1}${formatted_time}"
    
    echo "$line1"
}

# Build Line 2: Claude Usage & Cost Tracking
# Format: 🎵 Model │ REPO $X.XX │ 30DAY $X.XX │ 7DAY $X.XX │ DAY $X.XX │ 🔥 LIVE $X.XX
build_line2() {
    local model_name="$1"
    local session_cost="$2"
    local month_cost="$3"
    local week_cost="$4"
    local today_cost="$5"
    local block_info="$6"
    
    local line2=""
    
    # Add model with emoji
    local formatted_model
    formatted_model=$(format_model_name "$model_name")
    line2="${formatted_model} "
    
    # Add separator
    line2="${line2}$(format_separator) "
    
    # Add session cost
    local formatted_session
    formatted_session=$(format_session_cost "$session_cost")
    line2="${line2}${formatted_session} "
    
    # Add separator
    line2="${line2}$(format_separator) "
    
    # Add monthly cost
    local formatted_monthly
    formatted_monthly=$(format_monthly_cost "$month_cost")
    line2="${line2}${formatted_monthly} "
    
    # Add separator
    line2="${line2}$(format_separator) "
    
    # Add weekly cost
    local formatted_weekly
    formatted_weekly=$(format_weekly_cost "$week_cost")
    line2="${line2}${formatted_weekly} "
    
    # Add separator
    line2="${line2}$(format_separator) "
    
    # Add daily cost
    local formatted_daily
    formatted_daily=$(format_daily_cost "$today_cost")
    line2="${line2}${formatted_daily} "
    
    # Add separator
    line2="${line2}$(format_separator) "
    
    # Add live block info
    local formatted_block
    formatted_block=$(format_live_block_cost "$block_info")
    line2="${line2}${formatted_block}"
    
    echo "$line2"
}

# Build Line 3: MCP Server Status
# Format: MCP (X/Y): server1, server2, server3
build_line3() {
    local mcp_status="$1"
    local mcp_servers="$2"
    
    local line3=""
    
    # Add MCP status
    local formatted_mcp_status
    formatted_mcp_status=$(get_mcp_status_format "$mcp_status")
    
    # Add server list
    local formatted_servers
    formatted_servers=$(format_mcp_server_list "$mcp_servers")
    
    line3="${formatted_mcp_status}: ${formatted_servers}"
    
    echo "$line3"
}

# Build Line 4: RESET Info (conditional)
# Format: RESET at HH.MM (Xh Ym left) - only shown when active block exists
build_line4() {
    local reset_info="$1"
    
    if [[ -n "$reset_info" && "$reset_info" != "$CONFIG_NO_ACTIVE_BLOCK_MESSAGE" ]]; then
        echo "${CONFIG_LIGHT_GRAY}${CONFIG_ITALIC}${reset_info}${CONFIG_RESET}"
    fi
}

# ============================================================================
# COMPLETE STATUSLINE BUILDER
# ============================================================================

# Build complete 4-line statusline output
build_complete_statusline() {
    local statusline_data="$1"
    
    # Parse statusline data (this would be a structured format)
    # For now, we'll expect the data to be passed as separate arguments
    local mode_info="$2"
    local dir_display="$3"
    local branch="$4"
    local git_status="$5"
    local commits_count="$6"
    local claude_version="$7"
    local submodule_display="$8"
    local model_name="$9"
    local session_cost="${10}"
    local month_cost="${11}"
    local week_cost="${12}"
    local today_cost="${13}"
    local block_info="${14}"
    local mcp_status="${15}"
    local mcp_servers="${16}"
    local reset_info="${17}"
    
    # Build each line
    local line1 line2 line3 line4
    
    line1=$(build_line1 "$mode_info" "$dir_display" "$branch" "$git_status" "$commits_count" "$claude_version" "$submodule_display")
    line2=$(build_line2 "$model_name" "$session_cost" "$month_cost" "$week_cost" "$today_cost" "$block_info")
    line3=$(build_line3 "$mcp_status" "$mcp_servers")
    line4=$(build_line4 "$reset_info")
    
    # Output lines
    echo "$line1"
    echo "$line2"
    echo "$line3"
    [[ -n "$line4" ]] && echo "$line4"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Test display with sample data
test_display_formatting() {
    echo "Testing display formatting..."
    echo "============================="
    echo ""
    
    # Test each formatting function
    echo "Directory: $(format_directory_path "/Users/test/projects/my-app")"
    echo "Model: $(format_model_name "Claude 3.5 Sonnet")"
    echo "Git: $(format_git_info "main" "clean")"
    echo "Version: $(format_claude_version "$STATUSLINE_VERSION")"
    echo "Session Cost: $(format_session_cost "2.50")"
    echo "Time: $(format_current_time)"
    echo ""
    
    # Test complete statusline
    echo "Complete statusline test:"
    echo "========================"
    build_complete_statusline "" "" "~/projects/test" "main" "clean" "5" "$STATUSLINE_VERSION" "SUB:2" "Claude 3.5 Sonnet" "2.50" "45.30" "12.75" "3.20" "🔥 LIVE \$1.25" "2/3" "server1:connected,server2:disconnected,server3:connected" "RESET at 14.30 (2h 15m left)"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the display module
init_display_module() {
    debug_log "Display/formatting module initialized" "INFO"
    
    # Validate that theme colors are available
    if [[ -z "$CONFIG_RESET" ]]; then
        handle_warning "Theme colors not loaded - display may be incorrect" "init_display_module"
        return 1
    fi
    
    debug_log "Display formatting ready with theme: $(get_current_theme)" "INFO"
    return 0
}

# Initialize the module
init_display_module

# Export display functions
export -f format_directory_path get_model_emoji format_model_name
export -f format_git_branch format_git_status_emoji format_git_info
export -f format_cost_value format_session_cost format_monthly_cost format_weekly_cost
export -f format_daily_cost format_live_block_cost get_mcp_status_format format_mcp_server_list
export -f format_claude_version format_submodule_display format_current_time format_separator
export -f build_line1 build_line2 build_line3 build_line4 build_complete_statusline
export -f test_display_formatting