# Offer Card UI Design Specification

## Visual Layout

```
┌─────────────────────────────────────────────────────────┐
│  💲 Offer                              [Pending Badge]  │
│                                                          │
│  $80.00                                                  │
│         Original: $100.00 (strikethrough)               │
│         20% off                                          │
│                                                          │
│  "Would you accept this offer for the camera?"          │
│                                                          │
│  📅 5 days                                               │
│                                                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │ Reject  │  │ Counter │  │ Accept  │                │
│  └─────────┘  └─────────┘  └─────────┘                │
│                                                          │
│                                     Oct 2, 2:34 PM      │
└─────────────────────────────────────────────────────────┘
```

## Component Breakdown

### Header Row
- **Icon**: Dollar sign circle (💲) in primary green
- **Title**: "Offer" text in semibold
- **Status Badge**: Pill-shaped badge with status
  - Pending: Orange background
  - Accepted: Green background
  - Rejected: Red background
  - Countered: Blue background

### Offer Amount Section
- **Main Amount**: Large bold text ($80.00) in primary green
- **Original Price**: Smaller, gray, strikethrough ($100.00)
- **Discount**: Red accent text showing percentage off

### Message Section
- **Optional**: Only shown if offer includes a message
- **Style**: Regular text, secondary color
- **Max Lines**: 3 with truncation

### Duration Section
- **Icon**: Calendar icon
- **Text**: Number of days
- **Color**: Secondary gray

### Action Buttons (Recipient Only)
- **Reject**: White button with gray border
- **Counter**: White button with green border
- **Accept**: Solid green button with white text
- **Layout**: Equal width, horizontal row
- **Visibility**: Only shown if:
  - Message is from other user (not current user)
  - Status is "pending"

### Timestamp
- **Position**: Bottom right
- **Style**: Small, secondary color
- **Format**: Abbreviated date + short time

## Color Scheme

### For Sender (Current User)
- Background: Light primary green (10% opacity)
- Border: Primary green (20% opacity)
- Shadow: Subtle black shadow

### For Recipient (Other User)
- Background: Surface color (card background)
- Border: Light gray border
- Shadow: Subtle black shadow

## Status Badge Colors

| Status    | Background | Text  | Icon |
|-----------|-----------|-------|------|
| Pending   | Orange    | White | ⏳   |
| Accepted  | Green     | White | ✓    |
| Rejected  | Red       | White | ✗    |
| Countered | Blue      | White | ↔    |

## Dimensions

- **Card Padding**: 16px all sides
- **Corner Radius**: 12px
- **Border Width**: 1px
- **Shadow**: 4px blur, 2px offset, 5% opacity
- **Button Height**: 40px
- **Button Spacing**: 8px between buttons
- **Section Spacing**: 12px between sections

## Interaction States

### Buttons
- **Default**: Colored background/border
- **Pressed**: Darker shade (opacity 0.8)
- **Disabled**: Gray, 50% opacity

### Card
- **Default**: Normal appearance
- **Selected**: Slightly scaled (1.02x)
- **Animation**: Spring animation (0.3s)

## Accessibility

- **VoiceOver Labels**:
  - "Offer for $80 from [sender name]"
  - "Accept offer button"
  - "Reject offer button"
  - "Counter offer button"
- **Dynamic Type**: Supports large text sizes
- **High Contrast**: Maintains readable contrast ratios
- **Color Blind**: Status indicated by text, not just color

## Responsive Behavior

- **Small Screens**: Buttons stack vertically if < 375pt width
- **Large Text**: Card expands vertically
- **Landscape**: Maintains horizontal layout
- **iPad**: Slightly larger padding and fonts

## Dark Mode Adjustments

- Background uses darker surface colors
- Text uses lighter shades
- Borders more visible (higher opacity)
- Shadows adjusted for dark backgrounds
- Button colors maintain contrast

## Example Scenarios

### Scenario 1: New Pending Offer (Recipient View)
```
User B receives offer from User A
- Shows full card with all action buttons
- Status badge: Orange "Pending"
- Amount, message, and duration visible
- All three buttons enabled
```

### Scenario 2: Accepted Offer (Sender View)
```
User A views their accepted offer
- Shows card without action buttons
- Status badge: Green "Accepted"
- Amount and details still visible
- No buttons (already accepted)
```

### Scenario 3: Rejected Offer (Recipient View)
```
User B views rejected offer
- Shows card without action buttons
- Status badge: Red "Rejected"
- Amount and details still visible
- No buttons (already rejected)
```

### Scenario 4: Counter Offer (Sender View)
```
User A views countered offer
- Shows card without action buttons
- Status badge: Blue "Countered"
- Original amount visible
- Indicates counter offer in separate message
```

## Animation Behavior

### Card Appearance
- **Entry**: Scale from 0.8 to 1.0
- **Entry**: Fade from 0 to 1.0
- **Duration**: 0.3 seconds
- **Easing**: Spring animation

### Button Press
- **Scale**: 0.95 on press
- **Duration**: 0.1 seconds
- **Easing**: Linear

### Status Change
- **Badge**: Pulse animation (1.0 to 1.1 to 1.0)
- **Duration**: 0.5 seconds
- **Repeat**: Once

## Code Structure

```swift
OfferCardView(
    message: Message,           // Message containing offer data
    isFromCurrentUser: Bool,    // Determines card styling
    onAccept: () -> Void,       // Accept button callback
    onReject: () -> Void,       // Reject button callback
    onCounter: () -> Void       // Counter button callback
)
```

### Data Model
```swift
struct OfferData: Codable {
    let offerAmount: Double      // The offer amount
    let listingPrice: Double?    // Original listing price
    let status: String           // pending, accepted, rejected, countered
    let message: String?         // Optional offer message
    let duration: Int?           // Rental duration in days
}
```

## Integration Points

1. **EnhancedChatDetailView**: Displays offer cards in message list
2. **Message Model**: Stores offer data as JSON in content field
3. **APIClient**: Calls backend for accept/reject/counter actions
4. **AnalyticsService**: Tracks offer actions

## Future Enhancements

1. **Rich Media**: Add listing thumbnail to offer card
2. **History**: Show offer counter history
3. **Notifications**: Push notification when offer status changes
4. **Expiration**: Add countdown timer for expiring offers
5. **Templates**: Quick offer templates (e.g., "75% of asking price")
6. **Negotiation Helper**: AI-suggested counter offers
