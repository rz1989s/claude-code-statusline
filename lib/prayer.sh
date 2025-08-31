#!/bin/bash

# ============================================================================
# Claude Code Statusline - Islamic Prayer Times & Hijri Calendar Module
# ============================================================================
# 
# This module handles Islamic prayer times calculation and Hijri calendar
# display with proper Maghrib-based day changes according to Islamic tradition.
#
# Dependencies: core.sh, security.sh, cache.sh, config.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_LOADED=true

# Dependencies will be checked during initialization

# ============================================================================
# PRAYER CONSTANTS
# ============================================================================

# Prayer names in order
export PRAYER_NAMES=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
export PRAYER_COUNT=5

# Prayer status indicators
export PRAYER_STATUS_COMPLETED="completed"
export PRAYER_STATUS_NEXT="next"
export PRAYER_STATUS_UPCOMING="upcoming"

# API endpoints
export ALADHAN_API_BASE="https://api.aladhan.com/v1"
export ALADHAN_TIMINGS_ENDPOINT="/timings"

# Default calculation methods (Indonesian defaults)
export DEFAULT_CALCULATION_METHOD="20" # KEMENAG (Indonesian Ministry of Religious Affairs)  
export DEFAULT_MADHAB="2"              # Hanafi (Indonesian standard) - Shafi (1) or Hanafi (2)

# Hijri calendar constants
export HIJRI_MONTHS=("Muharram" "Safar" "Rabi' al-awwal" "Rabi' al-thani" "Jumada al-awwal" "Jumada al-thani" "Rajab" "Sha'ban" "Ramadan" "Shawwal" "Dhu al-Qi'dah" "Dhu al-Hijjah")

# Display indicators
export PRAYER_COMPLETED_INDICATOR="✓"
export PRAYER_NEXT_INDICATOR="(next)"
export PRAYER_MAGHRIB_MOON="🌙"
export HIJRI_INDICATOR="🕌"

# ============================================================================
# CONFIGURATION LOADING
# ============================================================================

# Load prayer configuration with defaults
load_prayer_config() {
    debug_log "Loading prayer configuration..." "INFO"
    
    # Feature toggles
    CONFIG_PRAYER_ENABLED="${ENV_CONFIG_FEATURES_SHOW_PRAYER_TIMES:-${CONFIG_FEATURES_SHOW_PRAYER_TIMES:-true}}"
    CONFIG_HIJRI_ENABLED="${ENV_CONFIG_FEATURES_SHOW_HIJRI_DATE:-${CONFIG_FEATURES_SHOW_HIJRI_DATE:-true}}"
    
    # Prayer settings
    CONFIG_PRAYER_CALCULATION_METHOD="${ENV_CONFIG_PRAYER_CALCULATION_METHOD:-${CONFIG_PRAYER_CALCULATION_METHOD:-$DEFAULT_CALCULATION_METHOD}}"
    CONFIG_PRAYER_MADHAB="${ENV_CONFIG_PRAYER_MADHAB:-${CONFIG_PRAYER_MADHAB:-$DEFAULT_MADHAB}}"
    CONFIG_PRAYER_LOCATION_MODE="${ENV_CONFIG_PRAYER_LOCATION_MODE:-${CONFIG_PRAYER_LOCATION_MODE:-auto}}"
    CONFIG_PRAYER_LATITUDE="${ENV_CONFIG_PRAYER_LATITUDE:-${CONFIG_PRAYER_LATITUDE:-}}"
    CONFIG_PRAYER_LONGITUDE="${ENV_CONFIG_PRAYER_LONGITUDE:-${CONFIG_PRAYER_LONGITUDE:-}}"
    CONFIG_PRAYER_TIMEZONE="${ENV_CONFIG_PRAYER_TIMEZONE:-${CONFIG_PRAYER_TIMEZONE:-}}"
    
    # Hijri settings
    CONFIG_HIJRI_CALCULATION_METHOD="${ENV_CONFIG_HIJRI_CALCULATION_METHOD:-${CONFIG_HIJRI_CALCULATION_METHOD:-umm_alqura}}"
    CONFIG_HIJRI_ADJUSTMENT_DAYS="${ENV_CONFIG_HIJRI_ADJUSTMENT_DAYS:-${CONFIG_HIJRI_ADJUSTMENT_DAYS:-0}}"
    CONFIG_HIJRI_SHOW_ARABIC="${ENV_CONFIG_HIJRI_SHOW_ARABIC:-${CONFIG_HIJRI_SHOW_ARABIC:-false}}"
    CONFIG_HIJRI_HIGHLIGHT_FRIDAY="${ENV_CONFIG_HIJRI_HIGHLIGHT_FRIDAY:-${CONFIG_HIJRI_HIGHLIGHT_FRIDAY:-true}}"
    CONFIG_HIJRI_SHOW_MAGHRIB_INDICATOR="${ENV_CONFIG_HIJRI_SHOW_MAGHRIB_INDICATOR:-${CONFIG_HIJRI_SHOW_MAGHRIB_INDICATOR:-true}}"
    
    # Display options
    CONFIG_PRAYER_SHOW_COMPLETED_INDICATOR="${ENV_CONFIG_PRAYER_SHOW_COMPLETED_INDICATOR:-${CONFIG_PRAYER_SHOW_COMPLETED_INDICATOR:-true}}"
    CONFIG_PRAYER_HIGHLIGHT_NEXT_PRAYER="${ENV_CONFIG_PRAYER_HIGHLIGHT_NEXT_PRAYER:-${CONFIG_PRAYER_HIGHLIGHT_NEXT_PRAYER:-true}}"
    CONFIG_PRAYER_SHOW_COUNTDOWN="${ENV_CONFIG_PRAYER_SHOW_COUNTDOWN:-${CONFIG_PRAYER_SHOW_COUNTDOWN:-false}}"
    CONFIG_PRAYER_TIME_FORMAT="${ENV_CONFIG_PRAYER_TIME_FORMAT:-${CONFIG_PRAYER_TIME_FORMAT:-24h}}"
    
    debug_log "Prayer configuration loaded - Enabled: $CONFIG_PRAYER_ENABLED, Method: $CONFIG_PRAYER_CALCULATION_METHOD" "INFO"
}

