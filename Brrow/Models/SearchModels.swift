//
//  SearchModels.swift
//  Brrow
//
//  Advanced search and filtering models
//

import Foundation
import CoreLocation

// MARK: - Search Request Models

struct SearchRequest: Codable {
    let query: String?
    let location: SearchLocation?
    let filters: AdvancedSearchFilters
    let sort: SearchSort
    let pagination: SearchPagination

    init(
        query: String? = nil,
        location: SearchLocation? = nil,
        filters: AdvancedSearchFilters = AdvancedSearchFilters(),
        sort: SearchSort = SearchSort(),
        pagination: SearchPagination = SearchPagination()
    ) {
        self.query = query
        self.location = location
        self.filters = filters
        self.sort = sort
        self.pagination = pagination
    }
}

struct SearchLocation: Codable {
    let latitude: Double
    let longitude: Double
    let radius: Double // in miles
    let address: String?

    init(coordinate: CLLocationCoordinate2D, radius: Double = 25.0, address: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.radius = radius
        self.address = address
    }
}

struct AdvancedSearchFilters: Codable {
    var categories: [String] = []
    var priceRange: PriceRange?
    var availability: AvailabilityFilter?
    var features: [String] = []
    var condition: ItemCondition?
    var deliveryOptions: [DeliveryOption] = []
    var ratingMin: Double?
    var isInstantBook: Bool?
    var isVerifiedOwner: Bool?
    var hasImages: Bool?
    var distance: Double?
    var verifiedSellersOnly: Bool = false
    var deliveryAvailable: Bool = false
    var instantBooking: Bool = false
    var includeGarageSales: Bool = false
    var freeItemsOnly: Bool = false
    var sortBy: SortOption = .relevance

    enum SortOption: String, Codable, CaseIterable {
        case relevance = "RELEVANCE"
        case price = "PRICE"
        case distance = "DISTANCE"
        case newest = "NEWEST"
        case rating = "RATING"
        case popular = "POPULAR"

        var displayName: String {
            switch self {
            case .relevance: return "Relevance"
            case .price: return "Price"
            case .distance: return "Distance"
            case .newest: return "Newest"
            case .rating: return "Rating"
            case .popular: return "Popular"
            }
        }
    }

    struct PriceRange: Codable {
        let min: Double?
        let max: Double?

        var lowerBound: Double? { min }
        var upperBound: Double? { max }

        func contains(_ value: Double) -> Bool {
            let minValue = min ?? 0
            let maxValue = max ?? Double.infinity
            return value >= minValue && value <= maxValue
        }
    }

    enum AvailabilityFilter: String, Codable, CaseIterable, Equatable {
        case all = "ALL"
        case available = "AVAILABLE"
        case comingSoon = "COMING_SOON"

        var displayName: String {
            switch self {
            case .all: return "All"
            case .available: return "Available Now"
            case .comingSoon: return "Coming Soon"
            }
        }
    }
}

enum ItemCondition: String, Codable, CaseIterable {
    case new = "NEW"
    case excellent = "EXCELLENT"
    case good = "GOOD"
    case fair = "FAIR"

    var displayName: String {
        switch self {
        case .new: return "Like New"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        }
    }
}

enum DeliveryOption: String, Codable, CaseIterable {
    case pickup = "PICKUP"
    case delivery = "DELIVERY"
    case meetup = "MEETUP"

    var displayName: String {
        switch self {
        case .pickup: return "Pickup"
        case .delivery: return "Delivery"
        case .meetup: return "Meet Up"
        }
    }

    var icon: String {
        switch self {
        case .pickup: return "house.fill"
        case .delivery: return "shippingbox.fill"
        case .meetup: return "mappin.and.ellipse"
        }
    }
}

struct SearchSort: Codable {
    let field: SortField
    let order: SortOrder

    init(field: SortField = .relevance, order: SortOrder = .descending) {
        self.field = field
        self.order = order
    }
}

