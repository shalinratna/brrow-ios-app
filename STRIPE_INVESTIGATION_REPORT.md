# Comprehensive Stripe Payment Capture & Seller Payout Investigation

## Executive Summary
The Brrow platform has implemented a sophisticated Stripe Connect integration with automatic fund transfers to sellers when they have completed onboarding. Payments are held (authorized but not captured) until verification, then automatically captured and transferred when conditions are met.

---

## 1. BACKEND PAYMENT FLOW

### Payment Intent Creation (Create → Hold → Capture → Transfer)

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/routes/payments.js`

#### Step 1: Payment Intent Creation (Lines 253-603)
```
POST /api/payments/create-payment-intent
```

**Key Details (Lines 488-524):**
- Creates PaymentIntent with `capture_method: 'manual'` (Line 491)
  - This HOLDS funds without capturing
  - Funds remain in buyer's account for up to 7 days
  
- **Immediate Seller Transfer (Lines 507-513):**
  - If seller has complete Stripe Connect account:
    ```javascript
    application_fee_amount: applicationFeeAmount  // 5% platform fee
    transfer_data: {
      destination: listing.users.stripe_account_id  // Seller's Connect account
    }
    ```
  - If seller NOT fully enabled: Platform holds funds until seller completes onboarding

- **Metadata stored includes:** `sellerId`, `buyerId`, `listingId`, `transactionType`

#### Step 2: Payment Capture (Webhook Handler)

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/routes/payments.js` (Lines 1243-1278)

**Event:** `payment_intent.succeeded`
```javascript
case 'payment_intent.succeeded':
  const paymentIntent = event.data.object;
  // Only processes if payment was fully captured (not just authorized)
  if (paymentIntent.status === 'succeeded') {
    // Update transaction to CONFIRMED
    // Transfer funds execute automatically via Stripe Connect
  }
```

**Status Updates (Line 1257-1264):**
- Updates transaction status to `CONFIRMED`
- Records `confirmed_at` timestamp
- Stores `stripe_charge_id` for reference

#### Step 3: Authorization Hold (No Capture Yet)

**Event:** `payment_intent.amount_capturable_updated` (Lines 1280-1378)

This event fires when payment is AUTHORIZED but NOT YET CAPTURED:
```javascript
case 'payment_intent.amount_capturable_updated':
  // Payment authorized - funds held for 3 days
  // Status: 'PENDING'
  // Seller receives notification: "New Offer"
  // Funds NOT yet transferred to seller
```

---

## 2. SELLER STRIPE ACCOUNT CONNECTION FLOW

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/routes/stripe.js`

### A. Onboarding (Lines 24-147)

```
POST /api/stripe/connect/onboard
```

**Process:**
1. Create Express Account if doesn't exist (Lines 78-91)
   ```javascript
   const account = await stripe.accounts.create({
     type: 'express',
     email: user.email,
     capabilities: {
       card_payments: { requested: true },
       transfers: { requested: true }
     }
   });
   ```

2. Save `stripe_account_id` to database (Line 100)
3. Generate onboarding link (Lines 116-121)
   - Return URL directs to `/settings/linked-accounts?success=true`

**Database Storage:**
- `users.stripe_account_id` - Seller's Stripe Connect account ID
- `users.stripe_account_status` - Status: 'pending' or 'active'

### B. Status Check (Lines 153-265)

```
GET /api/stripe/connect/status
```

Returns:
- `connected` - Has Stripe account
- `chargesEnabled` - Can receive charges
- `payoutsEnabled` - Can receive bank transfers
- `detailsSubmitted` - Completed onboarding
- `canReceivePayments` - chargesEnabled AND payoutsEnabled

**Key Update Logic (Lines 220-232):**
```javascript
if (account.charges_enabled !== user.can_receive_payments) {
  // Update local database when Stripe status changes
  await prisma.users.update({
    data: {
      can_receive_payments: account.charges_enabled,
      stripe_account_status: account.details_submitted ? 'active' : 'pending'
    }
  });
}
```

### C. Balance Retrieval (Lines 336-403)

```
GET /api/stripe/connect/balance
```

Returns:
- `available` - Ready to payout
- `pending` - Processing (usually 24-48 hours)
- Formatted with totals in dollars

### D. Payout History (Lines 409-480)

```
GET /api/stripe/connect/payouts
```

Lists payouts with:
- Amount, status, type (instant/standard)
- Arrival date, failure reasons
- Automatic vs manual flag

### E. Manual Payout Trigger (Lines 572-663)

```
POST /api/stripe/connect/payout/manual
```

Allows seller to request immediate payout if funds available:
- Standard: 2-5 business days
- Instant: 30 minutes (with fee)

---

## 3. AUTOMATIC TRANSFER MECHANISM

### When Does Money Go to Seller's Connect Account?

**Critical Finding:** Transfers happen IMMEDIATELY when payment is captured.

**Mechanism (Payment Hold Service):**

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/services/payment-hold.service.js`

