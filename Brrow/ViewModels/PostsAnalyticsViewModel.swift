//
//  PostsAnalyticsViewModel.swift
//  Brrow
//
//  Analytics view model that fetches real data from backend
//

import Foundation
import SwiftUI

@MainActor
class PostsAnalyticsViewModel: ObservableObject {
    @Published var analyticsData: APIClient.PostsAnalyticsResponse.AnalyticsData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeframe: AnalyticsTimeframe = .month

    private let apiClient = APIClient.shared

    func fetchAnalytics() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.fetchPostsAnalytics(timeframe: selectedTimeframe.apiValue)

            if response.success, let data = response.data {
                analyticsData = data
            } else {
                errorMessage = "Failed to load analytics data"
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Analytics fetch error: \(error)")
        }

        isLoading = false
    }

    func refreshAnalytics() async {
        await fetchAnalytics()
    }

    func selectTimeframe(_ timeframe: AnalyticsTimeframe) async {
        selectedTimeframe = timeframe
        await fetchAnalytics()
    }

    // MARK: - Computed Properties

    var summary: APIClient.PostsAnalyticsResponse.AnalyticsSummary? {
        analyticsData?.summary
    }

    var postsOverTimeData: [TimelineData] {
        guard let postsOverTime = analyticsData?.postsOverTime else { return [] }

        return postsOverTime.map { date, count in
            let parsedDate = parseAPIDate(date) ?? Date()
            return TimelineData(
                date: parsedDate,
                count: count,
                label: formatDate(parsedDate)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(10) // Show last 10 data points
        .map { $0 }
    }

    var categoryData: [CategoryData] {
        guard let distribution = analyticsData?.categoryDistribution else { return [] }
        let total = Double(distribution.values.reduce(0, +))

        return distribution.map { category, count in
            CategoryData(
                category: category,
                count: count,
                percentage: total > 0 ? Double(count) / total : 0
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(5) // Top 5 categories
        .map { $0 }
    }

    var statusData: [StatusData] {
        guard let breakdown = analyticsData?.statusBreakdown else { return [] }

        return breakdown.map { status, count in
            StatusData(
                status: status,
                count: count,
                color: statusColor(for: status)
            )
        }
        .sorted { $0.count > $1.count }
    }

    // MARK: - Helper Methods

    private func parseAPIDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "pending":
            return .orange
        case "completed", "fulfilled":
            return .blue
        case "sold", "rented":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Data Models

struct StatusData {
    let status: String
    let count: Int
    let color: Color
}

enum AnalyticsTimeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All Time"

    var apiValue: String {
        switch self {
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        case .all: return "all"
        }
    }
}

// Keep existing data models for compatibility
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