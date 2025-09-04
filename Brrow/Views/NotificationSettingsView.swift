//
//  NotificationSettingsView.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Professional notification settings interface
//

import SwiftUI

struct PushNotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var settings: NotificationSettings
    @State private var showingPermissionAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    init() {
        _settings = State(initialValue: NotificationManager.shared.notificationSettings)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    permissionSection
                    categorySettingsSection
                    quietHoursSection
                    advancedSection
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings", role: .none) {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive notifications, please enable them in Settings > Notifications > Brrow")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.primary)
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("Stay Connected")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Get notified about messages, rental requests, and important updates")
                    .font(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Spacing.lg)
    }
    
    private var permissionSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: notificationManager.hasPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(notificationManager.hasPermission ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permission")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(notificationManager.hasPermission ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                if !notificationManager.hasPermission {
                    Button("Enable") {
                        requestPermission()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    private var categorySettingsSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Notification Types")
            
            VStack(spacing: 0) {
                PushNotificationToggleRow(
                    icon: "message.fill",
                    title: "Messages",
                    subtitle: "New messages from other users",
                    isOn: $settings.newMessages
                )
                
                Divider()
                    .padding(.leading, 56)
                
                PushNotificationToggleRow(
                    icon: "calendar.badge.plus",
                    title: "Rental Updates",
                    subtitle: "Requests, confirmations, and updates",
                    isOn: $settings.rentalUpdates
                )
                
                Divider()
                    .padding(.leading, 56)
                
                PushNotificationToggleRow(
                    icon: "creditcard.fill",
                    title: "Payments",
                    subtitle: "Payment confirmations and receipts",
                    isOn: $settings.payments
                )
                
                Divider()
                    .padding(.leading, 56)
                
                PushNotificationToggleRow(
                    icon: "trophy.fill",
                    title: "Achievements",
                    subtitle: "New achievements and milestones",
                    isOn: $settings.achievements
                )
                
                Divider()
                    .padding(.leading, 56)
                
                PushNotificationToggleRow(
                    icon: "location.fill",
                    title: "Nearby Items",
                    subtitle: "Items available near you",
                    isOn: $settings.nearbyItems
                )
                
                Divider()
                    .padding(.leading, 56)
                
                PushNotificationToggleRow(
                    icon: "megaphone.fill",
                    title: "Promotions",
                    subtitle: "Special offers and updates",
                    isOn: $settings.marketing
                )
            }
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.lg)
    }
    
    private var quietHoursSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Quiet Hours")
            
            VStack(spacing: 0) {
                PushNotificationToggleRow(
                    icon: "moon.fill",
                    title: "Enable Quiet Hours",
                    subtitle: "Pause notifications during specified hours",
                    isOn: $settings.quietHoursEnabled
                )
                
                if settings.quietHoursEnabled {
                    Divider()
                        .padding(.leading, 56)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quiet Hours Schedule")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            HStack(spacing: Theme.Spacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Start")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                    
                                    Button(settings.quietHoursStart) {
                                        // Show time picker for start time
                                    }
                                    .foregroundColor(Theme.Colors.primary)
                                    .fontWeight(.medium)
                                }
                                
                                Text("to")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("End")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                    
                                    Button(settings.quietHoursEnd) {
                                        // Show time picker for end time
                                    }
                                    .foregroundColor(Theme.Colors.primary)
                                    .fontWeight(.medium)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.lg)
    }
    
    private var advancedSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Advanced")
            
            VStack(spacing: 0) {
                Button(action: {
                    NotificationManager.shared.clearAllNotifications()
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clear All Notifications")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("Remove all pending and delivered notifications")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(Theme.Spacing.md)
                }
                
                Divider()
                    .padding(.leading, 56)
                
                Button(action: {
                    openAppSettings()
                }) {
                    HStack {
                        Image(systemName: "gear.badge")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("System Settings")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("Open iOS notification settings")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(Theme.Spacing.md)
                }
                
                Divider()
                    .padding(.leading, 56)
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Status")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text(notificationManager.isRegistered ? "Registered for push notifications" : "Not registered")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(notificationManager.isRegistered ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xl)
    }
    
    private func requestPermission() {
        NotificationManager.shared.requestPermission { granted in
            if !granted {
                showingPermissionAlert = true
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func saveSettings() {
        NotificationManager.shared.updateSettings(settings)
        presentationMode.wrappedValue.dismiss()
    }
}

struct PushNotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
        }
        .padding(Theme.Spacing.md)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }
}

#Preview {
    PushNotificationSettingsView()
}