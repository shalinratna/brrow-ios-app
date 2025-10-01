# Profile Data Flow & Synchronization Diagram

## Complete Profile Update Flow

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                          USER INITIATES PROFILE UPDATE                       ┃
┃                          (EditProfileView.swift:723)                         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┬━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                                │
                                ▼
                    ┌───────────────────────┐
                    │ Has Changes?          │
                    │ (hasChanges flag)     │
                    └───────┬───────────────┘
                            │
                    ┌───────┴───────┐
                    │      YES      │      NO → Dismiss immediately
                    └───────┬───────┘
                            │
                            ▼
                    ┌─────────────────────────────┐
                    │ Is Username Changing?       │
                    └───────┬─────────────────────┘
                            │
                    ┌───────┴───────┐
                    │      YES      │      NO → Skip to Step 2
                    └───────┬───────┘
                            │
                            ▼
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ STEP 1: USERNAME CHANGE                          ┃
        ┃ (EditProfileView.swift:772)                      ┃
        ┗━━━━━━━━━━━━━━━━━━━━┬━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ APIClient.changeUsername(newUsername)          │
        │ → POST /api/users/change-username              │
        │ (APIClient.swift:2716)                         │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Backend (prisma-server.js:3300+)               │
        │ 1. Check 90-day cooldown                       │
        │ 2. Validate username available                 │
        │ 3. Update database                             │
        │ 4. Create UsernameHistory record               │
        │ 5. Return FULL User object                     │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ AuthManager.updateUser(updatedUser)            │
        │ (EditProfileView.swift:775)                    │
        │ • Updates currentUser                          │
        │ • Saves to Keychain                            │
        └────────────────────┬───────────────────────────┘
                               │
                               │
                               ▼
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ STEP 2: OTHER PROFILE FIELDS UPDATE              ┃
        ┃ (EditProfileView.swift:786)                      ┃
        ┗━━━━━━━━━━━━━━━━━━━━┬━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Check: hasNonUsernameChanges?                  │
        │ (email, phone, bio, profileImage)              │
        └────────────────────┬───────────────────────────┘
                               │
                        ┌──────┴──────┐
                        │     YES     │     NO → Skip to Step 3
                        └──────┬──────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Prepare ProfileUpdateData                      │
        │ ⚠️ Uses UPDATED username if changed            │
        │ (EditProfileView.swift:790-797)                │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ APIClient.updateProfile(data)                  │
        │ → PUT /api/users/me                            │
        │ (APIClient.swift:2481)                         │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Backend (settings-system.js:53-120)            │
        │ 1. Accepts: firstName, lastName, bio, etc.     │
        │ 2. ⚠️ Accepts both 'phone' and 'phoneNumber'   │
        │ 3. Updates database                            │
        │ 4. Returns LIMITED User object (17 fields)     │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ ⚠️ ISSUE: API response missing many fields!    │
        │ • No apiId                                     │
        │ • No displayName                               │
        │ • No location                                  │
        │ • No statistics fields                         │
        │ • No subscription fields                       │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ APIClient updates AuthManager internally       │
        │ (APIClient.swift:2502-2510)                    │
        │ ⚠️ With INCOMPLETE user data                   │
        └────────────────────┬───────────────────────────┘
                               │
                               │
                               ▼
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ STEP 3: PROFILE PICTURE UPDATE                   ┃
        ┃ (EditProfileView.swift:804)                      ┃
        ┗━━━━━━━━━━━━━━━━━━━━┬━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Check: imageUrl exists?                        │
        └────────────────────┬───────────────────────────┘
                               │
                        ┌──────┴──────┐
                        │     YES     │     NO → Skip to Step 4
                        └──────┬──────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ APIClient.updateProfileImage(imageUrl)         │
        │ → PUT /api/users/me/profile-picture            │
        │ (APIClient.swift:2542)                         │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Backend (prisma-server.js:3189+)               │
        │ 1. Upload to Cloudinary                        │
        │ 2. Update profilePictureUrl in DB              │
        │ 3. Return FULL User object                     │
        └────────────────────┬───────────────────────────┘
                               │
                               │
                               ▼
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ STEP 4: REFRESH COMPLETE PROFILE                 ┃
        ┃ (EditProfileView.swift:809)                      ┃
        ┗━━━━━━━━━━━━━━━━━━━━┬━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ AuthManager.refreshUserProfile()               │
        │ (AuthManager.swift:156-177)                    │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ APIClient.fetchProfile()                       │
        │ → GET /api/users/me                            │
        │ (APIClient.swift:2438)                         │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Backend (settings-system.js:10-50)             │
        │ Returns LIMITED User object (17 fields)        │
        │ ⚠️ Still missing many fields!                  │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ AuthManager.currentUser = freshUser            │
        │ Keychain updated                               │
        └────────────────────┬───────────────────────────┘
                               │
                               │
                               ▼
        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
        ┃ STEP 5: BROADCAST UPDATE NOTIFICATION            ┃
        ┃ (EditProfileView.swift:817)                      ┃
        ┗━━━━━━━━━━━━━━━━━━━━┬━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ NotificationCenter.post(.userDidUpdate)        │
        └────────────────────┬───────────────────────────┘
                               │
                 ┌─────────────┼─────────────┐
                 │             │             │
                 ▼             ▼             ▼
        ┌────────────┐ ┌─────────────┐ ┌──────────────┐
        │ChatListVM  │ │ProfileVM    │ │Other         │
        │(LISTENS)   │ │(SHOULD      │ │Subscribers   │
        │✅          │ │LISTEN)      │ │              │
        └─────┬──────┘ └─────────────┘ └──────────────┘
              │
              ▼
        ┌────────────────────────────────────────────────┐
        │ ChatListViewModel.fetchConversations()         │
        │ (ChatListViewModel.swift:76-82)                │
        │ bypassCache = true                             │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ APIClient.fetchConversations()                 │
        │ → GET /api/chats/conversations                 │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Backend queries messages table                 │
        │ Includes fresh sender data from users table    │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Conversations show updated profile data        │
        │ ✅ Username, profile picture refreshed         │
        └────────────────────────────────────────────────┘


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                        ⚠️ MISSING REFRESH                                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

        ┌────────────────────────────────────────────────┐
        │ ChatDetailViewModel                            │
        │ ❌ Does NOT listen to .userDidUpdate           │
        │ (ChatDetailViewModel.swift)                    │
        └────────────────────┬───────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────┐
        │ Message list shows STALE sender data           │
        │ • Old username on past messages                │
        │ • Old profile picture                          │
        │ ⚠️ Won't refresh until conversation reopened   │
        └────────────────────────────────────────────────┘
