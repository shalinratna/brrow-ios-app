#!/bin/bash
# Auto-fix Brrow archives by adding ApplicationProperties
# This makes archives show as "iOS App Archive" instead of "Generic Xcode Archive"

echo "🔧 Brrow Archive Fixer"

# Debug: Show what variables we have
echo "📝 ARCHIVE_PATH=$ARCHIVE_PATH"
echo "📝 SRCROOT=$SRCROOT"

# Wait for archive to be fully written
sleep 3

# Try to find the archive path
# Check ARCHIVE_PATH from Xcode (this gets set after archiving completes)
if [ -n "$ARCHIVE_PATH" ] && [ -d "$ARCHIVE_PATH" ]; then
    ARCHIVE="$ARCHIVE_PATH"
    echo "✓ Using ARCHIVE_PATH: $ARCHIVE"
# Check custom build path (for command-line builds)
elif [ -d "$SRCROOT/build/Brrow.xcarchive" ]; then
    ARCHIVE="$SRCROOT/build/Brrow.xcarchive"
    echo "✓ Using build path: $ARCHIVE"
# Finally check default Xcode archives location for most recent
else
    ARCHIVE=$(ls -td "$HOME/Library/Developer/Xcode/Archives"/*/*Brrow*.xcarchive 2>/dev/null | head -1)
    echo "✓ Using latest archive: $ARCHIVE"
fi

if [ -z "$ARCHIVE" ] || [ ! -d "$ARCHIVE" ]; then
    echo "⚠️  Archive not found, skipping"
    exit 0
fi

echo "📂 Archive: $ARCHIVE"

INFO_PLIST="$ARCHIVE/Info.plist"
APP_PLIST="$ARCHIVE/Products/Applications/Brrow.app/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "⚠️  Info.plist not found at: $INFO_PLIST"
    exit 0
fi

if [ ! -f "$APP_PLIST" ]; then
    echo "⚠️  App plist not found at: $APP_PLIST"
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

echo "📦 App: $BUNDLE_ID v$VERSION ($BUILD)"

# Add ApplicationProperties
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string 'Applications/Brrow.app'" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string '$BUNDLE_ID'" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string '$VERSION'" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string '$BUILD'" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string 'Apple Development'" "$INFO_PLIST" 2>/dev/null || true

echo "✅ Fixed: $BUNDLE_ID v$VERSION ($BUILD)"
echo "🔄 Refresh Xcode Organizer (Window → Organizer) to see iOS App Archive"
