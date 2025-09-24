import Foundation
import SwiftUI

// MARK: - Transaction Models
// Using Transaction from Models/Transaction.swift instead
/*
struct Transaction: Codable, Identifiable {
    let id: String
    let buyerId: String
    let sellerId: String
    let listingId: String
    let transactionType: TransactionType
    let status: TransactionStatus
    let amount: Double
    let rentalStartDate: Date?
    let rentalEndDate: Date?
    let completedAt: Date?
    let buyerReviewed: Bool
    let sellerReviewed: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Populated relations
    let buyer: TransactionUser?
    let seller: TransactionUser?
    let listing: TransactionListing?
    
    enum TransactionType: String, Codable {
        case purchase = "PURCHASE"
        case rental = "RENTAL"
    }
    
    enum TransactionStatus: String, Codable {
        case pending = "PENDING"
        case inProgress = "IN_PROGRESS"
        case completed = "COMPLETED"
        case cancelled = "CANCELLED"
        case disputed = "DISPUTED"
    }
}

struct TransactionUser: Codable {
    let id: String
    let username: String
    let profilePictureUrl: String?
    let averageRating: Double?
    let totalRatings: Int?
}

struct TransactionListing: Codable {
    let id: String
    let title: String
    let price: Double?
    let images: [TransactionListingImage]?
    let category: Category?
    
    struct TransactionListingImage: Codable {
        let id: String
        let url: String
        let isPrimary: Bool
    }
    
    struct Category: Codable {
        let id: String
        let name: String
    }
}
*/

struct CreateTransactionRequest: Codable {
    let listingId: String
    let sellerId: String
    let transactionType: String
    let amount: Double?
    let rentalStartDate: Date?
    let rentalEndDate: Date?
}

struct ReviewTransactionStats: Codable {
    let asBuyer: TransactionStat
    let asSeller: TransactionStat
    let pending: Int
    
    struct TransactionStat: Codable {
        let total: Int
        let completed: Int
    }
}

// MARK: - Review Service
@MainActor
class ReviewService: ObservableObject {
    static let shared = ReviewService()
    private let apiClient = APIClient.shared
    
    @Published var userReviews: [Review] = []
    @Published var listingReviews: [Review] = []
    @Published var reviewSummary: ReviewSummary?
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Review Operations
    
    func fetchUserReviews(userId: String, type: String = "all", page: Int = 1) async throws -> (reviews: [Review], stats: ReviewStats) {
        let queryString = "?type=\(type)&page=\(page)&limit=20"
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews/user/\(userId)\(queryString)",
            method: "GET",
            responseType: APIResponse<ReviewListResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch reviews")
        }
        
        return (data.reviews, data.stats)
    }
    
    func fetchListingReviews(listingId: String, page: Int = 1) async throws -> (reviews: [Review], stats: ReviewStats) {
        let queryString = "?page=\(page)&limit=20"
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews/listing/\(listingId)\(queryString)",
            method: "GET",
            responseType: APIResponse<ReviewListResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch listing reviews")
        }
        
        return (data.reviews, data.stats)
    }
    
    func submitReview(_ request: CreateReviewRequest) async throws -> Review {
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: ReviewAPIResponse.self
        )

        guard response.success, let review = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to submit review")
        }

        return review
    }

    func createReview(targetId: String, rating: Int, comment: String?, reviewType: String = "GENERAL", listingId: String? = nil, transactionId: String? = nil) async throws -> Review {
        let request = CreateReviewRequest(
            revieweeId: targetId,
            listingId: listingId,
            transactionId: transactionId,
            rating: rating,
            title: nil,
            content: comment ?? "",
            reviewType: ReviewType(rawValue: reviewType) ?? .seller,
            isAnonymous: false,
            criteriaRatings: nil,
            attachments: nil
        )

        return try await submitReview(request)
    }
    
    func updateReview(reviewId: String, rating: Int? = nil, comment: String? = nil) async throws -> Review {
        var body: [String: Any] = [:]
        if let rating = rating { body["rating"] = rating }
        if let comment = comment { body["comment"] = comment }
        
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews/\(reviewId)",
            method: "PATCH",
            body: try JSONSerialization.data(withJSONObject: body),
            responseType: APIResponse<Review>.self
        )
        
        guard response.success, let review = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update review")
        }
        
        return review
    }
    
    func deleteReview(reviewId: String) async throws {
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews/\(reviewId)",
            method: "DELETE",
            responseType: APIResponse<EmptyResponse>.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to delete review")
        }
    }
    
    func canReview(targetId: String, listingId: String? = nil) async throws -> CanReviewResponse {
        var queryString = ""
        if let listingId = listingId {
            queryString = "?listingId=\(listingId)"
        }
        
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews/can-review/\(targetId)\(queryString)",
            method: "GET",
            responseType: APIResponse<CanReviewResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to check review eligibility")
        }
        
        return data
    }
    
    func fetchReviewSummary(userId: String) async throws -> ReviewSummary {
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews/summary/\(userId)",
            method: "GET",
            responseType: APIResponse<ReviewSummary>.self
        )
        
        guard response.success, let summary = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch review summary")
        }
        
        return summary
    }
    
    func reportReview(reviewId: String, reason: String, description: String?) async throws {
        let body: [String: Any] = [
            "reason": reason,
            "description": description ?? ""
        ]
        
        let response = try await apiClient.performRequest(
            endpoint: "api/reviews/\(reviewId)/report",
            method: "POST",
            body: try JSONSerialization.data(withJSONObject: body),
            responseType: APIResponse<EmptyResponse>.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to report review")
        }
    }
}

