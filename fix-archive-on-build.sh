#!/bin/bash
#
# Run Script Phase: Fix Archive Properties
# This script runs during the build process and fixes archives created from Xcode GUI
# It only runs during archive builds and adds ApplicationProperties automatically
#

# Only run during archive builds
if [ "$ACTION" != "install" ]; then
    echo "Not an archive build, skipping..."
    exit 0
fi

# Log for debugging
LOG_FILE="/tmp/brrow-archive-fix-$(date +%Y%m%d-%H%M%S).log"
echo "=== Archive Fix Script ===" | tee "$LOG_FILE"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "ACTION: $ACTION" | tee -a "$LOG_FILE"
echo "CONFIGURATION: $CONFIGURATION" | tee -a "$LOG_FILE"
echo "ARCHIVE_PATH: $ARCHIVE_PATH" | tee -a "$LOG_FILE"
echo "BUILT_PRODUCTS_DIR: $BUILT_PRODUCTS_DIR" | tee -a "$LOG_FILE"

# During the build phase, ARCHIVE_PATH is not yet set
# We need to wait until post-processing or use a different approach
# Instead, we'll create a marker file that indicates this archive needs fixing

if [ "$CONFIGURATION" = "Release" ]; then
    MARKER_FILE="$BUILT_PRODUCTS_DIR/.needs-archive-fix"
    echo "Creating marker file: $MARKER_FILE" | tee -a "$LOG_FILE"
    echo "$(date +%s)" > "$MARKER_FILE"
    echo "Build number: $CURRENT_PROJECT_VERSION" >> "$MARKER_FILE"
    echo "Marker created successfully" | tee -a "$LOG_FILE"
fi

echo "=== Archive Fix Script Complete ===" | tee -a "$LOG_FILE"
exit 0
