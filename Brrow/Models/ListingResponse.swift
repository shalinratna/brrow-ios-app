//
//  ListingResponse.swift
//  Brrow
//
//  Models for handling listing API responses
//

import Foundation

// MARK: - Featured Listings Response
struct FeaturedListingsResponse: Codable {
    let listings: [FeaturedListing]
    let pagination: PaginationInfo
}

struct FeaturedListing: Codable {
    let id: Int
    let title: String
    let description: String
    let price: String
    let category: String
    let location: String
    let images: [String]
    let createdAt: String
    let views: Int
    let rating: Double?
    let isPromoted: Bool
    let promotionType: String?
    let listingType: String
    let ownerUsername: String
    let ownerProfilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, price, category, location, images, views, rating
        case createdAt = "created_at"
        case isPromoted = "is_promoted"
        case promotionType = "promotion_type"
        case listingType = "listing_type"
        case ownerUsername = "owner_username"
        case ownerProfilePicture = "owner_profile_picture"
    }
}

// MARK: - Fetch Listings Response
struct FetchListingsResponse: Codable {
    let listings: [FetchedListing]
    let pagination: ListingPaginationInfo
}

struct FetchedListing: Codable {
    let id: Int
    let listingId: String
    let userId: Int
    let userApiId: String?
    let title: String
    let description: String
    let price: String
    let pricePerDay: String
    let buyoutValue: String?
    let createdAt: String
    let activeRenters: [String]
    let status: String
    let category: String
    let location: String
    let datePosted: String
    let dateUpdated: String
    let views: Int
    let timesBorrowed: Int
    let inventoryAmt: Int
    let isFree: Bool
    let isArchived: Bool
    let type: String
    let rating: Double?
    let isActive: Bool
    let images: [String]
    let isFavorite: Bool
    let owner: ListingOwner
    
    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case userId = "user_id"
        case userApiId = "user_api_id"
        case title, description, price
        case pricePerDay = "price_per_day"
        case buyoutValue = "buyout_value"
        case createdAt = "created_at"
        case activeRenters = "active_renters"
        case status, category, location
        case datePosted = "datePosted"
        case dateUpdated = "dateUpdated"
        case views
        case timesBorrowed = "times_borrowed"
        case inventoryAmt = "inventory_amt"
        case isFree = "is_free"
        case isArchived = "is_archived"
        case type, rating
        case isActive = "is_active"
        case images
        case isFavorite = "isFavorite"
        case owner
    }
}

struct ListingOwner: Codable {
    let username: String
    let profilePicture: String?
    let listerRating: Double
    let verified: Bool
    
    enum CodingKeys: String, CodingKey {
        case username
        case profilePicture = "profile_picture"
        case listerRating = "lister_rating"
        case verified
    }
}

struct ListingPaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}

// MARK: - User Karma Response
struct UserKarmaResponse: Codable {
    let userId: String
    let username: String
    let karmaScore: Int
    let trustScore: Int
    let listerRating: Double
    let borrowerRating: Double
    let verified: Bool
    let badges: KarmaBadges
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case karmaScore = "karma_score"
        case trustScore = "trust_score"
        case listerRating = "lister_rating"
        case borrowerRating = "borrower_rating"
        case verified
        case badges
    }
}


// MARK: - Search Listings Response
struct ListingResponse: Codable {
    let success: Bool
    let message: String?
    let data: ListingSearchData?
}

struct ListingSearchData: Codable {
    let listings: [Listing]
    let pagination: SearchPaginationInfo
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case listings
        case pagination
        case hasMore = "has_more"
    }
}

struct SearchPaginationInfo: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let pages: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case total, page, limit, pages
        case hasMore = "has_more"
    }
}

// MARK: - Conversation Response
struct ConversationsResponse: Codable {
    let conversations: [ConversationData]
    let pagination: PaginationInfo
}

struct ConversationData: Codable {
    // Empty for now as API returns empty array
}