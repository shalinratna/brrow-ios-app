//
//  PostAnalyticsService.swift
//  Brrow
//
//  Service for tracking and retrieving post analytics
//

import Foundation
import UIKit

class PostAnalyticsService {
    static let shared = PostAnalyticsService()

    private let apiClient = APIClient.shared
    private var sessionId: String
    private var activeViewEventId: String?
    private var viewStartTime: Date?
    private var scrollDepth: Double = 0
    private var imagesViewed: Int = 0
    private var videoPlayed: Bool = false
    private var heartbeatTimer: Timer?

    private init() {
        sessionId = UUID().uuidString
    }

    // MARK: - Event Tracking

    /**
     Track a post view
     Call this when user opens a listing detail page
     */
    func trackPostView(
        listingId: String,
        source: TrafficSourceType? = nil,
        searchQuery: String? = nil
    ) async {
        // Reset tracking state
        viewStartTime = Date()
        scrollDepth = 0
        imagesViewed = 0
        videoPlayed = false

        let request = TrackViewRequest(
            listingId: listingId,
            sessionId: sessionId,
            source: source?.rawValue,
            searchQuery: searchQuery,
            referrerUrl: nil,
            deviceType: "ios",
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            country: nil, // Could be fetched from location services
            state: nil,
            city: nil
        )

        do {
            let response: APIResponse<ViewEventResponse> = try await apiClient.performRequest(
                endpoint: "api/post-analytics/track/view",
                method: "POST",
                body: try JSONEncoder().encode(request),
                responseType: APIResponse<ViewEventResponse>.self
            )

            if let viewEventId = response.data?.viewEventId {
                activeViewEventId = viewEventId

                // Start heartbeat for active viewers
                startHeartbeat(listingId: listingId)
            }

            debugLog("Post view tracked: \(listingId)")
        } catch {
            debugLog("Failed to track post view: \(error.localizedDescription)")
        }
    }

    /**
     Update view engagement metrics
     Call this when user exits the listing detail page
     */
    func endPostView() async {
        guard let viewEventId = activeViewEventId,
              let startTime = viewStartTime else {
            return
        }

        // Stop heartbeat
        stopHeartbeat()

        let duration = Int(Date().timeIntervalSince(startTime))

        let request = TrackViewEngagementRequest(
            viewEventId: viewEventId,
            viewDuration: duration,
            scrollDepth: scrollDepth,
            imagesViewed: imagesViewed,
            videoPlayed: videoPlayed
        )

        do {
            let _: APIResponse<EmptyData> = try await apiClient.performRequest(
                endpoint: "api/post-analytics/track/view-engagement",
                method: "POST",
                body: try JSONEncoder().encode(request),
                responseType: APIResponse<EmptyData>.self
            )

            debugLog("View engagement updated - Duration: \(duration)s, Scroll: \(scrollDepth)%")
        } catch {
            debugLog("Failed to update view engagement: \(error.localizedDescription)")
        }

        // Reset state
        activeViewEventId = nil
        viewStartTime = nil
        scrollDepth = 0
        imagesViewed = 0
        videoPlayed = false
    }

    /**
     Update scroll depth
     Call this as user scrolls through the listing
     */
    func updateScrollDepth(_ depth: Double) {
        scrollDepth = max(scrollDepth, depth)
    }

    /**
     Track image view in gallery
     Call this when user views an image
     */
    func trackImageViewed() {
        imagesViewed += 1
    }

    /**
     Track video play
     Call this when user plays a video
     */
    func trackVideoPlayed() {
        videoPlayed = true
    }

    /**
     Track engagement event
     */
    func trackEngagement(
        listingId: String,
        eventType: AnalyticsEventType,
        source: String? = nil,
        metadata: [String: String]? = nil
    ) async {
        let request = TrackEngagementRequest(
            listingId: listingId,
            eventType: eventType.rawValue,
            sessionId: sessionId,
            source: source,
            metadata: metadata,
            deviceType: "ios"
        )

        do {
            let _: APIResponse<EmptyData> = try await apiClient.performRequest(
                endpoint: "api/post-analytics/track/engagement",
                method: "POST",
                body: try JSONEncoder().encode(request),
                responseType: APIResponse<EmptyData>.self
            )

            debugLog("Engagement tracked: \(eventType.rawValue)")
        } catch {
            debugLog("Failed to track engagement: \(error.localizedDescription)")
        }
    }