# ============================================================================
# LOCATION DETECTION
# ============================================================================

# Get location coordinates (latitude, longitude)
get_location_coordinates() {
    debug_log "Determining location coordinates..." "INFO"
    
    case "$CONFIG_PRAYER_LOCATION_MODE" in
        "manual")
            if [[ -n "$CONFIG_PRAYER_LATITUDE" && -n "$CONFIG_PRAYER_LONGITUDE" ]]; then
                echo "$CONFIG_PRAYER_LATITUDE,$CONFIG_PRAYER_LONGITUDE"
                debug_log "Using manual coordinates: $CONFIG_PRAYER_LATITUDE,$CONFIG_PRAYER_LONGITUDE" "INFO"
                return 0
            else
                debug_log "Manual location mode selected but coordinates not provided" "WARN"
                return 1
            fi
            ;;
        "auto"|*)
            # Try to determine location automatically
            # For now, fall back to Indonesian location (can be enhanced later)
            debug_log "Auto location detection not implemented yet, using default Indonesian coordinates" "WARN"
            echo "-6.2349,106.9896"  # Jakarta/Bekasi coordinates as fallback
            return 0
            ;;
    esac
}

# ============================================================================
# TIME UTILITIES
# ============================================================================

# Get current time in HH:MM format
get_current_time() {
    date +"%H:%M"
}

# Get current date in YYYY-MM-DD format
get_current_date() {
    date +"%Y-%m-%d"
}

# Compare two times in HH:MM format
# Returns 0 if time1 >= time2, 1 otherwise
time_is_after() {
    local time1="$1"
    local time2="$2"
    
    # Convert to minutes for comparison
    local time1_minutes=$(echo "$time1" | awk -F: '{print $1 * 60 + $2}')
    local time2_minutes=$(echo "$time2" | awk -F: '{print $1 * 60 + $2}')
    
    [[ $time1_minutes -ge $time2_minutes ]]
}

# Format time according to configuration (12h or 24h)
format_prayer_time() {
    local time_24h="$1"
    
    if [[ "$CONFIG_PRAYER_TIME_FORMAT" == "12h" ]]; then
        # Convert 24h to 12h format
        date -d "$time_24h" +"%I:%M %p" 2>/dev/null || echo "$time_24h"
    else
        echo "$time_24h"
    fi
}

# ============================================================================
# API INTERACTION
# ============================================================================

