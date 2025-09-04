#!/bin/bash

# Auto-increment build number script for Xcode
# Only increments on Archive builds to avoid unnecessary increments during development

# Check if this is an Archive build
if [ "$CONFIGURATION" == "Release" ] || [ "$ACTION" == "install" ]; then
    
    # Get the current build number
    buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
    
    # Increment it
    buildNumber=$((buildNumber + 1))
    
    # Set the new build number
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"
    
    # Also update the project settings
    cd "${PROJECT_DIR}"
    agvtool new-version -all $buildNumber
    
    echo "Build number incremented to: $buildNumber"
else
    echo "Skipping build number increment for non-release build"
fi