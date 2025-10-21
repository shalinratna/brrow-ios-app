# 📦 Brrow Archiving Guide

## ⚠️ CRITICAL: Always Use the Workspace!

**ALWAYS open `Brrow.xcworkspace` in Xcode, NOT `Brrow.xcodeproj`**

This project uses CocoaPods, which requires building from the `.xcworkspace` file. If you try to archive from `.xcodeproj`, you'll get build errors about missing modules (SocketIO, GoogleSignIn, etc).

## ✅ AUTOMATIC ARCHIVE METADATA (BULLETPROOF)

**Good News:** Every archive automatically gets proper ApplicationProperties metadata!

The Xcode scheme now includes a **Post-Archive Action** that runs `add-archive-properties.sh` automatically after EVERY archive, whether you archive from:
- Xcode GUI (Product → Archive)
- Command line (`xcodebuild archive`)
- The `archive-app.sh` convenience script

This means all archives will ALWAYS show as "iOS App" in Xcode Organizer. No manual fixes needed!

## 🏗️ How to Archive from Xcode (RECOMMENDED)

1. **Open the correct file:**
   ```bash
   open Brrow.xcworkspace
   ```

2. **In Xcode:**
   - Select "Any iOS Device (arm64)" as the destination (NOT a simulator)
   - Product → Archive
   - Wait for the build to complete
   - Archive will AUTOMATICALLY have ApplicationProperties added
   - Archive will appear in Organizer as "iOS App"

3. **Verify the archive (optional):**
   ```bash
   ./verify-archive.sh ~/Library/Developer/Xcode/Archives/YYYY-MM-DD/ArchiveName.xcarchive
   ```

## 🖥️ Command Line Archive (Alternative Method 1)

Use the convenience script that handles everything:

```bash
./archive-app.sh
```

This script:
1. Creates the archive using xcodebuild
2. Automatically adds ApplicationProperties metadata
3. Provides a summary with the archive location

## 🖥️ Command Line Archive (Alternative Method 2)

If you prefer manual xcodebuild commands:

```bash
# Create archive (ApplicationProperties will be added automatically by Post-Archive Action)
xcodebuild archive \
  -workspace Brrow.xcworkspace \
  -scheme Brrow \
  -configuration Release \
  -archivePath ~/Library/Developer/Xcode/Archives/$(date '+%Y-%m-%d')/Brrow-$(date '+%H-%M-%S').xcarchive \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=UXM5W873X3
```

**Note:** The Xcode scheme's Post-Archive Action will automatically run `add-archive-properties.sh`, so no manual fixing needed!

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

## 🤖 Available Scripts

### `archive-app.sh` (Recommended for command line)
Complete workflow that creates archive and adds metadata:
```bash
./archive-app.sh [optional-archive-name]
```

### `add-archive-properties.sh` (Auto-run by Xcode)
Adds ApplicationProperties to an existing archive:
```bash
./add-archive-properties.sh /path/to/Archive.xcarchive
```

**Note:** This script runs AUTOMATICALLY as a Post-Archive Action in the Xcode scheme. You rarely need to run it manually.

### `verify-archive.sh` (Verification tool)
Checks if an archive has proper metadata:
```bash
./verify-archive.sh /path/to/Archive.xcarchive
```

Outputs a detailed report showing:
- Whether ApplicationProperties exists
- All metadata values (Bundle ID, version, signing identity, etc.)
- Pass/fail status

### `fix-archive-organizer.sh` (Legacy - for old archives)
Scans and fixes archives created before the automatic Post-Archive Action was added:
```bash
./fix-archive-organizer.sh
```

## 🔐 How the Automatic System Works

1. **Xcode Scheme Post-Archive Action:**
   - Located in: `Brrow.xcodeproj/xcshareddata/xcschemes/Brrow.xcscheme`
   - Runs after EVERY archive operation
   - Executes: `add-archive-properties.sh $ARCHIVE_PATH`

2. **add-archive-properties.sh:**
   - Extracts app bundle information from the archive
   - Gets signing identity from codesign
   - Adds ApplicationProperties dictionary to archive's Info.plist with:
     - ApplicationPath: "Applications/Brrow.app"
     - CFBundleIdentifier: com.shaiitech.com.brrow
     - CFBundleShortVersionString: (current version)
     - CFBundleVersion: (current build number)
     - SigningIdentity: (certificate name)
     - Team: UXM5W873X3

3. **Result:**
   - Archive shows as "iOS App" in Xcode Organizer
   - Can be distributed to App Store Connect
   - Can be exported as IPA for Ad Hoc/Enterprise distribution

## 🧪 Testing the Automatic System

To verify the system works:

1. Create a test archive:
   ```bash
   ./archive-app.sh test-archive
   ```

2. Verify it has metadata:
   ```bash
   ./verify-archive.sh ~/Library/Developer/Xcode/Archives/$(date '+%Y-%m-%d')/test-archive.xcarchive
   ```

3. Check Xcode Organizer:
   - Open: Window → Organizer in Xcode
   - Archive should show as "iOS App"
   - All metadata fields should be populated
