#!/bin/bash

# update-version-refs.sh - Find and update version references across codebase
# Usage: ./scripts/update-version-refs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$ROOT_DIR/version.txt"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "❌ Error: version.txt not found at $VERSION_FILE"
    exit 1
fi

# Read current version
CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
echo "🔍 Checking for version references that should use: $CURRENT_VERSION"

# Function to check if a version reference should be dynamic
should_be_dynamic() {
    local line="$1"
    # Skip TOML spec versions, API versions, etc.
    if [[ "$line" =~ "TOML v1.0" ]] || [[ "$line" =~ "API v" ]] || [[ "$line" =~ "Node.js" ]] || [[ "$line" =~ "Bash" ]]; then
        return 1
    fi
    # Focus on project version references
    if [[ "$line" =~ "statusline.*v[0-9]" ]] || [[ "$line" =~ "Version.*[0-9]\.[0-9]\.[0-9]" ]] || [[ "$line" =~ "v[0-9]\.[0-9]\.[0-9]" ]]; then
        return 0
    fi
    return 1
}

echo ""
echo "🔍 Scanning for potentially outdated version references..."

# Search for version patterns in docs and examples
grep -r -n "v[0-9]\.[0-9]" docs/ examples/ README.md 2>/dev/null | while IFS=: read -r file line_num content; do
    if should_be_dynamic "$content"; then
        echo "📄 $file:$line_num - $content"
    fi
done

echo ""
echo "✅ Version reference audit complete!"
echo "📝 Manual review recommended for context-specific version references"
echo "🎯 Current version: $CURRENT_VERSION"