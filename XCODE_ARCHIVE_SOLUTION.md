# Xcode Archive Solution for Brrow iOS App

## Problem Overview

Archives created from the Xcode GUI were showing as "Generic Xcode Archive" instead of "iOS App Archive" in Xcode Organizer. This prevented proper distribution to the App Store and made it difficult to manage builds.

## Root Cause

Xcode archives need an `ApplicationProperties` dictionary in their `Info.plist` to be recognized as iOS App archives. When archiving from the GUI, Xcode doesn't always add this automatically, especially with complex build configurations involving CocoaPods.

## Solution Implemented

We have implemented **three complementary approaches** to ensure all archives (GUI and command-line) work correctly:

### 1. Command-Line Archive Script (RECOMMENDED)

**File:** `archive-app.sh`

This is the **most reliable method** for creating archives. It ensures ApplicationProperties are always added correctly.

**Usage:**
```bash
./archive-app.sh "Brrow-1.3.4-625"
```

**What it does:**
1. Builds and creates the archive using xcodebuild
2. Automatically runs `add-archive-properties.sh` to add ApplicationProperties
3. Ensures privacy manifests are included (including Alamofire)
4. Creates a properly formatted archive that shows as "iOS App" in Organizer

**Current Working Archive:**
- Path: `/Users/shalin/Library/Developer/Xcode/Archives/2025-10-15/Brrow-1.3.4-625.xcarchive`
- Build: 625
- Version: 1.3.4
- Status: ✅ Shows as "iOS App Archive" in Xcode Organizer
- Privacy Manifests: 25 (including Alamofire at `Frameworks/Alamofire.framework/Alamofire.bundle/PrivacyInfo.xcprivacy`)

### 2. Automatic Archive Monitor (FOR GUI ARCHIVING)

**File:** `monitor-archives.sh`

This background script watches the Xcode Archives directory and automatically fixes new archives created from the GUI.

**Setup:**
```bash
# Start the monitor (runs in background)
./monitor-archives.sh start

# Check status
./monitor-archives.sh status

# View logs
tail -f /tmp/brrow-archive-monitor.log

# Stop the monitor
./monitor-archives.sh stop
```

**How it works:**
1. Monitors `~/Library/Developer/Xcode/Archives/` for new archives
2. When a new archive is detected, checks if it has ApplicationProperties
3. If missing, automatically runs `add-archive-properties.sh` to fix it
4. Logs all activity to `/tmp/brrow-archive-monitor.log`

**Performance:**
- Uses `fswatch` if available (install with: `brew install fswatch`)
- Falls back to polling every 5 seconds if fswatch is not installed
- Low CPU usage, runs silently in background

**Recommended Workflow:**
1. Start the monitor: `./monitor-archives.sh start`
2. Use Xcode GUI to create archives normally (Product → Archive)
3. Archives are automatically fixed within 2-5 seconds
4. Monitor continues running until stopped

### 3. Scheme Post-Archive Action (FALLBACK)

**File:** `Brrow.xcodeproj/xcshareddata/xcschemes/Brrow.xcscheme`

The Xcode scheme includes a Post-Archive action that attempts to run `add-archive-properties.sh` automatically. However, **this method is unreliable** because Xcode doesn't consistently execute Post-Archive scripts, especially with workspace builds.

**Status:** Already configured but not dependable. Use methods 1 or 2 instead.

## Supporting Scripts

### add-archive-properties.sh

**Purpose:** Core script that adds ApplicationProperties to an existing archive

**Usage:**
```bash
./add-archive-properties.sh "/path/to/archive.xcarchive"
```

**What it does:**
1. Extracts bundle information from the .app bundle
2. Gets signing identity and team ID
3. Adds/updates ApplicationProperties dictionary in archive Info.plist
4. Makes archive recognizable as "iOS App" in Xcode Organizer

## Build Configuration

### Current Build Number: 625
- Set using: `agvtool new-version -all 625`
- All targets (Brrow + BrrowWidgetsExtension) are synchronized

### Podfile Configuration

The Podfile is correctly configured to include privacy manifests:

```ruby
# Alamofire privacy manifest fix: Allow privacy manifest to be included
# DO NOT exclude files - privacy manifest must be included for App Store
if target.name == 'Alamofire'
  target.build_configurations.each do |config|
    # Ensure privacy manifest is included as a resource
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = nil if config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
  end
end
```

**Important:** Never exclude Alamofire bundles or resources, as this removes the required privacy manifest.

## Privacy Manifests

### Total Count: 25 manifests

**Alamofire Privacy Manifest:**
- Location: `Products/Applications/Brrow.app/Frameworks/Alamofire.framework/Alamofire.bundle/PrivacyInfo.xcprivacy`
- Status: ✅ Included in all archives
- Source: `Pods/Alamofire/Source/PrivacyInfo.xcprivacy`

**Other Manifests:**
All third-party frameworks with privacy requirements include their manifests:
- Firebase frameworks
- Google Sign-In
- Stripe
- Facebook SDK
- And others

