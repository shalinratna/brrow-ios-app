//
//  PostModels.swift
//  Brrow
//
//  Models for user posts and filtering
//

import Foundation

// MARK: - Post Filter

enum PostFilter: String, CaseIterable {
    case all = "All"
    case listings = "Listings"
    case seeks = "Seeks"
    case garageSales = "Garage Sales"

    var title: String { rawValue }
}