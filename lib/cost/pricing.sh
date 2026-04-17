#!/bin/bash

# ============================================================================
# Claude Code Statusline - Model Pricing
# ============================================================================
#
# Single source of truth for Claude model pricing.
# Prices are per million tokens, 5-column format:
#   "input output cache_write_5m cache_write_1h cache_read"
#
# UPDATE HERE ONLY when Anthropic changes rates.
# Official pricing: https://platform.claude.com/docs/en/about-claude/pricing
#
# Cache pricing multipliers (per official docs):
#   - cache_write_5m: 1.25x input price (5-minute TTL)
#   - cache_write_1h: 2.00x input price (1-hour TTL)
#   - cache_read:     0.10x input price
#
# Not modeled (invisible in JSONL or not yet applicable):
#   - Fast mode: 6x premium on Opus 4.6 (research preview)
#   - Data residency: 1.1x multiplier on Opus 4.6+ US-only inference
#   - Batch API: 0.5x discount (CC sessions aren't batch)
#
# IMPORTANT: bash 3.x compatible (macOS default) - no associative arrays
#
# Dependencies: None (loaded by cost modules)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_PRICING_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_PRICING_LOADED=true

# Get pricing for a specific model (bash 3.x compatible)
# Usage: pricing=$(get_model_pricing "claude-opus-4-6-20250415")
# Returns: "input output cache_write_5m cache_write_1h cache_read"
#
# Matches both dated IDs (`claude-opus-4-6-20250415`) and bare IDs
# (`claude-opus-4-6`) emitted by some API paths.
get_model_pricing() {
    local model="${1:-default}"

    case "$model" in
        # ---------------------------------------------------------------
        # Opus 4.7 / 4.6 / 4.5 — $5 / $25 (same rates)
        # ---------------------------------------------------------------
        claude-opus-4-7|claude-opus-4-7-*|claude-opus-4-6|claude-opus-4-6-*|claude-opus-4-5|claude-opus-4-5-*)
            echo "5.00 25.00 6.25 10.00 0.50"
            ;;

        # ---------------------------------------------------------------
        # Opus 4.1 / 4 / 3 — $15 / $75
        # ---------------------------------------------------------------
        claude-opus-4-1|claude-opus-4-1-*|claude-opus-4|claude-opus-4-*|claude-3-opus|claude-3-opus-*)
            echo "15.00 75.00 18.75 30.00 1.50"
            ;;

        # ---------------------------------------------------------------
        # Sonnet 4.6 / 4.5 / 4 / 3.7 — $3 / $15
        # ---------------------------------------------------------------
        claude-sonnet-4-6|claude-sonnet-4-6-*|claude-sonnet-4-5|claude-sonnet-4-5-*|claude-sonnet-4|claude-sonnet-4-*|claude-3-7-sonnet|claude-3-7-sonnet-*|claude-sonnet-3-7|claude-sonnet-3-7-*)
            echo "3.00 15.00 3.75 6.00 0.30"
            ;;

        # ---------------------------------------------------------------
        # Haiku 4.5 — $1 / $5
        # ---------------------------------------------------------------
        claude-haiku-4-5|claude-haiku-4-5-*)
            echo "1.00 5.00 1.25 2.00 0.10"
            ;;

        # ---------------------------------------------------------------
        # Haiku 3.5 — $0.80 / $4
        # ---------------------------------------------------------------
        claude-haiku-3-5|claude-haiku-3-5-*|claude-3-5-haiku|claude-3-5-haiku-*)
            echo "0.80 4.00 1.00 1.60 0.08"
            ;;

        # ---------------------------------------------------------------
        # Haiku 3 (deprecated) — $0.25 / $1.25
        # ---------------------------------------------------------------
        claude-3-haiku|claude-3-haiku-*|claude-haiku-3|claude-haiku-3-*)
            echo "0.25 1.25 0.30 0.50 0.03"
            ;;

        # ---------------------------------------------------------------
        # Default fallback — Sonnet rates (safer middle ground)
        # Applies to unknown Claude IDs and non-Claude models (gemma, glm, etc.)
        # ---------------------------------------------------------------
        *)
            echo "3.00 15.00 3.75 6.00 0.30"
            ;;
    esac
}

