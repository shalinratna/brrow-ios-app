//
//  ProfileModels.swift
//  Brrow
//
//  Profile related data models
//

import Foundation

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
    let type: ActivityType
    let title: String
    let description: String
    let amount: String?
    let createdAt: String
    let timeAgo: String
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, description, amount
        case createdAt = "created_at"
        case timeAgo = "time_ago"
    }
    
    enum ActivityType: String, Codable {
        case borrowed = "borrowed"
        case lent = "lent"
        case earned = "earned"
        case reviewed = "reviewed"
        case listed = "listed"
    }
}

// MARK: - Profile View Models
struct ProfileStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
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

struct ActivityStat: Identifiable {
    let id = UUID()
    let day: String
    let count: Int
}