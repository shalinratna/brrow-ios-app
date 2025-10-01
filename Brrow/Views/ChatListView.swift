//
//  ChatListView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct ChatListView: View {
    @StateObject private var chatService = ChatService.shared
    @StateObject private var viewModel = ChatListViewModel()
    @State private var searchText = ""
    @State private var selectedChat: Chat?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showingNewMessageSheet = false
    @State private var navigateToSelectedChat = false
    
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
            .onReceive(NotificationCenter.default.publisher(for: .openSpecificChat)) { notification in
                if let userInfo = notification.userInfo,
                   let chatId = userInfo["chatId"] as? String,
                   let listingId = userInfo["listingId"] as? String,
                   let listingTitle = userInfo["listingTitle"] as? String {

                    print("🔔 ChatListView received openSpecificChat for: \(chatId)")

                    // Create a minimal listing object for context
                    let tempListing = Listing.temporaryFromId(
                        listingId: listingId,
                        title: listingTitle
                    )

                    viewModel.navigateToChat(chatId: chatId, listing: tempListing)
                }
            }

            // Hidden NavigationLink for automatic navigation
            NavigationLink(
                destination: destinationView(),
                isActive: $navigateToSelectedChat
            ) {
                EmptyView()
            }
            .hidden()
        }
        .sheet(isPresented: $showingNewMessageSheet) {
            NewMessageSheet()
        }
        .onChange(of: viewModel.selectedChatId) { selectedId in
            if selectedId != nil {
                print("🔄 ChatListView detected selectedChatId change: \(selectedId ?? "nil")")
                // Use a slightly longer delay to ensure conversation is created
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("🔄 Triggering navigation to chat: \(selectedId ?? "nil")")
                    navigateToSelectedChat = true
                }
            }
        }
        .onChange(of: navigateToSelectedChat) { isNavigating in
            if !isNavigating {
                // Reset the selected chat when navigation is done
                viewModel.selectedChatId = nil
                viewModel.initialMessageForSelectedChat = nil
            }
        }
    }

    // MARK: - Navigation Helper
    @ViewBuilder
    private func destinationView() -> some View {
        if let selectedId = viewModel.selectedChatId {
            // Try to find conversation in list first
            if let conversation = viewModel.conversations.first(where: { $0.id == selectedId }) {
                EnhancedChatDetailView(
                    conversation: conversation,
                    initialMessage: viewModel.initialMessageForSelectedChat
                )
            } else {
                // If conversation doesn't exist yet, create a temporary one for navigation
                // This handles the case where we're navigating to a new conversation
                if let currentUser = AuthManager.shared.currentUser {
                    let tempConversation = Conversation(
                        id: selectedId,
                        otherUser: ConversationUser.placeholder(), // Placeholder conversation user
                        lastMessage: nil,
                        unreadCount: 0,
                        updatedAt: ISO8601DateFormatter().string(from: Date())
                    )
                    EnhancedChatDetailView(
                        conversation: tempConversation,
                        initialMessage: viewModel.initialMessageForSelectedChat
                    )
                } else {
                    EmptyView()
                }
            }
        } else {
            EmptyView()
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
                showingNewMessageSheet = true
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
            NavigationLink(destination: EnhancedChatDetailView(conversation: conversation)) {
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
            BrrowAsyncImage(url: conversation.otherUser.fullProfilePictureURL) { image in
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
                    
                    Text(timeAgo(conversation.lastMessage?.createdAt ?? conversation.updatedAt))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                HStack {
                    Text(conversation.lastMessage?.content ?? "No messages yet")
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
        // CRITICAL FIX: Parse timestamps with fractional seconds support
        // PostgreSQL/Prisma returns timestamps like "2025-10-01T14:30:45.123Z"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date = formatter.date(from: dateString)

        // Fallback: Try without fractional seconds
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }

        guard let parsedDate = date else {
            print("⚠️ [ChatListView] Failed to parse timestamp: \(dateString)")
            return "Now"
        }

        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: parsedDate, to: now)

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

// Chat Models moved to ConversationModels.swift


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
                                isCurrentUser: message.senderId == AuthManager.shared.currentUser?.id // CRITICAL FIX: Use User.id (CUID), not apiId
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
                let fetchedMessages = try await APIClient.shared.fetchMessages(conversationId: conversationId)
                DispatchQueue.main.async {
                    self.messages = fetchedMessages
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
    
    func sendMessage(_ messageRequest: SendMessageRequest) async {
        do {
            let messageType = MessageType(rawValue: messageRequest.messageType) ?? .text
            let sentMessage = try await APIClient.shared.sendMessage(
                conversationId: messageRequest.conversationId ?? "",
                content: messageRequest.content,
                messageType: messageType,
                mediaUrl: nil,
                thumbnailUrl: nil,
                listingId: nil
            )
            DispatchQueue.main.async {
                // The sentMessage is already a Message object from the new API
                self.messages.append(sentMessage)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func markMessagesAsRead(conversationId: String) {
        Task {
            do {
                // Use APIClient directly since we don't have access to viewModel here
                // TODO: Properly implement markConversationAsRead in APIClient
                print("Marking conversation as read: \(conversationId)")
                await MainActor.run {
                    // Update local state to mark conversation as read
                    // Note: This would need proper implementation with viewModel
                    // The conversations array is in the viewModel scope
                    print("Conversation marked as read: \(conversationId)")
                }
            } catch {
                print("Failed to mark messages as read: \(error)")
            }
        }
    }
}

// MARK: - Message Model
// Using Message from ChatModels.swift

struct MessageSender: Codable {
    let username: String
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case profilePicture = "profile_picture"
    }
}

// MARK: - New Message Sheet
struct NewMessageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUser: User?
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.Colors.secondaryText)
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.md)
                .padding(.horizontal)

                if isLoading {
                    ProgressView("Loading users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Select a user to start a conversation")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding()

                    Spacer()
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}