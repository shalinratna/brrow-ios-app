//
//  NotificationModels.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Data models for push notifications and notification history
//

import Foundation

// Using NotificationType enum from Enums.swift
// Extension to add computed properties
extension NotificationType {
    // Map additional notification types to existing cases
    static func from(string: String) -> NotificationType {
        switch string {
        case "rental_request", "borrow_request":
            return .newOffer
        case "rental_accepted", "borrow_accepted":
            return .offerAccepted
        case "rental_declined", "borrow_declined":
            return .offerDeclined
        case "achievement_unlocked", "karma_update":
            return .karmaUpdate
        case "nearby_listing", "new_listing":
            return .newOffer
        case "price_update":
            return .transactionUpdate
        case "reminder":
            return .listingExpiring
        default:
            return NotificationType(rawValue: string) ?? .newMessage
        }
    }
    
    var title: String {
        switch self {
        case .newOffer: return "New Offer"
        case .offerAccepted: return "Offer Accepted"
        case .offerDeclined: return "Offer Declined"
        case .newMessage: return "New Message"
        case .transactionUpdate: return "Transaction Update"
        case .paymentReceived: return "Payment Received"
        case .reviewReceived: return "Review Received"
        case .listingExpiring: return "Listing Expiring"
        case .karmaUpdate: return "Karma Update"
        }
    }
    
    var defaultSound: String {
        switch self {
        case .karmaUpdate: return "achievement_sound.wav"
        case .paymentReceived: return "payment_sound.wav"
        default: return "default"
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var isEnabled: Bool = true
    var newMessages: Bool = true
    var rentalUpdates: Bool = true
    var payments: Bool = true
    var achievements: Bool = true
    var marketing: Bool = false
    var nearbyItems: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: String = "22:00"
    var quietHoursEnd: String = "08:00"
    
    static var `default`: NotificationSettings {
        return NotificationSettings()
    }
}

// MARK: - Notification History Response
struct NotificationHistoryResponse: Codable {
    let success: Bool
    let data: NotificationHistoryData?
    let message: String?
}

struct NotificationHistoryData: Codable {
    let notifications: [NotificationHistoryItem]
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case notifications
        case total
        case page
        case limit
        case hasMore = "has_more"
    }
}

struct NotificationHistoryItem: Codable, Identifiable {
    let id: String
    let userId: Int
    let type: String
    let title: String
    let body: String
    let payload: [String: String]?
    let imageUrl: String?
    let actionUrl: String?
    let isRead: Bool
    let createdAt: String
    let readAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case body
        case payload
        case imageUrl = "image_url"
        case actionUrl = "action_url"
        case isRead = "is_read"
        case createdAt = "created_at"
        case readAt = "read_at"
    }
    
    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
    
    var readDate: Date? {
        guard let readAt = readAt else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: readAt)
    }
    
    var notificationType: NotificationType? {
        return NotificationType(rawValue: type)
    }
}

// MARK: - Badge Count Response
struct BadgeCountResponse: Codable {
    let success: Bool
    let data: BadgeCountData?
    let message: String?
}

struct BadgeCountData: Codable {
    let unreadCount: Int
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
        case totalCount = "total_count"
    }
}

// MARK: - Device Registration Request
struct DeviceRegistrationRequest: Codable {
    let userId: Int
    let deviceToken: String
    let platform: String
    let appVersion: String
    let deviceModel: String
    let osVersion: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceToken = "device_token"
        case platform
        case appVersion = "app_version"
        case deviceModel = "device_model"
        case osVersion = "os_version"
    }
}

// MARK: - Push Notification Request
struct PushNotificationRequest: Codable {
    let userId: Int
    let type: String
    let title: String
    let body: String
    let payload: [String: String]?
    let imageUrl: String?
    let actionUrl: String?
    let scheduleAt: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case type
        case title
        case body
        case payload
        case imageUrl = "image_url"
        case actionUrl = "action_url"
        case scheduleAt = "schedule_at"
    }
}

// MARK: - Notification Settings Request
struct NotificationSettingsRequest: Codable {
    let userId: Int
    let settings: NotificationSettings
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case settings
    }
}

// Using AnyCodable from APITypes.swift

// MARK: - Notification Template
struct NotificationTemplate {
    let type: NotificationType
    let titleTemplate: String
    let bodyTemplate: String
    let actionUrl: String?
    let imageUrl: String?
    
    static let templates: [NotificationType: NotificationTemplate] = [
        .newMessage: NotificationTemplate(
            type: .newMessage,
            titleTemplate: "New message from {sender}",
            bodyTemplate: "{message}",
            actionUrl: "brrow://chat/{conversation_id}",
            imageUrl: nil
        ),
        .newOffer: NotificationTemplate(
            type: .newOffer,
            titleTemplate: "New Offer",
            bodyTemplate: "{requester} wants to rent your {item_title}",
            actionUrl: "brrow://rental/{rental_id}",
            imageUrl: "{item_image}"
        ),
        .offerAccepted: NotificationTemplate(
            type: .offerAccepted,
            titleTemplate: "Offer Accepted!",
            bodyTemplate: "Your request to rent {item_title} was accepted",
            actionUrl: "brrow://rental/{rental_id}",
            imageUrl: "{item_image}"
        ),
        .offerDeclined: NotificationTemplate(
            type: .offerDeclined,
            titleTemplate: "Offer Declined",
            bodyTemplate: "Your request to rent {item_title} was declined",
            actionUrl: "brrow://marketplace",
            imageUrl: nil
        ),
        .paymentReceived: NotificationTemplate(
            type: .paymentReceived,
            titleTemplate: "Payment Received",
            bodyTemplate: "You received {amount} for {item_title}",
            actionUrl: "brrow://payments",
            imageUrl: nil
        ),
        .karmaUpdate: NotificationTemplate(
            type: .karmaUpdate,
            titleTemplate: "Achievement Unlocked! 🎉",
            bodyTemplate: "You unlocked '{achievement_name}'",
            actionUrl: "brrow://achievements/{achievement_id}",
            imageUrl: "{achievement_icon}"
        ),
        .listingExpiring: NotificationTemplate(
            type: .listingExpiring,
            titleTemplate: "Listing Expiring Soon",
            bodyTemplate: "Your listing '{item_title}' expires in {days} days",
            actionUrl: "brrow://listing/{listing_id}",
            imageUrl: "{item_image}"
        ),
        .reviewReceived: NotificationTemplate(
            type: .reviewReceived,
            titleTemplate: "New Review",
            bodyTemplate: "You received a new review for {item_title}",
            actionUrl: "brrow://profile/reviews",
            imageUrl: nil
        ),
        .transactionUpdate: NotificationTemplate(
            type: .transactionUpdate,
            titleTemplate: "Transaction Update",
            bodyTemplate: "Your transaction status has been updated",
            actionUrl: "brrow://transactions",
            imageUrl: nil
        )
    ]
    
    func format(with variables: [String: String]) -> (title: String, body: String) {
        var title = titleTemplate
        var body = bodyTemplate
        
        for (key, value) in variables {
            title = title.replacingOccurrences(of: "{\(key)}", with: value)
            body = body.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        return (title: title, body: body)
    }
}