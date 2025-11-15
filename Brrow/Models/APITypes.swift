//
//  APITypes.swift
//  Brrow
//
//  Missing API Type Definitions
//

import Foundation

// MARK: - Registration Response (wrapper for registration endpoint)
struct RegistrationResponse: Codable {
    let success: Bool
    let message: String?
    let user: User
    let accessToken: String
    let refreshToken: String
    let verificationToken: String?
}

// MARK: - Authentication Response
struct AuthResponse: Codable {
    let token: String?
    let accessToken: String?
    let refreshToken: String?
    let user: User
    let expiresAt: String?
    let isNewUser: Bool?
    
    // Computed property to get the actual token (supports both formats)
    var authToken: String? {
        return accessToken ?? token
    }
    
    init(token: String, user: User, expiresAt: String? = nil) {
        self.token = token
        self.accessToken = nil
        self.refreshToken = nil
        self.user = user
        self.expiresAt = expiresAt
        self.isNewUser = nil
    }
    
    init(token: String? = nil, accessToken: String? = nil, refreshToken: String? = nil, user: User, expiresAt: String? = nil, isNewUser: Bool? = nil) {
        self.token = token
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
        self.expiresAt = expiresAt
        self.isNewUser = isNewUser
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode both token formats
        self.token = try container.decodeIfPresent(String.self, forKey: .token)
        self.accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)

        // User is required
        self.user = try container.decode(User.self, forKey: .user)

        // Optional fields
        self.expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        self.isNewUser = try container.decodeIfPresent(Bool.self, forKey: .isNewUser)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(token, forKey: .token)
        try container.encodeIfPresent(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encode(user, forKey: .user)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(isNewUser, forKey: .isNewUser)
    }

    private enum CodingKeys: String, CodingKey {
        case token
        case accessToken
        case refreshToken
        case user
        case expiresAt = "expires_at"
        case isNewUser
    }
}

// MARK: - Listings Response
struct ListingsResponse: Codable {
    let success: Bool
    let listings: [Listing]?  // Backend returns listings directly
    let data: ListingsDataWrapper?  // Sometimes returns nested data
    let message: String?
    let total: Int?
    let page: Int?
    let limit: Int?

    // Handle multiple response formats
    var allListings: [Listing] {
        // First check if listings is directly available
        if let directListings = listings {
            return directListings
        }
        // Check for nested data.listings
        if let nestedData = data {
            if let nestedListings = nestedData.listings {
                return nestedListings
            }
            // Handle case where data is a direct array of listings
            if let directArray = nestedData.directArray {
                return directArray
            }
        }
        return []
    }

    // Flexible data wrapper to handle different API response formats
    struct ListingsDataWrapper: Codable {
        let listings: [Listing]?
        let pagination: PaginationData?
        let directArray: [Listing]?

        init(from decoder: Decoder) throws {
            // Try to decode as object with listings array first
            if let container = try? decoder.container(keyedBy: CodingKeys.self) {
                listings = try container.decodeIfPresent([Listing].self, forKey: .listings)
                pagination = try container.decodeIfPresent(PaginationData.self, forKey: .pagination)
                directArray = nil
            } else {
                // Try to decode as direct array of listings
                let arrayContainer = try decoder.singleValueContainer()
                if let array = try? arrayContainer.decode([Listing].self) {
                    directArray = array
                    listings = nil
                    pagination = nil
                } else {
                    // Fallback
                    listings = nil
                    pagination = nil
                    directArray = nil
                }
            }
        }

        enum CodingKeys: String, CodingKey {
            case listings, pagination
        }
    }

    struct ListingsData: Codable {
        let listings: [Listing]
        let pagination: PaginationData?
    }

    struct PaginationData: Codable {
        let total: Int
        let page: Int?
        let perPage: Int?
        let totalPages: Double?  // API returns as float
        let hasMore: Bool?

        // Support both field names for compatibility
        let limit: Int?
        let offset: Int?
        let pages: Int?

        enum CodingKeys: String, CodingKey {
            case total
            case page
            case perPage = "per_page"
            case totalPages = "total_pages"
            case hasMore = "has_more"
            case limit
            case offset
            case pages
        }

        // Computed property for compatibility
        var pageLimit: Int {
            return perPage ?? limit ?? 20
        }
    }
}

// MARK: - User Listings Response
struct UserListingsResponse: Codable {
    let success: Bool
    let data: UserListingsData?
    let message: String?

    // Handle listings access uniformly
    var allListings: [Listing] {
        return data?.listings ?? []
    }

