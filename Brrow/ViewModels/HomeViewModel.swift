//
//  HomeViewModel.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasActiveFilters = false
    @Published var toastMessage: String?
    @Published var toastType: ToastModifier.ToastType = .error
    
    // Filter properties
    @Published var selectedCategory: String = "All"
    @Published var priceRange: ClosedRange<Double> = 0...1000
    @Published var maxDistance: Double = 10.0
    @Published var listingType: String = "All"
    
    private var cancellables = Set<AnyCancellable>()
    private var allListings: [Listing] = []
    private var searchQuery: String = ""
    
    init() {
        setupFilters()
    }
    
    // MARK: - Data Loading
    
    /// Main function to load listings from server
    /// This is called when user navigates to marketplace or pulls to refresh
    /// Steps:
    /// 1. Sets loading state to show spinner
    /// 2. Fetches listings from server endpoint
    /// 3. Updates local state with fetched data
    /// 4. Saves to persistent storage for offline access
    /// 5. Preloads images in background for smooth scrolling
    func loadListings() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch from: https://brrowapp.com/api/listings/fetch.php
                let fetchedListings = try await APIClient.shared.fetchListings()
                
                await MainActor.run {
                    // Update local state with fetched listings
                    self.allListings = fetchedListings
                    self.listings = fetchedListings
                    self.isLoading = false
                    
                    // Save to Core Data for offline access
                    PersistenceController.shared.saveListings(fetchedListings)
                    
                    // Track analytics event
                    self.trackListingsLoaded(count: fetchedListings.count)
                    
                    // IMPORTANT: Preload images for smooth marketplace browsing
                    // This downloads and caches the first image of each listing
                    ImageCacheManager.shared.preloadMarketplaceImages(listings: fetchedListings)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    
                    // Handle specific error types
                    if let apiError = error as? BrrowAPIError {
                        switch apiError {
                        case .networkError:
                            self.toastMessage = "No internet connection. Showing cached items."
                            self.toastType = .warning
                        case .serverError(let message):
                            self.errorMessage = message
                        case .unauthorized:
                            self.errorMessage = "Session expired. Please log in again."
                            // Trigger re-authentication
                            AuthManager.shared.logout()
                        default:
                            self.errorMessage = "Failed to load listings"
                        }
                    } else {
                        self.toastMessage = "Using cached data"
                        self.toastType = .info
                    }
                    
                    // Always try to load cached data on error
                    self.loadCachedListings()
                }
            }
        }
    }
    
    func refreshListings() {
        loadListings()
        updateWidgetData()
    }
    
    // MARK: - Widget Updates
    private func updateWidgetData() {
        // Update basic widget data
        let activeListingsCount = listings.filter { $0.status == "active" }.count
        let nearbyItemsCount = listings.count // Use all listings for now
        
        WidgetDataManager.shared.updateWidgetData(
            activeListings: activeListingsCount,
            nearbyItems: nearbyItemsCount,
            recentActivity: "Last updated: \(Date().formatted(date: .omitted, time: .shortened))"
        )
        
        // Update achievement data if available
        if let currentUser = AuthManager.shared.currentUser {
            // Example achievement data - replace with actual data from AchievementManager
            WidgetDataManager.shared.updateAchievementData(
                level: 1,
                progress: 0.65,
                points: 150,
                badges: ["star.fill", "trophy.fill", "rosette"]
            )
        }
    }
    
    // MARK: - Background Preloading (Call this when app launches!)
    
    /// Preloads marketplace content in background when app starts
    /// This ensures marketplace is populated BEFORE user taps on it
    /// 
    /// How it works:
    /// 1. Called when app launches (in BrrowApp.swift or MainTabView)
    /// 2. Checks if data already exists (to avoid redundant fetches)
    /// 3. Silently fetches listings without showing loading spinner
    /// 4. Caches images so they're ready when user opens marketplace
    /// 5. Falls back to cached data if network fails
    ///
    /// Result: When user taps marketplace tab, content appears instantly!
    func preloadContent() async {
        // Skip if we already have listings loaded
        if !allListings.isEmpty {
            return
        }
        
        // Fetch in background (no loading spinner shown to user)
        do {
            // Fetch from: https://brrowapp.com/api/listings/fetch.php
            let fetchedListings = try await APIClient.shared.fetchListings()
            
            await MainActor.run {
                // Silently update state
                self.allListings = fetchedListings
                self.listings = fetchedListings
                
                // Save for offline access
                PersistenceController.shared.saveListings(fetchedListings)
                
                // CRITICAL: Preload images so marketplace loads instantly
                // This caches first 20 listing images in background
                ImageCacheManager.shared.preloadMarketplaceImages(listings: fetchedListings)
                
                print("✅ Preloaded \(fetchedListings.count) listings with images")
            }
        } catch {
            // Network failed? Load from cache silently
            await MainActor.run {
                self.loadCachedListings()
                print("📦 Loaded cached listings (network unavailable)")
            }
        }
    }
    
    private func loadCachedListings() {
        let cachedListings = PersistenceController.shared.fetchListings()
        let listings = cachedListings.compactMap { entity -> Listing? in
            // Convert Core Data entity to Listing model
            guard let imagesData = entity.images,
                  let images = try? JSONDecoder().decode([String].self, from: imagesData) else {
                return nil
            }
            
            // Parse location string to Location object
            let location = Location(
                address: entity.location,
                city: "Unknown",
                state: "Unknown", 
                zipCode: "00000",
                country: "US",
                latitude: 0.0,
                longitude: 0.0
            )
            
            // Convert price string to double
            let priceValue = Double(entity.price) ?? 0.0
            
            // Determine price type based on entity data
            let priceType: PriceType = entity.isFree ? .free : .daily
            
            return Listing(
                id: entity.listingId,
                title: entity.title,
                description: entity.listingDescription,
                categoryId: "default-category",
                condition: "GOOD",
                price: priceValue,
                dailyRate: nil,
                isNegotiable: true,
                availabilityStatus: entity.status == "available" ? .available : .pending,
                location: location,
                userId: String(entity.userId),
                viewCount: Int(entity.views),
                favoriteCount: 0,
                isActive: entity.isActive,
                isPremium: false,
                premiumExpiresAt: nil,
                deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
                tags: [],
                metadata: nil,
                createdAt: ISO8601DateFormatter().string(from: entity.createdAt),
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                user: nil,
                category: CategoryModel(
                    id: "default-category",
                    name: entity.category,
                    description: nil,
                    iconUrl: nil,
                    parentId: nil,
                    isActive: true,
                    sortOrder: 0,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                ),
                images: images.map { url in
                    ListingImage(
                        id: UUID().uuidString,
                        url: url,
                        imageUrl: url,
                        thumbnailUrl: nil,
                        isPrimary: false,
                        displayOrder: 0,
                        thumbnail_url: nil,
                        is_primary: false
                    )
                },
                videos: nil,
                imageUrl: nil,
                _count: Listing.ListingCount(favorites: 0),
                isOwner: false,
                isFavorite: entity.isFavorite
            )
        }
        
        allListings = listings
        self.listings = listings
    }
    
    // MARK: - Search and Filters
    func searchListings(query: String) {
        searchQuery = query
        applyFilters()
        
        trackSearch(query: query)
    }
    
    func clearSearch() {
        searchQuery = ""
        applyFilters()
    }
    
    func clearFilters() {
        selectedCategory = "All"
        priceRange = 0...1000
        maxDistance = 10.0
        listingType = "All"
        hasActiveFilters = false
        applyFilters()
    }
    
    private func setupFilters() {
        // Observe filter changes
        Publishers.CombineLatest4(
            $selectedCategory,
            $priceRange,
            $maxDistance,
            $listingType
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.applyFilters()
            self?.updateFilterState()
        }
        .store(in: &cancellables)
    }
    
    private func applyFilters() {
        var filtered = allListings
        
        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { listing in
                listing.title.localizedCaseInsensitiveContains(searchQuery) ||
                listing.description.localizedCaseInsensitiveContains(searchQuery) ||
                (listing.category?.name ?? "").localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply category filter
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category?.name == selectedCategory }
        }
        
        // Apply price filter
        filtered = filtered.filter { listing in
            if listing.isFree {
                return priceRange.contains(0)
            } else {
                return priceRange.contains(listing.price)
            }
        }
        
        // Apply listing type filter (based on price type)
        if listingType != "All" {
            filtered = filtered.filter { listing in
                let typeString = listing.price == 0 ? "free" : "daily"
                return typeString == listingType.lowercased()
            }
        }
        
        // TODO: Apply distance filter (requires location services)
        
        listings = filtered
    }
    
    private func updateFilterState() {
        hasActiveFilters = selectedCategory != "All" ||
                          priceRange != 0...1000 ||
                          maxDistance != 10.0 ||
                          listingType != "All"
    }
    
    // MARK: - Analytics
    private func trackListingsLoaded(count: Int) {
        let event = AnalyticsEvent(
            eventName: "listings_loaded",
            eventType: "data",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "count": String(count),
                "source": "api",
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    private func trackSearch(query: String) {
        let event = AnalyticsEvent(
            eventName: "search_performed",
            eventType: "interaction",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "query": query,
                "results_count": String(listings.count),
                "platform": "ios"
            ]
        )
        
        APIClient.shared.trackAnalytics(event: event)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}