#!/bin/bash
# Debug script to see what environment variables are available during archive post-action

LOG_FILE="$HOME/Desktop/archive-debug-$(date +%Y%m%d-%H%M%S).log"

echo "=== Archive Post-Action Debug Log ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "=== All Environment Variables ===" >> "$LOG_FILE"
env | sort >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
echo "=== Key Variables ===" >> "$LOG_FILE"
echo "ARCHIVE_PATH: $ARCHIVE_PATH" >> "$LOG_FILE"
echo "ARCHIVE_PRODUCTS_PATH: $ARCHIVE_PRODUCTS_PATH" >> "$LOG_FILE"
echo "SRCROOT: $SRCROOT" >> "$LOG_FILE"
echo "TARGET_BUILD_DIR: $TARGET_BUILD_DIR" >> "$LOG_FILE"
echo "BUILT_PRODUCTS_DIR: $BUILT_PRODUCTS_DIR" >> "$LOG_FILE"
echo "CONFIGURATION_BUILD_DIR: $CONFIGURATION_BUILD_DIR" >> "$LOG_FILE"
echo "DWARF_DSYM_FOLDER_PATH: $DWARF_DSYM_FOLDER_PATH" >> "$LOG_FILE"
echo "HOME: $HOME" >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
echo "=== Recent Archives ===" >> "$LOG_FILE"
ls -lt "$HOME/Library/Developer/Xcode/Archives"/*/*.xcarchive 2>/dev/null | head -5 >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
echo "✅ Debug log written to: $LOG_FILE" | tee -a "$LOG_FILE"

open "$LOG_FILE"
