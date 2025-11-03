#!/bin/bash
set -e

# This script adds ApplicationProperties to the archive Info.plist
# to ensure Xcode Organizer recognizes it as an iOS App Archive

ARCHIVE_INFO_PLIST="${ARCHIVE_PATH}/Info.plist"
APP_PATH="${ARCHIVE_PATH}/Products/Applications/${PRODUCT_NAME}.app"
APP_INFO_PLIST="${APP_PATH}/Info.plist"

echo "🔧 Fixing archive to prevent Generic Xcode Archive..."
echo "Archive path: ${ARCHIVE_PATH}"
echo "Archive Info.plist: ${ARCHIVE_INFO_PLIST}"
echo "App Info.plist: ${APP_INFO_PLIST}"

# Verify archive and app exist
if [ ! -f "${ARCHIVE_INFO_PLIST}" ]; then
    echo "❌ ERROR: Archive Info.plist not found at: ${ARCHIVE_INFO_PLIST}"
    exit 1
fi

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ ERROR: App not found at: ${APP_PATH}"
    exit 1
fi

if [ ! -f "${APP_INFO_PLIST}" ]; then
    echo "❌ ERROR: App Info.plist not found at: ${APP_INFO_PLIST}"
    exit 1
fi

# Extract values from the app's Info.plist
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${APP_INFO_PLIST}")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${APP_INFO_PLIST}")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${APP_INFO_PLIST}")

echo "Bundle ID: ${BUNDLE_ID}"
echo "Version: ${VERSION}"
echo "Build: ${BUILD}"
echo "Team: ${DEVELOPMENT_TEAM}"
echo "Code Sign Identity: ${CODE_SIGN_IDENTITY}"

# Check if ApplicationProperties already exists
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "${ARCHIVE_INFO_PLIST}" &>/dev/null; then
    echo "⚠️  ApplicationProperties already exists, deleting and recreating..."
    /usr/libexec/PlistBuddy -c "Delete :ApplicationProperties" "${ARCHIVE_INFO_PLIST}"
fi

# Add ApplicationProperties dictionary
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties dict" "${ARCHIVE_INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:ApplicationPath string Applications/${PRODUCT_NAME}.app" "${ARCHIVE_INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleIdentifier string ${BUNDLE_ID}" "${ARCHIVE_INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleShortVersionString string ${VERSION}" "${ARCHIVE_INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:CFBundleVersion string ${BUILD}" "${ARCHIVE_INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:SigningIdentity string ${CODE_SIGN_IDENTITY}" "${ARCHIVE_INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ApplicationProperties:Team string ${DEVELOPMENT_TEAM}" "${ARCHIVE_INFO_PLIST}"

echo "✅ Successfully added ApplicationProperties to archive"
echo "📦 Archive should now appear as iOS App Archive in Xcode Organizer"

# Print the ApplicationProperties for verification
echo ""
echo "ApplicationProperties added:"
/usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "${ARCHIVE_INFO_PLIST}"

exit 0
