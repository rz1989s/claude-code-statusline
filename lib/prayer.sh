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
# LOCATION DETECTION & PRAYER METHOD MAPPING
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
        -H "User-Agent: Claude-Code-Statusline/2.2.0" \
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

# Map country code to prayer calculation method
get_method_from_country_code() {
    local country_code="${1^^}"  # Convert to uppercase
    
    case "$country_code" in
        # Southeast Asia
        ID) echo "20" ;;  # Indonesia → KEMENAG
        MY) echo "17" ;;  # Malaysia → JAKIM  
        SG) echo "11" ;;  # Singapore → MUIS
        BN) echo "17" ;;  # Brunei → JAKIM (similar to Malaysia)
        
        # South Asia  
        PK) echo "1" ;;   # Pakistan → Karachi
        BD) echo "1" ;;   # Bangladesh → Karachi
        IN) echo "1" ;;   # India → Karachi
        AF) echo "1" ;;   # Afghanistan → Karachi
        MV) echo "1" ;;   # Maldives → Karachi
        LK) echo "1" ;;   # Sri Lanka → Karachi
        
        # Middle East & Gulf
        SA) echo "4" ;;   # Saudi Arabia → Umm al-Qura
        AE) echo "16" ;;  # UAE → Dubai
        KW) echo "9" ;;   # Kuwait → Kuwait
        QA) echo "10" ;;  # Qatar → Qatar
        BH) echo "4" ;;   # Bahrain → Umm al-Qura
        OM) echo "4" ;;   # Oman → Umm al-Qura
        IQ) echo "9" ;;   # Iraq → Kuwait (geographically close)
        IR) echo "7" ;;   # Iran → Tehran
        TR) echo "13" ;;  # Turkey → Diyanet
        
        # Levant
        SY) echo "5" ;;   # Syria → Egyptian
        JO) echo "5" ;;   # Jordan → Egyptian
        LB) echo "5" ;;   # Lebanon → Egyptian
        PS) echo "5" ;;   # Palestine → Egyptian
        YE) echo "4" ;;   # Yemen → Umm al-Qura
        
        # Central Asia
        UZ) echo "3" ;;   # Uzbekistan → MWL
        KZ) echo "3" ;;   # Kazakhstan → MWL
        KG) echo "3" ;;   # Kyrgyzstan → MWL
        TJ) echo "3" ;;   # Tajikistan → MWL
        TM) echo "3" ;;   # Turkmenistan → MWL
        AZ) echo "3" ;;   # Azerbaijan → MWL
        
        # North Africa
        EG) echo "5" ;;   # Egypt → Egyptian
        DZ) echo "22" ;;  # Algeria → Algeria
        MA) echo "23" ;;  # Morocco → Morocco
        TN) echo "21" ;;  # Tunisia → Tunisia
        LY) echo "5" ;;   # Libya → Egyptian
        SD) echo "5" ;;   # Sudan → Egyptian
        SO) echo "5" ;;   # Somalia → Egyptian
        DJ) echo "5" ;;   # Djibouti → Egyptian
        ER) echo "5" ;;   # Eritrea → Egyptian
        
        # Sub-Saharan Africa
        NG) echo "5" ;;   # Nigeria → Egyptian
        SN) echo "3" ;;   # Senegal → MWL
        ML) echo "3" ;;   # Mali → MWL
        NE) echo "3" ;;   # Niger → MWL
        MR) echo "3" ;;   # Mauritania → MWL
        TD) echo "3" ;;   # Chad → MWL
        ET) echo "5" ;;   # Ethiopia → Egyptian
        KE) echo "5" ;;   # Kenya → Egyptian
        TZ) echo "5" ;;   # Tanzania → Egyptian
        UG) echo "5" ;;   # Uganda → Egyptian
        
        # Europe
        RU) echo "14" ;;  # Russia → Spiritual Admin
        FR) echo "12" ;;  # France → UOIF
        GB) echo "3" ;;   # UK → MWL
        DE) echo "3" ;;   # Germany → MWL
        IT) echo "3" ;;   # Italy → MWL
        ES) echo "3" ;;   # Spain → MWL
        NL) echo "3" ;;   # Netherlands → MWL
        BE) echo "3" ;;   # Belgium → MWL
        BA) echo "3" ;;   # Bosnia → MWL
        AL) echo "3" ;;   # Albania → MWL
        XK) echo "3" ;;   # Kosovo → MWL
        MK) echo "3" ;;   # North Macedonia → MWL
        
        # Americas
        US) echo "2" ;;   # USA → ISNA
        CA) echo "2" ;;   # Canada → ISNA
        BR) echo "3" ;;   # Brazil → MWL
        AR) echo "3" ;;   # Argentina → MWL
        MX) echo "2" ;;   # Mexico → ISNA
        
        # Oceania
        AU) echo "3" ;;   # Australia → MWL
        NZ) echo "3" ;;   # New Zealand → MWL
        
        # Default fallback
        *) echo "3" ;;    # Unknown → MWL (safe worldwide)
    esac
}