    struct UserListingsData: Codable {
        let listings: [Listing]
        let stats: ListingStats?
        let total: Int?  // Optional for backward compatibility
        
        struct ListingStats: Codable {
            let total_listings: Int
            let active_listings: Int
            let archived_listings: Int
            let total_views: Int
            let total_borrowed: Int
        }
    }
}

// MARK: - User Rating
struct UserRating: Codable, Identifiable {
    let id: Int
    let rating: Double
    let review: String
    let reviewerName: String
    let reviewerProfilePicture: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case rating
        case review
        case reviewerName = "reviewer_name"
        case reviewerProfilePicture = "reviewer_profile_picture"
        case createdAt = "created_at"
    }
}

// MARK: - Empty Response
struct EmptyResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - Success Response
struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
    let data: [String: APIAnyCodable]?
}

// MARK: - APIAnyCodable for dynamic JSON
struct APIAnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([APIAnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: APIAnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode APIAnyCodable")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { APIAnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { APIAnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode APIAnyCodable"))
        }
    }
}

// MARK: - Password Reset Response
struct PasswordResetResponse: Codable {
    let success: Bool
    let message: String?
    let data: PasswordResetData?

    struct PasswordResetData: Codable {
        let token: String?
        let user: User?
    }
}

// MARK: - RSVP Response
struct RSVPResponse: Codable {
    let success: Bool
    let message: String?
    let data: RSVPData?
    
    struct RSVPData: Codable {
        let rsvpStatus: String?
        let totalRSVPs: Int?
        
        enum CodingKeys: String, CodingKey {
            case rsvpStatus = "rsvp_status"
            case totalRSVPs = "total_rsvps"
        }
    }
}

// MARK: - Favorite Response
struct FavoriteResponse: Codable {
    let success: Bool
    let message: String?
    let data: FavoriteData?
    
    struct FavoriteData: Codable {
        let isFavorited: Bool?
        let totalFavorites: Int?
        
        enum CodingKeys: String, CodingKey {
            case isFavorited = "is_favorited"
            case totalFavorites = "total_favorites"
        }
    }
}

// MARK: - Image Upload Response
struct APIImageUploadResponse: Codable {
    let success: Bool
    let message: String?
    let data: ImageUploadData?
    
    struct ImageUploadData: Codable {
        let url: String
        let publicId: String?
        
        enum CodingKeys: String, CodingKey {
            case url
            case publicId = "public_id"
        }
    }
}

// PaginationInfo moved to be the single definition used throughout

// MARK: - Profile Picture Upload Response
struct ProfilePictureUploadResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfilePictureData?
    
    struct ProfilePictureData: Codable {
        let url: String
        let thumbnailUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case url
            case thumbnailUrl = "thumbnail_url"
        }
    }
}

// MARK: - Karma Badges (removed but keeping for compatibility)
struct KarmaBadges: Codable {
    let badges: [String]
    
    init() {
        self.badges = []
    }
}

// MARK: - Karma Response (removed per user request)

// MARK: - Request Types
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let birthdate: String
}

struct AppleLoginRequest: Codable {
    let appleUserId: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let identityToken: String
}

// MARK: - User Achievements Response (matches backend actual response)
struct UserAchievementsResponse: Codable {
    let success: Bool
    let achievements: [Achievement]
    let points: Int
    let totalAchievements: Int
    let unlockedAchievements: Int

    enum CodingKeys: String, CodingKey {
        case success
        case achievements
        case points
        case totalAchievements = "total_achievements"
        case unlockedAchievements = "unlocked_achievements"
    }
}

// MARK: - Achievement Model (matches backend response)
struct Achievement: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let unlocked: Bool
    let points: Int
}

// MARK: - Create Listing Request
// CreateListingRequest moved to ListingModels.swift

// MARK: - Additional Missing Types
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case status
        case data
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle both "success" (bool) and "status" (string) fields
        if let successBool = try? container.decode(Bool.self, forKey: .success) {
            self.success = successBool
        } else if let statusString = try? container.decode(String.self, forKey: .status) {
            self.success = (statusString == "success")
        } else {
            self.success = false
        }
        
        self.data = try container.decodeIfPresent(T.self, forKey: .data)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(message, forKey: .message)
    }
}

struct FetchListingsAPIResponse: Codable {
    let success: Bool
    let data: FetchListingsData?
    let message: String?

    // Handle listings access uniformly
    var allListings: [Listing] {
        return data?.listings ?? []
    }

