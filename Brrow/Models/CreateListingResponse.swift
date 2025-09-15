import Foundation

// Structure for image data returned by API
struct ListingImage: Codable {
    let id: String
    let listingId: String?
    let url: String?
    let imageUrl: String?  // Alternative field name
    let thumbnailUrl: String?
    let isPrimary: Bool?
    let displayOrder: Int?
    let width: Int?
    let height: Int?
    let fileSize: Int?
    let uploadedAt: String?
    
    // Legacy field names
    let thumbnail_url: String?
    let is_primary: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, url, imageUrl, thumbnailUrl, isPrimary, displayOrder
        case listingId, width, height, fileSize, uploadedAt
        case thumbnail_url = "thumbnail_url"
        case is_primary = "is_primary"
    }
    
    // Memberwise initializer for manual creation
    init(id: String, listingId: String? = nil, url: String? = nil, imageUrl: String? = nil, 
         thumbnailUrl: String? = nil, isPrimary: Bool? = nil, displayOrder: Int? = nil,
         width: Int? = nil, height: Int? = nil, fileSize: Int? = nil, uploadedAt: String? = nil,
         thumbnail_url: String? = nil, is_primary: Bool? = nil) {
        self.id = id
        self.listingId = listingId
        self.url = url
        self.imageUrl = imageUrl
        self.thumbnailUrl = thumbnailUrl
        self.isPrimary = isPrimary
        self.displayOrder = displayOrder
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.uploadedAt = uploadedAt
        self.thumbnail_url = thumbnail_url
        self.is_primary = is_primary
    }
    
    // Custom decoder to handle multiple field variations
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.listingId = try? container.decodeIfPresent(String.self, forKey: .listingId)
        
        // Try multiple URL field names - prioritize imageUrl over url
        if let imageUrlValue = try? container.decodeIfPresent(String.self, forKey: .imageUrl) {
            self.url = imageUrlValue
            self.imageUrl = imageUrlValue
        } else if let urlValue = try? container.decodeIfPresent(String.self, forKey: .url) {
            self.url = urlValue
            self.imageUrl = urlValue
        } else {
            self.url = nil
            self.imageUrl = nil
        }
        
        // Try both camelCase and snake_case for thumbnail URL
        if let thumbnailValue = try? container.decodeIfPresent(String.self, forKey: .thumbnailUrl) {
            self.thumbnailUrl = thumbnailValue
        } else {
            self.thumbnailUrl = try? container.decodeIfPresent(String.self, forKey: .thumbnail_url)
        }
        
        // Legacy field support
        self.thumbnail_url = try? container.decodeIfPresent(String.self, forKey: .thumbnail_url)
        
        // Try both camelCase and snake_case for isPrimary
        if let primaryValue = try? container.decodeIfPresent(Bool.self, forKey: .isPrimary) {
            self.isPrimary = primaryValue
        } else {
            self.isPrimary = try? container.decodeIfPresent(Bool.self, forKey: .is_primary)
        }
        
        self.is_primary = try? container.decodeIfPresent(Bool.self, forKey: .is_primary)
        self.displayOrder = try? container.decodeIfPresent(Int.self, forKey: .displayOrder)
        self.width = try? container.decodeIfPresent(Int.self, forKey: .width)
        self.height = try? container.decodeIfPresent(Int.self, forKey: .height)
        self.fileSize = try? container.decodeIfPresent(Int.self, forKey: .fileSize)
        self.uploadedAt = try? container.decodeIfPresent(String.self, forKey: .uploadedAt)
    }
    
    // Helper method to get the full URL with base URL if needed
    var fullURL: String? {
        guard let urlString = url ?? imageUrl else { return nil }
        
        // If the URL is already complete (starts with http), return as-is
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return urlString
        }
        
        // If it's a relative path starting with /uploads/, prepend brrowapp.com URL
        if urlString.hasPrefix("/uploads/") || urlString.hasPrefix("uploads/") {
            let baseURL = "https://brrowapp.com"
            let formattedPath = urlString.hasPrefix("/") ? urlString : "/\(urlString)"
            return "\(baseURL)\(formattedPath)"
        }
        
        // For other relative paths, assume they need the brrowapp.com URL
        let baseURL = "https://brrowapp.com"
        return "\(baseURL)/\(urlString)"
    }
    
    // Helper method to get the full thumbnail URL
    var fullThumbnailURL: String? {
        guard let thumbnailUrlString = thumbnailUrl ?? thumbnail_url else { return nil }
        
        // If the URL is already complete (starts with http), return as-is
        if thumbnailUrlString.hasPrefix("http://") || thumbnailUrlString.hasPrefix("https://") {
            return thumbnailUrlString
        }
        
        // If it's a relative path starting with /uploads/, prepend brrowapp.com URL
        if thumbnailUrlString.hasPrefix("/uploads/") || thumbnailUrlString.hasPrefix("uploads/") {
            let baseURL = "https://brrowapp.com"
            let formattedPath = thumbnailUrlString.hasPrefix("/") ? thumbnailUrlString : "/\(thumbnailUrlString)"
            return "\(baseURL)\(formattedPath)"
        }
        
        // For other relative paths, assume they need the brrowapp.com URL
        let baseURL = "https://brrowapp.com"
        return "\(baseURL)/\(thumbnailUrlString)"
    }
}

// Response model for create listing endpoint
struct CreateListingResponse: Codable {
    let status: String?  // API returns "success" as string
    let success: Bool?   // Some endpoints return boolean
    let message: String?  // Made optional for flexibility
    let data: Listing?  // Backend returns full Listing object
    let listing: Listing?  // Backend now returns listing directly here
    let timestamp: String?
    
    // Computed property to check if successful
    var isSuccessful: Bool {
        return status == "success" || success == true
    }
    
    // Get the listing from either field
    var actualListing: Listing? {
        return listing ?? data
    }
}

// Legacy structure for backward compatibility
struct CreatedListing: Codable {
    // Minimal fields that API actually returns
    let listing_id: String?  // API returns as string (e.g., "lst_68aa3dd54a17f8.99928588")
    let numeric_id: Int?     // Numeric ID from API
    let id: String?          // Now returns string ID
    let title: String?
    let message: String?     // Success message from API
    let images: [ListingImage]?  // API returns structured image data
    
    // Legacy fields for backward compatibility
    let listingId: String?
    let userId: String?      // Changed to String to match new API
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
        // Get the actual ID as string
        let actualId = id ?? listing_id ?? listingId ?? "lst_unknown"
        
        // Extract image URLs from structured image data
        let imageUrls = images?.map { $0.url } ?? []
        
        let listing = Listing(
            id: actualId,
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
            userId: userId ?? "0",
            viewCount: views ?? 0,
            favoriteCount: 0,
            isActive: isActive ?? true,
            isPremium: false,
            premiumExpiresAt: nil,
            deliveryOptions: nil,
            tags: [],
            metadata: nil,
            createdAt: createdAt ?? ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            user: nil,
            category: nil,
            images: images ?? [],
            videos: nil,
            _count: Listing.ListingCount(favorites: 0),
            isOwner: true,
            isFavorite: false
        )
        
        return listing
    }
}