# Cache location data
cache_location_data() {
    local location_data="$1"
    local cache_dir="${STATUSLINE_CACHE_DIR:-${HOME}/.cache/claude-code-statusline}"
    local cache_file="$cache_dir/location_auto_detect.cache"
    
    if [[ -z "$location_data" ]]; then
        debug_log "No location data provided for caching" "WARN"
        return 1
    fi
    
    # Create cache directory if it doesn't exist
    if ! mkdir -p "$cache_dir" 2>/dev/null; then
        debug_log "Failed to create cache directory: $cache_dir" "WARN"
        return 1
    fi
    
    # Write location data to cache file with atomic operation
    if echo "$location_data" > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file"; then
        chmod 600 "$cache_file" 2>/dev/null  # Secure permissions
        debug_log "Location data cached successfully: $cache_file" "INFO"
        return 0
    else
        debug_log "Failed to cache location data" "WARN"
        rm -f "${cache_file}.tmp" 2>/dev/null
        return 1
    fi
}

# Load cached location data
load_cached_location() {
    local cache_dir="${STATUSLINE_CACHE_DIR:-${HOME}/.cache/claude-code-statusline}"
    local cache_file="$cache_dir/location_auto_detect.cache"
    local cache_duration_seconds=604800  # 7 days
    
    if [[ ! -f "$cache_file" ]]; then
        debug_log "No cached location data found" "INFO"
        return 1
    fi
    
    # Check cache age
    if command_exists stat; then
        local file_age
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS stat format
            file_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) ))
        else
            # Linux stat format  
            file_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        fi
        
        if [[ $file_age -gt $cache_duration_seconds ]]; then
            debug_log "Cached location data is too old (${file_age}s), ignoring" "INFO"
            return 1
        fi
        
        debug_log "Using cached location data (age: ${file_age}s)" "INFO"
    fi
    
    # Load and validate cached data
    local cached_data
    if cached_data=$(cat "$cache_file" 2>/dev/null) && [[ -n "$cached_data" ]]; then
        if command_exists jq && echo "$cached_data" | jq . > /dev/null 2>&1; then
            apply_location_config "$cached_data"
            debug_log "Cached location data loaded successfully" "INFO"
            return 0
        else
            debug_log "Cached location data is corrupted, ignoring" "WARN"
            rm -f "$cache_file" 2>/dev/null
            return 1
        fi
    else
        debug_log "Failed to read cached location data" "WARN"
        return 1
    fi
}

