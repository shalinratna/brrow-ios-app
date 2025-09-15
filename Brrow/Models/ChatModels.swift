//
//  ChatModels.swift
//  Brrow
//
//  Real-time messaging models
//

import Foundation

// MARK: - Chat Models

struct Chat: Identifiable {
    let id: String
    let type: ChatType
    let name: String?
    let listingId: String?
    let isActive: Bool
    let lastMessageAt: String?
    let createdAt: String
    let updatedAt: String?
    let participants: [ChatParticipant]
    let lastMessage: Message?
    let unreadCount: Int
    
    var displayName: String {
        if let name = name {
            return name
        }
        // For direct chats, show other participant's name
        if type == .direct {
            return participants.first?.user.username ?? "Unknown"
        }
        return "Chat"
    }
    
    var otherParticipant: User? {
        if type == .direct {
            return participants.first?.user
        }
        return nil
    }
    
    var lastMessageTime: Date? {
        if let lastMessageAt = lastMessageAt {
            return ISO8601DateFormatter().date(from: lastMessageAt)
        }
        return nil
    }
}

// Extension for Codable conformance
extension Chat: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, name, listingId, isActive, lastMessageAt
        case createdAt, updatedAt, participants, unreadCount
        // Exclude lastMessage from encoding/decoding due to Message complexity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ChatType.self, forKey: .type)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        listingId = try container.decodeIfPresent(String.self, forKey: .listingId)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        lastMessageAt = try container.decodeIfPresent(String.self, forKey: .lastMessageAt)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        participants = try container.decode([ChatParticipant].self, forKey: .participants)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        
        // Set lastMessage to nil by default
        lastMessage = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(listingId, forKey: .listingId)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(lastMessageAt, forKey: .lastMessageAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encode(participants, forKey: .participants)
        try container.encode(unreadCount, forKey: .unreadCount)
    }
}

enum ChatType: String, Codable {
    case direct = "DIRECT"
    case group = "GROUP"
}

struct ChatParticipant: Codable {
    let id: String
    let chatId: String
    let userId: String
    let role: ChatParticipantRole
    let joinedAt: String
    let leftAt: String?
    let lastReadAt: String?
    let user: User
}

enum ChatParticipantRole: String, Codable {
    case admin = "ADMIN"
    case moderator = "MODERATOR"
    case member = "MEMBER"
}

// MARK: - Message Models

struct Message: Identifiable, Equatable {
    let id: String
    let chatId: String
    let senderId: String
    let receiverId: String?
    let content: String
    let messageType: MessageType
    let mediaUrl: String?
    let thumbnailUrl: String?
    let listingId: String?
    let isRead: Bool
    let isEdited: Bool
    let editedAt: String?
    let deletedAt: String?
    let sentAt: String?
    let createdAt: String
    let sender: User?
    let reactions: [MessageReaction]?
    
    // For local tracking
    var tempId: String?
    var sendStatus: MessageSendStatus = .sent
    
    var timestamp: Date {
        ISO8601DateFormatter().date(from: createdAt) ?? Date()
    }
    
    var isFromCurrentUser: Bool {
        senderId == AuthManager.shared.currentUser?.id ||
        senderId == AuthManager.shared.currentUser?.apiId
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// Extension for Codable conformance (excluding non-Codable properties)
extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case id, chatId, senderId, receiverId, content, messageType
        case mediaUrl, thumbnailUrl, listingId, isRead, isEdited
        case editedAt, deletedAt, sentAt, createdAt, reactions
        // Exclude sender, tempId, and sendStatus from encoding/decoding
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        chatId = try container.decode(String.self, forKey: .chatId)
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decodeIfPresent(String.self, forKey: .receiverId)
        content = try container.decode(String.self, forKey: .content)
        messageType = try container.decode(MessageType.self, forKey: .messageType)
        mediaUrl = try container.decodeIfPresent(String.self, forKey: .mediaUrl)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        listingId = try container.decodeIfPresent(String.self, forKey: .listingId)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        isEdited = try container.decode(Bool.self, forKey: .isEdited)
        editedAt = try container.decodeIfPresent(String.self, forKey: .editedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        sentAt = try container.decodeIfPresent(String.self, forKey: .sentAt)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        reactions = try container.decodeIfPresent([MessageReaction].self, forKey: .reactions)
        
        // Set default values for non-Codable properties
        sender = nil
        tempId = nil
        sendStatus = .sent
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(senderId, forKey: .senderId)
        try container.encodeIfPresent(receiverId, forKey: .receiverId)
        try container.encode(content, forKey: .content)
        try container.encode(messageType, forKey: .messageType)
        try container.encodeIfPresent(mediaUrl, forKey: .mediaUrl)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(listingId, forKey: .listingId)
        try container.encode(isRead, forKey: .isRead)
        try container.encode(isEdited, forKey: .isEdited)
        try container.encodeIfPresent(editedAt, forKey: .editedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encodeIfPresent(sentAt, forKey: .sentAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(reactions, forKey: .reactions)
    }
}

enum MessageType: String, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
    case audio = "AUDIO"
    case file = "FILE"
    case listing = "LISTING"
    case system = "SYSTEM"
}

enum MessageSendStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

struct MessageReaction: Codable {
    let id: String
    let messageId: String
    let userId: String
    let emoji: String
    let createdAt: String
    let user: User?
}

// MARK: - API Response Models

struct ChatsResponse: Codable {
    let success: Bool
    let data: [Chat]
}

struct ChatResponse: Codable {
    let success: Bool
    let data: Chat
}

// MessagesResponse is defined in APIResponses.swift

struct MessageResponse: Codable {
    let success: Bool
    let data: Message
}

struct UnreadCountResponse: Codable {
    let success: Bool
    let data: UnreadCount
    
    struct UnreadCount: Codable {
        let count: Int
    }
}

// MARK: - Request Models

struct CreateDirectChatRequest: Codable {
    let recipientId: String
    let listingId: String?
}

struct ChatSendMessageRequest: Codable {
    let content: String?
    let messageType: String
    let mediaUrl: String?
    let thumbnailUrl: String?
    let listingId: String?
}

// MARK: - Socket Events

enum SocketEvent: String {
    // Connection
    case connect = "connect"
    case disconnect = "disconnect"
    case error = "error"
    
    // Chat
    case joinChat = "join_chat"
    case leaveChat = "leave_chat"
    
    // Messages
    case sendMessage = "send_message"
    case newMessage = "new_message"
    case messageRead = "message_read"
    case messagesRead = "messages_read"
    case messageDeleted = "message_deleted"
    case messageSent = "message_sent"
    
    // Typing
    case typingStart = "typing_start"
    case typingStop = "typing_stop"
    case userTyping = "user_typing"
    case userStoppedTyping = "user_stopped_typing"
    
    // Reactions
    case addReaction = "add_reaction"
    case reactionAdded = "reaction_added"
    
    // Presence
    case userOnline = "user_online"
    case contactStatus = "contact_status"
    case presenceUpdate = "presence_update"
    case updatePresence = "update_presence"
    
    // Read receipts
    case markRead = "mark_read"
}

// MARK: - Local Storage Models

struct ChatDraft: Codable {
    let chatId: String
    let content: String
    let timestamp: Date
}

struct ChatSettings: Codable {
    let chatId: String
    let isMuted: Bool
    let mutedUntil: Date?
    let customNotificationSound: String?
}