//
//  CreatorService.swift
//  Brrow
//
//  Creator dashboard and analytics service
//

import Foundation
import Combine

@MainActor
class CreatorService: ObservableObject {
    static let shared = CreatorService()

    @Published var dashboard: CreatorDashboard?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Analytics data
    @Published var currentPeriod: TimePeriod = .month
    @Published var analyticsData: CreatorAnalytics?
    @Published var earningsData: EarningsData?
    @Published var insights: [CreatorInsight] = []

    // Settings
    @Published var notificationPreferences: NotificationPreferences?
    @Published var profileSettings: CreatorProfileSettings?

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadCreatorSettings()
    }

    // MARK: - Dashboard Methods

    func fetchDashboard(period: TimePeriod = .month) async throws {
        isLoading = true
        errorMessage = nil
        currentPeriod = period

        do {
            let request = CreatorDashboardRequest(
                period: period,
                includeComparison: true,
                includeInsights: true
            )

            let response = try await apiClient.performRequest(
                endpoint: "api/creator/dashboard",
                method: "POST",
                body: try JSONEncoder().encode(request),
                responseType: CreatorAnalyticsResponse.self
            )

            guard response.success, let dashboardData = response.data else {
                throw BrrowAPIError.serverError(response.message ?? "Failed to fetch dashboard")
            }

            dashboard = dashboardData
            analyticsData = dashboardData.analytics
            earningsData = dashboardData.earnings
            insights = dashboardData.insights

        } catch {
            errorMessage = error.localizedDescription
            // Load mock data for demo
            loadMockDashboard(period: period)
        }

        isLoading = false
    }

    func refreshDashboard() async throws {
        try await fetchDashboard(period: currentPeriod)
    }

    // MARK: - Analytics Methods

    func fetchAnalytics(period: TimePeriod) async throws -> CreatorAnalytics {
        let request = CreatorDashboardRequest(
            period: period,
            includeComparison: true,
            includeInsights: false
        )

        let response = try await apiClient.performRequest(
            endpoint: "api/creator/analytics",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: CreatorAnalyticsResponse.self
        )

        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch analytics")
        }

        return data.analytics
    }

    func getPerformanceInsights() -> [CreatorInsight] {
        return insights.filter { $0.type == .optimization || $0.type == .opportunity }
    }

    func getPricingInsights() -> [CreatorInsight] {
        return insights.filter { $0.type == .pricing }
    }

    func getDemandInsights() -> [CreatorInsight] {
        return insights.filter { $0.type == .demand }
    }

    // MARK: - Earnings Methods

    func fetchEarnings() async throws -> EarningsData {
        let response = try await apiClient.performRequest(
            endpoint: "api/creator/earnings",
            method: "GET",
            responseType: APIResponse<EarningsData>.self
        )

        guard response.success, let earnings = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch earnings")
        }

        earningsData = earnings
        return earnings
    }

    func requestPayout(amount: Double) async throws {
        let request = ["amount": amount]

        let response = try await apiClient.performRequest(
            endpoint: "api/creator/payout",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to request payout")
        }

        // Refresh earnings data
        try await fetchEarnings()
    }

    func downloadTaxDocument(_ documentId: String) async throws -> URL {
        let response = try await apiClient.performRequest(
            endpoint: "api/creator/tax-documents/\(documentId)/download",
            method: "GET",
            responseType: APIResponse<[String: String]>.self
        )

        guard response.success,
              let data = response.data,
              let urlString = data["downloadUrl"],
              let url = URL(string: urlString) else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to get download URL")
        }

        return url
    }

    // MARK: - Settings Methods

    func updateSettings(_ settings: UpdateCreatorSettingsRequest) async throws {
        let response = try await apiClient.performRequest(
            endpoint: "api/creator/settings",
            method: "PUT",
            body: try JSONEncoder().encode(settings),
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update settings")
        }

        // Update local settings
        if let notifPrefs = settings.notificationPreferences {
            notificationPreferences = notifPrefs
        }
        if let profileSettings = settings.profileSettings {
            self.profileSettings = profileSettings
        }

        saveCreatorSettings()
    }

    func updatePayoutFrequency(_ frequency: PayoutFrequency) async throws {
        let settings = UpdateCreatorSettingsRequest(
            payoutFrequency: frequency,
            notificationPreferences: nil,
            profileSettings: nil
        )

        try await updateSettings(settings)
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        let settings = UpdateCreatorSettingsRequest(
            payoutFrequency: nil,
            notificationPreferences: preferences,
            profileSettings: nil
        )

        try await updateSettings(settings)
    }

    // MARK: - Monetization Methods

    func getOptimizationSuggestions() -> [CreatorInsight] {
        return insights.filter { insight in
            insight.type == .optimization && insight.impact != .low
        }.sorted { $0.impact.rawValue > $1.impact.rawValue }
    }

    func applyPricingRecommendation(_ insightId: UUID, newPrice: Double) async throws {
        struct ApplyRecommendationRequest: Codable {
            let insightId: String
            let newPrice: Double
        }

        let request = ApplyRecommendationRequest(
            insightId: insightId.uuidString,
            newPrice: newPrice
        )

        let response = try await apiClient.performRequest(
            endpoint: "api/creator/apply-recommendation",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to apply recommendation")
        }

        // Refresh dashboard to show updated data
        try await refreshDashboard()
    }

    func markInsightAsRead(_ insightId: UUID) async throws {
        let request = ["insightId": insightId.uuidString]

        let response = try await apiClient.performRequest(
            endpoint: "api/creator/insights/\(insightId.uuidString)/read",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to mark insight as read")
        }

        // Remove from local insights
        insights.removeAll { $0.id == insightId }
    }

    // MARK: - Performance Methods

    func getTopPerformingListings(limit: Int = 5) -> [ListingPerformance] {
        guard let analytics = analyticsData else { return [] }
        return Array(analytics.topPerformingListings.prefix(limit))
    }

    func getCategoryPerformance() -> [CategoryPerformance] {
        return analyticsData?.categoryBreakdown ?? []
    }

    func getGrowthMetrics() -> GrowthMetrics? {
        return dashboard?.growth
    }

    func getSeasonalTrends() -> [SeasonalTrend] {
        return analyticsData?.seasonalTrends ?? []
    }

    // MARK: - Ranking & Badges

    func getCurrentRank() -> CreatorRank? {
        return dashboard?.overview.currentRank
    }

    func getBadges() -> [CreatorBadge] {
        return dashboard?.overview.badgesEarned ?? []
    }

    func getAvailableBadges() async throws -> [CreatorBadge] {
        let response = try await apiClient.performRequest(
            endpoint: "api/creator/badges/available",
            method: "GET",
            responseType: APIResponse<[CreatorBadge]>.self
        )

        guard response.success, let badges = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch available badges")
        }

        return badges
    }

    // MARK: - Helper Methods

    private func loadCreatorSettings() {
        // Load notification preferences
        if let data = UserDefaults.standard.data(forKey: "creator_notification_preferences"),
           let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            notificationPreferences = preferences
        } else {
            // Default preferences
            notificationPreferences = NotificationPreferences(
                newBooking: true,
                paymentReceived: true,
                newReview: true,
                weeklyReport: true,
                monthlyReport: true,
                marketingUpdates: false
            )
        }

        // Load profile settings
        if let data = UserDefaults.standard.data(forKey: "creator_profile_settings"),
           let settings = try? JSONDecoder().decode(CreatorProfileSettings.self, from: data) {
            profileSettings = settings
        } else {
            // Default settings
            profileSettings = CreatorProfileSettings(
                isPublic: true,
                showEarnings: false,
                showBadges: true,
                autoAcceptBookings: false,
                minimumNotice: 24
            )
        }
    }

    private func saveCreatorSettings() {
        // Save notification preferences
        if let preferences = notificationPreferences,
           let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: "creator_notification_preferences")
        }

        // Save profile settings
        if let settings = profileSettings,
           let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "creator_profile_settings")
        }
    }

    // MARK: - Mock Data

    private func loadMockDashboard(period: TimePeriod) {
        let mockDashboard = generateMockDashboard(period: period)
        dashboard = mockDashboard
        analyticsData = mockDashboard.analytics
        earningsData = mockDashboard.earnings
        insights = mockDashboard.insights
    }

    private func generateMockDashboard(period: TimePeriod) -> CreatorDashboard {
        let overview = CreatorOverview(
            totalEarnings: 2450.75,
            totalBookings: 34,
            activeListings: 8,
            averageRating: 4.8,
            totalReviews: 42,
            responseRate: 0.96,
            completionRate: 0.98,
            joinedDate: "2023-03-15",
            isVerified: true,
            badgesEarned: [
                CreatorBadge(
                    id: "badge1",
                    name: "5-Star Host",
                    description: "Maintained 5-star rating for 10+ bookings",
                    icon: "star.fill",
                    earnedDate: "2024-01-15",
                    category: .quality
                ),
                CreatorBadge(
                    id: "badge2",
                    name: "Quick Responder",
                    description: "Response rate above 95%",
                    icon: "bolt.fill",
                    earnedDate: "2024-02-20",
                    category: .service
                )
            ],
            currentRank: CreatorRank(
                level: .gold,
                points: 2840,
                nextLevelPoints: 5000,
                benefits: [
                    RankBenefit(title: "Priority Support", description: "24/7 creator support", isActive: true),
                    RankBenefit(title: "Featured Listings", description: "Higher search ranking", isActive: true),
                    RankBenefit(title: "Lower Fees", description: "Reduced platform fees", isActive: false)
                ],
                progress: 0.568
            )
        )

        let analytics = generateMockAnalytics(period: period)
        let earnings = generateMockEarnings()
        let listings = generateMockListingsData()
        let bookings = generateMockBookingsData()
        let reviews = generateMockReviewsData()
        let growth = generateMockGrowthMetrics()
        let insights = generateMockInsights()

        return CreatorDashboard(
            overview: overview,
            analytics: analytics,
            earnings: earnings,
            listings: listings,
            bookings: bookings,
            reviews: reviews,
            growth: growth,
            insights: insights
        )
    }

    private func generateMockAnalytics(period: TimePeriod) -> CreatorAnalytics {
        let days = period == .week ? 7 : (period == .month ? 30 : (period == .quarter ? 90 : 365))

        let viewsData = AnalyticsTimeSeries(
            period: period,
            dataPoints: generateMockDataPoints(days: days, baseValue: 45),
            total: Double(days * 45),
            growth: 12.5,
            trend: .up
        )

        let bookingsData = AnalyticsTimeSeries(
            period: period,
            dataPoints: generateMockDataPoints(days: days, baseValue: 2),
            total: Double(days * 2),
            growth: 8.3,
            trend: .up
        )

        let earningsData = AnalyticsTimeSeries(
            period: period,
            dataPoints: generateMockDataPoints(days: days, baseValue: 85),
            total: Double(days * 85),
            growth: 15.2,
            trend: .up
        )

        return CreatorAnalytics(
            viewsData: viewsData,
            bookingsData: bookingsData,
            earningsData: earningsData,
            topPerformingListings: [
                ListingPerformance(
                    id: "perf1",
                    listingId: "listing1",
                    title: "Professional DSLR Camera",
                    views: 234,
                    bookings: 12,
                    earnings: 890.0,
                    rating: 4.9,
                    conversionRate: 0.051,
                    imageUrl: nil,
                    category: "Electronics",
                    trend: .up
                ),
                ListingPerformance(
                    id: "perf2",
                    listingId: "listing2",
                    title: "Mountain Bike",
                    views: 189,
                    bookings: 8,
                    earnings: 560.0,
                    rating: 4.7,
                    conversionRate: 0.042,
                    imageUrl: nil,
                    category: "Sports",
                    trend: .stable
                )
            ],
            categoryBreakdown: [
                CategoryPerformance(
                    category: "Electronics",
                    listings: 3,
                    bookings: 18,
                    earnings: 1240.0,
                    averageRating: 4.8,
                    demandScore: 0.85
                ),
                CategoryPerformance(
                    category: "Sports",
                    listings: 2,
                    bookings: 12,
                    earnings: 780.0,
                    averageRating: 4.6,
                    demandScore: 0.72
                )
            ],
            locationInsights: LocationAnalytics(
                topCities: [
                    CityPerformance(city: "San Francisco", bookings: 22, earnings: 1560.0, averageDistance: 3.2),
                    CityPerformance(city: "Oakland", bookings: 8, earnings: 520.0, averageDistance: 8.1),
                    CityPerformance(city: "Berkeley", bookings: 4, earnings: 280.0, averageDistance: 12.5)
                ],
                reachRadius: 25.0,
                mostPopularPickupLocation: "Downtown SF",
                deliverySuccess: 0.94
            ),
            seasonalTrends: [
                SeasonalTrend(month: "Jan", bookings: 8, earnings: 650.0, topCategory: "Electronics", demand: 0.7),
                SeasonalTrend(month: "Feb", bookings: 12, earnings: 890.0, topCategory: "Sports", demand: 0.8),
                SeasonalTrend(month: "Mar", bookings: 14, earnings: 1020.0, topCategory: "Electronics", demand: 0.9)
            ],
            competitorComparison: CompetitorAnalytics(
                averagePrice: 68.50,
                marketShare: 0.12,
                pricePosition: .competitive,
                suggestionScore: 0.78
            )
        )
    }

    private func generateMockDataPoints(days: Int, baseValue: Int) -> [AnalyticsTimeSeries.DataPoint] {
        var points: [AnalyticsTimeSeries.DataPoint] = []
        let calendar = Calendar.current

        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let variation = Double.random(in: 0.7...1.3)
            let value = Double(baseValue) * variation

            points.append(AnalyticsTimeSeries.DataPoint(
                date: ISO8601DateFormatter().string(from: date),
                value: value,
                label: nil
            ))
        }

        return points.reversed()
    }

    private func generateMockEarnings() -> EarningsData {
        return EarningsData(
            currentBalance: 425.80,
            pendingEarnings: 156.25,
            totalLifetimeEarnings: 2450.75,
            thisMonthEarnings: 890.50,
            lastMonthEarnings: 675.25,
            payoutSchedule: PayoutSchedule(
                frequency: .weekly,
                nextPayoutDate: "2024-12-30",
                minimumThreshold: 50.0,
                currency: "USD"
            ),
            recentTransactions: [
                EarningsTransaction(
                    id: "txn1",
                    bookingId: "booking1",
                    amount: 75.0,
                    type: .rental,
                    status: .completed,
                    date: "2024-12-20",
                    description: "Camera rental payment",
                    listingTitle: "DSLR Camera",
                    renterName: "John D.",
                    itemImageUrl: "https://example.com/camera.jpg"
                ),
                EarningsTransaction(
                    id: "txn2",
                    bookingId: "booking2",
                    amount: 45.0,
                    type: .rental,
                    status: .pending,
                    date: "2024-12-19",
                    description: "Bike rental payment",
                    listingTitle: "Mountain Bike",
                    renterName: "Sarah M.",
                    itemImageUrl: "https://example.com/bike.jpg"
                )
            ],
            taxDocuments: [
                TaxDocument(
                    id: "tax1",
                    year: 2024,
                    type: .form1099,
                    amount: 2450.75,
                    downloadUrl: "https://example.com/tax/2024.pdf",
                    generatedAt: "2024-01-31"
                )
            ],
            paymentMethods: [
                PaymentMethod(
                    id: "pm1",
                    type: .bankAccount,
                    displayName: "Chase Checking ****1234",
                    isDefault: true,
                    lastFour: "1234",
                    expiryDate: nil,
                    isVerified: true
                )
            ],
            growthRate: 0.15
        )
    }

    private func generateMockListingsData() -> CreatorListingsData {
        return CreatorListingsData(
            totalListings: 8,
            activeListings: 7,
            draftListings: 1,
            pausedListings: 0,
            totalViews: 1456,
            averageViewsPerListing: 182.0,
            conversionRate: 0.047,
            topCategories: ["Electronics", "Sports", "Tools"],
            performanceBreakdown: []
        )
    }

    private func generateMockBookingsData() -> CreatorBookingsData {
        return CreatorBookingsData(
            totalBookings: 34,
            upcomingBookings: 3,
            activeBookings: 2,
            completedBookings: 28,
            cancelledBookings: 1,
            averageBookingValue: 72.10,
            repeatCustomerRate: 0.35,
            popularDays: ["Friday", "Saturday", "Sunday"],
            averageRentalDuration: 2.4
        )
    }

    private func generateMockReviewsData() -> CreatorReviewsData {
        return CreatorReviewsData(
            totalReviews: 42,
            averageRating: 4.8,
            ratingDistribution: [
                RatingCount(rating: 5, count: 28, percentage: 66.7),
                RatingCount(rating: 4, count: 12, percentage: 28.6),
                RatingCount(rating: 3, count: 2, percentage: 4.7),
                RatingCount(rating: 2, count: 0, percentage: 0.0),
                RatingCount(rating: 1, count: 0, percentage: 0.0)
            ],
            recentReviews: [],
            responseRate: 0.96,
            positiveKeywords: ["excellent", "clean", "professional", "helpful"],
            improvementAreas: ["faster response", "better packaging"]
        )
    }

    private func generateMockGrowthMetrics() -> GrowthMetrics {
        return GrowthMetrics(
            monthOverMonthGrowth: GrowthData(earnings: 32.0, bookings: 25.0, views: 18.5, rating: 2.1),
            quarterOverQuarterGrowth: GrowthData(earnings: 68.5, bookings: 45.2, views: 42.1, rating: 8.3),
            yearOverYearGrowth: GrowthData(earnings: 145.8, bookings: 120.5, views: 98.7, rating: 15.2),
            projectedEarnings: ProjectedEarnings(
                nextMonth: 975.0,
                nextQuarter: 2850.0,
                nextYear: 12400.0,
                confidence: 0.82
            ),
            marketPosition: MarketPosition(
                rankInCategory: 12,
                totalInCategory: 156,
                rankInLocation: 8,
                totalInLocation: 89,
                percentile: 92.3
            )
        )
    }

    private func generateMockInsights() -> [CreatorInsight] {
        return [
            CreatorInsight(
                type: .pricing,
                title: "Price Optimization Opportunity",
                description: "Your camera rental could earn 15% more by adjusting the price to $85/day",
                impact: .high,
                actionRequired: true,
                actionText: "Update Price",
                data: InsightData(
                    currentValue: 75.0,
                    suggestedValue: 85.0,
                    potentialIncrease: 15.0,
                    confidence: 0.87
                ),
                createdAt: "2024-12-20"
            ),
            CreatorInsight(
                type: .demand,
                title: "High Demand Period",
                description: "Electronics rentals see 40% higher demand during weekends",
                impact: .medium,
                actionRequired: false,
                actionText: nil,
                data: InsightData(
                    currentValue: 0.85,
                    suggestedValue: nil,
                    potentialIncrease: 40.0,
                    confidence: 0.92
                ),
                createdAt: "2024-12-19"
            ),
            CreatorInsight(
                type: .opportunity,
                title: "New Category Opportunity",
                description: "Consider adding camping gear - high demand in your area",
                impact: .medium,
                actionRequired: false,
                actionText: "Explore Category",
                data: nil,
                createdAt: "2024-12-18"
            )
        ]
    }
}