    struct FetchListingsData: Codable {
        let listings: [Listing]
        let pagination: ListingsResponse.PaginationData?
        
        // Custom decoder to handle both simple and complex responses
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Try to decode listings
            self.listings = try container.decodeIfPresent([Listing].self, forKey: .listings) ?? []
            
            // Pagination is optional
            self.pagination = try? container.decode(ListingsResponse.PaginationData.self, forKey: .pagination)
        }
        
        private enum CodingKeys: String, CodingKey {
            case listings
            case pagination
        }
    }
}

struct FeaturedListingsAPIResponse: Codable {
    let success: Bool
    let data: FeaturedListingsData?
    let message: String?
    
    struct FeaturedListingsData: Codable {
        let listings: [Listing]
        let pagination: ListingsResponse.PaginationData?
        
        // Custom decoder to handle both simple array and nested structure
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Try to decode listings directly
            if let listingsArray = try? container.decode([Listing].self, forKey: .listings) {
                self.listings = listingsArray
            } else {
                // Fall back to empty array if decoding fails
                self.listings = []
            }
            
            // Pagination is optional
            self.pagination = try? container.decode(ListingsResponse.PaginationData.self, forKey: .pagination)
        }
        
        private enum CodingKeys: String, CodingKey {
            case listings
            case pagination
        }
    }
}

struct SearchSuggestionsResponse: Codable {
    let suggestions: [String]
}

struct FavoritesResponse: Codable {
    let success: Bool
    let favorites: [FavoriteItem]?  // Backend returns array of favorite items with nested listing
    let pagination: FavoritePagination?
    let message: String?

    // Nested favorite item structure
    struct FavoriteItem: Codable {
        let id: String
        let favoriteId: String
        let favoritedAt: String
        let listing: Listing
    }

    struct FavoritePagination: Codable {
        let page: Int
        let limit: Int
        let totalCount: Int
        let totalPages: Int
        let hasNextPage: Bool
        let hasPreviousPage: Bool
    }

    // Computed property for easy access to listings (extracts listing from each favorite item)
    var listings: [Listing] {
        return favorites?.map { $0.listing } ?? []
    }
}

struct FavoriteStatusResponse: Codable {
    let success: Bool
    let isFavorited: Bool
    let message: String?
}

struct UserPost: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let imageUrl: String?
    let createdAt: String
    let updatedAt: String
    let postType: String
    let status: String
    let price: Double?
    let category: String?
    let thumbnail: String?
    let urgency: String?
    let editRestrictions: [String]?
    let canEdit: Bool?

    // Computed property for display thumbnail
    var displayThumbnail: String? {
        return thumbnail ?? imageUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, updatedAt, postType, status, price, category, thumbnail, urgency, editRestrictions, canEdit
        case imageUrl = "image_url"
    }
}

struct UserPostsResponse: Codable {
    let success: Bool
    let posts: [UserPost]
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success, posts, total, limit, offset, message
        case hasMore = "has_more"
    }
}

struct CreateOfferRequest: Codable {
    let listingId: String
    let amount: Double
    let message: String?
}

struct UpdateProfileRequest: Codable {
    let name: String
    let bio: String
}

struct UpdateProfileImageRequest: Codable {
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}

struct ToggleFavoriteRequest: Codable {
    let listingId: Int
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case listingId = "listing_id"
        case userId = "user_id"
    }
}

struct RSVPRequest: Codable {
    let garageSaleId: String
    let isRsvp: Bool
    
    enum CodingKeys: String, CodingKey {
        case garageSaleId = "garage_sale_id"
        case isRsvp = "is_rsvp"
    }
}

struct GarageSaleFavoriteRequest: Codable {
    let garageSaleId: String
    
    enum CodingKeys: String, CodingKey {
        case garageSaleId = "garage_sale_id"
    }
}

struct ToggleActiveRequest: Codable {
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

struct ToggleFeaturedRequest: Codable {
    let isFeatured: Bool
    
    enum CodingKeys: String, CodingKey {
        case isFeatured = "is_featured"
    }
}

struct UpdateOfferStatusRequest: Codable {
    let offerId: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case offerId = "offer_id"
        case status
    }
}

struct UpdateTransactionStatusRequest: Codable {
    let transactionId: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
        case status
    }
}

struct APIExtendTransactionRequest: Codable {
    let transactionId: String
    let additionalDays: Int
    
    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
        case additionalDays = "additional_days"
    }
}

