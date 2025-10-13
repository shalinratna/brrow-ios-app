import Foundation

// MARK: - ListingOwner
struct ListingOwner: Codable {
    let id: String?
    let username: String?
    let email: String?
    let profilePicture: String?
    let rating: Double?
    let verified: Bool?
}

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

    // GPS-related fields from API
    let hasGPSData: Bool?
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let gpsTimestamp: String?
    let locationData: String?

    // Legacy field names
    let thumbnail_url: String?
    let is_primary: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, url, width, height, latitude, longitude, altitude
        // Support both camelCase (from backend transformer) and snake_case (legacy)
        case listingId, listing_id
        case imageUrl, image_url
        case thumbnailUrl, thumbnail_url
        case isPrimary, is_primary
        case displayOrder, display_order
        case fileSize, file_size
        case uploadedAt, uploaded_at
        case hasGPSData, has_gps_data
        case gpsTimestamp, gps_timestamp
        case locationData, location_data
    }

    // Memberwise initializer for manual creation
    init(id: String, listingId: String? = nil, url: String? = nil, imageUrl: String? = nil,
         thumbnailUrl: String? = nil, isPrimary: Bool? = nil, displayOrder: Int? = nil,
         width: Int? = nil, height: Int? = nil, fileSize: Int? = nil, uploadedAt: String? = nil,
         hasGPSData: Bool? = nil, latitude: Double? = nil, longitude: Double? = nil,
         altitude: Double? = nil, gpsTimestamp: String? = nil, locationData: String? = nil,
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
        self.hasGPSData = hasGPSData
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.gpsTimestamp = gpsTimestamp
        self.locationData = locationData
        self.thumbnail_url = thumbnail_url
        self.is_primary = is_primary
    }
    
    // Custom decoder to handle both camelCase and snake_case from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)

        // Try both camelCase and snake_case for listingId
        if let val = try? container.decodeIfPresent(String.self, forKey: .listingId) {
            self.listingId = val
        } else {
            self.listingId = try? container.decodeIfPresent(String.self, forKey: .listing_id)
        }

        // Try multiple URL field names - try camelCase first (from backend transformer)
        if let imageUrlValue = try? container.decodeIfPresent(String.self, forKey: .imageUrl) {
            self.url = imageUrlValue
            self.imageUrl = imageUrlValue
        } else if let imageUrlValue = try? container.decodeIfPresent(String.self, forKey: .image_url) {
            self.url = imageUrlValue
            self.imageUrl = imageUrlValue
        } else if let urlValue = try? container.decodeIfPresent(String.self, forKey: .url) {
            self.url = urlValue
            self.imageUrl = urlValue
        } else {
            self.url = nil
            self.imageUrl = nil
        }

        // Try both formats for thumbnailUrl
        let thumbnailValue = (try? container.decodeIfPresent(String.self, forKey: .thumbnailUrl))
            ?? (try? container.decodeIfPresent(String.self, forKey: .thumbnail_url))
        self.thumbnailUrl = thumbnailValue
        self.thumbnail_url = thumbnailValue

        // Try both formats for isPrimary
        let primaryValue = (try? container.decodeIfPresent(Bool.self, forKey: .isPrimary))
            ?? (try? container.decodeIfPresent(Bool.self, forKey: .is_primary))
        self.isPrimary = primaryValue
        self.is_primary = primaryValue

        // Try both formats for remaining fields
        self.displayOrder = (try? container.decodeIfPresent(Int.self, forKey: .displayOrder))
            ?? (try? container.decodeIfPresent(Int.self, forKey: .display_order))
        self.fileSize = (try? container.decodeIfPresent(Int.self, forKey: .fileSize))
            ?? (try? container.decodeIfPresent(Int.self, forKey: .file_size))
        self.uploadedAt = (try? container.decodeIfPresent(String.self, forKey: .uploadedAt))
            ?? (try? container.decodeIfPresent(String.self, forKey: .uploaded_at))

        // Direct fields (no snake_case version needed)
        self.width = try? container.decodeIfPresent(Int.self, forKey: .width)
        self.height = try? container.decodeIfPresent(Int.self, forKey: .height)

        // GPS fields - try both formats
        self.hasGPSData = (try? container.decodeIfPresent(Bool.self, forKey: .hasGPSData))
            ?? (try? container.decodeIfPresent(Bool.self, forKey: .has_gps_data))
        self.gpsTimestamp = (try? container.decodeIfPresent(String.self, forKey: .gpsTimestamp))
            ?? (try? container.decodeIfPresent(String.self, forKey: .gps_timestamp))
        self.locationData = (try? container.decodeIfPresent(String.self, forKey: .locationData))
            ?? (try? container.decodeIfPresent(String.self, forKey: .location_data))
        self.latitude = try? container.decodeIfPresent(Double.self, forKey: .latitude)
        self.longitude = try? container.decodeIfPresent(Double.self, forKey: .longitude)
        self.altitude = try? container.decodeIfPresent(Double.self, forKey: .altitude)
    }

    // Custom encoder - use camelCase format for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(listingId, forKey: .listingId)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(isPrimary, forKey: .isPrimary)
        try container.encodeIfPresent(displayOrder, forKey: .displayOrder)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(fileSize, forKey: .fileSize)
        try container.encodeIfPresent(uploadedAt, forKey: .uploadedAt)
        try container.encodeIfPresent(hasGPSData, forKey: .hasGPSData)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encodeIfPresent(gpsTimestamp, forKey: .gpsTimestamp)
        try container.encodeIfPresent(locationData, forKey: .locationData)
    }

    // Helper method to get the full URL with base URL if needed
    var fullURL: String? {
        guard let urlString = url ?? imageUrl else { return nil }

        // If the URL is already complete (starts with http), return as-is
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return urlString
        }

        // If it's a relative path starting with /uploads/, prepend Railway backend URL
        if urlString.hasPrefix("/uploads/") || urlString.hasPrefix("uploads/") {
            let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
            let formattedPath = urlString.hasPrefix("/") ? urlString : "/\(urlString)"
            return "\(baseURL)\(formattedPath)"
        }

        // For other relative paths, use Railway backend URL
        let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
        return "\(baseURL)/\(urlString)"
    }
    
    // Helper method to get the full thumbnail URL
    var fullThumbnailURL: String? {
        guard let thumbnailUrlString = thumbnailUrl ?? thumbnail_url else { return nil }

        // If the URL is already complete (starts with http), return as-is
        if thumbnailUrlString.hasPrefix("http://") || thumbnailUrlString.hasPrefix("https://") {
            return thumbnailUrlString
        }

        // If it's a relative path starting with /uploads/, prepend Railway backend URL
        if thumbnailUrlString.hasPrefix("/uploads/") || thumbnailUrlString.hasPrefix("uploads/") {
            let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
            let formattedPath = thumbnailUrlString.hasPrefix("/") ? thumbnailUrlString : "/\(thumbnailUrlString)"
            return "\(baseURL)\(formattedPath)"
        }

        // For other relative paths, use Railway backend URL
        let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
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
struct CreatedListing: Decodable {
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
        
        let jsonString = """
        {
            "id": "\(actualId)",
            "title": "\(title ?? "Untitled")",
            "description": "\(description ?? "")",
            "categoryId": "\(category ?? "general")",
            "condition": "good",
            "price": \(Double(price ?? "0") ?? 0.0),
            "dailyRate": null,
            "isNegotiable": false,
            "availabilityStatus": "available",
            "location": {
                "address": "\(location ?? "Unknown")",
                "city": "",
                "state": "",
                "zipCode": "",
                "country": "USA",
                "latitude": 0,
                "longitude": 0
            },
            "userId": "\(userId ?? "0")",
            "viewCount": \(views ?? 0),
            "favoriteCount": 0,
            "isActive": \(isActive ?? true),
            "isPremium": false,
            "premiumExpiresAt": null,
            "deliveryOptions": null,
            "tags": [],
            "metadata": null,
            "createdAt": "\(createdAt ?? ISO8601DateFormatter().string(from: Date()))",
            "updatedAt": "\(ISO8601DateFormatter().string(from: Date()))",
            "user": null,
            "category": null,
            "images": [],
            "videos": null,
            "imageUrl": null,
            "_count": {"favorites": 0},
            "isOwner": true,
            "isFavorite": false
        }
        """

        let data = jsonString.data(using: .utf8)!
        let listing = try! JSONDecoder().decode(Listing.self, from: data)
        
        return listing
    }
}