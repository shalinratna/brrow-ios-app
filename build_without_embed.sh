#!/bin/bash

echo "Building Brrow app without framework embedding issues..."

# Clean
echo "Cleaning..."
xcodebuild -workspace Brrow.xcworkspace -scheme Brrow clean -quiet

# Build without code signing
echo "Building..."
xcodebuild \
    -workspace Brrow.xcworkspace \
    -scheme Brrow \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    echo "App location: ~/Library/Developer/Xcode/DerivedData/Brrow-*/Build/Products/Debug-iphonesimulator/Brrow.app"
else
    echo "❌ Build failed"
fi