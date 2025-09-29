//
//  ModernChatView.swift
//  Brrow
//
//  Modern iMessage-style chat interface with smooth animations
//

import SwiftUI
import Combine
import CoreLocation

struct ModernChatView: View {
    let conversation: Conversation
    let initialMessage: String?
    @StateObject private var viewModel = ChatDetailViewModel()
    @State private var messageText = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var isTyping = false
    @State private var showingAttachmentMenu = false
    @FocusState private var isMessageFieldFocused: Bool

    init(conversation: Conversation, initialMessage: String? = nil) {
        self.conversation = conversation
        self.initialMessage = initialMessage
        self._messageText = State(initialValue: initialMessage ?? "")
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Modern header
                modernHeader

                // Messages area with iMessage-style bubbles
                messagesArea

                // Modern input area
                modernInputArea
            }
            .background(
                // iMessage-style gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.97, blue: 1.0),
                        Color(red: 0.95, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadMessages(for: conversation.id)
                // Set initial message if provided
                if let initial = initialMessage, !initial.isEmpty {
                    messageText = initial
                }
            }
            .onReceive(keyboardHeightPublisher) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height
                }
            }
        }
        .sheet(isPresented: $showingAttachmentMenu) {
            ModernAttachmentMenu { attachment in
                handleAttachment(attachment)
            }
        }
    }

    // MARK: - Modern Header
    private var modernHeader: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: {
                // Navigate back
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 32, height: 32)
            }

            // User avatar
            BrrowAsyncImage(url: conversation.otherUser.profilePicture) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .overlay(
                        Text(String(conversation.otherUser.username.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                    )
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(
                // Online status indicator
                Circle()
                    .fill(viewModel.isUserOnline ? Color.green : Color.clear)
                    .frame(width: 12, height: 12)
                    .offset(x: 12, y: 12)
            )

            // User info
            VStack(alignment: .leading, spacing: 0) {
                Text(conversation.otherUser.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                if isTyping {
                    TypingIndicatorView()
                } else {
                    Text(viewModel.isUserOnline ? "Active now" : "Offline")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    // Audio call
                }) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }

                Button(action: {
                    // Video call
                }) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.white.opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Messages Area
    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        let isFromCurrentUser = message.senderId == AuthManager.shared.currentUser?.apiId
                        ModernMessageBubble(
                            message: message.toEnhancedChatMessage(),
                            isFromCurrentUser: isFromCurrentUser,
                            showAvatar: shouldShowAvatar(for: message),
                            showTimestamp: shouldShowTimestamp(for: message)
                        )
                        .id(message.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: isFromCurrentUser ? .trailing : .leading)
                                .combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .onAppear {
                self.scrollViewProxy = proxy
            }
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
        .padding(.bottom, keyboardHeight)
    }

    // MARK: - Modern Input Area
    private var modernInputArea: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)

            HStack(spacing: 12) {
                // Attachment button
                Button(action: {
                    showingAttachmentMenu = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }

                // Message input field
                HStack(spacing: 8) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .focused($isMessageFieldFocused)
                        .font(.system(size: 16))
                        .lineLimit(1...6)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            sendMessage()
                        }
                        .onChange(of: messageText) { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isTyping = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            }
                        }

                    // Camera quick button
                    if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: {
                            // Quick camera access
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mic.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(
                                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                    Color.secondary : Theme.Colors.primary
                                )
                        )
                        .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1.0 : 1.1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.white.opacity(0.95)
                    .background(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Helper Methods
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // TODO: Implement sendMessage method in ChatDetailViewModel
            // viewModel.sendMessage(content: trimmedText, to: conversation.id)
            messageText = ""
            isTyping = false
        }

        // Scroll to bottom after sending
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if let proxy = scrollViewProxy {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id)
            }
        }
    }

    private func shouldShowAvatar(for message: Message) -> Bool {
        guard let currentIndex = viewModel.messages.firstIndex(where: { $0.id == message.id }) else { return true }

        // Show avatar if it's the last message from this user
        if currentIndex == viewModel.messages.count - 1 { return true }

        let nextMessage = viewModel.messages[currentIndex + 1]
        return nextMessage.senderId != message.senderId
    }

    private func shouldShowTimestamp(for message: Message) -> Bool {
        guard let currentIndex = viewModel.messages.firstIndex(where: { $0.id == message.id }) else { return true }

        // Show timestamp for first message or if significant time gap
        if currentIndex == 0 { return true }

        let previousMessage = viewModel.messages[currentIndex - 1]
        // Convert string timestamps to dates for comparison
        let dateFormatter = ISO8601DateFormatter()
        guard let currentDate = dateFormatter.date(from: message.createdAt),
              let previousDate = dateFormatter.date(from: previousMessage.createdAt) else {
            return true
        }

        let timeDiff = abs(currentDate.timeIntervalSince(previousDate))
        return timeDiff > 300 // 5 minutes
    }

    private func handleAttachment(_ attachment: ModernAttachmentType) {
        // Handle different attachment types
        switch attachment {
        case .photo:
            // Handle photo from library
            print("📸 Photo selected from library")
        case .camera:
            // Handle camera capture
            print("📷 Camera capture")
        case .location:
            // Handle location sharing
            print("📍 Location sharing")
        case .document:
            // Handle document attachment
            print("📄 Document attachment")
        case .payment:
            // Handle payment
            print("💳 Payment request")
        case .event:
            // Handle event scheduling
            print("📅 Event scheduling")
        }
    }
}

