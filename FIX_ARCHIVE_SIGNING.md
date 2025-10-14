# Fix Archive Signing Issue

**Problem:** Archive succeeds but doesn't appear in Organizer as "iOS App"

**Root Cause:** Using Development certificate instead of Distribution certificate

---

## Current Status:

```
✅ Build succeeds
✅ Archive creates
❌ Archive classified as "Generic" (not "iOS App")
❌ Organizer doesn't show it for distribution
❌ Can't upload to App Store
```

**Why:** Archives signed with "Apple Development" certificate are not recognized as App Store-ready archives.

---

## Solution 1: Install Distribution Certificate (For App Store)

### Step 1: Create/Download Distribution Certificate

1. Go to https://developer.apple.com/account/resources/certificates
2. Sign in with your Apple Developer account
3. Click **"+"** to create new certificate
4. Select **"Apple Distribution"** (under Production section)
5. Follow prompts to create CSR (Certificate Signing Request):
   - Open **Keychain Access** > **Certificate Assistant** > **Request a Certificate**
   - Enter email, choose "Saved to disk"
6. Upload CSR, download certificate
7. **Double-click** downloaded certificate to install in Keychain

### Step 2: Create App Store Provisioning Profile

1. Go to https://developer.apple.com/account/resources/profiles
2. Click **"+"** to create new profile
3. Select **"App Store"** under Distribution
4. Select your App ID: **com.shaiitech.com.brrow**
5. Select the **Distribution certificate** you just created
6. Name it: "Brrow App Store Distribution"
7. Download and **double-click** to install

### Step 3: Update Xcode Signing

1. Open Xcode
2. Select **Brrow** project in navigator
3. Select **Brrow** target
4. **Signing & Capabilities** tab
5. Uncheck **"Automatically manage signing"**
6. Under **Release** configuration:
   - **Team:** Shaiitech llc (UXM5W873X3)
   - **Signing Certificate:** Apple Distribution
   - **Provisioning Profile:** Brrow App Store Distribution

### Step 4: Do the same for BrrowWidgets Extension

1. Select **BrrowWidgetsExtension** target
2. Same signing settings as above

### Step 5: Archive Again

1. In Xcode: **Product > Archive**
2. Organizer should open automatically
3. Archive will appear as **"iOS App"** (not Generic)
4. Ready to **Distribute App** to App Store

---

## Solution 2: Test Archive with Development Certificate

**NOTE:** This won't allow App Store upload, but will let you test the archive locally or distribute via TestFlight internal testing.

### Quick Test Command:

```bash
# Archive with explicit export
xcodebuild -workspace Brrow.xcworkspace \
  -scheme Brrow \
  -configuration Release \
  -archivePath ~/Desktop/BrrowDev.xcarchive \
  archive

# Export for Ad-Hoc distribution (development)
xcodebuild -exportArchive \
  -archivePath ~/Desktop/BrrowDev.xcarchive \
  -exportPath ~/Desktop/BrrowExport \
  -exportOptionsPlist export-options-adhoc.plist
```

But you'll need to create `export-options-adhoc.plist` first.

---

## Solution 3: Use Xcode's Automatic App Store Signing

If you want to stick with automatic signing:

1. Open Xcode
2. Select Brrow target
3. **Signing & Capabilities** tab
4. Keep **"Automatically manage signing"** checked
5. Make sure your Apple ID is added:
   - Xcode > Settings > Accounts
   - Add Apple ID if not present
   - Download Manual Profiles
6. When archiving, Xcode should automatically:
   - Request App Store certificate
   - Create App Store provisioning profile
   - Sign with correct identity

**NOTE:** Requires Apple Developer Program membership ($99/year)

---

## Why This Matters:

| Certificate Type | Archive Type | Can Distribute? | Organizer Shows? |
|-----------------|--------------|-----------------|------------------|
| Apple Development | Generic | ❌ No | ❌ No |
| Apple Distribution | iOS App | ✅ Yes | ✅ Yes |

**Development certificates** are for:
- Running on device during development
- TestFlight internal testing (sometimes)

**Distribution certificates** are for:
- App Store submission
- TestFlight public beta
- Enterprise distribution

---

## Quick Check Commands:

### See what certificates you have:
```bash
security find-identity -v -p codesigning
```

Look for:
- ✅ "Apple Development: ..." (you have this)
- ❌ "Apple Distribution: ..." (you need this)

### Check current archive Info.plist:
```bash
defaults read ~/Desktop/BrrowTest.xcarchive/Info.plist
```

**Current Output:**
```
{
    ArchiveVersion = 2;
    CreationDate = "2025-10-14 06:48:16 +0000";
    Name = Brrow;
    SchemeName = Brrow;
}
```

**Expected with Distribution certificate:**
```
{
    ApplicationProperties = {
        ApplicationPath = "Applications/Brrow.app";
        CFBundleIdentifier = "com.shaiitech.com.brrow";
        CFBundleShortVersionString = "1.0";
        CFBundleVersion = "607";
        ...
    };
    ArchiveVersion = 2;
    CreationDate = "2025-10-14 06:48:16 +0000";
    Name = Brrow;
    SchemeName = Brrow;
}
```

**ApplicationProperties** is what makes it an "iOS App" archive!

---

## TL;DR:

**Why archive doesn't appear in Organizer:**
- You're using Development certificate
- Xcode sees it as "Generic" archive (not iOS App)
- Organizer only shows iOS App archives in main list

**Fix:**
1. Install Apple Distribution certificate
2. Create App Store provisioning profile
3. Update Xcode signing settings to use Distribution
4. Archive again
5. Organizer will show it as iOS App ✅

---

**Next Steps:**
1. Go to Apple Developer portal
2. Create Distribution certificate
3. Create App Store provisioning profile
4. Update Xcode signing
5. Archive again

Let me know if you need help with any of these steps!