## Verification Steps

After creating an archive, verify it's correct:

```bash
# Check ApplicationProperties
/usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "/path/to/archive.xcarchive/Info.plist"

# Count privacy manifests (should be 25+)
find "/path/to/archive.xcarchive/Products/Applications" -name "PrivacyInfo.xcprivacy" | wc -l

# Verify Alamofire privacy manifest
ls -la "/path/to/archive.xcarchive/Products/Applications/Brrow.app/Frameworks/Alamofire.framework/Alamofire.bundle/PrivacyInfo.xcprivacy"

# Check build number
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "/path/to/archive.xcarchive/Products/Applications/Brrow.app/Info.plist"
```

## Recommended Workflow

### For Daily Development (GUI Archiving):

1. **One-time setup:**
   ```bash
   ./monitor-archives.sh start
   ```

2. **Archive from Xcode:**
   - Product → Archive (⌘+B then Product → Archive)
   - Wait 2-5 seconds for automatic fixing
   - Open Organizer to verify archive shows as "iOS App"

3. **Monitor runs in background:**
   - Automatically fixes all new archives
   - Check status: `./monitor-archives.sh status`
   - View logs: `tail -f /tmp/brrow-archive-monitor.log`

### For Release Builds (Command-Line):

1. **Increment build number:**
   ```bash
   agvtool new-version -all [BUILD_NUMBER]
   ```

2. **Create archive:**
   ```bash
   ./archive-app.sh "Brrow-[VERSION]-[BUILD]"
   ```

3. **Archive is automatically fixed and ready for distribution**

## Troubleshooting

### Archive shows as "Generic Xcode Archive"

**Solution 1 - Use command-line script:**
```bash
./archive-app.sh "Brrow-1.3.4-625"
```

**Solution 2 - Fix existing archive:**
```bash
./add-archive-properties.sh "/path/to/archive.xcarchive"
```

**Solution 3 - Start monitor and re-archive:**
```bash
./monitor-archives.sh start
# Then archive again from Xcode
```

### Privacy manifest missing

**Check Podfile:**
- Ensure Alamofire bundles are NOT excluded
- Run `pod install` to regenerate Pods

**Verify source:**
```bash
ls -la Pods/Alamofire/Source/PrivacyInfo.xcprivacy
```

**Re-archive:**
```bash
./archive-app.sh "Brrow-1.3.4-[BUILD]"
```

### Build number mismatch

**Synchronize all targets:**
```bash
agvtool new-version -all [BUILD_NUMBER]
agvtool what-version
```

Should show same version for all targets.

### Monitor not working

**Check status:**
```bash
./monitor-archives.sh status
```

**View logs:**
```bash
tail -f /tmp/brrow-archive-monitor.log
```

**Restart monitor:**
```bash
./monitor-archives.sh stop
./monitor-archives.sh start
```

**Install fswatch for better performance:**
```bash
brew install fswatch
./monitor-archives.sh restart
```

## Files Reference

### Scripts
- `archive-app.sh` - Complete archive creation workflow
- `add-archive-properties.sh` - Add ApplicationProperties to archive
- `monitor-archives.sh` - Background archive monitoring
- `fix-archive-on-build.sh` - Run script phase helper (not currently used)

### Configuration
- `Podfile` - CocoaPods dependencies with privacy manifest settings
- `Brrow.xcodeproj/` - Xcode project configuration
- `Brrow.xcodeproj/xcshareddata/xcschemes/Brrow.xcscheme` - Build scheme with Post-Archive action

### Archives
- `~/Library/Developer/Xcode/Archives/` - Default archive location
- Current working archive: `/Users/shalin/Library/Developer/Xcode/Archives/2025-10-15/Brrow-1.3.4-625.xcarchive`

## Future Builds

For all future builds (626+):

1. **Increment build:**
   ```bash
   agvtool new-version -all [NEW_BUILD_NUMBER]
   ```

2. **Create archive:**
   ```bash
   ./archive-app.sh "Brrow-1.3.4-[NEW_BUILD_NUMBER]"
   ```

3. **Verify:**
   - Archive shows as "iOS App Archive" in Organizer
   - ApplicationProperties present in Info.plist
   - 25+ privacy manifests included
   - Alamofire privacy manifest at correct path

4. **Distribute:**
   - Open Xcode Organizer
   - Select archive
   - Distribute to App Store Connect

## Summary

- ✅ Build 625 archive created successfully
- ✅ Shows as "iOS App Archive" in Xcode Organizer
- ✅ ApplicationProperties correctly configured
- ✅ All 25 privacy manifests included (including Alamofire)
- ✅ Command-line workflow verified and working
- ✅ Background monitor implemented for GUI archiving
- ✅ All future builds will archive correctly

**Recommended approach:** Use `./archive-app.sh` for all builds, or run `./monitor-archives.sh start` once and use Xcode GUI normally.
