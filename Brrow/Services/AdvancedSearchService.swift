//
//  AdvancedSearchService.swift
//  Brrow
//
//  Advanced search service with filtering, location search, and analytics
//

import Foundation
import CoreLocation
import Combine

@MainActor
class AdvancedSearchService: NSObject, ObservableObject {
    static let shared = AdvancedSearchService()

    @Published var searchResults: [SearchResult] = []
    @Published var facets: SearchFacets?
    @Published var suggestions: [SearchSuggestion] = []
    @Published var searchHistory: [SearchHistory] = []
    @Published var savedSearches: [SavedSearch] = []
    @Published var popularSearches: [PopularSearch] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalResultCount = 0
    @Published var currentPage = 1
    @Published var hasMoreResults = false

    private let apiClient = APIClient.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var currentSearchRequest: SearchRequest?
    private let configuration = SearchConfiguration.default

    // Debounced search for real-time suggestions
    private var searchDebounceTimer: Timer?
    private let searchDebounceDelay: TimeInterval = 0.3

    override init() {
        super.init()
        setupLocationManager()
        loadSearchHistory()
        loadSavedSearches()
        loadPopularSearches()
    }

    // MARK: - Main Search

    func search(_ request: SearchRequest) async throws {
        isLoading = true
        errorMessage = nil
        currentSearchRequest = request

        do {
            let response = try await apiClient.performRequest(
                endpoint: "api/search",
                method: "POST",
                body: try JSONEncoder().encode(request),
                responseType: SearchResponse.self
            )

            guard response.success, let data = response.data else {
                throw BrrowAPIError.serverError(response.message ?? "Search failed")
            }

            searchResults = data.results
            facets = data.facets
            suggestions = data.suggestions ?? []
            totalResultCount = data.totalCount
            currentPage = data.pagination.page
            hasMoreResults = data.totalCount > (data.pagination.page * data.pagination.limit)

            // Save to search history
            if let query = request.query, !query.isEmpty {
                addToSearchHistory(query: query, resultCount: data.totalCount)
            }

        } catch {
            errorMessage = error.localizedDescription
            // Load mock data for demo
            loadMockSearchResults(request)
        }

        isLoading = false
    }

    func loadMoreResults() async throws {
        guard hasMoreResults, !isLoading, let currentRequest = currentSearchRequest else { return }

        let nextPageRequest = SearchRequest(
            query: currentRequest.query,
            location: currentRequest.location,
            filters: currentRequest.filters,
            sort: currentRequest.sort,
            pagination: SearchPagination(page: currentPage + 1, limit: currentRequest.pagination.limit)
        )

        isLoading = true

        do {
            let response = try await apiClient.performRequest(
                endpoint: "api/search",
                method: "POST",
                body: try JSONEncoder().encode(nextPageRequest),
                responseType: SearchResponse.self
            )

            guard response.success, let data = response.data else {
                throw BrrowAPIError.serverError(response.message ?? "Failed to load more results")
            }

            searchResults.append(contentsOf: data.results)
            currentPage = data.pagination.page
            hasMoreResults = data.totalCount > (data.pagination.page * data.pagination.limit)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Search Suggestions

    func searchSuggestions(for query: String) async throws -> [SearchSuggestion] {
        guard !query.isEmpty else { return [] }

        let response = try await apiClient.performRequest(
            endpoint: "api/search/suggestions?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            method: "GET",
            responseType: APIResponse<[SearchSuggestion]>.self
        )

        guard response.success, let suggestions = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to get suggestions")
        }

        return suggestions
    }

    func debouncedSearchSuggestions(for query: String, completion: @escaping ([SearchSuggestion]) -> Void) {
        searchDebounceTimer?.invalidate()

        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: searchDebounceDelay, repeats: false) { [weak self] _ in
            Task {
                do {
                    let suggestions = try await self?.searchSuggestions(for: query) ?? []
                    await MainActor.run {
                        completion(suggestions)
                    }
                } catch {
                    await MainActor.run {
                        completion([])
                    }
                }
            }
        }
    }

    // MARK: - Location Search

    func searchLocations(_ query: String) async throws -> [LocationResult] {
        let request = LocationSearchRequest(query: query)

        let response = try await apiClient.performRequest(
            endpoint: "api/search/locations",
            method: "POST",
            body: try JSONEncoder().encode(request),
            responseType: LocationSearchResponse.self
        )

        guard response.success, let locations = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Location search failed")
        }

