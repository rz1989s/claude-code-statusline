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
# REMOVED: VPN status tracking no longer needed
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

    # Single-pass numeric bounding-box lookup. Cities are listed first in
    # priority order (specific before broad); the regional boxes at the end act
    # as a catch-all. The first box that contains (latitude, longitude) wins.
    # Replaces the former per-city glob matching, which silently failed on
    # reversed character ranges (e.g. [7-2]) and decimal-boundary spans.
    # Coverage is verified in tests/unit/test_location_city_matching.bats.
    local city
    city=$(awk -v lat="$latitude" -v lon="$longitude" '
        NF >= 5 && lat >= $1 && lat <= $2 && lon >= $3 && lon <= $4 {
            name = $5
            for (i = 6; i <= NF; i++) name = name " " $i
            print name
            exit
        }
    ' <<'CITY_BOUNDING_BOXES'
-6.3 -6.08 106.69 106.94 Jakarta
-6.26 -6.2 106.95 107 Bekasi
-6.26 -6.2 107 107.03 Bekasi
-6.2 -6.17 106.6 106.64 Tangerang
-6.43 -6.4 106.78 106.8 Depok
-6.43 -6.4 106.8 106.82 Depok
-6.6 -6.58 106.8 106.83 Bogor
-6.93 -6.9 107.6 107.63 Bandung
-6.75 -6.72 108.54 108.57 Cirebon
-6.99 -6.96 110.41 110.44 Semarang
-7.59 -7.56 110.81 110.84 Solo
-7.79 -7.77 110.37 110.39 Yogyakarta
-7.27 -7.24 112.74 112.78 Surabaya
-8 -7.98 112.61 112.64 Malang
5.54 5.57 95.32 95.35 Banda Aceh
3.53 3.66 98.6 98.74 Medan
-0.9 -0.88 100.34 100.37 Padang
0.5 0.53 101.43 101.47 Pekanbaru
-1.63 -1.6 103.6 103.63 Jambi
-3 -2.97 104.74 104.77 Palembang
-5.4 -5.38 105.25 105.28 Bandar Lampung
-0.05 -0.01 109.32 109.36 Pontianak
-8.68 -8.63 115.2 115.24 Denpasar
-8.9 -8.4 115 115.8 Bali
-8.6 -8.57 116.1 116.14 Mataram
-9 -8.2 116 116.8 Lombok
-8.5 -8.48 117.42 117.45 Sumbawa
-8.48 -8.45 118.71 118.74 Bima
-10.19 -10.16 123.59 123.6 Kupang
-10.19 -10.16 123.6 123.63 Kupang
-5.16 -5.14 119.42 119.45 Makassar
-0.92 -0.9 119.82 119.85 Palu
1.47 1.5 124.83 124.86 Manado
-3.99 -3.96 122.58 122.6 Kendari
-3.99 -3.96 122.6 122.62 Kendari
-1.28 -1.25 116.82 116.85 Balikpapan
-0.52 -0.5 117.14 117.17 Samarinda
-3.34 -3.31 114.58 114.6 Banjarmasin
-3.34 -3.31 114.6 114.62 Banjarmasin
-2.23 -2.2 113.9 113.93 Palangkaraya
-0.89 -0.86 131.24 131.27 Sorong
-0.88 -0.85 134.05 134.08 Manokwari
-2.55 -2.52 140.7 140.73 Jayapura
-3.7 -3.68 128.17 128.2 Ambon
0.78 0.8 127.37 127.4 Ternate
3.12 3.15 101.66 101.7 Kuala Lumpur
5.4 5.43 100.32 100.35 George Town
1.44 1.55 103.7 103.82 Johor Bahru
1.54 1.57 110.34 110.37 Kuching
1.34 1.37 103.81 103.83 Singapore
4.9 4.92 114.94 114.96 Bandar Seri Begawan
24.85 24.9 67 67.03 Karachi
31.52 31.57 74.34 74.37 Lahore
33.66 33.69 73.04 73.07 Islamabad
31.4 31.43 73.06 73.09 Faisalabad
30.1 30.25 71.42 71.58 Multan
25.33 25.45 68.3 68.42 Hyderabad
23.8 23.82 90.4 90.43 Dhaka
22.34 22.37 91.82 91.85 Chittagong
24.36 24.39 88.6 88.63 Rajshahi
28.61 28.63 77.2 77.22 Delhi
19.07 19.09 72.87 72.89 Mumbai
13.08 13.1 80.27 80.29 Chennai
12.92 13.04 77.53 77.66 Bangalore
17.33 17.47 78.42 78.55 Hyderabad
22.57 22.59 88.36 88.38 Kolkata
23.02 23.04 72.56 72.58 Ahmedabad
18.52 18.54 73.85 73.87 Pune
26.91 26.93 75.81 75.83 Jaipur
21.09 21.2 79.03 79.15 Nagpur
34.52 34.54 69.17 69.19 Kabul
31.6 31.62 65.71 65.73 Kandahar
36.7 36.72 67.1 67.12 Mazar-i-Sharif
6.92 6.94 79.84 79.86 Colombo
4.17 4.19 73.5 73.52 Malé
24.71 24.73 46.67 46.69 Riyadh
21.54 21.56 39.16 39.18 Jeddah
21.42 21.44 39.82 39.84 Makkah
24.46 24.48 39.61 39.63 Madinah
26.38 26.4 49.97 49.99 Dammam
25.2 25.22 55.27 55.29 Dubai
24.45 24.47 54.36 54.38 Abu Dhabi
25.34 25.36 55.41 55.43 Sharjah
29.31 29.33 47.48 47.5 Kuwait City
25.28 25.3 51.53 51.55 Doha
26.22 26.24 50.58 50.6 Manama
23.58 23.6 58.4 58.42 Muscat
33.31 33.33 44.36 44.38 Baghdad
36.34 36.36 43.13 43.15 Mosul
30.5 30.52 47.81 47.83 Basra
35.68 35.7 51.38 51.4 Tehran
29.53 29.65 52.52 52.65 Shiraz
32.65 32.67 51.67 51.69 Isfahan
36.2 36.33 59.55 59.68 Mashhad
41 41.02 28.97 28.99 Istanbul
39.92 39.94 32.85 32.87 Ankara
38.41 38.43 27.12 27.14 Izmir
15.35 15.37 44.2 44.22 Sanaa
12.77 12.79 45.03 45.05 Aden
31.95 31.97 35.92 35.94 Amman
33.84 33.95 35.45 35.56 Beirut
33.46 33.58 36.22 36.34 Damascus
36.2 36.22 37.16 37.18 Aleppo
31.76 31.79 35.21 35.24 Jerusalem
31.5 31.52 34.46 34.48 Gaza
30.04 30.06 31.23 31.25 Cairo
31.2 31.22 29.95 29.97 Alexandria
25.68 25.7 32.63 32.65 Aswan
6.52 6.54 3.37 3.39 Lagos
9.07 9.09 7.53 7.55 Abuja
11.94 12.06 8.52 8.66 Kano
36.75 36.77 3.05 3.07 Algiers
35.64 35.76 -0.7 -0.56 Oran
33.97 33.98 -6.86 -6.84 Rabat
33.53 33.55 -7.6 -7.58 Casablanca
31.57 31.69 -8.05 -7.91 Marrakech
15.5 15.52 32.53 32.55 Khartoum
36.8 36.82 10.17 10.19 Tunis
32.88 32.9 13.18 13.2 Tripoli
2.04 2.06 45.34 45.36 Mogadishu
55.75 55.77 37.61 37.63 Moscow
59.93 59.95 30.31 30.33 St. Petersburg
55.74 55.86 49.04 49.18 Kazan
48.85 48.87 2.35 2.37 Paris
43.24 43.36 5.3 5.44 Marseille
51.5 51.52 -0.14 -0.12 London
53.48 53.5 -2.26 -2.24 Manchester
52.43 52.55 -1.96 -1.82 Birmingham
52.52 52.54 13.4 13.42 Berlin
50.11 50.13 8.68 8.7 Frankfurt
48.13 48.15 11.57 11.59 Munich
43.84 43.86 18.35 18.37 Sarajevo
41.32 41.34 19.81 19.83 Tirana
42.66 42.68 21.16 21.18 Pristina
40.71 40.73 -74.02 -74 New York
34.05 34.07 -118.26 -118.24 Los Angeles
41.87 41.89 -87.64 -87.62 Chicago
38.9 38.92 -77.05 -77.03 Washington DC
25.7 25.83 -80.26 -80.12 Miami
43.65 43.67 -79.4 -79.38 Toronto
49.28 49.3 -123.14 -123.12 Vancouver
45.5 45.52 -73.58 -73.56 Montreal
-33.88 -33.86 151.2 151.22 Sydney
-37.83 -37.81 144.96 144.98 Melbourne
-23.57 -23.55 -46.65 -46.63 São Paulo
-22.92 -22.9 -43.19 -43.17 Rio de Janeiro
41.26 41.28 69.21 69.23 Tashkent
43.23 43.25 76.85 76.87 Almaty
42.81 42.94 74.5 74.64 Bishkek
38.55 38.57 68.77 68.79 Dushanbe
37.95 37.97 58.38 58.4 Ashgabat
-26.22 -26.2 28.04 28.06 Johannesburg
-1.3 -1.28 36.81 36.83 Nairobi
-6.86 -6.73 39.14 39.28 Dar es Salaam
9 9.02 38.74 38.76 Addis Ababa
0.31 0.33 32.58 32.6 Kampala
12.36 12.38 -1.53 -1.51 Ouagadougou
13.51 13.53 -2.12 -2.1 Bamako
14.7 14.72 -17.46 -17.44 Dakar
12.13 12.15 15.05 15.07 N'Djamena
13.9 13.92 2.11 2.13 Niamey
-11 7 95 141 Southeast Asia
12 42 26 63 Middle East
6 37 60 97 South Asia
0 37 -17 51 North Africa
-35 15 -20 52 Africa
35 71 -10 70 Europe
15 83 -180 -52 North America
-56 13 -82 -34 South America
-50 -8 110 180 Oceania
CITY_BOUNDING_BOXES
)

    if [[ -n "$city" ]]; then
        echo "$city"
        return 0
    fi

    echo "Unknown"
    return 1
}

