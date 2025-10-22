#!/bin/bash
#
# Verify that an Xcode archive has proper ApplicationProperties
# This ensures the archive will show as "iOS App" in Xcode Organizer
#
# Usage: ./verify-archive.sh <path-to-archive>
#

set -e

ARCHIVE_PATH="$1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Error: Archive path required${NC}"
    echo "Usage: $0 <path-to-archive>"
    exit 1
fi

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Error: Archive not found at $ARCHIVE_PATH${NC}"
    exit 1
fi

INFO_PLIST="$ARCHIVE_PATH/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo -e "${RED}Error: Info.plist not found in archive${NC}"
    exit 1
fi

echo "========================================="
echo "Archive Verification Report"
echo "========================================="
echo ""
echo "Archive: $(basename "$ARCHIVE_PATH")"
echo "Path: $ARCHIVE_PATH"
echo ""

# Check if ApplicationProperties exists
if ! /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" &>/dev/null; then
    echo -e "${RED}❌ FAILED: ApplicationProperties dictionary not found${NC}"
    echo ""
    echo "This archive will show as 'Generic Xcode Archive' in Xcode Organizer."
    echo "Run: ./add-archive-properties.sh \"$ARCHIVE_PATH\""
    exit 1
fi

echo -e "${GREEN}✅ ApplicationProperties dictionary exists${NC}"
echo ""

# Required keys to check
REQUIRED_KEYS=(
    "ApplicationPath"
    "CFBundleIdentifier"
    "CFBundleShortVersionString"
    "CFBundleVersion"
    "SigningIdentity"
    "Team"
)

ALL_KEYS_PRESENT=true

for KEY in "${REQUIRED_KEYS[@]}"; do
    VALUE=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:$KEY" "$INFO_PLIST" 2>/dev/null || echo "")

    if [ -z "$VALUE" ]; then
        echo -e "${RED}❌ Missing: $KEY${NC}"
        ALL_KEYS_PRESENT=false
    else
        echo -e "${GREEN}✅ $KEY:${NC} $VALUE"
    fi
done

echo ""
echo "========================================="

if [ "$ALL_KEYS_PRESENT" = true ]; then
    echo -e "${GREEN}✅ VERIFICATION PASSED${NC}"
    echo ""
    echo "This archive has all required properties and will show as"
    echo "'iOS App' in Xcode Organizer."
    echo ""
    echo "You can now:"
    echo "  1. Open Xcode Organizer (Window > Organizer)"
    echo "  2. Distribute to App Store Connect"
    echo "  3. Export for Ad Hoc/Enterprise distribution"
    exit 0
else
    echo -e "${RED}❌ VERIFICATION FAILED${NC}"
    echo ""
    echo "Some required properties are missing."
    echo "Run: ./add-archive-properties.sh \"$ARCHIVE_PATH\""
    exit 1
fi
