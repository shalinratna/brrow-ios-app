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

struct EarningsTransaction: Identifiable, Codable {
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

    // Computed property for status enum if needed
    var payoutStatus: PayoutStatus? {
        return PayoutStatus(rawValue: status)
    }

    // Computed property for Date if needed
    var payoutDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }

    enum PayoutStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case processing = "Processing"
        case completed = "Completed"
        case failed = "Failed"
    }
}

// MARK: - Payout Request

struct PayoutRequest: Codable {
    let amount: Double
    let method: PayoutMethod
    let userId: String
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