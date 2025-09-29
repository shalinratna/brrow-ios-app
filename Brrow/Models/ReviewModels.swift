//
//  ReviewModels.swift
//  Brrow
//
//  Comprehensive review and rating system models
//

import Foundation

// MARK: - Review Model

struct Review: Codable, Identifiable {
    let id: String
    let reviewerId: String
    let revieweeId: String
    let listingId: String?
    let transactionId: String?
    let rating: Int  // 1-5 stars
    let title: String?
    let content: String
    let comment: String?
    let reviewType: ReviewType
    let isVerified: Bool
    let isAnonymous: Bool
    let helpfulCount: Int
    let reportCount: Int
    let status: ReviewStatus
    let createdAt: String
    let updatedAt: String
    let moderatedAt: String?
    let moderatorId: String?
    let moderationNote: String?

    // Related models
    let reviewer: UserInfo?
    let reviewee: UserInfo?
    let listing: ListingInfo?
    let transaction: TransactionInfo?
    let responses: [ReviewResponse]?
    let attachments: [ReviewAttachment]?

    enum CodingKeys: String, CodingKey {
        case id, reviewerId, revieweeId, listingId, transactionId
        case rating, title, content, comment, reviewType, isVerified, isAnonymous
        case helpfulCount, reportCount, status, createdAt, updatedAt
        case moderatedAt, moderatorId, moderationNote
        case reviewer, reviewee, listing, transaction, responses, attachments
    }
}

enum ReviewType: String, Codable, CaseIterable {
    case general = "GENERAL"    // General review
    case seller = "SELLER"      // Review of a seller
    case buyer = "BUYER"        // Review of a buyer
    case listing = "LISTING"    // Review of a specific listing/item
    case service = "SERVICE"    // Review of service quality
    case platform = "PLATFORM"  // Review of the platform itself

    var displayName: String {
        switch self {
        case .general: return "General Review"
        case .seller: return "Seller Review"
        case .buyer: return "Buyer Review"
        case .listing: return "Item Review"
        case .service: return "Service Review"
        case .platform: return "Platform Review"
        }
    }

    var icon: String {
        switch self {
        case .general: return "message.fill"
        case .seller: return "person.fill"
        case .buyer: return "cart.fill"
        case .listing: return "tag.fill"
        case .service: return "handshake.fill"
        case .platform: return "star.fill"
        }
    }
}

enum ReviewStatus: String, Codable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case flagged = "FLAGGED"
    case hidden = "HIDDEN"

    var displayName: String {
        switch self {
        case .pending: return "Under Review"
        case .approved: return "Published"
        case .rejected: return "Rejected"
        case .flagged: return "Flagged"
        case .hidden: return "Hidden"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .flagged: return "yellow"
        case .hidden: return "gray"
        }
    }
}

// MARK: - Review Response

struct ReviewResponse: Codable, Identifiable {
    let id: String
    let reviewId: String
    let responderId: String
    let content: String
    let isOfficial: Bool  // Response from Brrow team
    let createdAt: String
    let updatedAt: String

    let responder: UserInfo?

    enum CodingKeys: String, CodingKey {
        case id, reviewId, responderId, content, isOfficial
        case createdAt, updatedAt, responder
    }
}

// MARK: - Review Attachment

struct ReviewAttachment: Codable, Identifiable {
    let id: String
    let reviewId: String
    let fileUrl: String
    let thumbnailUrl: String?
    let fileType: ReviewAttachmentType
    let fileName: String
    let fileSize: Int
    let uploadedAt: String

    enum CodingKeys: String, CodingKey {
        case id, reviewId, fileUrl, thumbnailUrl, fileType
        case fileName, fileSize, uploadedAt
    }
}

enum ReviewAttachmentType: String, Codable {
    case image = "IMAGE"
    case video = "VIDEO"
    case document = "DOCUMENT"
}

// MARK: - Rating Summary

struct RatingSummary: Codable {
    let averageRating: Double
    let totalReviews: Int
    let ratingDistribution: [Int: Int]  // Rating -> Count
    let verifiedReviewsCount: Int
    let recentReviewsCount: Int  // Reviews in last 30 days

    // Computed properties
    var formattedAverageRating: String {
        return String(format: "%.1f", averageRating)
    }

