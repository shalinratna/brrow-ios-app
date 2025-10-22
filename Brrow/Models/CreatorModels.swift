//
//  CreatorModels.swift
//  Brrow
//
//  Creator dashboard and analytics models
//

import Foundation

// MARK: - Creator Dashboard Models

struct CreatorDashboard: Codable {
    let overview: CreatorOverview
    let analytics: CreatorAnalytics
    let earnings: EarningsData
    let listings: CreatorListingsData
    let bookings: CreatorBookingsData
    let reviews: CreatorReviewsData
    let growth: GrowthMetrics
    let insights: [CreatorInsight]
}

struct CreatorOverview: Codable {
    let totalEarnings: Double
    let totalBookings: Int
    let activeListings: Int
    let averageRating: Double
    let totalReviews: Int
    let responseRate: Double
    let completionRate: Double
    let joinedDate: String
    let isVerified: Bool
    let badgesEarned: [CreatorBadge]
    let currentRank: CreatorRank
}

struct CreatorAnalytics: Codable {
    let viewsData: AnalyticsTimeSeries
    let bookingsData: AnalyticsTimeSeries
    let earningsData: AnalyticsTimeSeries
    let topPerformingListings: [ListingPerformance]
    let categoryBreakdown: [CategoryPerformance]
    let locationInsights: LocationAnalytics
    let seasonalTrends: [SeasonalTrend]
    let competitorComparison: CompetitorAnalytics?
}

struct AnalyticsTimeSeries: Codable {
    let period: TimePeriod
    let dataPoints: [DataPoint]
    let total: Double
    let growth: Double
    let trend: TrendDirection

    struct DataPoint: Codable, Identifiable {
        let id = UUID()
        let date: String
        let value: Double
        let label: String?

        enum CodingKeys: String, CodingKey {
            case date, value, label
        }
    }
}

enum TimePeriod: String, Codable, CaseIterable {
    case week = "7d"
    case month = "30d"
    case quarter = "90d"
    case year = "1y"

    var displayName: String {
        switch self {
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .quarter: return "Last 3 Months"
        case .year: return "Last Year"
        }
    }
}

enum TrendDirection: String, Codable {
    case up = "UP"
    case down = "DOWN"
    case stable = "STABLE"

    var color: String {
        switch self {
        case .up: return "green"
        case .down: return "red"
        case .stable: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

// MARK: - Earnings Models

struct EarningsData: Codable {
    let currentBalance: Double
    let pendingEarnings: Double
    let totalLifetimeEarnings: Double
    let thisMonthEarnings: Double
    let lastMonthEarnings: Double
    let payoutSchedule: PayoutSchedule
    let recentTransactions: [EarningsTransaction]
    let taxDocuments: [TaxDocument]
    let paymentMethods: [PaymentMethod]
    let growthRate: Double
}

struct PayoutSchedule: Codable {
    let frequency: PayoutFrequency
    let nextPayoutDate: String
    let minimumThreshold: Double
    let currency: String
}

enum PayoutFrequency: String, Codable {
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case instant = "INSTANT"

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .instant: return "Instant"
        }
    }
}

struct EarningsTransaction: Identifiable {
    let id: String
    let bookingId: String
    let amount: Double
    let type: CreatorModels.TransactionType
    let status: EarningsTransactionStatus
    let date: String
    let description: String
    let listingTitle: String?
    let renterName: String?
    let itemImageUrl: String?

    // Computed property for date conversion
    var transactionDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }
}

// Add Codable conformance manually to avoid ambiguity
extension EarningsTransaction: Codable {
    enum CodingKeys: String, CodingKey {
        case id, bookingId, amount, type, status, date, description
        case listingTitle, renterName, itemImageUrl
    }
}

// Namespace the TransactionType within CreatorModels to avoid ambiguity
extension CreatorModels {
    enum TransactionType: String, Codable {
        case rental = "RENTAL"
        case sale = "SALE"
        case fee = "FEE"
        case refund = "REFUND"
        case bonus = "BONUS"

        var displayName: String {
            switch self {
            case .rental: return "Rental"
            case .sale: return "Sale"
            case .fee: return "Fee"
            case .refund: return "Refund"
            case .bonus: return "Bonus"
            }
        }
    }
}

// Add a namespace struct for CreatorModels types
struct CreatorModels {}

enum EarningsTransactionStatus: String, Codable {
    case pending = "PENDING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case refunded = "REFUNDED"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .refunded: return "Refunded"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .completed: return "green"
        case .failed: return "red"
        case .refunded: return "gray"
        }
    }
}

// MARK: - Performance Models

