//
//  MainTabView.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var predictiveLoader = PredictiveLoadingManager.shared
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedTab = 0
    @State private var previousTab = 0

    // Persistent view models to prevent reloading
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var browseViewModel = HomeViewModel() // Reuse for Browse
    @StateObject private var borrowViewModel = OffersViewModel() // Reuse for Borrow
    @StateObject private var chatViewModel = ChatListViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Ultra Modern Design
            UltraModernHomeView()
                .environmentObject(homeViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .foregroundColor(selectedTab == 0 ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    Text("Home")
                }
                .tag(0)
            
            // Browse Tab (Ultra Modern marketplace with vibrant colors)
            UltraModernMarketplaceView3()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "square.grid.2x2.fill" : "square.grid.2x2")
                        .foregroundColor(selectedTab == 1 ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    Text("Browse")
                }
                .tag(1)
            
            // Borrow Tab (offers, seeks, transactions)
            BorrowView()
                .environmentObject(borrowViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "arrow.2.squarepath" : "arrow.2.squarepath")
                        .foregroundColor(selectedTab == 2 ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    Text("Borrow")
                }
                .tag(2)
            
            // Chats Tab
            ChatListView()
                .environmentObject(chatViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "message.fill" : "message")
                        .foregroundColor(selectedTab == 3 ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    Text("Chats")
                }
                .tag(3)
            
            // Profile Tab
            SimpleProfessionalProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        .foregroundColor(selectedTab == 4 ? Theme.Colors.primary : Theme.Colors.secondaryText)
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(Theme.Colors.primary)
        .onChange(of: selectedTab) { newTab in
            // Store current tab as previous before processing the change
            let oldTab = previousTab
            previousTab = selectedTab

            // Smooth transition with haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            // Preload content for adjacent tabs
            preloadAdjacentTabs(currentTab: newTab)

            // 🚀 PREDICTIVE LOADING: Predict next navigation based on current tab
            Task {
                await predictiveLoader.predictNextNavigation(
                    from: getTabName(newTab),
                    userBehavior: ["previousTab": oldTab, "currentTab": newTab]
                )
            }

            // Track tab switching analytics
            trackTabSwitch(from: oldTab, to: newTab)
        }
        // Universal listing detail is handled at the app root level
        .onReceive(NotificationCenter.default.publisher(for: .navigateToMessages)) { _ in
            print("🔔 MainTabView: Received navigateToMessages, switching to Chats tab")
            selectedTab = 3  // Chats tab
        }
        .onAppear {
            setupTabAppearance()
            preloadInitialContent()
            trackScreenView("main_tab_view")

            // 🚀 PREDICTIVE LOADING: Start background sync when app launches
            Task {
                await predictiveLoader.startBackgroundSync()
            }
        }
    }
    
    private func setupTabAppearance() {
        // Configure tab bar appearance for brand guidelines
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.Colors.surface)
        appearance.shadowColor = UIColor(Theme.Colors.border)
        
        // Active tab color (emerald)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.Colors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.primary)
        ]
        
        // Inactive tab color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.Colors.secondaryText)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.secondaryText)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func preloadInitialContent() {
        // Preload content for first 3 tabs to eliminate loading delays
        Task {
            await homeViewModel.preloadContent()
            await browseViewModel.preloadContent()
            await borrowViewModel.preloadContent()
        }
    }
    
    private func preloadAdjacentTabs(currentTab: Int) {
        // Preload content for tabs adjacent to current tab
        let adjacentTabs = [max(0, currentTab - 1), min(4, currentTab + 1)]
        
        for tabIndex in adjacentTabs {
            Task {
                switch tabIndex {
                case 0: await homeViewModel.preloadContent()
                case 1: await browseViewModel.preloadContent()
                case 2: await borrowViewModel.preloadContent()
                case 3: await chatViewModel.preloadContent()
                case 4: await profileViewModel.preloadContent()
                default: break
                }
            }
        }
    }
    
    private func trackTabSwitch(from: Int, to: Int) {
        let tabNames = ["Home", "Browse", "Borrow", "Chats", "Profile"]
        let fromName = from < tabNames.count ? tabNames[from] : "Unknown"
        let toName = to < tabNames.count ? tabNames[to] : "Unknown"
        
        // TODO: Send analytics event
        print("Tab switched from \(fromName) to \(toName)")
    }
    
    private func trackScreenView(_ screenName: String) {
        // TODO: Track screen view analytics when needed
    }

    private func getTabName(_ tabIndex: Int) -> String {
        let tabNames = ["home", "marketplace", "borrow", "chats", "profile"]
        return tabIndex < tabNames.count ? tabNames[tabIndex] : "unknown"
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
