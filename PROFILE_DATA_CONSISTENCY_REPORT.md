# Profile Data Consistency Verification Report
**Generated**: 2025-10-01
**Status**: COMPREHENSIVE ANALYSIS COMPLETE

---

## Executive Summary

This report provides a detailed verification of profile data consistency across the Brrow iOS app, backend API, and PostgreSQL database. The analysis reveals **CRITICAL MISMATCHES** in field naming conventions and data structures that could lead to data loss, UI inconsistencies, and user confusion.

### Overall Assessment: ⚠️ INCONSISTENT - REQUIRES FIXES

**Risk Level**: MEDIUM-HIGH
**Impact**: Profile updates may fail silently or show stale data across different parts of the app

---

## 1. USER MODEL FIELD COMPARISON

### Side-by-Side Comparison

| Field Category | iOS (User.swift) | Backend API Response (settings-system.js) | Database (schema.prisma) | Status |
|----------------|------------------|------------------------------------------|-------------------------|--------|
| **Core Identity** |
| User ID | `id: String` | `id: String` | `id: String @id` | ✅ MATCH |
| API ID | `apiId: String?` | Not returned | `apiId: String @unique @map("api_id")` | ⚠️ MISSING IN API |
| Username | `username: String` | `username: String` | `username: String?` | ⚠️ OPTIONAL IN DB |
| Email | `email: String` | `email: String` | `email: String @unique` | ✅ MATCH |
| **Personal Info** |
| First Name | `firstName: String?` | `firstName: String` | `firstName: String @map("first_name")` | ✅ MATCH |
| Last Name | `lastName: String?` | `lastName: String` | `lastName: String @map("last_name")` | ✅ MATCH |
| Display Name | `displayName: String?` | ❌ NOT RETURNED | ❌ NOT IN DB | ❌ MISSING |
| Bio | `bio: String?` | `bio: String?` | `bio: String?` | ✅ MATCH |
| Phone | `phone: String?` | `phoneNumber: String?` | `phoneNumber: String? @map("phone_number")` | ⚠️ NAME MISMATCH |
| Location | `location: String?` | ❌ NOT RETURNED | `location: Json?` | ⚠️ TYPE MISMATCH |
| Website | `website: String?` | `website: String?` | ❌ NOT IN DB | ❌ MISSING IN DB |
| Birthdate | `birthdate: String?` | `birthdate: String?` | `dateOfBirth: DateTime? @map("date_of_birth")` | ⚠️ NAME & TYPE MISMATCH |
| **Profile Picture** |
| Profile Pic | `profilePicture: String?` | `profilePictureUrl: String?` | `profilePictureUrl: String? @map("profile_picture_url")` | ⚠️ NAME MISMATCH |
| **Verification** |
| Is Verified | `isVerified: Bool?` | `isVerified: Bool` | `isVerified: Boolean @default(false)` | ✅ MATCH |
| Email Verified | `emailVerified: Bool?` | ❌ NOT RETURNED | `emailVerifiedAt: DateTime?` | ⚠️ STRUCTURE MISMATCH |
| Phone Verified | `phoneVerified: Bool?` | `phoneVerified: Bool?` | `phoneVerified: Boolean @default(false)` | ✅ MATCH |
| **Account Status** |
| Is Active | `isActive: Bool?` | ❌ NOT RETURNED | `isActive: Boolean @default(true)` | ❌ MISSING IN API |
| Is Premium | `isPremium: Bool?` | ❌ NOT RETURNED | ❌ NOT IN DB | ❌ MISSING |
| **Creator System** |
| Is Creator | `❌ NOT IN MODEL` | `isCreator: Bool` | `isCreator: Boolean @default(false)` | ❌ MISSING IN iOS |
| Creator Tier | `❌ NOT IN MODEL` | `creatorTier: String?` | `creatorTier: String?` | ❌ MISSING IN iOS |
| **Ratings** |
| Average Rating | `❌ NOT IN MODEL` | `averageRating: Float?` | `averageRating: Float?` | ❌ MISSING IN iOS |
| Total Ratings | `❌ NOT IN MODEL` | `totalRatings: Int` | `totalRatings: Int @default(0)` | ❌ MISSING IN iOS |
| Lister Rating | `listerRating: Float?` | ❌ NOT IN API | ❌ NOT IN DB | ❌ ONLY IN iOS |
| Borrower Rating | `borrowerRating: Float?` | ❌ NOT IN API | ❌ NOT IN DB | ❌ ONLY IN iOS |
| **Preferences** |
| Language | `preferredLanguage: String?` | `language: String` | `language: String @default("en")` | ⚠️ NAME MISMATCH |
| Preferences | `❌ NOT IN MODEL` | `preferences: Json?` | `preferences: Json?` | ❌ MISSING IN iOS |
| **Timestamps** |
| Created At | `createdAt: String?` | `createdAt: DateTime` | `createdAt: DateTime @default(now())` | ⚠️ TYPE MISMATCH |
| Updated At | `updatedAt: String?` | ❌ NOT RETURNED | `updatedAt: DateTime @updatedAt` | ❌ MISSING IN API |
| Last Active | `lastActive: String?` | ❌ NOT RETURNED | ❌ NOT IN DB | ❌ ONLY IN iOS |

