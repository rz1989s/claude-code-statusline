# 🛠️ Scripts Directory - Version Management Tools

**Centralized version management utilities for Claude Code Enhanced Statusline.**

This directory contains automated tools for maintaining version consistency across the entire codebase using the **Single Source of Truth** approach with `version.txt`.

## 📁 **Available Scripts**

### 🔄 `sync-version.sh` - Package Synchronization
**Purpose**: Synchronize `package.json` version with `version.txt`

```bash
./scripts/sync-version.sh
```

**What it does**:
- Reads current version from `version.txt`
- Updates `package.json` version field using `jq`
- Ensures NPM package version stays in sync

**When to use**: After updating `version.txt` manually

---

### 🔍 `update-version-refs.sh` - Reference Auditor
**Purpose**: Find potentially outdated version references across codebase

```bash
./scripts/update-version-refs.sh
```

**What it does**:
- Scans documentation and examples for version patterns
- Identifies references that should be dynamic
- Provides audit report for manual review

**When to use**: Before releases or when version references seem inconsistent

---

### 🧪 `test-version-system.sh` - System Verification
**Purpose**: Comprehensive test of centralized version system

```bash
./scripts/test-version-system.sh
```

**What it does**:
- Verifies `version.txt` accessibility
- Tests CLI version command accuracy
- Checks package.json synchronization
- Validates display module dynamic versioning

**When to use**: After version system changes or before releases

---

## 🎯 **Version Management Workflow**

### Updating Version (Recommended Process)

1. **Update Single Source of Truth**:
   ```bash
   echo "1.4.0" > version.txt
   ```

2. **Sync Package Files**:
   ```bash
   ./scripts/sync-version.sh
   ```

3. **Verify System Consistency**:
   ```bash
   ./scripts/test-version-system.sh
   ```

4. **Audit Documentation**:
   ```bash
   ./scripts/update-version-refs.sh
   ```

5. **Test CLI**:
   ```bash
   ./statusline.sh --version
   ```

### Benefits of This Approach

✅ **Single Source of Truth** - `version.txt` controls all version references  
✅ **Consistency Guaranteed** - No version mismatches across components  
✅ **Easy Updates** - Change one file, sync everywhere  
✅ **Automation Friendly** - CI/CD can easily read/update versions  
✅ **Maintenance Simplified** - No hunting for scattered version references  

---

## 🔧 **Technical Details**

### Version Reading Implementation
```bash
# In lib/core.sh
get_statusline_version() {
    local script_dir="${BASH_SOURCE[0]%/*}"
    local version_file="${script_dir}/../version.txt"
    
    if [[ -f "$version_file" ]]; then
        cat "$version_file" 2>/dev/null | tr -d '[:space:]' || echo "1.3.1"
        return
    fi
    
    echo "1.3.1"  # Fallback
}

export STATUSLINE_VERSION=$(get_statusline_version)
```

### Components Using Centralized Version
- `lib/core.sh` - Version constants and functions
- `statusline.sh` - CLI version command
- `lib/display.sh` - Test examples and formatting
- `package.json` - NPM package version (via sync script)
- Future: Documentation generation, release automation

---

## 📚 **Best Practices**

1. **Always use version.txt** as the primary version source
2. **Run sync-version.sh** after manual version.txt updates  
3. **Test the system** with test-version-system.sh before releases
4. **Audit references** periodically with update-version-refs.sh
5. **Keep fallbacks** in version reading functions for robustness
6. **Document version strategy** in release notes and changelogs

This centralized approach ensures version consistency, reduces maintenance overhead, and provides reliable automation capabilities for the Claude Code Enhanced Statusline project.