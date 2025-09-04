//
//  APIResponseFixes.swift
//  Brrow
//
//  Fixes for API response models to match actual server responses
//

import Foundation

// MARK: - Fixed Achievements Response
struct FixedAchievementsResponse: Codable {
    let success: Bool
    let message: String
    let data: FixedAchievementsData
    let timestamp: String
}

struct FixedAchievementsData: Codable {
    let userLevel: Int
    let progressToNext: Int
    let nextLevelRequirement: Int
    let statistics: AchievementStatistics
    let achievements: [FixedAchievement]
    let recentUnlocked: [FixedAchievement]
    
    enum CodingKeys: String, CodingKey {
        case userLevel = "user_level"
        case progressToNext = "progress_to_next"
        case nextLevelRequirement = "next_level_requirement"
        case statistics
        case achievements
        case recentUnlocked = "recent_unlocked"
    }
}

struct AchievementStatistics: Codable {
    let totalUnlocked: Int
    let easyUnlocked: Int
    let mediumUnlocked: Int
    let hardUnlocked: Int
    
    enum CodingKeys: String, CodingKey {
        case totalUnlocked = "total_unlocked"
        case easyUnlocked = "easy_unlocked"
        case mediumUnlocked = "medium_unlocked"
        case hardUnlocked = "hard_unlocked"
    }
}

struct FixedAchievement: Codable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let difficulty: String
    let points: Int
    let category: String
    let progress: Int
    let maxProgress: Int
    let unlockedAt: String?
    let isUnlocked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, difficulty, points, category, progress
        case maxProgress = "max_progress"
        case unlockedAt = "unlocked_at"
        case isUnlocked = "is_unlocked"
    }
}

// MARK: - Fixed Conversations Response
struct FixedConversationsResponse: Codable {
    let success: Bool
    let message: String
    let data: FixedConversationsData
    let timestamp: String
}

struct FixedConversationsData: Codable {
    let conversations: [Conversation]
    let unreadCount: Int
    let pagination: ConversationPagination
    
    enum CodingKeys: String, CodingKey {
        case conversations
        case unreadCount = "unread_count"
        case pagination
    }
}

struct ConversationPagination: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case total, limit, offset
        case hasMore = "has_more"
    }
}

// MARK: - Fixed Earnings Chart Response
struct FixedEarningsChartResponse: Codable {
    let success: Bool
    let message: String
    let data: FixedEarningsChartData
    let timestamp: String
}

struct FixedEarningsChartData: Codable {
    let chart: FixedChartData
    let summary: EarningsSummary
    let periodInfo: PeriodInfo
    
    enum CodingKeys: String, CodingKey {
        case chart, summary
        case periodInfo = "period_info"
    }
}

struct FixedChartData: Codable {
    let labels: [String]
    let datasets: [ChartDataset]
}

struct ChartDataset: Codable {
    let label: String
    let data: [Double]
    let color: String
}

struct EarningsSummary: Codable {
    let totalEarnings: Double
    let totalSpending: Double
    let netEarnings: Double
    let platformFees: Double
    let totalRentals: Int
    let averagePerRental: Double
    
    enum CodingKeys: String, CodingKey {
        case totalEarnings = "total_earnings"
        case totalSpending = "total_spending"
        case netEarnings = "net_earnings"
        case platformFees = "platform_fees"
        case totalRentals = "total_rentals"
        case averagePerRental = "average_per_rental"
    }
}

struct PeriodInfo: Codable {
    let period: String
    let rangeDays: Int
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case period
        case rangeDays = "range_days"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

// MARK: - Fixed Earnings Overview Response
struct FixedEarningsOverviewResponse: Codable {
    let success: Bool
    let message: String
    let data: FixedEarningsOverviewData
    let timestamp: String
}

struct FixedEarningsOverviewData: Codable {
    let overview: FixedEarningsOverview
    let monthlyEarnings: [FixedMonthlyEarning]
    let topListings: [TopListing]
    let payoutInfo: PayoutInfo
    
    enum CodingKeys: String, CodingKey {
        case overview
        case monthlyEarnings = "monthly_earnings"
        case topListings = "top_listings"
        case payoutInfo = "payout_info"
    }
}

struct FixedEarningsOverview: Codable {
    let lifetimeEarnings: Double?
    let lifetimeSpent: Double?
    let netEarnings: Double?
    let platformFees: Double?
    let pendingEarnings: Double?
    let activeEarnings: Double?
    let totalRentals: Int?
    let totalBorrowings: Int?
    let averageRentalValue: Double?
    
    enum CodingKeys: String, CodingKey {
        case lifetimeEarnings = "lifetimeEarnings"  // Try both camelCase
        case lifetimeSpent = "lifetimeSpent"
        case netEarnings = "netEarnings"
        case platformFees = "platformFees"
        case pendingEarnings = "pendingEarnings"
        case activeEarnings = "activeEarnings"
        case totalRentals = "totalRentals"
        case totalBorrowings = "totalBorrowings"
        case averageRentalValue = "averageRentalValue"
    }
}

struct FixedMonthlyEarning: Codable {
    // Add properties as needed
}

struct TopListing: Codable {
    // Add properties as needed
}

struct PayoutInfo: Codable {
    let availableBalance: Double
    let nextPayoutDate: String
    let minimumPayout: Double
    let payoutMethod: String
    
    enum CodingKeys: String, CodingKey {
        case availableBalance = "available_balance"
        case nextPayoutDate = "next_payout_date"
        case minimumPayout = "minimum_payout"
        case payoutMethod = "payout_method"
    }
}