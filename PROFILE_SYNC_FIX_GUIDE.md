# Profile Data Sync - Immediate Fix Guide

**Priority**: HIGH
**Estimated Time**: 4-6 hours
**Risk Level**: LOW (changes are additive, won't break existing functionality)

---

## Quick Summary

Your profile sync mostly works, but has 3 critical issues:

1. ✅ **Working**: Conversation list refreshes after profile update
2. ❌ **Broken**: Message list doesn't refresh (shows old username/picture)
3. ⚠️ **Inconsistent**: API returns incomplete user data (17 fields vs 50+)

---

## Fix #1: Add Message List Refresh (CRITICAL)

### Problem
When user changes username/profile picture, the conversation list updates but the message list shows old sender data.

### Impact
User sees confusing UI - same person with different names in different views.

### File to Edit
`/Users/shalin/Documents/Projects/Xcode/Brrow/Brrow/ViewModels/ChatDetailViewModel.swift`

### Code Changes

**Add this to ChatDetailViewModel class** (around line 30):

```swift
private func setupProfileUpdateListener() {
    // Listen for profile updates to refresh message sender data
    NotificationCenter.default.publisher(for: .userDidUpdate)
        .sink { [weak self] _ in
            print("👤 [ChatDetailViewModel] userDidUpdate received - refreshing messages")
            guard let self = self,
                  let conversationId = self.conversation?.id else { return }
            self.refreshMessages(for: conversationId)
        }
        .store(in: &cancellables)
}
```

**Call it from init or loadMessages** (around line 40):

```swift
func loadMessages(for conversationId: String) {
    isLoading = true
    conversation = Conversation(
        id: conversationId,
        otherUser: ConversationUser(id: "", username: "", profilePicture: nil, isVerified: false),
        lastMessage: nil,
        unreadCount: 0,
        updatedAt: ""
    )

    // ADD THIS LINE:
    setupProfileUpdateListener()

    // Listen for REST API message sends to refresh
    NotificationCenter.default.addObserver(
        forName: .messageSentViaREST,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        // ... existing code ...
    }

    // ... rest of existing code ...
}
```

**Test**:
1. Open a conversation
2. Change your username
3. Return to conversation
4. Your messages should show new username immediately

---

## Fix #2: Complete API Response (HIGH PRIORITY)

### Problem
Backend returns only 17 fields when iOS model expects 100+ fields. This causes issues when trying to use fields like `apiId`, `displayName`, `location`, etc.

### Impact
- Features that depend on missing fields break
- UI shows empty/default values
- Future features can't access necessary data

### File to Edit
`/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/settings-system.js`

### Code Changes

**Replace lines 14-34** (the select object in GET /api/users/me):

```javascript
// OLD CODE (line 14-34):
select: {
  id: true,
  email: true,
  username: true,
  firstName: true,
  lastName: true,
  profilePictureUrl: true,
  bio: true,
  phoneNumber: true,
  phoneVerified: true,
  isVerified: true,
  createdAt: true,
  averageRating: true,
  totalRatings: true,
  isCreator: true,
  creatorTier: true,
  language: true,
  preferences: true
}

// NEW CODE:
select: {
  // Core Identity
  id: true,
  apiId: true,  // CRITICAL: iOS needs this for API calls
  email: true,
  username: true,

  // Personal Info
  firstName: true,
  lastName: true,
  profilePictureUrl: true,
  bio: true,
  phoneNumber: true,
  phoneVerified: true,
  phoneVerifiedAt: true,
  location: true,  // User's location data
  dateOfBirth: true,  // For birthdate field

  // Verification
  isVerified: true,
  emailVerifiedAt: true,
  verificationStatus: true,

  // Account Status
  isActive: true,
  deletedAt: true,

  // Creator System
  isCreator: true,
  creatorCode: true,
  creatorTier: true,
  creatorStatus: true,
  businessName: true,

  // Ratings
  averageRating: true,
  totalRatings: true,

  // Preferences
  language: true,
  preferences: true,

  // Timestamps
  createdAt: true,
  updatedAt: true,
  lastLoginAt: true,

  // Auth
  primaryAuthProvider: true,
  authMethod: true,

  // Username Management
  lastUsernameChange: true,

  // Subscription (if using)
  subscriptionType: true,
  subscriptionStatus: true,
  subscriptionExpiresAt: true,
  maxListings: true,
  commissionRate: true
}
```

**Also update PUT /api/users/me response** (line 90-110):

```javascript
// Replace the select in line 90-110 with the SAME select as above
const updatedUser = await prisma.user.update({
  where: { id: userId },
  data: updateData,
  select: {
    // Use the SAME expanded select as GET endpoint
    // Copy the entire select object from above
  }
});
```

**Test**:
1. Login to app
2. Check console logs for user data
3. Verify `apiId` is present
4. Update profile
5. Verify all fields still present after update

---

## Fix #3: Field Name Consistency (MEDIUM PRIORITY)

### Problem
iOS sends `phone`, backend expects `phoneNumber`. iOS expects `profilePicture`, backend returns `profilePictureUrl`. This causes silent failures.

### Impact
- Phone number updates might fail
- Profile picture might not display
- Language preference updates fail

### Solution A: Backend Accepts Both (Already Implemented ✅)

Your backend already handles this on line 68:
```javascript
if (phone !== undefined) updateData.phoneNumber = phone;
```

But you need to add similar handling for other fields.

### Solution B: iOS Field Mapping (Recommended)

**File to Edit**: `/Users/shalin/Documents/Projects/Xcode/Brrow/Brrow/Services/APIClient.swift`

**Add this struct** (around line 2400, before updateProfile methods):

```swift
// MARK: - Profile Field Mapping
struct ProfileFieldMapper {
    /// Map iOS field names to backend field names
    static func mapProfileDataToAPI(_ data: ProfileUpdateData) -> [String: Any] {
        var apiData: [String: Any] = [:]

        // Map fields with different names
        if let username = data.username {
            apiData["username"] = username
        }
        if let email = data.email {
            apiData["email"] = email
        }
        if let phone = data.phone {
            apiData["phoneNumber"] = phone  // iOS: phone → Backend: phoneNumber
        }
        if let bio = data.bio {
            apiData["bio"] = bio
        }
        if let birthdate = data.birthdate {
            apiData["birthdate"] = birthdate
        }
        if let profilePicture = data.profilePicture {
            apiData["profilePictureUrl"] = profilePicture  // iOS: profilePicture → Backend: profilePictureUrl
        }

        return apiData
    }

    /// Map backend response to iOS User model (for decoding edge cases)
    static func mapAPIResponseToUser(_ apiUser: [String: Any]) -> [String: Any] {
        var mappedUser = apiUser

        // Backend: phoneNumber → iOS: phone
        if let phoneNumber = apiUser["phoneNumber"] as? String {
            mappedUser["phone"] = phoneNumber
        }

        // Backend: profilePictureUrl → iOS: profilePicture
        if let profilePictureUrl = apiUser["profilePictureUrl"] as? String {
            mappedUser["profilePicture"] = profilePictureUrl
        }

        // Backend: language → iOS: preferredLanguage
        if let language = apiUser["language"] as? String {
            mappedUser["preferredLanguage"] = language
        }

        // Backend: dateOfBirth → iOS: birthdate
        if let dateOfBirth = apiUser["dateOfBirth"] as? String {
            mappedUser["birthdate"] = dateOfBirth
        }

        return mappedUser
    }
}
```

**Update updateProfile method** (line 2481):

```swift
func updateProfile(data: ProfileUpdateData) async throws {
    // USE MAPPER INSTEAD OF DIRECT ENCODING
    let apiData = ProfileFieldMapper.mapProfileDataToAPI(data)
    let bodyData = try JSONSerialization.data(withJSONObject: apiData)

    struct ProfileUpdateAPIResponse: Codable {
        let success: Bool
        let message: String?
        let user: User?
    }

    let response = try await performRequest(
        endpoint: "api/users/me",
        method: .PUT,
        body: bodyData,
        responseType: ProfileUpdateAPIResponse.self
    )

    guard response.success else {
        throw BrrowAPIError.serverError(response.message ?? "Failed to update profile")
    }

    // Update AuthManager with the new user data if available
    if let updatedUser = response.user {
        await MainActor.run {
            AuthManager.shared.currentUser = updatedUser
            // Force save the updated user to keychain
            if let userData = try? JSONEncoder().encode(updatedUser) {
                KeychainHelper().save(String(data: userData, encoding: .utf8) ?? "", forKey: "brrow_user_data")
            }
        }
    }
}
```

**Test**:
1. Update phone number
2. Check network logs - should send `phoneNumber` not `phone`
3. Verify phone number saved correctly
4. Update profile picture
5. Verify displays correctly

---

## Fix #4: Add ProfileViewModel Refresh (LOW PRIORITY)

### Problem
Profile view doesn't refresh automatically after profile update.

### File to Edit
`/Users/shalin/Documents/Projects/Xcode/Brrow/Brrow/ViewModels/ProfileViewModel.swift` (or ModernProfileViewModel.swift)

### Code Changes

**Add to ProfileViewModel**:

```swift
private var cancellables = Set<AnyCancellable>()

init() {
    // Listen for profile updates
    NotificationCenter.default.publisher(for: .userDidUpdate)
        .sink { [weak self] _ in
            print("👤 [ProfileViewModel] userDidUpdate received - refreshing profile")
            self?.refreshProfile()
        }
        .store(in: &cancellables)
}

private func refreshProfile() {
    Task {
        do {
            // Refresh from AuthManager's current user
            if let freshUser = AuthManager.shared.currentUser {
                await MainActor.run {
                    // Update any @Published properties in this ViewModel
                    // based on the fresh user data
                }
            }
        }
    }
}
```

---

## Testing Checklist

After implementing all fixes, test these scenarios:

### Scenario 1: Username Change
- [ ] Login to app
- [ ] Open a conversation
- [ ] Go to Edit Profile
- [ ] Change username
- [ ] Save
- [ ] Return to conversation
- [ ] **Expected**: All messages from you show NEW username
- [ ] **Expected**: Conversation list shows NEW username

### Scenario 2: Profile Picture Change
- [ ] Open a conversation
- [ ] Change profile picture
- [ ] Save
- [ ] Return to conversation
- [ ] **Expected**: Your messages show NEW profile picture
- [ ] **Expected**: Conversation list shows NEW profile picture

### Scenario 3: Phone Number Update
- [ ] Go to Edit Profile
- [ ] Update phone number
- [ ] Save
- [ ] Go to Profile View
- [ ] **Expected**: Shows NEW phone number
- [ ] Log out and log back in
- [ ] **Expected**: Phone number persisted

### Scenario 4: Multiple Field Update
- [ ] Update name, bio, and phone at once
- [ ] Save
- [ ] Check all views (Profile, Settings, Conversations)
- [ ] **Expected**: All fields updated everywhere
- [ ] Force close app
- [ ] Reopen
- [ ] **Expected**: Changes persisted

---

## Deployment Steps

### Phase 1: Backend Changes (Deploy First)
1. Update `settings-system.js` with expanded select
2. Deploy to Railway
3. Test GET /api/users/me endpoint manually
4. Verify response contains all expected fields

### Phase 2: iOS Changes (Deploy After Backend)
1. Implement Fix #1 (ChatDetailViewModel)
2. Implement Fix #3 (Field Mapping) if needed
3. Implement Fix #4 (ProfileViewModel)
4. Test thoroughly on simulator
5. Submit to TestFlight
6. Test on physical device
7. Release to production

### Phase 3: Monitoring
1. Monitor API logs for errors
2. Check user reports for profile issues
3. Verify no increase in crash rate
4. Monitor field mapping warnings in logs

---

## Rollback Plan

If issues arise:

### Backend Rollback
1. Revert `settings-system.js` to previous version
2. Redeploy to Railway
3. Old iOS version will still work (only gets 17 fields)

### iOS Rollback
1. Revert commits
2. Rebuild and redeploy
3. Previous backend API is compatible

---

## Estimated Impact

### Performance
- **Backend**: +0ms (just returning more fields, no extra queries)
- **iOS**: +50ms (slightly larger API response to decode)
- **Network**: +1-2KB per profile fetch (more fields in response)

### User Experience
- ✅ Conversations always show current profile data
- ✅ Messages always show current sender data
- ✅ No more confusing "2 names for same person" issue
- ✅ Profile updates feel more responsive

### Developer Experience
- ✅ Less debugging of "why is field missing?"
- ✅ Easier to add new features (more data available)
- ✅ More consistent codebase

---

## Future Improvements (Not Urgent)

### 1. GraphQL Migration
**Why**: Client requests only needed fields, eliminates over-fetching
**Effort**: HIGH (20-40 hours)
**Benefit**: Better performance, cleaner API

### 2. WebSocket Profile Updates
**Why**: Real-time profile sync across all devices
**Effort**: MEDIUM (8-12 hours)
**Benefit**: Better multi-device experience

### 3. Offline Profile Edit Queue
**Why**: Allow profile edits when offline
**Effort**: MEDIUM (10-15 hours)
**Benefit**: Better offline support

### 4. Profile Data Validation Layer
**Why**: Catch errors before they reach backend
**Effort**: LOW (2-4 hours)
**Benefit**: Fewer API errors, better UX

---

## Questions?

Contact the team if you encounter:
- Backend deployment issues
- iOS build errors
- Test failures
- Unexpected behavior after changes

---

**Last Updated**: 2025-10-01
**Author**: Claude (AI Assistant)
**Review Status**: Pending human review