# Generate awk pricing block for embedding in awk scripts
# Usage: awk_pricing=$(get_awk_pricing_block)
# Outputs all p["model"] = "..." lines for awk BEGIN blocks.
# Values are 5 space-separated columns matching get_model_pricing.
get_awk_pricing_block() {
    cat <<'EOF'
        # Opus 4.7 / 4.6 / 4.5 - $5/$25
        p["claude-opus-4-7"]               = "5.00 25.00 6.25 10.00 0.50"
        p["claude-opus-4-6"]               = "5.00 25.00 6.25 10.00 0.50"
        p["claude-opus-4-6-20250415"]      = "5.00 25.00 6.25 10.00 0.50"
        p["claude-opus-4-5"]               = "5.00 25.00 6.25 10.00 0.50"
        p["claude-opus-4-5-20251101"]      = "5.00 25.00 6.25 10.00 0.50"
        # Opus 4.1 / 4 / 3 - $15/$75
        p["claude-opus-4-1"]               = "15.00 75.00 18.75 30.00 1.50"
        p["claude-opus-4-1-20250805"]      = "15.00 75.00 18.75 30.00 1.50"
        p["claude-opus-4"]                 = "15.00 75.00 18.75 30.00 1.50"
        p["claude-opus-4-20250514"]        = "15.00 75.00 18.75 30.00 1.50"
        p["claude-3-opus-20240229"]        = "15.00 75.00 18.75 30.00 1.50"
        # Sonnet 4.6 / 4.5 / 4 / 3.7 - $3/$15
        p["claude-sonnet-4-6"]             = "3.00 15.00 3.75 6.00 0.30"
        p["claude-sonnet-4-6-20250929"]    = "3.00 15.00 3.75 6.00 0.30"
        p["claude-sonnet-4-5"]             = "3.00 15.00 3.75 6.00 0.30"
        p["claude-sonnet-4-5-20251101"]    = "3.00 15.00 3.75 6.00 0.30"
        p["claude-sonnet-4-5-20250929"]    = "3.00 15.00 3.75 6.00 0.30"
        p["claude-sonnet-4"]               = "3.00 15.00 3.75 6.00 0.30"
        p["claude-sonnet-4-20250514"]      = "3.00 15.00 3.75 6.00 0.30"
        p["claude-3-7-sonnet-20250219"]    = "3.00 15.00 3.75 6.00 0.30"
        # Haiku 4.5 - $1/$5
        p["claude-haiku-4-5"]              = "1.00 5.00 1.25 2.00 0.10"
        p["claude-haiku-4-5-20251001"]     = "1.00 5.00 1.25 2.00 0.10"
        p["claude-haiku-4-5-20251101"]     = "1.00 5.00 1.25 2.00 0.10"
        # Haiku 3.5 - $0.80/$4
        p["claude-3-5-haiku-20241022"]     = "0.80 4.00 1.00 1.60 0.08"
        p["claude-haiku-3-5-20241022"]     = "0.80 4.00 1.00 1.60 0.08"
        # Haiku 3 (deprecated) - $0.25/$1.25
        p["claude-3-haiku-20240307"]       = "0.25 1.25 0.30 0.50 0.03"
        # Default fallback (Sonnet pricing)
        p["default"]                       = "3.00 15.00 3.75 6.00 0.30"
EOF
}

# Get individual price component
# Usage: input_price=$(get_model_price "claude-opus-4-6-20250415" "input")
# Components: input, output, cache_write_5m, cache_write_1h, cache_read
# Backward-compat aliases: cache_write → cache_write_5m
get_model_price() {
    local model="${1:-default}"
    local component="${2:-input}"
    local pricing
    pricing=$(get_model_pricing "$model")

    case "$component" in
        input)          echo "$pricing" | awk '{print $1}' ;;
        output)         echo "$pricing" | awk '{print $2}' ;;
        cache_write_5m) echo "$pricing" | awk '{print $3}' ;;
        cache_write_1h) echo "$pricing" | awk '{print $4}' ;;
        cache_read)     echo "$pricing" | awk '{print $5}' ;;
        cache_write)    echo "$pricing" | awk '{print $3}' ;;  # alias for cache_write_5m
        *)              echo "$pricing" | awk '{print $1}' ;;
    esac
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f get_model_pricing get_awk_pricing_block get_model_price

debug_log "Pricing module loaded" "INFO" 2>/dev/null || true
