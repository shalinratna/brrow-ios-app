#!/bin/bash

# Fix Archive ApplicationProperties
# This script adds ApplicationProperties to the archive Info.plist
# which is required for Xcode Organizer to recognize it as an iOS App

# Get the archive path
ARCHIVE_PATH="$ARCHIVE_PATH"

if [ -z "$ARCHIVE_PATH" ]; then
    echo "Error: ARCHIVE_PATH not set"
    exit 1
fi

INFO_PLIST="$ARCHIVE_PATH/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "Error: Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Check if ApplicationProperties already exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" >/dev/null 2>&1; then
    echo "✅ ApplicationProperties already exists"
    exit 0
fi

# Get values from the app's Info.plist
APP_PLIST="$ARCHIVE_PATH/Products/Applications/$PRODUCT_NAME.app/Info.plist"

if [ ! -f "$APP_PLIST" ]; then
    echo "Error: App Info.plist not found"
    exit 1
fi

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PLIST")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PLIST")

# Add ApplicationProperties
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string 'Applications/$PRODUCT_NAME.app'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string '$BUNDLE_ID'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string '$VERSION'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string '$BUILD'" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string 'iPhone Distribution'" "$INFO_PLIST"

echo "✅ Added ApplicationProperties to archive"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Version: $VERSION"
echo "   Build: $BUILD"
echo "   Archive will now appear in Organizer"
