#!/bin/bash

# ============================================================================
# Claude Code Statusline - Session Info Module
# ============================================================================
#
# Extract session ID, project name, and context window from Anthropic's
# native JSON input and transcript files.
#
# Split from cost.sh as part of Issue #132.
# Implements Issues #101, #102, #105
#
# Dependencies: core.sh, cost/core.sh, cost/blocks.sh (for format_tokens_compact)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_SESSION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_SESSION_LOADED=true

# ============================================================================
# CONTEXT WINDOW VIA TRANSCRIPT PARSING (Issue #101)
# ============================================================================
# Parse transcript JSONL file to get accurate context window percentage.
# This avoids the bug in native context_window JSON (cumulative vs current).
# Reference: https://codelynx.dev/posts/calculate-claude-code-context

# Context window constants
export CONTEXT_WINDOW_SIZE=200000  # Claude's context window size

# Get transcript path from Anthropic JSON input or auto-discover
get_transcript_path() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        debug_log "No JSON input for transcript path" "INFO"
        echo ""
        return 1
    fi

    # Method 1: Try native transcript_path from JSON
    local transcript_path
    transcript_path=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.transcript_path // empty' 2>/dev/null)

    if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
        debug_log "Found transcript via native JSON path: $transcript_path" "INFO"
        echo "$transcript_path"
        return 0
    fi

    # Method 2: Auto-discover using FULL session_id (not short version)
    local session_id
    session_id=$(get_native_session_id)  # Returns full UUID like "75cdeac6-6f3d-4936-8cbe-29f56a3af952"

    if [[ -n "$session_id" ]]; then
        # Search in Claude projects directory for this session's transcript
        local claude_projects_dir="$HOME/.claude/projects"

        if [[ -d "$claude_projects_dir" ]]; then
            # Find transcript file matching session_id (with .jsonl extension)
            local found_path
            found_path=$(find "$claude_projects_dir" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)

            if [[ -n "$found_path" && -f "$found_path" ]]; then
                debug_log "Auto-discovered transcript: $found_path" "INFO"
                echo "$found_path"
                return 0
            fi
        fi
    fi

    debug_log "Could not find transcript path" "INFO"
    echo ""
    return 1
}

# Parse the last usage entry from transcript JSONL file
# Returns: JSON object with usage data or empty
parse_transcript_last_usage() {
    local transcript_path="$1"

    if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
        echo ""
        return 1
    fi

    # Use tac (reverse cat) to efficiently find last usage entry
    # Look for entries with "usage" field, excluding sidechains
    local last_usage

    # Performance optimization: use tac and grep -m1 for large files
    # Note: usage is at .message.usage in transcript entries
    if command_exists tac; then
        last_usage=$(tac "$transcript_path" 2>/dev/null | \
            grep -m1 '"usage"' 2>/dev/null | \
            jq -r '.message.usage // .usage // empty' 2>/dev/null)
    else
        # Fallback for systems without tac (macOS uses tail -r)
        if command_exists tail; then
            # Try tail -r (BSD/macOS)
            last_usage=$(tail -r "$transcript_path" 2>/dev/null | \
                grep -m1 '"usage"' 2>/dev/null | \
                jq -r '.message.usage // .usage // empty' 2>/dev/null)
        fi

        # Final fallback: use awk to get last line with usage
        if [[ -z "$last_usage" ]]; then
            last_usage=$(awk '/"usage"/' "$transcript_path" 2>/dev/null | \
                tail -1 | \
                jq -r '.message.usage // .usage // empty' 2>/dev/null)
        fi
    fi

    if [[ -n "$last_usage" && "$last_usage" != "null" ]]; then
        echo "$last_usage"
        return 0
    else
        debug_log "No usage data found in transcript" "INFO"
        echo ""
        return 1
    fi
}

# Get context window token count from transcript
# Returns: total tokens (input + cache_read + cache_creation)
get_context_tokens_from_transcript() {
    local transcript_path
    transcript_path=$(get_transcript_path)

    if [[ -z "$transcript_path" ]]; then
        echo "0"
        return 1
    fi

    local usage_data
    usage_data=$(parse_transcript_last_usage "$transcript_path")

    if [[ -z "$usage_data" ]]; then
        echo "0"
        return 1
    fi

    # Extract token counts
    local input_tokens cache_read cache_creation
    input_tokens=$(echo "$usage_data" | jq -r '.input_tokens // 0' 2>/dev/null)
    cache_read=$(echo "$usage_data" | jq -r '.cache_read_input_tokens // 0' 2>/dev/null)
    cache_creation=$(echo "$usage_data" | jq -r '.cache_creation_input_tokens // 0' 2>/dev/null)

    # Handle null/empty values
    [[ -z "$input_tokens" || "$input_tokens" == "null" ]] && input_tokens=0
    [[ -z "$cache_read" || "$cache_read" == "null" ]] && cache_read=0
    [[ -z "$cache_creation" || "$cache_creation" == "null" ]] && cache_creation=0

    # Calculate total: input_tokens + cache_read + cache_creation
    local total=$((input_tokens + cache_read + cache_creation))

    debug_log "Context tokens: input=$input_tokens, cache_read=$cache_read, cache_creation=$cache_creation, total=$total" "INFO"
    echo "$total"
}

# Get context window percentage from transcript
# Returns: percentage (0-100+)
get_context_window_percentage() {
    local total_tokens
    total_tokens=$(get_context_tokens_from_transcript)

    if [[ "$total_tokens" -eq 0 ]]; then
        echo "0"
        return 1
    fi

    # Calculate percentage
    local percentage
    percentage=$(awk "BEGIN {printf \"%.0f\", $total_tokens * 100 / $CONTEXT_WINDOW_SIZE}" 2>/dev/null)

    echo "${percentage:-0}"
}

