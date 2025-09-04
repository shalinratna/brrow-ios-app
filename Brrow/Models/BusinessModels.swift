import Foundation

// MARK: - Business Account Models

struct BusinessAccountResponse: Codable {
    let success: Bool
    let businessAccount: BusinessAccount?
    let analyticsSummary: BusinessAnalyticsSummary?
    let inventorySummary: InventorySummary?
    
    enum CodingKeys: String, CodingKey {
        case success
        case businessAccount = "business_account"
        case analyticsSummary = "analytics_summary"
        case inventorySummary = "inventory_summary"
    }
}

struct BusinessAccount: Codable {
    let id: Int
    let businessName: String
    let legalName: String?
    let businessType: String
    let taxId: String?
    let dunsNumber: String?
    let businessEmail: String?
    let businessPhone: String?
    let businessAddress: BusinessAddress?
    let website: String?
    let description: String?
    let logoUrl: String?
    let verificationStatus: String
    let verifiedAt: Date?
    let totalListings: Int
    let totalInventoryItems: Int
    let subscriptionType: String?
    let subscriptionStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case businessName = "business_name"
        case legalName = "legal_name"
        case businessType = "business_type"
        case taxId = "tax_id"
        case dunsNumber = "duns_number"
        case businessEmail = "business_email"
        case businessPhone = "business_phone"
        case businessAddress = "business_address"
        case website
        case description
        case logoUrl = "logo_url"
        case verificationStatus = "verification_status"
        case verifiedAt = "verified_at"
        case totalListings = "total_listings"
        case totalInventoryItems = "total_inventory_items"
        case subscriptionType = "subscription_type"
        case subscriptionStatus = "subscription_status"
    }
}

struct BusinessAddress: Codable {
    let street: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case street
        case city
        case state
        case zipCode = "zip_code"
        case country
    }
}

struct BusinessAnalyticsSummary: Codable {
    let revenue: MetricSummary?
    let bookings: MetricSummary?
    let views: MetricSummary?
    let conversion: MetricSummary?
}

struct MetricSummary: Codable {
    let total: Double
    let average: Double
    let peak: Double
    let dataPoints: Int
    
    enum CodingKeys: String, CodingKey {
        case total
        case average
        case peak
        case dataPoints = "data_points"
    }
}

struct InventorySummary: Codable {
    let totalItems: Int
    let categories: Int
    let totalQuantity: Int
    let avgDailyPrice: Double?
    let activeItems: Int
    
    enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case categories
        case totalQuantity = "total_quantity"
        case avgDailyPrice = "avg_daily_price"
        case activeItems = "active_items"
    }
}

// MARK: - Subscription Models

struct BusinessSubscriptionResponse: Codable {
    let success: Bool
    let currentSubscription: BusinessCurrentSubscription?
    let availablePlans: [BusinessSubscriptionPlan]?
    let benefits: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case success
        case currentSubscription = "current_subscription"
        case availablePlans = "available_plans"
        case benefits
    }
}

struct BusinessCurrentSubscription: Codable {
    let id: String
    let type: String
    let planName: String
    let price: Double
    let status: String
    let nextBillingDate: Date?
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case type = "subscription_type"
        case planName = "plan_name"
        case price
        case status
        case nextBillingDate = "next_billing_date"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
    }
}

struct BusinessSubscriptionPlan: Codable {
    let id: String
    let name: String
    let price: Double
    let features: [String]
}

// MARK: - Fleet Management Models

struct FleetDashboardResponse: Codable {
    let success: Bool
    let dashboard: FleetDashboard
}

struct FleetDashboard: Codable {
    let overview: FleetOverview
    let todayBookings: [FleetBooking]
    let upcomingReturns: [FleetReturn]
    let lowAvailabilityItems: [FleetInventoryItem]
    let revenueSummary: RevenueSummary
    let performanceMetrics: PerformanceMetrics
    
    enum CodingKeys: String, CodingKey {
        case overview
        case todayBookings = "today_bookings"
        case upcomingReturns = "upcoming_returns"
        case lowAvailabilityItems = "low_availability_items"
        case revenueSummary = "revenue_summary"
        case performanceMetrics = "performance_metrics"
    }
}

