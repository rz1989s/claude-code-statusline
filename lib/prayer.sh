#!/bin/bash

# ============================================================================
# Claude Code Statusline - Islamic Prayer Times & Hijri Calendar Module (Modular)
# ============================================================================
# 
# This is the new modular version that replaces the monolithic prayer.sh.
# It loads focused modules for better maintainability and follows SRP principles.
#
# Dependencies: core.sh, security.sh, cache.sh, config.sh, themes.sh
# Modules: prayer/core.sh, prayer/location.sh, prayer/calculation.sh, prayer/display.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PRAYER_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PRAYER_LOADED=true

# ============================================================================
# MODULE LOADING
# ============================================================================

# Get the directory containing this script
PRAYER_MODULE_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Load prayer modules in dependency order
load_prayer_modules() {
    debug_log "Loading prayer modules..." "INFO"
    
    # Core module (constants, configuration, API with retry logic)
    if ! source "${PRAYER_MODULE_DIR}/prayer/core.sh"; then
        debug_log "Failed to load prayer core module" "ERROR"
        return 1
    fi
    
    # Location module (IP geolocation, caching, coordinate resolution)
    if ! source "${PRAYER_MODULE_DIR}/prayer/location.sh"; then
        debug_log "Failed to load prayer location module" "ERROR"
        return 1
    fi
    
    # Calculation module (prayer time processing, Hijri calculations)
    if ! source "${PRAYER_MODULE_DIR}/prayer/calculation.sh"; then
        debug_log "Failed to load prayer calculation module" "ERROR" 
        return 1
    fi
    
    # Display module (formatting, visualization)
    if ! source "${PRAYER_MODULE_DIR}/prayer/display.sh"; then
        debug_log "Failed to load prayer display module" "ERROR"
        return 1
    fi
    
    debug_log "All prayer modules loaded successfully" "INFO"
    return 0
}

# ============================================================================
# MODULE INITIALIZATION  
# ============================================================================

# Initialize prayer system
initialize_prayer_system() {
    debug_log "Initializing prayer system..." "INFO"
    
    # Load all modules
    if ! load_prayer_modules; then
        debug_log "Prayer module loading failed" "ERROR"
        return 1
    fi
    
    # Load configuration
    if ! load_prayer_config; then
        debug_log "Prayer configuration loading failed" "ERROR"
        return 1
    fi
    
    debug_log "Prayer system initialized successfully" "INFO"
    return 0
}

# ============================================================================
# PUBLIC API
# ============================================================================

# Main entry point for prayer display (used by statusline.sh)
get_prayer_display() {
    # Ensure system is initialized
    if [[ "${STATUSLINE_PRAYER_CORE_LOADED:-}" != "true" ]]; then
        if ! initialize_prayer_system; then
            debug_log "Prayer system initialization failed" "ERROR"
            echo "${HIJRI_INDICATOR:-🕌} Prayer system unavailable"
            return 1
        fi
    fi
    
    # Check if prayer display is enabled
    if [[ "$CONFIG_PRAYER_ENABLED" != "true" ]]; then
        debug_log "Prayer display is disabled in configuration" "INFO"
        return 1
    fi
    
    # Generate display
    if ! get_prayer_display; then
        debug_log "Failed to generate prayer display" "ERROR"
        echo "${HIJRI_INDICATOR:-🕌} Display generation failed"
        return 1
    fi
    
    return 0
}

# Get compact prayer display (shows only next prayer)
get_compact_prayer_display() {
    # Ensure system is initialized
    if [[ "${STATUSLINE_PRAYER_CORE_LOADED:-}" != "true" ]]; then
        if ! initialize_prayer_system; then
            debug_log "Prayer system initialization failed" "ERROR"
            return 1
        fi
    fi
    
    # Generate compact display (delegates to display module)
    get_compact_prayer_display
}

# Get prayer status summary
get_prayer_status_summary() {
    # Ensure system is initialized
    if [[ "${STATUSLINE_PRAYER_CORE_LOADED:-}" != "true" ]]; then
        if ! initialize_prayer_system; then
            debug_log "Prayer system initialization failed" "ERROR"
            return 1
        fi
    fi
    
    # Generate status summary (delegates to display module)
    get_prayer_status_summary
}

# ============================================================================
# DEBUGGING AND DIAGNOSTICS
# ============================================================================

# Show prayer system status for debugging
show_prayer_system_status() {
    echo "Prayer System Status:"
    echo "===================="
    echo "Core Module Loaded: ${STATUSLINE_PRAYER_CORE_LOADED:-false}"
    echo "Location Module Loaded: ${STATUSLINE_PRAYER_LOCATION_LOADED:-false}"
    echo "Calculation Module Loaded: ${STATUSLINE_PRAYER_CALCULATION_LOADED:-false}"
    echo "Display Module Loaded: ${STATUSLINE_PRAYER_DISPLAY_LOADED:-false}"
    echo "Timezone Methods Loaded: ${STATUSLINE_PRAYER_TIMEZONE_METHODS_LOADED:-false}"
    echo ""
    echo "Configuration:"
    echo "Prayer Enabled: ${CONFIG_PRAYER_ENABLED:-not set}"
    echo "Location Mode: ${CONFIG_PRAYER_LOCATION_MODE:-not set}"
    echo "Calculation Method: ${CONFIG_PRAYER_CALCULATION_METHOD:-not set}"
    echo "Coordinates: ${CONFIG_PRAYER_LATITUDE:-not set},${CONFIG_PRAYER_LONGITUDE:-not set}"
    echo "Timezone: ${CONFIG_PRAYER_TIMEZONE:-not set}"
}

# Test prayer module functionality
test_prayer_modules() {
    echo "Testing Prayer Modules:"
    echo "======================"
    
    if initialize_prayer_system; then
        echo "✓ Module initialization: SUCCESS"
    else
        echo "✗ Module initialization: FAILED"
        return 1
    fi
    
    if coordinates=$(get_location_coordinates); then
        echo "✓ Location detection: SUCCESS ($coordinates)"
    else
        echo "✗ Location detection: FAILED"
    fi
    
    if prayer_data=$(get_prayer_times_and_hijri); then
        echo "✓ Prayer data retrieval: SUCCESS"
    else
        echo "✗ Prayer data retrieval: FAILED"
    fi
    
    if display=$(get_prayer_display); then
        echo "✓ Prayer display generation: SUCCESS"
        echo "Display: $display"
    else
        echo "✗ Prayer display generation: FAILED"
    fi
}

# ============================================================================
# AUTOMATIC INITIALIZATION
# ============================================================================

# Auto-initialize if not in test mode
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    initialize_prayer_system
fi

debug_log "Modular prayer module loaded successfully - Reduced from 1,536 to ~100 lines" "INFO"