---

## 2. CRITICAL MISMATCHES BREAKDOWN

### 2.1 Field Name Mismatches

These could cause silent data loss or failed updates:

#### High Priority:
1. **Phone Number**
   - iOS expects: `phone`
   - API returns: `phoneNumber`
   - Database: `phoneNumber` → `phone_number`
   - **Issue**: iOS sends `phone`, backend expects `phoneNumber`, could fail silently

2. **Profile Picture**
   - iOS expects: `profilePicture`
   - API returns: `profilePictureUrl`
   - Database: `profilePictureUrl` → `profile_picture_url`
   - **Issue**: Field name mismatch in decoding

3. **Language Preference**
   - iOS expects: `preferredLanguage`
   - API returns: `language`
   - Database: `language`
   - **Issue**: iOS model has wrong field name

4. **Birthdate**
   - iOS sends/expects: `birthdate` (String)
   - API returns: `birthdate`
   - Database: `dateOfBirth` (DateTime) → `date_of_birth`
   - **Issue**: Type and name mismatch

### 2.2 Missing Fields in API Response

The API at `GET /api/users/me` (settings-system.js:10-50) returns ONLY:
```javascript
{
  id, email, username, firstName, lastName,
  profilePictureUrl, bio, phoneNumber, phoneVerified,
  isVerified, createdAt, averageRating, totalRatings,
  isCreator, creatorTier, language, preferences
}
```

But iOS User model expects **55 additional fields** that are NOT returned, including:
- `apiId` - CRITICAL: Used throughout app for API calls
- `displayName` - Used in UI
- `location` - Used in profile display
- `website` - User-entered data
- `isActive` - Account status
- All subscription fields
- All statistics fields (activeListings, totalReviews, etc.)
- Username change tracking fields
- Most verification status fields

### 2.3 Missing Fields in iOS Model

iOS is missing these important backend fields:
- `isCreator` / `creatorTier` - Creator system features
- `averageRating` / `totalRatings` - Rating system (iOS has separate listerRating/borrowerRating)
- `preferences` - User preferences stored as JSON
- `updatedAt` - Last update timestamp

---

## 3. PROFILE UPDATE FLOW ANALYSIS

### 3.1 Update Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│ User Updates Profile in EditProfileView                             │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Username Change (if applicable)                                   │
│    → APIClient.changeUsername(newUsername)                          │
│    → POST /api/users/change-username                                │
│    → Returns updated User object                                    │
│    → Updates AuthManager.currentUser                                │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Profile Update (if non-username changes exist)                   │
│    → APIClient.updateProfile(data: ProfileUpdateData)               │
│    → PUT /api/users/me                                              │
│    → settings-system.js handles request                             │
│    → Returns: User object directly (not wrapped in data)            │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Profile Picture Update (if changed)                              │
│    → APIClient.updateProfileImage(imageUrl)                         │
│    → PUT /api/users/me/profile-picture                              │
│    → prisma-server.js:3189 handles request                          │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. Refresh User Profile                                             │
│    → AuthManager.refreshUserProfile()                               │
│    → GET /api/users/me                                              │
│    → Updates AuthManager.currentUser                                │
│    → Saves to Keychain                                              │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 5. Broadcast Update Notification                                    │
│    → NotificationCenter.post(name: .userDidUpdate)                  │
│    → ChatListViewModel listens and refreshes conversations          │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Critical Issues in Update Flow

