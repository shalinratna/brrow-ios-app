# ID.me Verification Testing Guide

**For:** Shalin (Brrow Owner)
**Date:** October 1, 2025
**Status:** Ready for end-to-end testing

---

## 🎯 What's Been Deployed

Your ID.me integration is **FULLY DEPLOYED TO PRODUCTION**. Everything is configured and working on the backend. Now we just need to test it with the actual iOS app.

---

## 📱 How to Test (Step-by-Step)

### Prerequisites:
- iPhone with Brrow app installed
- Active internet connection
- ID.me account (will be created during testing if needed)

### Step 1: Open Brrow App
1. Launch the Brrow app on your iPhone
2. Make sure you're logged in to your account
3. Navigate to the **Profile** tab (bottom right)

### Step 2: Find Identity Verification
1. Look for "Identity Verification" or "Verify with ID.me" option
2. It should be in your profile settings or account security section
3. Tap on "Identity Verification"

### Step 3: Start Verification
1. Tap the **"Start Verification"** or **"Verify Now"** button
2. Safari should open automatically
3. You'll be redirected to ID.me's website

### Step 4: Complete ID.me Flow
1. **If you have an ID.me account:**
   - Log in with your email and password
   - Complete any 2FA if enabled

2. **If you DON'T have an ID.me account:**
   - Tap "Sign Up"
   - Enter your email and create password
   - Follow ID.me's verification steps:
     - Email verification
     - Phone verification (SMS code)
     - Identity verification (document upload)

3. **Grant Permission:**
   - ID.me will ask to share your information with Brrow
   - Review the permissions
   - Tap "Allow" or "Authorize"

### Step 5: Return to Brrow App
1. After completing ID.me verification, you'll be automatically redirected
2. Safari will close
3. Brrow app should open automatically
4. You should see a success message

### Step 6: Verify Success
1. Go back to your Profile
2. Look for a "Verified" badge or checkmark
3. Your profile should now show as "ID.me Verified"

---

## ✅ What to Look For

### Success Indicators:
- ✅ Safari opens to ID.me website
- ✅ ID.me login/signup works
- ✅ Redirects back to Brrow app automatically
- ✅ Success message appears in app
- ✅ Profile shows verified badge
- ✅ No errors or crashes

### Potential Issues:
- ❌ Safari doesn't open → Check iOS URL scheme configuration
- ❌ Can't complete ID.me verification → ID.me account issue
- ❌ Doesn't redirect back to app → Deep link issue
- ❌ No verified badge appears → Check database update

---

## 🔍 What I'll Check After Your Test

### 1. Discord Notifications
I'll receive webhooks showing:
- ✅ Verification completed
- Your email address
- Verification level
- Groups verified (if any)

### 2. Database Record
I'll query the database to verify:
```sql
SELECT
  first_name,
  last_name,
  email,
  verification_level,
  verified,
  verified_at
FROM idme_verifications
WHERE email = '[your_email]';
```

### 3. User Status
I'll check your user record:
```sql
SELECT
  email,
  is_verified,
  verified_at,
  verification_status,
  verification_provider
FROM users
WHERE email = '[your_email]';
```

---

## 🎬 Testing Scenarios

### Scenario 1: Happy Path (Ideal)
1. Open app → Profile → Verify
2. Complete ID.me verification
3. Return to app
4. See success message
5. Profile shows verified badge

**Expected Result:** ✅ Full success

### Scenario 2: Cancel Verification
1. Open app → Profile → Verify
2. ID.me opens in Safari
3. Close Safari before completing
4. Return to app

**Expected Result:** Should show "Verification cancelled" or similar message. User can retry.

### Scenario 3: Already Verified
1. Complete verification once (Scenario 1)
2. Try to verify again

**Expected Result:** Should either:
- Show "Already verified" message, OR
- Update existing verification record

### Scenario 4: Network Error
1. Turn on Airplane Mode
2. Try to start verification

**Expected Result:** Should show network error message

---

## 📊 What Gets Stored

When you complete verification, the following data is stored:

### In `idme_verifications` Table:
- Your full name (from ID.me)
- Email address (from ID.me)
- Phone number (if verified with ID.me)
- Address (if provided to ID.me)
- Verification level (basic, identity, verified)
- Verification status (success)
- Timestamp of verification
- OAuth tokens (for future API calls)
- Raw ID.me response (for audit)

### In `users` Table (Your Brrow Account):
- `is_verified` = true
- `verified_at` = timestamp
- `verification_status` = 'VERIFIED'
- `verification_provider` = 'IDME'

---

## 🐛 Troubleshooting

### Problem: Safari doesn't open when tapping "Verify"
**Possible Causes:**
- URL scheme not configured
- Safari restricted on device
- Network connectivity issue

