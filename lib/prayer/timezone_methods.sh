#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Method Timezone Mappings
# ============================================================================
#
# This file contains structured mappings from timezones to Islamic prayer
# calculation methods, replacing the large hardcoded function.
#
# Error Suppression Patterns (Issue #108):
# - declare -A 2>/dev/null: Associative array (may already exist on reload)
#
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_TIMEZONE_METHODS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_TIMEZONE_METHODS_LOADED=true

# ============================================================================
# PRAYER METHOD MAPPINGS
# ============================================================================

# Declare associative arrays for timezone to method mappings
declare -A TIMEZONE_TO_METHOD=(
    # === SOUTHEAST ASIA (450M Muslims) ===
    ["Asia/Jakarta"]="20"        # Indonesia - KEMENAG
    ["Asia/Pontianak"]="20"      # Indonesia - KEMENAG
    ["Asia/Makassar"]="20"       # Indonesia - KEMENAG  
    ["Asia/Jayapura"]="20"       # Indonesia - KEMENAG
    ["Asia/Kuala_Lumpur"]="17"   # Malaysia - JAKIM
    ["Asia/Kuching"]="17"        # Malaysia - JAKIM
    ["Asia/Singapore"]="11"      # Singapore - MUIS
    
    # === SOUTH ASIA (620M Muslims) ===
    ["Asia/Karachi"]="1"         # Pakistan - Karachi University
    ["Asia/Dhaka"]="1"           # Bangladesh - Karachi University
    ["Asia/Kolkata"]="1"         # India - Karachi University
    ["Asia/Delhi"]="1"           # India - Karachi University
    ["Asia/Mumbai"]="1"          # India - Karachi University
    ["Asia/Chennai"]="1"         # India - Karachi University
    ["Asia/Bangalore"]="1"       # India - Karachi University
    
    # === MIDDLE EAST (100M Muslims) ===
    ["Asia/Riyadh"]="4"          # Saudi Arabia - Umm Al-Qura
    ["Asia/Kuwait"]="4"          # Kuwait - Umm Al-Qura
    ["Asia/Bahrain"]="4"         # Bahrain - Umm Al-Qura
    ["Asia/Qatar"]="4"           # Qatar - Umm Al-Qura
    ["Asia/Dubai"]="4"           # UAE - Umm Al-Qura
    ["Asia/Muscat"]="4"          # Oman - Umm Al-Qura
    ["Asia/Baghdad"]="4"         # Iraq - Umm Al-Qura
    ["Asia/Tehran"]="7"          # Iran - Institute of Geophysics
    ["Asia/Istanbul"]="18"       # Turkey - Presidency of Religious Affairs
    ["Europe/Istanbul"]="18"     # Turkey - Presidency of Religious Affairs
    ["Asia/Damascus"]="2"        # Syria - ISNA
    ["Asia/Beirut"]="2"          # Lebanon - ISNA
    ["Asia/Amman"]="2"           # Jordan - ISNA
    ["Asia/Jerusalem"]="2"       # Palestine - ISNA
    
    # === NORTH AFRICA (150M Muslims) ===
    ["Africa/Cairo"]="5"         # Egypt - Egyptian General Authority
    ["Africa/Algiers"]="18"      # Algeria - Turkish method
    ["Africa/Tunis"]="18"        # Tunisia - Turkish method
    ["Africa/Casablanca"]="18"   # Morocco - Turkish method  
    ["Africa/Tripoli"]="5"       # Libya - Egyptian method
    ["Africa/Khartoum"]="3"      # Sudan - MWL
    
    # === SUB-SAHARAN AFRICA (200M Muslims) ===
    ["Africa/Lagos"]="3"         # Nigeria - MWL
    ["Africa/Dakar"]="3"         # Senegal - MWL
    ["Africa/Bamako"]="3"        # Mali - MWL
    ["Africa/Ouagadougou"]="3"   # Burkina Faso - MWL
    ["Africa/Niamey"]="3"        # Niger - MWL
    ["Africa/Ndjamena"]="3"      # Chad - MWL
    ["Africa/Addis_Ababa"]="3"   # Ethiopia - MWL
    ["Africa/Nairobi"]="3"       # Kenya - MWL
    ["Africa/Dar_es_Salaam"]="3" # Tanzania - MWL
    ["Africa/Kampala"]="3"       # Uganda - MWL
    ["Africa/Johannesburg"]="3"  # South Africa - MWL
    
    # === CENTRAL ASIA (100M Muslims) ===
    ["Asia/Tashkent"]="3"        # Uzbekistan - MWL
    ["Asia/Almaty"]="3"          # Kazakhstan - MWL
    ["Asia/Bishkek"]="3"         # Kyrgyzstan - MWL
    ["Asia/Dushanbe"]="3"        # Tajikistan - MWL
    ["Asia/Ashgabat"]="3"        # Turkmenistan - MWL
    ["Asia/Kabul"]="1"           # Afghanistan - Karachi University
    
    # === EUROPE (50M Muslims) ===
    ["Europe/London"]="3"        # UK - MWL
    ["Europe/Paris"]="12"        # France - Union des Organisations Islamiques
    ["Europe/Berlin"]="3"        # Germany - MWL
    ["Europe/Rome"]="3"          # Italy - MWL
    ["Europe/Madrid"]="3"        # Spain - MWL
    ["Europe/Amsterdam"]="3"     # Netherlands - MWL
    ["Europe/Brussels"]="3"      # Belgium - MWL
    ["Europe/Vienna"]="3"        # Austria - MWL
    ["Europe/Zurich"]="3"        # Switzerland - MWL
    ["Europe/Stockholm"]="3"     # Sweden - MWL
    ["Europe/Oslo"]="3"          # Norway - MWL
    ["Europe/Copenhagen"]="3"    # Denmark - MWL
    ["Europe/Helsinki"]="3"      # Finland - MWL
    ["Europe/Warsaw"]="3"        # Poland - MWL
    ["Europe/Prague"]="3"        # Czech Republic - MWL
    ["Europe/Budapest"]="3"      # Hungary - MWL
    ["Europe/Bucharest"]="3"     # Romania - MWL
    ["Europe/Sofia"]="3"         # Bulgaria - MWL
    ["Europe/Athens"]="3"        # Greece - MWL
    ["Europe/Moscow"]="3"        # Russia - MWL
    ["Europe/Kiev"]="3"          # Ukraine - MWL
    ["Europe/Sarajevo"]="3"      # Bosnia - MWL
    ["Europe/Belgrade"]="3"      # Serbia - MWL
    ["Europe/Zagreb"]="3"        # Croatia - MWL
    ["Europe/Ljubljana"]="3"     # Slovenia - MWL
    ["Europe/Skopje"]="3"        # North Macedonia - MWL
    ["Europe/Podgorica"]="3"     # Montenegro - MWL
    ["Europe/Tirana"]="3"        # Albania - MWL
    
    # === AMERICAS (15M Muslims) ===
    ["America/New_York"]="2"     # USA East - ISNA
    ["America/Chicago"]="2"      # USA Central - ISNA
    ["America/Denver"]="2"       # USA Mountain - ISNA
    ["America/Los_Angeles"]="2"  # USA West - ISNA
    ["America/Toronto"]="2"      # Canada East - ISNA
    ["America/Vancouver"]="2"    # Canada West - ISNA
    ["America/Mexico_City"]="2"  # Mexico - ISNA
    ["America/Sao_Paulo"]="2"    # Brazil - ISNA
    ["America/Buenos_Aires"]="2" # Argentina - ISNA
    ["America/Lima"]="2"         # Peru - ISNA
    ["America/Bogota"]="2"       # Colombia - ISNA
    ["America/Caracas"]="2"      # Venezuela - ISNA
    
    # === OCEANIA (1M Muslims) ===
    ["Australia/Sydney"]="3"     # Australia - MWL
    ["Australia/Melbourne"]="3"  # Australia - MWL
    ["Australia/Perth"]="3"      # Australia - MWL
    ["Pacific/Auckland"]="3"     # New Zealand - MWL
)