    var ratingPercentages: [Int: Double] {
        var percentages: [Int: Double] = [:]
        for rating in 1...5 {
            let count = ratingDistribution[rating] ?? 0
            percentages[rating] = totalReviews > 0 ? Double(count) / Double(totalReviews) * 100 : 0
        }
        return percentages
    }
}

// MARK: - User Rating Profile

struct UserRatingProfile: Codable {
    let userId: String
    let overallRating: Double
    let totalReviews: Int
    let sellerRating: RatingSummary?
    let buyerRating: RatingSummary?
    let responseRate: Double?  // Response rate to messages
    let responseTime: String?  // Average response time
    let verificationLevel: UserVerificationLevel
    let trustScore: Int  // 0-100
    let joinDate: String
    let totalTransactions: Int
    let successfulTransactions: Int

    enum CodingKeys: String, CodingKey {
        case userId, overallRating, totalReviews
        case sellerRating, buyerRating, responseRate, responseTime
        case verificationLevel, trustScore, joinDate
        case totalTransactions, successfulTransactions
    }
}

enum UserVerificationLevel: String, Codable {
    case none = "NONE"
    case email = "EMAIL"
    case phone = "PHONE"
    case identity = "IDENTITY"
    case full = "FULL"

    var displayName: String {
        switch self {
        case .none: return "Unverified"
        case .email: return "Email Verified"
        case .phone: return "Phone Verified"
        case .identity: return "ID Verified"
        case .full: return "Fully Verified"
        }
    }

    var icon: String {
        switch self {
        case .none: return "questionmark.circle"
        case .email: return "envelope.circle.fill"
        case .phone: return "phone.circle.fill"
        case .identity: return "person.crop.circle.badge.checkmark"
        case .full: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Review Criteria

struct ReviewCriteria: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let reviewType: ReviewType
    let isRequired: Bool
    let maxRating: Int
    let order: Int

    // Predefined criteria
    static let sellerCriteria: [ReviewCriteria] = [
        ReviewCriteria(
            id: "communication",
            name: "Communication",
            description: "How well did the seller communicate?",
            reviewType: .seller,
            isRequired: true,
            maxRating: 5,
            order: 1
        ),
        ReviewCriteria(
            id: "item_accuracy",
            name: "Item as Described",
            description: "Was the item exactly as described?",
            reviewType: .seller,
            isRequired: true,
            maxRating: 5,
            order: 2
        ),
        ReviewCriteria(
            id: "shipping_speed",
            name: "Shipping Speed",
            description: "How quickly was the item shipped?",
            reviewType: .seller,
            isRequired: false,
            maxRating: 5,
            order: 3
        ),
        ReviewCriteria(
            id: "packaging",
            name: "Packaging",
            description: "How well was the item packaged?",
            reviewType: .seller,
            isRequired: false,
            maxRating: 5,
            order: 4
        )
    ]

    static let buyerCriteria: [ReviewCriteria] = [
        ReviewCriteria(
            id: "payment_speed",
            name: "Payment Speed",
            description: "How quickly did the buyer pay?",
            reviewType: .buyer,
            isRequired: true,
            maxRating: 5,
            order: 1
        ),
        ReviewCriteria(
            id: "communication",
            name: "Communication",
            description: "How well did the buyer communicate?",
            reviewType: .buyer,
            isRequired: true,
            maxRating: 5,
            order: 2
        ),
        ReviewCriteria(
            id: "pickup_punctuality",
            name: "Pickup/Meeting",
            description: "Was the buyer punctual for pickup/meeting?",
            reviewType: .buyer,
            isRequired: false,
            maxRating: 5,
            order: 3
        )
    ]
}

// MARK: - Review Templates

struct ReviewTemplate: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let rating: Int
    let reviewType: ReviewType
    let isPositive: Bool
    let usageCount: Int

    // Predefined templates
    static let positiveSellerTemplates: [ReviewTemplate] = [
        ReviewTemplate(
            id: "excellent_seller",
            title: "Excellent Seller",
            content: "Great communication, item exactly as described, fast shipping. Highly recommend!",
            rating: 5,
            reviewType: .seller,
            isPositive: true,
            usageCount: 0
        ),
        ReviewTemplate(
            id: "good_transaction",
            title: "Smooth Transaction",
            content: "Easy transaction, good communication, item as expected. Thank you!",
            rating: 4,
            reviewType: .seller,
            isPositive: true,
            usageCount: 0
        )
    ]

    static let negativeFeedbackTemplates: [ReviewTemplate] = [
        ReviewTemplate(
            id: "item_different",
            title: "Item Not as Described",
            content: "Item was different from description. Communication could be better.",
            rating: 2,
            reviewType: .seller,
            isPositive: false,
            usageCount: 0
        )
    ]
}

// MARK: - Review Analytics

struct ReviewAnalytics: Codable {
    let period: AnalyticsPeriod
    let totalReviews: Int
    let averageRating: Double
    let ratingTrend: [DateRatingPoint]
    let topKeywords: [KeywordCount]
    let sentimentScore: Double  // -1 to 1
    let responseRate: Double
    let moderationStats: ModerationStats