```

---

## Profile Data Storage & Caching Flow

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                         DATA STORAGE LAYERS                             ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Layer 1: PostgreSQL Database (Source of Truth)
┌─────────────────────────────────────────────────────────────────────┐
│ users table                                                         │
│ • 50+ fields                                                        │
│ • Auto-updated timestamps                                           │
│ • Cascading relationships                                           │
│ • Indexed for performance                                           │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
Layer 2: Backend API (Data Gatekeeper)
┌─────────────────────────────────────────────────────────────────────┐
│ GET /api/users/me                                                   │
│ • Returns ONLY 17 fields ⚠️                                         │
│ • Field name translations                                           │
│ • No caching                                                        │
│                                                                     │
│ PUT /api/users/me                                                   │
│ • Accepts 10 fields                                                 │
│ • Returns ONLY 17 fields ⚠️                                         │
│ • Updates timestamp automatically                                   │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
Layer 3: iOS AuthManager (In-Memory Cache)
┌─────────────────────────────────────────────────────────────────────┐
│ @Published var currentUser: User?                                   │
│ • Full User model (100+ fields)                                     │
│ • ⚠️ Many fields are nil (not returned by API)                      │
│ • Updates on: login, refreshUserProfile()                           │
│ • Cleared on: logout, app termination                               │
│                                                                     │
│ Refresh Triggers:                                                   │
│ 1. Manual: authManager.refreshUserProfile()                         │
│ 2. Auto: On app launch (if token exists)                            │
│ 3. Auto: On token refresh                                           │
│ 4. Manual: After profile update                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
Layer 4: Keychain (Persistent Cache)
┌─────────────────────────────────────────────────────────────────────┐
│ Key: "brrow_user_data"                                              │
│ • Stores serialized User JSON                                       │
│ • Survives app restarts                                             │
│ • No expiration                                                     │
│ • ⚠️ Can become stale if not updated properly                       │
│                                                                     │
│ Updates:                                                            │
│ • On login                                                          │
│ • After refreshUserProfile()                                        │
│ • After updateUser()                                                │
│                                                                     │
│ Reads:                                                              │
│ • On app launch (loadStoredAuth)                                    │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
Layer 5: UI (@Published Properties)
┌─────────────────────────────────────────────────────────────────────┐
│ SwiftUI Views observe AuthManager.currentUser                       │
│ • ProfileView                                                       │
│ • EditProfileView                                                   │
│ • ChatListView (via ConversationUser)                               │
│ • ChatDetailView (via Message.sender)                               │
│ • SettingsView                                                      │
│                                                                     │
│ Refresh Methods:                                                    │
│ • Pull-to-refresh (some views)                                      │
│ • .onAppear (most views)                                            │
│ • NotificationCenter .userDidUpdate (ChatListView only)             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Field Name Translation Map

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃              FIELD NAME JOURNEY ACROSS SYSTEMS                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Example 1: Phone Number
────────────────────────────────────────────────────────────────────

iOS User Model          iOS API Request         Backend Field         Database Column
────────────────        ───────────────         ─────────────         ───────────────
phone: String?    →    "phone": "1234567"  →   phoneNumber      →   phone_number
                       ⚠️ MISMATCH!
                       Backend expects:
                       "phoneNumber"

Current Workaround: Backend accepts both "phone" AND "phoneNumber"
Issue: Inconsistent, error-prone


Example 2: Profile Picture
────────────────────────────────────────────────────────────────────

iOS User Model          iOS Decoding            Backend Field         Database Column
────────────────        ────────────            ─────────────         ───────────────
profilePicture:    ←   .profilePicture     ←   profilePictureUrl ←  profile_picture_url
String?                 .profile_picture
                        (tries both!)

Current Workaround: iOS tries to decode both field names
Issue: Inconsistent naming, future maintenance burden


Example 3: Language Preference
────────────────────────────────────────────────────────────────────

iOS User Model          iOS API Request         Backend Field         Database Column
────────────────        ───────────────         ─────────────         ───────────────
preferredLanguage: →   "preferredLanguage" →   language         →   language
String?                 ⚠️ MISMATCH!
                        Backend expects:
                        "language"

Current Status: Likely broken - iOS sends wrong field name
Issue: Language updates probably failing silently


Example 4: Birthdate
────────────────────────────────────────────────────────────────────

iOS User Model          iOS API Request         Backend Field         Database Column
────────────────        ───────────────         ─────────────         ───────────────
birthdate:         →   "birthdate":        →   birthdate        →   date_of_birth
String?                 "2000-01-01"                                  (DateTime)

Issue: Name mismatch DB ↔ Backend, type mismatch String ↔ DateTime
```