**Payment Intent Creation (Lines 162-190):**
```javascript
const paymentIntent = await this.stripe.paymentIntents.create({
  amount: fees.amount,
  currency: 'usd',
  customer: stripeCustomerId,
  capture_method: 'manual',  // HOLD funds
  application_fee_amount: fees.platformFee,  // 5% to Brrow
  transfer_data: {
    destination: seller.stripe_account_id  // Destination set immediately!
  },
  // ... metadata
});
```

**Key Point:** `transfer_data.destination` is set on the PaymentIntent itself
- When payment is captured, Stripe automatically transfers the net amount to seller

**Capture Process (Lines 262-325):**
```javascript
async capturePayment(paymentIntentId) {
  const paymentIntent = await this.stripe.paymentIntents.capture(paymentIntentId);
  
  if (paymentIntent.status === 'succeeded') {
    // Transaction confirmed in database
    // Stripe automatically transfers funds to seller's Connect account
    // Platform fee (5%) stays with Brrow
  }
}
```

**Timeline:**
1. Payment created: `PENDING` (held)
2. Verification complete: `CONFIRMED` (captured)
3. Stripe processes: Transfers to seller within minutes
4. Seller account: Shows as `pending` (24-48 hours for bank)
5. Bank account: Receives funds (2-5 business days standard)

---

## 4. EARNINGS & BALANCE DISPLAY

### A. iOS EarningsView

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/Brrow/Views/EarningsView.swift`

**Displays:**
- `totalEarnings` - Lifetime earnings
- `availableBalance` - Ready to payout
- `monthlyEarnings` - This month's earnings
- `itemsRented` - Number of rentals
- `avgDailyEarnings` - Average per day
- `recentPayouts` - History of payouts
- `chartData` - 30-day earnings trend

**Data Flow:**
```swift
func loadEarningsData() {
  async let earningsTask = fetchEarningsOverview()
  async let payoutsTask = fetchRecentPayouts()
  // Calls backend endpoints
}
```

### B. Backend Earnings Endpoints

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/routes/earnings.js`

#### GET /api/earnings/overview (Lines 8-53)
**Problem:** This is HARDCODED mock data!
```javascript
const totalEarnings = listings.reduce((sum, listing) => sum + listing.price, 0);
const pendingEarnings = totalEarnings * 0.1;  // 10% arbitrary
const availableEarnings = totalEarnings * 0.9; // 90% arbitrary

// Returns static structure with NO real Stripe data
```

#### GET /api/earnings/payouts (Lines 84-120)
**Problem:** HARDCODED example payouts
```javascript
const payouts = [
  {
    id: '1',
    amount: 250.00,
    method: 'bank_transfer',
    status: 'Completed',  // FAKE
    date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
  }
];
```

---

## 5. PAYMENT METADATA & TRACKING

### What Stripe Knows About Seller

**Stored in PaymentIntent Metadata:**
```javascript
metadata: {
  listingId,
  sellerId: listing.user_id,
  buyerId,
  transactionType,
  platformName: 'Brrow',
  buyerStripeCustomerId: stripeCustomerId,
  // Platform fee tracked separately
}
```

