//
//  Transaction.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreData

// TransactionStatus enum is now defined in APITypes.swift

// MARK: - Transaction Model (Codable for API)
struct Transaction: Codable, Identifiable {
    let id: Int
    let offerId: Int
    let listingId: Int
    let borrowerId: Int
    let lenderId: Int
    let startDate: Date
    let endDate: Date
    let actualReturnDate: Date?
    let totalCost: Double
    let securityDeposit: Double?
    let status: TransactionStatus
    let paymentStatus: String // "unpaid", "paid", "refunded", "partial"
    let createdAt: Date
    let updatedAt: Date?
    let notes: String?
    let rating: Int?
    let review: String?
    
    enum CodingKeys: String, CodingKey {
        case id, status, notes, rating, review
        case offerId = "offer_id"
        case listingId = "listing_id"
        case borrowerId = "borrower_id"
        case lenderId = "lender_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case actualReturnDate = "actual_return_date"
        case totalCost = "total_cost"
        case securityDeposit = "security_deposit"
        case paymentStatus = "payment_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Standard initializer
    init(id: Int, offerId: Int, listingId: Int, borrowerId: Int, lenderId: Int, startDate: Date, endDate: Date, actualReturnDate: Date?, totalCost: Double, securityDeposit: Double?, status: TransactionStatus, paymentStatus: String, createdAt: Date, updatedAt: Date?, notes: String?, rating: Int?, review: String?) {
        self.id = id
        self.offerId = offerId
        self.listingId = listingId
        self.borrowerId = borrowerId
        self.lenderId = lenderId
        self.startDate = startDate
        self.endDate = endDate
        self.actualReturnDate = actualReturnDate
        self.totalCost = totalCost
        self.securityDeposit = securityDeposit
        self.status = status
        self.paymentStatus = paymentStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.rating = rating
        self.review = review
    }
    
    // Custom decoding to handle date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        offerId = try container.decode(Int.self, forKey: .offerId)
        listingId = try container.decode(Int.self, forKey: .listingId)
        borrowerId = try container.decode(Int.self, forKey: .borrowerId)
        lenderId = try container.decode(Int.self, forKey: .lenderId)
        status = try container.decode(TransactionStatus.self, forKey: .status)
        totalCost = try container.decode(Double.self, forKey: .totalCost)
        securityDeposit = try container.decodeIfPresent(Double.self, forKey: .securityDeposit)
        paymentStatus = try container.decode(String.self, forKey: .paymentStatus)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        review = try container.decodeIfPresent(String.self, forKey: .review)
        
        // Date decoding
        let dateFormatter = ISO8601DateFormatter()
        
        let startDateString = try container.decode(String.self, forKey: .startDate)
        guard let startDateValue = dateFormatter.date(from: startDateString) else {
            throw DecodingError.dataCorruptedError(forKey: .startDate, in: container, debugDescription: "Invalid date format")
        }
        startDate = startDateValue
        
        let endDateString = try container.decode(String.self, forKey: .endDate)
        guard let endDateValue = dateFormatter.date(from: endDateString) else {
            throw DecodingError.dataCorruptedError(forKey: .endDate, in: container, debugDescription: "Invalid date format")
        }
        endDate = endDateValue
        
        if let actualReturnDateString = try container.decodeIfPresent(String.self, forKey: .actualReturnDate) {
            actualReturnDate = dateFormatter.date(from: actualReturnDateString)
        } else {
            actualReturnDate = nil
        }
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtValue = dateFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format")
        }
        createdAt = createdAtValue
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
}

// MARK: - Core Data Entities
@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var listingId: String
    @NSManaged public var borrowerId: String
    @NSManaged public var lenderId: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var actualReturnDate: Date?
    @NSManaged public var totalCost: Double
    @NSManaged public var securityDeposit: Double
    @NSManaged public var status: String
    @NSManaged public var paymentStatus: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?
    @NSManaged public var notes: String?
    @NSManaged public var rating: Int16
    @NSManaged public var review: String?
    
    // Relationships
    @NSManaged public var listing: ListingEntity?
    @NSManaged public var borrower: UserEntity?
    @NSManaged public var lender: UserEntity?
}
