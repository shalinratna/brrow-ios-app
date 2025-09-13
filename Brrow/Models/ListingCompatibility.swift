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
    
    // Rental period compatibility
    var rentalPeriod: String? {
        return "day"
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
        isActive: Bool = true
    ) -> Listing {
        return Listing(
            id: id ?? "lst_\(UUID().uuidString.prefix(8))",
            title: title,
            description: description,
            categoryId: "default-category",
            condition: "GOOD",
            price: price,
            isNegotiable: true,
            availabilityStatus: isActive ? .available : .pending,
            location: location ?? Location(
                address: "Unknown",
                city: "Unknown",
                state: "Unknown",
                zipCode: "00000",
                country: "US",
                latitude: 0,
                longitude: 0
            ),
            userId: "0",
            viewCount: 0,
            favoriteCount: 0,
            isActive: isActive,
            isPremium: false,
            premiumExpiresAt: nil,
            deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
            tags: [],
            metadata: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            user: nil,
            category: CategoryModel(
                id: "default-category",
                name: category,
                description: nil,
                iconUrl: nil,
                parentId: nil,
                isActive: true,
                sortOrder: 0,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            ),
            images: images.map { url in
                ListingImage(
                    id: UUID().uuidString,
                    url: url,
                    imageUrl: url,
                    thumbnailUrl: nil,
                    isPrimary: false,
                    displayOrder: 0,
                    thumbnail_url: nil,
                    is_primary: false
                )
            },
            videos: nil,
            _count: Listing.ListingCount(favorites: 0),
            isOwner: false,
            isFavorite: false
        )
    }
}