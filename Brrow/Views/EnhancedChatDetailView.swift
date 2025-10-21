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
    @State private var showingVideoPicker = false
    @State private var isRecordingVoice = false
    @State private var showingVideoCall = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isTyping = false
    @State private var typingTimer: Timer?
    @State private var showingUserProfile = false
    @State private var otherUserProfile: User?
    @State private var isLoadingProfile = false
    @State private var showScrollToBottom = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingChatOptions = false
    @State private var showingSearch = false
    @State private var showingListingDetail = false
    @State private var showingVoiceRecorder = false
    @State private var selectedListing: Listing?
    @State private var showingFullScreenImage = false
    @State private var selectedImageURL: String?

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
        .sheet(isPresented: $showingVideoPicker) {
            VideoPicker { videoURL, thumbnail in
                Task {
                    await handleVideoUpload(videoURL: videoURL, thumbnail: thumbnail)
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let imageURL = selectedImageURL {
                FullScreenImageViewer(imageURL: imageURL)
            }
        }
        .fullScreenCover(isPresented: $showingVideoCall) {
            VideoCallView(conversation: conversation)
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

            // CRITICAL: Make profile picture and name tappable for Instagram-style profile view
            Button(action: { fetchAndShowProfile() }) {
                HStack(spacing: 12) {
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
                        Text(conversation.otherUser.displayName ?? conversation.otherUser.username)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        Text("@\(conversation.otherUser.username)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.secondaryText)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.isUserOnline ? Color.green : Color.gray)
                                .frame(width: 6, height: 6)

                            Text(viewModel.isUserOnline ? "Online" : "Offline")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

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
                showingChatOptions = true
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
        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                let scrollContent = ScrollView {
                    LazyVStack(spacing: 0) {
                    // Listing Context Banner (for listing conversations)
                    if conversation.isListingChat, let listing = conversation.listing {
                        Button(action: {
                            showingListingDetail = true
                        }) {
                            ListingContextBanner(listing: listing)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }

                    // Messages with grouping
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        let isFromCurrentUser = message.senderId == AuthManager.shared.currentUser?.id

                        // Message grouping logic
                        let previousMessage = index > 0 ? viewModel.messages[index - 1] : nil
                        let nextMessage = index < viewModel.messages.count - 1 ? viewModel.messages[index + 1] : nil

                        let showDateHeader = shouldShowDateHeader(for: message, previous: previousMessage)
                        let isFirstInGroup = isFirstMessageInGroup(message: message, previous: previousMessage)
                        let isLastInGroup = isLastMessageInGroup(message: message, next: nextMessage)
                        let showAvatar = !isFromCurrentUser && isLastInGroup

                        VStack(spacing: 0) {
                            // Date header
                            if showDateHeader {
                                DateHeaderView(date: message.timestamp)
                                    .padding(.vertical, 16)
                            }

                            // Message bubble
                            EnhancedMessageBubble(
                                message: ChatMessage.from(message),
                                isFromCurrentUser: isFromCurrentUser,
                                showAvatar: showAvatar,
                                senderProfilePicture: message.sender?.fullProfilePictureURL,
                                onImageTap: { imageURL in
                                    selectedImageURL = imageURL
                                    showingFullScreenImage = true
                                }
                            )
                            .id(message.id)
                            .padding(.horizontal, 16)
                            .padding(.bottom, isLastInGroup ? 12 : 2)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8)
                                    .combined(with: .opacity)
                                    .combined(with: .move(edge: isFromCurrentUser ? .trailing : .leading)),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.messages.count)
                        }
                    }

                    // Typing Indicator
                    if viewModel.otherUserIsTyping {
                        TypingIndicator(username: conversation.otherUser.name)
                            .padding(.horizontal, 16)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.otherUserIsTyping)
                    }
                }
                .padding(.vertical, 8)
            }

                scrollContent
                    .onChange(of: viewModel.messages.count) { _ in
                        // Animate new message appearance and scroll
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if let lastMessage = viewModel.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.otherUserIsTyping) { isTyping in
                        // Scroll to bottom when typing indicator appears
                        if isTyping {
                            withAnimation(.easeOut(duration: 0.25)) {
                                if let lastMessage = viewModel.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
            }
            .padding(.bottom, keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)

            // Scroll to bottom button
            if showScrollToBottom {
                Button(action: scrollToBottom) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.Colors.primary)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 4)
                }
                .padding(.trailing, 16)
                .padding(.bottom, keyboardHeight + 16)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func scrollToBottom() {
        if let lastMessage = viewModel.messages.last, let proxy = scrollProxy {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                showScrollToBottom = false
            }
        }
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

                    Button(action: { showingVideoPicker = true }) {
                        Label("Video", systemImage: "video")
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
                        .onChange(of: messageText) { newValue in
                            handleTextChange(newValue)
                        }
                    
                    if messageText.isEmpty {
                        // Voice recording button
                        Button(action: {
                            showingVoiceRecorder = true
                        }) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.primary)
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

            // Voice recorder overlay
            if showingVoiceRecorder {
                VoiceRecorderView(
                    viewModel: viewModel,
                    conversationId: conversation.id,
                    isRecording: $showingVoiceRecorder
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingVoiceRecorder)
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendTextMessage(messageText, to: conversation.id)
        
        // Track achievement for sending message
        AchievementManager.shared.trackMessageSent()
        
        messageText = ""
    }
    
    private func startVideoCall() {
        // In a real app, this would initiate a video call
        showingVideoCall = true
    }

    // MARK: - Typing Indicator Handling
    private func handleTextChange(_ newValue: String) {
        // Cancel existing timer
        typingTimer?.invalidate()

        if !newValue.isEmpty && !isTyping {
            // Start typing
            isTyping = true
            viewModel.sendTypingIndicator(chatId: conversation.id, isTyping: true)
        }

        if !newValue.isEmpty {
            // Set timer to auto-stop typing after 3 seconds
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                stopTyping()
            }
        } else {
            // Stop typing immediately if text is empty
            stopTyping()
        }
    }

    private func stopTyping() {
        if isTyping {
            isTyping = false
            viewModel.sendTypingIndicator(chatId: conversation.id, isTyping: false)
        }
        typingTimer?.invalidate()
        typingTimer = nil
    }

    // MARK: - Video Upload Handler
    private func handleVideoUpload(videoURL: URL, thumbnail: UIImage?) async {
        do {
            let result = try await FileUploadService.shared.uploadVideo(videoURL, thumbnail: thumbnail)

            // Send video message through view model
            await MainActor.run {
                viewModel.sendVideoMessage(videoURL, to: conversation.id)
            }

            print("✅ Video uploaded and message sent")
        } catch {
            print("❌ Failed to upload video: \(error)")
            // TODO: Show error alert to user
        }
    }

    // MARK: - Profile Fetching
    private func fetchAndShowProfile() {
        guard !isLoadingProfile else { return }

        isLoadingProfile = true
        showingUserProfile = true

        Task {
            do {
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
                }
            }
        }
    }

    // MARK: - Message Grouping Helpers

    private func shouldShowDateHeader(for message: Message, previous: Message?) -> Bool {
        guard let previousMessage = previous else { return true }

        let calendar = Calendar.current
        let messageDate = calendar.startOfDay(for: message.timestamp)
        let previousDate = calendar.startOfDay(for: previousMessage.timestamp)

        return messageDate != previousDate
    }

    private func isFirstMessageInGroup(message: Message, previous: Message?) -> Bool {
        guard let previousMessage = previous else { return true }

        // Different sender = new group
        if message.senderId != previousMessage.senderId {
            return true
        }

        // More than 1 minute apart = new group
        let timeDifference = message.timestamp.timeIntervalSince(previousMessage.timestamp)
        return timeDifference > 60
    }

    private func isLastMessageInGroup(message: Message, next: Message?) -> Bool {
        guard let nextMessage = next else { return true }

        // Different sender = end of group
        if message.senderId != nextMessage.senderId {
            return true
        }

        // More than 1 minute apart = end of group
        let timeDifference = nextMessage.timestamp.timeIntervalSince(message.timestamp)
        return timeDifference > 60
    }
}

// MARK: - Additional Sheet Presentations
extension EnhancedChatDetailView {
    var additionalSheets: some View {
        Group {
            // Chat options menu
            EmptyView()
                .sheet(isPresented: $showingChatOptions) {
                    ChatOptionsSheet(
                        conversation: conversation,
                        showingUserProfile: $showingUserProfile,
                        showingListingDetail: $showingListingDetail,
                        showingSearch: $showingSearch
                    )
                }

            // Search in conversation
            EmptyView()
                .fullScreenCover(isPresented: $showingSearch) {
                    ChatSearchView(
                        isPresented: $showingSearch,
                        messages: viewModel.messages,
                        onMessageSelected: { message in
                            // Scroll to selected message
                            if let proxy = scrollProxy {
                                withAnimation {
                                    proxy.scrollTo(message.id, anchor: .center)
                                }
                            }
                        }
                    )
                }

            // Listing detail (if available)
            if let listing = conversation.listing {
                EmptyView()
                    .sheet(isPresented: $showingListingDetail) {
                        ListingDetailNavigationView(listingId: listing.id)
                    }
            }
        }
    }
}

// MARK: - Date Header View
struct DateHeaderView: View {
    let date: Date

    var body: some View {
        Text(formattedDate)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Theme.Colors.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Colors.surface)
            .cornerRadius(12)
    }

    private var formattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Listing Context Banner
struct ListingContextBanner: View {
    let listing: ListingPreview

    var body: some View {
        HStack(spacing: 12) {
            // Listing Thumbnail
            if let imageUrl = listing.imageUrl {
                BrrowAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(Theme.Colors.divider)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(Theme.CornerRadius.sm)
            }

            // Listing Info
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                if let price = listing.price {
                    Text("$\(String(format: "%.2f", price))")
                        .font(Theme.Typography.body)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.primary)
                }

                Text(listing.availabilityStatus)
                    .font(Theme.Typography.caption)
                    .foregroundColor(listing.availabilityStatus == "AVAILABLE" ? .green : .orange)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.CornerRadius.md)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    let username: String
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            Text("\(username) is typing")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .italic()

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    let delay = Double(index) * 0.4
                    let scale = calculateScale(phase: animationPhase, delay: delay)
                    let opacity = calculateOpacity(phase: animationPhase, delay: delay)

                    Circle()
                        .fill(Theme.Colors.secondaryText)
                        .frame(width: 6, height: 6)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }

    private func calculateScale(phase: CGFloat, delay: Double) -> CGFloat {
        return 1.0 + sin(phase + delay) * 0.5
    }

    private func calculateOpacity(phase: CGFloat, delay: Double) -> Double {
        return 0.4 + sin(phase + delay) * 0.4
    }
}

