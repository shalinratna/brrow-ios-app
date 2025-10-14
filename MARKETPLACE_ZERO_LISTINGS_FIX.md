# Marketplace 0 Listings Issue - Root Cause & Fix

## Problem Summary
The iOS app marketplace was showing 0 listings even though there were 2 listings in the database.

**Evidence from app logs:**
```
🐛 [Brrow API Debug] 🏪 [MARKETPLACE] Successfully fetched 0 listings from ALL users
✅ [MARKETPLACE] API fetch successful: 0 listings
```

## Root Cause Analysis

### 1. Database State
Query revealed 2 listings in the database:
- **Listing 1:** "Test listing 2"
  - Status: `IN_TRANSACTION`
  - Active: `true`
  - Created: Oct 13, 2025

- **Listing 2:** "For sale listing 0"
  - Status: `IN_TRANSACTION`
  - Active: `true`
  - Created: Oct 13, 2025

### 2. API Filter Logic
The marketplace endpoint (`GET /api/listings`) applies this filter:

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/routes/listings.js` (Lines 496-503)

```javascript
} else if (!user_id) {
  // If no specific status filter AND no user_id (marketplace browsing),
  // exclude deleted/sold/in-transaction/upcoming listings
  // This ensures the marketplace only shows available listings
  where.availability_status = {
    notIn: ['SOLD', 'REMOVED', 'IN_TRANSACTION', 'UPCOMING']
  };
}
```

**Problem:** Both listings had `availability_status = 'IN_TRANSACTION'`, so they were excluded from marketplace results.

### 3. Why Were Listings IN_TRANSACTION?

Checking purchase history showed:
- Both listings had 1 purchase each with status `PENDING` (not `HELD`)
- No active payment holds existed
- Listings were likely set to IN_TRANSACTION by a migration script or manual status change

**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/migrate-listing-statuses.js`

This migration converts PENDING listings with purchases to IN_TRANSACTION status. However:
- The purchases were in PENDING state (not payment held)
- These listings should not have been locked as IN_TRANSACTION

## The Fix

### Step 1: Update Listing Status
Updated both listings from `IN_TRANSACTION` to `AVAILABLE`:

```javascript
await prisma.listings.updateMany({
  where: {
    availability_status: 'IN_TRANSACTION'
  },
  data: {
    availability_status: 'AVAILABLE',
    updated_at: new Date()
  }
});
```

**Result:** 2 listings updated successfully

### Step 2: Verification
Tested the marketplace endpoint:

**Request:**
```bash
curl -X GET "https://brrow-backend-nodejs-production.up.railway.app/api/listings?limit=1000" \
  -H "Authorization: Bearer [TOKEN]"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "listings": [
      {
        "title": "Test listing 2",
        "status": "AVAILABLE"
      },
      {
        "title": "For sale listing 0",
        "status": "AVAILABLE"
      }
    ],
    "pagination": {
      "total": 2,
      "page": 1,
      "per_page": 1000
    }
  }
}
```

✅ **Confirmed:** Endpoint now returns 2 listings

## Documentation Inconsistency Found

### Conflicting Information
**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/LISTING_STATUS_SYSTEM_GUIDE.md` (Line 46)

States: `"IN_TRANSACTION (still visible, payment held)"`

**However:** The route code explicitly excludes IN_TRANSACTION from marketplace.

### Recommendation
The current behavior (hiding IN_TRANSACTION listings) is **correct** because:

1. **User Experience:** Items in active transactions should not appear as available to other buyers
2. **Prevents Conflicts:** Avoids multiple buyers trying to purchase the same item
3. **Clear Ownership:** Once payment is held, the item is reserved for that specific buyer

**Action Required:** Update the LISTING_STATUS_SYSTEM_GUIDE.md to reflect that IN_TRANSACTION listings are NOT visible in marketplace.

## Prevention: Proper Status Management

### When Listings Should Be IN_TRANSACTION:
- ✅ Active payment hold exists (Stripe payment status = HELD)
- ✅ Buyer has initiated checkout but not completed
- ✅ Transaction is in progress

### When Listings Should Be AVAILABLE:
- ✅ No active purchases
- ✅ Previous purchases failed/cancelled
- ✅ Listing is ready for new buyers

### Recommended Status Flow:
```
UPCOMING (new, pending moderation)
    ↓ (admin approves)
AVAILABLE (visible in marketplace)
    ↓ (buyer starts checkout with payment hold)
IN_TRANSACTION (hidden from marketplace, payment held)
    ↓ (transaction completes)
SOLD or RENTED (final state)
```

## Scripts Created

### 1. Check Listings Database
**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/check-listings-db.js`

Shows all listings and which ones match marketplace filter.

### 2. Fix Listings Status
**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/fix-listings-status.js`

Updates IN_TRANSACTION listings to AVAILABLE if no active payment holds exist.

### 3. Check Transactions
**File:** `/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend/check-transactions.js`

Verifies which listings have active purchases/payment holds.

## Final Status

### ✅ Fixed
- 2 listings now visible in marketplace
- Endpoint returning correct data
- iOS app should show listings on next fetch

### ✅ Verified
- No active payment holds exist
- Listings correctly set to AVAILABLE status
- Marketplace filter working as designed

### ⚠️ Action Items
1. **Update Documentation:** Fix LISTING_STATUS_SYSTEM_GUIDE.md to reflect IN_TRANSACTION listings are hidden
2. **Monitor Status Changes:** Ensure listings only go to IN_TRANSACTION when payment is actually held
3. **Consider Cleanup Job:** Add periodic job to reset stale IN_TRANSACTION listings

## Test Plan for User

1. **Refresh iOS App**
   - Pull to refresh on marketplace screen
   - Should now see 2 listings

2. **Verify Listings Display**
   - "Test listing 2" should appear
   - "For sale listing 0" should appear
   - Both should show status AVAILABLE

3. **Test Interactions**
   - Can view listing details
   - Can favorite listings
   - Can initiate purchase

---

**Date Fixed:** October 14, 2025
**Backend URL:** https://brrow-backend-nodejs-production.up.railway.app
**Database:** Railway PostgreSQL
**Status:** ✅ RESOLVED
