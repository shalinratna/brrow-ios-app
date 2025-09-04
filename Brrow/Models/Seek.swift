//
//  Seek.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreData

// MARK: - Seek Model (Codable for API)
struct Seek: Codable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let description: String
    let category: String
    let location: String
    let latitude: Double?
    let longitude: Double?
    let maxDistance: Double // in kilometers
    let minBudget: Double?
    let maxBudget: Double?
    let urgency: String // "low", "medium", "high"
    let status: String // "active", "fulfilled", "expired", "cancelled"
    let createdAt: String
    let expiresAt: String?
    let images: [String]
    let tags: [String]
    let matchCount: Int
    var isActive: Bool { status == "active" }
    var hasMatches: Bool { matchCount > 0 }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, location, latitude, longitude, urgency, status, images, tags
        case userId = "user_id"
        case maxDistance = "max_distance"
        case minBudget = "min_budget"
        case maxBudget = "max_budget"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case matchCount = "match_count"
    }
}

// MARK: - Core Data Entity
@objc(SeekEntity)
public class SeekEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var userId: String
    @NSManaged public var title: String
    @NSManaged public var seekDescription: String
    @NSManaged public var category: String
    @NSManaged public var location: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var maxDistance: Double
    @NSManaged public var minBudget: Double
    @NSManaged public var maxBudget: Double
    @NSManaged public var urgency: String
    @NSManaged public var status: String
    @NSManaged public var createdAt: Date
    @NSManaged public var expiresAt: Date?
    @NSManaged public var images: Data? // JSON encoded array
    @NSManaged public var tags: Data? // JSON encoded array
    @NSManaged public var matchCount: Int32
    
    // Relationships
    @NSManaged public var user: UserEntity?
    @NSManaged public var matches: NSSet?
}
