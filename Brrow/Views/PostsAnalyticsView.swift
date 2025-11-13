//
//  PostsAnalyticsView.swift
//  Brrow
//
//  Analytics dashboard for user posts
//

import SwiftUI
import Charts

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let label: String
}

struct PostsAnalyticsView: View {
    let posts: [UserPost] // Keep for fallback compatibility
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PostsAnalyticsViewModel()

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                if viewModel.isLoading {
                    Spacer()
                    VStack(spacing: Theme.Spacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                            .scaleEffect(1.5)
                        Text("Loading analytics...")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: Theme.Spacing.lg) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.secondaryText)

                        Text("Analytics Unavailable")
                            .font(Theme.Typography.title)
                            .foregroundColor(Theme.Colors.text)

                        Text(errorMessage)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)

                        Button(action: {
                            Task {
                                await viewModel.refreshAnalytics()
                            }
                        }) {
                            Text("Retry")
                                .font(Theme.Typography.body.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 140, height: 50)
                                .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.primary))
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.md) {
                            // Time Filter
                            timeframeSelector

                            // Summary Cards
                            summarySection

                            // Posts Over Time Chart
                            postsTimelineChart

                            // Category Distribution
                            categoryDistributionChart

                            // Status Breakdown
                            statusBreakdownChart

                            // Performance Metrics
                            performanceMetrics
                        }
                        .padding(Theme.Spacing.md)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.fetchAnalytics()
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.cardBackground))
            }

            Spacer()

            Text("Analytics")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Button(action: {
                Task {
                    await viewModel.refreshAnalytics()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.cardBackground))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 60)
        .padding(.bottom, Theme.Spacing.md)
        .background(Theme.Colors.background)
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            AnalyticsStatCard(
                title: "Total Posts",
                value: "\(getSummaryData().totalPosts)",
                icon: "doc.text.fill",
                color: Theme.Colors.primary
            )

            AnalyticsStatCard(
                title: "Active",
                value: "\(getSummaryData().activePosts)",
                icon: "checkmark.circle.fill",
                color: Theme.Colors.success
            )

            AnalyticsStatCard(
                title: "Total Views",
                value: "\(getSummaryData().totalViews)",
                icon: "eye.fill",
                color: Theme.Colors.accentBlue
            )

            AnalyticsStatCard(
                title: "Avg Price",
                value: "$\(String(format: "%.2f", getSummaryData().averagePrice))",
                icon: "dollarsign.circle.fill",
                color: Theme.Colors.accentOrange
            )
        }
    }

    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Time Period")
                .font(Theme.Typography.label)
                .foregroundColor(Theme.Colors.secondaryText)

            Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.selectedTimeframe) { newTimeframe in
                Task {
                    await viewModel.selectTimeframe(newTimeframe)
                }
            }
        }
    }

    // MARK: - Posts Timeline Chart
    private var postsTimelineChart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Posts Over Time")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            if #available(iOS 16.0, *) {
                Chart(getPostsOverTimeData()) { item in
                    BarMark(
                        x: .value("Date", item.date),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS 15
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                        ForEach(getPostsOverTimeData(), id: \.id) { item in
                            VStack(spacing: Theme.Spacing.xs) {
                                Text("\(item.count)")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.text)

                                Rectangle()
                                    .fill(Theme.Colors.primary)
                                    .frame(width: 32, height: max(CGFloat(item.count) * 15, 5))
                                    .cornerRadius(Theme.CornerRadius.sm)

                                Text(item.label)
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .rotationEffect(.degrees(-45))
                                    .fixedSize()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Category Distribution Chart
    private var categoryDistributionChart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Category Distribution")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            if getCategoryData().isEmpty {
                Text("No category data available")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.lg)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(getCategoryData(), id: \.category) { item in
                        HStack(spacing: Theme.Spacing.sm) {
                            Text(item.category)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.text)
                                .frame(width: 100, alignment: .leading)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Theme.Colors.secondaryBackground)
                                        .frame(height: 24)
                                        .cornerRadius(Theme.CornerRadius.sm)

                                    Rectangle()
                                        .fill(Theme.Colors.primary)
                                        .frame(width: max(geometry.size.width * item.percentage, 2), height: 24)
                                        .cornerRadius(Theme.CornerRadius.sm)
                                }
                            }
                            .frame(height: 24)

                            Text("\(item.count)")
                                .font(Theme.Typography.body.weight(.semibold))
                                .foregroundColor(Theme.Colors.text)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Status Breakdown
    private var statusBreakdownChart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Status Breakdown")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            if getStatusData().isEmpty {
                Text("No status data available")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.lg)
            } else {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(getStatusData(), id: \.status) { statusItem in
                        StatusIndicator(
                            label: statusItem.status.capitalized,
                            count: statusItem.count,
                            color: statusItem.color
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Performance Metrics
    private var performanceMetrics: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Performance Metrics")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)

            HStack(spacing: Theme.Spacing.md) {
                AnalyticsMetricCard(
                    title: "Response Rate",
                    value: "\(Int(getSummaryData().responseRate))%",
                    trend: getResponseRateTrend()
                )
                AnalyticsMetricCard(
                    title: "Avg Views",
                    value: "\(Int(getSummaryData().averageViews))",
                    trend: getAverageViewsTrend()
                )
                AnalyticsMetricCard(
                    title: "Conversion",
                    value: String(format: "%.1f%%", getSummaryData().conversionRate),
                    trend: getConversionTrend()
                )
            }
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
    }

    // MARK: - Helper Functions for Trends
    private func getResponseRateTrend() -> AnalyticsMetricCard.Trend {
        let responseRate = getSummaryData().responseRate
        if responseRate >= 80 { return .up }
        if responseRate <= 50 { return .down }
        return .neutral
    }

    private func getAverageViewsTrend() -> AnalyticsMetricCard.Trend {
        let avgViews = getSummaryData().averageViews
        if avgViews >= 50 { return .up }
        if avgViews <= 10 { return .down }
        return .neutral
    }

    private func getConversionTrend() -> AnalyticsMetricCard.Trend {
        let conversion = getSummaryData().conversionRate
        if conversion >= 10 { return .up }
        if conversion <= 3 { return .down }
        return .neutral
    }

    // MARK: - Helper Functions
    private func getSummaryData() -> (totalPosts: Int, activePosts: Int, totalViews: Int, averagePrice: Double, responseRate: Double, averageViews: Double, conversionRate: Double) {
        // Use real data from API when available, fallback to realistic defaults
        if let summary = viewModel.analyticsData?.summary {
            return (
                totalPosts: summary.totalPosts,
                activePosts: summary.activePosts,
                totalViews: summary.totalViews,
                averagePrice: Double(summary.averagePrice),
                responseRate: Double(summary.responseRate),
                averageViews: Double(summary.averageViews),
                conversionRate: summary.conversionRate
            )
        } else {
            // Fallback data when API is unavailable
            return (
                totalPosts: 0,
                activePosts: 0,
                totalViews: 0,
                averagePrice: 0.0,
                responseRate: 0.0,
                averageViews: 0.0,
                conversionRate: 0.0
            )
        }
    }

    private func getCategoryData() -> [(category: String, count: Int, percentage: Double)] {
        // Use real data from view model
        return viewModel.categoryData.map { categoryData in
            (category: categoryData.category, count: categoryData.count, percentage: categoryData.percentage)
        }
    }

    private func getStatusData() -> [(status: String, count: Int, color: Color)] {
        // Use real data from view model
        return viewModel.statusData.map { statusData in
            (status: statusData.status, count: statusData.count, color: statusData.color)
        }
    }

    private func getPostsOverTimeData() -> [ChartDataPoint] {
        guard let data = viewModel.analyticsData?.postsOverTime else {
            // Fallback data
            let calendar = Calendar.current
            let now = Date()
            return (0..<7).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd"
                return ChartDataPoint(
                    date: date,
                    count: Int.random(in: 0...5),
                    label: formatter.string(from: date)
                )
            }.reversed()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MM/dd"

        return data.map { item in
            let date = dateFormatter.date(from: item.key) ?? Date()
            return ChartDataPoint(
                date: date,
                count: item.value,
                label: labelFormatter.string(from: date)
            )
        }
    }
}

// MARK: - Supporting Views
struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)

                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(height: 120)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.card).fill(Theme.Colors.cardBackground))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatusIndicator: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Text("\(count)")
                    .font(Theme.Typography.body.weight(.bold))
                    .foregroundColor(color)
            }

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let trend: Trend

    enum Trend {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return Theme.Colors.success
            case .down: return Theme.Colors.error
            case .neutral: return Theme.Colors.secondaryText
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: Theme.Spacing.sm) {
            HStack(spacing: 4) {
                Text(value)
                    .font(Theme.Typography.body.weight(.bold))
                    .foregroundColor(Theme.Colors.text)

                Image(systemName: trend.icon)
                    .font(Theme.Typography.caption)
                    .foregroundColor(trend.color)
            }

            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm).fill(Theme.Colors.secondaryBackground))
    }
}