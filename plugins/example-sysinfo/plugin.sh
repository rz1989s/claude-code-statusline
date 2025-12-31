#!/bin/bash

# ============================================================================
# Example Plugin - System Information Component
# ============================================================================
#
# This plugin demonstrates how to create custom components for the statusline.
# It adds a system information display showing load average and uptime.
#
# To use this plugin:
#   1. Enable plugins in Config.toml: plugins.enabled = true
#   2. Add "example-sysinfo" to your line components:
#      display.line4.components = ["example-sysinfo"]
#
# ============================================================================

# Plugin configuration (can be overridden by plugin.toml or environment)
PLUGIN_SYSINFO_SHOW_LOAD="${PLUGIN_SYSINFO_SHOW_LOAD:-true}"
PLUGIN_SYSINFO_SHOW_UPTIME="${PLUGIN_SYSINFO_SHOW_UPTIME:-true}"
PLUGIN_SYSINFO_COMPACT="${PLUGIN_SYSINFO_COMPACT:-true}"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get system load average (1-minute)
get_system_load() {
    local load

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS: use sysctl
        load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
    else
        # Linux: read from /proc/loadavg
        load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}')
    fi

    echo "${load:-0.00}"
}

# Get system uptime in human-readable format
get_system_uptime() {
    local uptime_str

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS: parse uptime output
        local boot_time
        boot_time=$(sysctl -n kern.boottime 2>/dev/null | awk -F'[ ,]' '{print $4}')
        if [[ -n "$boot_time" ]]; then
            local now
            now=$(date +%s)
            local uptime_secs=$((now - boot_time))
            local days=$((uptime_secs / 86400))
            local hours=$(((uptime_secs % 86400) / 3600))
            local mins=$(((uptime_secs % 3600) / 60))

            if [[ $days -gt 0 ]]; then
                uptime_str="${days}d ${hours}h"
            elif [[ $hours -gt 0 ]]; then
                uptime_str="${hours}h ${mins}m"
            else
                uptime_str="${mins}m"
            fi
        fi
    else
        # Linux: read from /proc/uptime
        local uptime_secs
        uptime_secs=$(cat /proc/uptime 2>/dev/null | awk '{print int($1)}')
        if [[ -n "$uptime_secs" ]]; then
            local days=$((uptime_secs / 86400))
            local hours=$(((uptime_secs % 86400) / 3600))
            local mins=$(((uptime_secs % 3600) / 60))

            if [[ $days -gt 0 ]]; then
                uptime_str="${days}d ${hours}h"
            elif [[ $hours -gt 0 ]]; then
                uptime_str="${hours}h ${mins}m"
            else
                uptime_str="${mins}m"
            fi
        fi
    fi

    echo "${uptime_str:-unknown}"
}

# ============================================================================
# MAIN COMPONENT FUNCTION
# ============================================================================

# This is the main function called by the plugin system
# It must follow the naming convention: get_<plugin_name>_component
get_example_sysinfo_component() {
    local output=""
    local separator=" "

    # Get load average if enabled
    if [[ "${PLUGIN_SYSINFO_SHOW_LOAD}" == "true" ]]; then
        local load
        load=$(get_system_load)

        if [[ "${PLUGIN_SYSINFO_COMPACT}" == "true" ]]; then
            output="Load:${load}"
        else
            output="Load Average: ${load}"
        fi
    fi

    # Get uptime if enabled
    if [[ "${PLUGIN_SYSINFO_SHOW_UPTIME}" == "true" ]]; then
        local uptime
        uptime=$(get_system_uptime)

        if [[ -n "$output" ]]; then
            output="${output}${separator}"
        fi

        if [[ "${PLUGIN_SYSINFO_COMPACT}" == "true" ]]; then
            output="${output}Up:${uptime}"
        else
            output="${output}Uptime: ${uptime}"
        fi
    fi

    # Return empty if nothing enabled
    if [[ -z "$output" ]]; then
        return 0
    fi

    echo "$output"
}

# Alternative generic function name (also supported)
get_component() {
    get_example_sysinfo_component
}
