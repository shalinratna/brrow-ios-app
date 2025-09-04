//
//  SocialMainTabView.swift
//  Brrow
//
//  Revolutionary Social Tab Experience
//

import SwiftUI

struct SocialMainTabView: View {
    @StateObject private var discoverViewModel = DiscoverViewModel()
    @StateObject private var chatViewModel = ChatListViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var earningsViewModel = EarningsViewModel()
    @StateObject private var settingsManager = SettingsManager.shared
    @EnvironmentObject var authManager: AuthManager
    
    @State private var selectedTab = 0
    @State private var showingPostSheet = false
    @State private var tabOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $selectedTab) {
                // Discover (Home)
                DiscoverView()
                    .environmentObject(discoverViewModel)
                    .tag(0)
                
                // Search & Browse
                SearchView()
                    .tag(1)
                
                // Post (handled by sheet)
                Color.clear
                    .tag(2)
                
                // Messages
                SocialChatView()
                    .environmentObject(chatViewModel)
                    .tag(3)
                
                // Earnings
                EarningsView()
                    .environmentObject(earningsViewModel)
                    .tag(4)
                
                // Profile
                Group {
                    if let currentUser = authManager.currentUser {
                        SocialProfileView(user: currentUser)
                    } else {
                        ProgressView("Loading...")
                    }
                }
                .environmentObject(profileViewModel)
                .tag(5)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom tab bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingPostSheet) {
            PostCreationView()
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                showingPostSheet = true
                // Reset to previous tab
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        VStack(spacing: 0) {
            // Tab bar background with blur
            HStack(spacing: 0) {
                ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                    TabBarItem(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        title: item.title,
                        isSelected: selectedTab == index,
                        badgeCount: badgeCount(for: index),
                        isSpecial: index == 2
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 34) // Safe area
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Tab Items Configuration
    private var tabItems: [(icon: String, selectedIcon: String, title: String)] {
        [
            ("house", "house.fill", "Discover"),
            ("magnifyingglass", "magnifyingglass", "Search"),
            ("plus.circle", "plus.circle.fill", "Post"),
            ("message", "message.fill", "Messages"),
            ("dollarsign.circle", "dollarsign.circle.fill", "Earnings"),
            ("person", "person.fill", "Profile")
        ]
    }
    
    private func badgeCount(for index: Int) -> Int {
        switch index {
        case 3: return chatViewModel.unreadCount
        case 4: return earningsViewModel.pendingPayments
        default: return 0
        }
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool
    let badgeCount: Int
    let isSpecial: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Special styling for post button
                    if isSpecial {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                        
                        Image(systemName: isSelected ? selectedIcon : icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        // Regular tab item
                        Image(systemName: isSelected ? selectedIcon : icon)
                            .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                    }
                    
                    // Badge
                    if badgeCount > 0 && !isSpecial {
                        Circle()
                            .fill(Theme.Colors.error)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("\\(min(badgeCount, 9))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    .opacity(isSpecial ? 0.8 : 1.0)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Settings Manager for Features
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isBrrowAIEnabled = true
    @Published var isVideoCallsEnabled = true
    @Published var isCommunityFeedEnabled = true
    @Published var isBrrowStoriesEnabled = true
    @Published var isKarmaCreditsEnabled = true
    @Published var isLocationSharingEnabled = true
    @Published var isPushNotificationsEnabled = true
    @Published var isAnalyticsEnabled = true
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load from UserDefaults
        isBrrowAIEnabled = UserDefaults.standard.bool(forKey: "brrowAI_enabled")
        isVideoCallsEnabled = UserDefaults.standard.bool(forKey: "videoCalls_enabled")
        isCommunityFeedEnabled = UserDefaults.standard.bool(forKey: "communityFeed_enabled")
        isBrrowStoriesEnabled = UserDefaults.standard.bool(forKey: "brrowStories_enabled")
        isKarmaCreditsEnabled = UserDefaults.standard.bool(forKey: "karmaCredits_enabled")
        isLocationSharingEnabled = UserDefaults.standard.bool(forKey: "locationSharing_enabled")
        isPushNotificationsEnabled = UserDefaults.standard.bool(forKey: "pushNotifications_enabled")
        isAnalyticsEnabled = UserDefaults.standard.bool(forKey: "analytics_enabled")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isBrrowAIEnabled, forKey: "brrowAI_enabled")
        UserDefaults.standard.set(isVideoCallsEnabled, forKey: "videoCalls_enabled")
        UserDefaults.standard.set(isCommunityFeedEnabled, forKey: "communityFeed_enabled")
        UserDefaults.standard.set(isBrrowStoriesEnabled, forKey: "brrowStories_enabled")
        UserDefaults.standard.set(isKarmaCreditsEnabled, forKey: "karmaCredits_enabled")
        UserDefaults.standard.set(isLocationSharingEnabled, forKey: "locationSharing_enabled")
        UserDefaults.standard.set(isPushNotificationsEnabled, forKey: "pushNotifications_enabled")
        UserDefaults.standard.set(isAnalyticsEnabled, forKey: "analytics_enabled")
    }
}

#Preview {
    SocialMainTabView()
}