//
//  CreatorDashboardView.swift
//  Brrow
//
//  Comprehensive creator dashboard with analytics and monetization
//

import SwiftUI
import Charts

struct CreatorDashboardView: View {
    @StateObject private var creatorService = CreatorService.shared
    @State private var selectedTab = 0
    @State private var selectedPeriod: TimePeriod = .month
    @State private var showingSettings = false
    @State private var showingInsights = false

    private let tabs = ["Overview", "Analytics", "Earnings", "Insights"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                dashboardHeaderView

                // Tab Selector
                tabSelectorView

                // Content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        switch selectedTab {
                        case 0:
                            overviewContent
                        case 1:
                            analyticsContent
                        case 2:
                            earningsContent
                        case 3:
                            insightsContent
                        default:
                            overviewContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Creator Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                CreatorSettingsView()
            }
            .sheet(isPresented: $showingInsights) {
                // CreatorInsightsView - defined in CreatorSettingsView.swift
                NavigationView {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(creatorService.insights) { insight in
                                InsightCard(insight: insight) {
                                    Task {
                                        try await creatorService.markInsightAsRead(insight.id)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Creator Insights")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingInsights = false
                            }
                        }
                    }
                }
            }
            .task {
                await loadDashboard()
            }
            .refreshable {
                await loadDashboard()
            }
        }
    }

    private var dashboardHeaderView: some View {
        VStack(spacing: 16) {
            if let overview = creatorService.dashboard?.overview {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Earnings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(Int(overview.totalEarnings))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: overview.currentRank.level.icon)
                                .foregroundColor(Color(overview.currentRank.level.color))
                            Text(overview.currentRank.level.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(overview.averageRating) ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                            Text("(\(overview.totalReviews))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Quick Stats
                HStack(spacing: 20) {
                    StatCard(title: "Active Listings", value: "\(overview.activeListings)", icon: "list.bullet", color: .blue)
                    StatCard(title: "Total Bookings", value: "\(overview.totalBookings)", icon: "calendar", color: .orange)
                    StatCard(title: "Response Rate", value: "\(Int(overview.responseRate * 100))%", icon: "message", color: .green)
                }
            }

            // Period Selector
            periodSelectorView
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var periodSelectorView: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedPeriod) { _ in
            Task {
                await loadDashboard()
            }
        }
    }

    private var tabSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        selectedTab = index
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)

                            Rectangle()
                                .fill(selectedTab == index ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Content Views

    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Performance Summary
            performanceSummaryView

            // Top Performing Listings
            topListingsView

            // Recent Activity
            recentActivityView

            // Quick Actions
            quickActionsView
        }
    }

    private var analyticsContent: some View {
        VStack(spacing: 20) {
            // Charts
            analyticsChartsView

            // Category Breakdown
            categoryBreakdownView

            // Location Analytics
            locationAnalyticsView

            // Seasonal Trends
            seasonalTrendsView
        }
    }

    private var earningsContent: some View {
        VStack(spacing: 20) {
            // Earnings Overview
            earningsOverviewView

            // Recent Transactions
            recentTransactionsView

            // Payout Schedule
            payoutScheduleView

            // Tax Documents
            taxDocumentsView
        }
    }

    private var insightsContent: some View {
        VStack(spacing: 20) {
            // Optimization Insights
            optimizationInsightsView

            // Market Insights
            marketInsightsView

            // Growth Opportunities
            growthOpportunitiesView
        }
    }

    // MARK: - Component Views

    private var performanceSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Summary")
                .font(.headline)

            if let analytics = creatorService.analyticsData {
                HStack(spacing: 20) {
                    PerformanceMetric(
                        title: "Views",
                        value: "\(Int(analytics.viewsData.total))",
                        growth: analytics.viewsData.growth,
                        trend: analytics.viewsData.trend
                    )

                    PerformanceMetric(
                        title: "Bookings",
                        value: "\(Int(analytics.bookingsData.total))",
                        growth: analytics.bookingsData.growth,
                        trend: analytics.bookingsData.trend
                    )

                    PerformanceMetric(
                        title: "Revenue",
                        value: "$\(Int(analytics.earningsData.total))",
                        growth: analytics.earningsData.growth,
                        trend: analytics.earningsData.trend
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var topListingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Performing Listings")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to detailed listings analytics
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            ForEach(creatorService.getTopPerformingListings()) { listing in
                ListingPerformanceRow(listing: listing)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)

            if let earnings = creatorService.earningsData {
                ForEach(earnings.recentTransactions.prefix(3)) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Create Listing",
                    icon: "plus.circle",
                    color: .blue
                ) {
                    // Navigate to create listing
                }

                QuickActionCard(
                    title: "View Insights",
                    icon: "lightbulb",
                    color: .orange
                ) {
                    showingInsights = true
                }

                QuickActionCard(
                    title: "Manage Bookings",
                    icon: "calendar",
                    color: .green
                ) {
                    // Navigate to bookings
                }

                QuickActionCard(
                    title: "Update Settings",
                    icon: "gear",
                    color: .purple
                ) {
                    showingSettings = true
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var analyticsChartsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics Charts")
                .font(.headline)

            if let analytics = creatorService.analyticsData {
                // Earnings Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Earnings Trend")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Chart(analytics.earningsData.dataPoints) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Earnings", dataPoint.value)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 150)
                    .chartXAxis(.hidden)
                }

                Divider()

                // Views vs Bookings Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Views vs Bookings")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Chart {
                        ForEach(analytics.viewsData.dataPoints.indices, id: \.self) { index in
                            let viewsPoint = analytics.viewsData.dataPoints[index]
                            let bookingsPoint = analytics.bookingsData.dataPoints[index]

                            LineMark(
                                x: .value("Date", viewsPoint.date),
                                y: .value("Views", viewsPoint.value)
                            )
                            .foregroundStyle(.blue)

                            LineMark(
                                x: .value("Date", bookingsPoint.date),
                                y: .value("Bookings", bookingsPoint.value * 10) // Scale for visibility
                            )
                            .foregroundStyle(.orange)
                        }
                    }
                    .frame(height: 150)
                    .chartXAxis(.hidden)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var categoryBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Performance")
                .font(.headline)

            ForEach(creatorService.getCategoryPerformance()) { category in
                CategoryPerformanceRow(category: category)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var locationAnalyticsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location Analytics")
                .font(.headline)

            if let locationInsights = creatorService.analyticsData?.locationInsights {
                VStack(spacing: 12) {
                    HStack {
                        Text("Reach Radius")
                        Spacer()
                        Text("\(Int(locationInsights.reachRadius)) miles")
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Delivery Success")
                        Spacer()
                        Text("\(Int(locationInsights.deliverySuccess * 100))%")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }

                    if let popularLocation = locationInsights.mostPopularPickupLocation {
                        HStack {
                            Text("Top Pickup Location")
                            Spacer()
                            Text(popularLocation)
                                .fontWeight(.medium)
                        }
                    }
                }

                Divider()

                Text("Top Cities")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(locationInsights.topCities) { city in
                    HStack {
                        Text(city.city)
                        Spacer()
                        Text("\(city.bookings) bookings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(Int(city.earnings))")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var seasonalTrendsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seasonal Trends")
                .font(.headline)

            if let trends = creatorService.analyticsData?.seasonalTrends {
                Chart(trends) { trend in
                    BarMark(
                        x: .value("Month", trend.month),
                        y: .value("Earnings", trend.earnings)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var earningsOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Earnings Overview")
                .font(.headline)

            if let earnings = creatorService.earningsData {
                VStack(spacing: 16) {
                    HStack {
                        EarningsCard(
                            title: "Current Balance",
                            amount: earnings.currentBalance,
                            color: .green
                        )

                        EarningsCard(
                            title: "Pending",
                            amount: earnings.pendingEarnings,
                            color: .orange
                        )
                    }

                    HStack {
                        EarningsCard(
                            title: "This Month",
                            amount: earnings.thisMonthEarnings,
                            color: .blue
                        )

                        EarningsCard(
                            title: "Last Month",
                            amount: earnings.lastMonthEarnings,
                            color: .gray
                        )
                    }

                    let growthRate = earnings.growthRate
                    HStack {
                        Text("Growth Rate")
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: growthRate >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundColor(growthRate >= 0 ? .green : .red)
                            Text("\(growthRate, specifier: "%.1f")%")
                                .fontWeight(.medium)
                                .foregroundColor(growthRate >= 0 ? .green : .red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var recentTransactionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to transactions
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if let earnings = creatorService.earningsData {
                ForEach(earnings.recentTransactions.prefix(5)) { transaction in
                    TransactionRow(transaction: transaction)
                        .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var payoutScheduleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payout Schedule")
                .font(.headline)

            if let earnings = creatorService.earningsData {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Frequency")
                        Spacer()
                        Text(earnings.payoutSchedule.frequency.displayName)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Next Payout")
                        Spacer()
                        Text(earnings.payoutSchedule.nextPayoutDate)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Minimum Threshold")
                        Spacer()
                        Text("$\(Int(earnings.payoutSchedule.minimumThreshold))")
                            .fontWeight(.medium)
                    }

                    if earnings.currentBalance >= earnings.payoutSchedule.minimumThreshold {
                        Button("Request Instant Payout") {
                            Task {
                                try await creatorService.requestPayout(amount: earnings.currentBalance)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var taxDocumentsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tax Documents")
                .font(.headline)

            if let earnings = creatorService.earningsData {
                ForEach(earnings.taxDocuments) { document in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.type.displayName)
                                .fontWeight(.medium)
                            Text("\(document.year)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("$\(Int(document.amount))")
                            .fontWeight(.medium)

                        Button("Download") {
                            Task {
                                _ = try await creatorService.downloadTaxDocument(document.id)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var optimizationInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optimization Insights")
                .font(.headline)

            ForEach(creatorService.getOptimizationSuggestions()) { insight in
                InsightCard(insight: insight) {
                    Task {
                        try await creatorService.markInsightAsRead(insight.id)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var marketInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Insights")
                .font(.headline)

            ForEach(creatorService.getDemandInsights()) { insight in
                InsightCard(insight: insight) {
                    Task {
                        try await creatorService.markInsightAsRead(insight.id)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var growthOpportunitiesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Opportunities")
                .font(.headline)

            ForEach(creatorService.getPricingInsights()) { insight in
                InsightCard(insight: insight) {
                    Task {
                        try await creatorService.markInsightAsRead(insight.id)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func loadDashboard() async {
        do {
            try await creatorService.fetchDashboard(period: selectedPeriod)
        } catch {
            print("Failed to load dashboard: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct PerformanceMetric: View {
    let title: String
    let value: String
    let growth: Double
    let trend: TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(Color(trend.color))

                Text("\(growth, specifier: "%.1f")%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(trend.color))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ListingPerformanceRow: View {
    let listing: ListingPerformance

    var body: some View {
        HStack {
            BrrowAsyncImage(url: listing.imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(listing.category)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("\(listing.views) views")
                    Text("•")
                    Text("\(listing.bookings) bookings")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(listing.earnings))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                HStack(spacing: 4) {
                    Image(systemName: listing.trend.icon)
                        .font(.caption2)
                        .foregroundColor(Color(listing.trend.color))

                    Text("\(listing.conversionRate * 100, specifier: "%.1f")%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TransactionRow: View {
    let transaction: EarningsTransaction

    var body: some View {
        HStack {
            Circle()
                .fill(Color(transaction.status.color).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: transactionIcon)
                        .font(.caption)
                        .foregroundColor(Color(transaction.status.color))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let listingTitle = transaction.listingTitle {
                    Text(listingTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(transaction.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+$\(Int(transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text(transaction.status.displayName)
                    .font(.caption)
                    .foregroundColor(Color(transaction.status.color))
            }
        }
    }

    private var transactionIcon: String {
        switch transaction.type {
        case .rental: return "calendar"
        case .sale: return "tag"
        case .fee: return "minus.circle"
        case .refund: return "arrow.uturn.left"
        case .bonus: return "gift"
        }
    }
}

struct CategoryPerformanceRow: View {
    let category: CategoryPerformance

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.category)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(category.listings) listings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(category.earnings))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)

                    Text("\(category.averageRating, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// QuickActionCard struct moved to ProfileView.swift to avoid duplication

struct EarningsCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("$\(Int(amount))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightCard: View {
    let insight: CreatorInsight
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title3)
                    .foregroundColor(Color(insight.impact.color))

                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if insight.actionRequired, let actionText = insight.actionText {
                Button(actionText) {
                    // Handle action
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(insight.impact.color).opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(insight.impact.color).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

struct CreatorDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        CreatorDashboardView()
    }
}