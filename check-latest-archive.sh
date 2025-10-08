#!/bin/bash

# Check the latest archive after archiving completes

LATEST_ARCHIVE=$(ls -t ~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/*.xcarchive 2>/dev/null | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
  echo "⏳ No archive found yet from today..."
  echo "   Waiting for archive to complete..."
  exit 0
fi

echo "📦 Latest Archive: $(basename "$LATEST_ARCHIVE")"
echo ""

# Check if it's iOS App or Generic
if [ -d "$LATEST_ARCHIVE/Products/Applications/Brrow.app" ]; then
  echo "✅ Archive Type: iOS App"
  echo ""

  # Check architecture
  echo "🔍 Architecture:"
  lipo -info "$LATEST_ARCHIVE/Products/Applications/Brrow.app/Brrow" 2>/dev/null
  echo ""

  # Check bundle info
  echo "📱 Bundle Info:"
  defaults read "$LATEST_ARCHIVE/Products/Applications/Brrow.app/Info.plist" CFBundleIdentifier 2>/dev/null
  defaults read "$LATEST_ARCHIVE/Products/Applications/Brrow.app/Info.plist" CFBundleShortVersionString 2>/dev/null
  echo ""

  echo "🎉 SUCCESS - Archive is ready for App Store upload!"
  echo ""
  echo "Next steps:"
  echo "  1. Xcode Organizer should open automatically"
  echo "  2. Select the archive"
  echo "  3. Click 'Distribute App'"
  echo "  4. Choose 'App Store Connect'"
  echo "  5. Click 'Upload'"

else
  echo "❌ Archive Type: Generic Archive"
  echo ""
  echo "⚠️  Issue detected - this won't upload to App Store"
  echo ""
  echo "Checking what went wrong..."
  ls -la "$LATEST_ARCHIVE/Products/" 2>/dev/null
fi
