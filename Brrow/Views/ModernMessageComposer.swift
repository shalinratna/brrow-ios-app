//
//  ModernMessageComposer.swift
//  Brrow
//
//  Enhanced message composer with auto-suggestions and smooth UX
//

import SwiftUI
import Combine

struct ModernMessageComposer: View {
    let recipient: User?
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingChatView = false
    @State private var conversationId: String?
    @State private var selectedSuggestion: String?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool

    // Auto-suggestions based on listing type
    private var messageSuggestions: [String] {
        let baseMessages = [
            "Hi! Is this \(listing.title) still available for rent?",
            "I'm interested in renting your \(listing.title). When would be a good time to discuss?",
            "Could you tell me more about the \(listing.title)?",
            "What's included with the \(listing.title) rental?"
        ]

        // Add price negotiation if applicable
        if listing.isNegotiable {
            return baseMessages + [
                "Would you consider $\(Int(listing.price * 0.9)) per \(listing.rentalPeriod ?? "day")?",
                "Is the price negotiable for longer rentals?"
            ]
        }

        return baseMessages
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Modern header
                modernHeader

                // Listing context card
                listingContextCard

                // Message suggestions
                if messageText.isEmpty {
                    messageSuggestionsView
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                Spacer()

                // Enhanced message input
                enhancedMessageInput
            }
            .background(
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.97, blue: 1.0),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .onReceive(keyboardHeightPublisher) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height
                }
            }
            .onAppear {
                // Auto-focus text field after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
        .sheet(isPresented: $showingChatView) {
            if let conversationId = conversationId {
                // Navigate to the actual chat view
                Text("Chat View for \(conversationId)")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Modern Header
    private var modernHeader: some View {
        HStack(spacing: 16) {
            // Cancel button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }

            Spacer()

            // Recipient info
            HStack(spacing: 8) {
                if let profilePicture = recipient?.profilePicture {
                    BrrowAsyncImage(url: profilePicture) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .overlay(
                                Text(String(recipient?.username.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(recipient?.username ?? "User")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    if recipient?.isVerified == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.primary)
                            Text("Verified")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Send button
            Button(action: sendMessage) {
                Text("Send")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        .secondary : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                Color.gray.opacity(0.2) : Theme.Colors.primary)
                    )
                    .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: messageText.isEmpty)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.white.opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Listing Context Card
    private var listingContextCard: some View {
        HStack(spacing: 12) {
            // Listing image
            if let imageUrl = listing.images.first?.url {
                BrrowAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }

            // Listing details
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("$\(Int(listing.price))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)

                    if let period = listing.rentalPeriod {
                        Text("per \(period)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                if listing.isNegotiable {
                    Text("Price negotiable")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.secondary)
                }
            }

            Spacer()

            // Listing type badge
            Text(listing.listingType.capitalized)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.primary.opacity(0.1))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Message Suggestions
    private var messageSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Messages")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(Array(messageSuggestions.enumerated()), id: \.offset) { index, suggestion in
                        ModernSuggestionButton(
                            text: suggestion,
                            isSelected: selectedSuggestion == suggestion,
                            action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    messageText = suggestion
                                    selectedSuggestion = suggestion
                                    isTextFieldFocused = true
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Enhanced Message Input
    private var enhancedMessageInput: some View {
        VStack(spacing: 16) {
            // Text input area
            VStack(alignment: .leading, spacing: 8) {
                if !messageText.isEmpty {
                    Text("Your Message")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                }

                HStack(spacing: 12) {
                    // Attachment button
                    Button(action: {
                        // Handle attachment
                    }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }

                    // Text field
                    TextField("Type your message...", text: $messageText, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .font(.system(size: 16))
                        .lineLimit(1...6)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isTextFieldFocused ? Theme.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)

                    // Voice message button (when text is empty)
                    if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: {
                            // Handle voice message
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Theme.Colors.primary)
                                .clipShape(Circle())
                                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Character count and send options
            if !messageText.isEmpty {
                HStack {
                    Text("\(messageText.count)/500")
                        .font(.system(size: 11))
                        .foregroundColor(messageText.count > 450 ? .red : .secondary)

                    Spacer()

                    if messageText.count > 160 {
                        Button(action: {
                            // Offer to split into multiple messages
                        }) {
                            Text("Split message")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.bottom, max(keyboardHeight, 20))
        .background(
            Color.white.opacity(0.95)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Actions
    private func sendMessage() {
        print("🚀 [ModernMessageComposer] sendMessage() called")

        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🚀 [ModernMessageComposer] Message length: \(trimmedMessage.count)")

        guard !trimmedMessage.isEmpty, !isLoading else {
            print("❌ [ModernMessageComposer] Message empty or already loading, returning")
            return
        }

        let recipientIdToUse = recipient?.apiId ?? recipient?.id ?? ""
        print("✅ [ModernMessageComposer] Recipient ID validated: \(recipientIdToUse)")

        isLoading = true

        Task {
            do {
                print("🔄 [ModernMessageComposer] Creating conversation...")
                // Create conversation and send message
                let conversation = try await APIClient.shared.createConversation(
                    otherUserId: recipientIdToUse,
                    listingId: listing.listingId
                )
                print("✅ [ModernMessageComposer] Conversation created: \(conversation.id)")

                print("🔄 [ModernMessageComposer] Sending message...")
                // Send the message FIRST
                let message = try await APIClient.shared.sendMessage(
                    conversationId: conversation.id,
                    content: trimmedMessage,
                    messageType: .text
                )
                print("✅ [ModernMessageComposer] Message sent successfully: \(message.id)")

                await MainActor.run {
                    print("🎬 [ModernMessageComposer] Entered MainActor.run block")
                    isLoading = false
                    conversationId = conversation.id
                    print("💾 [ModernMessageComposer] Stored conversation ID: \(conversation.id)")

                    print("📢 [ModernMessageComposer] Posting conversationDidUpdate notification")
                    NotificationCenter.default.post(name: .conversationDidUpdate, object: nil)
                    print("✅ [ModernMessageComposer] Notification posted")

                    print("👋 [ModernMessageComposer] Dismissing composer")
                    dismiss()
                    print("✅ [ModernMessageComposer] Dismiss called")

                    print("⏰ [ModernMessageComposer] Scheduling tab switch in 0.5s")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("🔀 [ModernMessageComposer] Executing tab switch NOW")
                        TabSelectionManager.shared.switchToMessages()
                        print("✅ [ModernMessageComposer] Tab switch completed")
                    }
                }

            } catch {
                print("❌ [ModernMessageComposer] Error occurred: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Modern Suggestion Button
struct ModernSuggestionButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Message icon
                Image(systemName: "message.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : Theme.Colors.primary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isSelected ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                    )

                // Message text
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Spacer()

                // Arrow icon
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.Colors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.primary : Color.white)
                    .shadow(
                        color: isSelected ? Theme.Colors.primary.opacity(0.3) : .black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cross-platform Keyboard Height Publisher
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