# Path Sanitization Security Analysis

## Current Implementation Issues

### 1. Path Traversal Preservation (statusline.sh:347-350)
**Problem**: Current sanitization preserves `..` sequences
```bash
# Current implementation
local sanitized=$(echo "$path" | sed 's|/|-|g')
sanitized=$(echo "$sanitized" | tr -cd '[:alnum:]-_.')

# Example:
# Input:  "/path/../../../etc/passwd"
# Output: "-path-..-..-..-etc-passwd"  # Still contains ".." sequences!
```

**Security Risk**: 
- Sanitized filenames still contain path traversal indicators
- Could be problematic if sanitized paths are later processed or displayed
- Tests acknowledge this issue but mark it as "skip" rather than fixing

### 2. Insufficient Character Filtering
**Problem**: Current implementation only removes "unsafe" characters but doesn't handle sequences
- Removes individual dangerous chars but not dangerous patterns
- No normalization of path components
- No detection of encoded traversal attempts

### 3. Limited Use Case Analysis
**Current Usage**: Only used in `sanitize_path_secure()` for session IDs (line 2547)
```bash
local current_session_id=$(sanitize_path_secure "$current_dir")
```

**Risk Assessment**:
- Low immediate risk since only used for display/session naming
- Could become higher risk if function is reused elsewhere
- Sets poor security precedent

## Security Improvements Needed

### 1. Remove Path Traversal Sequences
**Goal**: Eliminate all `..` sequences and normalize path components
```bash
# Proposed improvement:
# 1. Remove all ".." sequences
# 2. Remove "." sequences  
# 3. Collapse multiple separators
# 4. Apply character filtering
```

### 2. Enhanced Pattern Detection
**Detect and remove**:
- `..` and `../` patterns
- URL-encoded traversal (`%2e%2e`, `%2f`)
- Unicode normalization attacks
- Null bytes and control characters

### 3. Secure Implementation Strategy
```bash
sanitize_path_secure() {
    local path="$1"
    
    # Input validation
    [[ -z "$path" ]] && { echo ""; return 0; }
    [[ ${#path} -gt 1000 ]] && path="${path:0:1000}"
    
    # Remove path traversal sequences FIRST
    local sanitized="$path"
    sanitized=$(echo "$sanitized" | sed 's|\.\./||g')     # Remove ../
    sanitized=$(echo "$sanitized" | sed 's|\.\.|dot-dot|g') # Replace remaining ..
    sanitized=$(echo "$sanitized" | sed 's|\./||g')       # Remove ./
    
    # Standard character sanitization
    sanitized=$(echo "$sanitized" | sed 's|/|-|g')        # Replace slashes
    sanitized=$(echo "$sanitized" | tr -cd '[:alnum:]-_.')  # Keep only safe chars
    
    # Final validation
    [[ -z "$sanitized" ]] && sanitized="unknown-path"
    echo "$sanitized"
}
```

### 4. Test Case Updates
**Update test_security.bats**:
- Remove the "skip" condition for path traversal tests
- Add comprehensive path traversal test cases
- Verify all traversal patterns are properly neutralized
- Test edge cases and encoded sequences

## Priority Assessment
- **Medium Priority**: Current usage is limited and low-risk
- **High Value**: Sets good security foundation for future use
- **Low Effort**: Simple sed pattern additions
- **High Impact**: Demonstrates security-conscious development practices