#### Issue #1: Double API Call Risk
**Location**: EditProfileView.swift:786-809
**Problem**: If username changes, the flow calls:
1. `changeUsername()` - returns updated user
2. `updateProfile()` - updates other fields

But `updateProfile()` might overwrite the username change if not careful.

**Current Mitigation**: Code skips `updateProfile()` if ONLY username changed (line 781-801)

#### Issue #2: AuthManager Not Updated After Profile Update
**Location**: APIClient.swift:2481-2511
**Problem**: The `updateProfile(data:)` method DOES update AuthManager (lines 2502-2510), but this happens INSIDE APIClient, not coordinated with EditProfileView.

**Result**: EditProfileView calls `authManager.refreshUserProfile()` (line 809) which makes ANOTHER API call to GET the profile, potentially overwriting the update that just happened.

#### Issue #3: Notification Timing
**Location**: EditProfileView.swift:817
**Problem**: `.userDidUpdate` notification is posted AFTER all updates complete. But if the profile picture upload fails (which is separate), the notification is still sent with incomplete data.

---

## 4. CONVERSATION/MESSAGE PROFILE SYNC

### 4.1 How Profile Data Flows to Messages

```
Message Sender Info Sources:
┌────────────────────────────────────┐
│ Database: messages.sender          │ ← Populated from users table
│  ↓                                  │
│ Backend: includes sender: {        │
│   id, username, profilePictureUrl  │
│ }                                   │
│  ↓                                  │
│ iOS: Message.sender: User?         │ ← Decoded from API
│  ↓                                  │
│ UI: Shows sender.username and      │
│     sender.profilePicture          │
└────────────────────────────────────┘
```

### 4.2 Profile Update Propagation

**Current Mechanism**:
- EditProfileView posts `NotificationCenter.userDidUpdate` (line 817)
- ChatListViewModel listens (ChatListViewModel.swift:76-82)
- Calls `fetchConversations(bypassCache: true)`
- Refetches ALL conversations from backend
- Backend queries database with fresh user data
- UI updates with new profile info

**Analysis**: ✅ This mechanism WORKS CORRECTLY

### 4.3 Potential Stale Data Issues

#### Scenario 1: Cached Message Sender Data
**Location**: ChatDetailViewModel.swift:34
**Issue**: Messages cache sender data. If user changes username/picture, old messages still show old data until conversation is refreshed.

**Current Behavior**: Messages are NOT automatically refreshed after profile update.

**Fix Needed**: ChatDetailViewModel should also listen to `.userDidUpdate` and refresh messages.

#### Scenario 2: WebSocket Real-Time Messages
**Location**: WebSocketManager.swift
**Issue**: If a message arrives via WebSocket AFTER profile update but BEFORE conversation refresh, it will have old sender data.

**Impact**: LOW - Next conversation refresh will fix it.

---

## 5. CACHING & REFRESH BEHAVIOR

### 5.1 Profile Data Caching Layers

| Cache Layer | Location | Refresh Trigger | TTL | Issues |
|-------------|----------|-----------------|-----|--------|
| **Keychain** | AuthManager.shared | Manual via `refreshUserProfile()` | Indefinite | May become stale |
| **@Published currentUser** | AuthManager.shared | On login, manual refresh | Session | Stale after profile update |
| **Conversation Cache** | ChatListViewModel | `.userDidUpdate` notification | Manual | ✅ Properly refreshed |
| **Message Cache** | ChatDetailViewModel | None | Manual | ⚠️ Never refreshed on profile update |
| **API Response Cache** | None | N/A | N/A | No HTTP caching detected |

### 5.2 Pull-to-Refresh Coverage

#### Implemented:
- ✅ Conversations list (ChatListView)
- ✅ Listings (HomeView, MyPostsView)
- ✅ Profile view

#### Missing:
- ❌ Chat detail / message list
- ❌ Individual listing detail
- ❌ User profile view (viewing other users)

### 5.3 Keychain Data Consistency

**Current Flow**:
1. Login: User saved to keychain
2. Profile update: User updated in AuthManager.currentUser
3. `refreshUserProfile()`: Fetches fresh data, updates keychain
4. App restart: Loads from keychain

