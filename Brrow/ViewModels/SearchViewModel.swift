//
//  SearchViewModel.swift
//  Brrow
//
//  Advanced Search & Discovery Logic
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [Listing] = []
    @Published var suggestions: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    
    init() {
        loadSuggestions()
    }
    
    func search(query: String, category: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await apiClient.searchListings(query: query, category: category)
                self.searchResults = results
                self.isLoading = false

                // Track search analytics
                AnalyticsService.shared.trackSearch(query: query, resultsCount: results.count)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func clearSearch() {
        searchResults = []
        errorMessage = nil
    }
    
    func loadAllItems() {
        Task {
            do {
                let results = try await apiClient.fetchListings()
                self.searchResults = results
            } catch {
                print("Failed to load all items: \(error)")
            }
        }
    }
    
    private func loadSuggestions() {
        Task {
            do {
                suggestions = try await apiClient.fetchSearchSuggestions()
            } catch {
                // Use default suggestions if API fails
                suggestions = []
            }
        }
    }
}