# Declare country code to method mappings for fallback
declare -A COUNTRY_TO_METHOD=(
    # Major Islamic countries
    ["ID"]="20"    # Indonesia → KEMENAG
    ["MY"]="17"    # Malaysia → JAKIM
    ["SG"]="11"    # Singapore → MUIS
    ["PK"]="1"     # Pakistan → Karachi
    ["BD"]="1"     # Bangladesh → Karachi
    ["IN"]="1"     # India → Karachi
    ["SA"]="4"     # Saudi Arabia → Umm Al-Qura
    ["KW"]="4"     # Kuwait → Umm Al-Qura
    ["BH"]="4"     # Bahrain → Umm Al-Qura
    ["QA"]="4"     # Qatar → Umm Al-Qura
    ["AE"]="4"     # UAE → Umm Al-Qura
    ["OM"]="4"     # Oman → Umm Al-Qura
    ["IQ"]="4"     # Iraq → Umm Al-Qura
    ["IR"]="7"     # Iran → Institute of Geophysics
    ["TR"]="18"    # Turkey → Presidency of Religious Affairs
    ["SY"]="2"     # Syria → ISNA
    ["LB"]="2"     # Lebanon → ISNA
    ["JO"]="2"     # Jordan → ISNA
    ["PS"]="2"     # Palestine → ISNA
    ["EG"]="5"     # Egypt → Egyptian General Authority
    ["DZ"]="18"    # Algeria → Turkish
    ["TN"]="18"    # Tunisia → Turkish
    ["MA"]="18"    # Morocco → Turkish
    ["LY"]="5"     # Libya → Egyptian
    ["SD"]="3"     # Sudan → MWL
    ["NG"]="3"     # Nigeria → MWL
    ["SN"]="3"     # Senegal → MWL
    ["ML"]="3"     # Mali → MWL
    ["BF"]="3"     # Burkina Faso → MWL
    ["NE"]="3"     # Niger → MWL
    ["TD"]="3"     # Chad → MWL
    ["ET"]="3"     # Ethiopia → MWL
    ["KE"]="3"     # Kenya → MWL
    ["TZ"]="3"     # Tanzania → MWL
    ["UG"]="3"     # Uganda → MWL
    ["ZA"]="3"     # South Africa → MWL
    ["UZ"]="3"     # Uzbekistan → MWL
    ["KZ"]="3"     # Kazakhstan → MWL
    ["KG"]="3"     # Kyrgyzstan → MWL
    ["TJ"]="3"     # Tajikistan → MWL
    ["TM"]="3"     # Turkmenistan → MWL
    ["AF"]="1"     # Afghanistan → Karachi
    ["GB"]="3"     # UK → MWL
    ["FR"]="12"    # France → Union des Organisations Islamiques
    ["DE"]="3"     # Germany → MWL
    ["IT"]="3"     # Italy → MWL
    ["ES"]="3"     # Spain → MWL
    ["NL"]="3"     # Netherlands → MWL
    ["BE"]="3"     # Belgium → MWL
    ["AT"]="3"     # Austria → MWL
    ["CH"]="3"     # Switzerland → MWL
    ["SE"]="3"     # Sweden → MWL
    ["NO"]="3"     # Norway → MWL
    ["DK"]="3"     # Denmark → MWL
    ["FI"]="3"     # Finland → MWL
    ["PL"]="3"     # Poland → MWL
    ["CZ"]="3"     # Czech Republic → MWL
    ["HU"]="3"     # Hungary → MWL
    ["RO"]="3"     # Romania → MWL
    ["BG"]="3"     # Bulgaria → MWL
    ["GR"]="3"     # Greece → MWL
    ["RU"]="3"     # Russia → MWL
    ["UA"]="3"     # Ukraine → MWL
    ["BA"]="3"     # Bosnia → MWL
    ["RS"]="3"     # Serbia → MWL
    ["HR"]="3"     # Croatia → MWL
    ["SI"]="3"     # Slovenia → MWL
    ["MK"]="3"     # North Macedonia → MWL
    ["ME"]="3"     # Montenegro → MWL
    ["AL"]="3"     # Albania → MWL
    ["US"]="2"     # USA → ISNA
    ["CA"]="2"     # Canada → ISNA
    ["MX"]="2"     # Mexico → ISNA
    ["BR"]="2"     # Brazil → ISNA
    ["AR"]="2"     # Argentina → ISNA
    ["PE"]="2"     # Peru → ISNA
    ["CO"]="2"     # Colombia → ISNA
    ["VE"]="2"     # Venezuela → ISNA
    ["AU"]="3"     # Australia → MWL
    ["NZ"]="3"     # New Zealand → MWL
)

