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
    let sendStatus: MessageSendStatus  // ✅ OPTIMISTIC: Track send status
    let readAt: Date?  // ✅ INSTAGRAM-STYLE: Track when message was read for "Seen Xm ago"

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
    @State private var textEditorHeight: CGFloat = 36  // Dynamic height for text editor
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
            // Mark messages as read when opening chat
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay to let messages load
                markUnreadMessagesAsRead()
            }
        }
        .onChange(of: viewModel.messages) { _ in
            // Mark new messages as read when they arrive
            Task {
                markUnreadMessagesAsRead()
            }
        }
        .onDisappear {
            // Leave the WebSocket room when exiting chat
            WebSocketManager.shared.leaveChat(chatId: conversation.id)
        }
        // CRITICAL FIX: Removed duplicate .newMessageReceived listener
        // The ChatDetailViewModel already handles this notification at lines 96-104
        // Having two listeners caused messages to be fetched 7x times instead of once
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
                    UniversalProfileView(user: user)
                        .environmentObject(AuthManager.shared)
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
                        ForEach(Array(groupedMessagesByDate[date]?.enumerated() ?? [].enumerated()), id: \.element.id) { index, message in
                            // CRITICAL FIX: Compare with user.id (CUID), not apiId
                            // Backend sends senderId as User.id (e.g., "clxyz123"), not User.apiId (e.g., "usr_abc")
                            let isOwnMessage = message.senderId == AuthManager.shared.currentUser?.id

                            // ✅ MESSAGE GROUPING: Determine if this message should show timestamp
                            let messagesForDate = groupedMessagesByDate[date] ?? []
                            let previousMessage: Message? = index > 0 ? messagesForDate[index - 1] : nil
                            let isLastInGroup = isLastMessageInGroup(message, nextMessage: index < messagesForDate.count - 1 ? messagesForDate[index + 1] : nil)
                            let shouldShowTimestamp = shouldShowTimestamp(current: message, previous: previousMessage)

                            // ✅ INSTAGRAM-STYLE: Check if this is the absolute last message in the conversation
                            let isLastInConversation = viewModel.messages.last?.id == message.id

                            MessageBubbleView(
                                message: message.toEnhancedChatMessage(),
                                isOwnMessage: isOwnMessage,
                                showTimestamp: shouldShowTimestamp || isLastInGroup,  // Show timestamp on last in group or after 5 min
                                isFirstInGroup: isFirstInGroup(message: message, previous: previousMessage),
                                isLastInGroup: isLastInGroup,
                                isLastInConversation: isLastInConversation  // ✅ INSTAGRAM-STYLE: For "Seen Xm ago"
                            )
                            .id(message.id)
                            // ✅ MODERN ANIMATIONS: Different animations for sent vs received messages
                            .transition(.asymmetric(
                                insertion: isOwnMessage
                                    ? .move(edge: .trailing).combined(with: .scale(scale: 0.8, anchor: .bottomTrailing)).combined(with: .opacity)
                                    : .move(edge: .leading).combined(with: .scale(scale: 0.8, anchor: .bottomLeading)).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .onTapGesture {
                                // ✅ OPTIMISTIC: Allow retry on failed messages
                                if message.sendStatus == .failed {
                                    viewModel.retryFailedMessage(message)
                                }
                            }
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
                        // ✅ MODERN ANIMATIONS: Smooth spring animation for scroll
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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

    // ✅ MESSAGE GROUPING: Check if timestamp should be shown (show every 5 minutes or when sender changes)
    private func shouldShowTimestamp(current: Message, previous: Message?) -> Bool {
        guard let previous = previous else { return false }  // First message in date group doesn't show timestamp here

        // Don't show timestamp when sender changes (timestamp appears on LAST message of group)
        // iMessage behavior: timestamps appear BELOW the last message, not above the first
        if current.senderId != previous.senderId {
            return false  // ✅ FIXED: Don't show timestamp on first message of new group
        }

        // Show timestamp if more than 5 minutes passed
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let currentDate = dateFormatter.date(from: current.createdAt) ?? Date()
        let previousDate = dateFormatter.date(from: previous.createdAt) ?? Date()

        let timeDifference = currentDate.timeIntervalSince(previousDate)
        return timeDifference > 300 // 5 minutes
    }

    // ✅ MESSAGE GROUPING: Check if this is the first message in a group from the same sender
    private func isFirstInGroup(message: Message, previous: Message?) -> Bool {
        guard let previous = previous else { return true }

        // Different sender = new group
        if message.senderId != previous.senderId {
            return true
        }

        // Same sender but > 5 minutes apart = new group
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let currentDate = dateFormatter.date(from: message.createdAt) ?? Date()
        let previousDate = dateFormatter.date(from: previous.createdAt) ?? Date()

        let timeDifference = currentDate.timeIntervalSince(previousDate)
        return timeDifference > 300 // 5 minutes
    }

    // ✅ MESSAGE GROUPING: Check if this is the last message in a group
    private func isLastMessageInGroup(_ message: Message, nextMessage: Message?) -> Bool {
        guard let next = nextMessage else { return true }  // Last message overall

        // Different sender = end of group
        if message.senderId != next.senderId {
            return true
        }

        // Same sender but > 5 minutes until next = end of group
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let currentDate = dateFormatter.date(from: message.createdAt) ?? Date()
        let nextDate = dateFormatter.date(from: next.createdAt) ?? Date()

        let timeDifference = nextDate.timeIntervalSince(currentDate)
        return timeDifference > 300 // 5 minutes
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
                    .font(.system(size: 32))
                    .foregroundColor(Theme.Colors.primary)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            // Message Field - iMessage style
            ZStack(alignment: .leading) {
                // Placeholder text
                if messageText.isEmpty {
                    Text("Message")
                        .foregroundColor(Color(.placeholderText))
                        .font(.system(size: 17))
                        .padding(.leading, 12)
                }

                TextEditor(text: $messageText)
                    .focused($isMessageFieldFocused)
                    .font(.system(size: 17))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(height: max(36, min(textEditorHeight, 100)))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .onChange(of: messageText) { _ in
                        updateTextEditorHeight()
                    }
            }
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(18)
            
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

        // ✅ MODERN UX: Haptic feedback on send (like iMessage)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        viewModel.sendTextMessage(messageText, to: conversation.id)

        messageText = ""
        textEditorHeight = 36  // Reset height after sending
    }

    private func updateTextEditorHeight() {
        let font = UIFont.systemFont(ofSize: 17)
        let maxSize = CGSize(width: UIScreen.main.bounds.width - 120, height: .infinity)
        let text = messageText.isEmpty ? " " : messageText
        let attributes = [NSAttributedString.Key.font: font]
        let boundingRect = (text as NSString).boundingRect(
            with: maxSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        // Add some padding and ensure minimum height
        let newHeight = max(36, boundingRect.height + 16)
        textEditorHeight = newHeight
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

        // ✅ PERFORMANCE: Check cache first for instant loading
        if let cachedProfile = viewModel.cachedOtherUserProfile {
            print("⚡ [ChatDetailView] Using cached profile for instant display")
            self.otherUserProfile = cachedProfile
            showingUserProfile = true
            return
        }

        // Fallback: Fetch from API if not cached
        print("🔍 [ChatDetailView] Cache miss - fetching profile from API")
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

    // MARK: - Read Receipts

    /// Mark all unread messages in this chat as read
    private func markUnreadMessagesAsRead() {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }

        // Find all messages that:
        // 1. Are NOT from the current user (we don't mark our own messages as read)
        // 2. Are not already marked as read
        let unreadMessages = viewModel.messages.filter { message in
            message.senderId != currentUserId && !message.isRead
        }

        guard !unreadMessages.isEmpty else { return }

        let messageIds = unreadMessages.map { $0.id }
        print("📖 [ChatDetailView] Marking \(messageIds.count) messages as read in chat \(conversation.id)")

        // Call ChatService to emit mark_read event to backend
        ChatService.shared.markMessagesAsRead(messageIds: messageIds, chatId: conversation.id)
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: EnhancedChatMessage
    let isOwnMessage: Bool
    var showTimestamp: Bool = true
    var isFirstInGroup: Bool = true
    var isLastInGroup: Bool = true
    var isLastInConversation: Bool = false  // ✅ INSTAGRAM-STYLE: Track if this is the absolute last message
    @State private var showingFullScreenImage = false

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                if isOwnMessage { Spacer(minLength: 50) }

                VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 2) {  // ✅ Tighter spacing for grouped messages
                    if message.type == .text || message.content.contains("inquiry") {
                        Text(message.content)
                            .font(.system(size: 16))
                            .foregroundColor(isOwnMessage ? .white : Theme.Colors.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isOwnMessage ? Theme.Colors.primary : Color(red: 0.95, green: 0.95, blue: 0.97))
                            .cornerRadius(26)
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

                    // ✅ WHATSAPP-STYLE: Status and timestamp display
                    if isOwnMessage {
                        // For own messages, show status-specific UI
                        if message.sendStatus == .sending {
                            // SENDING: Show "sending..." text (no timestamp, no checkmark)
                            Text("sending...")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.secondaryText.opacity(0.7))
                                .padding(.top, 2)
                        } else if showTimestamp {
                            // SENT/DELIVERED/READ: Show timestamp with optional checkmark
                            HStack(spacing: 4) {
                                Text(formatTime(message.createdAt))
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.secondaryText)

                                // READ: Show single green checkmark
                                if message.sendStatus == .read {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Theme.Colors.primary)
                                        .transition(.scale.combined(with: .opacity))
                                }

                                // FAILED: Show red exclamation
                                if message.sendStatus == .failed {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.top, 2)
                        }
                    } else if showTimestamp {
                        // For received messages, just show timestamp
                        Text(formatTime(message.createdAt))
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .padding(.top, 2)
                    }
                }

                if !isOwnMessage { Spacer(minLength: 50) }
            }
        }
        .padding(.vertical, 2)
    }

    private func formatTime(_ date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        // Explicitly use local timezone (should be default, but being explicit)
        timeFormatter.timeZone = TimeZone.current
        return timeFormatter.string(from: date)
    }

    // ✅ INSTAGRAM-STYLE: Format relative time for "Seen Xm ago" indicator
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let minutes = components.minute, let hours = components.hour, let days = components.day {
            if days == 0 {
                // Today
                if hours == 0 {
                    // Less than an hour
                    if minutes == 0 {
                        return "just now"
                    } else if minutes == 1 {
                        return "1m ago"
                    } else {
                        return "\(minutes)m ago"
                    }
                } else if hours == 1 {
                    return "1h ago"
                } else {
                    return "\(hours)h ago"
                }
            } else if days == 1 {
                return "yesterday"
            } else if days < 7 {
                // Within a week - show day name
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE" // Day name
                return formatter.string(from: date)
            } else {
                // More than a week - show date
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            }
        }

        return "recently"
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
        // CRITICAL FIX: Parse timestamps with fractional seconds support
        // PostgreSQL/Prisma returns timestamps like "2025-10-01T14:30:45.123Z"
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var createdDate = dateFormatter.date(from: self.createdAt)

        // Fallback: Try without fractional seconds
        if createdDate == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            createdDate = dateFormatter.date(from: self.createdAt)
        }

        // Last resort: Use current date (should never happen)
        if createdDate == nil {
            print("⚠️ [ChatDetailView] Failed to parse message timestamp: \(self.createdAt)")
            createdDate = Date()
        }

        let finalCreatedDate = createdDate!

        // ✅ INSTAGRAM-STYLE: Parse readAt timestamp for "Seen Xm ago" indicator
        var finalReadAt: Date? = nil
        if let readAtString = self.readAt, !readAtString.isEmpty {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            finalReadAt = dateFormatter.date(from: readAtString)

            // Fallback: Try without fractional seconds
            if finalReadAt == nil {
                dateFormatter.formatOptions = [.withInternetDateTime]
                finalReadAt = dateFormatter.date(from: readAtString)
            }
        }

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
            createdAt: finalCreatedDate,
            isRead: self.isRead,
            sendStatus: self.sendStatus,  // ✅ OPTIMISTIC: Pass through send status
            readAt: finalReadAt  // ✅ INSTAGRAM-STYLE: Pass through read timestamp
        )
    }
}