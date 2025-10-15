//
//  GarageSale.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreData
import CoreLocation

// MARK: - GarageSale Model (Codable for API)
struct GarageSale: Codable, Identifiable {
    let id: String // UUID from backend
    let hostId: String
    let title: String
    let description: String?
    let location: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let saleDate: String
    let startTime: String
    let endTime: String
    let startDate: String
    let endDate: String
    let images: [String]
    let tags: [String]
    var rsvpCount: Int?
    let interestedCount: Int?
    let isPublic: Bool
    let host: GarageSaleHost
    let isActive: Bool
    let isUpcoming: Bool
    let isPast: Bool
    let isBusiness: Bool
    let isBoosted: Bool
    
    // User-specific fields
    var isRsvp: Bool?
    var isFavorited: Bool?
    
    // New fields from enhanced API
    var status: String?
    var statusColor: String?
    var hoursSinceEnd: Double?
    var isOwner: Bool?
    var isLive: Bool?
    var formattedDate: String?
    var formattedDateRange: String?
    var listingCount: Int?
    
    // Computed properties for backward compatibility
    var userId: String { return hostId } // Legacy support - use hostId
    var attendeeCount: Int { return rsvpCount ?? 0 }
    var categories: [String] { return tags }
    var photos: [GarageSalePhoto] { 
        return images.enumerated().map { GarageSalePhoto(url: $1, order: $0) }
    }
    var firstName: String { return host.username }
    var lastName: String { return "" }
    var profilePictureUrl: String? { return host.profilePicture }
    var verified: Bool { return host.verified }
    var distance: Double? { return nil }
    var startsIn: Int? { return nil }
    
    
    var computedStatus: String {
        // Use API-provided status if available
        if let apiStatus = status {
            return apiStatus
        }
        
        // Fallback to computed status
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let start = formatter.date(from: startDate),
           let end = formatter.date(from: endDate) {
            if end < now {
                return "ended"
            } else if start > now {
                return "upcoming"
            } else {
                return "live"
            }
        }
        return "unknown"
    }
    
    var hostName: String {
        "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location, address, latitude, longitude, images, tags, host
        case hostId = "host_id"
        case saleDate = "sale_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case startDate = "start_date"
        case endDate = "end_date"
        case rsvpCount = "rsvp_count"
        case interestedCount = "interested_count"
        case isPublic = "is_public"
        case isActive = "is_active"
        case isUpcoming = "is_upcoming"
        case isPast = "is_past"
        case isBusiness = "is_business"
        case isBoosted = "is_boosted"
        case isRsvp = "is_rsvp"
        case isFavorited = "is_favorited"
        case status, statusColor = "status_color"
        case hoursSinceEnd = "hours_since_end"
        case isOwner = "is_owner"
        case isLive = "is_live"
        case formattedDate = "formatted_date"
        case formattedDateRange = "formatted_date_range"
        case listingCount = "associated_listing_count"
    }
    
}

// MARK: - GarageSaleHost Model
struct GarageSaleHost: Codable {
    let username: String
    let profilePicture: String?
    let verified: Bool
    let rating: Int
    
    enum CodingKeys: String, CodingKey {
        case username
        case profilePicture = "profile_picture"
        case verified
        case rating
    }
}

// MARK: - GarageSalePhoto Model
struct GarageSalePhoto: Codable {
    let url: String
    let order: Int
}

// MARK: - Core Data Entity
@objc(GarageSaleEntity)
public class GarageSaleEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var hostId: String
    @NSManaged public var title: String
    @NSManaged public var saleDescription: String
    @NSManaged public var location: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?
    @NSManaged public var status: String
    @NSManaged public var images: Data? // JSON encoded array
    @NSManaged public var attendeeCount: Int32
    @NSManaged public var maxAttendees: Int32
    @NSManaged public var isPublic: Bool
    @NSManaged public var tags: Data? // JSON encoded array
    
    // Relationships
    @NSManaged public var host: UserEntity?
    @NSManaged public var attendees: NSSet?
}
