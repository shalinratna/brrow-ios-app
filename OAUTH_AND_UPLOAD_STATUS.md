# OAuth & Profile Upload Status Report

## ⚠️ ISSUES FOUND

### 1. Apple Sign-In & Google Sign-In - MISSING Backend Endpoints

**iOS App Status:** ✅ Fully implemented
- Google Sign-In button exists
- Apple Sign-In button exists
- Both send requests to backend

**Backend Status:** ❌ MISSING ENDPOINTS

**iOS App Expects:**
- `POST /api/auth/google` - For Google Sign-In
- `POST /api/auth/apple` - For Apple Sign-In

**What Backend Has:**
- ❌ No `/api/auth/google` endpoint found
- ❌ No `/api/auth/apple` endpoint found
- ✅ Has `/api/auth/2fa` endpoints (two-factor auth)

**Impact:**
- Users can click Google/Apple Sign-In buttons
- Backend returns 404 (endpoint not found)
- Sign-in fails

---

### 2. Profile Picture Upload - 500 Error

**Error from iOS:**
```
📡 Response: 500 for /api/profile/upload-picture
❌ Profile picture upload error: serverErrorCode(500)
```

**Backend Endpoint:** ✅ EXISTS at `/api/profile/upload-picture`

**Code Location:** `prisma-server.js:4336`

**What Endpoint Does:**
1. Validates image data (base64 format)
2. Checks image size (max 5MB)
3. Uploads to Cloudinary
4. Runs NSFW moderation check
5. Updates user profile

**Likely Causes of 500 Error:**
1. ⚠️ Cloudinary upload failing
2. ⚠️ NSFW moderation function error
3. ⚠️ Discord logging function error
4. ⚠️ Database update error

**Need to Check:**
- Railway logs for exact error message
- Cloudinary configuration
- `uploadToCloudinary()` function
- `checkImageNSFW()` function
- `logToDiscord()` function

---

## 🔧 FIXES REQUIRED

### Fix 1: Add OAuth Endpoints (High Priority)

**Need to create:**

#### `/api/auth/google` Endpoint
```javascript
router.post('/auth/google', async (req, res) => {
  try {
    const { googleId, email, firstName, lastName, idToken } = req.body;

    // Verify Google ID token
    // Find or create user
    // Generate JWT
    // Return user data + token

    res.json({
      success: true,
      token: jwtToken,
      user: userData
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

#### `/api/auth/apple` Endpoint
```javascript
router.post('/auth/apple', async (req, res) => {
  try {
    const { appleId, email, firstName, lastName, identityToken } = req.body;

    // Verify Apple ID token
    // Find or create user
    // Generate JWT
    // Return user data + token

    res.json({
      success: true,
      token: jwtToken,
      user: userData
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

**Where to Add:** `routes/auth.js` or add to `prisma-server.js`

---

### Fix 2: Debug Profile Upload Error (High Priority)

**Step 1: Check Railway Logs**
```bash
railway logs | grep "profile\|upload-picture\|500"
```

**Step 2: Check Cloudinary Function**
Look for errors in `uploadToCloudinary()` function around line 35-65 in prisma-server.js

**Step 3: Check NSFW Moderation**
The endpoint runs NSFW check - this might be failing:
- Line 4404: `const moderationResult = await checkImageNSFW(profilePictureUrl);`
- Check if moderation API is configured

**Step 4: Check Discord Logging**
Line 4410-4422 tries to log to Discord - this might error if webhook not configured

**Temporary Fix:**
Wrap error-prone sections in try-catch to prevent 500:
```javascript
// Around line 4404
try {
  const moderationResult = await checkImageNSFW(profilePictureUrl);
  // ... moderation logic
} catch (moderationError) {
  console.warn('Moderation check failed, allowing upload:', moderationError);
  // Continue with upload
}
```

---

## 📊 Current OAuth Status

### iOS App Implementation
**Google Sign-In:**
- ✅ Button implemented
- ✅ GoogleSignIn SDK configured
- ✅ Client ID: `13144810708-cdf0vg3j0u7krgff4m68pjj6qb6n2dlr.apps.googleusercontent.com`
- ✅ Sends request to `/api/auth/google`
- ❌ Backend endpoint missing

**Apple Sign-In:**
- ✅ Button implemented
- ✅ AuthenticationServices framework used
- ✅ Sends request to `/api/auth/apple`
- ❌ Backend endpoint missing

### Backend Implementation
**Google OAuth:**
- ❌ No endpoint at `/api/auth/google`
- ⚠️ Google OAuth environment variables not set:
  - `GOOGLE_CLIENT_ID` (optional)
  - `GOOGLE_CLIENT_SECRET` (optional)

**Apple Sign-In:**
- ❌ No endpoint at `/api/auth/apple`
- ⚠️ No Apple Sign-In configuration found

---

## 🚀 Quick Fixes

### Option 1: Add OAuth Endpoints Now (Recommended)

I can create the OAuth endpoints for you. They need to:
1. Verify the OAuth token
2. Find existing user or create new user
3. Generate JWT token
4. Return authentication response

**Estimated Time:** 30-45 minutes to implement and test

### Option 2: Disable OAuth Temporarily

If you want to launch without OAuth:
1. Hide Google/Apple buttons in iOS app
2. Use email/password authentication only
3. Add OAuth later

---

## 📋 Priority Checklist

### 🔴 HIGH PRIORITY (Blocking Users)
- [ ] Add `/api/auth/google` endpoint
- [ ] Add `/api/auth/apple` endpoint
- [ ] Fix profile picture upload 500 error

### 🟡 MEDIUM PRIORITY
- [ ] Test Google Sign-In end-to-end
- [ ] Test Apple Sign-In end-to-end
- [ ] Test profile picture upload

### 🟢 LOW PRIORITY
- [ ] Add OAuth token verification
- [ ] Add OAuth error handling
- [ ] Add OAuth analytics tracking

---

## 🔍 Next Steps

1. **Check Railway logs** for profile upload error
2. **Add OAuth endpoints** to routes/auth.js
3. **Test OAuth flow** with real Google/Apple accounts
4. **Fix profile upload** error
5. **Verify everything works** end-to-end

---

**Status:** ⚠️ OAuth and Profile Upload need fixes before launch
**Impact:** Users cannot sign in with Google/Apple, cannot upload profile pictures
**Priority:** HIGH - These are core user-facing features

---

Would you like me to:
1. Create the OAuth endpoints for you?
2. Debug the profile upload error?
3. Both?
