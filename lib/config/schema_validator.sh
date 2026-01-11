#!/bin/bash

# ============================================================================
# Claude Code Statusline - TOML Schema Validator Module (Issue #122)
# ============================================================================
#
# This module validates Config.toml against the expected schema:
# - Validates required keys exist
# - Type checks values (string, number, boolean, array)
# - Warns on unknown keys (possible typos)
# - Reports deprecated keys
#
# Dependencies: core.sh, config/toml_parser.sh
# ============================================================================

# Note: No include guard here - we need the array to be available
# even if the functions were already loaded

# ============================================================================
# SCHEMA DEFINITION
# ============================================================================

# Schema format: "key_pattern:type:required"
# Types: string, boolean, number, array, enum:val1|val2|val3
# Required: required, optional

# Define the complete schema for Config.toml
# Using global array without declare to ensure it persists across contexts
CONFIG_SCHEMA=(
    # Theme configuration
    "theme.name:enum:classic|garden|catppuccin|custom|ocean:optional"

    # Custom colors (all optional, only used when theme.name=custom)
    "colors.basic.red:string:optional"
    "colors.basic.blue:string:optional"
    "colors.basic.green:string:optional"
    "colors.basic.yellow:string:optional"
    "colors.basic.magenta:string:optional"
    "colors.basic.cyan:string:optional"
    "colors.basic.white:string:optional"
    "colors.extended.orange:string:optional"
    "colors.extended.light_orange:string:optional"
    "colors.extended.light_gray:string:optional"
    "colors.extended.bright_green:string:optional"
    "colors.extended.purple:string:optional"
    "colors.extended.teal:string:optional"
    "colors.extended.gold:string:optional"
    "colors.extended.pink_bright:string:optional"
    "colors.extended.indigo:string:optional"
    "colors.extended.violet:string:optional"
    "colors.extended.light_blue:string:optional"
    "colors.formatting.dim:string:optional"
    "colors.formatting.italic:string:optional"
    "colors.formatting.strikethrough:string:optional"
    "colors.formatting.reset:string:optional"

    # Core feature toggles
    "features.show_commits:boolean:optional"
    "features.show_version:boolean:optional"
    "features.show_submodules:boolean:optional"
    "features.show_mcp_status:boolean:optional"
    "features.show_cost_tracking:boolean:optional"
    "features.show_reset_info:boolean:optional"
    "features.show_session_info:boolean:optional"
    "features.show_prayer_times:boolean:optional"
    "features.show_hijri_date:boolean:optional"
    "features.show_code_productivity:boolean:optional"
    "features.show_context_window:boolean:optional"

    # Model emojis
    "emojis.opus:string:optional"
    "emojis.haiku:string:optional"
    "emojis.sonnet:string:optional"
    "emojis.default_model:string:optional"
    "emojis.clean_status:string:optional"
    "emojis.dirty_status:string:optional"
    "emojis.clock:string:optional"
    "emojis.live_block:string:optional"

    # Timeouts
    "timeouts.mcp:string:optional"
    "timeouts.version:string:optional"
    "timeouts.ccusage:string:optional"
    "timeouts.prayer:string:optional"

    # Cost tracking
    "cost.session_source:enum:auto|native|ccusage:optional"
    "cost.alerts.enabled:boolean:optional"
    "cost.alerts.daily_threshold:number:optional"
    "cost.alerts.weekly_threshold:number:optional"
    "cost.alerts.monthly_threshold:number:optional"
    "cost.alerts.session_threshold:number:optional"
    "cost.alerts.warn_percent:number:optional"
    "cost.alerts.critical_percent:number:optional"
    "cost.alerts.desktop_notify:boolean:optional"
    "cost.alerts.notify_cooldown:number:optional"
    "cost.alerts.notify_on_warn:boolean:optional"
    "cost.alerts.notify_on_critical:boolean:optional"

    # Cache configuration
    "cache.base_directory:string:optional"
    "cache.enable_universal_caching:boolean:optional"
    "cache.enable_statistics:boolean:optional"
    "cache.enable_corruption_detection:boolean:optional"
    "cache.cleanup_stale_files:boolean:optional"
    "cache.migrate_legacy_cache:boolean:optional"
    "cache.efficiency_source:enum:auto|native|ccusage:optional"
    "cache.durations.command_exists:string:optional"
    "cache.durations.system_info:number:optional"
    "cache.durations.claude_version:number:optional"
    "cache.durations.git_config:number:optional"
    "cache.durations.git_submodules:number:optional"
    "cache.durations.git_branches:number:optional"
    "cache.durations.git_status:number:optional"
    "cache.durations.git_current_branch:number:optional"
    "cache.durations.mcp_server_list:number:optional"
    "cache.durations.prayer_data:number:optional"
    "cache.durations.hijri_date:number:optional"
    "cache.durations.location_data:number:optional"
    "cache.durations.directory_info:number:optional"
    "cache.durations.file_operations:number:optional"
    "cache.performance.max_lock_retries:number:optional"
    "cache.performance.lock_retry_delay_ms:string:optional"
    "cache.performance.atomic_write_timeout:number:optional"
    "cache.performance.cache_cleanup_interval:number:optional"
    "cache.performance.max_cache_age_hours:number:optional"
    "cache.security.directory_permissions:string:optional"
    "cache.security.file_permissions:string:optional"
    "cache.security.enable_checksums:boolean:optional"
    "cache.security.validate_on_read:boolean:optional"
    "cache.security.secure_temp_files:boolean:optional"
    "cache.security.instance_isolation:boolean:optional"
    "cache.isolation.mode:enum:repository|instance|shared:optional"
    "cache.isolation.mcp:enum:repository|instance|shared:optional"
    "cache.isolation.git:enum:repository|instance|shared:optional"
    "cache.isolation.cost:enum:repository|instance|shared:optional"
    "cache.isolation.session:enum:repository|instance|shared:optional"
    "cache.isolation.prayer:enum:repository|instance|shared:optional"
    "cache.isolation.hijri:enum:repository|instance|shared:optional"
    "cache.legacy.version_duration:number:optional"
    "cache.legacy.version_file:string:optional"

    # Code productivity
    "code_productivity.show_zero:boolean:optional"
    "code_productivity.emoji:string:optional"

    # Context window
    "context_window.emoji:string:optional"
    "context_window.show_tokens:boolean:optional"
    "context_window.show_when_empty:boolean:optional"
    "context_window.warn_threshold:number:optional"
    "context_window.critical_threshold:number:optional"
    "context_window.medium_threshold:number:optional"

    # Session info
    "session_info.show_id:boolean:optional"
    "session_info.show_project:boolean:optional"
    "session_info.id_length:number:optional"
    "session_info.separator:string:optional"
    "session_info.emoji_session:string:optional"
    "session_info.emoji_project:string:optional"
    "session_info.show_when_empty:boolean:optional"

    # Prayer configuration
    "prayer.enabled:boolean:optional"
    "prayer.location_mode:enum:local_gps|auto|ip_based|manual:optional"
    "prayer.calculation_method:string:optional"
    "prayer.madhab:string:optional"
    "prayer.latitude:string:optional"
    "prayer.longitude:string:optional"
    "prayer.timezone:string:optional"
    "prayer.show_completed_indicator:boolean:optional"
    "prayer.highlight_next_prayer:boolean:optional"
    "prayer.show_countdown:boolean:optional"
    "prayer.time_format:enum:12h|24h:optional"
    "prayer.show_time_remaining:boolean:optional"
    "prayer.use_legacy_indicator:boolean:optional"
    "prayer.next_prayer_color_enabled:boolean:optional"
    "prayer.next_prayer_color:string:optional"

    # Hijri calendar
    "hijri.enabled:boolean:optional"
    "hijri.calculation_method:enum:umm_alqura|kuwait|qatar|singapore:optional"
    "hijri.adjustment_days:number:optional"
    "hijri.show_arabic:boolean:optional"
    "hijri.highlight_friday:boolean:optional"
    "hijri.show_maghrib_indicator:boolean:optional"
    "hijri.display_format:enum:short|full|with_weekday:optional"
    "hijri.show_weekday:boolean:optional"

    # Display configuration
    "display.lines:number:optional"
    "display.line1.components:array:optional"
    "display.line1.separator:string:optional"
    "display.line1.show_when_empty:boolean:optional"
    "display.line2.components:array:optional"
    "display.line2.separator:string:optional"
    "display.line2.show_when_empty:boolean:optional"
    "display.line3.components:array:optional"
    "display.line3.separator:string:optional"
    "display.line3.show_when_empty:boolean:optional"
    "display.line4.components:array:optional"
    "display.line4.separator:string:optional"
    "display.line4.show_when_empty:boolean:optional"
    "display.line5.components:array:optional"
    "display.line5.separator:string:optional"
    "display.line5.show_when_empty:boolean:optional"
    "display.line6.components:array:optional"
    "display.line6.separator:string:optional"
    "display.line6.show_when_empty:boolean:optional"
    "display.line7.components:array:optional"
    "display.line7.separator:string:optional"
    "display.line7.show_when_empty:boolean:optional"
    "display.line8.components:array:optional"
    "display.line8.separator:string:optional"
    "display.line8.show_when_empty:boolean:optional"
    "display.line9.components:array:optional"
    "display.line9.separator:string:optional"
    "display.line9.show_when_empty:boolean:optional"
    "display.time_format:string:optional"
    "display.date_format:string:optional"
    "display.date_format_compact:string:optional"

    # Labels
    "labels.commits:string:optional"
    "labels.repo:string:optional"
    "labels.monthly:string:optional"
    "labels.weekly:string:optional"
    "labels.daily:string:optional"
    "labels.mcp:string:optional"
    "labels.version_prefix:string:optional"
    "labels.claude_code_prefix:string:optional"
    "labels.statusline_prefix:string:optional"
    "labels.submodule:string:optional"
    "labels.session_prefix:string:optional"
    "labels.live:string:optional"
    "labels.reset:string:optional"

    # Messages
    "messages.no_ccusage:string:optional"
    "messages.ccusage_install:string:optional"
    "messages.no_active_block:string:optional"
    "messages.mcp_unknown:string:optional"
    "messages.mcp_none:string:optional"
    "messages.unknown_version:string:optional"
    "messages.no_submodules:string:optional"

    # Advanced settings
    "advanced.warn_missing_deps:boolean:optional"
    "advanced.debug_mode:boolean:optional"
    "advanced.performance_mode:boolean:optional"
    "advanced.strict_validation:boolean:optional"

    # Compatibility
    "compatibility.auto_detect_bash:boolean:optional"
    "compatibility.enable_compatibility_mode:boolean:optional"
    "compatibility.compatibility_warnings:boolean:optional"
    "compatibility.bash_path:string:optional"

    # Platform
    "platform.prefer_gtimeout:boolean:optional"
    "platform.use_gdate:boolean:optional"
    "platform.color_support_level:enum:full|256|16|none:optional"

    # Paths
    "paths.temp_dir:string:optional"
    "paths.config_dir:string:optional"
    "paths.cache_dir:string:optional"
    "paths.log_file:string:optional"

    # Performance
    "performance.parallel_data_collection:boolean:optional"
    "performance.max_concurrent_operations:number:optional"
    "performance.git_operation_timeout:string:optional"
    "performance.network_operation_timeout:string:optional"
    "performance.enable_smart_caching:boolean:optional"
    "performance.cache_compression:boolean:optional"

    # Debug
    "debug.log_level:enum:error|warn|info|debug:optional"
    "debug.log_config_loading:boolean:optional"
    "debug.log_theme_application:boolean:optional"
    "debug.log_validation_details:boolean:optional"
    "debug.benchmark_performance:boolean:optional"
    "debug.export_debug_info:boolean:optional"

    # Dynamic theme
    "theme.dynamic.enabled:boolean:optional"
    "theme.dynamic.mode:enum:time|sunrise_sunset|prayer:optional"
    "theme.dynamic.day_theme:string:optional"
    "theme.dynamic.night_theme:string:optional"
    "theme.dynamic.day_start:string:optional"
    "theme.dynamic.night_start:string:optional"
    "theme.dynamic.sunrise_offset:number:optional"
    "theme.dynamic.sunset_offset:number:optional"
    "theme.dynamic.prayer_day_trigger:string:optional"
    "theme.dynamic.prayer_night_trigger:string:optional"
    "theme.dynamic.manual_override:string:optional"

    # Theme inheritance
    "theme.inheritance.enabled:boolean:optional"
    "theme.inheritance.base_theme:string:optional"
    "theme.inheritance.merge_strategy:enum:override|merge:optional"
    "theme.inheritance.colors.red:string:optional"
    "theme.inheritance.colors.blue:string:optional"
    "theme.inheritance.colors.green:string:optional"
    "theme.inheritance.colors.yellow:string:optional"
    "theme.inheritance.colors.magenta:string:optional"
    "theme.inheritance.colors.cyan:string:optional"
    "theme.inheritance.colors.white:string:optional"
    "theme.inheritance.colors.orange:string:optional"
    "theme.inheritance.colors.purple:string:optional"
    "theme.inheritance.colors.teal:string:optional"
    "theme.inheritance.colors.gold:string:optional"
    "theme.inheritance.colors.pink:string:optional"

    # Conditional configuration
    "conditional.enabled:boolean:optional"
    "conditional.work_hours.enabled:boolean:optional"
    "conditional.work_hours.start_time:string:optional"
    "conditional.work_hours.end_time:string:optional"
    "conditional.work_hours.timezone:string:optional"
    "conditional.work_hours.work_profile:string:optional"
    "conditional.work_hours.off_hours_profile:string:optional"
    "conditional.git_context.enabled:boolean:optional"
    "conditional.git_context.work_repos:array:optional"
    "conditional.git_context.personal_repos:array:optional"

    # Profiles
    "profiles.enabled:boolean:optional"
    "profiles.default_profile:string:optional"
    "profiles.auto_switch:boolean:optional"
    "profiles.detection_priority:array:optional"
    "profiles.work.theme:string:optional"
    "profiles.work.show_cost_tracking:boolean:optional"
    "profiles.work.show_reset_info:boolean:optional"
    "profiles.work.mcp_timeout:string:optional"
    "profiles.work.directories:array:optional"
    "profiles.work.git_remotes:array:optional"
    "profiles.work.time_start:string:optional"
    "profiles.work.time_end:string:optional"
    "profiles.work.time_days:array:optional"
    "profiles.personal.theme:string:optional"
    "profiles.personal.show_cost_tracking:boolean:optional"
    "profiles.personal.show_reset_info:boolean:optional"
    "profiles.personal.mcp_timeout:string:optional"
    "profiles.personal.directories:array:optional"
    "profiles.personal.git_remotes:array:optional"
    "profiles.demo.theme:string:optional"
    "profiles.demo.show_cost_tracking:boolean:optional"
    "profiles.demo.show_commits:boolean:optional"
    "profiles.demo.show_reset_info:boolean:optional"
    "profiles.demo.directories:array:optional"
    "profiles.default.theme:string:optional"
    "profiles.default.show_cost_tracking:boolean:optional"
    "profiles.default.show_reset_info:boolean:optional"

    # Plugins
    "plugins.enabled:boolean:optional"
    "plugins.auto_discovery:boolean:optional"
    "plugins.plugin_dirs:array:optional"
    "plugins.timeout_per_plugin:string:optional"
    "plugins.validate_plugins:boolean:optional"
    "plugins.allow_network:boolean:optional"
    "plugins.debug_plugins:boolean:optional"
    # Signature verification (Issue #120)
    "plugins.require_signature:boolean:optional"
    "plugins.warn_unsigned:boolean:optional"
    "plugins.trusted_keys:string:optional"
    "plugins.keyserver:string:optional"
    "plugins.git_extended.enabled:boolean:optional"
    "plugins.git_extended.show_stash_count:boolean:optional"
    "plugins.git_extended.show_ahead_behind:boolean:optional"
    "plugins.git_extended.show_branch_age:boolean:optional"
    "plugins.system_info.enabled:boolean:optional"
    "plugins.system_info.show_load_average:boolean:optional"
    "plugins.system_info.show_memory_usage:boolean:optional"
    "plugins.system_info.show_disk_usage:boolean:optional"
    "plugins.weather.enabled:boolean:optional"
    "plugins.weather.api_key:string:optional"
    "plugins.weather.location:string:optional"
    "plugins.weather.units:enum:metric|imperial:optional"

    # GitHub integration
    "github.enabled:boolean:optional"
    "github.show_ci_status:boolean:optional"
    "github.show_open_prs:boolean:optional"
    "github.show_latest_release:boolean:optional"
    "github.cache_ttl:number:optional"
    "github.timeout:number:optional"
    "github.ci_passing:string:optional"
    "github.ci_failing:string:optional"
    "github.ci_pending:string:optional"
    "github.ci_unknown:string:optional"
)

