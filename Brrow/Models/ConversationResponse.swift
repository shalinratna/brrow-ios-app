//
//  ConversationResponse.swift
//  Brrow
//
//  Response models for conversation/chat APIs
//

import Foundation

// MARK: - Fetch Conversations Response
struct FetchConversationsResponse: Codable {
    let success: Bool
    let message: String
    let data: ConversationsData
}

struct ConversationsData: Codable {
    let conversations: [Conversation]
    let unreadCount: Int?  // Optional for backward compatibility
    let count: Int?         // Alternative field name from API
    let pagination: PaginationInfo?  // Optional if not provided
    
    enum CodingKeys: String, CodingKey {
        case conversations
        case unreadCount = "unread_count"
        case count
        case pagination
    }
    
    // Computed property to get the actual count
    var totalCount: Int {
        return count ?? unreadCount ?? conversations.count
    }
}

// MARK: - Send Message Response
struct SendMessageResponse: Codable {
    let success: Bool
    let message: String
    let data: ChatMessage
}

// MARK: - Create Conversation Response
struct CreateConversationResponse: Codable {
    let success: Bool
    let message: String
    let data: Conversation
}