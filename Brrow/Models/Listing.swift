//
//  Listing.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreData

// MARK: - PriceType Enum
enum PriceType: String, Codable, CaseIterable {
    case free = "free"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case fixed = "fixed"
}

// MARK: - PromotionType Enum
enum PromotionType: String, Codable {
    case autoPromote = "auto_promote"
    case payOnSale = "pay_on_sale"
}

// MARK: - PromotionStatus Enum
enum PromotionStatus: String, Codable {
    case active = "active"
    case inactive = "inactive"
    case expired = "expired"
    case used = "used"
}

// MARK: - Listing Status Enum
enum ListingStatus: String, Codable, CaseIterable {
    case available = "AVAILABLE"
    case sold = "SOLD"
    case pending = "PENDING"
    case reserved = "RESERVED"
    case deleted = "DELETED"
}

// MARK: - Listing Model (Codable for API)
struct Listing: Codable, Identifiable, Equatable {
    static func == (lhs: Listing, rhs: Listing) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Core fields from backend
    let id: String  // Using the Prisma cuid
    let title: String
    let description: String
    let categoryId: String
    let condition: String  // Changed from ItemCondition to String
    let price: Double
    let isNegotiable: Bool
    let availabilityStatus: ListingStatus
    let location: Location
    let userId: String
    let viewCount: Int
    let favoriteCount: Int
    let isActive: Bool
    let isPremium: Bool
    let premiumExpiresAt: String?  // Changed to String to avoid date decoding issues
    let deliveryOptions: DeliveryOptions?
    let tags: [String]
    let metadata: [String: String]?  // Changed from Any to String for Codable
    let createdAt: String  // Changed to String to avoid date decoding issues
    let updatedAt: String  // Changed to String to avoid date decoding issues
    
    // Relationships
    let user: UserInfo?
    let category: CategoryModel?
    let images: [ListingImage]
    let videos: [ListingVideo]?
    
    // Backend-provided count data
    let _count: ListingCount?
    
    // Client-side properties
    var isOwner: Bool?
    var isFavorite: Bool = false
    
    struct ListingCount: Codable {
        let favorites: Int
    }
    
    // Legacy support (computed properties for backward compatibility)
    var listingId: String { id }
    var imageUrls: [String] { 
        images.compactMap { image in
            if let url = image.url ?? image.imageUrl {
                return url
            }
            return nil
        }
    }
    var status: String { availabilityStatus.rawValue }
    var views: Int { viewCount }
    var inventoryAmt: Int { 1 } // Default
    var isArchived: Bool { !isActive }
    var ownerUsername: String? { user?.username }
    var ownerProfilePicture: String? { user?.profilePictureUrl }
    var ownerRating: Double? { user?.averageRating }
    var ownerVerified: Bool { user?.emailVerifiedAt != nil || user?.idmeVerified == true }
    var isPromoted: Bool { isPremium }
    var allowsOffers: Bool { isNegotiable }
    var deliveryAvailable: Bool? { deliveryOptions?.delivery ?? false }
    
    // Computed properties
    var isFree: Bool {
        return price == 0
    }
    
    var locationString: String {
        return location.formattedAddress
    }
    
    var distanceText: String? {
        // Calculate distance client-side if needed
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, categoryId, condition, price
        case isNegotiable, availabilityStatus, location, userId
        case viewCount, favoriteCount, isActive, isPremium
        case premiumExpiresAt, deliveryOptions, tags, metadata
        case createdAt, updatedAt, user, category, images, videos
        case _count
        // NOTE: isOwner and isFavorite are client-side only, not from API
    }
    
    // Helper methods
    var hasValidImages: Bool {
        return !images.isEmpty
    }
    
    var firstImageUrl: String? {
        return imageUrls.first
    }
    
    var isAvailable: Bool { 
        return isActive && availabilityStatus == .available
    }
    
    var priceDisplay: String {
        if price == 0 {
            return "Free"
        } else {
            return String(format: "$%.0f", price)
        }
    }
    
    var latitude: Double {
        return location.latitude
    }
    
    var longitude: Double {
        return location.longitude
    }
    
    var specifications: [(key: String, value: String)] {
        // This would be populated from API
        return []
    }
    
    // Example for preview
    static let example = Listing(
        id: "lst_example_drill",
        title: "DeWalt 20V Max Cordless Drill",
        description: "Professional-grade cordless drill perfect for home improvement projects. Includes two batteries, charger, and carrying case. Well-maintained and ready to use.",
        categoryId: "cat_tools",
        condition: "GOOD",
        price: 25.0,
        isNegotiable: true,
        availabilityStatus: ListingStatus.available,
        location: Location(
            address: "123 Main St",
            city: "San Francisco",
            state: "CA",
            zipCode: "94105",
            country: "USA",
            latitude: 37.7749,
            longitude: -122.4194
        ),
        userId: "usr_example",
        viewCount: 145,
        favoriteCount: 12,
        isActive: true,
        isPremium: false,
        premiumExpiresAt: nil as String?,
        deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
        tags: ["tools", "construction", "dewalt"],
        metadata: nil as [String: String]?,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        updatedAt: ISO8601DateFormatter().string(from: Date()),
        user: nil as UserInfo?,
        category: nil as CategoryModel?,
        images: [],
        videos: nil as [ListingVideo]?,
        _count: ListingCount(favorites: 0),
        isOwner: false,
        isFavorite: false
    )
}

// MARK: - Core Data Entity
@objc(ListingEntity)
public class ListingEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var listingId: String
    @NSManaged public var userId: Int32
    @NSManaged public var userApiId: String
    @NSManaged public var title: String
    @NSManaged public var listingDescription: String
    @NSManaged public var price: String
    @NSManaged public var pricePerDay: String?
    @NSManaged public var buyoutValue: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var status: String
    @NSManaged public var category: String
    @NSManaged public var location: String
    @NSManaged public var views: Int32
    @NSManaged public var timesBorrowed: Int32
    @NSManaged public var inventoryAmt: Int32
    @NSManaged public var isFree: Bool
    @NSManaged public var isArchived: Bool
    @NSManaged public var type: String
    @NSManaged public var rating: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var images: Data? // JSON encoded array
    @NSManaged public var activeRenters: Data? // JSON encoded array
    @NSManaged public var isFavorite: Bool
    
    // Relationships
    @NSManaged public var owner: UserEntity?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var offers: NSSet?
}