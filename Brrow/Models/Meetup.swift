//
//  Meetup.swift
//  Brrow
//
//  Created by Claude on 1/6/25.
//

import Foundation
import CoreLocation

// MARK: - Meetup Status
enum MeetupStatus: String, Codable {
    case scheduled = "SCHEDULED"
    case buyerArrived = "BUYER_ARRIVED"
    case sellerArrived = "SELLER_ARRIVED"
    case bothArrived = "BOTH_ARRIVED"
    case verified = "VERIFIED"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    case expired = "EXPIRED"

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .buyerArrived: return "Buyer Arrived"
        case .sellerArrived: return "Seller Arrived"
        case .bothArrived: return "Both Arrived"
        case .verified: return "Verified"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }

    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .buyerArrived, .sellerArrived: return "location"
        case .bothArrived: return "checkmark.circle"
        case .verified: return "checkmark.seal.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .expired: return "clock.badge.exclamationmark"
        }
    }
}

// MARK: - Verification Method
enum VerificationMethod: String, Codable {
    case pinCode = "PIN"
    case qrCode = "QR"

    var displayName: String {
        switch self {
        case .pinCode: return "PIN Code"
        case .qrCode: return "QR Code"
        }
    }
}

// MARK: - Meetup Location
struct MeetupLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - User Location Update
struct UserLocation: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var date: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp)
    }
}

// MARK: - Meetup User
struct MeetupUser: Codable, Identifiable {
    let id: String
    let username: String
    let profilePictureUrl: String?
    let phoneNumber: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case profilePictureUrl = "profile_picture_url"
        case phoneNumber = "phone_number"
    }
}

// MARK: - Meetup Listing
struct MeetupListing: Codable {
    let id: String?  // Optional - backend doesn't always include it in meetup responses
    let title: String
    let listingImages: [ListingImage]?

    enum CodingKeys: String, CodingKey {
        case id, title
        case listingImages = "listing_images"
    }
}

// MARK: - Meetup Transaction
struct MeetupTransaction: Codable {
    let id: String
    let amount: Double
    let status: String
    let transactionType: String
    let listing: MeetupListing

    enum CodingKeys: String, CodingKey {
        case id, amount, status, listing
        case transactionType = "transaction_type"
    }
}

// MARK: - Meetup Purchase (same structure as MeetupTransaction but for purchases)
struct MeetupPurchase: Codable {
    let id: String
    let amount: Double
    let listings: MeetupListing  // Note: Backend returns this as "listings" (plural) even though it's a single object

    enum CodingKeys: String, CodingKey {
        case id, amount, listings
    }
}

// MARK: - Meetup Model
struct Meetup: Codable, Identifiable {
    let id: String
    let transactionId: String?
    let purchaseId: String?
    let buyerId: String
    let sellerId: String
    let meetupLocation: MeetupLocation?
    let scheduledTime: Date?
    let buyerLocation: UserLocation?
    let sellerLocation: UserLocation?
    let buyerArrivedAt: Date?
    let sellerArrivedAt: Date?
    let proximityVerifiedAt: Date?
    let verifiedAt: Date?
    let verificationMethod: VerificationMethod?
    let status: MeetupStatus
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date