# ============================================================================
# LOCATION DATA INTEGRATION
# ============================================================================

# Get location data from prayer location system
get_location_data_from_prayer_system() {
    debug_log "Getting location data from prayer location system..." "INFO"

    # Use the prayer system's exported location data if available
    if [[ -n "${STATUSLINE_DETECTED_COORDINATES:-}" ]]; then
        local coordinates="${STATUSLINE_DETECTED_COORDINATES}"
        local method="${STATUSLINE_DETECTION_METHOD:-unknown}"
        local source="${STATUSLINE_VPN_STATUS:-UNKNOWN}"

        debug_log "Using prayer system location: $coordinates via $method ($source)" "INFO"
        echo "$coordinates,$method,$source"
        return 0
    fi

    # Fallback: Try to get fresh coordinates using prayer location functions
    if type get_location_coordinates &>/dev/null; then
        local coordinates
        if coordinates=$(get_location_coordinates); then
            debug_log "Got fresh coordinates from prayer system: $coordinates" "INFO"
            echo "$coordinates,direct_call,FRESH_DATA"
            return 0
        fi
    fi

    debug_log "No location data available from prayer system" "WARN"
    return 1
}

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect location display data - SIMPLIFIED (No VPN Detection)
collect_location_display_data() {
    debug_log "Collecting location_display component data" "INFO"

    # Get location data from the prayer system (uses fresh GPS/local coordinates)
    local location_data
    if location_data=$(get_location_data_from_prayer_system); then
        # Parse the returned data: coordinates,method,source
        local coordinates=$(echo "$location_data" | cut -d',' -f1-2)
        local method=$(echo "$location_data" | cut -d',' -f3)
        local source=$(echo "$location_data" | cut -d',' -f4)

        COMPONENT_LOCATION_DISPLAY_COORDINATES="$coordinates"
        COMPONENT_LOCATION_DISPLAY_METHOD="$method"

        # Set confidence based on method
        case "$method" in
            "local_gps") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="95" ;;
            "manual") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="100" ;;
            "ip_geolocation"|"direct_call") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="85" ;;
            "cached_location") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="80" ;;
            "timezone_fallback") COMPONENT_LOCATION_DISPLAY_CONFIDENCE="70" ;;
            *) COMPONENT_LOCATION_DISPLAY_CONFIDENCE="60" ;;
        esac

        debug_log "Using coordinates from prayer system: $coordinates via $method (confidence: ${COMPONENT_LOCATION_DISPLAY_CONFIDENCE}%)" "INFO"
    else
        # Ultimate fallback to Jakarta if prayer system fails
        debug_log "Prayer system location unavailable, using Jakarta fallback" "WARN"
        COMPONENT_LOCATION_DISPLAY_COORDINATES="-6.2088,106.8456"
        COMPONENT_LOCATION_DISPLAY_METHOD="ultimate_fallback"
        COMPONENT_LOCATION_DISPLAY_CONFIDENCE="50"
    fi

    # Extract city from coordinates
    local latitude="${coordinates%%,*}"
    local longitude="${coordinates##*,}"
    COMPONENT_LOCATION_DISPLAY_CITY=$(get_city_from_coordinates "$latitude" "$longitude")

    debug_log "location_display data: city=$COMPONENT_LOCATION_DISPLAY_CITY, method=$COMPONENT_LOCATION_DISPLAY_METHOD, confidence=$COMPONENT_LOCATION_DISPLAY_CONFIDENCE" "INFO"
    return 0
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render location display
render_location_display() {
    local display_format
    display_format=$(get_location_display_config "format" "short")

    # REMOVED: VPN indicator no longer needed with fresh GPS coordinates

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

    # REMOVED: VPN indicator - no longer needed with local GPS coordinates

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
        # REMOVED: show_vpn_indicator config option no longer needed
        "show_vpn_indicator")
            echo "false"  # Always false - VPN detection removed
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