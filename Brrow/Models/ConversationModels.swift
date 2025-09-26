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

    // Computed property for full profile picture URL
    var fullProfilePictureURL: String? {
        guard let profilePictureString = profilePicture else { return nil }

        // If the URL is already complete (starts with http), return as-is
        if profilePictureString.hasPrefix("http://") || profilePictureString.hasPrefix("https://") {
            return profilePictureString
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
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case messageType = "message_type"
        case createdAt = "created_at"
    }
}