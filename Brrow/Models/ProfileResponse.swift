//
//  ProfileResponse.swift
//  Brrow
//
//  Created to handle profile API responses
//

import Foundation

// MARK: - Profile Response Models
struct ProfileResponse: Codable {
    let id: Int
    let apiId: String
    let username: String
    let email: String
    let profilePicture: String?
    let bio: String
    let location: String
    let verified: Bool
    let trustScore: Int
    let createdAt: String?
    let listerRating: Double
    let renteeRating: Double
    let stats: ProfileStats
    let isOwnProfile: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case apiId = "api_id"
        case username, email
        case profilePicture = "profile_picture"
        case bio, location, verified
        case trustScore = "trust_score"
        case createdAt = "created_at"
        case listerRating = "lister_rating"
        case renteeRating = "rentee_rating"
        case stats
        case isOwnProfile = "is_own_profile"
    }
}

struct ProfileStats: Codable {
    let listings: Int
    let rentals: Int
    let rating: Double
    let reviews: Int
}

// Extension to convert ProfileResponse to User
extension ProfileResponse {
    func toUser() -> User {
        return User(
            id: id,
            username: username,
            email: email ?? "",
            apiId: apiId,
            profilePicture: profilePicture,
            listerRating: Float(listerRating),
            renteeRating: Float(renteeRating),
            bio: bio
        )
    }
}