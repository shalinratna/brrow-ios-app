# Pre-Release Testing Checklist
**Date**: October 14, 2025
**App Version**: 1.0
**Testing Environment**: iOS 18.4

---

## ✅ Critical Functionality Tests

### 1. Authentication System
- [ ] **Sign Up**: Create new account with email
- [ ] **Sign Up**: Create new account with Google
- [ ] **Sign Up**: Create new account with Apple ID
- [ ] **Sign In**: Login with existing credentials
- [ ] **Email Verification**: Send verification email
- [ ] **Email Verification**: Verify email works (click link)
- [ ] **Password Reset**: Request password reset
- [ ] **Logout**: Sign out successfully
- [ ] **Session Persistence**: App remembers logged-in user after restart

**Debug Logs to Check**:
- `[AUTH]` tags in console
- Token storage/retrieval messages
- API authentication responses

---

### 2. Marketplace & Listings
- [ ] **View Listings**: Marketplace loads all listings
- [ ] **Card Layout**: All cards have identical widths and heights ✅ (JUST FIXED)
- [ ] **Search**: Search for items works
- [ ] **Filters**: Category filters work
- [ ] **Filters**: Price range filters work
- [ ] **Create Listing**: Create new rental listing
- [ ] **Create Listing**: Create new sale listing
- [ ] **Edit Listing**: Modify existing listing
- [ ] **Delete Listing**: Remove listing
- [ ] **Image Upload**: Upload multiple photos
- [ ] **Listing Detail**: View full listing details
- [ ] **Favorites**: Add listing to favorites
- [ ] **Favorites**: Remove from favorites

**Debug Logs to Check**:
- `[MARKETPLACE]` loading messages
- `[CARD RENDER]` showing all cards rendered
- `[TAP HANDLER]` showing taps work
- Image upload progress

---

### 3. Transactions & Purchases
- [ ] **View Transactions**: List shows ONLY user's transactions ✅ (JUST FIXED)
- [ ] **Filter**: "All" shows all user transactions
- [ ] **Filter**: "Active" shows only held payments
- [ ] **Filter**: "Past" shows completed transactions
- [ ] **Filter**: "Buying" shows purchases
- [ ] **Filter**: "Selling" shows sales
- [ ] **Purchase Flow**: Buy an item (test mode)
- [ ] **Rental Flow**: Rent an item (test mode)
- [ ] **Payment**: Stripe payment processes
- [ ] **Receipt**: Receipt generated and viewable
- [ ] **Transaction Detail**: View full transaction details

**Debug Logs to Check**:
- Transaction fetch API calls
- Role parameter (`nil`, `buyer`, `seller`)
- Payment status updates

---

### 4. Messaging & Chat
- [ ] **Chat List**: View all conversations
- [ ] **Send Message**: Send text message
- [ ] **Send Image**: Send photo in chat
- [ ] **Send File**: Send file attachment
- [ ] **Receive Message**: Real-time message arrives
- [ ] **Read Receipts**: Message marked as read
- [ ] **WebSocket**: Real-time updates work
- [ ] **Notifications**: Push notification for new message
- [ ] **Typing Indicator**: See when other user is typing

**Debug Logs to Check**:
- `[WEBSOCKET]` connection status
- Message send/receive logs
- Chat list refresh messages

---

### 5. Profile & Settings
- [ ] **View Profile**: Own profile loads correctly
- [ ] **Profile Picture**: Upload profile picture ✅ (FIXED - persistence)
- [ ] **Profile Picture**: Picture persists after app restart ✅
- [ ] **Edit Profile**: Update name, bio, location
- [ ] **Verification**: ID.me verification flow
- [ ] **Stripe Connect**: Connect Stripe account
- [ ] **Settings**: Toggle notification settings
- [ ] **Settings**: Change language
- [ ] **Settings**: Privacy settings
- [ ] **Account Linking**: Link Google account
- [ ] **Account Linking**: Link Apple ID

