//
//  ChatDetailView.swift
//  Brrow
//
//  Chat conversation detail view
//

import SwiftUI
import PhotosUI

struct ChatDetailView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatDetailViewModel()
    @State private var messageText = ""
    @State private var isKeyboardVisible = false
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isMessageFieldFocused: Bool
    @State private var selectedPhotosItem: PhotosPickerItem? = nil
    @State private var showingMediaOptions = false
    @State private var isUploadingMedia = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Header
            chatHeader
            
            // Messages List
            messagesScrollView
            
            // Message Input
            messageInputBar
        }
        .navigationBarHidden(true)
        .background(Theme.Colors.background)
        .onAppear {
            viewModel.loadMessages(for: conversation.id)
        }
        .onChange(of: selectedPhotosItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await uploadMedia(data: data, isVideo: false)
                }
            }
        }
        .overlay(
            Group {
                if isUploadingMedia {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                Text("Uploading media...")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .padding(40)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                        )
                }
            }
        )
    }
    
    private var chatHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // User Avatar
            if let profilePicture = conversation.otherUser.profilePicture, !profilePicture.isEmpty {
                AsyncImage(url: URL(string: profilePicture)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Theme.Colors.surface)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Theme.Colors.surface)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(conversation.otherUser.username.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.otherUser.username)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                
                if conversation.otherUser.isVerified ?? false {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.primary)
                        Text("Verified")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            // More Options
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.text)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isOwnMessage: message.senderId == AuthManager.shared.currentUser?.apiId
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .background(Theme.Colors.background)
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInputBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Attachment Button
            Menu {
                PhotosPicker(selection: $selectedPhotosItem,
                            matching: .images,
                            photoLibrary: .shared()) {
                    Label("Choose Photo", systemImage: "photo")
                }
                
                PhotosPicker(selection: $selectedPhotosItem,
                            matching: .videos,
                            photoLibrary: .shared()) {
                    Label("Choose Video", systemImage: "video")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // Message Field
            HStack {
                TextField("Type a message...", text: $messageText)
                    .focused($isMessageFieldFocused)
                    .font(.system(size: 16))
                    .onSubmit {
                        sendMessage()
                    }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.surface)
            .cornerRadius(20)
            
            // Send Button
            Button(action: sendMessage) {
                Image(systemName: messageText.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(messageText.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.primary)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.background)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendTextMessage(messageText, to: conversation.id)
        
        messageText = ""
    }
    
    private func uploadMedia(data: Data, isVideo: Bool) async {
        await MainActor.run {
            isUploadingMedia = true
        }
        
        do {
            // Check user's tier and size limits
            let sizeLimit = getUserSizeLimit()
            if data.count > sizeLimit {
                await MainActor.run {
                    isUploadingMedia = false
                    // Show error alert
                    showSizeLimitError(currentSize: data.count, limit: sizeLimit)
                }
                return
            }
            
            // Upload media using the view model
            try await viewModel.sendMediaMessage(
                data: data,
                conversationId: conversation.id,
                receiverId: conversation.otherUser.apiId ?? "",
                isVideo: isVideo
            )
            
            await MainActor.run {
                isUploadingMedia = false
            }
        } catch {
            await MainActor.run {
                isUploadingMedia = false
                // TODO: Show error alert
                print("Failed to upload media: \(error)")
            }
        }
    }
    
    private func getUserSizeLimit() -> Int {
        // Get user's subscription tier from AuthManager
        let user = AuthManager.shared.currentUser
        if user?.hasGreenMembership == true {
            return 5 * 1024 * 1024 // 5MB for Green members
        } else {
            return 3 * 1024 * 1024 // 3MB for free users
        }
    }
    
    private func showSizeLimitError(currentSize: Int, limit: Int) {
        let currentMB = Double(currentSize) / (1024 * 1024)
        let limitMB = Double(limit) / (1024 * 1024)
        // TODO: Show proper alert
        print("File size (\(String(format: "%.1f", currentMB))MB) exceeds your limit of \(Int(limitMB))MB")
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: EnhancedChatMessage
    let isOwnMessage: Bool
    @State private var showingFullScreenImage = false
    
    var body: some View {
        HStack {
            if isOwnMessage { Spacer() }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                if message.type == .text || message.content.contains("inquiry") {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(isOwnMessage ? .white : Theme.Colors.text)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            isOwnMessage ? Theme.Colors.primary : Theme.Colors.surface
                        )
                        .cornerRadius(18)
                } else if message.type == .image {
                    if let mediaData = try? JSONDecoder().decode(MediaMessageData.self, from: message.content.data(using: .utf8) ?? Data()) {
                        AsyncImage(url: URL(string: "https://brrow-backend-nodejs-production.up.railway.app/brrow" + mediaData.url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 250, maxHeight: 300)
                                .clipped()
                                .cornerRadius(12)
                                .onTapGesture {
                                    showingFullScreenImage = true
                                }
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.surface)
                                .frame(width: 250, height: 200)
                                .overlay(
                                    ProgressView()
                                )
                        }
                        .fullScreenCover(isPresented: $showingFullScreenImage) {
                            ImageViewerView(imageUrl: "https://brrow-backend-nodejs-production.up.railway.app/brrow" + mediaData.url)
                        }
                    }
                } else if message.type == .video {
                    if let mediaData = try? JSONDecoder().decode(MediaMessageData.self, from: message.content.data(using: .utf8) ?? Data()) {
                        VideoThumbnailView(videoUrl: "https://brrow-backend-nodejs-production.up.railway.app/brrow" + mediaData.url)
                            .frame(maxWidth: 250, maxHeight: 300)
                            .cornerRadius(12)
                    }
                }
                
                Text(formatTime(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isOwnMessage ? .trailing : .leading)
            
            if !isOwnMessage { Spacer() }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: date)
    }
}

// MARK: - Media Message Data Model
struct MediaMessageData: Codable {
    let url: String
    let thumbnailUrl: String?
    let mimeType: String
    let size: Int
    let originalName: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case thumbnailUrl = "thumbnail_url"
        case mimeType = "mime_type"
        case size
        case originalName = "original_name"
    }
}