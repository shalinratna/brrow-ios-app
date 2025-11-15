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
    // NEW BALANCE SYSTEM FIELDS (matches backend camelCase)
    let availableBalance: Double
    let pendingBalance: Double?
    let totalEarned: Double?
    let totalWithdrawn: Double?
    let hasStripeConnected: Bool?
    let canRequestPayout: Bool?

    // BACKEND LEGACY FIELDS (matches backend camelCase)
    let lifetimeEarnings: Double?
    let netEarnings: Double?
    let platformFees: Double?
    let pendingEarnings: Double?
    let activeEarnings: Double?
    let totalRentals: Int?
    let totalSales: Int?

    // COMPUTED PROPERTIES for backward compatibility with views
    var totalEarnings: Double { totalEarned ?? lifetimeEarnings ?? 0.0 }
    var pendingBalanceValue: Double { pendingBalance ?? 0.0 }
    var totalEarnedValue: Double { totalEarned ?? lifetimeEarnings ?? 0.0 }
    var totalWithdrawnValue: Double { totalWithdrawn ?? 0.0 }
    var hasStripeConnectedValue: Bool { hasStripeConnected ?? false }
    var canRequestPayoutValue: Bool { canRequestPayout ?? false }
    var monthlyEarningsValue: Double { 0.0 }  // Not sent by backend
    var earningsChangeValue: Double { 0.0 }   // Not sent by backend
    var itemsRentedValue: Int { totalRentals ?? 0 }
    var avgDailyEarningsValue: Double { 0.0 } // Not sent by backend
    var pendingPaymentsValue: Int { Int(pendingEarnings ?? 0) }
    var totalSalesValue: Int { totalSales ?? 0 }
    var platformFeesValue: Double { platformFees ?? 0.0 }

    // NO CodingKeys enum - Swift uses default camelCase matching backend
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