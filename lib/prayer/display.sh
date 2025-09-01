#!/bin/bash

# ============================================================================
# Claude Code Statusline - Prayer Display Module
# ============================================================================
# 
# This module handles the formatting and display of prayer times and Hijri dates.
#
# Dependencies: core.sh, security.sh, themes.sh, prayer/core.sh, prayer/calculation.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_DISPLAY_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_DISPLAY_LOADED=true

# ============================================================================
# MAIN DISPLAY FUNCTION
# ============================================================================

# Get formatted prayer display string
get_prayer_display() {
    debug_log "Generating prayer display..." "INFO"
    
    # Load prayer configuration
    load_prayer_config
    
    # Check if prayer display is enabled
    if [[ "$CONFIG_PRAYER_ENABLED" != "true" ]]; then
        debug_log "Prayer display is disabled" "INFO"
        return 1
    fi
    
    # Get comprehensive prayer data
    local prayer_data
    prayer_data=$(get_prayer_times_and_hijri)
    
    if [[ $? -ne 0 || -z "$prayer_data" ]]; then
        debug_log "Failed to get prayer data for display" "ERROR"
        echo "${HIJRI_INDICATOR} Prayer times unavailable"
        return 1
    fi
    
    # Parse prayer data using tab delimiter
    # Format: prayer_times\tprayer_statuses\thijri_date\tcurrent_time
    IFS=$'\t' read -r prayer_times prayer_statuses hijri_date current_time <<< "$prayer_data"
    IFS=',' read -r fajr dhuhr asr maghrib isha <<< "$prayer_times"
    
    debug_log "Processing prayer data: times=[$prayer_times], statuses=[$prayer_statuses]" "DEBUG"
    
    # Build Hijri date display
    local hijri_display=""
    if [[ "$CONFIG_HIJRI_ENABLED" == "true" ]]; then
        hijri_display=$(format_hijri_date_display "$hijri_date" "$maghrib" "$current_time")
    fi
    
    # Build prayer times display
    local prayers_display
    prayers_display=$(format_prayer_times_display "$prayer_times" "$prayer_statuses" "$current_time")
    
    if [[ $? -ne 0 || -z "$prayers_display" ]]; then
        debug_log "Failed to format prayer times display" "ERROR"
        echo "${HIJRI_INDICATOR} Prayer formatting error"
        return 1
    fi
    
    # Combine displays
    local full_display=""
    if [[ -n "$hijri_display" ]]; then
        full_display="${hijri_display}"
        if [[ -n "$prayers_display" ]]; then
            full_display="${full_display} │ ${prayers_display}"
        fi
    else
        full_display="${prayers_display}"
    fi
    
    echo "$full_display"
    debug_log "Generated prayer display successfully" "INFO"
    return 0
}

# ============================================================================
# HIJRI DATE FORMATTING
# ============================================================================

# Format Hijri date for display with optional enhancements
format_hijri_date_display() {
    local hijri_date="$1"
    local maghrib_time="$2" 
    local current_time="$3"
    
    if [[ -z "$hijri_date" ]]; then
        return 1
    fi
    
    # Parse Hijri date components
    IFS=',' read -r hijri_day hijri_month hijri_year hijri_weekday <<< "$hijri_date"
    
    # Build base display
    local display="${HIJRI_INDICATOR} ${hijri_day} ${hijri_month} ${hijri_year}"
    
    # Add weekday if it's Friday and highlighting is enabled
    if [[ "$CONFIG_HIJRI_HIGHLIGHT_FRIDAY" == "true" && "$hijri_weekday" == "Friday" ]]; then
        display="${display} (Jumu'ah)"
    fi
    
    # Add Maghrib moon indicator if enabled and past Maghrib
    if [[ "$CONFIG_HIJRI_SHOW_MAGHRIB_INDICATOR" == "true" && -n "$maghrib_time" ]]; then
        if time_is_after "$current_time" "$maghrib_time"; then
            display="${display} ${PRAYER_MAGHRIB_MOON}"
        fi
    fi
    
    echo "$display"
    return 0
}

# ============================================================================
# PRAYER TIMES FORMATTING
# ============================================================================

# Format prayer times display with status indicators and colors
format_prayer_times_display() {
    local prayer_times="$1"
    local prayer_statuses="$2"
    local current_time="$3"
    
    if [[ -z "$prayer_times" || -z "$prayer_statuses" ]]; then
        debug_log "Missing prayer times or status data for formatting" "ERROR"
        return 1
    fi
    
    # Parse prayer times and statuses
    IFS=',' read -r fajr dhuhr asr maghrib isha <<< "$prayer_times"
    local prayer_names=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
    local times=("$fajr" "$dhuhr" "$asr" "$maghrib" "$isha")
    
    # Parse status information  
    # Format: status1,status2,status3,status4,status5|next_prayer|next_time|next_index
    local status_info="${prayer_statuses%%|*}"
    local next_info="${prayer_statuses#*|}"
    IFS=',' read -ra statuses <<< "$status_info"
    IFS='|' read -r next_prayer next_prayer_time next_prayer_index <<< "$next_info"
    
    local prayers_display=""
    
    # Format each prayer
    for i in "${!prayer_names[@]}"; do
        local prayer_name="${prayer_names[$i]}"
        local prayer_time=$(format_prayer_time "${times[$i]}")
        local prayer_status="${statuses[$i]}"
        
        local prayer_display
        prayer_display=$(format_single_prayer "$prayer_name" "$prayer_time" "$prayer_status" "$current_time" "$i" "$next_prayer_index")
        
        # Add to prayers display
        if [[ -z "$prayers_display" ]]; then
            prayers_display="$prayer_display"
        else
            prayers_display="$prayers_display │ $prayer_display"
        fi
    done
    
    echo "$prayers_display"
    return 0
}

