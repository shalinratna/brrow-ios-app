//
//  NotificationsView.swift
//  Brrow
//
//  Displays user notifications and manages preferences
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationService = UnifiedNotificationService.shared
    @State private var selectedFilter = "all"
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var selectedNotification: NotificationHistoryItem?
    @State private var selectedChatId: String?
    @State private var navigateToChat = false
    @State private var selectedTransactionId: String?
    @State private var navigateToTransaction = false
    @State private var allNotifications: [NotificationHistoryItem] = []

    private let filters = [
        ("all", "All"),
        ("unread", "Unread"),
        ("rental", "Rentals"),
        ("message", "Messages"),
        ("offer", "Offers")
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                filterTabs

                // Notifications list
                if allNotifications.isEmpty && !isLoading {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if notificationService.unreadCount > 0 {
                        Button("Mark All Read") {
                            markAllAsRead()
                        }
                        .font(.footnote)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NotificationSettingsView()
            }
            .sheet(item: $selectedNotification) { notification in
                NotificationDetailView(notification: notification)
            }
            .refreshable {
                await loadNotifications()
            }
            .onAppear {
                Task {
                    await loadNotifications()
                }
                AnalyticsService.shared.trackScreen(name: "notifications")
            }
            .background(
                Group {
                    NavigationLink(
                        destination: chatDestinationView,
                        isActive: $navigateToChat,
                        label: { EmptyView() }
                    )
                    .hidden()

                    NavigationLink(
                        destination: transactionDestinationView,
                        isActive: $navigateToTransaction,
                        label: { EmptyView() }
                    )
                    .hidden()
                }
            )
        }
    }

    @ViewBuilder
    private var chatDestinationView: some View {
        if let chatId = selectedChatId {
            ConversationNavigationView(conversationId: chatId)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var transactionDestinationView: some View {
        if let transactionId = selectedTransactionId {
            TransactionDetailView(purchaseId: transactionId)
        } else {
            EmptyView()
        }
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.0) { filter in
                    NotificationFilterChip(
                        title: filter.1,
                        isSelected: selectedFilter == filter.0,
                        action: {
                            selectedFilter = filter.0
                            Task {
                                await loadNotifications()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredNotifications) { notification in
                    NotificationRow(
                        notification: notification,
                        onTap: {
                            handleNotificationTap(notification)
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !notification.isRead {
                            Button {
                                Task {
                                    await markAsRead(notification)
                                }
                            } label: {
                                Label("Mark Read", systemImage: "envelope.open")
                            }
                            .tint(.blue)
                        }
                    }
                    
                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("When you receive notifications, they'll appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var filteredNotifications: [NotificationHistoryItem] {
        switch selectedFilter {
        case "unread":
            return allNotifications.filter { !$0.isRead }
        case "rental":
            return allNotifications.filter {
                $0.type.contains("offer") || $0.type.contains("rental")
            }
        case "message":
            return allNotifications.filter { $0.type == "new_message" }
        case "offer":
            return allNotifications.filter { $0.type.contains("offer") }
        case "all":
            return allNotifications
        default:
            return allNotifications
        }
    }

    private func loadNotifications() async {
        isLoading = true

        // Load regular notifications
        notificationService.loadNotificationHistory()

        // Load unread messages as notifications
        let unreadMessages = await notificationService.getUnreadMessages()

        // Combine and sort by date
        let combined = notificationService.notifications + unreadMessages
        allNotifications = combined.sorted { notification1, notification2 in
            notification1.createdDate > notification2.createdDate
        }

        isLoading = false
    }

    private func markAsRead(_ notification: NotificationHistoryItem) async {
        notificationService.markAsRead(notification.id)
    }

    private func markAllAsRead() {
        notificationService.markAllAsRead()
    }

    private func handleNotificationTap(_ notification: NotificationHistoryItem) {
        if !notification.isRead {
            notificationService.markAsRead(notification.id)
        }

        // Handle navigation based on notification type
        if notification.type == "new_message" {
            // Navigate to chat
            if let chatId = notification.payload?["chatId"] {
                selectedChatId = chatId
                navigateToChat = true
            }
        } else if let actionUrl = notification.actionUrl {
            // Handle deep linking navigation for other types
            handleDeepLink(actionUrl)
        }
    }

    private func handleDeepLink(_ urlString: String) {
        // Parse deep link URL (e.g., "brrow://chat/123")
        if urlString.hasPrefix("brrow://chat/") {
            let chatId = urlString.replacingOccurrences(of: "brrow://chat/", with: "")
            selectedChatId = chatId
            navigateToChat = true
        } else if urlString.hasPrefix("brrow://rental/") {
            // Handle rental/transaction deep link (e.g., "brrow://rental/txn_abc123")
            let transactionId = urlString.replacingOccurrences(of: "brrow://rental/", with: "")
            selectedTransactionId = transactionId
            navigateToTransaction = true
        } else if urlString.hasPrefix("brrow://transaction/") {
            // Handle transaction deep link (e.g., "brrow://transaction/txn_abc123")
            let transactionId = urlString.replacingOccurrences(of: "brrow://transaction/", with: "")
            selectedTransactionId = transactionId
            navigateToTransaction = true
        } else if urlString == "brrow://transactions" || urlString == "brrow://payments" {
            // Handle generic transactions/payments URL - could show TransactionsListView
            // For now, just log it
            print("Navigate to transactions list")
        }
        print("Navigate to: \(urlString)")
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: NotificationHistoryItem
    let onTap: () -> Void

    private var iconName: String {
        switch notification.type {
        case "new_offer", "rental_request": return "calendar.badge.plus"
        case "offer_accepted", "rental_accepted": return "checkmark.circle.fill"
        case "offer_declined", "rental_rejected": return "xmark.circle.fill"
        case "payment_received": return "creditcard.fill"
        case "new_message": return "message.fill"
        case "review_received": return "star.fill"
        case "achievement_unlocked": return "trophy.fill"
        case "listing_expiring": return "clock.fill"
        default: return "bell.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case "offer_accepted", "payment_received": return .green
        case "offer_declined": return .red
        case "new_message": return .blue
        case "new_offer": return .orange
        case "review_received": return .yellow
        case "achievement_unlocked": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.body)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)

                    Text(notification.createdDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(notification.isRead ? Color.clear : Color.blue.opacity(0.02))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Chip

struct NotificationFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                )
        }
    }
}

// MARK: - Notification Detail View

struct NotificationDetailView: View {
    let notification: NotificationHistoryItem
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(notification.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(notification.createdDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Message
                    Text(notification.body)
                        .font(.body)

                    // Additional data
                    if let payload = notification.payload, !payload.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)

                            ForEach(Array(payload.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(payload[key] ?? "")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)
                    }
                    
                    // Action button
                    if notification.actionUrl != nil {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            // Handle navigation to action URL
                            if let actionUrl = notification.actionUrl {
                                print("Navigate to: \(actionUrl)")
                            }
                        }) {
                            Text("View Details")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Conversation Navigation Helper

struct ConversationNavigationView: View {
    let conversationId: String
    @State private var conversation: Conversation?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading conversation...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let conversation = conversation {
                EnhancedChatDetailView(conversation: conversation)
            } else {
                Text("Conversation not found")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            Task {
                await loadConversation()
            }
        }
    }

    private func loadConversation() async {
        do {
            let fetchedConversation = try await APIClient.shared.fetchConversationById(conversationId)
            await MainActor.run {
                self.conversation = fetchedConversation
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "This conversation is no longer available"
                self.isLoading = false
            }
            print("Failed to fetch conversation: \(error)")
        }
    }
}

// MARK: - Preview

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}