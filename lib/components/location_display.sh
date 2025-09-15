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

# Map coordinates to worldwide Islamic centers
get_city_from_coordinates() {
    local latitude="$1"
    local longitude="$2"

    if [[ -z "$latitude" || -z "$longitude" ]]; then
        echo "Unknown"
        return 1
    fi

    # Precise coordinate matching using pattern matching (most efficient)
    # Format: latitude range, longitude range -> city

    # === SOUTHEAST ASIA (450M Muslims) ===
    case "$latitude,$longitude" in
        # Indonesia (231M Muslims)
        -6.1[7-2]*,106.8[2-6]*|-6.2[0-1]*,106.8[3-5]*) echo "Jakarta"; return 0 ;;          # Jakarta Metro
        -6.2[3-5]*,106.9[7-9]*|-6.2[3-5]*,107.0[0-2]*) echo "Bekasi"; return 0 ;;  # Bekasi/East Jakarta
        -7.2[4-6]*,112.7[4-7]*) echo "Surabaya"; return 0 ;;         # Surabaya
        -6.9[0-2]*,107.6[0-2]*) echo "Bandung"; return 0 ;;          # Bandung
        3.5[8-6]*,98.6[6-8]*) echo "Medan"; return 0 ;;              # Medan
        -5.1[4-5]*,119.4[2-4]*) echo "Makassar"; return 0 ;;         # Makassar
        -6.9[6-8]*,110.4[1-3]*) echo "Semarang"; return 0 ;;         # Semarang
        -2.9[7-9]*,104.7[4-6]*) echo "Palembang"; return 0 ;;        # Palembang
        -0.8[8-9]*,100.3[4-6]*) echo "Padang"; return 0 ;;           # Padang
        -7.7[7-8]*,110.3[7-8]*) echo "Yogyakarta"; return 0 ;;       # Yogyakarta

        # Malaysia (20M Muslims)
        3.1[2-4]*,101.6[6-9]*) echo "Kuala Lumpur"; return 0 ;;      # KL Metro
        5.4[0-2]*,100.3[2-4]*) echo "George Town"; return 0 ;;       # Penang
        1.4[8-5]*,103.7[4-6]*) echo "Johor Bahru"; return 0 ;;       # Johor
        1.5[4-6]*,110.3[4-6]*) echo "Kuching"; return 0 ;;           # Sarawak

        # Singapore (0.9M Muslims)
        1.3[4-6]*,103.8[1-2]*) echo "Singapore"; return 0 ;;

        # Brunei (0.4M Muslims)
        4.9[0-1]*,114.9[4-5]*) echo "Bandar Seri Begawan"; return 0 ;;
    esac

    # === SOUTH ASIA (620M Muslims) ===
    case "$latitude,$longitude" in
        # Pakistan (225M Muslims)
        24.8[5-9]*,67.0[0-2]*) echo "Karachi"; return 0 ;;           # Karachi Metro
        31.5[2-6]*,74.3[4-6]*) echo "Lahore"; return 0 ;;            # Lahore
        33.6[6-8]*,73.0[4-6]*) echo "Islamabad"; return 0 ;;         # Capital
        31.4[0-2]*,73.0[6-8]*) echo "Faisalabad"; return 0 ;;        # Faisalabad
        30.1[8-2]*,71.4[4-6]*) echo "Multan"; return 0 ;;            # Multan
        25.3[8-4]*,68.3[5-7]*) echo "Hyderabad"; return 0 ;;         # Hyderabad (PK)

        # Bangladesh (153M Muslims)
        23.8[0-1]*,90.4[0-2]*) echo "Dhaka"; return 0 ;;             # Dhaka Metro
        22.3[4-6]*,91.8[2-4]*) echo "Chittagong"; return 0 ;;        # Chittagong
        24.3[6-8]*,88.6[0-2]*) echo "Rajshahi"; return 0 ;;          # Rajshahi

        # India (195M Muslims)
        28.6[1-2]*,77.2[0-1]*) echo "Delhi"; return 0 ;;             # Delhi NCR
        19.0[7-8]*,72.8[7-8]*) echo "Mumbai"; return 0 ;;            # Mumbai
        13.0[8-9]*,80.2[7-8]*) echo "Chennai"; return 0 ;;           # Chennai
        12.9[7-8]*,77.5[9-6]*) echo "Bangalore"; return 0 ;;         # Bangalore
        17.3[8-4]*,78.4[6-8]*) echo "Hyderabad"; return 0 ;;         # Hyderabad (IN)
        22.5[7-8]*,88.3[6-7]*) echo "Kolkata"; return 0 ;;           # Kolkata
        23.0[2-3]*,72.5[6-7]*) echo "Ahmedabad"; return 0 ;;         # Ahmedabad
        18.5[2-3]*,73.8[5-6]*) echo "Pune"; return 0 ;;              # Pune
        26.9[1-2]*,75.8[1-2]*) echo "Jaipur"; return 0 ;;            # Jaipur
        21.1[4-2]*,79.0[8-1]*) echo "Nagpur"; return 0 ;;            # Nagpur

        # Afghanistan (38M Muslims)
        34.5[2-3]*,69.1[7-8]*) echo "Kabul"; return 0 ;;             # Kabul
        31.6[0-1]*,65.7[1-2]*) echo "Kandahar"; return 0 ;;          # Kandahar
        36.7[0-1]*,67.1[0-1]*) echo "Mazar-i-Sharif"; return 0 ;;   # Mazar

        # Sri Lanka (2M Muslims)
        6.9[2-3]*,79.8[4-5]*) echo "Colombo"; return 0 ;;            # Colombo

        # Maldives (0.5M Muslims)
        4.1[7-8]*,73.5[0-1]*) echo "Malé"; return 0 ;;               # Malé
    esac

    # === MIDDLE EAST & GULF (120M Muslims) ===
    case "$latitude,$longitude" in
        # Saudi Arabia (31M Muslims)
        24.7[1-2]*,46.6[7-8]*) echo "Riyadh"; return 0 ;;            # Capital
        21.5[4-5]*,39.1[6-7]*) echo "Jeddah"; return 0 ;;            # Jeddah
        21.4[2-3]*,39.8[2-3]*) echo "Makkah"; return 0 ;;            # Makkah
        24.4[6-7]*,39.6[1-2]*) echo "Madinah"; return 0 ;;           # Madinah
        26.3[8-9]*,49.9[7-8]*) echo "Dammam"; return 0 ;;            # Eastern Province

        # UAE (7M Muslims)
        25.2[0-1]*,55.2[7-8]*) echo "Dubai"; return 0 ;;             # Dubai
        24.4[5-6]*,54.3[6-7]*) echo "Abu Dhabi"; return 0 ;;         # Capital
        25.3[4-5]*,55.4[1-2]*) echo "Sharjah"; return 0 ;;           # Sharjah

        # Kuwait (3M Muslims)
        29.3[1-2]*,47.4[8-9]*) echo "Kuwait City"; return 0 ;;       # Kuwait

        # Qatar (2M Muslims)
        25.2[8-9]*,51.5[3-4]*) echo "Doha"; return 0 ;;              # Qatar

        # Bahrain (1M Muslims)
        26.2[2-3]*,50.5[8-9]*) echo "Manama"; return 0 ;;            # Bahrain

        # Oman (4M Muslims)
        23.5[8-9]*,58.4[0-1]*) echo "Muscat"; return 0 ;;            # Oman

        # Iraq (38M Muslims)
        33.3[1-2]*,44.3[6-7]*) echo "Baghdad"; return 0 ;;           # Baghdad
        36.3[4-5]*,43.1[3-4]*) echo "Mosul"; return 0 ;;             # Mosul
        30.5[0-1]*,47.8[1-2]*) echo "Basra"; return 0 ;;             # Basra

        # Iran (82M Muslims)
        35.6[8-9]*,51.3[8-9]*) echo "Tehran"; return 0 ;;            # Tehran
        29.5[9-6]*,52.5[8-9]*) echo "Shiraz"; return 0 ;;            # Shiraz
        32.6[5-6]*,51.6[7-8]*) echo "Isfahan"; return 0 ;;           # Isfahan
        36.2[9-3]*,59.6[1-2]*) echo "Mashhad"; return 0 ;;           # Mashhad

        # Turkey (79M Muslims)
        41.0[0-1]*,28.9[7-8]*) echo "Istanbul"; return 0 ;;          # Istanbul
        39.9[2-3]*,32.8[5-6]*) echo "Ankara"; return 0 ;;            # Ankara
        38.4[1-2]*,27.1[2-3]*) echo "Izmir"; return 0 ;;             # Izmir

        # Yemen (28M Muslims)
        15.3[5-6]*,44.2[0-1]*) echo "Sanaa"; return 0 ;;             # Sanaa
        12.7[7-8]*,45.0[3-4]*) echo "Aden"; return 0 ;;              # Aden

        # Jordan (7M Muslims)
        31.9[5-6]*,35.9[2-3]*) echo "Amman"; return 0 ;;             # Amman

        # Lebanon (2M Muslims)
        33.8[8-9]*,35.4[9-5]*) echo "Beirut"; return 0 ;;            # Beirut

        # Syria (18M Muslims)
        33.5[1-2]*,36.2[9-3]*) echo "Damascus"; return 0 ;;          # Damascus
        36.2[0-1]*,37.1[6-7]*) echo "Aleppo"; return 0 ;;            # Aleppo

        # Palestine (4M Muslims)
        31.7[6-8]*,35.2[1-3]*) echo "Jerusalem"; return 0 ;;         # Jerusalem
        31.5[0-1]*,34.4[6-7]*) echo "Gaza"; return 0 ;;              # Gaza
    esac

    # === NORTH AFRICA (280M Muslims) ===
    case "$latitude,$longitude" in
        # Egypt (87M Muslims)
        30.0[4-5]*,31.2[3-4]*) echo "Cairo"; return 0 ;;             # Cairo
        31.2[0-1]*,29.9[5-6]*) echo "Alexandria"; return 0 ;;        # Alexandria
        25.6[8-9]*,32.6[3-4]*) echo "Aswan"; return 0 ;;             # Aswan

        # Nigeria (99M Muslims)
        6.5[2-3]*,3.3[7-8]*) echo "Lagos"; return 0 ;;               # Lagos
        9.0[7-8]*,7.5[3-4]*) echo "Abuja"; return 0 ;;               # Abuja
        11.9[9-1]*,8.5[1-2]*) echo "Kano"; return 0 ;;               # Kano

        # Algeria (43M Muslims)
        36.7[5-6]*,3.0[5-6]*) echo "Algiers"; return 0 ;;            # Algiers
        35.6[9-7]*,-0.6[2-3]*) echo "Oran"; return 0 ;;              # Oran

        # Morocco (37M Muslims)
        33.9[7-7]*,-6.8[4-5]*) echo "Rabat"; return 0 ;;             # Rabat
        33.5[3-4]*,-7.5[8-9]*) echo "Casablanca"; return 0 ;;        # Casablanca
        31.6[3-4]*,-7.9[9-0]*) echo "Marrakech"; return 0 ;;         # Marrakech

        # Sudan (39M Muslims)
        15.5[0-1]*,32.5[3-4]*) echo "Khartoum"; return 0 ;;          # Khartoum

        # Tunisia (12M Muslims)
        36.8[0-1]*,10.1[7-8]*) echo "Tunis"; return 0 ;;             # Tunis

        # Libya (7M Muslims)
        32.8[8-9]*,13.1[8-9]*) echo "Tripoli"; return 0 ;;           # Tripoli

        # Somalia (11M Muslims)
        2.0[4-5]*,45.3[4-5]*) echo "Mogadishu"; return 0 ;;          # Mogadishu
    esac

    # === EUROPE (60M Muslims) ===
    case "$latitude,$longitude" in
        # Russia (20M Muslims)
        55.7[5-6]*,37.6[1-2]*) echo "Moscow"; return 0 ;;            # Moscow
        59.9[3-4]*,30.3[1-2]*) echo "St. Petersburg"; return 0 ;;    # St. Petersburg
        55.7[9-8]*,49.1[2-3]*) echo "Kazan"; return 0 ;;             # Kazan

        # France (6M Muslims)
        48.8[5-6]*,2.3[5-6]*) echo "Paris"; return 0 ;;              # Paris
        43.2[9-3]*,5.3[6-7]*) echo "Marseille"; return 0 ;;          # Marseille

        # UK (3M Muslims)
        51.5[0-1]*,-0.1[2-3]*) echo "London"; return 0 ;;            # London
        53.4[8-9]*,-2.2[4-5]*) echo "Manchester"; return 0 ;;        # Manchester
        52.4[8-9]*,-1.8[9-0]*) echo "Birmingham"; return 0 ;;        # Birmingham

        # Germany (5M Muslims)
        52.5[2-3]*,13.4[0-1]*) echo "Berlin"; return 0 ;;            # Berlin
        50.1[1-2]*,8.6[8-9]*) echo "Frankfurt"; return 0 ;;          # Frankfurt
        48.1[3-4]*,11.5[7-8]*) echo "Munich"; return 0 ;;            # Munich

        # Bosnia (2M Muslims)
        43.8[4-5]*,18.3[5-6]*) echo "Sarajevo"; return 0 ;;          # Sarajevo

        # Albania (2M Muslims)
        41.3[2-3]*,19.8[1-2]*) echo "Tirana"; return 0 ;;            # Tirana

        # Kosovo (2M Muslims)
        42.6[6-7]*,21.1[6-7]*) echo "Pristina"; return 0 ;;          # Pristina
    esac

    # === AMERICAS & OCEANIA (15M Muslims) ===
    case "$latitude,$longitude" in
        # USA (3.5M Muslims)
        40.7[1-2]*,-74.0[0-1]*) echo "New York"; return 0 ;;         # New York
        34.0[5-6]*,-118.2[4-5]*) echo "Los Angeles"; return 0 ;;     # Los Angeles
        41.8[7-8]*,-87.6[2-3]*) echo "Chicago"; return 0 ;;          # Chicago
        38.9[0-1]*,-77.0[3-4]*) echo "Washington DC"; return 0 ;;    # Washington
        25.7[6-7]*,-80.1[9-0]*) echo "Miami"; return 0 ;;            # Miami

        # Canada (1.5M Muslims)
        43.6[5-6]*,-79.3[8-9]*) echo "Toronto"; return 0 ;;          # Toronto
        49.2[8-9]*,-123.1[2-3]*) echo "Vancouver"; return 0 ;;       # Vancouver
        45.5[0-1]*,-73.5[6-7]*) echo "Montreal"; return 0 ;;         # Montreal

        # Australia (0.6M Muslims)
        -33.8[6-7]*,151.2[0-1]*) echo "Sydney"; return 0 ;;          # Sydney
        -37.8[1-2]*,144.9[6-7]*) echo "Melbourne"; return 0 ;;       # Melbourne

        # Brazil (1M Muslims)
        -23.5[5-6]*,-46.6[3-4]*) echo "São Paulo"; return 0 ;;       # São Paulo
        -22.9[0-1]*,-43.1[7-8]*) echo "Rio de Janeiro"; return 0 ;;  # Rio
    esac

    # === CENTRAL ASIA & SUB-SAHARAN AFRICA (Additional 200M Muslims) ===
    case "$latitude,$longitude" in
        # Central Asia
        41.2[6-7]*,69.2[1-2]*) echo "Tashkent"; return 0 ;;           # Uzbekistan
        43.2[3-4]*,76.8[5-6]*) echo "Almaty"; return 0 ;;             # Kazakhstan
        42.8[7-8]*,74.5[9-6]*) echo "Bishkek"; return 0 ;;            # Kyrgyzstan
        38.5[5-6]*,68.7[7-8]*) echo "Dushanbe"; return 0 ;;           # Tajikistan
        37.9[5-6]*,58.3[8-9]*) echo "Ashgabat"; return 0 ;;           # Turkmenistan

        # Sub-Saharan Africa
        -26.2[0-1]*,28.0[4-5]*) echo "Johannesburg"; return 0 ;;      # South Africa
        -1.2[8-9]*,36.8[1-2]*) echo "Nairobi"; return 0 ;;            # Kenya
        -6.7[9-8]*,39.2[6-7]*) echo "Dar es Salaam"; return 0 ;;      # Tanzania
        9.0[0-1]*,38.7[4-5]*) echo "Addis Ababa"; return 0 ;;         # Ethiopia
        0.3[1-2]*,32.5[8-9]*) echo "Kampala"; return 0 ;;             # Uganda
        12.3[6-7]*,-1.5[1-2]*) echo "Ouagadougou"; return 0 ;;        # Burkina Faso
        13.5[1-2]*,-2.1[0-1]*) echo "Bamako"; return 0 ;;             # Mali
        14.7[0-1]*,-17.4[4-5]*) echo "Dakar"; return 0 ;;             # Senegal
        12.1[3-4]*,15.0[5-6]*) echo "N'Djamena"; return 0 ;;          # Chad
        13.9[0-1]*,2.1[1-2]*) echo "Niamey"; return 0 ;;              # Niger
    esac

    # === REGIONAL FALLBACKS (Broader Geographic Detection) ===
    # If no specific city match found, determine general region

    # Southeast Asia region
    if (( $(echo "$latitude >= -11.0 && $latitude <= 7.0" | bc -l) )) &&
       (( $(echo "$longitude >= 95.0 && $longitude <= 141.0" | bc -l) )); then
        echo "Southeast Asia"
        return 0
    fi

    # Middle East region
    if (( $(echo "$latitude >= 12.0 && $latitude <= 42.0" | bc -l) )) &&
       (( $(echo "$longitude >= 26.0 && $longitude <= 63.0" | bc -l) )); then
        echo "Middle East"
        return 0
    fi

    # South Asia region
    if (( $(echo "$latitude >= 6.0 && $latitude <= 37.0" | bc -l) )) &&
       (( $(echo "$longitude >= 60.0 && $longitude <= 97.0" | bc -l) )); then
        echo "South Asia"
        return 0
    fi

    # North Africa region
    if (( $(echo "$latitude >= 0.0 && $latitude <= 37.0" | bc -l) )) &&
       (( $(echo "$longitude >= -17.0 && $longitude <= 51.0" | bc -l) )); then
        echo "North Africa"
        return 0
    fi

    # Sub-Saharan Africa region
    if (( $(echo "$latitude >= -35.0 && $latitude <= 15.0" | bc -l) )) &&
       (( $(echo "$longitude >= -20.0 && $longitude <= 52.0" | bc -l) )); then
        echo "Africa"
        return 0
    fi

    # Europe region
    if (( $(echo "$latitude >= 35.0 && $latitude <= 71.0" | bc -l) )) &&
       (( $(echo "$longitude >= -10.0 && $longitude <= 70.0" | bc -l) )); then
        echo "Europe"
        return 0
    fi

    # North America region
    if (( $(echo "$latitude >= 15.0 && $latitude <= 83.0" | bc -l) )) &&
       (( $(echo "$longitude >= -180.0 && $longitude <= -52.0" | bc -l) )); then
        echo "North America"
        return 0
    fi

    # South America region
    if (( $(echo "$latitude >= -56.0 && $latitude <= 13.0" | bc -l) )) &&
       (( $(echo "$longitude >= -82.0 && $longitude <= -34.0" | bc -l) )); then
        echo "South America"
        return 0
    fi

    # Oceania region
    if (( $(echo "$latitude >= -50.0 && $latitude <= -8.0" | bc -l) )) &&
       (( $(echo "$longitude >= 110.0 && $longitude <= 180.0" | bc -l) )); then
        echo "Oceania"
        return 0
    fi

    # Unknown location
    echo "Unknown"
    return 1
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
        ip_info=$(curl -s --max-time 5 "http://ip-api.com/json/?fields=isp,org,hosting,proxy,countryCode" 2>/dev/null)

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