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
            
            unreadCount = conversations.reduce(0) { $0 + $1.unreadCount }
        }
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
        print("🔄 Navigating to chat: \(chatId)")

        navigatedListing = listing

        // Generate helpful initial message if coming from a listing
        if let listing = listing {
            initialMessageForSelectedChat = "Hi! I'm interested in your listing '\(listing.title)'. Is it still available?"
        } else {
            initialMessageForSelectedChat = nil
        }

        // Find the conversation in the list
        if let conversation = conversations.first(where: { $0.id == chatId }) {
            print("✅ Found existing conversation: \(conversation.id)")
            // Mark as selected for navigation
            selectedChatId = conversation.id
        } else {
            print("🔄 Conversation not found, attempting to create...")
            // If conversation doesn't exist, try to create it from chatId
            // ChatId format: "listing_{listingId}_{userId1}_{userId2}"
            if chatId.hasPrefix("listing_") {
                Task {
                    await createConversationFromChatId(chatId: chatId, listing: listing)
                }
            } else {
                // For non-listing chats, set the chatId and let the UI handle it
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