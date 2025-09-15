#!/bin/bash

# Build specifically for debugging on physical device
echo "Building for physical device with debugging enabled..."

# Clean build folder
xcodebuild -workspace Brrow.xcworkspace \
           -scheme Brrow \
           -configuration Debug \
           -destination 'generic/platform=iOS' \
           -derivedDataPath ~/Library/Developer/Xcode/DerivedData \
           clean

# Build for device
xcodebuild -workspace Brrow.xcworkspace \
           -scheme Brrow \
           -configuration Debug \
           -destination 'generic/platform=iOS' \
           -derivedDataPath ~/Library/Developer/Xcode/DerivedData \
           build

echo "✅ Build complete! Now you can run from Xcode."
