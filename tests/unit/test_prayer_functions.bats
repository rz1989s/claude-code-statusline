#!/usr/bin/env bats

# Unit tests for Islamic Prayer Times and Hijri Calendar functions

load '../setup_suite'
load '../helpers/test_helpers'

setup() {
    common_setup
    
    # Load the prayer module for testing
    source "$TEST_STATUSLINE_DIR/lib/core.sh"
    source "$TEST_STATUSLINE_DIR/lib/security.sh"
    source "$TEST_STATUSLINE_DIR/lib/prayer.sh"
    
    # Set up mock configuration for prayer module
    export CONFIG_PRAYER_ENABLED="true"
    export CONFIG_HIJRI_ENABLED="true"
    export CONFIG_PRAYER_CALCULATION_METHOD="2"
    export CONFIG_PRAYER_MADHAB="1"
    export CONFIG_PRAYER_LOCATION_MODE="manual"
    export CONFIG_PRAYER_LATITUDE="40.7128"
    export CONFIG_PRAYER_LONGITUDE="-74.0060"
    export CONFIG_HIJRI_SHOW_MAGHRIB_INDICATOR="true"
}

teardown() {
    common_teardown
}

# Test configuration loading
@test "load_prayer_config should set default values" {
    unset CONFIG_PRAYER_ENABLED CONFIG_HIJRI_ENABLED
    
    run load_prayer_config
    assert_success
    
    # Check that default values are set
    [ "$CONFIG_PRAYER_ENABLED" = "true" ]
    [ "$CONFIG_HIJRI_ENABLED" = "true" ]
    [ "$CONFIG_PRAYER_CALCULATION_METHOD" = "2" ]
}

# Test location coordinate parsing
@test "get_location_coordinates should return manual coordinates when set" {
    export CONFIG_PRAYER_LOCATION_MODE="manual"
    export CONFIG_PRAYER_LATITUDE="40.7128"
    export CONFIG_PRAYER_LONGITUDE="-74.0060"
    
    run get_location_coordinates
    assert_success
    assert_output "40.7128,-74.0060"
}

@test "get_location_coordinates should fall back to default for auto mode" {
    export CONFIG_PRAYER_LOCATION_MODE="auto"
    
    run get_location_coordinates
    assert_success
    # Should return default NYC coordinates
    assert_output "40.7128,-74.0060"
}

# Test time utilities
@test "time_is_after should correctly compare times" {
    # Test case: 14:30 is after 12:00
    run time_is_after "14:30" "12:00"
    assert_success
    
    # Test case: 12:00 is not after 14:30
    run time_is_after "12:00" "14:30"
    assert_failure
    
    # Test case: same times should return success (equal)
    run time_is_after "12:00" "12:00"
    assert_success
}

@test "format_prayer_time should handle 24h format" {
    export CONFIG_PRAYER_TIME_FORMAT="24h"
    
    run format_prayer_time "14:30"
    assert_success
    assert_output "14:30"
}

# Test prayer times extraction
@test "extract_prayer_times should parse valid API response" {
    # Mock API response with prayer times
    local mock_response='{
        "data": {
            "timings": {
                "Fajr": "05:30",
                "Dhuhr": "12:45",
                "Asr": "15:45",
                "Maghrib": "18:30",
                "Isha": "20:00"
            }
        }
    }'
    
    run extract_prayer_times "$mock_response"
    assert_success
    assert_output "05:30,12:45,15:45,18:30,20:00"
}

@test "extract_prayer_times should fail with invalid response" {
    local invalid_response='{"error": "invalid"}'
    
    run extract_prayer_times "$invalid_response"
    assert_failure
}

# Test Hijri date extraction
@test "extract_hijri_date should parse valid API response" {
    local mock_response='{
        "data": {
            "date": {
                "hijri": {
                    "day": "29",
                    "month": {"en": "Jumada al-awwal"},
                    "year": "1446",
                    "weekday": {"en": "Al Khamis"}
                }
            }
        }
    }'
    
    run extract_hijri_date "$mock_response"
    assert_success
    assert_output "29,Jumada al-awwal,1446,Al Khamis"
}

# Test prayer status calculation
@test "calculate_prayer_statuses should identify completed and next prayers" {
    local prayer_times="05:30,12:45,15:45,18:30,20:00"
    local current_time="14:00"  # After Dhuhr, before Asr
    
    run calculate_prayer_statuses "$prayer_times" "$current_time"
    assert_success
    
    # Should show first two prayers as completed, Asr as next
    assert_output "completed,completed,next,upcoming,upcoming"
}

@test "calculate_prayer_statuses should handle early morning time" {
    local prayer_times="05:30,12:45,15:45,18:30,20:00"
    local current_time="04:00"  # Before Fajr
    
    run calculate_prayer_statuses "$prayer_times" "$current_time"
    assert_success
    
    # Should show Fajr as next, all others as upcoming
    assert_output "next,upcoming,upcoming,upcoming,upcoming"
}

@test "calculate_prayer_statuses should handle late night time" {
    local prayer_times="05:30,12:45,15:45,18:30,20:00"
    local current_time="23:00"  # After Isha
    
    run calculate_prayer_statuses "$prayer_times" "$current_time"
    assert_success
    
    # Should show all prayers as completed
    assert_output "completed,completed,completed,completed,completed"
}

