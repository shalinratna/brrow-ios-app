//
//  EarningsModels.swift
//  Brrow
//
//  Data models for Earnings features
//

import Foundation

// MARK: - Earnings Dashboard Overview

struct EarningsDashboardOverview: Codable {
    let totalEarnings: Double
    let availableBalance: Double
    let monthlyEarnings: Double
    let earningsChange: Double
    let itemsRented: Int
    let avgDailyEarnings: Double
    let pendingPayments: Int
}

// MARK: - Earnings Data Point

struct EarningsDataPoint: Identifiable, Codable {
    var id = UUID()
    let date: String  // Changed to String to avoid date decoding issues
    let amount: Double

    // Computed property for Date if needed
    var dataDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }

    enum CodingKeys: String, CodingKey {
        case date, amount
    }
}

// MARK: - Earnings Transaction

struct LegacyEarningsTransaction: Identifiable, Codable {
    let id: String
    let itemTitle: String
    let itemImageUrl: String?
    let renterName: String
    let amount: Double
    let date: String  // Changed to String to avoid date decoding issues
    let type: String  // Changed to String to accept any type from backend

    // Computed properties for compatibility
    var transactionDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }

    var transactionType: TransactionType? {
        return TransactionType(rawValue: type.lowercased())
    }

    enum TransactionType: String, Codable {
        case rental = "rental"
        case sale = "sale"
        case fee = "fee"
        case bonus = "bonus"
    }
}

// MARK: - Earnings Payout

struct EarningsPayout: Identifiable, Codable {
    let id: String
    let amount: Double
    let method: String
    let status: String  // Changed to String to accept any status from backend
    let date: String  // Changed to String to avoid date decoding issues
    let stripeTransferId: String?
    let estimatedArrival: String?

    // Computed property for status enum if needed
    var payoutStatus: PayoutStatus? {
        return PayoutStatus(rawValue: status.lowercased())
    }

    // Computed property for Date if needed
    var payoutDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }

    enum PayoutStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }

    enum CodingKeys: String, CodingKey {
        case id, amount, method, status, date
        case stripeTransferId = "stripe_transfer_id"
        case estimatedArrival = "estimated_arrival"
    }
}

// MARK: - Balance Transaction

struct BalanceTransaction: Identifiable, Codable {
    let id: String
    let type: String  // SALE_COMPLETED, RENTAL_COMPLETED, PAYOUT_REQUESTED, etc.
    let amount: Double
    let balanceAfter: Double
    let description: String
    let createdAt: String
    let relatedId: String?  // Transaction or payout ID
    let metadata: TransactionMetadata?

    var transactionType: BalanceTransactionType? {
        return BalanceTransactionType(rawValue: type)
    }

    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt)
    }

    var isCredit: Bool {
        guard let txType = transactionType else { return false }
        switch txType {
        case .saleCompleted, .rentalCompleted, .refundReceived:
            return true
        case .payoutRequested, .payoutCompleted, .platformFee:
            return false
        }
    }

    enum BalanceTransactionType: String, Codable {
        case saleCompleted = "SALE_COMPLETED"
        case rentalCompleted = "RENTAL_COMPLETED"
        case payoutRequested = "PAYOUT_REQUESTED"
        case payoutCompleted = "PAYOUT_COMPLETED"
        case platformFee = "PLATFORM_FEE"
        case refundReceived = "REFUND_RECEIVED"
    }

    struct TransactionMetadata: Codable {
        let listingTitle: String?
        let buyerName: String?
        let sellerName: String?

        enum CodingKeys: String, CodingKey {
            case listingTitle = "listing_title"
            case buyerName = "buyer_name"
            case sellerName = "seller_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, amount, description, metadata
        case balanceAfter = "balance_after"
        case createdAt = "created_at"
        case relatedId = "related_id"
    }
}

// MARK: - Payout Info

struct PayoutInfo: Codable {
    let minimumPayout: Double
    let payoutMethod: String  // "not_connected" or "stripe_transfer"
    let isPayoutEnabled: Bool
    let stripeAccountId: String?
    let accountStatus: String?  // "active", "restricted", "pending"

    enum CodingKeys: String, CodingKey {
        case minimumPayout = "minimum_payout"
        case payoutMethod = "payout_method"
        case isPayoutEnabled = "is_payout_enabled"
        case stripeAccountId = "stripe_account_id"
        case accountStatus = "account_status"
    }
}

// MARK: - Payout Request

struct PayoutRequest: Codable {
    let amount: Double
    let method: PayoutMethod
    let userId: String
}

// MARK: - New Payout Request (for Stripe)

struct StripePayoutRequest: Codable {
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case amount
    }
}

// MARK: - Payout Method

enum PayoutMethod: String, Codable, CaseIterable {
    case paypal = "PayPal"
    case bankTransfer = "Bank Transfer"
    case venmo = "Venmo"
    case cashApp = "Cash App"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .paypal: return "paypal"
        case .bankTransfer: return "building.columns"
        case .venmo: return "v.circle"
        case .cashApp: return "dollarsign.circle"
        }
    }
}