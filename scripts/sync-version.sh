#!/bin/bash

# sync-version.sh - Sync version.txt with package.json
# Usage: ./scripts/sync-version.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$ROOT_DIR/version.txt"
PACKAGE_JSON="$ROOT_DIR/package.json"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "❌ Error: version.txt not found at $VERSION_FILE"
    exit 1
fi

if [[ ! -f "$PACKAGE_JSON" ]]; then
    echo "❌ Error: package.json not found at $PACKAGE_JSON"
    exit 1
fi

# Read version from version.txt
VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')

if [[ -z "$VERSION" ]]; then
    echo "❌ Error: version.txt is empty"
    exit 1
fi

echo "📝 Syncing version $VERSION to package.json..."

# Update package.json version using jq
if command -v jq >/dev/null 2>&1; then
    jq --arg version "$VERSION" '.version = $version' "$PACKAGE_JSON" > "$PACKAGE_JSON.tmp" && mv "$PACKAGE_JSON.tmp" "$PACKAGE_JSON"
    echo "✅ Successfully updated package.json to version $VERSION"
else
    echo "⚠️  Warning: jq not found. Please manually update package.json version to: $VERSION"
fi

echo "🎯 Version synchronization complete!"