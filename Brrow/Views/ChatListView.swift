//
//  ChatListView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var searchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search Bar
                searchSection
                
                // Content
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    loadingView
                } else if viewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadConversations()
                trackScreenView("chat_list")
            }
            .refreshable {
                viewModel.refreshConversations()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Messages")
                .font(Theme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            Button(action: {
                // TODO: Implement new message action
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.secondaryText)
            
            TextField("Search conversations...", text: $searchText)
                .font(Theme.Typography.body)
                .onChange(of: searchText) { newValue in
                    viewModel.searchConversations(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.md)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Conversations List
    private var conversationsList: some View {
        List(viewModel.conversations, id: \.id) { conversation in
            NavigationLink(destination: ChatView(conversation: conversation)) {
                ConversationRow(conversation: conversation)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading conversations...")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("No Messages Yet")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            Text("Start chatting with other Brrow users about listings and transactions!")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func trackScreenView(_ screenName: String) {
        let event = AnalyticsEvent(
            eventName: "screen_view",
            eventType: "navigation",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "screen_name": screenName,
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Profile Image
            AsyncImage(url: URL(string: conversation.otherUser.profilePicture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .foregroundColor(Theme.Colors.divider)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Message Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(conversation.otherUser.username)
                        .font(Theme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Text(timeAgo(conversation.lastMessage.createdAt))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                HStack {
                    Text(conversation.lastMessage.content)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Colors.primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }
    
    private func timeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Now" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Now"
        }
    }
}

// MARK: - Chat Models
struct Conversation: Codable, Identifiable {
    let id: String
    let otherUser: User
    let lastMessage: ChatMessage
    let unreadCount: Int
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, unreadCount
        case otherUser = "other_user"
        case lastMessage = "last_message"
        case updatedAt = "updated_at"
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let messageType: String
    let createdAt: String
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, content, isRead
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case messageType = "message_type"
        case createdAt = "created_at"
    }
}


// MARK: - Chat View
struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.messages, id: \.id) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == AuthManager.shared.currentUser?.apiId
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            messageInputSection
        }
        .background(Theme.Colors.background)
        .navigationTitle(conversation.otherUser.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages(conversationId: conversation.id)
        }
        .onDisappear {
            viewModel.markMessagesAsRead(conversationId: conversation.id)
        }
    }
    
    private var messageInputSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Message...", text: $messageText, axis: .vertical)
                .lineLimit(1...4)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface)
                .cornerRadius(Theme.CornerRadius.lg)
                .font(Theme.Typography.body)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                    .foregroundColor(messageText.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.primary)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = SendMessageRequest(
            receiverId: conversation.otherUser.apiId ?? "",
            content: messageText,
            messageType: "text",
            conversationId: conversation.id
        )
        
        Task {
            await viewModel.sendMessage(message)
            DispatchQueue.main.async {
                messageText = ""
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                Text(message.content)
                    .font(Theme.Typography.body)
                    .foregroundColor(isCurrentUser ? .white : Theme.Colors.text)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        isCurrentUser ? Theme.Colors.primary : Theme.Colors.surface
                    )
                    .cornerRadius(Theme.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.divider, lineWidth: isCurrentUser ? 0 : 1)
                    )
                
                Text(timeAgo(message.createdAt))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func timeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Now" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Now"
        }
    }
}

// MARK: - Chat View Model
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadMessages(conversationId: String) {
        isLoading = true
        
        Task {
            do {
                let response = try await APIClient.shared.fetchMessages(conversationId: conversationId)
                DispatchQueue.main.async {
                    self.messages = response.messages
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func sendMessage(_ message: SendMessageRequest) async {
        do {
            let sentMessage = try await APIClient.shared.sendMessage(message)
            DispatchQueue.main.async {
                // Convert ChatMessage to Message
                let newMessage = Message(
                    id: sentMessage.id,
                    conversationId: message.receiverId, // Using receiverId as conversationId
                    senderId: sentMessage.senderId,
                    receiverId: sentMessage.receiverId,
                    content: sentMessage.content,
                    messageType: sentMessage.messageType,
                    isRead: sentMessage.isRead,
                    createdAt: sentMessage.createdAt,
                    sender: MessageSender(
                        username: AuthManager.shared.currentUser?.username ?? "",
                        profilePicture: AuthManager.shared.currentUser?.profilePicture
                    ),
                    isOwnMessage: true
                )
                self.messages.append(newMessage)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func markMessagesAsRead(conversationId: String) {
        // TODO: Implement mark as read functionality
    }
}

// MARK: - Message Model
struct Message: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: String
    let receiverId: String
    let content: String
    let messageType: String
    let isRead: Bool
    let createdAt: String
    let sender: MessageSender
    let isOwnMessage: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, content, isRead
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case messageType = "message_type"
        case createdAt = "created_at"
        case sender
        case isOwnMessage = "is_own_message"
    }
}

struct MessageSender: Codable {
    let username: String
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case profilePicture = "profile_picture"
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}