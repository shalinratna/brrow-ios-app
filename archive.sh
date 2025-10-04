#!/bin/bash
set -e

echo "🚀 Creating Brrow iOS Archive..."

# Clean old archive
rm -rf ~/Desktop/Brrow.xcarchive

# Build archive
xcodebuild archive \
  -workspace Brrow.xcworkspace \
  -scheme Brrow \
  -archivePath ~/Desktop/Brrow.xcarchive

# Fix archive Info.plist
echo "🔧 Fixing archive metadata..."
python3 /tmp/fix_archive_plist.py

echo "✅ Archive ready at ~/Desktop/Brrow.xcarchive"
echo "📱 Opening in Xcode Organizer..."
open ~/Desktop/Brrow.xcarchive
