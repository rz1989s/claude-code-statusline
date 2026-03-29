#!/bin/bash

# ============================================================================
# Claude Code Statusline - Responsive Module
# ============================================================================
#
# Width-aware component filtering. Detects terminal width, drops lower-priority
# components per line until the line fits, and applies ANSI-safe truncation
# as a safety net.
#
# Dependencies: core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_RESPONSIVE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_RESPONSIVE_LOADED=true

# ============================================================================
# WIDTH DETECTION
# ============================================================================

# Detect terminal width with caching.
# Priority: ENV_CONFIG_TERMINAL_WIDTH > $COLUMNS > tput cols > fallback 120
detect_terminal_width() {
    if [[ -n "${STATUSLINE_TERMINAL_WIDTH:-}" ]]; then
        echo "$STATUSLINE_TERMINAL_WIDTH"
        return 0
    fi

    local width=""
    local source="fallback"

    # 1. User override (highest priority)
    if [[ -n "${ENV_CONFIG_TERMINAL_WIDTH:-}" ]]; then
        width="$ENV_CONFIG_TERMINAL_WIDTH"
        source="ENV_CONFIG_TERMINAL_WIDTH"
    fi

    # 2. $COLUMNS (works when user exports it in shell profile)
    if [[ -z "$width" && -n "${COLUMNS:-}" ]]; then
        width="$COLUMNS"
        source="COLUMNS"
    fi

    # 3. tput cols — only trust when stdout is a real terminal.
    #    In CC's piped context (echo JSON | bash statusline.sh), stdout is a pipe
    #    and tput returns 80 (POSIX default), not the actual terminal width.
    if [[ -z "$width" ]] && [ -t 1 ]; then
        width=$(tput cols 2>/dev/null) || width=""
        [[ -n "$width" ]] && source="tput"
    fi

    # 4. Fallback: 120 (generous — don't penalize wide-terminal majority)
    if [[ -z "$width" ]] || ! [[ "$width" =~ ^[0-9]+$ ]] || [[ "$width" -lt 1 ]]; then
        width=120
        source="fallback"
    fi

    export STATUSLINE_TERMINAL_WIDTH="$width"
    debug_log "[responsive] terminal width: $width (source: $source)" "INFO"

    echo "$width"
    return 0
}

# ============================================================================
# WIDTH MEASUREMENT
# ============================================================================

# Measure the visible width of a string (strips ANSI, accounts for emoji).
# Returns the number of terminal columns the string occupies.
measure_visible_width() {
    local text="$1"

    if [[ -z "$text" ]]; then
        echo "0"
        return 0
    fi

    # 1. Strip ANSI escape sequences (colors, bold, dim, reset)
    local stripped
    stripped=$(printf '%s' "$text" | sed $'s/\x1b\[[0-9;]*m//g')

    # 2. Count characters (not bytes — handles Unicode correctly)
    local char_count
    char_count=$(printf '%s' "$stripped" | wc -m | tr -d ' ')

    # 3. Emoji correction: common double-width emoji add 1 extra column each
    #    Ranges: Emoticons (U+1F600-1F64F), Symbols (U+1F300-1F5FF),
    #    Transport (U+1F680-1F6FF), Misc (U+1F900-1F9FF), Dingbats (U+2600-27BF)
    #    Counts matches directly (not via wc -m) to avoid whole-line print bug.
    local emoji_count=0
    if command -v perl &>/dev/null; then
        local raw_count
        raw_count=$(printf '%s' "$stripped" | perl -CS -ne '$c++ while /[\x{1F300}-\x{1F9FF}\x{2600}-\x{27BF}]/g; END { print $c+0, "\n" }')
        emoji_count="${raw_count:-0}"
    fi

    echo $(( char_count + emoji_count ))
    return 0
}

# ============================================================================
# COMPONENT PRIORITY
# ============================================================================

# Priority levels:
#   1 = Essential (never dropped, only truncated as last resort)
#   2 = Important (dropped under moderate pressure)
#   3 = Nice-to-have (dropped early) — also the default for unregistered components
#   4 = First to go (sacrificed first when space is tight)

declare -gA RESPONSIVE_COMPONENT_PRIORITY=(
    # Line 1: Repository identity
    [repo_info]=1

    # Line 2: Model & git metrics
    [model_info]=1
    [bedrock_model]=2
    [commits]=2
    [submodules]=3
    [version_info]=3
    [time_display]=4

    # Line 3: Cost analytics
    [cost_repo]=1
    [cost_monthly]=2
    [cost_live]=2
    [cost_weekly]=3
    [cost_daily]=4

    # Line 4: Block metrics
    [context_window]=1
    [burn_rate]=2
    [cache_efficiency]=3
    [block_projection]=3
    [code_productivity]=4

    # Line 5: Usage limits
    [usage_limits]=1
    [usage_reset]=2

    # Line 6: Calendar & wellness
    [hijri_calendar]=2
    [wellness]=3

    # Line 7: Prayer
    [prayer_times]=1
    [prayer_times_only]=1
    [prayer_icon]=2

    # Line 8: MCP
    [mcp_status]=1
    [mcp_native]=2
    [mcp_servers]=2
    [mcp_plugins]=3

    # Other components (alternate configurations)
    [context_alert]=1
    [vim_mode]=2
    [agent_display]=2
    [session_info]=2
    [session_mode]=3
    [total_tokens]=3
    [token_usage]=3
    [github]=3
    [location_display]=3
    [version_display]=3
)

