# BRROW PRODUCTION TESTING CHECKLIST

## PRE-DEPLOYMENT CHECKLIST

### 1. DATABASE CLEANUP
- [ ] Run cleanup script: `DATABASE_URL="..." node clean_test_listings.js --dry-run`
- [ ] Review what will be deleted
- [ ] Run actual cleanup: `DATABASE_URL="..." node clean_test_listings.js`
- [ ] Verify test listings are removed from production database
- [ ] Backup file created in `/backups/` directory

### 2. BACKEND DEPLOYMENT
- [ ] Backend changes committed to git
- [ ] Backend deployed to Railway
- [ ] Railway deployment successful (check Railway dashboard)
- [ ] Test endpoints respond correctly:
  - `GET https://brrow-backend-nodejs-production.up.railway.app/api/listings`
  - Should return empty array or only real listings (no test data)

### 3. iOS APP BUILD
- [ ] Xcode build succeeds without errors
- [ ] No warning about test data in logs
- [ ] App launches successfully on simulator
- [ ] App launches successfully on physical device

---

## CORE FUNCTIONALITY TESTING

### AUTHENTICATION
- [ ] **Sign Up** - New user registration
  - Create new account with email/password
  - Receive confirmation email (if enabled)
  - Account created in database

- [ ] **Login** - Existing user login
  - Login with valid credentials
  - Receive JWT token
  - Token stored correctly
  - Stay logged in after app restart

- [ ] **Social Login** (if enabled)
  - Login with Google
  - Login with Apple
  - Account linking works

- [ ] **Logout**
  - Logout clears token
  - Redirects to login screen
  - Cannot access protected routes

- [ ] **Forgot Password**
  - Request password reset
  - Receive reset email
  - Reset password successfully

### PROFILE MANAGEMENT
- [ ] **View Profile**
  - Own profile displays correctly
  - Profile picture loads
  - Bio and details shown
  - Username displays correctly

- [ ] **Edit Profile**
  - Update username (respects 90-day cooldown)
  - Update bio
  - Update profile picture
  - Changes persist after app restart

- [ ] **Phone Verification**
  - Add phone number
  - Receive SMS code
  - Verify code successfully
  - Verified badge appears

### MARKETPLACE
- [ ] **Browse Listings**
  - Marketplace loads successfully
  - NO TEST LISTINGS APPEAR (VT Listing, Product for sale, etc.)
  - Only real, active listings shown
  - Images load correctly
  - Prices display correctly

- [ ] **Empty State**
  - If no listings, show "No listings available" message
  - Suggest creating a listing

- [ ] **Search**
  - Search by keyword
  - Filter by category
  - Filter by price range
  - Search results accurate

- [ ] **Featured Listings**
  - Featured section shows popular items
  - NO TEST LISTINGS in featured

### LISTING CREATION
- [ ] **Create New Listing**
  - Fill out listing form
  - Upload images (1-10 images)
  - Select category
  - Set price (daily rate or buy price)
  - Set condition
  - Add description
  - Save listing

- [ ] **Listing Appears**
  - New listing appears in marketplace immediately
  - Images uploaded to Cloudinary
  - All details correct

- [ ] **Edit Listing**
  - Edit existing listing
  - Update title, price, description
  - Changes saved successfully

- [ ] **Delete Listing**
  - Delete listing from "My Posts"
  - Listing no longer appears in marketplace
  - Soft delete (isActive = false)

### MY POSTS
- [ ] **View My Listings**
  - All user's listings shown
  - Active and inactive listings
  - Edit button works
  - Delete button works

### FAVORITES
- [ ] **Add to Favorites**
  - Tap heart icon on listing
  - Listing added to favorites
  - Heart icon fills in

- [ ] **View Favorites**
  - Navigate to favorites tab
  - All favorited listings shown
  - Can unfavorite items

- [ ] **Remove from Favorites**
  - Unfavorite a listing
  - Listing removed from favorites list