# Deprecated keys that should warn users
DEPRECATED_KEYS=(
    # Add deprecated keys here as: "old.key:replacement.key:version_deprecated"
    # Example: "old_setting:new_setting:v2.10.0"
)

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

# Validate a value against its expected type
# Returns: 0 if valid, 1 if invalid
validate_type() {
    local value="$1"
    local expected_type="$2"

    case "$expected_type" in
        string)
            # All values can be strings
            return 0
            ;;
        boolean)
            if [[ "$value" == "true" || "$value" == "false" ]]; then
                return 0
            fi
            return 1
            ;;
        number)
            if [[ "$value" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
                return 0
            fi
            return 1
            ;;
        array)
            if [[ "$value" =~ ^\[.*\]$ ]]; then
                return 0
            fi
            return 1
            ;;
        enum:*)
            # Extract valid values from enum definition
            local valid_values="${expected_type#enum:}"
            local IFS='|'
            for valid in $valid_values; do
                if [[ "$value" == "$valid" ]]; then
                    return 0
                fi
            done
            return 1
            ;;
        *)
            debug_log "Unknown type in schema: $expected_type" "WARN"
            return 0
            ;;
    esac
}

# Get schema entry for a key
# Returns: schema entry or empty if not found
get_schema_entry() {
    local key="$1"

    for entry in "${CONFIG_SCHEMA[@]}"; do
        local schema_key="${entry%%:*}"
        if [[ "$schema_key" == "$key" ]]; then
            echo "$entry"
            return 0
        fi
    done

    return 1
}

