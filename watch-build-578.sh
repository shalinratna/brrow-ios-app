#!/bin/bash

# Watch for build 578 archive and validate immediately

ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives/2025-10-07"

echo "⏳ Watching for Build 578 archive..."
echo ""

CURRENT_COUNT=$(ls "$ARCHIVES_DIR"/*.xcarchive 2>/dev/null | wc -l | xargs)

while true; do
  NEW_COUNT=$(ls "$ARCHIVES_DIR"/*.xcarchive 2>/dev/null | wc -l | xargs)

  if [ "$NEW_COUNT" -gt "$CURRENT_COUNT" ]; then
    echo "✅ NEW ARCHIVE DETECTED!"
    echo ""

    sleep 3  # Wait for file system to settle

    # Get newest archive
    NEWEST=$(ls -t "$ARCHIVES_DIR"/*.xcarchive 2>/dev/null | head -1)

    echo "📦 Archive: $(basename "$NEWEST")"
    echo ""

    # Check build number
    BUILD=$(defaults read "$NEWEST/Products/Applications/Brrow.app/Info.plist" CFBundleVersion 2>/dev/null)
    echo "🔢 Build Number: $BUILD"
    echo ""

    if [ "$BUILD" = "578" ]; then
      echo "🎯 This is Build 578!"
      echo ""

      # Check if ApplicationProperties exists WITHOUT manual intervention
      echo "🔍 Checking if fix ran automatically..."
      echo ""

      if defaults read "$NEWEST/Info.plist" ApplicationProperties 2>/dev/null > /dev/null; then
        echo "✅ SUCCESS! ApplicationProperties EXISTS automatically!"
        echo ""
        echo "The automated fix WORKED! 🎉"
        echo ""
        defaults read "$NEWEST/Info.plist" ApplicationProperties
        echo ""
        echo "This archive should appear as iOS App in Organizer WITHOUT manual fixes."
      else
        echo "❌ FAILED - ApplicationProperties MISSING"
        echo ""
        echo "The automated fix did NOT run. Need to investigate why."
        echo ""
        echo "Checking for debug log..."
        LATEST_LOG=$(ls -t ~/Desktop/archive-debug-*.log 2>/dev/null | head -1)
        if [ -n "$LATEST_LOG" ]; then
          echo "Latest debug log: $(basename "$LATEST_LOG")"
        fi
      fi

      break
    fi
  fi

  sleep 5
done
