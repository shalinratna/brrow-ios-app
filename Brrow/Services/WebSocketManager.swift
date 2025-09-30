//
//  WebSocketManager.swift
//  Brrow
//
//  Real-time WebSocket messaging implementation
//

import Foundation
import Combine
import Network
import SocketIO

class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var unreadMessageCount = 0

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let serverURL = "https://brrow-backend-nodejs-production.up.railway.app"

    private var cancellables = Set<AnyCancellable>()
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var authToken: String?

    // Message handling
    private var messageHandlers: [String: (Any) -> Void] = [:]
    private var typingUsers: [String: Date] = [:]
    private var connectedUsers: Set<String> = []

    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(String)
    }

    enum SocketError: LocalizedError {
        case noAuthToken
        case connectionFailed
        case invalidMessage
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .noAuthToken:
                return "Authentication token not available"
            case .connectionFailed:
                return "Failed to connect to messaging server"
            case .invalidMessage:
                return "Invalid message format"
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }
    }

    override init() {
        super.init()
        setupNetworkMonitoring()
        setupMessageHandlers()

        // Auto-connect if user is authenticated
        AuthManager.shared.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.connect()
                } else {
                    self?.disconnect()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Connection Management

    func connect() {
        guard let token = AuthManager.shared.authToken else {
            print("❌ [WebSocket] No auth token available")
            connectionStatus = .error("No authentication token")
            return
        }

        authToken = token

        if isConnected {
            print("ℹ️ [WebSocket] Already connected")
            return
        }

        print("🔌 [WebSocket] Connecting to \(serverURL)...")
        print("🔑 [WebSocket] Using auth token: \(token.prefix(20))...")
        connectionStatus = .connecting

        // Configure Socket.io with authentication
        // CRITICAL: Socket.io auth is sent via extraHeaders and connectParams
        let config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .secure(true),
            .forceWebsockets(true),
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(2),
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .connectParams(["token": token])
        ]

        manager = SocketManager(socketURL: URL(string: serverURL)!, config: config)
        socket = manager?.defaultSocket

        setupSocketHandlers()
        socket?.connect()

        print("✅ [WebSocket] Connection initiated with auth token")
    }

    func disconnect() {
        print("🔌 [WebSocket] Disconnecting...")
        connectionStatus = .disconnected
        isConnected = false

        socket?.disconnect()
        socket = nil
        manager = nil

        reconnectTimer?.invalidate()
        pingTimer?.invalidate()

        typingUsers.removeAll()
        connectedUsers.removeAll()

        print("✅ [WebSocket] Disconnected")
    }

    private func reconnect() {
        switch connectionStatus {
        case .connecting:
            return
        default:
            break
        }

        connectionStatus = .reconnecting
        disconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connect()
        }
    }

    // MARK: - Message Sending

    func sendMessage(chatId: String, content: String, messageType: MessageType = .text, listingId: String? = nil) {
        guard isConnected, let socket = socket else {
            print("⚠️ [WebSocket] Not connected, falling back to REST API")
            sendMessageViaREST(chatId: chatId, content: content)
            return
        }

        var data: [String: Any] = [
            "chatId": chatId,
            "content": content,
            "messageType": messageType.rawValue,
            "tempId": UUID().uuidString
        ]

        if let listingId = listingId {
            data["listingId"] = listingId
        }

        socket.emit("send_message", data)
        print("📤 [WebSocket] Sent message to chat \(chatId)")
    }

    func sendTypingIndicator(chatId: String, isTyping: Bool) {
        guard isConnected, let socket = socket else { return }

        let event = isTyping ? "typing_start" : "typing_stop"
        socket.emit(event, ["chatId": chatId])
        print("⌨️ [WebSocket] Sent \(event) for chat \(chatId)")
    }

    func joinChat(chatId: String) {
        guard isConnected, let socket = socket else { return }

        socket.emit("join_chat", ["chatId": chatId])
        print("🚪 [WebSocket] Joined chat \(chatId)")
    }

    func leaveChat(chatId: String) {
        guard isConnected, let socket = socket else { return }

        socket.emit("leave_chat", ["chatId": chatId])
        print("🚪 [WebSocket] Left chat \(chatId)")
    }

    func markMessageAsRead(messageId: String, chatId: String) {
        guard isConnected, let socket = socket else { return }

        socket.emit("mark_read", [
            "messageId": messageId,
            "chatId": chatId
        ])
        print("👁️ [WebSocket] Marked message \(messageId) as read")
    }

    func updatePresence(status: String) {
        guard isConnected, let socket = socket else { return }

        socket.emit("update_presence", ["status": status])
        print("🟢 [WebSocket] Updated presence to \(status)")
    }

    // Removed: Old URLSessionWebSocketTask-based sendMessage - now using Socket.io emit()

    // REST API fallback for sending messages
    private func sendMessageViaREST(chatId: String, content: String) {
        guard let token = authToken else { return }

        let url = URL(string: "https://brrow-backend-nodejs-production.up.railway.app/api/messages/chats/\(chatId)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "content": content,
            "messageType": "TEXT"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ REST message send error: \(error)")
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        print("✅ Message sent via REST API fallback")

                        // Trigger a refresh of messages
                        NotificationCenter.default.post(
                            name: .messageSentViaREST,
                            object: chatId
                        )
                    } else {
                        print("❌ REST message send failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    }
                }
            }.resume()

        } catch {
            print("❌ Failed to serialize REST message: \(error)")
        }
    }

    // MARK: - Event Processing
    // Socket.io handles message parsing and event routing automatically via setupSocketHandlers()

    // Legacy processSocketEvent removed - now using Socket.io event handlers

    private func processSocketEventLegacy(event: String, data: Any) {
        // This function is kept for compatibility but not used with Socket.io
        guard let socketEvent = SocketEvent(rawValue: event) else {
            print("⚠️ Unknown socket event: \(event)")
            return
        }

        switch socketEvent {
        case .connect:
            handleConnectionSuccess()

        case .disconnect:
            handleDisconnection()

        case .error:
            if let errorData = data as? [String: Any],
               let message = errorData["message"] as? String {
                handleServerError(message)
            }

        case .newMessage:
            handleNewMessage(data)

        case .messageRead:
            handleMessageRead(data)

        case .messagesRead:
            handleMessagesRead(data)

        case .messageDeleted:
            handleMessageDeleted(data)

        case .messageSent:
            handleMessageSent(data)

        case .userTyping:
            handleUserTyping(data)

        case .userStoppedTyping:
            handleUserStoppedTyping(data)

        case .userOnline:
            handleUserOnline(data)

        case .contactStatus:
            handleContactStatus(data)

        case .presenceUpdate:
            handlePresenceUpdate(data)

        case .reactionAdded:
            handleReactionAdded(data)

        default:
            // Handle other events
            messageHandlers[event]?(data)
        }
    }

    // MARK: - Event Handlers

    private func handleConnectionSuccess() {
        isConnected = true
        connectionStatus = .connected
        reconnectTimer?.invalidate()

        // Notify observers
        NotificationCenter.default.post(name: .webSocketConnected, object: nil)

        print("✅ WebSocket connected successfully")
    }

    private func handleDisconnection() {
        isConnected = false
        connectionStatus = .disconnected

        NotificationCenter.default.post(name: .webSocketDisconnected, object: nil)

        // Attempt reconnection if it was unexpected
        if authToken != nil {
            scheduleReconnection()
        }
    }

    private func handleServerError(_ message: String) {
        connectionStatus = .error(message)
        print("❌ Server error: \(message)")
    }

    private func handleNewMessage(_ data: Any) {
        guard let messageData = data as? [String: Any] else { return }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(Message.self, from: jsonData)

            // Update unread count
            if !message.isFromCurrentUser {
                unreadMessageCount += 1
            }

            NotificationCenter.default.post(
                name: .newMessageReceived,
                object: message,
                userInfo: ["chatId": message.chatId]
            )

        } catch {
            print("❌ Failed to decode new message: \(error)")
        }
    }

    private func handleMessageRead(_ data: Any) {
        guard let readData = data as? [String: Any],
              let messageId = readData["messageId"] as? String,
              let chatId = readData["chatId"] as? String else { return }

        NotificationCenter.default.post(
            name: .messageRead,
            object: messageId,
            userInfo: ["chatId": chatId]
        )
    }

    private func handleMessagesRead(_ data: Any) {
        guard let readData = data as? [String: Any],
              let chatId = readData["chatId"] as? String,
              let count = readData["count"] as? Int else { return }

        // Update unread count
        unreadMessageCount = max(0, unreadMessageCount - count)

        NotificationCenter.default.post(
            name: .messagesRead,
            object: chatId,
            userInfo: ["count": count]
        )
    }

    private func handleMessageDeleted(_ data: Any) {
        guard let deleteData = data as? [String: Any],
              let messageId = deleteData["messageId"] as? String else { return }

        NotificationCenter.default.post(
            name: .messageDeleted,
            object: messageId
        )
    }

    private func handleMessageSent(_ data: Any) {
        guard let sentData = data as? [String: Any],
              let tempId = sentData["tempId"] as? String,
              let messageId = sentData["messageId"] as? String else { return }

        NotificationCenter.default.post(
            name: .messageSent,
            object: messageId,
            userInfo: ["tempId": tempId]
        )
    }

    private func handleUserTyping(_ data: Any) {
        guard let typingData = data as? [String: Any],
              let userId = typingData["userId"] as? String,
              let chatId = typingData["chatId"] as? String else { return }

        typingUsers[userId] = Date()

        NotificationCenter.default.post(
            name: .userTyping,
            object: userId,
            userInfo: ["chatId": chatId]
        )

        // Auto-remove typing indicator after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.typingUsers.removeValue(forKey: userId)
            NotificationCenter.default.post(
                name: .userStoppedTyping,
                object: userId,
                userInfo: ["chatId": chatId]
            )
        }
    }

    private func handleUserStoppedTyping(_ data: Any) {
        guard let typingData = data as? [String: Any],
              let userId = typingData["userId"] as? String,
              let chatId = typingData["chatId"] as? String else { return }

        typingUsers.removeValue(forKey: userId)

        NotificationCenter.default.post(
            name: .userStoppedTyping,
            object: userId,
            userInfo: ["chatId": chatId]
        )
    }

    private func handleUserOnline(_ data: Any) {
        guard let onlineData = data as? [String: Any],
              let userId = onlineData["userId"] as? String else { return }

        connectedUsers.insert(userId)

        NotificationCenter.default.post(
            name: .userOnline,
            object: userId
        )
    }

    private func handleUserOffline(_ data: Any) {
        guard let offlineData = data as? [String: Any],
              let userId = offlineData["userId"] as? String else { return }

        connectedUsers.remove(userId)

        NotificationCenter.default.post(
            name: .contactStatusChanged,
            object: userId,
            userInfo: ["isOnline": false]
        )
    }

    private func handleTypingIndicator(_ data: Any) {
        guard let typingData = data as? [String: Any],
              let chatId = typingData["chatId"] as? String,
              let userId = typingData["userId"] as? String,
              let isTyping = typingData["isTyping"] as? Bool else { return }

        if isTyping {
            typingUsers[chatId] = Date()
            NotificationCenter.default.post(
                name: .userTyping,
                object: chatId,
                userInfo: ["userId": userId]
            )
        } else {
            typingUsers.removeValue(forKey: chatId)
            NotificationCenter.default.post(
                name: .userStoppedTyping,
                object: chatId,
                userInfo: ["userId": userId]
            )
        }
    }

    private func handleContactStatus(_ data: Any) {
        guard let statusData = data as? [String: Any],
              let userId = statusData["userId"] as? String,
              let isOnline = statusData["isOnline"] as? Bool else { return }

        if isOnline {
            connectedUsers.insert(userId)
        } else {
            connectedUsers.remove(userId)
        }

        NotificationCenter.default.post(
            name: .contactStatusChanged,
            object: userId,
            userInfo: ["isOnline": isOnline]
        )
    }

    private func handlePresenceUpdate(_ data: Any) {
        // Handle presence updates
        NotificationCenter.default.post(name: .presenceUpdated, object: data)
    }

    private func handleReactionAdded(_ data: Any) {
        guard let reactionData = data as? [String: Any] else { return }

        NotificationCenter.default.post(
            name: .reactionAdded,
            object: reactionData
        )
    }

    // MARK: - Utility Methods

    func isUserOnline(_ userId: String) -> Bool {
        return connectedUsers.contains(userId)
    }

    func getTypingUsers(in chatId: String) -> [String] {
        // Filter typing users for specific chat
        return Array(typingUsers.keys)
    }

    func addMessageHandler(for event: String, handler: @escaping (Any) -> Void) {
        messageHandlers[event] = handler
    }

    func removeMessageHandler(for event: String) {
        messageHandlers.removeValue(forKey: event)
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied && !(self?.isConnected ?? false) {
                    self?.reconnect()
                }
            }
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    private func setupMessageHandlers() {
        // Default message handlers can be set up here
    }

    private func setupSocketHandlers() {
        guard let socket = socket else { return }

        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ [WebSocket] Connected successfully!")
            DispatchQueue.main.async {
                self?.handleConnectionSuccess()
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("🔌 [WebSocket] Disconnected")
            DispatchQueue.main.async {
                self?.handleDisconnection()
            }
        }

        socket.on(clientEvent: .error) { [weak self] data, ack in
            print("❌ [WebSocket] Error: \(data)")
            DispatchQueue.main.async {
                self?.connectionStatus = .error("Connection error")
            }
        }

        socket.on(clientEvent: .reconnect) { [weak self] data, ack in
            print("🔄 [WebSocket] Reconnecting...")
            DispatchQueue.main.async {
                self?.connectionStatus = .reconnecting
            }
        }

        // Custom events
        socket.on("new_message") { [weak self] data, ack in
            print("📩 [WebSocket] Received new_message event")
            if let messageData = data.first {
                self?.handleNewMessage(messageData)
            }
        }

        socket.on("message_read") { [weak self] data, ack in
            print("👁️ [WebSocket] Received message_read event")
            if let readData = data.first {
                self?.handleMessageRead(readData)
            }
        }

        socket.on("typing") { [weak self] data, ack in
            print("⌨️ [WebSocket] Received typing event")
            if let typingData = data.first {
                self?.handleTypingIndicator(typingData)
            }
        }

        socket.on("user_online") { [weak self] data, ack in
            print("🟢 [WebSocket] User online event")
            if let userData = data.first {
                self?.handleUserOnline(userData)
            }
        }

        socket.on("user_offline") { [weak self] data, ack in
            print("⚪ [WebSocket] User offline event")
            if let userData = data.first {
                self?.handleUserOffline(userData)
            }
        }
    }

    private func startPingTimer() {
        // Socket.io handles ping/pong automatically, no need for manual implementation
    }

    private func handleConnectionError(_ error: Error) {
        connectionStatus = .error(error.localizedDescription)
        isConnected = false

        scheduleReconnection()
    }

    private func scheduleReconnection() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let webSocketConnected = Notification.Name("webSocketConnected")
    static let webSocketDisconnected = Notification.Name("webSocketDisconnected")
    static let messagesRead = Notification.Name("messagesRead")
    static let messageDeleted = Notification.Name("messageDeleted")
    static let messageSent = Notification.Name("messageSent")
    static let messageSentViaREST = Notification.Name("messageSentViaREST")
    static let userTyping = Notification.Name("userTyping")
    static let userStoppedTyping = Notification.Name("userStoppedTyping")
    static let userOnline = Notification.Name("userOnline")
    static let contactStatusChanged = Notification.Name("contactStatusChanged")
    static let presenceUpdated = Notification.Name("presenceUpdated")
    static let reactionAdded = Notification.Name("reactionAdded")
}