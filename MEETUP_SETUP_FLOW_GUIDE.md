# Meetup Setup Flow Guide - Frontend Implementation

## Overview

This document explains how the Brrow iOS app handles meetup coordination between buyers and sellers after a purchase is created.

## Purchase Flow and Meetup Coordination

### 1. Purchase Creation

**When a buyer purchases an item:**

```
Buyer → Listing Detail → Purchase Button → Create Purchase
↓
Backend creates purchase with status: "HELD" (payment held in escrow)
↓
Purchase object includes: buyerId, sellerId, listingId, amount, deadline
↓
iOS receives purchase confirmation
```

### 2. Current Meetup Implementation

**Backend Support** (`routes/purchases.js`):
- `POST /api/purchases/:purchaseId/meetup` - Create meetup
- `PUT /api/purchases/:purchaseId/meetup` - Update meetup location/time
- `GET /api/purchases/:purchaseId/meetup` - Get meetup details

**Database Schema** (`prisma/schema.prisma`):
```prisma
model meetups {
  id                String   @id @default(cuid())
  purchase_id       String   @unique
  location          String
  scheduled_time    DateTime
  created_at        DateTime @default(now())
  updated_at        DateTime @updatedAt

  // Relations
  purchases         purchases @relation(fields: [purchase_id], references: [id])
}
```

### 3. Frontend Meetup Setup Flow

#### Option A: Seller Initiates Meetup (Recommended)

1. **Seller receives notification:**
   ```
   "New Purchase Request"
   "{buyer_username} purchased "{listing_title}" for ${amount}"
   ```

2. **Seller opens transaction detail:**
   - Taps notification → opens `TransactionDetailView`
   - Sees purchase details and buyer info
   - Status shows "Payment Held - Awaiting Meetup"

3. **Seller proposes meetup:**
   - Taps "Propose Meetup" button
   - Opens `MeetupProposalView` (needs to be created)
   - Selects location (map picker or text entry)
   - Selects date/time
   - Taps "Send Proposal"

4. **iOS calls backend:**
   ```swift
   POST /api/purchases/{purchaseId}/meetup
   Body: {
     "location": "123 Main St, San Francisco, CA",
     "scheduled_time": "2025-10-15T14:00:00Z"
   }
   ```

5. **Buyer receives notification:**
   ```
   "Meetup Proposed"
   "{seller_username} proposed a meetup for "{listing_title}""
   ```

6. **Buyer reviews and accepts:**
   - Opens transaction detail
   - Sees proposed location and time
   - Taps "Accept Meetup" or "Suggest Different Time"

#### Option B: Built-in Chat Coordination

1. **After purchase created:**
   - iOS automatically creates/opens a listing chat
   - Buyer and seller coordinate via messages
   - Either party can propose meetup using same flow as Option A

### 4. What iOS Needs to Implement

#### A. **MeetupProposalView** (New Screen)

**Location:** `/Users/shalin/Documents/Projects/Xcode/Brrow/Brrow/Views/MeetupProposalView.swift`

**UI Components:**
```swift
struct MeetupProposalView: View {
    let purchaseId: String
    @State private var location: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showMapPicker = false

    var body: some View {
        VStack {
            // Location picker
            TextField("Meetup location", text: $location)
            Button("Pick on Map") { showMapPicker = true }

            // Date/time picker
            DatePicker("Meetup time", selection: $selectedDate)

            // Send button
            Button("Propose Meetup") {
                createMeetup()
            }
        }
    }

    func createMeetup() {
        // Call APIClient to create meetup
    }
}
```

#### B. **APIClient Meetup Methods** (Add to APIClient.swift)

```swift
// In APIClient.swift

func createMeetup(purchaseId: String, location: String, scheduledTime: Date) async throws -> Meetup {
    struct MeetupRequest: Codable {
        let location: String
        let scheduledTime: String

        enum CodingKeys: String, CodingKey {
            case location
            case scheduledTime = "scheduled_time"
        }
    }

    let request = MeetupRequest(
        location: location,
        scheduledTime: ISO8601DateFormatter().string(from: scheduledTime)
    )

    let bodyData = try JSONEncoder().encode(request)

    let response = try await performRequest(
        endpoint: "api/purchases/\(purchaseId)/meetup",
        method: .POST,
        body: bodyData,
        responseType: APIResponse<Meetup>.self
    )

    guard response.success, let meetup = response.data else {
        throw BrrowAPIError.serverError(response.message ?? "Failed to create meetup")
    }

    return meetup
}

func getMeetup(purchaseId: String) async throws -> Meetup? {
    let response = try await performRequest(
        endpoint: "api/purchases/\(purchaseId)/meetup",
        method: .GET,
        responseType: APIResponse<Meetup>.self
    )

    return response.data
}

func updateMeetup(purchaseId: String, location: String, scheduledTime: Date) async throws -> Meetup {
    // Similar to createMeetup but with PUT method
}
```

#### C. **Meetup Model** (Add to Models folder)

