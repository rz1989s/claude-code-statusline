#!/usr/bin/env bats

# ============================================================================
# Test Suite: Islamic Prayer Times Auto-Location Detection
# ============================================================================
# 
# Tests comprehensive worldwide auto-detection covering:
# • Timezone mapping for 98% of global Muslim population
# • Country code mapping for 80+ countries
# • IP geolocation integration with caching
# • Configuration integration and fallback chains
# ============================================================================

load '../helpers/test_helpers'

setup() {
    # Set up test environment
    export STATUSLINE_DEBUG_MODE="false"
    export STATUSLINE_CACHE_DIR="$BATS_TMPDIR/cache"
    mkdir -p "$STATUSLINE_CACHE_DIR"
    
    # Load prayer module with dependencies
    source_with_fallback "$BATS_TEST_DIRNAME/../../lib/core.sh"
    source_with_fallback "$BATS_TEST_DIRNAME/../../lib/security.sh"
    source_with_fallback "$BATS_TEST_DIRNAME/../../lib/config.sh" 
    source_with_fallback "$BATS_TEST_DIRNAME/../../lib/prayer.sh"
}

teardown() {
    # Clean up test cache
    rm -rf "$STATUSLINE_CACHE_DIR" 2>/dev/null
}

# ============================================================================
# TIMEZONE MAPPING TESTS - Major Islamic Countries (2+ Billion Muslims)
# ============================================================================

@test "Prayer method mapping: Southeast Asia (450M Muslims)" {
    # Indonesia - 231M Muslims → KEMENAG
    run get_prayer_method_from_timezone "Asia/Jakarta"
    assert_success
    assert_output "20"
    
    run get_prayer_method_from_timezone "Asia/Makassar"
    assert_success
    assert_output "20"
    
    # Malaysia - 20M Muslims → JAKIM
    run get_prayer_method_from_timezone "Asia/Kuala_Lumpur"
    assert_success
    assert_output "17"
    
    # Singapore - 0.9M Muslims → MUIS
    run get_prayer_method_from_timezone "Asia/Singapore"
    assert_success
    assert_output "11"
}

@test "Prayer method mapping: South Asia (620M Muslims)" {
    # Pakistan - 225M Muslims → Karachi
    run get_prayer_method_from_timezone "Asia/Karachi"
    assert_success
    assert_output "1"
    
    # Bangladesh - 153M Muslims → Karachi
    run get_prayer_method_from_timezone "Asia/Dhaka"
    assert_success
    assert_output "1"
    
    # India - 195M Muslims → Karachi
    run get_prayer_method_from_timezone "Asia/Delhi"
    assert_success
    assert_output "1"
    
    run get_prayer_method_from_timezone "Asia/Mumbai" 
    assert_success
    assert_output "1"
    
    run get_prayer_method_from_timezone "Asia/Kolkata"
    assert_success
    assert_output "1"
    
    # Afghanistan - 38M Muslims → Karachi
    run get_prayer_method_from_timezone "Asia/Kabul"
    assert_success
    assert_output "1"
}

@test "Prayer method mapping: Middle East & Gulf (120M Muslims)" {
    # Saudi Arabia - 31M Muslims → Umm al-Qura
    run get_prayer_method_from_timezone "Asia/Riyadh"
    assert_success
    assert_output "4"
    
    run get_prayer_method_from_timezone "Asia/Jeddah"
    assert_success
    assert_output "4"
    
    # UAE - 7M Muslims → Dubai
    run get_prayer_method_from_timezone "Asia/Dubai"
    assert_success
    assert_output "16"
    
    run get_prayer_method_from_timezone "Asia/Abu_Dhabi"
    assert_success
    assert_output "16"
    
    # Kuwait - 3M Muslims → Kuwait
    run get_prayer_method_from_timezone "Asia/Kuwait"
    assert_success
    assert_output "9"
    
    # Qatar - 2M Muslims → Qatar
    run get_prayer_method_from_timezone "Asia/Qatar"
    assert_success
    assert_output "10"
    
    run get_prayer_method_from_timezone "Asia/Doha"
    assert_success
    assert_output "10"
    
    # Iran - 82M Muslims → Tehran
    run get_prayer_method_from_timezone "Asia/Tehran"
    assert_success
    assert_output "7"
    
    # Turkey - 79M Muslims → Diyanet
    run get_prayer_method_from_timezone "Asia/Istanbul"
    assert_success
    assert_output "13"
    
    run get_prayer_method_from_timezone "Europe/Istanbul"
    assert_success
    assert_output "13"
}

