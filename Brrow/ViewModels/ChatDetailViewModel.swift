//
//  ChatDetailViewModel.swift
//  Brrow
//
//  Chat detail view model for enhanced messaging
//

import Foundation
import UIKit
import AVFoundation
import Combine

@MainActor
class ChatDetailViewModel: ObservableObject {
    @Published var messages: [EnhancedChatMessage] = []
    @Published var isUserOnline = false
    @Published var isRecording = false
    @Published var recordingDuration = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    func loadMessages(for conversationId: String) {
        isLoading = true
        
        Task {
            do {
                let loadedMessages = try await fetchMessages(conversationId: conversationId)
                self.messages = loadedMessages
                self.isUserOnline = true // Simulate online status
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    func sendTextMessage(_ text: String, to conversationId: String) {
        let message = EnhancedChatMessage(
            id: UUID().uuidString,
            senderId: AuthManager.shared.currentUser?.apiId ?? "current_user",
            receiverId: "other_user",
            content: text,
            type: .text,
            mediaUrl: nil,
            createdAt: Date(),
            isRead: false
        )
        
        messages.append(message)
        
        // Send to server
        Task {
            try await sendMessageToServer(message, conversationId: conversationId)
        }
    }
    
    func sendImageMessage(_ image: UIImage, to conversationId: String) {
        let message = EnhancedChatMessage(
            id: UUID().uuidString,
            senderId: AuthManager.shared.currentUser?.apiId ?? "current_user",
            receiverId: "other_user",
            content: "",
            type: .image,
            mediaUrl: "local_image_\(UUID().uuidString)",
            createdAt: Date(),
            isRead: false
        )
        
        messages.append(message)
        
        // Upload image and send to server
        Task {
            try await uploadAndSendImage(image, message: message, conversationId: conversationId)
        }
    }
    
    func sendMediaMessage(data: Data, conversationId: String, receiverId: String, isVideo: Bool) async throws {
        // Create multipart form data request
        var request = URLRequest(url: URL(string: "https://brrowapp.com/api_upload_media_message.php")!)
        request.httpMethod = "POST"
        
        // Add auth headers
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let userId = AuthManager.shared.currentUser?.apiId {
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
        
        let message = EnhancedChatMessage(
            id: uploadData.messageId,
            senderId: AuthManager.shared.currentUser?.apiId ?? "",
            receiverId: receiverId,
            content: mediaDataString,
            type: isVideo ? .video : .image,
            mediaUrl: uploadData.media.url,
            createdAt: Date(),
            isRead: false
        )
        
        await MainActor.run {
            self.messages.append(message)
        }
    }
    
    func sendVoiceMessage(_ audioURL: URL, to conversationId: String) {
        let message = EnhancedChatMessage(
            id: UUID().uuidString,
            senderId: AuthManager.shared.currentUser?.apiId ?? "current_user",
            receiverId: "other_user",
            content: "",
            type: .voice,
            mediaUrl: audioURL.absoluteString,
            createdAt: Date(),
            isRead: false
        )
        
        messages.append(message)
        
        // Upload audio and send to server
        Task {
            try await uploadAndSendVoice(audioURL, message: message, conversationId: conversationId)
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
    
    private func fetchMessages(conversationId: String) async throws -> [EnhancedChatMessage] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return [
            EnhancedChatMessage(
                id: "1",
                senderId: "other_user",
                receiverId: AuthManager.shared.currentUser?.apiId ?? "current_user",
                content: "Hi! Is the camera still available?",
                type: .text,
                mediaUrl: nil,
                createdAt: Date().addingTimeInterval(-300),
                isRead: true
            ),
            EnhancedChatMessage(
                id: "2",
                senderId: AuthManager.shared.currentUser?.apiId ?? "current_user",
                receiverId: "other_user",
                content: "Yes, it's available. Would you like to borrow it this weekend?",
                type: .text,
                mediaUrl: nil,
                createdAt: Date().addingTimeInterval(-200),
                isRead: true
            )
        ]
    }
    
    private func sendMessageToServer(_ message: EnhancedChatMessage, conversationId: String) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Message sent: \(message.content)")
    }
    
    private func uploadAndSendImage(_ image: UIImage, message: EnhancedChatMessage, conversationId: String) async throws {
        // Simulate image upload
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Image uploaded and sent")
    }
    
    private func uploadAndSendVoice(_ audioURL: URL, message: EnhancedChatMessage, conversationId: String) async throws {
        // Simulate voice upload
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Voice message uploaded and sent")
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}