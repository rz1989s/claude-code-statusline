#!/usr/bin/env bats

# ============================================================================
# Test Suite: City Coordinate Matching (numeric bounding-box lookup)
# ============================================================================
#
# Regression coverage for the reversed-glob-range bug class.
#
# get_city_from_coordinates() formerly matched each city with a string glob on
# the coordinate's decimal digits (e.g. -6.1[7-2]*,106.8[2-6]*). That approach
# silently failed in two ways:
#   1. Reversed character ranges like [7-2] match nothing in bash, so ~20
#      cities (Medan, Bangalore, Beirut, Miami, Bishkek, ...) collapsed to
#      their broad regional label ("Southeast Asia", "Middle East", ...).
#   2. A glob cannot express a box spanning a decimal boundary (e.g. Medan's
#      3.55-3.62), so even un-reversing the ranges would not have fixed them.
#
# The function now performs a single-pass numeric bounding-box lookup. These
# tests assert the previously-broken cities resolve correctly, that the clean
# cities and regional fallbacks are unchanged, and that the edge cases hold.
#
# Pure function, no network or mocks — runs in CI (unlike test_location_fallbacks).
# ============================================================================

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup

    # Stub the component's load-time dependencies so it sources standalone.
    register_component() { :; }
    debug_log() { :; }
    get_component_config() { echo "${3:-}"; }

    source "$STATUSLINE_ROOT/lib/components/location_display.sh" 2>/dev/null || true
}

teardown() {
    common_teardown
}

# ============================================================================
# Previously-broken cities (reversed-range bug) — now resolve correctly
# ============================================================================

@test "fix: Medan resolves to Medan (was 'Southeast Asia')" {
    run get_city_from_coordinates "3.5952" "98.6722"
    assert_success
    assert_output "Medan"
}

@test "fix: Johor Bahru resolves to Johor Bahru (was 'Southeast Asia')" {
    run get_city_from_coordinates "1.4927" "103.7414"
    assert_success
    assert_output "Johor Bahru"
}

@test "fix: Multan resolves to Multan (was 'South Asia')" {
    run get_city_from_coordinates "30.1575" "71.5249"
    assert_success
    assert_output "Multan"
}

@test "fix: Hyderabad (Pakistan) resolves to Hyderabad (was 'South Asia')" {
    run get_city_from_coordinates "25.3960" "68.3578"
    assert_success
    assert_output "Hyderabad"
}

@test "fix: Bangalore resolves to Bangalore (was 'South Asia')" {
    run get_city_from_coordinates "12.9716" "77.5946"
    assert_success
    assert_output "Bangalore"
}

@test "fix: Hyderabad (India) resolves to Hyderabad (was 'South Asia')" {
    run get_city_from_coordinates "17.3850" "78.4867"
    assert_success
    assert_output "Hyderabad"
}

@test "fix: Nagpur resolves to Nagpur (was 'South Asia')" {
    run get_city_from_coordinates "21.1458" "79.0882"
    assert_success
    assert_output "Nagpur"
}

@test "fix: Shiraz resolves to Shiraz (was 'Middle East')" {
    run get_city_from_coordinates "29.5918" "52.5837"
    assert_success
    assert_output "Shiraz"
}

@test "fix: Mashhad resolves to Mashhad (was 'Middle East')" {
    run get_city_from_coordinates "36.2605" "59.6168"
    assert_success
    assert_output "Mashhad"
}

@test "fix: Beirut resolves to Beirut (was 'Middle East', decimal-boundary span)" {
    run get_city_from_coordinates "33.8938" "35.5018"
    assert_success
    assert_output "Beirut"
}

@test "fix: Damascus resolves to Damascus (was 'Middle East')" {
    run get_city_from_coordinates "33.5138" "36.2765"
    assert_success
    assert_output "Damascus"
}

@test "fix: Kano resolves to Kano (was 'North Africa', decimal-boundary span)" {
    run get_city_from_coordinates "12.0022" "8.5920"
    assert_success
    assert_output "Kano"
}

@test "fix: Oran resolves to Oran (was 'North Africa')" {
    run get_city_from_coordinates "35.6971" "-0.6308"
    assert_success
    assert_output "Oran"
}

@test "fix: Marrakech resolves to Marrakech (was 'North Africa')" {
    run get_city_from_coordinates "31.6295" "-7.9811"
    assert_success
    assert_output "Marrakech"
}

@test "fix: Kazan resolves to Kazan (was 'Europe')" {
    run get_city_from_coordinates "55.7963" "49.1088"
    assert_success
    assert_output "Kazan"
}

@test "fix: Marseille resolves to Marseille (was 'Europe')" {
    run get_city_from_coordinates "43.2965" "5.3698"
    assert_success
    assert_output "Marseille"
}

@test "fix: Birmingham resolves to Birmingham (was 'Europe')" {
    run get_city_from_coordinates "52.4862" "-1.8904"
    assert_success
    assert_output "Birmingham"
}

