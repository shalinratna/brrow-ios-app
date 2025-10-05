# Post Analytics - Quick Start Guide

## 🚀 Quick Integration Checklist

### Backend Setup

1. **Run Database Migration**
   ```bash
   cd /Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend
   npx prisma migrate dev --name add_post_analytics_system
   npx prisma generate
   ```

2. **Verify Route Registration** ✅
   Already added to `prisma-server.js`:
   ```javascript
   const postAnalyticsRouter = require('./routes/postAnalytics');
   app.use('/api/post-analytics', postAnalyticsRouter);
   ```

3. **Deploy to Railway**
   ```bash
   git add .
   git commit -m "Feature: YouTube-style post analytics system"
   git push origin master
   ```

### iOS Setup

1. **Add Files to Xcode**
   - ✅ `Brrow/Models/PostAnalytics.swift`
   - ✅ `Brrow/Services/PostAnalyticsService.swift`

2. **Add to Xcode Project**
   - Open Xcode
   - Right-click on `Models` folder → Add Files
   - Select `PostAnalytics.swift`
   - Right-click on `Services` folder → Add Files
   - Select `PostAnalyticsService.swift`

## 📊 Basic Tracking Implementation

### Listing Detail View

```swift
import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    @State private var viewEventId: String?
    @State private var activeViewers: Int = 0

    var body: some View {
        ScrollView {
            // Your existing content
        }
        .onAppear {
            trackView()
            loadActiveViewers()
        }
        .onDisappear {
            endView()
        }
    }

    private func trackView() {
        Task {
            await PostAnalyticsService.shared.trackPostView(
                listingId: listing.id,
                source: .direct // Change based on context
            )
        }
    }

    private func endView() {
        Task {
            await PostAnalyticsService.shared.endPostView()
        }
    }

    private func loadActiveViewers() {
        Task {
            do {
                activeViewers = try await PostAnalyticsService.shared.getActiveViewerCount(
                    listingId: listing.id
                )
            } catch {
                print("Failed to load active viewers: \(error)")
            }
        }
    }
}
```

### Favorite Button

```swift
Button {
    toggleFavorite()
} label: {
    Image(systemName: isFavorited ? "heart.fill" : "heart")
}

func toggleFavorite() {
    Task {
        // Toggle favorite state
        isFavorited.toggle()

        // Track analytics
        await PostAnalyticsService.shared.trackFavorite(
            listingId: listing.id,
            isFavoriting: isFavorited
        )

        // Call backend API to persist
        // await favoriteListing()
    }
}
```

### Share Button

```swift
Button {
    showShareSheet = true
} label: {
    Image(systemName: "square.and.arrow.up")
}
.sheet(isPresented: $showShareSheet) {
    ShareSheet(listing: listing) { platform in
        Task {
            await PostAnalyticsService.shared.trackShare(
                listingId: listing.id,
                platform: platform
            )
        }
    }
}
```

### Message Button

```swift
Button("Contact Seller") {
    Task {
        // Track contact click
        await PostAnalyticsService.shared.trackContactClick(
            listingId: listing.id
        )

        // Navigate to conversation
        navigateToConversation()
    }
}
```

## 📈 Viewing Analytics

### Analytics Dashboard View

```swift
import SwiftUI

struct AnalyticsDashboardView: View {
    @State private var dashboard: AnalyticsDashboard?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            if let dashboard = dashboard {
                // Summary Cards
                HStack(spacing: 16) {
                    MetricCard(
                        title: "Total Views",
                        value: "\(dashboard.totals.totalViews ?? 0)",
                        icon: "eye"
                    )

                    MetricCard(
                        title: "Engagement",
                        value: "\(dashboard.totals.totalFavorites ?? 0)",
                        icon: "heart.fill"
                    )
                }

                // Post List
                ForEach(dashboard.posts, id: \.listingId) { post in
                    PostAnalyticsRow(post: post)
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            loadDashboard()
        }
    }

    private func loadDashboard() {
        isLoading = true

        Task {
            do {
                dashboard = try await PostAnalyticsService.shared.getAnalyticsDashboard()
            } catch {
                print("Failed to load dashboard: \(error)")
            }
            isLoading = false
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

### Post Analytics Detail View

```swift
import SwiftUI

struct PostAnalyticsDetailView: View {
    let listingId: String
    @State private var overview: PostAnalyticsOverview?
    @State private var trafficSources: [TrafficSource] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            if let overview = overview {
                // Overview Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Overview")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        StatBox(
                            title: "Total Views",
                            value: "\(overview.totalViews)"
                        )

