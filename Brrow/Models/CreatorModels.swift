import Foundation

// MARK: - Creator Status Response
struct CreatorStatusResponse: Codable {
    let success: Bool
    let isCreator: Bool
    let status: String?           // Backend returns "status" not "creator_status"
    let listingCount: Int?        // Backend returns this
    let tier: String?             // Backend returns this (basic/standard/pro)
    let benefits: CreatorBenefits? // Backend returns benefits object

    // Optional legacy fields for backward compatibility
    let creatorCode: String?
    let totalEarned: Double?
    let totalReferrals: Int?
    let applicationStatus: String?
    let rejectionReason: String?
    let shareLink: String?
    let onboardingStatus: String?

    private enum CodingKeys: String, CodingKey {
        case success
        case isCreator
        case status               // Match backend field name
        case listingCount
        case tier
        case benefits
        case creatorCode = "creator_code"
        case totalEarned = "total_earned"
        case totalReferrals = "total_referrals"
        case applicationStatus = "application_status"
        case rejectionReason = "rejection_reason"
        case shareLink = "share_link"
        case onboardingStatus = "onboarding_status"
    }

    // Computed property for backward compatibility
    var creatorStatus: String? { return status }
}

// MARK: - Creator Application Model
struct CreatorApplication: Codable {
    let id: String
    let userId: String
    let status: CreatorApplicationStatus
    let submittedAt: String
    let reviewedAt: String?
    let rejectionReason: String?
    let adminNotes: String?
    let discordWebhookSent: Bool?

    // Application Content
    let motivation: String
    let experience: String
    let businessName: String?
    let businessDescription: String?
    let experienceYears: Int?
    let portfolioLinks: String?
    let expectedMonthlyRevenue: Double?

    // Legacy fields for backward compatibility
    let platform: String?
    let followers: Int?
    let contentType: String?
    let referralStrategy: String?

    private enum CodingKeys: String, CodingKey {
        case id, status, motivation, experience, platform, followers
        case userId = "user_id"
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
        case rejectionReason = "rejection_reason"
        case adminNotes = "admin_notes"
        case discordWebhookSent = "discord_webhook_sent"
        case businessName = "business_name"
        case businessDescription = "business_description"
        case experienceYears = "experience_years"
        case portfolioLinks = "portfolio_links"
        case expectedMonthlyRevenue = "expected_monthly_revenue"
        case contentType = "content_type"
        case referralStrategy = "referral_strategy"
    }
}

// MARK: - Creator Application Status
enum CreatorApplicationStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case underReview = "UNDER_REVIEW"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending Review"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .underReview:
            return "Under Review"
        }
    }

    var color: String {
        switch self {
        case .pending:
            return "#FFA500" // Orange
        case .approved:
            return "#34C759" // Green
        case .rejected:
            return "#FF3B30" // Red
        case .underReview:
            return "#007AFF" // Blue
        }
    }
}

// MARK: - Creator Application Response
struct CreatorApplicationResponse: Codable {
    let hasApplication: Bool
    let canApply: Bool
    let application: CreatorApplication?
}

// MARK: - Creator Application Submission Request
struct CreatorApplicationRequest: Codable {
    let motivation: String
    let experience: String
    let businessName: String?
    let businessDescription: String?
    let experienceYears: Int?
    let portfolioLinks: String?
    let expectedMonthlyRevenue: Double?
    let platform: String?
    let followers: Int?
    let contentType: String?
    let referralStrategy: String?
    let agreementAccepted: Bool

    private enum CodingKeys: String, CodingKey {
        case motivation, experience, platform, followers
        case businessName = "business_name"
        case businessDescription = "business_description"
        case experienceYears = "experience_years"
        case portfolioLinks = "portfolio_links"
        case expectedMonthlyRevenue = "expected_monthly_revenue"
        case contentType = "content_type"
        case referralStrategy = "referral_strategy"
        case agreementAccepted = "agreement_accepted"
    }
}

// MARK: - Creator Benefits
struct CreatorBenefits: Codable {
    let commissionRate: Double?
    let featuredListings: Int?
    let analyticsAccess: Bool?
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