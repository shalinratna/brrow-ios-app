//
//  SearchResponse.swift
//  Brrow
//
//  Advanced search response models
//

import Foundation

// MARK: - Search Parameters
struct SearchParameters: Codable {
    let query: String?
    let category: String?
    let categoryId: String?
    let minPrice: Double?
    let maxPrice: Double?
    let condition: String?
    let isNegotiable: Bool?
    let deliveryOptions: [String]?
    let tags: [String]?
    let lat: Double?
    let lng: Double?
    let radius: Double?
    let city: String?
    let state: String?
    let zipCode: String?
    let availableOnly: Bool
    let sortBy: SearchSortOption
    let page: Int
    let limit: Int
    
    init(
        query: String? = nil,
        category: String? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        condition: String? = nil,
        location: (lat: Double, lng: Double, radius: Double)? = nil,
        sortBy: SearchSortOption = .relevance,
        page: Int = 1,
        limit: Int = 20
    ) {
        self.query = query
        self.category = category
        self.categoryId = nil
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.condition = condition
        self.isNegotiable = nil
        self.deliveryOptions = nil
        self.tags = nil
        self.lat = location?.lat
        self.lng = location?.lng
        self.radius = location?.radius
        self.city = nil
        self.state = nil
        self.zipCode = nil
        self.availableOnly = true
        self.sortBy = sortBy
        self.page = page
        self.limit = limit
    }
    
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let query = query, !query.isEmpty {
            items.append(URLQueryItem(name: "q", value: query))
        }
        if let category = category, !category.isEmpty {
            items.append(URLQueryItem(name: "category", value: category))
        }
        if let categoryId = categoryId {
            items.append(URLQueryItem(name: "categoryId", value: categoryId))
        }
        if let minPrice = minPrice {
            items.append(URLQueryItem(name: "minPrice", value: String(minPrice)))
        }
        if let maxPrice = maxPrice {
            items.append(URLQueryItem(name: "maxPrice", value: String(maxPrice)))
        }
        if let condition = condition {
            items.append(URLQueryItem(name: "condition", value: condition))
        }
        if let isNegotiable = isNegotiable {
            items.append(URLQueryItem(name: "isNegotiable", value: String(isNegotiable)))
        }
        if let deliveryOptions = deliveryOptions, !deliveryOptions.isEmpty {
            items.append(URLQueryItem(name: "deliveryOptions", value: deliveryOptions.joined(separator: ",")))
        }
        if let tags = tags, !tags.isEmpty {
            items.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }
        if let lat = lat {
            items.append(URLQueryItem(name: "lat", value: String(lat)))
        }
        if let lng = lng {
            items.append(URLQueryItem(name: "lng", value: String(lng)))
        }
        if let radius = radius {
            items.append(URLQueryItem(name: "radius", value: String(radius)))
        }
        if let city = city {
            items.append(URLQueryItem(name: "city", value: city))
        }
        if let state = state {
            items.append(URLQueryItem(name: "state", value: state))
        }
        if let zipCode = zipCode {
            items.append(URLQueryItem(name: "zipCode", value: zipCode))
        }
        items.append(URLQueryItem(name: "availableOnly", value: String(availableOnly)))
        items.append(URLQueryItem(name: "sortBy", value: sortBy.rawValue))
        items.append(URLQueryItem(name: "page", value: String(page)))
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        
        return items
    }
}

// MARK: - Sort Options
enum SearchSortOption: String, Codable, CaseIterable {
    case relevance = "relevance"
    case priceLow = "price_low"
    case priceHigh = "price_high"
    case distance = "distance"
    case newest = "newest"
    case popular = "popular"
    
    var displayName: String {
        switch self {
        case .relevance: return "Most Relevant"
        case .priceLow: return "Price: Low to High"
        case .priceHigh: return "Price: High to Low"
        case .distance: return "Distance: Nearest"
        case .newest: return "Newest First"
        case .popular: return "Most Popular"
        }
    }
    
    var icon: String {
        switch self {
        case .relevance: return "sparkles"
        case .priceLow, .priceHigh: return "dollarsign.circle"
        case .distance: return "location"
        case .newest: return "clock"
        case .popular: return "flame"
        }
    }
}

// MARK: - Search Response
struct LegacySearchResponse: Codable {
    let success: Bool
    let data: SearchData
    
    struct SearchData: Codable {
        let listings: [Listing]
        let pagination: LegacySearchPagination
        let filters: LegacySearchFilters
        let suggestions: [String]
    }
}

struct LegacySearchPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

struct LegacySearchFilters: Codable {
    let applied: AppliedFilters
    let available: AvailableFilters
    
    struct AppliedFilters: Codable {
        let query: String?
        let category: String?
        let priceRange: PriceRange?
        let condition: String?
        let location: LocationFilter?
        let deliveryOptions: [String]?
        let tags: [String]?
    }
    
    struct AvailableFilters: Codable {
        let categories: [CategoryModel]
        let conditions: [String]
        let sortOptions: [String]
    }
    
    struct PriceRange: Codable {
        let min: Double?
        let max: Double?
    }
    
    struct LocationFilter: Codable {
        let city: String?
        let state: String?
        let zipCode: String?
        let radius: Double?
    }
}

// MARK: - Autocomplete Response
struct AutocompleteResponse: Codable {
    let success: Bool
    let data: [String]
}

// MARK: - Suggestions Response  
// SuggestionsResponse is defined in APIResponses.swift