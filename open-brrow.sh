#!/bin/bash
# Script to always open Brrow with the correct workspace file
# This ensures archives are iOS App Archives, not Generic Archives

cd /Users/shalin/Documents/Projects/Xcode/Brrow
echo "🚀 Opening Brrow workspace (required for proper archiving)..."
open Brrow.xcworkspace
echo "✅ Brrow.xcworkspace opened"
echo ""
echo "📝 To archive:"
echo "   1. Product → Destination → Any iOS Device"
echo "   2. Product → Archive"
echo ""
echo "⚠️  Always open Brrow.xcworkspace, NOT Brrow.xcodeproj"
