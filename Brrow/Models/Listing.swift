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
    case upcoming = "UPCOMING"           // New listings awaiting moderation approval
    case available = "AVAILABLE"         // Approved, ready for transactions
    case inTransaction = "IN_TRANSACTION" // Payment hold active (visible in marketplace)
    case rented = "RENTED"               // Currently being rented (visible in marketplace)
    case sold = "SOLD"                   // Permanently sold
    case reserved = "RESERVED"           // Seller reserved (maintenance, etc.)
    case removed = "REMOVED"             // Admin/moderation removed

    // Professional user-facing display text
    var displayText: String {
        switch self {
        case .upcoming: return "Under Review"
        case .available: return "Available"
        case .inTransaction: return "Pending Sale"
        case .rented: return "Currently Rented"
        case .sold: return "Sold"
        case .reserved: return "Reserved"
        case .removed: return "Unavailable"
        }
    }

    // Badge color for visual consistency
    var badgeColor: String {
        switch self {
        case .upcoming: return "orange"
        case .available: return "green"
        case .inTransaction: return "blue"
        case .rented: return "purple"
        case .sold: return "gray"
        case .reserved: return "yellow"
        case .removed: return "red"
        }
    }

    // Whether this listing should show in marketplace
    var isPubliclyVisible: Bool {
        switch self {
        case .upcoming, .removed: return false
        case .available, .inTransaction, .rented, .sold, .reserved: return true
        }
    }

    // Whether user can initiate purchase/rental
    var canPurchase: Bool {
        return self == .available
    }
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
    let estimatedValue: Double?  // Estimated value for rental insurance
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

    // MARK: - Rental Helper Properties

    /// Determines if this listing is a rental based on the presence of dailyRate
    var isRental: Bool {
        return dailyRate != nil
    }

    /// Returns the appropriate display price (dailyRate for rentals, price for sales)
    var displayPrice: Double {
        return dailyRate ?? price
    }

    /// Returns the price suffix ("/day" for rentals, empty for sales)
    var priceSuffix: String {
        return isRental ? "/day" : ""
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case categoryId = "category_id"
        case condition, price
        case dailyRate = "daily_rate"
        case estimatedValue = "estimated_value"
        case pricingType = "pricing_type"
        case isNegotiable = "is_negotiable"
        case availabilityStatus = "availability_status"
        case location
        case userId = "user_id"
        case viewCount = "view_count"
        case favoriteCount = "favorite_count"
        case isActive = "is_active"
        case isPremium = "is_premium"
        case premiumExpiresAt = "premium_expires_at"
        case deliveryOptions = "delivery_options"
        case tags, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case category = "categories"  // API returns "categories" but we store as "category"
        case images = "listing_images"  // API returns "listing_images" but we store as "images"
        case videos
        case imageUrl = "image_url"
        case _count
        case apiImageUrlsFromAPI = "imageUrls"
        // NOTE: isOwner and isFavorite are client-side only, not from API
    }

    // Custom decoder to handle string location from API and both camelCase/snake_case
    init(from decoder: Decoder) throws {
        // Handle both camelCase and snake_case by trying raw keys
        enum RawKeys: String, CodingKey {
            case id, title, description, condition, price, location, tags, metadata, user, videos, imageUrl
            // camelCase versions
            case categoryId, dailyRate, estimatedValue, pricingType, isNegotiable, availabilityStatus, userId
            case viewCount, favoriteCount, isActive, isPremium, premiumExpiresAt, deliveryOptions
            case createdAt, updatedAt, category, images
            // snake_case versions
            case category_id, daily_rate, estimated_value, pricing_type, is_negotiable, availability_status, user_id
            case view_count, favorite_count, is_active, is_premium, premium_expires_at, delivery_options
            case created_at, updated_at, categories, listing_images, imageUrls, _count
        }

        let rawContainer = try decoder.container(keyedBy: RawKeys.self)

        id = try rawContainer.decode(String.self, forKey: .id)
        title = try rawContainer.decode(String.self, forKey: .title)
        description = try rawContainer.decode(String.self, forKey: .description)

        // Try both camelCase and snake_case for categoryId
        if let val = try? rawContainer.decode(String.self, forKey: .categoryId) {
            categoryId = val
        } else {
            categoryId = try rawContainer.decode(String.self, forKey: .category_id)
        }

        condition = try rawContainer.decode(String.self, forKey: .condition)
        price = try rawContainer.decode(Double.self, forKey: .price)

        // Try both formats for dailyRate
        if let val = try? rawContainer.decodeIfPresent(Double.self, forKey: .dailyRate) {
            dailyRate = val
        } else {
            dailyRate = try? rawContainer.decodeIfPresent(Double.self, forKey: .daily_rate)
        }

        // Try both formats for estimatedValue
        if let val = try? rawContainer.decodeIfPresent(Double.self, forKey: .estimatedValue) {
            estimatedValue = val
        } else {
            estimatedValue = try? rawContainer.decodeIfPresent(Double.self, forKey: .estimated_value)
        }

        // Try both formats for pricingType
        if let val = try? rawContainer.decodeIfPresent(String.self, forKey: .pricingType) {
            pricingType = val
        } else {
            pricingType = try? rawContainer.decodeIfPresent(String.self, forKey: .pricing_type)
        }

        // Try both formats for isNegotiable
        if let val = try? rawContainer.decode(Bool.self, forKey: .isNegotiable) {
            isNegotiable = val
        } else {
            isNegotiable = try rawContainer.decode(Bool.self, forKey: .is_negotiable)
        }

        // Try both formats for availabilityStatus
        if let val = try? rawContainer.decode(ListingStatus.self, forKey: .availabilityStatus) {
            availabilityStatus = val
        } else {
            availabilityStatus = try rawContainer.decode(ListingStatus.self, forKey: .availability_status)
        }

        // Handle location - can be string or object
        if let locationString = try? rawContainer.decode(String.self, forKey: .location) {
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
            location = try rawContainer.decode(Location.self, forKey: .location)
        }

        // Try both formats for userId
        if let val = try? rawContainer.decode(String.self, forKey: .userId) {
            userId = val
        } else {
            userId = try rawContainer.decode(String.self, forKey: .user_id)
        }

        // Try both formats for viewCount
        if let val = try? rawContainer.decodeIfPresent(Int.self, forKey: .viewCount) {
            viewCount = val
        } else {
            viewCount = (try? rawContainer.decodeIfPresent(Int.self, forKey: .view_count)) ?? 0
        }

        // Try both formats for favoriteCount
        if let val = try? rawContainer.decodeIfPresent(Int.self, forKey: .favoriteCount) {
            favoriteCount = val
        } else {
            favoriteCount = (try? rawContainer.decodeIfPresent(Int.self, forKey: .favorite_count)) ?? 0
        }

        // Try both formats for isActive
        if let val = try? rawContainer.decodeIfPresent(Bool.self, forKey: .isActive) {
            isActive = val
        } else {
            isActive = (try? rawContainer.decodeIfPresent(Bool.self, forKey: .is_active)) ?? true
        }

        // Try both formats for isPremium
        if let val = try? rawContainer.decodeIfPresent(Bool.self, forKey: .isPremium) {
            isPremium = val
        } else {
            isPremium = (try? rawContainer.decodeIfPresent(Bool.self, forKey: .is_premium)) ?? false
        }

        // Try both formats for premiumExpiresAt
        if let val = try? rawContainer.decodeIfPresent(String.self, forKey: .premiumExpiresAt) {
            premiumExpiresAt = val
        } else {
            premiumExpiresAt = try? rawContainer.decodeIfPresent(String.self, forKey: .premium_expires_at)
        }

        // Try both formats for deliveryOptions
        if let val = try? rawContainer.decodeIfPresent(DeliveryOptions.self, forKey: .deliveryOptions) {
            deliveryOptions = val
        } else {
            deliveryOptions = try? rawContainer.decodeIfPresent(DeliveryOptions.self, forKey: .delivery_options)
        }

        tags = (try? rawContainer.decodeIfPresent([String].self, forKey: .tags)) ?? []
        metadata = try? rawContainer.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)

        // Try both formats for createdAt
        if let val = try? rawContainer.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = val
        } else {
            createdAt = (try? rawContainer.decodeIfPresent(String.self, forKey: .created_at)) ?? ""
        }

        // Try both formats for updatedAt
        if let val = try? rawContainer.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = val
        } else {
            updatedAt = (try? rawContainer.decodeIfPresent(String.self, forKey: .updated_at)) ?? ""
        }

        user = try? rawContainer.decodeIfPresent(UserInfo.self, forKey: .user)

        // Try both formats for category
        if let val = try? rawContainer.decodeIfPresent(CategoryModel.self, forKey: .category) {
            category = val
        } else {
            category = try? rawContainer.decodeIfPresent(CategoryModel.self, forKey: .categories)
        }

        // Try both formats for images
        if let val = try? rawContainer.decodeIfPresent([ListingImage].self, forKey: .images) {
            images = val
        } else {
            images = (try? rawContainer.decodeIfPresent([ListingImage].self, forKey: .listing_images)) ?? []
        }

        videos = try? rawContainer.decodeIfPresent([ListingVideo].self, forKey: .videos)

        // imageUrl field (try direct field name)
        imageUrl = try? rawContainer.decodeIfPresent(String.self, forKey: .imageUrl)

        apiImageUrlsFromAPI = try? rawContainer.decodeIfPresent([String].self, forKey: .imageUrls)
        _count = try? rawContainer.decodeIfPresent(ListingCount.self, forKey: ._count)

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
    
    // Whether listing should show in marketplace (new logic: show multiple statuses)
    var isAvailable: Bool {
        return isActive && availabilityStatus.isPubliclyVisible
    }

    // Whether user can actually purchase/rent this listing
    var canInitiatePurchase: Bool {
        return isActive && availabilityStatus.canPurchase
    }

    // Status badge display text - context-aware for IN_TRANSACTION status
    var statusDisplayText: String {
        // For IN_TRANSACTION status, check if it's a rental or sale
        if availabilityStatus == .inTransaction {
            return listingType == "rental" ? "Rental Pending" : "Sale Pending"
        }
        return availabilityStatus.displayText
    }

    // Status badge color
    var statusBadgeColor: String {
        return availabilityStatus.badgeColor
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