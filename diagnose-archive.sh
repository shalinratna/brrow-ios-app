#!/bin/bash

ARCHIVE="/Users/shalin/Library/Developer/Xcode/Archives/2025-10-07/Brrow 10-7-25, 11.00.xcarchive"

echo "🔍 DIAGNOSING GENERIC ARCHIVE"
echo "================================================================"
echo ""

echo "Archive: $(basename "$ARCHIVE")"
echo ""

# Check structure
echo "1. TOP LEVEL CONTENTS:"
ls -la "$ARCHIVE/" 2>/dev/null
echo ""

# Check Products folder
echo "2. PRODUCTS FOLDER:"
if [ -d "$ARCHIVE/Products" ]; then
  ls -la "$ARCHIVE/Products/" 2>/dev/null
  echo ""

  if [ -d "$ARCHIVE/Products/Applications" ]; then
    echo "3. APPLICATIONS FOLDER:"
    ls -la "$ARCHIVE/Products/Applications/" 2>/dev/null
    echo ""

    if [ -d "$ARCHIVE/Products/Applications/Brrow.app" ]; then
      echo "✅ Brrow.app EXISTS!"
      echo ""
      echo "Architecture:"
      lipo -info "$ARCHIVE/Products/Applications/Brrow.app/Brrow" 2>/dev/null
    else
      echo "❌ NO Brrow.app FOUND"
    fi
  else
    echo "❌ NO Applications FOLDER"
  fi
else
  echo "❌ NO Products FOLDER"
fi

echo ""
echo "4. INFO.PLIST CONTENTS:"
if [ -f "$ARCHIVE/Info.plist" ]; then
  defaults read "$ARCHIVE/Info.plist" 2>/dev/null
else
  echo "❌ No Info.plist"
fi

echo ""
echo "================================================================"
echo ""
echo "Checking if post-action script ran..."
if [ -f "$ARCHIVE/post-action-log.txt" ]; then
  echo "⚠️  Post-action script DID run"
  cat "$ARCHIVE/post-action-log.txt"
else
  echo "Post-action script did not create log"
fi