enum SortField: String, Codable, CaseIterable {
    case relevance = "RELEVANCE"
    case price = "PRICE"
    case distance = "DISTANCE"
    case newest = "NEWEST"
    case rating = "RATING"
    case popular = "POPULAR"

    var displayName: String {
        switch self {
        case .relevance: return "Best Match"
        case .price: return "Price"
        case .distance: return "Distance"
        case .newest: return "Newest"
        case .rating: return "Rating"
        case .popular: return "Most Popular"
        }
    }
}

enum SortOrder: String, Codable {
    case ascending = "ASC"
    case descending = "DESC"
}

struct SearchPagination: Codable {
    let page: Int
    let limit: Int

    init(page: Int = 1, limit: Int = 20) {
        self.page = page
        self.limit = limit
    }
}

// MARK: - Search Response Models

struct SearchResponse: Codable {
    let success: Bool
    let data: SearchData?
    let message: String?
}

struct SearchData: Codable {
    let results: [SearchResult]
    let totalCount: Int
    let pagination: SearchPagination
    let facets: SearchFacets?
    let suggestions: [SearchSuggestion]?
    let appliedFilters: AdvancedSearchFilters
    let searchTime: Double

    enum CodingKeys: String, CodingKey {
        case results, totalCount, pagination, facets, suggestions
        case appliedFilters, searchTime
    }
}

struct SearchResult: Codable, Identifiable {
    let id: String
    let score: Double
    let listing: Listing
    let distance: Double?
    let matchedTerms: [String]?
    let highlights: SearchHighlights?

    struct SearchHighlights: Codable {
        let title: String?
        let description: String?
        let tags: [String]?
    }
}

struct SearchFacets: Codable {
    let categories: [FacetCount]
    let priceRanges: [FacetCount]
    let locations: [FacetCount]
    let conditions: [FacetCount]
    let ratings: [FacetCount]
    let features: [FacetCount]

    struct FacetCount: Codable, Identifiable {
        let id = UUID()
        let value: String
        let count: Int
        let isSelected: Bool

        enum CodingKeys: String, CodingKey {
            case value, count, isSelected
        }
    }
}

struct SearchSuggestion: Codable, Identifiable {
    let id = UUID()
    let query: String
    let type: SuggestionType
    let count: Int?

    enum SuggestionType: String, Codable {
        case query = "QUERY"
        case category = "CATEGORY"
        case location = "LOCATION"
        case brand = "BRAND"
    }

    enum CodingKeys: String, CodingKey {
        case query, type, count
    }
}

// MARK: - Saved Searches

struct SavedSearch: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let searchRequest: SearchRequest
    let isNotificationEnabled: Bool
    let createdAt: String
    let updatedAt: String
    let lastExecuted: String?
    let resultCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, userId, name, searchRequest
        case isNotificationEnabled, createdAt, updatedAt
        case lastExecuted, resultCount
    }
}

struct CreateSavedSearchRequest: Codable {
    let name: String
    let searchRequest: SearchRequest
    let isNotificationEnabled: Bool
}

// MARK: - Search History

struct SearchHistory: Codable, Identifiable {
    let id = UUID()
    let query: String
    let timestamp: Date
    let resultCount: Int
    let location: String?

    enum CodingKeys: String, CodingKey {
        case query, timestamp, resultCount, location
    }
}

// MARK: - Popular Searches

struct PopularSearch: Codable, Identifiable {
    let id = UUID()
    let query: String
    let count: Int
    let category: String?
    let trend: SearchTrend

    enum SearchTrend: String, Codable {
        case rising = "RISING"
        case stable = "STABLE"
        case falling = "FALLING"
    }

    enum CodingKeys: String, CodingKey {
        case query, count, category, trend
    }
}

// MARK: - Search Analytics

struct SearchAnalytics: Codable {
    let totalSearches: Int
    let uniqueQueries: Int
    let averageResultsPerSearch: Double
    let topCategories: [CategoryAnalytics]
    let topQueries: [QueryAnalytics]
    let searchTrends: [SearchTrendData]

