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
    /// - Parameter returnUrl: HTTPS URL to return to after verification (default: https://brrowapp.com/verified)
    /// - Returns: Verification session with URL to Stripe's hosted verification page
    func startVerification(returnUrl: String = "https://brrowapp.com/verified") async throws -> StripeVerificationSessionResponse {
        let endpoint = "api/identity/start"
        let bodyDict: [String: Any] = [
            "returnUrl": returnUrl
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: bodyDict)

        print("🔵 [Identity Service] Starting verification session...")

        let response: StripeVerificationSessionResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: HTTPMethod.POST.rawValue,
            body: bodyData,
            responseType: StripeVerificationSessionResponse.self
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
    func checkVerificationStatus(sessionId: String) async throws -> StripeVerificationStatusResponse {
        let endpoint = "api/identity/status/\(sessionId)"

        print("🔵 [Identity Service] Checking verification status: \(sessionId)")

        let response: StripeVerificationStatusResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: HTTPMethod.GET.rawValue,
            responseType: StripeVerificationStatusResponse.self
        )

        print("✅ [Identity Service] Status: \(response.status.rawValue)")

        return response
    }

    // MARK: - Get User Verification

    /// Gets the current user's verification details
    /// - Returns: User's complete verification information
    func getUserVerification() async throws -> StripeUserVerificationResponse {
        let endpoint = "api/identity/verification"

        print("🔵 [Identity Service] Fetching user verification...")

        let response: StripeUserVerificationResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: HTTPMethod.GET.rawValue,
            responseType: StripeUserVerificationResponse.self
        )

        print("✅ [Identity Service] User verified: \(response.verified)")

        return response
    }

    // MARK: - Quick Verification Check

    /// Quick check if user is verified (lightweight endpoint)
    /// - Returns: Boolean verification status
    func isUserVerified() async throws -> Bool {
        let endpoint = "api/identity/is-verified"

        print("🔵 [Identity Service] Quick verification check...")

        let response: StripeIsVerifiedResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: HTTPMethod.GET.rawValue,
            responseType: StripeIsVerifiedResponse.self
        )

        print("✅ [Identity Service] Is verified: \(response.verified)")

        return response.verified
    }

    // MARK: - Cancel Verification

    /// Cancels an active verification session
    /// - Parameter sessionId: Stripe verification session ID
    /// - Returns: Canceled session details
    func cancelVerification(sessionId: String) async throws -> StripeCancelSessionResponse {
        let endpoint = "api/identity/cancel/\(sessionId)"

        print("🔵 [Identity Service] Canceling verification session: \(sessionId)")

        let response: StripeCancelSessionResponse = try await apiClient.performRequest(
            endpoint: endpoint,
            method: HTTPMethod.POST.rawValue,
            responseType: StripeCancelSessionResponse.self
        )

        print("✅ [Identity Service] Session canceled")

        return response
    }

    // MARK: - Poll Verification Status

    /// Polls verification status until complete or max attempts reached
    /// - Parameters:
    ///   - sessionId: Stripe verification session ID
    ///   - maxAttempts: Maximum number of polling attempts (default: 60 = 2 minutes at 2-second intervals)
    ///   - intervalSeconds: Seconds between polling attempts (default: 2)
    /// - Returns: Final verification status
    func pollVerificationStatus(
        sessionId: String,
        maxAttempts: Int = 60,
        intervalSeconds: UInt64 = 2
    ) async throws -> StripeVerificationStatusResponse {
        print("🔵 [Identity Service] Starting status polling (max \(maxAttempts) attempts)")

        for attempt in 1...maxAttempts {
            let status = try await checkVerificationStatus(sessionId: sessionId)

            // Check if verification is in final state
            if status.status.isComplete || status.status == .failed || status.status == .canceled {
                print("✅ [Identity Service] Verification reached final state: \(status.status.rawValue)")
                return status
            }

            // Wait before next poll (except on last attempt)
            if attempt < maxAttempts {
                print("⏳ [Identity Service] Attempt \(attempt)/\(maxAttempts) - Status: \(status.status.rawValue), waiting \(intervalSeconds)s...")
                try await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
            }
        }

        // Max attempts reached, return last status
        print("⚠️ [Identity Service] Max polling attempts reached")
        return try await checkVerificationStatus(sessionId: sessionId)
    }
}