**Debug Logs to Check**:
- Profile picture upload progress
- `profilePicture` field mapping from backend
- Settings changes saved

---

### 6. Offers System
- [ ] **View Offers**: See all received offers
- [ ] **View Offers**: See all sent offers
- [ ] **Create Offer**: Make offer on listing
- [ ] **Accept Offer**: Accept incoming offer
- [ ] **Decline Offer**: Reject incoming offer
- [ ] **Counter Offer**: Send counter-offer
- [ ] **Offer Notifications**: Receive notification for new offer
- [ ] **Offer Expiry**: Offers expire after time limit

**Debug Logs to Check**:
- Offer creation API calls
- Offer status changes
- Notification triggers

---

### 7. Garage Sales (if enabled)
- [ ] **View Map**: Garage sale map loads
- [ ] **View List**: Garage sale list view
- [ ] **Create Sale**: Create new garage sale
- [ ] **Edit Sale**: Modify garage sale details
- [ ] **Location**: Location permissions work
- [ ] **Navigation**: Navigate to garage sale location

---

### 8. Notifications
- [ ] **Push Permission**: Request notification permission
- [ ] **Message Notification**: Receive notification for message
- [ ] **Offer Notification**: Receive notification for offer
- [ ] **Transaction Notification**: Receive notification for purchase
- [ ] **In-App Notifications**: View notification history
- [ ] **Mark as Read**: Mark notifications read
- [ ] **Deep Links**: Tap notification opens correct screen

**Debug Logs to Check**:
- `[PUSH NOTIFICATIONS]` registration
- Device token saved
- Notification payload received

---

### 9. Performance & Stability
- [ ] **App Launch**: Cold start under 3 seconds
- [ ] **Marketplace Load**: Listings appear instantly (preloader)
- [ ] **Memory**: No memory warnings during use
- [ ] **Crashes**: No crashes during 10-minute test
- [ ] **Network Loss**: App handles offline gracefully
- [ ] **Network Recovery**: App recovers when network returns
- [ ] **Background/Foreground**: App resumes correctly
- [ ] **iPad**: App displays correctly on iPad (if supported)

**Debug Logs to Check**:
- `[MARKETPLACE] INSTANT LOAD` message
- Preloader statistics
- Network error handling

---

### 10. Edge Cases & Error Handling
- [ ] **No Internet**: App shows meaningful error (not crash)
- [ ] **Invalid Data**: Handles malformed API responses
- [ ] **Empty States**: Shows empty state views correctly
- [ ] **Long Text**: Handles long titles/descriptions
- [ ] **Special Characters**: Handles emojis, unicode
- [ ] **Large Images**: Handles high-resolution photos
- [ ] **Token Expiry**: Handles expired auth token
- [ ] **Concurrent Requests**: Multiple taps don't cause issues

**Debug Logs to Check**:
- Error messages clear and helpful
- No cryptic crashes in console

---

## 🔧 Debug Mode Configuration

### Current Debug Status
✅ **1,337 debug print statements** across 141 files

### Key Debug Tags to Monitor
```
[AUTH]              - Authentication flows
[MARKETPLACE]       - Marketplace loading
[CARD RENDER]       - Card rendering
[TAP HANDLER]       - User interaction
[WEBSOCKET]         - Real-time messaging
[PUSH NOTIFICATIONS]- Push notification system
[API]               - API calls
[CACHE]             - Caching operations
[PEST]              - Performance monitoring
```

### How to View Logs in Xcode
1. Run app in Xcode (⌘+R)
2. Open Debug Console (⌘+Shift+Y)
3. Use filter box to search for specific tags
4. Example: Type `[MARKETPLACE]` to see only marketplace logs

---

## 🚨 Known Issues (Recently Fixed)

