//
//  ChatDetailViewModel.swift
//  Brrow
//
//  Real-time chat detail view model with full messaging functionality
//

import Foundation
import UIKit
import AVFoundation
import Combine
import SwiftUI

@MainActor
class ChatDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var typingUsers: [String] = []
    @Published var connectionStatus: WebSocketManager.ConnectionStatus = .disconnected
    @Published var unreadCount = 0
    @Published var isUserOnline = false
    @Published var isRecording = false
    @Published var recordingDuration = 0
    @Published var otherUserIsTyping = false
    @Published var cachedOtherUserProfile: User? = nil  // ✅ PERFORMANCE: Pre-loaded profile cache

    private var conversation: Conversation?
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let webSocketManager = WebSocketManager.shared
    private let authManager = AuthManager.shared

    // Message management
    private var pendingMessages: [String: Message] = [:]  // tempId -> Message
    private var messageCache: [String: Message] = [:]     // messageId -> Message

    // Audio recording
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    
    func loadMessages(for conversationId: String) {
        isLoading = true
        conversation = Conversation(
            id: conversationId,
            otherUser: ConversationUser(id: "", username: "", profilePicture: nil, isVerified: false),
            lastMessage: nil,
            unreadCount: 0,
            updatedAt: ""
        )

        // Listen for REST API message sends to refresh
        NotificationCenter.default.addObserver(
            forName: .messageSentViaREST,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let chatId = notification.object as? String,
               chatId == conversationId {
                self?.refreshMessages(for: conversationId)
            }
        }

        // CRITICAL FIX: Listen for user profile updates to refresh message sender info
        // When a user updates their username or profile picture, refresh messages
        // to show the updated information in the chat
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .sink { [weak self] _ in
                print("👤 [ChatDetailViewModel] userDidUpdate notification received!")
                print("🔄 [ChatDetailViewModel] Refreshing messages to show updated profile")
                self?.refreshMessages(for: conversationId)
            }
            .store(in: &cancellables)

        // Listen for typing indicators via WebSocket
        NotificationCenter.default.publisher(for: .userTyping)
            .sink { [weak self] notification in
                if let chatId = notification.userInfo?["chatId"] as? String,
                   chatId == conversationId {
                    print("⌨️ [ChatDetailViewModel] Other user is typing in chat \(chatId)")
                    self?.otherUserIsTyping = true
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .userStoppedTyping)
            .sink { [weak self] notification in
                if let chatId = notification.userInfo?["chatId"] as? String,
                   chatId == conversationId {
                    print("⌨️ [ChatDetailViewModel] Other user stopped typing in chat \(chatId)")
                    self?.otherUserIsTyping = false
                }
            }
            .store(in: &cancellables)

        // Listen for new messages via WebSocket
        NotificationCenter.default.publisher(for: .newMessageReceived)
            .sink { [weak self] notification in
                if let message = notification.object as? Message,
                   message.chatId == conversationId {
                    print("📩 [ChatDetailViewModel] New message received for this chat")
                    self?.refreshMessages(for: conversationId)
                }
            }
            .store(in: &cancellables)

        // ✅ READ RECEIPTS: Listen for message read notifications
        // When recipient reads a message, sender receives this notification to update UI
        NotificationCenter.default.publisher(for: .messageRead)
            .sink { [weak self] notification in
                guard let messageId = notification.object as? String,
                      let chatId = notification.userInfo?["chatId"] as? String,
                      chatId == conversationId else { return }

                print("👁️ [ChatDetailViewModel] Message \(messageId) was read in chat \(chatId)")

                // Update message status to .read on sender's side
                if let index = self?.messages.firstIndex(where: { $0.id == messageId }) {
                    var updatedMessage = self?.messages[index]
                    updatedMessage?.sendStatus = .read
                    self?.messages[index] = updatedMessage ?? self!.messages[index]
                    print("✅ [ChatDetailViewModel] Updated message status to .read")
                }
            }
            .store(in: &cancellables)

        Task {
            do {
                // Fetch messages first
                let loadedMessages = try await fetchMessages(conversationId: conversationId)
                self.messages = loadedMessages

                // ✅ PERFORMANCE: Now fetch profile concurrently with marking as read
                async let profileFetch = fetchAndCacheOtherUserProfile(from: loadedMessages)
                async let markAsRead = markUnreadMessagesAsRead(conversationId: conversationId)

                _ = await profileFetch  // Don't throw if profile fetch fails
                await markAsRead
                self.isUserOnline = true // TODO: Implement real online status
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    private func refreshMessages(for conversationId: String) {
        Task {
            do {
                let loadedMessages = try await fetchMessages(conversationId: conversationId)
                self.messages = loadedMessages
            } catch {
                print("Failed to refresh messages: \(error)")
            }
        }
    }
    
    func sendTextMessage(_ text: String, to conversationId: String) {
        // Generate temporary ID for optimistic UI
        let tempId = UUID().uuidString

        // OPTIMISTIC UI: Create message with .sending status
        var message = Message(
            id: tempId,
            chatId: conversationId,
            senderId: AuthManager.shared.currentUser?.id ?? "current_user",
            receiverId: "other_user",
            content: text,
            messageType: .text,
            mediaUrl: nil,
            thumbnailUrl: nil,
            listingId: nil,
            isRead: false,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: nil,
            deliveredAt: nil,
            readAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: nil,
            reactions: nil,
            tempId: tempId,
            sendStatus: MessageSendStatus.sending  // ✅ OPTIMISTIC: Show as sending
        )

        // Add to messages immediately (optimistic UI)
        messages.append(message)

        // Store in pending messages for tracking
        pendingMessages[tempId] = message

        // Track analytics
        AnalyticsService.shared.trackMessageSent(messageType: "text", conversationId: conversationId)

        // Send to server
        Task {
            do {
                // Send to server and get real message ID back
                try await sendMessageToServer(message, conversationId: conversationId)

                // ✅ SUCCESS: Update message status to .sent, then .delivered
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.tempId == tempId || $0.id == tempId }) {
                        var updatedMessage = messages[index]
                        updatedMessage.sendStatus = .sent
                        messages[index] = updatedMessage
                        print("✅ [ChatDetailViewModel] Message sent successfully (tempId: \(tempId))")

                        // ✅ AUTO-DELIVER: Messages are delivered immediately after being sent
                        // (Backend sets delivered_at when creating message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            guard let self = self else { return }
                            if let deliverIndex = self.messages.firstIndex(where: { $0.tempId == tempId || $0.id == tempId }) {
                                var deliveredMessage = self.messages[deliverIndex]
                                deliveredMessage.sendStatus = .delivered
                                self.messages[deliverIndex] = deliveredMessage
                                print("✅ [ChatDetailViewModel] Message delivered (tempId: \(tempId))")
                            }
                        }
                    }

                    // Remove from pending
                    pendingMessages.removeValue(forKey: tempId)

                    // Update conversation list
                    NotificationCenter.default.post(
                        name: .messageSent,
                        object: conversationId,
                        userInfo: [
                            "message": message,
                            "conversationId": conversationId
                        ]
                    )
                }
            } catch {
                // ❌ FAILED: Update message status to .failed
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.tempId == tempId || $0.id == tempId }) {
                        var failedMessage = messages[index]
                        failedMessage.sendStatus = .failed
                        messages[index] = failedMessage
                        print("❌ [ChatDetailViewModel] Message failed to send (tempId: \(tempId)): \(error)")
                    }
                }
            }
        }
    }
    
    func sendImageMessage(_ image: UIImage, to conversationId: String) {
        let message = Message(
            id: UUID().uuidString,
            chatId: conversationId,
            senderId: AuthManager.shared.currentUser?.id ?? "current_user", // CRITICAL FIX: Use User.id (CUID), not apiId
            receiverId: "other_user",
            content: "",
            messageType: .image,
            mediaUrl: "local_image_\(UUID().uuidString)",
            thumbnailUrl: nil,
            listingId: nil,
            isRead: false,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: nil,
            deliveredAt: nil,
            readAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: nil,
            reactions: nil
        )

        messages.append(message)
        
        // Upload image and send to server
        Task {
            try await uploadAndSendImage(image, message: message, conversationId: conversationId)
        }
    }
    
    func sendMediaMessage(data: Data, conversationId: String, receiverId: String, isVideo: Bool) async throws {
        // Create multipart form data request
        let baseURL = await APIEndpointManager.shared.getBestEndpoint()
        var request = URLRequest(url: URL(string: "\(baseURL)/api/messages/media")!)
        request.httpMethod = "POST"
        
        // Add auth headers
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let userId = AuthManager.shared.currentUser?.id { // CRITICAL FIX: Use User.id (CUID), not apiId
            request.setValue(userId, forHTTPHeaderField: "X-User-API-ID")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart body
        var body = Data()
        
        // Add conversation ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"conversation_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(conversationId)\r\n".data(using: .utf8)!)
        
        // Add receiver ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"receiver_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(receiverId)\r\n".data(using: .utf8)!)
        
        // Add media file
        let filename = isVideo ? "video.mp4" : "image.jpg"
        let mimeType = isVideo ? "video/mp4" : "image/jpeg"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"media\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Send request
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BrrowAPIError.serverError("Failed to upload media")
        }
        
        // Parse response
        let apiResponse = try JSONDecoder().decode(APIResponse<MediaUploadResponse>.self, from: responseData)
        
        guard apiResponse.success, let uploadData = apiResponse.data else {
            throw BrrowAPIError.serverError(apiResponse.message ?? "Upload failed")
        }
        
        // Create local message
        let mediaData = MediaMessageData(
            url: uploadData.media.url,
            thumbnailUrl: uploadData.media.thumbnailUrl,
            mimeType: uploadData.media.mimeType,
            size: uploadData.media.size,
            originalName: uploadData.media.originalName
        )
        
        let mediaDataJson = try JSONEncoder().encode(mediaData)
        let mediaDataString = String(data: mediaDataJson, encoding: .utf8) ?? "{}"
        
        let message = Message(
            id: uploadData.messageId,
            chatId: conversationId,
            senderId: AuthManager.shared.currentUser?.id ?? "", // CRITICAL FIX: Use User.id (CUID), not apiId
            receiverId: receiverId,
            content: mediaDataString,
            messageType: isVideo ? .video : .image,
            mediaUrl: uploadData.media.url,
            thumbnailUrl: uploadData.media.thumbnailUrl,
            listingId: nil,
            isRead: false,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: nil,
            deliveredAt: nil,
            readAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: nil,
            reactions: nil
        )

        await MainActor.run {
            self.messages.append(message)
        }
    }
    
    func sendVoiceMessage(_ audioURL: URL, to conversationId: String) {
        let message = Message(
            id: UUID().uuidString,
            chatId: conversationId,
            senderId: AuthManager.shared.currentUser?.id ?? "current_user", // CRITICAL FIX: Use User.id (CUID), not apiId
            receiverId: "other_user",
            content: "",
            messageType: .audio,
            mediaUrl: audioURL.absoluteString,
            thumbnailUrl: nil,
            listingId: nil,
            isRead: false,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: nil,
            deliveredAt: nil,
            readAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: nil,
            reactions: nil
        )

        messages.append(message)

        // Upload audio and send to server
        Task {
            try await uploadAndSendVoice(audioURL, message: message, conversationId: conversationId)
        }
    }

    func sendVideoMessage(_ videoURL: URL, to conversationId: String) {
        let message = Message(
            id: UUID().uuidString,
            chatId: conversationId,
            senderId: AuthManager.shared.currentUser?.id ?? "current_user", // CRITICAL FIX: Use User.id (CUID), not apiId
            receiverId: "other_user",
            content: "",
            messageType: .video,
            mediaUrl: videoURL.absoluteString,
            thumbnailUrl: nil,
            listingId: nil,
            isRead: false,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: nil,
            deliveredAt: nil,
            readAt: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: nil,
            reactions: nil
        )

        messages.append(message)

        // Upload video and send to server
        Task {
            try await uploadAndSendVideo(videoURL, message: message, conversationId: conversationId)
        }
    }

    func sendTypingIndicator(chatId: String, isTyping: Bool) {
        // Send typing indicator via WebSocket
        webSocketManager.sendTypingIndicator(chatId: chatId, isTyping: isTyping)
    }

    /// Retry sending a failed message
    func retryFailedMessage(_ message: Message) {
        guard let index = messages.firstIndex(where: { $0.id == message.id || $0.tempId == message.tempId }) else {
            print("❌ [ChatDetailViewModel] Failed message not found")
            return
        }

        // Update status to .sending
        var retryingMessage = messages[index]
        retryingMessage.sendStatus = .sending
        messages[index] = retryingMessage

        print("🔄 [ChatDetailViewModel] Retrying message (id: \(message.id))")

        // Retry sending
        Task {
            do {
                try await sendMessageToServer(retryingMessage, conversationId: retryingMessage.chatId)

                // ✅ SUCCESS: Update to .sent
                await MainActor.run {
                    if let updatedIndex = messages.firstIndex(where: { $0.id == message.id || $0.tempId == message.tempId }) {
                        var successMessage = messages[updatedIndex]
                        successMessage.sendStatus = .sent
                        messages[updatedIndex] = successMessage
                        print("✅ [ChatDetailViewModel] Message retry successful")
                    }
                }
            } catch {
                // ❌ FAILED AGAIN: Update to .failed
                await MainActor.run {
                    if let failedIndex = messages.firstIndex(where: { $0.id == message.id || $0.tempId == message.tempId }) {
                        var failedMessage = messages[failedIndex]
                        failedMessage.sendStatus = .failed
                        messages[failedIndex] = failedMessage
                        print("❌ [ChatDetailViewModel] Message retry failed: \(error)")
                    }
                }
            }
        }
    }
    
    func startVoiceRecording() {
        isRecording = true
        recordingDuration = 0
        
        // Setup audio recording
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            // Start timer
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopVoiceRecording(completion: @escaping (URL?) -> Void) {
        isRecording = false
        recordingTimer?.invalidate()
        audioRecorder?.stop()
        
        if let audioRecorder = audioRecorder {
            completion(audioRecorder.url)
        } else {
            completion(nil)
        }
    }
    
    func cancelVoiceRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    // MARK: - Private Methods
    
    private func fetchMessages(conversationId: String) async throws -> [Message] {
        return try await apiClient.fetchMessages(conversationId: conversationId)
    }

    /// ✅ PERFORMANCE: Fetch and cache the other user's profile from message list
    private func fetchAndCacheOtherUserProfile(from messages: [Message]) async {
        do {
            guard !messages.isEmpty,
                  let currentUserId = authManager.currentUser?.id else {
                print("⚠️ [ChatDetailViewModel] Cannot fetch profile: no messages or no current user")
                return
            }

            // Find the other user's ID from the first message
            let firstMessage = messages.first!
            let otherUserId = firstMessage.senderId == currentUserId ? firstMessage.receiverId : firstMessage.senderId

            guard let otherUserId = otherUserId else {
                print("⚠️ [ChatDetailViewModel] Cannot determine other user ID")
                return
            }

            print("👤 [ChatDetailViewModel] Pre-loading profile for user: \(otherUserId)")

            // Fetch the profile
            let profile = try await apiClient.fetchUserProfile(userId: otherUserId)

            await MainActor.run {
                self.cachedOtherUserProfile = profile
                print("✅ [ChatDetailViewModel] Profile cached successfully for: \(profile.username)")
            }
        } catch {
            print("❌ [ChatDetailViewModel] Failed to cache profile: \(error)")
            // Don't throw - profile caching is optional
        }
    }
    
    private func sendMessageToServer(_ message: Message, conversationId: String) async throws {
        let _ = try await apiClient.sendMessage(
            conversationId: conversationId,
            content: message.content,
            messageType: message.messageType,
            mediaUrl: message.mediaUrl,
            thumbnailUrl: message.thumbnailUrl,
            listingId: message.listingId
        )
        print("Message sent: \(message.content)")
    }
    
    private func uploadAndSendImage(_ image: UIImage, message: Message, conversationId: String) async throws {
        // Compress image before upload
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to compress image")
            return
        }

        // Upload image to backend
        let baseURL = await APIEndpointManager.shared.getBestEndpoint()
        guard let url = URL(string: "\(baseURL)/api/messages/upload/image") else {
            print("❌ Invalid upload URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Add auth headers
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Upload failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }

            // Parse response to get image URL
            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let data = json["data"] as? [String: Any],
               let imageUrl = data["url"] as? String {

                // Send message with image URL
                let _ = try await apiClient.sendMessage(
                    conversationId: conversationId,
                    content: "",
                    messageType: .image,
                    mediaUrl: imageUrl,
                    thumbnailUrl: nil,
                    listingId: nil
                )

                print("✅ Image message sent successfully")

                // Refresh messages to show the sent image
                await refreshMessages(for: conversationId)
            }
        } catch {
            print("❌ Image upload error: \(error)")
        }
    }

    private func uploadAndSendVoice(_ audioURL: URL, message: Message, conversationId: String) async throws {
        // Read audio file data
        guard let audioData = try? Data(contentsOf: audioURL) else {
            print("❌ Failed to read audio file")
            return
        }

        // Upload to backend (using same pattern as image)
        let baseURL = await APIEndpointManager.shared.getBestEndpoint()
        guard let url = URL(string: "\(baseURL)/api/messages/upload/audio") else {
            print("❌ Invalid upload URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Upload failed")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let data = json["data"] as? [String: Any],
               let audioUrl = data["url"] as? String {

                let _ = try await apiClient.sendMessage(
                    conversationId: conversationId,
                    content: "",
                    messageType: .audio,
                    mediaUrl: audioUrl,
                    thumbnailUrl: nil,
                    listingId: nil
                )

                await refreshMessages(for: conversationId)
            }
        } catch {
            print("❌ Audio upload error: \(error)")
        }
    }

    private func uploadAndSendVideo(_ videoURL: URL, message: Message, conversationId: String) async throws {
        guard let videoData = try? Data(contentsOf: videoURL) else {
            print("❌ Failed to read video file")
            return
        }

        let baseURL = await APIEndpointManager.shared.getBestEndpoint()
        guard let url = URL(string: "\(baseURL)/api/messages/upload/video") else {
            print("❌ Invalid upload URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Upload failed")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let data = json["data"] as? [String: Any],
               let videoUrl = data["url"] as? String {

                let _ = try await apiClient.sendMessage(
                    conversationId: conversationId,
                    content: "",
                    messageType: .video,
                    mediaUrl: videoUrl,
                    thumbnailUrl: data["thumbnailUrl"] as? String,
                    listingId: nil
                )

                await refreshMessages(for: conversationId)
            }
        } catch {
            print("❌ Video upload error: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    // MARK: - Read Receipts

    /// Mark all unread messages in a conversation as read
    func markUnreadMessagesAsRead(conversationId: String) async {
        guard let currentUserId = authManager.currentUser?.id else {
            print("❌ [ChatDetailViewModel] No current user ID")
            return
        }

        // Get unread messages that were sent to the current user
        let unreadMessages = messages.filter { message in
            !message.isRead && message.receiverId == currentUserId
        }

        guard !unreadMessages.isEmpty else {
            print("✅ [ChatDetailViewModel] No unread messages to mark as read")
            return
        }

        print("📖 [ChatDetailViewModel] Marking \(unreadMessages.count) messages as read")

        // Mark each message as read via API
        for message in unreadMessages {
            await markMessageAsRead(messageId: message.id)
        }

        // Notify UnifiedNotificationService to refresh unread counts
        await MainActor.run {
            NotificationCenter.default.post(
                name: .messageRead,
                object: conversationId
            )
        }
    }

    /// Mark a single message as read
    private func markMessageAsRead(messageId: String) async {
        guard let chatId = conversation?.id else {
            print("❌ [ChatDetailViewModel] No conversation ID available")
            return
        }

        do {
            struct MarkReadResponse: Codable {
                let success: Bool
                let data: Message?
                let message: String?
            }

            let response = try await apiClient.performRequest(
                endpoint: "api/messages/messages/\(messageId)/read",
                method: "PUT",
                responseType: MarkReadResponse.self
            )

            if response.success {
                print("✅ [ChatDetailViewModel] Message \(messageId) marked as read")

                // ✅ READ RECEIPTS: Notify sender via WebSocket that message was read
                webSocketManager.markMessageAsRead(messageId: messageId, chatId: chatId)

                // Update local message state
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == messageId }) {
                        var updatedMessage = messages[index]
                        // Update via reflection or create new message with updated isRead
                        // Since Message struct properties might be immutable, we need to replace
                        let newMessage = Message(
                            id: updatedMessage.id,
                            chatId: updatedMessage.chatId,
                            senderId: updatedMessage.senderId,
                            receiverId: updatedMessage.receiverId,
                            content: updatedMessage.content,
                            messageType: updatedMessage.messageType,
                            mediaUrl: updatedMessage.mediaUrl,
                            thumbnailUrl: updatedMessage.thumbnailUrl,
                            listingId: updatedMessage.listingId,
                            isRead: true,
                            isEdited: updatedMessage.isEdited,
                            editedAt: updatedMessage.editedAt,
                            deletedAt: updatedMessage.deletedAt,
                            sentAt: updatedMessage.sentAt,
                            deliveredAt: updatedMessage.deliveredAt,
                            readAt: updatedMessage.readAt,
                            createdAt: updatedMessage.createdAt,
                            sender: updatedMessage.sender,
                            reactions: updatedMessage.reactions
                        )
                        messages[index] = newMessage
                    }
                }
            } else {
                print("⚠️ [ChatDetailViewModel] Failed to mark message as read: \(response.message ?? "Unknown error")")
            }
        } catch {
            print("❌ [ChatDetailViewModel] Error marking message as read: \(error)")
        }
    }
}