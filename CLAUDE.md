- We are creating a master documentation book so keep all.MD files or any updated documentation information. Anything like that that we would need for a future Claude for myself or any future developers who come to work on this project is all going to be inside one file making it one massive thing and I know you cannot create a PDF file but there is already an existing PDF file. I do not want you to read because you will crash if you read that because there's too many pages so just keep everything clear and concise don't make a new MD files, split documentation appropriratelly.

- The Brrow iOS application should always be archivable and the build should always succeed without errors. Archive should never result in Generic Xcode Archive.

## CRITICAL: Xcode Archiving Requirements

**Brrow uses CocoaPods** - this means you MUST follow specific archiving procedures:

### Always Use Workspace File
- ✅ **CORRECT**: Open `Brrow.xcworkspace` for archiving
- ❌ **WRONG**: Opening `Brrow.xcodeproj` creates Generic Xcode Archive (cannot be distributed)

### Why This Matters
- CocoaPods creates both `.xcodeproj` (app only) and `.xcworkspace` (app + dependencies)
- The workspace contains your app + Pods project (GoogleSignIn, Firebase, Stripe, etc.)
- Opening `.xcodeproj` = missing dependencies = Generic Archive
- Opening `.xcworkspace` = complete build = iOS App Archive ✅

### Command Line Archiving
When archiving via xcodebuild, MUST use `-workspace`:
```bash
xcodebuild archive \
  -workspace Brrow.xcworkspace \
  -scheme Brrow \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "path/to/archive.xcarchive"
```

### Before Archiving
1. Ensure CocoaPods installed: `pod install`
2. Open workspace file: `open Brrow.xcworkspace`
3. Verify Xcode window title shows "Brrow.xcworkspace"
4. Set destination to "Any iOS Device (arm64)"

### Verification
A valid iOS App Archive must have `ApplicationProperties` in Info.plist:
```bash
plutil -p "path/to/archive.xcarchive/Info.plist" | grep ApplicationProperties
```

**See XCODE_ARCHIVING_GUIDE.md for complete documentation.**