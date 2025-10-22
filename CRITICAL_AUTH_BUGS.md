# CRITICAL Authentication Bugs - IMMEDIATE FIX REQUIRED

**Date:** October 17, 2025
**Priority:** 🔴 CRITICAL - Users cannot log in
**Status:** 🚧 IN PROGRESS

## 🚨 Critical Issues Discovered

### 1. EMAIL CASE-SENSITIVITY BUG (BLOCKER)

**Problem:** Login fails when email has different capitalization than registration

**Example:**
- User registers: `shalin@brrowapp.com` ✅
- User tries to login: `Shalin@brrowapp.com` ❌ 401 Unauthorized

**Root Cause:** iOS keyboard auto-capitalizes first letter of email field, but backend doesn't normalize email to lowercase before comparison.

**Impact:** Users cannot log into their accounts!

**Fix Required:**
1. Backend: Normalize ALL email inputs to `.toLowerCase()` in ALL auth endpoints
2. iOS: Disable auto-capitalization for email fields

### 2. NO VERIFICATION EMAILS SENT ✅ ROOT CAUSE IDENTIFIED

**Problem:** User created account `shalin@brrowapp.com` but:
- No welcome email received
- Clicked "Verify Email" banner - no email sent, no feedback

**Root Cause:** ✅ **NO EMAIL PROVIDER CONFIGURED ON RAILWAY**
- Railway environment has NO `RESEND_API_KEY` or `SMTP_HOST` configured
- Backend is running in "development mode" - logs emails instead of sending them
- Email service returns `{ success: true, mode: 'development' }` without actually sending

**Fix Required:**
1. ✅ Configure Resend email service on Railway (recommended)
2. ✅ Add `RESEND_API_KEY` and `RESEND_FROM` environment variables
3. ✅ Redeploy backend
4. ✅ Test email delivery end-to-end

**See:** `EMAIL_SERVICE_SETUP.md` for complete setup guide

### 3. SESSION MANAGEMENT CHAOS

**Problem:** User created new account but app loaded OLD account from keychain

**What Happened:**
1. User created `shalin@brrowapp.com`
2. App loaded old session: `shalin_brrow` (API ID: usr_mgvmakwgrs)
3. App switched to DIFFERENT account: `mom`
4. User was randomly logged out

**Root Cause:** Registration doesn't clear keychain before saving new session

**Fix Required:**
1. Clear keychain BEFORE saving new registration credentials
2. Implement proper session invalidation on logout
3. Prevent auto-login after logout

## 📋 Required Code Changes

### Backend Changes (brrow-backend)

#### 1. Fix auth.js - Normalize emails in ALL endpoints

Endpoints to fix:
- POST /api/auth/login
- POST /api/auth/register
- POST /api/auth/google
- POST /api/auth/apple
- POST /api/auth/resend-verification
- GET /api/auth/verify-email

**Pattern to apply:**
```javascript
const email = req.body.email?.toLowerCase().trim();
```

#### 2. Fix email service

Check `services/emailService.js`:
- Ensure `sendEmailVerification()` is working
- Add logging for email send failures
- Add retry logic for transient failures

### iOS Changes (Brrow)

#### 1. Fix Auto-Capitalization

File: `Views/ModernAuthView.swift` (or wherever email TextField is)

**Before:**
```swift
TextField("Email or Username", text: $email)
```

**After:**
```swift
TextField("Email or Username", text: $email)
    .textInputAutocapitalization(.never)
    .autocorrectionDisabled()
    .keyboardType(.emailAddress)
```

#### 2. Fix Registration Session Management

File: `Services/AuthManager.swift`

**Before registration:**
```swift
func register(...) {
    // Register API call
    // Save credentials
}
```

**After:**
```swift
func register(...) {
    // CLEAR OLD SESSION FIRST
    clearStoredAuth()

    // Register API call
    // Save credentials
}
```

## 🧪 Testing Checklist

- [ ] Register with `test@example.com`
- [ ] Try to login with `Test@example.com` (capitalized) - should work
- [ ] Try to login with `TEST@EXAMPLE.COM` - should work
- [ ] Verify email is received
- [ ] Click email verification link - should work
- [ ] Logout completely
- [ ] Register new account - should NOT load old session
- [ ] Check keychain is cleared after logout

## 🔧 Immediate Action Items

**Priority 1 (BLOCKER):**
1. ✅ Fix email case-sensitivity in login endpoint
2. ✅ Fix iOS email field auto-capitalization

**Priority 2 (HIGH):**
3. ✅ Fix email verification sending - Configure Resend on Railway (see EMAIL_SERVICE_SETUP.md)
4. Fix session management

**Priority 3 (MEDIUM):**
5. Add comprehensive error messages
6. Add analytics for auth failures

---

**Next Step:** Fix email case-sensitivity NOW so user can log in!
