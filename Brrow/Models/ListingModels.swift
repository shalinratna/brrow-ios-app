//
//  ListingModels.swift
//  Brrow
//
//  Supporting models for Listing functionality
//

import Foundation

// MARK: - User Info (for listing owner)
struct UserInfo: Codable {
    let id: String
    let username: String?
    let profilePictureUrl: String?
    let averageRating: Double?
    
    // Additional fields only for detailed views
    let bio: String?
    let totalRatings: Int?
    let isVerified: Bool?
    let createdAt: String? // Store as String to avoid date decoding issues
    
    // Computed properties for compatibility
    var apiId: String { id }
    var firstName: String? { nil }
    var lastName: String? { nil }
    var emailVerifiedAt: Date? { nil }
    var idmeVerified: Bool? { isVerified }
    
    var displayName: String {
        return username ?? "User"
    }

    // Helper method to get the full profile picture URL
    var fullProfilePictureURL: String? {
        guard let profilePictureString = profilePictureUrl else { return nil }

        // If the URL is already complete (starts with http), return as-is
        if profilePictureString.hasPrefix("http://") || profilePictureString.hasPrefix("https://") {
            return profilePictureString
        }

        // If it's a relative path starting with /uploads/, prepend base URL
        if profilePictureString.hasPrefix("/uploads/") || profilePictureString.hasPrefix("uploads/") {
            let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
            let formattedPath = profilePictureString.hasPrefix("/") ? profilePictureString : "/\(profilePictureString)"
            return "\(baseURL)\(formattedPath)"
        }

        // For other relative paths, assume they need the base URL
        let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
        return "\(baseURL)/\(profilePictureString)"
    }
}

// MARK: - Category
struct CategoryModel: Codable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let parentId: String?
    let isActive: Bool?
    let sortOrder: Int?
    let createdAt: String? // Changed to String to avoid date decoding issues
    let updatedAt: String? // Changed to String to avoid date decoding issues

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case iconUrl = "icon_url"
        case parentId = "parent_id"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// ListingImage is defined in CreateListingResponse.swift - removed duplicate

// MARK: - Listing Video
struct ListingVideo: Codable {
    let id: String
    let listingId: String
    let videoUrl: String
    let thumbnailUrl: String?
    let duration: Int?  // in seconds
    let width: Int?
    let height: Int?
    let fileSize: Int?
    let uploadedAt: String? // Changed to String to avoid date decoding issues
}

// MARK: - Delivery Options
struct DeliveryOptions: Codable {
    let pickup: Bool
    let delivery: Bool
    let shipping: Bool

    init(pickup: Bool = false, delivery: Bool = false, shipping: Bool = false) {
        self.pickup = pickup
        self.delivery = delivery
        self.shipping = shipping
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Provide defaults for missing fields (handles empty objects from backend)
        self.pickup = try container.decodeIfPresent(Bool.self, forKey: .pickup) ?? false
        self.delivery = try container.decodeIfPresent(Bool.self, forKey: .delivery) ?? false
        self.shipping = try container.decodeIfPresent(Bool.self, forKey: .shipping) ?? false
    }
}

// MARK: - Create Listing Request
struct CreateListingRequest: Codable {
    let title: String
    let description: String
    let price: Double?  // Sale price (for sale listings)
    let dailyRate: Double?  // Daily rental rate (for rental listings)
    let estimatedValue: Double?  // Estimated value for rental insurance
    let categoryId: String
    let condition: String
    let location: Location
    let isNegotiable: Bool
    let deliveryOptions: DeliveryOptions?
    let tags: [String]?
    let images: [String]?  // Simplified to array of URL strings for Railway backend
    let videos: [VideoUpload]?
    
    struct VideoUpload: Codable {
        let url: String
        let thumbnailUrl: String?
        let duration: Int?
        let width: Int?
        let height: Int?
        let fileSize: Int?
    }
}

// ListingsResponse and PaginationInfo are defined in APITypes.swift - removed duplicates

// MARK: - API Search Filters
struct APISearchFilters: Codable {
    let categoryId: String?
    let minPrice: Double?
    let maxPrice: Double?
    let condition: String?
    let city: String?
    let state: String?
    let sortBy: String?
    let sortOrder: String?
    let verifiedOnly: Bool?
}

// UserListingsResponse is defined in APITypes.swift - removed duplicate

// MarketplaceFilters is defined in SharedTypes.swift - removed duplicate

// MarketplaceSortOption is defined in SharedTypes.swift - removed duplicate