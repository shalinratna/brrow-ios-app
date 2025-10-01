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

        Task {
            do {
                let loadedMessages = try await fetchMessages(conversationId: conversationId)
                self.messages = loadedMessages
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
        let message = Message(
            id: UUID().uuidString,
            chatId: conversationId,
            senderId: AuthManager.shared.currentUser?.id ?? "current_user", // CRITICAL FIX: Use User.id (CUID), not apiId
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
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: nil,
            reactions: nil
        )

        messages.append(message)

        // Send to server
        Task {
            do {
                try await sendMessageToServer(message, conversationId: conversationId)

                // CRITICAL FIX: Update conversation preview with latest message
                await MainActor.run {
                    print("✅ [ChatDetailViewModel] Message sent successfully, updating conversation list")
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
                print("❌ [ChatDetailViewModel] Failed to send message: \(error)")
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
        // TODO: Implement real image upload via APIClient
        print("Image upload not yet implemented")
    }

    private func uploadAndSendVoice(_ audioURL: URL, message: Message, conversationId: String) async throws {
        // TODO: Implement real voice upload via APIClient
        print("Voice upload not yet implemented")
    }

    private func uploadAndSendVideo(_ videoURL: URL, message: Message, conversationId: String) async throws {
        // TODO: Implement real video upload via APIClient
        print("Video upload not yet implemented")
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}