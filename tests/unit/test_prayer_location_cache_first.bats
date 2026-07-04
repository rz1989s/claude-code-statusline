#!/usr/bin/env bats

# ============================================================================
# Test Suite: Prayer Location — Cache-First Ordering & Lazy Init (Issue #416)
# ============================================================================
#
# Regression coverage for two defects reported in #416:
#   (a) The location cache was only consulted AFTER a network round-trip, so a
#       fresh cache did not prevent an IP-geolocation call on every render.
#       These tests assert the cache is consulted BEFORE the network in every
#       network-dependent mode (local_gps, auto, ip_based).
#   (b) The prayer module eagerly initialized (and triggered detection) at
#       source time, before Config.toml was loaded — firing even when the
#       feature was disabled. This test asserts the module no longer
#       auto-initializes on source.
#
# These tests deliberately mock via bash-function overrides (not the PATH-based
# create_mock_command helper) so they are independent of the mock_bin harness
# and run identically in-session and in CI. Real `jq` reads the cache file.
# ============================================================================

load '../helpers/test_helpers'

setup() {
    export STATUSLINE_DEBUG_MODE="false"
    export STATUSLINE_TESTING="true"
    export STATUSLINE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    mkdir -p "$STATUSLINE_CACHE_DIR"

    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../.."

    # Load modules in dependency order (mirrors test_prayer_auto_location.bats)
    source "$PROJECT_ROOT/lib/core.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/security.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/cache.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/config.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/prayer.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/prayer/core.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/prayer/location.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/prayer/timezone_methods.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/prayer/calculation.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/lib/prayer/display.sh" 2>/dev/null || true
}

teardown() {
    rm -rf "$STATUSLINE_CACHE_DIR" 2>/dev/null
}

# A cache entry in the on-disk format written by cache_location_data(): the
# normalized shape produced by get_ip_location (latitude/longitude/countryCode).
_write_fresh_cache() {
    local lat="$1" lng="$2" cc="$3" tz="$4"
    printf '{"country":"Test","countryCode":"%s","city":"Test","latitude":%s,"longitude":%s,"timezone":"%s","timestamp":%s,"source":"test"}\n' \
        "$cc" "$lat" "$lng" "$tz" "$(date +%s)" > "$STATUSLINE_CACHE_DIR/location_auto_detect.cache"
}

# Overrides shared by the cache-first tests: local GPS unavailable, the network
# is "up" but any call to it trips a marker so the test can prove it was avoided.
_stub_gps_and_network() {
    NET_MARKER="$STATUSLINE_CACHE_DIR/network_was_called"
    rm -f "$NET_MARKER"
    get_local_system_coordinates() { return 1; }
    check_internet_connection() { return 0; }
    # Sentinel coordinates distinct from any cached value — if the network path
    # runs, the asserted output changes and the marker file appears.
    get_ip_location() {
        touch "$NET_MARKER"
        echo '{"country":"Net","countryCode":"NN","city":"Net","latitude":11.111,"longitude":22.222,"timezone":"UTC","timestamp":0,"source":"net"}'
        return 0
    }
}

# ============================================================================
# (a) CACHE-FIRST — network is skipped when a fresh cache exists
# ============================================================================

@test "cache-first: local_gps returns fresh cache without hitting the network" {
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    _stub_gps_and_network
    _write_fresh_cache "3.1390" "101.6869" "MY" "Asia/Kuala_Lumpur"

    run get_location_coordinates
    assert_success
    assert_output "3.1390,101.6869"          # from cache, not the 11.111 sentinel
    [[ ! -f "$NET_MARKER" ]]                  # network must NOT have been called
}

@test "cache-first: auto mode returns fresh cache without hitting the network" {
    CONFIG_PRAYER_LOCATION_MODE="auto"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    _stub_gps_and_network
    _write_fresh_cache "41.0082" "28.9784" "TR" "Europe/Istanbul"

    run get_location_coordinates
    assert_success
    assert_output "41.0082,28.9784"
    [[ ! -f "$NET_MARKER" ]]
}

@test "cache-first: ip_based returns fresh cache without hitting the network" {
    CONFIG_PRAYER_LOCATION_MODE="ip_based"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    _stub_gps_and_network
    _write_fresh_cache "-6.2088" "106.8456" "ID" "Asia/Jakarta"

    run get_location_coordinates
    assert_success
    assert_output "-6.2088,106.8456"
    [[ ! -f "$NET_MARKER" ]]
}

# ============================================================================
# (a) FRESHNESS RESPECTED — a stale cache still falls through to the network
# ============================================================================

@test "cache-first: stale cache is bypassed and the network is used" {
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    _stub_gps_and_network
    _write_fresh_cache "3.1390" "101.6869" "MY" "Asia/Kuala_Lumpur"
    # Age the cache well past the 30-minute TTL so it must be ignored.
    touch -t 202001010000 "$STATUSLINE_CACHE_DIR/location_auto_detect.cache"

    run get_location_coordinates
    assert_success
    assert_output "11.111,22.222"            # network sentinel, not the stale cache
    [[ -f "$NET_MARKER" ]]                    # network WAS called
}

# ============================================================================
# (b) LAZY INIT — module does not eagerly initialize (and detect) on source
# ============================================================================

@test "lazy-init: sourcing prayer.sh does not auto-run initialize_prayer_system" {
    # Detect eager init via a side-effect that survives prayer.sh redefining its
    # own functions: the real initializer sources prayer/core.sh, which exports
    # STATUSLINE_PRAYER_CORE_LOADED=true. If the module is lazy, prayer/core.sh
    # is never sourced at load time and the variable stays unset.
    #
    # The include guards (STATUSLINE_PRAYER_LOADED / _CORE_LOADED) are cleared so
    # the module body actually runs, and curl/ping are stubbed to fail so the
    # (pristine) eager path takes the offline branch — no real network in tests.
    run bash -c '
        unset STATUSLINE_TESTING STATUSLINE_PRAYER_LOADED STATUSLINE_PRAYER_CORE_LOADED
        BIN="'"$BATS_TEST_TMPDIR"'/nonet_bin"
        mkdir -p "$BIN"
        printf "#!/bin/sh\nexit 1\n" > "$BIN/curl"
        cp "$BIN/curl" "$BIN/ping"
        chmod +x "$BIN/curl" "$BIN/ping"
        export PATH="$BIN:$PATH"
        debug_log() { :; }
        source "'"$PROJECT_ROOT"'/lib/prayer.sh" 2>/dev/null || true
        [[ "${STATUSLINE_PRAYER_CORE_LOADED:-}" == "true" ]] && echo "EAGER_INIT" || echo "NO_EAGER_INIT"
    '
    assert_success
    assert_output --partial "NO_EAGER_INIT"
}
