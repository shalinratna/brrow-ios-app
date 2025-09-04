//
//  AdvancedSearchViewModel.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  View model for advanced search functionality
//

import Foundation
import Combine
import Speech
import AVFoundation

class AdvancedSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var filters = SearchFilters()
    @Published var suggestions: [String] = []
    @Published var listings: [Listing] = []
    @Published var garageSales: [GarageSale] = []
    @Published var users: [User] = []
    @Published var allResults: [SearchResult] = []
    @Published var featuredResults: [Listing] = []
    @Published var isSearching = false
    @Published var isListening = false
    @Published var showSearchHistory = false
    @Published var searchHistory: [String] = []
    @Published var activeFilters: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var totalResults: Int {
        listings.count + garageSales.count + users.count
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if !filters.categories.isEmpty { count += 1 }
        if filters.priceRange != 0...1000 { count += 1 }
        if filters.distance != 10.0 { count += 1 }
        if filters.condition != nil { count += 1 }
        if filters.availability != .all { count += 1 }
        if filters.verifiedSellersOnly { count += 1 }
        if filters.freeItemsOnly { count += 1 }
        if filters.deliveryAvailable { count += 1 }
        if filters.instantBooking { count += 1 }
        if !filters.includeGarageSales { count += 1 }
        if filters.sortBy != .relevance { count += 1 }
        return count
    }
    
    init() {
        loadSearchHistory()
        setupVoiceRecognition()
    }
    
    // MARK: - Search Methods
    
    func performSearch(_ query: String) {
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        isSearching = true
        searchQuery = query
        saveToHistory(query)
        updateActiveFilters()
        
        Task {
            do {
                // Perform parallel searches
                async let listingsResult = searchListings(query)
                async let garageSalesResult = searchGarageSales(query)
                async let usersResult = searchUsers(query)
                
                let (fetchedListings, fetchedGarageSales, fetchedUsers) = await (listingsResult, garageSalesResult, usersResult)
                
                await MainActor.run {
                    self.listings = self.applyFiltersToListings(fetchedListings)
                    self.garageSales = filters.includeGarageSales ? fetchedGarageSales : []
                    self.users = fetchedUsers
                    self.updateAllResults()
                    self.updateFeaturedResults()
                    self.sortResults()
                    self.isSearching = false
                    
                    // Track search achievement
                    if totalResults > 0 {
                        // Track search achievement when API is updated
                        // AchievementManager.shared.trackAction(.search)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                }
            }
        }
    }
    
    func updateSuggestions(for query: String) {
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        // Simulate API call for suggestions
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds debounce
            
            await MainActor.run {
                self.suggestions = self.generateSuggestions(for: query)
            }
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        listings = []
        garageSales = []
        users = []
        allResults = []
        featuredResults = []
        suggestions = []
        isSearching = false
    }
    
    func refreshSearch() async {
        if !searchQuery.isEmpty {
            performSearch(searchQuery)
        }
    }
    
    // MARK: - Filter Methods
    
    func applyFilters() {
        performSearch(searchQuery)
    }
    
    func removeFilter(_ filter: String) {
        // Remove specific filter based on the filter string
        if filter.contains("Category:") {
            let category = filter.replacingOccurrences(of: "Category: ", with: "")
            filters.categories.remove(category)
        } else if filter == "Free Items" {
            filters.freeItemsOnly = false
        } else if filter.contains("Within") {
            filters.distance = 10.0
        } else if filter.contains("Price:") {
            filters.priceRange = 0...1000
        } else if filter == "Verified Sellers" {
            filters.verifiedSellersOnly = false
        } else if filter == "Delivery Available" {
            filters.deliveryAvailable = false
        } else if filter == "Instant Booking" {
            filters.instantBooking = false
        }
        
        updateActiveFilters()
        applyFilters()
    }
    
    func clearAllFilters() {
        filters = SearchFilters()
        updateActiveFilters()
        applyFilters()
    }
    
    private func updateActiveFilters() {
        activeFilters.removeAll()
        
        // Categories
        filters.categories.forEach { category in
            activeFilters.append("Category: \(category)")
        }
        
        // Price
        if filters.freeItemsOnly {
            activeFilters.append("Free Items")
        } else if filters.priceRange != 0...1000 {
            activeFilters.append("Price: $\(Int(filters.priceRange.lowerBound))-$\(Int(filters.priceRange.upperBound))")
        }
        
        // Distance
        if filters.distance != 10.0 {
            activeFilters.append("Within \(Int(filters.distance)) miles")
        }
        
        // Condition
        if let condition = filters.condition {
            activeFilters.append("Condition: \(condition.displayName)")
        }
        
        // Availability
        if filters.availability != .all {
            activeFilters.append("Availability: \(filters.availability.displayName)")
        }
        
        // Additional filters
        if filters.verifiedSellersOnly {
            activeFilters.append("Verified Sellers")
        }
        
        if filters.deliveryAvailable {
            activeFilters.append("Delivery Available")
        }
        
        if filters.instantBooking {
            activeFilters.append("Instant Booking")
        }
    }
    
    // MARK: - Voice Search
    
    func startVoiceSearch() {
        if isListening {
            stopVoiceSearch()
        } else {
            requestSpeechAuthorization { [weak self] authorized in
                if authorized {
                    self?.startListening()
                }
            }
        }
    }
    
    private func setupVoiceRecognition() {
        // Setup handled in startListening
    }
    
    private func requestSpeechAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    private func startListening() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }
        
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            let inputNode = audioEngine.inputNode
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    self?.searchQuery = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.performSearch(result.bestTranscription.formattedString)
                        self?.stopVoiceSearch()
                    }
                }
                
                if error != nil {
                    self?.stopVoiceSearch()
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
        } catch {
            print("Failed to start voice recognition: \(error)")
        }
    }
    
    private func stopVoiceSearch() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
    
    // MARK: - Private Methods
    
    private func searchListings(_ query: String) async -> [Listing] {
        // Simulate API call
        do {
            let results = try await APIClient.shared.searchListings(query: query)
            return results
        } catch {
            return []
        }
    }
    
    private func searchGarageSales(_ query: String) async -> [GarageSale] {
        // Simulate API call
        return [] // Implement when API is ready
    }
    
    private func searchUsers(_ query: String) async -> [User] {
        // Simulate API call
        return [] // Implement when API is ready
    }
    
    private func applyFiltersToListings(_ listings: [Listing]) -> [Listing] {
        var filtered = listings
        
        // Category filter
        if !filters.categories.isEmpty {
            filtered = filtered.filter { filters.categories.contains($0.category) }
        }
        
        // Price filter
        if filters.freeItemsOnly {
            filtered = filtered.filter { $0.price == 0 }
        } else {
            filtered = filtered.filter { filters.priceRange.contains($0.price) }
        }
        
        // Distance filter (would require location data)
        // Implement when location services are integrated
        
        // Condition filter
        if let condition = filters.condition, condition != .any {
            // Implement when condition field is added to Listing model
        }
        
        // Availability filter
        switch filters.availability {
        case .available:
            filtered = filtered.filter { $0.isAvailable }
        case .comingSoon:
            // Implement when coming soon field is added
            break
        case .all:
            break
        }
        
        // Additional filters
        if filters.verifiedSellersOnly {
            // Implement when seller verification is added
        }
        
        if filters.deliveryAvailable {
            // Implement when delivery option is added
        }
        
        if filters.instantBooking {
            // Implement when instant booking is added
        }
        
        return filtered
    }
    
    private func updateAllResults() {
        allResults.removeAll()
        
        // Mix listings and garage sales
        listings.forEach { listing in
            allResults.append(SearchResult(
                title: listing.title,
                type: .listing,
                imageUrl: listing.images.first,
                price: listing.price,
                location: listing.location.city,
                rating: nil
            ))
        }
        
        garageSales.forEach { sale in
            allResults.append(SearchResult(
                title: sale.title,
                type: .garageSale,
                imageUrl: sale.images.first,
                price: nil,
                location: sale.location,
                rating: nil
            ))
        }
        
        users.forEach { user in
            allResults.append(SearchResult(
                title: user.username,
                type: .user,
                imageUrl: user.profilePicture,
                price: nil,
                location: nil,
                rating: Double(((user.listerRating ?? 0) + (user.renteeRating ?? 0)) / 2)
            ))
        }
    }
    
    private func updateFeaturedResults() {
        // Get promoted/featured listings
        featuredResults = listings.filter { $0.isPromoted }.prefix(5).map { $0 }
    }
    
    private func sortResults() {
        switch filters.sortBy {
        case .relevance:
            // Default relevance sorting
            break
        case .priceLowest:
            listings.sort { $0.price < $1.price }
        case .priceHighest:
            listings.sort { $0.price > $1.price }
        case .newest:
            listings.sort { $0.createdAt > $1.createdAt }
        case .nearest:
            // Implement when location sorting is available
            break
        case .highestRated:
            // Implement when rating is available on listings
            break
        case .mostReviews:
            // Implement when review count is available
            break
        }
    }
    
    private func generateSuggestions(for query: String) -> [String] {
        // Generate smart suggestions based on query
        var suggestions: [String] = []
        
        // Add category suggestions
        ListingCategory.allCases.forEach { category in
            if category.displayName.lowercased().contains(query.lowercased()) {
                suggestions.append(category.displayName)
            }
        }
        
        // Add common search terms
        let commonTerms = ["tools", "furniture", "electronics", "outdoor", "kitchen", "sports", "games", "baby items"]
        commonTerms.forEach { term in
            if term.contains(query.lowercased()) && !suggestions.contains(term) {
                suggestions.append(term)
            }
        }
        
        // Add from search history
        searchHistory.forEach { historyItem in
            if historyItem.lowercased().contains(query.lowercased()) && !suggestions.contains(historyItem) {
                suggestions.append(historyItem)
            }
        }
        
        return Array(suggestions.prefix(5))
    }
    
    // MARK: - Search History
    
    private func loadSearchHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: "SearchHistory") {
            searchHistory = saved
        }
    }
    
    private func saveToHistory(_ query: String) {
        // Remove if already exists
        searchHistory.removeAll { $0 == query }
        
        // Add to beginning
        searchHistory.insert(query, at: 0)
        
        // Keep only last 20 searches
        searchHistory = Array(searchHistory.prefix(20))
        
        // Save to UserDefaults
        UserDefaults.standard.set(searchHistory, forKey: "SearchHistory")
    }
}