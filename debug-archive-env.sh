#!/bin/bash

# Debug script to log archive environment variables

LOG_FILE="$HOME/Desktop/archive-debug-$(date +%Y%m%d-%H%M%S).log"

echo "=== Archive Post-Action Debug Log ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "=== All Environment Variables ===" >> "$LOG_FILE"
env | sort >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
echo "=== Key Archive Variables ===" >> "$LOG_FILE"
echo "ARCHIVE_PATH: $ARCHIVE_PATH" >> "$LOG_FILE"
echo "ARCHIVE_PRODUCTS_PATH: $ARCHIVE_PRODUCTS_PATH" >> "$LOG_FILE"
echo "INSTALL_PATH: $INSTALL_PATH" >> "$LOG_FILE"
echo "PRODUCT_NAME: $PRODUCT_NAME" >> "$LOG_FILE"
echo "PRODUCT_BUNDLE_IDENTIFIER: $PRODUCT_BUNDLE_IDENTIFIER" >> "$LOG_FILE"
echo "CURRENT_PROJECT_VERSION: $CURRENT_PROJECT_VERSION" >> "$LOG_FILE"
echo "MARKETING_VERSION: $MARKETING_VERSION" >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
echo "=== Archive Structure ===" >> "$LOG_FILE"
if [ -n "$ARCHIVE_PATH" ] && [ -d "$ARCHIVE_PATH" ]; then
    echo "Archive exists at: $ARCHIVE_PATH" >> "$LOG_FILE"
    ls -laR "$ARCHIVE_PATH" >> "$LOG_FILE" 2>&1
else
    echo "ARCHIVE_PATH not set or directory doesn't exist" >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
echo "Debug log saved to: $LOG_FILE"