# Get formatted context window display
# Returns: "45% (90K/200K)" or "85% ⚠️" format
get_context_window_display() {
    local warn_threshold="${CONFIG_CONTEXT_WARN_THRESHOLD:-75}"
    local critical_threshold="${CONFIG_CONTEXT_CRITICAL_THRESHOLD:-90}"

    local total_tokens percentage
    total_tokens=$(get_context_tokens_from_transcript)

    if [[ "$total_tokens" -eq 0 ]]; then
        echo "N/A"
        return 1
    fi

    percentage=$(awk "BEGIN {printf \"%.0f\", $total_tokens * 100 / $CONTEXT_WINDOW_SIZE}" 2>/dev/null)

    # Format tokens for display (K/M suffix)
    local formatted_tokens formatted_max
    formatted_tokens=$(format_tokens_compact "$total_tokens")
    formatted_max=$(format_tokens_compact "$CONTEXT_WINDOW_SIZE")

    # Add warning indicator based on threshold
    local indicator=""
    if [[ "$percentage" -ge "$critical_threshold" ]]; then
        indicator=" 🔴"
    elif [[ "$percentage" -ge "$warn_threshold" ]]; then
        indicator=" ⚠️"
    fi

    echo "${percentage}% (${formatted_tokens}/${formatted_max})${indicator}"
}

# ============================================================================
# SESSION INFO EXTRACTION (Issue #102)
# ============================================================================
# Extract session ID and project name from Anthropic's native JSON input.
# Provides session identification for multi-session awareness.

# Get full session ID from Anthropic JSON input
get_native_session_id() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    local session_id
    session_id=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.session_id // empty' 2>/dev/null)
    echo "${session_id:-}"
}

# Get short session ID (first N characters)
# Default: 8 characters for easy resume: claude -r abc12345
get_short_session_id() {
    local length="${1:-8}"
    local full_id
    full_id=$(get_native_session_id)

    if [[ -n "$full_id" ]]; then
        echo "${full_id:0:$length}"
    else
        echo ""
    fi
}

# Get project directory from workspace
get_native_project_dir() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    local project_dir
    project_dir=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.workspace.project_dir // empty' 2>/dev/null)
    echo "${project_dir:-}"
}

# Get project name (basename of project directory)
get_native_project_name() {
    local project_dir
    project_dir=$(get_native_project_dir)

    if [[ -n "$project_dir" ]]; then
        basename "$project_dir"
    else
        echo ""
    fi
}

# Get session title from first user message in transcript (Issue #105)
# Returns: First user message content (truncated to ~40 chars) or project name fallback
get_session_title() {
    local max_length="${1:-40}"

    # Try to get transcript path
    local transcript_path
    transcript_path=$(get_transcript_path)

    if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
        # Find first user message and extract content
        # Content can be string or array format: {"type":"text","text":"..."}
        local first_message
        first_message=$(grep -m1 '"type":"user"' "$transcript_path" 2>/dev/null | \
            jq -r '
                if .message.content | type == "string" then
                    .message.content
                elif .message.content | type == "array" then
                    (.message.content[] | select(.type == "text") | .text) // ""
                else
                    ""
                end
            ' 2>/dev/null | head -1)

        if [[ -n "$first_message" ]]; then
            # Strip command tags (e.g., <command-message>...</command-message>)
            first_message=$(echo "$first_message" | sed 's/<[^>]*>//g')

            # Truncate to max_length and add ellipsis if needed
            if [[ ${#first_message} -gt $max_length ]]; then
                first_message="${first_message:0:$((max_length - 3))}..."
            fi

            # Remove newlines and trim whitespace
            first_message=$(echo "$first_message" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            if [[ -n "$first_message" ]]; then
                echo "$first_message"
                return 0
            fi
        fi
    fi

    # Fallback to project name
    get_native_project_name
}

# Get current working directory from workspace
get_native_current_dir() {
    if [[ -z "${STATUSLINE_INPUT_JSON:-}" ]]; then
        echo ""
        return 1
    fi

    local current_dir
    current_dir=$(echo "$STATUSLINE_INPUT_JSON" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
    echo "${current_dir:-}"
}

# Get formatted session info display
# Format: "abc12345 • session title..."
get_session_info_display() {
    local separator="${CONFIG_SESSION_INFO_SEPARATOR:- • }"
    local id_length="${CONFIG_SESSION_INFO_ID_LENGTH:-8}"
    local title_length="${CONFIG_SESSION_INFO_TITLE_LENGTH:-40}"

    local short_id session_title
    short_id=$(get_short_session_id "$id_length")
    session_title=$(get_session_title "$title_length")

    local output=""

    if [[ -n "$short_id" ]]; then
        output="$short_id"
    fi

    if [[ -n "$session_title" ]]; then
        if [[ -n "$output" ]]; then
            output="${output}${separator}${session_title}"
        else
            output="$session_title"
        fi
    fi

    echo "$output"
}

# Export transcript parsing functions
export -f get_transcript_path parse_transcript_last_usage
export -f get_context_tokens_from_transcript get_context_window_percentage
export -f get_context_window_display

# Export session info functions
export -f get_native_session_id get_short_session_id
export -f get_native_project_dir get_native_project_name get_native_current_dir
export -f get_session_title get_session_info_display
