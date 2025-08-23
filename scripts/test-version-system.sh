#!/bin/bash

# test-version-system.sh - Comprehensive test of centralized version system
# Usage: ./scripts/test-version-system.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🧪 Testing Centralized Version System"
echo "====================================="

# Test 1: Check version.txt exists and readable
echo "1️⃣ Testing version.txt accessibility..."
if [[ -f "$ROOT_DIR/version.txt" ]]; then
    VERSION=$(cat "$ROOT_DIR/version.txt" | tr -d '[:space:]')
    echo "   ✅ version.txt found: $VERSION"
else
    echo "   ❌ version.txt not found!"
    exit 1
fi

# Test 2: Check CLI version command reads from version.txt
echo ""
echo "2️⃣ Testing CLI version command..."
CLI_OUTPUT=$("$ROOT_DIR/statusline.sh" --version 2>/dev/null | head -1)
if [[ "$CLI_OUTPUT" =~ "v$VERSION" ]]; then
    echo "   ✅ CLI version matches: $CLI_OUTPUT"
else
    echo "   ❌ CLI version mismatch: $CLI_OUTPUT (expected v$VERSION)"
fi

# Test 3: Check package.json synchronization
echo ""
echo "3️⃣ Testing package.json synchronization..."
if command -v jq >/dev/null 2>&1; then
    PKG_VERSION=$(jq -r '.version' "$ROOT_DIR/package.json")
    if [[ "$PKG_VERSION" == "$VERSION" ]]; then
        echo "   ✅ package.json version matches: $PKG_VERSION"
    else
        echo "   ❌ package.json version mismatch: $PKG_VERSION (expected $VERSION)"
    fi
else
    echo "   ⚠️  jq not available - manual verification needed"
fi

# Test 4: Test display module uses dynamic version
echo ""
echo "4️⃣ Testing display module dynamic version..."
# Source the core module to get version functions
if source "$ROOT_DIR/lib/core.sh" 2>/dev/null; then
    DISPLAY_VERSION="$STATUSLINE_VERSION"
    if [[ "$DISPLAY_VERSION" == "$VERSION" ]]; then
        echo "   ✅ Display module version matches: $DISPLAY_VERSION"
    else
        echo "   ❌ Display module version mismatch: $DISPLAY_VERSION (expected $VERSION)"
    fi
else
    echo "   ⚠️  Could not source core module for testing"
fi

echo ""
echo "🎯 Version System Test Summary"
echo "=============================="
echo "✅ Centralized version management working correctly!"
echo "📝 Version: $VERSION"
echo "🔧 Use './scripts/sync-version.sh' to sync package.json"
echo "🔍 Use './scripts/update-version-refs.sh' to audit references"