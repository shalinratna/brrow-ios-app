#!/bin/bash

echo "🔍 Brrow Archive Diagnostics"
echo "============================"
echo ""

# 1. Check if workspace exists
if [ -f "Brrow.xcworkspace/contents.xcworkspacedata" ]; then
    echo "✅ Workspace found: Brrow.xcworkspace"
else
    echo "❌ Workspace not found!"
    exit 1
fi

# 2. Check scheme
if [ -f "Brrow.xcodeproj/xcshareddata/xcschemes/Brrow.xcscheme" ]; then
    echo "✅ Brrow scheme found"
else
    echo "❌ Brrow scheme not found!"
    exit 1
fi

# 3. Check CocoaPods
if [ -d "Pods" ]; then
    echo "✅ CocoaPods installed"
else
    echo "⚠️  CocoaPods not installed - run 'pod install'"
fi

# 4. Check for build settings issues
echo ""
echo "📋 Checking build configuration..."
BUNDLE_ID=$(defaults read "$(pwd)/Brrow/Info.plist" CFBundleIdentifier 2>/dev/null || echo "Not found")
echo "   Bundle ID: $BUNDLE_ID"

VERSION=$(defaults read "$(pwd)/Brrow/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Not found")
echo "   Version: $VERSION"

BUILD=$(defaults read "$(pwd)/Brrow/Info.plist" CFBundleVersion 2>/dev/null || echo "Not found")
echo "   Build: $BUILD"

# 5. Check recent archives
echo ""
echo "📦 Recent archives:"
ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives"
if [ -d "$ARCHIVES_DIR" ]; then
    find "$ARCHIVES_DIR" -name "*.xcarchive" -type d -mtime -1 2>/dev/null | while read archive; do
        echo "   📁 $(basename "$archive")"

        # Check if it has ApplicationProperties
        if /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "$archive/Info.plist" >/dev/null 2>&1; then
            echo "      ✅ Has ApplicationProperties (should appear in Organizer)"
        else
            echo "      ❌ Missing ApplicationProperties (won't appear in Organizer)"
            echo "      🔧 Run: open \"$archive\" to register it"
        fi
    done
else
    echo "   ℹ️  No archives directory found"
fi

# 6. Check signing
echo ""
echo "🔐 Checking code signing..."
TEAM_ID=$(defaults read "$(pwd)/Brrow.xcodeproj/project.pbxproj" | grep -m 1 "DevelopmentTeam" | awk -F'"' '{print $2}' || echo "Not found")
echo "   Development Team: $TEAM_ID"

# 7. Provide archive command
echo ""
echo "🚀 To archive from command line:"
echo "   xcodebuild -workspace Brrow.xcworkspace \\"
echo "              -scheme Brrow \\"
echo "              -configuration Release \\"
echo "              -archivePath ~/Desktop/Brrow.xcarchive \\"
echo "              archive"
echo ""
echo "   Then open the archive:"
echo "   open ~/Desktop/Brrow.xcarchive"
echo ""
echo "✅ Diagnostics complete!"
