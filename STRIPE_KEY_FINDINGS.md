# STRIPE PAYMENT & PAYOUT SYSTEM - KEY FINDINGS

## QUICK REFERENCE: Code Locations & Line Numbers

### 1. PAYMENT FLOW

| Component | File | Lines | What It Does |
|-----------|------|-------|--------------|
| Create PaymentIntent | `routes/payments.js` | 253-603 | Creates hold with manual capture |
| Set Transfer Destination | `routes/payments.js` | 507-513 | Adds seller's Stripe Connect account |
| Payment Succeeded Webhook | `routes/payments.js` | 1243-1278 | Confirms payment, executes transfer |
| Authorization Hold Event | `routes/payments.js` | 1280-1378 | Notifies seller of new offer |
| Confirm & Capture Payment | `routes/payments.js` | 903-1023 | Manual capture endpoint |

### 2. SELLER STRIPE CONNECT

| Component | File | Lines | What It Does |
|-----------|------|-------|--------------|
| Onboard Seller | `routes/stripe.js` | 24-147 | Creates Express account + link |
| Check Status | `routes/stripe.js` | 153-265 | Returns canReceivePayments flag |
| Get Balance | `routes/stripe.js` | 336-403 | Returns available + pending funds |
| List Payouts | `routes/stripe.js` | 409-480 | History of payouts to bank |
| Manual Payout | `routes/stripe.js` | 572-663 | Seller requests payout |

### 3. TRANSFER MECHANISM

| Component | File | Lines | Key Code |
|-----------|------|-------|----------|
| Payment Hold Service | `services/payment-hold.service.js` | 162-190 | `transfer_data: { destination: seller.stripe_account_id }` |
| Capture Payment | `services/payment-hold.service.js` | 262-325 | `stripe.paymentIntents.capture()` → auto transfer |

### 4. WEBHOOK HANDLERS (All in routes/payments.js)

| Event | Lines | Action |
|-------|-------|--------|
| `payment_intent.succeeded` | 1243-1278 | Transaction CONFIRMED, transfer executes |
| `payment_intent.amount_capturable_updated` | 1280-1378 | Transaction PENDING, seller notified |
| `payout.created` | 1815-1841 | Payout initiated notification |
| `payout.paid` | 1843-1868 | Funds arrived at bank notification |
| `payout.failed` | 1870-1911 | Bank rejection notification |
| `account.updated` | 1774-1811 | Seller completed onboarding |

### 5. EARNINGS DISPLAY (THE PROBLEM)

| Component | File | Lines | Issue |
|-----------|------|-------|-------|
| Overview Endpoint | `routes/earnings.js` | 8-53 | **HARDCODED FAKE DATA** |
| Payouts Endpoint | `routes/earnings.js` | 84-120 | **HARDCODED EXAMPLE PAYOUTS** |
| iOS ViewModel | `EarningsViewModel.swift` | 38-79 | Uses fake endpoints, not real Stripe balance |
| iOS View | `EarningsView.swift` | 77-118 | Displays fake data to seller |

---

## THE CRITICAL TRANSFER FLOW

### When Seller IS Onboarded ✅

```
1. Buyer creates payment intent
   → POST /api/payments/create-payment-intent
   → Lines 507-513: transfer_data.destination = seller.stripe_account_id

2. Payment authorized (held)
   → Webhook: payment_intent.amount_capturable_updated (Line 1285)
   → Transaction status = PENDING
   → Funds held for 3 days

3. Seller accepts / Verification complete
   → POST /api/payments/confirm-payment (Line 903)
   → stripe.paymentIntents.capture(paymentIntentId) (Line 963)

4. AUTOMATIC TRANSFER ✅
   → Webhook: payment_intent.succeeded (Line 1244)
   → Stripe automatically transfers to seller (because transfer_data was set)
   → Platform fee (5%) stays with Brrow
   → Seller sees funds in Connect account

5. Payout to Bank
   → Webhook: payout.created (Line 1815)
   → 24-48 hours later
   → Webhook: payout.paid (Line 1843)
```

### When Seller NOT Onboarded ❌

```
1-3. Same as above

4. TRANSFER DOESN'T HAPPEN ❌
   → transfer_data NOT included (seller not onboarded)
   → Payment captured but funds stay in Brrow account
   → Seller receives NOTHING
   → Buyer's money stuck
```

---

## WHAT STRIPE KNOWS

### PaymentIntent Metadata (Set Before Capture)
```javascript
metadata: {
  listingId,
  sellerId,              // Seller's database ID
  buyerId,
  transactionType,
  buyerStripeCustomerId
}
```

### Transfer Data (CRITICAL)
```javascript
transfer_data: {
  destination: seller.stripe_account_id  // Seller's Connect account
}
// ↑ This is what tells Stripe to send money to seller
// Set BEFORE payment is captured
```

---

## THE EARNINGS PROBLEM

### What iOS Shows
```
EarningsView displays:
- totalEarnings: $5000
- availableBalance: $4500
- monthlyEarnings: $500
- recentPayouts: [Payout($250, Completed), Payout($175, Completed)]
```

