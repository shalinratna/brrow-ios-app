//
//  WebSocketManager.swift
//  Brrow
//
//  Real-time WebSocket messaging implementation
//

import Foundation
import Combine
import Network

class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var unreadMessageCount = 0

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let socketURL = URL(string: "wss://brrow-backend-nodejs-production.up.railway.app/socket.io/")!

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
            connectionStatus = .error("No authentication token")
            return
        }

        authToken = token

        if isConnected {
            return
        }

        connectionStatus = .connecting

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        var request = URLRequest(url: socketURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()

        startReceiving()
        startPingTimer()

        // Send authentication message
        sendAuthMessage()
    }

    func disconnect() {
        connectionStatus = .disconnected
        isConnected = false

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession = nil

        reconnectTimer?.invalidate()
        pingTimer?.invalidate()

        typingUsers.removeAll()
        connectedUsers.removeAll()
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
        let messageData: [String: Any] = [
            "event": SocketEvent.sendMessage.rawValue,
            "data": [
                "chatId": chatId,
                "content": content,
                "messageType": messageType.rawValue,
                "listingId": listingId as Any,
                "tempId": UUID().uuidString
            ]
        ]

        sendMessage(messageData)
    }

    func sendTypingIndicator(chatId: String, isTyping: Bool) {
        let event = isTyping ? SocketEvent.typingStart.rawValue : SocketEvent.typingStop.rawValue
        let messageData: [String: Any] = [
            "event": event,
            "data": [
                "chatId": chatId
            ]
        ]

        sendMessage(messageData)
    }

    func joinChat(chatId: String) {
        let messageData: [String: Any] = [
            "event": SocketEvent.joinChat.rawValue,
            "data": [
                "chatId": chatId
            ]
        ]

        sendMessage(messageData)
    }

    func leaveChat(chatId: String) {
        let messageData: [String: Any] = [
            "event": SocketEvent.leaveChat.rawValue,
            "data": [
                "chatId": chatId
            ]
        ]

        sendMessage(messageData)
    }

    func markMessageAsRead(messageId: String, chatId: String) {
        let messageData: [String: Any] = [
            "event": SocketEvent.markRead.rawValue,
            "data": [
                "messageId": messageId,
                "chatId": chatId
            ]
        ]

        sendMessage(messageData)
    }

    func updatePresence(status: String) {
        let messageData: [String: Any] = [
            "event": SocketEvent.updatePresence.rawValue,
            "data": [
                "status": status
            ]
        ]

        sendMessage(messageData)
    }

    private func sendMessage(_ data: [String: Any]) {
        guard isConnected else {
            print("⚠️ WebSocket not connected, cannot send message")
            // Fallback to REST API for sending messages
            if let eventData = data["data"] as? [String: Any],
               let chatId = eventData["chatId"] as? String,
               let content = eventData["content"] as? String {
                sendMessageViaREST(chatId: chatId, content: content)
            }
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let message = URLSessionWebSocketTask.Message.data(jsonData)

            webSocketTask?.send(message) { [weak self] error in
                if let error = error {
                    print("❌ WebSocket send error: \(error)")
                    DispatchQueue.main.async {
                        self?.handleConnectionError(error)
                    }
                }
            }
        } catch {
            print("❌ Failed to serialize message: \(error)")
        }
    }

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

    private func sendAuthMessage() {
        guard let token = authToken else { return }

        let authData: [String: Any] = [
            "event": "authenticate",
            "data": [
                "token": token
            ]
        ]

        sendMessage(authData)
    }

    // MARK: - Message Receiving

    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                // Continue receiving
                self?.startReceiving()

            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.handleConnectionError(error)
                }
            }
        }
    }

    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            handleDataMessage(data)

        case .string(let string):
            if let data = string.data(using: .utf8) {
                handleDataMessage(data)
            }

        @unknown default:
            print("⚠️ Unknown WebSocket message type received")
        }
    }

    private func handleDataMessage(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let event = json["event"] as? String,
               let eventData = json["data"] {

                DispatchQueue.main.async { [weak self] in
                    self?.processSocketEvent(event: event, data: eventData)
                }
            }
        } catch {
            print("❌ Failed to parse WebSocket message: \(error)")
        }
    }

    // MARK: - Event Processing

    private func processSocketEvent(event: String, data: Any) {
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

    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        let pingMessage = URLSessionWebSocketTask.Message.string("ping")
        webSocketTask?.send(pingMessage) { error in
            if let error = error {
                print("❌ Ping failed: \(error)")
            }
        }
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

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.handleConnectionSuccess()
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async { [weak self] in
            self?.handleDisconnection()
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