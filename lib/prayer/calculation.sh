#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Time Calculation Module
# ============================================================================
# 
# This module handles prayer time calculations, API data processing, and 
# Hijri calendar calculations.
#
# Dependencies: core.sh, security.sh, cache.sh, prayer/core.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_CALCULATION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_CALCULATION_LOADED=true

# ============================================================================
# TIME UTILITIES
# ============================================================================

# Get current time in HH:MM format
get_current_time() {
    date +"%H:%M"
}

# Get current date in DD-MM-YYYY format
get_current_date() {
    date +"%d-%m-%Y"
}

# Check if current time is after given time (both in HH:MM format)
time_is_after() {
    local current_time="$1"
    local target_time="$2"
    
    # Convert times to minutes for comparison
    local current_minutes=$((10#${current_time%:*} * 60 + 10#${current_time#*:}))
    local target_minutes=$((10#${target_time%:*} * 60 + 10#${target_time#*:}))
    
    [[ $current_minutes -gt $target_minutes ]]
}

# Calculate time until next prayer in minutes
calculate_time_until_prayer() {
    local current_time="$1"
    local prayer_time="$2"
    
    # Convert times to minutes since midnight
    local current_minutes=$((10#${current_time%:*} * 60 + 10#${current_time#*:}))
    local prayer_minutes=$((10#${prayer_time%:*} * 60 + 10#${prayer_time#*:}))
    
    # Calculate difference
    if [[ $prayer_minutes -ge $current_minutes ]]; then
        echo $((prayer_minutes - current_minutes))
    else
        # Prayer is tomorrow (add 24 hours)
        echo $((prayer_minutes + 1440 - current_minutes))
    fi
}

# Format time remaining for display
format_time_remaining() {
    local minutes="$1"
    
    if [[ $minutes -gt 60 ]]; then
        local hours=$((minutes / 60))
        local remaining_minutes=$((minutes % 60))
        echo "${hours}h ${remaining_minutes}m"
    else
        echo "${minutes}m"
    fi
}

# Format prayer time based on configuration
format_prayer_time() {
    local time_24h="$1"
    
    if [[ "$CONFIG_PRAYER_TIME_FORMAT" == "12h" ]]; then
        # Convert to 12-hour format if date command supports it
        date -d "$time_24h" +"%I:%M %p" 2>/dev/null || echo "$time_24h"
    else
        echo "$time_24h"
    fi
}

# ============================================================================
# PRAYER TIME PROCESSING
# ============================================================================

# Extract prayer times from API response
extract_prayer_times() {
    local api_response="$1"
    
    if [[ -z "$api_response" ]]; then
        return 1
    fi
    
    # Extract all prayer times using jq
    local fajr=$(echo "$api_response" | jq -r '.data.timings.Fajr' 2>/dev/null)
    local dhuhr=$(echo "$api_response" | jq -r '.data.timings.Dhuhr' 2>/dev/null)
    local asr=$(echo "$api_response" | jq -r '.data.timings.Asr' 2>/dev/null)
    local maghrib=$(echo "$api_response" | jq -r '.data.timings.Maghrib' 2>/dev/null)
    local isha=$(echo "$api_response" | jq -r '.data.timings.Isha' 2>/dev/null)
    
    # Validate all times were extracted
    if [[ "$fajr" == "null" || "$dhuhr" == "null" || "$asr" == "null" || "$maghrib" == "null" || "$isha" == "null" ]]; then
        debug_log "Failed to extract all prayer times from API response" "ERROR"
        return 1
    fi
    
    echo "$fajr,$dhuhr,$asr,$maghrib,$isha"
    return 0
}

# Extract Hijri date from API response  
extract_hijri_date() {
    local api_response="$1"
    
    if [[ -z "$api_response" ]]; then
        return 1
    fi
    
    # Extract Hijri date components
    local hijri_day=$(echo "$api_response" | jq -r '.data.date.hijri.day' 2>/dev/null)
    local hijri_month_number=$(echo "$api_response" | jq -r '.data.date.hijri.month.number' 2>/dev/null)
    local hijri_year=$(echo "$api_response" | jq -r '.data.date.hijri.year' 2>/dev/null)
    local hijri_weekday=$(echo "$api_response" | jq -r '.data.date.hijri.weekday.en' 2>/dev/null)
    
    # Validate extraction
    if [[ "$hijri_day" == "null" || "$hijri_month_number" == "null" || "$hijri_year" == "null" ]]; then
        debug_log "Failed to extract Hijri date from API response" "ERROR"
        return 1
    fi
    
    # Get month name from array (month numbers are 1-based)
    local month_index=$((hijri_month_number - 1))
    local hijri_month_name="${HIJRI_MONTHS[$month_index]}"
    
    echo "$hijri_day,$hijri_month_name,$hijri_year,$hijri_weekday"
    return 0
}

# ============================================================================
# PRAYER STATUS CALCULATION
# ============================================================================

# Calculate prayer completion status and next prayer
calculate_prayer_statuses() {
    local current_time="$1"
    local prayer_times="$2"  # Format: fajr,dhuhr,asr,maghrib,isha
    
    # Split prayer times
    IFS=',' read -r fajr dhuhr asr maghrib isha <<< "$prayer_times"
    
    # Initialize arrays
    local prayer_names=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
    local prayer_times_array=("$fajr" "$dhuhr" "$asr" "$maghrib" "$isha")
    local statuses=()
    local next_prayer=""
    local next_prayer_time=""
    local next_prayer_index=-1
    
    # Determine prayer statuses
    for i in {0..4}; do
        local prayer_time="${prayer_times_array[$i]}"
        
        if time_is_after "$current_time" "$prayer_time"; then
            statuses[$i]="$PRAYER_STATUS_COMPLETED"
        elif [[ -z "$next_prayer" ]]; then
            # This is the next prayer
            statuses[$i]="$PRAYER_STATUS_NEXT"
            next_prayer="${prayer_names[$i]}"
            next_prayer_time="$prayer_time"
            next_prayer_index=$i
        else
            statuses[$i]="$PRAYER_STATUS_UPCOMING"
        fi
    done
    
    # Special case: If all prayers are completed, Fajr is next (tomorrow)
    if [[ -z "$next_prayer" ]]; then
        statuses[0]="$PRAYER_STATUS_NEXT"
        next_prayer="Fajr"
        next_prayer_time="$fajr"
        next_prayer_index=0
    fi
    
    # Output: status1,status2,status3,status4,status5|next_prayer|next_time|next_index
    echo "${statuses[0]},${statuses[1]},${statuses[2]},${statuses[3]},${statuses[4]}|$next_prayer|$next_prayer_time|$next_prayer_index"
    return 0
}

# ============================================================================
# HIJRI DATE CALCULATION WITH MAGHRIB-BASED DAY CHANGE
# ============================================================================

# Get current Hijri date considering Maghrib-based day changes
get_current_hijri_date_with_maghrib() {
    local current_time="$1"
    local maghrib_time="$2" 
    local todays_hijri="$3"     # Format: day,month,year,weekday
    local tomorrows_hijri="$4"  # Format: day,month,year,weekday (optional)
    
    # In Islamic calendar, the day changes at Maghrib, not midnight
    # If current time is after Maghrib, we should show tomorrow's Hijri date
    if [[ -n "$maghrib_time" ]] && time_is_after "$current_time" "$maghrib_time"; then
        if [[ -n "$tomorrows_hijri" ]]; then
            debug_log "Current time is after Maghrib, using tomorrow's Hijri date" "INFO"
            echo "$tomorrows_hijri"
        else
            # Calculate tomorrow's Hijri date if not provided
            debug_log "Maghrib passed but tomorrow's Hijri date not available, estimating..." "WARN"
            IFS=',' read -r day month year weekday <<< "$todays_hijri"
            
            # Simple increment (this is approximate, actual Islamic calendar is complex)
            local next_day=$((day + 1))
            echo "$next_day,$month,$year,$weekday"
        fi
    else
        debug_log "Current time is before Maghrib, using today's Hijri date" "INFO"
        echo "$todays_hijri"
    fi
}

# ============================================================================
# CACHE VALIDATION
# ============================================================================

# Validate cached static prayer data (prayer_times\thijri_date)
validate_static_prayer_cache() {
    local cache_file="$1"

    # Basic cache validation
    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi

    # Read cache content
    local cache_content
    cache_content="$(cat "$cache_file" 2>/dev/null)" || return 1

    # Check for tab-delimited format (prayer_times\thijri_date)
    if [[ ! "$cache_content" =~ $'\t' ]]; then
        debug_log "Static prayer cache validation failed: missing tab delimiter" "WARN"
        return 1
    fi

    # Parse and validate components
    IFS=$'\t' read -r prayer_times hijri_date <<< "$cache_content"

    # Validate prayer times format (should have 5 comma-separated times)
    if [[ ! "$prayer_times" =~ ^[0-9]{2}:[0-9]{2}(,[0-9]{2}:[0-9]{2}){4}$ ]]; then
        debug_log "Static prayer cache validation failed: invalid prayer times format" "WARN"
        return 1
    fi

    # Validate hijri date (should have comma-separated components)
    if [[ ! "$hijri_date" =~ ^[0-9]+(,[^,]+){3}$ ]]; then
        debug_log "Static prayer cache validation failed: invalid hijri date format" "WARN"
        return 1
    fi

    debug_log "Static prayer cache validation passed" "INFO"
    return 0
}

# Validate cached prayer data to ensure it's properly formatted (backward compatibility)
validate_prayer_cache() {
    local cache_file="$1"

    # Basic cache validation
    if ! validate_basic_cache "$cache_file"; then
        return 1
    fi

    # Read cache content
    local cache_content
    cache_content="$(cat "$cache_file" 2>/dev/null)" || return 1

    # Check for tab-delimited format (prayer_times\tprayer_statuses\thijri_date\tcurrent_time)
    if [[ ! "$cache_content" =~ $'\t' ]]; then
        debug_log "Prayer cache validation failed: missing tab delimiters" "WARN"
        return 1
    fi

    # Parse and validate components
    IFS=$'\t' read -r prayer_times prayer_statuses hijri_date current_time <<< "$cache_content"

    # Validate prayer times format (should have 5 comma-separated times)
    if [[ ! "$prayer_times" =~ ^[0-9]{2}:[0-9]{2}(,[0-9]{2}:[0-9]{2}){4}$ ]]; then
        debug_log "Prayer cache validation failed: invalid prayer times format" "WARN"
        return 1
    fi

    # Validate prayer statuses (should contain status info)
    if [[ -z "$prayer_statuses" ]]; then
        debug_log "Prayer cache validation failed: missing prayer statuses" "WARN"
        return 1
    fi

    # Validate hijri date (should have comma-separated components)
    if [[ ! "$hijri_date" =~ ^[0-9]+(,[^,]+){3}$ ]]; then
        debug_log "Prayer cache validation failed: invalid hijri date format" "WARN"
        return 1
    fi

    # Validate current time format
    if [[ ! "$current_time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        debug_log "Prayer cache validation failed: invalid current time format" "WARN"
        return 1
    fi

    debug_log "Prayer cache validation passed" "INFO"
    return 0
}

# ============================================================================
# MAIN PRAYER DATA RETRIEVAL
# ============================================================================

# Internal function to fetch only static prayer data without caching (for execute_cached_command)
_get_prayer_times_static_uncached() {
    debug_log "Retrieving static prayer and Hijri data (uncached)..." "INFO"

    # Get current location coordinates
    local coordinates
    coordinates=$(get_location_coordinates)

    if [[ $? -ne 0 || -z "$coordinates" ]]; then
        debug_log "Failed to get location coordinates" "ERROR"
        return 1
    fi

    local latitude="${coordinates%%,*}"
    local longitude="${coordinates##*,}"
    local current_date=$(get_current_date)

    debug_log "Using coordinates: $latitude,$longitude for date: $current_date" "INFO"

    # Fetch prayer data from API with retry logic
    local api_response
    api_response=$(fetch_prayer_data_with_retry "$current_date" "$latitude" "$longitude")

    if [[ $? -ne 0 || -z "$api_response" ]]; then
        debug_log "Failed to fetch prayer data from API" "ERROR"
        return 1
    fi

    # Extract prayer times
    local prayer_times
    prayer_times=$(extract_prayer_times "$api_response")

    if [[ $? -ne 0 || -z "$prayer_times" ]]; then
        debug_log "Failed to extract prayer times" "ERROR"
        return 1
    fi

    # Extract Hijri date
    local hijri_date
    hijri_date=$(extract_hijri_date "$api_response")

    if [[ $? -ne 0 || -z "$hijri_date" ]]; then
        debug_log "Failed to extract Hijri date" "ERROR"
        return 1
    fi

    # Store only static data - no prayer statuses or current time
    # Format: prayer_times\thijri_date
    echo -e "$prayer_times\t$hijri_date"

    debug_log "Successfully retrieved static prayer data" "INFO"
    return 0
}

# Backward compatibility function that includes dynamic status calculation
_get_prayer_times_and_hijri_uncached() {
    debug_log "Retrieving comprehensive prayer and Hijri data (uncached)..." "INFO"

    # Get static data (cached)
    local static_data
    static_data=$(get_prayer_times_static)

    if [[ $? -ne 0 || -z "$static_data" ]]; then
        debug_log "Failed to get static prayer data" "ERROR"
        return 1
    fi

    # Parse static data
    IFS=$'\t' read -r prayer_times hijri_date <<< "$static_data"

    # Calculate dynamic prayer statuses with current time
    local current_time=$(get_current_time)
    local prayer_statuses
    prayer_statuses=$(calculate_prayer_statuses "$current_time" "$prayer_times")

    if [[ $? -ne 0 || -z "$prayer_statuses" ]]; then
        debug_log "Failed to calculate prayer statuses" "ERROR"
        return 1
    fi

    # Get Maghrib time for Hijri day calculation
    local maghrib_time
    IFS=',' read -r fajr dhuhr asr maghrib isha <<< "$prayer_times"
    maghrib_time="$maghrib"

    # Adjust Hijri date based on current Maghrib time
    local adjusted_hijri
    adjusted_hijri=$(get_current_hijri_date_with_maghrib "$current_time" "$maghrib_time" "$hijri_date")

    # Combine all data using tab delimiter
    # Format: prayer_times\tprayer_statuses\thijri_date\tcurrent_time
    echo -e "$prayer_times\t$prayer_statuses\t$adjusted_hijri\t$current_time"

    debug_log "Successfully retrieved and processed all prayer data with fresh statuses" "INFO"
    return 0
}

# Get static prayer times and Hijri date (cached) - no status calculation
get_prayer_times_static() {
    debug_log "Retrieving static prayer data with caching..." "INFO"

    # Get current coordinates for cache key generation (to detect location changes)
    local coordinates
    coordinates=$(get_location_coordinates)

    if [[ $? -ne 0 || -z "$coordinates" ]]; then
        debug_log "Failed to get location coordinates for cache key" "ERROR"
        return 1
    fi

    local latitude="${coordinates%%,*}"
    local longitude="${coordinates##*,}"
    local current_date=$(get_current_date)

    # Generate location-aware cache key to detect travel/location changes
    local safe_date="${current_date//-/}"  # Remove all dashes
    local safe_lat="${latitude//[.-]/}"    # Remove dots and minus signs
    local safe_lng="${longitude//[.-]/}"   # Remove dots and minus signs
    local cache_key="prayer_static_${safe_date}_${safe_lat}_${safe_lng}_${CONFIG_PRAYER_CALCULATION_METHOD}"

    debug_log "Using travel-aware cache key for static data: $cache_key" "INFO"

    # Use longer cache duration for static data (can be cached longer)
    execute_cached_command \
        "$cache_key" \
        "$CACHE_DURATION_PRAYER_TIMES" \
        "validate_static_prayer_cache" \
        "true" \
        "false" \
        _get_prayer_times_static_uncached
}

# Get comprehensive prayer times and Hijri date data with dynamic status calculation
get_prayer_times_and_hijri() {
    debug_log "Retrieving prayer data with dynamic status calculation..." "INFO"

    # This function now always calculates fresh statuses but uses cached prayer times
    _get_prayer_times_and_hijri_uncached
}