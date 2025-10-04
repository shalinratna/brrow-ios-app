//
//  PostAnalytics.swift
//  Brrow
//
//  YouTube-style analytics models for posts/listings
//

import Foundation

// MARK: - Post Analytics Overview

struct PostAnalyticsOverview: Codable {
    let id: String
    let listingId: String

    // View metrics
    let totalViews: Int
    let uniqueViews: Int
    let totalImpressions: Int

    // Engagement metrics
    let totalFavorites: Int
    let totalShares: Int
    let totalMessages: Int
    let totalClicks: Int

    // Interaction metrics
    let galleryViews: Int
    let contactClicks: Int
    let mapClicks: Int

    // Performance metrics
    let avgViewDuration: Double?
    let avgScrollDepth: Double?
    let clickThroughRate: Double?
    let engagementRate: Double?

    // Trending
    let trendingScore: Double

    // Real-time
    let activeViewers: Int?

    // Timestamps
    let lastViewAt: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case totalViews = "total_views"
        case uniqueViews = "unique_views"
        case totalImpressions = "total_impressions"
        case totalFavorites = "total_favorites"
        case totalShares = "total_shares"
        case totalMessages = "total_messages"
        case totalClicks = "total_clicks"
        case galleryViews = "gallery_views"
        case contactClicks = "contact_clicks"
        case mapClicks = "map_clicks"
        case avgViewDuration = "avg_view_duration"
        case avgScrollDepth = "avg_scroll_depth"
        case clickThroughRate = "click_through_rate"
        case engagementRate = "engagement_rate"
        case trendingScore = "trending_score"
        case activeViewers = "active_viewers"
        case lastViewAt = "last_view_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties for display
    var formattedViewDuration: String {
        guard let duration = avgViewDuration else { return "N/A" }
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m \(seconds)s"
    }

    var formattedScrollDepth: String {
        guard let depth = avgScrollDepth else { return "N/A" }
        return String(format: "%.1f%%", depth)
    }

    var formattedCTR: String {
        guard let ctr = clickThroughRate else { return "N/A" }
        return String(format: "%.2f%%", ctr)
    }

    var formattedEngagementRate: String {
        guard let rate = engagementRate else { return "N/A" }
        return String(format: "%.2f%%", rate)
    }
}

// MARK: - View Event

struct PostViewEvent: Codable {
    let id: String
    let listingId: String
    let viewerId: String?
    let sessionId: String
    let isUniqueView: Bool

    // Context
    let source: String?
    let searchQuery: String?
    let referrerUrl: String?

    // Device
    let deviceType: String?
    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?

    // Location
    let country: String?
    let state: String?
    let city: String?

    // Engagement
    let viewDuration: Int?
    let scrollDepth: Double?
    let imagesViewed: Int
    let videoPlayed: Bool

    // Timestamps
    let viewedAt: String
    let exitAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case viewerId = "viewer_id"
        case sessionId = "session_id"
        case isUniqueView = "is_unique_view"
        case source
        case searchQuery = "search_query"
        case referrerUrl = "referrer_url"
        case deviceType = "device_type"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case appVersion = "app_version"
        case country
        case state
        case city
        case viewDuration = "view_duration"
        case scrollDepth = "scroll_depth"
        case imagesViewed = "images_viewed"
        case videoPlayed = "video_played"
        case viewedAt = "viewed_at"
        case exitAt = "exit_at"
    }
}

// MARK: - Engagement Analytics

struct EngagementAnalytics: Codable {
    let totalEngagement: Int
    let byType: [EngagementByType]

    enum CodingKeys: String, CodingKey {
        case totalEngagement = "total_engagement"
        case byType = "by_type"
    }
}

struct EngagementByType: Codable {
    let type: String
    let count: Int
}

// MARK: - Audience Demographics

struct AudienceDemographics: Codable {
    let byCountry: [CountryDemographic]
    let detailed: [DetailedDemographic]

    enum CodingKeys: String, CodingKey {
        case byCountry = "by_country"
        case detailed
    }
}

struct CountryDemographic: Codable {
    let country: String
    let viewCount: Int
    let uniqueViewers: Int
    let engagementCount: Int
    let cities: [CityDemographic]

    enum CodingKeys: String, CodingKey {
        case country
        case viewCount = "view_count"
        case uniqueViewers = "unique_viewers"
        case engagementCount = "engagement_count"
        case cities
    }
}

