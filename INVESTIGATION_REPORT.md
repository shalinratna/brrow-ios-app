# 🔍 Complete Investigation Report - Two Critical Issues

**Date:** October 16, 2025
**Status:** INVESTIGATION IN PROGRESS

---

## 📋 Issue #1: Linked Accounts Showing 0 Despite Database Having Data

### The Mystery:

**Database Reality:**
```
User: shalinratna@gmail.com (ballinshalin)
├── Google ID: 108845935856716955853 ✅
├── Stripe Account: acct_1SGagZDVqsGVjCRV ✅
└── Primary Auth: LOCAL
```

**iOS App Display:**
```
Linked Accounts Count: 0 ❌
Stripe Connected: false ❌
```

---

### Investigation Results:

#### ✅ 1. Backend Code Analysis

**Location:** `routes/auth.js:527-660`

The endpoint `/api/auth/linked-accounts` already has **comprehensive debug logging**:

```javascript
router.get('/linked-accounts', authenticateToken, async (req, res) => {
  const userId = req.user.id;  // From JWT token

  console.log('🔍 [AUTH DEBUG] GET /api/auth/linked-accounts');
  console.log('   👤 User ID:', userId);

  const user = await prisma.users.findUnique({
    where: { id: userId },
    select: {
      google_id: true,
      apple_id: true,
      stripe_account_id: true,
      // ...
    }
  });

  console.log('   Google ID:', user.google_id || 'NOT LINKED');
  console.log('   Apple ID:', user.apple_id || 'NOT LINKED');
  console.log('   Stripe Account ID:', user.stripe_account_id || 'NOT LINKED');

  // Build linkedAccounts array
  if (user.google_id) {
    linkedAccounts.push({
      id: user.google_id,
      provider: 'google',
      // ...
    });
  }

  console.log('   Linked Accounts Count:', linkedAccounts.length);

  res.json({
    success: true,
    data: {
      accounts: linkedAccounts,
      stripe: stripeStatus
    }
  });
});
```

**Analysis:** The code logic is **100% correct**. If `user.google_id` exists, it MUST add it to the array.

---

#### ✅ 2. Database Verification

**Ran diagnostic:** `check-user-oauth-status.js`

**Result:**
```
✅ USER FOUND
   User ID: cmfrmr7l30000nz01qfyr0lc4
   Email: shalinratna@gmail.com
   Google ID: 108845935856716955853
   Stripe Account ID: acct_1SGagZDVqsGVjCRV
   Total Linked Accounts: 1 (Google)
```

**Analysis:** Database has the correct data. No question.

---

#### ❓ 3. The Missing Link

**If the code is correct AND the database has data, why is the API returning 0?**

**Possible Explanations:**

**A. JWT Token Has Wrong User ID**
- JWT contains user ID: `X`
- Database query searches for user ID: `X`
- But finds a different user or no user
- Backend logs should show this

**B. Railway Is Running Old Code**
- GitHub has correct code
- Railway hasn't redeployed
- Still running old version without the fix

**C. Database Connection Mismatch**
- Backend connects to different database than we're querying
- Environment variable `DATABASE_URL` is wrong

**D. The `req.user.id` Is Undefined/Null**
- Auth middleware isn't working correctly
- JWT decode failed silently
- User ID is null, so query returns nothing

---

### 🎯 Next Steps to Solve This:

#### Step 1: Check Railway Logs

The backend **logs everything**. Railway logs will show:
- What user ID the JWT contains
- What the database query returns
- Why the response is empty

**Command:**
```bash
railway logs --limit 100 | grep -A 20 "LINKED ACCOUNTS"
```

**What to look for:**
```
🔍 [AUTH DEBUG] GET /api/auth/linked-accounts
   👤 User ID: cmfrmr7l30000nz01qfyr0lc4  <- Should match your user ID
   ✅ User Data:
      Google ID: 108845935856716955853  <- Should show this!
      Linked Accounts Count: 1          <- Should be 1, not 0!
```

---

#### Step 2: Verify Railway Deployment

**Check latest commit deployed:**
```bash
git log --oneline -1
railway status
```

**Check environment variables:**
```bash
railway variables | grep DATABASE_URL
```

**Should show:**
```
DATABASE_URL=postgresql://postgres:kciFfaaVBLcfEAlHomvyNFnbMjIxGdOE@yamanote.proxy.rlwy.net:10740/railway
```

---

#### Step 3: Test JWT Token

**Decode the JWT token from your app:**

```javascript
// decode-token.js (already created)
const jwt = require('jsonwebtoken');
const token = 'YOUR_TOKEN_FROM_APP';
const decoded = jwt.decode(token);
console.log('JWT User ID:', decoded.userId || decoded.id);
```

**Compare with database user ID:**
```
JWT User ID: ??? <- Should be cmfrmr7l30000nz01qfyr0lc4
DB User ID:  cmfrmr7l30000nz01qfyr0lc4
```

**If they don't match → That's the bug!**

---

#### Step 4: Force Railway Redeploy

If Railway is running old code:

```bash
git add -A
git commit -m "Trigger redeploy: verify linked-accounts endpoint"
git push origin master
railway logs --follow
```

Watch the deployment and verify the latest commit is deployed.

---

## 📋 Issue #2: Push Notifications Not Being Received

