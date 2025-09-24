import Foundation
import SwiftUI

@MainActor
class CreatorDashboardViewModel: ObservableObject {
    @Published var dashboard: LegacyCreatorDashboard?
    @Published var isLoading = false
    @Published var error: String?

    func loadDashboard() async {
        isLoading = true
        error = nil

        do {
            dashboard = try await APIClient.shared.getCreatorDashboard()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

@MainActor
class StripeOnboardingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    func startOnboarding() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await APIClient.shared.startCreatorStripeOnboarding()
            
            if let url = URL(string: response.onboardingUrl) {
                await UIApplication.shared.open(url)
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Data Models

struct LegacyCreatorDashboard: Codable {
    let success: Bool
    let creator: CreatorInfo
    let stats: CreatorStats
    let shareLink: String
    let monthlyEarnings: [CreatorMonthlyEarning]
    let recentCommissions: [CreatorCommission]

    private enum CodingKeys: String, CodingKey {
        case success
        case creator
        case stats
        case shareLink = "share_link"
        case monthlyEarnings = "monthly_earnings"
        case recentCommissions = "recent_commissions"
    }
}

struct CreatorInfo: Codable {
    let creatorCode: String
    let status: String
    let username: String
    let email: String
    let profilePicture: String?
    let stripeConnected: Bool
    let onboardingStatus: String?
    let createdAt: String
    
    private enum CodingKeys: String, CodingKey {
        case creatorCode = "creator_code"
        case status
        case username
        case email
        case profilePicture = "profile_picture"
        case stripeConnected = "stripe_connected"
        case onboardingStatus = "onboarding_status"
        case createdAt = "created_at"
    }
}

struct CreatorStats: Codable {
    let totalReferrals: Int
    let totalEarned: Double
    let pendingEarnings: Double
    let totalTransactions: Int
    let averageCommission: Double
    
    private enum CodingKeys: String, CodingKey {
        case totalReferrals = "total_referrals"
        case totalEarned = "total_earned"
        case pendingEarnings = "pending_earnings"
        case totalTransactions = "total_transactions"
        case averageCommission = "average_commission"
    }
}

struct CreatorMonthlyEarning: Codable, Identifiable {
    let month: String
    let earnings: Double
    
    var id: String { month }
}

struct CreatorCommission: Codable, Identifiable {
    let id: Int
    let commissionAmount: Double
    let transactionAmount: Double
    let paymentStatus: String
    let buyerUsername: String
    let listingTitle: String?
    let createdAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case commissionAmount = "commission_amount"
        case transactionAmount = "transaction_amount"
        case paymentStatus = "payment_status"
        case buyerUsername = "buyer_username"
        case listingTitle = "listing_title"
        case createdAt = "created_at"
    }
}

struct CreatorStripeOnboardingResponse: Codable {
    let success: Bool
    let onboardingUrl: String
    let message: String
    let alreadyConnected: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case onboardingUrl = "onboarding_url"
        case message
        case alreadyConnected = "already_connected"
    }
}