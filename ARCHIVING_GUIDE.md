# 📦 Brrow Archiving Guide

## ⚠️ CRITICAL: Always Use the Workspace!

**ALWAYS open `Brrow.xcworkspace` in Xcode, NOT `Brrow.xcodeproj`**

This project uses CocoaPods, which requires building from the `.xcworkspace` file. If you try to archive from `.xcodeproj`, you'll get build errors about missing modules (SocketIO, GoogleSignIn, etc).

## 🏗️ How to Archive from Xcode

1. **Open the correct file:**
   ```bash
   open Brrow.xcworkspace
   ```

2. **In Xcode:**
   - Select "Any iOS Device (arm64)" as the destination (NOT a simulator)
   - Product → Archive
   - Wait for the build to complete
   - Archive should appear in Organizer automatically

3. **If archive doesn't appear in Organizer:**
   ```bash
   ./fix-archive-organizer.sh
   ```
   Then open: Window → Organizer in Xcode

## 🖥️ Command Line Archive (Alternative)

If Xcode GUI has issues, you can archive from command line:

```bash
# Clean build
xcodebuild -workspace Brrow.xcworkspace -scheme Brrow clean

# Create archive
xcodebuild -workspace Brrow.xcworkspace \
  -scheme Brrow \
  -archivePath ~/Library/Developer/Xcode/Archives/$(date '+%Y-%m-%d')/Brrow-$(date '+%H-%M-%S').xcarchive \
  archive \
  -destination "generic/platform=iOS"

# Fix archive metadata if needed
./fix-archive-organizer.sh
```

## 🔧 Troubleshooting

### "No such module 'SocketIO'" or similar errors
- **Cause:** Opening `.xcodeproj` instead of `.xcworkspace`
- **Fix:** Close Xcode, open `Brrow.xcworkspace`, then archive again

### Archive succeeds but doesn't appear in Organizer
- **Cause:** Missing ApplicationProperties in archive Info.plist
- **Fix:** Run `./fix-archive-organizer.sh`

### "CFBundleVersion of app extension must match parent app"
- **Warning only:** This is a non-blocking warning about widget extension version
- Archive will still succeed and work

### Permission denied when archiving
- **Cause:** Directory doesn't exist or has wrong permissions
- **Fix:**
  ```bash
  mkdir -p ~/Library/Developer/Xcode/Archives/$(date '+%Y-%m-%d')
  ```

## 📝 After Archiving

1. Open Xcode Organizer: **Window → Organizer**
2. Verify your archive appears with correct version/build number
3. Click "Distribute App" to upload to App Store Connect or create IPA

## 🎯 Current Build Info

- **Version:** 1.3.4
- **Build:** 600
- **Bundle ID:** com.shaiitech.com.brrow
- **Team:** UXM5W873X3 (Shailay Investment Group Inc.)

## 🤖 Automated Fix

The `fix-archive-organizer.sh` script automatically:
- Scans all archives in `~/Library/Developer/Xcode/Archives/`
- Detects archives missing ApplicationProperties
- Adds the required metadata so they appear in Organizer
- Safe to run multiple times (skips already-fixed archives)