@test "Prayer method mapping: North Africa (280M Muslims)" {
    # Egypt - 87M Muslims → Egyptian
    run get_prayer_method_from_timezone "Africa/Cairo"
    assert_success
    assert_output "5"
    
    # Nigeria - 99M Muslims → Egyptian
    run get_prayer_method_from_timezone "Africa/Lagos"
    assert_success
    assert_output "5"
    
    # Algeria - 43M Muslims → Algeria
    run get_prayer_method_from_timezone "Africa/Algiers"
    assert_success
    assert_output "22"
    
    # Morocco - 37M Muslims → Morocco
    run get_prayer_method_from_timezone "Africa/Casablanca"
    assert_success
    assert_output "23"
    
    # Tunisia - 12M Muslims → Tunisia
    run get_prayer_method_from_timezone "Africa/Tunis"
    assert_success
    assert_output "21"
    
    # Sudan - 39M Muslims → Egyptian
    run get_prayer_method_from_timezone "Africa/Khartoum"
    assert_success
    assert_output "5"
}

@test "Prayer method mapping: Europe & Americas (75M Muslims)" {
    # Russia - 20M Muslims → Spiritual Admin
    run get_prayer_method_from_timezone "Europe/Moscow"
    assert_success
    assert_output "14"
    
    # France - 6M Muslims → UOIF
    run get_prayer_method_from_timezone "Europe/Paris"
    assert_success
    assert_output "12"
    
    # UK - 3M Muslims → MWL
    run get_prayer_method_from_timezone "Europe/London"
    assert_success
    assert_output "3"
    
    # Germany - 5M Muslims → MWL
    run get_prayer_method_from_timezone "Europe/Berlin"
    assert_success
    assert_output "3"
    
    # USA - 3.5M Muslims → ISNA
    run get_prayer_method_from_timezone "America/New_York"
    assert_success
    assert_output "2"
    
    run get_prayer_method_from_timezone "America/Los_Angeles"
    assert_success
    assert_output "2"
    
    # Canada - 1.5M Muslims → ISNA
    run get_prayer_method_from_timezone "America/Toronto"
    assert_success
    assert_output "2"
    
    # Australia - 0.6M Muslims → MWL
    run get_prayer_method_from_timezone "Australia/Sydney"
    assert_success
    assert_output "3"
}

@test "Prayer method mapping: Pattern-based regional detection" {
    # Indonesian city patterns → KEMENAG
    run get_prayer_method_from_timezone "Asia/Surabaya"
    assert_success
    assert_output "20"
    
    # Pakistani city patterns → Karachi
    run get_prayer_method_from_timezone "Asia/Lahore"
    assert_success
    assert_output "1"
    
    # Saudi city patterns → Umm al-Qura
    run get_prayer_method_from_timezone "Asia/Mecca"
    assert_success
    assert_output "4"
    
    # Generic continent fallbacks
    run get_prayer_method_from_timezone "Asia/Unknown"
    assert_success
    assert_output "3"  # MWL fallback
    
    run get_prayer_method_from_timezone "Africa/Unknown"
    assert_success
    assert_output "5"  # Egyptian fallback
    
    run get_prayer_method_from_timezone "Europe/Unknown"
    assert_success
    assert_output "3"  # MWL fallback
    
    # Ultimate safe fallback
    run get_prayer_method_from_timezone "Unknown/Unknown"
    assert_success
    assert_output "3"  # MWL safe fallback
}

# ============================================================================
# COUNTRY CODE MAPPING TESTS - 80+ Countries
# ============================================================================

