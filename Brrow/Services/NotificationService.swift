//
//  NotificationService.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import UserNotifications
import UIKit
import Combine

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var hasPermission = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        // Configure notification categories first
        configureNotificationCategories()
        
        // Request authorization with all options including time-sensitive
        var authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        
        // Add time-sensitive notifications for iOS 15+
        if #available(iOS 15.0, *) {
            authOptions.insert(.timeSensitive)
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if let error = error {
                    self?.error = error.localizedDescription
                }
                
                if granted {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func configureNotificationCategories() {
        // Conversation category with reply action
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message..."
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )
        
        let conversationCategory = UNNotificationCategory(
            identifier: "CONVERSATION",
            actions: [replyAction, viewAction],
            intentIdentifiers: [],
            options: [.allowInCarPlay]
        )
        
        // Time-sensitive category for urgent notifications
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_ACTION",
            title: "Accept",
            options: [.foreground]
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_ACTION",
            title: "Decline",
            options: [.destructive]
        )
        
        let timeSensitiveCategory = UNNotificationCategory(
            identifier: "TIME_SENSITIVE",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: [.allowInCarPlay, .hiddenPreviewsShowTitle]
        )
        
        // Regular notification category
        let regularCategory = UNNotificationCategory(
            identifier: "REGULAR",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Set categories
        UNUserNotificationCenter.current().setNotificationCategories([
            conversationCategory,
            timeSensitiveCategory,
            regularCategory
        ])
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func handleDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Update device token on server
        let payload = [
            "device_token": tokenString,
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        
        APIClient.shared.post(endpoint: "update_device_token.php", parameters: payload)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        // Track notification received
        let event = AnalyticsEvent(
            eventName: "notification_received",
            eventType: "notification",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "notification_type": type,
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Handle different notification types
        switch type {
        case "new_match":
            guard let seekId = userInfo["seek_id"] as? String else { return }
            NotificationCenter.default.post(name: .newSeekMatch, object: nil, userInfo: ["seekId": seekId])
            
        case "new_message", "conversation":
            guard let conversationId = userInfo["conversation_id"] as? String else { return }
            NotificationCenter.default.post(name: .newMessage, object: nil, userInfo: ["conversationId": conversationId])
            
        case "rental_request", "rental_accepted", "rental_declined":
            // Time-sensitive rental notifications
            guard let listingId = userInfo["listing_id"] as? String else { return }
            NotificationCenter.default.post(name: .rentalUpdate, object: nil, userInfo: ["listingId": listingId, "type": type])
            
        case "payment_received", "payment_sent":
            // Time-sensitive payment notifications
            guard let transactionId = userInfo["transaction_id"] as? String else { return }
            NotificationCenter.default.post(name: .paymentUpdate, object: nil, userInfo: ["transactionId": transactionId, "type": type])
            
        case "offer_update":
            guard let offerId = userInfo["offer_id"] as? String else { return }
            NotificationCenter.default.post(name: .offerUpdate, object: nil, userInfo: ["offerId": offerId])
            
        case "transaction_update":
            guard let transactionId = userInfo["transaction_id"] as? String else { return }
            NotificationCenter.default.post(name: .transactionUpdate, object: nil, userInfo: ["transactionId": transactionId])
            
        default:
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        
        // Handle notification
        handleNotification(notification.request.content.userInfo)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        handleNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
}

// Notification names are already defined in Notification+Extensions.swift