//
//  PushNotificationService.swift
//  Brrow
//
//  Push Notifications Management
//

import Foundation
import UserNotifications
import UIKit

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Configuration
    
    func configure() {
        // Initial configuration - check status, etc.
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .carPlay, .criticalAlert]
            )
            
            await MainActor.run {
                authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Device Token Management
    
    func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        
        // Send token to server
        Task {
            await sendDeviceTokenToServer(tokenString)
        }
    }
    
    private func sendDeviceTokenToServer(_ token: String) async {
        guard let userId = AuthManager.shared.currentUser?.apiId else { return }
        
        do {
            try await APIClient.shared.updateDeviceToken(token: token, userId: userId)
            print("Device token registered successfully")
        } catch {
            print("Failed to register device token: \(error)")
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval = 0,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger = timeInterval > 0 
            ? UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            : nil
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE",
            actions: [
                UNNotificationAction(
                    identifier: "REPLY",
                    title: "Reply",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "MARK_READ",
                    title: "Mark as Read",
                    options: [.destructive]
                )
            ],
            intentIdentifiers: []
        )
        
        let borrowRequestCategory = UNNotificationCategory(
            identifier: "BORROW_REQUEST",
            actions: [
                UNNotificationAction(
                    identifier: "ACCEPT",
                    title: "Accept",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DECLINE",
                    title: "Decline",
                    options: [.destructive]
                )
            ],
            intentIdentifiers: []
        )
        
        let paymentCategory = UNNotificationCategory(
            identifier: "PAYMENT",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_EARNINGS",
                    title: "View Earnings",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: []
        )
        
        notificationCenter.setNotificationCategories([
            messageCategory,
            borrowRequestCategory,
            paymentCategory
        ])
    }
    
    // MARK: - Badge Management
    
    func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        setBadgeCount(0)
    }
    
    // MARK: - Notification Types
    
    enum NotificationType: String, CaseIterable {
        case newMessage = "new_message"
        case borrowRequest = "borrow_request"
        case borrowApproved = "borrow_approved"
        case borrowDeclined = "borrow_declined"
        case paymentReceived = "payment_received"
        case itemReturned = "item_returned"
        case reviewReceived = "review_received"
        case itemAvailable = "item_available"
        case reminderReturn = "reminder_return"
        case reminderPickup = "reminder_pickup"
        
        var title: String {
            switch self {
            case .newMessage: return "New Message"
            case .borrowRequest: return "Borrow Request"
            case .borrowApproved: return "Request Approved"
            case .borrowDeclined: return "Request Declined"
            case .paymentReceived: return "Payment Received"
            case .itemReturned: return "Item Returned"
            case .reviewReceived: return "New Review"
            case .itemAvailable: return "Item Available"
            case .reminderReturn: return "Return Reminder"
            case .reminderPickup: return "Pickup Reminder"
            }
        }
        
        var category: String {
            switch self {
            case .newMessage: return "MESSAGE"
            case .borrowRequest: return "BORROW_REQUEST"
            case .paymentReceived: return "PAYMENT"
            default: return "GENERAL"
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func sendNewMessageNotification(from username: String, message: String) {
        scheduleLocalNotification(
            title: "New message from \(username)",
            body: message,
            identifier: "message_\(UUID().uuidString)",
            userInfo: [
                "type": NotificationType.newMessage.rawValue,
                "username": username
            ]
        )
    }
    
    func sendBorrowRequestNotification(from username: String, itemTitle: String) {
        scheduleLocalNotification(
            title: "\(username) wants to borrow your item",
            body: itemTitle,
            identifier: "request_\(UUID().uuidString)",
            userInfo: [
                "type": NotificationType.borrowRequest.rawValue,
                "username": username,
                "item": itemTitle
            ]
        )
    }
    
    func sendPaymentNotification(amount: String, from username: String) {
        scheduleLocalNotification(
            title: "Payment received: \(amount)",
            body: "From \(username)",
            identifier: "payment_\(UUID().uuidString)",
            userInfo: [
                "type": NotificationType.paymentReceived.rawValue,
                "amount": amount,
                "username": username
            ]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification actions
        switch response.actionIdentifier {
        case "REPLY":
            handleReplyAction(userInfo: userInfo)
        case "ACCEPT":
            handleAcceptAction(userInfo: userInfo)
        case "DECLINE":
            handleDeclineAction(userInfo: userInfo)
        case "VIEW_EARNINGS":
            handleViewEarningsAction()
        case UNNotificationDefaultActionIdentifier:
            handleDefaultAction(userInfo: userInfo)
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleReplyAction(userInfo: [AnyHashable: Any]) {
        // Navigate to chat
        NotificationCenter.default.post(
            name: .navigateToChat,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleAcceptAction(userInfo: [AnyHashable: Any]) {
        // Accept borrow request
        NotificationCenter.default.post(
            name: .acceptBorrowRequest,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleDeclineAction(userInfo: [AnyHashable: Any]) {
        // Decline borrow request
        NotificationCenter.default.post(
            name: .declineBorrowRequest,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleViewEarningsAction() {
        // Navigate to earnings
        NotificationCenter.default.post(name: .navigateToEarnings, object: nil)
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String,
              let type = NotificationType(rawValue: typeString) else {
            return
        }
        
        switch type {
        case .newMessage:
            NotificationCenter.default.post(name: .navigateToChat, object: nil, userInfo: userInfo)
        case .borrowRequest:
            NotificationCenter.default.post(name: .navigateToBorrowRequests, object: nil)
        case .paymentReceived:
            NotificationCenter.default.post(name: .navigateToEarnings, object: nil)
        default:
            // Navigate to main app
            break
        }
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let navigateToBorrowRequests = Notification.Name("navigateToBorrowRequests")
    static let acceptBorrowRequest = Notification.Name("acceptBorrowRequest")
    static let declineBorrowRequest = Notification.Name("declineBorrowRequest")
}

// MARK: - API Client Extension

extension APIClient {
    func updateDeviceToken(token: String, userId: String) async throws {
        // Implementation would send token to server
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Device token updated: \(token)")
    }
}