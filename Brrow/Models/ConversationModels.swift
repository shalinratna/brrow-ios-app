//
//  ConversationModels.swift
//  Brrow
//
//  Consolidated conversation and messaging models
//  Enhanced with dual messaging system (Direct + Listing conversations)
//

import Foundation

// MARK: - Chat Type
enum ChatType: String, Codable {
    case direct = "DIRECT"
    case group = "GROUP"
    case listing = "LISTING"
}

// MARK: - Message Type
enum MessageType: String, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
    case audio = "AUDIO"
    case voice = "VOICE"  // Legacy support
    case file = "FILE"    // Legacy support
    case system = "SYSTEM" // Legacy support
    case offer = "OFFER"   // Legacy support
    case location = "LOCATION"
    case listing = "LISTING"
    case listingReference = "LISTING_REFERENCE"
}

// MARK: - Delivery Status
enum DeliveryStatus: String, Codable {
    case sent
    case delivered
    case read

    var displayText: String {
        switch self {
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .read: return "Read"
        }
    }
}

// MARK: - Unread Counts
struct UnreadCounts: Codable {
    let direct: Int
    let listing: Int
    let total: Int

    init(direct: Int = 0, listing: Int = 0) {
        self.direct = direct
        self.listing = listing
        self.total = direct + listing
    }
}

// MARK: - Listing Preview (for listing conversations)
struct ListingPreview: Codable, Identifiable {
    let id: String
    let title: String
    let price: Double?
    let imageUrl: String?
    let availabilityStatus: String

    enum CodingKeys: String, CodingKey {
        case id, title, price
        case imageUrl = "thumbnail"  // Backend sends "thumbnail"
        case availabilityStatus = "status"  // Backend sends "status"
    }
}

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

// MARK: - Conversation Model (Enhanced with Dual Messaging)
struct Conversation: Codable, Identifiable {
    let id: String
    let type: ChatType
    let otherUser: ConversationUser  // Use minimal user model
    let lastMessage: ChatMessage?  // Make optional to handle null
    let unreadCount: Int
    let updatedAt: String
    let listing: ListingPreview?  // For listing conversations
    let listingId: String?  // Backend may send listingId instead of full listing
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, unreadCount, type, listing, listingId, isActive
        case otherUser = "other_user"     // Fix: JSON has "other_user"
        case lastMessage                  // Fix: JSON has "lastMessage" not "last_message"
        case updatedAt                    // Fix: JSON has "updatedAt" not "updated_at"
    }

    // MARK: - Custom Decoder to handle missing isActive field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ChatType.self, forKey: .type)
        otherUser = try container.decode(ConversationUser.self, forKey: .otherUser)
        lastMessage = try container.decodeIfPresent(ChatMessage.self, forKey: .lastMessage)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        listing = try container.decodeIfPresent(ListingPreview.self, forKey: .listing)
        listingId = try container.decodeIfPresent(String.self, forKey: .listingId)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true  // Default to true
    }

    // MARK: - Manual Initializer
    init(id: String, type: ChatType = .direct, otherUser: ConversationUser, lastMessage: ChatMessage? = nil, unreadCount: Int = 0, updatedAt: String, listing: ListingPreview? = nil, listingId: String? = nil, isActive: Bool = true) {
        self.id = id
        self.type = type
        self.otherUser = otherUser
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.updatedAt = updatedAt
        self.listing = listing
        self.listingId = listingId
        self.isActive = isActive
    }

    // Helper: Display title for conversation
    var displayTitle: String {
        if type == .listing, let listing = listing {
            return listing.title
        }
        return otherUser.username
    }

    // Helper: Is this a listing conversation?
    var isListingChat: Bool {
        return type == .listing
    }
}

// MARK: - Chat Message (Enhanced with Media Support)
struct ChatMessage: Codable, Identifiable {
    let id: String
    let senderId: String
    let receiverId: String?
    let content: String
    let messageType: MessageType
    let createdAt: String
    let isRead: Bool

    // Enhanced fields for dual messaging system
    let mediaUrl: String?
    let thumbnailUrl: String?
    let videoDuration: Int?
    let deliveredAt: String?
    let readAt: String?

    // Sender info
    let sender: ConversationUser?