# Apply location configuration from API data
apply_location_config() {
    local location_data="$1"
    
    if [[ -z "$location_data" ]] || ! command_exists jq; then
        debug_log "Cannot apply location config: missing data or jq" "WARN"
        return 1
    fi
    
    # Extract location information
    local country_code=$(echo "$location_data" | jq -r '.countryCode // "XX"' 2>/dev/null)
    local latitude=$(echo "$location_data" | jq -r '.latitude // 0' 2>/dev/null)
    local longitude=$(echo "$location_data" | jq -r '.longitude // 0' 2>/dev/null)
    local timezone=$(echo "$location_data" | jq -r '.timezone // "UTC"' 2>/dev/null)
    local city=$(echo "$location_data" | jq -r '.city // "Unknown"' 2>/dev/null)
    local country=$(echo "$location_data" | jq -r '.country // "Unknown"' 2>/dev/null)
    
    # Get appropriate prayer method for country
    local detected_method=$(get_method_from_country_code "$country_code")
    
    # Apply configuration if not manually overridden
    if [[ -z "$CONFIG_PRAYER_CALCULATION_METHOD" || "$CONFIG_PRAYER_CALCULATION_METHOD" == "$DEFAULT_CALCULATION_METHOD" ]]; then
        CONFIG_PRAYER_CALCULATION_METHOD="$detected_method"
        debug_log "Auto-detected prayer method: $detected_method for $country ($country_code)" "INFO"
    fi
    
    if [[ -z "$CONFIG_PRAYER_LATITUDE" && -z "$CONFIG_PRAYER_LONGITUDE" ]]; then
        CONFIG_PRAYER_LATITUDE="$latitude"
        CONFIG_PRAYER_LONGITUDE="$longitude"
        debug_log "Auto-detected coordinates: $latitude,$longitude ($city, $country)" "INFO"
    fi
    
    if [[ -z "$CONFIG_PRAYER_TIMEZONE" ]]; then
        CONFIG_PRAYER_TIMEZONE="$timezone"
        debug_log "Auto-detected timezone: $timezone" "INFO"
    fi
    
    debug_log "Location configuration applied for $city, $country" "INFO"
    return 0
}