@test "fix: Miami resolves to Miami (was 'North America')" {
    run get_city_from_coordinates "25.7617" "-80.1918"
    assert_success
    assert_output "Miami"
}

@test "fix: Bishkek resolves to Bishkek (was 'Unknown')" {
    run get_city_from_coordinates "42.8746" "74.5698"
    assert_success
    assert_output "Bishkek"
}

@test "fix: Dar es Salaam resolves to Dar es Salaam (was 'Africa')" {
    run get_city_from_coordinates "-6.7924" "39.2083"
    assert_success
    assert_output "Dar es Salaam"
}

# ============================================================================
# Reported symptom: North-Jakarta IP coordinate must resolve to a city
# ============================================================================
#
# ip-api.com geolocates the reporter's ISP egress to (-6.1474, 106.8711),
# which it labels "North Jakarta". The old Jakarta glob (-6.1[7-2]*,106.8[2-6]*)
# matched neither the reversed latitude range nor longitude 106.87, so the
# render fell through to "Southeast Asia". It must now resolve to Jakarta.

@test "symptom: North-Jakarta IP coordinate resolves to Jakarta (was 'Southeast Asia')" {
    run get_city_from_coordinates "-6.1474" "106.8711"
    assert_success
    assert_output "Jakarta"
}

# ============================================================================
# Negative-zero / equator edge (Pontianak)
# ============================================================================
#
# Pontianak sits just south of the equator. Its prefix "-0.0" exercises the
# signed-interval conversion (float -0.0 compares >= 0, which must not flip the
# box north of the equator).

@test "edge: Pontianak (just south of equator) resolves to Pontianak" {
    run get_city_from_coordinates "-0.0194" "109.3419"
    assert_success
    assert_output "Pontianak"
}

@test "edge: a point just north of the equator is not mislabelled Pontianak" {
    run get_city_from_coordinates "0.0500" "109.3400"
    assert_success
    assert_output "Southeast Asia"
}

# ============================================================================
# Clean cities (well-formed ranges) — unchanged behaviour
# ============================================================================

@test "regression: Riyadh still resolves to Riyadh" {
    run get_city_from_coordinates "24.7136" "46.6753"
    assert_success
    assert_output "Riyadh"
}

@test "regression: Istanbul still resolves to Istanbul" {
    run get_city_from_coordinates "41.0082" "28.9784"
    assert_success
    assert_output "Istanbul"
}

@test "regression: London still resolves to London" {
    run get_city_from_coordinates "51.5074" "-0.1278"
    assert_success
    assert_output "London"
}

@test "regression: Dubai still resolves to Dubai" {
    run get_city_from_coordinates "25.2048" "55.2708"
    assert_success
    assert_output "Dubai"
}

@test "regression: New York still resolves to New York" {
    run get_city_from_coordinates "40.7128" "-74.0060"
    assert_success
    assert_output "New York"
}

@test "regression: city name with non-ASCII characters is preserved (Sao Paulo)" {
    run get_city_from_coordinates "-23.5558" "-46.6396"
    assert_success
    assert_output "São Paulo"
}

@test "regression: city name with an apostrophe is preserved (N'Djamena)" {
    run get_city_from_coordinates "12.1348" "15.0557"
    assert_success
    assert_output "N'Djamena"
}

# ============================================================================
# Adjacency: Jakarta / Bekasi seam
# ============================================================================

@test "adjacency: Jakarta metro resolves to Jakarta" {
    run get_city_from_coordinates "-6.2000" "106.8500"
    assert_success
    assert_output "Jakarta"
}

@test "adjacency: Bekasi resolves to Bekasi (not Jakarta)" {
    run get_city_from_coordinates "-6.2349" "106.9896"
    assert_success
    assert_output "Bekasi"
}

# ============================================================================
# Regional fallbacks — coordinates away from any city
# ============================================================================

@test "regional: open water in the Southeast Asia box resolves to 'Southeast Asia'" {
    run get_city_from_coordinates "-2.0000" "118.0000"
    assert_success
    assert_output "Southeast Asia"
}

@test "regional: a point in the Europe box resolves to 'Europe'" {
    run get_city_from_coordinates "47.0000" "15.0000"
    assert_success
    assert_output "Europe"
}

# ============================================================================
# Edge cases — invalid / out-of-coverage input
# ============================================================================

@test "edge: empty coordinates return Unknown and a failure status" {
    run get_city_from_coordinates "" ""
    assert_failure
    assert_output "Unknown"
}

@test "edge: a missing longitude returns Unknown and a failure status" {
    run get_city_from_coordinates "12.9716" ""
    assert_failure
    assert_output "Unknown"
}

@test "edge: a mid-Pacific coordinate outside every box returns Unknown" {
    run get_city_from_coordinates "0.0000" "-140.0000"
    assert_failure
    assert_output "Unknown"
}
