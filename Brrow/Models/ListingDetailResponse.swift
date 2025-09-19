//
//  ListingDetailResponse.swift
//  Brrow
//
//  Complete listing detail response with owner information
//

import Foundation

struct ListingDetail: Codable {
    let id: Int
    let listing_id: String
    let owner_id: Int
    let owner_api_id: String?
    let title: String
    let description: String
    let price: Double
    let price_type: String?
    let buyout_value: Double?
    let status: String
    let category: String
    let type: String
    let views: Int
    let times_borrowed: Int
    let inventory_amt: Int
    let is_active: Bool
    let is_archived: Bool
    let images: [String]
    let rating: Double?
    let created_at: String?
    let updated_at: String?
    let location: LocationDetail
    let owner: OwnerDetail?
    
    struct LocationDetail: Codable {
        let address: String
        let city: String
        let state: String
        let zip_code: String
        let country: String
        let latitude: Double
        let longitude: Double
    }
    
    struct OwnerDetail: Codable {
        let id: Int
        let username: String
        let display_name: String
        let first_name: String
        let last_name: String
        let bio: String
        let profile_picture: String?
        let verified: Bool
        let member_since: String
        let location: String
        let total_listings: Int
        let rating: Double
        let review_count: Int
        let response_time: String
        let response_rate: String
    }
    
    // Convert to Listing model
    func toListing() -> Listing {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let createdDateString = created_at ?? dateFormatter.string(from: Date())
        let updatedDateString = updated_at ?? createdDateString
        
        let locationModel = Location(
            address: location.address,
            city: location.city,
            state: location.state,
            zipCode: location.zip_code,
            country: location.country,
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        // Convert images array to ListingImage objects
        let listingImages = images.map { imageUrl in
            ListingImage(
                id: UUID().uuidString,
                url: imageUrl,
                imageUrl: imageUrl,
                thumbnailUrl: nil,
                isPrimary: images.first == imageUrl,
                displayOrder: images.firstIndex(of: imageUrl) ?? 0,
                thumbnail_url: nil,
                is_primary: images.first == imageUrl
            )
        }
        
        // Create CategoryModel from category string
        let categoryModel = CategoryModel(
            id: "cat_\(category.lowercased())",
            name: category,
            description: nil,
            iconUrl: nil,
            parentId: nil,
            isActive: true,
            sortOrder: 0,
            createdAt: dateFormatter.string(from: Date()),
            updatedAt: dateFormatter.string(from: Date())
        )
        
        var listing = Listing(
            id: "\(id)",
            title: title,
            description: description,
            categoryId: "default-category",
            condition: "GOOD",
            price: price,
            dailyRate: nil,
            isNegotiable: true,
            availabilityStatus: is_active ? .available : .deleted,
            location: locationModel,
            userId: "\(owner_id)",
            viewCount: views,
            favoriteCount: 0,
            isActive: is_active,
            isPremium: false,
            premiumExpiresAt: nil,
            deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
            tags: [],
            metadata: [:],
            createdAt: createdDateString,
            updatedAt: updatedDateString,
            user: nil,
            category: categoryModel,
            images: listingImages,
            videos: [],
            _count: Listing.ListingCount(favorites: 0),
            isOwner: false,
            isFavorite: false
        )
        
        // Owner details are already handled via the user property
        // The computed properties ownerUsername, ownerProfilePicture, etc. 
        // will automatically derive their values from the user object
        
        return listing
    }
}