---

## Critical Data Flow Issues

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                    ISSUE #1: INCOMPLETE API RESPONSE                    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Database has 50+ user fields
        │
        ▼
Backend API returns only 17 fields
        │
        ├─ id ✅
        ├─ email ✅
        ├─ username ✅
        ├─ firstName ✅
        ├─ lastName ✅
        ├─ profilePictureUrl ✅
        ├─ bio ✅
        ├─ phoneNumber ✅
        ├─ phoneVerified ✅
        ├─ isVerified ✅
        ├─ createdAt ✅
        ├─ averageRating ✅
        ├─ totalRatings ✅
        ├─ isCreator ✅
        ├─ creatorTier ✅
        ├─ language ✅
        └─ preferences ✅
        │
        ▼
iOS receives incomplete data
        │
        ├─ apiId ❌ MISSING
        ├─ displayName ❌ MISSING
        ├─ location ❌ MISSING
        ├─ website ❌ MISSING
        ├─ lastUsernameChange ❌ MISSING
        ├─ usernameChangeCount ❌ MISSING
        ├─ subscriptionType ❌ MISSING
        ├─ activeListings ❌ MISSING
        ├─ totalReviews ❌ MISSING
        └─ ... 30+ more fields missing
        │
        ▼
iOS tries to use missing fields
        │
        ▼
⚠️ Risk: Nil pointer issues, UI shows empty/default data


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃              ISSUE #2: PROFILE UPDATE OVERWRITES RISK                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

User changes username
        │
        ▼
changeUsername() returns FULL user object
        │
        ▼
AuthManager.currentUser updated (line 775)
        │
        ▼
User also changed bio
        │
        ▼
updateProfile() returns LIMITED user object (17 fields)
        │
        ▼
