//
//  TrendingItemsView.swift
//  Brrow
//
//  View showing trending items in the marketplace
//

import SwiftUI

struct TrendingItemsView: View {
    @StateObject private var viewModel = TrendingItemsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Trending metrics header
                trendingMetricsSection
                
                // Time filter
                timeFilterSection
                
                // Trending items grid
                if viewModel.isLoading {
                    LoadingGrid()
                } else if viewModel.trendingItems.isEmpty {
                    EmptyStateView(
                        title: "No trending items",
                        message: "Check back later for popular items",
                        systemImage: "flame"
                    )
                    .frame(minHeight: 400)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(viewModel.trendingItems.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(destination: ListingDetailView(listing: item)) {
                                TrendingItemGridCard(
                                    listing: item,
                                    rank: index + 1,
                                    trend: viewModel.getTrend(for: item)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Trending")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadTrendingItems()
        }
    }
    
    private var trendingMetricsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                MetricCard(
                    icon: "eye.fill",
                    value: "\(viewModel.totalViews)",
                    label: "Total Views",
                    color: .blue
                )
                
                MetricCard(
                    icon: "person.2.fill",
                    value: "\(viewModel.uniqueViewers)",
                    label: "Unique Viewers",
                    color: .purple
                )
                
                MetricCard(
                    icon: "arrow.up.right",
                    value: "+\(viewModel.growthPercentage)%",
                    label: "Growth Rate",
                    color: .green
                )
                
                MetricCard(
                    icon: "clock.fill",
                    value: "\(viewModel.avgViewTime)s",
                    label: "Avg. View Time",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var timeFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeFilter.allCases, id: \.self) { filter in
                    TimeFilterChip(
                        filter: filter,
                        isSelected: viewModel.selectedTimeFilter == filter,
                        action: {
                            viewModel.selectedTimeFilter = filter
                            viewModel.loadTrendingItems()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

struct TrendingItemGridCard: View {
    let listing: Listing
    let rank: Int
    let trend: TrendData
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with rank badge
            ZStack(alignment: .topLeading) {
                if let imageUrl = listing.imageUrls.first {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Rank badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                    Text("#\(rank)")
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(rankColor(for: rank))
                .cornerRadius(12)
                .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(Theme.Colors.text)
                
                HStack {
                    Text("$\(Int(listing.price))/day")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Spacer()
                    
                    // Trend indicator
                    HStack(spacing: 2) {
                        Image(systemName: trend.isUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text("\(trend.percentage)%")
                            .font(.caption)
                    }
                    .foregroundColor(trend.isUp ? .green : .red)
                }
                
                // Stats
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.caption2)
                        Text("\(listing.views)")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.caption2)
                        Text("\(trend.favorites)")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    if listing.isAvailable {
                        Label("Available", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .foregroundColor(.gray)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .orange
        case 2: return .purple
        case 3: return .blue
        default: return .gray
        }
    }
}

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 100)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct TimeFilterChip: View {
    let filter: TimeFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.displayName)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.Colors.primary : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : Theme.Colors.text)
                .cornerRadius(20)
        }
    }
}

// MARK: - View Model

class TrendingItemsViewModel: ObservableObject {
    @Published var trendingItems: [Listing] = []
    @Published var isLoading = false
    @Published var selectedTimeFilter: TimeFilter = .today
    
    // Metrics
    @Published var totalViews = 0
    @Published var uniqueViewers = 0
    @Published var growthPercentage = 0
    @Published var avgViewTime = 0
    
    private let apiClient = APIClient.shared
    private var trendData: [String: TrendData] = [:]
    
    func loadTrendingItems() {
        Task {
            await MainActor.run { isLoading = true }
            
            do {
                // In production, this would be a dedicated trending API endpoint
                let allListings = try await apiClient.fetchListings()
                
                // Sort by views and filter based on time
                let filtered = filterByTime(allListings)
                let sorted = filtered.sorted { $0.views > $1.views }
                
                await MainActor.run {
                    self.trendingItems = Array(sorted.prefix(20))
                    self.calculateMetrics()
                    self.generateTrendData()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
                print("Error loading trending items: \(error)")
            }
        }
    }
    
    private func filterByTime(_ listings: [Listing]) -> [Listing] {
        let now = Date()
        let calendar = Calendar.current
        
        return listings.filter { listing in
            // Convert createdAt string to Date for calendar comparisons
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            guard let createdDate = formatter.date(from: listing.createdAt) else {
                return false
            }
            
            switch selectedTimeFilter {
            case .today:
                return calendar.isDateInToday(createdDate)
            case .thisWeek:
                return calendar.isDate(createdDate, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth:
                return calendar.isDate(createdDate, equalTo: now, toGranularity: .month)
            case .allTime:
                return true
            }
        }
    }
    
    private func calculateMetrics() {
        totalViews = trendingItems.reduce(0) { $0 + $1.views }
        uniqueViewers = Int(Double(totalViews) * 0.7) // Simulated
        growthPercentage = Int.random(in: 15...45)
        avgViewTime = Int.random(in: 30...120)
    }
    
    private func generateTrendData() {
        for item in trendingItems {
            trendData[item.id] = TrendData(
                isUp: Bool.random(),
                percentage: Int.random(in: 5...30),
                favorites: Int.random(in: 10...100),
                inquiries: Int.random(in: 5...50)
            )
        }
    }
    
    func getTrend(for listing: Listing) -> TrendData {
        return trendData[listing.id] ?? TrendData(isUp: true, percentage: 0, favorites: 0, inquiries: 0)
    }
}

// MARK: - Models

enum TimeFilter: CaseIterable {
    case today, thisWeek, thisMonth, allTime
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .allTime: return "All Time"
        }
    }
}

struct TrendData {
    let isUp: Bool
    let percentage: Int
    let favorites: Int
    let inquiries: Int
}

// MARK: - Preview

struct TrendingItemsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TrendingItemsView()
        }
    }
}