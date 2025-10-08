#!/bin/bash

# This script fixes the archive Info.plist to include ApplicationProperties
# so that Xcode Organizer recognizes it as an iOS App instead of Generic Archive

set -e

echo "=== Fix Archive Info.plist Script ==="
echo "Date: $(date)"
echo ""

# Check if ARCHIVE_PATH is set
if [ -z "$ARCHIVE_PATH" ]; then
    echo "ERROR: ARCHIVE_PATH environment variable is not set"
    exit 1
fi

echo "Archive Path: $ARCHIVE_PATH"

# Path to the archive's Info.plist
ARCHIVE_INFO_PLIST="$ARCHIVE_PATH/Info.plist"
APP_INFO_PLIST="$ARCHIVE_PATH/Products/Applications/Brrow.app/Info.plist"

if [ ! -f "$ARCHIVE_INFO_PLIST" ]; then
    echo "ERROR: Archive Info.plist not found at: $ARCHIVE_INFO_PLIST"
    exit 1
fi

if [ ! -f "$APP_INFO_PLIST" ]; then
    echo "ERROR: App Info.plist not found at: $APP_INFO_PLIST"
    exit 1
fi

echo "Found archive Info.plist: $ARCHIVE_INFO_PLIST"
echo "Found app Info.plist: $APP_INFO_PLIST"

# Extract values from app's Info.plist
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_INFO_PLIST" 2>/dev/null || echo "")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST" 2>/dev/null || echo "")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST" 2>/dev/null || echo "")

echo ""
echo "Extracted from app Info.plist:"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Version: $VERSION"
echo "  Build: $BUILD"

# Check if ApplicationProperties already exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$ARCHIVE_INFO_PLIST" >/dev/null 2>&1; then
    echo ""
    echo "ApplicationProperties already exists in archive Info.plist"
    echo "Archive should be recognized correctly by Xcode Organizer"
    exit 0
fi

# Backup the original Info.plist
cp "$ARCHIVE_INFO_PLIST" "$ARCHIVE_INFO_PLIST.backup"
echo ""
echo "Created backup: $ARCHIVE_INFO_PLIST.backup"

# Add ApplicationProperties dictionary
echo "Adding ApplicationProperties to archive Info.plist..."

/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "$ARCHIVE_INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string 'Applications/Brrow.app'" "$ARCHIVE_INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string '$BUNDLE_ID'" "$ARCHIVE_INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string '$VERSION'" "$ARCHIVE_INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string '$BUILD'" "$ARCHIVE_INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string 'Apple Development'" "$ARCHIVE_INFO_PLIST" 2>/dev/null || true

echo "Successfully added ApplicationProperties to archive Info.plist"
echo ""

# Force Xcode Organizer to re-index by touching the archive
echo "Forcing Xcode Organizer to re-index..."
touch "$ARCHIVE_PATH"
touch "$ARCHIVE_INFO_PLIST"
touch "$ARCHIVE_PATH/Products/Applications/Brrow.app"

# Delete Xcode's archive database to force fresh indexing
ARCHIVE_DB="$HOME/Library/Developer/Xcode/UserData/IDEArchiveDatabase.db"
if [ -f "$ARCHIVE_DB" ]; then
    rm "$ARCHIVE_DB"
    echo "Cleared Xcode archive database cache"
fi

echo ""
echo "✅ ApplicationProperties added to archive"
echo "Archive will appear as 'iOS App' in Organizer"
echo "=== Fix Archive Script Completed ==="
