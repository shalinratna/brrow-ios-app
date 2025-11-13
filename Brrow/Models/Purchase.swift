//
//  Purchase.swift
//  Brrow
//
//  Purchase model for Buy Now system with Stripe payment holds
//

import Foundation

// MARK: - Purchase Status Enums
enum PurchaseType: String, Codable {
    case buyNow = "BUY_NOW"
    case acceptedOffer = "ACCEPTED_OFFER"
}

enum PurchasePaymentStatus: String, Codable {
    case pending = "PENDING"
    case held = "HELD"
    case captured = "CAPTURED"
    case refunded = "REFUNDED"
    case cancelled = "CANCELLED"
    case failed = "FAILED"
}

enum PurchaseVerificationStatus: String, Codable {
    case pending = "PENDING"
    case sellerConfirmed = "SELLER_CONFIRMED"
    case buyerConfirmed = "BUYER_CONFIRMED"
    case bothConfirmed = "BOTH_CONFIRMED"
    case failed = "FAILED"
}

// MARK: - Purchase Model
struct Purchase: Codable, Identifiable {
    let id: String
    let listingId: String
    let buyerId: String
    let sellerId: String
    let purchaseType: PurchaseType
    let amount: Double
    let paymentIntentId: String?
    let paymentStatus: PurchasePaymentStatus
    let verificationStatus: PurchaseVerificationStatus
    let deadline: Date
    let createdAt: Date
    let updatedAt: Date?  // Optional - backend may not always include this

    // Optional fields
    let sellerConfirmedAt: Date?
    let buyerConfirmedAt: Date?
    let verificationCompletedAt: Date?
    let refundedAt: Date?
    let meetupId: String?

    // Boolean confirmation flags (returned by accept endpoint)
    let sellerConfirmed: Bool?
    let buyerConfirmed: Bool?
    let transactionDisplayId: String?
    let isActive: Bool?
    let isPast: Bool?

    // Receipt fields
    let receiptId: String?
    let receiptGeneratedAt: Date?
    let receiptUrl: String?

    // Relationships
    var listing: PurchaseListing?
    var buyer: PurchaseUser?
    var seller: PurchaseUser?

    // Computed properties
    var isPending: Bool {
        return (paymentStatus == .pending || paymentStatus == .held) && verificationStatus == .pending
    }

    var isCompleted: Bool {
        return paymentStatus == .captured && verificationStatus == .bothConfirmed
    }

    // Custom init for Codable conformance
    init(id: String, listingId: String, buyerId: String, sellerId: String, purchaseType: PurchaseType, amount: Double, paymentIntentId: String?, paymentStatus: PurchasePaymentStatus, verificationStatus: PurchaseVerificationStatus, deadline: Date, createdAt: Date, updatedAt: Date?, sellerConfirmedAt: Date?, buyerConfirmedAt: Date?, verificationCompletedAt: Date?, refundedAt: Date?, meetupId: String?, sellerConfirmed: Bool?, buyerConfirmed: Bool?, transactionDisplayId: String?, isActive: Bool?, isPast: Bool?, receiptId: String?, receiptGeneratedAt: Date?, receiptUrl: String?, listing: PurchaseListing?, buyer: PurchaseUser?, seller: PurchaseUser?) {
        self.id = id
        self.listingId = listingId
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.purchaseType = purchaseType
        self.amount = amount
        self.paymentIntentId = paymentIntentId
        self.paymentStatus = paymentStatus
        self.verificationStatus = verificationStatus
        self.deadline = deadline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sellerConfirmedAt = sellerConfirmedAt
        self.buyerConfirmedAt = buyerConfirmedAt
        self.verificationCompletedAt = verificationCompletedAt
        self.refundedAt = refundedAt
        self.meetupId = meetupId
        self.sellerConfirmed = sellerConfirmed
        self.buyerConfirmed = buyerConfirmed
        self.transactionDisplayId = transactionDisplayId
        self.isActive = isActive
        self.isPast = isPast
        self.receiptId = receiptId
        self.receiptGeneratedAt = receiptGeneratedAt
        self.receiptUrl = receiptUrl
        self.listing = listing
        self.buyer = buyer
        self.seller = seller
    }

    var isExpired: Bool {
        return Date() > deadline
    }

    var timeRemaining: TimeInterval {
        return deadline.timeIntervalSinceNow
    }

    var daysRemaining: Int {
        let days = timeRemaining / 86400
        return max(0, Int(ceil(days)))
    }

    var formattedDeadline: String {
        return deadline.toUserFriendlyString()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case listingId = "listing_id"
        case buyerId = "buyer_id"
        case sellerId = "seller_id"
        case purchaseType = "purchase_type"
        case amount
        case paymentIntentId = "payment_intent_id"
        case paymentStatus = "payment_status"
        case verificationStatus = "verification_status"
        case deadline
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sellerConfirmedAt = "seller_confirmed_at"
        case buyerConfirmedAt = "buyer_confirmed_at"
        case verificationCompletedAt = "verification_completed_at"
        case refundedAt = "refunded_at"
        case meetupId = "meetup_id"
        case sellerConfirmed = "sellerConfirmed"
        case buyerConfirmed = "buyerConfirmed"
        case transactionDisplayId = "transactionDisplayId"
        case isActive = "isActive"
        case isPast = "isPast"
        case receiptId = "receipt_id"
        case receiptGeneratedAt = "receipt_generated_at"
        case receiptUrl = "receipt_url"
        case listing
        case buyer
        case seller
    }
}

// MARK: - API Response Models
// Note: PurchaseUser, PurchaseListing, and PurchaseListingDetail are defined in APITypes.swift
struct CreatePurchaseResponse: Codable {
    let success: Bool
    let purchase: Purchase?  // Optional - webhook flow doesn't return purchase immediately
    let message: String?
    let needsPaymentMethod: Bool?  // Present when payment method setup is required
    let checkoutUrl: String?  // Stripe Checkout URL for guest payment
    let sessionId: String?  // Stripe Checkout Session ID

    enum CodingKeys: String, CodingKey {
        case success
        case purchase
        case message
        case needsPaymentMethod = "needsPaymentMethod"
        case checkoutUrl = "checkoutUrl"
        case sessionId = "sessionId"
    }
}

struct PurchaseListResponse: Codable {
    let success: Bool
    let purchases: [Purchase]
}

struct VerifyPurchaseResponse: Codable {
    let success: Bool
    let purchase: Purchase
    let message: String
}

struct GetPurchaseResponse: Codable {
    let success: Bool
    let purchase: Purchase
}

struct CancelPurchaseResponse: Codable {
    let success: Bool
    let message: String?
}
