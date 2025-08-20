# Error Handling Analysis for TOML Configuration

## Current Error Handling Issues

### 1. Silent Parse Failures (statusline.sh:548-551)
**Problem**: `parse_toml_to_json()` returns `"{}"` on file read failure without logging
```bash
if [[ ! -f "$toml_file" ]]; then
    echo "ERROR: TOML configuration file not found: $toml_file" >&2
    echo "{}"  # Silent failure - returns empty JSON
    return 0   # Returns success!
fi
```

**Issue**: 
- Logs error to stderr but returns success (exit code 0)
- Caller cannot distinguish between "empty file" vs "file not found"
- Main config loader only checks for empty JSON, not error conditions

### 2. Inadequate Error Checking in Main Loader (statusline.sh:698-703)
**Problem**: Main loader doesn't check parse_toml_to_json return code
```bash
config_json=$(parse_toml_to_json "$config_file")  # No error checking

if [[ "$config_json" == "{}" ]]; then
    echo "Warning: Empty or invalid config file, using defaults" >&2
    return 1
fi
```

**Issue**:
- Only checks for empty JSON output, not actual parsing errors
- File read errors, permission issues, and malformed TOML all treated the same
- No distinction between recoverable vs fatal errors

### 3. Missing jq Dependency Fallback
**Problem**: No fallback when `jq` is unavailable despite being critical
- Code assumes jq is always available after validate_dependencies()
- If jq becomes unavailable during execution, silent failures occur

## Recommended Error Handling Improvements

### 1. Enhanced parse_toml_to_json Error Handling
- Return proper exit codes for different error types
- Distinguish between file not found, permission errors, and parse errors
- Add verbose error logging option

### 2. Robust Main Config Loader
- Check both return code AND output from parse_toml_to_json
- Implement graceful degradation for different error types
- Add retry logic for transient errors

### 3. jq Availability Checking
- Verify jq availability before each critical operation
- Implement fallback parsing for basic TOML structures
- Graceful degradation when jq becomes unavailable

### 4. Error Categories
- **Fatal**: File permissions, jq missing, critical syntax errors
- **Warning**: Empty files, missing optional sections
- **Info**: Using defaults, fallback values applied