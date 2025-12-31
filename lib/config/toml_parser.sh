#!/bin/bash

# ============================================================================
# Claude Code Statusline - TOML Parser Module
# ============================================================================
#
# This module handles TOML to JSON conversion for configuration parsing.
# Supports flat TOML format with dot notation for nested values.
#
# Dependencies: core.sh (handle_error, debug_log, command_exists)
# ============================================================================

# Prevent multiple includes
[[ "${STATUSLINE_CONFIG_TOML_PARSER_LOADED:-}" == "true" ]] && return 0
export STATUSLINE_CONFIG_TOML_PARSER_LOADED=true

# ============================================================================
# TOML PARSING FUNCTIONS
# ============================================================================

# Simple TOML to JSON converter for basic types (strings, booleans, integers)
parse_toml_to_json() {
    local toml_file="$1"

    # Enhanced error handling with proper exit codes
    if [[ -z "$toml_file" ]]; then
        handle_error "No TOML file path provided" 2 "parse_toml_to_json"
        echo "{}"
        return 2 # Invalid arguments
    fi

    if [[ ! -f "$toml_file" ]]; then
        handle_error "TOML configuration file not found: $toml_file" 1 "parse_toml_to_json"
        echo "{}"
        return 1 # File not found
    fi

    if [[ ! -r "$toml_file" ]]; then
        handle_error "TOML configuration file not readable: $toml_file" 3 "parse_toml_to_json"
        echo "{}"
        return 3 # Permission denied
    fi

    # Create temporary flat structure
    local flat_json="{"
    local current_section=""
    local first_item=true

    # Read TOML file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Detect nested TOML sections and return error (flat format required)
        if [[ "$line" == \[*\] ]]; then
            # Extract section name using sed for better compatibility
            local section_name=$(echo "$line" | sed 's/^[[:space:]]*\[\([^]]*\)\][[:space:]]*$/\1/')

            # Return clear error for nested configuration
            handle_error "❌ NESTED TOML FORMAT DETECTED: [$section_name]

Your Config.toml uses nested sections, but this system now requires FLAT format for reliability.

NESTED (old):          FLAT (required):
[theme]                theme.name = \"catppuccin\"
name = \"catppuccin\"     theme.inheritance.enabled = true

[theme.inheritance]
enabled = true

Please convert your Config.toml to flat format using dot notation.
Run: ./statusline.sh --help config  for examples and migration help.

File: $toml_file" 6 "parse_toml_to_json"
            echo "{}"
            return 6 # Nested format detected
        fi

        # Handle key-value pairs using sed for robust extraction (fixes BASH_REMATCH compatibility issues)
        if [[ "$line" =~ = ]]; then
            # Use sed to extract key and value parts
            local key=$(echo "$line" | sed 's/^[[:space:]]*\([^=]*\)[[:space:]]*=.*/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            local value=$(echo "$line" | sed 's/^[[:space:]]*[^=]*=[[:space:]]*\(.*\)/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Strip inline comments (# not inside quotes) - Fix for v2.13.0
            # Handle quoted strings: find closing quote, strip everything after
            if [[ "$value" =~ ^\" ]]; then
                # Quoted string - extract up to closing quote, ignore rest
                value=$(echo "$value" | sed 's/^\("[^"]*"\).*/\1/')
            elif [[ "$value" =~ ^\[ ]]; then
                # Array - extract up to closing bracket, ignore rest
                value=$(echo "$value" | sed 's/^\(\[[^]]*\]\).*/\1/')
            else
                # Unquoted value - strip from # onwards (inline comment)
                value=$(echo "$value" | sed 's/[[:space:]]*#.*//')
            fi

            # Skip if key is empty (malformed line)
            if [[ -z "$key" ]]; then
                debug_log "Skipping malformed TOML line: $line" "DEBUG"
                continue
            fi

            # Create flat key with section prefix
            local flat_key
            if [[ -n "$current_section" ]]; then
                flat_key="${current_section}.${key}"
            else
                flat_key="$key"
            fi

            # Add comma if not first item
            if [[ "$first_item" != "true" ]]; then
                flat_json="$flat_json,"
            fi

            # Parse value type and format for JSON using sed-based extraction
            if [[ "$value" =~ ^\".*\"$ ]]; then
                # String value (quoted) - extract content between quotes using sed
                local string_val=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
                # Escape quotes and backslashes for JSON (fixed over-escaping)
                string_val=$(echo "$string_val" | sed 's/\\\\/\\\\/g; s/"/\\"/g')
                flat_json="$flat_json\"$flat_key\":\"$string_val\""
            elif [[ "$value" =~ ^\[.*\]$ ]]; then
                # Array value - simplified for now
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^(true|false)$ ]]; then
                # Boolean value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]+$ ]]; then
                # Integer value
                flat_json="$flat_json\"$flat_key\":$value"
            elif [[ "$value" =~ ^[0-9]*\.[0-9]+$ ]]; then
                # Float value
                flat_json="$flat_json\"$flat_key\":$value"
            else
                # Unquoted string - treat as string (fixed over-escaping)
                value=$(echo "$value" | sed 's/\\\\/\\\\/g; s/"/\\"/g')
                flat_json="$flat_json\"$flat_key\":\"$value\""
            fi

            first_item=false
        fi
    done <"$toml_file"

    # Close flat JSON
    flat_json="$flat_json}"

    # Check if jq is available for JSON validation
    if command_exists jq; then
        # Validate flat JSON before processing
        if ! echo "$flat_json" | jq . >/dev/null 2>&1; then
            handle_error "Generated invalid JSON during TOML parsing: $toml_file" 4 "parse_toml_to_json"
            debug_log "Invalid flat JSON: $flat_json" "DEBUG"
            echo "{}"
            return 4 # Parse error
        else
            debug_log "Valid flat JSON generated successfully" "DEBUG"
        fi
    else
        debug_log "jq not available for JSON validation, skipping validation: $toml_file" "WARN"
    fi

    # Return the flat JSON directly (no Python nesting needed)
    debug_log "Flat TOML configuration parsed successfully: $toml_file" "INFO"
    echo "$flat_json"
}

# Export function
export -f parse_toml_to_json