@test "Country code mapping: Major Islamic countries" {
    # Southeast Asia
    run get_method_from_country_code "ID"
    assert_success
    assert_output "20"  # Indonesia → KEMENAG
    
    run get_method_from_country_code "MY"
    assert_success
    assert_output "17"  # Malaysia → JAKIM
    
    run get_method_from_country_code "SG"
    assert_success
    assert_output "11"  # Singapore → MUIS
    
    # South Asia
    run get_method_from_country_code "PK"
    assert_success
    assert_output "1"   # Pakistan → Karachi
    
    run get_method_from_country_code "BD"
    assert_success
    assert_output "1"   # Bangladesh → Karachi
    
    run get_method_from_country_code "IN"
    assert_success
    assert_output "1"   # India → Karachi
    
    # Middle East
    run get_method_from_country_code "SA"
    assert_success
    assert_output "4"   # Saudi Arabia → Umm al-Qura
    
    run get_method_from_country_code "AE"
    assert_success
    assert_output "16"  # UAE → Dubai
    
    run get_method_from_country_code "IR"
    assert_success
    assert_output "7"   # Iran → Tehran
    
    run get_method_from_country_code "TR"
    assert_success
    assert_output "13"  # Turkey → Diyanet
    
    # Africa
    run get_method_from_country_code "EG"
    assert_success
    assert_output "5"   # Egypt → Egyptian
    
    run get_method_from_country_code "NG"
    assert_success
    assert_output "5"   # Nigeria → Egyptian
    
    run get_method_from_country_code "DZ"
    assert_success
    assert_output "22"  # Algeria → Algeria
    
    run get_method_from_country_code "MA"
    assert_success
    assert_output "23"  # Morocco → Morocco
}

@test "Country code mapping: Europe and Americas" {
    # Europe
    run get_method_from_country_code "RU"
    assert_success
    assert_output "14"  # Russia → Spiritual Admin
    
    run get_method_from_country_code "FR"
    assert_success
    assert_output "12"  # France → UOIF
    
    run get_method_from_country_code "GB"
    assert_success
    assert_output "3"   # UK → MWL
    
    run get_method_from_country_code "DE"
    assert_success
    assert_output "3"   # Germany → MWL
    
    # Americas
    run get_method_from_country_code "US"
    assert_success
    assert_output "2"   # USA → ISNA
    
    run get_method_from_country_code "CA"
    assert_success
    assert_output "2"   # Canada → ISNA
    
    # Case insensitive
    run get_method_from_country_code "id"
    assert_success
    assert_output "20"  # Indonesia (lowercase)
    
    # Unknown country fallback
    run get_method_from_country_code "XX"
    assert_success
    assert_output "3"   # MWL safe fallback
}

# ============================================================================
# INTERNET CONNECTIVITY TESTS
# ============================================================================

@test "Internet connectivity check: curl available" {
    # Mock curl command to be available
    create_mock_command "curl" "echo 'success'"
    
    run check_internet_connection
    assert_success
}

@test "Internet connectivity check: ping fallback" {
    # Mock curl not available but ping available
    create_mock_command "ping" "echo 'ping success'"
    
    run check_internet_connection
    assert_success
}

@test "Internet connectivity check: no connectivity" {
    # Mock no internet tools available
    export PATH="/tmp/empty:$PATH"
    
    run check_internet_connection  
    assert_failure
}

# ============================================================================
# LOCATION CACHING TESTS
# ============================================================================

@test "Location caching: cache location data" {
    local test_data='{"country":"Indonesia","countryCode":"ID","city":"Jakarta","latitude":-6.2088,"longitude":106.8456,"timezone":"Asia/Jakarta","timestamp":1640995200,"source":"test"}'
    
    run cache_location_data "$test_data"
    assert_success
    
    # Verify cache file exists and has correct content
    local cache_file="$STATUSLINE_CACHE_DIR/location_auto_detect.cache"
    [[ -f "$cache_file" ]]
    
    # Check file contents
    local cached_content=$(cat "$cache_file")
    [[ "$cached_content" == "$test_data" ]]
    
    # Check file permissions (should be 600)
    local perms=$(stat -c %a "$cache_file" 2>/dev/null || stat -f %A "$cache_file" 2>/dev/null || echo "600")
    [[ "$perms" == "600" ]]
}

