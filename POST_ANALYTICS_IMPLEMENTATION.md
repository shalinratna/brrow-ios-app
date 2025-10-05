# Post Analytics Implementation Guide

## Overview
This document describes the comprehensive YouTube-style analytics system for Brrow posts/listings.

## Architecture

### Database Schema
The analytics system uses 9 new database tables:

1. **post_analytics** - Aggregated metrics per post (overview)
2. **post_view_events** - Detailed individual view records
3. **post_engagement_events** - Clicks, favorites, shares
4. **post_search_impressions** - Search result appearances
5. **post_hourly_metrics** - Hourly aggregated data
6. **post_daily_metrics** - Daily aggregated data
7. **post_audience_demographics** - Geographic viewer breakdown
8. **post_traffic_sources** - Where views come from
9. **post_active_viewers** - Real-time active viewer tracking

### Backend API Endpoints

#### Event Tracking (Public)
- `POST /api/post-analytics/track/view` - Track post view
- `POST /api/post-analytics/track/view-engagement` - Update view metrics on exit
- `POST /api/post-analytics/track/engagement` - Track engagement events
- `POST /api/post-analytics/track/search-impression` - Track search impressions
- `POST /api/post-analytics/heartbeat` - Real-time viewer heartbeat

#### Analytics Retrieval (Authenticated, Owner Only)
- `GET /api/post-analytics/:listingId/overview` - Overall metrics
- `GET /api/post-analytics/:listingId/views` - Detailed view data
- `GET /api/post-analytics/:listingId/engagement` - Engagement breakdown
- `GET /api/post-analytics/:listingId/audience` - Demographics
- `GET /api/post-analytics/:listingId/traffic-sources` - Traffic breakdown
- `GET /api/post-analytics/:listingId/performance` - Time-series data
- `GET /api/post-analytics/:listingId/search-performance` - Search metrics
- `GET /api/post-analytics/:listingId/active-viewers` - Current viewers

#### Comparisons
- `GET /api/post-analytics/:listingId/compare/user-posts` - vs your other posts
- `GET /api/post-analytics/:listingId/compare/category` - vs category average

#### Dashboard
- `GET /api/post-analytics/dashboard` - All your posts summary

## Integration Points

### 1. Listing Detail View
When user opens a listing:
```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    Task {
        await PostAnalyticsService.shared.trackPostView(
            listingId: listing.id,
            source: .search, // or .profile, .featured, etc.
            searchQuery: searchQuery // if came from search
        )
    }
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    Task {
        await PostAnalyticsService.shared.endPostView()
    }
}
```

### 2. Scroll Tracking
Track how far user scrolls:
```swift
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let scrollDepth = (scrollView.contentOffset.y + scrollView.frame.height) / scrollView.contentSize.height * 100
    PostAnalyticsService.shared.updateScrollDepth(scrollDepth)
}
```

### 3. Image Gallery
Track image views:
```swift
func didViewImage(at index: Int) {
    PostAnalyticsService.shared.trackImageViewed()
}
```

### 4. Favorite Button
Track favorites:
```swift
func toggleFavorite() {
    let isFavoriting = !listing.isFavorited

    Task {
        // Toggle favorite in backend
        await toggleFavoriteAPI()

        // Track analytics
        await PostAnalyticsService.shared.trackFavorite(
            listingId: listing.id,
            isFavoriting: isFavoriting
        )
    }
}
```

### 5. Share Button
Track shares:
```swift
func shareListing(platform: String) {
    Task {
        await PostAnalyticsService.shared.trackShare(
            listingId: listing.id,
            platform: platform // "messages", "instagram", "copy_link"
        )
    }
}
```

### 6. Contact/Message Button
Track contact clicks:
```swift
func messageOwner() {
    Task {
        await PostAnalyticsService.shared.trackContactClick(
            listingId: listing.id
        )

        // Navigate to conversation
    }
}
```

### 7. Search Results
Track search impressions:
```swift
// When displaying search results
for (index, listing) in listings.enumerated() {
    await trackSearchImpression(
        listingId: listing.id,
        position: index + 1,
        searchQuery: searchQuery
    )
}

// When user clicks a result
func didSelectListing(at index: Int) {
    Task {
        await trackImpressionClick(impressionId: impressionIds[index])
    }
}
```

### 8. Real-time Active Viewers
Display active viewers on listing:
```swift
func loadActiveViewers() {
    Task {
        let count = try await PostAnalyticsService.shared.getActiveViewerCount(
            listingId: listing.id
        )

        updateActiveViewersBadge(count: count)
    }
}
```

## Metrics Tracked

### Reach Metrics
- **Total Views** - All view events
- **Unique Views** - Deduplicated by session
- **Impressions** - Search result appearances
- **CTR** - Click-through rate from search

### Engagement Metrics
- **Favorites** - Add/remove from favorites
- **Shares** - Share button clicks
- **Messages** - Contact button clicks
- **Gallery Views** - Image interactions
- **Map Clicks** - Location clicks

### Audience Metrics
- **Geographic Data** - Country, state, city breakdown
- **Traffic Sources** - Search, direct, profile, featured, category
- **Device Info** - iOS version, device model