struct CityDemographic: Codable {
    let city: String
    let state: String?
    let viewCount: Int

    enum CodingKeys: String, CodingKey {
        case city
        case state
        case viewCount = "view_count"
    }
}

struct DetailedDemographic: Codable {
    let id: String
    let listingId: String
    let country: String
    let state: String?
    let city: String?
    let viewCount: Int
    let uniqueViewers: Int
    let engagementCount: Int
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case country
        case state
        case city
        case viewCount = "view_count"
        case uniqueViewers = "unique_viewers"
        case engagementCount = "engagement_count"
        case lastUpdated = "last_updated"
    }
}

// MARK: - Traffic Sources

struct TrafficSource: Codable {
    let id: String
    let listingId: String
    let source: String
    let views: Int
    let uniqueViews: Int
    let clicks: Int
    let conversions: Int
    let avgDuration: Double?
    let bounceRate: Double?
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case source
        case views
        case uniqueViews = "unique_views"
        case clicks
        case conversions
        case avgDuration = "avg_duration"
        case bounceRate = "bounce_rate"
        case lastUpdated = "last_updated"
    }

    var displayName: String {
        switch source {
        case "search": return "Search"
        case "direct": return "Direct"
        case "profile": return "Your Profile"
        case "featured": return "Featured"
        case "category": return "Category Browse"
        case "home_feed": return "Home Feed"
        case "external": return "External"
        default: return source.capitalized
        }
    }

    var iconName: String {
        switch source {
        case "search": return "magnifyingglass"
        case "direct": return "link"
        case "profile": return "person.circle"
        case "featured": return "star"
        case "category": return "square.grid.2x2"
        case "home_feed": return "house"
        case "external": return "arrow.up.forward.square"
        default: return "chart.bar"
        }
    }
}

// MARK: - Performance Time Series

struct HourlyMetrics: Codable {
    let id: String
    let listingId: String
    let hourTimestamp: String
    let views: Int
    let uniqueViews: Int
    let impressions: Int
    let clicks: Int
    let favorites: Int
    let shares: Int
    let messages: Int
    let avgDuration: Double?
    let avgScroll: Double?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case hourTimestamp = "hour_timestamp"
        case views
        case uniqueViews = "unique_views"
        case impressions
        case clicks
        case favorites
        case shares
        case messages
        case avgDuration = "avg_duration"
        case avgScroll = "avg_scroll"
        case createdAt = "created_at"
    }
}

struct DailyMetrics: Codable {
    let id: String
    let listingId: String
    let date: String
    let views: Int
    let uniqueViews: Int
    let impressions: Int
    let clicks: Int
    let favorites: Int
    let shares: Int
    let messages: Int
    let avgDuration: Double?
    let avgScroll: Double?
    let ctr: Double?
    let engagementRate: Double?
    let topSource: String?
    let topCountry: String?
    let topCity: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case date
        case views
        case uniqueViews = "unique_views"
        case impressions
        case clicks
        case favorites
        case shares
        case messages
        case avgDuration = "avg_duration"
        case avgScroll = "avg_scroll"
        case ctr
        case engagementRate = "engagement_rate"
        case topSource = "top_source"
        case topCountry = "top_country"
        case topCity = "top_city"
        case createdAt = "created_at"
    }
}

// MARK: - Search Performance

struct SearchPerformance: Codable {
    let totalImpressions: Int
    let totalClicks: Int
    let ctr: Double
    let avgPosition: Double?
    let topQueries: [SearchQuery]

    enum CodingKeys: String, CodingKey {
        case totalImpressions = "total_impressions"
        case totalClicks = "total_clicks"
        case ctr
        case avgPosition = "avg_position"
        case topQueries = "top_queries"
    }
}

struct SearchQuery: Codable {
    let query: String
    let count: Int
}

// MARK: - Comparisons

struct PostComparison: Codable {
    let thisPost: PostAnalyticsOverview?
    let averageOfOthers: AverageMetrics?
    let comparison: ComparisonMetrics

    enum CodingKeys: String, CodingKey {
        case thisPost = "this_post"
        case averageOfOthers = "average_of_others"
        case comparison
    }
}

struct CategoryComparison: Codable {
    let thisPost: PostAnalyticsOverview?
    let categoryAverage: AverageMetrics?
    let comparison: ComparisonMetrics

    enum CodingKeys: String, CodingKey {
        case thisPost = "this_post"
        case categoryAverage = "category_average"
        case comparison
    }
}

