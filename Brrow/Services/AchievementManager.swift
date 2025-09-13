//
//  AchievementManager.swift
//  Brrow
//
//  Created by Assistant on 7/26/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Achievement Models
struct AchievementCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let color: String
    let unlockedCount: Int
    let totalCount: Int
    let completionPercentage: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color
        case unlockedCount = "unlocked_count"
        case totalCount = "total_count"
        case completionPercentage = "completion_percentage"
    }
}

struct AchievementData: Codable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let description: String
    let hint: String?
    let icon: String
    let points: Int
    let difficulty: String
    let type: String
    let category: String
    let categoryColor: String
    let isUnlocked: Bool
    let isSecret: Bool
    let unlockedAt: String?
    let progress: Progress
    
    enum CodingKeys: String, CodingKey {
        case id, code, name, description, hint, icon, points, difficulty, type, category
        case categoryColor = "category_color"
        case isUnlocked = "is_unlocked"
        case isSecret = "is_secret"
        case unlockedAt = "unlocked_at"
        case progress
    }
    
    struct Progress: Codable {
        let current: Int
        let target: Int
        let percentage: Int
    }
    
    var difficultyColor: Color {
        switch difficulty {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        case "legendary": return .purple
        default: return .gray
        }
    }
    
    var displayName: String {
        isSecret && !isUnlocked ? "???" : name
    }
    
    var displayDescription: String {
        isSecret && !isUnlocked ? "Hidden achievement" : description
    }
}

struct UserLevel: Codable {
    let current: Int
    let points: Int
    let pointsToNext: Int
    let lifetimePoints: Int
    let title: String
    let prestige: Int
    let rank: Int
    let progressPercentage: Int
    
    enum CodingKeys: String, CodingKey {
        case current, points, title, prestige, rank
        case pointsToNext = "points_to_next"
        case lifetimePoints = "lifetime_points"
        case progressPercentage = "progress_percentage"
    }
}

struct AchievementStats: Codable {
    let totalUnlocked: Int
    let easyUnlocked: Int?
    let mediumUnlocked: Int?
    let hardUnlocked: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalUnlocked = "total_unlocked"
        case easyUnlocked = "easy_unlocked"
        case mediumUnlocked = "medium_unlocked"
        case hardUnlocked = "hard_unlocked"
    }
}

struct AchievementsResponse: Codable {
    let success: Bool
    let data: AchievementsData
    
    struct AchievementsData: Codable {
        let userLevel: Int?
        let progressToNext: Int?
        let nextLevelRequirement: Int?
        let statistics: AchievementStats?
        let achievements: [AchievementData]
        let recentUnlocked: [AchievementData]?
        
        enum CodingKeys: String, CodingKey {
            case userLevel = "user_level"
            case progressToNext = "progress_to_next"
            case nextLevelRequirement = "next_level_requirement"
            case statistics
            case achievements
            case recentUnlocked = "recent_unlocked"
        }
    }
}

struct AchievementUnlockResult: Codable {
    let action: String
    let value: Int
    let timestamp: String?
    let achievementsUnlocked: [UnlockedAchievement]?
    let progressUpdated: Bool?
    let level: UserLevel?
    
    enum CodingKeys: String, CodingKey {
        case action, value, level, timestamp
        case achievementsUnlocked = "achievements_unlocked"
        case progressUpdated = "progress_updated"
    }
    
    // Computed properties for backward compatibility
    var unlockedAchievements: [UnlockedAchievement] {
        return achievementsUnlocked ?? []
    }
    
    var unlockedCount: Int {
        return unlockedAchievements.count
    }
    
    struct UnlockedAchievement: Codable {
        let id: Int
        let code: String
        let name: String
        let description: String
        let points: Int
        let icon: String
        let difficulty: String
    }
}

