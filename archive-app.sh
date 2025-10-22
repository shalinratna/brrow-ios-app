#!/bin/bash
#
# Complete archiving workflow for Brrow iOS app
# Creates archive AND automatically adds ApplicationProperties to ensure
# it shows as "iOS App" in Xcode Organizer
#
# Usage: ./archive-app.sh [archive-name]
#

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$SCRIPT_DIR/Brrow.xcworkspace"
SCHEME="Brrow"

# Use provided archive name or generate timestamp-based name
if [ -n "$1" ]; then
    ARCHIVE_NAME="$1"
else
    ARCHIVE_NAME="Brrow-$(date +%Y-%m-%d-%H%M)"
fi

ARCHIVE_PATH="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/$ARCHIVE_NAME.xcarchive"

echo "========================================="
echo "Brrow iOS App Archive Creator"
echo "========================================="
echo ""
echo "Workspace: $WORKSPACE"
echo "Scheme: $SCHEME"
echo "Archive path: $ARCHIVE_PATH"
echo ""
echo "Step 1/2: Creating archive..."
echo "========================================="

# Create the archive
xcodebuild archive \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=UXM5W873X3

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Error: Archive creation failed"
    exit 1
fi

echo ""
echo "✅ Archive created successfully"
echo ""
echo "Step 2/2: Adding ApplicationProperties..."
echo "========================================="

# Add ApplicationProperties using our script
"$SCRIPT_DIR/add-archive-properties.sh" "$ARCHIVE_PATH"

echo ""
echo "========================================="
echo "🎉 Archive creation complete!"
echo "========================================="
echo ""
echo "Archive location: $ARCHIVE_PATH"
echo ""
echo "The archive will show as 'iOS App' in Xcode Organizer"
echo "You can now:"
echo "  1. Open Xcode Organizer to view the archive"
echo "  2. Distribute to App Store Connect"
echo "  3. Export for Ad Hoc/Enterprise distribution"
echo ""