### ✅ FIXED (This Session)
1. **Marketplace Card Layout** - Cards now have equal widths (removed GeometryReader)
2. **Transactions Filter** - Now shows only user's transactions (not all system transactions)
3. **Email Verification 404** - Cache-busting prevents 404 errors
4. **Profile Picture Persistence** - Backend correctly maps `profilePicture` field

### ⚠️ Minor Issues to Verify
1. **Build Number Mismatch** - Widget extension vs main app (warning, not critical)
2. **Background Build Processes** - Kill any hanging `xcodebuild` processes before testing

---

## 📱 Testing Environments

### Recommended Test Devices
- [ ] iPhone 16 Pro (iOS 18.4) - Primary device
- [ ] iPhone SE (smaller screen)
- [ ] iPad (if supported)
- [ ] iOS 17.x device (backward compatibility)

### Test Accounts Needed
- [ ] Fresh user account (never used before)
- [ ] Existing user with data
- [ ] User with Stripe connected
- [ ] User with pending transactions
- [ ] User with active chats

---

## 🎯 Critical Path (Must Work)

### User Journey 1: New User Signup → First Purchase
1. Download app → Sign up
2. Browse marketplace → Find item
3. View item details → Make purchase
4. Complete payment → Receive receipt
5. Contact seller → Send message

**Expected Time**: 5-10 minutes
**Success Criteria**: All steps complete without errors

### User Journey 2: Seller Creates Listing → Makes Sale
1. Sign in → Go to "My Posts"
2. Create new listing → Upload photos
3. Set price → Publish
4. Receive offer → Accept offer
5. Complete transaction → Receive payment

**Expected Time**: 5-10 minutes
**Success Criteria**: All steps complete without errors

---

## 📊 Pre-Release Metrics to Check

### App Performance
- [ ] Launch time: < 3 seconds
- [ ] Marketplace load: < 1 second (with preloader)
- [ ] API response time: < 2 seconds average
- [ ] Memory usage: < 150MB during normal use

### Backend Health
```bash
# Test backend is healthy
curl -s "https://brrow-backend-nodejs-production.up.railway.app/health"

# Should return:
# {"status":"healthy","version":"1.3.4","database":"connected"}
```

### Database Integrity
- [ ] No orphaned records
- [ ] All foreign keys valid
- [ ] Transactions match listings
- [ ] User data complete

---

## 🐛 How to Report Issues

### When You Find a Bug
1. **Reproduce** - Can you make it happen again?
2. **Check Console** - What debug logs appear?
3. **Screenshot** - Capture the issue visually
4. **Steps** - Write exact steps to reproduce
5. **Data** - What data caused the issue?

### Bug Report Template
```
**Issue**: [Brief description]
**Steps**:
1. Open app
2. Navigate to X
3. Tap Y
4. See error

**Expected**: [What should happen]
**Actual**: [What actually happens]
**Console Logs**: [Relevant debug output]
**Screenshot**: [If applicable]
**Device**: iPhone 16 Pro, iOS 18.4
```

---

## ✅ Final Release Checklist

Before submitting to App Store:
- [ ] All critical tests passed
- [ ] No console errors during normal use
- [ ] App runs on physical device
- [ ] Screenshots updated
- [ ] App Store metadata complete
- [ ] Privacy policy URL works
- [ ] Terms of service URL works
- [ ] Support email tested
- [ ] TestFlight beta tested (optional but recommended)
- [ ] Version number incremented
- [ ] Build number unique

---

## 🚀 Ready for Release When...

✅ All critical functionality works
✅ No crashes during 30-minute test session
✅ All recent fixes verified (marketplace, transactions, profile picture)
✅ User journey tests complete successfully
✅ Performance metrics meet targets
✅ Backend healthy and stable

---

**Testing Notes**:
- Use Xcode console to monitor all debug logs
- Test on actual device, not just simulator
- Try both happy path and edge cases
- Don't rush - thorough testing prevents user issues

**Start Testing**: Open Xcode → Run app → Follow checklist above ☝️