// MARK: - Transaction Service
@MainActor
class TransactionService: ObservableObject {
    static let shared = TransactionService()
    private let apiClient = APIClient.shared
    
    @Published var transactions: [Transaction] = []
    @Published var currentTransaction: Transaction?
    @Published var stats: ReviewTransactionStats?
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Transaction Operations
    
    func createTransaction(listingId: String, sellerId: String, transactionType: String, amount: Double? = nil, rentalStartDate: Date? = nil, rentalEndDate: Date? = nil) async throws -> Transaction {
        let request = CreateTransactionRequest(
            listingId: listingId,
            sellerId: sellerId,
            transactionType: transactionType,
            amount: amount,
            rentalStartDate: rentalStartDate,
            rentalEndDate: rentalEndDate
        )
        
        let response = try await apiClient.performRequest(
            endpoint: "api/transactions",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: APIResponse<Transaction>.self
        )
        
        guard response.success, let transaction = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create transaction")
        }
        
        return transaction
    }
    
    func fetchMyTransactions(role: String = "all", status: String? = nil, page: Int = 1) async throws -> [Transaction] {
        var queryString = "?role=\(role)&page=\(page)&limit=20"
        if let status = status {
            queryString += "&status=\(status)"
        }
        
        let response = try await apiClient.performRequest(
            endpoint: "api/transactions/my-transactions\(queryString)",
            method: "GET",
            responseType: APIResponse<TransactionListResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch transactions")
        }
        
        return data.data
    }
    
    func fetchTransactionDetails(transactionId: String) async throws -> Transaction {
        let response = try await apiClient.performRequest(
            endpoint: "api/transactions/\(transactionId)",
            method: "GET",
            responseType: APIResponse<Transaction>.self
        )
        
        guard response.success, let transaction = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch transaction details")
        }
        
        return transaction
    }
    
    func updateTransactionStatus(transactionId: String, status: String) async throws -> Transaction {
        let body: [String: Any] = ["status": status]
        
        let response = try await apiClient.performRequest(
            endpoint: "api/transactions/\(transactionId)/status",
            method: "PATCH",
            body: try JSONSerialization.data(withJSONObject: body),
            responseType: APIResponse<Transaction>.self
        )
        
        guard response.success, let transaction = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update transaction status")
        }
        
        return transaction
    }
    
    func markTransactionReviewed(transactionId: String) async throws {
        let response = try await apiClient.performRequest(
            endpoint: "api/transactions/\(transactionId)/reviewed",
            method: "PATCH",
            responseType: APIResponse<Transaction>.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to mark transaction as reviewed")
        }
    }
    
    func fetchTransactionStats() async throws -> ReviewTransactionStats {
        let response = try await apiClient.performRequest(
            endpoint: "api/transactions/stats/summary",
            method: "GET",
            responseType: APIResponse<ReviewTransactionStats>.self
        )
        
        guard response.success, let stats = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch transaction stats")
        }
        
        return stats
    }
}

// MARK: - Helper Response Types
// Using ReviewListResponse from ReviewModels.swift

private struct TransactionListResponse: Codable {
    let data: [Transaction]
    let pagination: PaginationInfo?
}

// Using PaginationInfo and EmptyResponse from APITypes.swift instead