import Foundation

// MARK: - Creator Status Response
struct CreatorStatusResponse: Codable {
    let success: Bool
    let isCreator: Bool
    let creatorStatus: String?
    let creatorCode: String?
    let totalEarned: Double?
    let totalReferrals: Int?
    let applicationStatus: String?
    let rejectionReason: String?
    let shareLink: String?
    let onboardingStatus: String?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case isCreator = "is_creator"
        case creatorStatus = "creator_status"
        case creatorCode = "creator_code"
        case totalEarned = "total_earned"
        case totalReferrals = "total_referrals"
        case applicationStatus = "application_status"
        case rejectionReason = "rejection_reason"
        case shareLink = "share_link"
        case onboardingStatus = "onboarding_status"
    }
}

// MARK: - Creator Badge Type
enum CreatorBadgeType: String {
    case creator = "creator"
    case verified = "verified"
    case business = "business"
    case none = "none"
    
    var icon: String {
        switch self {
        case .creator:
            return "star.circle.fill"
        case .verified:
            return "checkmark.seal.fill"
        case .business:
            return "briefcase.circle.fill"
        case .none:
            return ""
        }
    }
    
    var color: String {
        switch self {
        case .creator:
            return "#FFD700" // Gold
        case .verified:
            return "#007AFF" // Blue
        case .business:
            return "#34C759" // Green
        case .none:
            return "#000000"
        }
    }
}