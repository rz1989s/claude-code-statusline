#!/usr/bin/env bats

# ============================================================================
# Test Suite: Location Detection Fallback Resilience
# ============================================================================
#
# Covers fixes for the IP geolocation fallback chain when:
#   1. ip-api.com HTTPS returns "SSL unavailable" (free tier paywalled HTTPS)
#   2. local_gps mode falls through to Tier 3 cached location
#   3. Indonesian timezones (Asia/Makassar, Asia/Jayapura) map to their
#      correct regional coordinates instead of collapsing to Jakarta
# ============================================================================

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    if [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]]; then
        skip "Location fallback tests require full environment (skipped in CI)"
    fi

    common_setup

    # Load prayer modules in dependency order
    source "$STATUSLINE_ROOT/lib/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/security.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/cache.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/config.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/prayer/timezone_methods.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/prayer/core.sh" 2>/dev/null || true
    source "$STATUSLINE_ROOT/lib/prayer/location.sh" 2>/dev/null || true

    # Isolate cache so tests don't read user's real cache
    export STATUSLINE_CACHE_DIR="$TEST_TMP_DIR/location_cache"
    mkdir -p "$STATUSLINE_CACHE_DIR"

    # Reset prayer config so each test starts from a clean slate
    export CONFIG_PRAYER_LOCATION_MODE="local_gps"
    export CONFIG_PRAYER_LATITUDE=""
    export CONFIG_PRAYER_LONGITUDE=""
    export CONFIG_PRAYER_TIMEZONE=""
    export CONFIG_PRAYER_CALCULATION_METHOD=""
}

teardown() {
    common_teardown
}

# ============================================================================
# BUG 4: Timezone-to-coordinates mapping — Indonesian regions
# ============================================================================
#
# Asia/Makassar covers Bali, Sulawesi, Lombok, NTB, NTT (WITA, UTC+8).
# Asia/Jayapura covers Papua and Maluku (WIT, UTC+9).
# Previously all four Indonesian zones collapsed to Jakarta — wrong by
# 400-1300km even within Indonesia.

@test "Bug 4: Asia/Makassar maps to Makassar coords (not Jakarta)" {
    run get_coordinates_from_timezone "Asia/Makassar"
    assert_success
    assert_output "-5.1477,119.4327"
}

@test "Bug 4: Asia/Jayapura maps to Jayapura coords (not Jakarta)" {
    run get_coordinates_from_timezone "Asia/Jayapura"
    assert_success
    assert_output "-2.5316,140.7180"
}

@test "Bug 4: Asia/Jakarta still maps to Jakarta (regression guard)" {
    run get_coordinates_from_timezone "Asia/Jakarta"
    assert_success
    assert_output "-6.2088,106.8456"
}

@test "Bug 4: Asia/Pontianak still maps to Jakarta (same WIB zone)" {
    run get_coordinates_from_timezone "Asia/Pontianak"
    assert_success
    assert_output "-6.2088,106.8456"
}

# ============================================================================
# BUG 1: ip-api.com HTTP fallback when HTTPS returns "SSL unavailable"
# ============================================================================
#
# ip-api.com paywalled their HTTPS endpoint. Free tier only works over HTTP.
# The "SSL unavailable" response is distinguishable from a real network
# failure, so we retry once over HTTP rather than skipping to ipinfo.io
# (which has stricter rate limits).

@test "Bug 1: HTTP fallback used when ip-api.com HTTPS returns SSL unavailable" {
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
# Find the URL (last positional arg, prefixed with http/https)
url=""
for arg in "$@"; do
    case "$arg" in
        http://*|https://*) url="$arg" ;;
    esac
done

case "$url" in
    "https://1.1.1.1")
        exit 0  # connectivity check succeeds
        ;;
    "https://ip-api.com/"*)
        echo '{"status":"fail","message":"SSL unavailable for this endpoint, order a key at https://members.ip-api.com/"}'
        exit 0
        ;;
    "http://ip-api.com/"*)
        echo '{"status":"success","country":"Indonesia","countryCode":"ID","city":"Denpasar","lat":-8.65,"lon":115.2167,"timezone":"Asia/Makassar","query":"203.142.67.168"}'
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/curl"

    run get_ip_location
    assert_success
    assert_line --partial '"city": "Denpasar"'
    assert_line --partial '"latitude": -8.65'
    assert_line --partial '"longitude": 115.2167'
}

