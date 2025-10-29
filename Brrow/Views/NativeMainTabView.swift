//
//  NativeMainTabView.swift
//  Brrow
//
//  Production-Ready Native iOS Tab Bar
//

import SwiftUI
import Combine

struct NativeMainTabView: View {
    @StateObject private var discoverViewModel = DiscoverViewModel()
    @StateObject private var chatViewModel = ChatListViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var earningsViewModel = EarningsViewModel()
    @StateObject private var tabSelectionManager = TabSelectionManager.shared
    @StateObject private var achievementNotificationManager = AchievementNotificationManager.shared
    @StateObject private var listingNavManager = ListingNavigationManager.shared
    // IMPORTANT: HomeViewModel for background marketplace preloading
    @StateObject private var homeViewModel = HomeViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    @State private var showingPostSheet = false
    @State private var showingGuestAlert = false
    
    init() {
        // Configure native tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.3)
        appearance.shadowImage = UIImage()
        
        // Configure item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.Colors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(Theme.Colors.primary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $tabSelectionManager.selectedTab) {
            // Home Tab - Professional Design (Hidden for guests)
            if !authManager.isGuestUser {
                NavigationView {
                    ProfessionalHomeView()
                        .environmentObject(discoverViewModel)
                }
                .tabItem {
                    Label(LocalizationHelper.localizedString("home"), systemImage: "house.fill")
                }
                .tag(0)
            }
            
            // Marketplace Tab - Professional Design
            NavigationView {
                ProfessionalMarketplaceView()
            }
            .tabItem {
                Label(LocalizationHelper.localizedString("marketplace"), systemImage: "bag.fill")
            }
            .tag(1)
            
            // Post Tab - Opens sheet instead of navigating (Plus icon in middle)
            Color.clear
                .tabItem {
                    Label(LocalizationHelper.localizedString("post"), systemImage: "plus.app.fill")
                }
                .tag(2)
            
            // Messages Tab with badge
            NavigationView {
                SocialChatView()
                    .environmentObject(chatViewModel)
            }
            .tabItem {
                Label(LocalizationHelper.localizedString("messages"), systemImage: "message.fill")
            }
            .badge(chatViewModel.unreadCount > 0 ? "\(chatViewModel.unreadCount)" : nil)
            .tag(3)
            
            // Profile Tab - Professional Design
            NavigationView {
                SimpleProfessionalProfileView()
                    .environmentObject(profileViewModel)
                    .environmentObject(authManager)
            }
            .tabItem {
                Label(LocalizationHelper.localizedString("profile"), systemImage: "person.fill")
            }
            .tag(4)
            }
            .onChange(of: tabSelectionManager.selectedTab) { newValue in
            // Check guest restrictions - guests can only use marketplace
            if authManager.isGuestUser {
                // For guests, any tab other than marketplace (1) shows alert
                if newValue != 1 {
                    showGuestAlert()
                    // Always reset to marketplace for guests
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tabSelectionManager.selectedTab = 1
                    }
                }
            } else {
                // Regular user - only handle post tab
                if newValue == 2 {
                    showingPostSheet = true
                    // Reset to previous tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        tabSelectionManager.selectedTab = 0
                    }
                }
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
            .sheet(isPresented: $showingPostSheet) {
                ModernPostCreationView(onListingCreated: { listingId in
                    print("🎯 NativeMainTabView: Received listing creation callback with ID: \(listingId)")

                    // Navigate to the marketplace tab
                    tabSelectionManager.selectedTab = 1 // Marketplace tab

                    // Trigger marketplace refresh
                    NotificationCenter.default.post(name: Notification.Name("RefreshMarketplace"), object: nil)

                    // Show the listing detail using the navigation manager
                    // Increased delay to ensure marketplace tab loads completely
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        print("🚀 NativeMainTabView: Attempting to show listing with ID: \(listingId)")
                        listingNavManager.showListingById(listingId)
                    }
                })
            }
            // .quickActionsOverlay() // Temporarily disabled - will be restored after fixing build issues
            
            // Achievement Notifications Overlay
            if achievementNotificationManager.showNotification,
               let achievement = achievementNotificationManager.currentNotification {
                AchievementNotificationView(
                    achievement: achievement,
                    isPresented: $achievementNotificationManager.showNotification
                )
                .onDisappear {
                    achievementNotificationManager.dismissCurrentNotification()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToChat)) { notification in
            print("🔔 Received navigateToChat notification")
            // Handle navigation to chat
            if let userInfo = notification.userInfo,
               let chatId = userInfo["chatId"] as? String {
                print("🔔 Switching to chat tab with chatId: \(chatId)")

                // Close any presented sheets first
                listingNavManager.showingListingDetail = false

                // Small delay to allow sheet dismissal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Switch to messages tab
                    tabSelectionManager.selectedTab = 3

                    // Pass the chat ID to the chat view model
                    if let listing = userInfo["listing"] as? Listing {
                        print("🔔 Navigating to chat with listing: \(listing.title)")
                        chatViewModel.navigateToChat(chatId: chatId, listing: listing)
                    } else {
                        print("🔔 Navigating to chat without listing")
                        chatViewModel.navigateToChat(chatId: chatId, listing: nil)
                    }
                }
            } else {
                print("❌ Invalid notification data for navigateToChat")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToMessagesTab)) { _ in
            print("🔔 [NativeMainTabView] Received switchToMessagesTab notification")
            print("🔔 [NativeMainTabView] Current tab: \(tabSelectionManager.selectedTab)")
            print("🔀 [NativeMainTabView] Switching to Messages tab (3)...")
            tabSelectionManager.selectedTab = 3
            print("✅ [NativeMainTabView] Tab switched to: \(tabSelectionManager.selectedTab)")
        }
        .sheet(isPresented: $listingNavManager.showingListingDetail, onDismiss: {
            print("🔴 Sheet dismissed")
            listingNavManager.clearListing()
        }) {
            if let listing = listingNavManager.selectedListing {
                ProfessionalListingDetailView(listing: listing)
            }
        }
        .alert("Sign In Required", isPresented: $showingGuestAlert) {
            Button("Sign In") {
                // Log out guest and return to login
                authManager.logout()
            }
            Button("Continue Browsing", role: .cancel) {}
        } message: {
            Text("Guest users can only browse the marketplace. Sign in to access all features including posting items, messaging, and your profile.")
        }
        .toastOverlay()
        // Universal listing detail is handled at the app root level
        // NOTE: Data preloading is now handled by AppDataPreloader in BrrowApp.swift
        // All tabs load instantly thanks to comprehensive preloading on app launch
    }
    
    private func showGuestAlert() {
        showingGuestAlert = true
    }
}

#Preview {
    NativeMainTabView()
        .environmentObject(AuthManager.shared)
}