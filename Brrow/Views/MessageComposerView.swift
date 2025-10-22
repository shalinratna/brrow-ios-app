//
//  MessageComposerView.swift
//  Brrow
//
//  Message composer for contacting listing owners
//

import SwiftUI

struct MessageComposerView: View {
    let recipient: User?
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingChatView = false
    @State private var conversationId: String?
    @State private var showCustomMessageInput = false
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recipient info (stays at top)
                HStack(spacing: 12) {
                    if let profilePicture = recipient?.profilePicture {
                        BrrowAsyncImage(url: profilePicture) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Theme.Colors.secondary)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(recipient?.username ?? "User")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            if recipient?.isVerified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }

                        Text("About: \(listing.title)")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Theme.Colors.secondaryBackground)

                // Scrollable content area
                ScrollView {
                    VStack(spacing: 16) {
                        if !showCustomMessageInput {
                            // Quick responses as full-width cards
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Choose a message to send")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.text)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)

                                VStack(spacing: 12) {
                                    QuickResponseCard(
                                        title: "Is this still available?",
                                        message: "Hi! Is this \(listing.title) still available for rent?"
                                    ) {
                                        // Send immediately - don't trigger keyboard
                                        messageText = "Hi! Is this \(listing.title) still available for rent?"
                                        sendMessage()
                                    }

                                    QuickResponseCard(
                                        title: "What's the condition?",
                                        message: "Hi! Can you tell me more about the condition of the \(listing.title)?"
                                    ) {
                                        // Send immediately - don't trigger keyboard
                                        messageText = "Hi! Can you tell me more about the condition of the \(listing.title)?"
                                        sendMessage()
                                    }

                                    QuickResponseCard(
                                        title: "Negotiate price",
                                        message: "Hi! I'm interested in renting the \(listing.title). Would you consider $\(Int(listing.price * 0.8))/day?"
                                    ) {
                                        // Send immediately - don't trigger keyboard
                                        messageText = "Hi! I'm interested in renting the \(listing.title). Would you consider $\(Int(listing.price * 0.8))/day?"
                                        sendMessage()
                                    }

                                    QuickResponseCard(
                                        title: "Schedule pickup",
                                        message: "Hi! I'd like to rent the \(listing.title). When would be a good time to pick it up?"
                                    ) {
                                        // Send immediately - don't trigger keyboard
                                        messageText = "Hi! I'd like to rent the \(listing.title). When would be a good time to pick it up?"
                                        sendMessage()
                                    }

                                    // Write custom message button
                                    Button(action: {
                                        withAnimation {
                                            showCustomMessageInput = true
                                            // TextEditor will auto-focus on its own .onAppear
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.pencil")
                                                .font(.system(size: 18))
                                            Text("Write custom message")
                                                .font(.system(size: 16, weight: .semibold))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(Theme.Colors.primary)
                                        .padding(16)
                                        .background(Theme.Colors.secondaryBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Theme.Colors.primary, lineWidth: 2)
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // CRITICAL FIX: Only render TextEditor when explicitly requested
                        // This prevents ANY auto-focus issues
                        if showCustomMessageInput {
                            // Custom message input area
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Write your message")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.Colors.text)

                                    Spacer()

                                    Button(action: {
                                        withAnimation {
                                            showCustomMessageInput = false
                                            isTextEditorFocused = false
                                            messageText = ""
                                        }
                                    }) {
                                        Text("Back to quick responses")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Theme.Colors.primary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)

                                VStack(spacing: 8) {
                                    TextEditor(text: $messageText)
                                        .focused($isTextEditorFocused)
                                        .padding(12)
                                        .background(Theme.Colors.secondaryBackground)
                                        .cornerRadius(12)
                                        .frame(minHeight: 150)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isTextEditorFocused ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                                        )
                                        .onAppear {
                                            // Auto-focus ONLY when TextEditor appears
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isTextEditorFocused = true
                                            }
                                        }

                                    HStack {
                                        Text("\(messageText.count)/500")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.Colors.secondaryText)

                                        Spacer()

                                        if messageText.count > 500 {
                                            Text("Message too long")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // Extra padding at bottom for send button
                        Color.clear.frame(height: 80)
                    }
                }

                // Send button (stays at bottom, above keyboard)
                VStack {
                    Divider()
                    Button(action: { sendMessage() }) {
                        HStack {
                            Text("Send Message")
                                .font(.system(size: 18, weight: .semibold))

                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                        .opacity(messageText.isEmpty || isLoading ? 0.6 : 1)
                    }
                    .disabled(messageText.isEmpty || isLoading || messageText.count > 500)
                    .padding(16)
                }
                .background(Theme.Colors.background)
            }
            .navigationTitle("Send Message")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button("Cancel") {
                    dismiss()
                }
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                // CRITICAL FIX: TextEditor doesn't exist until user taps "Write custom message"
                // No need to dismiss keyboard - it won't appear
                showCustomMessageInput = false
                isTextEditorFocused = false
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingChatView) {
            if let conversationId = conversationId {
                // Create a temporary conversation object for ChatDetailView using the custom initializer
                let tempUser = ConversationUser(
                    id: recipient?.apiId ?? "",
                    username: recipient?.displayName ?? recipient?.username ?? "User",
                    profilePicture: recipient?.profilePicture,
                    hasBlueCheckmark: recipient?.hasBlueCheckmark ?? false
                )
                let tempMessage = ChatMessage(
                    id: "",
                    senderId: "",
                    receiverId: "",
                    content: "",
                    messageType: .text,
                    createdAt: "",
                    isRead: false
                )
                let tempConversation = Conversation(
                    id: conversationId,
                    otherUser: tempUser,
                    lastMessage: tempMessage,
                    unreadCount: 0,
                    updatedAt: ""
                )
                ChatDetailView(conversation: tempConversation)
            }
        }
    }
    
    private func sendMessage() {
        print("🚀 [MessageComposer] sendMessage() called")
        print("🚀 [MessageComposer] recipient?.apiId = \(recipient?.apiId ?? "nil")")

        guard let recipientId = recipient?.apiId else {
            print("❌ [MessageComposer] No recipient API ID, returning early")
            return
        }

        print("✅ [MessageComposer] Recipient ID validated: \(recipientId)")
        isLoading = true

        Task {
            do {
                print("🔄 [MessageComposer] Creating conversation...")
                // First create or find a conversation
                let conversation = try await APIClient.shared.createConversation(
                    otherUserId: recipientId,
                    listingId: listing.listingId
                )
                print("✅ [MessageComposer] Conversation created: \(conversation.id)")

                print("🔄 [MessageComposer] Sending message...")
                // Then send the message
                let message = try await APIClient.shared.sendMessage(
                    conversationId: conversation.id,
                    content: messageText,
                    messageType: .text
                )
                print("✅ [MessageComposer] Message sent successfully: \(message.id)")

                await MainActor.run {
                    print("🎬 [MessageComposer] Entered MainActor.run block")
                    isLoading = false
                    self.conversationId = conversation.id
                    print("💾 [MessageComposer] Stored conversation ID: \(conversation.id)")

                    print("📢 [MessageComposer] Posting conversationDidUpdate notification")
                    NotificationCenter.default.post(name: .conversationDidUpdate, object: nil)
                    print("✅ [MessageComposer] Notification posted")

                    print("👋 [MessageComposer] Dismissing composer")
                    dismiss()
                    print("✅ [MessageComposer] Dismiss called")

                    print("⏰ [MessageComposer] Scheduling tab switch in 0.8s")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        print("🔀 [MessageComposer] Posting switchToMessagesTab notification")
                        NotificationCenter.default.post(name: .switchToMessagesTab, object: nil)
                        print("✅ [MessageComposer] Tab switch notification posted")
                    }
                }
            } catch {
                print("❌ [MessageComposer] Error occurred: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct QuickResponseCard: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.primary)
                }

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}