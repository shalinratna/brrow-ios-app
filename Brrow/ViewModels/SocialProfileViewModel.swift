//
//  SocialProfileViewModel.swift
//  Brrow
//
//  Social Profile Logic and Data Management
//

import Foundation
import SwiftUI
import Combine

// MARK: - Social Activity Stat
struct SocialActivityStat {
    let type: String
    let count: Int
    let color: Color
}

@MainActor
class SocialProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var stats: [ProfileStat] = []
    @Published var activities: [UserActivity] = []
    @Published var userListings: [Listing] = []
    @Published var reviews: [SocialUserReview] = []
    @Published var monthlyEarnings: [MonthlyEarning] = []
    @Published var activityStats: [SocialActivityStat] = []
    @Published var isFollowing = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    
    func loadUserProfile(userId: Int) {
        isLoading = true
        
        Task {
            do {
                // Load all profile data concurrently
                async let profile = loadProfile(userId: userId)
                async let statsData = loadStats(userId: userId)
                async let activitiesData = loadActivities(userId: userId)
                async let listingsData = loadUserListings(userId: userId)
                async let reviewsData = loadReviews(userId: userId)
                async let earningsData = loadEarnings(userId: userId)
                
                let (profileResult, statsResult, activitiesResult, listingsResult, reviewsResult, earningsResult) = await (
                    try profile,
                    try statsData,
                    try activitiesData,
                    try listingsData,
                    try reviewsData,
                    try earningsData
                )
                
                self.userProfile = profileResult
                self.stats = statsResult
                self.activities = activitiesResult
                self.userListings = listingsResult
                self.reviews = reviewsResult
                self.monthlyEarnings = earningsResult
                self.generateActivityStats()
                
            } catch {
                self.errorMessage = error.localizedDescription
                // Error will be automatically reported to Discord by APIClient
            }
            
            self.isLoading = false
        }
    }
    
    func toggleFollow() {
        isFollowing.toggle()
        
        Task {
            do {
                if isFollowing {
                    try await apiClient.followUser()
                } else {
                    try await apiClient.unfollowUser()
                }
            } catch {
                // Revert on error
                isFollowing.toggle()
                errorMessage = "Failed to update follow status"
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadProfile(userId: Int) async throws -> UserProfile {
        let response = try await apiClient.fetchUserProfile(userId: userId)
        
        let dateFormatter = ISO8601DateFormatter()
        let joinDate = response.createdAt.flatMap { dateFormatter.date(from: $0) } ?? Date()
        
        return UserProfile(
            bio: response.bio,
            joinDate: joinDate,
            location: response.location,
            website: nil // website not in current ProfileResponse
        )
    }
    
    private func loadStats(userId: Int) async throws -> [ProfileStat] {
        let response = try await apiClient.fetchUserProfile(userId: userId)
        
        return [
            ProfileStat(title: "Active Listings", value: "\(response.stats.listings)"),
            ProfileStat(title: "Total Rentals", value: "\(response.stats.rentals)"),
            ProfileStat(title: "Rating", value: String(format: "%.1f", response.stats.rating)),
            ProfileStat(title: "Total Reviews", value: "\(response.stats.reviews)")
        ]
    }
    
    private func loadActivities(userId: Int) async throws -> [UserActivity] {
        let apiActivities = try await apiClient.fetchUserActivities(userId: userId, limit: 20)
        return apiActivities.map { apiActivity in
            // Map APIUserActivity.type string to UserActivity.ActivityType enum
            let activityType: UserActivity.ActivityType
            switch apiActivity.type {
            case "listing_created": activityType = .listed
            case "listing_viewed", "search": activityType = .reviewed // No direct viewing type
            case "transaction", "message_sent": activityType = .borrowed
            case "favorite": activityType = .reviewed
            default: activityType = .listed // Default fallback
            }
            
            // Format timestamp as time ago
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let timeAgo = formatter.localizedString(for: apiActivity.timestamp, relativeTo: Date())
            
            return UserActivity(
                id: apiActivity.id,
                type: activityType,
                title: apiActivity.description,
                description: apiActivity.description,
                amount: nil,
                createdAt: ISO8601DateFormatter().string(from: apiActivity.timestamp),
                timeAgo: timeAgo
            )
        }
    }
    
    private func loadUserListings(userId: Int) async throws -> [Listing] {
        return try await apiClient.fetchSocialUserListings(userId: userId)
    }
    
    private func loadReviews(userId: Int) async throws -> [SocialUserReview] {
        return try await apiClient.fetchSocialUserReviews(userId: userId)
    }
    
    private func loadEarnings(userId: Int) async throws -> [MonthlyEarning] {
        return try await apiClient.fetchUserEarnings(userId: userId)
    }
    
    private func generateActivityStats() {
        let borrowedCount = activities.filter { $0.type == .borrowed }.count
        let lentCount = activities.filter { $0.type == .lent }.count
        let earnedCount = activities.filter { $0.type == .earned }.count
        let reviewedCount = activities.filter { $0.type == .reviewed }.count
        
        activityStats = [
            SocialActivityStat(type: "Items Lent", count: lentCount, color: .green),
            SocialActivityStat(type: "Items Borrowed", count: borrowedCount, color: .blue),
            SocialActivityStat(type: "Payments", count: earnedCount, color: Theme.Colors.primary),
            SocialActivityStat(type: "Reviews", count: reviewedCount, color: .orange)
        ]
    }
}

// MARK: - API Extensions

extension APIClient {
    func followUser() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Following user")
    }
    
    func unfollowUser() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Unfollowing user")
    }
}