# Format a single prayer with status indicators and colors
format_single_prayer() {
    local prayer_name="$1"
    local prayer_time="$2"
    local prayer_status="$3"
    local current_time="$4"
    local prayer_index="$5"
    local next_prayer_index="$6"
    
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
                # Add time information or indicator
                if [[ "$CONFIG_PRAYER_USE_LEGACY_INDICATOR" == "true" ]]; then
                    # Use legacy "(next)" indicator
                    prayer_display="$prayer_display $PRAYER_NEXT_INDICATOR"
                elif [[ "$CONFIG_PRAYER_SHOW_TIME_REMAINING" == "true" ]]; then
                    # Calculate and show time remaining
                    local minutes_until=$(calculate_time_until_prayer "$current_time" "$prayer_time")
                    local time_remaining=$(format_time_remaining "$minutes_until")
                    prayer_display="$prayer_display ($time_remaining)"
                else
                    # Fallback to legacy indicator
                    prayer_display="$prayer_display $PRAYER_NEXT_INDICATOR"
                fi
                
                # Apply color highlighting if enabled
                if [[ "$CONFIG_PRAYER_NEXT_PRAYER_COLOR_ENABLED" == "true" ]]; then
                    prayer_display=$(apply_next_prayer_color "$prayer_display")
                fi
            fi
            ;;
            
        "$PRAYER_STATUS_UPCOMING")
            # No special formatting for upcoming prayers
            ;;
    esac
    
    echo "$prayer_display"
    return 0
}

# Apply color to next prayer display
apply_next_prayer_color() {
    local prayer_display="$1"
    
    # Choose color based on configuration
    local next_color=""
    case "$CONFIG_PRAYER_NEXT_PRAYER_COLOR" in
        "green")
            next_color="$CONFIG_GREEN"
            ;;
        "bright_green")
            next_color="$CONFIG_BRIGHT_GREEN"
            ;;
        "teal")
            next_color="$CONFIG_TEAL"
            ;;
        "yellow")
            next_color="$CONFIG_YELLOW"
            ;;
        "bright_yellow")
            next_color="$CONFIG_BRIGHT_YELLOW"
            ;;
        "blue")
            next_color="$CONFIG_BLUE"
            ;;
        "bright_blue")
            next_color="$CONFIG_BRIGHT_BLUE"
            ;;
        "magenta")
            next_color="$CONFIG_MAGENTA"
            ;;
        "bright_magenta")
            next_color="$CONFIG_BRIGHT_MAGENTA"
            ;;
        *)
            next_color="$CONFIG_BRIGHT_GREEN"  # Default
            ;;
    esac
    
    # Apply color to entire prayer display
    echo "${next_color}${prayer_display}${CONFIG_RESET}"
}

# ============================================================================
# COMPACT DISPLAY MODES (FUTURE ENHANCEMENT)
# ============================================================================

# Get compact prayer display (shows only next prayer)
get_compact_prayer_display() {
    debug_log "Generating compact prayer display..." "INFO"
    
    # Load prayer configuration
    load_prayer_config
    
    # Get prayer data
    local prayer_data
    prayer_data=$(get_prayer_times_and_hijri)
    
    if [[ $? -ne 0 || -z "$prayer_data" ]]; then
        debug_log "Failed to get prayer data for compact display" "ERROR"
        echo "${HIJRI_INDICATOR} N/A"
        return 1
    fi
    
    # Parse prayer data
    IFS='|' read -r prayer_times prayer_statuses hijri_date current_time <<< "$prayer_data"
    
    # Get next prayer info
    local next_info="${prayer_statuses#*|}"
    IFS='|' read -r next_prayer next_prayer_time next_prayer_index <<< "$next_info"
    
    # Format next prayer time
    local formatted_time=$(format_prayer_time "$next_prayer_time")
    
    # Calculate time remaining
    local minutes_until=$(calculate_time_until_prayer "$current_time" "$next_prayer_time")
    local time_remaining=$(format_time_remaining "$minutes_until")
    
    echo "${HIJRI_INDICATOR} $next_prayer $formatted_time ($time_remaining)"
    return 0
}

# Get prayer status summary (shows prayer completion status)
get_prayer_status_summary() {
    debug_log "Generating prayer status summary..." "INFO"
    
    # Load prayer configuration  
    load_prayer_config
    
    # Get prayer data
    local prayer_data
    prayer_data=$(get_prayer_times_and_hijri)
    
    if [[ $? -ne 0 || -z "$prayer_data" ]]; then
        debug_log "Failed to get prayer data for status summary" "ERROR"
        return 1
    fi
    
    # Parse prayer data
    IFS='|' read -r prayer_times prayer_statuses hijri_date current_time <<< "$prayer_data"
    
    # Count completed prayers
    local status_info="${prayer_statuses%%|*}"
    IFS=',' read -ra statuses <<< "$status_info"
    
    local completed_count=0
    for status in "${statuses[@]}"; do
        if [[ "$status" == "$PRAYER_STATUS_COMPLETED" ]]; then
            ((completed_count++))
        fi
    done
    
    echo "${HIJRI_INDICATOR} ${completed_count}/5 completed"
    return 0
}

debug_log "Prayer display module loaded successfully" "INFO"