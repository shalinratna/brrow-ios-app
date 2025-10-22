#!/bin/bash
#
# Test the archive fix script in isolation
# This simulates what happens during a real archive build
#

set -e

echo "🧪 Testing Archive Fix Script..."
echo ""

# Find the most recent archive
LATEST_ARCHIVE=$(find ~/Library/Developer/Xcode/Archives/2025-* -name "Brrow*.xcarchive" -type d 2>/dev/null | sort -r | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo "❌ No archives found in ~/Library/Developer/Xcode/Archives/2025-*"
    echo ""
    echo "Please create an archive first:"
    echo "  1. Open Xcode"
    echo "  2. Product → Archive"
    echo ""
    exit 1
fi

echo "📦 Found latest archive:"
echo "   $LATEST_ARCHIVE"
echo ""

# Check current state
echo "1. Checking current ApplicationProperties..."
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$LATEST_ARCHIVE/Info.plist" >/dev/null 2>&1; then
    echo "   ✅ ApplicationProperties already exists"
    echo ""
    /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$LATEST_ARCHIVE/Info.plist" | sed 's/^/   /'
    echo ""
    echo "   This means the fix is working! The script successfully added ApplicationProperties."
else
    echo "   ⚠️  ApplicationProperties does NOT exist"
    echo "   This archive will show as 'Generic Xcode Archive'"
    echo ""
    echo "   Running fix script now..."
    echo ""

    # Run the fix script
    /Users/shalin/Documents/Projects/Xcode/Brrow/add-archive-properties.sh "$LATEST_ARCHIVE"

    echo ""
    echo "2. Verifying fix was applied..."
    if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$LATEST_ARCHIVE/Info.plist" >/dev/null 2>&1; then
        echo "   ✅ ApplicationProperties successfully added!"
        echo ""
        /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$LATEST_ARCHIVE/Info.plist" | sed 's/^/   /'
    else
        echo "   ❌ Failed to add ApplicationProperties"
        exit 1
    fi
fi

echo ""
echo "3. Checking archive appearance in Organizer..."
echo "   To verify, open Xcode Organizer (Window → Organizer)"
echo "   The archive should show as 'iOS App Archive' with app icon"
echo ""

# Check if this is a fresh archive (within last 5 minutes)
ARCHIVE_TIME=$(stat -f "%m" "$LATEST_ARCHIVE")
CURRENT_TIME=$(date +%s)
TIME_DIFF=$((CURRENT_TIME - ARCHIVE_TIME))

if [ $TIME_DIFF -lt 300 ]; then
    echo "   📌 This archive was created $((TIME_DIFF / 60)) minutes ago"
    echo "   This is likely from your most recent build!"
else
    echo "   📌 This archive is $((TIME_DIFF / 3600)) hours old"
    echo "   Consider creating a new archive to test the fix"
fi

echo ""
echo "✅ Test Complete!"
echo ""
