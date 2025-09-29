//
//  ConversationModels.swift
//  Brrow
//
//  Consolidated conversation and messaging models
//

import Foundation

// MARK: - Conversation User (minimal data from conversation API)
struct ConversationUser: Codable, Identifiable {
    let id: String
    let username: String
    let profilePicture: String?
    let isVerified: Bool?

    // Computed property for API compatibility
    var apiId: String { return id }

    enum CodingKeys: String, CodingKey {
        case id, username, isVerified
        case profilePicture
    }

    // MARK: - Manual Initializer
    init(id: String, username: String, profilePicture: String? = nil, isVerified: Bool = false) {
        self.id = id
        self.username = username
        self.profilePicture = profilePicture
        self.isVerified = isVerified
    }

    // Computed property for full profile picture URL (platform-only)
    var fullProfilePictureURL: String? {
        guard let profilePictureString = profilePicture else { return nil }

        // If the URL is already complete (starts with http), check domain whitelist
        if profilePictureString.hasPrefix("http://") || profilePictureString.hasPrefix("https://") {
            let allowedDomains = [
                "brrow-backend-nodejs-production.up.railway.app",
                "brrowapp.com",
                "api.brrowapp.com",
                "res.cloudinary.com"
            ]

            for domain in allowedDomains {
                if profilePictureString.contains(domain) {
                    return profilePictureString
                }
            }

            print("🚫 Rejected external profile picture URL in ConversationUser: \(profilePictureString)")
            return nil
        }

        // If it's a relative path starting with /uploads/, prepend base URL
        if profilePictureString.hasPrefix("/uploads/") || profilePictureString.hasPrefix("uploads/") {
            let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
            let formattedPath = profilePictureString.hasPrefix("/") ? profilePictureString : "/\(profilePictureString)"
            return "\(baseURL)\(formattedPath)"
        }

        // For other relative paths, assume they need the base URL
        let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
        return "\(baseURL)/\(profilePictureString)"
    }

    // MARK: - Conversion from User
    static func fromUser(_ user: User) -> ConversationUser {
        return ConversationUser(
            id: user.apiId ?? user.id,
            username: user.username,
            profilePicture: user.profilePicture,
            isVerified: user.isVerified ?? user.verified ?? false
        )
    }

    // MARK: - Placeholder
    static func placeholder() -> ConversationUser {
        return ConversationUser(
            id: "placeholder",
            username: "Loading...",
            profilePicture: nil,
            isVerified: false
        )
    }
}

// MARK: - Conversation Model
struct Conversation: Codable, Identifiable {
    let id: String
    let otherUser: ConversationUser  // Use minimal user model
    let lastMessage: ChatMessage?  // Make optional to handle null
    let unreadCount: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, unreadCount
        case otherUser = "other_user"     // Fix: JSON has "other_user"
        case lastMessage                  // Fix: JSON has "lastMessage" not "last_message"
        case updatedAt                    // Fix: JSON has "updatedAt" not "updated_at"
    }

    // MARK: - Manual Initializer
    init(id: String, otherUser: ConversationUser, lastMessage: ChatMessage? = nil, unreadCount: Int = 0, updatedAt: String) {
        self.id = id
        self.otherUser = otherUser
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.updatedAt = updatedAt
    }
}

// MARK: - Chat Message
struct ChatMessage: Codable, Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let messageType: String
    let createdAt: String
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, content, isRead
        case senderId = "senderId"           // API uses camelCase
        case receiverId = "receiverId"       // API uses camelCase
        case messageType = "messageType"     // API uses camelCase
        case createdAt = "createdAt"         // API uses camelCase
    }
}