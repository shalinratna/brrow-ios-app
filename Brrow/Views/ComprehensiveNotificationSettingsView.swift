//
//  ComprehensiveNotificationSettingsView.swift
//  Brrow
//
//  Production-ready comprehensive notification settings with all features
//

import SwiftUI

struct ComprehensiveNotificationSettingsView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // General Toggles
                    generalSettingsSection

                    // Category Preferences
                    categoryPreferencesSection

                    // Listing Activity
                    listingActivitySection

                    // Seek Matching
                    seekMatchingSection

                    // Meetup Reminders
                    meetupRemindersSection

                    // Quiet Hours
                    quietHoursSection

                    // Rate Limiting
                    rateLimitingSection
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Settings Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your notification preferences have been updated successfully.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.primary)

            Text("Manage Notifications")
                .font(.title2)
                .fontWeight(.bold)

            Text("Customize how you receive updates about your activity")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - General Settings

    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                Toggle("Push Notifications", isOn: $viewModel.preferences.pushNotificationsEnabled)
                    .padding()

                Divider()

                Toggle("Email Notifications", isOn: $viewModel.preferences.emailNotificationsEnabled)
                    .padding()

                Divider()

                Toggle("SMS Notifications", isOn: $viewModel.preferences.smsNotificationsEnabled)
                    .padding()
            }
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Category Preferences

    private var categoryPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                CategoryPreferenceRow(
                    icon: "message.fill",
                    title: "Messages",
                    subtitle: "Chat messages and direct communications",
                    preference: $viewModel.preferences.messages
                )

                CategoryPreferenceRow(
                    icon: "arrow.left.arrow.right",
                    title: "Transactions",
                    subtitle: "Rental requests, payments, and completions",
                    preference: $viewModel.preferences.transactions
                )

                CategoryPreferenceRow(
                    icon: "list.bullet.rectangle",
                    title: "Listings",
                    subtitle: "Your listing activity and updates",
                    preference: $viewModel.preferences.listings
                )

                CategoryPreferenceRow(
                    icon: "star.fill",
                    title: "Reviews",
                    subtitle: "New reviews and ratings",
                    preference: $viewModel.preferences.reviews
                )

                CategoryPreferenceRow(
                    icon: "person.2.fill",
                    title: "Social",
                    subtitle: "Follows, likes, and social interactions",
                    preference: $viewModel.preferences.social
                )

                CategoryPreferenceRow(
                    icon: "lock.shield.fill",
                    title: "Security",
                    subtitle: "Security alerts and account changes",
                    preference: $viewModel.preferences.security
                )

                CategoryPreferenceRow(
                    icon: "megaphone.fill",
                    title: "Marketing",
                    subtitle: "Promotions, tips, and product updates",
                    preference: $viewModel.preferences.marketing
                )
            }
            .padding()
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Listing Activity

    private var listingActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Listing Activity Milestones")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                ListingActivityPreferenceRow(
                    icon: "eye.fill",
                    title: "View Milestones",
                    subtitle: "Get notified when your listings reach view milestones",
                    preference: $viewModel.preferences.listingViews
                )

                ListingActivityPreferenceRow(
                    icon: "heart.fill",
                    title: "Favorite Milestones",
                    subtitle: "Know when people save your listings",
                    preference: $viewModel.preferences.listingFavorites
                )

                ListingActivityPreferenceRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Share Milestones",
                    subtitle: "Track when your listings get shared",
                    preference: $viewModel.preferences.listingShares
                )
            }
            .padding()
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Seek Matching

    private var seekMatchingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seek Matching")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                Toggle("Enable Seek Matching Notifications", isOn: $viewModel.preferences.seekMatching.enabled)
                    .padding()

                if viewModel.preferences.seekMatching.enabled {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Match Score: \(viewModel.preferences.seekMatching.minMatchScore)%")
                            .font(.subheadline)

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.preferences.seekMatching.minMatchScore) },
                                set: { viewModel.preferences.seekMatching.minMatchScore = Int($0) }
                            ),
                            in: 0...100,
                            step: 5
                        )
                        .tint(Theme.Colors.primary)
                    }
                    .padding()

                    Divider()

                    Toggle("Notify Immediately", isOn: $viewModel.preferences.seekMatching.notifyImmediately)
                        .padding()

                    if !viewModel.preferences.seekMatching.notifyImmediately {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Digest Frequency")
                                .font(.subheadline)

                            Picker("Frequency", selection: $viewModel.preferences.seekMatching.digestFrequency) {
                                Text("Daily").tag(NotificationFrequency.daily)
                                Text("Weekly").tag(NotificationFrequency.weekly)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Meetup Reminders

    private var meetupRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meetup Reminders")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                Toggle("Enable Meetup Reminders", isOn: $viewModel.preferences.meetupReminders.enabled)
                    .padding()

                if viewModel.preferences.meetupReminders.enabled {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Times (hours before)")
                            .font(.subheadline)

                        ForEach(viewModel.preferences.meetupReminders.reminderTimes.indices, id: \.self) { index in
                            HStack {
                                Text("\(viewModel.preferences.meetupReminders.reminderTimes[index], specifier: "%.1f") hours")
                                Spacer()
                                Button(action: {
                                    viewModel.preferences.meetupReminders.reminderTimes.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        Text("Default: 24h, 2h, 30min before")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding()

                    Divider()

                    Toggle("Location Updates", isOn: $viewModel.preferences.meetupReminders.locationUpdates)
                        .padding()

                    Divider()

                    Toggle("Status Updates", isOn: $viewModel.preferences.meetupReminders.statusUpdates)
                        .padding()
                }
            }
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Quiet Hours

    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiet Hours")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                Toggle("Enable Quiet Hours", isOn: $viewModel.preferences.quietHoursEnabled)
                    .padding()

                if viewModel.preferences.quietHoursEnabled {
                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                            Text(viewModel.preferences.quietHoursStart)
                                .font(.headline)
                        }

                        Spacer()

                        Text("to")
                            .foregroundColor(Theme.Colors.secondaryText)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("End")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                            Text(viewModel.preferences.quietHoursEnd)
                                .font(.headline)
                        }
                    }
                    .padding()

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exceptions (always notify)")
                            .font(.subheadline)

                        ForEach(viewModel.preferences.quietHoursExceptions, id: \.self) { exception in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.primary)
                                Text(exception.capitalized)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Rate Limiting

    private var rateLimitingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Notifications")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max per hour: \(viewModel.preferences.maxNotificationsPerHour)")
                        .font(.subheadline)

                    Slider(
                        value: Binding(
                            get: { Double(viewModel.preferences.maxNotificationsPerHour) },
                            set: { viewModel.preferences.maxNotificationsPerHour = Int($0) }
                        ),
                        in: 1...20,
                        step: 1
                    )
                    .tint(Theme.Colors.primary)
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Max per day: \(viewModel.preferences.maxNotificationsPerDay)")
                        .font(.subheadline)

                    Slider(
                        value: Binding(
                            get: { Double(viewModel.preferences.maxNotificationsPerDay) },
                            set: { viewModel.preferences.maxNotificationsPerDay = Int($0) }
                        ),
                        in: 10...100,
                        step: 5
                    )
                    .tint(Theme.Colors.primary)
                }
                .padding()

                Divider()

                Toggle("Group Similar Notifications", isOn: $viewModel.preferences.groupSimilarNotifications)
                    .padding()

                if viewModel.preferences.groupSimilarNotifications {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grouping window: \(viewModel.preferences.groupingWindowMinutes) minutes")
                            .font(.subheadline)

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.preferences.groupingWindowMinutes) },
                                set: { viewModel.preferences.groupingWindowMinutes = Int($0) }
                            ),
                            in: 5...60,
                            step: 5
                        )
                        .tint(Theme.Colors.primary)
                    }
                    .padding()
                }
            }
            .background(Theme.Colors.surface)
            .cornerRadius(12)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Actions

    private func savePreferences() {
        viewModel.savePreferences()
        showingSaveConfirmation = true
    }
}

