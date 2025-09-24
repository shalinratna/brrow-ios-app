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
                if notificationService.notifications.isEmpty && !isLoading {
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
            }
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
            return notificationService.notifications.filter { !$0.isRead }
        case "rental":
            return notificationService.notifications.filter {
                $0.type.contains("offer") || $0.type.contains("rental")
            }
        case "message":
            return notificationService.notifications.filter { $0.type == "new_message" }
        case "offer":
            return notificationService.notifications.filter { $0.type.contains("offer") }
        case "all":
            return notificationService.notifications
        default:
            return notificationService.notifications
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        notificationService.loadNotificationHistory()
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
        if let actionUrl = notification.actionUrl {
            // Handle deep linking navigation
            print("Navigate to: \(actionUrl)")
        }
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

// MARK: - Preview

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}