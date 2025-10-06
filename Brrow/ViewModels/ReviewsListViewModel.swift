//
//  ReviewsListViewModel.swift
//  Brrow
//
//  ViewModel for managing reviews list and filtering
//

import Foundation
import SwiftUI

@MainActor
class ReviewsListViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var ratingSummary: RatingSummary?
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreReviews = false

    private let reviewService = ReviewService.shared
    private var currentPage = 1
    private var currentFilters: ReviewFilters?
    private var currentRevieweeId: String?
    private var currentType: ReviewsListView.ReviewDisplayType?

    func loadReviews(
        for revieweeId: String,
        type: ReviewsListView.ReviewDisplayType,
        filters: ReviewFilters
    ) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1
        currentFilters = filters
        currentRevieweeId = revieweeId
        currentType = type

        do {
            let result = try await fetchReviews(
                revieweeId: revieweeId,
                type: type,
                filters: filters,
                page: currentPage
            )

            reviews = result.reviews
            if let summary = result.summary {
                ratingSummary = summary
            }
            hasMoreReviews = result.hasMore

        } catch {
            errorMessage = error.localizedDescription
            reviews = []
        }

        isLoading = false
    }

    func loadMoreReviews() async {
        guard !isLoadingMore,
              hasMoreReviews,
              let revieweeId = currentRevieweeId,
              let type = currentType,
              let filters = currentFilters else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let result = try await fetchReviews(
                revieweeId: revieweeId,
                type: type,
                filters: filters,
                page: currentPage
            )

            reviews.append(contentsOf: result.reviews)
            hasMoreReviews = result.hasMore

        } catch {
            errorMessage = error.localizedDescription
            currentPage -= 1
        }

        isLoadingMore = false
    }

    private func fetchReviews(
        revieweeId: String,
        type: ReviewsListView.ReviewDisplayType,
        filters: ReviewFilters,
        page: Int
    ) async throws -> (reviews: [Review], summary: RatingSummary?, hasMore: Bool) {

        // Fetch reviews based on type (user or listing)
        let result: (reviews: [Review], stats: ReviewStats)

        switch type {
        case .user:
            // Build type parameter for user reviews
            var userType = "all"
            if let reviewType = filters.reviewType {
                userType = reviewType == .buyer ? "as_buyer" : reviewType == .seller ? "as_seller" : "all"
            }
            result = try await reviewService.fetchUserReviews(userId: revieweeId, type: userType, page: page)

        case .listing:
            result = try await reviewService.fetchListingReviews(listingId: revieweeId, page: page)
        }

        // Build rating summary from stats (only on first page)
        var summary: RatingSummary? = nil
        if page == 1 {
            // Convert ReviewStats to RatingSummary
            let ratingBreakdown = result.stats.ratingBreakdown
            var distribution: [Int: Int] = [:]
            for (index, count) in ratingBreakdown.enumerated() {
                distribution[index + 1] = count
            }

            summary = RatingSummary(
                averageRating: result.stats.averageRating,
                totalReviews: result.stats.totalReviews,
                ratingDistribution: distribution,
                verifiedReviewsCount: result.reviews.filter { $0.isVerified }.count,
                recentReviewsCount: result.reviews.count
            )
        }

        // Determine if there are more reviews
        let hasMore = result.reviews.count == 20 // If we got a full page, there might be more

        return (
            reviews: result.reviews,
            summary: summary,
            hasMore: hasMore
        )
    }
}