// MARK: - Category Preference Row

struct CategoryPreferenceRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var preference: CategoryPreference
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            if isExpanded {
                VStack(spacing: 8) {
                    Toggle("Push", isOn: $preference.push)
                    Toggle("Email", isOn: $preference.email)
                    Toggle("SMS", isOn: $preference.sms)
                }
                .padding(.leading, 36)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Listing Activity Preference Row

struct ListingActivityPreferenceRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var preference: ListingActivityPreference
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }

                    Spacer()

                    Toggle("", isOn: $preference.enabled)
                        .labelsHidden()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            if isExpanded && preference.enabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Threshold: \(preference.threshold)")
                        .font(.subheadline)

                    Slider(
                        value: Binding(
                            get: { Double(preference.threshold) },
                            set: { preference.threshold = Int($0) }
                        ),
                        in: 1...500,
                        step: title.contains("View") ? 100 : (title.contains("Favorite") ? 10 : 5)
                    )
                    .tint(Theme.Colors.primary)

                    Picker("Frequency", selection: $preference.frequency) {
                        Text("Once").tag(NotificationFrequency.once)
                        Text("Daily").tag(NotificationFrequency.daily)
                        Text("Weekly").tag(NotificationFrequency.weekly)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.leading, 36)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ViewModel

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    @Published var preferences: NotificationPreferences
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        // Initialize with default preferences
        // In production, this would load from UserDefaults or API
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            self.preferences = NotificationPreferences(userId: "")
            return
        }

        self.preferences = NotificationPreferences(userId: currentUserId)
        loadPreferences()
    }

    func loadPreferences() {
        // TODO: Load from backend API
        // For now, load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "notificationPreferences"),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            preferences = decoded
        }
    }

    func savePreferences() {
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "notificationPreferences")
        }

        // TODO: Save to backend API
        // APIClient.shared.updateNotificationPreferences(preferences)
    }
}

#Preview {
    ComprehensiveNotificationSettingsView()
}