```swift
// File: /Users/shalin/Documents/Projects/Xcode/Brrow/Brrow/Models/Meetup.swift

import Foundation

struct Meetup: Codable, Identifiable {
    let id: String
    let purchaseId: String
    let location: String
    let scheduledTime: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case purchaseId = "purchase_id"
        case location
        case scheduledTime = "scheduled_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var scheduledDate: Date? {
        return scheduledTime.toDate()
    }

    var formattedTime: String {
        return scheduledTime.toUserFriendlyDate()
    }
}
```

#### D. **Update TransactionDetailView**

Add meetup section to existing transaction detail view:

```swift
// In TransactionDetailView.swift

@State private var meetup: Meetup?
@State private var showMeetupProposal = false

var body: some View {
    VStack {
        // ... existing transaction details ...

        // Meetup section
        if let meetup = meetup {
            VStack(alignment: .leading, spacing: 8) {
                Text("Meetup Details")
                    .font(.headline)

                HStack {
                    Image(systemName: "mappin.circle.fill")
                    Text(meetup.location)
                }

                HStack {
                    Image(systemName: "clock.fill")
                    Text(meetup.formattedTime)
                }

                Button("Get Directions") {
                    // Open Maps
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.card)
        } else {
            Button("Propose Meetup") {
                showMeetupProposal = true
            }
        }
    }
    .onAppear {
        loadMeetup()
    }
    .sheet(isPresented: $showMeetupProposal) {
        MeetupProposalView(purchaseId: purchase.id)
    }
}

func loadMeetup() {
    Task {
        do {
            meetup = try await APIClient.shared.getMeetup(purchaseId: purchase.id)
        } catch {
            // No meetup created yet
        }
    }
}
```

### 5. Complete User Flow Example

**Scenario:** Sarah buys Jake's camera for $100

1. **Purchase Created:**
   - Sarah taps "Buy Now" on camera listing
   - Backend creates purchase, holds $100 in Stripe
   - Jake receives push notification: "Sarah purchased "Canon EOS R5" for $100"

2. **Jake Opens Transaction:**
   - Taps notification → opens transaction detail
   - Sees Sarah's profile, payment held, deadline (72 hours)
   - Taps "Propose Meetup"

3. **Jake Proposes Location:**
   - Opens meetup proposal screen
   - Types "Starbucks, 123 Main St" or picks on map
   - Selects "Tomorrow at 3:00 PM"
   - Taps "Send Proposal"

4. **Sarah Gets Notified:**
   - Receives push: "Jake proposed a meetup for Canon EOS R5"
   - Opens transaction detail
   - Sees: "Starbucks, 123 Main St - Tomorrow at 3:00 PM"
   - Taps "Accept" (or "Suggest Different Time")

5. **Both Receive Confirmation:**
   - Meetup is confirmed
   - Both users see meetup details in transaction
   - Both get "Get Directions" button

6. **After Meetup:**
   - Both users receive prompt: "Did the exchange happen?"
   - Both confirm → payment is released to Jake
   - If one doesn't confirm → escalation flow

### 6. Push Notification Support

**Already Implemented** (as of latest deployment):

When purchase is created, seller receives:
```json
{
  "notification": {
    "title": "New Purchase Request",
    "body": "{buyer} purchased "{item}" for ${amount}"
  },
  "data": {
    "type": "transaction",
    "transactionId": "purchase_id",
    "screen": "transaction_detail",
    "purchaseId": "purchase_id",
    "listingId": "listing_id"
  }
}
```

**Need to Add:**
- Notification when meetup is proposed
- Notification when meetup is accepted
- Notification when meetup time is approaching (1 hour before)

### 7. Backend Endpoints (Already Available)

✅ **POST** `/api/purchases/:purchaseId/meetup`
- Create new meetup
- Body: `{ location: string, scheduled_time: ISO8601 }`
- Returns: Meetup object

✅ **GET** `/api/purchases/:purchaseId/meetup`
- Get meetup details
- Returns: Meetup object or null

✅ **PUT** `/api/purchases/:purchaseId/meetup`
- Update existing meetup
- Body: `{ location: string, scheduled_time: ISO8601 }`
- Returns: Updated meetup object

### 8. What You Need to Do

**High Priority:**
1. Create `MeetupProposalView.swift`
2. Add meetup methods to `APIClient.swift`
3. Create `Meetup.swift` model
4. Update `TransactionDetailView` to show meetup section
5. Test the flow end-to-end

**Medium Priority:**
6. Add "Get Directions" functionality (opens Apple Maps)
7. Add ability to reschedule meetup
8. Add meetup reminders (1 hour before)
9. Add post-meetup confirmation UI

**Low Priority:**
10. Add map view for location picking
11. Add saved locations (home, work, favorite spots)
12. Add transit time estimation

### 9. Alternative: Simple Chat-Based Coordination

If you don't want to build the full meetup UI yet, you can:

1. Just open a chat between buyer and seller automatically after purchase
2. Let them coordinate via messages
3. Add quick action buttons in chat: "Propose Location", "Propose Time"
4. These buttons just insert formatted messages into the chat

This is simpler but less structured than the full meetup flow.

---

## Summary

The backend already supports meetups fully. The iOS app just needs:
1. A meetup proposal UI (simple form)
2. Display meetup details in transaction view
3. API client methods to create/get meetups
4. Notification handling for meetup events

The flow is straightforward: seller proposes → buyer accepts → both see details → both confirm after exchange.
