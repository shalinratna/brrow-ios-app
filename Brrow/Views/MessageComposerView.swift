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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recipient info
                HStack(spacing: 12) {
                    if let profilePicture = recipient?.profilePicture {
                        AsyncImage(url: URL(string: profilePicture)) { image in
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
                
                // Quick responses
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        QuickResponseButton(text: "Is this still available?") {
                            messageText = "Hi! Is this \(listing.title) still available for rent?"
                        }
                        
                        QuickResponseButton(text: "What's the condition?") {
                            messageText = "Hi! Can you tell me more about the condition of the \(listing.title)?"
                        }
                        
                        QuickResponseButton(text: "Negotiate price") {
                            messageText = "Hi! I'm interested in renting the \(listing.title). Would you consider $\(Int(listing.price * 0.8))/day?"
                        }
                        
                        QuickResponseButton(text: "Schedule pickup") {
                            messageText = "Hi! I'd like to rent the \(listing.title). When would be a good time to pick it up?"
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                // Message input
                VStack(spacing: 16) {
                    TextEditor(text: $messageText)
                        .padding(12)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                        .frame(minHeight: 120)
                    
                    Text("\(messageText.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(16)
                
                Spacer()
                
                // Send button
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
            .navigationTitle("Send Message")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingChatView) {
            if let conversationId = conversationId {
                // Create a temporary conversation object for ChatDetailView using the custom initializer
                let tempUser = User(
                    id: recipient?.apiId ?? "",
                    username: recipient?.displayName ?? recipient?.username ?? "User",
                    email: "",
                    apiId: recipient?.apiId,
                    profilePicture: recipient?.profilePicture
                )
                let tempMessage = ChatMessage(
                    id: "",
                    senderId: "",
                    receiverId: "",
                    content: "",
                    messageType: "text",
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
        guard let recipientId = recipient?.apiId else { return }
        
        isLoading = true
        
        Task {
            do {
                // First create or find a conversation
                let conversation = try await APIClient.shared.createConversation(
                    otherUserId: recipientId,
                    listingId: listingId
                )

                // Then send the message
                let message = try await APIClient.shared.sendMessage(
                    conversationId: conversation.id,
                    content: messageText,
                    messageType: .text
                )
                
                await MainActor.run {
                    isLoading = false
                    // Set conversation ID for navigation - use message ID as fallback
                    self.conversationId = message.id
                    dismiss()

                    // Navigate to chat view with this conversation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showingChatView = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct QuickResponseButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(20)
        }
    }
}