// MARK: - Modern Message Bubble
struct ModernMessageBubble: View {
    let message: EnhancedChatMessage
    let isFromCurrentUser: Bool
    let showAvatar: Bool
    let showTimestamp: Bool

    var body: some View {
        VStack(spacing: 2) {
            // Timestamp if needed
            if showTimestamp {
                Text(timeString)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }

            // Message bubble
            HStack(alignment: .bottom, spacing: 8) {
                if !isFromCurrentUser {
                    // Other user's avatar
                    if showAvatar {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("U")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                            )
                    } else {
                        // Invisible spacer to maintain alignment
                        Color.clear
                            .frame(width: 28, height: 28)
                    }
                } else {
                    // Push user's messages to the right
                    Spacer(minLength: 60)
                }

                // Message content
                VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                    messageContentView

                    // Read receipt for user's messages
                    if isFromCurrentUser {
                        HStack(spacing: 2) {
                            // TODO: Add isDelivered property to EnhancedChatMessage model
                            // if message.isDelivered {
                                Text("Delivered")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            // }

                            if message.isRead {
                                Text("Read")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                }

                if isFromCurrentUser {
                    // Invisible spacer for other user's messages
                    Color.clear
                        .frame(width: 28, height: 1)
                } else {
                    // Push other's messages to the left
                    Spacer(minLength: 60)
                }
            }
        }
    }

    @ViewBuilder
    private var messageContentView: some View {
        switch message.type {
        case .text:
            modernTextBubble
        case .image:
            modernImageBubble
        default:
            modernTextBubble // Fallback
        }
    }

    private var modernTextBubble: some View {
        Text(message.content)
            .font(.system(size: 16))
            .foregroundColor(isFromCurrentUser ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isFromCurrentUser ?
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white, Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: isFromCurrentUser ? 4 : 2,
                        x: 0,
                        y: 1
                    )
            )
    }

    private var modernImageBubble: some View {
        BrrowAsyncImage(url: message.mediaUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(ProgressView())
        }
        .frame(maxWidth: 200, maxHeight: 200)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.createdAt)
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
            Text("typing...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation {
                animationPhase = 2
            }
        }
    }
}

// MARK: - Extensions
extension View {
}

// Cross-platform keyboard height publisher
private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
    #if targetEnvironment(macCatalyst) || os(macOS)
    // On Mac, keyboard behavior is different - return minimal adjustment
    Just(0)
        .eraseToAnyPublisher()
    #else
    // iOS keyboard handling
    Publishers.Merge(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            },
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
    )
    .eraseToAnyPublisher()
    #endif
}

