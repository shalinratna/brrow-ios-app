import Foundation

// Structure for image data returned by API
struct ListingImage: Codable {
    let id: String
    let url: String?
    let imageUrl: String?  // Alternative field name
    let thumbnailUrl: String?
    let isPrimary: Bool?
    let displayOrder: Int?
    
    // Legacy field names
    let thumbnail_url: String?
    let is_primary: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, url, imageUrl, thumbnailUrl, isPrimary, displayOrder
        case thumbnail_url = "thumbnail_url"
        case is_primary = "is_primary"
    }
}

// Response model for create_listing.php that handles string price values
struct CreateListingResponse: Codable {
    let status: String?  // API returns "success" as string
    let success: Bool?   // Some endpoints return boolean
    let message: String
    let data: CreatedListing?
    let timestamp: String?
    
    // Computed property to check if successful
    var isSuccessful: Bool {
        return status == "success" || success == true
    }
}

struct CreatedListing: Codable {
    // Minimal fields that API actually returns
    let listing_id: String?  // API returns as string (e.g., "lst_68aa3dd54a17f8.99928588")
    let numeric_id: Int?     // Numeric ID from API
    let id: Int?             // Sometimes returned as id
    let title: String?
    let message: String?     // Success message from API
    let images: [ListingImage]?  // API returns structured image data
    
    // Legacy fields for backward compatibility
    let listingId: String?
    let userId: Int?
    let userApiId: String?
    let description: String?
    let price: String?
    let pricePerDay: String?
    let buyoutValue: String?
    let createdAt: String?
    let activeRenters: [String]?
    let status: String?
    let category: String?
    let location: String?
    let datePosted: String?
    let dateUpdated: String?
    let views: Int?
    let timesBorrowed: Int?
    let inventoryAmt: Int?
    let isFree: Bool?
    let isArchived: Bool?
    let type: String?
    let rating: Double?
    let isActive: Bool?
    let isFavorite: Bool?
    let owner: ListingOwner?
    
    
    // Convert to standard Listing model
    func toListing() -> Listing {
        // Get the actual numeric ID (from numeric_id or id field)
        let actualId = numeric_id ?? id ?? 0
        
        // Get listingId string (use listing_id string or listingId)
        let actualListingId = listing_id ?? listingId ?? "lst_\(actualId)"
        
        // Extract image URLs from structured image data
        let imageUrls = images?.map { $0.url } ?? []
        
        let listing = Listing(
            id: actualListingId,
            title: title ?? "Untitled",
            description: description ?? "",
            categoryId: category ?? "general",
            condition: "Good",
            price: Double(price ?? "0") ?? 0.0,
            isNegotiable: false,
            availabilityStatus: .available,
            location: Location(
                address: location ?? "Unknown",
                city: "",
                state: "",
                zipCode: "",
                country: "USA",
                latitude: 0,
                longitude: 0
            ),
            userId: String(userId ?? 0),
            viewCount: views ?? 0,
            favoriteCount: 0,
            isActive: isActive ?? true,
            isPremium: false,
            premiumExpiresAt: nil,
            deliveryOptions: nil,
            tags: [],
            metadata: nil,
            createdAt: ISO8601DateFormatter().date(from: createdAt ?? "") ?? Date(),
            updatedAt: Date(),
            user: nil,
            category: nil,
            images: images ?? [],
            videos: nil,
            isOwner: true,
            isFavorite: false
        )
        
        return listing
    }
}