struct CreateListingWithPromotionRequest: Codable {
    let listing: CreateListingRequest
    let promotion: PromotionRequest?
}

struct CreateListingWithPromotionResponse: Codable {
    let success: Bool
    let listing: Listing?
    let promotion: PromotionData?
    let message: String?
}

struct PromotionRequest: Codable {
    let type: String
    let duration: Int
}

struct PromotionData: Codable {
    let id: String
    let type: String
    let startDate: String
    let endDate: String
    let paymentRequired: Bool?
    let paymentIntentId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case startDate = "start_date"
        case endDate = "end_date"
        case paymentRequired = "payment_required"
        case paymentIntentId = "payment_intent_id"
    }
}

struct ConfirmPromotionRequest: Codable {
    let promotionId: String
    let paymentMethod: String
    
    enum CodingKeys: String, CodingKey {
        case promotionId = "promotion_id"
        case paymentMethod = "payment_method"
    }
}

struct PromotionConfirmationResponse: Codable {
    let success: Bool
    let message: String?
    let paymentRequired: Bool?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case paymentRequired = "payment_required"
    }
}

struct APIMessagesResponse: Codable {
    let success: Bool
    let messages: [Message]
    let pagination: PaginationInfo?
}

struct APICategory: Codable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let parentId: String?
    let isActive: Bool
    let sortOrder: Int?
    let createdAt: String?
    let updatedAt: String?

    // Computed property for backward compatibility
    var icon: String {
        return iconUrl ?? "📦"
    }

    // Map backend snake_case to iOS camelCase
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconUrl = "icon_url"
        case parentId = "parent_id"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// CategoriesResponse moved to ResponseTypes.swift

// MARK: - ID.me Verification Types
struct UpdateVerificationStatusRequest: Codable {
    let isVerified: Bool
    let verificationLevel: String?
    let verificationProvider: String
    
    enum CodingKeys: String, CodingKey {
        case isVerified = "is_verified"
        case verificationLevel = "verification_level"
        case verificationProvider = "verification_provider"
    }
}

struct UserVerificationResponse: Codable {
    let success: Bool
    let data: UserVerificationData?
    let message: String?
    
    struct UserVerificationData: Codable {
        let isVerified: Bool
        let verificationLevel: String?
        let verificationProvider: String?
        let verifiedAt: String?
        
        enum CodingKeys: String, CodingKey {
            case isVerified = "is_verified"
            case verificationLevel = "verification_level"
            case verificationProvider = "verification_provider"
            case verifiedAt = "verified_at"
        }
    }
}

// MARK: - Enum Types
enum OfferStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case cancelled = "cancelled"
    case expired = "expired"
}

enum TransactionStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    case disputed = "disputed"
}

// MARK: - Earnings Response Types
struct FixedEarningsOverviewResponse: Codable {
    let success: Bool
    let message: String?
    let data: EarningsOverviewData
    let timestamp: String?
    
    struct EarningsOverviewData: Codable {
        let overview: EarningsOverviewInfo
        let monthlyEarnings: [MonthlyEarning]?
        let topListings: [TopListing]?
        let payoutInfo: PayoutInfo
    }
    
    struct EarningsOverviewInfo: Codable {
        // NEW BALANCE SYSTEM FIELDS
        let availableBalance: Double?
        let pendingBalance: Double?
        let totalEarned: Double?
        let totalWithdrawn: Double?
        let hasStripeConnected: Bool?
        let canRequestPayout: Bool?

        // LEGACY FIELDS (keep for compatibility)
        let lifetimeEarnings: Double?
        let lifetimeSpent: Double?
        let netEarnings: Double?
        let platformFees: Double?
        let pendingEarnings: Double?
        let activeEarnings: Double?
        let totalRentals: Int?
        let totalBorrowings: Int?
        let averageRentalValue: Double?
        let totalSales: Int?

        enum CodingKeys: String, CodingKey {
            case availableBalance = "availableBalance"
            case pendingBalance = "pendingBalance"
            case totalEarned = "totalEarned"
            case totalWithdrawn = "totalWithdrawn"
            case hasStripeConnected = "hasStripeConnected"
            case canRequestPayout = "canRequestPayout"
            case lifetimeEarnings = "lifetimeEarnings"
            case lifetimeSpent = "lifetimeSpent"
            case netEarnings = "netEarnings"
            case platformFees = "platformFees"
            case pendingEarnings = "pendingEarnings"
            case activeEarnings = "activeEarnings"
            case totalRentals = "totalRentals"
            case totalBorrowings = "totalBorrowings"
            case averageRentalValue = "averageRentalValue"
            case totalSales = "totalSales"
        }
    }
    