struct AverageMetrics: Codable {
    let totalViews: Double?
    let uniqueViews: Double?
    let totalFavorites: Double?
    let totalShares: Double?
    let totalMessages: Double?
    let engagementRate: Double?
    let clickThroughRate: Double?

    enum CodingKeys: String, CodingKey {
        case totalViews = "total_views"
        case uniqueViews = "unique_views"
        case totalFavorites = "total_favorites"
        case totalShares = "total_shares"
        case totalMessages = "total_messages"
        case engagementRate = "engagement_rate"
        case clickThroughRate = "click_through_rate"
    }
}

struct ComparisonMetrics: Codable {
    let viewsDiffPercent: Double
    let engagementDiffPercent: Double
    let ctrDiffPercent: Double?

    enum CodingKeys: String, CodingKey {
        case viewsDiffPercent = "views_diff_percent"
        case engagementDiffPercent = "engagement_diff_percent"
        case ctrDiffPercent = "ctr_diff_percent"
    }

    var viewsIndicator: String {
        if viewsDiffPercent > 0 {
            return "+\(String(format: "%.1f", viewsDiffPercent))%"
        } else {
            return "\(String(format: "%.1f", viewsDiffPercent))%"
        }
    }

    var engagementIndicator: String {
        if engagementDiffPercent > 0 {
            return "+\(String(format: "%.1f", engagementDiffPercent))%"
        } else {
            return "\(String(format: "%.1f", engagementDiffPercent))%"
        }
    }

    var isPerformingWell: Bool {
        return viewsDiffPercent > 0 && engagementDiffPercent > 0
    }
}

// MARK: - User Dashboard

struct AnalyticsDashboard: Codable {
    let posts: [DashboardPost]
    let totals: DashboardTotals
    let postCount: Int

    enum CodingKeys: String, CodingKey {
        case posts
        case totals
        case postCount = "post_count"
    }
}

struct DashboardPost: Codable {
    let listingId: String
    let title: String
    let createdAt: String?
    let analytics: PostAnalyticsOverview

    enum CodingKeys: String, CodingKey {
        case listingId = "listing_id"
        case title
        case createdAt = "created_at"
        case analytics
    }
}

struct DashboardTotals: Codable {
    let totalViews: Int?
    let uniqueViews: Int?
    let totalFavorites: Int?
    let totalShares: Int?
    let totalMessages: Int?

    enum CodingKeys: String, CodingKey {
        case totalViews = "total_views"
        case uniqueViews = "unique_views"
        case totalFavorites = "total_favorites"
        case totalShares = "total_shares"
        case totalMessages = "total_messages"
    }
}

// MARK: - Tracking Request Models

struct TrackViewRequest: Codable {
    let listingId: String
    let sessionId: String
    let source: String?
    let searchQuery: String?
    let referrerUrl: String?
    let deviceType: String
    let deviceModel: String?
    let osVersion: String
    let appVersion: String?
    let country: String?
    let state: String?
    let city: String?

    enum CodingKeys: String, CodingKey {
        case listingId
        case sessionId
        case source
        case searchQuery
        case referrerUrl
        case deviceType
        case deviceModel
        case osVersion
        case appVersion
        case country
        case state
        case city
    }
}

struct TrackViewEngagementRequest: Codable {
    let viewEventId: String
    let viewDuration: Int?
    let scrollDepth: Double?
    let imagesViewed: Int
    let videoPlayed: Bool

    enum CodingKeys: String, CodingKey {
        case viewEventId
        case viewDuration
        case scrollDepth
        case imagesViewed
        case videoPlayed
    }
}

struct TrackEngagementRequest: Codable {
    let listingId: String
    let eventType: String
    let sessionId: String?
    let source: String?
    let metadata: [String: String]?
    let deviceType: String?

    enum CodingKeys: String, CodingKey {
        case listingId
        case eventType
        case sessionId
        case source
        case metadata
        case deviceType
    }
}

// MARK: - Event Types

enum AnalyticsEventType: String {
    case favorite
    case unfavorite
    case share
    case contactClick = "contact_click"
    case messageClick = "message_click"
    case galleryClick = "gallery_click"
    case mapClick = "map_click"
    case phoneClick = "phone_click"
}

enum TrafficSourceType: String {
    case search
    case direct
    case profile
    case featured
    case category
    case homeFeed = "home_feed"
    case external
}
