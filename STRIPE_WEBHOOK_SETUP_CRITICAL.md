# ⚠️ CRITICAL: Stripe Webhook Setup Required

**Status**: ❌ NOT CONFIGURED
**Impact**: 🔴 HIGH - Purchases stuck in PENDING status
**Priority**: 🚨 URGENT - Must be done before production use

---

## 🔍 What's The Problem?

**Current Situation**:
- Users complete payment successfully on Stripe ✅
- Payment is charged and held in escrow ✅
- **Purchase record NEVER gets updated to HELD status** ❌
- Listing correctly shows as IN_TRANSACTION ✅
- But purchase stays PENDING forever ❌

**Why This Happens**:
The backend expects Stripe to send a webhook notification when checkout completes, but the webhook is not configured in Stripe Dashboard.

---

## 📊 Verified Purchase Status Issue

**Database Analysis** (Oct 9, 2025):
```
Most Recent Purchases:

Purchase 1:
  ID: fe288db9-52d3-412e-b6a3-7ec6f501db26
  Listing: "mom listing 6 sale"
  Amount: $22
  Payment Status: PENDING ⚠️
  Payment Intent: None ⚠️
  Created: Thu Oct 09 2025 22:11:05 GMT-0700

Purchase 2:
  ID: de7a5d92-4ef4-47b4-8f63-6e447dd8544c
  Listing: "mom listing 6 sale"
  Amount: $23
  Payment Status: PENDING ⚠️
  Payment Intent: None ⚠️
  Created: Thu Oct 09 2025 22:01:11 GMT-0700
```

**Expected After Webhook Setup**:
```
Payment Status: HELD ✅
Payment Intent: pi_abc123... ✅
```

---

## ✅ How To Fix (5 Minutes)

### Step 1: Login to Stripe Dashboard

1. Go to https://dashboard.stripe.com
2. Login with your Stripe account
3. Make sure you're in **LIVE** mode (toggle in top left)

### Step 2: Create Webhook Endpoint

1. Click **Developers** in left sidebar
2. Click **Webhooks**
3. Click **Add endpoint** button

### Step 3: Configure Webhook

**Endpoint URL**:
```
https://brrow-backend-nodejs-production.up.railway.app/api/stripe/webhook
```

**Events to listen for** (select these 4):
- ✅ `checkout.session.completed` ← **Most important!**
- ✅ `checkout.session.expired`
- ✅ `payment_intent.succeeded`
- ✅ `payment_intent.payment_failed`

**API Version**: Latest (2024-10-28.acacia or newer)

### Step 4: Get Signing Secret

After creating the webhook, Stripe will show you a **Signing secret** that looks like:
```
whsec_abc123def456ghi789...
```

**Copy this!** You'll need it in the next step.

### Step 5: Update Railway Environment Variable

1. Go to https://railway.app
2. Open your `brrow-backend-nodejs-production` project
3. Click **Variables** tab
4. Find `STRIPE_WEBHOOK_SECRET` (or add it if missing)
5. **Paste the signing secret** from Step 4
6. Click **Save**
7. Click **Deploy** to restart with new environment variable

---

## 🧪 How To Test After Setup

### Test 1: Buy Something

1. Open Brrow iOS app
2. Find a listing and click **Buy Now**
3. Complete Stripe Checkout
4. Check the logs:

**Expected Logs** (after fix):
```
✅ [WEBHOOK] Purchase checkout completed: fe288db9-52d3-412e-b6a3-7ec6f501db26
✅ [WEBHOOK] Payment intent: pi_abc123...
✅ [WEBHOOK] Purchase fe288db9-52d3-412e-b6a3-7ec6f501db26 updated to HELD status
```

### Test 2: Check Database

Run this query:
```bash
node check-recent-purchase.js
```

**Expected Output** (after fix):
```
Purchase 1:
  Payment Status: HELD ✅
  Payment Intent: pi_abc123... ✅
  Listing Status: IN_TRANSACTION ✅
```

### Test 3: Test in Stripe Dashboard

1. Go to Stripe Dashboard → Developers → Webhooks
2. Click on your webhook endpoint
3. Click **Send test webhook**
4. Select `checkout.session.completed`
5. Check if webhook succeeds (no errors)

---

## 🔧 What The Webhook Handler Does

**Backend Code** (`prisma-server.js:7760-7794`):

```javascript
case 'checkout.session.completed':
  const session = event.data.object;

  if (session.mode === 'payment' && session.metadata?.purchase_id) {
    const purchaseId = session.metadata.purchase_id;
    const paymentIntentId = session.payment_intent;

    console.log(`✅ [WEBHOOK] Purchase checkout completed: ${purchaseId}`);
    console.log(`✅ [WEBHOOK] Payment intent: ${paymentIntentId}`);

    // Update purchase record to HELD status
    await prisma.purchases.update({
      where: { id: purchaseId },
      data: {
        payment_status: 'HELD',
        payment_intent_id: paymentIntentId
      }
    });

    console.log(`✅ [WEBHOOK] Purchase ${purchaseId} updated to HELD status`);
  }
  break;
```

---

## ⚠️ Security Notes

1. **Never skip signature verification** - The webhook handler verifies Stripe's signature using `STRIPE_WEBHOOK_SECRET`
2. **Use HTTPS only** - Railway provides this automatically
3. **Test mode vs Live mode** - Create webhooks in BOTH if you want to test in Stripe test mode

---

## 📋 Expected Flow After Fix

### Current (Broken) Flow:
```
1. User clicks Buy Now
   → Purchase created with PENDING status

2. User completes Stripe Checkout
   → ❌ Webhook not configured
   → ❌ Purchase NEVER updated

3. Purchase stuck in PENDING forever
```

### Fixed Flow:
```
1. User clicks Buy Now
   → Purchase created with PENDING status

2. User completes Stripe Checkout
   → ✅ Stripe sends webhook to backend
   → ✅ Backend updates purchase to HELD

3. Both parties verify within 3 days
   → Payment captured
   → Purchase completed
```

---

## 🚀 After You Fix This

Once the webhook is configured, you'll see:

✅ Purchases update to HELD status immediately after payment
✅ Payment intent IDs stored correctly
✅ Receipt view shows accurate escrow status
✅ 3-day countdown timer starts
✅ Confetti celebration triggers properly
✅ Sellers can see confirmed purchases
✅ Buyers can track verification deadline

---

## 💡 Troubleshooting

### Webhook returning 401 Unauthorized
- **Fix**: Make sure Railway has the correct `STRIPE_WEBHOOK_SECRET` environment variable

### Webhook returning 400 Bad Request
- **Fix**: Check Stripe Dashboard → Webhooks → Your endpoint → Recent deliveries for error details

### Purchases still showing PENDING
- **Check 1**: Is webhook endpoint active? (should show green checkmark in Stripe Dashboard)
- **Check 2**: Did you redeploy Railway after adding the secret?
- **Check 3**: Are you in Live mode (not Test mode)?

---

## 📞 Quick Reference

**Webhook Endpoint**:
```
https://brrow-backend-nodejs-production.up.railway.app/api/stripe/webhook
```

**Required Events**:
- `checkout.session.completed`
- `checkout.session.expired`
- `payment_intent.succeeded`
- `payment_intent.payment_failed`

**Environment Variable**:
```
STRIPE_WEBHOOK_SECRET=whsec_your_secret_here
```

---

**Last Updated**: October 9, 2025
**Status**: Waiting for webhook configuration
**Estimated Time**: 5 minutes
**Impact**: Critical for production use