// MARK: - Enhanced Message Bubble
struct EnhancedMessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let showAvatar: Bool
    let senderProfilePicture: String?
    let onImageTap: ((String) -> Void)?

    init(message: ChatMessage, isFromCurrentUser: Bool, showAvatar: Bool, senderProfilePicture: String?, onImageTap: ((String) -> Void)? = nil) {
        self.message = message
        self.isFromCurrentUser = isFromCurrentUser
        self.showAvatar = showAvatar
        self.senderProfilePicture = senderProfilePicture
        self.onImageTap = onImageTap
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Profile picture for received messages (left side)
            if !isFromCurrentUser {
                if showAvatar {
                    BrrowAsyncImage(url: senderProfilePicture) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    // Invisible spacer to maintain alignment when avatar is hidden
                    Color.clear
                        .frame(width: 32, height: 32)
                }
            }

            // Message content
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content based on type
                messageContent

                // Message metadata with enhanced read receipts
                HStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if isFromCurrentUser {
                        // Enhanced delivery status icons
                        deliveryStatusIcon

                        // Show formatted read time on tap/hover
                        if let readTime = message.formattedReadTime {
                            Text(readTime)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }

    // MARK: - Delivery Status Icon (WhatsApp-style)
    @ViewBuilder
    private var deliveryStatusIcon: some View {
        switch message.deliveryStatus {
        case .sent:
            // Single gray checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        case .delivered:
            // Double gray checkmarks
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.gray)
        case .read:
            // Double blue checkmarks
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(Theme.Colors.primary)
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.messageType {
        case .text:
            textMessageView
        case .image:
            imageMessageView
        case .video:
            videoMessageView
        case .audio, .voice:
            audioMessageView
        case .file:
            fileMessageView
        case .system:
            textMessageView  // System messages shown as text
        case .offer:
            offerMessageView
        case .location:
            locationMessageView
        case .listing, .listingReference:
            listingMessageView
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
            Button(action: {
                if let mediaUrl = message.mediaUrl {
                    onImageTap?(mediaUrl)
                }
            }) {
                BrrowAsyncImage(url: message.mediaUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                        )
                }
                .frame(maxWidth: 200, maxHeight: 200)
                .cornerRadius(12)
                .clipped()
            }
            .buttonStyle(PlainButtonStyle())

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
            // Video thumbnail with play button
            if let thumbnailUrl = message.thumbnailUrl {
                BrrowAsyncImage(url: thumbnailUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(ProgressView())
                }
                .frame(maxWidth: 200, maxHeight: 150)
                .cornerRadius(12)
                .overlay(
                    ZStack {
                        // Play button overlay
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 50, height: 50)

                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                )
                .overlay(
                    // Video duration badge
                    Group {
                        if let duration = message.videoDuration {
                            Text(formatDuration(duration))
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                        }
                    },
                    alignment: .bottomTrailing
                )
                .padding(4)
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
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

    private var audioMessageView: some View {
        Group {
            if let mediaUrl = message.mediaUrl {
                AudioPlayerView(audioURL: mediaUrl)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromCurrentUser ? Theme.Colors.primary : Theme.Colors.surface)
                    )
            } else {
                textMessageView
            }
        }
    }

    private var fileMessageView: some View {
        Group {
            if let mediaUrl = message.mediaUrl {
                // Parse file data from message content
                if let data = message.content.data(using: .utf8),
                   let fileData = try? JSONDecoder().decode(FileMessageData.self, from: data) {
                    FileMessageView(
                        fileURL: fileData.url,
                        fileName: fileData.fileName,
                        fileSize: fileData.fileSize,
                        isFromCurrentUser: isFromCurrentUser
                    )
                } else {
                    // Fallback if content doesn't have file data
                    FileMessageView(
                        fileURL: mediaUrl,
                        fileName: nil,
                        fileSize: nil,
                        isFromCurrentUser: isFromCurrentUser
                    )
                }
            } else {
                textMessageView
            }
        }
    }

    private var listingMessageView: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.primary)

            Text("Shared a listing")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isFromCurrentUser ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.surface)
        )
    }

    private var offerMessageView: some View {
        // Convert ChatMessage to Message for OfferCardView
        let convertedMessage = Message(
            id: message.id,
            chatId: "", // Not needed for display
            senderId: message.senderId,
            receiverId: message.receiverId,
            content: message.content,
            messageType: message.messageType,
            mediaUrl: message.mediaUrl,
            thumbnailUrl: message.thumbnailUrl,
            listingId: nil,
            isRead: message.isRead,
            isEdited: false,
            editedAt: nil,
            deletedAt: nil,
            sentAt: nil,
            deliveredAt: message.deliveredAt,
            readAt: message.readAt,
            createdAt: message.createdAt,
            sender: nil,
            reactions: nil
        )

        return OfferCardView(
            message: convertedMessage,
            isFromCurrentUser: isFromCurrentUser,
            onAccept: {
                // Accept offer
                Task {
                    await handleOfferAction(action: "accept")
                }
            },
            onReject: {
                // Reject offer
                Task {
                    await handleOfferAction(action: "reject")
                }
            },
            onCounter: {
                // Counter offer
                // TODO: Show counter offer dialog
                print("Counter offer tapped for message: \(message.id)")
            }
        )
    }

    private func handleOfferAction(action: String) async {
        // Extract offer data from message content
        guard let data = message.content.data(using: .utf8),
              let offerData = try? JSONDecoder().decode(OfferData.self, from: data) else {
            print("Failed to parse offer data")
            return
        }

        // Call API to update offer status
        // This would be implemented in the APIClient
        print("Handling offer action: \(action) for amount: \(offerData.offerAmount)")

        // For now, just send a system message
        let statusMessage = action == "accept" ? "Offer accepted!" : "Offer rejected"
        // viewModel.sendMessage(statusMessage, to: conversation.id)
    }

    private var timeString: String {
        // CRITICAL FIX: Parse timestamps with fractional seconds support
        // PostgreSQL/Prisma returns timestamps like "2025-10-01T14:30:45.123Z"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date = formatter.date(from: message.createdAt)

        // Fallback: Try without fractional seconds
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: message.createdAt)
        }

        guard let parsedDate = date else {
            print("⚠️ [EnhancedMessageBubble] Failed to parse timestamp: \(message.createdAt)")
            return "Now"
        }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.timeZone = TimeZone.current // Use local timezone for display
        return timeFormatter.string(from: parsedDate)
    }
}

