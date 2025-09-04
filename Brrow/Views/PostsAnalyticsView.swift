//
//  PostsAnalyticsView.swift
//  Brrow
//
//  Analytics dashboard for user posts
//

import SwiftUI
import Charts

struct PostsAnalyticsView: View {
    let posts: [UserPost]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe: AnalyticsTimeframe = .month
    
    var body: some View {
        NavigationView {
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
                    
                    // Performance Metrics
                    performanceMetrics
                }
                .padding()
            }
            .background(Theme.Colors.background)
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
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AnalyticsStatCard(
                    title: "Total Posts",
                    value: "\(posts.count)",
                    icon: "doc.text.fill",
                    color: Theme.Colors.primary
                )
                
                AnalyticsStatCard(
                    title: "Active",
                    value: "\(activePostsCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                AnalyticsStatCard(
                    title: "Listings",
                    value: "\(listingsCount)",
                    icon: "tag.fill",
                    color: Theme.Colors.accentBlue
                )
                
                AnalyticsStatCard(
                    title: "Avg Price",
                    value: "$\(Int(averagePrice))",
                    icon: "dollarsign.circle.fill",
                    color: Theme.Colors.accentOrange
                )
            }
        }
    }
    
    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Posts Timeline Chart
    private var postsTimelineChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Posts Over Time")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(postsOverTime) { item in
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
                    ForEach(postsOverTime) { item in
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
            
            ForEach(categoryData, id: \.category) { item in
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
                StatusIndicator(label: "Active", count: activePostsCount, color: .green)
                StatusIndicator(label: "Pending", count: pendingPostsCount, color: .orange)
                StatusIndicator(label: "Completed", count: completedPostsCount, color: .blue)
                StatusIndicator(label: "Inactive", count: inactivePostsCount, color: .gray)
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
                AnalyticsMetricCard(title: "Response Rate", value: "95%", trend: .up)
                AnalyticsMetricCard(title: "Avg Views", value: "124", trend: .up)
                AnalyticsMetricCard(title: "Conversion", value: "12%", trend: .down)
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    private var activePostsCount: Int {
        posts.filter { $0.status == "active" }.count
    }
    
    private var pendingPostsCount: Int {
        posts.filter { $0.status == "pending" }.count
    }
    
    private var completedPostsCount: Int {
        posts.filter { $0.status == "completed" || $0.status == "fulfilled" }.count
    }
    
    private var inactivePostsCount: Int {
        posts.filter { $0.status != "active" && $0.status != "pending" && $0.status != "completed" && $0.status != "fulfilled" }.count
    }
    
    private var listingsCount: Int {
        posts.filter { $0.postType == "listing" }.count
    }
    
    private var averagePrice: Double {
        let prices = posts.map { $0.price }
        guard !prices.isEmpty else { return 0 }
        return prices.reduce(0, +) / Double(prices.count)
    }
    
    private var postsOverTime: [TimelineData] {
        // Group posts by date
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: posts) { post -> Date in
            let date = ISO8601DateFormatter().date(from: post.createdAt) ?? Date()
            return calendar.startOfDay(for: date)
        }
        
        // Create timeline data
        return grouped.map { date, posts in
            TimelineData(
                date: date,
                count: posts.count,
                label: formatDate(date)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(7) // Show last 7 days
    }
    
    private var categoryData: [CategoryData] {
        let grouped = Dictionary(grouping: posts) { $0.category }
        let total = Double(posts.count)
        
        return grouped.map { category, posts in
            CategoryData(
                category: category,
                count: posts.count,
                percentage: Double(posts.count) / total
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(5) // Top 5 categories
        .map { $0 }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
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

// MARK: - Data Models
struct TimelineData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let label: String
}

struct CategoryData {
    let category: String
    let count: Int
    let percentage: Double
}

enum AnalyticsTimeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All Time"
}