### MESSAGING
- [ ] **Start Conversation**
  - Message seller from listing detail
  - New conversation created
  - Message sent successfully

- [ ] **View Conversations**
  - All conversations listed
  - Shows latest message preview
  - Shows timestamp
  - Shows unread indicator

- [ ] **Send Messages**
  - Send text message
  - Message appears immediately
  - Other user receives message (test with 2 accounts)

- [ ] **Receive Messages**
  - Receive message from other user
  - Notification appears (if enabled)
  - Unread badge shows

- [ ] **Real-time Messaging**
  - Messages appear without refresh
  - Conversation updates live
  - Timestamp accurate

### NOTIFICATIONS
- [ ] **Push Notifications** (if enabled)
  - Grant notification permission
  - Receive notification for new message
  - Receive notification for offer
  - Notification taps open correct screen

- [ ] **In-App Notifications**
  - Notification badge shows count
  - Notification list displays
  - Mark as read works

### OFFERS (if implemented)
- [ ] **Send Offer**
  - Send rental/purchase offer
  - Offer sent to listing owner
  - Owner receives notification

- [ ] **Receive Offer**
  - View received offers
  - Accept/decline offer
  - Status updates correctly

### BOOKINGS (if implemented)
- [ ] **Create Booking**
  - Select dates for rental
  - Calculate total price
  - Brrow Protection shown correctly
  - Submit booking request

- [ ] **View Bookings**
  - See active bookings
  - See past bookings
  - Booking status correct

### PAYMENTS (if implemented)
- [ ] **Add Payment Method**
  - Add credit card
  - Card saved securely
  - Stripe integration works

- [ ] **Process Payment**
  - Pay for rental/purchase
  - Payment successful
  - Receipt generated

### SEARCH & DISCOVERY
- [ ] **Search Functionality**
  - Search bar works
  - Results relevant
  - "No results" state works

- [ ] **Category Filtering**
  - Filter by category
  - Subcategories work
  - Clear filters works

- [ ] **Sort Options**
  - Sort by price (low to high)
  - Sort by price (high to low)
  - Sort by newest
  - Sort by popularity

### LOCATION FEATURES (if implemented)
- [ ] **Location Permission**
  - Request location permission
  - Permission granted
  - Location detected correctly

- [ ] **Nearby Listings**
  - Show listings near user
  - Distance calculated correctly
  - Map view works (if enabled)

---

## EDGE CASES & ERROR HANDLING

### NETWORK ERRORS
- [ ] **No Internet Connection**
  - Turn off wifi/data
  - App shows "No connection" message
  - Retry button works
  - Offline mode works (if implemented)

- [ ] **Slow Connection**
  - Throttle network speed
  - Loading indicators show
  - Timeout handled gracefully
  - Retry logic works

- [ ] **API Errors**
  - Server returns 500 error
  - App shows friendly error message
  - User can retry
  - App doesn't crash

### VALIDATION
- [ ] **Empty Form Fields**
  - Try submitting empty form
  - Validation messages appear
  - Required fields marked

- [ ] **Invalid Data**
  - Enter invalid email format
  - Enter price as negative
  - Enter text in number field
  - App validates and shows error

### AUTHENTICATION ERRORS
- [ ] **Invalid Login**
  - Try wrong password
  - Error message clear
  - Can retry

- [ ] **Expired Token**
  - Token expires
  - App redirects to login
  - Message explains why

### LISTING ERRORS
- [ ] **Upload Failures**
  - Image upload fails
  - App shows error
  - Can retry upload
  - Partial uploads handled

- [ ] **Listing Not Found**
  - Try to view deleted listing
  - 404 handled gracefully
  - Shows "Listing unavailable" message

---

## PERFORMANCE TESTING

### LOADING PERFORMANCE
- [ ] **App Launch Time**
  - App launches within 3 seconds
  - Splash screen shows
  - No black screen

- [ ] **Marketplace Load Time**
  - Listings load within 2 seconds
  - Loading indicator shows
  - Pagination works smoothly