# ============================================================================
# PRAYER METHOD LOOKUP FUNCTIONS
# ============================================================================

# Get prayer method from timezone using case-based matching
get_prayer_method_from_timezone() {
    local timezone="${1:-$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || date +%Z)}"
    local default_method="3"  # Muslim World League (safe worldwide default)
    
    debug_log "Looking up prayer method for timezone: '$timezone'" "INFO"
    
    # Direct timezone lookup using case statement (more reliable than associative arrays)
    case "$timezone" in
        # === SOUTHEAST ASIA (450M Muslims) ===
        Asia/Jakarta|Asia/Pontianak|Asia/Makassar|Asia/Jayapura)
            echo "20"  # Indonesia - KEMENAG
            debug_log "Direct timezone match: $timezone → method 20 (KEMENAG)" "INFO"
            return 0
            ;;
        Asia/Kuala_Lumpur|Asia/Kuching)
            echo "17"  # Malaysia - JAKIM
            debug_log "Direct timezone match: $timezone → method 17 (JAKIM)" "INFO"
            return 0
            ;;
        Asia/Singapore)
            echo "11"  # Singapore - MUIS
            debug_log "Direct timezone match: $timezone → method 11 (MUIS)" "INFO"
            return 0
            ;;
        # === SOUTH ASIA (620M Muslims) ===
        Asia/Karachi|Asia/Dhaka|Asia/Kolkata|Asia/Delhi|Asia/Mumbai|Asia/Chennai|Asia/Bangalore)
            echo "1"   # University of Islamic Sciences, Karachi
            debug_log "Direct timezone match: $timezone → method 1 (Karachi)" "INFO"
            return 0
            ;;
        # === MIDDLE EAST (100M Muslims) ===
        Asia/Riyadh|Asia/Kuwait|Asia/Bahrain|Asia/Qatar|Asia/Dubai|Asia/Muscat|Asia/Baghdad)
            echo "4"   # Umm Al-Qura
            debug_log "Direct timezone match: $timezone → method 4 (Umm Al-Qura)" "INFO"
            return 0
            ;;
        Asia/Tehran)
            echo "7"   # Iran - Institute of Geophysics
            debug_log "Direct timezone match: $timezone → method 7 (Iran)" "INFO"
            return 0
            ;;
        Asia/Istanbul|Europe/Istanbul)
            echo "18"  # Turkey - Presidency of Religious Affairs
            debug_log "Direct timezone match: $timezone → method 18 (Turkey)" "INFO"
            return 0
            ;;
        Asia/Damascus|Asia/Beirut|Asia/Amman|Asia/Jerusalem)
            echo "2"   # ISNA
            debug_log "Direct timezone match: $timezone → method 2 (ISNA)" "INFO"
            return 0
            ;;
        # === NORTH AFRICA (150M Muslims) ===
        Africa/Cairo|Africa/Tripoli)
            echo "5"   # Egyptian General Authority
            debug_log "Direct timezone match: $timezone → method 5 (Egyptian)" "INFO"
            return 0
            ;;
        Africa/Algiers|Africa/Tunis|Africa/Casablanca)
            echo "18"  # Turkish method
            debug_log "Direct timezone match: $timezone → method 18 (Turkish)" "INFO"
            return 0
            ;;
        # === EUROPE ===
        Europe/Paris)
            echo "12"  # Union des Organisations Islamiques
            debug_log "Direct timezone match: $timezone → method 12 (France)" "INFO"
            return 0
            ;;
        # === AMERICAS ===
        America/*)
            echo "2"   # ISNA
            debug_log "Direct timezone match: $timezone → method 2 (ISNA)" "INFO"
            return 0
            ;;
        # === DEFAULT CASES ===
        Europe/*|Africa/*|Australia/*|Pacific/*)
            echo "3"   # MWL (safe default)
            debug_log "Direct timezone match: $timezone → method 3 (MWL default)" "INFO"
            return 0
            ;;
    esac
    
    # Extract continent/region for broader matching
    local continent="${timezone%%/*}"
    local region="${timezone#*/}"
    
    debug_log "Trying continent-based matching: $continent" "INFO"
    
    case "$continent" in
        "Asia")
            # Try partial matches for Asian timezones
            case "$timezone" in
                Asia/Jakarta*|Asia/Pontianak*|Asia/Makassar*|Asia/Jayapura*) echo "20" ;; # Indonesia
                Asia/Kuala_Lumpur*|Asia/Kuching*) echo "17" ;;                          # Malaysia
                Asia/Karachi*|Asia/Dhaka*|Asia/Kolkata*|Asia/Delhi*|Asia/Mumbai*) echo "1" ;; # South Asia
                Asia/Riyadh*|Asia/Kuwait*|Asia/Dubai*|Asia/Muscat*) echo "4" ;;         # Gulf states
                Asia/Tehran*) echo "7" ;;                                               # Iran
                Asia/Istanbul*) echo "18" ;;                                            # Turkey
                *) echo "3" ;;  # Default for Asia → MWL
            esac
            ;;
        "Africa")
            case "$timezone" in
                Africa/Cairo*|Africa/Tripoli*) echo "5" ;;    # Egypt/Libya
                Africa/Algiers*|Africa/Tunis*|Africa/Casablanca*) echo "18" ;; # North Africa (Turkish)
                *) echo "3" ;;  # Default for Africa → MWL
            esac
            ;;
        "Europe")
            case "$timezone" in
                Europe/Istanbul*) echo "18" ;;  # Turkey
                Europe/Paris*) echo "12" ;;     # France
                *) echo "3" ;;  # Default for Europe → MWL
            esac
            ;;
        "America")
            echo "2"  # Americas → ISNA
            ;;
        "Australia"|"Pacific")
            echo "3"  # Oceania → MWL
            ;;
        *)
            echo "$default_method"  # Unknown → safe default
            ;;
    esac
    
    debug_log "Continent-based match completed for $timezone" "INFO"
}

# Get prayer method from country code
get_prayer_method_from_country() {
    local country_code="$1"
    local default_method="3"
    
    if [[ -n "${COUNTRY_TO_METHOD[$country_code]:-}" ]]; then
        echo "${COUNTRY_TO_METHOD[$country_code]}"
        debug_log "Country code match: $country_code → method ${COUNTRY_TO_METHOD[$country_code]}" "INFO"
    else
        echo "$default_method"
        debug_log "No country match found for $country_code, using default: $default_method" "WARN"
    fi
}