// MARK: - Achievement Manager
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var userLevel: UserLevel?
    @Published var stats: AchievementStats?
    @Published var categories: [AchievementCategory] = []
    @Published var achievements: [AchievementData] = []
    @Published var recentUnlocks: [AchievementData] = []
    @Published var isLoading = false
    @Published var newlyUnlockedAchievements: [AchievementUnlockResult.UnlockedAchievement] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Listen for app becoming active to refresh achievements
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.fetchAchievements()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch Achievements
    func fetchAchievements() {
        guard AuthManager.shared.currentUser?.apiId != nil else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await APIClient.shared.getUserAchievements()
                
                await MainActor.run {
                    self.isLoading = false
                    if let userLevel = response.data.userLevel,
                       let progressToNext = response.data.progressToNext,
                       let nextLevelRequirement = response.data.nextLevelRequirement {
                        self.userLevel = UserLevel(
                            current: userLevel,
                            points: progressToNext,
                            pointsToNext: nextLevelRequirement - progressToNext,
                            lifetimePoints: progressToNext, // Estimate
                            title: "Level \(userLevel)",
                            prestige: 0,
                            rank: userLevel,
                            progressPercentage: Int(Double(progressToNext) / Double(nextLevelRequirement) * 100)
                        )
                    }
                    self.stats = response.data.statistics
                    self.categories = [] // Categories not in response
                    self.achievements = response.data.achievements
                    self.recentUnlocks = response.data.recentUnlocked ?? []
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("❌ Failed to fetch achievements: \(error)")
                }
            }
        }
    }
    
    // MARK: - Track Achievement Progress
    func trackProgress(action: String, value: Int = 1, metadata: [String: Any] = [:]) {
        guard AuthManager.shared.isAuthenticated else { return }
        
        Task {
            do {
                let response = try await APIClient.shared.trackAchievementProgress(
                    action: action,
                    value: value,
                    metadata: metadata.isEmpty ? nil : metadata
                )
                
                await MainActor.run {
                    guard response.success else { return }
                    
                    // Handle newly unlocked achievements
                    if !response.data.unlockedAchievements.isEmpty {
                        self.handleUnlockedAchievements(response.data.unlockedAchievements)
                        
                        // Update level if provided
                        if let newLevel = response.data.level {
                            self.userLevel = newLevel
                        }
                        
                        // Refresh full achievement list
                        self.fetchAchievements()
                    }
                }
            } catch {
                print("❌ Failed to track achievement: \(error)")
            }
        }
    }
    
    private func handleUnlockedAchievements(_ unlocked: [AchievementUnlockResult.UnlockedAchievement]) {
        // Add to newly unlocked list
        newlyUnlockedAchievements.append(contentsOf: unlocked)
        
        // Trigger haptic feedback
        HapticManager.notification(type: .success)
        
        // Post notification for UI to show celebration
        for achievement in unlocked {
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: nil,
                userInfo: ["achievement": achievement]
            )
            
            // Send push notification for achievement unlock
            NotificationManager.shared.sendAchievementNotification(
                achievementName: achievement.name,
                achievementId: String(achievement.id)
            )
        }
    }
    
    // MARK: - Helper Methods
    func getAchievementsByCategory(_ categoryName: String) -> [AchievementData] {
        achievements.filter { $0.category == categoryName }
    }
    
    func getProgress(for categoryName: String) -> Double {
        let categoryAchievements = getAchievementsByCategory(categoryName)
        guard !categoryAchievements.isEmpty else { return 0 }
        
        let unlocked = categoryAchievements.filter { $0.isUnlocked }.count
        return Double(unlocked) / Double(categoryAchievements.count)
    }
    
    func clearNewlyUnlocked() {
        newlyUnlockedAchievements.removeAll()
    }
}

// MARK: - Achievement Tracking Response
// Using the AchievementTrackResponse from APIClient.swift

// MARK: - Notification Names
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Achievement Actions
extension AchievementManager {
    // Common achievement tracking actions
    func trackListingCreated() {
        trackProgress(action: "listing_created")
    }
    
    func trackRentalCompleted() {
        trackProgress(action: "rental_completed")
    }
    
    func trackMessageSent() {
        trackProgress(action: "message_sent")
    }
    
    func trackProfileCompleted() {
        trackProgress(action: "profile_complete")
    }
    
    func trackListingViewed() {
        trackProgress(action: "listing_viewed")
    }
    
    func trackFavoriteAdded() {
        trackProgress(action: "favorite_added")
    }
    
    func trackSeekPosted() {
        trackProgress(action: "seek_posted")
    }
    
    func trackGarageSaleVisited() {
        trackProgress(action: "garage_sale_visited")
    }
    
    func trackGarageSaleHosted() {
        trackProgress(action: "garage_sale_hosted")
    }
    
    func trackAppOpened() {
        trackProgress(action: "app_opened")
    }
    
    func trackDailyLogin() {
        trackProgress(action: "daily_login")
    }
    
    func trackTrustScoreUpdated(score: Int) {
        trackProgress(action: "trust_score_updated", metadata: ["current_value": score])
    }
    
    func trackCO2Saved(amount: Double) {
        trackProgress(action: "co2_saved", value: Int(amount))
    }
    
    func trackUniqueConnection(userId: String) {
        trackProgress(action: "unique_connections", metadata: ["unique_id": userId])
    }
    
    func trackStreak(type: String) {
        trackProgress(action: "streak_maintained", metadata: ["streak_type": type])
    }
    
    // MARK: - Additional Tracking Methods
    
    func trackOnboardingCompleted() {
        trackProgress(action: "onboarding_completed")
    }
    
    func trackIdentityVerified() {
        trackProgress(action: "identity_verified")
    }
    
    func trackBusinessAccountCreated() {
        trackProgress(action: "business_account_created")
    }
}