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

// MARK: - Listing Model (Codable for API)
struct Listing: Codable, Identifiable, Equatable {
    static func == (lhs: Listing, rhs: Listing) -> Bool {
        return lhs.listingId == rhs.listingId
    }
    let id: Int
    let listingId: String  // The proper listing ID to use for API calls
    let ownerId: Int
    let title: String
    let description: String
    let price: Double
    let priceType: PriceType
    let buyoutValue: Double?
    let createdAt: Date
    let updatedAt: Date?
    let status: String
    let category: String
    let type: String
    let location: Location
    let views: Int
    let timesBorrowed: Int
    let inventoryAmt: Int
    let isActive: Bool
    let isArchived: Bool
    let images: [String]
    let rating: Double?
    var condition: String = "Good"
    var moderationStatus: String?
    var isOwner: Bool?
    
    // Promotion properties
    var isPromoted: Bool = false
    var promotionType: PromotionType?
    var promotionFee: Double?
    var promotionStatus: PromotionStatus = .inactive
    var promotionStartDate: Date?
    var promotionEndDate: Date?
    
    // Additional properties for marketplace
    var imageUrls: [String]?
    var ownerUsername: String?
    var ownerProfilePicture: String?
    var distance: Double?
    var viewCount: Int?
    var reviewCount: Int?
    var isUrgent: Bool = false
    var isSaved: Bool = false
    
    // Client-side properties
    var isFavorite: Bool = false
    var ownerApiId: String?
    var allowsOffers: Bool = true
    var rentalPeriod: String?
    var securityDeposit: Double?
    var deliveryAvailable: Bool?
    
    // Extended owner information
    var ownerRating: Double?
    var ownerVerified: Bool = false
    var ownerBio: String?
    var ownerLocation: String?
    var ownerMemberSince: String?
    var ownerTotalListings: Int?
    
    // Computed properties
    var isFree: Bool {
        return priceType == .free || price == 0
    }
    
    var locationString: String {
        return location.formattedAddress
    }
    
    var distanceText: String? {
        guard let distance = distance else { return nil }
        if distance < 1 {
            return "\(Int(distance * 5280)) ft away"
        } else {
            return String(format: "%.1f mi away", distance)
        }
    }
    
    // Custom initializer for API responses
    init(id: Int, title: String, description: String, price: Double, category: String, 
         location: String, images: [String], userId: Int, listingId: String, 
         pricePerDay: Double, createdAt: String, status: String, datePosted: String,
         views: Int, timesBorrowed: Int, inventoryAmt: Int, isFree: Bool, 
         isActive: Bool, rating: Double?, username: String, userProfilePicture: String?,
         isFavorite: Bool, isPromoted: Bool, promotionType: String?) {
        self.id = id
        self.listingId = listingId
        self.ownerId = userId
        self.title = title
        self.description = description
        self.price = pricePerDay > 0 ? pricePerDay : price
        self.priceType = isFree ? .free : .daily
        self.buyoutValue = nil
        self.createdAt = ISO8601DateFormatter().date(from: createdAt) ?? Date()
        self.updatedAt = nil
        self.status = status
        self.category = category
        self.type = "listing"
        self.location = Location(
            address: location,
            city: "",
            state: "",
            zipCode: "",
            country: "USA",
            latitude: 0,
            longitude: 0
        )
        self.views = views
        self.timesBorrowed = timesBorrowed
        self.inventoryAmt = inventoryAmt
        self.isActive = isActive
        self.isArchived = false
        self.images = images
        self.rating = rating
        self.ownerUsername = username
        self.ownerProfilePicture = userProfilePicture
        self.isFavorite = isFavorite
        self.isPromoted = isPromoted
        self.promotionType = promotionType.flatMap { PromotionType(rawValue: $0) }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, price, status, category, type, views, rating
        case listingId = "listing_id"
        case ownerId = "owner_id"
        case priceType = "price_type"
        case buyoutValue = "buyout_value"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case location
        case timesBorrowed = "times_borrowed"
        case inventoryAmt = "inventory_amt"
        case isActive = "is_active"
        case isArchived = "is_archived"
        case images
        case isPromoted = "is_promoted"
        case promotionType = "promotion_type"
        case promotionFee = "promotion_fee"
        case promotionStatus = "promotion_status"
        case promotionStartDate = "promotion_start_date"
        case promotionEndDate = "promotion_end_date"
        case imageUrls
        case distance
        case viewCount
        case reviewCount
        case isUrgent
        case isSaved
        case moderationStatus = "moderation_status"
        case isOwner = "is_owner"
        case ownerUsername = "owner_username"
        case ownerProfilePicture = "owner_profile_picture"
        case condition
        case rentalPeriod = "rental_period"
    }
    
    // Standard initializer
    init(id: Int, listingId: String, ownerId: Int, title: String, description: String, price: Double, priceType: PriceType, buyoutValue: Double?, createdAt: Date, updatedAt: Date?, status: String, category: String, type: String, location: Location, views: Int, timesBorrowed: Int, inventoryAmt: Int, isActive: Bool, isArchived: Bool, images: [String], rating: Double?) {
        self.id = id
        self.listingId = listingId
        self.ownerId = ownerId
        self.title = title
        self.description = description
        self.price = price
        self.priceType = priceType
        self.buyoutValue = buyoutValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.category = category
        self.type = type
        self.location = location
        self.views = views
        self.timesBorrowed = timesBorrowed
        self.inventoryAmt = inventoryAmt
        self.isActive = isActive
        self.isArchived = isArchived
        self.images = images
        self.rating = rating
    }
    
