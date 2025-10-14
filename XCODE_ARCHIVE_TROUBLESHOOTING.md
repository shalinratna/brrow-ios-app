# Xcode Archive Troubleshooting Guide

## Current Status

✅ **Archive EXISTS and is VALID:**
- Location: `/Users/shalin/Library/Developer/Xcode/Archives/2025-10-13/Brrow 10-13-25, 20.21.xcarchive`
- App bundle: Present and valid
- Code signing: Valid
- Created: October 13, 2025, 8:20 PM

## Common Issues & Solutions

### Issue 1: Organizer Won't Open or Shows Nothing

**Symptoms:**
- Archive completes but Organizer doesn't open automatically
- Organizer opens but shows empty list
- Organizer crashes when trying to view archives

**Solutions:**
1. Open Organizer manually:
   - In Xcode: `Window → Organizer` (or `Cmd+Option+Shift+O`)
   - Or run: `open "xcode://organizer"`

2. Restart Xcode completely:
   ```bash
   killall Xcode
   open -a Xcode
   ```

3. Rebuild the Organizer index:
   - Quit Xcode
   - Delete: `~/Library/Developer/Xcode/DerivedData/*`
   - Reopen Xcode

### Issue 2: Archive Fails with "No such module" Error

**Symptom:**
```
error: no such module 'StripePaymentSheet'
error: no such module 'FirebaseAuth'
```

**Solution:**
You MUST use the **workspace** file, not the project file!

❌ **WRONG:** `Brrow.xcodeproj`
✅ **CORRECT:** `Brrow.xcworkspace`

Steps:
1. Close Xcode
2. Open: `Brrow.xcworkspace` (double-click it)
3. Make sure "Any iOS Device" is selected as destination
4. Product → Archive

### Issue 3: Archive Succeeds But Can't Find It

**Solution:**
Archives are stored in:
```
~/Library/Developer/Xcode/Archives/YYYY-MM-DD/
```

Your latest archive:
```
~/Library/Developer/Xcode/Archives/2025-10-13/Brrow 10-13-25, 20.21.xcarchive
```

To open directly:
```bash
open "/Users/shalin/Library/Developer/Xcode/Archives/2025-10-13/Brrow 10-13-25, 20.21.xcarchive"
```

### Issue 4: Using Helper Script

I've created a helper script to make archiving easier:

```bash
cd /Users/shalin/Documents/Projects/Xcode/Brrow
./archive-brrow.sh
```

This script:
- ✅ Ensures you're using the workspace file
- ✅ Cleans build folder
- ✅ Archives with correct settings
- ✅ Verifies the archive
- ✅ Opens Organizer automatically

## Manual Archive Commands

If you want to archive from terminal:

### Clean Build (Recommended first):
```bash
cd /Users/shalin/Documents/Projects/Xcode/Brrow
xcodebuild clean -workspace Brrow.xcworkspace -scheme Brrow -configuration Release
```

### Archive:
```bash
xcodebuild \
  -workspace Brrow.xcworkspace \
  -scheme Brrow \
  -configuration Release \
  -archivePath ~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/"Brrow $(date +%m-%d-%y, %H.%M).xcarchive" \
  -destination "generic/platform=iOS" \
  archive
```

## Verify Archive is Valid

```bash
ARCHIVE="/Users/shalin/Library/Developer/Xcode/Archives/2025-10-13/Brrow 10-13-25, 20.21.xcarchive"

# Check if app bundle exists
ls -la "$ARCHIVE/Products/Applications/Brrow.app"

# Verify code signing
codesign --verify --verbose "$ARCHIVE/Products/Applications/Brrow.app"

# Check archive metadata
defaults read "$ARCHIVE/Info.plist"

# Open in Organizer
open "$ARCHIVE"
```

## Step-by-Step Archiving in Xcode

1. **Open the correct file:**
   - ✅ Double-click `Brrow.xcworkspace`
   - ❌ Don't open `Brrow.xcodeproj`

2. **Select destination:**
   - Top toolbar: select "Any iOS Device"
   - NOT a simulator
   - NOT a specific device

3. **Clean build folder:**
   - `Product → Clean Build Folder` (Cmd+Shift+K)

4. **Build first (optional but recommended):**
   - `Product → Build` (Cmd+B)
   - Make sure it builds successfully

5. **Archive:**
   - `Product → Archive` (Cmd+Option+B)
   - Wait for build to complete (may take 2-5 minutes)

6. **Check Organizer:**
   - Should open automatically when done
   - If not: `Window → Organizer` (Cmd+Option+Shift+O)
   - Click "Archives" tab
   - Select your app "Brrow"
   - See list of archives

## What Went Wrong?

When you said "it did not work at all", what happened exactly?

- [ ] Archive build failed with errors?
- [ ] Archive succeeded but Organizer didn't open?
- [ ] Organizer opened but list was empty?
- [ ] Got "no such module" errors?
- [ ] Something else?

## Quick Fixes

### Fix 1: The Nuclear Option (Clean Everything)
```bash
cd /Users/shalin/Documents/Projects/Xcode/Brrow

# Remove derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean pods
rm -rf Pods/
rm Podfile.lock

# Reinstall pods
pod install

# Now archive
./archive-brrow.sh
```

### Fix 2: Reset Xcode Preferences
```bash
defaults delete com.apple.dt.Xcode
```

### Fix 3: Check Xcode Version
```bash
xcodebuild -version
```

Should show:
```
Xcode 16.x
Build version xxx
```

## Getting Help

If still having issues, I need to know:

1. **What error message do you see?** (exact text)
2. **Where does it fail?** (during build? after build? in Organizer?)
3. **Which file did you open?** (workspace or project?)
4. **What's your selected destination?** (simulator? device? Any iOS Device?)

Run this diagnostic:
```bash
cd /Users/shalin/Documents/Projects/Xcode/Brrow

echo "=== Diagnostics ==="
echo "1. Workspace exists:"
ls -la Brrow.xcworkspace/contents.xcworkspacedata

echo "2. Pods installed:"
ls -la Pods/ | head -5

echo "3. Latest archive:"
ls -la ~/Library/Developer/Xcode/Archives/2025-10-13/

echo "4. Xcode version:"
xcodebuild -version
```

## Success Checklist

After archiving, you should see:

✅ Build completes with "** ARCHIVE SUCCEEDED **"
✅ Organizer opens automatically
✅ Archive appears in list with app icon
✅ Archive shows version 1.3.4 and build 605
✅ "Distribute App" button is enabled
✅ No warnings about missing entitlements or provisioning

---

**Current Archive Location:**
```
/Users/shalin/Library/Developer/Xcode/Archives/2025-10-13/Brrow 10-13-25, 20.21.xcarchive
```

**To open it directly:**
```bash
open "/Users/shalin/Library/Developer/Xcode/Archives/2025-10-13/Brrow 10-13-25, 20.21.xcarchive"
```

**To open Organizer:**
```bash
open "xcode://organizer"
```
