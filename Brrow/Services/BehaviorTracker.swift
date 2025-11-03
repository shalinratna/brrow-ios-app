import Foundation
import UIKit

/// Silent behavior tracking service for ML recommendations
/// Batches events locally and uploads periodically to minimize server load
class BehaviorTracker {
    static let shared = BehaviorTracker()

    private init() {
        setupSession()
        setupBackgroundUpload()
    }

    // MARK: - Configuration
    private let batchSize = 30 // Upload after 30 events
    private let uploadInterval: TimeInterval = 60 // Upload every 60 seconds
    private var uploadTimer: Timer?

    // MARK: - Session Management
    private var sessionId: String = UUID().uuidString
    private var sessionStartTime = Date()
    private var sessionStats = SessionStats()

    // MARK: - Event Buffers
    private var searchBuffer: [SearchEvent] = []
    private var recommendationBuffer: [RecommendationEvent] = []

    private let queue = DispatchQueue(label: "com.brrow.behaviortracker", qos: .utility)

    // MARK: - Session Setup
    private func setupSession() {
        sessionId = UUID().uuidString
        sessionStartTime = Date()
        sessionStats = SessionStats()
    }

    private func setupBackgroundUpload() {
        // Upload every 60 seconds
        uploadTimer = Timer.scheduledTimer(withTimeInterval: uploadInterval, repeats: true) { [weak self] _ in
            self?.uploadBatch()
        }
    }

    // MARK: - Track Search
    func trackSearch(
        query: String?,
        categoryId: String? = nil,
        priceRange: (min: Double, max: Double)? = nil,
        location: (lat: Double, lng: Double)? = nil,
        filters: [String: Any]? = nil,
        resultsCount: Int = 0,
        clickedListingId: String? = nil
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let event = SearchEvent(
                query: query ?? "",
                categoryId: categoryId,
                priceRange: priceRange.map { ["min": $0.min, "max": $0.max] },
                location: location.map { ["latitude": $0.lat, "longitude": $0.lng] },
                filters: filters,
                resultsCount: resultsCount,
                clickedListingId: clickedListingId
            )

            self.searchBuffer.append(event)
            self.sessionStats.searchesPerformed += 1

            if self.searchBuffer.count >= self.batchSize {
                self.uploadBatch()
            }
        }
    }

    // MARK: - Track Recommendation Interaction
    func trackRecommendation(
        listingId: String,
        recommendationType: String,
        recommendationScore: Double? = nil,
        position: Int = 0,
        wasViewed: Bool = false,
        wasClicked: Bool = false,
        wasFavorited: Bool = false,
        viewDuration: TimeInterval? = nil
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let event = RecommendationEvent(
                listingId: listingId,
                recommendationType: recommendationType,
                recommendationScore: recommendationScore,
                position: position,
                wasViewed: wasViewed,
                wasClicked: wasClicked,
                wasFavorited: wasFavorited,
                viewDurationSeconds: viewDuration.map { Int($0) }
            )

            self.recommendationBuffer.append(event)

            if self.recommendationBuffer.count >= self.batchSize {
                self.uploadBatch()
            }
        }
    }

    // MARK: - Track Listing View
    func trackListingView(listingId: String) {
        sessionStats.listingsViewed += 1
    }

    // MARK: - Track Favorite
    func trackFavorite(listingId: String) {
        sessionStats.favoritesAdded += 1
    }

    // MARK: - Track Message
    func trackMessage() {
        sessionStats.messagesSent += 1
    }

    // MARK: - Session End
    func endSession() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.uploadSession()
            self.uploadBatch()
        }
    }

    // MARK: - Upload
    private func uploadBatch() {
        guard !searchBuffer.isEmpty || !recommendationBuffer.isEmpty else { return }

        let searches = searchBuffer
        let recommendations = recommendationBuffer

        searchBuffer.removeAll()
        recommendationBuffer.removeAll()

        Task {
            do {
                guard let _ = await AuthManager.shared.currentUser else { return }

                struct BatchResponse: Codable {
                    let success: Bool
                    let message: String?
                }

                let payload: [String: Any] = [
                    "searches": searches.map { $0.toDictionary() },
                    "sessions": [],
                    "recommendations": recommendations.map { $0.toDictionary() }
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: payload)

                let response: BatchResponse = try await APIClient.shared.makeRequest(
                    "analytics/track/batch",
                    method: "POST",
                    body: jsonData
                )

                if response.success {
                    print("✅ Behavior batch uploaded: \(searches.count) searches, \(recommendations.count) recommendations")
                }
            } catch {
                print("❌ Failed to upload behavior batch: \(error)")
                // Re-add events on failure
                queue.async {
                    self.searchBuffer.append(contentsOf: searches)
                    self.recommendationBuffer.append(contentsOf: recommendations)
                }
            }
        }
    }

    private func uploadSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)

        Task {
            do {
                let deviceInfo = await getDeviceInfo()

                struct SessionResponse: Codable {
                    let success: Bool
                    let message: String?
                }

                let payload: [String: Any] = [
                    "session_id": sessionId,
                    "device_type": deviceInfo.deviceType,
                    "os_version": deviceInfo.osVersion,
                    "app_version": deviceInfo.appVersion,
                    "started_at": ISO8601DateFormatter().string(from: sessionStartTime),
                    "ended_at": ISO8601DateFormatter().string(from: Date()),
                    "duration_seconds": Int(duration),
                    "listings_viewed": sessionStats.listingsViewed,
                    "searches_performed": sessionStats.searchesPerformed,
                    "favorites_added": sessionStats.favoritesAdded,
                    "messages_sent": sessionStats.messagesSent
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: payload)

                let response: SessionResponse = try await APIClient.shared.makeRequest(
                    "analytics/track/session",
                    method: "POST",
                    body: jsonData
                )

                if response.success {
                    print("✅ Session uploaded: \(Int(duration))s")
                }
            } catch {
                print("❌ Failed to upload session: \(error)")
            }
        }
    }

    @MainActor
    private func getDeviceInfo() -> (deviceType: String, osVersion: String, appVersion: String) {
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let osVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        return (deviceType, osVersion, appVersion)
    }

    // MARK: - Cleanup
    deinit {
        uploadTimer?.invalidate()
        uploadBatch()
        uploadSession()
    }
}

