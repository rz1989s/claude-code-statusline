#!/bin/bash

# ============================================================================
# Claude Code Statusline - Location Display Component
# ============================================================================
#
# This component displays detected location for prayer time calculations
# with VPN-aware detection and transparency indicators.
#
# Dependencies: display.sh, prayer/location.sh, prayer/core.sh
# ============================================================================

# Component data storage
COMPONENT_LOCATION_DISPLAY_CITY=""
COMPONENT_LOCATION_DISPLAY_METHOD=""
COMPONENT_LOCATION_DISPLAY_VPN_STATUS=""
COMPONENT_LOCATION_DISPLAY_CONFIDENCE=""
COMPONENT_LOCATION_DISPLAY_COORDINATES=""

# ============================================================================
# CITY DETECTION FROM COORDINATES
# ============================================================================

# Map coordinates to Indonesian cities
get_city_from_coordinates() {
    local latitude="$1"
    local longitude="$2"

    if [[ -z "$latitude" || -z "$longitude" ]]; then
        echo "Unknown"
        return 1
    fi

    # Convert to float comparison
    local lat_float=$(echo "$latitude" | sed 's/^-//' | bc -l)
    local lon_float=$(echo "$longitude" | bc -l)

    # Indonesian major cities (most precise ranges)
    case "$latitude,$longitude" in
        # Jakarta Metropolitan Area (more precise)
        -6.1[0-9]*,106.8[0-9]*)
            if (( $(echo "$latitude >= -6.20 && $latitude <= -6.17" | bc -l) )) &&
               (( $(echo "$longitude >= 106.82 && $longitude <= 106.86" | bc -l) )); then
                echo "Jakarta"
                return 0
            fi
            ;;
        # Bekasi Area (West Java - your area!)
        -6.2[3-5]*,106.9[7-9]*|-6.2[3-5]*,107.0[0-2]*)
            if (( $(echo "$latitude >= -6.25 && $latitude <= -6.23" | bc -l) )) &&
               (( $(echo "$longitude >= 106.97 && $longitude <= 107.02" | bc -l) )); then
                echo "Bekasi"
                return 0
            fi
            ;;
        # Surabaya (East Java)
        -7.2[4-6]*,112.7[4-7]*)
            if (( $(echo "$latitude >= -7.26 && $latitude <= -7.24" | bc -l) )) &&
               (( $(echo "$longitude >= 112.74 && $longitude <= 112.77" | bc -l) )); then
                echo "Surabaya"
                return 0
            fi
            ;;
        # Bandung (West Java)
        -6.9[0-2]*,107.6[0-2]*)
            echo "Bandung"
            return 0
            ;;
        # Medan (North Sumatra)
        3.5[8-6]*,98.6[6-8]*)
            echo "Medan"
            return 0
            ;;
        # Makassar (South Sulawesi)
        -5.1[4-5]*,119.4[2-4]*)
            echo "Makassar"
            return 0
            ;;
        # Semarang (Central Java)
        -6.9[6-8]*,110.4[1-3]*)
            echo "Semarang"
            return 0
            ;;
        # Palembang (South Sumatra)
        -2.9[7-9]*,104.7[4-6]*)
            echo "Palembang"
            return 0
            ;;
    esac

    # Broader regional detection for Indonesia
    if (( $(echo "$latitude >= -11.0 && $latitude <= 6.0" | bc -l) )) &&
       (( $(echo "$longitude >= 95.0 && $longitude <= 141.0" | bc -l) )); then

        # More specific Java region detection first
        if (( $(echo "$latitude >= -8.0 && $latitude <= -5.0" | bc -l) )) &&
           (( $(echo "$longitude >= 106.0 && $longitude <= 115.0" | bc -l) )); then
            echo "Jakarta"  # Default to Jakarta for central Java region
            return 0
        fi

        # Determine major island/region as fallback
        if (( $(echo "$longitude >= 95.0 && $longitude <= 108.0" | bc -l) )); then
            echo "Jakarta"  # Default to Jakarta even for Sumatra range when unclear
        elif (( $(echo "$longitude >= 106.0 && $longitude <= 115.0" | bc -l) )); then
            echo "Jakarta"  # Java region - default to Jakarta
        elif (( $(echo "$longitude >= 108.0 && $longitude <= 119.0" | bc -l) )); then
            echo "Kalimantan"
        elif (( $(echo "$longitude >= 119.0 && $longitude <= 130.0" | bc -l) )); then
            echo "Sulawesi"
        elif (( $(echo "$longitude >= 130.0 && $longitude <= 141.0" | bc -l) )); then
            echo "Papua"
        else
            echo "Jakarta"  # Default fallback to Jakarta
        fi
        return 0
    fi

    # International cities (major Islamic centers)
    case "$latitude,$longitude" in
        # Malaysia
        3.1[0-4]*,101.6[6-9]*) echo "Kuala Lumpur" ;;
        # Singapore
        1.3[4-6]*,103.8[1-2]*) echo "Singapore" ;;
        # Pakistan
        24.8[5-7]*,67.0[0-1]*) echo "Karachi" ;;
        33.6[7-9]*,73.0[4-5]*) echo "Islamabad" ;;
        # Bangladesh
        23.8[0-1]*,90.4[1-2]*) echo "Dhaka" ;;
        # India
        28.6[1-2]*,77.2[0-1]*) echo "Delhi" ;;
        19.0[7-8]*,72.8[7-8]*) echo "Mumbai" ;;
        # Saudi Arabia
        24.7[1-2]*,46.6[7-8]*) echo "Riyadh" ;;
        21.5[4-5]*,39.1[6-7]*) echo "Jeddah" ;;
        # UAE
        25.2[0-1]*,55.2[7-8]*) echo "Dubai" ;;
        # Turkey
        41.0[0-1]*,28.9[7-8]*) echo "Istanbul" ;;
        # Egypt
        30.0[4-5]*,31.2[3-4]*) echo "Cairo" ;;
        *) echo "Unknown" ;;
    esac
}