    struct CategoryAnalytics: Codable {
        let category: String
        let searchCount: Int
        let clickThrough: Double
    }

    struct QueryAnalytics: Codable {
        let query: String
        let count: Int
        let avgResultCount: Int
        let avgClickPosition: Double?
    }

    struct SearchTrendData: Codable {
        let date: String
        let searchCount: Int
        let topQuery: String?
    }
}

// MARK: - Location Search

struct LocationSearchRequest: Codable {
    let query: String
    let types: [LocationType]?
    let countryCode: String?
    let limit: Int

    enum LocationType: String, Codable {
        case city = "CITY"
        case neighborhood = "NEIGHBORHOOD"
        case landmark = "LANDMARK"
        case address = "ADDRESS"
    }

    init(query: String, types: [LocationType]? = nil, countryCode: String? = "US", limit: Int = 10) {
        self.query = query
        self.types = types
        self.countryCode = countryCode
        self.limit = limit
    }
}

struct LocationSearchResponse: Codable {
    let success: Bool
    let data: [LocationResult]?
    let message: String?
}

struct LocationResult: Codable, Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let city: String
    let state: String
    let country: String
    let latitude: Double
    let longitude: Double
    let type: LocationSearchRequest.LocationType
    let distance: Double?

    enum CodingKeys: String, CodingKey {
        case name, address, city, state, country
        case latitude, longitude, type, distance
    }
}

// MARK: - Search Configuration

struct SearchConfiguration: Codable {
    let enabledFeatures: [SearchFeature]
    let defaultRadius: Double
    let maxRadius: Double
    let resultsPerPage: Int
    let maxResultsPerPage: Int
    let enableAutoComplete: Bool
    let enableTypoCorrection: Bool
    let enableSynonyms: Bool

    enum SearchFeature: String, Codable {
        case locationSearch = "LOCATION_SEARCH"
        case facetedSearch = "FACETED_SEARCH"
        case savedSearches = "SAVED_SEARCHES"
        case searchHistory = "SEARCH_HISTORY"
        case searchSuggestions = "SEARCH_SUGGESTIONS"
        case searchAnalytics = "SEARCH_ANALYTICS"
    }

    static let `default` = SearchConfiguration(
        enabledFeatures: [.locationSearch, .facetedSearch, .savedSearches, .searchHistory, .searchSuggestions],
        defaultRadius: 25.0,
        maxRadius: 100.0,
        resultsPerPage: 20,
        maxResultsPerPage: 50,
        enableAutoComplete: true,
        enableTypoCorrection: true,
        enableSynonyms: true
    )
}

// MARK: - Helper Extensions

extension AdvancedSearchFilters {
    var isEmpty: Bool {
        return categories.isEmpty &&
               priceRange == nil &&
               availability == nil &&
               features.isEmpty &&
               condition == nil &&
               deliveryOptions.isEmpty &&
               ratingMin == nil &&
               isInstantBook == nil &&
               isVerifiedOwner == nil &&
               hasImages == nil
    }

    var activeFilterCount: Int {
        var count = 0
        if !categories.isEmpty { count += 1 }
        if priceRange != nil { count += 1 }
        if availability != nil { count += 1 }
        if !features.isEmpty { count += 1 }
        if condition != nil { count += 1 }
        if !deliveryOptions.isEmpty { count += 1 }
        if ratingMin != nil { count += 1 }
        if isInstantBook != nil { count += 1 }
        if isVerifiedOwner != nil { count += 1 }
        if hasImages != nil { count += 1 }
        return count
    }
}

extension SearchLocation {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension SearchResult {
    var distanceString: String? {
        guard let distance = distance else { return nil }
        if distance < 1.0 {
            return "< 1 mi"
        } else {
            return String(format: "%.1f mi", distance)
        }
    }
}