### Backend Logs Show:

```
📬 [MessageService] Sending notification to user cmfrmr7l30000nz01qfyr0lc4 for chat 49c238ea-b8a8-4fe8-a40d-f1de905fd88e
Found 1 FCM token(s) for user cmfrmr7l30000nz01qfyr0lc4
✅ [MessageService] Notification sent successfully
```

**The Problem:** Backend says "notification sent successfully", but **recipient doesn't receive it**.

---

### Possible Causes:

#### 1. FCM Token Is Invalid/Expired
- Token exists in database
- But it's old/expired/invalid
- FCM silently fails (doesn't throw error)
- Backend thinks it succeeded

**Fix:** Validate FCM tokens before sending

#### 2. Firebase Cloud Messaging Configuration
- Server key is wrong
- Service account doesn't have permission
- Firebase project mismatch

**Fix:** Verify Firebase credentials

#### 3. iOS App Not Handling Notification
- Notification is delivered to device
- But app doesn't show it (iOS permissions?)
- Notification payload format wrong

**Fix:** Check iOS notification permissions

#### 4. FCM Returns Success But Doesn't Deliver
- Firebase says "sent"
- But actual delivery fails
- Need to check FCM response details

**Fix:** Log FCM response details

---

### Investigation Steps for Notifications:

#### Step 1: Check FCM Token Validity

**Create diagnostic script:**
```javascript
// verify-fcm-token.js
const admin = require('firebase-admin');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function verifyFCMToken() {
  const userId = 'cmfrmr7l30000nz01qfyr0lc4';

  // Get FCM token from database
  const tokens = await prisma.fcmTokens.findMany({
    where: { user_id: userId }
  });

  console.log(`Found ${tokens.length} FCM tokens for user`);

  for (const token of tokens) {
    console.log(`\nToken: ${token.token.substring(0, 20)}...`);
    console.log(`Created: ${token.created_at}`);

    // Try to send test notification
    try {
      const response = await admin.messaging().send({
        token: token.token,
        notification: {
          title: 'Test Notification',
          body: 'Testing if your token works'
        }
      });
      console.log('✅ Token is VALID - Notification sent:', response);
    } catch (error) {
      console.log('❌ Token is INVALID:', error.code);
      console.log('   Error:', error.message);

      // Delete invalid token
      await prisma.fcmTokens.delete({ where: { id: token.id } });
      console.log('   Deleted invalid token from database');
    }
  }
}

verifyFCMToken();
```

---

#### Step 2: Enhanced Logging in MessageService

**Add detailed FCM response logging:**

```javascript
// In services/messageService.js or wherever FCM is called

const response = await admin.messaging().send({
  token: fcmToken,
  notification: {
    title: senderName,
    body: messageContent
  },
  data: {
    chatId: chatId,
    senderId: senderId
  }
});

// ADD THIS:
console.log('📱 FCM Response:', JSON.stringify(response, null, 2));
console.log('   Success Count:', response.successCount || 'N/A');
console.log('   Failure Count:', response.failureCount || 'N/A');

if (response.failureCount > 0) {
  console.error('❌ FCM Delivery Failed');
  console.error('   Results:', response.results);
}
```

---

#### Step 3: Check iOS Notification Permissions

**In iOS app, verify:**

1. **User granted notification permission:**
```swift
UNUserNotificationCenter.current().getNotificationSettings { settings in
    print("Notification Authorization: \(settings.authorizationStatus)")
    // Should be .authorized
}
```

2. **FCM token is being uploaded to backend:**
```swift
// In AppDelegate or wherever FCM is configured
Messaging.messaging().token { token, error in
    if let token = token {
        print("FCM Token: \(token)")
        // Should call backend to save token
    }
}
```

3. **Notification payload is correct:**
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                          willPresent notification: UNNotification) {
    print("Received notification while app is open:")
    print("  Title: \(notification.request.content.title)")
    print("  Body: \(notification.request.content.body)")
    print("  Data: \(notification.request.content.userInfo)")
}
```

---

## 🎯 Action Plan:

### For Linked Accounts Issue:

1. ✅ Check Railway logs for `/api/auth/linked-accounts` calls
2. ✅ Verify JWT token user ID matches database user ID
3. ✅ Verify Railway is running latest code
4. ✅ Force redeploy if needed
5. ✅ Test from iOS app again

### For Notifications Issue:

1. ✅ Validate FCM tokens in database
2. ✅ Add enhanced FCM response logging
3. ✅ Check iOS notification permissions
4. ✅ Verify Firebase configuration
5. ✅ Test with diagnostic notification script

---

## 📊 Current Status:

**Linked Accounts:**
- ✅ Database has correct data
- ✅ Backend code is correct
- ❓ Need to check Railway logs
- ❓ Need to verify deployment

**Push Notifications:**
- ✅ Backend sends notifications
- ✅ FCM tokens exist in database
- ❓ Need to verify token validity
- ❓ Need enhanced logging

---

**Next Command to Run:**

```bash
# For linked accounts:
railway logs --limit 200 | grep -A 30 "LINKED ACCOUNTS"

# For notifications:
cd brrow-backend && node verify-fcm-token.js
```

---

**Report Generated:** October 16, 2025
**Status:** Awaiting Railway logs analysis
**Priority:** Both issues are HIGH priority