**Transfer Destination:**
```javascript
transfer_data: {
  destination: seller.stripe_account_id  // Explicit seller account ID
}
```

**Key Tracking:**
- Seller ID is in metadata
- Transfer destination is set before capture
- Stripe automatically knows to pay this Connect account when charge succeeds

---

## 6. CURRENT IMPLEMENTATION STATUS

### What Works
1. ✅ Seller Stripe Connect onboarding
2. ✅ Account status checking
3. ✅ Payment authorization holds
4. ✅ Automatic transfers to seller when payment captured
5. ✅ Payout listing from seller's Connect account
6. ✅ Manual payout requests
7. ✅ Webhook handling for payout events (payout.created, payout.paid, payout.failed)
8. ✅ Seller notifications when payouts processed

### What's Missing / Broken

#### CRITICAL GAP #1: Earnings Endpoint Returns Fake Data
- `/api/earnings/overview` - Uses listing prices, NOT actual transaction data
- `/api/earnings/payouts` - Hardcoded example data
- **Impact:** iOS app shows fabricated earnings, not real Stripe data
- **Fix needed:** Query `transactions` or Stripe Connect balance API

#### CRITICAL GAP #2: No Real-Time Balance in App
- EarningsView shows `availableBalance` but gets fake data
- Should call `GET /api/stripe/connect/balance` for actual amounts
- Currently EarningsViewModel calculates fictitious pending/available split

#### CRITICAL GAP #3: Capture Flow Unclear
- `/api/payments/confirm-payment` exists (Line 903) to manually capture
- But unclear when/how this is triggered in practice
- Payment hold service has `capturePayment()` method but unclear when called
- User flow: Does iOS app manually confirm, or auto-capture?

#### CRITICAL GAP #4: Only Works If Seller Onboarded
- If seller hasn't completed Stripe Connect setup
- Platform holds funds, but never auto-completes payment
- No escalation system for seller to finish onboarding
- Buyer funds stuck in limbo

---

## 7. STEP-BY-STEP CURRENT PAYMENT FLOW

### Complete Flow When Seller IS Onboarded:

1. **Buyer initiates purchase**
   - POST /api/payments/create-payment-intent
   - Creates PaymentIntent with manual capture
   - transfer_data set to seller's stripe_account_id
   
2. **Payment method added (iOS PaymentSheet)**
   - Client-side card entry
   - Creates Payment Intent client secret
   
3. **Payment authorized (not captured)**
   - `payment_intent.amount_capturable_updated` webhook fires
   - Transaction marked as PENDING
   - Seller notified: "New Offer"
   - Funds HELD for 3 days
   
4. **Verification complete / Offer accepted**
   - POST /api/payments/confirm-payment (or automatic?)
   - stripe.paymentIntents.capture(paymentIntentId)
   - payment_intent.succeeded webhook fires
   
5. **Automatic Transfer**
   - Stripe automatically transfers to seller's Connect account
   - Platform fee (5%) stays with Brrow
   - Seller receives notification
   
6. **Payout**
   - Seller's balance accrues in Stripe Connect
   - After 24-48 hours: marked "available"
   - Can request manual payout or wait for automatic (daily)

### If Seller NOT Onboarded:

1. Same flow, BUT
2. transfer_data is NOT included
3. Payment still captures
4. Funds stay in Brrow's account
5. No way to transfer to seller unless they complete onboarding
6. **GAP:** No system to trigger manual transfer later

---