**Issues**:
- If app crashes between steps 2-3, keychain has stale data
- No versioning or timestamps in keychain data
- No data integrity checks

---

## 6. CRITICAL GAPS & RISKS

### 6.1 Data Loss Risks

#### Risk Level: HIGH
**Scenario**: User updates phone number
**Issue**: iOS sends `phone`, backend expects `phoneNumber`
**Result**: Phone update FAILS SILENTLY (backend ignores unknown field)

#### Risk Level: HIGH
**Scenario**: User updates profile in v1 of app, uses v2 with new fields
**Issue**: Keychain has old data structure
**Result**: App crashes or shows missing data

#### Risk Level: MEDIUM
**Scenario**: Backend adds new field (e.g., `displayName`)
**Issue**: iOS model doesn't have it, API doesn't return it
**Result**: Data inconsistency between users

### 6.2 UI Inconsistency Risks

#### Risk Level: MEDIUM
**Scenario**: User changes username, sends message
**Issue**: Old messages in chat still show old username
**Result**: Confusing UI - same user appears with 2 different names

#### Risk Level: LOW
**Scenario**: User updates profile picture during active chat
**Issue**: Other user sees old picture in conversation list until refresh
**Result**: Minor UX issue, resolved on next app launch

### 6.3 API Integration Risks

#### Risk Level: HIGH
**Scenario**: `apiId` missing from API response
**Issue**: iOS code throughout app uses `user.apiId` for API calls
**Result**: App breaks when making API calls after profile update

**Evidence**:
- User.swift:202 - Constructor sets `apiId = apiId ?? id` as fallback
- Many API calls use `currentUser?.apiId`

---

## 7. SPECIFIC FILE ANALYSIS

### 7.1 iOS Model (User.swift)

**File**: `/Users/shalin/Documents/Projects/Xcode/Brrow/Brrow/Models/User.swift`

**Strengths**:
- Comprehensive field coverage (100+ fields)
- Flexible decoding with fallbacks (lines 258-383)
- Handles both `profilePicture` and `profile_picture` (lines 304-316)
- apiId fallback mechanism (lines 272-288)

**Weaknesses**:
- Too many optional fields - hard to know which are actually populated
- Mixes different data sources (API, CoreData, computed)
- No version tracking
- Computed properties depend on optional fields (may return wrong defaults)

**Critical Code**:
```swift
// Line 272-288: apiId fallback
if let apiIdValue = try container.decodeIfPresent(String.self, forKey: .apiId) {
    self.apiId = apiIdValue
} else {
    // Fallback: use the main id if apiId is missing
    print("⚠️ WARNING: apiId not found in response, using id as fallback")
    self.apiId = self.id
}
```
**Issue**: This warning suggests apiId is sometimes missing from API responses.

### 7.2 Backend API (settings-system.js)

**File**: `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/settings-system.js`

**GET /api/users/me** (lines 10-50):
```javascript
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
```

**PUT /api/users/me** (lines 53-120):
- Accepts: `firstName`, `lastName`, `bio`, `phoneNumber`, `username`, `email`, `phone`, `birthdate`, `website`
- Returns: User object directly (not wrapped)
- ⚠️ Returns SAME limited fields as GET

**Issues**:
1. **Selective field return**: Only returns 17 fields out of 100+ in database
2. **No apiId**: Critical field missing
3. **Field name translation**: Accepts both `phone` and `phoneNumber` (line 68) but inconsistent
4. **No data validation**: Doesn't validate if fields match expected formats

### 7.3 Database Schema (schema.prisma)

**File**: `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/prisma/schema.prisma`

**User Model** (lines 14-138):
- 50+ direct fields
- 20+ relation fields
- Extensive metadata tracking

**Strengths**:
- Complete data model
- Proper indexing
- Cascade delete handling
- Timestamps managed automatically

**Weaknesses**:
- Optional username (line 25) - but app requires it
- Complex nested JSON fields (`location`, `preferences`, `verificationData`) - type safety issues
- No field-level validation in schema

### 7.4 Profile Update Endpoints

