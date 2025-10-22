//
//  ProfileModels.swift
//  Brrow
//
//  Profile related data models
//

import Foundation
import SwiftUI  // CRITICAL: Required for Color type used in UserActivity and ProfileStat

// UserProfileResponse and UserProfileData moved to ResponseTypes.swift

// Keeping original UserProfileData for reference
struct LegacyUserProfileData: Codable {
    let id: Int
    let apiId: String
    let username: String
    let email: String
    let profilePicture: String?
    let bio: String
    let location: String
    let website: String?
    let createdAt: String
    let listerRating: Double
    let renteeRating: Double
    let verified: Bool
    let stripeLinked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, bio, location, website, verified
        case apiId = "api_id"
        case profilePicture = "profile_picture"
        case createdAt = "created_at"
        case listerRating = "lister_rating"
        case renteeRating = "rentee_rating"
        case stripeLinked = "stripe_linked"
    }
}

struct UserStats: Codable {
    let totalListings: Int
    let totalTransactions: Int
    let totalReviews: Int
    let itemsLent: Int
    let itemsBorrowed: Int
    let totalEarnings: Double
    
    enum CodingKeys: String, CodingKey {
        case totalListings = "total_listings"
        case totalTransactions = "total_transactions"
        case totalReviews = "total_reviews"
        case itemsLent = "items_lent"
        case itemsBorrowed = "items_borrowed"
        case totalEarnings = "total_earnings"
    }
}

// MARK: - Activities Response
struct ActivitiesResponse: Codable {
    let success: Bool
    let activities: [UserActivity]
}

struct UserActivity: Codable, Identifiable {
    let id: String
    let type: ActivityType?       // Made optional for local activities
    let icon: String?             // NEW: SF Symbol icon name (for local-only activities)
    let title: String
    let subtitle: String?         // NEW: Renamed from "description" for clarity
    let description: String?      // Keep for backwards compatibility with API
    let amount: String?
    let createdAt: String?        // Made optional for local activities
    let timeAgo: String
    let color: Color?             // NEW: Custom color (for local-only activities)

    enum CodingKeys: String, CodingKey {
        case id, type, title, description, amount
        case createdAt = "created_at"
        case timeAgo = "time_ago"
        // icon, subtitle, and color are NOT decoded from API (local only)
    }

    enum ActivityType: String, Codable {
        case borrowed = "borrowed"
        case lent = "lent"
        case earned = "earned"
        case reviewed = "reviewed"
        case listed = "listed"
    }

    // Computed property: use subtitle if available, otherwise description
    var displaySubtitle: String {
        return subtitle ?? description ?? ""
    }

    // Custom initializer for local activities (UniversalProfileViewModel)
    init(id: String, icon: String, title: String, subtitle: String, timeAgo: String, color: Color) {
        self.id = id
        self.type = nil
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.description = nil
        self.amount = nil
        self.createdAt = nil
        self.timeAgo = timeAgo
        self.color = color
    }

    // Decoder for API responses
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decodeIfPresent(ActivityType.self, forKey: .type)
        icon = nil  // Not from API
        title = try container.decode(String.self, forKey: .title)
        subtitle = nil  // Not from API
        description = try container.decodeIfPresent(String.self, forKey: .description)
        amount = try container.decodeIfPresent(String.self, forKey: .amount)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        timeAgo = try container.decode(String.self, forKey: .timeAgo)
        color = nil  // Not from API
    }
}

// MARK: - Profile View Models
struct ProfileStat: Identifiable {
    let id = UUID()
    let icon: String?          // NEW: SF Symbol icon name
    let title: String
    let value: String
    let color: Color?          // NEW: Custom color for icon/badge
    let trend: String?         // NEW: "up", "down", "neutral" for trend indicator

    // Convenience initializer for simple stats without icon/color/trend
    init(title: String, value: String) {
        self.icon = nil
        self.title = title
        self.value = value
        self.color = nil
        self.trend = nil
    }

    // Full initializer with all properties
    init(icon: String?, title: String, value: String, color: Color?, trend: String?) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.trend = trend
    }
}

struct UserProfile {
    let bio: String
    let joinDate: Date
    let location: String
    let website: String?
}

struct UserReview: Identifiable {
    let id: String
    let reviewerName: String
    let reviewerAvatar: String?
    let rating: Int
    let comment: String
    let date: Date
    let listingTitle: String
}

// Social profile review variant
struct SocialUserReview: Codable, Identifiable {
    let id: String
    let reviewerName: String
    let reviewerProfilePicture: String
    let rating: Int
    let comment: String
    let timeAgo: String
}

struct MonthlyEarning: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

// NEW: Monthly data for charts (earnings + rentals)
struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let earnings: Double
    let rentals: Int
}

struct ActivityStat: Identifiable {
    let id = UUID()
    let label: String   // Changed from "day" to "label" for more flexibility
    let value: Int      // Changed from "count" to "value" for consistency
    let trend: String?  // NEW: "up", "down", "neutral" for trend indicator

    // Convenience initializer for simple stats without trend
    init(label: String, value: Int) {
        self.label = label
        self.value = value
        self.trend = nil
    }

    // Full initializer with trend
    init(label: String, value: Int, trend: String) {
        self.label = label
        self.value = value
        self.trend = trend
    }

    // Legacy initializer for backwards compatibility
    init(day: String, count: Int) {
        self.label = day
        self.value = count
        self.trend = nil
    }
}