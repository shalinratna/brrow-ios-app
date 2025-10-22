//
//  UniversalProfileViewModel.swift
//  Brrow
//
//  Universal profile view model that handles both own profile and other users' profiles
//

import Foundation
import Combine
import SwiftUI

@MainActor
class UniversalProfileViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var user: User
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Profile Data
    @Published var listings: [Listing] = []
    @Published var reviews: [SocialUserReview] = []  // FIXED: Use existing SocialUserReview model
    @Published var activities: [UserActivity] = []
    @Published var stats: [ProfileStat] = []
    @Published var monthlyData: [MonthlyData] = []
    @Published var activityStats: [ActivityStat] = []

    // Pagination
    @Published var hasMoreListings = false
    @Published var hasMoreReviews = false
    @Published var hasMoreActivities = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared

    // Track if this is own profile for optimized data loading
    var isOwnProfile: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        return user.id == currentUser.id || user.apiId == currentUser.apiId
    }

    // MARK: - Initialization

    init(user: User) {
        self.user = user
    }

    // MARK: - Profile Loading

    /// Load all profile data based on profile ownership
    func loadProfile() {
        print("🔄 [UniversalProfileViewModel] Loading profile for \(user.username)")
        print("🔍 [UniversalProfileViewModel] Is own profile: \(isOwnProfile)")

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Load different data based on profile ownership
                if isOwnProfile {
                    await loadOwnProfileData()
                } else {
                    await loadOtherUserProfileData()
                }

                // Load common data for both
                await loadUserListings()
                await loadUserReviews()
                await loadUserStats()

                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("❌ [UniversalProfileViewModel] Error loading profile: \(error)")
                }
            }
        }
    }

    // MARK: - Own Profile Data Loading

    private func loadOwnProfileData() async {
        print("🔄 [UniversalProfileViewModel] Loading own profile data")

        // For own profile, fetch activities (transactions, favorites, etc.)
        await MainActor.run {
            // Note: Replace with real API endpoint when available
            // Example: activities = try await apiClient.fetchUserActivities(userId: user.id)
            activities = generateMockActivities()

            // Load monthly earnings data for charts
            monthlyData = generateMonthlyData()

            // Load activity stats
            activityStats = generateActivityStats()
        }
    }

    // MARK: - Other User Profile Data Loading

    private func loadOtherUserProfileData() async {
        print("🔄 [UniversalProfileViewModel] Loading other user profile data")

        // For other users, we don't show activities (privacy)
        // Only show public data: listings, reviews, basic stats
        activities = []
        monthlyData = []
        activityStats = []
    }

    // MARK: - Common Data Loading

    private func loadUserListings() async {
        do {
            // Convert user ID to Int if needed
            guard let userIdInt = Int(user.id) else {
                print("❌ [UniversalProfileViewModel] Invalid user ID format: \(user.id)")
                return
            }

            let fetchedListings = try await apiClient.fetchUserListings(userId: userIdInt)

            await MainActor.run {
                self.listings = fetchedListings
                self.hasMoreListings = fetchedListings.count >= 20 // Pagination threshold
                print("✅ [UniversalProfileViewModel] Loaded \(fetchedListings.count) listings")
            }
        } catch {
            print("❌ [UniversalProfileViewModel] Error loading listings: \(error)")
            await MainActor.run {
                self.listings = []
            }
        }
    }

    private func loadUserReviews() async {
        // Note: Implement when review API endpoint is available
        // For now, use mock data
        await MainActor.run {
            self.reviews = generateMockReviews()
            print("✅ [UniversalProfileViewModel] Loaded \(self.reviews.count) reviews (mock data)")
        }
    }

    private func loadUserStats() async {
        do {
            // Convert user ID to Int if needed
            guard let userIdInt = Int(user.id) else {
                print("❌ [UniversalProfileViewModel] Invalid user ID format: \(user.id)")
                return
            }

            // Fetch user rating
            let ratingData = try await apiClient.fetchUserRating(userId: userIdInt)

            await MainActor.run {
                // Generate stats from available data
                self.stats = [
                    ProfileStat(
                        icon: "bag.fill",
                        title: "Active Listings",
                        value: "\(self.listings.filter { $0.isActive }.count)",
                        color: Theme.Colors.primary,
                        trend: "neutral"
                    ),
                    ProfileStat(
                        icon: "star.fill",
                        title: "Average Rating",
                        value: String(format: "%.1f", ratingData.rating),
                        color: Theme.Colors.accent,
                        trend: "neutral"
                    ),
                    ProfileStat(
                        icon: "message.fill",
                        title: "Total Reviews",
                        value: "\(self.reviews.count)",
                        color: Theme.Colors.secondary,
                        trend: "neutral"
                    ),
                    ProfileStat(
                        icon: "checkmark.seal.fill",
                        title: "Completed Rentals",
                        value: "\(user.completedRentals)",
                        color: Color.green,  // FIXED: Use Color.green instead of .green
                        trend: "neutral"
                    )
                ]

                print("✅ [UniversalProfileViewModel] Generated stats")
            }
        } catch {
            print("❌ [UniversalProfileViewModel] Error loading stats: \(error)")
            await MainActor.run {
                // Generate basic stats from available user data
                self.stats = [
                    ProfileStat(
                        icon: "bag.fill",
                        title: "Active Listings",
                        value: "\(self.listings.filter { $0.isActive }.count)",
                        color: Theme.Colors.primary,
                        trend: "neutral"
                    ),
                    ProfileStat(
                        icon: "star.fill",
                        title: "Member Since",
                        value: self.formatMemberSince(),
                        color: Theme.Colors.accent,
                        trend: "neutral"
                    )
                ]
            }
        }
    }

    // MARK: - Pagination

    func loadMoreListings() {
        guard hasMoreListings, !isLoading else { return }

        // Implement pagination when API supports it
        print("🔄 [UniversalProfileViewModel] Loading more listings (pagination)")
    }

    func loadMoreReviews() {
        guard hasMoreReviews, !isLoading else { return }

        // Implement pagination when API supports it
        print("🔄 [UniversalProfileViewModel] Loading more reviews (pagination)")
    }

    // MARK: - Helper Methods

    private func formatMemberSince() -> String {
        let calendar = Calendar.current
        let now = Date()
        let memberSince = user.memberSince

        let components = calendar.dateComponents([.year, .month], from: memberSince, to: now)

        if let years = components.year, years > 0 {
            return "\(years)y"
        } else if let months = components.month, months > 0 {
            return "\(months)mo"
        } else {
            return "New"
        }
    }

    // MARK: - Mock Data Generators (Remove when real API is available)

    private func generateMockReviews() -> [SocialUserReview] {
        // Generate sample reviews for display
        return []
    }

    private func generateMockActivities() -> [UserActivity] {
        // Generate sample activities for own profile using the custom initializer
        let sampleActivities: [UserActivity] = [
            UserActivity(
                id: UUID().uuidString,
                icon: "bag.badge.plus",
                title: "New Listing Posted",
                subtitle: "Power Drill",
                timeAgo: "2h ago",
                color: Color.green
            ),
            UserActivity(
                id: UUID().uuidString,
                icon: "message.fill",
                title: "New Message",
                subtitle: "About: Camera Lens",
                timeAgo: "4h ago",
                color: Color.blue
            ),
            UserActivity(
                id: UUID().uuidString,
                icon: "star.fill",
                title: "New Review Received",
                subtitle: "5 stars from @johndoe",
                timeAgo: "1d ago",
                color: Color.orange
            )
        ]

        return sampleActivities
    }

    private func generateMonthlyData() -> [MonthlyData] {
        // Generate sample monthly data for charts
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        return months.enumerated().map { index, month in
            MonthlyData(
                month: month,
                earnings: Double.random(in: 100...500),
                rentals: Int.random(in: 2...10)
            )
        }
    }

    private func generateActivityStats() -> [ActivityStat] {
        return [
            ActivityStat(label: "Views", value: 1234, trend: "up"),
            ActivityStat(label: "Saves", value: 89, trend: "up"),
            ActivityStat(label: "Messages", value: 45, trend: "neutral"),
            ActivityStat(label: "Rentals", value: 23, trend: "up")
        ]
    }
}
