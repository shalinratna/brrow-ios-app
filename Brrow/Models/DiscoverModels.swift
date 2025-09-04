//
//  DiscoverModels.swift
//  Brrow
//
//  Data models for Discover features
//

import Foundation

// MARK: - Story Model

struct BrrowStory: Identifiable, Codable {
    var id = UUID()
    let userId: String
    let username: String
    let thumbnailUrl: String
    let videoUrl: String?
    let imageUrl: String?
    let caption: String
    let timestamp: Date
    let isViewed: Bool
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username, thumbnailUrl = "thumbnail_url"
        case videoUrl = "video_url", imageUrl = "image_url"
        case caption, timestamp, isViewed = "is_viewed"
    }
}

// MARK: - Challenge Model

struct CommunityChallenge: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let reward: String
    let participantCount: Int
    let endDate: Date
    let difficulty: ChallengeDifficulty
    let category: ChallengeCategory
    let progress: Double // 0.0 to 1.0
    
    enum ChallengeDifficulty: String, Codable, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }
    
    enum ChallengeCategory: String, Codable, CaseIterable {
        case sharing = "Sharing"
        case community = "Community"
        case eco = "Eco-Friendly"
        case social = "Social"
    }
}