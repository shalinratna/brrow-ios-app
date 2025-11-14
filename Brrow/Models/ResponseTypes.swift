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
    // NEW BALANCE SYSTEM FIELDS
    let availableBalance: Double
    let pendingBalance: Double?
    let totalEarned: Double?
    let totalWithdrawn: Double?
    let hasStripeConnected: Bool?
    let canRequestPayout: Bool?

    // LEGACY FIELDS (for compatibility)
    let totalEarnings: Double
    let pendingEarnings: Double?
    let lastPayout: String?
    let monthlyEarnings: Double?
    let earningsChange: Double?
    let itemsRented: Int?
    let avgDailyEarnings: Double?
    let pendingPayments: Int?
    let totalSales: Int?
    let platformFees: Double?

    enum CodingKeys: String, CodingKey {
        case availableBalance = "available_balance"
        case pendingBalance = "pending_balance"
        case totalEarned = "total_earned"
        case totalWithdrawn = "total_withdrawn"
        case hasStripeConnected = "has_stripe_connected"
        case canRequestPayout = "can_request_payout"
        case totalEarnings = "total_earnings"
        case pendingEarnings = "pending_earnings"
        case lastPayout = "last_payout"
        case monthlyEarnings = "monthly_earnings"
        case earningsChange = "earnings_change"
        case itemsRented = "items_rented"
        case avgDailyEarnings = "avg_daily_earnings"
        case pendingPayments = "pending_payments"
        case totalSales = "total_sales"
        case platformFees = "platform_fees"
    }

    // Provide default values for optional fields
    var pendingBalanceValue: Double { pendingBalance ?? 0.0 }
    var totalEarnedValue: Double { totalEarned ?? totalEarnings }
    var totalWithdrawnValue: Double { totalWithdrawn ?? 0.0 }
    var hasStripeConnectedValue: Bool { hasStripeConnected ?? false }
    var canRequestPayoutValue: Bool { canRequestPayout ?? false }
    var monthlyEarningsValue: Double { monthlyEarnings ?? 0.0 }
    var earningsChangeValue: Double { earningsChange ?? 0.0 }
    var itemsRentedValue: Int { itemsRented ?? 0 }
    var avgDailyEarningsValue: Double { avgDailyEarnings ?? 0.0 }
    var pendingPaymentsValue: Int { pendingPayments ?? 0 }
    var totalSalesValue: Int { totalSales ?? 0 }
    var platformFeesValue: Double { platformFees ?? 0.0 }
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