//
//  SystemNotificationsView.swift
//  Brrow
//
//  System notifications view for important updates (excluding chat messages)
//

import SwiftUI

struct SystemNotificationsView: View {
    @StateObject private var viewModel = SystemNotificationsViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedNotification: SystemNotification?
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Menu {
                            Button(action: { viewModel.markAllAsRead() }) {
                                Label("Mark All as Read", systemImage: "checkmark.circle")
                            }
                            
                            Button(action: { viewModel.clearAllNotifications() }) {
                                Label("Clear All", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadNotifications()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondary)
            
            Text("No Notifications")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Text("You're all caught up! Important notifications will appear here.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.groupedNotifications, id: \.date) { group in
                    Section {
                        ForEach(group.notifications) { notification in
                            SystemNotificationRow(notification: notification)
                                .onTapGesture {
                                    handleNotificationTap(notification)
                                }
                        }
                    } header: {
                        HStack {
                            Text(group.date.notificationDateHeader)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.secondaryBackground)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refreshNotifications()
        }
    }
    
    private func handleNotificationTap(_ notification: SystemNotification) {
        // Mark as read
        viewModel.markAsRead(notification)
        
        // Handle navigation based on notification type
        switch notification.type {
        case .newOffer, .offerAccepted, .offerDeclined:
            // Navigate to listing detail
            TabSelectionManager.shared.switchToMarketplace()
            presentationMode.wrappedValue.dismiss()
            
        case .paymentReceived:
            // Navigate to earnings/transactions
            TabSelectionManager.shared.selectedTab = 4 // Profile tab
            NotificationCenter.default.post(name: .openEarnings, object: nil)
            presentationMode.wrappedValue.dismiss()
            
        case .listingExpiring:
            // Navigate to my posts
            TabSelectionManager.shared.selectedTab = 4 // Profile tab
            presentationMode.wrappedValue.dismiss()
            
        case .karmaUpdate:
            // Show achievement detail
            selectedNotification = notification
            
        case .newMessage:
            // Navigate to messages
            TabSelectionManager.shared.selectedTab = 3 // Messages tab
            presentationMode.wrappedValue.dismiss()
            
        case .transactionUpdate, .reviewReceived:
            // Navigate to profile
            TabSelectionManager.shared.selectedTab = 4 // Profile tab
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Notification Row
struct SystemNotificationRow: View {
    let notification: SystemNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 48, height: 48)
                
                Image(systemName: notification.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
                
                Text(notification.timestamp.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            notification.isRead ? Color.clear : Theme.Colors.primary.opacity(0.05)
        )
    }
    
    private var iconBackground: Color {
        switch notification.type {
        case .newOffer, .offerAccepted:
            return Theme.Colors.primary.opacity(0.1)
        case .offerDeclined:
            return Color.red.opacity(0.1)
        case .paymentReceived:
            return Color.green.opacity(0.1)
        case .karmaUpdate:
            return Color.orange.opacity(0.1)
        case .newMessage, .transactionUpdate:
            return Color.blue.opacity(0.1)
        case .listingExpiring, .reviewReceived:
            return Theme.Colors.secondary.opacity(0.1)
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .newOffer, .offerAccepted:
            return Theme.Colors.primary
        case .offerDeclined:
            return .red
        case .paymentReceived:
            return .green
        case .karmaUpdate:
            return .orange
        case .newMessage, .transactionUpdate:
            return .blue
        case .listingExpiring, .reviewReceived:
            return Theme.Colors.secondary
        }
    }
}

// MARK: - View Model
class SystemNotificationsViewModel: ObservableObject {
    @Published var notifications: [SystemNotification] = []
    @Published var isLoading = false
    @Published var error: String?
    
    var groupedNotifications: [(date: Date, notifications: [SystemNotification])] {
        let grouped = Dictionary(grouping: notifications) { notification in
            Calendar.current.startOfDay(for: notification.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, notifications: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }
    
    func loadNotifications() {
        isLoading = true
        
        Task {
            do {
                // Fetch notifications from API
                let response = try await APIClient.shared.getSystemNotifications()
                
                await MainActor.run {
                    self.notifications = response.data ?? []
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshNotifications() async {
        do {
            let response = try await APIClient.shared.getSystemNotifications()
            
            await MainActor.run {
                self.notifications = response.data ?? []
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func markAsRead(_ notification: SystemNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        
        notifications[index].isRead = true
        
        // Update on server
        Task {
            try? await APIClient.shared.markNotificationAsRead(notificationId: notification.id)
        }
    }
    
    func markAllAsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
        
        // Update on server
        Task {
            try? await APIClient.shared.markAllNotificationsAsRead()
        }
    }
    
    func clearAllNotifications() {
        notifications.removeAll()
        
        // Clear on server
        Task {
            try? await APIClient.shared.clearAllNotifications()
        }
    }
}

// MARK: - Models
struct SystemNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let metadata: [String: String]?
    
    var icon: String {
        switch type {
        case .newOffer:
            return "envelope.badge"
        case .offerAccepted:
            return "checkmark.circle.fill"
        case .offerDeclined:
            return "xmark.circle.fill"
        case .paymentReceived:
            return "dollarsign.circle.fill"
        case .listingExpiring:
            return "clock.fill"
        case .newMessage:
            return "message.fill"
        case .transactionUpdate:
            return "arrow.triangle.2.circlepath"
        case .reviewReceived:
            return "star.fill"
        case .karmaUpdate:
            return "heart.fill"
        }
    }
}

// NotificationType enum is already defined in Enums.swift
// Removed duplicate definition to fix build error

// MARK: - Date Extension
extension Date {
    var notificationDateHeader: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: self, to: Date()).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }
    }
}