# Fetch prayer times and Hijri date from AlAdhan API
fetch_prayer_data() {
    local date="$1"
    local latitude="$2"
    local longitude="$3"
    
    debug_log "Fetching prayer data for date: $date, coordinates: $latitude,$longitude" "INFO"
    
    # Build API URL
    local api_url="${ALADHAN_API_BASE}${ALADHAN_TIMINGS_ENDPOINT}/${date}"
    api_url="${api_url}?latitude=${latitude}&longitude=${longitude}"
    api_url="${api_url}&method=${CONFIG_PRAYER_CALCULATION_METHOD}"
    api_url="${api_url}&school=${CONFIG_PRAYER_MADHAB}"
    
    if [[ -n "$CONFIG_PRAYER_TIMEZONE" ]]; then
        api_url="${api_url}&timezone=${CONFIG_PRAYER_TIMEZONE}"
    fi
    
    debug_log "API URL: $api_url" "DEBUG"
    
    # Make API request with timeout
    local response
    if command_exists curl; then
        response=$(curl -s --max-time 10 "$api_url" 2>/dev/null)
    elif command_exists wget; then
        response=$(wget -qO- --timeout=10 "$api_url" 2>/dev/null)
    else
        debug_log "Neither curl nor wget available for API requests" "ERROR"
        return 1
    fi
    
    # Validate response
    if [[ -z "$response" ]] || ! echo "$response" | jq -e '.data.timings' &>/dev/null; then
        debug_log "Invalid API response received" "ERROR"
        return 1
    fi
    
    echo "$response"
    debug_log "Successfully fetched prayer data from API" "INFO"
    return 0
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
    local hijri_month_en=$(echo "$api_response" | jq -r '.data.date.hijri.month.en' 2>/dev/null)
    local hijri_year=$(echo "$api_response" | jq -r '.data.date.hijri.year' 2>/dev/null)
    local hijri_weekday_en=$(echo "$api_response" | jq -r '.data.date.hijri.weekday.en' 2>/dev/null)
    
    # Validate all components were extracted
    if [[ "$hijri_day" == "null" || "$hijri_month_en" == "null" || "$hijri_year" == "null" ]]; then
        debug_log "Failed to extract Hijri date from API response" "ERROR"
        return 1
    fi
    
    echo "$hijri_day,$hijri_month_en,$hijri_year,$hijri_weekday_en"
    return 0
}

# ============================================================================
# PRAYER STATUS CALCULATION
# ============================================================================

# Determine which prayer is next and status of all prayers
calculate_prayer_statuses() {
    local prayer_times="$1"
    local current_time="$2"
    
    # Split prayer times
    IFS=',' read -r fajr dhuhr asr maghrib isha <<< "$prayer_times"
    local times=("$fajr" "$dhuhr" "$asr" "$maghrib" "$isha")
    
    local statuses=()
    local next_prayer_found=false
    
    for i in "${!times[@]}"; do
        local prayer_time="${times[$i]}"
        
        if time_is_after "$current_time" "$prayer_time"; then
            # Prayer time has passed
            statuses[$i]="$PRAYER_STATUS_COMPLETED"
        elif [[ "$next_prayer_found" == "false" ]]; then
            # This is the next prayer
            statuses[$i]="$PRAYER_STATUS_NEXT"
            next_prayer_found=true
        else
            # Future prayer
            statuses[$i]="$PRAYER_STATUS_UPCOMING"
        fi
    done
    
    # Join statuses with comma
    local result=""
    for status in "${statuses[@]}"; do
        if [[ -z "$result" ]]; then
            result="$status"
        else
            result="$result,$status"
        fi
    done
    
    echo "$result"
}

# ============================================================================
# MAGHRIB-BASED HIJRI DATE LOGIC
# ============================================================================

# Determine current Hijri date considering Maghrib day change
get_current_hijri_date_with_maghrib() {
    local hijri_date_data="$1"
    local maghrib_time="$2"
    local current_time="$3"
    
    # Split Hijri date data
    IFS=',' read -r hijri_day hijri_month hijri_year hijri_weekday <<< "$hijri_date_data"
    
    # Check if we're after Maghrib (new Islamic day)
    if time_is_after "$current_time" "$maghrib_time"; then
        debug_log "Current time ($current_time) is after Maghrib ($maghrib_time) - Islamic day has changed" "INFO"
        
        # Increment the day (simplified - in real implementation would handle month/year rollover)
        hijri_day=$((hijri_day + 1))
        
        # Add moon indicator if configured
        local moon_indicator=""
        if [[ "$CONFIG_HIJRI_SHOW_MAGHRIB_INDICATOR" == "true" ]]; then
            moon_indicator=" $PRAYER_MAGHRIB_MOON"
        fi
        
        echo "${hijri_day},${hijri_month},${hijri_year},${hijri_weekday}${moon_indicator}"
    else
        echo "$hijri_date_data"
    fi
}

# ============================================================================
# MAIN PRAYER DATA FUNCTIONS
# ============================================================================

