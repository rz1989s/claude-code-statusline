#!/bin/bash

# ============================================================================
# Claude Code Statusline - Plugin System Module (Issue #90)
# ============================================================================
#
# This module handles plugin discovery, loading, validation, and execution.
# Plugins can add custom components to the statusline.
#
# Plugin Structure:
#   ~/.claude/statusline/plugins/
#   ├── my-plugin/
#   │   ├── plugin.toml      # Metadata (optional)
#   │   └── plugin.sh        # Implementation (required)
#
# Dependencies: core.sh, security.sh
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_PLUGINS_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_PLUGINS_LOADED=true

# ============================================================================
# PLUGIN CONFIGURATION DEFAULTS
# ============================================================================

CONFIG_PLUGINS_ENABLED="${CONFIG_PLUGINS_ENABLED:-false}"
CONFIG_PLUGINS_AUTO_DISCOVERY="${CONFIG_PLUGINS_AUTO_DISCOVERY:-true}"
CONFIG_PLUGINS_DIRS="${CONFIG_PLUGINS_DIRS:-~/.claude/statusline/plugins,./plugins}"
CONFIG_PLUGINS_TIMEOUT="${CONFIG_PLUGINS_TIMEOUT:-5s}"
CONFIG_PLUGINS_VALIDATE="${CONFIG_PLUGINS_VALIDATE:-true}"
CONFIG_PLUGINS_ALLOW_NETWORK="${CONFIG_PLUGINS_ALLOW_NETWORK:-false}"
CONFIG_PLUGINS_DEBUG="${CONFIG_PLUGINS_DEBUG:-false}"

# Signature verification settings (Issue #120)
CONFIG_PLUGINS_REQUIRE_SIGNATURE="${CONFIG_PLUGINS_REQUIRE_SIGNATURE:-false}"
CONFIG_PLUGINS_WARN_UNSIGNED="${CONFIG_PLUGINS_WARN_UNSIGNED:-true}"
CONFIG_PLUGINS_TRUSTED_KEYS="${CONFIG_PLUGINS_TRUSTED_KEYS:-}"
CONFIG_PLUGINS_KEYSERVER="${CONFIG_PLUGINS_KEYSERVER:-hkps://keys.openpgp.org}"

# Plugin registry (associative array: plugin_name -> plugin_path)
declare -A LOADED_PLUGINS
declare -A PLUGIN_COMPONENTS

# Dangerous patterns for security validation
DANGEROUS_PATTERNS=(
    'rm -rf'
    'rm -fr'
    'mkfs'
    'dd if='
    '> /dev/'
    'chmod 777'
    'curl .* \| *(ba)?sh'
    'wget .* \| *(ba)?sh'
    '\beval\b'
    'source /dev'
)

# Signature verification status tracking
declare -A PLUGIN_SIGNATURE_STATUS

# ============================================================================
# SIGNATURE VERIFICATION (Issue #120)
# ============================================================================

# Check if GPG is available
is_gpg_available() {
    command_exists gpg || command_exists gpg2
}

# Get GPG command (prefer gpg2 if available)
get_gpg_cmd() {
    if command_exists gpg2; then
        echo "gpg2"
    elif command_exists gpg; then
        echo "gpg"
    else
        echo ""
    fi
}