APIClient internally updates AuthManager (line 2504)
        │
        ▼
⚠️ Risk: Limited response overwrites the full data from changeUsername()
        │
        ▼
refreshUserProfile() fetches again
        │
        ▼
Returns LIMITED data (17 fields)
        │
        ▼
✅ But this is expected - iOS model uses optionals


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃            ISSUE #3: MESSAGE LIST NOT REFRESHED                         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

User updates username: "john123" → "john_doe"
        │
        ▼
.userDidUpdate notification posted
        │
        ├────────────────────────────┬────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
ChatListViewModel            ChatDetailViewModel        ProfileViewModel
✅ Listens                   ❌ Does NOT listen         ❌ Does NOT listen
        │                            │                            │
        ▼                            ▼                            ▼
Refreshes conversations      No action taken            No action taken
        │                            │                            │
        ▼                            ▼                            ▼
Shows new username           Still shows "john123"       Shows new username
"john_doe" in list           in message sender names     in profile view
        │                            │                            │
        │                            ▼                            │
        │                    User sees confusing UI:             │
        │                    • Conv list: "john_doe"             │
        │                    • Messages: "john123"               │
        │                    Same person, 2 names!               │
        │                            │                            │
        └────────────────────────────┴────────────────────────────┘
                                     │
                                     ▼
                        User force-closes and reopens app
                                     │
                                     ▼
                          Messages still show "john123"!
                                     │
                                     ▼
                      Why? Because Message.sender is cached
                      with old data, and never refreshed
```

---

## Correct Implementation Pattern (Recommended)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                   RECOMMENDED: CENTRALIZED PROFILE SYNC                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

User updates profile
        │
        ▼
Single API call: updateProfile()
        │
        ▼
Backend returns COMPLETE user object (not just 17 fields!)
        │
        ▼
AuthManager.setCurrentUser(completeUser)
        │
        ├─ Update @Published currentUser
        ├─ Save to Keychain
        └─ Post .userDidUpdate notification
        │
        ▼
All subscribers refresh their views
        │
        ├─────────────────┬─────────────────┬─────────────────┐
        ▼                 ▼                 ▼                 ▼
   ChatListVM      ChatDetailVM       ProfileVM       SettingsVM
        │                 │                 │                 │
        ▼                 ▼                 ▼                 ▼
   Refresh list    Refresh messages  Refresh profile  Refresh settings
        │                 │                 │                 │
        │                 ▼                 │                 │
        │         ✅ Now shows              │                 │
        │            updated data           │                 │
        │            immediately            │                 │
        └─────────────────┴─────────────────┴─────────────────┘
                                │
                                ▼
                        All views in sync
                        Consistent user experience
```

---

## Notification Propagation Diagram

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃               NotificationCenter.userDidUpdate FLOW                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

                    Notification Posted
                    (EditProfileView.swift:817)
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌────────────────┐  ┌────────────────┐
│ChatListVM     │  │ChatDetailVM    │  │ProfileVM       │
│✅ SUBSCRIBED  │  │❌ NOT          │  │❌ NOT          │
│               │  │   SUBSCRIBED   │  │   SUBSCRIBED   │
└───────┬───────┘  └────────────────┘  └────────────────┘
        │
        ▼
NotificationCenter
  .default
  .publisher(for: .userDidUpdate)
  .sink { [weak self] _ in
      self?.fetchConversations(bypassCache: true)
  }
  .store(in: &cancellables)
        │
        ▼
GET /api/chats/conversations
        │
        ▼
Backend includes fresh sender data
        │
        ▼
UI updates with new profile info
✅ Working correctly


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                   WHAT SHOULD HAPPEN (Fix Needed)                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

                    Notification Posted
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌────────────────┐  ┌────────────────┐
│ChatListVM     │  │ChatDetailVM    │  │ProfileVM       │
│✅ SUBSCRIBED  │  │✅ SUBSCRIBED   │  │✅ SUBSCRIBED   │
│               │  │   (NEW!)       │  │   (NEW!)       │
└───────┬───────┘  └───────┬────────┘  └───────┬────────┘
        │                  │                    │
        ▼                  ▼                    ▼
Refresh              Refresh              Refresh
conversations        messages             profile view
        │                  │                    │
        └──────────────────┴────────────────────┘
                           │
                           ▼
                All views show updated data
                  Consistent experience
```

---

**End of Diagram Document**
