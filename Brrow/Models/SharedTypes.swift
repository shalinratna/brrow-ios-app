//
//  SharedTypes.swift
//  Brrow
//
//  Shared types used across multiple views and services
//

import Foundation

// MARK: - Sort Options

enum MarketplaceSortOption: String, CaseIterable {
    case newest = "Newest"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case distance = "Distance"
    case popularity = "Most Popular"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest"
        case .priceLowToHigh: return "Price ↑"
        case .priceHighToLow: return "Price ↓"
        case .distance: return "Nearest"
        case .popularity: return "Popular"
        }
    }
    
    var apiValue: String {
        switch self {
        case .newest: return "newest"
        case .priceLowToHigh: return "price_asc"
        case .priceHighToLow: return "price_desc"
        case .distance: return "distance"
        case .popularity: return "popular"
        }
    }
}

// MARK: - Marketplace Filters

struct MarketplaceFilters {
    var priceRange: ClosedRange<Double>?
    var distance: Double?
    var availability: Bool?
    var condition: String?
    var sortBy: MarketplaceSortOption = .newest
}