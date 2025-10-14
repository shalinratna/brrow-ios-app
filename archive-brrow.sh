#!/bin/bash

# Brrow Archive Helper Script
# This script ensures you archive correctly using the workspace

set -e

echo "🎯 Brrow Archive Helper"
echo "======================="
echo ""

# Check if we're in the right directory
if [ ! -f "Brrow.xcworkspace/contents.xcworkspacedata" ]; then
    echo "❌ Error: Must run this script from the Brrow project directory"
    echo "   Expected: /Users/shalin/Documents/Projects/Xcode/Brrow"
    exit 1
fi

echo "✅ Found Brrow.xcworkspace"
echo ""

# Check if workspace is already open in Xcode
if pgrep -q "Xcode"; then
    echo "⚠️  Xcode is running. Make sure:"
    echo "   1. You have Brrow.xcworkspace open (NOT Brrow.xcodeproj)"
    echo "   2. You have 'Any iOS Device' selected as destination"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
else
    echo "📱 Opening Brrow.xcworkspace in Xcode..."
    open Brrow.xcworkspace
    echo "   Waiting for Xcode to start..."
    sleep 3
fi

echo ""
echo "📦 Starting archive build..."
echo ""

# Get current date/time for archive name
DATE=$(date +"%m-%d-%y, %H.%M")
ARCHIVE_NAME="Brrow $DATE.xcarchive"
ARCHIVE_PATH="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/$ARCHIVE_NAME"

echo "Archive will be saved to:"
echo "   $ARCHIVE_PATH"
echo ""

# Clean build folder first
echo "🧹 Cleaning build folder..."
xcodebuild clean -workspace Brrow.xcworkspace -scheme Brrow -configuration Release

echo ""
echo "🔨 Building archive (this may take a few minutes)..."
echo ""

# Archive the app
xcodebuild \
    -workspace Brrow.xcworkspace \
    -scheme Brrow \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    archive \
    2>&1 | grep -E "(error|warning|Archive|succeeded|failed|✓)" || true

if [ -d "$ARCHIVE_PATH" ]; then
    echo ""
    echo "✅ Archive created successfully!"
    echo ""
    echo "📁 Archive location:"
    echo "   $ARCHIVE_PATH"
    echo ""

    # Verify the archive
    if [ -d "$ARCHIVE_PATH/Products/Applications/Brrow.app" ]; then
        echo "✅ App bundle found in archive"

        # Check code signing
        codesign --verify --verbose "$ARCHIVE_PATH/Products/Applications/Brrow.app" 2>&1 | head -2

        echo ""
        echo "🎉 Archive is ready for distribution!"
        echo ""
        echo "Next steps:"
        echo "   1. Open Xcode Organizer: Window → Organizer (Cmd+Option+Shift+O)"
        echo "   2. Select 'Archives' tab"
        echo "   3. Find your archive in the list"
        echo "   4. Click 'Distribute App'"
        echo ""

        # Ask if they want to open Organizer
        read -p "Open Organizer now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "$ARCHIVE_PATH"
            osascript -e 'tell application "Xcode" to activate'
            osascript -e 'tell application "System Events" to keystroke "o" using {command down, option down, shift down}'
        fi
    else
        echo "⚠️  Warning: App bundle not found in archive"
        echo "   This might indicate an issue with the build"
    fi
else
    echo ""
    echo "❌ Archive failed!"
    echo ""
    echo "Troubleshooting steps:"
    echo "   1. Make sure Brrow.xcworkspace is open (not .xcodeproj)"
    echo "   2. Select 'Any iOS Device' as destination"
    echo "   3. Check that all CocoaPods are installed: pod install"
    echo "   4. Try cleaning: Product → Clean Build Folder (Cmd+Shift+K)"
    echo "   5. Try archiving manually: Product → Archive (Cmd+B then Cmd+Shift+B)"
    exit 1
fi