@test "Location caching: load fresh cached data" {
    # Create test cache file
    local test_data='{"country":"Malaysia","countryCode":"MY","city":"Kuala Lumpur","latitude":3.1390,"longitude":101.6869,"timezone":"Asia/Kuala_Lumpur","timestamp":'$(date +%s)',"source":"test"}'
    local cache_file="$STATUSLINE_CACHE_DIR/location_auto_detect.cache"
    
    echo "$test_data" > "$cache_file"
    chmod 600 "$cache_file"
    
    # Mock jq for JSON parsing
    create_mock_command "jq" 'case "$*" in
        ". > /dev/null 2>&1") exit 0 ;;
        "-r .countryCode // \"XX\" 2>/dev/null") echo "MY" ;;
        "-r .latitude // 0 2>/dev/null") echo "3.1390" ;;
        "-r .longitude // 0 2>/dev/null") echo "101.6869" ;;
        "-r .timezone // \"UTC\" 2>/dev/null") echo "Asia/Kuala_Lumpur" ;;
        "-r .city // \"Unknown\" 2>/dev/null") echo "Kuala Lumpur" ;;
        "-r .country // \"Unknown\" 2>/dev/null") echo "Malaysia" ;;
    esac'
    
    run load_cached_location
    assert_success
    
    # Verify configuration was applied
    [[ "$CONFIG_PRAYER_CALCULATION_METHOD" == "17" ]]  # JAKIM for Malaysia
    [[ "$CONFIG_PRAYER_LATITUDE" == "3.1390" ]]
    [[ "$CONFIG_PRAYER_LONGITUDE" == "101.6869" ]]
}

@test "Location caching: reject expired cache" {
    # Create old cache file (8 days ago)
    local old_timestamp=$(($(date +%s) - 691200))  # 8 days * 86400 seconds
    local test_data='{"country":"Test","timestamp":'$old_timestamp'}'
    local cache_file="$STATUSLINE_CACHE_DIR/location_auto_detect.cache"
    
    echo "$test_data" > "$cache_file"
    
    # Set file modification time to 8 days ago
    touch -t $(date -d "@$old_timestamp" "+%Y%m%d%H%M" 2>/dev/null || date -r $old_timestamp "+%Y%m%d%H%M" 2>/dev/null || echo "202101010000") "$cache_file"
    
    run load_cached_location
    assert_failure  # Should reject expired cache
}

# ============================================================================
# IP GEOLOCATION MOCK TESTS
# ============================================================================

@test "IP geolocation: successful API response" {
    # Mock successful API response
    local mock_response='{"status":"success","country":"Indonesia","countryCode":"ID","city":"Jakarta","lat":-6.2088,"lon":106.8456,"timezone":"Asia/Jakarta","query":"203.142.67.168"}'
    
    create_mock_command "curl" "echo '$mock_response'"
    create_mock_command "jq" 'case "$*" in
        "-r .status // \"fail\" 2>/dev/null") echo "success" ;;
        "-r .country // \"Unknown\" 2>/dev/null") echo "Indonesia" ;;
        "-r .countryCode // \"XX\" 2>/dev/null") echo "ID" ;;
        "-r .city // \"Unknown\" 2>/dev/null") echo "Jakarta" ;;
        "-r .lat // 0 2>/dev/null") echo "-6.2088" ;;
        "-r .lon // 0 2>/dev/null") echo "106.8456" ;;
        "-r .timezone // \"UTC\" 2>/dev/null") echo "Asia/Jakarta" ;;
        "-r .query // \"unknown\" 2>/dev/null") echo "203.142.67.168" ;;
    esac'
    
    run get_ip_location
    assert_success
    assert_line --partial '"country": "Indonesia"'
    assert_line --partial '"countryCode": "ID"'
    assert_line --partial '"city": "Jakarta"'
    assert_line --partial '"latitude": -6.2088'
    assert_line --partial '"longitude": 106.8456'
}

@test "IP geolocation: API failure handling" {
    # Mock API failure
    create_mock_command "curl" "exit 1"
    
    run get_ip_location
    assert_failure
}