                        StatBox(
                            title: "Unique Views",
                            value: "\(overview.uniqueViews)"
                        )
                    }

                    HStack(spacing: 16) {
                        StatBox(
                            title: "Avg Duration",
                            value: overview.formattedViewDuration
                        )

                        StatBox(
                            title: "Engagement Rate",
                            value: overview.formattedEngagementRate
                        )
                    }
                }
                .padding()

                // Traffic Sources
                if !trafficSources.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Traffic Sources")
                            .font(.title2)
                            .fontWeight(.bold)

                        ForEach(trafficSources, id: \.id) { source in
                            TrafficSourceRow(source: source)
                        }
                    }
                    .padding()
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Analytics")
        .onAppear {
            loadAnalytics()
        }
    }

    private func loadAnalytics() {
        isLoading = true

        Task {
            do {
                async let overviewTask = PostAnalyticsService.shared.getPostOverview(
                    listingId: listingId
                )
                async let sourcesTask = PostAnalyticsService.shared.getTrafficSources(
                    listingId: listingId
                )

                overview = try await overviewTask
                trafficSources = try await sourcesTask
            } catch {
                print("Failed to load analytics: \(error)")
            }
            isLoading = false
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TrafficSourceRow: View {
    let source: TrafficSource

    var body: some View {
        HStack {
            Image(systemName: source.iconName)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(source.displayName)
                    .font(.subheadline)

                Text("\(source.views) views")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(source.uniqueViews)")
                .font(.headline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
```

## 🎯 Traffic Source Types

When tracking views, specify the source:

```swift
// From search results
await PostAnalyticsService.shared.trackPostView(
    listingId: listing.id,
    source: .search,
    searchQuery: "mountain bike"
)

// From user profile
await PostAnalyticsService.shared.trackPostView(
    listingId: listing.id,
    source: .profile
)

// From featured section
await PostAnalyticsService.shared.trackPostView(
    listingId: listing.id,
    source: .featured
)

// From category browse
await PostAnalyticsService.shared.trackPostView(
    listingId: listing.id,
    source: .category
)

// From home feed
await PostAnalyticsService.shared.trackPostView(
    listingId: listing.id,
    source: .homeFeed
)

// Direct link
await PostAnalyticsService.shared.trackPostView(
    listingId: listing.id,
    source: .direct
)
```

## 🔍 Available Analytics

### Overview Metrics
- Total views
- Unique views
- Impressions (search appearances)
- Favorites
- Shares
- Messages
- Click-through rate
- Engagement rate
- Trending score
- Active viewers (real-time)

### Detailed Analytics
- View duration
- Scroll depth
- Images viewed
- Traffic sources breakdown
- Geographic demographics
- Search performance
- Hourly/daily trends

### Comparisons
- Compare to your other posts
- Compare to category average
- Performance benchmarking

## 🐛 Testing

### Test Tracking
1. Open a listing → Should track view
2. Scroll through listing → Should track scroll depth
3. View images → Should increment image views
4. Favorite listing → Should track engagement
5. Share listing → Should track share
6. Click message → Should track contact
7. Exit listing → Should send engagement data

### Test Analytics Viewing
1. Navigate to analytics dashboard
2. Should see all your posts
3. Click on a post
4. Should see detailed metrics
5. Should see traffic sources
6. Should see real-time active viewers

### Verify Backend
```bash
# Check logs
cd /Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend
npm start

# Test endpoint
curl http://localhost:3002/api/post-analytics/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## ⚠️ Important Notes

1. **Privacy**: Only post owners can view analytics
2. **Anonymous Tracking**: Viewer tracking works without authentication
3. **Real-time**: Active viewers update every 10 seconds
4. **Performance**: Aggregations run in background
5. **Cleanup**: Old detailed events auto-archived after 90 days

## 📚 Full Documentation

See `POST_ANALYTICS_IMPLEMENTATION.md` for:
- Complete API reference
- Database schema details
- Advanced features
- Performance optimization
- Privacy considerations
- Future enhancements

## 🆘 Troubleshooting

### Backend Issues
- Check Railway logs for errors
- Verify Prisma migration ran successfully
- Ensure routes are registered in server

### iOS Issues
- Verify files added to Xcode project
- Check network requests in debug
- Ensure authentication token is valid

### No Data Showing
- Check if tracking events are being sent
- Verify user owns the listing
- Check backend logs for errors
- Ensure database migration completed

## 🎉 You're Ready!

Start tracking analytics by:
1. Running the database migration
2. Adding the iOS files to Xcode
3. Integrating tracking calls
4. Creating analytics views
5. Deploying to Railway

The system will automatically aggregate data and provide YouTube-style insights!
