# Cache File Security Analysis

## Current State
- **Current umask**: 022 (creates files with 644 permissions)
- **Cache file creation**: `echo "$clean_version" >"$cache_file" 2>/dev/null` (line 2658)
- **Security issue**: No explicit permission setting - relies on umask

## Identified Security Concerns

### 1. Umask Dependency
**Issue**: File permissions depend entirely on user's umask setting
- Current umask 022 → files created with 644 (good)
- User could have umask 000 → files created with 666 (world-writable, bad)
- User could have umask 002 → files created with 664 (group-writable, potentially bad)

### 2. No Explicit Permission Control
**Problem**: Cache file at statusline.sh:2658 doesn't set explicit permissions
```bash
echo "$clean_version" >"$cache_file" 2>/dev/null  # No chmod
```

### 3. Cache File Locations
**Analysis**: Cache files are created in potentially sensitive locations
- Default: `/tmp/.claude_version_cache` (system temp directory)
- User configurable via CONFIG_VERSION_CACHE_FILE
- No validation of cache file location security

## Security Requirements

### 1. Explicit Permission Setting
- All cache files should be created with 644 permissions explicitly
- Owner read/write, group/other read-only
- No world-writable or group-writable permissions

### 2. Secure Cache Directory
- Validate cache file directory permissions
- Ensure parent directory is not world-writable
- Create secure cache directories if needed

### 3. Permission Verification
- Verify cache file permissions after creation
- Warn if insecure permissions detected
- Automatic remediation when possible

## Implementation Strategy

### 1. Secure Cache File Creation Function
```bash
create_secure_cache_file() {
    local cache_file="$1"
    local content="$2"
    
    # Create file with explicit permissions
    echo "$content" > "$cache_file" 2>/dev/null
    chmod 644 "$cache_file" 2>/dev/null
    
    # Verify permissions
    if [[ -f "$cache_file" ]]; then
        local perms=$(stat -f %A "$cache_file" 2>/dev/null || stat -c %a "$cache_file" 2>/dev/null)
        if [[ "$perms" != "644" ]]; then
            echo "Warning: Cache file has unexpected permissions: $perms" >&2
        fi
    fi
}
```

### 2. Cache Directory Validation
- Check parent directory permissions before cache file creation
- Warn about insecure cache directories
- Suggest secure alternatives when needed

### 3. Integration Points
- Replace line 2658 with secure cache file creation
- Apply to all cache file operations throughout codebase
- Add permission checks to existing cache files