@test "IP geolocation: invalid response handling" {
    # Mock invalid API response
    local mock_response='{"status":"fail","message":"private range","query":"192.168.1.1"}'
    
    create_mock_command "curl" "echo '$mock_response'"
    create_mock_command "jq" 'case "$*" in
        "-r .status // \"fail\" 2>/dev/null") echo "fail" ;;
        "-r .message // \"Unknown error\" 2>/dev/null") echo "private range" ;;
    esac'
    
    run get_ip_location
    assert_failure
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "Integration: local_gps mode with successful IP geolocation fallback" {
    # Set up configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    
    # Mock successful IP geolocation
    local mock_response='{"status":"success","country":"Malaysia","countryCode":"MY","city":"Kuala Lumpur","lat":3.1390,"lon":101.6869,"timezone":"Asia/Kuala_Lumpur","query":"1.2.3.4"}'
    
    create_mock_command "curl" "echo '$mock_response'"
    create_mock_command "jq" 'case "$*" in
        ". > /dev/null 2>&1") exit 0 ;;
        "-r .status // \"fail\" 2>/dev/null") echo "success" ;;
        "-r .country // \"Unknown\" 2>/dev/null") echo "Malaysia" ;;
        "-r .countryCode // \"XX\" 2>/dev/null") echo "MY" ;;
        "-r .city // \"Unknown\" 2>/dev/null") echo "Kuala Lumpur" ;;
        "-r .lat // 0 2>/dev/null") echo "3.1390" ;;
        "-r .lon // 0 2>/dev/null") echo "101.6869" ;;
        "-r .timezone // \"UTC\" 2>/dev/null") echo "Asia/Kuala_Lumpur" ;;
        "-r .query // \"unknown\" 2>/dev/null") echo "1.2.3.4" ;;
        "-r .latitude // 0 2>/dev/null") echo "3.1390" ;;
        "-r .longitude // 0 2>/dev/null") echo "101.6869" ;;
    esac'
    
    run get_location_coordinates
    assert_success
    assert_output "3.1390,101.6869"
    
    # Verify configuration was updated
    [[ "$CONFIG_PRAYER_CALCULATION_METHOD" == "17" ]]  # JAKIM for Malaysia
}

@test "Integration: local_gps mode with offline timezone fallback" {
    # Set up configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"  
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    
    # Mock no internet connectivity
    create_mock_command "curl" "exit 1"
    create_mock_command "ping" "exit 1"
    
    # Mock system timezone
    create_mock_command "readlink" "echo '/usr/share/zoneinfo/Asia/Jakarta'"
    
    run get_location_coordinates
    assert_success
    assert_output "-6.2088,106.8456"  # Jakarta coordinates
}

@test "Integration: manual mode override" {
    # Set up manual configuration
    CONFIG_PRAYER_LOCATION_MODE="manual"
    CONFIG_PRAYER_LATITUDE="-37.8136"  # Melbourne
    CONFIG_PRAYER_LONGITUDE="144.9631"
    
    run get_location_coordinates
    assert_success
    assert_output "-37.8136,144.9631"
    
    # Should not attempt auto-detection
    [[ "$CONFIG_PRAYER_CALCULATION_METHOD" != "17" ]]  # Should not be auto-detected
}

# ============================================================================
# ERROR HANDLING TESTS  
# ============================================================================

@test "Error handling: missing dependencies gracefully handled" {
    # Test without jq
    PATH="/tmp/empty:$PATH" run get_ip_location
    assert_failure
    
    # Test without curl
    PATH="/tmp/empty:$PATH" run check_internet_connection
    assert_failure
}

@test "Error handling: malformed timezone gracefully handled" {
    run get_prayer_method_from_timezone ""
    assert_success
    assert_output "3"  # Safe fallback
    
    run get_prayer_method_from_timezone "Invalid/Timezone/Format"
    assert_success
    assert_output "3"  # Safe fallback
}