struct FleetOverview: Codable {
    let totalItems: Int
    let totalUnits: Int
    let categories: Int
    let utilizationRate: Double
    
    enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case totalUnits = "total_units"
        case categories
        case utilizationRate = "utilization_rate"
    }
}

struct FleetInventoryItem: Codable {
    let id: Int
    let sku: String
    let itemName: String
    let category: String
    let description: String?
    let quantity: Int
    let basePriceDaily: Double
    let basePriceWeekly: Double?
    let basePriceMonthly: Double?
    let images: [String]
    let specifications: [String: String]?
    let condition: String
    let location: String?
    let isActive: Bool
    let activeBookings: Int?
    let availableToday: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case itemName = "item_name"
        case category
        case description
        case quantity
        case basePriceDaily = "base_price_daily"
        case basePriceWeekly = "base_price_weekly"
        case basePriceMonthly = "base_price_monthly"
        case images
        case specifications
        case condition
        case location
        case isActive = "is_active"
        case activeBookings = "active_bookings"
        case availableToday = "available_today"
    }
}

struct FleetBooking: Codable {
    let id: Int
    let itemName: String
    let customerName: String
    let startDate: Date
    let endDate: Date
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemName = "item_name"
        case customerName = "customer_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case status
    }
}

struct FleetReturn: Codable {
    let id: Int
    let itemName: String
    let customerName: String
    let returnDate: Date
    let daysOverdue: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemName = "item_name"
        case customerName = "customer_name"
        case returnDate = "return_date"
        case daysOverdue = "days_overdue"
    }
}

struct RevenueSummary: Codable {
    let todayRevenue: Double
    let weekRevenue: Double
    let monthRevenue: Double
    let yearRevenue: Double
    
    enum CodingKeys: String, CodingKey {
        case todayRevenue = "today_revenue"
        case weekRevenue = "week_revenue"
        case monthRevenue = "month_revenue"
        case yearRevenue = "year_revenue"
    }
}

struct PerformanceMetrics: Codable {
    let avgBookingDuration: Double
    let returnRate: Double
    let customerSatisfaction: Double
    let topPerformingCategory: String?
    
    enum CodingKeys: String, CodingKey {
        case avgBookingDuration = "avg_booking_duration"
        case returnRate = "return_rate"
        case customerSatisfaction = "customer_satisfaction"
        case topPerformingCategory = "top_performing_category"
    }
}

struct FleetAnalyticsResponse: Codable {
    let success: Bool
    let analytics: FleetAnalytics
}

struct FleetAnalytics: Codable {
    let revenueBreakdown: [RevenueDataPoint]
    let utilizationRates: [UtilizationData]
    let popularItems: [PopularItem]
    let customerInsights: CustomerInsights
    let seasonalTrends: [SeasonalTrend]
    let forecast: RevenueForecast
    
    enum CodingKeys: String, CodingKey {
        case revenueBreakdown = "revenue_breakdown"
        case utilizationRates = "utilization_rates"
        case popularItems = "popular_items"
        case customerInsights = "customer_insights"
        case seasonalTrends = "seasonal_trends"
        case forecast
    }
}

struct RevenueDataPoint: Codable {
    let date: Date
    let revenue: Double
    let bookings: Int
}

struct UtilizationData: Codable {
    let category: String
    let utilizationRate: Double
    let trend: String
    
    enum CodingKeys: String, CodingKey {
        case category
        case utilizationRate = "utilization_rate"
        case trend
    }
}

struct PopularItem: Codable {
    let itemName: String
    let bookingCount: Int
    let revenue: Double
    let rating: Double
    
    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case bookingCount = "booking_count"
        case revenue
        case rating
    }
}

struct CustomerInsights: Codable {
    let totalCustomers: Int
    let repeatCustomerRate: Double
    let avgCustomerValue: Double
    let topCustomerSegment: String?
    
    enum CodingKeys: String, CodingKey {
        case totalCustomers = "total_customers"
        case repeatCustomerRate = "repeat_customer_rate"
        case avgCustomerValue = "avg_customer_value"
        case topCustomerSegment = "top_customer_segment"
    }
}