## 8. STRIPE WEBHOOK HANDLERS

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/routes/payments.js`

### Payout Events (Lines 1815-1945)

**payout.created** (Lines 1815-1841)
- Notifies seller payout initiated
- Stores payout ID and amount

**payout.paid** (Lines 1843-1868)
- Notifies seller: "Funds successfully transferred to bank"
- Records completion timestamp

**payout.failed** (Lines 1870-1911)
- Critical notification to seller
- Logs failure reason (invalid bank, etc.)
- Requires user action (update bank details)

**account.updated** (Lines 1774-1811)
- Detects when seller completes onboarding
- Updates `can_receive_payments` flag
- Notifies seller: "Account now active!"

---

## 9. CRITICAL ISSUES & GAPS

### Issue #1: Earnings View Shows Fake Data
**Severity:** HIGH
**Location:** `/brrow-backend/routes/earnings.js`
**Problem:** 
- Calculates earnings from listing prices, not actual transactions
- Hardcodes 10% pending, 90% available
- Returns fake payout history

**Should Instead:**
- Query `transactions` table for real earnings
- Call Stripe Connect balance API
- Pull actual payout history from Stripe

### Issue #2: No Automatic Capture Trigger Visible
**Severity:** MEDIUM
**Problem:**
- Unclear how/when payment goes from PENDING → CONFIRMED
- `/api/payments/confirm-payment` requires manual call
- No automatic trigger visible in webhook handlers

**Should Investigate:**
- Does iOS app call confirm-payment?
- Is there a cron job triggering capture?
- What happens to expired holds (>3 days)?

### Issue #3: Seller Cannot Receive Funds Without Onboarding
**Severity:** HIGH
**Problem:**
- If seller doesn't complete Stripe Connect setup
- Payment is captured but stays in Brrow account
- No automatic transfer to seller later
- Buyer's money stuck in limbo

**Should Have:**
- System to retry transfer when seller completes onboarding
- Dashboard alert for seller: "Complete setup to receive $XXX"
- Ability to manually transfer funds after seller onboards

### Issue #4: EarningsViewModel Doesn't Use Real Stripe Data
**Severity:** HIGH
**Location:** `Brrow/ViewModels/EarningsViewModel.swift`
**Problem:**
- Calls `apiClient.fetchEarningsOverview()` which returns fake data
- Does NOT call `/api/stripe/connect/balance` for real balance
- Shows mock payouts and transactions

**Should:**
- If seller has Stripe Connected account:
  - Call `/api/stripe/connect/balance`
  - Call `/api/stripe/connect/payouts`
  - Show real data
- If not connected:
  - Show message: "Connect Stripe to receive earnings"

---

## 10. RECOMMENDED IMMEDIATE FIXES

### Fix #1: Real Earnings Endpoint (HIGH PRIORITY)
**File:** `brrow-backend/routes/earnings.js`

Replace `/earnings/overview` to:
1. Get seller's Stripe Connect balance (if exists)
2. Query transactions for real earnings
3. Return actual available/pending split

### Fix #2: Automatic Payment Capture
**Need to determine:**
- When exactly does payment go from PENDING → CONFIRMED?
- Add logging to track capture timing
- Ensure no holds expire without capture

### Fix #3: Seller Onboarding Escalation
Add new endpoint:
```
GET /api/stripe/connect/pending-transfers
```
Returns funds waiting for seller to complete onboarding
- Allow admin to see total stuck funds
- Notify sellers of pending amounts

### Fix #4: iOS Earnings View Update
Connect to real Stripe endpoints:
```swift
if user.hasStripeConnect {
  let balance = await apiClient.getStripeBalance()
  // Use real balance
} else {
  // Show: "Connect Stripe Account to earn"
}
```

---

## 11. VERIFICATION NOTES

All findings verified from:
1. Stripe.js route handlers - Full payment flow
2. Payment hold service - Transfer logic  
3. Webhook handlers - Event processing
4. iOS EarningsView - What sellers see
5. Earnings endpoint - Data returned

**Code review completed for:**
- Payment creation with transfer_data
- Webhook event handling
- Stripe Connect status
- Balance & payout retrieval
- iOS data models

---

## CONCLUSION

The Brrow platform HAS implemented automatic transfers to seller Stripe Connect accounts, but:

1. **Transfers work correctly** when seller is onboarded
2. **Earnings display is broken** - Shows fake data instead of real Stripe balance
3. **Unclear capture flow** - How/when payments move from PENDING to CONFIRMED
4. **Stuck funds problem** - If seller doesn't onboard, payment captured but not transferred

**Immediate action needed:** Fix earnings endpoints and iOS earnings view to show real Stripe data.

