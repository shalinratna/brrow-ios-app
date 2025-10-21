//
//  IdentityVerification.swift
//  Brrow
//
//  Created by Claude on 1/21/25.
//  Stripe Identity verification data models
//

import Foundation

// MARK: - Verification Session (POST /api/identity/start)
struct VerificationSessionResponse: Codable {
    let success: Bool
    let sessionId: String
    let verificationUrl: String
    let clientSecret: String?
    let expiresAt: Date
    let status: String
    let alreadyVerified: Bool?

    enum CodingKeys: String, CodingKey {
        case success
        case sessionId
        case verificationUrl
        case clientSecret
        case expiresAt
        case status
        case alreadyVerified
    }
}

// MARK: - Verification Status (GET /api/identity/status/:sessionId)
struct VerificationStatusResponse: Codable {
    let success: Bool
    let sessionId: String
    let status: VerificationStatus
    let verifiedData: VerifiedData?
    let lastError: VerificationError?
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case success
        case sessionId
        case status
        case verifiedData
        case lastError
        case expiresAt
    }
}

// MARK: - Verification Status Enum
enum VerificationStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case requiresInput = "requires_input"
    case verified = "verified"
    case canceled = "canceled"
    case failed = "failed"

    var displayText: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .requiresInput:
            return "Additional Input Required"
        case .verified:
            return "Verified"
        case .canceled:
            return "Canceled"
        case .failed:
            return "Failed"
        }
    }

    var isComplete: Bool {
        return self == .verified
    }

    var needsAction: Bool {
        return self == .requiresInput
    }
}

// MARK: - Verified Data
struct VerifiedData: Codable {
    let name: String?
    let dob: DateOfBirth?
    let address: Address?
    let nationality: String?

    struct DateOfBirth: Codable {
        let day: Int
        let month: Int
        let year: Int

        var date: Date? {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            return Calendar.current.date(from: components)
        }

        var formatted: String {
            return "\(month)/\(day)/\(year)"
        }
    }

    struct Address: Codable {
        let line1: String?
        let line2: String?
        let city: String?
        let state: String?
        let postalCode: String?
        let country: String?

        enum CodingKeys: String, CodingKey {
            case line1
            case line2
            case city
            case state
            case postalCode = "postal_code"
            case country
        }

        var formatted: String {
            var parts: [String] = []
            if let line1 = line1 { parts.append(line1) }
            if let line2 = line2 { parts.append(line2) }
            if let city = city, let state = state {
                parts.append("\(city), \(state)")
            } else if let city = city {
                parts.append(city)
            } else if let state = state {
                parts.append(state)
            }
            if let postalCode = postalCode { parts.append(postalCode) }
            return parts.joined(separator: "\n")
        }
    }
}

// MARK: - Verification Error
struct VerificationError: Codable {
    let code: String?
    let reason: String?

    var message: String {
        return reason ?? "An error occurred during verification."
    }
}

// MARK: - User Verification Details (GET /api/identity/verification)
struct UserVerificationResponse: Codable {
    let success: Bool
    let verified: Bool
    let verification: UserVerification?

    enum CodingKeys: String, CodingKey {
        case success
        case verified
        case verification
    }
}

struct UserVerification: Codable {
    let userId: String
    let sessionId: String
    let verificationStatus: VerificationStatus
    let verifiedName: String?
    let verifiedDob: String?
    let verifiedAddress: String?
    let livenessCheckPassed: Bool?
    let faceMatchPassed: Bool?
    let documentCheckPassed: Bool?
    let verifiedAt: Date?
    let failedAt: Date?
    let failureCode: String?
    let failureReason: String?
    let expiresAt: Date?
    let submittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId
        case sessionId
        case verificationStatus
        case verifiedName
        case verifiedDob
        case verifiedAddress
        case livenessCheckPassed
        case faceMatchPassed
        case documentCheckPassed
        case verifiedAt
        case failedAt
        case failureCode
        case failureReason
        case expiresAt
        case submittedAt
    }

    var isVerified: Bool {
        return verificationStatus == .verified && verifiedAt != nil
    }

    var allChecksPassed: Bool {
        guard let liveness = livenessCheckPassed,
              let faceMatch = faceMatchPassed,
              let document = documentCheckPassed else {
            return false
        }
        return liveness && faceMatch && document
    }

    var failureMessage: String? {
        guard let reason = failureReason else { return nil }
        return reason
    }
}

// MARK: - Quick Verification Check (GET /api/identity/is-verified)
struct QuickVerificationResponse: Codable {
    let success: Bool
    let verified: Bool
}

// MARK: - Cancel Session Response (POST /api/identity/cancel/:sessionId)
struct CancelSessionResponse: Codable {
    let success: Bool
    let sessionId: String
    let status: String
    let canceledAt: Date

    enum CodingKeys: String, CodingKey {
        case success
        case sessionId
        case status
        case canceledAt
    }
}

// MARK: - Error Response
struct IdentityVerificationError: Codable, LocalizedError {
    let success: Bool
    let error: String
    let message: String?

    var errorDescription: String? {
        return message ?? error
    }
}