// MARK: - Event Models
private struct SearchEvent {
    let query: String
    let categoryId: String?
    let priceRange: [String: Double]?
    let location: [String: Double]?
    let filters: [String: Any]?
    let resultsCount: Int
    let clickedListingId: String?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "query": query,
            "results_count": resultsCount
        ]

        if let categoryId = categoryId { dict["category_id"] = categoryId }
        if let priceRange = priceRange { dict["price_range"] = priceRange }
        if let location = location { dict["location"] = location }
        if let filters = filters { dict["filters"] = filters }
        if let clickedListingId = clickedListingId { dict["clicked_listing_id"] = clickedListingId }

        return dict
    }
}

private struct RecommendationEvent {
    let listingId: String
    let recommendationType: String
    let recommendationScore: Double?
    let position: Int
    let wasViewed: Bool
    let wasClicked: Bool
    let wasFavorited: Bool
    let viewDurationSeconds: Int?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "listing_id": listingId,
            "recommendation_type": recommendationType,
            "position": position,
            "was_viewed": wasViewed,
            "was_clicked": wasClicked,
            "was_favorited": wasFavorited
        ]

        if let score = recommendationScore { dict["recommendation_score"] = score }
        if let duration = viewDurationSeconds { dict["view_duration_seconds"] = duration }

        return dict
    }
}

private struct SessionStats {
    var listingsViewed = 0
    var searchesPerformed = 0
    var favoritesAdded = 0
    var messagesSent = 0
}