    struct MonthlyEarning: Codable {
        let month: String
        let earnings: Double
    }
    
    struct TopListing: Codable {
        let id: String
        let title: String
        let earnings: Double
    }
    
    struct PayoutInfo: Codable {
        let nextPayoutDate: String?
        let minimumPayout: Double?
        let payoutMethod: String?
        let isPayoutEnabled: Bool?
        let availableBalance: Double?
        let stripeAccountId: String?
        let accountStatus: String?

        // Payout tier information
        let payoutTier: String?          // "New User", "Verified User", "Trusted Seller"
        let payoutTierCode: String?      // "UNVERIFIED", "VERIFIED", "TRUSTED"
        let holdDays: Int?               // 7, 5, or 3
        let emailVerified: Bool?
        let idVerified: Bool?
        let completedSales: Int?

        enum CodingKeys: String, CodingKey {
            case nextPayoutDate = "nextPayoutDate"
            case minimumPayout = "minimumPayout"
            case payoutMethod = "payoutMethod"
            case isPayoutEnabled = "isPayoutEnabled"
            case availableBalance = "availableBalance"
            case stripeAccountId = "stripeAccountId"
            case accountStatus = "accountStatus"
            case payoutTier = "payoutTier"
            case payoutTierCode = "payoutTierCode"
            case holdDays = "holdDays"
            case emailVerified = "emailVerified"
            case idVerified = "idVerified"
            case completedSales = "completedSales"
        }
    }
}

// MARK: - Email Verification Types
struct EmailVerificationResponse: Codable {
    let success: Bool
    let message: String
    let email: String?
    let alreadyVerified: Bool?
    let expiresInHours: Int?
    
    enum CodingKeys: String, CodingKey {
        case success, message, email
        case alreadyVerified = "already_verified"
        case expiresInHours = "expires_in_hours"
    }
}

struct CreatorStatusResponse: Codable {
    let success: Bool
    let data: CreatorStatus?
    let message: String?
}

struct CreatorStatus: Codable {
    let isCreator: Bool
    let status: String
    let canApply: Bool
    let applicationId: String?
    let createdAt: String?
    let approvedAt: String?
}

// CreatorBadgeType moved to CreatorModels.swift to avoid duplication

// MARK: - Password Management Types
struct PasswordValidationResponse: Codable {
    let valid: Bool
    let errors: [String]?
}

struct CheckPasswordExistsResponse: Codable {
    let success: Bool
    let hasPassword: Bool
    let authMethod: String?

    enum CodingKeys: String, CodingKey {
        case success
        case hasPassword = "has_password"
        case authMethod = "auth_method"
    }
}

// MARK: - Purchase/Transaction Types
struct PurchasesListResponse: Codable {
    let success: Bool
    let data: PurchasesData
    let message: String?

    struct PurchasesData: Codable {
        let purchases: [PurchaseSummary]
        let pagination: PurchasesPagination?
    }

    struct PurchasesPagination: Codable {
        let total: Int
        let page: Int
        let limit: Int
    }

    // Convenience property for backward compatibility
    var purchases: [PurchaseSummary] {
        return data.purchases
    }
}

struct PurchaseSummary: Codable, Identifiable {
    let id: String
    let transactionDisplayId: String?
    let buyerId: String
    let sellerId: String
    let listingId: String
    let amount: Double
    let paymentStatus: String
    let verificationStatus: String
    let purchaseType: String
    let createdAt: String
    let deadline: String
    let capturedAt: String?
    let cancelledAt: String?
    let cancellationReason: String?
    let sellerConfirmed: Bool
    let buyerConfirmed: Bool
    let isActive: Bool
    let isPast: Bool
    let buyer: PurchaseUser?
    let seller: PurchaseUser?
    let listing: PurchaseListing?
    let meetup: PurchaseMeetup?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionDisplayId = "transaction_display_id"
        case buyerId = "buyer_id"
        case sellerId = "seller_id"
        case listingId = "listing_id"
        case amount
        case paymentStatus = "payment_status"
        case verificationStatus = "verification_status"
        case purchaseType = "purchase_type"
        case createdAt = "created_at"
        case deadline
        case capturedAt = "captured_at"
        case cancelledAt = "cancelled_at"
        case cancellationReason = "cancellation_reason"
        case sellerConfirmed = "seller_confirmed"
        case buyerConfirmed = "buyer_confirmed"
        case isActive = "is_active"
        case isPast = "is_past"
        case buyer, seller, listing, meetup
    }
}

