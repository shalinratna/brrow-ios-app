//
//  SocialChatView.swift
//  Brrow
//
//  Enhanced Social Chat Experience
//

import SwiftUI

struct SocialChatView: View {
    @EnvironmentObject var viewModel: ChatListViewModel
    @State private var searchText = ""
    @State private var showingFeedbackHelp = false
    @State private var showDeleteConfirmation = false
    @State private var conversationToDelete: Conversation?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                    // Header
                    chatHeader

                    // Search bar
                    searchBar

                    // Chat list
                    chatList
                }
                .background(Theme.Colors.background)
                .navigationBarHidden(true)
                .sheet(isPresented: $showingFeedbackHelp) {
                    FeedbackHelpView()
                }
                .onAppear {
                    // FIXED: Use preloaded cache on first appearance for instant display
                    // Manual refresh (pull-to-refresh) will still bypass cache
                    print("📱 [SocialChatView] View appeared, using preloaded cache")
                    viewModel.fetchConversations(bypassCache: false)
                }

            // CRITICAL: Hidden NavigationLink for programmatic navigation from notifications
            if let selectedId = viewModel.selectedChatId,
               let selectedConversation = viewModel.conversations.first(where: { $0.id == selectedId }) {
                NavigationLink(
                    destination: ChatDetailView(conversation: selectedConversation),
                    isActive: Binding(
                        get: { viewModel.selectedChatId != nil },
                        set: { if !$0 { viewModel.selectedChatId = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
                .onAppear {
                    print("🔔 [SocialChatView] Programmatically navigating to chat: \(selectedId)")
                }
            }
        }
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack {
            Text(LocalizationHelper.localizedString("messages"))
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Theme.Colors.text)

            Spacer()

            Button(action: { showingFeedbackHelp = true }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.secondaryText)
            
            TextField(LocalizationHelper.localizedString("search_conversations"), text: $searchText)
                .font(.system(size: 16))
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .cornerRadius(20)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
    
    // MARK: - Chat List
    private var chatList: some View {
        Group {
            if viewModel.conversations.isEmpty {
                ScrollView {
                    emptyChatState
                }
            } else {
                // Use List for swipe actions to work
                List {
                    ForEach(filteredConversations, id: \.id) { conversation in
                        ZStack {
                            // Hidden NavigationLink for navigation
                            NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                                EmptyView()
                            }
                            .opacity(0)

                            // Visible content
                            SocialConversationRow(conversation: conversation)
                                .contentShape(Rectangle())
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                conversationToDelete = conversation
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }

                            Button {
                                // Archive functionality
                                print("Archive conversation: \(conversation.id)")
                            } label: {
                                Label("Archive", systemImage: "archivebox.fill")
                            }
                            .tint(.orange)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.Colors.background)
                .refreshable {
                    // CRITICAL FIX: Add pull-to-refresh to update username/profile changes
                    print("🔄 [SocialChatView] Pull-to-refresh triggered, bypassing cache")
                    viewModel.fetchConversations(bypassCache: true)
                }
            }
        }
        .alert("Delete Conversation?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let conversation = conversationToDelete {
                    viewModel.deleteConversation(conversation)
                    conversationToDelete = nil
                }
            }
        } message: {
            Text("This conversation will be deleted. This action cannot be undone.")
        }
    }
    
    // MARK: - Empty Chat State
    
    private var emptyChatState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.primary.opacity(0.6))
            
            Text(LocalizationHelper.localizedString("no_messages_yet"))
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Text(LocalizationHelper.localizedString("messages_from_inquiries_appear_here"))
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
            
            VStack(spacing: 12) {
                Button(action: {
                    TabSelectionManager.shared.switchToMarketplace()
                }) {
                    HStack {
                        Image(systemName: "bag.fill")
                        Text(LocalizationHelper.localizedString("browse_marketplace"))
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.primary)
                    .cornerRadius(24)
                }
                
                Text(LocalizationHelper.localizedString("find_items_connect_lenders"))
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.top, Theme.Spacing.xxl)
    }
    
    // MARK: - Computed Properties
    
    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return viewModel.conversations
        } else {
            return viewModel.conversations.filter { conversation in
                conversation.otherUser.username.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage?.content.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
}

// MARK: - Social Conversation Row
struct SocialConversationRow: View {
    let conversation: Conversation
    @State private var showingUserProfile = false
    @State private var otherUserProfile: User?
    @State private var isLoadingProfile = false

    var body: some View {
        HStack(spacing: 14) {
            // Instagram-style profile picture (64x64)
            ZStack(alignment: .bottomTrailing) {
                Button(action: {
                    HapticManager.impact(style: .light)
                    fetchAndShowProfile()
                }) {
                    BrrowAsyncImage(url: conversation.otherUser.profilePicture) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .overlay(
                                Text(String(conversation.otherUser.username.prefix(1)).uppercased())
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primary)
                            )
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                // Blue dot indicator for unread (Instagram style)
                if conversation.unreadCount > 0 {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.background, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .center, spacing: 6) {
                    Text(conversation.otherUser.username)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)

                    // Blue checkmark if verified
                    if conversation.otherUser.hasBlueCheckmark == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.primary)
                    }

                    Spacer()

                    Text(timeAgo(conversation.lastMessage?.createdAt ?? conversation.updatedAt))
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                HStack(alignment: .center, spacing: 6) {
                    // Message preview with media icon if applicable
                    HStack(spacing: 4) {
                        if let messageType = conversation.lastMessage?.messageType {
                            if messageType == .image {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            } else if messageType == .video {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }

                        Text(conversation.lastMessage?.content ?? "No messages yet")
                            .font(.system(size: 15))
                            .foregroundColor(conversation.unreadCount > 0 ? Theme.Colors.text : Theme.Colors.secondaryText)
                            .fontWeight(conversation.unreadCount > 0 ? .medium : .regular)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Unread count badge (Instagram style)
                    if conversation.unreadCount > 0 {
                        if conversation.unreadCount == 1 {
                            // Just the dot for single unread
                            Circle()
                                .fill(Theme.Colors.primary)
                                .frame(width: 8, height: 8)
                        } else {
                            // "X+ new" for multiple unread
                            Text("\(min(conversation.unreadCount, 99))+ new")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
        .sheet(isPresented: $showingUserProfile) {
            if let user = otherUserProfile {
                NavigationView {
                    UniversalProfileView(user: user)
                        .environmentObject(AuthManager.shared)
                        .navigationBarItems(trailing: Button("Done") {
                            showingUserProfile = false
                        })
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading profile...")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.background)
            }
        }
    }

    private func fetchAndShowProfile() {
        guard !isLoadingProfile else { return }

        isLoadingProfile = true
        showingUserProfile = true

        Task {
            do {
                let profile = try await APIClient.shared.fetchUserProfile(userId: conversation.otherUser.id)

                await MainActor.run {
                    self.otherUserProfile = profile
                    self.isLoadingProfile = false
                }
            } catch {
                print("❌ Failed to fetch user profile: \(error)")
                await MainActor.run {
                    self.isLoadingProfile = false
                    self.showingUserProfile = false
                }
            }
        }
    }

    private func timeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }

        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        } else {
            let weeks = Int(timeInterval / 604800)
            return "\(weeks)w"
        }
    }
}

// MARK: - New Chat View
struct NewChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var users: [User] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    TextField(LocalizationHelper.localizedString("search_users"), text: $searchText)
                        .font(.system(size: 16))
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .cornerRadius(12)
                .padding(.horizontal, Theme.Spacing.md)
                
                // Users list
                List(users, id: \.id) { user in
                    Button(action: {
                        // Start conversation with user
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            BrrowAsyncImage(url: user.profilePicture) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Theme.Colors.primary.opacity(0.2))
                                    .overlay(
                                        Text(String(user.username.prefix(1)).uppercased())
                                            .foregroundColor(Theme.Colors.primary)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            Text(user.username)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .navigationTitle(LocalizationHelper.localizedString("new_message"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationHelper.localizedString("cancel")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SocialChatView()
        .environmentObject(ChatListViewModel())
}