#!/bin/bash
# Post-archive script to ensure archive has ApplicationProperties

set -e

echo "🔧 Post-Archive Fix Script"
echo "=========================="

# Find the most recent archive
LATEST_ARCHIVE=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d | sort -r | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo "❌ No archive found"
    exit 0
fi

echo "📦 Checking archive: $LATEST_ARCHIVE"

# Check if ApplicationProperties exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$LATEST_ARCHIVE/Info.plist" >/dev/null 2>&1; then
    echo "✅ Archive already has ApplicationProperties"
    exit 0
fi

echo "⚠️  Archive missing ApplicationProperties - fixing..."

# Get app info
APP_PATH="$LATEST_ARCHIVE/Products/Applications/Brrow.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found in archive"
    exit 1
fi

# Read values from app's Info.plist
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Info.plist" 2>/dev/null || echo "1.0")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Info.plist")

echo "  Bundle ID: $BUNDLE_ID"
echo "  Version: $VERSION"
echo "  Build: $BUILD"

# Add ApplicationProperties to archive
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$LATEST_ARCHIVE/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string Applications/Brrow.app" "$LATEST_ARCHIVE/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string $BUNDLE_ID" "$LATEST_ARCHIVE/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string $VERSION" "$LATEST_ARCHIVE/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string $BUILD" "$LATEST_ARCHIVE/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string iPhone Distribution" "$LATEST_ARCHIVE/Info.plist" 2>/dev/null || true

echo "✅ Archive fixed! Opening in Organizer..."

# Open archive
open "$LATEST_ARCHIVE"

# Also trigger Organizer
osascript -e 'tell application "Xcode" to activate' 2>/dev/null
sleep 1
osascript -e 'tell application "System Events" to keystroke "o" using {command down, option down, shift down}' 2>/dev/null

echo "🎉 Done! Check Organizer for your archive."