    // Custom encoding to handle date formats
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(listingId, forKey: .listingId)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(price, forKey: .price)
        try container.encode(priceType, forKey: .priceType)
        try container.encodeIfPresent(buyoutValue, forKey: .buyoutValue)
        try container.encode(status, forKey: .status)
        try container.encode(category, forKey: .category)
        try container.encode(type, forKey: .type)
        try container.encode(location, forKey: .location)
        try container.encode(views, forKey: .views)
        try container.encode(timesBorrowed, forKey: .timesBorrowed)
        try container.encode(inventoryAmt, forKey: .inventoryAmt)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(rating, forKey: .rating)
        
        // Date encoding
        let dateFormatter = ISO8601DateFormatter()
        let createdAtString = dateFormatter.string(from: createdAt)
        try container.encode(createdAtString, forKey: .createdAt)
        
        if let updatedAt = updatedAt {
            let updatedAtString = dateFormatter.string(from: updatedAt)
            try container.encode(updatedAtString, forKey: .updatedAt)
        }
    }
    
    // Custom decoding to handle date formats and missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        listingId = try container.decode(String.self, forKey: .listingId)
        ownerId = try container.decodeIfPresent(Int.self, forKey: .ownerId) ?? 0
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        priceType = try container.decodeIfPresent(PriceType.self, forKey: .priceType) ?? .daily
        buyoutValue = try container.decodeIfPresent(Double.self, forKey: .buyoutValue)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Other"
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "borrow"
        
        // Handle location - might be string or object
        if let locationObject = try? container.decode(Location.self, forKey: .location) {
            location = locationObject
        } else if let locationString = try? container.decode(String.self, forKey: .location) {
            location = Location(
                address: locationString,
                city: "",
                state: "",
                zipCode: "",
                country: "USA",
                latitude: 0,
                longitude: 0
            )
        } else {
            location = Location(
                address: "Unknown",
                city: "",
                state: "",
                zipCode: "",
                country: "USA",
                latitude: 0,
                longitude: 0
            )
        }
        
        views = try container.decodeIfPresent(Int.self, forKey: .views) ?? 0
        timesBorrowed = try container.decodeIfPresent(Int.self, forKey: .timesBorrowed) ?? 0
        inventoryAmt = try container.decodeIfPresent(Int.self, forKey: .inventoryAmt) ?? 1
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        
        // Date decoding - handle multiple date formats
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = Listing.parseDate(from: createdAtString) ?? Date()
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = Listing.parseDate(from: updatedAtString)
        } else {
            updatedAt = nil
        }
        
        // Additional fields from API response
        moderationStatus = try container.decodeIfPresent(String.self, forKey: .moderationStatus)
        isOwner = try container.decodeIfPresent(Bool.self, forKey: .isOwner)
        ownerUsername = try container.decodeIfPresent(String.self, forKey: .ownerUsername)
        ownerProfilePicture = try container.decodeIfPresent(String.self, forKey: .ownerProfilePicture)
        condition = try container.decodeIfPresent(String.self, forKey: .condition) ?? "Good"
        rentalPeriod = try container.decodeIfPresent(String.self, forKey: .rentalPeriod)
    }
    
    private static func parseDate(from dateString: String) -> Date? {
        // Try ISO8601 first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try PostgreSQL format with timezone (e.g., "2025-08-13 05:32:26.456515+00")
        let postgresFormatter = DateFormatter()
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        postgresFormatter.locale = Locale(identifier: "en_US_POSIX")
        postgresFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = postgresFormatter.date(from: dateString) {
            return date
        }
        
        // Try PostgreSQL format without microseconds
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        
        if let date = postgresFormatter.date(from: dateString) {
            return date
        }
        
        // Try without timezone
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        
        if let date = postgresFormatter.date(from: dateString) {
            return date
        }
        
        // Try simple format
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = postgresFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    // Helper methods
    var hasValidImages: Bool {
        return !images.isEmpty && !images[0].isEmpty
    }
    
    var firstImageUrl: String? {
        return hasValidImages ? images[0] : nil
    }
    
    var isAvailable: Bool { 
        return isActive && !isArchived && inventoryAmt > 0
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
        id: 1,
        listingId: "lst_example_drill",
        ownerId: 1,
        title: "DeWalt 20V Max Cordless Drill",
        description: "Professional-grade cordless drill perfect for home improvement projects. Includes two batteries, charger, and carrying case. Well-maintained and ready to use.",
        price: 25.0,
        priceType: .daily,
        buyoutValue: nil,
        createdAt: Date(),
        updatedAt: nil,
        status: "active",
        category: "Tools",
        type: "listing",
        location: Location(
            address: "123 Main St",
            city: "San Francisco",
            state: "CA",
            zipCode: "94105",
            country: "USA",
            latitude: 37.7749,
            longitude: -122.4194
        ),
        views: 145,
        timesBorrowed: 12,
        inventoryAmt: 1,
        isActive: true,
        isArchived: false,
        images: [
            "https://brrowapp.com/images/drill1.jpg",
            "https://brrowapp.com/images/drill2.jpg",
            "https://brrowapp.com/images/drill3.jpg"
        ],
        rating: 4.8
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