    struct DateRatingPoint: Codable {
        let date: String
        let averageRating: Double
        let reviewCount: Int
    }

    struct KeywordCount: Codable {
        let keyword: String
        let count: Int
        let sentiment: String  // positive, negative, neutral
    }

    struct ModerationStats: Codable {
        let totalReviews: Int
        let approvedReviews: Int
        let rejectedReviews: Int
        let flaggedReviews: Int
        let averageProcessingTime: Double  // hours
    }
}

enum AnalyticsPeriod: String, Codable {
    case week = "WEEK"
    case month = "MONTH"
    case quarter = "QUARTER"
    case year = "YEAR"
    case allTime = "ALL_TIME"
}

// MARK: - API Request/Response Models

struct CreateReviewRequest: Codable {
    let revieweeId: String
    let listingId: String?
    let transactionId: String?
    let rating: Int
    let title: String?
    let content: String
    let reviewType: ReviewType
    let isAnonymous: Bool
    let criteriaRatings: [String: Int]?  // criteriaId -> rating
    let attachments: [ReviewAttachmentUpload]?
}

struct ReviewAttachmentUpload: Codable {
    let fileData: String  // base64 encoded
    let fileName: String
    let fileType: ReviewAttachmentType
}

struct UpdateReviewRequest: Codable {
    let rating: Int?
    let title: String?
    let content: String?
    let status: ReviewStatus?
    let moderationNote: String?
}

struct ReviewsResponse: Codable {
    let success: Bool
    let data: ReviewsData?
    let message: String?

    struct ReviewsData: Codable {
        let reviews: [Review]
        let pagination: PaginationInfo?
        let ratingSummary: RatingSummary?
    }
}

struct ReviewAPIResponse: Codable {
    let success: Bool
    let data: Review?
    let message: String?
}

struct RatingProfileResponse: Codable {
    let success: Bool
    let data: UserRatingProfile?
    let message: String?
}

struct ReviewAnalyticsResponse: Codable {
    let success: Bool
    let data: ReviewAnalytics?
    let message: String?
}

// MARK: - Review Filters

struct ReviewFilters: Codable {
    var rating: Int?
    var reviewType: ReviewType?
    var status: ReviewStatus?
    var isVerified: Bool?
    var dateRange: DateRange?
    var sortBy: ReviewSortOption
    var sortOrder: SortOrder

    struct DateRange: Codable {
        let startDate: String
        let endDate: String
    }
}

enum ReviewSortOption: String, Codable, CaseIterable {
    case newest = "NEWEST"
    case oldest = "OLDEST"
    case highestRated = "HIGHEST_RATED"
    case lowestRated = "LOWEST_RATED"
    case mostHelpful = "MOST_HELPFUL"

    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .highestRated: return "Highest Rated"
        case .lowestRated: return "Lowest Rated"
        case .mostHelpful: return "Most Helpful"
        }
    }
}

// MARK: - Supporting Models


struct ListingInfo: Codable {
    let id: String
    let title: String
    let imageUrl: String?
    let price: Double
}

struct TransactionInfo: Codable {
    let id: String
    let type: String
    let amount: Double
    let completedAt: String
}

// MARK: - Missing Review Service Types

struct ReviewSummary: Codable {
    let averageRating: Double
    let totalReviews: Int
    let ratingDistribution: [Int: Int]
}

struct ReviewStats: Codable {
    let totalReviews: Int
    let averageRating: Double
    let responseRate: Double
    let ratingBreakdown: [Int]
}

struct CanReviewResponse: Codable {
    let canReview: Bool
    let reason: String?
}

struct ReviewListResponse: Codable {
    let reviews: [Review]
    let stats: ReviewStats
    let pagination: PaginationInfo?
}