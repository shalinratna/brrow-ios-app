#!/bin/bash
#
# Xcode Behavior Script: Auto-fix Archive ApplicationProperties
#
# This script is designed to be triggered by Xcode Behaviors "Build → Succeeds"
# It intelligently detects if an archive was just created and adds ApplicationProperties
#
# Setup in Xcode:
#   Xcode → Behaviors → Edit Behaviors → Build → Succeeds
#   Check "Run" and select this script
#

LOG_FILE="/tmp/xcode-behavior-archive-fix.log"
ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"

# Log execution
echo "=== Xcode Behavior Archive Fix - $(date) ===" >> "$LOG_FILE"
echo "PWD: $PWD" >> "$LOG_FILE"
echo "USER: $USER" >> "$LOG_FILE"

# Find the most recently created archive
LATEST_ARCHIVE=$(ls -td "$ARCHIVE_DIR"/*/*.xcarchive 2>/dev/null | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo "No archives found - this is a regular build, not an archive" >> "$LOG_FILE"
    exit 0
fi

# Get the archive's creation time
ARCHIVE_TIME=$(stat -f %m "$LATEST_ARCHIVE" 2>/dev/null)
CURRENT_TIME=$(date +%s)
AGE=$((CURRENT_TIME - ARCHIVE_TIME))

echo "Latest archive: $LATEST_ARCHIVE" >> "$LOG_FILE"
echo "Archive age: ${AGE} seconds" >> "$LOG_FILE"

# Only process if archive is less than 60 seconds old (just created)
if [ $AGE -gt 60 ]; then
    echo "Archive is too old (${AGE}s) - this was a regular build, not a fresh archive" >> "$LOG_FILE"
    exit 0
fi

echo "🎯 Fresh archive detected! Processing..." >> "$LOG_FILE"

# Check if ApplicationProperties already exists
INFO_PLIST="$LATEST_ARCHIVE/Info.plist"
if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$INFO_PLIST" &>/dev/null; then
    echo "✅ ApplicationProperties already exists - no action needed" >> "$LOG_FILE"
    exit 0
fi

echo "⚙️  ApplicationProperties missing - adding now..." >> "$LOG_FILE"

# Wait for Info.plist to be fully written (max 30 seconds)
MAX_WAIT=30
WAITED=0
while [ ! -f "$INFO_PLIST" ] && [ $WAITED -lt $MAX_WAIT ]; do
    echo "Waiting for Info.plist to be created... (${WAITED}s)" >> "$LOG_FILE"
    sleep 1
    WAITED=$((WAITED + 1))
done

if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ ERROR: Info.plist still not found after ${MAX_WAIT}s" >> "$LOG_FILE"
    exit 1
fi

echo "✓ Info.plist exists, proceeding with fix..." >> "$LOG_FILE"

# Run the fix script
SCRIPT_DIR="$HOME/Documents/Projects/Xcode/Brrow"
if [ -f "$SCRIPT_DIR/add-archive-properties.sh" ]; then
    "$SCRIPT_DIR/add-archive-properties.sh" "$LATEST_ARCHIVE" >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ SUCCESS: ApplicationProperties added automatically" >> "$LOG_FILE"

        # Show notification to user
        osascript -e 'display notification "Archive automatically fixed for iOS App classification" with title "Brrow Archive Fix" sound name "Glass"' &>/dev/null
    else
        echo "❌ ERROR: Failed with exit code $EXIT_CODE" >> "$LOG_FILE"

        # Show error notification
        osascript -e 'display notification "Failed to add ApplicationProperties - check log" with title "Brrow Archive Fix Error" sound name "Basso"' &>/dev/null
    fi
else
    echo "❌ ERROR: add-archive-properties.sh not found at $SCRIPT_DIR" >> "$LOG_FILE"
fi

echo "=== End ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
