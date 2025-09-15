#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Location Detection Module
# ============================================================================
# 
# This module handles location detection, caching, and coordinate resolution
# for Islamic prayer times.
#
# Dependencies: core.sh, security.sh, cache.sh, prayer/core.sh, prayer/timezone_methods.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_LOCATION_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_LOCATION_LOADED=true

# Load timezone method mappings
source "$(dirname "${BASH_SOURCE[0]}")/timezone_methods.sh"

# ============================================================================
# CONNECTIVITY AND IP GEOLOCATION
# ============================================================================

# Check if internet connection is available
check_internet_connection() {
    # Quick connectivity check using multiple methods
    if command_exists curl; then
        # Try to connect to a reliable DNS server with minimal timeout
        if curl -s --max-time 3 --connect-timeout 2 "http://1.1.1.1" > /dev/null 2>&1; then
            debug_log "Internet connectivity confirmed via curl" "INFO"
            return 0
        fi
    fi
    
    if command_exists ping; then
        # Fallback to ping test
        if ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1; then
            debug_log "Internet connectivity confirmed via ping" "INFO"
            return 0
        fi
    fi
    
    debug_log "No internet connectivity detected" "WARN"
    return 1
}

# Get location data from IP geolocation API
# PRIVACY NOTE: This function uses ip-api.com to determine location based on IP address
# This sends your IP address to a third-party service. Location data is cached locally.
# To disable IP-based location detection, set CONFIG_PRAYER_LOCATION_MODE=manual
get_ip_location() {
    local api_url="http://ip-api.com/json/?fields=status,message,country,countryCode,region,regionName,city,lat,lon,timezone,query"
    local response
    
    debug_log "Fetching location data from IP geolocation API..." "INFO"
    
    if ! command_exists curl; then
        debug_log "curl not available for IP geolocation" "WARN"
        return 1
    fi
    
    # Make API request with timeout and user agent
    response=$(curl -s --max-time 8 --connect-timeout 3 \
        -H "User-Agent: Claude-Code-Statusline/2.4.0" \
        "$api_url" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$response" ]]; then
        debug_log "IP geolocation API request failed" "WARN"
        return 1
    fi
    
    # Check if jq is available for JSON parsing
    if ! command_exists jq; then
        debug_log "jq not available for JSON parsing" "WARN"
        return 1
    fi
    
    # Parse and validate API response
    local status=$(echo "$response" | jq -r '.status // "fail"' 2>/dev/null)
    if [[ "$status" != "success" ]]; then
        local message=$(echo "$response" | jq -r '.message // "Unknown error"' 2>/dev/null)
        debug_log "IP geolocation API returned error: $message" "WARN"
        return 1
    fi
    
    # Extract location data
    local country=$(echo "$response" | jq -r '.country // "Unknown"' 2>/dev/null)
    local country_code=$(echo "$response" | jq -r '.countryCode // "XX"' 2>/dev/null)
    local city=$(echo "$response" | jq -r '.city // "Unknown"' 2>/dev/null)
    local latitude=$(echo "$response" | jq -r '.lat // 0' 2>/dev/null)
    local longitude=$(echo "$response" | jq -r '.lon // 0' 2>/dev/null)
    local timezone=$(echo "$response" | jq -r '.timezone // "UTC"' 2>/dev/null)
    local ip=$(echo "$response" | jq -r '.query // "unknown"' 2>/dev/null)
    
    # Validate essential data
    if [[ "$country_code" == "XX" || "$latitude" == "0" || "$longitude" == "0" ]]; then
        debug_log "Invalid location data received from API" "WARN"
        return 1
    fi
    
    # Create structured location data
    local location_data=$(cat <<EOF
{
    "country": "$country",
    "countryCode": "$country_code", 
    "city": "$city",
    "latitude": $latitude,
    "longitude": $longitude,
    "timezone": "$timezone",
    "ip": "$ip",
    "timestamp": $(date +%s),
    "source": "ip-geolocation"
}
EOF
    )
    
    debug_log "IP geolocation successful: $country ($country_code) - $city" "INFO"
    echo "$location_data"
    return 0
}

# ============================================================================
# LOCATION CACHING SYSTEM
# ============================================================================

# Cache location data
cache_location_data() {
    local location_data="$1"
    local cache_dir="${STATUSLINE_CACHE_DIR:-${HOME}/.cache/claude-code-statusline}"
    local cache_file="$cache_dir/location_auto_detect.cache"
    
    if [[ -z "$location_data" ]]; then
        debug_log "No location data provided for caching" "WARN"
        return 1
    fi
    
    # Ensure cache directory exists
    if ! mkdir -p "$cache_dir" 2>/dev/null; then
        debug_log "Failed to create cache directory: $cache_dir" "WARN"
        return 1
    fi
    
    # Write to cache file
    if echo "$location_data" > "$cache_file" 2>/dev/null; then
        debug_log "Location data cached successfully" "INFO"
        return 0
    else
        debug_log "Failed to write location cache file" "WARN"
        return 1
    fi
}

# Load cached location data
load_cached_location() {
    local cache_dir="${STATUSLINE_CACHE_DIR:-${HOME}/.cache/claude-code-statusline}"
    local cache_file="$cache_dir/location_auto_detect.cache"
    local cache_ttl=604800  # 7 days in seconds
    
    if [[ ! -f "$cache_file" ]]; then
        debug_log "No cached location data found" "INFO"
        return 1
    fi
    
    # Check cache age
    local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    if [[ $cache_age -gt $cache_ttl ]]; then
        debug_log "Cached location data expired (${cache_age}s > ${cache_ttl}s)" "INFO"
        rm -f "$cache_file" 2>/dev/null
        return 1
    fi
    
    # Validate cache file format
    if ! command_exists jq; then
        debug_log "jq not available for cache validation" "WARN"
        return 1
    fi
    
    local cached_data
    if ! cached_data=$(cat "$cache_file" 2>/dev/null); then
        debug_log "Failed to read location cache file" "WARN"
        return 1
    fi
    
    # Validate JSON format
    if ! echo "$cached_data" | jq empty 2>/dev/null; then
        debug_log "Invalid JSON in location cache, removing" "WARN"
        rm -f "$cache_file" 2>/dev/null
        return 1
    fi
    
    debug_log "Using cached location data (age: ${cache_age}s)" "INFO"
    echo "$cached_data"
    return 0
}

# ============================================================================
# LOCATION CONFIGURATION AND FALLBACKS
# ============================================================================

# Apply location data to global configuration variables
apply_location_config() {
    local location_data="$1"
    
    if [[ -z "$location_data" ]]; then
        debug_log "No location data to apply" "WARN"
        return 1
    fi
    
    if ! command_exists jq; then
        debug_log "jq not available for location data parsing" "WARN"
        return 1
    fi
    
    # Extract coordinates
    local latitude=$(echo "$location_data" | jq -r '.latitude // empty' 2>/dev/null)
    local longitude=$(echo "$location_data" | jq -r '.longitude // empty' 2>/dev/null)
    local timezone=$(echo "$location_data" | jq -r '.timezone // empty' 2>/dev/null)
    local country_code=$(echo "$location_data" | jq -r '.countryCode // empty' 2>/dev/null)
    
    if [[ -n "$latitude" && -n "$longitude" ]]; then
        CONFIG_PRAYER_LATITUDE="$latitude"
        CONFIG_PRAYER_LONGITUDE="$longitude"
        debug_log "Applied coordinates from location data: $latitude,$longitude" "INFO"
    fi
    
    if [[ -n "$timezone" ]]; then
        CONFIG_PRAYER_TIMEZONE="$timezone"
        debug_log "Applied timezone from location data: $timezone" "INFO"
    fi
    
    # Auto-detect prayer calculation method
    if [[ -n "$country_code" ]]; then
        local method=$(get_prayer_method_from_country "$country_code")
        if [[ -n "$method" ]]; then
            CONFIG_PRAYER_CALCULATION_METHOD="$method"
            debug_log "Applied calculation method from country code: $method" "INFO"
        fi
    elif [[ -n "$timezone" ]]; then
        local method=$(get_prayer_method_from_timezone "$timezone")
        if [[ -n "$method" ]]; then
            CONFIG_PRAYER_CALCULATION_METHOD="$method"  
            debug_log "Applied calculation method from timezone: $method" "INFO"
        fi
    fi
    
    return 0
}

# ============================================================================
# ENHANCED LOCATION DATA EXPORT
# ============================================================================

# Export location data for external components (e.g., location_display)
export_location_data() {
    local coordinates="$1"
    local method="$2"
    local vpn_status="$3"

    if [[ -n "$coordinates" ]]; then
        export STATUSLINE_DETECTED_COORDINATES="$coordinates"
        export STATUSLINE_DETECTION_METHOD="$method"
        export STATUSLINE_VPN_STATUS="${vpn_status:-NO_VPN}"

        debug_log "Exported location data: coords=$coordinates, method=$method, vpn=$vpn_status" "INFO"
    fi
}

# Get exported location data (for component consumption)
get_exported_location_data() {
    echo "${STATUSLINE_DETECTED_COORDINATES:-},${STATUSLINE_DETECTION_METHOD:-unknown},${STATUSLINE_VPN_STATUS:-NO_VPN}"
}

# ============================================================================
# COORDINATE RESOLUTION
# ============================================================================

# Get location coordinates (latitude, longitude)
get_location_coordinates() {
    debug_log "Determining location coordinates..." "INFO"
    
    case "$CONFIG_PRAYER_LOCATION_MODE" in
        "manual")
            if [[ -n "$CONFIG_PRAYER_LATITUDE" && -n "$CONFIG_PRAYER_LONGITUDE" ]]; then
                local coordinates="$CONFIG_PRAYER_LATITUDE,$CONFIG_PRAYER_LONGITUDE"
                export_location_data "$coordinates" "manual" "NO_VPN"
                echo "$coordinates"
                debug_log "Using manual coordinates: $CONFIG_PRAYER_LATITUDE,$CONFIG_PRAYER_LONGITUDE" "INFO"
                return 0
            else
                debug_log "Manual mode selected but coordinates not configured" "WARN"
                return 1
            fi
            ;;
            
        "ip_based")
            # Pure IP-based detection with fallback coordinates
            debug_log "IP-based location detection mode enabled" "INFO"
            
            # Try IP geolocation first
            if check_internet_connection; then
                debug_log "Attempting IP geolocation..." "INFO"
                local location_data
                if location_data=$(get_ip_location); then
                    # Cache the location data
                    cache_location_data "$location_data"
                    
                    # Apply to configuration
                    apply_location_config "$location_data"
                    
                    # Extract and return coordinates
                    local latitude=$(echo "$location_data" | jq -r '.latitude' 2>/dev/null)
                    local longitude=$(echo "$location_data" | jq -r '.longitude' 2>/dev/null)
                    local coordinates="$latitude,$longitude"
                    export_location_data "$coordinates" "ip_geolocation" "NO_VPN"
                    echo "$coordinates"
                    return 0
                fi
            fi
            
            debug_log "IP geolocation failed, using timezone-based fallback coordinates..." "INFO"
            
            # Fallback: Use timezone to guess coordinates
            local system_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || date +%Z)
            local coordinates
            case "$system_tz" in
                # Major city coordinates for common timezones
                Asia/Jakarta|Asia/Pontianak|Asia/Makassar|Asia/Jayapura) coordinates="-6.2088,106.8456" ;;  # Jakarta
                Asia/Kuala_Lumpur|Asia/Kuching) coordinates="3.1390,101.6869" ;;                             # Kuala Lumpur
                Asia/Singapore) coordinates="1.3521,103.8198" ;;                                             # Singapore
                Asia/Karachi) coordinates="24.8607,67.0011" ;;                                               # Karachi
                Asia/Dhaka) coordinates="23.8103,90.4125" ;;                                                 # Dhaka
                Asia/Kolkata|Asia/Delhi|Asia/Mumbai|Asia/Chennai|Asia/Bangalore) coordinates="28.6139,77.2090" ;; # Delhi
                Asia/Riyadh) coordinates="24.7136,46.6753" ;;                                                # Riyadh
                Asia/Kuwait) coordinates="29.3117,47.4818" ;;                                                # Kuwait City
                Asia/Dubai) coordinates="25.2048,55.2708" ;;                                                 # Dubai
                Asia/Tehran) coordinates="35.6892,51.3890" ;;                                                # Tehran
                Asia/Istanbul|Europe/Istanbul) coordinates="41.0082,28.9784" ;;                              # Istanbul
                Africa/Cairo) coordinates="30.0444,31.2357" ;;                                               # Cairo
                Africa/Lagos) coordinates="6.5244,3.3792" ;;                                                 # Lagos
                # Ultimate fallback (Indonesian coordinates)
                *) coordinates="-6.2349,106.9896" ;;           # Jakarta/Bekasi fallback
            esac

            export_location_data "$coordinates" "timezone_fallback" "POSSIBLE_VPN"
            echo "$coordinates"
            debug_log "Auto-detection completed successfully in fallback mode" "INFO"
            return 0
            ;;
            
        "auto"|*)
            # Enhanced multi-tier automatic location detection
            debug_log "Starting comprehensive automatic location detection..." "INFO"
            
            # Tier 1: Try IP geolocation (if online and not already attempted)
            if [[ "$CONFIG_PRAYER_LOCATION_MODE" != "ip_based" ]] && check_internet_connection; then
                debug_log "Tier 1: Attempting IP geolocation..." "INFO"
                local location_data
                if location_data=$(get_ip_location); then
                    # Cache the successful location data
                    cache_location_data "$location_data"
                    
                    # Apply to configuration
                    apply_location_config "$location_data"
                    
                    # Extract and return coordinates
                    local latitude=$(echo "$location_data" | jq -r '.latitude' 2>/dev/null)
                    local longitude=$(echo "$location_data" | jq -r '.longitude' 2>/dev/null)
                    echo "$latitude,$longitude"
                    debug_log "IP geolocation successful: $latitude,$longitude" "INFO"
                    return 0
                else
                    debug_log "Tier 1 failed: IP geolocation unsuccessful" "WARN"
                fi
            else
                debug_log "Tier 1 skipped: No internet connection" "INFO"
            fi
            
            # Tier 2: Try cached location data
            debug_log "Tier 2: Attempting to load cached location..." "INFO"
            local cached_location
            if cached_location=$(load_cached_location); then
                # Apply cached data to configuration
                apply_location_config "$cached_location"
                
                # Extract and return coordinates
                local latitude=$(echo "$cached_location" | jq -r '.latitude' 2>/dev/null)
                local longitude=$(echo "$cached_location" | jq -r '.longitude' 2>/dev/null)
                echo "$latitude,$longitude"
                debug_log "Using cached location: $latitude,$longitude" "INFO"
                return 0
            else
                debug_log "Tier 2 failed: No valid cached location" "WARN"
            fi
            
            # Tier 3: Timezone-based geographic estimation
            debug_log "Tier 3: Using timezone-based coordinate estimation..." "INFO"
            local system_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
            if [[ -n "$system_tz" ]]; then
                local detected_method=$(get_prayer_method_from_timezone "$system_tz")
                CONFIG_PRAYER_CALCULATION_METHOD="$detected_method"
            fi
            
            case "$system_tz" in
                # Major Islamic population centers
                Asia/Jakarta*|Asia/Pontianak*|Asia/Makassar*|Asia/Jayapura*) echo "-6.2088,106.8456" ;; # Jakarta
                Asia/Kuala_Lumpur*|Asia/Kuching*) echo "3.1390,101.6869" ;;                            # Kuala Lumpur
                Asia/Singapore*) echo "1.3521,103.8198" ;;                                             # Singapore  
                Asia/Karachi*) echo "24.8607,67.0011" ;;                                               # Karachi
                Asia/Dhaka*) echo "23.8103,90.4125" ;;                                                 # Dhaka
                Asia/Kolkata*|Asia/Delhi*|Asia/Mumbai*) echo "28.6139,77.2090" ;;                      # Delhi
                Asia/Riyadh*) echo "24.7136,46.6753" ;;                                                # Riyadh
                Asia/Istanbul*|Europe/Istanbul*) echo "41.0082,28.9784" ;;                             # Istanbul
                Africa/Cairo*) echo "30.0444,31.2357" ;;                                               # Cairo
                Europe/*) echo "48.8566,2.3522" ;;      # Default to Paris for Europe
                America/*) echo "40.7128,-74.0060" ;;   # Default to New York for Americas
                Australia/*) echo "-33.8688,151.2093" ;; # Default to Sydney for Oceania
                
                # Ultimate fallback (Indonesian coordinates)
                *) echo "-6.2349,106.9896" ;;           # Jakarta/Bekasi fallback
            esac
            
            debug_log "Auto-detection completed successfully" "INFO"
            return 0
            ;;
    esac
}