    enum CodingKeys: String, CodingKey {
        case id, content, isRead, sender
        case senderId = "senderId"
        case receiverId = "receiverId"
        case messageType = "messageType"
        case createdAt = "createdAt"
        case mediaUrl = "mediaUrl"
        case thumbnailUrl = "thumbnailUrl"
        case videoDuration = "videoDuration"
        case deliveredAt = "deliveredAt"
        case readAt = "readAt"
    }

    // MARK: - Computed Properties

    // Delivery status based on timestamps
    var deliveryStatus: DeliveryStatus {
        if isRead, readAt != nil {
            return .read
        } else if deliveredAt != nil {
            return .delivered
        } else {
            return .sent
        }
    }

    // Display text for different message types
    var displayContent: String {
        switch messageType {
        case .text:
            return content
        case .image:
            return "📷 Photo"
        case .video:
            return "🎥 Video"
        case .audio, .voice:
            return "🎤 Voice Message"
        case .file:
            return "📎 File"
        case .system:
            return content
        case .offer:
            return "💰 Offer"
        case .location:
            return "📍 Location"
        case .listing, .listingReference:
            return "🏷️ Listing"
        }
    }

    // Is this a media message?
    var isMediaMessage: Bool {
        return messageType == .image || messageType == .video
    }

    // Formatted read time (e.g., "Read at 2:34 PM")
    var formattedReadTime: String? {
        guard let readAt = readAt else { return nil }

        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: readAt) else { return nil }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return "Read at \(timeFormatter.string(from: date))"
    }

    // MARK: - Manual Initializer
    init(id: String, senderId: String, receiverId: String?, content: String, messageType: MessageType = .text, createdAt: String, isRead: Bool = false, mediaUrl: String? = nil, thumbnailUrl: String? = nil, videoDuration: Int? = nil, deliveredAt: String? = nil, readAt: String? = nil, sender: ConversationUser? = nil) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.messageType = messageType
        self.createdAt = createdAt
        self.isRead = isRead
        self.mediaUrl = mediaUrl
        self.thumbnailUrl = thumbnailUrl
        self.videoDuration = videoDuration
        self.deliveredAt = deliveredAt
        self.readAt = readAt
        self.sender = sender
    }
}

// MARK: - Conversion from Message to ChatMessage
extension ChatMessage {
    /// Convert from Message (ChatModels) to ChatMessage (ConversationModels)
    static func from(_ message: Message) -> ChatMessage {
        return ChatMessage(
            id: message.id,
            senderId: message.senderId,
            receiverId: message.receiverId,
            content: message.content,
            messageType: message.messageType,
            createdAt: message.createdAt,
            isRead: message.isRead,
            mediaUrl: message.mediaUrl,
            thumbnailUrl: message.thumbnailUrl,
            videoDuration: nil, // Not in Message model
            deliveredAt: message.sentAt,
            readAt: nil, // Not in Message model
            sender: message.sender.map { ConversationUser.fromUser($0) }
        )
    }
}

// MARK: - Conversion from ChatMessage to Message
extension Message {
    /// Convert from ChatMessage (ConversationModels) to Message (ChatModels)
    static func from(_ chatMessage: ChatMessage) -> Message {
        var message = Message(
            id: chatMessage.id,
            chatId: "", // Not available in ChatMessage
            senderId: chatMessage.senderId,
            receiverId: chatMessage.receiverId,
            content: chatMessage.content,
            messageType: chatMessage.messageType,
            mediaUrl: chatMessage.mediaUrl,
            thumbnailUrl: chatMessage.thumbnailUrl,
            listingId: nil,
            isRead: chatMessage.isRead,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: chatMessage.deliveredAt,
            createdAt: chatMessage.createdAt,
            sender: chatMessage.sender.map { User.from($0) },
            reactions: nil
        )
        // Set var properties after initialization
        message.tempId = nil
        message.sendStatus = chatMessage.deliveryStatus == .read ? .read : (chatMessage.deliveryStatus == .delivered ? .delivered : .sent)
        return message
    }
}

// MARK: - User conversion helper
extension User {
    static func from(_ conversationUser: ConversationUser) -> User {
        return User(
            id: conversationUser.id,
            username: conversationUser.username,
            email: "",  // ConversationUser doesn't have email
            profilePicture: conversationUser.profilePicture
        )
    }
}