@test "Error handling: cache corruption recovery" {
    # Create corrupted cache file
    local cache_file="$STATUSLINE_CACHE_DIR/location_auto_detect.cache"
    echo "invalid json data" > "$cache_file"
    
    run load_cached_location
    assert_failure
    
    # Cache file should be removed
    [[ ! -f "$cache_file" ]]
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

@test "Performance: timezone mapping is fast" {
    # Time multiple timezone lookups
    local start_time=$(date +%s)
    
    for timezone in "Asia/Jakarta" "Asia/Karachi" "Africa/Cairo" "Europe/London" "America/New_York"; do
        get_prayer_method_from_timezone "$timezone" > /dev/null
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Should complete in under 5 seconds (very generous for offline operation)
    [[ $duration -lt 5 ]]
}

@test "Coverage verification: major Islamic countries supported" {
    # Verify coverage for countries with >10M Muslims
    local major_countries=(
        "Asia/Jakarta:20"      # Indonesia 231M → KEMENAG
        "Asia/Karachi:1"       # Pakistan 225M → Karachi
        "Asia/Dhaka:1"         # Bangladesh 153M → Karachi
        "Asia/Delhi:1"         # India 195M → Karachi
        "Africa/Lagos:5"       # Nigeria 99M → Egyptian
        "Africa/Cairo:5"       # Egypt 87M → Egyptian
        "Asia/Tehran:7"        # Iran 82M → Tehran
        "Europe/Istanbul:13"   # Turkey 79M → Diyanet
        "Africa/Algiers:22"    # Algeria 43M → Algeria
        "Africa/Khartoum:5"    # Sudan 39M → Egyptian
        "Asia/Baghdad:9"       # Iraq 38M → Kuwait
        "Asia/Kabul:1"         # Afghanistan 38M → Karachi
        "Africa/Casablanca:23" # Morocco 37M → Morocco
        "Asia/Riyadh:4"        # Saudi Arabia 31M → Umm al-Qura
    )
    
    for country_test in "${major_countries[@]}"; do
        local timezone="${country_test%:*}"
        local expected_method="${country_test#*:}"
        
        run get_prayer_method_from_timezone "$timezone"
        assert_success
        assert_output "$expected_method"
    done
}

# ============================================================================
# GPS LOCATION DETECTION TESTS (NEW)
# ============================================================================

@test "GPS detection: local_gps mode with CoreLocationCLI (macOS)" {
    # Set up local_gps configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""

    # Mock CoreLocationCLI for macOS
    create_mock_command "uname" "echo 'Darwin'"
    create_mock_command "CoreLocationCLI" "echo '40.7128 -74.0060'"

    # Source the location module to get access to GPS functions
    source_with_fallback "$BATS_TEST_DIRNAME/../../lib/prayer/location.sh"

    run get_local_system_coordinates
    assert_success
    assert_output "40.7128 -74.0060"
}

@test "GPS detection: local_gps mode with geoclue2 (Linux)" {
    # Set up local_gps configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""

    # Mock geoclue2 for Linux
    create_mock_command "uname" "echo 'Linux'"

    # Create mock geoclue2 executable
    mkdir -p /tmp/mock_geoclue/usr/lib/geoclue-2.0/demos
    cat > /tmp/mock_geoclue/usr/lib/geoclue-2.0/demos/where-am-i << 'EOF'
#!/bin/bash
echo "Latitude: 40.7128"
echo "Longitude: -74.0060"
EOF
    chmod +x /tmp/mock_geoclue/usr/lib/geoclue-2.0/demos/where-am-i

    # Mock the file existence check
    create_mock_command "test" "case \"\$*\" in
        *geoclue-2.0/demos/where-am-i*) exit 0 ;;
        *) /usr/bin/test \"\$@\" ;;
    esac"

    # Source the location module to get access to GPS functions
    source_with_fallback "$BATS_TEST_DIRNAME/../../lib/prayer/location.sh"

    # Override the geoclue path check for testing
    export MOCK_GEOCLUE_PATH="/tmp/mock_geoclue/usr/lib/geoclue-2.0/demos/where-am-i"

    run get_local_system_coordinates
    assert_success
    assert_output "40.7128 -74.0060"

    # Cleanup
    rm -rf /tmp/mock_geoclue
}

@test "GPS detection: local_gps mode fallback to IP geolocation" {
    # Set up local_gps configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""

    # Mock GPS tools not available
    create_mock_command "CoreLocationCLI" "exit 1"
    create_mock_command "uname" "echo 'Darwin'"

    # Mock successful IP geolocation fallback
    local mock_response='{"status":"success","country":"Indonesia","countryCode":"ID","city":"Jakarta","lat":-6.2088,"lon":106.8456,"timezone":"Asia/Jakarta","query":"203.142.67.168"}'

    create_mock_command "curl" "echo '$mock_response'"
    create_mock_command "jq" 'case "$*" in
        ". > /dev/null 2>&1") exit 0 ;;
        "-r .status // \"fail\" 2>/dev/null") echo "success" ;;
        "-r .country // \"Unknown\" 2>/dev/null") echo "Indonesia" ;;
        "-r .countryCode // \"XX\" 2>/dev/null") echo "ID" ;;
        "-r .city // \"Unknown\" 2>/dev/null") echo "Jakarta" ;;
        "-r .lat // 0 2>/dev/null") echo "-6.2088" ;;
        "-r .lon // 0 2>/dev/null") echo "106.8456" ;;
        "-r .timezone // \"UTC\" 2>/dev/null") echo "Asia/Jakarta" ;;
        "-r .query // \"unknown\" 2>/dev/null") echo "203.142.67.168" ;;
        "-r .latitude // 0 2>/dev/null") echo "-6.2088" ;;
        "-r .longitude // 0 2>/dev/null") echo "106.8456" ;;
    esac'

    run get_location_coordinates
    assert_success
    assert_output "-6.2088,106.8456"

    # Verify configuration was updated for Indonesia
    [[ "$CONFIG_PRAYER_CALCULATION_METHOD" == "20" ]]  # KEMENAG for Indonesia
}

