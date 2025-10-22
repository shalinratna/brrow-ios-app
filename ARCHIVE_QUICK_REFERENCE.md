# Brrow iOS App - Archive Quick Reference

## Current Build Info
- **Build Number:** 625
- **Version:** 1.3.4
- **Archive Path:** `/Users/shalin/Library/Developer/Xcode/Archives/2025-10-15/Brrow-1.3.4-625.xcarchive`
- **Status:** ✅ iOS App Archive (verified)
- **Privacy Manifests:** 25 (including Alamofire)

## Quick Commands

### Create New Archive (Recommended Method)
```bash
# Increment build number first
agvtool new-version -all 626

# Create archive
./archive-app.sh "Brrow-1.3.4-626"
```

### GUI Archiving (Alternative Method)
```bash
# Start monitor (one-time setup)
./monitor-archives.sh start

# Then use Xcode: Product → Archive
# Archives are automatically fixed within 2-5 seconds

# Check monitor status
./monitor-archives.sh status

# Stop monitor
./monitor-archives.sh stop
```

### Fix Existing Archive
```bash
./add-archive-properties.sh "/path/to/archive.xcarchive"
```

### Verify Archive
```bash
# Check if shows as iOS App (should have ApplicationProperties)
/usr/libexec/PlistBuddy -c "Print :ApplicationProperties" "/path/to/archive.xcarchive/Info.plist"

# Count privacy manifests (should be 25+)
find "/path/to/archive.xcarchive/Products/Applications" -name "PrivacyInfo.xcprivacy" | wc -l

# Verify Alamofire privacy manifest
ls -la "/path/to/archive.xcarchive/Products/Applications/Brrow.app/Frameworks/Alamofire.framework/Alamofire.bundle/PrivacyInfo.xcprivacy"
```

## Scripts Overview

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `archive-app.sh` | Complete archive workflow | **RECOMMENDED** for all builds |
| `add-archive-properties.sh` | Fix individual archive | When archive shows as "Generic" |
| `monitor-archives.sh` | Auto-fix GUI archives | For Xcode GUI archiving |

## Troubleshooting

### Archive shows as "Generic Xcode Archive"
```bash
./add-archive-properties.sh "/path/to/archive.xcarchive"
```

### Build number mismatch
```bash
agvtool new-version -all 626
agvtool what-version  # Should show 626 for all targets
```

### Missing privacy manifests
```bash
pod install
./archive-app.sh "Brrow-1.3.4-626"
```

## For More Details
See: `XCODE_ARCHIVE_SOLUTION.md`
