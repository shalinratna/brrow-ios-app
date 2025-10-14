#!/bin/bash

# Fix Latest Archive - Run this after Product > Archive if archive doesn't appear in Organizer
# This adds ApplicationProperties and opens the archive to register it

echo "🔍 Finding latest archive..."

LATEST_ARCHIVE=$(ls -t ~/Library/Developer/Xcode/Archives/*/*.xcarchive 2>/dev/null | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo "❌ No archives found in ~/Library/Developer/Xcode/Archives/"
    exit 1
fi

echo "📦 Found: $LATEST_ARCHIVE"

INFO_PLIST="$LATEST_ARCHIVE/Info.plist"
APP_PLIST="$LATEST_ARCHIVE/Products/Applications/Brrow.app/Info.plist"

# Check if ApplicationProperties already exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" >/dev/null 2>&1; then
    echo "✅ Archive already has ApplicationProperties"
    echo "📂 Opening archive in Organizer..."
    open "$LATEST_ARCHIVE"
    echo "✅ Done! Check Organizer window."
    exit 0
fi

echo "➕ Adding ApplicationProperties..."

# Get values
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PLIST")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PLIST")

# Add ApplicationProperties
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string 'Applications/Brrow.app'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string '$BUNDLE_ID'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string '$VERSION'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string '$BUILD'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string 'iPhone Distribution'" "$INFO_PLIST"

echo "✅ Added ApplicationProperties"
echo "   Version: $VERSION ($BUILD)"
echo "   Bundle ID: $BUNDLE_ID"
echo ""
echo "📂 Opening archive in Organizer..."
open "$LATEST_ARCHIVE"
echo ""
echo "✅ Done! Archive should now appear in Organizer."