# Validate plugin signature using GPG
# Returns:
#   0 = Valid signature
#   1 = No signature file found
#   2 = Invalid signature
#   3 = GPG not available
#   4 = Untrusted key
validate_plugin_signature() {
    local plugin_path="$1"
    local plugin_name="$2"
    local plugin_script="${plugin_path}plugin.sh"
    local sig_path="${plugin_script}.sig"
    local asc_path="${plugin_script}.asc"

    plugin_debug "Checking signature for $plugin_name"

    # Check if GPG is available
    local gpg_cmd
    gpg_cmd=$(get_gpg_cmd)
    if [[ -z "$gpg_cmd" ]]; then
        plugin_debug "GPG not available for signature verification"
        PLUGIN_SIGNATURE_STATUS["$plugin_name"]="gpg_unavailable"
        return 3
    fi

    # Check for signature file (.sig or .asc)
    local sig_file=""
    if [[ -f "$sig_path" ]]; then
        sig_file="$sig_path"
    elif [[ -f "$asc_path" ]]; then
        sig_file="$asc_path"
    fi

    if [[ -z "$sig_file" ]]; then
        plugin_debug "No signature file found for $plugin_name"
        PLUGIN_SIGNATURE_STATUS["$plugin_name"]="unsigned"
        return 1
    fi

    plugin_debug "Found signature file: $sig_file"

    # Check if we have trusted keys configured
    local trusted_keys="${CONFIG_PLUGINS_TRUSTED_KEYS:-}"
    local keyring_args=""

    if [[ -n "$trusted_keys" ]]; then
        # If specific keys are configured, verify against them
        plugin_debug "Checking against trusted keys: $trusted_keys"
    fi

    # Verify the signature
    local verify_output
    local verify_result

    verify_output=$("$gpg_cmd" --verify "$sig_file" "$plugin_script" 2>&1)
    verify_result=$?

    if [[ $verify_result -eq 0 ]]; then
        # Signature valid
        local signer_key
        signer_key=$(echo "$verify_output" | grep -oE '[A-F0-9]{16,}' | head -1)

        # Check if key is in trusted list (if configured)
        if [[ -n "$trusted_keys" ]]; then
            local key_trusted=false
            # Parse comma-separated trusted keys
            IFS=',' read -ra KEYS <<< "$trusted_keys"
            for key in "${KEYS[@]}"; do
                key=$(echo "$key" | xargs)  # Trim whitespace
                if [[ "$verify_output" == *"$key"* ]]; then
                    key_trusted=true
                    break
                fi
            done

            if [[ "$key_trusted" != "true" ]]; then
                plugin_debug "Signature valid but key not in trusted list: $signer_key"
                PLUGIN_SIGNATURE_STATUS["$plugin_name"]="untrusted:$signer_key"
                return 4
            fi
        fi

        plugin_debug "Valid signature for $plugin_name (key: ${signer_key:-unknown})"
        PLUGIN_SIGNATURE_STATUS["$plugin_name"]="valid:${signer_key:-unknown}"
        return 0
    else
        # Invalid signature
        plugin_debug "Invalid signature for $plugin_name: $verify_output"
        PLUGIN_SIGNATURE_STATUS["$plugin_name"]="invalid"
        return 2
    fi
}

# Get signature status for a plugin
get_plugin_signature_status() {
    local plugin_name="$1"
    echo "${PLUGIN_SIGNATURE_STATUS[$plugin_name]:-unknown}"
}

# Check if unsigned plugins should be allowed
should_allow_unsigned() {
    [[ "${CONFIG_PLUGINS_REQUIRE_SIGNATURE:-false}" != "true" ]]
}

# ============================================================================
# PLUGIN SYSTEM UTILITIES
# ============================================================================

# Check if plugins are enabled
is_plugins_enabled() {
    [[ "${CONFIG_PLUGINS_ENABLED:-false}" == "true" ]]
}

# Expand ~ to home directory
expand_plugin_path() {
    local path="$1"
    echo "${path/#\~/$HOME}"
}

# Get list of plugin directories
get_plugin_dirs() {
    local dirs="${CONFIG_PLUGINS_DIRS:-}"
    # Handle both comma-separated and array formats
    dirs=$(echo "$dirs" | tr -d '[]"' | tr ',' '\n')
    echo "$dirs"
}

# Debug log for plugins
plugin_debug() {
    local message="$1"
    if [[ "${CONFIG_PLUGINS_DEBUG:-false}" == "true" ]]; then
        debug_log "[PLUGIN] $message" "INFO"
    fi
}

# ============================================================================
# PLUGIN DISCOVERY
# ============================================================================

