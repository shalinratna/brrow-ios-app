//
//  SmartNotificationService.swift
//  Brrow
//
//  Production-ready smart notification service with rate limiting, grouping, and quiet hours
//

import Foundation
import UserNotifications

@MainActor
class SmartNotificationService: ObservableObject {
    static let shared = SmartNotificationService()

    @Published var preferences: NotificationPreferences?
    @Published var rateLimitStatus: RateLimitStatus?

    private let apiClient = APIClient.shared
    private var notificationQueue: [PendingNotification] = []
    private var sentNotifications: [SentNotificationRecord] = []

    // MARK: - Initialization

    private init() {
        loadPreferences()
        scheduleHousekeeper()
    }

    // MARK: - Preferences Management

    func loadPreferences() {
        Task {
            do {
                guard let currentUser = AuthManager.shared.currentUser else {
                    print("⚠️ [SmartNotificationService] No current user, cannot load preferences")
                    return
                }

                let response = try await apiClient.performRequest(
                    endpoint: "api/notifications/preferences",
                    method: "GET",
                    responseType: NotificationPreferencesResponse.self
                )

                if response.success, let prefs = response.data {
                    await MainActor.run {
                        self.preferences = prefs
                        print("✅ [SmartNotificationService] Loaded notification preferences")
                    }
                }
            } catch {
                print("❌ [SmartNotificationService] Failed to load preferences: \(error)")
            }
        }
    }

    func savePreferences(_ prefs: NotificationPreferences) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(prefs)

        let response = try await apiClient.performRequest(
            endpoint: "api/notifications/preferences",
            method: "PUT",
            body: data,
            responseType: NotificationPreferencesResponse.self
        )