### Where It Comes From (FAKE)
```javascript
// routes/earnings.js Line 18-20
const totalEarnings = listings.reduce((sum, listing) => sum + listing.price, 0);
const pendingEarnings = totalEarnings * 0.1;      // Arbitrary 10%
const availableEarnings = totalEarnings * 0.9;    // Arbitrary 90%

// routes/earnings.js Line 87-102
const payouts = [
  { id: '1', amount: 250.00, status: 'Completed' },  // FAKE
  { id: '2', amount: 175.50, status: 'Completed' }   // FAKE
];
```

### What It SHOULD Show
```javascript
// Get from Stripe Connect API
const balance = await stripe.balance.retrieve({
  stripeAccount: user.stripe_account_id
});

// balance.available[0].amount = real available funds
// balance.pending[0].amount = real pending funds

// OR get from payouts API
const payouts = await stripe.payouts.list({
  stripeAccount: user.stripe_account_id
});
// payouts.data = actual payout history
```

---

## CRITICAL GAPS

### Gap #1: Earnings Endpoint Returns Fake Data
**Line:** `routes/earnings.js` lines 8-53, 84-120
**Impact:** Sellers see fabricated earnings
**Fix:** Query transactions table OR call Stripe Connect balance API

### Gap #2: Capture Trigger Unclear
**Location:** Lines 903-1023 (confirm-payment endpoint)
**Question:** When does iOS app call this? Auto-capture or manual?
**Fix:** Add logging to track capture timing

### Gap #3: Seller Cannot Receive If Not Onboarded
**Location:** Lines 507-513 (transfer_data conditional)
**Problem:** If seller hasn't onboarded, transfer_data not included
**Impact:** Captured funds stay in Brrow account
**Fix:** Add system to retry transfer when seller completes onboarding

### Gap #4: iOS Uses Fake Earnings Data
**Location:** `EarningsViewModel.swift` lines 38-79
**Problem:** Calls fake `/earnings/overview` endpoint
**Fix:** Call real `/stripe/connect/balance` and `/stripe/connect/payouts`

---

## PAYMENT FLOW TIMELINE

```
T=0:  Buyer initiates → PaymentIntent created
      transfer_data.destination set to seller.stripe_account_id
      
T=1:  Webhook: payment_intent.amount_capturable_updated (Line 1285)
      Transaction: PENDING
      Seller notified: "New Offer"
      Buyer: Funds authorized (held on card)
      
T=2:  Seller accepts OR Verification complete
      POST /api/payments/confirm-payment called
      stripe.paymentIntents.capture(intentId) (Line 963)
      
T=3:  Webhook: payment_intent.succeeded (Line 1244)
      Transaction: CONFIRMED
      Stripe automatically transfers to seller's Connect account
      Platform fee goes to Brrow
      Seller notified: Payout coming
      
T=4:  Stripe marks funds as pending in seller's account
      (24-48 hours)
      
T=5:  Webhook: payout.created (Line 1815)
      Seller notified: Payout initiated
      
T=6:  2-5 business days
      Webhook: payout.paid (Line 1843)
      Funds in seller's bank account
      Seller notified: Complete!
```

---

## WHAT NEEDS TESTING

1. **Does iOS call confirm-payment?**
   - Search app for "confirm-payment"
   - Add logging to endpoint

2. **What happens to expired holds?**
   - After 3 days, payment still PENDING?
   - Is there an auto-release?

3. **Manual transfer when seller onboards later?**
   - If seller didn't onboard initially
   - Does system transfer funds when they complete setup?
   - Answer: Probably NOT (gap!)

4. **Real earnings data**
   - Does `/earnings/overview` ever return real data?
   - Or always mock data?

---

## ACTION ITEMS

### IMMEDIATE (Critical)
- [ ] Fix `/earnings/overview` to use real Stripe data
- [ ] Fix `/earnings/payouts` to return actual payouts
- [ ] Update iOS to call real endpoints

### SHORT TERM (Important)
- [ ] Clarify capture flow - add logging
- [ ] Handle seller onboarding after payment captured
- [ ] Test full flow end-to-end

### MEDIUM TERM (Nice to have)
- [ ] Add admin dashboard for pending transfers
- [ ] Add automatic retry for failed payouts
- [ ] Improve seller notifications

---

## CODE SNIPPETS FOR QUICK REFERENCE

### Current Payment Creation
```javascript
// routes/payments.js, Line 507-512
if (sellerHasStripeAccount && sellerCanReceive) {
  paymentIntentData.application_fee_amount = applicationFeeAmount;
  paymentIntentData.transfer_data = {
    destination: listing.users.stripe_account_id
  };
}
```

### Current Capture
```javascript
// routes/payments.js, Line 963
const paymentIntent = await stripe.paymentIntents.capture(
  transaction.stripe_payment_intent_id
);
```

### Current Earnings (FAKE)
```javascript
// routes/earnings.js, Line 18-20
const totalEarnings = listings.reduce((sum, listing) => sum + listing.price, 0);
const pendingEarnings = totalEarnings * 0.1;
const availableEarnings = totalEarnings * 0.9;
```

### Real Balance (Should Use)
```javascript
// routes/stripe.js, Line 363-365
const balance = await stripe.balance.retrieve({
  stripeAccount: user.stripe_account_id
});
```