    // Relations
    let buyers: MeetupUser?
    let sellers: MeetupUser?
    let transactions: MeetupTransaction?
    let purchases: MeetupPurchase?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionId = "transaction_id"
        case purchaseId = "purchase_id"
        case buyerId = "buyer_id"
        case sellerId = "seller_id"
        case meetupLocation = "meetup_location"
        case scheduledTime = "scheduled_time"
        case buyerLocation = "buyer_location"
        case sellerLocation = "seller_location"
        case buyerArrivedAt = "buyer_arrived_at"
        case sellerArrivedAt = "seller_arrived_at"
        case proximityVerifiedAt = "proximity_verified_at"
        case verifiedAt = "verified_at"
        case verificationMethod = "verification_method"
        case status, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
        case buyers, sellers, transactions, purchases
    }

    // Custom decoding for dates
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        transactionId = try container.decodeIfPresent(String.self, forKey: .transactionId)
        purchaseId = try container.decodeIfPresent(String.self, forKey: .purchaseId)
        buyerId = try container.decode(String.self, forKey: .buyerId)
        sellerId = try container.decode(String.self, forKey: .sellerId)
        meetupLocation = try container.decodeIfPresent(MeetupLocation.self, forKey: .meetupLocation)
        buyerLocation = try container.decodeIfPresent(UserLocation.self, forKey: .buyerLocation)
        sellerLocation = try container.decodeIfPresent(UserLocation.self, forKey: .sellerLocation)
        verificationMethod = try container.decodeIfPresent(VerificationMethod.self, forKey: .verificationMethod)
        status = try container.decode(MeetupStatus.self, forKey: .status)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        buyers = try container.decodeIfPresent(MeetupUser.self, forKey: .buyers)
        sellers = try container.decodeIfPresent(MeetupUser.self, forKey: .sellers)
        transactions = try container.decodeIfPresent(MeetupTransaction.self, forKey: .transactions)
        purchases = try container.decodeIfPresent(MeetupPurchase.self, forKey: .purchases)

        // Decode dates
        let dateFormatter = ISO8601DateFormatter()

        if let scheduledTimeString = try container.decodeIfPresent(String.self, forKey: .scheduledTime) {
            scheduledTime = dateFormatter.date(from: scheduledTimeString)
        } else {
            scheduledTime = nil
        }

        if let buyerArrivedString = try container.decodeIfPresent(String.self, forKey: .buyerArrivedAt) {
            buyerArrivedAt = dateFormatter.date(from: buyerArrivedString)
        } else {
            buyerArrivedAt = nil
        }

        if let sellerArrivedString = try container.decodeIfPresent(String.self, forKey: .sellerArrivedAt) {
            sellerArrivedAt = dateFormatter.date(from: sellerArrivedString)
        } else {
            sellerArrivedAt = nil
        }

        if let proximityVerifiedString = try container.decodeIfPresent(String.self, forKey: .proximityVerifiedAt) {
            proximityVerifiedAt = dateFormatter.date(from: proximityVerifiedString)
        } else {
            proximityVerifiedAt = nil
        }

        if let verifiedString = try container.decodeIfPresent(String.self, forKey: .verifiedAt) {
            verifiedAt = dateFormatter.date(from: verifiedString)
        } else {
            verifiedAt = nil
        }

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()

        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()

        let expiresAtString = try container.decode(String.self, forKey: .expiresAt)
        expiresAt = dateFormatter.date(from: expiresAtString) ?? Date()
    }

    // Helper computed properties
    var isBuyerArrived: Bool {
        buyerArrivedAt != nil
    }

    var isSellerArrived: Bool {
        sellerArrivedAt != nil
    }

    var areBothArrived: Bool {
        isBuyerArrived && isSellerArrived
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var canVerify: Bool {
        status == .bothArrived && !isExpired
    }

    var otherUser: MeetupUser? {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return nil }
        if currentUserId == buyerId {
            return sellers
        } else {
            return buyers
        }
    }

    var currentUserRole: String {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return "Unknown" }
        return currentUserId == buyerId ? "Buyer" : "Seller"
    }
}

// MARK: - Verification Code
struct VerificationCode: Codable, Identifiable {
    let id: String
    let codeType: VerificationMethod
    let codeValue: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case codeType = "codeType"
        case codeValue = "codeValue"
        case expiresAt = "expiresAt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        codeType = try container.decode(VerificationMethod.self, forKey: .codeType)
        codeValue = try container.decode(String.self, forKey: .codeValue)

        let dateFormatter = ISO8601DateFormatter()
        let expiresAtString = try container.decode(String.self, forKey: .expiresAt)
        expiresAt = dateFormatter.date(from: expiresAtString) ?? Date()
    }

    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Proximity Status
struct ProximityStatus: Codable {
    let status: MeetupStatus
    let buyerArrived: Bool
    let sellerArrived: Bool
    let bothArrived: Bool
    let proximityVerified: Bool
    let buyerDistance: Int?
    let sellerDistance: Int?
    let canVerify: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case buyerArrived = "buyerArrived"
        case sellerArrived = "sellerArrived"
        case bothArrived = "bothArrived"
        case proximityVerified = "proximityVerified"
        case buyerDistance = "buyerDistance"
        case sellerDistance = "sellerDistance"
        case canVerify = "canVerify"
    }
}

// MARK: - API Responses
struct MeetupResponse: Codable {
    let success: Bool
    let data: Meetup?
    let message: String?

    // Backend also returns these but we don't need them for the model
    // They're handled separately in the UI
    enum CodingKeys: String, CodingKey {
        case success, data, message
        // Ignore: payment, verificationCode
    }
}

struct MeetupsListResponse: Codable {
    let success: Bool
    let data: [Meetup]?
    let message: String?
}

struct VerificationCodeResponse: Codable {
    let success: Bool
    let data: VerificationCode?
    let message: String?
}

struct VerificationResultResponse: Codable {
    let success: Bool
    let data: VerificationResult?
    let message: String?
}

struct VerificationResult: Codable {
    let verified: Bool
    let meetupStatus: String
    let transactionStatus: String
    let paymentCaptured: Bool

    enum CodingKeys: String, CodingKey {
        case verified
        case meetupStatus = "meetupStatus"
        case transactionStatus = "transactionStatus"
        case paymentCaptured = "paymentCaptured"
    }
}

struct ProximityStatusResponse: Codable {
    let success: Bool
    let data: ProximityStatus?
    let message: String?
}

struct LocationUpdateResponse: Codable {
    let success: Bool
    let data: LocationUpdateData?
    let message: String?
}

struct LocationUpdateData: Codable {
    let meetup: Meetup
    let distance: Int
    let withinProximity: Bool

    enum CodingKeys: String, CodingKey {
        case meetup, distance
        case withinProximity = "withinProximity"
    }
}