struct ListingPerformance: Codable, Identifiable {
    let id: String
    let listingId: String
    let title: String
    let views: Int
    let bookings: Int
    let earnings: Double
    let rating: Double
    let conversionRate: Double
    let imageUrl: String?
    let category: String
    let trend: TrendDirection
}

struct CategoryPerformance: Codable, Identifiable {
    let id = UUID()
    let category: String
    let listings: Int
    let bookings: Int
    let earnings: Double
    let averageRating: Double
    let demandScore: Double

    enum CodingKeys: String, CodingKey {
        case category, listings, bookings, earnings, averageRating, demandScore
    }
}

struct LocationAnalytics: Codable {
    let topCities: [CityPerformance]
    let reachRadius: Double
    let mostPopularPickupLocation: String?
    let deliverySuccess: Double
}

struct CityPerformance: Codable, Identifiable {
    let id = UUID()
    let city: String
    let bookings: Int
    let earnings: Double
    let averageDistance: Double

    enum CodingKeys: String, CodingKey {
        case city, bookings, earnings, averageDistance
    }
}

struct SeasonalTrend: Codable, Identifiable {
    let id = UUID()
    let month: String
    let bookings: Int
    let earnings: Double
    let topCategory: String
    let demand: Double

    enum CodingKeys: String, CodingKey {
        case month, bookings, earnings, topCategory, demand
    }
}

struct CompetitorAnalytics: Codable {
    let averagePrice: Double
    let marketShare: Double
    let pricePosition: PricePosition
    let suggestionScore: Double
}

enum PricePosition: String, Codable {
    case below = "BELOW"
    case competitive = "COMPETITIVE"
    case above = "ABOVE"

    var displayName: String {
        switch self {
        case .below: return "Below Market"
        case .competitive: return "Competitive"
        case .above: return "Above Market"
        }
    }
}

// MARK: - Creator Rankings & Badges

struct CreatorRank: Codable {
    let level: RankLevel
    let points: Int
    let nextLevelPoints: Int
    let benefits: [RankBenefit]
    let progress: Double
}

enum RankLevel: String, Codable {
    case bronze = "BRONZE"
    case silver = "SILVER"
    case gold = "GOLD"
    case platinum = "PLATINUM"
    case diamond = "DIAMOND"

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        }
    }

    var color: String {
        switch self {
        case .bronze: return "brown"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "purple"
        case .diamond: return "blue"
        }
    }

    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "medal.fill"
        case .platinum: return "crown.fill"
        case .diamond: return "diamond.fill"
        }
    }
}

struct RankBenefit: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case title, description, isActive
    }
}

struct CreatorBadge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let earnedDate: String
    let category: BadgeCategory
}

enum BadgeCategory: String, Codable {
    case quality = "QUALITY"
    case volume = "VOLUME"
    case service = "SERVICE"
    case special = "SPECIAL"

    var displayName: String {
        switch self {
        case .quality: return "Quality"
        case .volume: return "Volume"
        case .service: return "Service"
        case .special: return "Special"
        }
    }
}

// MARK: - Creator Insights

struct CreatorInsight: Codable, Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let impact: ImpactLevel
    let actionRequired: Bool
    let actionText: String?
    let data: InsightData?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case type, title, description, impact, actionRequired, actionText, data, createdAt
    }
}

enum InsightType: String, Codable {
    case pricing = "PRICING"
    case demand = "DEMAND"
    case competition = "COMPETITION"
    case optimization = "OPTIMIZATION"
    case opportunity = "OPPORTUNITY"

    var icon: String {
        switch self {
        case .pricing: return "dollarsign.circle"
        case .demand: return "chart.line.uptrend.xyaxis"
        case .competition: return "person.2.circle"
        case .optimization: return "gear.circle"
        case .opportunity: return "lightbulb.circle"
        }
    }
}

enum ImpactLevel: String, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

struct InsightData: Codable {
    let currentValue: Double?
    let suggestedValue: Double?
    let potentialIncrease: Double?
    let confidence: Double?
}

// MARK: - Creator Listings Data

struct CreatorListingsData: Codable {
    let totalListings: Int
    let activeListings: Int
    let draftListings: Int
    let pausedListings: Int
    let totalViews: Int
    let averageViewsPerListing: Double
    let conversionRate: Double
    let topCategories: [String]
    let performanceBreakdown: [ListingPerformance]
}

// MARK: - Creator Bookings Data

struct CreatorBookingsData: Codable {
    let totalBookings: Int
    let upcomingBookings: Int
    let activeBookings: Int
    let completedBookings: Int
    let cancelledBookings: Int
    let averageBookingValue: Double
    let repeatCustomerRate: Double
    let popularDays: [String]
    let averageRentalDuration: Double
}

// MARK: - Creator Reviews Data

