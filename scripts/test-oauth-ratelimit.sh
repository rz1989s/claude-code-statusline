#!/usr/bin/env bash
# ============================================================================
# OAuth Usage API Rate Limit Discovery Script
# ============================================================================
# Empirically determines the rate limit for /api/oauth/usage endpoint.
# Sends controlled bursts and detects where 429 kicks in.
#
# Usage: ./scripts/test-oauth-ratelimit.sh
# ============================================================================

set -euo pipefail

TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)

if [[ -z "$TOKEN" ]]; then
    echo "ERROR: No OAuth token found in keychain"
    exit 1
fi

API_URL="https://api.anthropic.com/api/oauth/usage"
TOTAL_429=0
TOTAL_200=0

call_api() {
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/json" \
        "$API_URL" 2>/dev/null)
    echo "$code"
}

# Pre-flight: check if we're still blocked
echo "=== OAuth Usage API Rate Limit Discovery ==="
echo ""
echo "Pre-flight check..."
PRE=$(call_api)
if [[ "$PRE" == "429" ]]; then
    echo "BLOCKED: Still getting 429. IP-level block hasn't cleared yet."
    echo "Try again later."
    exit 1
fi
echo "Pre-flight OK (HTTP $PRE). Starting tests..."
echo ""

# ============================================================================
# Test 1: Sustained rate — 1 request per interval
# ============================================================================
run_sustained_test() {
    local interval="$1"
    local count="$2"
    local label="$3"
    local success=0
    local fail=0

    echo -n "  $label: "

    for ((i = 1; i <= count; i++)); do
        local code
        code=$(call_api)
        if [[ "$code" == "200" ]]; then
            ((success++))
            ((TOTAL_200++))
            echo -n "."
        elif [[ "$code" == "429" ]]; then
            ((fail++))
            ((TOTAL_429++))
            echo -n "X"
        else
            echo -n "?($code)"
        fi
        if [[ "$i" -lt "$count" ]]; then
            sleep "$interval"
        fi
    done

    echo " → ${success}/${count} OK (${fail} rejected)"

    # Cool down after each test
    sleep 5
}

# ============================================================================
# Test 2: Burst — rapid requests with no delay
# ============================================================================
run_burst_test() {
    local count="$1"
    local label="$2"
    local success=0
    local fail=0
    local first_fail=0

    echo -n "  $label: "

    for ((i = 1; i <= count; i++)); do
        local code
        code=$(call_api)
        if [[ "$code" == "200" ]]; then
            ((success++))
            ((TOTAL_200++))
            echo -n "."
        elif [[ "$code" == "429" ]]; then
            ((fail++))
            ((TOTAL_429++))
            [[ "$first_fail" -eq 0 ]] && first_fail=$i
            echo -n "X"
        else
            echo -n "?($code)"
        fi
    done

    echo " → ${success}/${count} OK (first 429 at request #${first_fail:-none})"

    # Longer cool down after burst
    sleep 10
}

echo "--- Phase 1: Sustained rate tests (safe → aggressive) ---"
echo ""
run_sustained_test 10 6  "1 req/10s (6 RPM)"
run_sustained_test 5  6  "1 req/5s  (12 RPM)"
run_sustained_test 3  6  "1 req/3s  (20 RPM)"
run_sustained_test 2  6  "1 req/2s  (30 RPM)"
run_sustained_test 1  10 "1 req/1s  (60 RPM)"

echo ""
echo "--- Phase 2: Burst tests (find the wall) ---"
echo ""
run_burst_test 5   "5 rapid requests"
run_burst_test 10  "10 rapid requests"
run_burst_test 20  "20 rapid requests"

echo ""
echo "=== Results ==="
echo "Total successful: $TOTAL_200"
echo "Total rejected:   $TOTAL_429"
echo ""
echo "If all sustained tests passed but bursts failed at N,"
echo "the limit is approximately N requests per short window."
echo ""
echo "Recommended polling interval: at least 60s (conservative)"
echo "Current statusline default: 300s (5 min) — should be safe."
