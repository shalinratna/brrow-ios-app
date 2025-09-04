//
//  Offer.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreData

// OfferStatus enum is now defined in APITypes.swift

// MARK: - Offer Model (Codable for API)
struct Offer: Codable, Identifiable {
    let id: Int
    let listingId: Int
    let borrowerId: Int
    let amount: Double
    let message: String?
    let duration: Int? // in days
    let status: OfferStatus
    let createdAt: Date
    let updatedAt: Date
    var listing: Listing?
    var borrower: User?
    
    // Initializer
    init(id: Int, listingId: Int, borrowerId: Int, amount: Double, message: String?, duration: Int?, status: OfferStatus, createdAt: Date, updatedAt: Date, listing: Listing? = nil, borrower: User? = nil) {
        self.id = id
        self.listingId = listingId
        self.borrowerId = borrowerId
        self.amount = amount
        self.message = message
        self.duration = duration
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.listing = listing
        self.borrower = borrower
    }
    
    // Computed properties for display
    var price: Double { return amount }
    var listingTitle: String { return listing?.title ?? "Unknown Listing" }
    var senderName: String { return borrower?.username ?? "Unknown User" }
    var recipientName: String { return "Unknown User" }
    
    enum CodingKeys: String, CodingKey {
        case id, amount, message, duration, status
        case listingId = "listing_id"
        case borrowerId = "borrower_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case listing, borrower
    }
    
    // Custom decoding to handle date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        listingId = try container.decode(Int.self, forKey: .listingId)
        borrowerId = try container.decode(Int.self, forKey: .borrowerId)
        amount = try container.decode(Double.self, forKey: .amount)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        duration = try container.decode(Int.self, forKey: .duration)
        status = try container.decode(OfferStatus.self, forKey: .status)
        
        // Handle date decoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        
        listing = try container.decodeIfPresent(Listing.self, forKey: .listing)
        borrower = try container.decodeIfPresent(User.self, forKey: .borrower)
    }
}


// MARK: - Update Offer Request
struct UpdateOfferRequest: Codable {
    let status: OfferStatus
    let message: String?
}

// MARK: - Core Data Entity
@objc(OfferEntity)
public class OfferEntity: NSManagedObject {
    
}

extension OfferEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfferEntity> {
        return NSFetchRequest<OfferEntity>(entityName: "OfferEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var listingId: String
    @NSManaged public var offererId: String
    @NSManaged public var ownerId: String
    @NSManaged public var offerAmount: Double
    @NSManaged public var message: String?
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var status: String
    @NSManaged public var createdAt: Date
    @NSManaged public var respondedAt: Date?
    @NSManaged public var response: String?
    
    // Relationships
    @NSManaged public var listing: ListingEntity?
    @NSManaged public var offerer: UserEntity?
    @NSManaged public var owner: UserEntity?
    
    // Convert to API model
    func toOffer() -> Offer {
        let durationInDays = Int(endDate.timeIntervalSince(startDate) / 86400) // 86400 seconds in a day
        
        return Offer(
            id: Int(id) ?? 0,
            listingId: Int(listingId) ?? 0,
            borrowerId: Int(offererId) ?? 0,
            amount: offerAmount,
            message: message,
            duration: durationInDays,
            status: OfferStatus(rawValue: status) ?? .pending,
            createdAt: createdAt,
            updatedAt: respondedAt ?? createdAt,
            listing: nil,
            borrower: nil
        )
    }
}
