//
//  APIResponses.swift
//  Brrow
//
//  API Response Models
//

import Foundation

// MARK: - Authentication
// AuthResponse is defined in APIClient.swift

// MARK: - User Stats
struct APIUserStats: Codable {
    let activeListings: Int
    let rating: Double
    let totalEarnings: Int
    let savedItems: Int
    let daysActive: Int
    let newMessages: Int
}

// MARK: - Marketplace Stats
struct MarketplaceStats: Codable {
    let available: Int
    let nearby: Int
    let todaysDeals: Int
    let categories: [CategoryCount]
    let location: LocationInfo
    let userStats: UserMarketplaceStats?
    
    struct CategoryCount: Codable {
        let name: String
        let count: Int
    }
    
    struct LocationInfo: Codable {
        let latitude: Double
        let longitude: Double
        let radius: Int
    }
    
    struct UserMarketplaceStats: Codable {
        let favorites: Int
        let myListings: Int
    }
    
    private enum CodingKeys: String, CodingKey {
        case available
        case nearby
        case todaysDeals = "todays_deals"
        case categories
        case location
        case userStats = "user_stats"
    }
}

// MARK: - Notifications
struct NotificationsResponse: Codable {
    let notifications: [APIUserNotification]
    let unreadCount: Int
    let hasMore: Bool
}

struct APIUserNotification: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: Date
    let data: [String: String]?
    let fromUser: NotificationUser?
}

struct NotificationUser: Codable {
    let id: Int
    let username: String
    let profilePicture: String?
}

// MARK: - User Activities
struct UserActivitiesResponse: Codable {
    let activities: [APIUserActivity]
    let hasMore: Bool
}

struct APIUserActivity: Codable, Identifiable {
    let id: String
    let type: String
    let description: String
    let timestamp: Date
    let metadata: [String: String]?
    let isPublic: Bool
}

// MARK: - Empty Response
// EmptyResponse is defined in APIClient.swift

// MARK: - Simple Response
struct SimpleResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - Suggestions
struct SuggestionsResponse: Codable {
    let suggestions: [String]
}

// MARK: - Image Upload
struct ImageUploadResponse: Codable {
    let url: String
    let publicId: String
}

// MARK: - Messages
struct MessagesResponse: Codable {
    let success: Bool
    let data: [Message]
    let hasMore: Bool
    
    var messages: [Message] {
        return data
    }
}

// MARK: - Notification Count
struct NotificationCountResponse: Codable {
    let unreadCount: Int
}

// MARK: - Karma removed per user request

// MARK: - Social User Review (for profile)
// SocialUserReview is defined in ProfileModels.swift

// MARK: - Monthly Earning
// MonthlyEarning is defined in ProfileModels.swift

// MARK: - Payout Request
// PayoutRequest is defined in EarningsModels.swift

// MARK: - Report Listing
struct ReportListingRequest: Codable {
    let listingId: Int
    let reason: String
    let details: String
}

// MARK: - Report Transaction Issue
struct ReportTransactionIssueRequest: Codable {
    let transactionId: Int
    let issue: String
    let details: String
}

// MARK: - Create Garage Sale
struct CreateGarageSaleRequest: Codable {
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let address: String
    let location: String // Added location field for API compatibility
    let latitude: Double
    let longitude: Double
    let categories: [String]
    let photos: [String]
    let images: [String] // Also send as images for compatibility
    let tags: [String]
    let showExactAddress: Bool
    let showPinOnMap: Bool
    let isPublic: Bool
    let startTime: String?
    let endTime: String?
    let linkedListingIds: [String]? // IDs of listings to link to this garage sale
    
    enum CodingKeys: String, CodingKey {
        case title, description, address, location, latitude, longitude, categories, photos, images, tags
        case startDate = "start_date"
        case endDate = "end_date"
        case showExactAddress = "show_exact_address"
        case showPinOnMap = "show_pin_on_map"
        case isPublic = "is_public"
        case startTime = "start_time"
        case endTime = "end_time"
        case linkedListingIds = "linked_listing_ids"
    }
}

struct CreateGarageSaleResponse: Codable {
    let success: Bool
    let message: String?
    let garageSaleId: Int?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case garageSaleId = "garage_sale_id"
    }
}

// MARK: - Create Seek
struct CreateSeekRequest: Codable {
    let title: String
    let description: String
    let category: String
    let maxPrice: Double
    let radius: Double
    let location: Location
}

// MARK: - Send Message
struct SendMessageRequest: Codable {
    let receiverId: String
    let content: String
    let messageType: String
    let conversationId: String?
    
    enum CodingKeys: String, CodingKey {
        case receiverId = "receiver_id"
        case content
        case messageType = "message_type"
        case conversationId = "conversation_id"
    }
}

// MARK: - Extend Transaction
struct ExtendTransactionRequest: Codable {
    let transactionId: Int
    let newEndDate: Date
    let additionalPrice: Double
}

// MARK: - Listing Inquiry
struct SendListingInquiryRequest: Codable {
    let listingId: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case listingId = "listing_id"
        case message
    }
}

struct ListingInquiryResponse: Codable {
    let conversationId: String
    let messageId: String
    let message: ChatMessage
    let seller: SellerInfo
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case messageId = "message_id"
        case message
        case seller
    }
}

struct SellerInfo: Codable {
    let apiId: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case apiId = "api_id"
        case username
    }
}

struct MediaUploadResponse: Codable {
    let messageId: String
    let conversationId: String
    let media: MediaInfo
    let messageType: String
    let createdAt: String
    let sizeLimit: SizeLimitInfo
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case media
        case messageType = "message_type"
        case createdAt = "created_at"
        case sizeLimit = "size_limit"
    }
}

struct MediaInfo: Codable {
    let url: String
    let thumbnailUrl: String?
    let mimeType: String
    let size: Int
    let originalName: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case thumbnailUrl = "thumbnail_url"
        case mimeType = "mime_type"
        case size
        case originalName = "original_name"
    }
}

struct SizeLimitInfo: Codable {
    let current: Int
    let used: Int
    let tierInfo: TierInfo
    
    enum CodingKeys: String, CodingKey {
        case current
        case used
        case tierInfo = "tier_info"
    }
}

struct TierInfo: Codable {
    let free: String
    let brrowGreen: String
    let brrowGold: String
    
    enum CodingKeys: String, CodingKey {
        case free
        case brrowGreen = "brrow_green"
        case brrowGold = "brrow_gold"
    }
}

// MARK: - Stripe Requests
struct CreateCheckoutSessionRequest: Codable {
    let priceId: String?
    let successUrl: String
    let cancelUrl: String
    let metadata: [String: String]?
    let customAmount: Int?
    let customDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case priceId = "price_id"
        case successUrl = "success_url"
        case cancelUrl = "cancel_url"
        case metadata
        case customAmount = "custom_amount"
        case customDescription = "custom_description"
    }
}

