///  APIClient.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import Combine
import CoreLocation
import UIKit

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

// MARK: - API Errors
enum BrrowAPIError: Error, LocalizedError {
    case networkError(String)
    case serverError(String)
    case serverErrorCode(Int)
    case validationError(String)
    case decodingError(Error)
    case invalidResponse
    case invalidURL
    case unauthorized
    case addressConflict(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return message.isEmpty ? "Network connection error. Please check your internet." : message
        case .serverError(let message):
            return message.isEmpty ? "Server error. Please try again." : message
        case .serverErrorCode(let code):
            return "Server error (Code: \(code)). Please try again."
        case .validationError(let message):
            return message.isEmpty ? "Please check your information and try again." : message
        case .decodingError(let error):
            return "Unable to process server response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response. Please try again."
        case .invalidURL:
            return "Invalid URL format. Please check the request."
        case .unauthorized:
            return "Authentication required. Please log in again."
        case .addressConflict(let message):
            return message.isEmpty ? "Address conflict detected." : message
        }
    }
}

// MARK: - API Client
class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private var baseURL: String {
        get async {
            return await APIEndpointManager.shared.getBestEndpoint()
        }
    }

    // Public method to get base URL
    func getBaseURL() async -> String {
        return await baseURL
    }
    private var primaryURL = "https://brrow-backend-nodejs-production.up.railway.app"
    private let session: URLSession = NetworkManager.createURLSession()
    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthManager.shared
    
    // Debug mode - enable for testing
    private let debugMode = true
    
    // MARK: - Debug Logging
    private func debugLog(_ message: String, data: Any? = nil) {
        if debugMode {
            print("🐛 [Brrow API Debug] \(message)")
            if let data = data {
                print("📊 Data: \(data)")
            }
        }
    }
    
    // MARK: - Configuration
    static func configure(baseURL: String, timeout: TimeInterval, maxRetries: Int) {
        // baseURL is now managed by APIEndpointManager
        print("🔧 API Client configured with endpoint manager")
    }
    
    // MARK: - Token Refresh
    func attemptTokenRefresh() async -> String? {
        guard let currentToken = AuthManager.shared.authToken else {
            debugLog("❌ No current token to refresh")
            return nil
        }
        
        debugLog("🔄 Attempting token refresh")
        
        do {
            let baseURL = await self.baseURL
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/refresh-token")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(currentToken)", forHTTPHeaderField: "Authorization")
            
            // Add user API ID if available
            if let user = AuthManager.shared.currentUser {
                request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                debugLog("❌ Token refresh failed - HTTP error")
                return nil
            }
            
            struct TokenRefreshResponse: Codable {
                let success: Bool
                let data: TokenData?
                
                struct TokenData: Codable {
                    let token: String
                    let expires_at: String
                    let user: UserData
                    
                    struct UserData: Codable {
                        let id: Int
                        let api_id: String
                        let username: String
                        let email: String
                        let verified: Bool
                    }
                }
            }
            
            let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
            
            if refreshResponse.success, let tokenData = refreshResponse.data {
                // Update AuthManager with new token
                await MainActor.run {
                    AuthManager.shared.updateToken(tokenData.token)
                }
                debugLog("✅ Token refreshed successfully")
                return tokenData.token
            } else {
                debugLog("❌ Token refresh failed - API error")
                return nil
            }
            
        } catch {
            debugLog("❌ Token refresh failed - \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Discord Error Reporting
    private func reportErrorToDiscord(
        endpoint: String,
        errorType: String,
        errorMessage: String,
        responseData: Data? = nil,
        httpResponse: HTTPURLResponse? = nil,
        requestData: Data? = nil
    ) async {
        let responseString = responseData != nil ? String(data: responseData!, encoding: .utf8) ?? "Unable to decode response as UTF-8" : "No response data"
        let requestString = requestData != nil ? String(data: requestData!, encoding: .utf8) ?? "Unable to decode request as UTF-8" : "No request data"
        
        // Comprehensive error report data
        let _ = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "error_type": errorType,
            "endpoint": endpoint,
            "error_message": errorMessage,
            "http_status": httpResponse?.statusCode ?? 0,
            "response_headers": httpResponse?.allHeaderFields ?? [:],
            "raw_response": responseString,
            "response_size": responseData?.count ?? 0,
            "request_data": requestString,
            "request_size": requestData?.count ?? 0,
            "expected_format": "APIResponse<T>",
            "actual_format_detected": responseData != nil ? detectResponseFormat(responseString) : "no_response",
            "device_info": [
                "platform": "iOS",
                "app_version": "1.0",
                "debug_mode": debugMode,
                "base_url": await baseURL
            ]
        ] as [String: Any]
        
        // Disable Discord webhook for now - causing network errors
        debugLog("Discord error reporting disabled")
        return
    }
    
    private func getErrorColor(for errorType: String) -> Int {
        switch errorType.lowercased() {
        case "network_error": return 16711680 // Red
        case "server_error": return 16753920 // Orange
        case "database_error": return 16711680 // Red
        case "authentication_error": return 16776960 // Yellow
        case "validation_error": return 16753920 // Orange
        case "json_decoding_error": return 16711935 // Magenta
        default: return 15158332 // Default red
        }
    }
    
    private func detectResponseFormat(_ responseString: String) -> String {
        guard let data = responseString.data(using: .utf8) else { return "invalid_utf8" }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let keys = json?.keys.sorted().joined(separator: ", ") ?? "no_keys"
            return "JSON object with keys: [\(keys)]"
        } catch {
            return "invalid_json: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Shaiitech System Headers
    private func createRequest(for endpoint: String, method: HTTPMethod = .GET) async -> URLRequest {
        let baseURL = await self.baseURL
        let urlString = "\(baseURL)/\(endpoint)"
        // Ensure URL is valid and won't cause NaN errors
        let sanitized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty,
              let url = URL(string: sanitized) else {
            debugLog("❌ Invalid URL: \(urlString)")
            // Return a dummy request to avoid crash
            return URLRequest(url: URL(string: "https://brrow-backend-nodejs-production.up.railway.app/health")!)
        }
        
        debugLog("Creating request", data: ["endpoint": endpoint, "method": method.rawValue, "url": url.absoluteString])
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("BrrowApp-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "X-Mobile-App")
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("HTTP/1.1", forHTTPHeaderField: "HTTP-Version")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        // Add Shaiitech system headers
        let requestId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970.description
        request.setValue(requestId, forHTTPHeaderField: "X-Request-ID")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        
        debugLog("Added system headers", data: ["X-Request-ID": requestId, "X-Timestamp": timestamp])
        
        // Add auth token if available
        let authManager = AuthManager.shared
        debugLog("🔍 Checking auth state", data: [
            "isAuthenticated": authManager.isAuthenticated,
            "hasToken": authManager.authToken != nil,
            "hasUser": authManager.currentUser != nil,
            "userApiId": authManager.currentUser?.apiId ?? "nil"
        ])
        
        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            debugLog("✅ Added auth token", data: ["token_prefix": String(token.prefix(10)) + "..."])
        } else {
            debugLog("❌ No auth token available")
            // Also check keychain directly
            if let storedToken = KeychainHelper().loadString(forKey: "brrow_auth_token") {
                debugLog("⚠️ Token exists in keychain but not in AuthManager!", data: ["keychain_token_prefix": String(storedToken.prefix(10)) + "..."])
            }
        }
        
        // Add user_api_id header if available
        if let user = AuthManager.shared.currentUser {
            if let apiId = user.apiId, !apiId.isEmpty {
                request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
                debugLog("✅ Added user API ID", data: ["user_api_id": apiId, "username": user.username])
            } else {
                debugLog("❌ User exists but apiId is nil or empty!", data: [
                    "user_id": user.id,
                    "username": user.username,
                    "apiId": user.apiId ?? "nil"
                ])
                // Try to use the user's main ID as a fallback
                if !user.id.isEmpty && user.id != "unknown" {
                    request.setValue(user.id, forHTTPHeaderField: "X-User-API-ID")
                    debugLog("⚠️ Using user.id as fallback for X-User-API-ID", data: ["fallback_id": user.id])
                }
            }
        } else {
            debugLog("❌ No current user available for API ID")
        }
        
        return request
    }

    // MARK: - Retry Wrapper for Raw URLSession Calls
    /// Performs a raw URLRequest with exponential backoff retry logic
    /// Use this for legacy functions that need retry logic but don't use Decodable responses
    private func performRawRequestWithRetry(
        _ request: URLRequest,
        maxRetries: Int = 3
    ) async throws -> (Data, URLResponse) {
        var lastError: Error?
        var delay: TimeInterval = 1.0
        let maxDelay: TimeInterval = 8.0

        for attempt in 0..<maxRetries {
            do {
                debugLog("🔄 API Request attempt \(attempt + 1)/\(maxRetries)", data: ["url": request.url?.absoluteString ?? "unknown"])

                // Check network connectivity
                if !NetworkManager.shared.isConnected {
                    throw BrrowAPIError.networkError("No network connection")
                }

                // Perform request
                let (data, response) = try await session.data(for: request)

                // Check response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw BrrowAPIError.invalidResponse
                }

                debugLog("📡 Response: \(httpResponse.statusCode)", data: ["url": request.url?.path ?? "unknown"])

                // Handle different status codes
                switch httpResponse.statusCode {
                case 200...299:
                    // Success - return data
                    return (data, response)

                case 401:
                    throw BrrowAPIError.unauthorized

                case 400...499:
                    // Client error - don't retry
                    let errorMessage: String
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorData["error"] as? String {
                        errorMessage = message
                    } else {
                        errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
                    }

                    // Report 404 errors to PEST
                    if httpResponse.statusCode == 404 {
                        let requestPath = request.url?.path ?? "unknown"
                        let requestMethod = request.httpMethod ?? "GET"
                        PESTControlSystem.shared.captureError(
                            BrrowAPIError.validationError(errorMessage),
                            context: "API 404 Not Found: \(requestPath)",
                            severity: .high,
                            userInfo: [
                                "endpoint": requestPath,
                                "statusCode": httpResponse.statusCode,
                                "method": requestMethod,
                                "response": errorMessage
                            ]
                        )
                    }

                    throw BrrowAPIError.validationError(errorMessage)

                case 500...599:
                    // Server error - retryable
                    debugLog("⚠️ Server error \(httpResponse.statusCode) - will retry if attempts remain")
                    let serverError = BrrowAPIError.serverErrorCode(httpResponse.statusCode)

                    // Report 500+ errors to PEST
                    let requestPath = request.url?.path ?? "unknown"
                    let requestMethod = request.httpMethod ?? "GET"
                    PESTControlSystem.shared.captureError(
                        serverError,
                        context: "API Server Error: \(requestPath)",
                        severity: .critical,
                        userInfo: [
                            "endpoint": requestPath,
                            "statusCode": httpResponse.statusCode,
                            "method": requestMethod,
                            "response": String(data: data, encoding: .utf8) ?? "N/A",
                            "attempt": attempt + 1,
                            "maxRetries": maxRetries
                        ]
                    )

                    lastError = serverError

                default:
                    lastError = BrrowAPIError.serverError("Unexpected status code: \(httpResponse.statusCode)")
                }

            } catch let error as URLError {
                // Network errors - retryable
                switch error.code {
                case .timedOut:
                    debugLog("⏱️ Request timed out (attempt \(attempt + 1))")
                    lastError = BrrowAPIError.networkError("Request timed out")

                case .notConnectedToInternet, .networkConnectionLost:
                    debugLog("📵 Network connection lost (attempt \(attempt + 1))")
                    lastError = BrrowAPIError.networkError("Network connection lost")

                case .cannotConnectToHost, .cannotFindHost:
                    debugLog("🚫 Cannot connect to server (attempt \(attempt + 1))")
                    lastError = BrrowAPIError.networkError("Cannot connect to server")

                default:
                    debugLog("❌ Network error: \(error.localizedDescription)")
                    lastError = error
                }

            } catch {
                // Check for task cancellation - don't retry
                if Task.isCancelled || error is CancellationError {
                    debugLog("🛑 Task was cancelled - stopping retry")
                    throw CancellationError()
                }

                // Other errors
                if error is BrrowAPIError {
                    // Don't retry API-specific errors (validation, unauthorized, etc.)
                    throw error
                }
                lastError = error
            }

            // Check for cancellation before sleeping
            if Task.isCancelled {
                throw CancellationError()
            }

            // If we have more attempts, wait before retrying
            if attempt < maxRetries - 1 {
                debugLog("⏳ Waiting \(delay)s before retry...")
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    // If sleep was cancelled, stop retrying
                    if Task.isCancelled || error is CancellationError {
                        debugLog("🛑 Sleep cancelled - stopping retry")
                        throw CancellationError()
                    }
                    throw error
                }

                // Exponential backoff: 1s, 2s, 4s, 8s
                delay = min(delay * 2.0, maxDelay)
            }
        }

        // All attempts failed
        throw lastError ?? BrrowAPIError.networkError("All retry attempts failed")
    }

    // MARK: - Generic Request Method for Decodable-only types (no caching)
    private func performRequestNoCaching<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        var request = await createRequest(for: endpoint, method: method)
        
        if let body = body {
            request.httpBody = body
            // Truncate large request bodies in debug output to prevent massive gaps
            let bodyString = String(data: body, encoding: .utf8) ?? "non-utf8"
            let truncatedBody = bodyString.count > 500 ? String(bodyString.prefix(500)) + "... [TRUNCATED]" : bodyString
            debugLog("Added request body", data: ["body_size": body.count, "body_preview": truncatedBody])
        }
        
        debugLog("🌐 API Request", data: [
            "endpoint": endpoint,
            "method": method.rawValue,
            "url": request.url?.absoluteString ?? "nil"
        ])
        
        do {
            // Use NetworkManager's retry logic with better error handling
            let result = try await NetworkManager.performRequestWithRetry(
                request: request,
                session: session,
                responseType: T.self
            )
            
            // If NetworkManager successfully decoded the response, return it
            return result
        } catch let error as BrrowAPIError {
            // Re-throw Brrow API errors
            throw error
        } catch {
            // For other errors, try to extract more information
            debugLog("❌ Request failed with error", data: [
                "error": error.localizedDescription,
                "type": String(describing: type(of: error))
            ])
            
            // Convert to BrrowAPIError for consistency
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw BrrowAPIError.networkError("Request timed out")
                case .notConnectedToInternet, .networkConnectionLost:
                    throw BrrowAPIError.networkError("No internet connection")
                case .secureConnectionFailed:
                    throw BrrowAPIError.networkError("SSL connection failed")
                default:
                    throw BrrowAPIError.networkError(urlError.localizedDescription)
                }
            }
            
            throw BrrowAPIError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Generic Request Method with Caching (requires Codable)
    private func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type,
        cachePolicy: CachePolicy = .networkFirst
    ) async throws -> T {
        let cacheKey = CacheManager.shared.apiCacheKey(endpoint: endpoint, parameters: nil)
        
        // Check cache first based on policy
        if cachePolicy != .ignoreCache && cachePolicy != .refreshCache {
            if let cached = CacheManager.shared.load(T.self, forKey: cacheKey, policy: cachePolicy) {
                debugLog("✅ Cache hit for endpoint: \(endpoint)")
                return cached
            }
        }
        
        var request = await createRequest(for: endpoint, method: method)
        
        if let body = body {
            request.httpBody = body
            // Truncate large request bodies in debug output to prevent massive gaps
            let bodyString = String(data: body, encoding: .utf8) ?? "non-utf8"
            let truncatedBody = bodyString.count > 500 ? String(bodyString.prefix(500)) + "... [TRUNCATED]" : bodyString
            debugLog("Added request body", data: ["body_size": body.count, "body_preview": truncatedBody])
        }
        
        debugLog("Executing request", data: ["url": request.url?.absoluteString ?? "unknown"])
        
        do {
            // Use NetworkManager's retry logic for consistent error handling
            let result = try await NetworkManager.performRequestWithRetry(
                request: request,
                session: session,
                responseType: T.self
            )
            
            // Cache the successful response
            if cachePolicy != .ignoreCache {
                CacheManager.shared.save(result, forKey: cacheKey)
                debugLog("💾 Cached response for endpoint: \(endpoint)")
            }
            
            return result
        } catch let error as BrrowAPIError {
            // Re-throw Brrow API errors
            throw error
        } catch {
            // For other errors, convert to BrrowAPIError for consistency
            debugLog("❌ Request failed", data: [
                "error": error.localizedDescription,
                "type": String(describing: type(of: error))
            ])
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw BrrowAPIError.networkError("Request timed out")
                case .notConnectedToInternet, .networkConnectionLost:
                    throw BrrowAPIError.networkError("No internet connection")
                case .secureConnectionFailed:
                    throw BrrowAPIError.networkError("SSL connection failed")
                default:
                    throw BrrowAPIError.networkError(urlError.localizedDescription)
                }
            }
            
            throw BrrowAPIError.networkError(error.localizedDescription)
        }
        
        // Old manual retry code - no longer needed
        /* Remove after testing
        // Declare variables that need to be accessible in error handling
        var responseData: Data?
        var httpResponse: HTTPURLResponse?
            
            let responseString = String(data: responseData, encoding: .utf8) ?? "non-utf8"
            let truncatedResponse = responseString.count > 500 ? String(responseString.prefix(500)) + "... [TRUNCATED]" : responseString
            debugLog("Received response", data: [
                "status_code": httpResponse.statusCode,
                "headers": httpResponse.allHeaderFields,
                "response_size": responseData.count,
                "response_preview": truncatedResponse
            ])
            
            guard httpResponse.statusCode == 200 else {
                debugLog("❌ HTTP Error", data: ["status_code": httpResponse.statusCode])
                if httpResponse.statusCode == 401 {
                    debugLog("⚠️ 401 Unauthorized for endpoint: \(endpoint)", data: ["response": responseString])
                    
                    // Don't logout immediately - some endpoints may return 401 for other reasons
                    // Only logout for critical auth endpoints where 401 definitely means invalid token
                    let criticalAuthEndpoints = ["api/auth/login", "api/auth/register", "api/auth/test", "api/auth/refresh-token", "api/auth/validate-token", "api/users/me"]
                    let shouldConsiderLogout = criticalAuthEndpoints.contains(where: { endpoint.contains($0) })
                    
                    // Never logout guest users
                    if AuthManager.shared.isGuestUser {
                        debugLog("⚠️ Guest user - skipping logout on 401")
                        throw BrrowAPIError.unauthorized
                    }
                    
                    // Check if we can refresh the token and retry (only once to avoid infinite loop)
                    if endpoint != "api/auth/refresh-token", let refreshed = await TokenManager.shared.refreshToken() {
                        debugLog("🔄 Token refreshed, retrying request")
                        // Update the authorization header with new token
                        var retryRequest = request
                        retryRequest.setValue("Bearer \(refreshed)", forHTTPHeaderField: "Authorization")
                        
                        // Retry the request directly without recursion
                        let (retryData, retryResponse) = try await session.data(for: retryRequest)
                        
                        guard let retryHttpResp = retryResponse as? HTTPURLResponse else {
                            throw BrrowAPIError.networkError("Invalid retry response")
                        }
                        
                        if retryHttpResp.statusCode == 200 {
                            // Parse successful retry response
                            let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: retryData)
                            if apiResponse.success {
                                guard let data = apiResponse.data else {
                                    throw BrrowAPIError.decodingError(NSError(domain: "BrrowAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
                                }
                                return data
                            } else {
                                throw BrrowAPIError.validationError(apiResponse.message ?? "Unknown error")
                            }
                        } else {
                            debugLog("❌ Retry also failed", data: ["retry_status": retryHttpResp.statusCode, "endpoint": endpoint])
                            // Only logout if it's a critical endpoint AND retry failed
                            if shouldConsiderLogout {
                                debugLog("🚪 Logging out due to 401 on critical endpoint")
                                await MainActor.run {
                                    AuthManager.shared.logout()
                                }
                            } else {
                                debugLog("⚠️ Not logging out - non-critical endpoint")
                            }
                            throw BrrowAPIError.unauthorized
                        }
                    } else {
                        debugLog("❌ Cannot refresh token or refresh failed for endpoint: \(endpoint)")
                        // Only logout if it's a critical endpoint
                        if shouldConsiderLogout {
                            debugLog("🚪 Logging out due to inability to refresh token on critical endpoint")
                            await MainActor.run {
                                AuthManager.shared.logout()
                            }
                        } else {
                            debugLog("⚠️ Not logging out - non-critical endpoint may have auth issues")
                        }
                        throw BrrowAPIError.unauthorized
                    }
                } else {
                    // Try to get error message from response
                    let errorString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                    debugLog("Server error response", data: ["error_body": errorString])
                    
                    // Report all HTTP errors to Discord
                    Task {
                        await reportErrorToDiscord(
                            endpoint: endpoint,
                            errorType: "server_error",
                            errorMessage: "HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))",
                            responseData: responseData,
                            httpResponse: httpResponse,
                            requestData: request.httpBody
                        )
                    }
                    
                    // For registration endpoints, provide user-friendly error messages
                    if endpoint.contains("register") || endpoint.contains("login") {
                        if errorString.contains("Fatal error") || errorString.contains("Database") {
                            throw BrrowAPIError.serverErrorCode(503) // Service Unavailable
                        }
                    }
                    
                    throw BrrowAPIError.serverErrorCode(httpResponse.statusCode)
                }
            }
            
            // Try to decode as APIResponse<T> first, with fallback handling
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: responseData)
                debugLog("✅ Response decoded as APIResponse<T>", data: ["success": apiResponse.success])
                
                if apiResponse.success {
                    guard let data = apiResponse.data else {
                        throw BrrowAPIError.decodingError(NSError(domain: "BrrowAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
                    }
                    // Cache successful responses
                    if cachePolicy != .ignoreCache {
                        CacheManager.shared.save(data, forKey: cacheKey, expiration: .minutes(30))
                        debugLog("💾 Cached response for endpoint: \(endpoint)")
                    }
                    return data
                } else {
                    debugLog("❌ API Error", data: ["message": apiResponse.message ?? "Unknown error"])
                    throw BrrowAPIError.validationError(apiResponse.message ?? "Unknown error")
                }
            } catch {
                // If APIResponse decoding fails, try alternative formats
                debugLog("⚠️ APIResponse decoding failed, trying alternative formats")
                
                // Try to decode the response as the target type directly (for legacy endpoints)
                do {
                    let directResponse = try JSONDecoder().decode(T.self, from: responseData)
                    debugLog("✅ Response decoded directly as target type")
                    // Cache successful responses
                    if cachePolicy != .ignoreCache {
                        CacheManager.shared.save(directResponse, forKey: cacheKey, expiration: .minutes(30))
                        debugLog("💾 Cached response for endpoint: \(endpoint)")
                    }
                    return directResponse
                } catch {
                    // For EmptyResponse type, try to handle simple success responses
                    if T.self == EmptyResponse.self {
                        do {
                            let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
                            if let success = json?["success"] as? Bool, success == true {
                                debugLog("✅ Response decoded as simple success response")
                                return EmptyResponse(success: true, message: nil) as! T
                            }
                        } catch {
                            debugLog("❌ Failed to parse as simple success response")
                        }
                    }
                    
                    // For AuthResponse type, handle different response formats
                    if T.self == AuthResponse.self {
                        let responseString = String(data: responseData, encoding: .utf8) ?? ""
                        
                        // Check for database errors first
                        if responseString.contains("Fatal error") || responseString.contains("Database") {
                            debugLog("❌ Database error detected in authentication")
                            
                            // Report database errors to Discord
                            Task {
                                await reportErrorToDiscord(
                                    endpoint: endpoint,
                                    errorType: "database_error",
                                    errorMessage: "Database connection failed during authentication",
                                    responseData: responseData,
                                    httpResponse: httpResponse,
                                    requestData: request.httpBody
                                )
                            }
                            
                            throw BrrowAPIError.serverErrorCode(503)
                        }
                        
                        // Try to parse the direct server response format
                        do {
                            let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
                            if let success = json?["success"] as? Bool, success == true,
                               let dataDict = json?["data"] as? [String: Any],
                               let userData = dataDict["user"] as? [String: Any],
                               let token = dataDict["token"] as? String {
                                
                                debugLog("✅ Parsing direct server response format")
                                
                                // Try to decode the user data
                                do {
                                    let userDataJSON = try JSONSerialization.data(withJSONObject: userData, options: [])
                                    let user = try JSONDecoder().decode(User.self, from: userDataJSON)
                                    let authResponse = AuthResponse(token: token, user: user)
                                    return authResponse as! T
                                } catch {
                                    // Fallback to simple initialization
                                    let user = User(
                                        id: userData["id"] as? Int ?? 0,
                                        username: userData["username"] as? String ?? "",
                                        email: userData["email"] as? String ?? "",
                                        apiId: userData["api_id"] as? String,
                                        profilePicture: userData["profile_picture"] as? String
                                    )
                                    let authResponse = AuthResponse(token: token, user: user)
                                    return authResponse as! T
                                }
                            }
                        } catch {
                            debugLog("❌ Failed to parse direct server response format")
                        }
                    }
                    
                    // If all else fails, throw the original decoding error
                    throw error
                }
            }
            */ // End of old manual retry code
    }
    
    // MARK: - Username Availability Check
    func checkUsernameAvailability(username: String) async throws -> UsernameAvailabilityResponse {
        debugLog("🔍 Checking username availability", data: ["username": username])

        let endpoint = "\(APIEndpoints.Auth.checkUsername)/\(username)"

        let response = try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: UsernameAvailabilityResponse.self,
            cachePolicy: .ignoreCache  // Never cache username checks
        )

        debugLog("✅ Username check response", data: [
            "available": response.available,
            "message": response.message
        ])

        return response
    }

    // MARK: - Authentication
    func login(email: String, password: String) async throws -> AuthResponse {
        let loginRequest = LoginRequest(username: email, password: password)
        let bodyData = try JSONEncoder().encode(loginRequest)
        
        debugLog("🔐 Login attempt", data: ["email": email])
        
        // Login endpoint returns direct response, not wrapped
        let response = try await performRequest(
            endpoint: APIEndpoints.Auth.login,
            method: .POST,
            body: bodyData,
            responseType: AuthResponse.self,
            cachePolicy: .ignoreCache  // Never cache auth responses
        )
        
        debugLog("🔐 Login response received", data: [
            "hasToken": response.authToken != nil,
            "token": response.authToken ?? "nil",
            "tokenLength": response.authToken?.count ?? 0,
            "userApiId": response.user.apiId ?? "nil",
            "userName": response.user.username ?? "nil"
        ])
        
        // Ensure token is present (support both accessToken and token)
        guard let token = response.authToken, !token.isEmpty else {
            debugLog("❌ Token missing or empty in response")
            throw BrrowAPIError.serverError("Authentication token missing from response")
        }
        
        debugLog("✅ Login successful, returning AuthResponse with token")
        return response
    }
    
    func appleLogin(userIdentifier: String, email: String?, firstName: String?, lastName: String?, identityToken: String) async throws -> AuthResponse {
        let request = AppleLoginRequest(
            appleUserId: userIdentifier,
            email: email,
            firstName: firstName,
            lastName: lastName,
            identityToken: identityToken
        )
        let bodyData = try JSONEncoder().encode(request)
        
        debugLog("🍎 Apple Sign In attempt", data: ["userIdentifier": userIdentifier, "email": email ?? "none"])
        
        let response = try await performRequest(
            endpoint: APIEndpoints.Auth.appleLogin,
            method: .POST,
            body: bodyData,
            responseType: APIResponse<AuthResponse>.self
        )
        
        debugLog("🍎 Apple Sign In response", data: [
            "success": response.success,
            "hasData": response.data != nil,
            "hasToken": response.data?.token != nil
        ])
        
        guard response.success, let authData = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Apple Sign In failed")
        }
        
        // Ensure token is present (support both accessToken and token)
        guard let token = authData.authToken, !token.isEmpty else {
            debugLog("❌ Token missing or empty in Apple Sign In response")
            throw BrrowAPIError.serverError("Authentication token missing from response")
        }
        
        debugLog("✅ Apple Sign In successful")
        return authData
    }
    
    func register(username: String, email: String, password: String, firstName: String, lastName: String, birthdate: String) async throws -> AuthResponse {
        debugLog("🔐 Starting registration", data: ["username": username, "email": email, "birthdate": birthdate])
        
        let registerRequest = RegisterRequest(username: username, email: email, password: password, firstName: firstName, lastName: lastName, birthdate: birthdate)
        let bodyData = try JSONEncoder().encode(registerRequest)
        
        debugLog("📤 Registration request encoded", data: ["body_size": bodyData.count])
        
        // The registration endpoint returns a RegistrationResponse
        // Backend returns: { success: true, message: "...", user: {...}, accessToken: "...", refreshToken: "...", verificationToken: "..." }
        let registrationData = try await performRequest(
            endpoint: APIEndpoints.Auth.register,
            method: .POST,
            body: bodyData,
            responseType: RegistrationResponse.self,  // Use RegistrationResponse type
            cachePolicy: .ignoreCache  // Never cache auth responses
        )
        
        // Convert RegistrationResponse to AuthResponse
        let authResponse = AuthResponse(
            token: nil,
            accessToken: registrationData.accessToken,
            refreshToken: registrationData.refreshToken,
            user: registrationData.user,
            expiresAt: nil,
            isNewUser: true
        )
        
        debugLog("✅ Registration successful", data: [
            "hasToken": authResponse.authToken != nil,
            "username": authResponse.user.username,
            "message": registrationData.message ?? ""
        ])
        
        return authResponse
    }
    
    // MARK: - Combine-based Authentication (for legacy support)
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, BrrowAPIError> {
        return Future { promise in
            Task {
                do {
                    let result = try await self.login(email: email, password: password)
                    promise(.success(result))
                } catch {
                    if let brrowError = error as? BrrowAPIError {
                        promise(.failure(BrrowAPIError.networkError(brrowError.localizedDescription)))
                    } else {
                        promise(.failure(BrrowAPIError.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func register(username: String, email: String, password: String, birthdate: String) -> AnyPublisher<AuthResponse, BrrowAPIError> {
        return Future { promise in
            Task {
                do {
                    let authResponse = try await self.register(username: username, email: email, password: password, firstName: "", lastName: "", birthdate: birthdate)
                    promise(.success(authResponse))
                } catch {
                    if let brrowError = error as? BrrowAPIError {
                        promise(.failure(BrrowAPIError.networkError(brrowError.localizedDescription)))
                    } else {
                        promise(.failure(BrrowAPIError.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Password Reset
    func requestPasswordReset(email: String) async throws -> PasswordResetResponse {
        let requestData = ["email": email]
        let bodyData = try JSONEncoder().encode(requestData)
        
        return try await performRequest(
            endpoint: "api/auth/request-password-reset",
            method: .POST,
            body: bodyData,
            responseType: PasswordResetResponse.self
        )
    }
    
    func resetPassword(token: String, newPassword: String) async throws -> PasswordResetResponse {
        let requestData = [
            "token": token,
            "password": newPassword
        ]
        let bodyData = try JSONEncoder().encode(requestData)
        
        return try await performRequest(
            endpoint: "api/auth/reset-password",
            method: .POST,
            body: bodyData,
            responseType: PasswordResetResponse.self
        )
    }
    
    // MARK: - Creator System
    
    // MARK: - Enhanced Creator Application System

    func submitCreatorApplication(
        motivation: String,
        experience: String,
        businessName: String? = nil,
        businessDescription: String? = nil,
        experienceYears: Int? = nil,
        portfolioLinks: String? = nil,
        expectedMonthlyRevenue: Double? = nil,
        platform: String? = nil,
        followers: Int? = nil,
        contentType: String? = nil,
        referralStrategy: String? = nil
    ) async throws -> CreatorApplicationResponse {

        let requestData = CreatorApplicationRequest(
            motivation: motivation,
            experience: experience,
            businessName: businessName,
            businessDescription: businessDescription,
            experienceYears: experienceYears ?? 0,
            portfolioLinks: portfolioLinks?.split(separator: ",").map(String.init) ?? [],
            expectedMonthlyRevenue: expectedMonthlyRevenue,
            agreedToTerms: true
        )

        let bodyData = try JSONEncoder().encode(requestData)

        return try await performRequest(
            endpoint: "api/creators/apply",
            method: .POST,
            body: bodyData,
            responseType: CreatorApplicationResponse.self
        )
    }

    func getCreatorApplicationStatus() async throws -> CreatorApplicationResponse {
        return try await performRequest(
            endpoint: "api/creators/application",
            method: .GET,
            responseType: CreatorApplicationResponse.self
        )
    }
    
    func getCreatorStatus() async throws -> CreatorStatusResponse {
        return try await performRequest(
            endpoint: "api/creators/status",
            method: .GET,
            responseType: CreatorStatusResponse.self
        )
    }
    
    func getCreatorDashboard() async throws -> LegacyCreatorDashboard {
        return try await performRequest(
            endpoint: "api/creators/dashboard",
            method: .GET,
            responseType: LegacyCreatorDashboard.self
        )
    }
    
    func setCreatorReferral(code: String) async throws -> SetCreatorReferralResponse {
        let requestData = ["creator_code": code]
        let bodyData = try JSONEncoder().encode(requestData)
        
        return try await performRequest(
            endpoint: "api/creators/referral",
            method: .POST,
            body: bodyData,
            responseType: SetCreatorReferralResponse.self
        )
    }
    
    func startCreatorStripeOnboarding() async throws -> CreatorStripeOnboardingResponse {
        return try await performRequest(
            endpoint: "api/creators/stripe-onboarding",
            method: .POST,
            body: nil,
            responseType: CreatorStripeOnboardingResponse.self
        )
    }
    
    // SHALIN: - Auth from api
    func testPersonalConnection() async throws -> [String: Any] {
        debugLog("Starting personal connection test...")
        
        let request = await createRequest(for: "api/auth/test-personal-connection", method: .GET)
        let (data, response) = try await session.data(for: request)
        
        guard response is HTTPURLResponse else {
            throw BrrowAPIError.networkError("Invalid response")
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
        
        debugLog("Test personal connection has successfully completed")
        return json
    }
    
    // MARK: - Authentication Testing
    func testAuthenticationDetailed() async throws -> [String: Any] {
        debugLog("🔐 Testing authentication...")
        
        let request = await createRequest(for: "api/auth/test", method: .GET)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BrrowAPIError.networkError("Invalid response")
        }
        
        debugLog("🔐 Test auth response", data: ["status": httpResponse.statusCode])
        
        // Parse the response as JSON dictionary
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            debugLog("❌ Failed to parse test auth response: \(responseString)")
            throw BrrowAPIError.decodingError(NSError(domain: "BrrowAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
        }
        
        return json
    }
    
    // MARK: - User Profile
    func fetchUserProfile(userId: Int) async throws -> ProfileResponse {
        let response = try await performRequest(
            endpoint: "api/users/\(userId)/profile",
            method: .GET,
            responseType: APIResponse<ProfileResponse>.self
        )
        
        guard response.success, let profile = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch user profile")
        }
        
        return profile
    }
    
    // fetchUserActivities is defined later in the file to return [APIUserActivity]
    
    // MARK: - File Upload
    func uploadFileData(_ imageData: Data, fileName: String, endpoint: String = "api/upload", entityType: String = "listings", entityId: String? = nil) async throws -> String {
        // High-quality upload with configurable endpoint and entity type
        let base64String = imageData.base64EncodedString()
        let fileType = fileName.hasSuffix(".png") ? "image/png" : "image/jpeg"
        
        let uploadRequest = [
            "image": base64String,  // Send raw base64, not data URL
            "entity_type": entityType,  // Entity type (listings, users, seeks, etc.)
            "entity_id": entityId ?? "",      // Entity ID if available
            "type": entityType.trimmingCharacters(in: .init(charactersIn: "s")), // Legacy compatibility
            "fileName": fileName,
            "fileType": fileType,
            "media_type": "image",
            "quality": "highest",  // Request highest quality processing
            "preserve_metadata": true
        ] as [String: Any]
        
        let bodyData = try JSONSerialization.data(withJSONObject: uploadRequest)
        
        struct UploadData: Codable {
            let url: String?  // Backend returns 'url'
            let imageUrl: String?  // For backward compatibility
            let publicId: String?  // Backend returns 'public_id'
            let thumbnailUrl: String?
            let width: Int?
            let height: Int?
            let size: Int?
            
            enum CodingKeys: String, CodingKey {
                case url
                case imageUrl = "image_url"
                case publicId = "public_id"
                case thumbnailUrl = "thumbnail_url"
                case width, height, size
            }
        }
        
        struct UploadResponse: Codable {
            let success: Bool
            let message: String
            let data: UploadData? // Response data with URLs
            let timestamp: String?
        }
        
        let response = try await performRequest(
            endpoint: endpoint,
            method: .POST,
            body: bodyData,
            responseType: UploadResponse.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message)
        }
        
        // Return the image URL from the response (check both url and imageUrl fields)
        if let url = response.data?.url {
            return url
        } else if let imageUrl = response.data?.imageUrl {
            return imageUrl
        } else {
            throw BrrowAPIError.serverError("No image URL in upload response")
        }
    }
    
    func uploadFile(_ imageData: Data, fileName: String) async throws -> String {
        // Legacy method - redirects to the new high-quality method with proper entity context
        // Generate temp ID for organization
        let tempId = "temp_\(UUID().uuidString.prefix(8))"
        return try await uploadFileData(
            imageData, 
            fileName: fileName, 
            endpoint: "api/upload",
            entityType: "misc",  // Default to misc for legacy calls
            entityId: tempId
        )
    }
    
    func uploadProfilePicture(imageData: Data) async throws -> String {
        // Get current user's API ID for organization
        let userApiId = authManager.currentUser?.apiId ?? "unknown_user"

        // AGGRESSIVE compression to prevent timeouts
        var compressedData = imageData
        let maxSize = 50 * 1024  // 50KB max for profile pictures

        // If data is too large, compress it
        if imageData.count > maxSize {
            guard let image = UIImage(data: imageData) else {
                throw BrrowAPIError.validationError("Invalid image data")
            }

            // Resize to small profile picture size
            let maxDimension: CGFloat = 400  // Small for profile pics
            let resizedImage = image.resizedWithAspectRatio(maxDimension: maxDimension)

            // Try different compression levels
            for quality in stride(from: 0.5, to: 0.1, by: -0.1) {
                if let data = resizedImage.jpegData(compressionQuality: quality) {
                    if data.count <= maxSize {
                        compressedData = data
                        print("📸 Profile pic compressed to \(data.count / 1024)KB")
                        break
                    }
                }
            }

            // Last resort - use minimum quality
            if compressedData.count > maxSize {
                if let minData = resizedImage.jpegData(compressionQuality: 0.1) {
                    compressedData = minData
                    print("⚠️ Profile pic still \(compressedData.count / 1024)KB at min quality")
                }
            }
        }

        // Use enhanced profile picture upload endpoint
        let uploadRequest = [
            "imageData": "data:image/jpeg;base64,\(compressedData.base64EncodedString())",
            "fileName": "profile_picture.jpg"
        ] as [String: Any]

        let bodyData = try JSONSerialization.data(withJSONObject: uploadRequest)

        // Add debug logging for profile picture upload
        print("📸 Profile picture upload request: \(String(data: bodyData, encoding: .utf8)?.prefix(200) ?? "nil")")

        let response = try await performRequest(
            endpoint: "api/profile/upload-picture",
            method: .POST,
            body: bodyData,
            responseType: ImageUploadResponse.self,
            cachePolicy: .ignoreCache
        )

        print("📸 Profile picture upload response: \(response)")
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to upload profile picture")
        }

        // The backend returns profilePictureUrl in the response
        let url = response.profilePictureUrl ?? response.url ?? response.data?.url ?? response.user?.profilePicture ?? ""

        // Update local user data if available (user is now at root level) - on main thread
        if let userData = response.user {
            await MainActor.run {
                authManager.updateUser(userData)
            }
        }

        return url
    }

    // MARK: - Profile Picture Upload with Crop Data
    func uploadProfilePictureWithCrop(imageData: Data, cropData: CropData? = nil) async throws -> String {
        // Get current user's API ID for organization
        let userApiId = authManager.currentUser?.apiId ?? "unknown_user"

        // AGGRESSIVE compression to prevent timeouts
        var compressedData = imageData
        let maxSize = 100 * 1024  // 100KB max for profile pictures with crop data

        // If data is too large, compress it
        if imageData.count > maxSize {
            guard let image = UIImage(data: imageData) else {
                throw BrrowAPIError.validationError("Invalid image data")
            }

            // Resize to optimal profile picture size
            let maxDimension: CGFloat = 600  // Higher quality for cropped images
            let resizedImage = image.resizedWithAspectRatio(maxDimension: maxDimension)

            // Try different compression levels
            for quality in stride(from: 0.8, to: 0.3, by: -0.1) {
                if let data = resizedImage.jpegData(compressionQuality: quality) {
                    if data.count <= maxSize {
                        compressedData = data
                        print("📸 Profile pic with crop data compressed to \(data.count / 1024)KB")
                        break
                    }
                }
            }

            // Last resort - use minimum quality
            if compressedData.count > maxSize {
                if let minData = resizedImage.jpegData(compressionQuality: 0.3) {
                    compressedData = minData
                    print("⚠️ Profile pic still \(compressedData.count / 1024)KB at min quality")
                }
            }
        }

        // Create upload request with optional crop data
        var uploadRequest: [String: Any] = [
            "imageData": "data:image/jpeg;base64,\(compressedData.base64EncodedString())",
            "fileName": "profile_picture.jpg"
        ]

        // Add crop data if available
        if let cropData = cropData {
            uploadRequest["cropData"] = [
                "offsetX": cropData.offsetX,
                "offsetY": cropData.offsetY,
                "scale": cropData.scale,
                "cropSize": cropData.cropSize
            ]
        }

        let bodyData = try JSONSerialization.data(withJSONObject: uploadRequest)

        // Add debug logging for profile picture upload
        print("📸 Profile picture upload with crop data request: \(String(data: bodyData, encoding: .utf8)?.prefix(300) ?? "nil")")

        let response = try await performRequest(
            endpoint: "api/profile/upload-picture",
            method: .POST,
            body: bodyData,
            responseType: ImageUploadResponse.self,
            cachePolicy: .ignoreCache
        )

        print("📸 Profile picture upload response: \(response)")

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to upload profile picture")
        }

        // The backend returns profilePictureUrl in the response
        let url = response.profilePictureUrl ?? response.url ?? response.data?.url ?? response.user?.profilePicture ?? ""

        // Update local user data if available (user is now at root level) - on main thread
        if let userData = response.user {
            await MainActor.run {
                authManager.updateUser(userData)
            }
        }

        return url
    }
    
    func uploadProfilePicture(_ imageData: Data, fileName: String) async throws -> ProfilePictureUploadResponse {
        // Legacy method for compatibility
        let url = try await uploadProfilePicture(imageData: imageData)
        return ProfilePictureUploadResponse(success: true, message: "Upload successful", data: ProfilePictureUploadResponse.ProfilePictureData(url: url, thumbnailUrl: nil))
    }

    // MARK: - Profile Picture Upload with User Data
    func uploadProfilePictureWithUserData(imageData: String) async throws -> User {
        struct ProfilePictureRequest: Codable {
            let imageData: String
            let fileName: String
        }

        struct ProfilePictureResponse: Codable {
            let success: Bool
            let message: String
            let profilePictureUrl: String?
            let user: User
        }

        let request = ProfilePictureRequest(imageData: imageData, fileName: "profile.jpg")
        let bodyData = try JSONEncoder().encode(request)

        let response = try await performRequest(
            endpoint: "api/profile/upload-picture",
            method: .POST,
            body: bodyData,
            responseType: ProfilePictureResponse.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message)
        }

        return response.user
    }
    
    // MARK: - Search Methods
    
    func searchListings(query: String, filters: AdvancedSearchFilters? = nil) async throws -> [Listing] {
        var parameters: [String: Any] = ["query": query]
        
        if let filters = filters {
            // Add filter parameters
            if !filters.categories.isEmpty {
                parameters["categories"] = Array(filters.categories).joined(separator: ",")
            }
            parameters["min_price"] = filters.priceRange?.lowerBound
            parameters["max_price"] = filters.priceRange?.upperBound
            parameters["distance"] = filters.distance
            parameters["free_only"] = filters.freeItemsOnly
            parameters["verified_only"] = filters.verifiedSellersOnly
            parameters["sort"] = filters.sortBy.rawValue
        }
        
        // Convert parameters to query string
        let baseURL = await self.baseURL
        var urlComponents = URLComponents(string: "\(baseURL)/api/search")!
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        
        guard let url = urlComponents.url else {
            throw BrrowAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if available
        if let user = AuthManager.shared.currentUser {
            request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BrrowAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BrrowAPIError.serverErrorCode(httpResponse.statusCode)
        }
        
        let searchResponse = try JSONDecoder().decode(ListingResponse.self, from: data)
        
        guard searchResponse.success else {
            throw BrrowAPIError.serverError(searchResponse.message ?? "Search failed")
        }
        
        return searchResponse.data?.listings ?? []
    }
    
    // MARK: - Listings
    func fetchListings(
        category: String? = nil,
        search: String? = nil,
        location: CLLocation? = nil,
        radius: Double? = nil
    ) async throws -> [Listing] {
        // Check cache first
        let cacheKey = category ?? "all"
        if let cachedListings = DataCacheManager.shared.getCachedListings(category: cacheKey) {
            // Using cached listings for category: \(cacheKey)
            return cachedListings
        }
        
        var endpoint = "api/listings?"
        var params: [String] = []
        
        if let category = category {
            params.append("category=\(category)")
        }
        if let search = search {
            params.append("search=\(search)")
        }
        if let location = location {
            params.append("lat=\(location.coordinate.latitude)")
            params.append("lng=\(location.coordinate.longitude)")
        }
        if let radius = radius {
            params.append("radius=\(radius)")
        }
        
        if !params.isEmpty {
            endpoint += params.joined(separator: "&")
        }
        
        // Fetch with the actual API response structure
        let response = try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: FetchListingsAPIResponse.self
        )
        
        // Convert to Listing array
        let listings = response.allListings
        
        // Cache the listings
        if !listings.isEmpty {
            DataCacheManager.shared.cacheListings(listings, category: cacheKey)
        }
        
        return listings
    }
    
    func fetchListingDetails(id: Int) async throws -> Listing {
        // Deprecated - use fetchListingDetailsByListingId instead
        let response = try await performRequest(
            endpoint: "api/listings/\(id)",
            method: .GET,
            responseType: APIResponse<Listing>.self
        )
        
        guard response.success, let listing = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch listing details")
        }
        
        return listing
    }
    
    func fetchListingDetailsByListingId(_ listingId: String) async throws -> Listing {
        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)",
            method: .GET,
            responseType: APIResponse<Listing>.self
        )
        
        guard response.success, let listing = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch listing details")
        }
        
        // Use the listing directly from the response
        var mutableListing = listing
        
        // Owner information is now read-only computed properties
        // No need to set them manually as they come from the user field
        
        // Check if current user is the owner
        if let currentUser = AuthManager.shared.currentUser {
            // Compare API IDs if available, otherwise compare numeric IDs
            if let ownerApiId = mutableListing.user?.apiId, !ownerApiId.isEmpty {
                mutableListing.isOwner = (currentUser.apiId == ownerApiId)
            } else {
                mutableListing.isOwner = (currentUser.id == mutableListing.userId)
            }
        } else {
            mutableListing.isOwner = false
        }
        
        return mutableListing
    }
    
    func createListing(_ listing: CreateListingRequest) async throws -> Listing {
        let bodyData = try JSONEncoder().encode(listing)
        
        struct CreateListingAPIResponse: Codable {
            let success: Bool?
            let status: String?
            let message: String?
            let data: Listing?  // Backend returns data field
            let listing: Listing?  // Sometimes also includes listing field
            let error: String?
        }
        
        let response = try await performRequest(
            endpoint: "api/listings",
            method: .POST,
            body: bodyData,
            responseType: CreateListingAPIResponse.self
        )
        
        // Check for success and get listing from either data or listing field
        let isSuccess = response.success == true || response.status == "success"
        guard isSuccess, let createdListing = response.data ?? response.listing else {
            throw BrrowAPIError.serverError(response.error ?? response.message ?? "Failed to create listing")
        }
        
        return createdListing
    }
    
    // MARK: - Listing Management
    
    func updateListing(listingId: String, updates: [String: Any]) async throws -> Listing {
        let bodyData = try JSONSerialization.data(withJSONObject: updates)

        struct UpdateListingAPIResponse: Codable {
            let success: Bool
            let listing: Listing?
            let error: String?
        }

        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)",
            method: .PUT,
            body: bodyData,
            responseType: UpdateListingAPIResponse.self,
            cachePolicy: .ignoreCache // Don't use cache for updates
        )

        guard response.success, let updatedListing = response.listing else {
            throw BrrowAPIError.serverError(response.error ?? "Failed to update listing")
        }

        // CRITICAL FIX: Clear cache for this specific listing to force fresh data on next read
        let cacheKey = CacheManager.shared.apiCacheKey(endpoint: "api/listings/\(listingId)", parameters: nil)
        CacheManager.shared.remove(forKey: cacheKey)
        debugLog("🗑️ Cleared cache for listing: \(listingId)")

        return updatedListing
    }
    
    func deleteListing(listingId: String) async throws {
        struct DeleteListingAPIResponse: Codable {
            let success: Bool
            let message: String?
            let error: String?
        }
        
        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)",
            method: .DELETE,
            body: nil,
            responseType: DeleteListingAPIResponse.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.error ?? "Failed to delete listing")
        }
    }
    
    // MARK: - Garage Sale Edit/Delete
    
    func updateGarageSale(saleId: String, updates: [String: Any]) async throws -> GarageSale {
        var body = updates
        body["sale_id"] = saleId
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response = try await performRequest(
            endpoint: "api/garage-sales",
            method: .PUT,
            body: bodyData,
            responseType: GarageSaleUpdateResponse.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update garage sale")
        }
        
        return data
    }
    
    func deleteGarageSale(saleId: String) async throws {
        let body = ["sale_id": saleId]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response = try await performRequest(
            endpoint: "api/garage-sales",
            method: .POST,
            body: bodyData,
            responseType: DeleteResponse.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to delete garage sale")
        }
    }
    
    // MARK: - Seeks Edit/Delete
    
    func updateSeek(seekId: String, updates: [String: Any]) async throws -> Seek {
        var body = updates
        body["seek_id"] = seekId
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response = try await performRequest(
            endpoint: "api/seeks",
            method: .PUT,
            body: bodyData,
            responseType: SeekUpdateResponse.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update seek")
        }
        
        return data
    }
    
    func deleteSeek(seekId: String) async throws {
        let body = ["seek_id": seekId]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response = try await performRequest(
            endpoint: "api/seeks",
            method: .POST,
            body: bodyData,
            responseType: DeleteResponse.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to delete seek")
        }
    }
    
    // MARK: - Listing Update Operations
    
    func updateListingField(listingId: String, field: String, value: Any) async throws {
        let body: [String: Any] = [field: value]

        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)",
            method: .PATCH,
            body: try JSONSerialization.data(withJSONObject: body),
            responseType: APIResponse<EmptyResponse>.self,
            cachePolicy: .ignoreCache // Don't use cache for updates
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update listing")
        }

        // CRITICAL FIX: Clear cache for this specific listing to force fresh data on next read
        let cacheKey = CacheManager.shared.apiCacheKey(endpoint: "api/listings/\(listingId)", parameters: nil)
        CacheManager.shared.remove(forKey: cacheKey)
        debugLog("🗑️ Cleared cache for listing: \(listingId)")
    }
    
    func updateListingBulk(listingId: String, updates: [String: Any]) async throws {
        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)",
            method: .PATCH,
            body: try JSONSerialization.data(withJSONObject: updates),
            responseType: APIResponse<EmptyResponse>.self,
            cachePolicy: .ignoreCache // Don't use cache for updates
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update listing")
        }

        // CRITICAL FIX: Clear cache for this specific listing to force fresh data on next read
        let cacheKey = CacheManager.shared.apiCacheKey(endpoint: "api/listings/\(listingId)", parameters: nil)
        CacheManager.shared.remove(forKey: cacheKey)
        debugLog("🗑️ Cleared cache for listing: \(listingId)")
    }

    // Update listing status using the new status system
    func updateListingStatus(listingId: String, status: String) async throws -> Listing {
        struct StatusUpdateRequest: Codable {
            let status: String
        }

        struct StatusUpdateResponse: Codable {
            let success: Bool
            let message: String?
            let data: Listing?
            let error: String?
        }

        let requestBody = StatusUpdateRequest(status: status)
        let bodyData = try JSONEncoder().encode(requestBody)

        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)/status",
            method: .PUT,
            body: bodyData,
            responseType: StatusUpdateResponse.self,
            cachePolicy: .ignoreCache
        )

        guard response.success, let updatedListing = response.data else {
            throw BrrowAPIError.serverError(response.error ?? response.message ?? "Failed to update listing status")
        }

        // Clear cache for this listing to force fresh data
        let cacheKey = CacheManager.shared.apiCacheKey(endpoint: "api/listings/\(listingId)", parameters: nil)
        CacheManager.shared.remove(forKey: cacheKey)
        debugLog("✅ Updated listing status to \(status), cleared cache")

        return updatedListing
    }

    // MARK: - Rental Transaction Operations
    func createRentalRequest(data: [String: Any]) async throws -> [String: Any] {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api_create_rental.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: data)

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to create rental request")
        }

        return response
    }
    
    func acceptRejectRental(transactionId: String, action: String, rejectionReason: String? = nil) async throws -> [String: Any] {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api_accept_rental.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        var body: [String: Any] = [
            "transaction_id": transactionId,
            "action": action
        ]

        if let reason = rejectionReason {
            body["rejection_reason"] = reason
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to process rental request")
        }

        return response
    }
    
    func completeRental(transactionId: String, condition: String, notes: String?, rating: Int?, review: String?) async throws -> [String: Any] {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api_complete_rental.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        var body: [String: Any] = [
            "transaction_id": transactionId,
            "condition": condition
        ]

        if let notes = notes { body["notes"] = notes }
        if let rating = rating { body["rating"] = rating }
        if let review = review { body["review"] = review }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to complete rental")
        }

        return response
    }
    
    func getRentals(type: String = "all", status: String = "all", limit: Int = 20, offset: Int = 0) async throws -> [String: Any] {
        let baseURL = await self.baseURL
        var components = URLComponents(string: "\(baseURL)/api_get_rentals.php")!
        components.queryItems = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to fetch rentals")
        }

        return response
    }
    
    // MARK: - Push Notification Operations
    
    func registerDeviceToken(_ deviceInfo: [String: Any]) async throws -> [String: Any] {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api/users/me/fcm-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: deviceInfo)

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to register device token")
        }

        return response
    }
    
    func getNotificationPreferences() async throws -> NotificationSettings {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api_notification_preferences.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to fetch notification preferences")
        }

        guard let data = response["data"] as? [String: Any],
              let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: jsonData) else {
            throw BrrowAPIError.decodingError(NSError(domain: "BrrowAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
        }

        return settings
    }
    
    func updateNotificationPreferences(_ preferences: [String: Any]) async throws -> [String: Any] {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api_notification_preferences.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: preferences)

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to update notification preferences")
        }

        return response
    }
    
    func getNotifications(type: String = "all", limit: Int = 20, offset: Int = 0) async throws -> (notifications: [AppNotification], unreadCount: Int) {
        let baseURL = await self.baseURL
        var components = URLComponents(string: "\(baseURL)/api/notifications")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "unread_only", value: type == "unread" ? "true" : "false")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        guard let notificationsData = response["notifications"] as? [[String: Any]],
              let jsonData = try? JSONSerialization.data(withJSONObject: notificationsData),
              let notifications = try? JSONDecoder().decode([AppNotification].self, from: jsonData) else {
            throw BrrowAPIError.decodingError(NSError(domain: "BrrowAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
        }

        let unreadCount = response["unreadCount"] as? Int ?? 0

        return (notifications, unreadCount)
    }

    // Removed duplicate - using the APIResponse version below

    func markAllNotificationsAsRead_OLD() async throws -> [String: Any] {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api/notifications/read-all")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to mark all notifications as read")
        }

        return response
    }
    
    func sendTestNotification(data: [String: Any]) async throws -> [String: Any] {
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api_send_push_notification.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: data)

        let (responseData, _) = try await performRawRequestWithRetry(request)
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] ?? [:]

        if response["success"] as? Bool != true {
            throw BrrowAPIError.serverError(response["message"] as? String ?? "Failed to send test notification")
        }

        return response
    }
    
    func createListingWithPromotion(_ request: CreateListingWithPromotionRequest) async throws -> CreateListingWithPromotionResponse {
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "create_listing_with_promotion.php",
            method: .POST,
            body: bodyData,
            responseType: CreateListingWithPromotionResponse.self
        )
    }
    
    func confirmPromotionPayment(paymentIntentId: String, listingId: Int) async throws -> PromotionConfirmationResponse {
        let request = ConfirmPromotionRequest(
            promotionId: paymentIntentId,
            paymentMethod: String(listingId)
        )
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "confirm_promotion_payment.php",
            method: .POST,
            body: bodyData,
            responseType: PromotionConfirmationResponse.self
        )
    }
    
    func fetchFeaturedListings(category: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> ListingsResponse {
        var endpoint = APIEndpoints.Listings.featured + "?"
        var params: [String] = []
        
        if let category = category {
            params.append("category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        params.append("limit=\(limit)")
        params.append("offset=\(offset)")
        
        endpoint += params.joined(separator: "&")
        
        // Use the correct response type that matches the API
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: ListingsResponse.self,
            cachePolicy: .cacheFirst
        )
    }
    
    func fetchUserListings(userId: Int) async throws -> [Listing] {
        struct UserListingsResponse: Codable {
            let listings: [Listing]
            let stats: ListingStats?
            
            struct ListingStats: Codable {
                let total_listings: Int
                let active_listings: Int
                let archived_listings: Int
                let total_views: Int
                let total_borrowed: Int
                let avg_rating: Double?
            }
        }
        
        let response = try await performRequest(
            endpoint: APIEndpoints.Listings.getUserListings + "?user_id=\(userId)",
            method: .GET,
            responseType: APIResponse<UserListingsResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch user listings")
        }
        
        return data.listings
    }
    
    // MARK: - Garage Sales
    func fetchGarageSales(
        searchText: String? = nil,
        radius: Double? = nil,
        location: CLLocation? = nil
    ) async throws -> [GarageSale] {
        var endpoint = APIEndpoints.GarageSales.fetchAll + "?"
        var params: [String] = []
        
        if let searchText = searchText {
            params.append("search=\(searchText)")
        }
        if let radius = radius {
            params.append("radius=\(radius)")
        }
        if let location = location {
            params.append("lat=\(location.coordinate.latitude)")
            params.append("lng=\(location.coordinate.longitude)")
        }
        
        if !params.isEmpty {
            endpoint += params.joined(separator: "&")
        }
        
        // Create a response structure to match the actual API response
        struct GarageSalesResponse: Codable {
            let success: Bool
            let garage_sales: [GarageSale]
            let pagination: Pagination
            
            struct Pagination: Codable {
                let page: Int
                let limit: Int
                let total: Int
                let pages: Int
            }
        }
        
        let response = try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: GarageSalesResponse.self
        )
        
        return response.garage_sales
    }
    
    func createGarageSale(_ garageSale: CreateGarageSaleRequest) async throws -> GarageSale {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601Full)
        let bodyData = try encoder.encode(garageSale)
        
        let response = try await performRequest(
            endpoint: "api/garage-sales",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<GarageSale>.self
        )
        
        guard response.success, let garageSale = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create garage sale")
        }
        
        return garageSale
    }
    
    func reportAddressConflict(_ request: ReportAddressConflictRequest) async throws {
        let bodyData = try JSONEncoder().encode(request)
        
        _ = try await performRequest(
            endpoint: "report_address_conflict.php",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<EmptyResponse>.self
        )
    }
    
    func deleteGarageSale(id: Int) async throws -> Void {
        _ = try await performRequest(
            endpoint: "delete_garage_sale.php?id=\(id)",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
    }
    
    func fetchGarageSaleDetails(id: Int) async throws -> GarageSale {
        return try await performRequest(
            endpoint: "api/get_garage_sale_details.php?id=\(id)",
            method: .GET,
            responseType: GarageSale.self
        )
    }
    
    func rsvpGarageSale(id: Int, isRsvp: Bool) async throws -> RSVPResponse {
        let request = RSVPRequest(garageSaleId: String(id), isRsvp: isRsvp)
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "api/garage_sales/rsvp.php",
            method: .POST,
            body: bodyData,
            responseType: RSVPResponse.self
        )
    }
    
    func toggleGarageSaleFavorite(id: Int) async throws -> FavoriteResponse {
        let request = GarageSaleFavoriteRequest(garageSaleId: String(id))
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "api/garage_sales/favorite.php",
            method: .POST,
            body: bodyData,
            responseType: FavoriteResponse.self
        )
    }
    
    func toggleGarageSaleActive(id: Int, isActive: Bool) async throws -> GarageSale {
        let request = ToggleActiveRequest(isActive: isActive)
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "api/toggle_garage_sale_active.php",
            method: .POST,
            body: bodyData,
            responseType: GarageSale.self
        )
    }
    
    func toggleGarageSaleFeatured(id: Int, isFeatured: Bool) async throws -> GarageSale {
        let request = ToggleFeaturedRequest(isFeatured: isFeatured)
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "api/toggle_garage_sale_feature.php",
            method: .POST,
            body: bodyData,
            responseType: GarageSale.self
        )
    }
    
    func fetchUserGarageSales(userId: Int? = nil, status: String = "all") async throws -> [GarageSale] {
        var endpoint = APIEndpoints.GarageSales.fetchAll + "?status=\(status)"
        if let userId = userId {
            endpoint += "&user_id=\(userId)"
        }
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: [GarageSale].self
        )
    }
    
    func fetchUserGarageSales(userId: String, status: String = "all") async throws -> [GarageSale] {
        let endpoint = APIEndpoints.GarageSales.fetchAll + "?status=\(status)&user_id=\(userId)"
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: [GarageSale].self
        )
    }
    
    // MARK: - Search & Discovery
    
    func fetchSearchSuggestions(query: String) async throws -> [SearchSuggestion] {
        let baseURL = await self.baseURL
        var components = URLComponents(string: "\(baseURL)/api/search/suggestions")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "10")
        ]
        
        guard let url = components.url else {
            throw BrrowAPIError.serverErrorCode(400)
        }
        
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(SearchSuggestionsResponse.self, from: data)
        
        // Convert API response to SearchSuggestion models
        var suggestions: [SearchSuggestion] = []
        
        // Convert simple string suggestions to SearchSuggestion models
        for suggestionText in response.suggestions {
            suggestions.append(SearchSuggestion(
                query: suggestionText,
                type: .query,
                count: nil
            ))
        }
        
        return suggestions
    }
    
    func searchListings(query: String, page: Int = 1, sort: MarketplaceSortOption? = nil) async throws -> [Listing] {
        let baseURL = await self.baseURL
        var components = URLComponents(string: "\(baseURL)/api/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        if let sort = sort {
            components.queryItems?.append(URLQueryItem(name: "sort", value: sortParameterValue(for: sort)))
        }
        
        guard let url = components.url else {
            throw BrrowAPIError.serverErrorCode(400)
        }
        
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(ListingsResponse.self, from: data)
        return response.allListings
    }
    
    // MARK: - Fetch Listings from Server  
    /// Fetches all active listings from the server
    /// Endpoint: /api/listings
    /// NEW CLEAN STRUCTURE - All APIs in /api/ directory
    /// - Direct database connection
    /// - Automatic temp/misc image replacement
    /// - Background preloading compatible
    /// - Organized in /api/listings/ directory
    /// Returns: Array of Listing objects with images, location, and all metadata
    func fetchListings() async throws -> [Listing] {
        // Add limit parameter to fetch all listings (default backend limit is 20)
        // IMPORTANT: This endpoint fetches ALL active listings from ALL users for marketplace browsing
        // It should NEVER include a user_id parameter
        let endpoint = "\(APIEndpoints.Listings.fetchAll)?limit=1000"

        debugLog("🏪 [MARKETPLACE] Fetching ALL listings for marketplace (no user filter)", data: ["endpoint": endpoint])

        // Use public request for marketplace browsing (no auth required)
        let response = try await performPublicRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: ListingsResponse.self
        )

        debugLog("🏪 [MARKETPLACE] Successfully fetched \(response.allListings.count) listings from ALL users")

        return response.allListings
    }

    /// Public request method that doesn't require authentication (for browsing marketplace)
    private func performPublicRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        let baseURL = await self.baseURL
        let urlString = "\(baseURL)/\(endpoint)"

        guard let url = URL(string: urlString) else {
            throw BrrowAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("BrrowApp-iOS/1.0", forHTTPHeaderField: "User-Agent")

        if let body = body {
            request.httpBody = body
        }

        debugLog("Executing public request", data: ["url": url.absoluteString])

        let (data, response) = try await performRawRequestWithRetry(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BrrowAPIError.invalidResponse
        }

        debugLog("Received response", data: ["status": httpResponse.statusCode, "data_size": data.count])

        guard httpResponse.statusCode == 200 else {
            throw BrrowAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            debugLog("✅ Successfully decoded public response")
            return decodedResponse
        } catch {
            debugLog("❌ Failed to decode public response", data: ["error": error.localizedDescription])
            throw BrrowAPIError.decodingError(error)
        }
    }
    
    func fetchFilteredListings(category: String? = nil, filters: MarketplaceFilters? = nil, page: Int = 1) async throws -> [Listing] {
        let baseURL = await self.baseURL
        var components = URLComponents(string: "\(baseURL)/api/listings")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page))
        ]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if let filters = filters {
            if let priceRange = filters.priceRange {
                queryItems.append(URLQueryItem(name: "min_price", value: String(Int(priceRange.lowerBound))))
                queryItems.append(URLQueryItem(name: "max_price", value: String(Int(priceRange.upperBound))))
            }
            
            if let distance = filters.distance {
                queryItems.append(URLQueryItem(name: "distance", value: String(Int(distance))))
            }
            
            if let availability = filters.availability {
                queryItems.append(URLQueryItem(name: "available", value: availability ? "1" : "0"))
            }
            
            queryItems.append(URLQueryItem(name: "sort", value: sortParameterValue(for: filters.sortBy)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw BrrowAPIError.serverErrorCode(400)
        }
        
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(ListingsResponse.self, from: data)
        return response.allListings
    }
    
    private func sortParameterValue(for sort: MarketplaceSortOption) -> String {
        return sort.apiValue
    }
    
    // MARK: - Seeks
    func fetchSeeks() async throws -> [Seek] {
        struct SeeksResponse: Codable {
            let seeks: [Seek]
            let pagination: PaginationInfo?
        }
        
        let response = try await performRequest(
            endpoint: "api/seeks",
            method: .GET,
            responseType: APIResponse<SeeksResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch seeks")
        }
        
        return data.seeks
    }
    
    func fetchUserSeeks(userId: String) async throws -> [Seek] {
        struct UserSeeksResponse: Codable {
            let seeks: [Seek]
        }
        
        let response = try await performRequest(
            endpoint: "api/seeks?user_id=\(userId)",
            method: .GET,
            responseType: APIResponse<UserSeeksResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch user seeks")
        }
        
        return data.seeks
    }
    
    func createSeek(_ seek: CreateSeekRequest) async throws -> Seek {
        let bodyData = try JSONEncoder().encode(seek)
        
        let response = try await performRequest(
            endpoint: "api/seeks",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<Seek>.self
        )
        
        guard response.success, let seek = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create seek")
        }
        
        return seek
    }
    
    func toggleSeekStatus(id: Int) async throws -> Seek {
        return try await performRequest(
            endpoint: "toggle_seek_status.php?id=\(id)",
            method: .POST,
            responseType: Seek.self
        )
    }
    
    func deleteSeek(id: Int) async throws -> Void {
        _ = try await performRequest(
            endpoint: "delete_seek.php?id=\(id)",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - User Profile
    func fetchUserProfile(userId: String? = nil, username: String? = nil) async throws -> User {
        // Use Node.js endpoint to fetch user profile by ID
        guard let userId = userId else {
            throw BrrowAPIError.validationError("User ID is required")
        }

        let endpoint = "api/users/\(userId)"

        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: User.self
        )
    }
    
    func fetchUserRating(userId: Int) async throws -> UserRating {
        struct UserRatingResponse: Codable {
            let averageRating: Double
            let reviewCount: Int
            let lenderRating: Double?
            let borrowerRating: Double?
            let lenderReviewCount: Int
            let borrowerReviewCount: Int
            let recentReviews: [UserRating]?
        }
        
        let response = try await performRequest(
            endpoint: "api/users/\(userId)/rating",
            method: .GET,
            responseType: APIResponse<UserRatingResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch user rating")
        }
        
        // Return a mock UserRating with the average rating
        return UserRating(
            id: userId,
            rating: data.averageRating,
            review: "",
            reviewerName: "",
            reviewerProfilePicture: nil,
            createdAt: Date()
        )
    }
    
    func fetchProfile() async throws -> User {
        struct ProfileResponse: Codable {
            let success: Bool
            let user: User  // Backend returns 'user', not 'data'
        }

        let response = try await performRequest(
            endpoint: "api/users/me",
            method: .GET,
            responseType: ProfileResponse.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError("Failed to fetch profile")
        }

        return response.user
    }
    
    func updateProfile(name: String, bio: String) async throws -> User {
        let updateRequest = UpdateProfileRequest(name: name, bio: bio)
        let bodyData = try JSONEncoder().encode(updateRequest)

        struct ProfileUpdateAPIResponse: Codable {
            let success: Bool
            let message: String?
            let user: User?
        }

        let response = try await performRequest(
            endpoint: "api/users/me",
            method: .PUT,
            body: bodyData,
            responseType: ProfileUpdateAPIResponse.self
        )

        guard response.success, let user = response.user else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update profile")
        }

        return user
    }
    
    func updateProfile(data: ProfileUpdateData) async throws {
        let bodyData = try JSONEncoder().encode(data)

        struct ProfileUpdateAPIResponse: Codable {
            let success: Bool
            let message: String?
            let user: User?  // Backend returns user directly, not nested in data
        }

        let response = try await performRequest(
            endpoint: "api/users/me",
            method: .PUT,
            body: bodyData,
            responseType: ProfileUpdateAPIResponse.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update profile")
        }

        // Update AuthManager with the new user data if available
        if let updatedUser = response.user {
            await MainActor.run {
                AuthManager.shared.currentUser = updatedUser
                // Force save the updated user to keychain
                if let userData = try? JSONEncoder().encode(updatedUser) {
                    KeychainHelper().save(String(data: userData, encoding: .utf8) ?? "", forKey: "brrow_user_data")
                }
            }
        }
    }
    
    func fetchUserListings(userId: String? = nil, status: String = "active") async throws -> UserListingsResponse {
        let endpoint: String

        if let userId = userId {
            // Fetch listings for a specific user by ID
            endpoint = APIEndpoints.Listings.getUserListings + "?user_id=\(userId)&status=\(status)"
            debugLog("👤 [USER LISTINGS] Fetching listings for specific user", data: ["userId": userId, "status": status])
        } else {
            // Use JWT-based endpoint to fetch authenticated user's own listings
            endpoint = APIEndpoints.Listings.myListings + "?status=\(status)"
            debugLog("👤 [USER LISTINGS] Fetching listings for authenticated user (JWT-based)", data: ["status": status, "endpoint": endpoint])
        }

        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: UserListingsResponse.self
        )
    }
    
    func fetchFavorites(limit: Int = 20, offset: Int = 0) async throws -> FavoritesResponse {
        return try await performRequest(
            endpoint: "api/favorites?limit=\(limit)&offset=\(offset)",
            method: .GET,
            responseType: FavoritesResponse.self
        )
    }

    func fetchUserPosts(limit: Int = 20, offset: Int = 0) async throws -> UserPostsResponse {
        return try await performRequest(
            endpoint: "api/users/posts?limit=\(limit)&offset=\(offset)",
            method: .GET,
            responseType: UserPostsResponse.self
        )
    }
    
    func updateProfileImage(imageUrl: String) async throws -> User {
        struct ProfilePictureUpdate: Codable {
            let profilePictureUrl: String
        }

        struct ProfilePictureResponse: Codable {
            let success: Bool
            let message: String?
            let user: User
        }

        let updateRequest = ProfilePictureUpdate(profilePictureUrl: imageUrl)
        let bodyData = try JSONEncoder().encode(updateRequest)

        let response = try await performRequest(
            endpoint: "api/users/me/profile-picture",
            method: .PUT,
            body: bodyData,
            responseType: ProfilePictureResponse.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update profile picture")
        }

        return response.user
    }
    
    // MARK: - Enhanced Profile Methods
    func updateProfileEnhanced(data: [String: Any]) async throws {
        let bodyData = try JSONSerialization.data(withJSONObject: data)

        let response = try await performRequest(
            endpoint: "api/profile/enhanced",
            method: .PUT,
            body: bodyData,
            responseType: ProfileUpdateResponse.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update profile")
        }
    }
    
    func checkUsernameAvailability(username: String) async throws -> UsernameAvailabilityResponse {
        let requestData = ["username": username]
        let bodyData = try JSONSerialization.data(withJSONObject: requestData)

        return try await performRequest(
            endpoint: "api/profile/check-username",
            method: .POST,
            body: bodyData,
            responseType: UsernameAvailabilityResponse.self
        )
    }
    
    struct ProfileUpdateResponse: Codable {
        let success: Bool
        let message: String
        let user: User?
    }
    
    struct ImageUploadResponse: Codable {
        let success: Bool
        let message: String?
        let url: String?
        let profilePictureUrl: String?
        let data: ImageData?
        let user: User?  // Add user at root level to match server response

        struct ImageData: Codable {
            let url: String?
            let thumbnailUrl: String?
        }
        
        struct UsernameChangeInfo: Codable {
            let canChange: Bool
            let daysUntilAllowed: Int
            let message: String
            let changeCount: Int
            let previousUsername: String?
            let reservedUsernames: [ReservedUsername]
            
            enum CodingKeys: String, CodingKey {
                case canChange = "can_change"
                case daysUntilAllowed = "days_until_allowed"
                case message
                case changeCount = "change_count"
                case previousUsername = "previous_username"
                case reservedUsernames = "reserved_usernames"
            }
        }
        
        struct ReservedUsername: Codable {
            let username: String
            let reservedUntil: String
            
            enum CodingKeys: String, CodingKey {
                case username
                case reservedUntil = "reserved_until"
            }
        }
    }
    
    struct UsernameAvailabilityResponse: Codable {
        let success: Bool
        let available: Bool
        let status: String
        let message: String
    }

    // MARK: - SMS Verification Methods
    func sendPhoneVerification(phoneNumber: String) async throws -> SMSVerificationResponse {
        let requestData = ["phoneNumber": phoneNumber]
        let bodyData = try JSONSerialization.data(withJSONObject: requestData)

        return try await performRequest(
            endpoint: "api/users/send-phone-verification",
            method: .POST,
            body: bodyData,
            responseType: SMSVerificationResponse.self
        )
    }

    func verifyPhone(phoneNumber: String, code: String) async throws -> PhoneVerificationResponse {
        let requestData = [
            "phoneNumber": phoneNumber,
            "code": code
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: requestData)

        return try await performRequest(
            endpoint: "api/users/verify-phone",
            method: .POST,
            body: bodyData,
            responseType: PhoneVerificationResponse.self
        )
    }

    struct SMSVerificationResponse: Codable {
        let success: Bool
        let message: String
        let testMode: Bool?

        enum CodingKeys: String, CodingKey {
            case success, message
            case testMode = "testMode"
        }
    }

    struct PhoneVerificationResponse: Codable {
        let success: Bool
        let message: String
        let user: User
    }

    // Response type for SMS verification that matches SMSVerificationService expectations
    struct SMSVerificationServiceResponse: Codable {
        let success: Bool
        let message: String?
        let error: String?
        let user: User?
        let status: String?
        let testMode: Bool?
    }

    // SMS Verification methods for SMSVerificationService compatibility
    func sendSMSVerificationCode(phoneNumber: String) async throws -> SMSVerificationServiceResponse {
        let requestData = [
            "phoneNumber": phoneNumber
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: requestData)

        return try await performRequest(
            endpoint: "api/verify/send-sms",
            method: .POST,
            body: bodyData,
            responseType: SMSVerificationServiceResponse.self
        )
    }

    func verifySMSCode(code: String, phoneNumber: String) async throws -> SMSVerificationServiceResponse {
        let requestData = [
            "code": code,
            "phoneNumber": phoneNumber
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: requestData)

        return try await performRequest(
            endpoint: "api/verify/verify-sms",
            method: .POST,
            body: bodyData,
            responseType: SMSVerificationServiceResponse.self
        )
    }

    // MARK: - Analytics Methods
    func fetchPostsAnalytics(timeframe: String = "month") async throws -> PostsAnalyticsResponse {
        return try await performRequest(
            endpoint: "api/analytics/posts?timeframe=\(timeframe)",
            method: .GET,
            responseType: PostsAnalyticsResponse.self
        )
    }

    func trackListingView(listingId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)/view",
            method: .POST,
            responseType: BasicResponse.self
        )

        if !response.success {
            throw BrrowAPIError.serverError(response.message ?? "Failed to track view")
        }
    }

    func trackListingInterest(listingId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)/interested",
            method: .POST,
            responseType: BasicResponse.self
        )

        if !response.success {
            throw BrrowAPIError.serverError(response.message ?? "Failed to track interest")
        }
    }

    struct PostsAnalyticsResponse: Codable {
        let success: Bool
        let data: AnalyticsData?

        struct AnalyticsData: Codable {
            let summary: AnalyticsSummary
            let postsOverTime: [String: Int]
            let categoryDistribution: [String: Int]
            let statusBreakdown: [String: Int]
            let timeframe: String
        }

        struct AnalyticsSummary: Codable {
            let totalPosts: Int
            let activePosts: Int
            let totalViews: Int
            let totalInterested: Int
            let averagePrice: Int
            let responseRate: Int
            let averageViews: Int
            let conversionRate: Double
        }
    }

    struct BasicResponse: Codable {
        let success: Bool
        let message: String?
    }

    // MARK: - Username Change
    func changeUsername(_ newUsername: String) async throws -> User {
        struct ChangeUsernameRequest: Codable {
            let newUsername: String
        }

        struct ChangeUsernameResponse: Codable {
            let success: Bool
            let message: String
            let oldUsername: String?
            let newUsername: String?
            let user: User?
            let error: String?
            let daysRemaining: Int?
        }

        let requestBody = ChangeUsernameRequest(newUsername: newUsername)
        let bodyData = try JSONEncoder().encode(requestBody)

        let response = try await performRequest(
            endpoint: "api/users/change-username",
            method: .POST,
            body: bodyData,
            responseType: ChangeUsernameResponse.self
        )

        guard response.success else {
            if let daysRemaining = response.daysRemaining {
                throw BrrowAPIError.serverError("Username can only be changed once every 90 days. \(daysRemaining) days remaining.")
            }
            throw BrrowAPIError.serverError(response.error ?? response.message)
        }

        // Return the updated user object
        guard let updatedUser = response.user else {
            throw BrrowAPIError.serverError("Username updated but user data not returned")
        }

        return updatedUser
    }

    struct UpdateListingResponse: Codable {
        let success: Bool
        let message: String?
        let data: Listing?
    }
    
    struct DeleteResponse: Codable {
        let success: Bool
        let message: String?
    }
    
    struct GarageSaleUpdateResponse: Codable {
        let success: Bool
        let message: String?
        let data: GarageSale?
    }
    
    struct SeekUpdateResponse: Codable {
        let success: Bool
        let message: String?
        let data: Seek?
    }
    
    func updateFullProfile(_ updates: [String: Any]) async throws -> User {
        let bodyData = try JSONSerialization.data(withJSONObject: updates)
        
        return try await performRequest(
            endpoint: "api/users/me",
            method: .PUT,
            body: bodyData,
            responseType: User.self
        )
    }
    
    // MARK: - Password Management

    /// Validate password against backend rules
    func validatePassword(password: String) async throws -> PasswordValidationResponse {
        struct ValidatePasswordRequest: Codable {
            let password: String
        }

        let request = ValidatePasswordRequest(password: password)
        let bodyData = try JSONEncoder().encode(request)

        return try await performRequest(
            endpoint: "api/auth/validate-password",
            method: .POST,
            body: bodyData,
            responseType: PasswordValidationResponse.self
        )
    }

    /// Check if user has a password (OAuth users may not have passwords)
    func checkPasswordExists() async throws -> CheckPasswordExistsResponse {
        return try await performRequest(
            endpoint: "api/auth/check-password-exists",
            method: .GET,
            responseType: CheckPasswordExistsResponse.self
        )
    }

    /// Change password for existing email users
    func changePassword(currentPassword: String, newPassword: String) async throws -> EmptyResponse {
        struct ChangePasswordRequest: Codable {
            let currentPassword: String
            let newPassword: String

            enum CodingKeys: String, CodingKey {
                case currentPassword = "current_password"
                case newPassword = "new_password"
            }
        }

        let request = ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword)
        let bodyData = try JSONEncoder().encode(request)

        return try await performRequest(
            endpoint: "api/auth/change-password",
            method: .PUT,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }

    /// Create password for OAuth users
    func createPassword(newPassword: String) async throws -> EmptyResponse {
        struct CreatePasswordRequest: Codable {
            let newPassword: String

            enum CodingKeys: String, CodingKey {
                case newPassword = "new_password"
            }
        }

        let request = CreatePasswordRequest(newPassword: newPassword)
        let bodyData = try JSONEncoder().encode(request)

        return try await performRequest(
            endpoint: "api/auth/create-password",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    func deleteAccount(password: String) async throws -> Void {
        struct DeleteAccountRequest: Codable {
            let password: String
        }
        
        let request = DeleteAccountRequest(password: password)
        let bodyData = try JSONEncoder().encode(request)
        
        _ = try await performRequest(
            endpoint: "delete_account.php",
            method: .DELETE,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Favorites (New Dedicated Endpoints)

    // Check if a listing is favorited (GET /api/favorites/check/:listingId)
    func checkFavoriteStatus(listingId: String) async throws -> Bool {
        struct CheckFavoriteResponse: Codable {
            let success: Bool
            let isFavorited: Bool
            let favorite: FavoriteDetail?

            struct FavoriteDetail: Codable {
                let id: String
                let favoritedAt: String
            }
        }

        let response = try await performRequest(
            endpoint: "api/favorites/check/\(listingId)",
            method: .GET,
            responseType: CheckFavoriteResponse.self
        )

        return response.isFavorited
    }

    // Add a listing to favorites (POST /api/favorites/:listingId)
    func addFavorite(_ listingId: String) async throws {
        struct AddFavoriteResponse: Codable {
            let success: Bool
            let message: String
            let favorite: FavoriteDetail?
            let newFavoriteCount: Int?

            struct FavoriteDetail: Codable {
                let id: String
                let listingId: String
                let createdAt: String
            }
        }

        let response = try await performRequest(
            endpoint: "api/favorites/\(listingId)",
            method: .POST,
            responseType: AddFavoriteResponse.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message)
        }
    }

    // Remove a listing from favorites (DELETE /api/favorites/:listingId)
    func removeFavorite(_ listingId: String) async throws {
        struct RemoveFavoriteResponse: Codable {
            let success: Bool
            let message: String
            let newFavoriteCount: Int?
        }

        let response = try await performRequest(
            endpoint: "api/favorites/\(listingId)",
            method: .DELETE,
            responseType: RemoveFavoriteResponse.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message)
        }
    }

    // DEPRECATED: Use addFavorite/removeFavorite instead
    // Kept for backward compatibility with old toggle logic
    func toggleFavoriteByListingId(_ listingId: String) async throws -> Bool {
        // Check current status
        let isFavorited = try await checkFavoriteStatus(listingId: listingId)

        if isFavorited {
            // Remove from favorites
            try await removeFavorite(listingId)
            return false
        } else {
            // Add to favorites
            try await addFavorite(listingId)
            return true
        }
    }

    // DEPRECATED: Legacy methods kept for backward compatibility
    func checkFavoriteStatus(listingId: Int, userId: Int) async throws -> Bool {
        return try await checkFavoriteStatus(listingId: String(listingId))
    }

    func toggleFavorite(listingId: Int, userId: Int) async throws -> Bool {
        return try await toggleFavoriteByListingId(String(listingId))
    }

    func toggleFavoriteByListingId(_ listingId: String, userId: Int) async throws -> Bool {
        return try await toggleFavoriteByListingId(listingId)
    }
    
    func fetchSimilarListings(listingId: String, category: String, limit: Int) async throws -> [Listing] {
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)/similar?category=\(encodedCategory)&limit=\(limit)",
            method: .GET,
            responseType: APIResponse<[Listing]>.self
        )
        
        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch similar listings")
        }
        
        return response.data ?? []
    }
    
    // MARK: - Offers
    func fetchOffers(type: String = "all") async throws -> [Offer] {
        let response = try await performRequest(
            endpoint: "api/offers?type=\(type)",
            method: .GET,
            responseType: APIResponse<[Offer]>.self
        )
        
        guard response.success, let offers = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch offers")
        }
        
        return offers
    }
    
    func fetchReceivedOffers() async throws -> [Offer] {
        return try await fetchOffers(type: "received")
    }
    
    func fetchSentOffers() async throws -> [Offer] {
        return try await fetchOffers(type: "sent")
    }
    
    func createOffer(_ offer: CreateOfferRequest) async throws -> Offer {
        let bodyData = try JSONEncoder().encode(offer)

        let response = try await performRequest(
            endpoint: "api/offers",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<Offer>.self
        )
        
        guard response.success, let offer = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create offer")
        }
        
        return offer
    }
    
    func submitOffer(_ offer: Offer) async throws -> Offer {
        let bodyData = try JSONEncoder().encode(offer)

        let response = try await performRequest(
            endpoint: "api/offers",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<Offer>.self
        )

        guard response.success, let offer = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to submit offer")
        }

        return offer
    }
    
    func updateOfferStatus(offerId: Int, status: OfferStatus) async throws -> Offer {
        let request = UpdateOfferStatusRequest(offerId: String(offerId), status: status.rawValue)
        let bodyData = try JSONEncoder().encode(request)

        let response = try await performRequest(
            endpoint: "api/offers/\(offerId)/status",
            method: .PUT,
            body: bodyData,
            responseType: APIResponse<Offer>.self
        )

        guard response.success, let offer = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update offer status")
        }

        return offer
    }
    
    func fetchOfferDetails(id: Int) async throws -> Offer {
        let response = try await performRequest(
            endpoint: "api/offers/\(id)",
            method: .GET,
            responseType: APIResponse<Offer>.self
        )

        guard response.success, let offer = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch offer details")
        }

        return offer
    }

    // Accept an offer (for chat messages)
    func acceptOffer(offerId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/offers/\(offerId)/accept",
            method: .POST,
            responseType: APIResponse<EmptyData>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to accept offer")
        }
    }

    // Reject an offer (for chat messages)
    func rejectOffer(offerId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/offers/\(offerId)/reject",
            method: .POST,
            responseType: APIResponse<EmptyData>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to reject offer")
        }
    }

    // Counter an offer (for chat messages)
    func counterOffer(offerId: String, newAmount: Double, message: String?) async throws {
        struct CounterOfferRequest: Codable {
            let amount: Double
            let message: String?
        }

        let request = CounterOfferRequest(amount: newAmount, message: message)
        let bodyData = try JSONEncoder().encode(request)

        let response = try await performRequest(
            endpoint: "api/offers/\(offerId)/counter",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<EmptyData>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to counter offer")
        }
    }
    
    // MARK: - Transactions
    func fetchTransactions() async throws -> [Transaction] {
        struct TransactionsResponse: Codable {
            let transactions: [Transaction]
            let pagination: PaginationInfo?
        }
        
        let response = try await performRequest(
            endpoint: "fetch_transactions.php",
            method: .GET,
            responseType: APIResponse<TransactionsResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch transactions")
        }
        
        return data.transactions
    }
    
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        let bodyData = try JSONEncoder().encode(transaction)
        
        let response = try await performRequest(
            endpoint: "create_transaction.php",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<Transaction>.self
        )
        
        guard response.success, let transaction = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create transaction")
        }
        
        return transaction
    }
    
    func updateTransactionStatus(transactionId: Int, status: TransactionStatus) async throws -> Transaction {
        let request = UpdateTransactionStatusRequest(transactionId: String(transactionId), status: status.rawValue)
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "update_transaction_status.php",
            method: .POST,
            body: bodyData,
            responseType: Transaction.self
        )
    }
    
    func extendTransaction(transactionId: Int, additionalDays: Int) async throws -> Transaction {
        let request = APIExtendTransactionRequest(transactionId: String(transactionId), additionalDays: additionalDays)
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "extend_transaction.php",
            method: .POST,
            body: bodyData,
            responseType: Transaction.self
        )
    }
    
    func fetchTransactionDetails(id: Int) async throws -> Transaction {
        return try await performRequest(
            endpoint: "fetch_transaction_details.php?id=\(id)",
            method: .GET,
            responseType: Transaction.self
        )
    }
    
    func reportTransactionIssue(transactionId: Int, issue: String, details: String) async throws -> Void {
        let request = ReportTransactionIssueRequest(transactionId: transactionId, issue: issue, details: details)
        let bodyData = try JSONEncoder().encode(request)
        
        _ = try await performRequest(
            endpoint: "report_transaction_issue.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Listing Inquiries
    
    struct ListingInquiryResponse: Codable {
        let conversationId: Int
        let messageId: Int
        
        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case messageId = "message_id"
        }
    }
    
    func sendListingInquiry(listingId: String, message: String, inquiryType: String = "general") async throws -> ListingInquiryResponse {
        let body: [String: Any] = [
            "message": message,
            "inquiryType": inquiryType
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let response = try await performRequest(
            endpoint: "api/listings/\(listingId)/inquiry",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<ListingInquiryResponse>.self
        )

        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to send inquiry")
        }

        return data
    }
    
    // MARK: - Chat (Enhanced Dual Messaging System)

    /// Legacy method for backward compatibility
    func fetchConversations() async throws -> [Conversation] {
        let result = try await fetchConversations(type: nil, limit: 20, offset: 0, search: nil)
        return result.conversations
    }

    /// Enhanced method with dual messaging support
    func fetchConversations(type: String?, limit: Int = 20, offset: Int = 0, search: String?, bypassCache: Bool = false) async throws -> (conversations: [Conversation], hasMore: Bool) {
        var endpoint = "api/messages/chats?limit=\(limit)&offset=\(offset)"

        if let type = type {
            endpoint += "&type=\(type)"
        }

        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)"
        }

        struct PaginatedConversationsResponse: Codable {
            let success: Bool
            let data: [Conversation]
            let pagination: PaginationInfo
        }

        struct PaginationInfo: Codable {
            let total: Int
            let limit: Int
            let offset: Int
            let hasMore: Bool
        }

        do {
            let response = try await performRequest(
                endpoint: endpoint,
                method: .GET,
                responseType: PaginatedConversationsResponse.self,
                cachePolicy: bypassCache ? .ignoreCache : .networkFirst
            )
            return (conversations: response.data, hasMore: response.pagination.hasMore)
        } catch {
            print("❌ Error fetching conversations: \(error)")
            return (conversations: [], hasMore: false)
        }
    }

    /// Fetch unread counts by type
    func fetchUnreadCounts() async throws -> UnreadCounts {
        let response = try await performRequest(
            endpoint: "api/messages/unread-counts",
            method: .GET,
            responseType: APIResponse<UnreadCounts>.self
        )

        guard response.success, let counts = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch unread counts")
        }

        return counts
    }

    /// Create or get listing conversation
    func createListingConversation(listingId: String) async throws -> Conversation {
        let bodyDict = ["listingId": listingId]
        let bodyData = try JSONEncoder().encode(bodyDict)

        let response = try await performRequest(
            endpoint: "api/messages/chats/listing",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<Conversation>.self
        )

        guard response.success, let conversation = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create listing conversation")
        }

        return conversation
    }

    /// Hide chat (soft delete)
    func hideChat(chatId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/messages/chats/\(chatId)/hide",
            method: .DELETE,
            responseType: APIResponse<String>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to hide chat")
        }
    }

    /// Block user
    func blockUser(userId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/messages/\(userId)/block",
            method: .POST,
            responseType: APIResponse<String>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to block user")
        }
    }

    /// Report user
    func reportUser(userId: String, reason: String, details: String) async throws {
        struct ReportUserRequest: Codable {
            let userId: String
            let reason: String
            let details: String
        }

        let request = ReportUserRequest(userId: userId, reason: reason, details: details)
        let bodyData = try JSONEncoder().encode(request)

        let response = try await performRequest(
            endpoint: "api/reports/user",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<String>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to report user")
        }
    }

    /// Clear chat history
    func clearChatHistory(conversationId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/messages/\(conversationId)/clear",
            method: .POST,
            responseType: APIResponse<String>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to clear chat history")
        }
    }

    /// Delete conversation (overload for String ID)
    func deleteConversation(conversationId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/conversations/\(conversationId)",
            method: .DELETE,
            responseType: APIResponse<String>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to delete conversation")
        }
    }

    /// Unblock user
    func unblockUser(userId: String) async throws {
        let response = try await performRequest(
            endpoint: "api/messages/\(userId)/block",
            method: .DELETE,
            responseType: APIResponse<String>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to unblock user")
        }
    }
    
    func fetchMessages(conversationId: String, limit: Int = 50, before: String? = nil) async throws -> [Message] {
        var endpoint = "api/messages/chats/\(conversationId)/messages?limit=\(limit)"
        if let before = before {
            endpoint += "&before=\(before)"
        }

        let response = try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: APIResponse<[Message]>.self
        )

        guard response.success, let messages = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to fetch messages")
        }

        return messages
    }
    
    func sendMessage(conversationId: String, content: String, messageType: MessageType = .text, mediaUrl: String? = nil, thumbnailUrl: String? = nil, listingId: String? = nil) async throws -> Message {
        let bodyDict = [
            "content": content,
            "messageType": messageType.rawValue.uppercased(),
            "mediaUrl": mediaUrl,
            "thumbnailUrl": thumbnailUrl,
            "listingId": listingId
        ].compactMapValues { $0 }

        let bodyData = try JSONEncoder().encode(bodyDict)

        let response = try await performRequest(
            endpoint: "api/messages/chats/\(conversationId)/messages",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<Message>.self
        )

        guard response.success, let message = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to send message")
        }

        return message
    }
    
    func sendListingInquiry(_ request: SendListingInquiryRequest) async throws -> ListingInquiryResponse {
        let bodyData = try JSONEncoder().encode(request)

        let response = try await performRequest(
            endpoint: "api/conversations/inquiry",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<ListingInquiryResponse>.self
        )

        guard response.success, let data = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to send inquiry")
        }

        return data
    }
    
    func createConversation(otherUserId: String, listingId: String? = nil) async throws -> Conversation {
        // Use NEW dual messaging endpoint
        let endpoint = listingId != nil ? "api/messages/chats/listing" : "api/messages/chats/direct"

        // CRITICAL FIX: Backend expects "recipientId" not "otherUserId" for direct chats
        let bodyDict: [String: Any] = listingId != nil
            ? ["listingId": listingId!]
            : ["recipientId": otherUserId]

        let body = try JSONSerialization.data(withJSONObject: bodyDict)

        let response = try await performRequest(
            endpoint: endpoint,
            method: .POST,
            body: body,
            responseType: APIResponse<Conversation>.self
        )

        guard response.success, let conversation = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create conversation")
        }

        return conversation
    }
    
    func deleteConversation(id: Int) async throws -> Void {
        _ = try await performRequest(
            endpoint: "api/conversations/\(id)",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
    }

    /// Fetch a single conversation by ID
    /// Note: Backend doesn't have a dedicated endpoint, so we fetch all and filter
    func fetchConversationById(_ conversationId: String) async throws -> Conversation {
        let result = try await fetchConversations(type: nil, limit: 100, offset: 0, search: nil)

        guard let conversation = result.conversations.first(where: { $0.id == conversationId }) else {
            throw BrrowAPIError.serverError("Conversation not found")
        }

        return conversation
    }

    /// Mark conversation as read by fetching messages (backend automatically marks as read)
    func markConversationAsRead(conversationId: String) async throws {
        // Backend marks messages as read when fetching messages
        // We just need to make a fetch call with limit 0 to trigger the mark-as-read logic
        _ = try await fetchMessages(conversationId: conversationId, limit: 1)
    }

    // MARK: - Convenience Methods
    func post(endpoint: String, parameters: [String: Any]) -> AnyPublisher<Data, BrrowAPIError> {
        return Future { promise in
            Task {
                do {
                    let bodyData = try JSONSerialization.data(withJSONObject: parameters)
                    let _: EmptyResponse = try await self.performRequest(
                        endpoint: endpoint,
                        method: .POST,
                        body: bodyData,
                        responseType: EmptyResponse.self
                    )
                    // For this case, we need to return the raw data, so we'll need to modify this
                    // But for now, let's return empty data since the PaymentService expects Data
                    promise(.success(Data()))
                } catch {
                    if let brrowError = error as? BrrowAPIError {
                        promise(.failure(BrrowAPIError.networkError(brrowError.localizedDescription)))
                    } else {
                        promise(.failure(BrrowAPIError.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Generic Request
    func request<T: Codable>(
        _ endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        responseType: T.Type = T.self
    ) async throws -> T {
        var bodyData: Data? = nil
        
        if let parameters = parameters {
            bodyData = try JSONSerialization.data(withJSONObject: parameters)
        }
        
        return try await performRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            responseType: responseType
        )
    }
    
    // MARK: - User Account Management
    func changeUsername(newUsername: String) async throws -> APIResponse<User> {
        struct UsernameChangeRequest: Codable {
            let newUsername: String
        }

        let request = UsernameChangeRequest(newUsername: newUsername)
        let bodyData = try JSONEncoder().encode(request)

        return try await performRequest(
            endpoint: "api/users/change-username",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<User>.self
        )
    }

    // MARK: - User Stats
    func getUserStats() async throws -> APIUserStats {
        return try await request(
            "user/stats.php",
            method: .GET,
            responseType: APIUserStats.self
        )
    }
    
    // MARK: - Marketplace Stats
    func fetchMarketplaceStats(location: CLLocation? = nil, radius: Int = 10) async throws -> MarketplaceStats {
        var endpoint = "get_marketplace_stats.php?"
        var params: [String] = []
        
        if let location = location {
            params.append("lat=\(location.coordinate.latitude)")
            params.append("lng=\(location.coordinate.longitude)")
        }
        params.append("radius=\(radius)")
        
        endpoint += params.joined(separator: "&")
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: MarketplaceStats.self
        )
    }
    
    // MARK: - Analytics
    func trackAnalytics(event: AnalyticsEvent) async throws -> Void {
        struct AnalyticsResponse: Codable {
            let status: String
            let message: String
            let data: AnalyticsData?
            
            struct AnalyticsData: Codable {
                let tracked: Bool
                let event: String
                let timestamp: String
            }
        }
        
        _ = try JSONEncoder().encode(event)
        
        // Analytics endpoint not yet implemented in Node.js backend
        // Silently skip for now to avoid errors
        debugLog("📊 Analytics event (skipped - not implemented)", data: [
            "event": event.eventName,
            "type": event.eventType
        ])
        return
    }
    
    // MARK: - Combine-based Analytics (for legacy support)
    func trackAnalytics(event: AnalyticsEvent) -> AnyPublisher<Void, BrrowAPIError> {
        return Future { promise in
            Task {
                do {
                    try await self.trackAnalytics(event: event)
                    promise(.success(()))
                } catch {
                    if let brrowError = error as? BrrowAPIError {
                        promise(.failure(BrrowAPIError.networkError(brrowError.localizedDescription)))
                    } else {
                        promise(.failure(BrrowAPIError.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Reporting
    func reportListing(listingId: Int, reason: String, details: String) async throws -> Void {
        let request = ReportListingRequest(listingId: listingId, reason: reason, details: details)
        let bodyData = try JSONEncoder().encode(request)
        
        _ = try await performRequest(
            endpoint: "report_listing.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Discover Features
    func fetchTrendingListings() async throws -> [Listing] {
        return try await performRequest(
            endpoint: "fetch_trending_listings.php",
            method: .GET,
            responseType: [Listing].self
        )
    }
    
    func fetchBrrowStories() async throws -> [BrrowStory] {
        struct StoriesResponse: Codable {
            let stories: [BrrowStory]
            let pagination: PaginationInfo?
        }
        
        let response = try await performRequest(
            endpoint: "fetch_stories.php",
            method: .GET,
            responseType: StoriesResponse.self
        )
        return response.stories
    }
    
    func fetchActiveChallenges() async throws -> [CommunityChallenge] {
        struct ChallengesResponse: Codable {
            let challenges: [CommunityChallenge]
            let pagination: PaginationInfo?
        }
        
        let response = try await performRequest(
            endpoint: "fetch_challenges.php",
            method: .GET,
            responseType: ChallengesResponse.self
        )
        return response.challenges
    }
    
    // Karma functionality removed per user request
    
    func fetchUnreadNotificationsCount() async throws -> Int {
        let response = try await performRequest(
            endpoint: "fetch_notifications_count.php",
            method: .GET,
            responseType: NotificationCountResponse.self
        )
        return response.unreadCount
    }
    
    // Karma granting removed per user request
    
    // MARK: - User Stats and Home Data
    func fetchUserStats() async throws -> APIUserStats {
        return try await performRequest(
            endpoint: "api/users/stats",
            method: .GET,
            responseType: APIUserStats.self
        )
    }
    
    func fetchNearbyListings(radius: Int = 5) async throws -> [Listing] {
        // Get current location if available
        let endpoint = "get_nearby_listings.php?radius=\(radius)"
        
        // In a real app, you would get the actual location from LocationManager
        // For now, we'll just use the endpoint without location
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: [Listing].self
        )
    }
    
    func fetchNotifications(limit: Int = 20, unreadOnly: Bool = false) async throws -> [APIUserNotification] {
        var endpoint = "api/notifications?limit=\(limit)"
        if unreadOnly {
            endpoint += "&unread_only=true"
        }

        let response = try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: NotificationsResponse.self
        )

        return response.notifications
    }
    
    func fetchUserActivities(userId: Int, limit: Int = 20) async throws -> [APIUserActivity] {
        let endpoint = "get_user_activities.php?user_id=\(userId)&limit=\(limit)"
        
        let response = try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: UserActivitiesResponse.self
        )
        
        return response.activities
    }
    
    func toggleSavedListing(listingId: Int) async throws -> Void {
        _ = try await performRequest(
            endpoint: "toggle_saved_listing.php?listing_id=\(listingId)",
            method: .POST,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - AI Features
    func fetchAISuggestions(query: String) async throws -> [String] {
        let response = try await performRequest(
            endpoint: "ai_suggestions.php?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            method: .GET,
            responseType: SuggestionsResponse.self
        )
        return response.suggestions
    }
    
    // MARK: - Borrow vs Buy Calculator
    func borrowVsBuyCalculation(
        listingId: Int,
        category: String,
        purchasePrice: Double,
        rentalPriceDaily: Double,
        usageDays: Int,
        usageFrequency: String,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        Task {
            do {
                let parameters: [String: Any] = [
                    "listing_id": listingId,
                    "category": category,
                    "purchase_price": purchasePrice,
                    "rental_price_daily": rentalPriceDaily,
                    "usage_days": usageDays,
                    "usage_frequency": usageFrequency
                ]
                
                let bodyData = try JSONSerialization.data(withJSONObject: parameters)
                
                // Custom response handling for complex JSON
                let baseURL = await self.baseURL
                var request = URLRequest(url: URL(string: "\(baseURL)/borrow_vs_buy.php")!)
                request.httpMethod = "POST"
                request.httpBody = bodyData
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Add authentication header
                if let user = AuthManager.shared.currentUser {
                    request.setValue(user.apiId, forHTTPHeaderField: "X-User-API-ID")
                }
                
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw BrrowAPIError.networkError("Invalid response")
                }
                
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success,
                   let calculation = json?["calculation"] as? [String: Any] {
                    var result: [String: Any] = ["calculation": calculation]
                    
                    if let insights = json?["insights"] {
                        result["insights"] = insights
                    }
                    if let similarItems = json?["similar_items"] {
                        result["similar_items"] = similarItems
                    }
                    if let userStats = json?["user_stats"] {
                        result["user_stats"] = userStats
                    }
                    
                    completion(.success(result))
                } else {
                    let error = json?["error"] as? String ?? "Unknown error"
                    completion(.failure(BrrowAPIError.serverError(error)))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Business Accounts
    func createBusinessAccount(_ request: CreateBusinessAccountRequest) async throws -> BusinessAccount {
        let bodyData = try JSONEncoder().encode(request)
        
        let response = try await performRequest(
            endpoint: "create_business_account.php",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<BusinessAccount>.self
        )
        
        guard response.success, let account = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to create business account")
        }
        
        return account
    }
    
    func getBusinessAccount() async throws -> BusinessAccountResponse {
        return try await performRequest(
            endpoint: "business_account.php",
            method: .GET,
            responseType: BusinessAccountResponse.self
        )
    }
    
    func submitBusinessVerification(verificationData: [String: Any]) async throws {
        let bodyData = try JSONSerialization.data(withJSONObject: [
            "action": "request_verification",
            "legal_name": verificationData["legal_name"],
            "tax_id": verificationData["tax_id"],
            "duns_number": verificationData["duns_number"],
            "id_document": verificationData["id_document"],
            "business_documents": verificationData["business_documents"]
        ])
        
        _ = try await performRequest(
            endpoint: "business_account.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Subscriptions
    struct CurrentSubscription: Codable {
        let id: String
        let planType: String
        let status: String
        let currentPeriodEnd: String?

        enum CodingKeys: String, CodingKey {
            case id
            case planType = "plan_type"
            case status
            case currentPeriodEnd = "current_period_end"
        }
    }

    struct SubscriptionResponse: Codable {
        let currentSubscription: CurrentSubscription?

        enum CodingKeys: String, CodingKey {
            case currentSubscription = "current_subscription"
        }
    }
    
    func getCurrentSubscription() async throws -> CurrentSubscription? {
        let response = try await performRequest(
            endpoint: "subscriptions.php",
            method: .GET,
            responseType: SubscriptionResponse.self
        )
        
        return response.currentSubscription
    }
    
    func createSubscription(planType: String, paymentMethodId: String) async throws {
        let bodyData = try JSONSerialization.data(withJSONObject: [
            "action": "subscribe",
            "plan_type": planType,
            "payment_method_id": paymentMethodId
        ])
        
        _ = try await performRequest(
            endpoint: "subscriptions.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    func updateSubscription(newPlanType: String) async throws {
        let bodyData = try JSONSerialization.data(withJSONObject: [
            "action": "update",
            "new_plan_type": newPlanType
        ])
        
        _ = try await performRequest(
            endpoint: "subscriptions.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    func cancelSubscription(immediately: Bool) async throws {
        let bodyData = try JSONSerialization.data(withJSONObject: [
            "action": "cancel",
            "immediately": immediately
        ])
        
        _ = try await performRequest(
            endpoint: "subscriptions.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Fleet Management
    func getFleetDashboard() async throws -> FleetDashboardResponse {
        return try await performRequest(
            endpoint: "fleet_management.php?resource=dashboard",
            method: .GET,
            responseType: FleetDashboardResponse.self
        )
    }
    
    func getFleetInventory(filters: [String: String]? = nil) async throws -> [FleetInventoryItem] {
        var endpoint = "fleet_management.php?resource=inventory"
        if let filters = filters {
            for (key, value) in filters {
                endpoint += "&\(key)=\(value)"
            }
        }
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: [FleetInventoryItem].self
        )
    }
    
    func addFleetInventoryItem(itemData: [String: Any]) async throws -> FleetInventoryItem {
        let bodyData = try JSONSerialization.data(withJSONObject: [
            "action": "add_inventory",
            "item": itemData
        ])
        
        return try await performRequest(
            endpoint: "fleet_management.php",
            method: .POST,
            body: bodyData,
            responseType: FleetInventoryItem.self
        )
    }
    
    func updateFleetAvailability(itemId: Int, dates: [String], quantity: Int?, priceOverride: Double?) async throws {
        let bodyData = try JSONSerialization.data(withJSONObject: [
            "action": "update_availability",
            "item_id": itemId,
            "dates": dates,
            "quantity": quantity as Any,
            "price_override": priceOverride as Any
        ])
        
        _ = try await performRequest(
            endpoint: "fleet_management.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    func getFleetAnalytics(timeframe: String = "30d") async throws -> FleetAnalyticsResponse {
        return try await performRequest(
            endpoint: "fleet_management.php?resource=analytics&timeframe=\(timeframe)",
            method: .GET,
            responseType: FleetAnalyticsResponse.self
        )
    }
    
    // MARK: - App Settings
    struct AppSetting: Codable {
        let key: String
        let value: String
        let type: String
    }
    
    func getAppSettings(keys: [String]? = nil, includeCache: Bool = true) async throws -> [AppSetting] {
        var endpoint = "app_settings.php?include_cache=\(includeCache)"
        if let keys = keys {
            endpoint += "&keys=\(keys.joined(separator: ","))"
        }
        
        return try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: [AppSetting].self
        )
    }
    
    func fetchPersonalizedRecommendations() async throws -> [Listing] {
        return try await performRequest(
            endpoint: "ai_recommendations.php",
            method: .GET,
            responseType: [Listing].self
        )
    }
    
    func fetchSeekSuggestions(description: String) async throws -> [String] {
        let response = try await performRequest(
            endpoint: "ai_seek_suggestions.php?description=\(description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            method: .GET,
            responseType: SuggestionsResponse.self
        )
        return response.suggestions
    }
    
    // MARK: - Search
    
    // Advanced search with filters, sorting, and location
    func performAdvancedSearch(parameters: SearchParameters) async throws -> SearchResponse {
        var components = URLComponents(string: "api/search/listings")!
        components.queryItems = parameters.queryItems
        
        let endpoint = components.url?.relativePath ?? "api/search/listings"
        let query = components.query ?? ""
        let fullEndpoint = query.isEmpty ? endpoint : "\(endpoint)?\(query)"
        
        return try await performRequest(
            endpoint: fullEndpoint,
            method: .GET,
            responseType: SearchResponse.self
        )
    }
    
    // Simple search (backward compatible)
    func searchListings(query: String, category: String) async throws -> [Listing] {
        let params = SearchParameters(
            query: query.isEmpty ? nil : query,
            category: category == "All" || category.isEmpty ? nil : category
        )
        
        let response = try await performAdvancedSearch(parameters: params)
        return response.data?.results.map { $0.listing } ?? []
    }
    
    // Search with all filters
    func searchWithFilters(
        query: String? = nil,
        category: String? = nil,
        priceRange: (min: Double, max: Double)? = nil,
        condition: String? = nil,
        location: (lat: Double, lng: Double, radius: Double)? = nil,
        sortBy: SearchSortOption = .relevance,
        page: Int = 1
    ) async throws -> SearchResponse {
        let params = SearchParameters(
            query: query,
            category: category,
            minPrice: priceRange?.min,
            maxPrice: priceRange?.max,
            condition: condition,
            location: location,
            sortBy: sortBy,
            page: page
        )
        
        return try await performAdvancedSearch(parameters: params)
    }
    
    // Autocomplete for search
    func fetchAutocomplete(query: String) async throws -> [String] {
        guard !query.isEmpty else { return [] }
        
        let endpoint = "api/search/autocomplete?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        let response = try await performRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: AutocompleteResponse.self
        )
        return response.data
    }
    
    func fetchSearchSuggestions() async throws -> [String] {
        let response = try await performRequest(
            endpoint: "api/search/suggestions",
            method: .GET,
            responseType: SuggestionsResponse.self
        )
        return response.suggestions
    }
    
    // MARK: - Location Services
    func geocodeAddress(_ address: String) async throws -> Location {
        let response = try await performRequest(
            endpoint: "geocode.php?address=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            method: .GET,
            responseType: Location.self
        )
        return response
    }
    
    // MARK: - Image Upload
    func uploadImage(imageData: Data) async throws -> APIImageUploadResponse {
        // For image upload, we need a multipart form data request
        // This is a simplified version - in production, use proper multipart encoding
        return try await performRequest(
            endpoint: "api/upload",
            method: .POST,
            body: imageData,
            responseType: APIImageUploadResponse.self
        )
    }
    
    // MARK: - Earnings
    func fetchEarningsOverview() async throws -> EarningsOverview {
        let response: FixedEarningsOverviewResponse = try await performRequest(
            endpoint: "api/earnings/overview",
            method: .GET,
            responseType: FixedEarningsOverviewResponse.self
        )
        
        // Convert to EarningsOverview format expected by the app
        return EarningsOverview(
            totalEarnings: response.data.overview.lifetimeEarnings ?? 0,
            pendingEarnings: response.data.overview.pendingEarnings ?? 0,
            availableBalance: response.data.payoutInfo.availableBalance ?? 0,
            lastPayout: nil,
            monthlyEarnings: 0, // Not provided in API response
            earningsChange: 0, // Not provided in API response
            itemsRented: response.data.overview.totalRentals ?? 0,
            avgDailyEarnings: response.data.overview.averageRentalValue ?? 0,
            pendingPayments: Int(response.data.overview.pendingEarnings ?? 0)
        )
    }
    
    func fetchRecentEarningsTransactions() async throws -> [EarningsTransaction] {
        struct TransactionsResponse: Codable {
            let success: Bool
            let data: TransactionsData
        }
        
        struct TransactionsData: Codable {
            let transactions: [EarningsTransaction]
            let pagination: PaginationInfo?
        }
        
        let response = try await performRequest(
            endpoint: "api/earnings/transactions",
            method: .GET,
            responseType: TransactionsResponse.self
        )
        
        return response.data.transactions
    }
    
    func fetchRecentPayouts() async throws -> [EarningsPayout] {
        struct PayoutsResponse: Codable {
            let success: Bool
            let data: PayoutsData
        }
        
        struct PayoutsData: Codable {
            let payouts: [EarningsPayout]
            let pagination: PaginationInfo?
        }
        
        let response = try await performRequest(
            endpoint: "api/earnings/payouts",
            method: .GET,
            responseType: PayoutsResponse.self
        )
        
        return response.data.payouts
    }
    
    func fetchEarningsChartData() async throws -> [EarningsDataPoint] {
        struct ChartResponse: Codable {
            let success: Bool
            let message: String?
            let data: ChartData
            let timestamp: String?
        }
        
        struct ChartData: Codable {
            let chart: Chart
            let summary: ChartSummary?
            let period_info: PeriodInfo?
        }
        
        struct Chart: Codable {
            let labels: [String]
            let datasets: [Dataset]
        }
        
        struct Dataset: Codable {
            let label: String
            let data: [Double]
            let color: String?
        }
        
        struct ChartSummary: Codable {
            let total_earnings: Double?
            let total_spending: Double?
            let net_earnings: Double?
            let platform_fees: Double?
            let total_rentals: Int?
            let average_per_rental: Double?
        }
        
        struct PeriodInfo: Codable {
            let start_date: String?
            let end_date: String?
            let days: Int?
        }
        
        do {
            let response = try await performRequest(
                endpoint: "api/earnings/chart",
                method: .GET,
                responseType: ChartResponse.self
            )
            
            // Extract labels and data from the first dataset
            guard let firstDataset = response.data.chart.datasets.first else {
                return []
            }
            
            let labels = response.data.chart.labels
            let amounts = firstDataset.data
            
            // Convert to EarningsDataPoint array
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var dataPoints: [EarningsDataPoint] = []
            for (index, label) in labels.enumerated() {
                if index < amounts.count {
                    // EarningsDataPoint now expects a String for the date field
                    dataPoints.append(EarningsDataPoint(date: label, amount: amounts[index]))
                }
            }
            
            return dataPoints
        } catch {
            // Return empty array if fetch fails
            return []
        }
    }
    
    func requestPayout(_ request: PayoutRequest) async throws {
        let bodyData = try JSONEncoder().encode(request)
        
        _ = try await performRequest(
            endpoint: "request_payout.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - User Profile Methods
    
    func fetchSocialUserListings(userId: Int) async throws -> [Listing] {
        struct ListingsResponse: Codable {
            let listings: [Listing]
        }
        
        let response = try await performRequest(
            endpoint: APIEndpoints.Listings.getUserListings + "?user_id=\(userId)",
            method: .GET,
            responseType: ListingsResponse.self
        )
        
        return response.listings
    }
    
    func fetchSocialUserReviews(userId: Int) async throws -> [SocialUserReview] {
        struct SocialReviewResponse: Codable {
            let reviews: [SocialUserReview]
        }
        
        let response = try await performRequest(
            endpoint: "api/users/\(userId)/reviews",
            method: .GET,
            responseType: SocialReviewResponse.self
        )
        
        return response.reviews
    }
    
    func fetchUserEarnings(userId: Int) async throws -> [MonthlyEarning] {
        struct SocialEarningsResponse: Codable {
            let earnings: [SocialMonthlyEarning]
        }
        
        struct SocialMonthlyEarning: Codable {
            let month: String
            let amount: Double
        }
        
        let response = try await performRequest(
            endpoint: "api/users/\(userId)/earnings",
            method: .GET,
            responseType: SocialEarningsResponse.self
        )
        
        return response.earnings.map { earning in
            MonthlyEarning(
                month: earning.month,
                amount: earning.amount
            )
        }
    }
    
    // MARK: - Categories
    func fetchCategories() async throws -> [APICategory] {
        let response = try await performRequest(
            endpoint: "api/categories",
            method: .GET,
            responseType: CategoriesResponse.self
        )
        return response.categories
    }
    
    // MARK: - Debug/Test Methods
    func testAuthentication() async throws -> Bool {
        struct AuthTestResponse: Codable {
            let success: Bool
            let timestamp: String
            let headersReceived: [String: String]
            let tokenInfo: TokenInfo
            
            struct TokenInfo: Codable {
                let valid: Bool
                let error: String?
                let userId: Int?
                let apiId: String?
                let exp: String?
                
                enum CodingKeys: String, CodingKey {
                    case valid, error
                    case userId = "user_id"
                    case apiId = "api_id"
                    case exp
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case success, timestamp
                case headersReceived = "headers_received"
                case tokenInfo = "token_info"
            }
        }
        
        let response = try await performRequest(
            endpoint: "test_auth.php",
            method: .GET,
            responseType: AuthTestResponse.self,
            cachePolicy: .ignoreCache
        )
        
        debugLog("Auth test result", data: [
            "success": response.success,
            "headers": response.headersReceived,
            "tokenValid": response.tokenInfo.valid,
            "error": response.tokenInfo.error ?? "none"
        ])
        
        return response.success
    }
    
    // MARK: - Achievement Methods (Legacy)
    func getUserAchievementsLegacy() async throws -> UserAchievementsResponse {
        return try await performRequest(
            endpoint: "api/users/me/achievements",
            method: .GET,
            responseType: UserAchievementsResponse.self
        )
    }
    
    // MARK: - Stripe Types
    struct SetCreatorReferralResponse: Codable {
        let success: Bool
        let message: String?
    }

    struct StripeSubscription: Codable {
        let id: String?
        let status: String?
        let planType: String?
        let currentPeriodEnd: String?

        enum CodingKeys: String, CodingKey {
            case id
            case status
            case planType = "plan_type"
            case currentPeriodEnd = "current_period_end"
        }
    }

    struct StripeCheckoutSession: Codable {
        let url: String
        let sessionId: String?

        enum CodingKeys: String, CodingKey {
            case url
            case sessionId = "session_id"
        }
    }

    struct StripeCustomerPortal: Codable {
        let url: String
    }

    // MARK: - Stripe Subscription Methods
    func getStripeSubscription() async throws -> StripeSubscription {
        return try await performRequest(
            endpoint: "stripe_subscription.php",
            method: .GET,
            responseType: StripeSubscription.self
        )
    }
    
    func createStripeCheckoutSession(priceId: String?, successUrl: String, cancelUrl: String, metadata: [String: String]? = nil, customAmount: Int? = nil, customDescription: String? = nil) async throws -> StripeCheckoutSession {
        let request = CreateCheckoutSessionRequest(
            priceId: priceId,
            successUrl: successUrl,
            cancelUrl: cancelUrl,
            metadata: metadata,
            customAmount: customAmount,
            customDescription: customDescription
        )
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "stripe_create_checkout.php",
            method: .POST,
            body: bodyData,
            responseType: StripeCheckoutSession.self
        )
    }
    
    func getStripeCustomerPortal() async throws -> StripeCustomerPortal {
        return try await performRequest(
            endpoint: "stripe_customer_portal.php",
            method: .POST,
            responseType: StripeCustomerPortal.self
        )
    }
    
    func cancelStripeSubscription() async throws {
        _ = try await performRequest(
            endpoint: "stripe_cancel_subscription.php",
            method: .POST,
            responseType: EmptyResponse.self
        )
    }
    
    func handleStripeWebhook(payload: Data, signature: String) async throws {
        let baseURL = await self.baseURL
        var request = URLRequest(url: URL(string: "\(baseURL)/stripe_webhook.php")!)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.setValue(signature, forHTTPHeaderField: "Stripe-Signature")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BrrowAPIError.invalidResponse
        }
    }
    
    // MARK: - ID.me Verification Methods
    func updateUserVerificationStatus(
        isVerified: Bool,
        verificationLevel: String?,
        verificationProvider: String
    ) async throws -> User {
        let request = UpdateVerificationStatusRequest(
            isVerified: isVerified,
            verificationLevel: verificationLevel,
            verificationProvider: verificationProvider
        )
        let bodyData = try JSONEncoder().encode(request)
        
        return try await performRequest(
            endpoint: "update_verification_status.php",
            method: .POST,
            body: bodyData,
            responseType: User.self
        )
    }
    
    func getUserVerificationStatus() async throws -> UserVerificationResponse {
        return try await performRequest(
            endpoint: "get_verification_status.php",
            method: .GET,
            responseType: UserVerificationResponse.self
        )
    }
    
    // MARK: - Email Verification Methods
    func sendEmailVerification() async throws -> EmailVerificationResponse {
        return try await performRequest(
            endpoint: "api/auth/resend-verification",
            method: .POST,
            responseType: EmailVerificationResponse.self
        )
    }
    
    // MARK: - Language Settings Methods
    func updateLanguagePreference(languageCode: String) async throws -> EmptyResponse {
        let body = ["language_code": languageCode]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        return try await performRequest(
            endpoint: APIEndpoints.Profile.updateLanguage,
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - System Notifications Methods
    func getSystemNotifications() async throws -> APIResponse<[SystemNotification]> {
        return try await performRequest(
            endpoint: "get_system_notifications.php",
            method: .GET,
            responseType: APIResponse<[SystemNotification]>.self
        )
    }
    
    func markNotificationAsRead(notificationId: String) async throws -> APIResponse<EmptyResponse> {
        let body = ["notification_id": notificationId]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        return try await performRequest(
            endpoint: "api/notifications/\(notificationId)/read",
            method: .POST,
            body: bodyData,
            responseType: APIResponse<EmptyResponse>.self
        )
    }

    func markAllNotificationsAsRead() async throws -> APIResponse<EmptyResponse> {
        return try await performRequest(
            endpoint: "api/notifications/read-all",
            method: .POST,
            responseType: APIResponse<EmptyResponse>.self
        )
    }
    
    func clearAllNotifications() async throws -> APIResponse<EmptyResponse> {
        return try await performRequest(
            endpoint: "clear_all_notifications.php",
            method: .POST,
            responseType: APIResponse<EmptyResponse>.self
        )
    }
    
    // MARK: - Achievements
    struct AchievementTrackResponse: Codable {
        let success: Bool
        let data: AchievementUnlockResult
    }
    
    func getUserAchievements() async throws -> AchievementsResponse {
        // ACHIEVEMENTS DISABLED FOR LAUNCH
        // TODO: Enable later by uncommenting API call below
        return AchievementsResponse(
            success: true,
            data: AchievementsResponse.AchievementsData(
                userLevel: nil,
                progressToNext: nil,
                nextLevelRequirement: nil,
                statistics: nil,
                achievements: [],
                recentUnlocked: nil
            )
        )

        /* DISABLED FOR LAUNCH - RE-ENABLE LATER:
        return try await performRequest(
            endpoint: "api_achievements_get_user.php",
            method: .GET,
            responseType: AchievementsResponse.self
        )
        */
    }
    
    func trackAchievementProgress(action: String, value: Int, metadata: [String: Any]?) async throws -> AchievementTrackResponse {
        // ACHIEVEMENTS DISABLED FOR LAUNCH
        // TODO: Enable later by uncommenting API call below
        return AchievementTrackResponse(
            success: true,
            data: AchievementUnlockResult(
                action: action,
                value: value,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                achievementsUnlocked: nil,
                progressUpdated: false,
                level: nil
            )
        )

        /* DISABLED FOR LAUNCH - RE-ENABLE LATER:
        var body: [String: Any] = [
            "action": action,
            "value": value
        ]
        
        if let metadata = metadata {
            body["metadata"] = metadata
        }

        if let metadata = metadata {
            body["metadata"] = metadata
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        return try await performRequest(
            endpoint: "api_achievements_track_progress.php",
            method: .POST,
            body: bodyData,
            responseType: AchievementTrackResponse.self
        )
        */
    }
    
    // MARK: - Async versions of performRequest for string method parameter
    func performRequest<T: Decodable>(
        endpoint: String,
        method: String,
        authenticated: Bool = true,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequestNoCaching(
            endpoint: endpoint,
            method: HTTPMethod(rawValue: method) ?? .GET,
            responseType: responseType
        )
    }
    
    func performRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data?,
        authenticated: Bool = true,
        responseType: T.Type
    ) async throws -> T {
        return try await performRequestNoCaching(
            endpoint: endpoint,
            method: HTTPMethod(rawValue: method) ?? .POST,
            body: body,
            responseType: responseType
        )
    }
    
    // MARK: - Achievements (Combine Support for legacy compatibility)
    func performRequestCombine<T: Decodable>(
        endpoint: String,
        method: String,
        authenticated: Bool = true,
        responseType: T.Type
    ) -> AnyPublisher<T, BrrowAPIError> {
        return Future { promise in
            Task {
                do {
                    let result: T = try await self.performRequestNoCaching(
                        endpoint: endpoint,
                        method: HTTPMethod(rawValue: method) ?? .GET,
                        responseType: responseType
                    )
                    promise(.success(result))
                } catch {
                    if let brrowError = error as? BrrowAPIError {
                        promise(.failure(BrrowAPIError.networkError(brrowError.localizedDescription)))
                    } else {
                        promise(.failure(BrrowAPIError.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func performRequestCombine<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data?,
        authenticated: Bool = true,
        responseType: T.Type
    ) -> AnyPublisher<T, BrrowAPIError> {
        return Future { promise in
            Task {
                do {
                    let result: T = try await self.performRequestNoCaching(
                        endpoint: endpoint,
                        method: HTTPMethod(rawValue: method) ?? .POST,
                        body: body,
                        responseType: responseType
                    )
                    promise(.success(result))
                } catch {
                    if let brrowError = error as? BrrowAPIError {
                        promise(.failure(BrrowAPIError.networkError(brrowError.localizedDescription)))
                    } else {
                        promise(.failure(BrrowAPIError.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Push Notifications
    func registerDeviceToken(parameters: [String: Any]) async throws -> EmptyResponse {
        let bodyData = try JSONSerialization.data(withJSONObject: parameters)
        return try await performRequest(
            endpoint: "api/users/me/fcm-token",
            method: .PUT,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    func unregisterDeviceToken(deviceToken: String) async throws -> EmptyResponse {
        let parameters = ["device_token": deviceToken]
        let bodyData = try JSONSerialization.data(withJSONObject: parameters)
        return try await performRequest(
            endpoint: "api/users/me/fcm-token",
            method: .DELETE,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    func getNotificationSettings() async throws -> NotificationSettingsResponse {
        return try await performRequest(
            endpoint: "api/users/notification-settings",
            method: .GET,
            responseType: NotificationSettingsResponse.self
        )
    }

    func updateNotificationSettings(settings: [String: Bool]) async throws {
        let bodyData = try JSONSerialization.data(withJSONObject: settings)
        let response: APIResponse<AnyCodable> = try await performRequest(
            endpoint: "api/users/notification-settings",
            method: .PUT,
            body: bodyData,
            responseType: APIResponse<AnyCodable>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to update notification settings")
        }
    }
    
    func sendPushNotification(
        to userId: Int,
        type: String,
        title: String,
        body: String,
        payload: [String: Any] = [:]
    ) async throws -> EmptyResponse {
        var parameters: [String: Any] = [
            "user_id": userId,
            "type": type,
            "title": title,
            "body": body
        ]
        
        if !payload.isEmpty {
            parameters["payload"] = payload
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: parameters)
        return try await performRequest(
            endpoint: "send_push_notification.php",
            method: .POST,
            body: bodyData,
            responseType: EmptyResponse.self
        )
    }
    
    func fetchNotificationHistory(page: Int = 1, limit: Int = 20) async throws -> NotificationHistoryResponse {
        return try await performRequest(
            endpoint: "fetch_notification_history.php?page=\(page)&limit=\(limit)",
            method: .GET,
            responseType: NotificationHistoryResponse.self
        )
    }
    
    // Removed duplicate markNotificationAsRead method - already defined above with APIResponse return type
    
    func getNotificationBadgeCount() async throws -> BadgeCountResponse {
        return try await performRequest(
            endpoint: "get_badge_count.php",
            method: .GET,
            responseType: BadgeCountResponse.self
        )
    }
    
    // MARK: - Location Services
    func updateLocation(latitude: Double, 
                       longitude: Double,
                       accuracy: Double? = nil,
                       address: String? = nil,
                       city: String? = nil,
                       state: String? = nil,
                       country: String? = nil,
                       zipCode: String? = nil,
                       searchRadius: Double? = nil) async throws -> [String: Any] {
        
        var parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        if let accuracy = accuracy { parameters["accuracy"] = accuracy }
        if let address = address { parameters["address"] = address }
        if let city = city { parameters["city"] = city }
        if let state = state { parameters["state"] = state }
        if let country = country { parameters["country"] = country }
        if let zipCode = zipCode { parameters["zip_code"] = zipCode }
        if let searchRadius = searchRadius { parameters["search_radius"] = searchRadius }
        
        let bodyData = try JSONSerialization.data(withJSONObject: parameters)
        
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api/users/me/location")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        if let success = response["success"] as? Bool, !success {
            throw BrrowAPIError.invalidResponse
        }
        
        return response
    }
    
    func searchByLocation(latitude: Double,
                         longitude: Double,
                         radius: Double = 10,
                         type: String = "all",
                         category: String? = nil,
                         minPrice: Double? = nil,
                         maxPrice: Double? = nil,
                         sort: String = "distance",
                         limit: Int = 20,
                         offset: Int = 0) async throws -> [String: Any] {
        
        var queryParams = [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "radius": String(radius),
            "type": type,
            "sort": sort,
            "limit": String(limit),
            "offset": String(offset)
        ]
        
        if let category = category { queryParams["category"] = category }
        if let minPrice = minPrice { queryParams["min_price"] = String(minPrice) }
        if let maxPrice = maxPrice { queryParams["max_price"] = String(maxPrice) }
        
        let queryString = queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        let baseURL = await self.baseURL
        let url = URL(string: "\(baseURL)/api/search/location?\(queryString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authManager.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let apiId = authManager.currentUser?.apiId {
            request.setValue(apiId, forHTTPHeaderField: "X-User-API-ID")
        }
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        if let success = response["success"] as? Bool, !success {
            throw BrrowAPIError.invalidResponse
        }
        
        return response
    }

    // MARK: - Stripe Connect Methods

    struct StripeConnectStatusResponse: Codable {
        let connected: Bool
        let canReceivePayments: Bool
        let accountId: String?
        let detailsSubmitted: Bool?
        let chargesEnabled: Bool?
        let payoutsEnabled: Bool?
        let requiresOnboarding: Bool?
    }

    struct StripeConnectOnboardingResponse: Codable {
        let success: Bool
        let onboardingUrl: String
        let accountId: String
    }

    func getStripeConnectStatus() async throws -> StripeConnectStatusResponse {
        return try await performRequest(
            endpoint: "api/stripe/connect/status",
            method: .GET,
            responseType: StripeConnectStatusResponse.self
        )
    }

    func getStripeConnectOnboardingUrl() async throws -> StripeConnectOnboardingResponse {
        return try await performRequest(
            endpoint: "api/stripe/connect/onboarding",
            method: .GET,
            responseType: StripeConnectOnboardingResponse.self
        )
    }

    // MARK: - User Preferences Methods

    struct UserPreferences: Codable {
        let isDarkMode: Bool
        let textSize: String
        let language: String
    }

    struct UserPreferencesResponse: Codable {
        let success: Bool
        let message: String?
    }

    func saveUserPreferences(_ preferences: UserPreferences) async throws {
        let requestBody: [String: Any] = [
            "isDarkMode": preferences.isDarkMode,
            "textSize": preferences.textSize,
            "language": preferences.language
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)

        let _ = try await performRequest(
            endpoint: "api/user/preferences",
            method: .POST,
            body: bodyData,
            responseType: UserPreferencesResponse.self
        )
    }

    func getUserPreferences() async throws -> UserPreferences? {
        struct UserPreferencesAPIResponse: Codable {
            let success: Bool
            let data: UserPreferencesData?

            struct UserPreferencesData: Codable {
                let isDarkMode: Bool?
                let textSize: String?
                let language: String?
            }
        }

        let response = try await performRequest(
            endpoint: "api/user/preferences",
            method: .GET,
            responseType: UserPreferencesAPIResponse.self
        )

        guard let data = response.data else { return nil }

        return UserPreferences(
            isDarkMode: data.isDarkMode ?? false,
            textSize: data.textSize ?? "medium",
            language: data.language ?? "en"
        )
    }

    // MARK: - Earnings
    func fetchRecentLegacyEarningsTransactions() async throws -> [LegacyEarningsTransaction] {
        // Placeholder implementation
        return []
    }

    // MARK: - Two-Factor Authentication

    struct TwoFactorSetupResponse: Codable {
        let success: Bool
        let data: TwoFactorData?
        let message: String?

        struct TwoFactorData: Codable {
            let qrCode: String
            let secret: String
            let backupCodes: [String]
        }
    }

    struct TwoFactorVerifyResponse: Codable {
        let success: Bool
        let message: String?
        let data: TwoFactorVerifyData?

        struct TwoFactorVerifyData: Codable {
            let enabled: Bool
        }
    }

    func setupTwoFactor() async throws -> TwoFactorSetupResponse {
        return try await performRequestNoCaching(
            endpoint: "api/auth/2fa/setup",
            method: .POST,
            responseType: TwoFactorSetupResponse.self
        )
    }

    func verifyTwoFactor(code: String) async throws -> TwoFactorVerifyResponse {
        struct VerifyRequest: Codable {
            let code: String
        }

        let bodyData = try JSONEncoder().encode(VerifyRequest(code: code))

        return try await performRequestNoCaching(
            endpoint: "api/auth/2fa/verify",
            method: .POST,
            body: bodyData,
            responseType: TwoFactorVerifyResponse.self
        )
    }

    func verifyTwoFactorLogin(code: String) async throws -> TwoFactorVerifyResponse {
        struct VerifyRequest: Codable {
            let code: String
        }

        let bodyData = try JSONEncoder().encode(VerifyRequest(code: code))

        return try await performRequestNoCaching(
            endpoint: "api/auth/2fa/verify-login",
            method: .POST,
            body: bodyData,
            responseType: TwoFactorVerifyResponse.self
        )
    }

    func disableTwoFactor(code: String) async throws -> TwoFactorVerifyResponse {
        struct DisableRequest: Codable {
            let code: String
        }

        let bodyData = try JSONEncoder().encode(DisableRequest(code: code))

        return try await performRequestNoCaching(
            endpoint: "api/auth/2fa/disable",
            method: .POST,
            body: bodyData,
            responseType: TwoFactorVerifyResponse.self
        )
    }
}