struct CreatorReviewsData: Codable {
    let totalReviews: Int
    let averageRating: Double
    let ratingDistribution: [RatingCount]
    let recentReviews: [Review]
    let responseRate: Double
    let positiveKeywords: [String]
    let improvementAreas: [String]
}

struct RatingCount: Codable, Identifiable {
    let id = UUID()
    let rating: Int
    let count: Int
    let percentage: Double

    enum CodingKeys: String, CodingKey {
        case rating, count, percentage
    }
}

// MARK: - Growth Metrics

struct GrowthMetrics: Codable {
    let monthOverMonthGrowth: GrowthData
    let quarterOverQuarterGrowth: GrowthData
    let yearOverYearGrowth: GrowthData
    let projectedEarnings: ProjectedEarnings
    let marketPosition: MarketPosition
}

struct GrowthData: Codable {
    let earnings: Double
    let bookings: Double
    let views: Double
    let rating: Double
}

struct ProjectedEarnings: Codable {
    let nextMonth: Double
    let nextQuarter: Double
    let nextYear: Double
    let confidence: Double
}

struct MarketPosition: Codable {
    let rankInCategory: Int
    let totalInCategory: Int
    let rankInLocation: Int
    let totalInLocation: Int
    let percentile: Double
}

// MARK: - API Request/Response Models

struct CreatorDashboardRequest: Codable {
    let period: TimePeriod
    let includeComparison: Bool
    let includeInsights: Bool
}

struct CreatorAnalyticsResponse: Codable {
    let success: Bool
    let data: CreatorDashboard?
    let message: String?
}

struct UpdateCreatorSettingsRequest: Codable {
    let payoutFrequency: PayoutFrequency?
    let notificationPreferences: CreatorNotificationPreferences?
    let profileSettings: CreatorProfileSettings?
}

struct CreatorNotificationPreferences: Codable {
    var newBooking: Bool
    var paymentReceived: Bool
    var newReview: Bool
    var weeklyReport: Bool
    var monthlyReport: Bool
    var marketingUpdates: Bool
}

struct CreatorProfileSettings: Codable {
    var isPublic: Bool
    var showEarnings: Bool
    var showBadges: Bool
    var autoAcceptBookings: Bool
    var minimumNotice: Int
}

// MARK: - Tax Documents

struct TaxDocument: Codable, Identifiable {
    let id: String
    let year: Int
    let type: TaxDocumentType
    let amount: Double
    let downloadUrl: String
    let generatedAt: String
}

enum TaxDocumentType: String, Codable {
    case form1099 = "FORM_1099"
    case summary = "SUMMARY"
    case quarterly = "QUARTERLY"

    var displayName: String {
        switch self {
        case .form1099: return "Form 1099"
        case .summary: return "Annual Summary"
        case .quarterly: return "Quarterly Report"
        }
    }
}

// MARK: - Payment Methods

struct PaymentMethod: Codable, Identifiable {
    let id: String
    let type: PaymentMethodType
    let displayName: String
    let isDefault: Bool
    let lastFour: String?
    let expiryDate: String?
    let isVerified: Bool
}

enum PaymentMethodType: String, Codable {
    case bankAccount = "BANK_ACCOUNT"
    case paypal = "PAYPAL"
    case stripe = "STRIPE"
    case venmo = "VENMO"

    var displayName: String {
        switch self {
        case .bankAccount: return "Bank Account"
        case .paypal: return "PayPal"
        case .stripe: return "Stripe"
        case .venmo: return "Venmo"
        }
    }

    var icon: String {
        switch self {
        case .bankAccount: return "building.columns"
        case .paypal: return "creditcard"
        case .stripe: return "creditcard"
        case .venmo: return "dollarsign.circle"
        }
    }
}

// MARK: - Creator Application Request
struct CreatorApplicationRequest: Codable {
    let motivation: String
    let experience: String
    let businessName: String?
    let businessDescription: String?
    let experienceYears: Int
    let portfolioLinks: [String]
    let expectedMonthlyRevenue: Double?
    let agreedToTerms: Bool
}

// MARK: - Creator Application Response
struct CreatorApplicationResponse: Codable {
    let success: Bool
    let data: CreatorApplication?
    let message: String?
    let canApply: Bool?
    let hasApplication: Bool?

    var application: CreatorApplication? {
        return data
    }

    struct CreatorApplication: Codable {
        let id: String
        let status: ApplicationStatus
        let submittedAt: String
        let reviewedAt: String?
        let reviewNotes: String?
        let rejectionReason: String?

        enum ApplicationStatus: String, Codable {
            case pending = "PENDING"
            case approved = "APPROVED"
            case rejected = "REJECTED"
            case underReview = "UNDER_REVIEW"
        }
    }
}