        return locations
    }

    func getCurrentLocation() -> CLLocationCoordinate2D? {
        guard let location = locationManager.location else { return nil }
        return location.coordinate
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Saved Searches

    func saveSearch(name: String, request: SearchRequest, enableNotifications: Bool = false) async throws {
        let saveRequest = CreateSavedSearchRequest(
            name: name,
            searchRequest: request,
            isNotificationEnabled: enableNotifications
        )

        let response = try await apiClient.performRequest(
            endpoint: "api/search/saved",
            method: "POST",
            body: try JSONEncoder().encode(saveRequest),
            responseType: APIResponse<SavedSearch>.self
        )

        guard response.success, let savedSearch = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to save search")
        }

        savedSearches.insert(savedSearch, at: 0)
    }

    func deleteSavedSearch(_ searchId: String) async throws {
        let response = try await apiClient.performRequest(
            endpoint: "api/search/saved/\(searchId)",
            method: "DELETE",
            responseType: APIResponse<EmptyResponse>.self
        )

        guard response.success else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to delete saved search")
        }

        savedSearches.removeAll { $0.id == searchId }
    }

    func executeSavedSearch(_ savedSearch: SavedSearch) async throws {
        try await search(savedSearch.searchRequest)
    }

    // MARK: - Search History

    private func addToSearchHistory(query: String, resultCount: Int) {
        let historyItem = SearchHistory(
            query: query,
            timestamp: Date(),
            resultCount: resultCount,
            location: nil
        )

        // Remove duplicate queries
        searchHistory.removeAll { $0.query.lowercased() == query.lowercased() }

        // Add to beginning
        searchHistory.insert(historyItem, at: 0)

        // Limit to 50 items
        if searchHistory.count > 50 {
            searchHistory.removeLast()
        }

        saveSearchHistory()
    }

    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }

    func removeFromSearchHistory(_ query: String) {
        searchHistory.removeAll { $0.query == query }
        saveSearchHistory()
    }

    // MARK: - Popular Searches

    func loadPopularSearches() {
        // Mock popular searches
        popularSearches = [
            PopularSearch(query: "camera", count: 1250, category: "Electronics", trend: .rising),
            PopularSearch(query: "bike", count: 980, category: "Sports", trend: .stable),
            PopularSearch(query: "tools", count: 750, category: "Tools", trend: .rising),
            PopularSearch(query: "furniture", count: 650, category: "Home", trend: .falling),
            PopularSearch(query: "laptop", count: 550, category: "Electronics", trend: .stable)
        ]
    }

    // MARK: - Faceted Search

    func applyFacetFilter(_ facet: SearchFacets.FacetCount, to filters: inout AdvancedSearchFilters) {
        // Implementation depends on facet type
        // This is a simplified version
        if !filters.categories.contains(facet.value) {
            filters.categories.append(facet.value)
        }
    }

    func removeFacetFilter(_ facet: SearchFacets.FacetCount, from filters: inout AdvancedSearchFilters) {
        filters.categories.removeAll { $0 == facet.value }
    }

    // MARK: - Search Analytics

    func getSearchAnalytics(period: String = "30d") async throws -> SearchAnalytics {
        let response = try await apiClient.performRequest(
            endpoint: "api/search/analytics?period=\(period)",
            method: "GET",
            responseType: APIResponse<SearchAnalytics>.self
        )

        guard response.success, let analytics = response.data else {
            throw BrrowAPIError.serverError(response.message ?? "Failed to get analytics")
        }

        return analytics
    }

    // MARK: - Helper Methods

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "search_history"),
           let history = try? JSONDecoder().decode([SearchHistory].self, from: data) {
            searchHistory = history
        }
    }

    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "search_history")
        }
    }

    private func loadSavedSearches() {
        // Load from API or mock data
        savedSearches = []
    }

    // MARK: - Mock Data

    private func loadMockSearchResults(_ request: SearchRequest) {
        let mockResults = generateMockSearchResults(for: request.query ?? "")
        searchResults = mockResults
        totalResultCount = mockResults.count
        hasMoreResults = false
        facets = generateMockFacets()
    }

    private func generateMockSearchResults(for query: String) -> [SearchResult] {
        let mockListings = [
            Listing.example,
            Listing.example,
            Listing.example
        ]

        return mockListings.enumerated().map { index, listing in
            SearchResult(
                id: listing.id,
                score: 0.95 - (Double(index) * 0.1),
                listing: listing,
                distance: Double.random(in: 0.5...15.0),
                matchedTerms: [query],
                highlights: SearchResult.SearchHighlights(
                    title: listing.title,
                    description: listing.description,
                    tags: nil
                )
            )
        }
    }

    private func generateMockFacets() -> SearchFacets {
        return SearchFacets(
            categories: [
                SearchFacets.FacetCount(value: "Electronics", count: 45, isSelected: false),
                SearchFacets.FacetCount(value: "Sports", count: 32, isSelected: false),
                SearchFacets.FacetCount(value: "Tools", count: 28, isSelected: false),
                SearchFacets.FacetCount(value: "Home", count: 21, isSelected: false)
            ],
            priceRanges: [
                SearchFacets.FacetCount(value: "$0-$25", count: 25, isSelected: false),
                SearchFacets.FacetCount(value: "$25-$50", count: 35, isSelected: false),
                SearchFacets.FacetCount(value: "$50-$100", count: 28, isSelected: false),
                SearchFacets.FacetCount(value: "$100+", count: 12, isSelected: false)
            ],
            locations: [
                SearchFacets.FacetCount(value: "San Francisco", count: 89, isSelected: false),
                SearchFacets.FacetCount(value: "Oakland", count: 34, isSelected: false),
                SearchFacets.FacetCount(value: "Berkeley", count: 23, isSelected: false)
            ],
            conditions: [
                SearchFacets.FacetCount(value: "Like New", count: 42, isSelected: false),
                SearchFacets.FacetCount(value: "Excellent", count: 38, isSelected: false),
                SearchFacets.FacetCount(value: "Good", count: 24, isSelected: false)
            ],
            ratings: [
                SearchFacets.FacetCount(value: "4.5+", count: 67, isSelected: false),
                SearchFacets.FacetCount(value: "4.0+", count: 89, isSelected: false),
                SearchFacets.FacetCount(value: "3.5+", count: 98, isSelected: false)
            ],
            features: [
                SearchFacets.FacetCount(value: "Instant Book", count: 45, isSelected: false),
                SearchFacets.FacetCount(value: "Delivery Available", count: 32, isSelected: false),
                SearchFacets.FacetCount(value: "Verified Owner", count: 67, isSelected: false)
            ]
        )
    }
}

// MARK: - CLLocationManagerDelegate

extension AdvancedSearchService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates if needed
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle authorization changes
    }
}