# Check if a key is in the schema
is_known_key() {
    local key="$1"
    get_schema_entry "$key" >/dev/null 2>&1
}

# Check if a key is deprecated
get_deprecated_info() {
    local key="$1"

    for entry in "${DEPRECATED_KEYS[@]}"; do
        local deprecated_key="${entry%%:*}"
        if [[ "$deprecated_key" == "$key" ]]; then
            echo "$entry"
            return 0
        fi
    done

    return 1
}

# ============================================================================
# MAIN VALIDATION FUNCTION
# ============================================================================

# Validate configuration against schema
# Arguments: $1 = path to Config.toml
# Returns: 0 if valid (with warnings), 1 if critical errors found
validate_config_schema() {
    local config_file="${1:-}"
    local strict="${2:-false}"

    # Validation result tracking
    local errors=0
    local warnings=0
    local unknown_keys=()
    local type_errors=()
    local deprecated_warnings=()

    # Check file exists
    if [[ -z "$config_file" ]]; then
        debug_log "No config file specified for validation" "WARN"
        return 0
    fi

    if [[ ! -f "$config_file" ]]; then
        debug_log "Config file not found for validation: $config_file" "INFO"
        return 0
    fi

    debug_log "Validating config schema: $config_file" "INFO"

    # Parse config to JSON
    local config_json
    config_json=$(parse_toml_to_json "$config_file" 2>/dev/null)

    if [[ -z "$config_json" || "$config_json" == "{}" ]]; then
        debug_log "Empty or invalid config, skipping validation" "WARN"
        return 0
    fi

    # Check if jq is available
    if ! command_exists jq; then
        debug_log "jq not available for schema validation" "WARN"
        return 0
    fi

    # Extract all keys from config
    local config_keys
    config_keys=$(echo "$config_json" | jq -r 'keys[]' 2>/dev/null)

    if [[ -z "$config_keys" ]]; then
        debug_log "No keys found in config" "INFO"
        return 0
    fi

    # Validate each key
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue

        # Get value for this key
        local value
        value=$(echo "$config_json" | jq -r --arg k "$key" '.[$k] // empty' 2>/dev/null)

        # Check if key is deprecated
        local deprecated_info
        if deprecated_info=$(get_deprecated_info "$key"); then
            local replacement="${deprecated_info#*:}"
            replacement="${replacement%%:*}"
            local version="${deprecated_info##*:}"
            deprecated_warnings+=("$key (use '$replacement' instead, deprecated in $version)")
            ((warnings++))
        fi

        # Check if key is known
        local schema_entry
        if schema_entry=$(get_schema_entry "$key"); then
            # Key is known, validate type
            local type_def="${schema_entry#*:}"
            type_def="${type_def%%:*}"

            if ! validate_type "$value" "$type_def"; then
                type_errors+=("$key: expected $type_def, got '$value'")
                ((errors++))
            fi
        else
            # Key is unknown - possible typo
            unknown_keys+=("$key")
            ((warnings++))
        fi
    done <<< "$config_keys"

    # Report results
    if [[ ${#unknown_keys[@]} -gt 0 ]]; then
        debug_log "Unknown config keys (possible typos): ${unknown_keys[*]}" "WARN"
    fi

    if [[ ${#type_errors[@]} -gt 0 ]]; then
        for err in "${type_errors[@]}"; do
            debug_log "Type error: $err" "ERROR"
        done
    fi

    if [[ ${#deprecated_warnings[@]} -gt 0 ]]; then
        for warn in "${deprecated_warnings[@]}"; do
            debug_log "Deprecated key: $warn" "WARN"
        done
    fi

    # Summary
    if [[ $errors -gt 0 || $warnings -gt 0 ]]; then
        debug_log "Schema validation: $errors errors, $warnings warnings" "INFO"
    else
        debug_log "Schema validation passed" "INFO"
    fi

    # Return based on strict mode
    if [[ "$strict" == "true" && $errors -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Quick validation check (silent, returns status only)
validate_config_quick() {
    local config_file="$1"
    validate_config_schema "$config_file" "false" >/dev/null 2>&1
}

# Detailed validation with formatted output
# Note: This is a fast summary validation that uses schema matching
validate_config_detailed() {
    local config_file="${1:-}"

    if [[ -z "$config_file" ]]; then
        echo "Usage: validate_config_detailed <config_file>"
        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file"
        return 1
    fi

    echo "Validating: $config_file"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        echo "⚠️  jq not available, skipping validation"
        return 0
    fi

    # Parse config to JSON
    local config_json
    config_json=$(parse_toml_to_json "$config_file" 2>/dev/null)

    if [[ -z "$config_json" || "$config_json" == "{}" ]]; then
        echo "❌ Failed to parse config file"
        return 1
    fi

    # Count entries
    local schema_count=${#CONFIG_SCHEMA[@]}
    local config_key_count
    config_key_count=$(echo "$config_json" | jq 'keys | length' 2>/dev/null)

    echo "Schema entries: $schema_count"
    echo "Config keys: $config_key_count"

    # Build schema set for matching
    local schema_keys=""
    for entry in "${CONFIG_SCHEMA[@]}"; do
        schema_keys+="${entry%%:*}"$'\n'
    done

    # Get config keys and find unknown ones
    local config_keys
    config_keys=$(echo "$config_json" | jq -r 'keys[]' 2>/dev/null)

    local unknown_count=0
    local unknown_sample=""
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        if ! echo "$schema_keys" | grep -qxF "$key"; then
            ((unknown_count++))
            [[ $unknown_count -le 5 ]] && unknown_sample+="  - $key"$'\n'
        fi
    done <<< "$config_keys"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ $unknown_count -gt 0 ]]; then
        echo "⚠️  Unknown keys found: $unknown_count"
        [[ -n "$unknown_sample" ]] && echo "$unknown_sample"
        [[ $unknown_count -gt 5 ]] && echo "  ... and $((unknown_count - 5)) more"
        echo ""
        echo "⚠️  Configuration has warnings (possible typos)"
        return 0
    else
        echo "✅ All $config_key_count keys are valid"
        echo ""
        echo "✅ Configuration is valid!"
        return 0
    fi
}

# Helper to load schema if not already loaded
_load_config_schema() {
    # Re-source this file to reload the schema array
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$script_dir/schema_validator.sh"
}

# Get list of all valid config keys (for autocomplete/documentation)
get_all_valid_keys() {
    for entry in "${CONFIG_SCHEMA[@]}"; do
        echo "${entry%%:*}"
    done | sort
}

# Get schema info for a specific key
get_key_info() {
    local key="$1"
    local entry

    if entry=$(get_schema_entry "$key"); then
        local type_def="${entry#*:}"
        type_def="${type_def%%:*}"
        local required="${entry##*:}"

        echo "Key: $key"
        echo "Type: $type_def"
        echo "Required: $required"
    else
        echo "Key '$key' is not in the schema"
        return 1
    fi
}

# Note: Functions are available via source, no need to export
# (export -f can cause output pollution in some bash versions)
