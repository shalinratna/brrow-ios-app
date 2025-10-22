#!/bin/bash
#
# Automatically add ApplicationProperties to Xcode archive Info.plist
# This ensures archives show as "iOS App" in Xcode Organizer without manual intervention
#
# Usage: ./add-archive-properties.sh <path-to-archive>
#

set -e

ARCHIVE_PATH="$1"

if [ -z "$ARCHIVE_PATH" ]; then
    echo "Error: Archive path required"
    echo "Usage: $0 <path-to-archive>"
    exit 1
fi

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Error: Archive not found at $ARCHIVE_PATH"
    exit 1
fi

INFO_PLIST="$ARCHIVE_PATH/Info.plist"
APP_PATH="$ARCHIVE_PATH/Products/Applications"

if [ ! -f "$INFO_PLIST" ]; then
    echo "Error: Info.plist not found in archive"
    exit 1
fi

# Find the .app bundle
APP_BUNDLE=$(find "$APP_PATH" -maxdepth 1 -name "*.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_BUNDLE" ]; then
    echo "Error: No .app bundle found in archive"
    exit 1
fi

APP_NAME=$(basename "$APP_BUNDLE")
APP_INFO_PLIST="$APP_BUNDLE/Info.plist"

# Extract values from app's Info.plist
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_INFO_PLIST" 2>/dev/null || echo "")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST" 2>/dev/null || echo "")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST" 2>/dev/null || echo "")

# Get signing identity from codesign
SIGNING_IDENTITY=$(codesign -dvv "$APP_BUNDLE" 2>&1 | grep "^Authority=" | head -1 | sed 's/Authority=//')
TEAM_ID=$(codesign -dvv "$APP_BUNDLE" 2>&1 | grep "^TeamIdentifier=" | sed 's/TeamIdentifier=//')

if [ -z "$BUNDLE_ID" ] || [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
    echo "Error: Could not extract required information from app bundle"
    exit 1
fi

echo "Adding ApplicationProperties to archive..."
echo "  Bundle ID: $BUNDLE_ID"
echo "  Version: $VERSION"
echo "  Build: $BUILD"
echo "  Signing Identity: $SIGNING_IDENTITY"
echo "  Team ID: $TEAM_ID"

# Check if ApplicationProperties already exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" &>/dev/null; then
    echo "ApplicationProperties already exists, updating..."
    /usr/libexec/PlistBuddy -c "Delete :ApplicationProperties" "$INFO_PLIST"
fi

# Add ApplicationProperties dictionary
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string 'Applications/$APP_NAME'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string '$BUNDLE_ID'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string '$VERSION'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string '$BUILD'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string '$SIGNING_IDENTITY'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Team string '$TEAM_ID'" "$INFO_PLIST"

echo "✅ ApplicationProperties successfully added to archive"
echo "Archive should now appear as 'iOS App' in Xcode Organizer"
