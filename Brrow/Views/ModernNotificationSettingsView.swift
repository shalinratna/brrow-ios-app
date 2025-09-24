import SwiftUI
import UserNotifications

struct ModernNotificationSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var settings = ModernNotificationSettings()
    @State private var isLoading = false
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        Form {
            // Push Notifications
            Section {
                Toggle(isOn: $settings.pushEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Push Notifications")
                                .font(.body)
                            Text("Get alerts on your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .onChange(of: settings.pushEnabled) { oldValue, newValue in
                    if newValue {
                        requestNotificationPermission()
                    }
                }
            }
            
            // Notification Types
            Section("What to notify me about") {
                ForEach(NotificationSettingType.allCases, id: \.self) { type in
                    NotificationToggleRow(
                        type: type,
                        isEnabled: binding(for: type)
                    )
                }
            }
            
            // Email Notifications
            Section("Email Notifications") {
                Toggle(isOn: $settings.emailDigest) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Digest")
                                .font(.body)
                            Text("Summary of your Brrow activity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Theme.Colors.accentBlue)
                    }
                }
                
                Toggle(isOn: $settings.marketingEmails) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Updates & Offers")
                                .font(.body)
                            Text("New features and special deals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(Theme.Colors.accentPurple)
                    }
                }
            }
            
            // Quiet Hours
            Section("Quiet Hours") {
                Toggle(isOn: $settings.quietHoursEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Do Not Disturb")
                                .font(.body)
                            Text("Pause notifications during set hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "moon.fill")
                            .foregroundColor(Theme.Colors.accentOrange)
                    }
                }
                
                if settings.quietHoursEnabled {
                    DatePicker("From", selection: $settings.quietHoursStart, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $settings.quietHoursEnd, displayedComponents: .hourAndMinute)
                }
            }
            
            // Sound & Vibration
            Section("Sound & Vibration") {
                Toggle(isOn: $settings.soundEnabled) {
                    Label("Notification Sounds", systemImage: "speaker.wave.3.fill")
                        .foregroundColor(Theme.Colors.info)
                }
                
                Toggle(isOn: $settings.vibrationEnabled) {
                    Label("Vibration", systemImage: "iphone.radiowaves.left.and.right")
                        .foregroundColor(Theme.Colors.success)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveSettings()
                }
                .fontWeight(.semibold)
                .disabled(isLoading)
            }
        }
        .overlay(
            Group {
                if showingSaveConfirmation {
                    SaveConfirmationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
        )
        .onAppear {
            loadSettings()
        }
    }
    
    private func binding(for type: NotificationSettingType) -> Binding<Bool> {
        switch type {
        case .messages:
            return $settings.messagesEnabled
        case .listings:
            return $settings.listingsEnabled
        case .offers:
            return $settings.offersEnabled
        case .reviews:
            return $settings.reviewsEnabled
        case .reminders:
            return $settings.remindersEnabled
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if !granted {
                DispatchQueue.main.async {
                    settings.pushEnabled = false
                }
            }
        }
    }
    
    private func loadSettings() {
        Task {
            isLoading = true
            do {
                let response = try await APIClient.shared.getNotificationSettings()
                await MainActor.run {
                    // Update settings from API response
                    settings.pushEnabled = response.data.pushEnabled
                    settings.messagesEnabled = response.data.messagesReceived
                    settings.listingsEnabled = response.data.listingInquiries
                    settings.offersEnabled = response.data.favoriteListingUpdates
                    settings.reviewsEnabled = response.data.reviewsReceived
                    settings.remindersEnabled = response.data.garageSaleReminders
                    settings.emailDigest = response.data.emailEnabled
                    settings.marketingEmails = response.data.systemUpdates
                    settings.soundEnabled = response.data.pushEnabled // Use push as proxy for sound
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Keep defaults if API fails
                    isLoading = false
                }
                print("Failed to load notification settings: \(error)")
            }
        }
    }
    
    private func saveSettings() {
        Task {
            isLoading = true

            do {
                // Prepare notification settings for API
                let notificationSettings: [String: Bool] = [
                    "pushEnabled": settings.pushEnabled,
                    "emailEnabled": settings.emailDigest,
                    "smsEnabled": false, // Not supported in this view
                    "listingInquiries": settings.listingsEnabled,
                    "listingSold": true, // Default enabled
                    "messagesReceived": settings.messagesEnabled,
                    "reviewsReceived": settings.reviewsEnabled,
                    "favoriteListingUpdates": settings.offersEnabled,
                    "garageSaleReminders": settings.remindersEnabled,
                    "seekMatches": true, // Default enabled
                    "systemUpdates": settings.marketingEmails,
                    "securityAlerts": true // Always enabled for security
                ]

                // Save to API
                try await APIClient.shared.updateNotificationSettings(settings: notificationSettings)

                await MainActor.run {
                    withAnimation {
                        showingSaveConfirmation = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingSaveConfirmation = false
                        }
                    }

                    HapticManager.notification(type: .success)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Failed to save notification settings: \(error)")
                    // Show error to user here
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct ModernNotificationSettings {
    var pushEnabled = true
    var messagesEnabled = true
    var listingsEnabled = true
    var offersEnabled = true
    var reviewsEnabled = true
    var remindersEnabled = true
    var emailDigest = true
    var marketingEmails = false
    var quietHoursEnabled = false
    var quietHoursStart = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    var soundEnabled = true
    var vibrationEnabled = true
}

enum NotificationSettingType: String, CaseIterable {
    case messages = "Messages"
    case listings = "Listing Updates"
    case offers = "Offers & Requests"
    case reviews = "Reviews"
    case reminders = "Reminders"
    
    var icon: String {
        switch self {
        case .messages: return "message.fill"
        case .listings: return "bag.fill"
        case .offers: return "tag.fill"
        case .reviews: return "star.fill"
        case .reminders: return "bell.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .messages: return Theme.Colors.accentBlue
        case .listings: return Theme.Colors.primary
        case .offers: return Theme.Colors.success
        case .reviews: return Theme.Colors.warning
        case .reminders: return Theme.Colors.info
        }
    }
    
    var description: String {
        switch self {
        case .messages: return "New messages and replies"
        case .listings: return "Updates on your listings"
        case .offers: return "New offers and booking requests"
        case .reviews: return "When someone reviews you"
        case .reminders: return "Booking reminders and deadlines"
        }
    }
}

struct NotificationToggleRow: View {
    let type: NotificationSettingType
    @Binding var isEnabled: Bool
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.body)
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
            }
        }
    }
}

struct SaveConfirmationView: View {
    @State private var scale = 0.5
    @State private var opacity = 0.0
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Settings Saved")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                Capsule()
                    .fill(Theme.Colors.success)
                    .shadow(radius: 10)
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .padding(.top, 50)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring()) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Preview

struct ModernNotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ModernNotificationSettingsView()
                .environmentObject(AuthManager.shared)
        }
    }
}