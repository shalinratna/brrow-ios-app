//
//  AdminAPIClient.swift
//  BrrowAdmin
//
//  API Client for all 110+ admin backend endpoints
//

import Foundation

class AdminAPIClient {
    static let shared = AdminAPIClient()

    private let baseURL = "https://brrow-backend-nodejs-production.up.railway.app/api/admin"
    private let localURL = "http://localhost:3000/api/admin" // For local testing

    private var useLocalServer = false
    private var authToken: String?

    private init() {
        // Load auth token from keychain if exists
        self.authToken = KeychainManager.shared.getAdminToken()
    }

    // MARK: - Base URL
    private var apiBaseURL: String {
        useLocalServer ? localURL : baseURL
    }

    func toggleServer() {
        useLocalServer.toggle()
    }

    // MARK: - Generic Request Method
    private func makeRequest<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(apiBaseURL)/\(endpoint)") else {
            throw AdminAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdminAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw AdminAPIError.unauthorized
            }
            throw AdminAPIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Authentication
    func login(email: String, password: String) async throws -> AdminLoginResponse {
        let payload = ["email": email, "password": password]
        let body = try JSONEncoder().encode(payload)

        let response: AdminLoginResponse = try await makeRequest(
            "login",
            method: "POST",
            body: body,
            requiresAuth: false
        )

        self.authToken = response.token
        KeychainManager.shared.saveAdminToken(response.token)

        return response
    }

    func logout() {
        self.authToken = nil
        KeychainManager.shared.deleteAdminToken()
    }

    func getCurrentAdmin() async throws -> AdminUser {
        return try await makeRequest("me")
    }

    // MARK: - Dashboard
    func getDashboardStats() async throws -> DashboardStats {
        return try await makeRequest("stats")
    }

    func getRecentActivity() async throws -> [ActivityLog] {
        return try await makeRequest("activities")
    }

    func getRealtimeMetrics() async throws -> RealtimeMetrics {
        return try await makeRequest("realtime")
    }

    // MARK: - User Management (15 endpoints)
    func getUsers(page: Int = 1, limit: Int = 50, search: String? = nil, filters: UserFilters? = nil) async throws -> UsersResponse {
        var queryItems = "?page=\(page)&limit=\(limit)"

        if let search = search, !search.isEmpty {
            queryItems += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        if let filters = filters {
            if let verified = filters.verified {
                queryItems += "&verified=\(verified)"
            }
            if let banned = filters.banned {
                queryItems += "&banned=\(banned)"
            }
        }

        return try await makeRequest("users\(queryItems)")
    }

    func getUser(_ userId: String) async throws -> AdminUserDetail {
        return try await makeRequest("users/\(userId)")
    }

    func createUser(_ userData: CreateUserRequest) async throws -> AdminUserDetail {
        let body = try JSONEncoder().encode(userData)
        return try await makeRequest("users", method: "POST", body: body)
    }

    func updateUser(_ userId: String, updates: UpdateUserRequest) async throws -> AdminUserDetail {
        let body = try JSONEncoder().encode(updates)
        return try await makeRequest("users/\(userId)", method: "PATCH", body: body)
    }

    func deleteUser(_ userId: String) async throws -> SuccessResponse {
        return try await makeRequest("users/\(userId)", method: "DELETE")
    }

    func suspendUser(_ userId: String, reason: String, expiresAt: Date?) async throws -> SuccessResponse {
        var payload: [String: Any] = ["reason": reason]
        if let expiresAt = expiresAt {
            payload["expiresAt"] = ISO8601DateFormatter().string(from: expiresAt)
        }
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("users/\(userId)/suspend", method: "POST", body: body)
    }

    func unsuspendUser(_ userId: String) async throws -> SuccessResponse {
        return try await makeRequest("users/\(userId)/unsuspend", method: "POST")
    }

    func banUser(_ userId: String, reason: String, permanent: Bool = false) async throws -> SuccessResponse {
        let payload = ["reason": reason, "permanent": permanent] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("users/\(userId)/ban", method: "POST", body: body)
    }

    func unbanUser(_ userId: String) async throws -> SuccessResponse {
        return try await makeRequest("users/\(userId)/unban", method: "POST")
    }

    func verifyUser(_ userId: String) async throws -> SuccessResponse {
        return try await makeRequest("users/\(userId)/verify", method: "POST")
    }

    func resetUserPassword(_ userId: String) async throws -> ResetPasswordResponse {
        return try await makeRequest("users/\(userId)/reset-password", method: "POST")
    }

    func bulkSuspendUsers(_ userIds: [String], reason: String) async throws -> BulkActionResponse {
        let payload = ["userIds": userIds, "reason": reason] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("users/bulk-suspend", method: "POST", body: body)
    }

    func bulkDeleteUsers(_ userIds: [String]) async throws -> BulkActionResponse {
        let payload = ["userIds": userIds]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("users/bulk-delete", method: "POST", body: body)
    }

    // MARK: - Listing Management (15 endpoints)
    func getListings(page: Int = 1, limit: Int = 50, status: String? = nil) async throws -> ListingsResponse {
        var queryItems = "?page=\(page)&limit=\(limit)"
        if let status = status {
            queryItems += "&status=\(status)"
        }
        return try await makeRequest("listings\(queryItems)")
    }

    func getListing(_ listingId: String) async throws -> AdminListingDetail {
        return try await makeRequest("listings/\(listingId)")
    }

    func approveListing(_ listingId: String) async throws -> SuccessResponse {
        return try await makeRequest("listings/\(listingId)/approve", method: "POST")
    }

    func rejectListing(_ listingId: String, reason: String) async throws -> SuccessResponse {
        let payload = ["reason": reason]
        let body = try JSONEncoder().encode(payload)
        return try await makeRequest("listings/\(listingId)/reject", method: "POST", body: body)
    }

    func flagListing(_ listingId: String, reason: String) async throws -> SuccessResponse {
        let payload = ["flagReason": reason]
        let body = try JSONEncoder().encode(payload)
        return try await makeRequest("listings/\(listingId)/moderate", method: "PATCH", body: body)
    }

    func unflagListing(_ listingId: String) async throws -> SuccessResponse {
        let payload = ["isFlagged": false]
        let body = try JSONEncoder().encode(payload)
        return try await makeRequest("listings/\(listingId)/moderate", method: "PATCH", body: body)
    }

    func deleteListing(_ listingId: String, reason: String) async throws -> SuccessResponse {
        return try await makeRequest("listings/\(listingId)?reason=\(reason)", method: "DELETE")
    }

    func updateListing(_ listingId: String, updates: UpdateListingRequest) async throws -> AdminListingDetail {
        let body = try JSONEncoder().encode(updates)
        return try await makeRequest("listings/\(listingId)", method: "PATCH", body: body)
    }

    func bulkApproveListing(_ listingIds: [String]) async throws -> BulkActionResponse {
        let payload = ["listingIds": listingIds]
        let body = try JSONEncoder().encode(payload)
        return try await makeRequest("listings/bulk-approve", method: "POST", body: body)
    }

    func bulkRejectListings(_ listingIds: [String], reason: String) async throws -> BulkActionResponse {
        let payload = ["listingIds": listingIds, "reason": reason] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("listings/bulk-reject", method: "POST", body: body)
    }

    // MARK: - Transaction Management (12 endpoints)
    func getTransactions(page: Int = 1, limit: Int = 50) async throws -> TransactionsResponse {
        return try await makeRequest("transactions?page=\(page)&limit=\(limit)")
    }

    func getTransaction(_ transactionId: String) async throws -> AdminTransactionDetail {
        return try await makeRequest("transactions/\(transactionId)")
    }

    func refundTransaction(_ transactionId: String, amount: Double, reason: String) async throws -> RefundResponse {
        let payload = ["amount": amount, "reason": reason] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("transactions/\(transactionId)/refund", method: "POST", body: body)
    }

    func getRevenueAnalytics(startDate: Date, endDate: Date) async throws -> RevenueAnalytics {
        let formatter = ISO8601DateFormatter()
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return try await makeRequest("analytics/revenue?start=\(start)&end=\(end)")
    }

    // MARK: - Reports & Moderation (8 endpoints)
    func getReports(page: Int = 1, limit: Int = 50, status: String? = nil) async throws -> ReportsResponse {
        var queryItems = "?page=\(page)&limit=\(limit)"
        if let status = status {
            queryItems += "&status=\(status)"
        }
        return try await makeRequest("reports\(queryItems)")
    }

    func getReport(_ reportId: String) async throws -> ReportDetail {
        return try await makeRequest("reports/\(reportId)")
    }

    func assignReport(_ reportId: String, adminId: String) async throws -> SuccessResponse {
        let payload = ["assignedTo": adminId]
        let body = try JSONEncoder().encode(payload)
        return try await makeRequest("reports/\(reportId)/assign", method: "PATCH", body: body)
    }

    func resolveReport(_ reportId: String, action: String, notes: String) async throws -> SuccessResponse {
        let payload = ["status": "RESOLVED", "actionTaken": action, "notes": notes] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("reports/\(reportId)/resolve", method: "PATCH", body: body)
    }

    func dismissReport(_ reportId: String, reason: String) async throws -> SuccessResponse {
        let payload = ["status": "DISMISSED", "notes": reason] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("reports/\(reportId)/resolve", method: "PATCH", body: body)
    }

    // MARK: - Fraud Alerts (3 endpoints)
    func getFraudAlerts(page: Int = 1, status: String? = nil) async throws -> FraudAlertsResponse {
        var queryItems = "?page=\(page)"
        if let status = status {
            queryItems += "&status=\(status)"
        }
        return try await makeRequest("fraud-alerts\(queryItems)")
    }

    func reviewFraudAlert(_ alertId: String, action: String, notes: String) async throws -> SuccessResponse {
        let payload = ["reviewAction": action, "reviewNotes": notes] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("fraud-alerts/\(alertId)/review", method: "PATCH", body: body)
    }

    func getUserFraudHistory(_ userId: String) async throws -> [FraudAlert] {
        return try await makeRequest("fraud-alerts/user/\(userId)")
    }

    // MARK: - Analytics (8 endpoints)
    func getUserGrowthMetrics(period: String = "30d") async throws -> UserGrowthMetrics {
        return try await makeRequest("analytics/users?period=\(period)")
    }

    func getListingPerformance(period: String = "30d") async throws -> ListingPerformanceMetrics {
        return try await makeRequest("analytics/listings?period=\(period)")
    }

    func getPlatformHealth() async throws -> PlatformHealthMetrics {
        return try await makeRequest("analytics/health")
    }

    // MARK: - Announcements (8 endpoints)
    func getAnnouncements() async throws -> [Announcement] {
        return try await makeRequest("announcements")
    }

    func createAnnouncement(_ announcement: CreateAnnouncementRequest) async throws -> Announcement {
        let body = try JSONEncoder().encode(announcement)
        return try await makeRequest("announcements", method: "POST", body: body)
    }

    func updateAnnouncement(_ announcementId: String, updates: UpdateAnnouncementRequest) async throws -> Announcement {
        let body = try JSONEncoder().encode(updates)
        return try await makeRequest("announcements/\(announcementId)", method: "PATCH", body: body)
    }

    func deleteAnnouncement(_ announcementId: String) async throws -> SuccessResponse {
        return try await makeRequest("announcements/\(announcementId)", method: "DELETE")
    }

    // MARK: - Settings (8 endpoints)
    func getSettings() async throws -> [AdminSetting] {
        return try await makeRequest("settings")
    }

    func updateSetting(key: String, value: Any, reason: String) async throws -> AdminSetting {
        let payload = ["key": key, "value": value, "changeReason": reason] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await makeRequest("settings", method: "PUT", body: body)
    }

    func getSettingHistory(key: String) async throws -> [SettingHistory] {
        return try await makeRequest("settings/\(key)/history")
    }

    // MARK: - Audit Logs
    func getAuditLogs(page: Int = 1, adminId: String? = nil, action: String? = nil) async throws -> AuditLogsResponse {
        var queryItems = "?page=\(page)"
        if let adminId = adminId {
            queryItems += "&adminId=\(adminId)"
        }
        if let action = action {
            queryItems += "&action=\(action)"
        }
        return try await makeRequest("logs\(queryItems)")
    }
}

// MARK: - Error Types
enum AdminAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized - Please log in again"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.brrow.admin"
    private let account = "admin-token"

    func saveAdminToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getAdminToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func deleteAdminToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
