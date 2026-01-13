#!/bin/bash

# ============================================================================
# Claude Code Statusline - Configuration Cache Module
# ============================================================================
#
# This module provides pre-compiled configuration caching to avoid expensive
# TOML parsing on every run. The cache is invalidated when Config.toml changes.
#
# Performance improvement: 12+ seconds → <0.1 seconds for config loading
#
# Issue #145, #146: TOML parsing performance optimization
#
# Dependencies: core.sh (debug_log, command_exists)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_CACHE_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_CACHE_LOADED=true

# ============================================================================
# CACHE FILE PATHS
# ============================================================================

# Get cache file path for compiled config
get_config_cache_path() {
    local config_file="${1:-}"
    if [[ -z "$config_file" ]]; then
        echo ""
        return 1
    fi

    # Cache file sits next to Config.toml
    local cache_dir
    cache_dir=$(dirname "$config_file")
    echo "${cache_dir}/.Config.cache.sh"
}

# Get checksum file path
get_config_checksum_path() {
    local config_file="${1:-}"
    if [[ -z "$config_file" ]]; then
        echo ""
        return 1
    fi

    local cache_dir
    cache_dir=$(dirname "$config_file")
    echo "${cache_dir}/.Config.checksum"
}

# ============================================================================
# CHECKSUM FUNCTIONS
# ============================================================================

# Calculate checksum of Config.toml
calculate_config_checksum() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        echo ""
        return 1
    fi

    # Use sha256sum if available, fall back to md5
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$config_file" 2>/dev/null | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$config_file" 2>/dev/null | cut -d' ' -f1
    elif command -v md5sum >/dev/null 2>&1; then
        md5sum "$config_file" 2>/dev/null | cut -d' ' -f1
    elif command -v md5 >/dev/null 2>&1; then
        md5 -q "$config_file" 2>/dev/null
    else
        # Fallback: use file modification time
        stat -f "%m" "$config_file" 2>/dev/null || stat -c "%Y" "$config_file" 2>/dev/null
    fi
}

# Check if cache is valid (checksum matches)
is_config_cache_valid() {
    local config_file="$1"
    local cache_file
    local checksum_file

    cache_file=$(get_config_cache_path "$config_file")
    checksum_file=$(get_config_checksum_path "$config_file")

    # Cache must exist
    if [[ ! -f "$cache_file" ]]; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Config cache not found" "DEBUG"
        return 1
    fi

    # Checksum file must exist
    if [[ ! -f "$checksum_file" ]]; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Config checksum not found" "DEBUG"
        return 1
    fi

    # Compare checksums
    local current_checksum
    local cached_checksum

    current_checksum=$(calculate_config_checksum "$config_file")
    cached_checksum=$(cat "$checksum_file" 2>/dev/null)

    if [[ "$current_checksum" == "$cached_checksum" ]]; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Config cache valid (checksum match)" "DEBUG"
        return 0
    else
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Config cache invalid (checksum mismatch)" "DEBUG"
        return 1
    fi
}

# ============================================================================
# CACHE GENERATION
# ============================================================================

# Generate compiled config cache from TOML
generate_config_cache() {
    local config_file="$1"
    local config_json="$2"

    local cache_file
    local checksum_file

    cache_file=$(get_config_cache_path "$config_file")
    checksum_file=$(get_config_checksum_path "$config_file")

    if [[ -z "$cache_file" ]]; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cannot determine cache path" "WARN"
        return 1
    fi

    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Generating config cache: $cache_file" "INFO"

    # Generate bash exports from JSON using jq
    local cache_content
    cache_content=$(cat <<'CACHE_HEADER'
#!/bin/bash
# Auto-generated config cache - DO NOT EDIT
# Generated from Config.toml for fast loading
# Regenerate by deleting this file or modifying Config.toml

CACHE_HEADER
)

    # Extract all config values and generate exports
    # Variable name mapping to match extract.sh expectations:
    #   display.line1.components → LINE1_COMPONENTS (strip display. prefix)
    #   display.line1.separator → LINE1_SEPARATOR (strip display. prefix)
    #   theme.name → THEME_NAME (unchanged)
    #   features.show_commits → FEATURES_SHOW_COMMITS (unchanged)
    local exports
    exports=$(echo "$config_json" | jq -r '
        to_entries |
        map(
            "export CONFIG_" +
            (.key | gsub("\\."; "_") | ascii_upcase |
             # Strip DISPLAY_ prefix for line configurations
             gsub("^DISPLAY_LINE"; "LINE")) +
            "=" +
            (if .value == null then "\"\""
             elif .value | type == "string" then "\"" + (.value | gsub("\""; "\\\"")) + "\""
             elif .value | type == "array" then "\"" + (.value | join(",")) + "\""
             else (.value | tostring)
             end)
        ) | .[]
    ' 2>/dev/null)

    if [[ -z "$exports" ]]; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Failed to generate exports from JSON" "WARN"
        return 1
    fi

    # Write cache file
    {
        echo "$cache_content"
        echo ""
        echo "# Configuration exports"
        echo "$exports"
        echo ""
        echo "# Mark as loaded"
        echo "export STATUSLINE_CONFIG_CACHE_SOURCED=true"
    } > "$cache_file"

    # Make executable
    chmod 644 "$cache_file" 2>/dev/null

    # Write checksum
    calculate_config_checksum "$config_file" > "$checksum_file"

    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Config cache generated successfully" "INFO"
    return 0
}

# ============================================================================
# CACHE LOADING
# ============================================================================

# Load config from cache (fast path)
load_config_from_cache() {
    local config_file="$1"
    local cache_file

    cache_file=$(get_config_cache_path "$config_file")

    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    # Source the cache file
    # shellcheck disable=SC1090
    if source "$cache_file" 2>/dev/null; then
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Config loaded from cache (fast path)" "INFO"
        return 0
    else
        [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Failed to source config cache" "WARN"
        return 1
    fi
}

# Try to load from cache, generate if needed
load_cached_configuration() {
    local config_file="$1"

    # Fast path: try to load from valid cache
    if is_config_cache_valid "$config_file"; then
        if load_config_from_cache "$config_file"; then
            return 0
        fi
    fi

    # Slow path: parse TOML and generate cache
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache miss - parsing TOML (slow path)" "INFO"

    # Parse TOML to JSON
    local config_json
    config_json=$(parse_toml_to_json "$config_file")
    local parse_result=$?

    if [[ $parse_result -ne 0 ]]; then
        return $parse_result
    fi

    # Generate cache for next time
    generate_config_cache "$config_file" "$config_json"

    # Load from freshly generated cache
    if load_config_from_cache "$config_file"; then
        return 0
    fi

    # Fallback: extract directly (shouldn't reach here normally)
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Cache fallback - extracting directly" "WARN"
    extract_config_values "$config_json"
    return $?
}

# Invalidate config cache (force regeneration)
invalidate_config_cache() {
    local config_file="$1"
    local cache_file
    local checksum_file

    cache_file=$(get_config_cache_path "$config_file")
    checksum_file=$(get_config_checksum_path "$config_file")

    rm -f "$cache_file" "$checksum_file" 2>/dev/null
    [[ "${STATUSLINE_CORE_LOADED:-}" == "true" ]] && debug_log "Config cache invalidated" "INFO"
}

# Export functions
export -f get_config_cache_path get_config_checksum_path
export -f calculate_config_checksum is_config_cache_valid
export -f generate_config_cache load_config_from_cache load_cached_configuration
export -f invalidate_config_cache