- [ ] **Image Loading**
  - Images load progressively
  - Thumbnails load first
  - No broken image icons
  - Caching works (images don't reload)

### MEMORY & BATTERY
- [ ] **Memory Usage**
  - App uses reasonable memory
  - No memory leaks
  - Doesn't crash after extended use

- [ ] **Battery Usage**
  - App doesn't drain battery excessively
  - Background tasks reasonable

---

## USER EXPERIENCE

### UI/UX
- [ ] **Visual Design**
  - UI looks clean and modern
  - Consistent styling
  - Proper spacing
  - Readable fonts

- [ ] **Navigation**
  - Tab bar works correctly
  - Back buttons work
  - Navigation is intuitive
  - Deep links work (if implemented)

- [ ] **Feedback**
  - Buttons show pressed state
  - Loading indicators visible
  - Success messages appear
  - Error messages clear

### ACCESSIBILITY
- [ ] **Dark Mode** (if implemented)
  - App works in dark mode
  - Text readable
  - Colors appropriate

- [ ] **Text Size**
  - Supports dynamic text sizing
  - UI adapts to larger text

---

## SECURITY & PRIVACY

### DATA SECURITY
- [ ] **Token Storage**
  - JWT stored securely (Keychain)
  - Token not in UserDefaults
  - Token not logged

- [ ] **Sensitive Data**
  - Passwords not stored
  - Payment info secure
  - PII handled properly

### PERMISSIONS
- [ ] **Required Permissions Only**
  - Only necessary permissions requested
  - Permission reasons clear
  - App works without optional permissions

---

## TESTING WITH MULTIPLE ACCOUNTS

### Two-Account Testing
- [ ] **User A creates listing**
  - User B can see listing
  - User B can favorite listing
  - User B can message User A

- [ ] **User B sends offer**
  - User A receives offer notification
  - User A can accept/decline
  - Status syncs between accounts

- [ ] **Conversation Flow**
  - Messages send both ways
  - Real-time updates work
  - Unread counts correct

---

## PRODUCTION READINESS

### FINAL CHECKS
- [ ] **No Test Data**
  - NO test listings in marketplace
  - NO test users visible
  - NO placeholder content

- [ ] **No Debug Code**
  - No print statements in production
  - No test API endpoints
  - No hardcoded test tokens

- [ ] **Error Logging**
  - Errors logged to Discord (if set up)
  - Analytics tracking works
  - Crash reporting enabled

- [ ] **App Store Metadata**
  - App name correct
  - Version number updated
  - Bundle ID correct
  - Screenshots current

### POST-DEPLOYMENT MONITORING
- [ ] **Monitor Railway Logs**
  - Watch for errors
  - Check API response times
  - Monitor database connections

- [ ] **Monitor Discord Webhooks**
  - User registrations
  - Listing creations
  - Error notifications
  - System alerts

- [ ] **Monitor App Analytics**
  - User engagement
  - Feature usage
  - Error rates
  - Crash rates

---

## CRITICAL BUGS TO WATCH FOR

### Known Issues to Verify Fixed
- [ ] Marketplace showing test listings - FIXED
- [ ] Username change overwrites - FIXED
- [ ] Message ownership bugs - FIXED
- [ ] Conversation sorting issues - FIXED
- [ ] Timestamp timezone handling - FIXED

### Areas of Concern
- [ ] Image upload failures
- [ ] Token expiration handling
- [ ] Real-time messaging delays
- [ ] Push notification delivery
- [ ] Payment processing errors

---

## SIGN-OFF

### Testing Completed By
- Tester Name: ____________________
- Date: ____________________
- Device: ____________________
- iOS Version: ____________________

### Issues Found
List any issues discovered during testing:

1. ____________________________________________________________
2. ____________________________________________________________
3. ____________________________________________________________

### Production Ready?
- [ ] YES - All critical tests passed, ready for production
- [ ] NO - Issues found, need to address before deployment

### Notes
_____________________________________________________________________
_____________________________________________________________________
_____________________________________________________________________
