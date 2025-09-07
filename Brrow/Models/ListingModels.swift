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
    let apiId: String
    let firstName: String?
    let lastName: String?
    let username: String?
    let profilePictureUrl: String?
    let bio: String?
    let averageRating: Double?
    let totalRatings: Int?
    let emailVerifiedAt: Date?
    let idmeVerified: Bool?
    let createdAt: Date?
}

// MARK: - Category
struct Category: Codable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let parentId: String?
    let isActive: Bool
    let sortOrder: Int?
    let createdAt: Date?
    let updatedAt: Date?
}

// MARK: - Listing Image
struct ListingImage: Codable {
    let id: String
    let listingId: String
    let imageUrl: String
    let thumbnailUrl: String?
    let isPrimary: Bool
    let displayOrder: Int
    let width: Int?
    let height: Int?
    let fileSize: Int?
    let uploadedAt: Date?
}

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
    let uploadedAt: Date?
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

// MARK: - Listings Response
struct ListingsResponse: Codable {
    let success: Bool
    let listings: [Listing]
    let pagination: PaginationInfo?
}

// MARK: - Pagination Info
struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

// MARK: - Search Filters
struct SearchFilters: Codable {
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

// MARK: - User Listings Response
struct UserListingsResponse: Codable {
    let success: Bool
    let listings: [Listing]
    let pagination: PaginationInfo?
}

// MARK: - Marketplace Filters
struct MarketplaceFilters: Codable {
    let minPrice: Double?
    let maxPrice: Double?
    let condition: String?
    let distance: Double?
    let verifiedOnly: Bool?
}

// MARK: - Marketplace Sort Option
enum MarketplaceSortOption: String, Codable {
    case recent = "createdAt"
    case priceLow = "price_asc"
    case priceHigh = "price_desc"
    case popular = "viewCount"
    case distance = "distance"
}