# Get the priority for a component. Returns 3 (nice-to-have) for unknown components.
get_component_priority() {
    local component_name="$1"
    echo "${RESPONSIVE_COMPONENT_PRIORITY[$component_name]:-3}"
    return 0
}

# ============================================================================
# COMPONENT FILTERING
# ============================================================================

# Filter components for a line to fit within width budget.
# Drops lowest-priority components (rightmost on tie) until the line fits.
# Never drops the last component — truncation handles overflow.
#
# Args:
#   $1 - width_budget (integer)
#   $2 - separator string (e.g., " │ ")
#   $3 - nameref to array of component names
#   $4 - nameref to array of rendered outputs (parallel to names)
#
# Output: comma-separated surviving component names
filter_line_components() {
    local width_budget="$1"
    local separator="$2"
    local -n _names="$3"
    local -n _outputs="$4"

    local sep_width
    sep_width=$(measure_visible_width "$separator")

    # Build parallel arrays of active components (skip empty outputs)
    local active_names=()
    local active_widths=()
    local i
    for i in "${!_names[@]}"; do
        local w
        w=$(measure_visible_width "${_outputs[$i]}")
        if [[ "$w" -gt 0 ]]; then
            active_names+=("${_names[$i]}")
            active_widths+=("$w")
        fi
    done

    if [[ ${#active_names[@]} -eq 0 ]]; then
        echo ""
        return 0
    fi

    # Calculate total visible width: sum(widths) + (N-1) * sep_width
    local total=0
    for w in "${active_widths[@]}"; do total=$((total + w)); done
    [[ ${#active_widths[@]} -gt 1 ]] && total=$((total + (${#active_widths[@]} - 1) * sep_width))

    # Drop loop: remove lowest-priority (rightmost on tie) until fits
    while [[ "$total" -gt "$width_budget" ]] && [[ ${#active_names[@]} -gt 1 ]]; do
        # Find index of lowest-priority component (highest number, rightmost on tie)
        local drop_idx=0
        local drop_pri
        drop_pri=$(get_component_priority "${active_names[0]}")

        for i in "${!active_names[@]}"; do
            local pri
            pri=$(get_component_priority "${active_names[$i]}")
            # Higher number = lower priority. On tie (>=), prefer rightmost (later index)
            if [[ "$pri" -ge "$drop_pri" ]]; then
                drop_idx="$i"
                drop_pri="$pri"
            fi
        done

        debug_log "[responsive] dropped ${active_names[$drop_idx]} (pri:$drop_pri)" "INFO"

        # Remove the component at drop_idx
        unset 'active_names[drop_idx]'
        unset 'active_widths[drop_idx]'
        # Re-index arrays (bash arrays get sparse after unset)
        active_names=("${active_names[@]}")
        active_widths=("${active_widths[@]}")

        total=0
        for w in "${active_widths[@]}"; do total=$((total + w)); done
        [[ ${#active_widths[@]} -gt 1 ]] && total=$((total + (${#active_widths[@]} - 1) * sep_width))
    done

    # Return surviving names as comma-separated string
    local result=""
    for name in "${active_names[@]}"; do
        if [[ -n "$result" ]]; then
            result="${result},${name}"
        else
            result="$name"
        fi
    done

    echo "$result"
    return 0
}

# ============================================================================
# ANSI-SAFE TRUNCATION (Safety Net)
# ============================================================================

# Truncate a line to max_width visible columns, preserving ANSI sequences.
# Appends "…" and closes any open ANSI sequences with reset.
# Only fires when a single component exceeds terminal width (rare edge case).
truncate_line_ansi_safe() {
    local line="$1"
    local max_width="$2"

    if [[ -z "$line" ]] || [[ "$max_width" -lt 1 ]]; then
        echo ""
        return 0
    fi

    # Fast path: if visible width fits, return as-is
    local visible_width
    visible_width=$(measure_visible_width "$line")
    if [[ "$visible_width" -le "$max_width" ]]; then
        echo "$line"
        return 0
    fi

    debug_log "[responsive] truncating line at col $max_width (safety net)" "INFO"

    # Character-by-character walk: track visible column, preserve ANSI sequences
    local result=""
    local col=0
    local in_escape=false
    local has_ansi=false
    local target=$((max_width - 1))  # Reserve 1 column for "…"
    local i char

    for (( i=0; i<${#line}; i++ )); do
        char="${line:$i:1}"

        if [[ "$in_escape" == true ]]; then
            result+="$char"
            # End of ANSI sequence: letter terminates it
            if [[ "$char" =~ [a-zA-Z] ]]; then
                in_escape=false
            fi
            continue
        fi

        # Start of ANSI escape sequence
        if [[ "$char" == $'\e' ]] && [[ "${line:$((i+1)):1}" == "[" ]]; then
            in_escape=true
            has_ansi=true
            result+="$char"
            continue
        fi

        # Visible character — check if we've hit the budget
        if [[ "$col" -ge "$target" ]]; then
            break
        fi

        result+="$char"
        # Detect double-width characters (emoji ranges)
        local codepoint
        codepoint=$(printf '%d' "'$char" 2>/dev/null) || codepoint=0
        if [[ $codepoint -ge 127744 ]]; then  # U+1F300 = 127744 decimal
            col=$((col + 2))
        else
            col=$((col + 1))
        fi
    done

    # Close any open ANSI sequences (only if input contained ANSI) and append ellipsis
    if [[ "$has_ansi" == true ]]; then
        printf '%s\e[0m…' "$result"
    else
        printf '%s…' "$result"
    fi
    return 0
}
