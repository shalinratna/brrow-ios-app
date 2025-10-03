# 🚧 Incomplete Features - Action Plan

Total Issues Found: **346 items**

## Priority 1: CRITICAL USER-FACING FEATURES ❌

### 1. Payment Flow (BLOCKING LAUNCH)
- **File**: `PaymentMethodsView.swift:334, 488`
- **Issue**: "Apple Pay coming soon", "Bank account coming soon"
- **Action**: Implement Stripe payment sheet integration
- **Status**: MUST FIX

### 2. Chat Message Features
- **File**: `EnhancedChatDetailView.swift:66`
- **Issue**: Video picker not implemented
- **Action**: Implement video selection from library
- **Status**: MUST FIX

- **File**: `EnhancedChatDetailView.swift:799, 803`
- **Issue**: File viewer and offer cards not implemented
- **Action**: Build file preview and offer UI components
- **Status**: MUST FIX

- **File**: `EnhancedChatDetailView.swift:826`
- **Issue**: Full-screen image viewer TODO
- **Action**: Implement full-screen photo viewer with zoom/pan
- **Status**: MUST FIX

### 3. Notification → Chat Navigation
- **File**: `NotificationsView.swift:87`
- **Issue**: Shows "Loading conversation..." placeholder
- **Action**: Implement proper conversation fetching and navigation
- **Status**: MUST FIX

### 4. Listing Detail Navigation
- **File**: `EnhancedChatDetailView.swift:537`
- **Issue**: "TODO: Navigate to actual listing detail view"
- **Action**: Wire up navigation to listing detail
- **Status**: MUST FIX

---

## Priority 2: FEATURES WITH UI BUT NO BACKEND ⚠️

### 5. Booking Messages
- **File**: `BookingDetailView.swift:512`
- **Issue**: "Messages feature coming soon..."
- **Action**: Connect to existing chat system
- **Status**: SHOULD FIX

### 6. Edit Seek
- **File**: `EditSeekView.swift:15`
- **Issue**: Entire view is placeholder
- **Action**: Implement edit functionality for "Seeking" posts
- **Status**: SHOULD FIX

### 7. Advanced Search Filters
- **File**: `AdvancedSearchView.swift:447, 473, 493`
- **Issue**: Advanced filters, map view, saved searches all "coming soon"
- **Action**: Remove buttons or implement features
- **Status**: SHOULD FIX

### 8. Booking Filters
- **File**: `MyBookingsView.swift:339`
- **Issue**: "Filters coming soon..."
- **Action**: Implement filter dropdown (Upcoming, Active, Completed, Cancelled)
- **Status**: SHOULD FIX

### 9. ID.me Student Verification
- **File**: `IDmeVerificationView.swift:147, 151`
- **Issue**: "Student Verification - Coming Soon"
- **Action**: Either implement or remove from UI
- **Status**: CAN REMOVE

### 10. Custom Themes
- **File**: `ProfileSupportViews.swift:616`
- **Issue**: "Custom themes coming soon!"
- **Action**: Remove feature or implement theme switching
- **Status**: CAN REMOVE

---

## Priority 3: ANALYTICS & NON-CRITICAL TODOs 📊

### 11. Analytics Tracking (40+ instances)
- **Files**: Multiple ViewModels and Services
- **Issue**: "TODO: Add analytics tracking"
- **Action**: Implement event tracking using existing analytics backend
- **Status**: NICE TO HAVE

### 12. Core Data / Caching TODOs (20+ instances)
- **Files**: ChatService, IntelligentCacheManager, AppOptimizationService
- **Issue**: Various cache persistence TODOs
- **Action**: Implement or remove if not critical
- **Status**: NICE TO HAVE

### 13. Location Services TODOs
- **Files**: HomeViewModel, IntelligentCacheManager
- **Issue**: Distance filtering, location data
- **Action**: Implement location permissions and filtering
- **Status**: NICE TO HAVE

---

## Implementation Order

