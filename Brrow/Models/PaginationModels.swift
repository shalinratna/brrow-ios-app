//
//  PaginationModels.swift
//  Brrow
//
//  Pagination-related models used across the app
//

import Foundation

// MARK: - Pagination Info
struct PaginationInfo: Codable {
    let page: Int?
    let limit: Int?
    let total: Int
    let hasMore: Bool?
    let pages: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case hasMore = "has_more"
        case pages
    }

    // Computed properties for compatibility
    var hasMorePages: Bool {
        return hasMore ?? false
    }

    var currentPage: Int {
        return page ?? 1
    }

    var itemsPerPage: Int {
        return limit ?? 20
    }
}