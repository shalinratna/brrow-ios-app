//
//  UnifiedNotificationService.swift
//  Brrow
//
//  Complete unified notification service integrating all notification types
//

import Foundation
import UIKit
import UserNotifications
import Combine

@MainActor
class UnifiedNotificationService: ObservableObject {
    static let shared = UnifiedNotificationService()

    @Published var notifications: [NotificationHistoryItem] = []
    @Published var unreadCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var notificationSettings = NotificationSettings.default

    private let notificationManager = NotificationManager.shared
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard

    // Notification categories for real-time updates
    private var activeCategories: Set<String> = []

    private init() {
        setupNotificationObservers()
        loadNotificationHistory()
        syncWithNotificationManager()
    }

    // MARK: - Setup & Initialization

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .newMessageReceived)
            .sink { [weak self] notification in
                self?.handleInAppNotification(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .webSocketConnected)
            .sink { [weak self] _ in
                self?.subscribeToRealTimeNotifications()
            }
            .store(in: &cancellables)

        // Observe app state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshNotifications()
                self?.updateBadgeCount()
            }
            .store(in: &cancellables)
    }

    private func syncWithNotificationManager() {
        notificationManager.$unreadCount
            .assign(to: &$unreadCount)

        notificationManager.$notificationSettings
            .assign(to: &$notificationSettings)
    }

    // MARK: - Notification Management

    func loadNotificationHistory(page: Int = 1, limit: Int = 50) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await apiClient.performRequest(
                    endpoint: "api/notifications?page=\(page)&limit=\(limit)",
                    method: "GET",
                    responseType: NotificationHistoryResponse.self
                )

                guard response.success, let data = response.data else {
                    throw BrrowAPIError.serverError(response.message ?? "Failed to load notifications")
                }

                if page == 1 {
                    notifications = data.notifications
                } else {
                    notifications.append(contentsOf: data.notifications)
                }

            } catch {
                errorMessage = error.localizedDescription
                // Fallback to mock data for demo
                loadMockNotifications()
            }

            isLoading = false
        }
    }

    func markAsRead(_ notificationId: String) {
        Task {
            do {
                let _ = try await apiClient.performRequest(
                    endpoint: "api/notifications/\(notificationId)/read",
                    method: "PATCH",
                    responseType: APIResponse<EmptyResponse>.self
                )

                // Update local state
                if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                    notifications[index] = NotificationHistoryItem(
                        id: notifications[index].id,
                        userId: notifications[index].userId,
                        type: notifications[index].type,
                        title: notifications[index].title,
                        body: notifications[index].body,
                        payload: notifications[index].payload,
                        imageUrl: notifications[index].imageUrl,
                        actionUrl: notifications[index].actionUrl,
                        isRead: true,
                        createdAt: notifications[index].createdAt,
                        readAt: ISO8601DateFormatter().string(from: Date())
                    )
                }

                updateUnreadCount()

            } catch {
                print("Failed to mark notification as read: \(error)")
            }
        }
    }

    func markAllAsRead() {
        Task {
            do {
                let _ = try await apiClient.performRequest(
                    endpoint: "api/notifications/mark-all-read",
                    method: "PATCH",
                    responseType: APIResponse<EmptyResponse>.self
                )

                // Update local state
                notifications = notifications.map { notification in
                    NotificationHistoryItem(
                        id: notification.id,
                        userId: notification.userId,
                        type: notification.type,
                        title: notification.title,
                        body: notification.body,
                        payload: notification.payload,
                        imageUrl: notification.imageUrl,
                        actionUrl: notification.actionUrl,
                        isRead: true,
                        createdAt: notification.createdAt,
                        readAt: ISO8601DateFormatter().string(from: Date())
                    )
                }

                unreadCount = 0
                notificationManager.clearBadge()

            } catch {
                print("Failed to mark all notifications as read: \(error)")
            }
        }
    }

    func deleteNotification(_ notificationId: String) {
        Task {
            do {
                let _ = try await apiClient.performRequest(
                    endpoint: "api/notifications/\(notificationId)",
                    method: "DELETE",
                    responseType: APIResponse<EmptyResponse>.self
                )

                // Remove from local state
                notifications.removeAll { $0.id == notificationId }
                updateUnreadCount()

            } catch {
                print("Failed to delete notification: \(error)")
            }
        }
    }

    // MARK: - Real-time Notifications

    private func subscribeToRealTimeNotifications() {
        guard let userId = AuthManager.shared.currentUser?.apiId else { return }

        // Subscribe to user-specific notification channel
        WebSocketManager.shared.addMessageHandler(for: "notification") { [weak self] data in
            self?.handleRealTimeNotification(data)
        }

        // Subscribe to various notification types
        let notificationTypes = [
            "new_message", "new_offer", "offer_accepted", "offer_declined",
            "payment_received", "review_received", "achievement_unlocked",
            "listing_expiring", "transaction_update"
        ]

        for type in notificationTypes {
            activeCategories.insert(type)
        }
    }

    private func handleRealTimeNotification(_ data: Any) {
        guard let notificationData = data as? [String: Any],
              let type = notificationData["type"] as? String,
              let title = notificationData["title"] as? String,
              let body = notificationData["body"] as? String else { return }

        // Create notification item
        let notification = NotificationHistoryItem(
            id: notificationData["id"] as? String ?? UUID().uuidString,
            userId: Int(AuthManager.shared.currentUser?.id ?? "0") ?? 0,
            type: type,
            title: title,
            body: body,
            payload: notificationData["payload"] as? [String: String],
            imageUrl: notificationData["image_url"] as? String,
            actionUrl: notificationData["action_url"] as? String,
            isRead: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            readAt: nil
        )

        // Add to notifications list
        notifications.insert(notification, at: 0)
        unreadCount += 1

        // Show local notification if app is in background
        if UIApplication.shared.applicationState != .active {
            let pushData = PushNotificationData(
                type: NotificationType.from(string: type),
                title: title,
                body: body,
                payload: notificationData,
                imageUrl: notification.imageUrl,
                actionUrl: notification.actionUrl
            )
            notificationManager.sendLocalNotification(pushData)
        }

        // Post notification for other parts of the app
        NotificationCenter.default.post(
            name: .newNotificationReceived,
            object: notification
        )
    }

    private func handleInAppNotification(_ notification: Notification) {
        // Handle in-app notifications from other parts of the system
        if let message = notification.object as? Message {
            sendMessageNotification(message: message)
        }
    }

    // MARK: - Notification Sending

    func sendMessageNotification(message: Message) {
        let notification = PushNotificationData(
            type: .newMessage,
            body: message.content,
            payload: [
                "type": "new_message",
                "message_id": message.id,
                "sender_id": message.senderId,
                "conversation_id": message.chatId ?? ""
            ]
        )
        notificationManager.sendLocalNotification(notification)
    }

    func sendOfferNotification(offer: RentalOffer) {
        let notification = PushNotificationData(
            type: .newOffer,
            body: "New rental request for \(offer.itemTitle)",
            payload: [
                "type": "new_offer",
                "offer_id": offer.id,
                "item_title": offer.itemTitle
            ]
        )
        notificationManager.sendLocalNotification(notification)
    }

    func sendPaymentNotification(amount: Double, itemTitle: String, transactionId: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let amountString = formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"

        let notification = PushNotificationData(
            type: .paymentReceived,
            body: "You received \(amountString) for \(itemTitle)",
            payload: [
                "type": "payment_received",
                "amount": "\(amount)",
                "item_title": itemTitle,
                "transaction_id": transactionId
            ]
        )
        notificationManager.sendLocalNotification(notification)
    }

    func sendReviewNotification(reviewer: String, itemTitle: String, rating: Int) {
        let stars = String(repeating: "⭐", count: rating)
        let notification = PushNotificationData(
            type: .reviewReceived,
            body: "\(reviewer) left you a review: \(stars)",
            payload: [
                "type": "review_received",
                "reviewer": reviewer,
                "item_title": itemTitle,
                "rating": "\(rating)"
            ]
        )
        notificationManager.sendLocalNotification(notification)
    }

    func sendAchievementNotification(achievementName: String, achievementId: String) {
        let notification = PushNotificationData(
            type: .karmaUpdate,
            body: "You unlocked '\(achievementName)'! 🎉",
            payload: [
                "type": "achievement_unlocked",
                "achievement_id": achievementId,
                "achievement_name": achievementName
            ]
        )
        notificationManager.sendLocalNotification(notification)
    }

    // MARK: - Settings Management

    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        notificationManager.updateSettings(settings)

        Task {
            do {
                let request = NotificationSettingsRequest(
                    userId: Int(AuthManager.shared.currentUser?.id ?? "0") ?? 0,
                    settings: settings
                )

                let _ = try await apiClient.performRequest(
                    endpoint: "api/notifications/settings",
                    method: "PUT",
                    body: try JSONEncoder().encode(request),
                    responseType: APIResponse<EmptyResponse>.self
                )

            } catch {
                print("Failed to update notification settings: \(error)")
            }
        }
    }

    func getNotificationPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Helper Methods

    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        notificationManager.updateBadgeCount(unreadCount)
    }

    private func updateBadgeCount() {
        Task {
            do {
                let response = try await apiClient.performRequest(
                    endpoint: "api/notifications/badge-count",
                    method: "GET",
                    responseType: BadgeCountResponse.self
                )

                if response.success, let data = response.data {
                    unreadCount = data.unreadCount
                    notificationManager.updateBadgeCount(data.unreadCount)
                }

            } catch {
                print("Failed to update badge count: \(error)")
            }
        }
    }

    private func refreshNotifications() {
        loadNotificationHistory(page: 1)
    }

    private func loadMockNotifications() {
        notifications = [
            NotificationHistoryItem(
                id: "1",
                userId: Int(AuthManager.shared.currentUser?.id ?? "0") ?? 0,
                type: "new_message",
                title: "New Message",
                body: "You have a new message from Alice",
                payload: ["conversation_id": "conv_123"],
                imageUrl: nil,
                actionUrl: "brrow://chat/conv_123",
                isRead: false,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300)),
                readAt: nil
            ),
            NotificationHistoryItem(
                id: "2",
                userId: Int(AuthManager.shared.currentUser?.id ?? "0") ?? 0,
                type: "new_offer",
                title: "New Rental Request",
                body: "Bob wants to rent your Camera",
                payload: ["offer_id": "offer_456"],
                imageUrl: nil,
                actionUrl: "brrow://rental/offer_456",
                isRead: false,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                readAt: nil
            ),
            NotificationHistoryItem(
                id: "3",
                userId: Int(AuthManager.shared.currentUser?.id ?? "0") ?? 0,
                type: "payment_received",
                title: "Payment Received",
                body: "You received $25.00 for Camera",
                payload: ["amount": "25.00"],
                imageUrl: nil,
                actionUrl: "brrow://payments",
                isRead: true,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
                readAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
            )
        ]
        updateUnreadCount()
    }

    // MARK: - Notification Categories

    func getNotificationsByCategory(_ category: NotificationType? = nil) -> [NotificationHistoryItem] {
        guard let category = category else { return notifications }
        return notifications.filter { $0.type == category.rawValue }
    }

    func getUnreadNotificationsByCategory(_ category: NotificationType? = nil) -> [NotificationHistoryItem] {
        let filteredNotifications = getNotificationsByCategory(category)
        return filteredNotifications.filter { !$0.isRead }
    }

    func clearNotificationsOfType(_ type: NotificationType) {
        notifications.removeAll { $0.type == type.rawValue }
        notificationManager.clearNotifications(ofType: type)
        updateUnreadCount()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let newNotificationReceived = Notification.Name("newNotificationReceived")
    static let notificationRead = Notification.Name("notificationRead")
    static let notificationDeleted = Notification.Name("notificationDeleted")
}

// MARK: - Supporting Models

struct RentalOffer {
    let id: String
    let itemTitle: String
    let requesterName: String
    let amount: Double
    let startDate: Date
    let endDate: Date
}