# Get prayer calculation method from system timezone
# Covers 98% of global Muslim population (2+ billion Muslims)
get_prayer_method_from_timezone() {
    local timezone="${1:-$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || date +%Z)}"
    local default_method="3"  # Muslim World League (safe worldwide default)
    
    debug_log "Mapping timezone '$timezone' to prayer calculation method..." "INFO"
    
    # ========================================================================
    # TIER 1: EXACT TIMEZONE MAPPINGS (Major Islamic Countries)
    # Covers 1.8+ billion Muslims with precise method selection
    # ========================================================================
    
    case "$timezone" in
        # === SOUTHEAST ASIA (450M Muslims) ===
        Asia/Jakarta|Asia/Pontianak|Asia/Makassar|Asia/Jayapura)
            # Indonesia - 231M Muslims
            echo "20"  # KEMENAG (Kementerian Agama RI)
            debug_log "Indonesia detected → KEMENAG method (20)" "INFO"
            return 0
            ;;
        Asia/Kuala_Lumpur|Asia/Kuching)
            # Malaysia - 20M Muslims  
            echo "17"  # JAKIM (Jabatan Kemajuan Islam Malaysia)
            debug_log "Malaysia detected → JAKIM method (17)" "INFO"
            return 0
            ;;
        Asia/Singapore)
            # Singapore - 0.9M Muslims
            echo "11"  # MUIS (Majlis Ugama Islam Singapura)
            debug_log "Singapore detected → MUIS method (11)" "INFO"
            return 0
            ;;
            
        # === SOUTH ASIA (620M Muslims) ===
        Asia/Karachi)
            # Pakistan - 225M Muslims
            echo "1"   # University of Islamic Sciences, Karachi
            debug_log "Pakistan detected → Karachi method (1)" "INFO"
            return 0
            ;;
        Asia/Dhaka)
            # Bangladesh - 153M Muslims
            echo "1"   # University of Islamic Sciences, Karachi
            debug_log "Bangladesh detected → Karachi method (1)" "INFO"
            return 0
            ;;
        Asia/Kolkata|Asia/Delhi|Asia/Mumbai|Asia/Chennai|Asia/Bangalore)
            # India - 195M Muslims
            echo "1"   # University of Islamic Sciences, Karachi
            debug_log "India detected → Karachi method (1)" "INFO"
            return 0
            ;;
        Asia/Kabul)
            # Afghanistan - 38M Muslims
            echo "1"   # University of Islamic Sciences, Karachi
            debug_log "Afghanistan detected → Karachi method (1)" "INFO"
            return 0
            ;;
            
        # === MIDDLE EAST & GULF (120M Muslims) ===
        Asia/Riyadh|Asia/Jeddah|Asia/Dammam)
            # Saudi Arabia - 31M Muslims
            echo "4"   # Umm al-Qura, Makkah
            debug_log "Saudi Arabia detected → Umm al-Qura method (4)" "INFO"
            return 0
            ;;
        Asia/Dubai|Asia/Abu_Dhabi|Asia/Sharjah)
            # UAE - 7M Muslims
            echo "16"  # Dubai method
            debug_log "UAE detected → Dubai method (16)" "INFO"
            return 0
            ;;
        Asia/Kuwait)
            # Kuwait - 3M Muslims
            echo "9"   # Kuwait method
            debug_log "Kuwait detected → Kuwait method (9)" "INFO"
            return 0
            ;;
        Asia/Qatar|Asia/Doha)
            # Qatar - 2M Muslims
            echo "10"  # Qatar method
            debug_log "Qatar detected → Qatar method (10)" "INFO"
            return 0
            ;;
        Asia/Bahrain|Asia/Manama)
            # Bahrain - 1M Muslims
            echo "4"   # Umm al-Qura
            debug_log "Bahrain detected → Umm al-Qura method (4)" "INFO"
            return 0
            ;;
        Asia/Muscat)
            # Oman - 4M Muslims
            echo "4"   # Umm al-Qura
            debug_log "Oman detected → Umm al-Qura method (4)" "INFO"
            return 0
            ;;
        Asia/Baghdad)
            # Iraq - 38M Muslims
            echo "9"   # Kuwait method (geographically close)
            debug_log "Iraq detected → Kuwait method (9)" "INFO"
            return 0
            ;;
        Asia/Tehran)
            # Iran - 82M Muslims
            echo "7"   # Institute of Geophysics, University of Tehran
            debug_log "Iran detected → Tehran method (7)" "INFO"
            return 0
            ;;
        Asia/Istanbul|Europe/Istanbul)
            # Turkey - 79M Muslims
            echo "13"  # Diyanet İşleri Başkanlığı
            debug_log "Turkey detected → Diyanet method (13)" "INFO"
            return 0
            ;;
            
        # === LEVANT & MESOPOTAMIA (80M Muslims) ===
        Asia/Damascus)
            # Syria - 18M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Syria detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Asia/Amman)
            # Jordan - 10M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Jordan detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Asia/Beirut)
            # Lebanon - 3M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Lebanon detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Asia/Jerusalem|Asia/Gaza|Asia/Hebron)
            # Palestine - 5M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Palestine detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Asia/Aden)
            # Yemen - 28M Muslims
            echo "4"   # Umm al-Qura
            debug_log "Yemen detected → Umm al-Qura method (4)" "INFO"
            return 0
            ;;
            
        # === CENTRAL ASIA (50M Muslims) ===
        Asia/Tashkent|Asia/Samarkand)
            # Uzbekistan - 30M Muslims
            echo "3"   # Muslim World League
            debug_log "Uzbekistan detected → MWL method (3)" "INFO"
            return 0
            ;;
        Asia/Almaty|Asia/Aqtau|Asia/Bishkek)
            # Kazakhstan/Kyrgyzstan - 15M Muslims
            echo "3"   # Muslim World League
            debug_log "Central Asia detected → MWL method (3)" "INFO"
            return 0
            ;;
        Asia/Baku)
            # Azerbaijan - 9M Muslims
            echo "3"   # Muslim World League
            debug_log "Azerbaijan detected → MWL method (3)" "INFO"
            return 0
            ;;
            
        # === NORTH AFRICA (280M Muslims) ===
        Africa/Cairo|Africa/Alexandria)
            # Egypt - 87M Muslims
            echo "5"   # Egyptian General Authority of Survey
            debug_log "Egypt detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Africa/Lagos|Africa/Abuja|Africa/Kano)
            # Nigeria - 99M Muslims
            echo "5"   # Egyptian General Authority (widely used in Africa)
            debug_log "Nigeria detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Africa/Algiers)
            # Algeria - 43M Muslims
            echo "22"  # Algeria method
            debug_log "Algeria detected → Algeria method (22)" "INFO"
            return 0
            ;;
        Africa/Casablanca|Africa/Rabat)
            # Morocco - 37M Muslims
            echo "23"  # Morocco method
            debug_log "Morocco detected → Morocco method (23)" "INFO"
            return 0
            ;;
        Africa/Khartoum)
            # Sudan - 39M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Sudan detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Africa/Tunis)
            # Tunisia - 12M Muslims
            echo "21"  # Tunisia method
            debug_log "Tunisia detected → Tunisia method (21)" "INFO"
            return 0
            ;;
        Africa/Tripoli)
            # Libya - 7M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Libya detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Africa/Mogadishu)
            # Somalia - 11M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Somalia detected → Egyptian method (5)" "INFO"
            return 0
            ;;
            
        # === SUB-SAHARAN AFRICA (200M Muslims) ===
        Africa/Dakar)
            # Senegal - 16M Muslims
            echo "3"   # Muslim World League
            debug_log "Senegal detected → MWL method (3)" "INFO"
            return 0
            ;;
        Africa/Bamako)
            # Mali - 18M Muslims
            echo "3"   # Muslim World League
            debug_log "Mali detected → MWL method (3)" "INFO"
            return 0
            ;;
        Africa/Niamey)
            # Niger - 21M Muslims
            echo "3"   # Muslim World League
            debug_log "Niger detected → MWL method (3)" "INFO"
            return 0
            ;;
        Africa/Nouakchott)
            # Mauritania - 4M Muslims
            echo "3"   # Muslim World League
            debug_log "Mauritania detected → MWL method (3)" "INFO"
            return 0
            ;;
        Africa/Ndjamena)
            # Chad - 8M Muslims
            echo "3"   # Muslim World League
            debug_log "Chad detected → MWL method (3)" "INFO"
            return 0
            ;;
        Africa/Addis_Ababa)
            # Ethiopia - 35M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Ethiopia detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Africa/Nairobi)
            # Kenya - 5M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Kenya detected → Egyptian method (5)" "INFO"
            return 0
            ;;
        Africa/Dar_es_Salaam)
            # Tanzania - 20M Muslims
            echo "5"   # Egyptian General Authority
            debug_log "Tanzania detected → Egyptian method (5)" "INFO"
            return 0
            ;;
            
        # === EUROPE (60M Muslims) ===
        Europe/Moscow|Europe/Volgograd)
            # Russia - 20M Muslims
            echo "14"  # Spiritual Administration of Muslims of Russia
            debug_log "Russia detected → Spiritual Admin method (14)" "INFO"
            return 0
            ;;
        Europe/Paris)
            # France - 6M Muslims
            echo "12"  # Union of Islamic Organizations of France
            debug_log "France detected → UOIF method (12)" "INFO"
            return 0
            ;;
        Europe/London)
            # UK - 3M Muslims
            echo "3"   # Muslim World League
            debug_log "UK detected → MWL method (3)" "INFO"
            return 0
            ;;
        Europe/Berlin)
            # Germany - 5M Muslims
            echo "3"   # Muslim World League
            debug_log "Germany detected → MWL method (3)" "INFO"
            return 0
            ;;
        Europe/Rome)
            # Italy - 2M Muslims
            echo "3"   # Muslim World League
            debug_log "Italy detected → MWL method (3)" "INFO"
            return 0
            ;;
        Europe/Madrid)
            # Spain - 2M Muslims
            echo "3"   # Muslim World League
            debug_log "Spain detected → MWL method (3)" "INFO"
            return 0
            ;;
        Europe/Amsterdam|Europe/Brussels)
            # Netherlands/Belgium - 2M Muslims
            echo "3"   # Muslim World League
            debug_log "Netherlands/Belgium detected → MWL method (3)" "INFO"
            return 0
            ;;
        Europe/Sarajevo)
            # Bosnia - 2M Muslims
            echo "3"   # Muslim World League
            debug_log "Bosnia detected → MWL method (3)" "INFO"
            return 0
            ;;
        Europe/Tirana)
            # Albania - 2M Muslims
            echo "3"   # Muslim World League
            debug_log "Albania detected → MWL method (3)" "INFO"
            return 0
            ;;
        Europe/Pristina)
            # Kosovo - 2M Muslims
            echo "3"   # Muslim World League
            debug_log "Kosovo detected → MWL method (3)" "INFO"
            return 0
            ;;
            
        # === AMERICAS & OCEANIA (15M Muslims) ===
        America/New_York|America/Chicago|America/Los_Angeles|America/Denver|America/Phoenix)
            # USA - 3.5M Muslims
            echo "2"   # Islamic Society of North America
            debug_log "USA detected → ISNA method (2)" "INFO"
            return 0
            ;;
        America/Toronto|America/Vancouver|America/Montreal)
            # Canada - 1.5M Muslims
            echo "2"   # Islamic Society of North America
            debug_log "Canada detected → ISNA method (2)" "INFO"
            return 0
            ;;
        America/Sao_Paulo|America/Argentina/Buenos_Aires|America/Lima|America/Bogota)
            # South America - 1M Muslims
            echo "3"   # Muslim World League
            debug_log "South America detected → MWL method (3)" "INFO"
            return 0
            ;;
        Australia/Sydney|Australia/Melbourne|Australia/Perth|Australia/Brisbane)
            # Australia - 0.6M Muslims
            echo "3"   # Muslim World League
            debug_log "Australia detected → MWL method (3)" "INFO"
            return 0
            ;;
            
        # ====================================================================
        # TIER 2: PATTERN-BASED REGIONAL MAPPING
        # Handles variations and alternative timezone names
        # ====================================================================
        
        *)
            # Extract continent and region for pattern matching
            local continent="${timezone%%/*}"
            local region="${timezone#*/}"
            
            case "$continent" in
                Asia)
                    # Asian Muslim regions
                    if [[ "$region" =~ ^(Jakarta|Medan|Surabaya|Makassar|Bandung|Yogyakarta|Semarang|Palembang|Tangerang|Bekasi|Depok|Bogor|Batam|Pekanbaru|Bandar_Lampung) ]]; then
                        echo "20"  # Indonesian cities → KEMENAG
                        debug_log "Indonesian region '$region' detected → KEMENAG method (20)" "INFO"
                        return 0
                    elif [[ "$region" =~ ^(Karachi|Lahore|Islamabad|Faisalabad|Rawalpindi|Multan|Peshawar|Quetta|Sialkot) ]]; then
                        echo "1"   # Pakistani cities → Karachi
                        debug_log "Pakistani region '$region' detected → Karachi method (1)" "INFO"
                        return 0
                    elif [[ "$region" =~ ^(Dhaka|Chittagong|Sylhet|Rajshahi|Khulna|Rangpur|Mymensingh) ]]; then
                        echo "1"   # Bangladeshi cities → Karachi
                        debug_log "Bangladeshi region '$region' detected → Karachi method (1)" "INFO"
                        return 0
                    elif [[ "$region" =~ ^(Riyadh|Jeddah|Mecca|Medina|Dammam|Khobar|Tabuk|Abha|Hail|Najran) ]]; then
                        echo "4"   # Saudi cities → Umm al-Qura
                        debug_log "Saudi region '$region' detected → Umm al-Qura method (4)" "INFO"
                        return 0
                    else
                        echo "$default_method"  # Generic Asia → MWL
                        debug_log "Generic Asian timezone '$timezone' → MWL fallback (3)" "INFO"
                        return 0
                    fi
                    ;;
                Africa)
                    # African Muslim regions
                    if [[ "$region" =~ ^(Cairo|Alexandria|Giza|Luxor|Aswan|Port_Said|Suez|Mansoura) ]]; then
                        echo "5"   # Egyptian cities → Egyptian
                        debug_log "Egyptian region '$region' detected → Egyptian method (5)" "INFO"
                        return 0
                    else
                        echo "5"   # Generic Africa → Egyptian (widely accepted)
                        debug_log "African timezone '$timezone' → Egyptian fallback (5)" "INFO"
                        return 0
                    fi
                    ;;
                Europe)
                    echo "3"   # Generic Europe → MWL
                    debug_log "European timezone '$timezone' → MWL fallback (3)" "INFO"
                    return 0
                    ;;
                America)
                    if [[ "$region" =~ ^(New_York|Chicago|Los_Angeles|Denver|Phoenix|Detroit|Boston|Atlanta|Dallas|Houston|Philadelphia|Miami|Seattle|San_Francisco) ]]; then
                        echo "2"   # North American cities → ISNA
                        debug_log "North American region '$region' detected → ISNA method (2)" "INFO"
                        return 0
                    else
                        echo "3"   # Generic Americas → MWL
                        debug_log "American timezone '$timezone' → MWL fallback (3)" "INFO"
                        return 0
                    fi
                    ;;
                Australia|Pacific)
                    echo "3"   # Oceania → MWL
                    debug_log "Oceania timezone '$timezone' → MWL fallback (3)" "INFO"
                    return 0
                    ;;
                *)
                    echo "$default_method"  # Unknown continent → safe default
                    debug_log "Unknown timezone '$timezone' → MWL safe fallback (3)" "WARN"
                    return 0
                    ;;
            esac
            ;;
    esac
}

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
        "ip_based")
            # Force IP-based geolocation (requires internet)
            debug_log "Starting IP-based location detection..." "INFO"
            
            if check_internet_connection; then
                local location_data=$(get_ip_location)
                if [[ -n "$location_data" ]]; then
                    cache_location_data "$location_data"
                    apply_location_config "$location_data"
                    
                    # Extract coordinates from location data
                    local latitude=$(echo "$location_data" | jq -r '.latitude // 0' 2>/dev/null)
                    local longitude=$(echo "$location_data" | jq -r '.longitude // 0' 2>/dev/null)
                    echo "$latitude,$longitude"
                    debug_log "IP-based location detection successful" "INFO"
                    return 0
                else
                    debug_log "IP geolocation failed, falling back to cached data" "WARN"
                    if load_cached_location; then
                        echo "$CONFIG_PRAYER_LATITUDE,$CONFIG_PRAYER_LONGITUDE"
                        return 0
                    fi
                fi
            else
                debug_log "No internet connection for IP-based detection" "WARN"
            fi
            
            # Fallback to timezone-based detection
            debug_log "Falling back to timezone-based detection" "INFO"
            ;& # Fall through to auto mode
            ;;
        "auto"|*)
            # Enhanced multi-tier automatic location detection
            debug_log "Starting comprehensive automatic location detection..." "INFO"
            
            # Tier 1: Try IP geolocation (if online and not already attempted)
            if [[ "$CONFIG_PRAYER_LOCATION_MODE" != "ip_based" ]] && check_internet_connection; then
                local location_data=$(get_ip_location)
                if [[ -n "$location_data" ]]; then
                    cache_location_data "$location_data"
                    apply_location_config "$location_data"
                    
                    # Extract coordinates from location data
                    local latitude=$(echo "$location_data" | jq -r '.latitude // 0' 2>/dev/null)
                    local longitude=$(echo "$location_data" | jq -r '.longitude // 0' 2>/dev/null)
                    echo "$latitude,$longitude"
                    debug_log "IP geolocation successful in auto mode" "INFO"
                    return 0
                else
                    debug_log "IP geolocation failed, continuing with fallback methods" "INFO"
                fi
            fi
            
            # Tier 2: Try cached location data (7-day cache)
            if load_cached_location && [[ -n "$CONFIG_PRAYER_LATITUDE" && -n "$CONFIG_PRAYER_LONGITUDE" ]]; then
                echo "$CONFIG_PRAYER_LATITUDE,$CONFIG_PRAYER_LONGITUDE"
                debug_log "Using cached location data in auto mode" "INFO"
                return 0
            fi
            
            # Tier 3: Timezone-based detection (offline fallback)
            debug_log "Using timezone-based location detection..." "INFO"
            
            # Step 1: Get system timezone
            local system_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || date +%Z)
            debug_log "System timezone detected: $system_tz" "INFO"
            
            # Step 2: Map timezone to prayer method
            local detected_method=$(get_prayer_method_from_timezone "$system_tz")
            debug_log "Detected prayer method: $detected_method for timezone: $system_tz" "INFO"
            
            # Step 3: Override config if not manually set
            if [[ -z "$CONFIG_PRAYER_CALCULATION_METHOD" || "$CONFIG_PRAYER_CALCULATION_METHOD" == "$DEFAULT_CALCULATION_METHOD" ]]; then
                CONFIG_PRAYER_CALCULATION_METHOD="$detected_method"
                debug_log "Auto-updated calculation method to: $detected_method" "INFO"
            fi
            
            # Step 4: Provide region-specific default coordinates based on timezone
            case "$system_tz" in
                # Major Islamic regions with specific coordinates
                Asia/Jakarta|Asia/Pontianak) echo "-6.2088,106.8456" ;;    # Jakarta
                Asia/Makassar) echo "-5.1477,119.4327" ;;                   # Makassar
                Asia/Jayapura) echo "-2.5489,140.7163" ;;                   # Jayapura
                Asia/Kuala_Lumpur) echo "3.1390,101.6869" ;;               # Kuala Lumpur
                Asia/Singapore) echo "1.3521,103.8198" ;;                  # Singapore
                Asia/Karachi) echo "24.8607,67.0011" ;;                    # Karachi
                Asia/Dhaka) echo "23.8103,90.4125" ;;                      # Dhaka
                Asia/Delhi) echo "28.6139,77.2090" ;;                      # Delhi
                Asia/Mumbai) echo "19.0760,72.8777" ;;                     # Mumbai
                Asia/Kolkata) echo "22.5726,88.3639" ;;                    # Kolkata
                Asia/Riyadh) echo "24.7136,46.6753" ;;                     # Riyadh
                Asia/Dubai) echo "25.2048,55.2708" ;;                      # Dubai
                Asia/Kuwait) echo "29.3117,47.4818" ;;                     # Kuwait City
                Asia/Doha) echo "25.2867,51.5333" ;;                       # Doha
                Asia/Tehran) echo "35.6892,51.3890" ;;                     # Tehran
                Asia/Istanbul|Europe/Istanbul) echo "41.0082,28.9784" ;;   # Istanbul
                Asia/Baghdad) echo "33.3152,44.3661" ;;                    # Baghdad
                Asia/Damascus) echo "33.5138,36.2765" ;;                   # Damascus
                Asia/Amman) echo "31.9454,35.9284" ;;                      # Amman
                Africa/Cairo) echo "30.0444,31.2357" ;;                    # Cairo
                Africa/Lagos) echo "6.5244,3.3792" ;;                     # Lagos
                Africa/Algiers) echo "36.7538,3.0588" ;;                  # Algiers
                Africa/Casablanca) echo "33.5731,-7.5898" ;;              # Casablanca
                Africa/Tunis) echo "36.8065,10.1815" ;;                   # Tunis
                Europe/Paris) echo "48.8566,2.3522" ;;                    # Paris
                Europe/London) echo "51.5074,-0.1278" ;;                  # London
                Europe/Moscow) echo "55.7558,37.6176" ;;                  # Moscow
                America/New_York) echo "40.7128,-74.0060" ;;              # New York
                America/Chicago) echo "41.8781,-87.6298" ;;               # Chicago
                America/Los_Angeles) echo "34.0522,-118.2437" ;;          # Los Angeles
                America/Toronto) echo "43.6532,-79.3832" ;;               # Toronto
                Australia/Sydney) echo "-33.8688,151.2093" ;;             # Sydney
                
                # Regional fallbacks based on continent
                Asia/*) echo "-6.2088,106.8456" ;;      # Default to Jakarta for Asia
                Africa/*) echo "30.0444,31.2357" ;;     # Default to Cairo for Africa  
                Europe/*) echo "51.5074,-0.1278" ;;     # Default to London for Europe
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