@test "Bug 1: real network failure (no SSL message) still tries ipinfo.io fallback" {
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
url=""
for arg in "$@"; do
    case "$arg" in
        http://*|https://*) url="$arg" ;;
    esac
done

case "$url" in
    "https://1.1.1.1") exit 0 ;;
    "https://ip-api.com/"*) exit 1 ;;   # network failure, not SSL
    "http://ip-api.com/"*) exit 1 ;;    # HTTP also fails
    "https://ipinfo.io/"*)
        echo '{"ip":"203.142.67.168","city":"Denpasar","country":"ID","loc":"-8.65,115.2167","timezone":"Asia/Makassar"}'
        exit 0
        ;;
    *) exit 1 ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/curl"

    run get_ip_location
    assert_success
    assert_line --partial '"city": "Denpasar"'
    assert_line --partial '"latitude": -8.65'
}

# ============================================================================
# BUG 3: local_gps mode falls through to Tier 3 cached location
# ============================================================================
#
# When GPS and IP geolocation both fail, local_gps mode previously jumped
# straight to Tier 4 timezone fallback (regional estimate) — even with a
# valid recent cache. The Tier 3 cached-location lookup is now consulted
# first, preserving last-known good coordinates.

@test "Bug 3: local_gps falls back to cached location when GPS+IP fail" {
    # GPS unavailable
    cat > "$MOCK_BIN_DIR/CoreLocationCLI" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$MOCK_BIN_DIR/CoreLocationCLI"

    # IP APIs both fail. Internet check still works.
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
url=""
for arg in "$@"; do
    case "$arg" in
        http://*|https://*) url="$arg" ;;
    esac
done
case "$url" in
    "https://1.1.1.1") exit 0 ;;
    *) exit 1 ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/curl"

    # Plant a fresh, valid Denpasar cache entry
    local cache_file="$STATUSLINE_CACHE_DIR/location_auto_detect.cache"
    cat > "$cache_file" << EOF
{"country":"Indonesia","countryCode":"ID","city":"Denpasar","latitude":-8.65,"longitude":115.2167,"timezone":"Asia/Makassar","timestamp":$(date +%s),"source":"test"}
EOF
    chmod 600 "$cache_file"

    run get_location_coordinates
    assert_success
    assert_output "-8.65,115.2167"
}

@test "Bug 3: local_gps with no cache still falls through to timezone fallback" {
    cat > "$MOCK_BIN_DIR/CoreLocationCLI" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$MOCK_BIN_DIR/CoreLocationCLI"

    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$MOCK_BIN_DIR/curl"

    cat > "$MOCK_BIN_DIR/ping" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$MOCK_BIN_DIR/ping"

    # Ensure no cache file exists
    rm -f "$STATUSLINE_CACHE_DIR/location_auto_detect.cache"

    # Mock timezone to Asia/Makassar so we exercise Bug 4's new mapping too
    cat > "$MOCK_BIN_DIR/readlink" << 'EOF'
#!/bin/bash
echo "/usr/share/zoneinfo/Asia/Makassar"
EOF
    chmod +x "$MOCK_BIN_DIR/readlink"

    run get_location_coordinates
    assert_success
    # Asia/Makassar should resolve to Makassar coords (Bug 4 fix), NOT Jakarta
    assert_output "-5.1477,119.4327"
}

# ============================================================================
# BUG 5: City detection must recognise Bali coordinates
# ============================================================================
#
# Even with the IP-geo HTTP fallback returning correct Bali coordinates,
# the city pattern table had no entry for Bali — so users in
# Denpasar/Kuta/Seminyak/Ubud rendered as "Southeast Asia" regional fallback.

@test "Bug 5: Denpasar coords map to Denpasar" {
    source "$STATUSLINE_ROOT/lib/components/location_display.sh" 2>/dev/null || true
    run get_city_from_coordinates "-8.6500" "115.2167"
    assert_success
    assert_output "Denpasar"
}

@test "Bug 5: Kuta/Legian coords map to Bali" {
    source "$STATUSLINE_ROOT/lib/components/location_display.sh" 2>/dev/null || true
    run get_city_from_coordinates "-8.7041" "115.17"
    assert_success
    assert_output "Bali"
}

@test "Bug 5: Pecatu/Uluwatu coords map to Bali" {
    source "$STATUSLINE_ROOT/lib/components/location_display.sh" 2>/dev/null || true
    run get_city_from_coordinates "-8.8029" "115.2007"
    assert_success
    assert_output "Bali"
}

@test "Bug 5: Jakarta still maps to Jakarta (regression guard)" {
    source "$STATUSLINE_ROOT/lib/components/location_display.sh" 2>/dev/null || true
    run get_city_from_coordinates "-6.2088" "106.8456"
    assert_success
    assert_output "Jakarta"
}
