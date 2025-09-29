//
//  EnhancedChatDetailView.swift
//  Brrow
//
//  Rich Messaging with Media, Voice, Video Calls
//

import SwiftUI
import AVFoundation
import CallKit

struct EnhancedChatDetailView: View {
    let conversation: Conversation
    let initialMessage: String?
    @StateObject private var viewModel = ChatDetailViewModel()
    @State private var messageText = ""

    init(conversation: Conversation, initialMessage: String? = nil) {
        self.conversation = conversation
        self.initialMessage = initialMessage
        self._messageText = State(initialValue: initialMessage ?? "")
    }
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isRecordingVoice = false
    @State private var showingVideoCall = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header with video call button
            chatHeader
            
            // Messages list
            messagesScrollView
            
            // Message input
            messageInputView
        }
        .background(Theme.Colors.background)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadMessages(for: conversation.id)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                viewModel.sendImageMessage(image, to: conversation.id)
            }
        }
        .sheet(isPresented: $showingCamera) {
            BrrowCameraView()
        }
        .fullScreenCover(isPresented: $showingVideoCall) {
            VideoCallView(conversation: conversation)
        }
        #if !targetEnvironment(macCatalyst) && !os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        #endif
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Navigate back
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // Profile picture
            BrrowAsyncImage(url: conversation.otherUser.profilePicture) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .overlay(
                        Text(String(conversation.otherUser.username.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.otherUser.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isUserOnline ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    
                    Text(viewModel.isUserOnline ? "Online" : "Offline")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Video call button
            Button(action: {
                startVideoCall()
            }) {
                Image(systemName: "video.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(16)
            }
            
            // Menu button
            Button(action: {
                // Show menu options
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.surface)
        .shadow(color: Theme.Shadows.card.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Messages Scroll View
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            let scrollContent = ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        let isFromCurrentUser = message.senderId == AuthManager.shared.currentUser?.apiId
                        EnhancedMessageBubble(
                            message: message.toEnhancedChatMessage(),
                            isFromCurrentUser: isFromCurrentUser
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            scrollContent
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
        }
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
    }
    
    // MARK: - Message Input
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Attachment button
                Menu {
                    Button(action: { showingImagePicker = true }) {
                        Label("Photo Library", systemImage: "photo")
                    }
                    
                    Button(action: { showingCamera = true }) {
                        Label("Camera", systemImage: "camera")
                    }
                    
                    Button(action: { /* Send location */ }) {
                        Label("Location", systemImage: "location")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary)
                }
                
                // Message text field
                HStack(spacing: 8) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .lineLimit(1...4)
                        .font(.system(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    
                    if messageText.isEmpty {
                        // Voice recording button
                        Button(action: {
                            if isRecordingVoice {
                                stopVoiceRecording()
                            } else {
                                startVoiceRecording()
                            }
                        }) {
                            let iconName = isRecordingVoice ? "stop.circle.fill" : "mic.circle.fill"
                            let iconColor = isRecordingVoice ? Color.red : Theme.Colors.primary
                            let iconScale = isRecordingVoice ? 1.2 : 1.0

                            Image(systemName: iconName)
                                .font(.system(size: 24))
                                .foregroundColor(iconColor)
                                .scaleEffect(iconScale)
                                .animation(.easeInOut(duration: 0.1), value: isRecordingVoice)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                )
                
                // Send button
                if !messageText.isEmpty {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.Colors.background)
            
            if isRecordingVoice {
                voiceRecordingIndicator
            }
        }
    }
    
    // MARK: - Voice Recording Indicator
    private var voiceRecordingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(viewModel.isRecording ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isRecording)
                
                Text("Recording... \(viewModel.recordingDuration)s")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            Button("Cancel") {
                cancelVoiceRecording()
            }
            .font(.system(size: 14))
            .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendTextMessage(messageText, to: conversation.id)
        
        // Track achievement for sending message
        AchievementManager.shared.trackMessageSent()
        
        messageText = ""
    }
    
    private func startVoiceRecording() {
        isRecordingVoice = true
        viewModel.startVoiceRecording()
    }
    
    private func stopVoiceRecording() {
        isRecordingVoice = false
        viewModel.stopVoiceRecording { audioURL in
            if let url = audioURL {
                viewModel.sendVoiceMessage(url, to: conversation.id)
            }
        }
    }
    
    private func cancelVoiceRecording() {
        isRecordingVoice = false
        viewModel.cancelVoiceRecording()
    }
    
    private func startVideoCall() {
        // In a real app, this would initiate a video call
        showingVideoCall = true
    }
}

// MARK: - Enhanced Message Bubble
struct EnhancedMessageBubble: View {
    let message: EnhancedChatMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content based on type
                messageContent
                
                // Message metadata
                HStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if isFromCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 11))
                            .foregroundColor(message.isRead ? Theme.Colors.primary : .secondary)
                    }
                }
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.type {
        case .text:
            textMessageView
        case .image:
            imageMessageView
        case .video:
            videoMessageView
        case .voice:
            voiceMessageView
        case .location:
            locationMessageView
        case .system:
            systemMessageView
        }
    }
    
    private var textMessageView: some View {
        Text(message.content)
            .font(.system(size: 16))
            .foregroundColor(isFromCurrentUser ? .white : Theme.Colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isFromCurrentUser ? Theme.Colors.primary : Theme.Colors.surface)
            )
    }
    
    private var imageMessageView: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 8) {
            BrrowAsyncImage(url: message.mediaUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(maxWidth: 200, maxHeight: 200)
            .cornerRadius(12)
            .clipped()
            
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.surface)
                    )
            }
        }
    }
    
    private var videoMessageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = URL(string: message.content) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        )
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(maxWidth: 200, maxHeight: 150)
                .cornerRadius(12)
                .clipped()
            }
        }
    }
    
    private var voiceMessageView: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Play/pause voice message
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isFromCurrentUser ? .white : Theme.Colors.primary)
            }
            
            // Waveform visualization
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(isFromCurrentUser ? Color.white.opacity(0.7) : Theme.Colors.primary.opacity(0.7))
                        .frame(width: 2, height: CGFloat.random(in: 4...16))
                        .cornerRadius(1)
                }
            }
            
            Text("0:15")
                .font(.system(size: 12))
                .foregroundColor(isFromCurrentUser ? .white.opacity(0.8) : Theme.Colors.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isFromCurrentUser ? Theme.Colors.primary : Theme.Colors.surface)
        )
    }
    
    private var locationMessageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Map thumbnail would go here
            Rectangle()
                .fill(Theme.Colors.surface)
                .frame(height: 120)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.Colors.primary)
                        Text("Location Shared")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.text)
                    }
                )
            
            Text("Current Location")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
        }
        .frame(width: 200)
    }
    
    private var systemMessageView: some View {
        Text(message.content)
            .font(.system(size: 12))
            .foregroundColor(Theme.Colors.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.surface.opacity(0.5))
            )
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date()) // Would use message.createdAt
    }
}

// MARK: - Enhanced Chat Message Model
struct EnhancedChatMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let createdAt: Date
    let isRead: Bool
    
    enum MessageType: String, Codable {
        case text = "text"
        case image = "image"
        case video = "video"
        case voice = "voice"
        case location = "location"
        case system = "system"
    }
}

