#!/bin/bash
# Fix iOS Archive Properties
# Usage: ./fix-archive-properties.sh <path-to-archive>

ARCHIVE_PATH="$1"

if [ -z "$ARCHIVE_PATH" ]; then
    echo "Usage: $0 <path-to-archive.xcarchive>"
    exit 1
fi

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Error: Archive not found at $ARCHIVE_PATH"
    exit 1
fi

INFO_PLIST="$ARCHIVE_PATH/Info.plist"
APP_PATH="$ARCHIVE_PATH/Products/Applications"

# Find the .app bundle
APP_BUNDLE=$(find "$APP_PATH" -name "*.app" -maxdepth 1 -type d | head -n 1)

if [ -z "$APP_BUNDLE" ]; then
    echo "Error: No .app bundle found in archive"
    exit 1
fi

APP_NAME=$(basename "$APP_BUNDLE")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_BUNDLE/Info.plist" 2>/dev/null)
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Info.plist" 2>/dev/null)
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_BUNDLE/Info.plist" 2>/dev/null)

# Get signing identity from codesign
SIGNING_IDENTITY=$(codesign -dvv "$APP_BUNDLE" 2>&1 | grep "Authority=" | head -n 1 | sed 's/Authority=//' | xargs)

# Check if ApplicationProperties already exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" >/dev/null 2>&1; then
    echo "✅ ApplicationProperties already exists"
    /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST"
    exit 0
fi

echo "📝 Adding ApplicationProperties to archive..."

# Add ApplicationProperties
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string Applications/$APP_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string $BUNDLE_ID" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string $VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string $BUILD" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string $SIGNING_IDENTITY" "$INFO_PLIST"

echo "✅ Archive fixed successfully!"
echo "   Version: $VERSION ($BUILD)"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Signing: $SIGNING_IDENTITY"
