#!/bin/bash

# ============================================================================
# Claude Code Statusline - Component System
# ============================================================================
# 
# This module provides the component registry and base functionality for the
# modular statusline system. Components are self-contained modules that can
# collect data and render display output.
#
# Dependencies: core.sh, config.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_COMPONENTS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_COMPONENTS_LOADED=true

# ============================================================================
# COMPONENT REGISTRY
# ============================================================================

# Component registry - associative array of registered components
declare -gA STATUSLINE_COMPONENT_REGISTRY=()
declare -ga STATUSLINE_COMPONENT_ORDER=()

# Component metadata
declare -gA COMPONENT_DESCRIPTIONS=()
declare -gA COMPONENT_DEPENDENCIES=()
declare -gA COMPONENT_ENABLED=()

# ============================================================================
# COMPONENT BASE STRUCTURE
# ============================================================================

# Component interface - every component must implement these functions:
# - collect_${component_name}_data() - Gather component data  
# - render_${component_name}() - Format display output
# - get_${component_name}_config() - Get component configuration

# ============================================================================
# COMPONENT REGISTRATION
# ============================================================================

# Register a component in the system
register_component() {
    local component_name="$1"
    local description="$2"
    local dependencies="$3"
    local enabled="${4:-true}"
    
    if [[ -z "$component_name" ]]; then
        handle_error "Component name required for registration" "register_component"
        return 1
    fi
    
    # Validate component functions exist
    if ! type "collect_${component_name}_data" &>/dev/null; then
        handle_warning "collect_${component_name}_data function not found" "register_component"
    fi
    
    if ! type "render_${component_name}" &>/dev/null; then
        handle_warning "render_${component_name} function not found" "register_component"
    fi
    
    # Register component
    STATUSLINE_COMPONENT_REGISTRY["$component_name"]="$component_name"
    COMPONENT_DESCRIPTIONS["$component_name"]="$description"
    COMPONENT_DEPENDENCIES["$component_name"]="$dependencies"
    COMPONENT_ENABLED["$component_name"]="$enabled"
    
    # Add to order list if not already present
    if [[ ! " ${STATUSLINE_COMPONENT_ORDER[@]} " =~ " ${component_name} " ]]; then
        STATUSLINE_COMPONENT_ORDER+=("$component_name")
    fi
    
    debug_log "Registered component: $component_name" "INFO"
    return 0
}

# Check if component is registered
is_component_registered() {
    local component_name="$1"
    [[ -n "${STATUSLINE_COMPONENT_REGISTRY[$component_name]:-}" ]]
}

# Check if component is enabled
is_component_enabled() {
    local component_name="$1"
    local enabled="${COMPONENT_ENABLED[$component_name]:-true}"
    [[ "$enabled" == "true" ]]
}

# Get all registered components
get_registered_components() {
    printf '%s\n' "${STATUSLINE_COMPONENT_ORDER[@]}"
}

# Get component description
get_component_description() {
    local component_name="$1"
    echo "${COMPONENT_DESCRIPTIONS[$component_name]:-No description}"
}

# ============================================================================
# COMPONENT DATA COLLECTION
# ============================================================================

# Collect data for a specific component
collect_component_data() {
    local component_name="$1"
    
    if ! is_component_registered "$component_name"; then
        handle_warning "Component $component_name not registered" "collect_component_data"
        return 1
    fi
    
    if ! is_component_enabled "$component_name"; then
        debug_log "Component $component_name disabled, skipping data collection" "INFO"
        return 0
    fi
    
    # Check dependencies
    local dependencies="${COMPONENT_DEPENDENCIES[$component_name]:-}"
    if [[ -n "$dependencies" ]]; then
        for dep in $dependencies; do
            if ! is_module_loaded "$dep"; then
                debug_log "Component $component_name disabled - missing dependency: $dep" "WARN"
                return 1
            fi
        done
    fi
    
    # Call component's data collection function
    local collect_func="collect_${component_name}_data"
    if type "$collect_func" &>/dev/null; then
        debug_log "Collecting data for component: $component_name" "INFO"
        "$collect_func"
    else
        handle_warning "Data collection function not found: $collect_func" "collect_component_data"
        return 1
    fi
}

