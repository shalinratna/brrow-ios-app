//
//  NotificationsView.swift
//  Brrow
//
//  Displays user notifications and manages preferences
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationManager = PushNotificationManager.shared
    @State private var selectedFilter = "all"
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var selectedNotification: AppNotification?
    
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
                if notificationManager.notifications.isEmpty && !isLoading {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if notificationManager.unreadCount > 0 {
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
    
    private var filteredNotifications: [AppNotification] {
        switch selectedFilter {
        case "unread":
            return notificationManager.notifications.filter { !$0.isRead }
        case "all":
            return notificationManager.notifications
        default:
            return notificationManager.notifications.filter { $0.type.contains(selectedFilter) }
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        await notificationManager.fetchNotifications(type: selectedFilter)
        isLoading = false
    }
    
    private func markAsRead(_ notification: AppNotification) async {
        await notificationManager.markAsRead(notificationId: notification.id)
    }
    
    private func markAllAsRead() {
        Task {
            await notificationManager.markAllAsRead()
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        if !notification.isRead {
            Task {
                await markAsRead(notification)
            }
        }
        
        // Handle navigation based on notification type
        notificationManager.handleNotificationAction(notification)
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    private var iconName: String {
        switch notification.type {
        case "rental_request": return "calendar.badge.plus"
        case "rental_accepted": return "checkmark.circle.fill"
        case "rental_rejected": return "xmark.circle.fill"
        case "payment_received": return "creditcard.fill"
        case "message": return "message.fill"
        case "offer": return "tag.fill"
        case "new_listing": return "sparkles"
        case "garage_sale": return "house.fill"
        default: return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case "rental_accepted", "payment_received": return .green
        case "rental_rejected": return .red
        case "message": return .blue
        case "offer": return .orange
        case "new_listing": return .purple
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
                    
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    if let timeAgo = notification.timeAgo {
                        Text(timeAgo)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                    }
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
    let notification: AppNotification
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
                        
                        if let timeAgo = notification.timeAgo {
                            Text(timeAgo)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Message
                    Text(notification.message)
                        .font(.body)
                    
                    // Additional data
                    if !notification.data.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)
                            
                            ForEach(Array(notification.data.keys.sorted()), id: \.self) { key in
                                if let value = notification.data[key] {
                                    HStack {
                                        Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("\(value)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
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
                            PushNotificationManager.shared.handleNotificationAction(notification)
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