struct SeasonalTrend: Codable {
    let season: String
    let demandLevel: String
    let topCategories: [String]
    let recommendation: String
    
    enum CodingKeys: String, CodingKey {
        case season
        case demandLevel = "demand_level"
        case topCategories = "top_categories"
        case recommendation
    }
}

struct RevenueForecast: Codable {
    let nextMonth: Double
    let nextQuarter: Double
    let confidence: Double
    let factors: [String]
    
    enum CodingKeys: String, CodingKey {
        case nextMonth = "next_month"
        case nextQuarter = "next_quarter"
        case confidence
        case factors
    }
}

// MARK: - App Settings Models

struct BusinessAppSetting: Codable {
    let key: String
    let value: String
    let type: String
    let description: String?
    let isCached: Bool?
    let cacheDuration: Int?
    let lastModified: Date?
    
    enum CodingKeys: String, CodingKey {
        case key
        case value
        case type
        case description
        case isCached = "is_cached"
        case cacheDuration = "cache_duration"
        case lastModified = "last_modified"
    }
}

// MARK: - Analytics Models

struct BusinessAnalyticsEvent: Codable {
    let eventType: String
    let eventName: String
    let userId: String?
    let sessionId: String
    let timestamp: String
    let metadata: [String: String]?
    let deviceModel: String?
    let locationName: String?
    
    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case eventName = "event_name"
        case userId = "user_id"
        case sessionId = "session_id"
        case timestamp
        case metadata
        case deviceModel = "device_model"
        case locationName = "location_name"
    }
}

struct UserDashboard: Codable {
    let overview: UserOverview
    let activity: [BusinessUserActivity]
    let listings: ListingStats
    let transactions: TransactionStats
    let engagement: EngagementMetrics
    let achievements: AchievementProgress
}

struct UserOverview: Codable {
    let sessions: Int
    let totalEvents: Int
    let activeDays: Int
    
    enum CodingKeys: String, CodingKey {
        case sessions
        case totalEvents = "total_events"
        case activeDays = "active_days"
    }
}

struct BusinessUserActivity: Codable {
    let date: Date
    let events: Int
    let sessions: Int
}

struct ListingStats: Codable {
    let totalListings: Int
    let activeListings: Int
    let totalViews: Int
    let avgRating: Double
    
    enum CodingKeys: String, CodingKey {
        case totalListings = "total_listings"
        case activeListings = "active_listings"
        case totalViews = "total_views"
        case avgRating = "avg_rating"
    }
}

struct TransactionStats: Codable {
    let totalTransactions: Int
    let totalRevenue: Double
    let avgTransactionValue: Double
    let completionRate: Double
    
    enum CodingKeys: String, CodingKey {
        case totalTransactions = "total_transactions"
        case totalRevenue = "total_revenue"
        case avgTransactionValue = "avg_transaction_value"
        case completionRate = "completion_rate"
    }
}

struct EngagementMetrics: Codable {
    let engagementScore: Int
    let activityTrend: String
    let favoriteCategories: [String]
    let peakHours: [Int]
    
    enum CodingKeys: String, CodingKey {
        case engagementScore = "engagement_score"
        case activityTrend = "activity_trend"
        case favoriteCategories = "favorite_categories"
        case peakHours = "peak_hours"
    }
}

struct BusinessAchievement: Codable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let pointsReward: Int
    let icon: String
    let targetValue: Int
    let currentProgress: Int
    let isUnlocked: Bool
    let unlockedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, icon
        case pointsReward = "points_reward"
        case targetValue = "target_value"
        case currentProgress = "current_progress"
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
    }
}

struct AchievementProgress: Codable {
    let totalAchievements: Int
    let unlockedAchievements: Int
    let totalPoints: Int
    let nextAchievement: BusinessAchievement?
    
    enum CodingKeys: String, CodingKey {
        case totalAchievements = "total_achievements"
        case unlockedAchievements = "unlocked_achievements"
        case totalPoints = "total_points"
        case nextAchievement = "next_achievement"
    }
}