//
//  EnhancedChatListView.swift
//  Brrow
//
//  Enhanced chat list with dual messaging system (Direct + Listing conversations)
//  Features: Tabs, badge counts, search, pagination, media support
//

import SwiftUI
import Combine

struct EnhancedChatListView: View {
    @StateObject private var viewModel = EnhancedChatListViewModel()
    @State private var searchText = ""
    @State private var selectedTab: ChatType = .direct
    @State private var showingNewMessageSheet = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Tab Selector with Badge Counts
                tabSelectorSection

                // Search Bar
                searchSection

                // Content
                contentSection
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadConversations(type: selectedTab)
                viewModel.loadUnreadCounts()
                trackScreenView("enhanced_chat_list")
            }
            .refreshable {
                await viewModel.refreshConversations(type: selectedTab)
            }
        }
        .sheet(isPresented: $showingNewMessageSheet) {
            NewMessageSheet()
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

    // MARK: - Tab Selector with Badge Counts
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            // Direct Tab
            TabButton(
                title: "Direct",
                badgeCount: viewModel.unreadCounts.direct,
                isSelected: selectedTab == .direct
            ) {
                withAnimation {
                    selectedTab = .direct
                    viewModel.loadConversations(type: .direct)
                }
            }

            // Listing Tab
            TabButton(
                title: "Listings",
                badgeCount: viewModel.unreadCounts.listing,
                isSelected: selectedTab == .listing
            ) {
                withAnimation {
                    selectedTab = .listing
                    viewModel.loadConversations(type: .listing)
                }
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
                    viewModel.searchConversations(query: newValue, type: selectedTab)
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

    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                loadingView
            } else if viewModel.conversations.isEmpty {
                emptyStateView
            } else {
                conversationsList
            }
        }
    }

    // MARK: - Conversations List with Pagination
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(viewModel.conversations, id: \.id) { conversation in
                    NavigationLink(destination: EnhancedChatDetailView(conversation: conversation)) {
                        EnhancedConversationRow(conversation: conversation)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        // Load more when near the end
                        if conversation.id == viewModel.conversations.last?.id {
                            viewModel.loadMoreIfNeeded(type: selectedTab)
                        }
                    }
                }

                // Loading indicator for pagination
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                        Spacer()
                    }
                    .padding(.vertical, Theme.Spacing.md)
                }
            }
            .padding(.top, Theme.Spacing.md)
        }
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
            Image(systemName: selectedTab == .direct ? "message" : "bag")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)

            Text(selectedTab == .direct ? "No Direct Messages" : "No Listing Conversations")
                .font(Theme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)

            Text(selectedTab == .direct
                ? "Start chatting with other Brrow users!"
                : "Message sellers about listings you're interested in!")
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

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let badgeCount: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(isSelected ? .semibold : .regular)

                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.primary)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Theme.Colors.primary.opacity(0.1) : Color.clear
            )
            .cornerRadius(Theme.CornerRadius.md)
        }
    }
}

// MARK: - Enhanced Conversation Row
struct EnhancedConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Profile Image or Listing Thumbnail
            thumbnailView

            // Message Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    // Username or Listing Title
                    Text(conversation.displayTitle)
                        .font(Theme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)

                    // Listing indicator
                    if conversation.isListingChat {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.primary)
                    }

                    Spacer()

                    // Timestamp
                    Text(timeAgo(conversation.lastMessage?.createdAt ?? conversation.updatedAt))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                // Last Message or Listing Info
                HStack {
                    if let lastMessage = conversation.lastMessage {
                        // Display message content with type indicator
                        HStack(spacing: 4) {
                            messageTypeIcon(lastMessage.messageType)
                            Text(lastMessage.displayContent)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .lineLimit(2)
                        }
                    } else if let listing = conversation.listing {
                        // Display listing price if no messages yet
                        if let price = listing.price {
                            Text("$\(String(format: "%.2f", price))")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.primary)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("No messages yet")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .italic()
                    }

                    Spacer()

                    // Unread Badge
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Colors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }

    // MARK: - Thumbnail View
    @ViewBuilder
    private var thumbnailView: some View {
        if conversation.isListingChat, let listing = conversation.listing, let imageUrl = listing.imageUrl {
            // Listing thumbnail
            BrrowAsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(Theme.Colors.divider)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.secondaryText)
                    )
            }
            .frame(width: 50, height: 50)
            .cornerRadius(Theme.CornerRadius.sm)
        } else {
            // User profile picture
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
        }
    }

    // MARK: - Message Type Icon
    @ViewBuilder
    private func messageTypeIcon(_ type: MessageType) -> some View {
        switch type {
        case .image:
            Image(systemName: "photo.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        case .video:
            Image(systemName: "video.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        case .location:
            Image(systemName: "location.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
        case .listing, .listingReference:
            Image(systemName: "tag.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.primary)
        default:
            EmptyView()
        }
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

// MARK: - Enhanced Chat List ViewModel
class EnhancedChatListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var unreadCounts = UnreadCounts()
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private let pageSize = 20
    private var hasMore = true
    private var currentSearchQuery = ""

    // MARK: - Load Conversations
    func loadConversations(type: ChatType) {
        currentPage = 0
        hasMore = true
        conversations = []
        isLoading = true

        Task {
            await fetchConversations(type: type, page: 0)
        }
    }

    // MARK: - Refresh Conversations
    func refreshConversations(type: ChatType) async {
        currentPage = 0
        hasMore = true
        await fetchConversations(type: type, page: 0)
        await loadUnreadCounts()
    }

    // MARK: - Load More (Pagination)
    func loadMoreIfNeeded(type: ChatType) {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true
        currentPage += 1

        Task {
            await fetchConversations(type: type, page: currentPage, append: true)
        }
    }

    // MARK: - Fetch Conversations from API
    private func fetchConversations(type: ChatType, page: Int, append: Bool = false) async {
        do {
            // Call APIClient with type, limit, offset, search
            let offset = page * pageSize
            let result = try await APIClient.shared.fetchConversations(
                type: type.rawValue,
                limit: pageSize,
                offset: offset,
                search: currentSearchQuery.isEmpty ? nil : currentSearchQuery
            )

            await MainActor.run {
                if append {
                    self.conversations.append(contentsOf: result.conversations)
                } else {
                    self.conversations = result.conversations
                }
                self.hasMore = result.hasMore
                self.isLoading = false
                self.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.isLoadingMore = false
            }
            print("❌ Error fetching conversations: \(error)")
        }
    }

    // MARK: - Load Unread Counts
    func loadUnreadCounts() {
        Task {
            do {
                let counts = try await APIClient.shared.fetchUnreadCounts()
                await MainActor.run {
                    self.unreadCounts = counts
                }
            } catch {
                print("❌ Error fetching unread counts: \(error)")
            }
        }
    }

    // MARK: - Search
    func searchConversations(query: String, type: ChatType) {
        currentSearchQuery = query
        currentPage = 0
        hasMore = true

        Task {
            await fetchConversations(type: type, page: 0)
        }
    }

    func clearSearch() {
        currentSearchQuery = ""
    }
}

struct EnhancedChatListView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedChatListView()
    }
}