# ============================================================================
# VPN DETECTION
# ============================================================================

# Detect if user is using VPN
detect_vpn_status() {
    debug_log "Detecting VPN status..." "INFO"

    # Method 1: Check for known VPN providers via IP info
    if command_exists curl && check_internet_connection; then
        local ip_info
        ip_info=$(curl -s --max-time 5 "http://ip-api.com/json/?fields=isp,org,hosting,proxy" 2>/dev/null)

        if [[ -n "$ip_info" ]] && command_exists jq; then
            local isp=$(echo "$ip_info" | jq -r '.isp // "unknown"' 2>/dev/null)
            local org=$(echo "$ip_info" | jq -r '.org // "unknown"' 2>/dev/null)
            local is_hosting=$(echo "$ip_info" | jq -r '.hosting // false' 2>/dev/null)
            local is_proxy=$(echo "$ip_info" | jq -r '.proxy // false' 2>/dev/null)

            # Check for Cloudflare (1.1.1.1)
            if [[ "$isp" =~ "Cloudflare" ]] || [[ "$org" =~ "Cloudflare" ]]; then
                echo "VPN_CLOUDFLARE"
                return 0
            fi

            # Check for other VPN indicators
            if [[ "$is_hosting" == "true" ]] || [[ "$is_proxy" == "true" ]]; then
                echo "VPN_DATACENTER"
                return 0
            fi

            # Check for common VPN providers
            case "$isp" in
                *"NordVPN"*|*"ExpressVPN"*|*"ProtonVPN"*|*"Surfshark"*)
                    echo "VPN_COMMERCIAL"
                    return 0
                    ;;
                *"DigitalOcean"*|*"AWS"*|*"Google Cloud"*|*"Azure"*)
                    echo "VPN_CLOUD"
                    return 0
                    ;;
            esac
        fi
    fi

    # Method 2: IP/Timezone mismatch detection
    local system_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || date +%Z)

    if [[ -n "$ip_info" ]] && command_exists jq; then
        local ip_country=$(echo "$ip_info" | jq -r '.countryCode // "XX"' 2>/dev/null)
        local tz_country=""

        # Map timezone to country
        case "$system_tz" in
            Asia/Jakarta*) tz_country="ID" ;;
            Asia/Kuala_Lumpur*) tz_country="MY" ;;
            Asia/Singapore*) tz_country="SG" ;;
            Asia/Karachi*) tz_country="PK" ;;
            Asia/Dhaka*) tz_country="BD" ;;
            Asia/Kolkata*|Asia/Delhi*) tz_country="IN" ;;
            Asia/Riyadh*) tz_country="SA" ;;
            Asia/Dubai*) tz_country="AE" ;;
            Asia/Istanbul*|Europe/Istanbul*) tz_country="TR" ;;
            Africa/Cairo*) tz_country="EG" ;;
            America/*) tz_country="US" ;;
            Europe/*) tz_country="GB" ;;
            *) tz_country="XX" ;;
        esac

        if [[ "$ip_country" != "$tz_country" && "$tz_country" != "XX" ]]; then
            echo "VPN_MISMATCH"
            return 0
        fi
    fi

    echo "NO_VPN"
    return 1
}

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect location display data
collect_location_display_data() {
    debug_log "Collecting location_display component data" "INFO"

    # Get VPN status
    COMPONENT_LOCATION_DISPLAY_VPN_STATUS=$(detect_vpn_status)

    # Get location coordinates with VPN awareness
    local coordinates
    if [[ "$COMPONENT_LOCATION_DISPLAY_VPN_STATUS" =~ ^VPN_ ]]; then
        debug_log "VPN detected, using VPN-aware location detection" "INFO"
        # Use timezone-based location for VPN users
        local system_tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || date +%Z)
        case "$system_tz" in
            Asia/Jakarta*) coordinates="-6.2088,106.8456" ;;  # Jakarta center
            Asia/Kuala_Lumpur*) coordinates="3.1390,101.6869" ;;
            Asia/Singapore*) coordinates="1.3521,103.8198" ;;
            Asia/Karachi*) coordinates="24.8607,67.0011" ;;
            Asia/Dhaka*) coordinates="23.8103,90.4125" ;;
            Asia/Kolkata*) coordinates="28.6139,77.2090" ;;
            Asia/Riyadh*) coordinates="24.7136,46.6753" ;;
            Asia/Dubai*) coordinates="25.2048,55.2708" ;;
            *) coordinates="-6.2088,106.8456" ;;  # Default to Jakarta
        esac
        COMPONENT_LOCATION_DISPLAY_METHOD="timezone_fallback"
        COMPONENT_LOCATION_DISPLAY_CONFIDENCE="75"
    else
        # Use IP geolocation for non-VPN users
        if type get_location_coordinates &>/dev/null; then
            coordinates=$(get_location_coordinates)
            COMPONENT_LOCATION_DISPLAY_METHOD="ip_geolocation"
            COMPONENT_LOCATION_DISPLAY_CONFIDENCE="90"
        else
            # Fallback to Jakarta
            coordinates="-6.2088,106.8456"
            COMPONENT_LOCATION_DISPLAY_METHOD="fallback"
            COMPONENT_LOCATION_DISPLAY_CONFIDENCE="50"
        fi
    fi

    COMPONENT_LOCATION_DISPLAY_COORDINATES="$coordinates"

    # Extract city from coordinates
    local latitude="${coordinates%%,*}"
    local longitude="${coordinates##*,}"
    COMPONENT_LOCATION_DISPLAY_CITY=$(get_city_from_coordinates "$latitude" "$longitude")

    debug_log "location_display data: city=$COMPONENT_LOCATION_DISPLAY_CITY, method=$COMPONENT_LOCATION_DISPLAY_METHOD, vpn=$COMPONENT_LOCATION_DISPLAY_VPN_STATUS, confidence=$COMPONENT_LOCATION_DISPLAY_CONFIDENCE" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render location display
render_location_display() {
    local display_format
    display_format=$(get_location_display_config "format" "short")

    local show_vpn_indicator
    show_vpn_indicator=$(get_location_display_config "show_vpn_indicator" "true")

    local show_confidence
    show_confidence=$(get_location_display_config "show_confidence" "false")

    # Build base display
    local location_text="📍 Loc: ${COMPONENT_LOCATION_DISPLAY_CITY}"

    # Add format variations
    case "$display_format" in
        "full")
            case "$COMPONENT_LOCATION_DISPLAY_CITY" in
                "Jakarta") location_text="📍 Loc: Jakarta, DKI Jakarta, Indonesia" ;;
                "Bekasi") location_text="📍 Loc: Bekasi, West Java, Indonesia" ;;
                "Surabaya") location_text="📍 Loc: Surabaya, East Java, Indonesia" ;;
                "Bandung") location_text="📍 Loc: Bandung, West Java, Indonesia" ;;
                *) location_text="📍 Loc: ${COMPONENT_LOCATION_DISPLAY_CITY}" ;;
            esac
            ;;
        "short"|*)
            location_text="📍 Loc: ${COMPONENT_LOCATION_DISPLAY_CITY}"
            ;;
    esac

    # Add VPN indicator
    if [[ "$show_vpn_indicator" == "true" && "$COMPONENT_LOCATION_DISPLAY_VPN_STATUS" =~ ^VPN_ ]]; then
        case "$COMPONENT_LOCATION_DISPLAY_VPN_STATUS" in
            "VPN_CLOUDFLARE") location_text="${location_text} (VPN)" ;;
            "VPN_COMMERCIAL") location_text="${location_text} (VPN)" ;;
            "VPN_DATACENTER") location_text="${location_text} (Proxy)" ;;
            "VPN_MISMATCH") location_text="${location_text} (VPN detected)" ;;
            *) location_text="${location_text} (VPN)" ;;
        esac
    fi

    # Add confidence indicator
    if [[ "$show_confidence" == "true" ]]; then
        location_text="${location_text} [${COMPONENT_LOCATION_DISPLAY_CONFIDENCE}%]"
    fi

    # Add method indicator for debugging (only if debug enabled)
    if [[ "${STATUSLINE_DEBUG:-}" == "true" ]]; then
        location_text="${location_text} (${COMPONENT_LOCATION_DISPLAY_METHOD})"
    fi

    echo "$location_text"
    return 0
}

# ============================================================================
# COMPONENT CONFIGURATION
# ============================================================================

# Get component configuration
get_location_display_config() {
    local config_key="$1"
    local default_value="$2"

    case "$config_key" in
        "enabled")
            get_component_config "location_display" "enabled" "${default_value:-true}"
            ;;
        "format")
            # short, full
            get_component_config "location_display" "format" "${default_value:-short}"
            ;;
        "show_vpn_indicator")
            get_component_config "location_display" "show_vpn_indicator" "${default_value:-true}"
            ;;
        "show_confidence")
            get_component_config "location_display" "show_confidence" "${default_value:-false}"
            ;;
        "icon")
            get_component_config "location_display" "icon" "${default_value:-📍}"
            ;;
        *)
            echo "$default_value"
            ;;
    esac
}

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register the location_display component
register_component \
    "location_display" \
    "Location detection display with VPN awareness" \
    "prayer/location,display" \
    "$(get_location_display_config 'enabled' 'true')"

debug_log "Location display component loaded" "INFO"