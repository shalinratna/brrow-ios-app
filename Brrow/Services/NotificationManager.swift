//
//  NotificationManager.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Push notification management service using OneSignal
//

import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Notification Data
struct PushNotificationData {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let payload: [String: Any]
    let imageUrl: String?
    let actionUrl: String?
    let timestamp: Date
    
    init(type: NotificationType, title: String? = nil, body: String, payload: [String: Any] = [:], imageUrl: String? = nil, actionUrl: String? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title ?? type.title
        self.body = body
        self.payload = payload
        self.imageUrl = imageUrl
        self.actionUrl = actionUrl
        self.timestamp = Date()
    }
}

// MARK: - Notification Manager
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notificationSettings = NotificationSettings.default
    @Published var isRegistered = false
    @Published var hasPermission = false
    @Published var deviceToken: String?
    @Published var unreadCount = 0
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "notification_settings"
    private var cancellables = Set<AnyCancellable>()
    
    // OneSignal Configuration
    // Brrow Production OneSignal App ID
    private let oneSignalAppId = "ebb64d61-971c-4415-8ca3-53aa7b4a2ca0"
    
    override init() {
        super.init()
        loadSettings()
        setupNotificationCenter()
    }
    
    // MARK: - Initialization
    
    func initialize() {
        requestPermission()
        registerForNotifications()
        setupNotificationHandling()
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Management
    
    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if granted {
                    self?.registerForNotifications()
                }
                completion(granted)
            }
            
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func checkPermissionStatus() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }
        }
    }
    
    // MARK: - Registration
    
    private func registerForNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        self.isRegistered = true
        
        // Send token to server
        registerDeviceWithServer(token: tokenString)
    }
    
    func handleRegistrationError(_ error: Error) {
        print("Failed to register for notifications: \(error)")
        self.isRegistered = false
    }
    
    // MARK: - Server Integration
    
    private func registerDeviceWithServer(token: String) {
        guard let user = AuthManager.shared.currentUser else { return }
        
        let parameters: [String: Any] = [
            "user_api_id": user.apiId,
            "device_token": token,
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "device_model": UIDevice.current.model,
            "os_version": UIDevice.current.systemVersion
        ]
        
        // API call to register device token
        Task {
            do {
                let _ = try await APIClient.shared.registerDeviceToken(parameters: parameters)
                print("Device token registered successfully")
            } catch {
                print("Failed to register device token: \(error)")
            }
        }
    }
    
    // MARK: - Notification Sending
    
    func sendLocalNotification(_ data: PushNotificationData) {
        guard notificationSettings.isEnabled else { return }
        
        // Check notification type permissions
        if !shouldShowNotification(type: data.type) {
            return
        }
        
        // Check quiet hours
        if isInQuietHours() {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = data.title
        content.body = data.body
        content.userInfo = data.payload
        content.badge = NSNumber(value: unreadCount + 1)
        
        // Add image if available
        if let imageUrl = data.imageUrl {
            addImageToNotification(content: content, imageUrl: imageUrl)
        }
        
        // Set sound
        if data.type.defaultSound != "default" {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(data.type.defaultSound))
        } else {
            content.sound = .default
        }
        
        // Add actions based on type
        content.categoryIdentifier = data.type.rawValue
        
        let request = UNNotificationRequest(
            identifier: data.id,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
        
        // Update unread count
        DispatchQueue.main.async {
            self.unreadCount += 1
        }
    }
    
    private func addImageToNotification(content: UNMutableNotificationContent, imageUrl: String) {
        guard let url = URL(string: imageUrl) else { return }
        
        let task = URLSession.shared.downloadTask(with: url) { location, _, _ in
            guard let location = location else { return }
            
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
            
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: location, to: destinationURL)
                
                if let attachment = try? UNNotificationAttachment(identifier: "image", url: destinationURL, options: nil) {
                    content.attachments = [attachment]
                }
            } catch {
                print("Failed to add image attachment: \(error)")
            }
        }
        task.resume()
    }
    
    // MARK: - Notification Categories & Actions
    
    private func setupNotificationHandling() {
        setupNotificationCategories()
    }
    
    private func setupNotificationCategories() {
        let messageCategory = createMessageCategory()
        let rentalCategory = createRentalCategory()
        let achievementCategory = createAchievementCategory()
        
        UNUserNotificationCenter.current().setNotificationCategories([
            messageCategory,
            rentalCategory,
            achievementCategory
        ])
    }
    
    private func createMessageCategory() -> UNNotificationCategory {
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [.foreground],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message..."
        )
        
        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ_ACTION",
            title: "Mark as Read",
            options: []
        )
        
        return UNNotificationCategory(
            identifier: NotificationType.newMessage.rawValue,
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }
    
    private func createRentalCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_RENTAL_ACTION",
            title: "View Details",
            options: [.foreground]
        )
        
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_RENTAL_ACTION",
            title: "Accept",
            options: [.foreground]
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_RENTAL_ACTION",
            title: "Decline",
            options: []
        )
        
        return UNNotificationCategory(
            identifier: "rental_request",
            actions: [acceptAction, declineAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    private func createAchievementCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACHIEVEMENT_ACTION",
            title: "View Achievement",
            options: [.foreground]
        )
        
        let shareAction = UNNotificationAction(
            identifier: "SHARE_ACHIEVEMENT_ACTION",
            title: "Share",
            options: [.foreground]
        )
        
        return UNNotificationCategory(
            identifier: "achievement_unlocked",
            actions: [viewAction, shareAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    // MARK: - Settings Management
    
    private func shouldShowNotification(type: NotificationType) -> Bool {
        switch type {
        case .newMessage:
            return notificationSettings.newMessages
        case .newOffer, .offerAccepted, .offerDeclined:
            return notificationSettings.rentalUpdates
        case .paymentReceived:
            return notificationSettings.payments
        case .karmaUpdate:
            return notificationSettings.achievements
        case .listingExpiring, .reviewReceived, .transactionUpdate:
            return notificationSettings.nearbyItems
        }
    }
    
    private func isInQuietHours() -> Bool {
        guard notificationSettings.quietHoursEnabled else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startTime = formatter.date(from: notificationSettings.quietHoursStart),
              let endTime = formatter.date(from: notificationSettings.quietHoursEnd) else {
            return false
        }
        
        let currentTime = formatter.date(from: formatter.string(from: now))!
        
        if startTime <= endTime {
            // Same day quiet hours (e.g., 14:00 to 18:00)
            return currentTime >= startTime && currentTime <= endTime
        } else {
            // Overnight quiet hours (e.g., 22:00 to 08:00)
            return currentTime >= startTime || currentTime <= endTime
        }
    }
    
    func updateSettings(_ settings: NotificationSettings) {
        self.notificationSettings = settings
        saveSettings()
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return
        }
        self.notificationSettings = settings
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            self.unreadCount = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Notification History
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }
    
    func clearNotifications(ofType type: NotificationType) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .compactMap { request in
                    if let category = request.content.userInfo["type"] as? String,
                       category == type.rawValue {
                        return request.identifier
                    }
                    return nil
                }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications
                .compactMap { notification in
                    if let category = notification.request.content.userInfo["type"] as? String,
                       category == type.rawValue {
                        return notification.request.identifier
                    }
                    return nil
                }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        handleNotificationAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        switch actionIdentifier {
        case "REPLY_ACTION":
            if let response = userInfo as? UNTextInputNotificationResponse {
                handleReplyAction(text: response.userText, userInfo: userInfo)
            }
            
        case "MARK_READ_ACTION":
            handleMarkReadAction(userInfo: userInfo)
            
        case "VIEW_RENTAL_ACTION":
            handleViewRentalAction(userInfo: userInfo)
            
        case "ACCEPT_RENTAL_ACTION":
            handleAcceptRentalAction(userInfo: userInfo)
            
        case "DECLINE_RENTAL_ACTION":
            handleDeclineRentalAction(userInfo: userInfo)
            
        case "VIEW_ACHIEVEMENT_ACTION":
            handleViewAchievementAction(userInfo: userInfo)
            
        case "SHARE_ACHIEVEMENT_ACTION":
            handleShareAchievementAction(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            handleDefaultAction(userInfo: userInfo)
            
        default:
            break
        }
    }
    
    private func handleReplyAction(text: String, userInfo: [AnyHashable: Any]) {
        // Handle quick reply
        if let conversationId = userInfo["conversation_id"] as? String {
            // Send message through ChatManager
            // ChatManager.shared.sendMessage(text: text, conversationId: conversationId)
        }
    }
    
    private func handleMarkReadAction(userInfo: [AnyHashable: Any]) {
        // Mark message as read
        if let messageId = userInfo["message_id"] as? String {
            // Mark message as read in API
        }
    }
    
    private func handleViewRentalAction(userInfo: [AnyHashable: Any]) {
        // Navigate to rental details
        if let rentalId = userInfo["rental_id"] as? String {
            // Navigate to rental screen
        }
    }
    
    private func handleAcceptRentalAction(userInfo: [AnyHashable: Any]) {
        // Accept rental request
        if let rentalId = userInfo["rental_id"] as? String {
            // Call API to accept rental
        }
    }
    
    private func handleDeclineRentalAction(userInfo: [AnyHashable: Any]) {
        // Decline rental request
        if let rentalId = userInfo["rental_id"] as? String {
            // Call API to decline rental
        }
    }
    
    private func handleViewAchievementAction(userInfo: [AnyHashable: Any]) {
        // Navigate to achievements screen
        // Present achievement detail view
    }
    
    private func handleShareAchievementAction(userInfo: [AnyHashable: Any]) {
        // Share achievement
        if let achievementId = userInfo["achievement_id"] as? String {
            // Share achievement on social media
        }
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        // Handle tap on notification
        if let actionUrl = userInfo["action_url"] as? String {
            // Navigate to specific screen based on URL
        }
    }
}

// MARK: - Convenience Methods
extension NotificationManager {
    
    func sendMessageNotification(from sender: String, message: String, conversationId: String) {
        let data = PushNotificationData(
            type: .newMessage,
            body: message,
            payload: [
                "type": NotificationType.newMessage.rawValue,
                "conversation_id": conversationId,
                "sender": sender
            ]
        )
        sendLocalNotification(data)
    }
    
    func sendRentalRequestNotification(itemTitle: String, requester: String, rentalId: String) {
        let data = PushNotificationData(
            type: .newOffer,
            body: "\(requester) wants to rent your \(itemTitle)",
            payload: [
                "type": "rental_request",
                "rental_id": rentalId,
                "requester": requester
            ]
        )
        sendLocalNotification(data)
    }
    
    func sendAchievementNotification(achievementName: String, achievementId: String) {
        let data = PushNotificationData(
            type: .karmaUpdate,
            body: "You unlocked '\(achievementName)'! 🎉",
            payload: [
                "type": "achievement_unlocked",
                "achievement_id": achievementId
            ]
        )
        sendLocalNotification(data)
    }
    
    func sendPaymentNotification(amount: Double, itemTitle: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let amountString = formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
        
        let data = PushNotificationData(
            type: .paymentReceived,
            body: "You received \(amountString) for \(itemTitle)",
            payload: [
                "type": NotificationType.paymentReceived.rawValue,
                "amount": amount,
                "item_title": itemTitle
            ]
        )
        sendLocalNotification(data)
    }
}