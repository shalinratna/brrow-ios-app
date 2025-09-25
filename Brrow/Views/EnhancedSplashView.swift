//
//  EnhancedSplashView.swift
//  Brrow
//
//  Advanced splash screen with data preloading and caching
//

import SwiftUI
import Combine

struct EnhancedSplashView: View {
    @StateObject private var preloader = DataPreloader()
    @State private var animationPhase = 0
    @State private var showContent = false
    @Binding var isComplete: Bool
    
    init(isComplete: Binding<Bool> = .constant(false)) {
        self._isComplete = isComplete
    }
    
    var body: some View {
        ZStack {
            // Keep the existing green splash screen from LaunchScreen.storyboard
            Theme.Colors.primary
                .ignoresSafeArea()
        }
        .onAppear {
            // Immediately start preloading and complete
            preloader.preloadData()
            
            // Complete the splash screen immediately to go to next view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isComplete = true
            }
        }
    }
    
    private func startAnimationSequence() {
        withAnimation {
            animationPhase = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                animationPhase = 2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                animationPhase = 3
            }
        }
    }
}

// MARK: - Data Preloader
class DataPreloader: ObservableObject {
    @Published var isLoading = true
    @Published var isComplete = false
    @Published var loadingMessage = "Initializing..."
    @Published var progress: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let cacheManager = CacheManager.shared
    
    func preloadData() {
        Task {
            await performPreloading()
        }
    }
    
    @MainActor
    private func performPreloading() async {
        // Step 1: Check authentication
        updateLoadingState("Checking authentication...", progress: 0.1)
        await checkAuthentication()
        
        // Step 2: Load user data
        updateLoadingState("Loading user data...", progress: 0.2)
        await loadUserData()
        
        // Step 3: Preload featured listings
        updateLoadingState("Loading featured items...", progress: 0.4)
        await preloadFeaturedListings()
        
        // Step 4: Preload marketplace data
        updateLoadingState("Preparing marketplace...", progress: 0.6)
        await preloadMarketplaceData()
        
        // Step 5: Load user preferences
        updateLoadingState("Loading preferences...", progress: 0.8)
        await loadUserPreferences()
        
        // Step 6: Initialize services
        updateLoadingState("Starting services...", progress: 0.9)
        await initializeServices()
        
        // Complete
        updateLoadingState("Ready!", progress: 1.0)
        
        // Small delay for smooth transition
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isLoading = false
        isComplete = true
    }
    
    private func updateLoadingState(_ message: String, progress: Double) {
        DispatchQueue.main.async {
            self.loadingMessage = message
            self.progress = progress
        }
    }
    
    private func checkAuthentication() async {
        // Verify token is still valid
        if AuthManager.shared.authToken != nil {
            // Token refresh is handled automatically by APIClient
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
    }
    
    private func loadUserData() async {
        guard AuthManager.shared.isAuthenticated else { return }
        
        // Try cache first
        if let cachedUser = cacheManager.load(User.self, forKey: "current_user") {
            await MainActor.run {
                AuthManager.shared.currentUser = cachedUser
            }
        } else {
            // Fetch from API if not cached
            // Simulate API call - in real app, call actual endpoint
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
            
            // Cache the user data
            if let user = AuthManager.shared.currentUser {
                cacheManager.save(user, forKey: "current_user", expiration: .days(1))
            }
        }
    }
    
    private func preloadFeaturedListings() async {
        // Check cache first
        let cacheKey = "featured_listings"
        if let cached = cacheManager.load([Listing].self, forKey: cacheKey) {
            // Use cached data
            print("Using cached featured listings: \(cached.count) items")
        } else {
            // Fetch from API
            do {
                // Create a task that can be cancelled
                let task = Task {
                    try await APIClient.shared.fetchFeaturedListings(limit: 10)
                }
                
                // Race between API call and timeout
                let response = try await withTimeout(seconds: 3) {
                    try await task.value
                }
                
                // Cache for 30 minutes
                let listings = response.allListings
                if !listings.isEmpty {
                    cacheManager.save(listings, forKey: cacheKey, expiration: .minutes(30))
                }
            } catch {
                print("Failed to preload featured listings: \(error)")
                // Don't block app startup
            }
        }
    }
    
    private func preloadMarketplaceData() async {
        // Preload categories
        let categoriesCacheKey = "marketplace_categories"
        if cacheManager.load([String].self, forKey: categoriesCacheKey) == nil {
            // Define default categories
            let categories = [
                "Electronics & Gadgets",
                "Home & Kitchen",
                "Tools & DIY",
                "Sports & Outdoors",
                "Party Supplies",
                "Musical Instruments"
            ]
            cacheManager.save(categories, forKey: categoriesCacheKey, expiration: .days(7))
        }
        
        // Simulate loading marketplace data
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
    }
    
    private func loadUserPreferences() async {
        // Load notification preferences, theme settings, etc.
        struct UserPreferences: Codable {
            let notificationsEnabled: Bool
            let locationEnabled: Bool
            let theme: String
        }
        
        let preferencesCacheKey = "user_preferences"
        if cacheManager.load(UserPreferences.self, forKey: preferencesCacheKey) == nil {
            // Set default preferences
            let defaultPreferences = UserPreferences(
                notificationsEnabled: true,
                locationEnabled: true,
                theme: "light"
            )
            cacheManager.save(defaultPreferences, forKey: preferencesCacheKey, expiration: .never)
        }
        
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    }
    
    private func initializeServices() async {
        // Initialize push notifications
        PushNotificationService.shared.configure()
        
        // Start location services if needed
        // LocationManager.shared.requestPermission()
        
        // Initialize analytics
        // AnalyticsService.shared.initialize()
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
    }
}

// MARK: - Progress Indicator
struct SplashProgressView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Theme.Colors.secondaryBackground)
                    .frame(height: 4)
                
                // Progress
                Capsule()
                    .fill(Theme.Colors.primary)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.spring(response: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Preview
struct EnhancedSplashView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedSplashView(isComplete: .constant(false))
    }
}