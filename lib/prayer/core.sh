#!/bin/bash

# ============================================================================
# Claude Code Statusline - Islamic Prayer Core Module
# ============================================================================
# 
# This module handles prayer configuration, constants, and API interactions.
# 
# Dependencies: core.sh, security.sh, cache.sh, config.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_CORE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_CORE_LOADED=true

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
    CONFIG_PRAYER_SHOW_TIME_REMAINING="${ENV_CONFIG_PRAYER_SHOW_TIME_REMAINING:-${CONFIG_PRAYER_SHOW_TIME_REMAINING:-true}}"
    CONFIG_PRAYER_USE_LEGACY_INDICATOR="${ENV_CONFIG_PRAYER_USE_LEGACY_INDICATOR:-${CONFIG_PRAYER_USE_LEGACY_INDICATOR:-false}}"
    CONFIG_PRAYER_NEXT_PRAYER_COLOR_ENABLED="${ENV_CONFIG_PRAYER_NEXT_PRAYER_COLOR_ENABLED:-${CONFIG_PRAYER_NEXT_PRAYER_COLOR_ENABLED:-true}}"
    CONFIG_PRAYER_NEXT_PRAYER_COLOR="${ENV_CONFIG_PRAYER_NEXT_PRAYER_COLOR:-${CONFIG_PRAYER_NEXT_PRAYER_COLOR:-bright_green}}"
    
    # Auto-detection integration
    if [[ "$CONFIG_PRAYER_ENABLED" == "true" ]]; then
        debug_log "Integrating auto-detection with prayer configuration..." "INFO"
        
        case "$CONFIG_PRAYER_LOCATION_MODE" in
            "auto"|"ip_based")
                # Run auto-detection if coordinates are not manually provided
                if [[ -z "$CONFIG_PRAYER_LATITUDE" || -z "$CONFIG_PRAYER_LONGITUDE" ]]; then
                    debug_log "Running auto-detection for location and method..." "INFO"
                    
                    # Attempt to get location coordinates (triggers auto-detection)
                    local auto_coordinates
                    auto_coordinates=$(get_location_coordinates)
                    
                    if [[ -n "$auto_coordinates" && "$auto_coordinates" != "0,0" ]]; then
                        # Parse coordinates if not already set by auto-detection functions
                        if [[ -z "$CONFIG_PRAYER_LATITUDE" || -z "$CONFIG_PRAYER_LONGITUDE" ]]; then
                            CONFIG_PRAYER_LATITUDE="${auto_coordinates%%,*}"
                            CONFIG_PRAYER_LONGITUDE="${auto_coordinates##*,}"
                            debug_log "Auto-detected coordinates applied: $CONFIG_PRAYER_LATITUDE,$CONFIG_PRAYER_LONGITUDE" "INFO"
                        fi
                        
                        # Auto-detect calculation method if not manually set
                        if [[ -z "$CONFIG_PRAYER_CALCULATION_METHOD" || "$CONFIG_PRAYER_CALCULATION_METHOD" == "$DEFAULT_CALCULATION_METHOD" ]]; then
                            # Try timezone-based method detection as fallback
                            local system_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || date +%Z)
                            local detected_method=$(get_prayer_method_from_timezone "$system_tz")
                            CONFIG_PRAYER_CALCULATION_METHOD="$detected_method"
                            debug_log "Auto-detected calculation method: $detected_method" "INFO"
                        fi
                        
                        # Auto-detect timezone if not manually set
                        if [[ -z "$CONFIG_PRAYER_TIMEZONE" ]]; then
                            local system_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
                            if [[ -n "$system_tz" ]]; then
                                CONFIG_PRAYER_TIMEZONE="$system_tz"
                                debug_log "Auto-detected timezone: $system_tz" "INFO"
                            fi
                        fi
                    else
                        debug_log "Auto-detection failed, using configured defaults" "WARN"
                    fi
                else
                    debug_log "Manual coordinates provided, skipping auto-detection" "INFO"
                fi
                ;;
            "manual")
                debug_log "Manual location mode, skipping auto-detection" "INFO"
                ;;
            *)
                debug_log "Unknown location mode: $CONFIG_PRAYER_LOCATION_MODE" "WARN"
                ;;
        esac
    fi
    
    debug_log "Prayer configuration completed - Enabled: $CONFIG_PRAYER_ENABLED, Method: $CONFIG_PRAYER_CALCULATION_METHOD, Mode: $CONFIG_PRAYER_LOCATION_MODE" "INFO"
}

# ============================================================================
# API INTERACTION WITH RETRY LOGIC
# ============================================================================

# Enhanced API call with exponential backoff retry logic
fetch_prayer_data_with_retry() {
    local date="$1"
    local latitude="$2"
    local longitude="$3"
    local max_attempts=3
    local base_delay=1
    
    debug_log "Fetching prayer data with retry logic for: $date, coordinates: $latitude,$longitude" "INFO"
    
    for attempt in $(seq 1 $max_attempts); do
        debug_log "API attempt $attempt/$max_attempts" "INFO"
        
        if result=$(fetch_prayer_data_single "$date" "$latitude" "$longitude"); then
            debug_log "API request succeeded on attempt $attempt" "INFO"
            echo "$result"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            local delay=$((base_delay * (2 ** (attempt - 1))))
            debug_log "API request failed, retrying in ${delay}s..." "WARN"
            sleep "$delay"
        fi
    done
    
    debug_log "All API attempts failed" "ERROR"
    return 1
}

# Single API request (original logic)
fetch_prayer_data_single() {
    local date="$1"
    local latitude="$2"
    local longitude="$3"
    
    debug_log "Making single API request for date: $date, coordinates: $latitude,$longitude" "INFO"
    
    # Build API URL
    local api_url="${ALADHAN_API_BASE}${ALADHAN_TIMINGS_ENDPOINT}/${date}"
    api_url="${api_url}?latitude=${latitude}&longitude=${longitude}"
    api_url="${api_url}&method=${CONFIG_PRAYER_CALCULATION_METHOD}"
    api_url="${api_url}&school=${CONFIG_PRAYER_MADHAB}"
    
    if [[ -n "$CONFIG_PRAYER_TIMEZONE" ]]; then
        api_url="${api_url}&timezonestring=${CONFIG_PRAYER_TIMEZONE}"
    fi
    
    debug_log "API URL: $api_url" "DEBUG"
    
    if ! command_exists curl; then
        debug_log "curl not available for API requests" "ERROR"
        return 1
    fi
    
    # Make API request with shorter timeout for better retry behavior
    local response
    response=$(curl -s --max-time 5 --connect-timeout 3 \
        -H "User-Agent: Claude-Code-Statusline/2.4.0" \
        "$api_url" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$response" ]]; then
        debug_log "API request failed or returned empty response" "WARN"
        return 1
    fi
    
    # Validate JSON response
    if ! command_exists jq; then
        debug_log "jq not available for JSON parsing" "ERROR"
        return 1
    fi
    
    # Check API response status
    local status_code=$(echo "$response" | jq -r '.code // "error"' 2>/dev/null)
    if [[ "$status_code" != "200" ]]; then
        debug_log "API returned error status: $status_code" "WARN"
        return 1
    fi
    
    echo "$response"
    return 0
}

# Backward compatibility wrapper (uses retry logic)
fetch_prayer_data() {
    fetch_prayer_data_with_retry "$@"
}