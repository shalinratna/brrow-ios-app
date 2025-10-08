#!/bin/bash

# Nuclear option: Touch the archive to force re-indexing

ARCHIVE="/Users/shalin/Library/Developer/Xcode/Archives/2025-10-07/Brrow 10-7-25, 11.00.xcarchive"

echo "🔄 Forcing archive re-index..."
echo ""

# Touch the archive and its Info.plist
touch "$ARCHIVE"
touch "$ARCHIVE/Info.plist"
touch "$ARCHIVE/Products/Applications/Brrow.app"

echo "✅ Archive timestamps updated"
echo ""
echo "Now:"
echo "  1. Quit Xcode (Cmd+Q)"
echo "  2. Wait 5 seconds"
echo "  3. Reopen Xcode"
echo "  4. Open Organizer"
echo ""
echo "This forces macOS to re-index the archive."
