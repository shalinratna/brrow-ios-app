//
//  ChatService.swift
//  Brrow
//
//  Real-time chat service with Socket.io
//

import Foundation
import Combine
import SocketIO

// Typealias to resolve conflict with SocketIO.Message
typealias BrrowMessage = Message

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    // Published properties
    @Published var chats: [Chat] = []
    @Published var activeChat: Chat?
    @Published var messages: [String: [BrrowMessage]] = [:] // chatId -> messages
    @Published var unreadCount: Int = 0
    @Published var isConnected: Bool = false
    @Published var typingUsers: [String: Set<String>] = [:] // chatId -> Set of userIds
    @Published var onlineUsers: Set<String> = []
    
    // Socket.io
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    // Message queue for offline support
    private var messageQueue: [BrrowMessage] = []
    private var drafts: [String: String] = [:] // chatId -> draft content
    
    // Combine
    private var cancellables = Set<AnyCancellable>()
    
    private let apiClient = APIClient.shared
    
    private init() {
        setupSocket()
        loadCachedData()
        observeAuthChanges()
    }
    
    // MARK: - Socket Setup
    
    private func setupSocket() {
        guard let token = AuthManager.shared.authToken else { return }
        
        Task {
            let baseURL = await getBaseURL()
            await MainActor.run {
                self.manager = SocketManager(
                    socketURL: URL(string: baseURL)!,
                    config: [
                        .log(false),
                        .compress,
                        .reconnects(true),
                        .reconnectAttempts(5),
                        .reconnectWait(3),
                        .connectParams(["token": token]),
                        .extraHeaders(["Authorization": "Bearer \(token)"])
                    ]
                )
                
                self.socket = self.manager?.defaultSocket
                self.setupSocketHandlers()
            }
        }
    }
    
    private func getBaseURL() async -> String {
        // Use the actual backend URL
        let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
        // Convert https to wss for WebSocket
        return baseURL.replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
    }
    
    private func setupSocketHandlers() {
        guard let socket = socket else { return }
        
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ Socket connected")
            Task { @MainActor in
                self?.isConnected = true
                self?.syncOfflineMessages()
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("❌ Socket disconnected")
            Task { @MainActor in
                self?.isConnected = false
            }
        }
        
        socket.on(clientEvent: .error) { data, ack in
            print("⚠️ Socket error: \(data)")
        }
        
        // Message events
        socket.on(SocketEvent.newMessage.rawValue) { [weak self] data, ack in
            guard let messageData = data.first as? [String: Any],
                  let chatId = messageData["chatId"] as? String,
                  let messageDict = messageData["message"] as? [String: Any],
                  let messageJSON = try? JSONSerialization.data(withJSONObject: messageDict),
                  let message = try? JSONDecoder().decode(BrrowMessage.self, from: messageJSON) else {
                return
            }
            
            Task { @MainActor in
                self?.handleNewMessage(message, chatId: chatId)
            }
        }
        
        socket.on(SocketEvent.messageRead.rawValue) { [weak self] data, ack in
            guard let dict = data.first as? [String: Any],
                  let messageId = dict["messageId"] as? String,
                  let readBy = dict["readBy"] as? String else {
                return
            }
            
            Task { @MainActor in
                self?.markMessageAsRead(messageId: messageId, readBy: readBy)
            }
        }
        
        socket.on(SocketEvent.messageDeleted.rawValue) { [weak self] data, ack in
            guard let dict = data.first as? [String: Any],
                  let messageId = dict["messageId"] as? String,
                  let chatId = dict["chatId"] as? String else {
                return
            }
            
            Task { @MainActor in
                self?.removeMessage(messageId: messageId, chatId: chatId)
            }
        }
        
        // Typing indicators
        socket.on(SocketEvent.userTyping.rawValue) { [weak self] data, ack in
            guard let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? String,
                  let chatId = dict["chatId"] as? String else {
                return
            }
            
            Task { @MainActor in
                self?.addTypingUser(userId: userId, chatId: chatId)
            }
        }
        
        socket.on(SocketEvent.userStoppedTyping.rawValue) { [weak self] data, ack in
            guard let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? String,
                  let chatId = dict["chatId"] as? String else {
                return
            }
            
            Task { @MainActor in
                self?.removeTypingUser(userId: userId, chatId: chatId)
            }
        }
        
        // Presence
        socket.on(SocketEvent.contactStatus.rawValue) { [weak self] data, ack in
            guard let dict = data.first as? [String: Any],
                  let userId = dict["userId"] as? String,
                  let isOnline = dict["isOnline"] as? Bool else {
                return
            }
            
            Task { @MainActor in
                if isOnline {
                    self?.onlineUsers.insert(userId)
                } else {
                    self?.onlineUsers.remove(userId)
                }
            }
        }
        
        // Message sent acknowledgment
        socket.on(SocketEvent.messageSent.rawValue) { [weak self] data, ack in
            guard let dict = data.first as? [String: Any],
                  let tempId = dict["tempId"] as? String,
                  let messageDict = dict["message"] as? [String: Any],
                  let messageJSON = try? JSONSerialization.data(withJSONObject: messageDict),
                  let message = try? JSONDecoder().decode(BrrowMessage.self, from: messageJSON) else {
                return
            }
            
            Task { @MainActor in
                self?.replaceTemporaryMessage(tempId: tempId, with: message)
            }
        }
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard AuthManager.shared.isAuthenticated else { return }
        
        if socket == nil {
            setupSocket()
        }
        
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        isConnected = false
    }
    
    func reconnect() {
        disconnect()
        setupSocket()
        connect()
    }
    
    // MARK: - Chat Management
    
    func loadChats() async {
        do {
            let response = try await apiClient.performRequest(
                endpoint: "api/messages/chats",
                method: "GET",
                responseType: ChatsResponse.self
            )
            
            if response.success {
                self.chats = response.data.sorted { chat1, chat2 in
                    (chat1.lastMessageTime ?? Date.distantPast) > (chat2.lastMessageTime ?? Date.distantPast)
                }
                
                // Cache chats
                saveCachedChats()
                
                // Join all chat rooms
                for chat in chats {
                    joinChat(chatId: chat.id)
                }
                
                // Update unread count
                updateUnreadCount()
            }
        } catch {
            print("Failed to load chats: \(error)")
            // Load cached chats
            loadCachedChats()
        }
    }
    
    func createOrGetDirectChat(with userId: String, listingId: String? = nil) async throws -> Chat {
        let request = CreateDirectChatRequest(recipientId: userId, listingId: listingId)
        let bodyData = try JSONEncoder().encode(request)
        
        let response = try await apiClient.performRequest(
            endpoint: "api/messages/chats/direct",
            method: "POST",
            body: bodyData,
            responseType: ChatResponse.self
        )
        
        if response.success {
            let chat = response.data
            
            // Add to chats if not exists
            if !chats.contains(where: { $0.id == chat.id }) {
                chats.insert(chat, at: 0)
            }
            
            // Join chat room
            joinChat(chatId: chat.id)
            
            return chat
        } else {
            throw BrrowAPIError.serverError("Failed to create chat")
        }
    }
    
    // MARK: - Message Management
    
    func loadMessages(for chatId: String, before: Date? = nil) async {
        do {
            var endpoint = "api/messages/chats/\(chatId)/messages"
            if let before = before {
                let dateString = ISO8601DateFormatter().string(from: before)
                endpoint += "?before=\(dateString)"
            }
            
            let response = try await apiClient.performRequest(
                endpoint: endpoint,
                method: "GET",
                responseType: MessagesResponse.self
            )
            
            if response.success {
                if before != nil {
                    // Prepend older messages
                    messages[chatId] = response.data + (messages[chatId] ?? [])
                } else {
                    // Replace with new messages
                    messages[chatId] = response.data
                }
                
                // Cache messages
                saveCachedMessages(for: chatId)
            }
        } catch {
            print("Failed to load messages: \(error)")
            // Load cached messages
            loadCachedMessages(for: chatId)
        }
    }
    
    func sendMessage(
        chatId: String,
        content: String? = nil,
        messageType: MessageType = .text,
        mediaUrl: String? = nil,
        thumbnailUrl: String? = nil,
        listingId: String? = nil
    ) {
        let tempId = UUID().uuidString
        
        // Create temporary message for immediate UI update
        var tempMessage = BrrowMessage(
            id: tempId,
            chatId: chatId,
            senderId: AuthManager.shared.currentUser?.id ?? "",
            receiverId: nil,
            content: content ?? "",
            messageType: messageType,
            mediaUrl: mediaUrl,
            thumbnailUrl: thumbnailUrl,
            listingId: listingId,
            isRead: false,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: AuthManager.shared.currentUser,
            reactions: nil
        )
        tempMessage.tempId = tempId
        tempMessage.sendStatus = .sending
        
        // Add to messages immediately
        if messages[chatId] == nil {
            messages[chatId] = []
        }
        messages[chatId]?.append(tempMessage)
        
        // Send via socket if connected, otherwise queue
        if isConnected {
            socket?.emit(SocketEvent.sendMessage.rawValue, [
                "chatId": chatId,
                "content": content ?? "",
                "messageType": messageType.rawValue,
                "mediaUrl": mediaUrl as Any,
                "thumbnailUrl": thumbnailUrl as Any,
                "listingId": listingId as Any,
                "tempId": tempId
            ])
        } else {
            // Queue for later
            messageQueue.append(tempMessage)
            
            // Try REST API as fallback
            Task {
                await sendMessageViaAPI(tempMessage)
            }
        }
        
        // Update chat's last message
        updateChatLastMessage(chatId: chatId, message: tempMessage)
    }
    
    private func sendMessageViaAPI(_ message: Message) async {
        do {
            let request = ChatSendMessageRequest(
                content: message.content,
                messageType: message.messageType.rawValue,
                mediaUrl: message.mediaUrl,
                thumbnailUrl: message.thumbnailUrl,
                listingId: message.listingId
            )
            
            let bodyData = try JSONEncoder().encode(request)
            
            let response = try await apiClient.performRequest(
                endpoint: "api/messages/chats/\(message.chatId)/messages",
                method: "POST",
                body: bodyData,
                responseType: MessageResponse.self
            )
            
            if response.success {
                replaceTemporaryMessage(tempId: message.tempId ?? "", with: response.data)
            }
        } catch {
            print("Failed to send message via API: \(error)")
            markMessageAsFailed(tempId: message.tempId ?? "")
        }
    }
    
    // MARK: - Socket Actions
    
    func joinChat(chatId: String) {
        socket?.emit(SocketEvent.joinChat.rawValue, chatId)
    }
    
    func leaveChat(chatId: String) {
        socket?.emit(SocketEvent.leaveChat.rawValue, chatId)
    }
    
    func startTyping(in chatId: String) {
        socket?.emit(SocketEvent.typingStart.rawValue, ["chatId": chatId])
    }
    
    func stopTyping(in chatId: String) {
        socket?.emit(SocketEvent.typingStop.rawValue, ["chatId": chatId])
    }
    
    func markMessagesAsRead(messageIds: [String], chatId: String) {
        socket?.emit(SocketEvent.markRead.rawValue, [
            "messageIds": messageIds,
            "chatId": chatId
        ])
        
        // Update local state immediately
        // Update local state immediately by creating new message instances
        if let chatMessages = messages[chatId] {
            messages[chatId] = chatMessages.map { message in
                if messageIds.contains(message.id) {
                    // Create a new message with isRead set to true
                    return Message(
                        id: message.id,
                        chatId: message.chatId,
                        senderId: message.senderId,
                        receiverId: message.receiverId,
                        content: message.content,
                        messageType: message.messageType,
                        mediaUrl: message.mediaUrl,
                        thumbnailUrl: message.thumbnailUrl,
                        listingId: message.listingId,
                        isRead: true, // Update isRead
                        isEdited: message.isEdited,
                        editedAt: message.editedAt,
                        deletedAt: message.deletedAt,
                        sentAt: message.sentAt,
                        createdAt: message.createdAt,
                        sender: message.sender,
                        reactions: message.reactions,
                        tempId: message.tempId,
                        sendStatus: .read
                    )
                }
                return message
            }
        }
        
        updateUnreadCount()
    }
    
    // MARK: - Message Handlers
    
    private func handleNewMessage(_ message: Message, chatId: String) {
        // Add to messages
        if messages[chatId] == nil {
            messages[chatId] = []
        }
        
        // Check if message already exists (prevent duplicates)
        if !messages[chatId]!.contains(where: { $0.id == message.id }) {
            messages[chatId]?.append(message)
        }
        
        // Update chat's last message
        updateChatLastMessage(chatId: chatId, message: message)
        
        // Update unread count if not from current user
        if !message.isFromCurrentUser {
            updateUnreadCount()
            
            // Show local notification if app is in background
            showLocalNotification(for: message)
        }
        
        // Save to cache
        saveCachedMessages(for: chatId)
    }
    
    private func replaceTemporaryMessage(tempId: String, with message: Message) {
        for (chatId, chatMessages) in messages {
            if let index = chatMessages.firstIndex(where: { $0.tempId == tempId }) {
                messages[chatId]?[index] = message
                saveCachedMessages(for: chatId)
                break
            }
        }
    }
    
    private func markMessageAsFailed(tempId: String) {
        for (chatId, chatMessages) in messages {
            if let index = chatMessages.firstIndex(where: { $0.tempId == tempId }) {
                messages[chatId]?[index].sendStatus = .failed
                break
            }
        }
    }
    
    private func markMessageAsRead(messageId: String, readBy: String) {
        for (chatId, chatMessages) in messages {
            if let index = chatMessages.firstIndex(where: { $0.id == messageId }) {
                let message = chatMessages[index]
                // Create a new message with updated read status
                let updatedMessage = Message(
                    id: message.id,
                    chatId: message.chatId,
                    senderId: message.senderId,
                    receiverId: message.receiverId,
                    content: message.content,
                    messageType: message.messageType,
                    mediaUrl: message.mediaUrl,
                    thumbnailUrl: message.thumbnailUrl,
                    listingId: message.listingId,
                    isRead: true, // Update isRead
                    isEdited: message.isEdited,
                    editedAt: message.editedAt,
                    deletedAt: message.deletedAt,
                    sentAt: message.sentAt,
                    createdAt: message.createdAt,
                    sender: message.sender,
                    reactions: message.reactions,
                    tempId: message.tempId,
                    sendStatus: .read // Update sendStatus
                )
                messages[chatId]?[index] = updatedMessage
                break
            }
        }
    }
    
    private func removeMessage(messageId: String, chatId: String) {
        messages[chatId]?.removeAll { $0.id == messageId }
        saveCachedMessages(for: chatId)
    }
    
    // MARK: - Typing Indicators
    
    private func addTypingUser(userId: String, chatId: String) {
        if typingUsers[chatId] == nil {
            typingUsers[chatId] = Set()
        }
        typingUsers[chatId]?.insert(userId)
        
        // Auto-remove after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.removeTypingUser(userId: userId, chatId: chatId)
        }
    }
    
    private func removeTypingUser(userId: String, chatId: String) {
        typingUsers[chatId]?.remove(userId)
    }
    
    // MARK: - Helper Methods
    
    private func updateChatLastMessage(chatId: String, message: BrrowMessage) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            let existingChat = chats[index]
            
            // Create new Chat instance with updated properties
            let updatedChat = Chat(
                id: existingChat.id,
                type: existingChat.type,
                name: existingChat.name,
                listingId: existingChat.listingId,
                isActive: existingChat.isActive,
                lastMessageAt: message.createdAt,
                createdAt: existingChat.createdAt,
                updatedAt: existingChat.updatedAt,
                participants: existingChat.participants,
                lastMessage: message,
                unreadCount: existingChat.unreadCount
            )
            
            chats[index] = updatedChat
            
            // Re-sort chats
            chats.sort { chat1, chat2 in
                (chat1.lastMessageTime ?? Date.distantPast) > (chat2.lastMessageTime ?? Date.distantPast)
            }
        }
    }
    
    private func updateUnreadCount() {
        unreadCount = chats.reduce(0) { $0 + $1.unreadCount }
    }
    
    private func syncOfflineMessages() {
        for message in messageQueue {
            sendMessage(
                chatId: message.chatId,
                content: message.content,
                messageType: message.messageType,
                mediaUrl: message.mediaUrl,
                thumbnailUrl: message.thumbnailUrl,
                listingId: message.listingId
            )
        }
        messageQueue.removeAll()
    }
    
    private func showLocalNotification(for message: BrrowMessage) {
        // TODO: Implement local notification
    }
    
    // MARK: - Cache Management
    
    private func loadCachedData() {
        loadCachedChats()
        // Load messages for each chat
        for chat in chats {
            loadCachedMessages(for: chat.id)
        }
    }
    
    private func loadCachedChats() {
        // TODO: Implement cache loading from UserDefaults or Core Data
    }
    
    private func saveCachedChats() {
        // TODO: Implement cache saving
    }
    
    private func loadCachedMessages(for chatId: String) {
        // TODO: Implement cache loading
    }
    
    private func saveCachedMessages(for chatId: String) {
        // TODO: Implement cache saving
    }
    
    // MARK: - Draft Management
    
    func saveDraft(_ content: String, for chatId: String) {
        drafts[chatId] = content
        // TODO: Persist to UserDefaults
    }
    
    func getDraft(for chatId: String) -> String? {
        return drafts[chatId]
    }
    
    func clearDraft(for chatId: String) {
        drafts.removeValue(forKey: chatId)
    }
    
    // MARK: - Auth Observer
    
    private func observeAuthChanges() {
        AuthManager.shared.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.reconnect()
                    Task {
                        await self?.loadChats()
                    }
                } else {
                    self?.disconnect()
                    self?.chats.removeAll()
                    self?.messages.removeAll()
                    self?.unreadCount = 0
                }
            }
            .store(in: &cancellables)
    }
}