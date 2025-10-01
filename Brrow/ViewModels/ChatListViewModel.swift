import Foundation
import Combine
import SwiftUI

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var filteredConversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount = 0
    @Published var selectedChatId: String?
    @Published var navigatedListing: Listing?
    @Published var initialMessageForSelectedChat: String?
    @Published var searchQuery = ""

    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init() {
        // Only fetch conversations if authenticated and not a guest
        if authManager.isAuthenticated && !authManager.isGuestUser {
            fetchConversations()
        }
        setupRealtimeUpdates()
    }
    
    private func setupRealtimeUpdates() {
        // Listen for new messages
        NotificationCenter.default.publisher(for: .newMessageReceived)
            .sink { [weak self] notification in
                if let message = notification.object as? ChatMessage {
                    self?.updateConversationWithMessage(message)
                }
            }
            .store(in: &cancellables)

        // Listen for message read status updates
        NotificationCenter.default.publisher(for: .messageRead)
            .sink { [weak self] notification in
                if let conversationId = notification.object as? String {
                    self?.markConversationAsRead(conversationId)
                }
            }
            .store(in: &cancellables)

        // Listen for conversation updates (new conversation created or updated)
        NotificationCenter.default.publisher(for: .conversationDidUpdate)
            .sink { [weak self] _ in
                print("📬 [ChatListViewModel] conversationDidUpdate notification received!")
                // CRITICAL: Bypass cache when refreshing after new conversation created
                print("🔄 [ChatListViewModel] Calling fetchConversations(bypassCache: true)")
                self?.fetchConversations(bypassCache: true)
            }
            .store(in: &cancellables)

        // CRITICAL FIX: Listen for sent messages to update conversation preview
        NotificationCenter.default.publisher(for: .messageSent)
            .sink { [weak self] notification in
                guard let conversationId = notification.object as? String,
                      let userInfo = notification.userInfo,
                      let message = userInfo["message"] as? Message else {
                    return
                }

                print("✅ [ChatListViewModel] messageSent received for conversation: \(conversationId)")
                print("   Message content: \(message.content)")
                self?.updateConversationPreview(conversationId: conversationId, message: message)
            }
            .store(in: &cancellables)

        // CRITICAL FIX: Listen for user profile updates to refresh conversations
        // When a user updates their username or profile picture, refresh all conversations
        // to show the updated information to other users
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .sink { [weak self] _ in
                print("👤 [ChatListViewModel] userDidUpdate notification received!")
                print("🔄 [ChatListViewModel] Refreshing conversations to show updated profile")
                self?.fetchConversations(bypassCache: true)
            }
            .store(in: &cancellables)
    }
    
    func loadConversations() {
        fetchConversations()
    }
    
    func refreshConversations() {
        fetchConversations()
    }
    
    func preloadContent() async {
        // Check if user is authenticated and not a guest
        guard authManager.isAuthenticated && !authManager.isGuestUser else { return }
        
        // Check if we already have conversations to avoid unnecessary loading
        if !conversations.isEmpty {
            return
        }
        
        // Silently preload conversations in background
        do {
            let fetchedConversations = try await apiClient.fetchConversations()
            self.conversations = fetchedConversations.sorted { $0.updatedAt > $1.updatedAt }
            self.unreadCount = fetchedConversations.reduce(0) { $0 + $1.unreadCount }
        } catch {
            // Silently handle errors during preloading
            print("Failed to preload conversations: \(error.localizedDescription)")
        }
    }
    
    func searchConversations(query: String) {
        searchQuery = query
        if query.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter { conversation in
                conversation.otherUser.username.localizedCaseInsensitiveContains(query) ||
                conversation.lastMessage?.content.localizedCaseInsensitiveContains(query) == true
            }
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        filteredConversations = conversations
    }
    
    func fetchConversations(bypassCache: Bool = false) {
        print("🔍 [ChatListViewModel] fetchConversations called with bypassCache: \(bypassCache)")

        // Check if user is authenticated and not a guest
        guard authManager.isAuthenticated && !authManager.isGuestUser else {
            print("⚠️ [ChatListViewModel] User not authenticated or is guest, clearing conversations")
            conversations = []
            filteredConversations = []
            unreadCount = 0
            isLoading = false
            return
        }

        print("✅ [ChatListViewModel] User authenticated, proceeding with fetch")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                print("📡 [ChatListViewModel] Calling API fetchConversations with bypassCache: \(bypassCache)")
                let result = try await apiClient.fetchConversations(type: nil, limit: 20, offset: 0, search: nil, bypassCache: bypassCache)
                let fetchedConversations = result.conversations
                print("✅ [ChatListViewModel] Fetched \(fetchedConversations.count) conversations from API")

                // DETAILED LOGGING: Show all conversation IDs and details
                print("📋 [ChatListViewModel] Conversation details:")
                for (index, conv) in fetchedConversations.enumerated() {
                    print("  [\(index + 1)] ID: \(conv.id)")
                    print("      Other user: \(conv.otherUser.username) (ID: \(conv.otherUser.id))")
                    print("      Last message: \"\(conv.lastMessage?.content.prefix(50) ?? "")\"")
                    print("      Updated: \(conv.updatedAt)")
                    print("      Unread: \(conv.unreadCount)")
                }
                
                await MainActor.run {
                    let sortedConversations = fetchedConversations.sorted {
                        let formatter = ISO8601DateFormatter()
                        let timestamp1 = formatter.date(from: $0.lastMessage?.createdAt ?? $0.updatedAt) ?? Date()
                        let timestamp2 = formatter.date(from: $1.lastMessage?.createdAt ?? $1.updatedAt) ?? Date()
                        return timestamp1 > timestamp2
                    }
                    self.conversations = sortedConversations
                    if self.searchQuery.isEmpty {
                        self.filteredConversations = sortedConversations
                    } else {
                        self.searchConversations(query: self.searchQuery)
                    }
                    self.unreadCount = fetchedConversations.reduce(0) { $0 + $1.unreadCount }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteConversation(_ conversation: Conversation) {
        Task {
            do {
                try await apiClient.deleteConversation(id: Int(conversation.id) ?? 0)
                await MainActor.run {
                    self.conversations.removeAll { $0.id == conversation.id }
                    self.filteredConversations.removeAll { $0.id == conversation.id }
                    self.unreadCount = self.conversations.reduce(0) { $0 + $1.unreadCount }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func markConversationAsRead(_ conversationId: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index] = Conversation(
                id: conversations[index].id,
                otherUser: conversations[index].otherUser,
                lastMessage: conversations[index].lastMessage,
                unreadCount: 0,
                updatedAt: conversations[index].updatedAt
            )
            unreadCount = conversations.reduce(0) { $0 + $1.unreadCount }
        }
    }
    
    private func updateConversationWithMessage(_ message: ChatMessage) {
        // Find conversation by checking if message sender/receiver matches conversation participants
        if let index = conversations.firstIndex(where: { conversation in
            String(conversation.otherUser.id) == message.senderId || String(conversation.otherUser.id) == message.receiverId
        }) {
            let updatedConversation = Conversation(
                id: conversations[index].id,
                otherUser: conversations[index].otherUser,
                lastMessage: message,
                unreadCount: message.senderId != (authManager.currentUser?.id ?? "") ? 1 : 0,
                updatedAt: message.createdAt
            )

            // Remove old conversation and insert updated one at top
            conversations.remove(at: index)
            conversations.insert(updatedConversation, at: 0)

            // CRITICAL FIX: Also update filtered conversations for UI refresh
            if !searchQuery.isEmpty {
                searchConversations(query: searchQuery)
            } else {
                filteredConversations = conversations
            }

            unreadCount = conversations.reduce(0) { $0 + $1.unreadCount }
        }
    }

    private func updateConversationPreview(conversationId: String, message: Message) {
        // Find the conversation by ID
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else {
            print("⚠️ [ChatListViewModel] Conversation not found: \(conversationId)")
            return
        }

        print("✅ [ChatListViewModel] Updating conversation at index \(index)")

        // Convert Message to ChatMessage for the conversation preview
        let chatMessage = ChatMessage(
            id: message.id,
            senderId: message.senderId,
            receiverId: message.receiverId,
            content: message.content,
            messageType: message.messageType,
            createdAt: message.createdAt,
            isRead: message.isRead
        )

        // Create updated conversation with new lastMessage
        let updatedConversation = Conversation(
            id: conversations[index].id,
            otherUser: conversations[index].otherUser,
            lastMessage: chatMessage,
            unreadCount: 0, // Don't increment unread for our own messages
            updatedAt: message.createdAt
        )

        // Remove old conversation and insert updated one at top (like iMessage)
        conversations.remove(at: index)
        conversations.insert(updatedConversation, at: 0)

        // Also update filtered conversations if search is active
        if !searchQuery.isEmpty {
            searchConversations(query: searchQuery)
        } else {
            filteredConversations = conversations
        }

        print("✅ [ChatListViewModel] Conversation preview updated and moved to top")
    }

    func startConversation(with user: User, about item: Listing? = nil) -> Conversation {
        let otherUser = ConversationUser(
            id: user.id,
            username: user.username,
            profilePicture: user.profilePicture,
            isVerified: user.isVerified ?? false
        )

        let conversation = Conversation(
            id: "temp_\(UUID().uuidString)", // Will be set by server
            otherUser: otherUser,
            lastMessage: ChatMessage(
                id: "",
                senderId: authManager.currentUser?.id ?? "0",
                receiverId: user.id,
                content: "",
                messageType: .text,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                isRead: false
            ),
            unreadCount: 0,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        Task {
            do {
                let createdConversation = try await apiClient.createConversation(
                    otherUserId: user.apiId ?? user.id,
                    listingId: item?.listingId
                )
                await MainActor.run {
                    self.conversations.insert(createdConversation, at: 0)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        
        return conversation
    }

    // Navigate to a specific chat
    func navigateToChat(chatId: String, listing: Listing?) {
        print("🔄 [navigateToChat] Starting navigation to chat: \(chatId)")
        print("🔄 [navigateToChat] Current conversations count: \(conversations.count)")

        navigatedListing = listing

        // Generate helpful initial message if coming from a listing
        if let listing = listing {
            initialMessageForSelectedChat = "Hi! I'm interested in your listing '\(listing.title)'. Is it still available?"
        } else {
            initialMessageForSelectedChat = nil
        }

        // Find the conversation in the list
        if let conversation = conversations.first(where: { $0.id == chatId }) {
            print("✅ [navigateToChat] Found existing conversation: \(conversation.id)")
            // Mark as selected for navigation
            selectedChatId = conversation.id
        } else {
            print("🔄 [navigateToChat] Conversation not found in current list")
            print("🔄 [navigateToChat] Fetching conversations from API...")

            // CRITICAL FIX: Fetch conversations from API to ensure we have the latest data
            // This is essential for notification deep linking when app launches
            Task {
                await fetchConversationsAndNavigate(chatId: chatId, listing: listing)
            }
        }
    }

    // Fetch conversations and then navigate to the specific chat
    private func fetchConversationsAndNavigate(chatId: String, listing: Listing?) async {
        print("📡 [fetchConversationsAndNavigate] Fetching conversations for chatId: \(chatId)")

        do {
            // Fetch conversations directly from API
            let result = try await apiClient.fetchConversations(type: nil, limit: 20, offset: 0, search: nil, bypassCache: true)
            let fetchedConversations = result.conversations

            await MainActor.run {
                let sortedConversations = fetchedConversations.sorted {
                    let formatter = ISO8601DateFormatter()
                    let timestamp1 = formatter.date(from: $0.lastMessage?.createdAt ?? $0.updatedAt) ?? Date()
                    let timestamp2 = formatter.date(from: $1.lastMessage?.createdAt ?? $1.updatedAt) ?? Date()
                    return timestamp1 > timestamp2
                }
                self.conversations = sortedConversations
                if self.searchQuery.isEmpty {
                    self.filteredConversations = sortedConversations
                }

                print("📡 [fetchConversationsAndNavigate] After fetch, conversations count: \(conversations.count)")

                // Try to find the conversation again
                if let conversation = conversations.first(where: { $0.id == chatId }) {
                    print("✅ [fetchConversationsAndNavigate] Found conversation after fetch: \(conversation.id)")
                    selectedChatId = conversation.id
                } else if chatId.hasPrefix("listing_") {
                    print("🔄 [fetchConversationsAndNavigate] Listing conversation not found, attempting to create...")
                    Task {
                        await createConversationFromChatId(chatId: chatId, listing: listing)
                    }
                } else {
                    print("⚠️ [fetchConversationsAndNavigate] Conversation still not found after fetch: \(chatId)")
                    // Set it anyway and let the UI try to handle it
                    selectedChatId = chatId
                }
            }
        } catch {
            print("❌ [fetchConversationsAndNavigate] Error fetching conversations: \(error)")
            await MainActor.run {
                // Still try to navigate even if fetch fails
                selectedChatId = chatId
            }
        }
    }

    // Create conversation from the chat ID format
    private func createConversationFromChatId(chatId: String, listing: Listing?) async {
        guard let currentUser = authManager.currentUser else {
            print("❌ No current user found")
            return
        }

        // Parse the chat ID to extract user IDs
        let components = chatId.components(separatedBy: "_")
        guard components.count >= 4 else {
            print("❌ Invalid chat ID format: \(chatId)")
            return
        }

        let listingIdString = components[1] // Skip "listing" prefix
        let userId1String = components[components.count - 2]
        let userId2String = components[components.count - 1]

        // Determine which user is the "other" user
        let currentUserId = currentUser.id
        let otherUserId: String

        if currentUserId == userId1String {
            otherUserId = userId2String
        } else if currentUserId == userId2String {
            otherUserId = userId1String
        } else {
            print("❌ Current user not found in chat ID: \(chatId)")
            print("❌ Current user ID: \(currentUserId), Chat users: \(userId1String), \(userId2String)")
            return
        }

        // Try to find the other user by numeric ID or use listing owner info
        var otherUserApiId: String = otherUserId
        if let listing = listing {
            otherUserApiId = listing.userId // This should be the owner's API ID
        }

        print("🔄 Creating conversation with other user: \(otherUserApiId)")

        do {
            let conversation = try await apiClient.createConversation(
                otherUserId: otherUserApiId,
                listingId: listing?.listingId
            )

            await MainActor.run {
                // Check if conversation already exists to prevent duplicates
                if !self.conversations.contains(where: { $0.id == conversation.id }) {
                    // Add the new conversation to the list
                    self.conversations.insert(conversation, at: 0)
                } else {
                    // Update existing conversation if it already exists
                    if let existingIndex = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
                        self.conversations[existingIndex] = conversation
                    }
                }

                if self.searchQuery.isEmpty {
                    self.filteredConversations = self.conversations
                }
                // Navigate to it
                self.selectedChatId = conversation.id
                print("✅ Created and navigating to conversation: \(conversation.id)")
            }
        } catch {
            print("❌ Failed to create conversation: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to start conversation. Please try again."
            }
        }
    }
}