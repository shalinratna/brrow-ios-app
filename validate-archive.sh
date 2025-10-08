#!/bin/bash

# Validation script to check if an archive is properly formatted for iOS App distribution

set -e

ARCHIVE_PATH="${1:-/Users/shalin/Library/Developer/Xcode/Archives/2025-10-07/Brrow 10-7-25, 11.00.xcarchive}"

echo "=== Archive Validation Script ==="
echo "Archive: $ARCHIVE_PATH"
echo ""

# Check if archive exists
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ ERROR: Archive not found at: $ARCHIVE_PATH"
    exit 1
fi
echo "✅ Archive directory exists"

# Check Info.plist
ARCHIVE_INFO="$ARCHIVE_PATH/Info.plist"
if [ ! -f "$ARCHIVE_INFO" ]; then
    echo "❌ ERROR: Info.plist not found"
    exit 1
fi
echo "✅ Archive Info.plist exists"

# Check ApplicationProperties
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$ARCHIVE_INFO" >/dev/null 2>&1; then
    echo "✅ ApplicationProperties dictionary exists"

    # Check required keys
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleIdentifier" "$ARCHIVE_INFO" 2>/dev/null || echo "")
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$ARCHIVE_INFO" 2>/dev/null || echo "")
    BUILD=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$ARCHIVE_INFO" 2>/dev/null || echo "")
    APP_PATH=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:ApplicationPath" "$ARCHIVE_INFO" 2>/dev/null || echo "")
    SIGNING=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:SigningIdentity" "$ARCHIVE_INFO" 2>/dev/null || echo "")

    if [ -n "$BUNDLE_ID" ]; then
        echo "✅ Bundle ID: $BUNDLE_ID"
    else
        echo "❌ CFBundleIdentifier missing"
    fi

    if [ -n "$VERSION" ]; then
        echo "✅ Version: $VERSION"
    else
        echo "❌ CFBundleShortVersionString missing"
    fi

    if [ -n "$BUILD" ]; then
        echo "✅ Build: $BUILD"
    else
        echo "❌ CFBundleVersion missing"
    fi

    if [ -n "$APP_PATH" ]; then
        echo "✅ Application Path: $APP_PATH"
    else
        echo "❌ ApplicationPath missing"
    fi

    if [ -n "$SIGNING" ]; then
        echo "✅ Signing Identity: $SIGNING"
    else
        echo "❌ SigningIdentity missing"
    fi
else
    echo "❌ CRITICAL: ApplicationProperties dictionary missing!"
    echo "   This archive will show as 'Generic Xcode Archive' in Organizer"
    exit 1
fi

# Check app bundle
APP_BUNDLE="$ARCHIVE_PATH/Products/Applications/Brrow.app"
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ ERROR: App bundle not found at: $APP_BUNDLE"
    exit 1
fi
echo "✅ App bundle exists"

# Check app binary
APP_BINARY="$APP_BUNDLE/Brrow"
if [ ! -f "$APP_BINARY" ]; then
    echo "❌ ERROR: App binary not found"
    exit 1
fi
echo "✅ App binary exists"

# Check architecture
ARCH=$(file "$APP_BINARY" | grep -o "arm64" || echo "")
if [ -n "$ARCH" ]; then
    echo "✅ Architecture: arm64"
else
    echo "⚠️  WARNING: Architecture might not be arm64"
    file "$APP_BINARY"
fi

echo ""
echo "=== Validation Result ==="
if [ -n "$BUNDLE_ID" ] && [ -n "$VERSION" ] && [ -n "$BUILD" ] && [ -n "$APP_PATH" ]; then
    echo "✅ PASS: Archive is properly formatted for iOS App distribution"
    echo ""
    echo "This archive should:"
    echo "  - Appear under 'iOS Apps' in Xcode Organizer"
    echo "  - Show version $VERSION ($BUILD)"
    echo "  - Enable 'Distribute App' button"
    echo "  - Allow App Store submission"
    exit 0
else
    echo "❌ FAIL: Archive has missing or incomplete ApplicationProperties"
    echo ""
    echo "This archive will likely show as 'Generic Xcode Archive'"
    exit 1
fi
