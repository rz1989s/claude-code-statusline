#!/bin/bash

# ============================================================================
# Claude Code Statusline - Model Pricing
# ============================================================================
#
# Single source of truth for Claude model pricing.
# Prices are per million tokens: input output cache_write cache_read
#
# UPDATE HERE ONLY when Anthropic changes rates.
# Official pricing: https://claude.com/pricing
#
# IMPORTANT: bash 3.x compatible (macOS default) - no associative arrays
#
# Dependencies: None (loaded by cost modules)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COST_PRICING_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COST_PRICING_LOADED=true

# ============================================================================
# PRICING DATA
# ============================================================================
# Format: "input output cache_write cache_read" (per million tokens)
#
# Cache pricing multipliers:
#   - cache_write: 1.25x input price
#   - cache_read:  0.10x input price

# Get pricing for a specific model (bash 3.x compatible)
# Usage: pricing=$(get_model_pricing "claude-opus-4-5-20251101")
# Returns: "input output cache_write cache_read"
get_model_pricing() {
    local model="${1:-default}"

    # Official Anthropic pricing from https://claude.com/pricing
    case "$model" in
        # Opus 4.5: $5/$25 input/output
        claude-opus-4-5-20251101)
            echo "5.00 25.00 6.25 0.50"
            ;;
        # Sonnet 4.5: $3/$15 input/output
        claude-sonnet-4-5-20251101|claude-sonnet-4-5-20250929)
            echo "3.00 15.00 3.75 0.30"
            ;;
        # Sonnet 4: $3/$15 input/output
        claude-sonnet-4-20250514)
            echo "3.00 15.00 3.75 0.30"
            ;;
        # Haiku 4.5: $1/$5 input/output
        claude-haiku-4-5-20251101|claude-haiku-4-5-20251001)
            echo "1.00 5.00 1.25 0.10"
            ;;
        # Default fallback (Sonnet pricing - safer middle ground)
        *)
            echo "3.00 15.00 3.75 0.30"
            ;;
    esac
}

# Generate awk pricing block for embedding in awk scripts
# Usage: awk_pricing=$(get_awk_pricing_block)
# This outputs all p["model"] = "..." lines for awk BEGIN blocks
get_awk_pricing_block() {
    cat <<'EOF'
        p["claude-opus-4-5-20251101"] = "5.00 25.00 6.25 0.50"
        p["claude-sonnet-4-5-20251101"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-5-20250929"] = "3.00 15.00 3.75 0.30"
        p["claude-sonnet-4-20250514"] = "3.00 15.00 3.75 0.30"
        p["claude-haiku-4-5-20251101"] = "1.00 5.00 1.25 0.10"
        p["claude-haiku-4-5-20251001"] = "1.00 5.00 1.25 0.10"
        p["default"] = "3.00 15.00 3.75 0.30"
EOF
}

# Get individual price component
# Usage: input_price=$(get_model_price "claude-opus-4-5-20251101" "input")
# Components: input, output, cache_write, cache_read
get_model_price() {
    local model="${1:-default}"
    local component="${2:-input}"
    local pricing
    pricing=$(get_model_pricing "$model")

    case "$component" in
        input)       echo "$pricing" | awk '{print $1}' ;;
        output)      echo "$pricing" | awk '{print $2}' ;;
        cache_write) echo "$pricing" | awk '{print $3}' ;;
        cache_read)  echo "$pricing" | awk '{print $4}' ;;
        *)           echo "$pricing" | awk '{print $1}' ;;
    esac
}

# ============================================================================
# EXPORTS
# ============================================================================

export -f get_model_pricing get_awk_pricing_block get_model_price

debug_log "Pricing module loaded" "INFO" 2>/dev/null || true
