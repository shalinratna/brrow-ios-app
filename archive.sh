#!/bin/bash

# Brrow Archive Helper
# This script archives your app and automatically fixes it for Organizer

echo "🚀 Starting Brrow archive..."
echo ""

# Archive with xcodebuild
xcodebuild -workspace Brrow.xcworkspace -scheme Brrow -configuration Release archive 2>&1 | grep -E "(ARCHIVE|error|warning|BUILD)"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Archive failed. Check the error above."
    exit 1
fi

echo ""
echo "✅ Archive build completed!"
echo ""
echo "🔧 Fixing archive for Organizer..."

# Run the fix script
./fix-latest-archive.sh

echo ""
echo "✅ Done! Your archive should now be in Organizer."
echo "   Open Xcode > Window > Organizer to see it."
