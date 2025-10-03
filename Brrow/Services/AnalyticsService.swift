//
//  AnalyticsService.swift
//  Brrow
//
//  Analytics tracking service - Fire and forget
//  Tracks user actions, engagement, and errors
//

import Foundation
import UIKit

class AnalyticsService {
    static let shared = AnalyticsService()

    private let apiClient = APIClient.shared
    private var sessionId: String
    private var eventQueue: [AnalyticsEvent] = []
    private let queueLimit = 50
    private var isOffline = false

    private init() {
        // Generate unique session ID
        sessionId = UUID().uuidString

        // Monitor network status
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange),
            name: NSNotification.Name("NetworkStatusChanged"),
            object: nil
        )
    }

    // MARK: - Public Tracking Methods

    /// Track a custom event with optional properties
    func track(event: String, properties: [String: Any]? = nil) {
        let userId = AuthManager.shared.currentUser?.id

        let analyticsEvent = AnalyticsEvent(
            eventName: event,
            eventType: determineEventType(event),
            userId: userId,
            sessionId: sessionId,
            metadata: properties
        )

        sendEvent(analyticsEvent)
    }

    /// Track screen view
    func trackScreen(name: String) {
        track(event: "screen_view", properties: [
            "screen_name": name,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }

    /// Track user action (button tap, swipe, etc.)
    func trackUserAction(action: String, target: String, properties: [String: Any]? = nil) {
        var metadata = properties ?? [:]
        metadata["action"] = action
        metadata["target"] = target

        track(event: "user_action", properties: metadata)
    }

    /// Track listing view
    func trackListingView(listingId: String, listingTitle: String?) {
        track(event: "listing_viewed", properties: [
            "listing_id": listingId,
            "listing_title": listingTitle ?? "Unknown"
        ])
    }

    /// Track search query
    func trackSearch(query: String, resultsCount: Int) {
        track(event: "search_performed", properties: [
            "query": query,
            "results_count": resultsCount
        ])
    }

    /// Track listing creation
    func trackListingCreated(listingId: String, category: String?, price: Double?) {
        track(event: "listing_created", properties: [
            "listing_id": listingId,
            "category": category ?? "Unknown",
            "price": price ?? 0
        ])
    }

    /// Track favorite action
    func trackFavorite(listingId: String, action: String) {
        track(event: "listing_favorited", properties: [
            "listing_id": listingId,
            "action": action // "add" or "remove"
        ])
    }

    /// Track message sent
    func trackMessageSent(messageType: String, conversationId: String) {
        track(event: "message_sent", properties: [
            "message_type": messageType,
            "conversation_id": conversationId
        ])
    }

    /// Track offer action
    func trackOfferAction(action: String, amount: Double, listingId: String?) {
        track(event: "offer_\(action)", properties: [
            "action": action, // "made", "accepted", "rejected", "countered"
            "amount": amount,
            "listing_id": listingId ?? "unknown"
        ])
    }

    /// Track payment action
    func trackPayment(action: String, amount: Double, status: String) {
        track(event: "payment_\(action)", properties: [
            "action": action, // "initiated", "succeeded", "failed"
            "amount": amount,
            "status": status
        ])
    }

    /// Track authentication events
    func trackAuth(action: String, method: String? = nil) {
        track(event: "auth_\(action)", properties: [
            "action": action, // "login", "logout", "signup"
            "method": method ?? "email" // "email", "google", "apple"
        ])
    }

    /// Track profile view
    func trackProfileView(userId: String, username: String?) {
        track(event: "profile_viewed", properties: [
            "profile_id": userId,
            "username": username ?? "unknown"
        ])
    }

    /// Track tab switch
    func trackTabSwitch(from: String, to: String) {
        track(event: "tab_switched", properties: [
            "from_tab": from,
            "to_tab": to
        ])
    }

    /// Track error
    func trackError(error: Error, context: String) {
        track(event: "error_occurred", properties: [
            "error_message": error.localizedDescription,
            "error_type": String(describing: type(of: error)),
            "context": context
        ])
    }

    /// Track app opened
    func trackAppOpened(source: String = "unknown") {
        track(event: "app_opened", properties: [
            "source": source, // "direct", "notification", "deeplink"
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "os_version": UIDevice.current.systemVersion
        ])
    }

    /// Track feature usage
    func trackFeatureUsed(feature: String, properties: [String: Any]? = nil) {
        var metadata = properties ?? [:]
        metadata["feature"] = feature

        track(event: "feature_used", properties: metadata)
    }

    // MARK: - Private Methods

    private func determineEventType(_ eventName: String) -> String {
        // Categorize events for better analytics grouping
        if eventName.contains("screen_view") || eventName.contains("tab_switched") {
            return "navigation"
        } else if eventName.contains("listing") {
            return "listing"
        } else if eventName.contains("message") || eventName.contains("chat") {
            return "messaging"
        } else if eventName.contains("payment") || eventName.contains("transaction") {
            return "payment"
        } else if eventName.contains("search") {
            return "search"
        } else if eventName.contains("auth") || eventName.contains("login") || eventName.contains("signup") {
            return "authentication"
        } else if eventName.contains("error") {
            return "error"
        } else if eventName.contains("offer") {
            return "offer"
        } else {
            return "general"
        }
    }

    private func sendEvent(_ event: AnalyticsEvent) {
        // Add to queue if offline
        if isOffline {
            queueEvent(event)
            return
        }

        // Send to backend (fire and forget)
        Task {
            do {
                let bodyData = try JSONEncoder().encode(event)

                // Use the public trackEvent endpoint
                struct TrackEventRequest: Codable {
                    let event_type: String
                    let metadata: [String: String]?
                }

                // Convert metadata to String dictionary for API
                var metadataDict: [String: String]?
                if let metadata = event.metadata {
                    metadataDict = metadata.mapValues { String(describing: $0) }
                }

                let request = TrackEventRequest(
                    event_type: event.eventName,
                    metadata: metadataDict
                )

                let requestData = try JSONEncoder().encode(request)

                _ = try await apiClient.performRequest(
                    endpoint: "api/analytics/track",
                    method: "POST",
                    body: requestData,
                    responseType: APIResponse<EmptyData>.self
                )

                debugLog("Analytics event sent: \(event.eventName)")
            } catch {
                // Silent fail - analytics shouldn't break the app
                debugLog("Failed to send analytics event: \(error.localizedDescription)")
                queueEvent(event)
            }
        }
    }

    private func queueEvent(_ event: AnalyticsEvent) {
        eventQueue.append(event)

        // Limit queue size
        if eventQueue.count > queueLimit {
            eventQueue.removeFirst()
        }

        // Save to UserDefaults for persistence
        saveQueue()
    }

    private func flushQueue() {
        guard !eventQueue.isEmpty else { return }

        let eventsToSend = eventQueue
        eventQueue.removeAll()
        saveQueue()

        Task {
            for event in eventsToSend {
                sendEvent(event)
            }
        }
    }

    private func saveQueue() {
        // Save queued events to UserDefaults
        if let encoded = try? JSONEncoder().encode(eventQueue) {
            UserDefaults.standard.set(encoded, forKey: "AnalyticsQueue")
        }
    }

    private func loadQueue() {
        // Load queued events from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "AnalyticsQueue"),
           let decoded = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) {
            eventQueue = decoded
        }
    }

    @objc private func handleNetworkChange(_ notification: Notification) {
        if let isOnline = notification.userInfo?["isOnline"] as? Bool {
            isOffline = !isOnline

            if isOnline {
                // Flush queued events when back online
                flushQueue()
            }
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("📊 [Analytics] \(message)")
        #endif
    }
}

// MARK: - Empty Data Response Type

struct EmptyData: Codable {
    // Empty struct for endpoints that don't return data
}
