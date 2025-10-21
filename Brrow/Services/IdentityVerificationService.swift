//
//  IdentityVerificationService.swift
//  Brrow
//
//  Created by Claude on 1/21/25.
//  Stripe Identity verification API client
//

import Foundation

class IdentityVerificationService {
    static let shared = IdentityVerificationService()
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Start Verification

    /// Creates a new Stripe Identity verification session
    /// - Parameter returnUrl: Deep link URL to return to after verification (default: brrow://identity/verification/complete)
    /// - Returns: Verification session with URL to Stripe's hosted verification page
    func startVerification(returnUrl: String = "brrow://identity/verification/complete") async throws -> VerificationSessionResponse {
        let endpoint = "api/identity/start"
        let body: [String: Any] = [
            "returnUrl": returnUrl
        ]

        print("🔵 [Identity Service] Starting verification session...")

        let response: VerificationSessionResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: .POST,
            body: body,
            responseType: VerificationSessionResponse.self
        )

        if response.alreadyVerified == true {
            print("✅ [Identity Service] User already verified")
        } else {
            print("✅ [Identity Service] Verification session created: \(response.sessionId)")
        }

        return response
    }

    // MARK: - Check Status

    /// Checks the status of a verification session
    /// - Parameter sessionId: Stripe verification session ID
    /// - Returns: Current verification status
    func checkVerificationStatus(sessionId: String) async throws -> VerificationStatusResponse {
        let endpoint = "api/identity/status/\(sessionId)"

        print("🔵 [Identity Service] Checking verification status: \(sessionId)")

        let response: VerificationStatusResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: VerificationStatusResponse.self
        )

        print("✅ [Identity Service] Status: \(response.status.rawValue)")

        return response
    }

    // MARK: - Get User Verification

    /// Gets the current user's verification details
    /// - Returns: User's complete verification information
    func getUserVerification() async throws -> UserVerificationResponse {
        let endpoint = "api/identity/verification"

        print("🔵 [Identity Service] Fetching user verification...")

        let response: UserVerificationResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: UserVerificationResponse.self
        )

        if response.verified {
            print("✅ [Identity Service] User is verified")
        } else {
            print("ℹ️ [Identity Service] User is not verified")
        }

        return response
    }

    // MARK: - Quick Verification Check

    /// Quick check if user is verified (lightweight)
    /// - Returns: Boolean indicating verification status
    func isUserVerified() async throws -> Bool {
        let endpoint = "api/identity/is-verified"

        let response: QuickVerificationResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: QuickVerificationResponse.self
        )

        return response.verified
    }

    // MARK: - Cancel Verification

    /// Cancels a pending verification session
    /// - Parameter sessionId: Stripe verification session ID
    /// - Returns: Canceled session response
    func cancelVerification(sessionId: String) async throws -> CancelSessionResponse {
        let endpoint = "api/identity/cancel/\(sessionId)"

        print("🔵 [Identity Service] Canceling verification session: \(sessionId)")

        let response: CancelSessionResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: .POST,
            responseType: CancelSessionResponse.self
        )

        print("✅ [Identity Service] Session canceled")

        return response
    }

    // MARK: - Polling Helper

    /// Polls verification status until completion or timeout
    /// - Parameters:
    ///   - sessionId: Stripe verification session ID
    ///   - maxAttempts: Maximum number of polling attempts (default: 60)
    ///   - intervalSeconds: Seconds between polls (default: 2)
    /// - Returns: Final verification status
    func pollVerificationStatus(
        sessionId: String,
        maxAttempts: Int = 60,
        intervalSeconds: UInt64 = 2
    ) async throws -> VerificationStatusResponse {
        print("🔵 [Identity Service] Starting polling for session: \(sessionId)")

        for attempt in 1...maxAttempts {
            let status = try await checkVerificationStatus(sessionId: sessionId)

            // Terminal states
            if status.status == .verified || status.status == .failed || status.status == .canceled {
                print("✅ [Identity Service] Polling complete - Final status: \(status.status.rawValue)")
                return status
            }

            // States that need user action
            if status.status == .requiresInput {
                print("⚠️ [Identity Service] Verification requires additional input")
                return status
            }

            // Continue polling for pending/processing states
            print("⏳ [Identity Service] Poll attempt \(attempt)/\(maxAttempts) - Status: \(status.status.rawValue)")

            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
            }
        }

        throw IdentityVerificationError(
            success: false,
            error: "Polling timeout",
            message: "Verification status check timed out after \(maxAttempts) attempts"
        )
    }
}
