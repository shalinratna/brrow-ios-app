//
//  ListingCompatibility.swift
//  Brrow
//
//  Compatibility layer for old Listing model properties
//

import Foundation

// MARK: - Compatibility Extension
extension Listing {
    // Legacy ID property
    var ownerId: Int {
        return Int(userId) ?? 0
    }
    
    // Price type compatibility
    var priceType: PriceType {
        return price == 0 ? .free : .daily
    }
    
    // Type compatibility
    var type: String {
        return price == 0 ? "free" : "for_rent"
    }
    
    // Rating compatibility
    var rating: Double? {
        return ownerRating
    }
    
    // Times borrowed compatibility
    var timesBorrowed: Int {
        return 0 // Default value as it's not tracked in new model
    }
    
    // Review count compatibility
    var reviewCount: Int? {
        return 0 // Default value
    }
    
    // Buyout value compatibility
    var buyoutValue: Double? {
        return nil // Not supported in new model
    }
    
    // Security deposit compatibility  
    var securityDeposit: Double? {
        return nil // Not supported in new model
    }
    
    
    // Rental period
    var rentalPeriod: String? {
        // Default to "day" for rental listings
        return listingType == "rent" ? "day" : nil
    }
    
    // Check if listing is new
    var isNew: Bool? {
        // Check if created within last 7 days
        let formatter = ISO8601DateFormatter()
        if let created = formatter.date(from: createdAt) {
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            return created > sevenDaysAgo
        }
        return false
    }
    
    // Distance compatibility
    var distance: Double? {
        return nil // Will be calculated client-side if needed
    }
    
    // Promotion status compatibility
    var promotionStatus: PromotionStatus? {
        return isPremium ? .active : nil
    }
    
    // Updated at compatibility (make it non-optional)
    var updatedAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: updatedAt) ?? Date()
    }
    
    // Category string compatibility
    var categoryString: String {
        return category?.name ?? "General"
    }
    
    // Images array compatibility (ListingImage to String)
    var imageStrings: [String] {
        return imageUrls
    }
    
    // Active renters compatibility
    var activeRenters: [String] {
        return []
    }
}

// MARK: - Alternative Listing Constructor
extension Listing {
    // Convenience initializer for UI preview/testing
    static func create(
        id: String? = nil,
        title: String,
        description: String,
        price: Double,
        category: String = "General",
        location: Location? = nil,
        images: [String] = [],
        isActive: Bool = true,
        ownerId: String = "default-user"
    ) -> Listing {
        // Use JSON-based initialization to avoid constructor issues
        let jsonString = """
        {
            "id": "\(id ?? "lst_\(UUID().uuidString.prefix(8))")",
            "title": "\(title)",
            "description": "\(description)",
            "categoryId": "default-category",
            "condition": "good",
            "price": \(price),
            "dailyRate": null,
            "isNegotiable": true,
            "availabilityStatus": "available",
            "location": {
                "address": "\(location)",
                "city": "Unknown",
                "state": "Unknown",
                "zipCode": "00000",
                "country": "USA",
                "latitude": 0,
                "longitude": 0
            },
            "userId": "\(ownerId)",
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
        let data = jsonString.data(using: String.Encoding.utf8)!
        return try! JSONDecoder().decode(Listing.self, from: data)
    }
}