# Discover plugins in configured directories
discover_plugins() {
    if ! is_plugins_enabled; then
        plugin_debug "Plugin system disabled"
        return 0
    fi

    plugin_debug "Starting plugin discovery..."

    local discovered=0

    while IFS= read -r plugin_dir; do
        [[ -z "$plugin_dir" ]] && continue

        plugin_dir=$(expand_plugin_path "$plugin_dir")
        plugin_dir=$(echo "$plugin_dir" | xargs)  # Trim whitespace

        if [[ ! -d "$plugin_dir" ]]; then
            plugin_debug "Plugin directory not found: $plugin_dir"
            continue
        fi

        plugin_debug "Scanning directory: $plugin_dir"

        # Find plugin directories (contain plugin.sh)
        for plugin_path in "$plugin_dir"/*/; do
            [[ ! -d "$plugin_path" ]] && continue

            local plugin_name
            plugin_name=$(basename "$plugin_path")

            local plugin_script="${plugin_path}plugin.sh"

            if [[ -f "$plugin_script" ]]; then
                plugin_debug "Found plugin: $plugin_name at $plugin_path"
                LOADED_PLUGINS["$plugin_name"]="$plugin_path"
                ((discovered++))
            fi
        done
    done <<< "$(get_plugin_dirs)"

    plugin_debug "Discovered $discovered plugins"
    return 0
}

# ============================================================================
# PLUGIN VALIDATION
# ============================================================================

# Check plugin script for dangerous patterns
validate_plugin_security() {
    local plugin_script="$1"
    local plugin_name="$2"

    if [[ "${CONFIG_PLUGINS_VALIDATE:-true}" != "true" ]]; then
        plugin_debug "Security validation disabled for $plugin_name"
        return 0
    fi

    plugin_debug "Validating security for $plugin_name"

    # Read plugin content
    local content
    content=$(cat "$plugin_script" 2>/dev/null)

    if [[ -z "$content" ]]; then
        debug_log "Empty or unreadable plugin: $plugin_name" "WARN"
        return 1
    fi

    # Check for dangerous patterns
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$content" | grep -qE "$pattern"; then
            debug_log "SECURITY: Dangerous pattern '$pattern' found in plugin $plugin_name" "ERROR"
            return 1
        fi
    done

    # Check for network calls if not allowed
    if [[ "${CONFIG_PLUGINS_ALLOW_NETWORK:-false}" != "true" ]]; then
        if echo "$content" | grep -qE '(curl|wget|nc |netcat)'; then
            debug_log "SECURITY: Network call found in plugin $plugin_name (not allowed)" "WARN"
            return 1
        fi
    fi

    plugin_debug "Security validation passed for $plugin_name"
    return 0
}

# Validate plugin has required structure
validate_plugin_structure() {
    local plugin_path="$1"
    local plugin_name="$2"

    local plugin_script="${plugin_path}plugin.sh"

    # Check plugin.sh exists and is readable
    if [[ ! -f "$plugin_script" || ! -r "$plugin_script" ]]; then
        debug_log "Plugin $plugin_name missing or unreadable plugin.sh" "WARN"
        return 1
    fi

    # Check for component function
    local component_func="get_${plugin_name}_component"
    if ! grep -q "$component_func" "$plugin_script"; then
        # Also check for generic component function
        if ! grep -q "get_component" "$plugin_script"; then
            debug_log "Plugin $plugin_name missing component function ($component_func or get_component)" "WARN"
            return 1
        fi
    fi

    plugin_debug "Structure validation passed for $plugin_name"
    return 0
}

# ============================================================================
# PLUGIN LOADING
# ============================================================================

# Load a single plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_path="${LOADED_PLUGINS[$plugin_name]}"

    if [[ -z "$plugin_path" ]]; then
        debug_log "Plugin not found: $plugin_name" "WARN"
        return 1
    fi

    local plugin_script="${plugin_path}plugin.sh"

    plugin_debug "Loading plugin: $plugin_name from $plugin_path"

    # Validate structure
    if ! validate_plugin_structure "$plugin_path" "$plugin_name"; then
        return 1
    fi

    # Validate signature (Issue #120)
    local sig_result
    validate_plugin_signature "$plugin_path" "$plugin_name"
    sig_result=$?

    case $sig_result in
        0)
            # Valid signature - proceed
            plugin_debug "Plugin $plugin_name has valid signature"
            ;;
        1)
            # Unsigned plugin
            if ! should_allow_unsigned; then
                debug_log "SECURITY: Plugin $plugin_name is unsigned (signatures required)" "ERROR"
                return 1
            elif [[ "${CONFIG_PLUGINS_WARN_UNSIGNED:-true}" == "true" ]]; then
                debug_log "WARNING: Plugin $plugin_name is unsigned" "WARN"
            fi
            ;;
        2)
            # Invalid signature - always reject
            debug_log "SECURITY: Plugin $plugin_name has INVALID signature - refusing to load" "ERROR"
            return 1
            ;;
        3)
            # GPG not available
            if ! should_allow_unsigned; then
                debug_log "SECURITY: Cannot verify plugin $plugin_name (GPG unavailable, signatures required)" "ERROR"
                return 1
            fi
            plugin_debug "GPG unavailable, skipping signature check for $plugin_name"
            ;;
        4)
            # Untrusted key
            debug_log "SECURITY: Plugin $plugin_name signed by untrusted key - refusing to load" "ERROR"
            return 1
            ;;
    esac

    # Validate security (pattern-based)
    if ! validate_plugin_security "$plugin_script" "$plugin_name"; then
        return 1
    fi

    # Source the plugin (in subshell for safety, but we need functions)
    # shellcheck disable=SC1090
    if source "$plugin_script" 2>/dev/null; then
        # Register the component
        local component_func="get_${plugin_name}_component"

        if declare -f "$component_func" >/dev/null 2>&1; then
            PLUGIN_COMPONENTS["$plugin_name"]="$component_func"
            plugin_debug "Registered component: $plugin_name -> $component_func"
        elif declare -f "get_component" >/dev/null 2>&1; then
            # Rename generic function to specific
            eval "${component_func}() { get_component; }"
            PLUGIN_COMPONENTS["$plugin_name"]="$component_func"
            plugin_debug "Registered generic component: $plugin_name -> get_component"
        fi

        debug_log "Plugin loaded successfully: $plugin_name" "INFO"
        return 0
    else
        debug_log "Failed to source plugin: $plugin_name" "WARN"
        return 1
    fi
}

# Load all discovered plugins
load_all_plugins() {
    if ! is_plugins_enabled; then
        return 0
    fi

    plugin_debug "Loading all discovered plugins..."

    local loaded=0
    local failed=0

    for plugin_name in "${!LOADED_PLUGINS[@]}"; do
        if load_plugin "$plugin_name"; then
            ((loaded++))
        else
            ((failed++))
        fi
    done

    plugin_debug "Loaded $loaded plugins, $failed failed"
    debug_log "Plugin system: $loaded loaded, $failed failed" "INFO"
}

# ============================================================================
# PLUGIN EXECUTION
# ============================================================================

# Execute a plugin component with timeout
execute_plugin_component() {
    local plugin_name="$1"
    local component_func="${PLUGIN_COMPONENTS[$plugin_name]}"

    if [[ -z "$component_func" ]]; then
        plugin_debug "No component registered for plugin: $plugin_name"
        echo ""
        return 1
    fi

    local timeout="${CONFIG_PLUGINS_TIMEOUT:-5s}"
    # Remove 's' suffix if present
    timeout="${timeout%s}"

    plugin_debug "Executing $component_func with ${timeout}s timeout"

    local result
    if command_exists timeout; then
        result=$(timeout "$timeout" bash -c "$component_func" 2>/dev/null)
    elif command_exists gtimeout; then
        result=$(gtimeout "$timeout" bash -c "$component_func" 2>/dev/null)
    else
        # No timeout available, run directly
        result=$($component_func 2>/dev/null)
    fi

    echo "$result"
}

# Check if a plugin component is available
is_plugin_component_available() {
    local plugin_name="$1"
    [[ -n "${PLUGIN_COMPONENTS[$plugin_name]}" ]]
}

# ============================================================================
# PLUGIN API FOR COMPONENTS
# ============================================================================

# Get output from a plugin component (for use in display)
get_plugin_output() {
    local plugin_name="$1"

    if ! is_plugins_enabled; then
        echo ""
        return 1
    fi

    if ! is_plugin_component_available "$plugin_name"; then
        echo ""
        return 1
    fi

    execute_plugin_component "$plugin_name"
}

# Get list of available plugin components
get_available_plugin_components() {
    if ! is_plugins_enabled; then
        echo ""
        return 0
    fi

    echo "${!PLUGIN_COMPONENTS[*]}"
}

# Get plugin info for display
get_plugin_info() {
    local plugin_name="$1"
    local plugin_path="${LOADED_PLUGINS[$plugin_name]}"

    if [[ -z "$plugin_path" ]]; then
        echo "not found"
        return 1
    fi

    local metadata_file="${plugin_path}plugin.toml"
    if [[ -f "$metadata_file" ]]; then
        # Try to extract version from TOML
        local version
        version=$(grep -E '^version\s*=' "$metadata_file" 2>/dev/null | head -1 | cut -d'"' -f2)
        echo "${plugin_name}@${version:-unknown}"
    else
        echo "${plugin_name}@local"
    fi
}

# ============================================================================
# PLUGIN MANAGEMENT
# ============================================================================

# Enable a specific plugin
enable_plugin() {
    local plugin_name="$1"

    if [[ -z "${LOADED_PLUGINS[$plugin_name]}" ]]; then
        debug_log "Cannot enable unknown plugin: $plugin_name" "WARN"
        return 1
    fi

    load_plugin "$plugin_name"
}

# Disable a specific plugin
disable_plugin() {
    local plugin_name="$1"

    unset "PLUGIN_COMPONENTS[$plugin_name]"
    plugin_debug "Disabled plugin: $plugin_name"
}

# Reload all plugins
reload_plugins() {
    # Clear current state
    LOADED_PLUGINS=()
    PLUGIN_COMPONENTS=()

    # Rediscover and reload
    discover_plugins
    load_all_plugins
}

# Get plugin system status
get_plugins_status() {
    if ! is_plugins_enabled; then
        echo "disabled"
        return 0
    fi

    local total="${#LOADED_PLUGINS[@]}"
    local active="${#PLUGIN_COMPONENTS[@]}"

    echo "enabled:$active/$total"
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize the plugins module
init_plugins_module() {
    debug_log "Plugins module initialized" "INFO"

    if is_plugins_enabled; then
        plugin_debug "Plugin system enabled, discovering plugins..."
        discover_plugins
        load_all_plugins

        local status
        status=$(get_plugins_status)
        debug_log "Plugin system status: $status" "INFO"
    else
        debug_log "Plugin system disabled" "INFO"
    fi

    return 0
}

# Initialize the module (skip during testing)
if [[ "${STATUSLINE_TESTING:-}" != "true" ]]; then
    init_plugins_module
fi

# Export plugin functions
export -f is_plugins_enabled expand_plugin_path get_plugin_dirs plugin_debug
export -f discover_plugins validate_plugin_security validate_plugin_structure
export -f load_plugin load_all_plugins execute_plugin_component
export -f is_plugin_component_available get_plugin_output get_available_plugin_components
export -f get_plugin_info enable_plugin disable_plugin reload_plugins get_plugins_status
# Signature verification exports (Issue #120)
export -f is_gpg_available get_gpg_cmd validate_plugin_signature
export -f get_plugin_signature_status should_allow_unsigned