// MARK: - Listing Detail Navigation Helper

struct ListingDetailNavigationView: View {
    let listingId: String
    @State private var listing: Listing?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading listing...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button("Close") {
                            dismiss()
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let listing = listing {
                    ProfessionalListingDetailView(listing: listing)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Listing not found")
                            .font(.headline)
                        Text("This listing may have been removed or sold")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button("Close") {
                            dismiss()
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                Task {
                    await loadListing()
                }
            }
        }
    }

    private func loadListing() async {
        do {
            let fetchedListing = try await APIClient.shared.fetchListingDetailsByListingId(listingId)
            await MainActor.run {
                self.listing = fetchedListing
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "This listing is no longer available"
                self.isLoading = false
            }
            print("Failed to fetch listing: \(error)")
        }
    }
}

// MARK: - Placeholder Views for Missing Features

struct VideoCallView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Video Call")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Video calling feature coming soon")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Theme.Colors.primary)
                        .cornerRadius(25)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

struct VoiceRecorderView: View {
    let viewModel: ChatDetailViewModel
    let conversationId: String
    @Binding var isRecording: Bool
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                // Recording indicator
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(recordingDuration.truncatingRemainder(dividingBy: 1.0) < 0.5 ? 1.0 : 0.3)

                    Text(formatDuration(recordingDuration))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                }

                // Waveform placeholder
                HStack(spacing: 4) {
                    ForEach(0..<20, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.primary)
                            .frame(width: 3, height: CGFloat.random(in: 10...40))
                    }
                }
                .padding()

                Text("Voice recording not yet implemented")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding()
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.lg)

            HStack(spacing: 40) {
                // Cancel button
                Button(action: {
                    timer?.invalidate()
                    isRecording = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }

                // Send button
                Button(action: {
                    timer?.invalidate()
                    // In a real implementation, would send the recorded audio
                    isRecording = false
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Theme.Colors.background.opacity(0.95))
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingDuration += 0.1
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AudioPlayerView: View {
    let audioURL: String
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 60 // Placeholder duration

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: {
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.Colors.primary)
            }

            // Waveform visualization
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    let height: CGFloat = CGFloat.random(in: 4...20)
                    let progress = currentTime / duration
                    let isPlayed = Double(index) / 30.0 < progress

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlayed ? Theme.Colors.primary : Theme.Colors.secondaryText.opacity(0.3))
                        .frame(width: 2, height: height)
                }
            }
            .frame(maxWidth: .infinity)

            // Duration
            Text(formatTime(currentTime))
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