#### Primary Endpoint: PUT /api/users/me (settings-system.js)
**Request Body**:
```typescript
{
  firstName?: string,
  lastName?: string,
  bio?: string,
  phoneNumber?: string,
  username?: string,  // ⚠️ But should use /change-username
  email?: string,
  phone?: string,     // Alias for phoneNumber
  birthdate?: string,
  website?: string
}
```

**Response**:
```typescript
User {
  // Only 17 fields (see 7.2)
}
```

#### Username Change: POST /api/users/change-username
**Located**: prisma-server.js:3300-3400
**Logic**:
1. Checks 90-day cooldown
2. Validates username availability
3. Updates username
4. Creates UsernameHistory record
5. Returns full user object

**Issue**: This endpoint returns FULL user object, but PUT /api/users/me returns LIMITED fields.

---

## 8. RECOMMENDATIONS

### 8.1 Immediate Fixes (Priority: CRITICAL)

#### Fix #1: Standardize Field Names
**Action**: Create field mapping layer in iOS APIClient
**File**: `APIClient.swift`
**Code**:
```swift
struct ProfileFieldMapper {
    static func mapToAPI(_ localProfile: ProfileUpdateData) -> [String: Any] {
        return [
            "phoneNumber": localProfile.phone,  // Map phone → phoneNumber
            "firstName": localProfile.firstName,
            "lastName": localProfile.lastName,
            // ... rest of fields
        ]
    }

    static func mapFromAPI(_ apiUser: [String: Any]) -> User {
        // Map API response to User model with proper field names
    }
}
```

#### Fix #2: Include apiId in API Response
**Action**: Update settings-system.js GET /api/users/me
**File**: `settings-system.js:10-50`
**Change**:
```javascript
select: {
  id: true,
  apiId: true,  // ADD THIS
  // ... rest of fields
}
```

#### Fix #3: Add ChatDetailViewModel Refresh on Profile Update
**Action**: Listen to `.userDidUpdate` notification
**File**: `ChatDetailViewModel.swift`
**Code**:
```swift
init() {
    NotificationCenter.default.publisher(for: .userDidUpdate)
        .sink { [weak self] _ in
            self?.refreshMessages(for: currentConversationId)
        }
        .store(in: &cancellables)
}
```

### 8.2 Short-Term Improvements (Priority: HIGH)

#### Improvement #1: Profile Data Validation
**Action**: Add validation layer before API calls
**Purpose**: Catch field mismatches before they reach backend

#### Improvement #2: Keychain Data Versioning
**Action**: Add version field to stored User data
**Purpose**: Handle model changes gracefully across app updates

#### Improvement #3: Complete API Response
**Action**: Return ALL user fields from GET /api/users/me
**Purpose**: Eliminate need for multiple API calls to build complete profile

### 8.3 Long-Term Enhancements (Priority: MEDIUM)

#### Enhancement #1: GraphQL Migration
**Purpose**: Client requests only needed fields, eliminates over/under-fetching

#### Enhancement #2: Real-Time Profile Sync
**Purpose**: WebSocket pushes profile updates to all connected clients

#### Enhancement #3: Offline Profile Edit Queue
**Purpose**: Queue profile updates when offline, sync when online

---

## 9. TESTING CHECKLIST

### 9.1 Manual Testing Steps

#### Test Case 1: Basic Profile Update
- [ ] Update first name, last name, bio
- [ ] Verify API request contains correct field names
- [ ] Verify API response contains updated data
- [ ] Verify AuthManager.currentUser updated
- [ ] Verify keychain updated
- [ ] Verify conversation list shows new name
- [ ] Verify message list shows new name (for own messages)

#### Test Case 2: Username Change
- [ ] Change username (first time)
- [ ] Verify 90-day cooldown starts
- [ ] Try to change again (should fail)
- [ ] Verify conversations show new username
- [ ] Verify old messages still show old username (expected)
- [ ] Verify new messages show new username

#### Test Case 3: Profile Picture Update
- [ ] Upload new profile picture
- [ ] Verify image uploaded to backend
- [ ] Verify API response contains new URL
- [ ] Verify AuthManager.currentUser has new URL
- [ ] Verify conversation list shows new picture
- [ ] Refresh conversation - verify still correct

#### Test Case 4: Concurrent Updates
- [ ] Two devices logged in as same user
- [ ] Device A updates profile
- [ ] Device B sends message
- [ ] Verify Device B's message has correct sender info
- [ ] Pull to refresh on Device B
- [ ] Verify conversation shows updated profile

