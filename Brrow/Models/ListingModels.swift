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
}

// MARK: - Create Listing Request
struct CreateListingRequest: Codable {
    let title: String
    let description: String
    let price: Double
    let categoryId: String
    let condition: String
    let location: Location
    let isNegotiable: Bool
    let deliveryOptions: DeliveryOptions?
    let tags: [String]?
    let images: [ImageUpload]?
    let videos: [VideoUpload]?
    
    struct ImageUpload: Codable {
        let url: String
        let thumbnailUrl: String?
        let width: Int?
        let height: Int?
        let fileSize: Int?
    }
    
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