# Get all components configured for display across all lines
get_configured_components() {
    local max_lines="${CONFIG_DISPLAY_LINES:-7}"
    declare -A seen_components
    local components_list=""

    for line_num in $(seq 1 "$max_lines"); do
        local line_config=""
        case "$line_num" in
            1) line_config="$CONFIG_LINE1_COMPONENTS" ;;
            2) line_config="$CONFIG_LINE2_COMPONENTS" ;;
            3) line_config="$CONFIG_LINE3_COMPONENTS" ;;
            4) line_config="$CONFIG_LINE4_COMPONENTS" ;;
            5) line_config="$CONFIG_LINE5_COMPONENTS" ;;
            6) line_config="$CONFIG_LINE6_COMPONENTS" ;;
            7) line_config="$CONFIG_LINE7_COMPONENTS" ;;
            8) line_config="$CONFIG_LINE8_COMPONENTS" ;;
            9) line_config="$CONFIG_LINE9_COMPONENTS" ;;
        esac

        [[ -z "$line_config" ]] && continue

        # Parse comma-separated list
        IFS=',' read -ra component_array <<< "$line_config"
        for component in "${component_array[@]}"; do
            # Trim whitespace
            component=$(echo "$component" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$component" ]] && continue

            # Only add if not seen before
            if [[ -z "${seen_components[$component]:-}" ]]; then
                seen_components["$component"]=1
                [[ -n "$components_list" ]] && components_list+=" "
                components_list+="$component"
            fi
        done
    done

    echo "$components_list"
}

# Collect data for only configured components (optimized)
# Uses guard to prevent double collection in same execution
declare -g _COMPONENT_DATA_COLLECTED=""

collect_all_component_data() {
    # Guard: skip if already collected in this execution
    if [[ "$_COMPONENT_DATA_COLLECTED" == "true" ]]; then
        debug_log "Component data already collected, skipping" "INFO"
        return 0
    fi

    debug_log "Starting component data collection phase" "INFO"
    start_timer "component_data_collection"

    local collected_count=0
    local configured_components
    configured_components=$(get_configured_components)

    if [[ -z "$configured_components" ]]; then
        debug_log "No components configured for display, skipping collection" "WARN"
        return 0
    fi

    debug_log "Configured components: $configured_components" "INFO"

    # Only collect data for configured components
    for component_name in $configured_components; do
        if is_component_registered "$component_name"; then
            if collect_component_data "$component_name"; then
                collected_count=$((collected_count + 1))
            fi
        else
            debug_log "Component $component_name not registered, skipping" "WARN"
        fi
    done

    local collection_time
    collection_time=$(end_timer "component_data_collection")
    debug_log "Collected data for $collected_count components in ${collection_time}s" "INFO"

    # Set guard to prevent double collection
    _COMPONENT_DATA_COLLECTED="true"
}

# ============================================================================
# COMPONENT RENDERING
# ============================================================================

# Render a specific component
render_component() {
    local component_name="$1"
    
    if ! is_component_registered "$component_name"; then
        handle_warning "Component $component_name not registered" "render_component"
        return 1
    fi
    
    if ! is_component_enabled "$component_name"; then
        debug_log "Component $component_name disabled, skipping render" "INFO"
        return 0
    fi
    
    # Call component's render function
    local render_func="render_${component_name}"
    if type "$render_func" &>/dev/null; then
        debug_log "Rendering component: $component_name" "INFO"
        "$render_func"
    else
        handle_warning "Render function not found: $render_func" "render_component"
        return 1
    fi
}

# ============================================================================
# LINE BUILDING SYSTEM
# ============================================================================

