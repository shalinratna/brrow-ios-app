import Foundation
import Combine
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingImagePicker = false
    @Published var showingEditProfile = false
    @Published var showingSettings = false
    @Published var userListings: [Listing] = []
    @Published var userRating: Double = 0.0
    @Published var reviewCount: Int = 0
    
    // Additional properties for UltraModernProfileView2
    @Published var activities: [ProfileActivity] = []
    @Published var reviews: [ProfileReview] = []
    @Published var totalEarned: Double = 0.0
    @Published var monthlyEarnings: Double = 0.0
    @Published var monthlyChange: String = "+0%"
    @Published var totalViews: Int = 0
    @Published var totalSaves: Int = 0
    @Published var totalMessages: Int = 0
    @Published var totalRentals: Int = 0
    @Published var viewsTrend: ProfileInsightCard.Trend = .neutral
    @Published var savesTrend: ProfileInsightCard.Trend = .neutral
    @Published var messagesTrend: ProfileInsightCard.Trend = .neutral
    @Published var rentalsTrend: ProfileInsightCard.Trend = .neutral
    @Published var analyticsData: [ChartDataPoint] = []
    @Published var ratingDistribution: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    private let fileUploadService = FileUploadService.shared
    
    init() {
        loadUserProfile()
        setupUserObserver()
    }
    
    private func setupUserObserver() {
        authManager.$currentUser
            .sink { [weak self] user in
                self?.user = user
                // Only load data if user is authenticated with a token
                if user != nil && self?.authManager.isAuthenticated == true {
                    self?.loadUserListings()
                    self?.loadUserRating()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadUserProfile() {
        user = authManager.currentUser
        // Only load data if authenticated
        if authManager.isAuthenticated {
            loadUserListings()
            loadUserRating()
        }
    }
    
    func preloadContent() async {
        // Profile content is already loaded via currentUser observer
        // Just ensure we have the latest data
        if user == nil {
            user = authManager.currentUser
        }
        
        // Silently preload user listings and rating if not already loaded
        if userListings.isEmpty {
            await loadUserListingsAsync()
        }
        
        if userRating == 0.0 {
            await loadUserRatingAsync()
        }
    }
    
    private func loadUserListingsAsync() async {
        guard let userId = user?.id, let userIdInt = Int(userId), userIdInt > 0 else { 
            self.userListings = []
            return 
        }
        
        do {
            guard let userIdInt = Int(userId) else { return }
            let listings = try await apiClient.fetchUserListings(userId: userIdInt)
            self.userListings = listings
        } catch {
            print("Failed to preload user listings: \(error.localizedDescription)")
        }
    }
    
    private func loadUserRatingAsync() async {
        guard let userId = user?.id, let userIdInt = Int(userId), userIdInt > 0 else { 
            self.userRating = 0.0
            self.reviewCount = 0
            return 
        }
        
        do {
            let rating = try await apiClient.fetchUserRating(userId: userIdInt)
            self.userRating = rating.rating
            self.reviewCount = 0 // UserRating doesn't have reviewCount, will be set elsewhere
        } catch {
            print("Failed to preload user rating: \(error.localizedDescription)")
        }
    }
    
    private func loadUserListings() {
        guard let userId = user?.id,
              let userIdInt = Int(userId),
              userIdInt > 0,
              authManager.isAuthenticated,
              authManager.authToken != nil else { 
            self.userListings = []
            return 
        }
        
        Task {
            do {
                let listings = try await apiClient.fetchUserListings(userId: userIdInt)
                await MainActor.run {
                    self.userListings = listings
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
              let userIdInt = Int(userId),
              userIdInt > 0,
              authManager.isAuthenticated,
              authManager.authToken != nil else { 
            self.userRating = 0.0
            self.reviewCount = 0
            return 
        }
        
        Task {
            do {
                let rating = try await apiClient.fetchUserRating(userId: userIdInt)
                await MainActor.run {
                    self.userRating = rating.rating
                    self.reviewCount = 0 // UserRating doesn't have reviewCount, will be set elsewhere
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateProfile(name: String, bio: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let updatedUser = try await apiClient.updateProfile(name: name, bio: bio)
                await MainActor.run {
                    self.user = updatedUser
                    // Update AuthManager's current user and persist to keychain
                    self.authManager.currentUser = updatedUser
                    // Force save the updated user to keychain
                    if let userData = try? JSONEncoder().encode(updatedUser) {
                        KeychainHelper().save(String(data: userData, encoding: .utf8) ?? "", forKey: "brrow_user_data")
                    }
                    self.isLoading = false
                    self.showingEditProfile = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateProfileImage(_ image: UIImage) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let imageUrl = try await fileUploadService.uploadProfileImage(image)
                let updatedUser = try await apiClient.updateProfileImage(imageUrl: imageUrl)

                await MainActor.run {
                    self.user = updatedUser
                    // Update AuthManager's current user and persist to keychain
                    self.authManager.currentUser = updatedUser
                    // Force save the updated user to keychain
                    if let userData = try? JSONEncoder().encode(updatedUser) {
                        KeychainHelper().save(String(data: userData, encoding: .utf8) ?? "", forKey: "brrow_user_data")
                    }
                    self.isLoading = false
                    self.showingImagePicker = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func logout() {
        authManager.logout()
    }
    
    func deleteAccount(password: String) {
        Task {
            do {
                try await apiClient.deleteAccount(password: password)
                await MainActor.run {
                    self.authManager.logout()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    var profileStats: ProfileStatsData {
        ProfileStatsData(
            listingsCount: userListings.count,
            activeListingsCount: userListings.filter { $0.isActive }.count,
            averageRating: userRating,
            reviewCount: reviewCount
        )
    }
}

struct ProfileStatsData {
    let listingsCount: Int
    let activeListingsCount: Int
    let averageRating: Double
    let reviewCount: Int
}

// Additional models for UltraModernProfileView2
struct ProfileActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let timeAgo: String
    let color: Color
}

struct ProfileReview: Identifiable {
    let id = UUID()
    let reviewerName: String
    let reviewerImage: String?
    let listingTitle: String
    let rating: Int
    let comment: String
    let date: Date
}