**How to Debug:**
- Check if other links in the app open Safari
- Restart app and try again
- Check internet connection

**What I Need:**
- Screenshot of what happens when you tap verify
- Any error messages shown

---

### Problem: ID.me verification fails
**Possible Causes:**
- Document not accepted
- Photo quality issues
- ID.me system issue

**How to Debug:**
- This is an ID.me issue, not Brrow
- Try different document type
- Ensure good lighting for photos
- Contact ID.me support if persistent

**What I Need:**
- Screenshot of ID.me error
- What step failed (email, phone, document, etc.)

---

### Problem: Completes ID.me but doesn't return to app
**Possible Causes:**
- Deep link not working
- Backend redirect issue
- iOS 18 permissions

**How to Debug:**
- Check if brrowapp:// URL scheme is registered
- Try manually opening app
- Check background app refresh settings

**What I Need:**
- What URL shows in Safari after completing ID.me
- Screenshot of final page
- iOS version you're using

---

### Problem: Returns to app but no verified badge
**Possible Causes:**
- Database update failed
- UI not refreshing
- User record not linked

**How to Debug:**
- Force quit app and reopen
- Log out and log back in
- Check profile again after 1 minute

**What I Need:**
- Did you see a success message?
- Screenshot of your profile page
- Your email address (so I can check database)

---

## 📸 Screenshots I Need

Please take screenshots of:

1. **Before verification:** Your profile showing "Not Verified"
2. **Verification button:** The button you tap to start
3. **ID.me page:** When Safari opens
4. **After completion:** Success message (if any)
5. **Profile after:** Your profile showing verified badge (if it appears)
6. **Any errors:** Any error messages at any step

---

## 🔄 If Something Goes Wrong

### Don't Worry!
- The system is designed to be safe
- You can retry verification as many times as needed
- Your data is secure and encrypted
- We can fix any issues quickly

### What to Do:
1. Take screenshots of the error
2. Note what step you were on
3. Send me:
   - Screenshots
   - Description of what happened
   - What you expected to happen
   - Any error messages

### I Can:
- Check backend logs
- Verify database records
- Fix any configuration issues
- Update code if needed
- Redeploy in minutes

---

## ✅ Success Criteria

We'll know the integration is working if:

1. ✅ Safari opens to ID.me successfully
2. ✅ ID.me verification completes without errors
3. ✅ Automatically returns to Brrow app
4. ✅ Success message appears in app
5. ✅ Profile shows verified badge
6. ✅ Database records created correctly
7. ✅ Discord webhook notifications received
8. ✅ User experience feels smooth

---

## 🎯 Test Accounts

### Live ID.me Account
You can use your real ID.me account and real information. This is a production integration with ID.me's live API.

**What ID.me Accepts:**
- US Driver's License
- US Passport
- US State ID
- Military ID (for military verification)
- Student ID (for student verification - future feature)

### Privacy Note
All data transmitted is encrypted. ID.me is a trusted identity verification provider used by government agencies and major companies. Your data is handled according to their privacy policy and GDPR/CCPA regulations.

---

## 📞 Contact During Testing

If you encounter any issues during testing:

1. **Take screenshots** of everything
2. **Note the exact steps** you took
3. **Describe what happened** vs what you expected
4. **Send me all details** so I can investigate

I can:
- Check backend logs in real-time
- Query database for your records
- See Discord webhook notifications
- Debug any issues immediately
- Deploy fixes within minutes

---

## 🚀 After Successful Test

Once you've successfully completed verification:

1. I'll verify the database records
2. I'll confirm Discord notifications worked
3. I'll validate all data was stored correctly
4. We'll mark the integration as "VERIFIED IN PRODUCTION"
5. We can enable for all users

---

## 📋 Test Checklist

Use this checklist during testing:

- [ ] App opens successfully
- [ ] Navigate to Profile → Identity Verification
- [ ] Tap "Start Verification" button
- [ ] Safari opens to ID.me
- [ ] Create account or log in to ID.me
- [ ] Complete email verification (if new account)
- [ ] Complete phone verification (if required)
- [ ] Upload identity document (if required)
- [ ] Grant permission to share data with Brrow
- [ ] Automatically redirected back to Brrow app
- [ ] Success message displayed
- [ ] Profile shows verified badge
- [ ] No errors or crashes occurred
- [ ] Screenshots taken of each step

---

## 🎉 Ready to Test!

The system is deployed and ready. Whenever you're ready to test, just follow the steps above and let me know how it goes!

**Remember:**
- Take screenshots at each step
- Note any errors or unexpected behavior
- You can retry as many times as needed
- I can fix issues quickly if anything goes wrong

**Good luck with testing! 🚀**

---

**Last Updated:** October 1, 2025
**Status:** Ready for end-to-end testing
**Next Step:** Test with physical iOS device
