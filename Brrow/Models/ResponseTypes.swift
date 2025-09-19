//
//  ResponseTypes.swift
//  Brrow
//
//  Consolidated API response types
//

import Foundation

// MARK: - User Profile Response
struct UserProfileResponse: Codable {
    let success: Bool
    let user: User?  // Some endpoints return user directly
    let profile: UserProfileData? // Some return profile with nested data
    let stats: UserStats?
    let message: String?

    // Handle both response formats
    var actualUser: User? {
        if let user = user {
            return user
        }
        // Convert profile data to User if needed
        if let profile = profile {
            return User(
                id: profile.apiId,
                username: profile.username,
                email: profile.email,
                apiId: profile.apiId
            )
        }
        return nil
    }
}

struct UserProfileData: Codable {
    let id: Int
    let apiId: String
    let username: String
    let email: String
    let firstName: String?
    let lastName: String?
    let bio: String?
    let phone: String?
    let location: String?
    let verified: Bool?
    let profilePicture: String?

    enum CodingKeys: String, CodingKey {
        case id
        case apiId = "api_id"
        case username
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
        case phone
        case location
        case verified
        case profilePicture = "profile_picture"
    }
}

// MARK: - Listing Detail Response
struct ListingDetailResponse: Codable {
    let success: Bool
    let listing: Listing
    let message: String?
}


// MARK: - Categories Response
struct CategoriesResponse: Codable {
    let success: Bool
    let categories: [APICategory]
}

// MARK: - Earnings Overview
struct EarningsOverview: Codable {
    let totalEarnings: Double
    let pendingEarnings: Double?
    let availableBalance: Double
    let lastPayout: String?
    let monthlyEarnings: Double?
    let earningsChange: Double?
    let itemsRented: Int?
    let avgDailyEarnings: Double?
    let pendingPayments: Int?

    enum CodingKeys: String, CodingKey {
        case totalEarnings = "total_earnings"
        case pendingEarnings = "pending_earnings"
        case availableBalance = "available_balance"
        case lastPayout = "last_payout"
        case monthlyEarnings = "monthly_earnings"
        case earningsChange = "earnings_change"
        case itemsRented = "items_rented"
        case avgDailyEarnings = "avg_daily_earnings"
        case pendingPayments = "pending_payments"
    }

    // Provide default values for optional fields
    var monthlyEarningsValue: Double { monthlyEarnings ?? 0.0 }
    var earningsChangeValue: Double { earningsChange ?? 0.0 }
    var itemsRentedValue: Int { itemsRented ?? 0 }
    var avgDailyEarningsValue: Double { avgDailyEarnings ?? 0.0 }
    var pendingPaymentsValue: Int { pendingPayments ?? 0 }
}

// MARK: - Conversations Response
struct ConversationsResponse: Codable {
    let success: Bool?
    let conversations: [Conversation]?
    let data: ConversationsData?
    let message: String?

    // Handle both response formats
    var allConversations: [Conversation] {
        return conversations ?? data?.conversations ?? []
    }
}

struct ConversationsData: Codable {
    let conversations: [Conversation]
    let pagination: PaginationInfo?
}