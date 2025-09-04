#!/bin/bash

# Only increment for Archive builds
if [ "${CONFIGURATION}" = "Release" ]; then
    buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}")
    buildNumber=$((buildNumber + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${INFOPLIST_FILE}"
    echo "Build number incremented to $buildNumber"
fi