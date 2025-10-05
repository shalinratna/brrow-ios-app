#!/bin/bash
# Auto-fix Brrow archives by adding ApplicationProperties
# This makes archives show as "iOS App Archive" instead of "Generic Xcode Archive"

set -e

echo "🔧 Brrow Archive Fixer"

# Wait for archive to be fully written
sleep 2

# Try to find the archive path
if [ -n "$ARCHIVE_PATH" ]; then
    ARCHIVE="$ARCHIVE_PATH"
else
    ARCHIVE=$(ls -td "$HOME/Library/Developer/Xcode/Archives"/*/*Brrow*.xcarchive 2>/dev/null | head -1)
fi

if [ -z "$ARCHIVE" ] || [ ! -d "$ARCHIVE" ]; then
    echo "⚠️  Archive not found, skipping"
    exit 0
fi

INFO_PLIST="$ARCHIVE/Info.plist"
APP_PLIST="$ARCHIVE/Products/Applications/Brrow.app/Info.plist"

if [ ! -f "$INFO_PLIST" ] || [ ! -f "$APP_PLIST" ]; then
    echo "⚠️  Plist files not found"
    exit 0
fi

# Check if already fixed
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" &>/dev/null; then
    echo "✅ Archive already has ApplicationProperties"
    exit 0
fi

# Read from app Info.plist
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

echo "✅ Fixed: $BUNDLE_ID v$VERSION ($BUILD)"
echo "🔄 Close and reopen Organizer to see iOS App Archive"