# Test Maghrib-based Hijri date logic
@test "get_current_hijri_date_with_maghrib should increment date after Maghrib" {
    export CONFIG_HIJRI_SHOW_MAGHRIB_INDICATOR="true"
    local hijri_data="29,Jumada al-awwal,1446,Al Khamis"
    local maghrib_time="18:30"
    local current_time="19:00"  # After Maghrib
    
    run get_current_hijri_date_with_maghrib "$hijri_data" "$maghrib_time" "$current_time"
    assert_success
    
    # Should increment day and add moon indicator
    [[ "$output" == *"30,Jumada al-awwal,1446,Al Khamis"* ]]
    [[ "$output" == *"🌙"* ]]
}

@test "get_current_hijri_date_with_maghrib should not change date before Maghrib" {
    local hijri_data="29,Jumada al-awwal,1446,Al Khamis"
    local maghrib_time="18:30"
    local current_time="16:00"  # Before Maghrib
    
    run get_current_hijri_date_with_maghrib "$hijri_data" "$maghrib_time" "$current_time"
    assert_success
    assert_output "29,Jumada al-awwal,1446,Al Khamis"
}

# Test main prayer display function
@test "get_prayer_display should return fallback when prayer disabled" {
    export CONFIG_PRAYER_ENABLED="false"
    
    run get_prayer_display
    assert_failure
}

# Test API interaction with mocked responses
@test "fetch_prayer_data should construct correct API URL" {
    # Mock curl command to capture the URL
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
# Echo the URL that would be called
echo "URL: $4" >&2
echo '{"data":{"timings":{"Fajr":"05:30","Dhuhr":"12:45","Asr":"15:45","Maghrib":"18:30","Isha":"20:00"},"date":{"hijri":{"day":"29","month":{"en":"Jumada al-awwal"},"year":"1446","weekday":{"en":"Al Khamis"}}}}}'
EOF
    chmod +x "$MOCK_BIN_DIR/curl"
    
    run fetch_prayer_data "2024-01-15" "40.7128" "-74.0060"
    assert_success
    
    # Check that URL contains expected parameters
    [[ "$stderr" == *"latitude=40.7128"* ]]
    [[ "$stderr" == *"longitude=-74.0060"* ]]
    [[ "$stderr" == *"method=2"* ]]
    [[ "$stderr" == *"school=1"* ]]
}

@test "fetch_prayer_data should handle API timeout" {
    # Mock curl to timeout
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
exit 28  # curl timeout exit code
EOF
    chmod +x "$MOCK_BIN_DIR/curl"
    
    run fetch_prayer_data "2024-01-15" "40.7128" "-74.0060"
    assert_failure
}

# Integration test for complete prayer display
@test "prayer display integration should generate formatted output" {
    # Mock successful API response
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
cat << 'JSON'
{
    "data": {
        "timings": {
            "Fajr": "05:30",
            "Dhuhr": "12:45", 
            "Asr": "15:45",
            "Maghrib": "18:30",
            "Isha": "20:00"
        },
        "date": {
            "hijri": {
                "day": "29",
                "month": {"en": "Jumada al-awwal"},
                "year": "1446",
                "weekday": {"en": "Al Khamis"}
            }
        }
    }
}
JSON
EOF
    chmod +x "$MOCK_BIN_DIR/curl"
    
    # Mock date command to return consistent time
    cat > "$MOCK_BIN_DIR/date" << 'EOF'
#!/bin/bash
case "$*" in
    "+%Y-%m-%d") echo "2024-01-15" ;;
    "+%H:%M") echo "14:00" ;;  # After Dhuhr, before Asr
    *) /bin/date "$@" ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/date"
    
    run get_prayer_display
    assert_success
    
    # Verify the output contains expected elements
    [[ "$output" == *"🕌"* ]]                    # Hijri indicator
    [[ "$output" == *"29 Jumada al-awwal 1446"* ]] # Hijri date
    [[ "$output" == *"Fajr 05:30"* ]]            # Prayer times
    [[ "$output" == *"✓"* ]]                     # Completed indicator
    [[ "$output" == *"(next)"* ]]                # Next prayer indicator
}

# Performance test
@test "prayer functions should execute within reasonable time" {
    # Setup mock responses for fast execution
    cat > "$MOCK_BIN_DIR/curl" << 'EOF'
#!/bin/bash
echo '{"data":{"timings":{"Fajr":"05:30","Dhuhr":"12:45","Asr":"15:45","Maghrib":"18:30","Isha":"20:00"},"date":{"hijri":{"day":"29","month":{"en":"Jumada al-awwal"},"year":"1446"}}}}'
EOF
    chmod +x "$MOCK_BIN_DIR/curl"
    
    # Time the execution
    start_time=$(date +%s%N)
    run get_prayer_display
    end_time=$(date +%s%N)
    
    assert_success
    
    # Should complete within 2 seconds (2,000,000,000 nanoseconds)
    local execution_time=$((end_time - start_time))
    [ $execution_time -lt 2000000000 ]
}