    /**
     Track favorite
     */
    func trackFavorite(listingId: String, isFavoriting: Bool) async {
        await trackEngagement(
            listingId: listingId,
            eventType: isFavoriting ? .favorite : .unfavorite
        )
    }

    /**
     Track share
     */
    func trackShare(listingId: String, platform: String? = nil) async {
        var metadata: [String: String]? = nil
        if let platform = platform {
            metadata = ["platform": platform]
        }

        await trackEngagement(
            listingId: listingId,
            eventType: .share,
            metadata: metadata
        )
    }

    /**
     Track contact/message click
     */
    func trackContactClick(listingId: String) async {
        await trackEngagement(
            listingId: listingId,
            eventType: .contactClick
        )
    }

    /**
     Track gallery click
     */
    func trackGalleryClick(listingId: String) async {
        await trackEngagement(
            listingId: listingId,
            eventType: .galleryClick
        )
    }

    /**
     Track map click
     */
    func trackMapClick(listingId: String) async {
        await trackEngagement(
            listingId: listingId,
            eventType: .mapClick
        )
    }

    // MARK: - Real-time Analytics

    private func startHeartbeat(listingId: String) {
        // Send heartbeat every 10 seconds
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task {
                await self?.sendHeartbeat(listingId: listingId)
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func sendHeartbeat(listingId: String) async {
        struct HeartbeatRequest: Codable {
            let listingId: String
            let sessionId: String
        }

        let request = HeartbeatRequest(
            listingId: listingId,
            sessionId: sessionId
        )

        do {
            let _: APIResponse<EmptyData> = try await apiClient.performRequest(
                endpoint: "api/post-analytics/heartbeat",
                method: "POST",
                body: try JSONEncoder().encode(request),
                responseType: APIResponse<EmptyData>.self
            )
        } catch {
            // Silent fail - heartbeat is optional
        }
    }

    /**
     Get active viewer count
     */
    func getActiveViewerCount(listingId: String) async throws -> Int {
        struct ActiveViewersResponse: Codable {
            let activeViewers: Int

            enum CodingKeys: String, CodingKey {
                case activeViewers = "active_viewers"
            }
        }

        let response: APIResponse<ActiveViewersResponse> = try await apiClient.performRequest(
            endpoint: "api/post-analytics/\(listingId)/active-viewers",
            method: "GET",
            responseType: APIResponse<ActiveViewersResponse>.self
        )

        return response.data?.activeViewers ?? 0
    }

    // MARK: - Analytics Retrieval

    /**
     Get post analytics overview
     */
    func getPostOverview(listingId: String) async throws -> PostAnalyticsOverview {
        let response: APIResponse<PostAnalyticsOverview> = try await apiClient.performRequest(
            endpoint: "api/post-analytics/\(listingId)/overview",
            method: "GET",
            responseType: APIResponse<PostAnalyticsOverview>.self
        )

        guard let overview = response.data else {
            throw BrrowAPIError.invalidResponse
        }

        return overview
    }

    /**
     Get engagement analytics
     */
    func getEngagementAnalytics(listingId: String, startDate: Date? = nil, endDate: Date? = nil) async throws -> EngagementAnalytics {
        var endpoint = "api/post-analytics/\(listingId)/engagement"
        var queryItems: [String] = []

        if let startDate = startDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("start_date=\(formatter.string(from: startDate))")
        }

        if let endDate = endDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("end_date=\(formatter.string(from: endDate))")
        }

        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }

        let response: APIResponse<EngagementAnalytics> = try await apiClient.performRequest(
            endpoint: endpoint,
            method: "GET",
            responseType: APIResponse<EngagementAnalytics>.self
        )

        guard let analytics = response.data else {
            throw BrrowAPIError.invalidResponse
        }