### Phase 1: Critical Launch Blockers (Week 1)
1. ✅ **Payment Flow UI** - Connect Stripe to iOS (PRIORITY #1)
2. ✅ **Notification → Chat Navigation** - Fix broken flow
3. ✅ **Full-Screen Image Viewer** - Basic implementation
4. ✅ **Listing Detail Navigation from Chat** - Wire up existing view

### Phase 2: Chat Enhancements (Week 1-2)
5. ✅ **Video Picker** - Allow video selection and upload
6. ✅ **File Attachments** - Implement file preview and download
7. ✅ **Offer Cards** - Design and implement offer UI in chat

### Phase 3: Polish & Remove "Coming Soon" (Week 2)
8. ✅ **Remove or Implement**: Advanced search filters, student verification, themes
9. ✅ **Booking Messages** - Connect to chat system
10. ✅ **Edit Seek** - Implement or remove feature
11. ✅ **Booking Filters** - Add filter options

### Phase 4: Analytics & Optimization (Week 3)
12. ✅ **Analytics Integration** - Track key events
13. ✅ **Cache Optimization** - Implement persistent caching
14. ✅ **Location Services** - Add distance filtering

---

## Detailed Action Items

### 1. Payment Flow Implementation

**Files to Modify**:
- `PaymentMethodsView.swift`
- Create new `StripePaymentSheet.swift`
- Create new `PaymentFlowView.swift`

**Tasks**:
- [ ] Install Stripe iOS SDK
- [ ] Implement PaymentSheet UI
- [ ] Connect to backend `/api/payments/create-intent`
- [ ] Handle payment confirmation
- [ ] Show success/error states
- [ ] Test with live Stripe keys

**Estimated Time**: 2-3 days

---

### 2. Video Picker Implementation

**Files to Modify**:
- `EnhancedChatDetailView.swift` (line 66)
- Create new `VideoPicker.swift` view

**Tasks**:
- [ ] Implement PHPickerViewController for videos
- [ ] Add video compression before upload
- [ ] Upload to backend `/api/upload/video`
- [ ] Store video URL in message
- [ ] Implement video player in chat

**Estimated Time**: 1-2 days

---

### 3. Notification → Chat Navigation Fix

**Files to Modify**:
- `NotificationsView.swift` (line 87)
- `ChatListViewModel.swift`

**Tasks**:
- [ ] Fetch conversation by chatId from notification
- [ ] Create minimal Conversation object for navigation
- [ ] Navigate to EnhancedChatDetailView
- [ ] Test deep link: `brrow://chat/123`

**Estimated Time**: 1 day

---

### 4. Full-Screen Image Viewer

**Files to Modify**:
- `EnhancedChatDetailView.swift` (line 826)
- Create new `FullScreenImageViewer.swift`

**Tasks**:
- [ ] Implement zoom/pan gestures
- [ ] Add share button
- [ ] Add download button
- [ ] Swipe to dismiss
- [ ] Image caching

**Estimated Time**: 1 day

---

### 5. File Attachments & Offer Cards

**Files to Modify**:
- `EnhancedChatDetailView.swift` (lines 799, 803)
- Create `FileMessageView.swift`
- Create `OfferCardView.swift`

**Tasks**:
- [ ] Design file preview UI (PDF, DOC icons)
- [ ] Implement file download
- [ ] Design offer card UI (price, accept/decline)
- [ ] Connect to backend offer API
- [ ] Handle offer acceptance/rejection

**Estimated Time**: 2 days

---

### 6. Remove "Coming Soon" Features

**Quick Wins** (1 hour each):
- [ ] Remove "Student Verification" section from ID.me (or implement)
- [ ] Remove "Custom Themes" from settings
- [ ] Remove "Advanced Filters" button from search
- [ ] Remove "Map View" button from search
- [ ] Remove "Saved Searches" button from search

**Alternative**: Hide these features behind a "Beta Features" toggle in settings

---

## Success Criteria

### Before Launch:
- ✅ NO "Coming Soon" text visible to users
- ✅ NO placeholder screens when tapping buttons
- ✅ Payment flow works end-to-end
- ✅ All chat features functional (text, images, videos, files)
- ✅ All navigation flows work without placeholders
- ✅ App builds without warnings
- ✅ No crashes in critical user paths

### Metrics:
- User can complete: Sign up → Browse → Message → Book → Pay → Complete
- Every button does something (no dead ends)
- Every "TODO" either implemented or removed
- Code coverage > 70% for critical flows

---

## Next Steps

Ready to start implementation? I recommend:

1. **Start with Payment Flow** (biggest blocker)
2. **Fix Navigation Issues** (notifications, chat, listings)
3. **Clean up "Coming Soon"** (quick wins)
4. **Implement Chat Features** (video, files, offers)
5. **Polish & Test** (end-to-end flows)

Should I start implementing Phase 1 items now?
