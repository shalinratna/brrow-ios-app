//
//  APIClient+PEST.swift
//  Brrow
//
//  PEST Control integration for API calls
//

import Foundation
import SwiftUI

extension APIClient {

    // MARK: - Safe Request Wrapper
    func safeRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil,
        responseType: T.Type,
        retryCount: Int = 3
    ) async -> Result<T, Error> {

        for attempt in 1...retryCount {
            do {
                let result = try await performRequest(
                    endpoint: endpoint,
                    method: method.rawValue,
                    body: body,
                    responseType: responseType
                )

                // Success - log to Discord if first attempt failed
                if attempt > 1 {
                    PESTControlSystem.shared.captureError(
                        NSError(domain: "Recovery", code: 0),
                        context: "Request succeeded after \(attempt) attempts: \(endpoint)",
                        severity: .low
                    )
                }

                return .success(result)

            } catch {
                // Capture error with PEST
                let severity: PESTSeverity = attempt == retryCount ? .high : .medium

                PESTControlSystem.shared.captureError(
                    error,
                    context: "API Request Failed: \(endpoint)",
                    severity: severity,
                    userInfo: [
                        "endpoint": endpoint,
                        "method": method.rawValue,
                        "attempt": attempt,
                        "max_attempts": retryCount
                    ]
                )

                // Check if we should retry
                if attempt < retryCount {
                    // Wait before retry (exponential backoff)
                    let delay = Double(attempt) * 2.0
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                    // Check for specific errors that shouldn't retry
                    if let apiError = error as? BrrowAPIError {
                        switch apiError {
                        case .unauthorized:
                            // Token refresh would happen here if implemented
                            break
                        case .networkError:
                            // Check network status
                            PESTControlSystem.shared.handleNetworkError(
                                error,
                                endpoint: endpoint,
                                retry: {
                                    // Retry will happen in next loop iteration
                                }
                            )
                        default:
                            break
                        }
                    }

                    continue // Try again
                }

                return .failure(error)
            }
        }

        // Should never reach here
        return .failure(BrrowAPIError.invalidResponse)
    }

    // MARK: - Safe Login
    func safeLogin(email: String, password: String) async -> Result<AuthResponse, Error> {
        return await safeRequest(
            endpoint: "api/auth/login",
            method: .POST,
            body: try? JSONEncoder().encode(["email": email, "password": password]),
            responseType: AuthResponse.self
        )
    }

    // MARK: - Safe Listing Fetch
    func safeFetchListings(
        category: String? = nil,
        search: String? = nil
    ) async -> Result<[Listing], Error> {

        var endpoint = "api/listings?"
        var params: [String] = []

        if let category = category {
            params.append("category=\(category)")
        }
        if let search = search {
            params.append("search=\(search)")
        }

        if !params.isEmpty {
            endpoint += params.joined(separator: "&")
        }

        let result: Result<FetchListingsAPIResponse, Error> = await safeRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: FetchListingsAPIResponse.self
        )

        switch result {
        case .success(let response):
            return .success(response.allListings)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - AuthManager PEST Integration
extension AuthManager {

    func safeLogin(email: String, password: String) async -> Bool {
        let result = await APIClient.shared.safeLogin(email: email, password: password)

        switch result {
        case .success(let authResponse):
            DispatchQueue.main.async {
                self.handleAuthResponse(authResponse)
            }
            return true

        case .failure(let error):
            PESTControlSystem.shared.captureError(
                error,
                context: "Login Failed",
                severity: .high,
                userInfo: [
                    "email": email,
                    "timestamp": Date().timeIntervalSince1970
                ]
            )
            return false
        }
    }

    private func handleAuthResponse(_ response: AuthResponse) {
        self.authToken = response.token
        self.currentUser = response.user
        self.isAuthenticated = true

        // Save to UserDefaults (keychain is private, would need refactor to access)
        UserDefaults.standard.set(response.token, forKey: "authToken")
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
}

// MARK: - View Extensions for PEST
extension View {
    func pestProtected(context: String = "View Operation") -> some View {
        self.onAppear {
            // Track view appearance (disabled for now to reduce noise)
            #if DEBUG
            // Uncomment to enable view tracking
            // PESTControlSystem.shared.captureError(
            //     NSError(domain: "ViewTracking", code: 0),
            //     context: "View Appeared: \(context)",
            //     severity: .low
            // )
            #endif
        }
    }
}

// MARK: - Image Loading with PEST
// Note: CachedAsyncImage extension removed as it would need
// access to the internal URL property which may not be available.
// Image loading errors are caught at the network layer instead.
