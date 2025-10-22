# iOS Archive Fix - "Generic Xcode Archive" Issue

## Problem
Archives created via `xcodebuild archive` or Xcode Product → Archive were showing as **"Generic Xcode Archive"** instead of **"iOS App"** in Xcode Organizer, preventing distribution to App Store Connect.

## Root Cause
The Xcode scheme file (`Brrow.xcscheme`) had an incorrect configuration in the `ArchiveAction` element. It contained a `BuildableProductRunnable` child element, which should ONLY exist in `LaunchAction` and `ProfileAction`, NOT in `ArchiveAction`.

When `ArchiveAction` contains `BuildableProductRunnable`, Xcode treats the archive as a "generic runnable product" instead of an iOS application for distribution, preventing it from adding the `ApplicationProperties` dictionary to the archive's Info.plist.

## Fix Applied

### 1. Scheme Configuration Fix
**File**: `Brrow.xcodeproj/xcshareddata/xcschemes/Brrow.xcscheme`

**Before:**
```xml
<ArchiveAction
   buildConfiguration = "Release"
   revealArchiveInOrganizer = "YES">
   <BuildableProductRunnable runnableDebuggingMode = "0">
      <BuildableReference ... />
   </BuildableProductRunnable>
</ArchiveAction>
```

**After:**
```xml
<ArchiveAction
   buildConfiguration = "Release"
   revealArchiveInOrganizer = "YES">
</ArchiveAction>
```

### 2. Automatic ApplicationProperties Script
Since `xcodebuild` doesn't automatically add `ApplicationProperties` during archiving (Xcode Organizer adds it when the archive is first opened), I created scripts to automate this:

**add-archive-properties.sh**: Adds ApplicationProperties to existing archives
- Extracts bundle ID, version, build number from app's Info.plist
- Extracts signing identity and team ID from code signature
- Adds complete ApplicationProperties dictionary to archive's Info.plist

**archive-app.sh**: Complete archiving workflow
- Runs xcodebuild archive with correct settings
- Automatically applies add-archive-properties.sh
- Ensures archives always show as "iOS App"

## Usage

### Method 1: Use the Archive Wrapper Script (Recommended)
```bash
./archive-app.sh                    # Creates archive with timestamp name
./archive-app.sh "MyCustomName"     # Creates archive with custom name
```

### Method 2: Fix Existing Archives
```bash
./add-archive-properties.sh ~/Desktop/MyArchive.xcarchive
```

### Method 3: Use Xcode (Now Fixed)
With the scheme fix applied, archives created via Product → Archive in Xcode will now be properly recognized as iOS App archives when opened in Organizer.

## Verification
Archives should now:
- ✅ Show as "iOS App" in Xcode Organizer (not "Generic Xcode Archive")
- ✅ Have "Distribute App" option available
- ✅ Be uploadable to App Store Connect
- ✅ Have ApplicationProperties dictionary in Info.plist

## Technical Details

### ApplicationProperties Dictionary Structure
```xml
<key>ApplicationProperties</key>
<dict>
    <key>ApplicationPath</key>
    <string>Applications/Brrow.app</string>
    <key>CFBundleIdentifier</key>
    <string>com.shaiitech.com.brrow</string>
    <key>CFBundleShortVersionString</key>
    <string>1.3.4</string>
    <key>CFBundleVersion</key>
    <string>619</string>
    <key>SigningIdentity</key>
    <string>Apple Development: Raj Ratna (85NQ732355)</string>
    <key>Team</key>
    <string>UXM5W873X3</string>
</dict>
```

### Build Settings Verified
- ✅ CODE_SIGN_STYLE = Automatic
- ✅ DEVELOPMENT_TEAM = UXM5W873X3
- ✅ SKIP_INSTALL = NO (main app)
- ✅ SKIP_INSTALL = YES (widget extension)
- ✅ INSTALL_PATH = /Applications
- ✅ PRODUCT_BUNDLE_PACKAGE_TYPE resolves to "APPL"

## References
- Apple Technical Note: Troubleshooting iOS App Archives
- Stack Overflow: Why does my archive show as "Generic Xcode Archive"
- Xcode Scheme Format Documentation

## Files Modified
- `Brrow.xcodeproj/xcshareddata/xcschemes/Brrow.xcscheme` - Fixed ArchiveAction
- `add-archive-properties.sh` - Created (utility script)
- `archive-app.sh` - Created (wrapper script)
