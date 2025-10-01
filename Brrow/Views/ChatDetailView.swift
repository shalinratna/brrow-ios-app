//
//  ChatDetailView.swift
//  Brrow
//
//  Chat conversation detail view
//

import SwiftUI
import PhotosUI

// MARK: - Enhanced Chat Message (Legacy Support)
struct EnhancedChatMessage: Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let createdAt: Date
    let isRead: Bool

    enum MessageType {
        case text
        case image
        case video
        case voice
    }
}

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
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingUserProfile = false  // For click-to-profile navigation
    @State private var otherUserProfile: User?  // Will be fetched when button tapped
    @State private var isLoadingProfile = false

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
            // Join the WebSocket room for this chat
            WebSocketManager.shared.joinChat(chatId: conversation.id)
        }
        .onDisappear {
            // Leave the WebSocket room when exiting chat
            WebSocketManager.shared.leaveChat(chatId: conversation.id)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newMessageReceived)) { notification in
            // CRITICAL: Handle real-time messages from WebSocket
            guard let message = notification.object as? Message,
                  let chatId = notification.userInfo?["chatId"] as? String,
                  chatId == conversation.id else { return }

            print("💬 [ChatDetailView] Received real-time message for chat \(chatId)")

            // Reload messages to show the new message
            viewModel.loadMessages(for: conversation.id)
        }
        .onChange(of: selectedPhotosItem) { newItem in
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
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingUserProfile) {
            if let user = otherUserProfile {
                NavigationView {
                    SocialProfileView(user: user)
                        .navigationBarItems(trailing: Button("Done") {
                            showingUserProfile = false
                        })
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading profile...")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.background)
            }
        }
    }
    
    private var chatHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
            }

            // CRITICAL FIX: Make user avatar and name tappable to view profile (like Instagram DM)
            Button(action: { fetchAndShowProfile() }) {
                HStack(spacing: Theme.Spacing.md) {
                    // User Avatar
                    if let profilePicture = conversation.otherUser.profilePicture, !profilePicture.isEmpty {
                        BrrowAsyncImage(url: profilePicture) { image in
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
                }
            }
            .buttonStyle(PlainButtonStyle())  // Prevent button from changing appearance

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
            let messagesContent = ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(groupedMessagesByDate.keys.sorted(by: >)), id: \.self) { date in
                        // Date header (like iMessage)
                        Text(formatDateHeader(date))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .padding(.vertical, 16)
                            .padding(.top, 8)

                        // Messages for this date
                        ForEach(groupedMessagesByDate[date] ?? []) { message in
                            // CRITICAL FIX: Compare with user.id (CUID), not apiId
                            // Backend sends senderId as User.id (e.g., "clxyz123"), not User.apiId (e.g., "usr_abc")
                            let isOwnMessage = message.senderId == AuthManager.shared.currentUser?.id

                            MessageBubbleView(
                                message: message.toEnhancedChatMessage(),
                                isOwnMessage: isOwnMessage
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .background(Color.white) // Clean white background

            messagesContent
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
        }
    }

    // Group messages by date
    private var groupedMessagesByDate: [Date: [Message]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.messages) { message in
            let dateFormatter = ISO8601DateFormatter()
            let date = dateFormatter.date(from: message.createdAt) ?? Date()
            return calendar.startOfDay(for: date)
        }
        return grouped
    }

    // Format date header like iMessage (Today, Yesterday, or date)
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name (Monday, Tuesday, etc.)
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    // Get previous message for comparison
    private func getPreviousMessage(for message: Message) -> Message? {
        guard let index = viewModel.messages.firstIndex(where: { $0.id == message.id }),
              index > 0 else { return nil }
        return viewModel.messages[index - 1]
    }

    // Check if timestamp should be shown (show every 5 minutes)
    private func shouldShowTimestamp(current: Message, previous: Message?) -> Bool {
        guard let previous = previous else { return true }

        let dateFormatter = ISO8601DateFormatter()
        let currentDate = dateFormatter.date(from: current.createdAt) ?? Date()
        let previousDate = dateFormatter.date(from: previous.createdAt) ?? Date()

        let timeDifference = currentDate.timeIntervalSince(previousDate)
        return timeDifference > 300 // 5 minutes
    }

    // Check if this is the first message in a group from the same sender
    private func isFirstInGroup(message: Message, previous: Message?) -> Bool {
        guard let previous = previous else { return true }
        return message.senderId != previous.senderId
    }

    // Check if this is the last message in a group (simplified - checks if it's the last overall)
    private func isLastInGroup(message: Message) -> Bool {
        return message.id == viewModel.messages.last?.id
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
                let iconName = messageText.isEmpty ? "mic.fill" : "arrow.up.circle.fill"
                let iconColor = messageText.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.primary

                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
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
                errorMessage = "Failed to upload media. Please try again."
                showingErrorAlert = true
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
        errorMessage = "File size (\(String(format: "%.1f", currentMB))MB) exceeds your limit of \(Int(limitMB))MB. Please choose a smaller file."
        showingErrorAlert = true
        print("File size (\(String(format: "%.1f", currentMB))MB) exceeds your limit of \(Int(limitMB))MB")
    }

    // MARK: - Profile Fetching
    private func fetchAndShowProfile() {
        guard !isLoadingProfile else { return }

        isLoadingProfile = true
        showingUserProfile = true  // Show sheet immediately with loading state

        Task {
            do {
                // Fetch full user profile from API using the user's ID
                let profile = try await APIClient.shared.fetchUserProfile(userId: conversation.otherUser.id)

                await MainActor.run {
                    self.otherUserProfile = profile
                    self.isLoadingProfile = false
                }
            } catch {
                print("❌ Failed to fetch user profile: \(error)")
                await MainActor.run {
                    self.isLoadingProfile = false
                    self.showingUserProfile = false
                    self.errorMessage = "Failed to load user profile. Please try again."
                    self.showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: EnhancedChatMessage
    let isOwnMessage: Bool
    var showTimestamp: Bool = true
    var isFirstInGroup: Bool = true
    var isLastInGroup: Bool = true
    @State private var showingFullScreenImage = false

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                if isOwnMessage { Spacer(minLength: 50) }

                VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                    if message.type == .text || message.content.contains("inquiry") {
                        Text(message.content)
                            .font(.system(size: 16))
                            .foregroundColor(isOwnMessage ? .white : Theme.Colors.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(isOwnMessage ? Theme.Colors.primary : Color(red: 0.95, green: 0.95, blue: 0.97))
                            .cornerRadius(20)
                    } else if message.type == .image {
                        if let mediaData = try? JSONDecoder().decode(MediaMessageData.self, from: message.content.data(using: .utf8) ?? Data()) {
                            BrrowAsyncImage(url: mediaData.url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: 250, maxHeight: 300)
                                    .clipped()
                                    .cornerRadius(16)
                                    .onTapGesture {
                                        showingFullScreenImage = true
                                    }
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 250, height: 200)
                                    .overlay(
                                        ProgressView()
                                    )
                            }
                            .fullScreenCover(isPresented: $showingFullScreenImage) {
                                ImageViewerView(imageUrl: "https://brrowapp.com/brrow" + mediaData.url)
                            }
                        }
                    } else if message.type == .video {
                        if let mediaData = try? JSONDecoder().decode(MediaMessageData.self, from: message.content.data(using: .utf8) ?? Data()) {
                            VideoThumbnailView(videoUrl: "https://brrowapp.com/brrow" + mediaData.url)
                                .frame(maxWidth: 250, maxHeight: 300)
                                .cornerRadius(16)
                        }
                    }

                    // ALWAYS show timestamp on each message for clarity
                    Text(formatTime(message.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.top, 2)
                }

                if !isOwnMessage { Spacer(minLength: 50) }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        // Explicitly use local timezone (should be default, but being explicit)
        timeFormatter.timeZone = TimeZone.current
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

// MARK: - Message Conversion Extension
extension Message {
    func toEnhancedChatMessage() -> EnhancedChatMessage {
        let dateFormatter = ISO8601DateFormatter()
        let createdDate = dateFormatter.date(from: self.createdAt) ?? Date()

        // Convert MessageType to EnhancedChatMessage.MessageType
        let enhancedType: EnhancedChatMessage.MessageType
        switch self.messageType {
        case .text:
            enhancedType = .text
        case .image:
            enhancedType = .image
        case .video:
            enhancedType = .video
        case .voice:
            enhancedType = .voice
        case .audio:
            enhancedType = .voice // map audio to voice
        case .file:
            enhancedType = .text // fallback to text for file type
        case .listing, .listingReference:
            enhancedType = .text // fallback to text for listing type
        case .location:
            enhancedType = .text // fallback to text for location type
        case .system:
            enhancedType = .text // fallback to text for system type
        case .offer:
            enhancedType = .text // fallback to text for offer type
        }

        return EnhancedChatMessage(
            id: self.id,
            senderId: self.senderId,
            receiverId: self.receiverId ?? "",
            content: self.content,
            type: enhancedType,
            mediaUrl: self.mediaUrl,
            createdAt: createdDate,
            isRead: self.isRead
        )
    }
}