# Build a statusline from configured components for a specific line
build_component_line() {
    local line_number="$1"
    local components_config="$2"
    local separator="${3:- │ }"
    
    if [[ -z "$components_config" ]]; then
        debug_log "No components configured for line $line_number" "INFO"
        return 0
    fi
    
    local line_output=""
    local rendered_count=0
    
    # Parse components list (comma-separated)
    IFS=',' read -ra component_list <<< "$components_config"
    
    for component_name in "${component_list[@]}"; do
        # Trim whitespace
        component_name=$(echo "$component_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ -z "$component_name" ]]; then
            continue
        fi
        
        # Render component
        local component_output
        component_output=$(render_component "$component_name")
        
        if [[ $? -eq 0 && -n "$component_output" ]]; then
            if [[ -n "$line_output" ]]; then
                line_output="${line_output}${separator}${component_output}"
            else
                line_output="$component_output"
            fi
            rendered_count=$((rendered_count + 1))
        fi
    done
    
    if [[ $rendered_count -gt 0 ]]; then
        echo "$line_output"
        return 0
    else
        debug_log "No components rendered for line $line_number" "INFO"
        return 1
    fi
}

# ============================================================================
# CONFIGURATION HELPERS
# ============================================================================

# Get component configuration value
get_component_config() {
    local component_name="$1"
    local config_key="$2"
    local default_value="$3"
    
    # Try component-specific config first
    local config_var="CONFIG_COMPONENT_${component_name^^}_${config_key^^}"
    local value="${!config_var:-}"
    
    # Fall back to general component config
    if [[ -z "$value" ]]; then
        config_var="CONFIG_COMPONENTS_${config_key^^}"
        value="${!config_var:-}"
    fi
    
    # Use default if still empty
    echo "${value:-$default_value}"
}

# Set component enabled state
set_component_enabled() {
    local component_name="$1"
    local enabled="$2"
    
    COMPONENT_ENABLED["$component_name"]="$enabled"
    debug_log "Component $component_name enabled: $enabled" "INFO"
}

# ============================================================================
# COMPONENT DISCOVERY AND LOADING
# ============================================================================

# Load component modules from lib/components/ directory
load_component_modules() {
    local components_dir="$SCRIPT_DIR/lib/components"
    
    if [[ ! -d "$components_dir" ]]; then
        debug_log "Components directory not found: $components_dir" "WARN"
        return 1
    fi
    
    debug_log "Loading component modules from: $components_dir" "INFO"
    local loaded_count=0
    
    # Load all .sh files in components directory
    for component_file in "$components_dir"/*.sh; do
        if [[ -f "$component_file" ]]; then
            local component_basename
            component_basename=$(basename "$component_file" .sh)
            
            debug_log "Loading component module: $component_basename" "INFO"
            
            if source "$component_file"; then
                loaded_count=$((loaded_count + 1))
                debug_log "Successfully loaded component: $component_basename" "INFO"
            else
                handle_warning "Failed to load component: $component_basename" "load_component_modules"
            fi
        fi
    done
    
    debug_log "Loaded $loaded_count component modules" "INFO"
    return 0
}

# ============================================================================
# COMPONENT SYSTEM STATUS
# ============================================================================

# Display component system status
show_component_status() {
    echo "Component System Status:"
    echo "========================"
    echo "Registered components: ${#STATUSLINE_COMPONENT_REGISTRY[@]}"
    echo ""
    
    for component_name in "${STATUSLINE_COMPONENT_ORDER[@]}"; do
        local enabled_status="✗"
        if is_component_enabled "$component_name"; then
            enabled_status="✓"
        fi
        
        local description="${COMPONENT_DESCRIPTIONS[$component_name]:-No description}"
        local dependencies="${COMPONENT_DEPENDENCIES[$component_name]:-none}"
        
        echo "  $enabled_status $component_name - $description"
        echo "    Dependencies: $dependencies"
    done
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the component system
init_component_system() {
    debug_log "Component system initialized" "INFO"
    
    # Load component modules if directory exists
    load_component_modules
    
    debug_log "Component registry ready with ${#STATUSLINE_COMPONENT_REGISTRY[@]} components" "INFO"
    return 0
}

# Note: init_component_system should be called explicitly from the main script
# after SCRIPT_DIR is properly set. Do not auto-initialize here.

# Issue #134: exports removed - component functions run in main process only

debug_log "Component system module loaded successfully" "INFO"