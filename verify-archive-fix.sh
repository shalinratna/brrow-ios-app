#!/bin/bash
#
# Verify that the archive fix has been properly implemented
#

set -e

echo "🔍 Verifying Archive Fix Implementation..."
echo ""

PROJECT_DIR="/Users/shalin/Documents/Projects/Xcode/Brrow"
PROJECT_FILE="$PROJECT_DIR/Brrow.xcodeproj/project.pbxproj"
SCRIPT_FILE="$PROJECT_DIR/add-archive-properties.sh"

# Check 1: project.pbxproj is valid
echo "1. Checking project.pbxproj validity..."
if plutil -lint "$PROJECT_FILE" >/dev/null 2>&1; then
    echo "   ✅ project.pbxproj is valid"
else
    echo "   ❌ project.pbxproj has syntax errors"
    exit 1
fi

# Check 2: Run Script Phase exists in project
echo "2. Checking Run Script Phase exists..."
if grep -q "AA419ADD4A281F99876E9CC1.*Fix Archive Properties" "$PROJECT_FILE"; then
    echo "   ✅ Run Script Phase 'Fix Archive Properties' found"
else
    echo "   ❌ Run Script Phase not found in project"
    exit 1
fi

# Check 3: Script is added to Brrow target build phases
echo "3. Checking script is in Brrow target..."
if grep -A 20 "ED419AF32E281A31006E8DB9.*Brrow.*=" "$PROJECT_FILE" | grep -q "AA419ADD4A281F99876E9CC1"; then
    echo "   ✅ Run Script Phase is in Brrow target build phases"
else
    echo "   ❌ Run Script Phase not in Brrow target"
    exit 1
fi

# Check 4: add-archive-properties.sh exists and is executable
echo "4. Checking add-archive-properties.sh..."
if [ -f "$SCRIPT_FILE" ]; then
    echo "   ✅ Script file exists"
    if [ -x "$SCRIPT_FILE" ]; then
        echo "   ✅ Script is executable"
    else
        echo "   ⚠️  Script exists but is not executable"
        echo "      Run: chmod +x $SCRIPT_FILE"
    fi
else
    echo "   ❌ Script file not found"
    exit 1
fi

# Check 5: User Script Sandboxing is disabled
echo "5. Checking User Script Sandboxing..."
if grep -q "ENABLE_USER_SCRIPT_SANDBOXING = NO" "$PROJECT_FILE"; then
    echo "   ✅ User Script Sandboxing is disabled (required for scripts to run)"
else
    echo "   ⚠️  User Script Sandboxing may be enabled (could prevent script from running)"
fi

# Check 6: Verify Xcode can read the project
echo "6. Checking Xcode can read project..."
if xcodebuild -list -project "$PROJECT_DIR/Brrow.xcodeproj" >/dev/null 2>&1; then
    echo "   ✅ Xcode can read the project"
else
    echo "   ❌ Xcode cannot read the project"
    exit 1
fi

echo ""
echo "✅ All checks passed!"
echo ""
echo "📦 Next Steps:"
echo "   1. Open Xcode"
echo "   2. Select 'Any iOS Device' or a connected device"
echo "   3. Go to Product → Archive"
echo "   4. After archiving, check Xcode Organizer"
echo "   5. Verify the new archive shows as 'iOS App Archive' (not 'Generic Xcode Archive')"
echo ""
echo "To verify a specific archive has ApplicationProperties:"
echo "   ARCHIVE_PATH=\"~/Library/Developer/Xcode/Archives/2025-10-16/Brrow-XXXX.xcarchive\""
echo "   /usr/libexec/PlistBuddy -c \"Print :ApplicationProperties\" \"\$ARCHIVE_PATH/Info.plist\""
echo ""
