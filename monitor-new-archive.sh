#!/bin/bash

# Monitor for new archive and validate it immediately

ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives/2025-10-07"

echo "⏳ Monitoring for new archive (Build 577)..."
echo ""
echo "Current archives:"
ls -lt "$ARCHIVES_DIR"/*.xcarchive 2>/dev/null | awk '{print $9}' | xargs -I {} basename {}

echo ""
echo "⏳ Waiting for new archive..."
echo ""

# Check every 10 seconds for new archive
INITIAL_COUNT=$(ls "$ARCHIVES_DIR"/*.xcarchive 2>/dev/null | wc -l)

while true; do
  CURRENT_COUNT=$(ls "$ARCHIVES_DIR"/*.xcarchive 2>/dev/null | wc -l)

  if [ "$CURRENT_COUNT" -gt "$INITIAL_COUNT" ]; then
    echo ""
    echo "✅ New archive detected!"
    echo ""

    # Get the newest archive
    NEWEST=$(ls -t "$ARCHIVES_DIR"/*.xcarchive 2>/dev/null | head -1)

    echo "📦 Archive: $(basename "$NEWEST")"
    echo ""

    # Wait a moment for file system to settle
    sleep 2

    # Validate it
    echo "🔍 Validating new archive..."
    echo ""
    /Users/shalin/Documents/Projects/Xcode/Brrow/validate-archive.sh "$NEWEST"

    break
  fi

  sleep 10
done
