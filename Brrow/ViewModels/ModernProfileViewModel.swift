import Foundation
import Combine
import SwiftUI

@MainActor
class ModernProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userListings: [Listing] = []
    @Published var rating: Double = 0.0
    @Published var reviewCount: Int = 0
    @Published var totalListings: Int = 0
    @Published var totalTransactions: Int = 0
    @Published var totalEarnings: Int = 0
    @Published var totalRentals: Int = 0
    @Published var recentActivity: [UserActivity] = []
    @Published var earningsData: [EarningsDataPoint] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var userReviews: [ProfileReview] = []
    @Published var reviewDistribution: [Int: Int] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init() {
        setupUserObserver()
    }
    
    private func setupUserObserver() {
        authManager.$currentUser
            .sink { [weak self] user in
                self?.user = user
                // Only load profile data if user is authenticated with a token
                if user != nil && self?.authManager.isAuthenticated == true {
                    self?.loadProfileData()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadProfileData() {
        user = authManager.currentUser
        loadUserListings()
        loadUserRating()
        loadUserStats()
        loadRecentActivity()
        loadEarningsData()
        loadRecentTransactions()
        loadUserReviews()
    }
    
    func loadUserData() {
        // Alias for loadProfileData for compatibility
        loadProfileData()
    }
    
    private func loadUserListings() {
        guard let userId = user?.id,
              userId > 0,
              authManager.isAuthenticated,
              authManager.authToken != nil else { 
            self.userListings = []
            self.totalListings = 0
            return 
        }
        
        Task {
            do {
                let listings = try await apiClient.fetchUserListings(userId: userId)
                await MainActor.run {
                    self.userListings = listings
                    self.totalListings = listings.count
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadUserRating() {
        guard let userId = user?.id,
              userId > 0,
              authManager.isAuthenticated,
              authManager.authToken != nil else { 
            self.rating = 0.0
            self.reviewCount = 0
            return 
        }
        
        Task {
            do {
                let rating = try await apiClient.fetchUserRating(userId: userId)
                await MainActor.run {
                    self.rating = rating.rating
                    self.reviewCount = 0 // UserRating doesn't have reviewCount
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadUserStats() {
        // Mock data for now
        totalTransactions = 42
        totalEarnings = 1234
        totalRentals = 18
    }
    
    private func loadRecentActivity() {
        // Mock recent activity
        recentActivity = [
            UserActivity(
                id: "1",
                type: .borrowed,
                title: "New Rental",
                description: "Power Drill rented by John",
                amount: "45",
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                timeAgo: "1 hour ago"
            ),
            UserActivity(
                id: "2",
                type: .reviewed,
                title: "Review Received",
                description: "5-star review from Sarah",
                amount: nil,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
                timeAgo: "2 hours ago"
            ),
            UserActivity(
                id: "3",
                type: .listed,
                title: "Listing Promoted",
                description: "Camera Kit featured",
                amount: nil,
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-10800)),
                timeAgo: "3 hours ago"
            )
        ]
    }
    
    private func loadEarningsData() {
        // Mock earnings data
        let calendar = Calendar.current
        earningsData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let amount = Double.random(in: 50...200)
            return EarningsDataPoint(date: date, amount: amount)
        }.reversed()
    }
    
    private func loadRecentTransactions() {
        // Mock will be replaced with actual API call
        recentTransactions = []
    }
    
    private func loadUserReviews() {
        // Mock reviews
        userReviews = []
        
        // Mock review distribution
        reviewDistribution = [
            5: 15,
            4: 8,
            3: 2,
            2: 1,
            1: 0
        ]
    }
    
    // Computed property for compatibility
    var userRating: Double {
        return rating
    }
    
    var totalReviews: Int {
        return reviewCount
    }
}

// MARK: - Extensions for compatibility

extension UserActivity {
    var icon: String {
        switch type {
        case .borrowed: return "arrow.triangle.2.circlepath"
        case .lent: return "arrow.triangle.2.circlepath"
        case .earned: return "dollarsign.circle"
        case .reviewed: return "star.fill"
        case .listed: return "cube.box"
        }
    }
    
    var color: Color {
        switch type {
        case .borrowed: return .blue
        case .lent: return .green
        case .earned: return .orange
        case .reviewed: return .yellow
        case .listed: return .purple
        }
    }
    
    var date: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
}

// Supporting views moved to ProfileSupportingViews.swift