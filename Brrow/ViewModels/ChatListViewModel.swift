import Foundation
import Combine
import SwiftUI

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount = 0
    
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
        // TODO: Implement search functionality
    }
    
    func clearSearch() {
        // TODO: Implement clear search functionality
    }
    
    func fetchConversations() {
        // Check if user is authenticated and not a guest
        guard authManager.isAuthenticated && !authManager.isGuestUser else {
            conversations = []
            unreadCount = 0
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedConversations = try await apiClient.fetchConversations()
                
                await MainActor.run {
                    self.conversations = fetchedConversations.sorted {
                        let formatter = ISO8601DateFormatter()
                        let timestamp1 = formatter.date(from: $0.lastMessage.createdAt) ?? Date()
                        let timestamp2 = formatter.date(from: $1.lastMessage.createdAt) ?? Date()
                        return timestamp1 > timestamp2
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
        let conversation = Conversation(
            id: "temp_\(UUID().uuidString)", // Will be set by server
            otherUser: user,
            lastMessage: ChatMessage(
                id: "",
                senderId: authManager.currentUser?.id ?? "0",
                receiverId: user.id,
                content: "",
                messageType: "text",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                isRead: false
            ),
            unreadCount: 0,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        Task {
            do {
                let createdConversation = try await apiClient.createConversation(conversation)
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
}