        return analytics
    }

    /**
     Get audience demographics
     */
    func getAudienceDemographics(listingId: String) async throws -> AudienceDemographics {
        let response: APIResponse<AudienceDemographics> = try await apiClient.performRequest(
            endpoint: "api/post-analytics/\(listingId)/audience",
            method: "GET",
            responseType: APIResponse<AudienceDemographics>.self
        )

        guard let demographics = response.data else {
            throw BrrowAPIError.invalidResponse
        }

        return demographics
    }

    /**
     Get traffic sources
     */
    func getTrafficSources(listingId: String) async throws -> [TrafficSource] {
        let response: APIResponse<[TrafficSource]> = try await apiClient.performRequest(
            endpoint: "api/post-analytics/\(listingId)/traffic-sources",
            method: "GET",
            responseType: APIResponse<[TrafficSource]>.self
        )

        return response.data ?? []
    }

    /**
     Get performance time series
     */
    func getPerformanceTimeSeries(
        listingId: String,
        interval: String = "hourly",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [HourlyMetrics] {
        var endpoint = "api/post-analytics/\(listingId)/performance"
        var queryItems: [String] = ["interval=\(interval)"]

        if let startDate = startDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("start_date=\(formatter.string(from: startDate))")
        }

        if let endDate = endDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("end_date=\(formatter.string(from: endDate))")
        }

        endpoint += "?" + queryItems.joined(separator: "&")

        let response: APIResponse<[HourlyMetrics]> = try await apiClient.performRequest(
            endpoint: endpoint,
            method: "GET",
            responseType: APIResponse<[HourlyMetrics]>.self
        )

        return response.data ?? []
    }

    /**
     Get search performance
     */
    func getSearchPerformance(listingId: String, startDate: Date? = nil, endDate: Date? = nil) async throws -> SearchPerformance {
        var endpoint = "api/post-analytics/\(listingId)/search-performance"
        var queryItems: [String] = []

        if let startDate = startDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("start_date=\(formatter.string(from: startDate))")
        }

        if let endDate = endDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("end_date=\(formatter.string(from: endDate))")
        }

        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }

        let response: APIResponse<SearchPerformance> = try await apiClient.performRequest(
            endpoint: endpoint,
            method: "GET",
            responseType: APIResponse<SearchPerformance>.self
        )

        guard let performance = response.data else {
            throw BrrowAPIError.invalidResponse
        }

        return performance
    }

    /**
     Compare to user's other posts
     */
    func compareToUserPosts(listingId: String) async throws -> PostComparison {
        let response: APIResponse<PostComparison> = try await apiClient.performRequest(
            endpoint: "api/post-analytics/\(listingId)/compare/user-posts",
            method: "GET",
            responseType: APIResponse<PostComparison>.self
        )

        guard let comparison = response.data else {
            throw BrrowAPIError.invalidResponse
        }

        return comparison
    }

    /**
     Compare to category average
     */
    func compareToCategoryAverage(listingId: String) async throws -> CategoryComparison {
        let response: APIResponse<CategoryComparison> = try await apiClient.performRequest(
            endpoint: "api/post-analytics/\(listingId)/compare/category",
            method: "GET",
            responseType: APIResponse<CategoryComparison>.self
        )

        guard let comparison = response.data else {
            throw BrrowAPIError.invalidResponse
        }

        return comparison
    }

    /**
     Get analytics dashboard
     */
    func getAnalyticsDashboard(limit: Int = 20, orderBy: String = "views") async throws -> AnalyticsDashboard {
        let endpoint = "api/post-analytics/dashboard?limit=\(limit)&order_by=\(orderBy)"

        let response: APIResponse<AnalyticsDashboard> = try await apiClient.performRequest(
            endpoint: endpoint,
            method: "GET",
            responseType: APIResponse<AnalyticsDashboard>.self
        )

        guard let dashboard = response.data else {
            throw BrrowAPIError.invalidResponse
        }

        return dashboard
    }

    // MARK: - Helper Functions

    private func debugLog(_ message: String) {
        #if DEBUG
        print("📈 [PostAnalytics] \(message)")
        #endif
    }
}

// MARK: - Response Models

struct ViewEventResponse: Codable {
    let viewEventId: String

    enum CodingKeys: String, CodingKey {
        case viewEventId = "view_event_id"
    }
}
