#!/bin/bash
# Automatic Archive Fixer for Xcode Organizer
# This script fixes archives that don't appear in Xcode Organizer

ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives"

echo "🔍 Scanning for archives missing ApplicationProperties..."

# Find all xcarchive directories
find "$ARCHIVES_DIR" -name "*.xcarchive" -type d | while read -r archive; do
    INFO_PLIST="$archive/Info.plist"

    # Check if Info.plist exists
    if [ ! -f "$INFO_PLIST" ]; then
        echo "⚠️  Skipping $archive - no Info.plist found"
        continue
    fi

    # Check if ApplicationProperties already exists
    if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" &>/dev/null; then
        echo "✅ $archive - already has ApplicationProperties"
        continue
    fi

    echo "🔧 Fixing: $(basename "$archive")"

    # Find the app bundle
    APP_PATH=$(find "$archive/Products" -name "*.app" -maxdepth 3 -type d | head -1)

    if [ -z "$APP_PATH" ]; then
        echo "❌ No .app bundle found in $archive"
        continue
    fi

    APP_INFO_PLIST="$APP_PATH/Info.plist"

    if [ ! -f "$APP_INFO_PLIST" ]; then
        echo "❌ No Info.plist in app bundle"
        continue
    fi

    # Extract app information
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_INFO_PLIST" 2>/dev/null)
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST" 2>/dev/null)
    BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST" 2>/dev/null)

    if [ -z "$BUNDLE_ID" ] || [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
        echo "❌ Could not read app metadata"
        continue
    fi

    # Get relative path to app
    APP_RELATIVE=$(echo "$APP_PATH" | sed "s|$archive/Products/||")

    # Add ApplicationProperties to archive Info.plist
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string '$APP_RELATIVE'" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string '$BUNDLE_ID'" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string '$VERSION'" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string '$BUILD'" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Architectures array" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Architectures:0 string 'arm64'" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string 'Apple Development: Raj Ratna (85NQ732355)'" "$INFO_PLIST" 2>/dev/null
    /usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Team string 'UXM5W873X3'" "$INFO_PLIST" 2>/dev/null

    echo "✅ Fixed: $BUNDLE_ID v$VERSION ($BUILD)"
done

echo ""
echo "✅ Done! Archives should now appear in Xcode Organizer."
echo "   Open Xcode → Window → Organizer to verify."