@test "GPS detection: local_gps mode with cached fallback" {
    # Set up local_gps configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""

    # Mock GPS tools and network not available
    create_mock_command "CoreLocationCLI" "exit 1"
    create_mock_command "curl" "exit 1"
    create_mock_command "ping" "exit 1"

    # Create fresh cache file
    local test_data='{"country":"Malaysia","countryCode":"MY","city":"Kuala Lumpur","latitude":3.1390,"longitude":101.6869,"timezone":"Asia/Kuala_Lumpur","timestamp":'$(date +%s)',"source":"test"}'
    local cache_file="$STATUSLINE_CACHE_DIR/location_auto_detect.cache"

    echo "$test_data" > "$cache_file"
    chmod 600 "$cache_file"

    # Mock jq for JSON parsing
    create_mock_command "jq" 'case "$*" in
        ". > /dev/null 2>&1") exit 0 ;;
        "-r .countryCode // \"XX\" 2>/dev/null") echo "MY" ;;
        "-r .latitude // 0 2>/dev/null") echo "3.1390" ;;
        "-r .longitude // 0 2>/dev/null") echo "101.6869" ;;
        "-r .timezone // \"UTC\" 2>/dev/null") echo "Asia/Kuala_Lumpur" ;;
        "-r .city // \"Unknown\" 2>/dev/null") echo "Kuala Lumpur" ;;
        "-r .country // \"Unknown\" 2>/dev/null") echo "Malaysia" ;;
    esac'

    run get_location_coordinates
    assert_success
    assert_output "3.1390,101.6869"

    # Verify configuration was updated for Malaysia
    [[ "$CONFIG_PRAYER_CALCULATION_METHOD" == "17" ]]  # JAKIM for Malaysia
}

@test "GPS detection: local_gps mode with timezone fallback" {
    # Set up local_gps configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""

    # Mock all location detection methods not available
    create_mock_command "CoreLocationCLI" "exit 1"
    create_mock_command "curl" "exit 1"
    create_mock_command "ping" "exit 1"

    # Mock no valid cache
    local cache_file="$STATUSLINE_CACHE_DIR/location_auto_detect.cache"
    [[ -f "$cache_file" ]] && rm "$cache_file"

    # Mock system timezone detection
    create_mock_command "readlink" "echo '/usr/share/zoneinfo/Asia/Jakarta'"

    run get_location_coordinates
    assert_success
    assert_output "-6.2088,106.8456"  # Jakarta coordinates from timezone fallback
}

@test "GPS integration: local_gps mode end-to-end success" {
    # Set up local_gps configuration
    CONFIG_PRAYER_LOCATION_MODE="local_gps"
    CONFIG_PRAYER_LATITUDE=""
    CONFIG_PRAYER_LONGITUDE=""
    CONFIG_PRAYER_ENABLED="true"

    # Mock successful GPS detection
    create_mock_command "uname" "echo 'Darwin'"
    create_mock_command "CoreLocationCLI" "echo '21.4225 39.8262'"  # Mecca coordinates

    # Mock successful prayer API response
    local mock_prayer_response='{"data":{"timings":{"Fajr":"05:30","Dhuhr":"12:45","Asr":"15:45","Maghrib":"18:30","Isha":"20:00"},"date":{"hijri":{"day":"29","month":{"en":"Jumada al-awwal"},"year":"1446","weekday":{"en":"Al Khamis"}}}}}'

    create_mock_command "curl" "echo '$mock_prayer_response'"
    create_mock_command "jq" 'echo "05:30,12:45,15:45,18:30,20:00"'
    create_mock_command "date" 'case "$*" in
        "+%Y-%m-%d") echo "2024-01-15" ;;
        "+%H:%M") echo "14:00" ;;
        *) /bin/date "$@" ;;
    esac'

    # Source prayer module
    source_with_fallback "$BATS_TEST_DIRNAME/../../lib/prayer.sh"

    run get_location_coordinates
    assert_success
    assert_output "21.4225,39.8262"

    # Verify Saudi Arabia prayer method was detected
    [[ "$CONFIG_PRAYER_CALCULATION_METHOD" == "4" ]]  # Umm al-Qura for Saudi Arabia
}