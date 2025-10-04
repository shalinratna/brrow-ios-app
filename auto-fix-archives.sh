#!/bin/bash
# Auto-fix archives after Xcode creates them
# Run this in a separate terminal BEFORE you press Archive in Xcode

ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FIX_SCRIPT="$SCRIPT_DIR/fix_archive_plist.py"

echo "🔍 Monitoring for new Brrow archives..."
echo "📁 Watching: $ARCHIVE_DIR"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Get the latest archive before we start
LAST_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

while true; do
    sleep 2

    # Find the newest archive
    CURRENT_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

    # If we found a new archive
    if [ "$CURRENT_ARCHIVE" != "$LAST_ARCHIVE" ] && [ -n "$CURRENT_ARCHIVE" ]; then
        ARCHIVE_NAME=$(basename "$CURRENT_ARCHIVE")

        # Check if it's a Brrow archive
        if [[ "$ARCHIVE_NAME" == *"Brrow"* ]] || grep -q "Brrow" "$CURRENT_ARCHIVE/Info.plist" 2>/dev/null; then
            echo ""
            echo "🎯 New Brrow archive detected: $ARCHIVE_NAME"
            echo "🔧 Auto-fixing archive metadata..."

            # Wait a moment for Xcode to finish writing
            sleep 1

            # Set environment variable for the fix script
            export ARCHIVE_PATH="$CURRENT_ARCHIVE"

            # Run the fix script
            if python3 "$FIX_SCRIPT"; then
                echo "✅ Archive fixed automatically!"
                echo "📱 Refresh Xcode Organizer (Cmd+R) to see iOS App archive"

                # Play a sound to notify user
                afplay /System/Library/Sounds/Glass.aiff 2>/dev/null
            else
                echo "❌ Failed to fix archive"
            fi
        fi

        LAST_ARCHIVE="$CURRENT_ARCHIVE"
    fi
done
