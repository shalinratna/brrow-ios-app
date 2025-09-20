//
//  NetworkManager.swift
//  Brrow
//
//  Network configuration and retry logic
//

import Foundation
import Network

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    // Retry configuration
    struct RetryConfiguration {
        let maxAttempts: Int = 3
        let initialDelay: TimeInterval = 1.0
        let maxDelay: TimeInterval = 16.0
        let multiplier: Double = 2.0
    }
    
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                if !path.status.isConnected {
                    print("⚠️ Network disconnected")
                } else {
                    print("✅ Network connected via \(path.availableInterfaces.first?.type.description ?? "unknown")")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // Enhanced URL session configuration
    static func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        
        // More aggressive timeout values for better UX (except uploads)
        config.timeoutIntervalForRequest = 30.0  // 30 seconds for single request (increased for uploads)
        config.timeoutIntervalForResource = 120.0  // 2 minutes total (to support image uploads)
        
        // Connection settings
        config.httpMaximumConnectionsPerHost = 3
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        
        // Cache policy - DISABLED to always fetch fresh data
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil  // Disable cache completely
        
        // Headers - Force no caching
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "Brrow/1.0 iOS",
            "Accept-Encoding": "gzip, deflate",
            "Connection": "keep-alive",
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0"
        ]
        
        // TLS configuration - Force TLS 1.2 in simulator to avoid SSL issues
        #if targetEnvironment(simulator)
        // Simulator has issues with newer TLS versions and HTTP/3
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv12
        #else
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        #endif
        
        // Disable HTTP/3 QUIC which causes connection issues in simulator
        config.multipathServiceType = .none
        config.httpShouldUsePipelining = false
        
        // Additional network fixes for simulator
        #if targetEnvironment(simulator)
        // Disable HTTP/2 in simulator if having issues
        if #available(iOS 14.0, *) {
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
        }
        // Use legacy network stack in simulator
        config.networkServiceType = .default
        #endif
        
        return URLSession(configuration: config)
    }
    
    // Retry logic with exponential backoff
    static func performRequestWithRetry<T: Decodable>(
        request: URLRequest,
        session: URLSession,
        responseType: T.Type,
        retryConfig: RetryConfiguration = RetryConfiguration()
    ) async throws -> T {
        // Add timeout to individual request
        var mutableRequest = request

        // Check if this is an upload endpoint and needs longer timeout
        if let url = mutableRequest.url?.absoluteString,
           (url.contains("/api/upload") || url.contains("/upload") || url.contains("image")) {
            // Give uploads 60 seconds timeout
            mutableRequest.timeoutInterval = 60.0
            print("📤 Upload endpoint detected - using 60s timeout")
        } else if mutableRequest.timeoutInterval == 60.0 {  // Default timeout for non-uploads
            mutableRequest.timeoutInterval = 15.0  // Override with shorter timeout
        }
        var lastError: Error?
        var delay = retryConfig.initialDelay
        
        for attempt in 1...retryConfig.maxAttempts {
            do {
                // Log attempt
                print("🔄 API Request attempt \(attempt)/\(retryConfig.maxAttempts): \(request.url?.path ?? "")")
                
                // Check network connectivity
                if !NetworkManager.shared.isConnected {
                    throw BrrowAPIError.networkError("No network connection")
                }
                
                // Perform request
                let (data, response) = try await session.data(for: mutableRequest)
                
                // Check response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw BrrowAPIError.invalidResponse
                }
                
                // Log response
                print("📡 Response: \(httpResponse.statusCode) for \(request.url?.path ?? "")")
                
                // Handle different status codes
                switch httpResponse.statusCode {
                case 200...299:
                    // Success - decode and return
                    do {
                        // First check if response is actually JSON
                        if let responseString = String(data: data, encoding: .utf8) {
                            // Check if response is PHP source code (AwardSpace not executing PHP)
                            if responseString.contains("<?php") {
                                print("⚠️ PHP source code detected - server not executing PHP")
                                // Report endpoint failure to trigger failover
                                if let baseURL = request.url?.host {
                                    APIEndpointManager.shared.reportEndpointFailure("https://\(baseURL)")
                                }
                                throw BrrowAPIError.serverError("Primary server error. Switching to backup...")
                            }
                            
                            // Check for PHP errors in response
                            if responseString.contains("<br />") && 
                               (responseString.contains("Parse error") || 
                                responseString.contains("Fatal error") ||
                                responseString.contains("Warning:") ||
                                responseString.contains("Notice:")) {
                                print("❌ PHP Error detected in response: \(responseString)")
                                throw BrrowAPIError.serverError("Server configuration error. Please try again later.")
                            }
                            
                            // Check if response is HTML error page
                            if responseString.hasPrefix("<!DOCTYPE") || responseString.hasPrefix("<html") {
                                print("❌ HTML error page returned instead of JSON")
                                throw BrrowAPIError.serverError("Server returned an error page. Please try again later.")
                            }
                        }
                        
                        // Special handling for EmptyResponse type
                        if responseType == EmptyResponse.self {
                            // Try to decode as EmptyResponse, but be lenient
                            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                let success = json["success"] as? Bool ?? true
                                let message = json["message"] as? String
                                let emptyResponse = EmptyResponse(success: success, message: message)
                                return emptyResponse as! T
                            }
                            // If we can't parse it but got 200, assume success
                            let emptyResponse = EmptyResponse(success: true, message: "Operation completed")
                            return emptyResponse as! T
                        }
                        
                        // Configure JSONDecoder - don't set date strategy if not needed
                        let decoder = JSONDecoder()
                        // Most of our models use String for dates now, so we don't need custom date decoding
                        // This avoids the crash from date formatter issues
                        
                        let decoded = try decoder.decode(responseType, from: data)
                        return decoded
                    } catch {
                        // Log the raw response for debugging
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("❌ Decoding error. Raw response: \(responseString)")
                        }
                        throw BrrowAPIError.decodingError
                    }
                    
                case 401:
                    throw BrrowAPIError.unauthorized

                case 403:
                    // Parse 403 response to check for token expiration
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Forbidden"
                    if errorMessage.contains("Invalid or expired token") {
                        print("🔐 Token expired - forcing logout")
                        // Force logout on main thread
                        DispatchQueue.main.async {
                            AuthManager.shared.logout()
                        }
                        throw BrrowAPIError.unauthorized
                    }
                    // Other 403 errors
                    throw BrrowAPIError.validationError(errorMessage)

                case 409:
                    // Conflict error - parse the response for address conflict details
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Conflict error"
                    throw BrrowAPIError.addressConflict(errorMessage)

                case 400...499:
                    // Client error - don't retry
                    // Try to decode the error response
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let error = jsonObject["error"] as? String ?? "Client error"
                        let daysRemaining = jsonObject["daysRemaining"] as? Int

                        // Check for token expiration in JSON response
                        if error.contains("Invalid or expired token") {
                            print("🔐 Token expired - forcing logout")
                            // Force logout on main thread
                            DispatchQueue.main.async {
                                AuthManager.shared.logout()
                            }
                            throw BrrowAPIError.unauthorized
                        }

                        // Special handling for username change 90-day policy
                        if let days = daysRemaining, error.contains("90 days") {
                            throw BrrowAPIError.validationError("Username can only be changed once every 90 days. \(days) days remaining.")
                        }

                        throw BrrowAPIError.validationError(error)
                    }

                    // Fallback to raw error message
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
                    // Check for token expiration in raw response
                    if errorMessage.contains("Invalid or expired token") {
                        print("🔐 Token expired - forcing logout")
                        // Force logout on main thread
                        DispatchQueue.main.async {
                            AuthManager.shared.logout()
                        }
                        throw BrrowAPIError.unauthorized
                    }
                    throw BrrowAPIError.validationError(errorMessage)
                    
                case 500...599:
                    // Server error - retry
                    lastError = BrrowAPIError.serverErrorCode(httpResponse.statusCode)
                    
                default:
                    lastError = BrrowAPIError.serverError("Unexpected status code: \(httpResponse.statusCode)")
                }
                
            } catch let error as URLError {
                // Network errors - retry
                switch error.code {
                case .timedOut:
                    print("⏱️ Request timed out (attempt \(attempt))")
                    lastError = BrrowAPIError.networkError("Request timed out")
                    
                case .notConnectedToInternet, .networkConnectionLost:
                    print("📵 Network connection lost (attempt \(attempt))")
                    lastError = BrrowAPIError.networkError("Network connection lost")
                    
                case .cannotConnectToHost, .cannotFindHost:
                    print("🚫 Cannot connect to server (attempt \(attempt))")
                    lastError = BrrowAPIError.networkError("Cannot connect to server")
                    
                default:
                    print("❌ Network error: \(error.localizedDescription)")
                    lastError = error
                }
                
            } catch {
                // Other errors
                if error is BrrowAPIError {
                    throw error  // Don't retry API errors
                }
                lastError = error
            }
            
            // If we have more attempts, wait before retrying
            if attempt < retryConfig.maxAttempts {
                print("⏳ Waiting \(delay)s before retry...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Exponential backoff
                delay = min(delay * retryConfig.multiplier, retryConfig.maxDelay)
            }
        }
        
        // All attempts failed
        throw lastError ?? BrrowAPIError.networkError("All retry attempts failed")
    }
}

// Extension for NWInterface.InterfaceType
extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}

// Extension for NWPath.Status
extension NWPath.Status {
    var isConnected: Bool {
        return self == .satisfied
    }
}
