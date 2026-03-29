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
    # Return cached value if already detected this invocation
    if [[ -n "${STATUSLINE_TERMINAL_WIDTH:-}" ]]; then
        echo "$STATUSLINE_TERMINAL_WIDTH"
        return 0
    fi

    local width=""

    # 1. User override (highest priority)
    if [[ -n "${ENV_CONFIG_TERMINAL_WIDTH:-}" ]]; then
        width="$ENV_CONFIG_TERMINAL_WIDTH"
    fi

    # 2. $COLUMNS (works when user exports it in shell profile)
    if [[ -z "$width" && -n "${COLUMNS:-}" ]]; then
        width="$COLUMNS"
    fi

    # 3. tput cols (mirrors $COLUMNS when set, else returns 80 default)
    if [[ -z "$width" ]]; then
        width=$(tput cols 2>/dev/null) || width=""
    fi

    # 4. Fallback: 120 (generous — don't penalize wide-terminal majority)
    if [[ -z "$width" ]] || ! [[ "$width" =~ ^[0-9]+$ ]] || [[ "$width" -lt 1 ]]; then
        width=120
    fi

    # Cache for this invocation
    export STATUSLINE_TERMINAL_WIDTH="$width"
    debug_log "[responsive] terminal width: $width (source: $(
        if [[ -n "${ENV_CONFIG_TERMINAL_WIDTH:-}" ]]; then echo "ENV_CONFIG_TERMINAL_WIDTH"
        elif [[ -n "${COLUMNS:-}" ]]; then echo "COLUMNS"
        else echo "fallback"
        fi
    ))" "INFO"

    echo "$width"
    return 0
}
