#!/bin/bash
# Quick fix for the latest Brrow archive
# Run this after archiving from Xcode if it shows as "Generic Xcode Archive"

set -e

echo "🔧 Fixing latest Brrow archive..."

# Find the most recent archive
ARCHIVE=$(ls -td "$HOME/Library/Developer/Xcode/Archives"/*/*Brrow*.xcarchive 2>/dev/null | head -1)

if [ -z "$ARCHIVE" ]; then
    echo "❌ No Brrow archives found"
    exit 1
fi

echo "📂 Found: $ARCHIVE"

INFO_PLIST="$ARCHIVE/Info.plist"
APP_PLIST="$ARCHIVE/Products/Applications/Brrow.app/Info.plist"

# Check if already fixed
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" &>/dev/null; then
    echo "✅ Archive already has ApplicationProperties"
    exit 0
fi

# Read app info
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PLIST" 2>/dev/null)
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PLIST" 2>/dev/null)
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PLIST" 2>/dev/null)

# Add ApplicationProperties
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string 'Applications/Brrow.app'" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string '$BUNDLE_ID'" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string '$VERSION'" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string '$BUILD'" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string 'Apple Development'" "$INFO_PLIST" 2>/dev/null

echo "✅ Fixed! $BUNDLE_ID v$VERSION ($BUILD)"
echo "📱 Refresh Xcode Organizer (Window → Organizer) to see the change"
echo ""
echo "Archive is now ready for App Store submission!"