### Performance Metrics
- **View Duration** - Time spent viewing
- **Scroll Depth** - How far they scrolled
- **Engagement Rate** - Engagements / unique views
- **Trending Score** - Weighted recent activity score

## YouTube-Style Features

### 1. Overview Dashboard
Shows key metrics at a glance:
- Total views (with trend)
- Unique viewers
- Watch time equivalent (view duration)
- Engagement rate
- Active viewers (real-time)

### 2. Reach Tab
- Views over time (chart)
- Impressions vs views
- CTR from search
- Traffic sources breakdown

### 3. Engagement Tab
- Engagement breakdown by type
- Engagement rate over time
- Top performing elements

### 4. Audience Tab
- Geographic map of viewers
- Top countries/cities
- New vs returning viewers

### 5. Traffic Tab
- Source breakdown (search, direct, profile, etc.)
- Search queries that led to views
- Average position in search results

### 6. Comparisons
- Compare to your other posts
- Compare to category average
- Trending score ranking

## Performance Considerations

### Aggregation Strategy
- Real-time: Direct updates to post_analytics table
- Hourly: Aggregated in post_hourly_metrics
- Daily: Aggregated in post_daily_metrics
- Run cleanup job periodically to archive old detailed events

### Optimization
- Indexed queries on common filters
- Cached aggregations
- Background jobs for heavy calculations
- Pagination for large datasets

## Privacy & Security

### Access Control
- Only post owners can view analytics
- Anonymous tracking for viewers
- IP addresses hashed for privacy
- GDPR compliance considerations

### Data Retention
- Detailed events: 90 days
- Aggregated metrics: Indefinite
- Active viewers: 5 minutes timeout

## Setup Instructions

### 1. Database Migration
```bash
cd brrow-backend
npx prisma migrate dev --name add_post_analytics
```

### 2. Register Routes
Add to server.js:
```javascript
const postAnalyticsRoutes = require('./routes/postAnalytics');
app.use('/api/post-analytics', postAnalyticsRoutes);
```

### 3. Deploy Backend
```bash
git add .
git commit -m "Feature: YouTube-style post analytics system"
git push

# Deploy to Railway
```

### 4. iOS Integration
Add the new files to Xcode project:
- Models/PostAnalytics.swift
- Services/PostAnalyticsService.swift

### 5. Integrate Tracking
Add tracking calls to:
- ListingDetailView
- SearchResultsView
- FavoriteButton
- ShareSheet
- MessageButton
- ImageGallery

## Testing Checklist

- [ ] Track view event on listing open
- [ ] Update engagement on listing close
- [ ] Track scroll depth
- [ ] Track favorites
- [ ] Track shares
- [ ] Track contact clicks
- [ ] Track search impressions
- [ ] Real-time active viewers update
- [ ] Analytics dashboard loads
- [ ] Performance charts display
- [ ] Demographics map works
- [ ] Traffic sources breakdown
- [ ] Comparisons calculate correctly
- [ ] Only owners can view analytics
- [ ] Anonymous users can trigger tracking

## Future Enhancements

1. **A/B Testing**
   - Test different titles/descriptions
   - Optimize pricing
   - Test image ordering

2. **Recommendations**
   - AI-powered suggestions to improve performance
   - "Posts like this get X% more views when..."

3. **Alerts**
   - Notify when post goes viral
   - Alert on trending spike
   - Weekly performance summary

4. **Export**
   - CSV export for analytics
   - PDF reports
   - Email summaries

5. **Advanced Demographics**
   - Age ranges (if verified)
   - User interests
   - Purchase history patterns

## API Response Examples

### Overview
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "listing_id": "listing-123",
    "total_views": 1524,
    "unique_views": 892,
    "total_impressions": 3421,
    "total_favorites": 45,
    "total_shares": 12,
    "total_messages": 23,
    "avg_view_duration": 45.2,
    "avg_scroll_depth": 67.8,
    "click_through_rate": 26.1,
    "engagement_rate": 8.9,
    "trending_score": 156.3,
    "active_viewers": 3
  }
}
```

### Traffic Sources
```json
{
  "success": true,
  "data": [
    {
      "source": "search",
      "views": 823,
      "unique_views": 521,
      "clicks": 234,
      "conversions": 12,
      "avg_duration": 52.3
    },
    {
      "source": "profile",
      "views": 421,
      "unique_views": 289,
      "clicks": 156,
      "conversions": 8
    }
  ]
}
```

### Audience Demographics
```json
{
  "success": true,
  "data": {
    "by_country": [
      {
        "country": "United States",
        "view_count": 1245,
        "unique_viewers": 723,
        "cities": [
          {"city": "New York", "state": "NY", "view_count": 342},
          {"city": "Los Angeles", "state": "CA", "view_count": 289}
        ]
      }
    ]
  }
}
```

## Support

For questions or issues:
- Check backend logs: `railway logs`
- Check Prisma schema: `/brrow-backend/prisma/schema.prisma`
- Review service: `/brrow-backend/services/postAnalyticsService.js`
- Review routes: `/brrow-backend/routes/postAnalytics.js`
