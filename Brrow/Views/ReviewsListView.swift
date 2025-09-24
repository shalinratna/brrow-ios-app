//
//  ReviewsListView.swift
//  Brrow
//
//  Display reviews and ratings for users and listings
//

import SwiftUI

struct ReviewsListView: View {
    let revieweeId: String
    let reviewType: ReviewDisplayType

    @StateObject private var viewModel = ReviewsListViewModel()
    @State private var selectedFilter: ReviewFilters = ReviewFilters(
        rating: nil,
        reviewType: nil,
        status: .approved,
        isVerified: nil,
        dateRange: nil,
        sortBy: .newest,
        sortOrder: .descending
    )
    @State private var showingFilters = false

    enum ReviewDisplayType {
        case user
        case listing
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Rating Summary
                if let summary = viewModel.ratingSummary {
                    ratingHeaderView(summary)
                        .padding()
                        .background(Color(.systemGray6))
                }

                // Filter Bar
                filterBarView
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Reviews List
                if viewModel.isLoading && viewModel.reviews.isEmpty {
                    loadingView
                } else if viewModel.reviews.isEmpty {
                    emptyStateView
                } else {
                    reviewsScrollView
                }
            }
            .navigationTitle("Reviews")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ReviewFiltersView(filters: $selectedFilter) {
                    loadReviews()
                }
            }
            .task {
                await loadInitialData()
            }
            .refreshable {
                await loadInitialData()
            }
        }
    }

    private func ratingHeaderView(_ summary: RatingSummary) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Average Rating
                VStack(spacing: 4) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(summary.formattedAverageRating)
                            .font(.system(size: 36, weight: .bold))
                        Text("/ 5")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(summary.averageRating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }

                    Text("\(summary.totalReviews) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 60)

                // Rating Distribution
                VStack(alignment: .leading, spacing: 6) {
                    ForEach((1...5).reversed(), id: \.self) { rating in
                        HStack(spacing: 8) {
                            Text("\(rating)")
                                .font(.caption)
                                .frame(width: 12)

                            HStack(spacing: 2) {
                                ForEach(1...rating, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.yellow)
                                }
                            }
                            .frame(width: 40, alignment: .leading)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 6)

                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(
                                            width: geometry.size.width * (summary.ratingPercentages[rating] ?? 0) / 100,
                                            height: 6
                                        )
                                }
                                .cornerRadius(3)
                            }
                            .frame(height: 6)

                            Text("\(Int(summary.ratingPercentages[rating] ?? 0))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }

            // Additional Stats
            HStack(spacing: 24) {
                statItem("Verified", value: "\(summary.verifiedReviewsCount)")
                statItem("Recent", value: "\(summary.recentReviewsCount)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func statItem(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var filterBarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ReviewsFilterChip(
                    title: "All Reviews",
                    isSelected: selectedFilter.rating == nil
                ) {
                    selectedFilter.rating = nil
                    loadReviews()
                }

                ForEach(1...5, id: \.self) { rating in
                    ReviewsFilterChip(
                        title: "\(rating) Star\(rating == 1 ? "" : "s")",
                        isSelected: selectedFilter.rating == rating
                    ) {
                        selectedFilter.rating = rating
                        loadReviews()
                    }
                }

                ReviewsFilterChip(
                    title: "Verified",
                    isSelected: selectedFilter.isVerified == true
                ) {
                    selectedFilter.isVerified = selectedFilter.isVerified == true ? nil : true
                    loadReviews()
                }
            }
            .padding(.horizontal)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading reviews...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Reviews Yet")
                .font(.headline)

            Text("Be the first to leave a review!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var reviewsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.reviews) { review in
                    ReviewsRowView(review: review)
                        .padding(.horizontal)
                }

                // Load More Button
                if viewModel.hasMoreReviews {
                    Button {
                        loadMoreReviews()
                    } label: {
                        if viewModel.isLoadingMore {
                            ProgressView()
                        } else {
                            Text("Load More Reviews")
                        }
                    }
                    .padding()
                }
            }
            .padding(.vertical)
        }
    }

    private func loadInitialData() async {
        await viewModel.loadReviews(
            for: revieweeId,
            type: reviewType,
            filters: selectedFilter
        )
    }

    private func loadReviews() {
        Task {
            await viewModel.loadReviews(
                for: revieweeId,
                type: reviewType,
                filters: selectedFilter
            )
        }
    }

    private func loadMoreReviews() {
        Task {
            await viewModel.loadMoreReviews()
        }
    }
}

// MARK: - Supporting Views

struct ReviewsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ReviewsRowView: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Profile Image
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text((review.reviewer?.displayName ?? "A").prefix(1).uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(review.isAnonymous ? "Anonymous" : (review.reviewer?.displayName ?? "Unknown"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if review.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Group {
                        if let date = ISO8601DateFormatter().date(from: review.createdAt) {
                            Text(date, style: .relative)
                        } else {
                            Text(review.createdAt)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(star <= review.rating ? .yellow : .gray)
                    }
                }
            }

            // Review Title
            if let title = review.title, !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Review Content
            Text(review.content)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            // Review Type Badge
            HStack {
                ReviewTypeBadge(type: review.reviewType)
                Spacer()

                // Helpful Count
                if review.helpfulCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                            .font(.caption)
                        Text("\(review.helpfulCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ReviewTypeBadge: View {
    let type: ReviewType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption)
            Text(type.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct ReviewsListView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewsListView(
            revieweeId: "user123",
            reviewType: .user
        )
    }
}