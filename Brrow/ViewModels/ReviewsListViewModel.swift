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

        // Simulate API call for now
        try await Task.sleep(nanoseconds: 500_000_000)

        let mockReviews = generateMockReviews(count: page == 1 ? 10 : 5)
        let mockSummary = generateMockRatingSummary()

        return (
            reviews: mockReviews,
            summary: page == 1 ? mockSummary : nil,
            hasMore: page < 3
        )
    }

    private func generateMockReviews(count: Int) -> [Review] {
        var reviews: [Review] = []
        for index in 0..<count {
            let randomContent = [
                "Excellent communication and fast delivery. Would definitely rent from again!",
                "Good quality item, exactly as described. Professional seller.",
                "Quick response and easy pickup. Item was in perfect condition.",
                "Smooth transaction, very reliable. Highly recommended!",
                "Great service and attention to detail. Will use again."
            ].randomElement() ?? ""

            let randomReviewType = [ReviewType.seller, ReviewType.buyer].randomElement() ?? .seller
            let randomName = ["Alice Johnson", "Bob Smith", "Carol Davis", "David Wilson", "Emma Brown"].randomElement() ?? "User"
            let randomTitle = ["Camera Equipment", "Bike", "Tools", "Electronics"].randomElement() ?? "Item"

            let userInfo = UserInfo(
                id: "reviewer_\(index)",
                username: randomName,
                profilePictureUrl: nil,
                averageRating: Double.random(in: 3.5...5.0),
                bio: nil,
                totalRatings: nil,
                isVerified: Bool.random(),
                createdAt: nil
            )

            var listingInfo: ListingInfo? = nil
            if index % 2 == 0 {
                listingInfo = ListingInfo(
                    id: "listing_\(index)",
                    title: randomTitle,
                    imageUrl: nil,
                    price: Double.random(in: 10...100)
                )
            }

            let review = Review(
                id: "review_\(index)_\(UUID().uuidString)",
                reviewerId: "reviewer_\(index)",
                revieweeId: currentRevieweeId ?? "",
                listingId: index % 2 == 0 ? "listing_\(index)" : nil,
                transactionId: index % 3 == 0 ? "transaction_\(index)" : nil,
                rating: Int.random(in: 3...5),
                title: index % 2 == 0 ? "Great experience!" : nil,
                content: randomContent,
                comment: randomContent,
                reviewType: randomReviewType,
                isVerified: Bool.random(),
                isAnonymous: index % 4 == 0,
                helpfulCount: Int.random(in: 0...5),
                reportCount: 0,
                status: .approved,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-TimeInterval(index * 86400))),
                updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-TimeInterval(index * 86400))),
                moderatedAt: nil,
                moderatorId: nil,
                moderationNote: nil,
                reviewer: userInfo,
                reviewee: nil,
                listing: listingInfo,
                transaction: nil,
                responses: nil,
                attachments: nil
            )
            reviews.append(review)
        }
        return reviews
    }

    private func generateMockRatingSummary() -> RatingSummary {
        let totalReviews = Int.random(in: 25...100)
        let averageRating = Double.random(in: 4.0...5.0)

        let distribution: [Int: Int] = [
            5: Int(Double(totalReviews) * 0.6),
            4: Int(Double(totalReviews) * 0.25),
            3: Int(Double(totalReviews) * 0.1),
            2: Int(Double(totalReviews) * 0.03),
            1: Int(Double(totalReviews) * 0.02)
        ]

        return RatingSummary(
            averageRating: averageRating,
            totalReviews: totalReviews,
            ratingDistribution: distribution,
            verifiedReviewsCount: Int(Double(totalReviews) * 0.7),
            recentReviewsCount: Int.random(in: 5...15)
        )
    }
}