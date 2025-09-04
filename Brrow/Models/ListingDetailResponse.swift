//
//  ListingDetailResponse.swift
//  Brrow
//
//  Complete listing detail response with owner information
//

import Foundation

struct ListingDetailResponse: Codable {
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
        let createdDate = created_at.flatMap { dateFormatter.date(from: $0) } ?? Date()
        let updatedDate = updated_at.flatMap { dateFormatter.date(from: $0) }
        
        let locationModel = Location(
            address: location.address,
            city: location.city,
            state: location.state,
            zipCode: location.zip_code,
            country: location.country,
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        let priceTypeEnum = PriceType(rawValue: price_type ?? "fixed") ?? .fixed
        
        var listing = Listing(
            id: id,
            listingId: listing_id,
            ownerId: owner_id,
            title: title,
            description: description,
            price: price,
            priceType: priceTypeEnum,
            buyoutValue: buyout_value,
            createdAt: createdDate,
            updatedAt: updatedDate,
            status: status,
            category: category,
            type: type,
            location: locationModel,
            views: views,
            timesBorrowed: times_borrowed,
            inventoryAmt: inventory_amt,
            isActive: is_active,
            isArchived: is_archived,
            images: images,
            rating: rating
        )
        
        // Add owner details
        listing.ownerApiId = owner_api_id ?? (owner?.id != nil ? "usr_\(owner!.id)" : nil)
        listing.ownerUsername = owner?.username ?? owner?.display_name
        listing.ownerProfilePicture = owner?.profile_picture
        listing.ownerRating = owner?.rating
        listing.reviewCount = owner?.review_count
        listing.ownerVerified = owner?.verified ?? false
        listing.ownerBio = owner?.bio
        listing.ownerLocation = owner?.location
        listing.ownerMemberSince = owner?.member_since
        listing.ownerTotalListings = owner?.total_listings
        
        return listing
    }
}