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

    # 3. tput cols (mirrors $COLUMNS when set, else returns 80 default)
    if [[ -z "$width" ]]; then
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