struct PurchaseDetailResponse: Codable {
    let success: Bool
    let purchase: PurchaseDetail
    let message: String?
}

struct PurchaseDetail: Codable, Identifiable {
    let id: String
    let transactionDisplayId: String?
    let buyerId: String
    let sellerId: String
    let listingId: String
    let amount: Double
    let paymentStatus: String
    let verificationStatus: String
    let purchaseType: String
    let createdAt: String
    let deadline: String
    let capturedAt: String?
    let refundedAt: String?
    let cancelledAt: String?
    let cancellationReason: String?
    let sellerConfirmed: Bool
    let buyerConfirmed: Bool
    let sellerConfirmedAt: String?
    let buyerConfirmedAt: String?
    let buyer: PurchaseUser?
    let seller: PurchaseUser?
    let listing: PurchaseListingDetail?
    let meetup: PurchaseMeetup?
    let timeline: [TimelineStep]
    let receipt: Receipt
    let isBuyer: Bool
    let otherParty: PurchaseUser?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionDisplayId = "transaction_display_id"
        case buyerId = "buyer_id"
        case sellerId = "seller_id"
        case listingId = "listing_id"
        case amount
        case paymentStatus = "payment_status"
        case verificationStatus = "verification_status"
        case purchaseType = "purchase_type"
        case createdAt = "created_at"
        case deadline
        case capturedAt = "captured_at"
        case refundedAt = "refunded_at"
        case cancelledAt = "cancelled_at"
        case cancellationReason = "cancellation_reason"
        case sellerConfirmed = "seller_confirmed"
        case buyerConfirmed = "buyer_confirmed"
        case sellerConfirmedAt = "seller_confirmed_at"
        case buyerConfirmedAt = "buyer_confirmed_at"
        case buyer, seller, listing, meetup, timeline, receipt
        case isBuyer = "is_buyer"
        case otherParty = "other_party"
    }
}

struct TimelineStep: Codable, Identifiable {
    var id: Int { step }
    let step: Int
    let status: String // completed, in_progress, pending
    let title: String
    let description: String
    let completedAt: String?
    let meetupScheduled: Bool?
    let icon: String

    enum CodingKeys: String, CodingKey {
        case step, status, title, description
        case completedAt = "completed_at"
        case meetupScheduled = "meetup_scheduled"
        case icon
    }
}

struct Receipt: Codable {
    let subtotal: Double
    let stripeFee: Double
    let stripeFeeNote: String
    let total: Double
    let currency: String

    enum CodingKeys: String, CodingKey {
        case subtotal
        case stripeFee = "stripe_fee"
        case stripeFeeNote = "stripe_fee_note"
        case total, currency
    }
}

struct PurchaseUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let profilePictureUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case profilePictureUrl = "profile_picture_url"
    }

    // Convert PurchaseUser to full User model for messaging
    func toUser() -> User {
        return User(
            id: id,
            username: username,
            email: "",  // Not available from PurchaseUser
            apiId: id,  // Use the same ID for API requests
            profilePicture: profilePictureUrl,
            listerRating: nil,
            renteeRating: nil,
            bio: nil,
            emailVerified: false,
            idVerified: false,
            stripeLinked: false
        )
    }
}

struct PurchaseListing: Codable {
    let id: String
    let title: String
    let price: Double
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, price
        case imageUrl = "image_url"
    }
}

struct PurchaseListingDetail: Codable {
    let id: String
    let title: String
    let description: String
    let price: Double
    let listingImages: [ListingImage]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, price
        case listingImages = "listing_images"
    }
}

struct PurchaseMeetup: Codable {
    let id: String
    let status: String
    let scheduledTime: String?
    let meetupLocation: MeetupLocation?
    let buyerArrivedAt: String?
    let sellerArrivedAt: String?
    let verifiedAt: String?
    let verificationMethod: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case scheduledTime = "scheduled_time"
        case meetupLocation = "meetup_location"
        case buyerArrivedAt = "buyer_arrived_at"
        case sellerArrivedAt = "seller_arrived_at"
        case verifiedAt = "verified_at"
        case verificationMethod = "verification_method"
    }
}

struct PurchaseAcceptResponse: Codable {
    let success: Bool
    let message: String
    let purchase: PurchaseSummary?
}

struct PurchaseDeclineResponse: Codable {
    let success: Bool
    let message: String
}