//
//  PostsAnalyticsView.swift
//  Brrow
//
//  Analytics dashboard for user posts
//

import SwiftUI
import Charts

struct PostsAnalyticsView: View {
    let posts: [UserPost] // Keep for fallback compatibility
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PostsAnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Loading analytics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("Analytics Unavailable")
                            .font(.headline)

                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Retry") {
                            Task {
                                await viewModel.refreshAnalytics()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary Cards
                            summarySection

                            // Time Filter
                            timeframeSelector

                            // Posts Over Time Chart
                            postsTimelineChart

                            // Category Distribution
                            categoryDistributionChart

                            // Status Breakdown
                            statusBreakdownChart

                            // Performance Metrics (now with real data)
                            performanceMetrics
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Posts Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchAnalytics()
            }
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AnalyticsStatCard(
                    title: "Total Posts",
                    value: "\(viewModel.summary?.totalPosts ?? 0)",
                    icon: "doc.text.fill",
                    color: Theme.Colors.primary
                )

                AnalyticsStatCard(
                    title: "Active",
                    value: "\(viewModel.summary?.activePosts ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }

            HStack(spacing: 16) {
                AnalyticsStatCard(
                    title: "Total Views",
                    value: "\(viewModel.summary?.totalViews ?? 0)",
                    icon: "eye.fill",
                    color: Theme.Colors.accentBlue
                )

                AnalyticsStatCard(
                    title: "Avg Price",
                    value: "$\(viewModel.summary?.averagePrice ?? 0)",
                    icon: "dollarsign.circle.fill",
                    color: Theme.Colors.accentOrange
                )
            }
        }
    }
    
    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
            ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: viewModel.selectedTimeframe) { _, newTimeframe in
            Task {
                await viewModel.selectTimeframe(newTimeframe)
            }
        }
    }
    
    // MARK: - Posts Timeline Chart
    private var postsTimelineChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Posts Over Time")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(viewModel.postsOverTimeData) { item in
                    BarMark(
                        x: .value("Date", item.date),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                // Fallback for iOS 15
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(viewModel.postsOverTimeData) { item in
                        VStack {
                            Text("\(item.count)")
                                .font(.caption2)

                            Rectangle()
                                .fill(Theme.Colors.primary)
                                .frame(width: 30, height: CGFloat(item.count) * 20)

                            Text(item.label)
                                .font(.caption2)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Category Distribution Chart
    private var categoryDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Distribution")
                .font(.headline)
            
            ForEach(viewModel.categoryData, id: \.category) { item in
                HStack {
                    Text(item.category)
                        .font(.caption)
                        .frame(width: 100, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Theme.Colors.primary)
                                .frame(width: geometry.size.width * item.percentage, height: 20)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 20)
                    
                    Text("\(item.count)")
                        .font(.caption)
                        .frame(width: 30)
                }
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Status Breakdown
    private var statusBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Breakdown")
                .font(.headline)
            
            HStack(spacing: 20) {
                ForEach(viewModel.statusData, id: \.status) { statusItem in
                    StatusIndicator(
                        label: statusItem.status.capitalized,
                        count: statusItem.count,
                        color: statusItem.color
                    )
                }
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Performance Metrics
    private var performanceMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
            
            HStack(spacing: 20) {
                AnalyticsMetricCard(
                    title: "Response Rate",
                    value: "\(viewModel.summary?.responseRate ?? 0)%",
                    trend: responseRateTrend
                )
                AnalyticsMetricCard(
                    title: "Avg Views",
                    value: "\(viewModel.summary?.averageViews ?? 0)",
                    trend: averageViewsTrend
                )
                AnalyticsMetricCard(
                    title: "Conversion",
                    value: String(format: "%.1f%%", viewModel.summary?.conversionRate ?? 0),
                    trend: conversionTrend
                )
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties for Trends
    private var responseRateTrend: AnalyticsMetricCard.Trend {
        guard let responseRate = viewModel.summary?.responseRate else { return .neutral }
        // Simple trend logic based on performance thresholds
        if responseRate >= 80 { return .up }
        if responseRate <= 50 { return .down }
        return .neutral
    }

    private var averageViewsTrend: AnalyticsMetricCard.Trend {
        guard let avgViews = viewModel.summary?.averageViews else { return .neutral }
        // Simple trend logic based on view thresholds
        if avgViews >= 50 { return .up }
        if avgViews <= 10 { return .down }
        return .neutral
    }

    private var conversionTrend: AnalyticsMetricCard.Trend {
        guard let conversion = viewModel.summary?.conversionRate else { return .neutral }
        // Simple trend logic based on conversion thresholds
        if conversion >= 10 { return .up }
        if conversion <= 3 { return .down }
        return .neutral
    }
}

// MARK: - Supporting Views
struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct StatusIndicator: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text("\(count)")
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
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
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            HStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Data Models now defined in PostsAnalyticsViewModel