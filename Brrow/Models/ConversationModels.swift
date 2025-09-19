//
//  ConversationModels.swift
//  Brrow
//
//  Consolidated conversation and messaging models
//

import Foundation

// MARK: - Conversation Model
struct Conversation: Codable, Identifiable {
    let id: String
    let otherUser: User
    let lastMessage: ChatMessage
    let unreadCount: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, unreadCount
        case otherUser = "other_user"
        case lastMessage = "last_message"
        case updatedAt = "updated_at"
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