# Get prayer times and Hijri date with intelligent caching
get_prayer_times_and_hijri() {
    debug_log "Getting prayer times and Hijri date..." "INFO"
    
    # Check if prayer feature is enabled
    if [[ "$CONFIG_PRAYER_ENABLED" != "true" ]]; then
        debug_log "Prayer times feature is disabled" "INFO"
        return 1
    fi
    
    # Get current date and location
    local current_date=$(get_current_date)
    local coordinates=$(get_location_coordinates)
    
    if [[ -z "$coordinates" ]]; then
        debug_log "Failed to determine location coordinates" "ERROR"
        return 1
    fi
    
    IFS=',' read -r latitude longitude <<< "$coordinates"
    
    # Check cache first
    local cache_key="prayer_data_${latitude}_${longitude}_${current_date}"
    local cached_data
    
    if is_module_loaded "cache"; then
        cached_data=$(execute_cached_command "prayer_data" "$cache_key" 3600 "echo placeholder")
    fi
    
    # If no cached data or cache is placeholder, fetch from API
    if [[ -z "$cached_data" || "$cached_data" == "placeholder" ]]; then
        debug_log "No valid cached prayer data, fetching from API..." "INFO"
        
        local api_response
        api_response=$(fetch_prayer_data "$current_date" "$latitude" "$longitude")
        
        if [[ $? -ne 0 || -z "$api_response" ]]; then
            debug_log "Failed to fetch prayer data from API" "ERROR"
            return 1
        fi
        
        # Extract prayer times and Hijri date
        local prayer_times
        prayer_times=$(extract_prayer_times "$api_response")
        
        local hijri_date
        hijri_date=$(extract_hijri_date "$api_response")
        
        if [[ -z "$prayer_times" || -z "$hijri_date" ]]; then
            debug_log "Failed to extract prayer data from API response" "ERROR"
            return 1
        fi
        
        # Cache the combined data
        cached_data="$prayer_times|$hijri_date"
        
        if is_module_loaded "cache"; then
            # Cache for 1 hour
            execute_cached_command "prayer_data" "$cache_key" 3600 "echo '$cached_data'" >/dev/null
        fi
    fi
    
    echo "$cached_data"
    debug_log "Successfully retrieved prayer times and Hijri date" "INFO"
    return 0
}

# Get formatted prayer display string
get_prayer_display() {
    debug_log "Generating prayer display..." "INFO"
    
    # Load prayer configuration
    load_prayer_config
    
    # Get prayer data
    local prayer_data
    prayer_data=$(get_prayer_times_and_hijri)
    
    if [[ $? -ne 0 || -z "$prayer_data" ]]; then
        debug_log "Failed to get prayer data for display" "ERROR"
        echo "${HIJRI_INDICATOR} Prayer times unavailable"
        return 1
    fi
    
    # Split prayer data
    IFS='|' read -r prayer_times hijri_date_data <<< "$prayer_data"
    IFS=',' read -r fajr dhuhr asr maghrib isha <<< "$prayer_times"
    
    # Get current time
    local current_time=$(get_current_time)
    
    # Calculate prayer statuses
    local prayer_statuses
    prayer_statuses=$(calculate_prayer_statuses "$prayer_times" "$current_time")
    
    # Get current Hijri date with Maghrib consideration
    local current_hijri_date
    current_hijri_date=$(get_current_hijri_date_with_maghrib "$hijri_date_data" "$maghrib" "$current_time")
    
    # Format Hijri date for display
    IFS=',' read -r hijri_day hijri_month hijri_year hijri_weekday hijri_extra <<< "$current_hijri_date"
    local hijri_display="${hijri_day} ${hijri_month} ${hijri_year}${hijri_extra}"
    
    # Build prayer times display
    local prayers_display=""
    local prayer_names=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
    local times=("$fajr" "$dhuhr" "$asr" "$maghrib" "$isha")
    IFS=',' read -ra statuses <<< "$prayer_statuses"
    
    for i in "${!prayer_names[@]}"; do
        local prayer_name="${prayer_names[$i]}"
        local prayer_time=$(format_prayer_time "${times[$i]}")
        local prayer_status="${statuses[$i]}"
        
        local prayer_display="$prayer_name $prayer_time"
        
        # Add status indicators
        case "$prayer_status" in
            "$PRAYER_STATUS_COMPLETED")
                if [[ "$CONFIG_PRAYER_SHOW_COMPLETED_INDICATOR" == "true" ]]; then
                    prayer_display="$prayer_display $PRAYER_COMPLETED_INDICATOR"
                fi
                ;;
            "$PRAYER_STATUS_NEXT")
                if [[ "$CONFIG_PRAYER_HIGHLIGHT_NEXT_PRAYER" == "true" ]]; then
                    prayer_display="$prayer_display $PRAYER_NEXT_INDICATOR"
                fi
                ;;
        esac
        
        # Add to prayers display
        if [[ -z "$prayers_display" ]]; then
            prayers_display="$prayer_display"
        else
            prayers_display="$prayers_display │ $prayer_display"
        fi
    done
    
    # Combine Hijri date and prayer times
    echo "${HIJRI_INDICATOR} ${hijri_display} │ ${prayers_display}"
    
    debug_log "Generated prayer display successfully" "INFO"
    return 0
}

debug_log "Prayer module loaded successfully" "INFO"