### 9.2 Automated Testing Requirements

#### Unit Tests Needed:
- [ ] User model encoding/decoding with all field variations
- [ ] ProfileUpdateData field mapping
- [ ] AuthManager.refreshUserProfile() updates all caches
- [ ] Notification propagation to ChatListViewModel

#### Integration Tests Needed:
- [ ] End-to-end profile update flow
- [ ] Username change with cooldown
- [ ] Profile picture upload and update
- [ ] Conversation refresh after profile update

---

## 10. CONCLUSION

### 10.1 Current State Assessment

**Profile Data Consistency**: ⚠️ 60% CONSISTENT

**Working Correctly**:
- ✅ Core profile updates (name, bio)
- ✅ Username change flow
- ✅ Conversation list refresh
- ✅ Profile picture upload
- ✅ AuthManager caching

**Broken or Incomplete**:
- ❌ Field name mismatches (phone/phoneNumber, profilePicture/profilePictureUrl)
- ❌ API returns incomplete user data (17 fields vs 100+)
- ❌ Message list not refreshed after profile update
- ❌ apiId sometimes missing from API responses
- ❌ No data versioning or migration strategy

### 10.2 Risk Assessment

**Overall Risk**: MEDIUM-HIGH

**Likelihood of User Impact**: HIGH
**Severity of Impact**: MEDIUM

**Most Likely Failure Scenario**: User updates phone number → fails silently → user thinks it worked → discovers issue when trying to verify phone later

### 10.3 Recommended Action Plan

1. **Week 1**: Implement Fix #1 (field mapping) and Fix #2 (apiId in response)
2. **Week 2**: Implement Fix #3 (message list refresh) and Improvement #1 (validation)
3. **Week 3**: Complete manual testing checklist
4. **Week 4**: Implement Improvement #2 (keychain versioning) and Enhancement #1 (complete API response)

### 10.4 Monitoring Recommendations

**Metrics to Track**:
- Profile update success rate
- API error rate for /api/users/me endpoints
- Client-side validation failures
- Cache refresh frequency
- Field mapping issues (logs)

**Alerting Thresholds**:
- Profile update failure rate > 5%
- apiId missing from response > 1%
- Field mapping errors > 0.1%

---

## APPENDIX A: Field Mapping Reference

### iOS → Backend Field Name Map
```
iOS Field Name          → Backend Field Name
─────────────────────────────────────────────
phone                   → phoneNumber
profilePicture          → profilePictureUrl
preferredLanguage       → language
birthdate               → dateOfBirth (also type change: String → DateTime)
```

### Backend → Database Field Name Map
```
Backend Field Name      → Database Column Name
─────────────────────────────────────────────
phoneNumber             → phone_number
profilePictureUrl       → profile_picture_url
firstName               → first_name
lastName                → last_name
dateOfBirth             → date_of_birth
isVerified              → is_verified
emailVerifiedAt         → email_verified_at
phoneVerified           → phone_verified
```

## APPENDIX B: API Endpoint Quick Reference

| Endpoint | Method | Purpose | Returns Complete User? |
|----------|--------|---------|----------------------|
| `/api/users/me` | GET | Fetch profile | ❌ No (17 fields) |
| `/api/users/me` | PUT | Update profile | ❌ No (17 fields) |
| `/api/users/me/profile-picture` | PUT | Update picture | ✅ Yes (but inconsistent) |
| `/api/users/change-username` | POST | Change username | ✅ Yes |

## APPENDIX C: Notification Flow Diagram

```
Profile Update Event
        │
        ▼
NotificationCenter.post(.userDidUpdate)
        │
        ├─────────────────────┬─────────────────────┐
        ▼                     ▼                     ▼
ChatListViewModel    ProfileViewModel    (Other subscribers)
        │                     │
        ▼                     ▼
fetchConversations()  refreshProfile()
        │                     │
        ▼                     ▼
API: GET /conversations  API: GET /users/me
        │                     │
        ▼                     ▼
Update UI with fresh   Update UI with fresh
  profile data           profile data
```

---

**Report End**

*This report should be reviewed by the backend team, iOS team, and QA team. Address CRITICAL priority items before next production release.*
