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
    
    var body: some View {
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
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack {
            Text(LocalizationHelper.localizedString("messages"))
                .font(.system(size: 32, weight: .bold))
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
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.conversations.isEmpty {
                    emptyChatState
                } else {
                    ForEach(filteredConversations, id: \.id) { conversation in
                        NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                            SocialConversationRow(conversation: conversation)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
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
                conversation.lastMessage.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Social Conversation Row
struct SocialConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Profile picture
            BrrowAsyncImage(url: conversation.otherUser.profilePicture) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.2))
                    .overlay(
                        Text(String(conversation.otherUser.username.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.primary)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Text(timeAgo(conversation.lastMessage.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                HStack {
                    Text(conversation.lastMessage.content)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(min(conversation.unreadCount, 9))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
    
    private func timeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
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