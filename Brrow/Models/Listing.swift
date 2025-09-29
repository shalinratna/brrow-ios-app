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
    let dailyRate: Double?  // Optional daily rental rate
    let pricingType: String?  // Explicit pricing type from backend
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
    let metadata: [String: AnyCodable]?  // Support any JSON type for metadata
    let createdAt: String  // Changed to String to avoid date decoding issues
    let updatedAt: String  // Changed to String to avoid date decoding issues
    
    // Relationships
    let user: UserInfo?
    let category: CategoryModel?
    let images: [ListingImage]
    let videos: [ListingVideo]?

    // Backend compatibility fields
    let imageUrl: String?
    let apiImageUrlsFromAPI: [String]?  // Direct array of image URLs from API
    
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
        // First try to use direct imageUrls from API
        if let apiImageUrls = apiImageUrlsFromAPI, !apiImageUrls.isEmpty {
            return apiImageUrls
        }
        // Fall back to images array if available
        return images.compactMap { image in
            // Use the fullURL property to get the complete URL with brrowapp.com base
            return image.fullURL
        }
    }
    var status: String { availabilityStatus.rawValue }
    var views: Int { viewCount }
    var inventoryAmt: Int { 1 } // Default
    var isArchived: Bool { !isActive }
    var ownerUsername: String? { user?.username }
    var ownerProfilePicture: String? { user?.fullProfilePictureURL }
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
        case id, title, description, categoryId, condition, price, dailyRate, pricingType
        case isNegotiable, availabilityStatus, location, userId
        case viewCount, favoriteCount, isActive, isPremium
        case premiumExpiresAt, deliveryOptions, tags, metadata
        case createdAt, updatedAt, user, category, images, videos
        case imageUrl, _count
        case apiImageUrlsFromAPI = "imageUrls"
        // NOTE: isOwner and isFavorite are client-side only, not from API
    }

    // Custom decoder to handle string location from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        condition = try container.decode(String.self, forKey: .condition)
        price = try container.decode(Double.self, forKey: .price)
        dailyRate = try container.decodeIfPresent(Double.self, forKey: .dailyRate)
        pricingType = try container.decodeIfPresent(String.self, forKey: .pricingType)
        isNegotiable = try container.decode(Bool.self, forKey: .isNegotiable)
        availabilityStatus = try container.decode(ListingStatus.self, forKey: .availabilityStatus)

        // Handle location - can be string or object
        if let locationString = try? container.decode(String.self, forKey: .location) {
            // If location is a string, create a Location object with the string as city
            location = Location(
                address: locationString,
                city: locationString,
                state: "",
                zipCode: "",
                country: "",
                latitude: 0.0,
                longitude: 0.0
            )
        } else {
            // If location is an object, decode it normally
            location = try container.decode(Location.self, forKey: .location)
        }

        userId = try container.decode(String.self, forKey: .userId)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        favoriteCount = try container.decodeIfPresent(Int.self, forKey: .favoriteCount) ?? 0
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        premiumExpiresAt = try container.decodeIfPresent(String.self, forKey: .premiumExpiresAt)
        deliveryOptions = try container.decodeIfPresent(DeliveryOptions.self, forKey: .deliveryOptions)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        user = try container.decodeIfPresent(UserInfo.self, forKey: .user)
        category = try container.decodeIfPresent(CategoryModel.self, forKey: .category)

        // Handle both images array and imageUrls array formats
        if let imagesArray = try? container.decodeIfPresent([ListingImage].self, forKey: .images) {
            images = imagesArray ?? []
        } else {
            // If images array is not available, create from imageUrls if available
            images = []
        }

        videos = try container.decodeIfPresent([ListingVideo].self, forKey: .videos)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        apiImageUrlsFromAPI = try container.decodeIfPresent([String].self, forKey: .apiImageUrlsFromAPI)
        _count = try container.decodeIfPresent(ListingCount.self, forKey: ._count)

        // Client-side properties (not from API)
        isOwner = nil
        isFavorite = false
    }

    // Helper methods
    var hasValidImages: Bool {
        return !images.isEmpty
    }
    
    var firstImageUrl: String? {
        return imageUrls.first ?? imageUrl
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

    // Computed property to determine if this is for sale or rent
    var listingType: String {
        // First, use explicit pricing type from backend if available
        if let explicitType = pricingType, !explicitType.isEmpty {
            switch explicitType.lowercased() {
            case "for_sale", "sale":
                return "sale"
            case "for_rent", "rental", "rent":
                return "rental"
            case "free":
                return "free"
            default:
                // Fall through to legacy logic
                break
            }
        }

        // Legacy logic for backward compatibility
        // If daily rate exists and > 0, it's for rent (Brrow's primary business model)
        if let dailyRate = dailyRate, dailyRate > 0 {
            return "rental"
        }
        // If only price exists and > 0, it's for sale
        else if price > 0 {
            return "sale"
        }
        // If both are 0, it's free
        else {
            return "free"
        }
    }

    // Human-readable listing type
    var listingTypeDisplay: String {
        switch listingType {
        case "rental":
            return "For Rent"
        case "sale":
            return "For Sale"
        case "free":
            return "Free"
        default:
            return "Available"
        }
    }

    var specifications: [(key: String, value: String)] {
        // This would be populated from API
        return []
    }

    // Determine if this is an item or service based on category
    var itemType: String {
        guard let categoryName = category?.name else { return "Item" }

        // Services are typically intangible offerings
        let serviceCategories = [
            "Services", "Professional Services", "Home Services",
            "Tutoring", "Consulting", "Repair Services", "Cleaning",
            "Photography", "Design", "Writing", "Entertainment"
        ]

        return serviceCategories.contains(categoryName) ? "Service" : "Item"
    }
    
    // Example for preview
    static var example: Listing {
        let jsonString = """
        {
            "id": "lst_example_drill",
            "title": "DeWalt 20V Max Cordless Drill",
            "description": "Professional-grade cordless drill perfect for home improvement projects. Includes two batteries, charger, and carrying case. Well-maintained and ready to use.",
            "categoryId": "cat_tools",
            "condition": "GOOD",
            "price": 25.0,
            "dailyRate": null,
            "pricingType": "sale",
            "isNegotiable": true,
            "availabilityStatus": "AVAILABLE",
            "location": {
                "address": "123 Main St",
                "city": "San Francisco",
                "state": "CA",
                "zipCode": "94105",
                "country": "USA",
                "latitude": 37.7749,
                "longitude": -122.4194
            },
            "userId": "usr_example",
            "viewCount": 145,
            "favoriteCount": 12,
            "isActive": true,
            "isPremium": false,
            "premiumExpiresAt": null,
            "deliveryOptions": {
                "pickup": true,
                "delivery": false,
                "shipping": false
            },
            "tags": ["tools", "construction", "dewalt"],
            "metadata": null,
            "createdAt": "2024-01-15T10:30:00Z",
            "updatedAt": "2024-01-15T10:30:00Z",
            "user": null,
            "category": null,
            "images": [],
            "videos": null,
            "imageUrl": null,
            "_count": {
                "favorites": 0
            },
            "isOwner": false,
            "isFavorite": false
        }
        """

        let data = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(Listing.self, from: data)
    }

    // MARK: - Static Factory Methods
    static func temporaryFromId(listingId: String, title: String) -> Listing {
        // Create a minimal JSON string and decode it
        let jsonString = """
        {
            "id": "temp_\(listingId)",
            "title": "\(title)",
            "description": "",
            "categoryId": "temp",
            "condition": "Used",
            "price": 0.0,
            "dailyRate": null,
            "pricingType": "daily",
            "isNegotiable": false,
            "availabilityStatus": "AVAILABLE",
            "location": {
                "latitude": 0.0,
                "longitude": 0.0,
                "address": "Loading...",
                "city": "Loading...",
                "state": "Loading...",
                "zipCode": "00000",
                "country": "US"
            },
            "userId": "temp",
            "viewCount": 0,
            "favoriteCount": 0,
            "isActive": true,
            "isPremium": false,
            "premiumExpiresAt": null,
            "deliveryOptions": null,
            "tags": [],
            "metadata": null,
            "createdAt": "\(ISO8601DateFormatter().string(from: Date()))",
            "updatedAt": "\(ISO8601DateFormatter().string(from: Date()))",
            "user": {
                "id": "temp",
                "username": "Loading...",
                "profilePicture": null,
                "emailVerifiedAt": null,
                "idmeVerified": false,
                "averageRating": 0.0
            },
            "category": {
                "id": "temp",
                "name": "General",
                "icon": "📦"
            },
            "images": [],
            "videos": null,
            "imageUrl": null,
            "imageUrls": [],
            "_count": {
                "favorites": 0
            }
        }
        """

        let data = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(Listing.self, from: data)
    }
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