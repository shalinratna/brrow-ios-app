#!/usr/bin/env python3
import plistlib
import subprocess
from pathlib import Path

archive_path = Path.home() / "Desktop" / "Brrow.xcarchive"
info_plist_path = archive_path / "Info.plist"
app_path = archive_path / "Products" / "Applications" / "Brrow.app"
app_info_plist = app_path / "Info.plist"

# Read archive Info.plist
with open(info_plist_path, 'rb') as f:
    archive_plist = plistlib.load(f)

# Read app Info.plist to get bundle ID and version
with open(app_info_plist, 'rb') as f:
    app_plist = plistlib.load(f)

bundle_id = app_plist.get('CFBundleIdentifier', 'com.shaiitech.com.brrow')
version = app_plist.get('CFBundleShortVersionString', '1.0.0')
build = app_plist.get('CFBundleVersion', '1')

# Add ApplicationProperties
archive_plist['ApplicationProperties'] = {
    'ApplicationPath': 'Applications/Brrow.app',
    'CFBundleIdentifier': bundle_id,
    'CFBundleShortVersionString': version,
    'CFBundleVersion': build,
    'SigningIdentity': 'Apple Development',
    'IconPaths': [
        'Applications/Brrow.app/AppIcon60x60@2x.png',
        'Applications/Brrow.app/AppIcon76x76@2x~ipad.png'
    ]
}

# Write back
with open(info_plist_path, 'wb') as f:
    plistlib.dump(archive_plist, f)

print("✅ Fixed archive Info.plist with ApplicationProperties")
