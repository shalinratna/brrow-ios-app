# 🔗 Stripe Webhook Setup - 3 Minutes

## What You Need to Do

You mentioned: "also i have not done anything for stripe yet let me know"

Here's the **exact 3-step process** to complete Stripe integration:

---

## Step 1: Create Stripe Webhook (2 minutes)

1. Go to: https://dashboard.stripe.com/webhooks
2. Click **"Add endpoint"**
3. Enter this URL:
   ```
   https://brrow-backend-nodejs-production.up.railway.app/api/payments/webhook
   ```
4. Click **"Select events"** and add these 3 events:
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
   - ✅ `account.updated`
5. Click **"Add endpoint"**
6. **COPY the webhook secret** (starts with `whsec_...`)

---

## Step 2: Add Webhook Secret to Railway (1 minute)

1. Go to Railway project: https://railway.app
2. Click on your **brrow-backend** service
3. Go to **Variables** tab
4. Add new variable:
   ```
   STRIPE_WEBHOOK_SECRET = whsec_xxxxxxxxxxxxx
   ```
   (paste the secret you copied from Step 1)
5. Click **Save** - Railway will auto-redeploy

---

## Step 3: Test Payment Flow (Optional but Recommended)

After Railway finishes deploying:

1. Open Brrow iOS app
2. Find any listing
3. Click **"Buy Now"** or **"Rent"**
4. Use Stripe test card:
   ```
   Card Number: 4242 4242 4242 4242
   Expiry: Any future date (e.g., 12/25)
   CVC: Any 3 digits (e.g., 123)
   ZIP: Any 5 digits (e.g., 12345)
   ```
5. Complete payment
6. Check that:
   - ✅ Transaction appears in app
   - ✅ Money shows in Stripe dashboard
   - ✅ 5% commission was deducted
   - ✅ Email confirmation was sent

---

## ✅ What's Already Done

- ✅ Stripe Connect integration (5% commission)
- ✅ Payment intents with escrow
- ✅ Seller payout system
- ✅ $120 Brrow Protection
- ✅ Backend webhook endpoint `/api/payments/webhook`
- ✅ Transaction status updates
- ✅ Email notifications on payment

---

## 🔐 Your Stripe Credentials (from earlier)

You should already have these in Railway:
- `STRIPE_SECRET_KEY` (your secret key)
- `STRIPE_PUBLISHABLE_KEY` (your publishable key)

If not, get them from: https://dashboard.stripe.com/apikeys

---

## 🚀 That's It!

Once you add the webhook secret, **everything else is already built and deployed**.

The webhook allows Stripe to notify your backend when payments succeed/fail, which:
- Updates transaction status in database
- Sends confirmation emails
- Triggers payout to seller
- Updates listing availability

---

## 📊 Test Mode vs Live Mode

Right now you're in **Stripe Test Mode** (good for testing).

When ready to go live:
1. Switch Stripe dashboard to **Live mode**
2. Get **live API keys** from: https://dashboard.stripe.com/apikeys
3. Replace Railway env vars with live keys
4. Create a **new webhook** for live mode (same URL, same events)

---

## ❓ Questions?

**Q: What if webhook secret is wrong?**
A: Payments will process but status won't update automatically. Check Railway logs for errors.

**Q: Do I need to verify my Stripe account?**
A: For testing, no. For live payments, Stripe requires business verification.

**Q: Can I test without webhook?**
A: Yes, but transaction status won't auto-update. You'd need to manually mark transactions complete.

---

**Next Step**: Go to https://dashboard.stripe.com/webhooks and add the endpoint!
