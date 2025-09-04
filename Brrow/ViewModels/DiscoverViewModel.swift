//
//  DiscoverViewModel.swift
//  Brrow
//
//  Advanced Social Discovery with AI Integration
//

import Foundation
import CoreLocation
import Combine

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var nearbyListings: [Listing] = []
    @Published var trendingListings: [Listing] = []
    @Published var stories: [BrrowStory] = []
    @Published var activeChallenges: [CommunityChallenge] = []
    @Published var currentLocation = ""
    // karmaCredits removed per user request
    @Published var unreadNotifications = 0
    @Published var isLoading = false
    
    // Filter properties
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 500
    @Published var maxDistance: Double = 25
    @Published var listingType: ListingType? = nil
    @Published var sortBy: SortOption = .nearest
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let locationService = LocationService.shared
    private let aiService = BrrowAIService.shared
    
    init() {
        setupLocationTracking()
        // Don't load content automatically - let views trigger loading when needed
        // This prevents unnecessary API calls for guests
    }
    
    // MARK: - API Methods
    
    func loadDiscoverContent() {
        // Only load content for non-guest users
        guard !AuthManager.shared.isGuestUser else { return }
        loadInitialContent()
        loadUserInfo()
    }
    
    func loadListings() async {
        isLoading = true
        do {
            let response = try await apiClient.fetchListings()
            self.listings = response
            self.nearbyListings = response
        } catch {
            print("Failed to load listings: \(error)")
        }
        isLoading = false
    }
    
    func refreshListings() async {
        await loadListings()
    }
    
    func searchListings(query: String) async {
        isLoading = true
        do {
            let response = try await apiClient.fetchListings(search: query)
            self.listings = response
        } catch {
            print("Failed to search listings: \(error)")
        }
        isLoading = false
    }
    
    func filterByCategory(_ category: ListingCategory) async {
        if category == .all {
            self.listings = nearbyListings
        } else {
            self.listings = nearbyListings.filter { $0.category == category.rawValue }
        }
    }
    
    func applyFilters() async {
        var filtered = nearbyListings
        
        // Price filter
        filtered = filtered.filter { listing in
            let price = Double(listing.price) ?? 0
            return price >= minPrice && price <= maxPrice
        }
        
        // Type filter
        if let type = listingType {
            filtered = filtered.filter { $0.type == type.rawValue }
        }
        
        // Sort
        switch sortBy {
        case .nearest:
            // Already sorted by distance
            break
        case .newest:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .priceLowToHigh:
            filtered.sort { (Double($0.price) ?? 0) < (Double($1.price) ?? 0) }
        case .priceHighToLow:
            filtered.sort { (Double($0.price) ?? 0) > (Double($1.price) ?? 0) }
        }
        
        self.listings = filtered
    }
    
    func resetFilters() {
        minPrice = 0
        maxPrice = 500
        maxDistance = 25
        listingType = nil
        sortBy = .nearest
    }
    
    func loadNearbyContent() {
        Task {
            await loadNearbyListings()
            await loadStories()
        }
    }
    
    func refreshContent() async {
        isLoading = true
        
        async let nearbyTask = loadNearbyListings()
        async let trendingTask = loadTrendingListings()
        async let storiesTask = loadStories()
        async let challengesTask = loadActiveChallenges()
        
        await nearbyTask
        await trendingTask
        await storiesTask
        await challengesTask
        
        isLoading = false
    }
    
    func switchTab(to tab: String) {
        switch tab {
        case "nearby":
            Task { await loadNearbyListings() }
        case "trending":
            Task { await loadTrendingListings() }
        case "stories":
            Task { await loadStories() }
        case "challenges":
            Task { await loadActiveChallenges() }
        default:
            break
        }
    }
    
    func searchWithAI(query: String) {
        Task {
            do {
                let suggestions = try await aiService.getSmartSuggestions(for: query)
                // Handle AI suggestions
                print("AI Suggestions: \(suggestions)")
            } catch {
                print("AI search failed: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationTracking() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateLocationDisplay(location)
            }
            .store(in: &cancellables)
    }
    
    private func updateLocationDisplay(_ location: CLLocation) {
        // Reverse geocode to get city name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self?.currentLocation = "\(placemark.locality ?? ""), \(placemark.administrativeArea ?? "")"
                }
            }
        }
    }
    
    private func loadInitialContent() {
        Task {
            await loadNearbyListings()
            await loadStories()
            await loadActiveChallenges()
        }
    }
    
    private func loadNearbyListings() async {
        do {
            let listings = try await apiClient.fetchListings(
                location: locationService.currentLocation,
                radius: maxDistance
            )
            self.nearbyListings = listings
            self.listings = listings
        } catch {
            print("Failed to load nearby listings: \(error)")
        }
    }
    
    private func loadTrendingListings() async {
        do {
            let listings = try await apiClient.fetchTrendingListings()
            self.trendingListings = listings
        } catch {
            print("Failed to load trending listings: \(error)")
        }
    }
    
    private func loadStories() async {
        do {
            let stories = try await apiClient.fetchBrrowStories()
            self.stories = stories
        } catch {
            print("Failed to load stories: \(error)")
        }
    }
    
    private func loadActiveChallenges() async {
        do {
            let challenges = try await apiClient.fetchActiveChallenges()
            self.activeChallenges = challenges
        } catch {
            print("Failed to load challenges: \(error)")
        }
    }
    
    private func loadUserInfo() {
        Task {
            guard let currentUser = AuthManager.shared.currentUser,
                  !AuthManager.shared.isGuestUser else { return }
            
            do {
                // Fetch unread notifications count
                let notificationsCount = try await apiClient.fetchUnreadNotificationsCount()
                self.unreadNotifications = notificationsCount
            } catch {
                print("Failed to load user info: \(error)")
            }
        }
    }
}


// MARK: - AI Service

class BrrowAIService {
    static let shared = BrrowAIService()
    private let apiClient = APIClient.shared
    private init() {}
    
    func getSmartSuggestions(for query: String) async throws -> [String] {
        // Call AI suggestion endpoint
        return try await apiClient.fetchAISuggestions(query: query)
    }
    
    func getPersonalizedRecommendations() async throws -> [Listing] {
        // AI-powered recommendations based on user behavior
        return try await apiClient.fetchPersonalizedRecommendations()
    }
}

