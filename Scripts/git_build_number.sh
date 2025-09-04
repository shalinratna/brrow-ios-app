#!/bin/bash

# Use git commit count as build number
# This ensures unique, incrementing build numbers

# Get the number of commits
buildNumber=$(git rev-list HEAD --count)

# Set the build number
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"

echo "Build number set to commit count: $buildNumber"