        if response.success, let updated = response.data {
            await MainActor.run {
                self.preferences = updated
            }
        }
    }

    // MARK: - Smart Notification Sending

    /// Send a notification with smart rate limiting, grouping, and quiet hours
    func sendNotification(
        type: String,
        title: String,
        body: String,
        category: NotificationCategory = .general,
        priority: NotificationPriority = .normal,
        payload: [String: String]? = nil
    ) async {
        guard let prefs = preferences else {
            print("⚠️ [SmartNotificationService] No preferences loaded, using defaults")
            await sendNotificationDirect(title: title, body: body, payload: payload)
            return
        }

        // Check if category is enabled
        guard isCategoryEnabled(category, in: prefs) else {
            print("🔕 [SmartNotificationService] Category \(category.rawValue) is disabled")
            return
        }

        // Check quiet hours
        if isQuietHours(in: prefs) && !isException(category: category, in: prefs) {
            print("🌙 [SmartNotificationService] Quiet hours active, queuing notification")
            queueNotification(type: type, title: title, body: body, category: category, priority: priority, payload: payload)
            return
        }

        // Check rate limits
        if isRateLimited(in: prefs) {
            print("⏱ [SmartNotificationService] Rate limit exceeded, queuing notification")
            queueNotification(type: type, title: title, body: body, category: category, priority: priority, payload: payload)
            return
        }

        // Check if should group
        if prefs.groupSimilarNotifications {
            if let grouped = tryGroupNotification(type: type, title: title, body: body, category: category, in: prefs) {
                print("📦 [SmartNotificationService] Grouped notification with existing")
                return
            }
        }

        // Send notification
        await sendNotificationDirect(title: title, body: body, payload: payload)
        recordNotification(type: type, category: category)
    }

    // MARK: - Rate Limiting

    private func isRateLimited(in prefs: NotificationPreferences) -> Bool {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)

        // Count notifications in last hour
        let hourCount = sentNotifications.filter { $0.sentAt >= oneHourAgo }.count
        if hourCount >= prefs.maxNotificationsPerHour {
            print("⚠️ [SmartNotificationService] Hourly limit exceeded: \(hourCount)/\(prefs.maxNotificationsPerHour)")
            return true
        }

        // Count notifications in last day
        let dayCount = sentNotifications.filter { $0.sentAt >= oneDayAgo }.count
        if dayCount >= prefs.maxNotificationsPerDay {
            print("⚠️ [SmartNotificationService] Daily limit exceeded: \(dayCount)/\(prefs.maxNotificationsPerDay)")
            return true
        }

        // Update rate limit status
        rateLimitStatus = RateLimitStatus(
            hourlyUsed: hourCount,
            hourlyLimit: prefs.maxNotificationsPerHour,
            dailyUsed: dayCount,
            dailyLimit: prefs.maxNotificationsPerDay
        )

        return false
    }

    private func recordNotification(type: String, category: NotificationCategory) {
        let record = SentNotificationRecord(
            type: type,
            category: category,
            sentAt: Date()
        )
        sentNotifications.append(record)
    }

    // MARK: - Quiet Hours

    private func isQuietHours(in prefs: NotificationPreferences) -> Bool {
        guard prefs.quietHoursEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

        let startComponents = parseTime(prefs.quietHoursStart)
        let endComponents = parseTime(prefs.quietHoursEnd)

        guard let nowMinutes = nowComponents.hour.map({ $0 * 60 + (nowComponents.minute ?? 0) }),
              let startMinutes = startComponents.0.map({ $0 * 60 + startComponents.1 }),
              let endMinutes = endComponents.0.map({ $0 * 60 + endComponents.1 }) else {
            return false
        }

        // Handle overnight quiet hours (e.g., 22:00 to 08:00)
        if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        } else {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }
    }

    private func isException(category: NotificationCategory, in prefs: NotificationPreferences) -> Bool {
        return prefs.quietHoursExceptions.contains(category.rawValue)
    }

    private func parseTime(_ timeString: String) -> (Int?, Int) {
        let components = timeString.split(separator: ":").map { Int($0) }
        return (components.first ?? nil, components.last ?? 0)
    }

    // MARK: - Grouping

    private func tryGroupNotification(
        type: String,
        title: String,
        body: String,
        category: NotificationCategory,
        in prefs: NotificationPreferences
    ) -> Bool {
        let windowStart = Date().addingTimeInterval(-Double(prefs.groupingWindowMinutes * 60))

        // Find similar recent notifications
        let similarNotifications = sentNotifications.filter { record in
            record.type == type &&
            record.category == category &&
            record.sentAt >= windowStart
        }

        if similarNotifications.count > 0 {
            // Update existing notification with grouped count
            let groupedTitle = "\(title) (\(similarNotifications.count + 1) new)"
            Task {
                await sendNotificationDirect(title: groupedTitle, body: body, payload: nil)
            }
            return true
        }

        return false
    }

    // MARK: - Queuing

    private func queueNotification(
        type: String,
        title: String,
        body: String,
        category: NotificationCategory,
        priority: NotificationPriority,
        payload: [String: String]?
    ) {
        let pending = PendingNotification(
            type: type,
            title: title,
            body: body,
            category: category,
            priority: priority,
            payload: payload,
            queuedAt: Date()
        )
        notificationQueue.append(pending)

        // Process queue if high priority
        if priority == .high {
            Task {
                await processQueue()
            }
        }
    }

    private func processQueue() async {
        guard let prefs = preferences else { return }

        // Sort by priority and time
        notificationQueue.sort { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority.rawValue > rhs.priority.rawValue
            }
            return lhs.queuedAt < rhs.queuedAt
        }

        var processed: [String] = []

        for notification in notificationQueue {
            // Check if quiet hours ended
            if isQuietHours(in: prefs) && !isException(category: notification.category, in: prefs) {
                continue
            }

            // Check rate limit
            if isRateLimited(in: prefs) {
                break
            }

            // Send notification
            await sendNotificationDirect(
                title: notification.title,
                body: notification.body,
                payload: notification.payload
            )
            recordNotification(type: notification.type, category: notification.category)

            processed.append(notification.id.uuidString)
        }

        // Remove processed notifications
        notificationQueue.removeAll { processed.contains($0.id.uuidString) }
    }

    // MARK: - Direct Sending

    private func sendNotificationDirect(title: String, body: String, payload: [String: String]?) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let payload = payload {
            content.userInfo = payload
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ [SmartNotificationService] Sent notification: \(title)")
        } catch {
            print("❌ [SmartNotificationService] Failed to send notification: \(error)")
        }
    }

    // MARK: - Category Enablement

    private func isCategoryEnabled(_ category: NotificationCategory, in prefs: NotificationPreferences) -> Bool {
        guard prefs.pushNotificationsEnabled else { return false }

        switch category {
        case .messages:
            return prefs.messages.push
        case .transactions:
            return prefs.transactions.push
        case .listings:
            return prefs.listings.push
        case .reviews:
            return prefs.reviews.push
        case .social:
            return prefs.social.push
        case .security:
            return prefs.security.push
        case .marketing:
            return prefs.marketing.push
        case .general:
            return true
        }
    }

    // MARK: - Housekeeping

    private func scheduleHousekeeper() {
        // Clean up old records every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.cleanupOldRecords()
        }
    }

    private func cleanupOldRecords() {
        let twoDaysAgo = Date().addingTimeInterval(-172800)
        sentNotifications.removeAll { $0.sentAt < twoDaysAgo }
        notificationQueue.removeAll { $0.queuedAt < twoDaysAgo }
        print("🧹 [SmartNotificationService] Cleaned up old notification records")
    }
}

// MARK: - Supporting Models

enum NotificationCategory: String {
    case messages
    case transactions
    case listings
    case reviews
    case social
    case security
    case marketing
    case general
}

enum NotificationPriority: Int {
    case low = 1
    case normal = 2
    case high = 3
}

struct PendingNotification: Identifiable {
    let id = UUID()
    let type: String
    let title: String
    let body: String
    let category: NotificationCategory
    let priority: NotificationPriority
    let payload: [String: String]?
    let queuedAt: Date
}

struct SentNotificationRecord {
    let type: String
    let category: NotificationCategory
    let sentAt: Date
}

struct RateLimitStatus {
    let hourlyUsed: Int
    let hourlyLimit: Int
    let dailyUsed: Int
    let dailyLimit: Int

    var hourlyRemaining: Int { max(0, hourlyLimit - hourlyUsed) }
    var dailyRemaining: Int { max(0, dailyLimit - dailyUsed) }
}

struct NotificationPreferencesResponse: Codable {
    let success: Bool
    let data: NotificationPreferences?
    let message: String?
}
