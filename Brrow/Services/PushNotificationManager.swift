//
//  PushNotificationManager.swift
//  Brrow
//
//  Manages push notifications for the app
//

import Foundation
import UserNotifications
import UIKit

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var isAuthorized = false
    @Published var deviceToken: String?
    @Published var notificationSettings: NotificationSettings?
    @Published var unreadCount = 0
    @Published var notifications: [AppNotification] = []
    
    private let authManager = AuthManager.shared
    private let apiClient = APIClient.shared
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Setup & Permissions
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.registerForRemoteNotifications()
                }
                
                if let error = error {
                    print("Notification authorization error: \(error)")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
                if settings.authorizationStatus == .authorized {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Device Token Management
    
    func registerDeviceToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        
        // Send to server
        Task {
            await registerTokenWithServer(token)
        }
    }
    
    private func registerTokenWithServer(_ token: String) async {
        guard authManager.isAuthenticated else { return }
        
        do {
            let deviceInfo: [String: Any] = [
                "device_token": token,
                "device_type": "ios",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                "os_version": UIDevice.current.systemVersion,
                "device_model": UIDevice.current.model
            ]
            
            _ = try await apiClient.registerDeviceToken(deviceInfo)
            print("Device token registered successfully")
        } catch {
            print("Failed to register device token: \(error)")
        }
    }
    
    func handleRegistrationError(_ error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Notification Preferences
    
    func loadNotificationPreferences() async {
        do {
            let preferences = try await apiClient.getNotificationPreferences()
            await MainActor.run {
                self.notificationSettings = preferences
            }
        } catch {
            print("Failed to load notification preferences: \(error)")
        }
    }
    
    func updateNotificationPreferences(_ preferences: [String: Any]) async {
        do {
            _ = try await apiClient.updateNotificationPreferences(preferences)
            await loadNotificationPreferences()
        } catch {
            print("Failed to update notification preferences: \(error)")
        }
    }
    
    // MARK: - Fetch Notifications
    
    func fetchNotifications(type: String = "all", limit: Int = 20, offset: Int = 0) async {
        do {
            let response = try await apiClient.getNotifications(type: type, limit: limit, offset: offset)
            
            await MainActor.run {
                if offset == 0 {
                    self.notifications = response.notifications
                } else {
                    self.notifications.append(contentsOf: response.notifications)
                }
                self.unreadCount = response.unreadCount
            }
            
            // Update badge
            updateBadgeCount(response.unreadCount)
        } catch {
            print("Failed to fetch notifications: \(error)")
        }
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(notificationId: String) async {
        do {
            _ = try await apiClient.markNotificationAsRead(notificationId: notificationId)
            
            await MainActor.run {
                if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                    notifications[index].isRead = true
                }
                unreadCount = max(0, unreadCount - 1)
            }
            
            updateBadgeCount(unreadCount)
        } catch {
            print("Failed to mark notification as read: \(error)")
        }
    }
    
    func markAllAsRead() async {
        do {
            _ = try await apiClient.markAllNotificationsAsRead()
            
            await MainActor.run {
                for i in notifications.indices {
                    notifications[i].isRead = true
                }
                unreadCount = 0
            }
            
            updateBadgeCount(0)
        } catch {
            print("Failed to mark all notifications as read: \(error)")
        }
    }
    
    // MARK: - Badge Management
    
    private func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Handle Notification Actions
    
    func handleNotificationAction(_ notification: AppNotification) {
        // Navigate based on notification type
        switch notification.type.uppercased() {  // CRITICAL FIX: Backend sends uppercase types
        case "RENTAL_REQUEST", "RENTAL_ACCEPTED", "RENTAL_REJECTED":
            if let transactionId = notification.data["transaction_id"] as? String {
                navigateToRental(transactionId: transactionId)
            }

        case "MESSAGE":  // CRITICAL FIX: Backend sends "MESSAGE" not "message"
            // CRITICAL FIX: Backend sends "chatId" not "conversation_id"
            if let chatId = notification.data["chatId"] as? String {
                navigateToConversation(conversationId: chatId)
            }

        case "NEW_LISTING":
            if let listingId = notification.data["listing_id"] as? String {
                navigateToListing(listingId: listingId)
            }

        case "GARAGE_SALE":
            if let saleId = notification.data["sale_id"] as? String {
                navigateToGarageSale(saleId: saleId)
            }

        default:
            break
        }
    }
    
    private func navigateToRental(transactionId: String) {
        NotificationCenter.default.post(
            name: .navigateToRental,
            object: nil,
            userInfo: ["transactionId": transactionId]
        )
    }
    
    private func navigateToConversation(conversationId: String) {
        // CRITICAL FIX: Post .navigateToChat (not .navigateToConversation)
        // because NativeMainTabView listens for .navigateToChat
        NotificationCenter.default.post(
            name: .navigateToChat,
            object: nil,
            userInfo: ["chatId": conversationId]  // Changed key from conversationId to chatId
        )
    }
    
    private func navigateToListing(listingId: String) {
        NotificationCenter.default.post(
            name: .navigateToListing,
            object: nil,
            userInfo: ["listingId": listingId]
        )
    }
    
    private func navigateToGarageSale(saleId: String) {
        NotificationCenter.default.post(
            name: .navigateToGarageSale,
            object: nil,
            userInfo: ["saleId": saleId]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
        
        // Refresh notifications
        Task {
            await fetchNotifications()
        }
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        // Parse notification data
        if let data = userInfo["data"] as? [String: Any],
           let type = userInfo["type"] as? String {
            
            let notification = AppNotification(
                id: UUID().uuidString,
                type: type,
                title: response.notification.request.content.title,
                message: response.notification.request.content.body,
                data: data,
                isRead: false,
                createdAt: Date()
            )
            
            handleNotificationAction(notification)
        }
        
        completionHandler()
    }
}

// MARK: - Models

struct AppNotification: Identifiable, Codable {
    let id: String
    let type: String
    let title: String
    let message: String
    let data: [String: Any]
    var isRead: Bool
    let icon: String?
    let actionUrl: String?
    let timeAgo: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, message, data, icon
        case isRead = "is_read"
        case actionUrl = "action_url"
        case timeAgo = "time_ago"
        case createdAt = "created_at"
    }
    
    init(id: String, type: String, title: String, message: String, data: [String: Any], isRead: Bool, icon: String? = nil, actionUrl: String? = nil, timeAgo: String? = nil, createdAt: Date) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.data = data
        self.isRead = isRead
        self.icon = icon
        self.actionUrl = actionUrl
        self.timeAgo = timeAgo
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        actionUrl = try container.decodeIfPresent(String.self, forKey: .actionUrl)
        timeAgo = try container.decodeIfPresent(String.self, forKey: .timeAgo)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Decode data as Any
        if let dataString = try? container.decode(String.self, forKey: .data),
           let dataObject = dataString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: dataObject) as? [String: Any] {
            data = json
        } else {
            data = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(isRead, forKey: .isRead)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(actionUrl, forKey: .actionUrl)
        try container.encodeIfPresent(timeAgo, forKey: .timeAgo)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Encode data as JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            try container.encode(jsonString, forKey: .data)
        }
    }
}

// These notification structs are now defined in NotificationModels.swift
// Removing duplicates to avoid ambiguity

struct NotificationSettingsPrefs: Codable {
    let emailNotifications: Bool
    let pushEnabled: Bool
    let quietHours: QuietHours
    
    enum CodingKeys: String, CodingKey {
        case emailNotifications = "email_notifications"
        case pushEnabled = "push_enabled"
        case quietHours = "quiet_hours"
    }
}

struct QuietHours: Codable {
    let enabled: Bool
    let start: String
    let end: String
}

struct NotificationStatistics: Codable {
    let totalNotifications: Int
    let unreadCount: Int
    let lastNotification: String?
    let activeDevices: Int
    let lastDeviceActivity: String?
    
    enum CodingKeys: String, CodingKey {
        case totalNotifications = "total_notifications"
        case unreadCount = "unread_count"
        case lastNotification = "last_notification"
        case activeDevices = "active_devices"
        case lastDeviceActivity = "last_device_activity"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToRental = Notification.Name("navigateToRental")
    static let navigateToConversation = Notification.Name("navigateToConversation")
    static let navigateToListing = Notification.Name("navigateToListing")
    static let navigateToGarageSale = Notification.Name("navigateToGarageSale")
}