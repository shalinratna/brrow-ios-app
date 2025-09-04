//
//  User.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreData


// MARK: - User Model (Codable for API)
struct User: Codable, Identifiable {
    // Core Identity
    let id: Int
    let apiId: String
    let username: String
    let email: String
    let appleUserId: String?
    
    // Personal Information
    let firstName: String?
    let lastName: String?
    let displayName: String?
    let bio: String?
    let phone: String?
    let location: String?
    let website: String?
    let birthdate: String?
    var profilePicture: String?
    
    // Verification Status
    let verified: Bool
    let emailVerified: Bool?
    let idVerified: Bool?
    let phoneVerified: Bool?
    let idVerification: String?
    let verificationStatus: String?
    
    // Account Status
    let isActive: Bool?
    let isPremium: Bool?
    let hasGreenMembership: Bool?
    let badgeType: String?
    let accountType: String?
    
    // Ratings & Scores
    let trustScore: Int?
    let listerRating: Float?
    let borrowerRating: Float?
    let renteeRating: Float?
    
    // Stripe & Payment
    let stripeLinked: Bool?
    let stripeCustomerId: String?
    let commissionRate: Float?
    
    // Subscription Management
    let subscriptionType: String?
    let subscriptionStatus: String?
    let subscriptionFeatures: [String]?
    let subscriptionExpiresAt: String?
    let maxListings: Int?
    
    // Progress & Gamification
    let currentLevel: Int?
    let userAchievementProgress: [String: String]?
    
    // Username Management
    let lastUsernameChange: Date?
    let usernameChangeCount: Int?
    let previousUsername: String?
    
    // System Fields
    let preferredLanguage: String?
    let referredByCreatorCode: String?
    let insuranceEstimate: String?
    let aiInsights: String?
    let lastActive: String?
    let createdAt: String?
    let updatedAt: String?
    
    // Additional
    let stats: UserStats?
    let isOwnProfile: Bool?
    
    // Coding keys to match API response
    enum CodingKeys: String, CodingKey {
        // Core Identity
        case id
        case apiId = "api_id"
        case username
        case email
        case appleUserId = "apple_user_id"
        
        // Personal Information
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case bio
        case phone
        case location
        case website
        case birthdate
        case profilePicture = "profile_picture"
        
        // Verification Status
        case verified
        case emailVerified = "email_verified"
        case idVerified = "id_verified"
        case phoneVerified = "phone_verified"
        case idVerification = "id_verification"
        case verificationStatus = "verification_status"
        
        // Account Status
        case isActive = "is_active"
        case isPremium = "is_premium"
        case hasGreenMembership = "has_green_membership"
        case badgeType = "badge_type"
        case accountType = "account_type"
        
        // Ratings & Scores
        case trustScore = "trust_score"
        case listerRating = "lister_rating"
        case borrowerRating = "borrower_rating"
        case renteeRating = "rentee_rating"
        
        // Stripe & Payment
        case stripeLinked = "stripe_linked"
        case stripeCustomerId = "stripe_customer_id"
        case commissionRate = "commission_rate"
        
        // Subscription Management
        case subscriptionType = "subscription_type"
        case subscriptionStatus = "subscription_status"
        case subscriptionFeatures = "subscription_features"
        case subscriptionExpiresAt = "subscription_expires_at"
        case maxListings = "max_listings"
        
        // Progress & Gamification
        case currentLevel = "current_level"
        case userAchievementProgress = "user_achievement_progress"
        
        // Username Management
        case lastUsernameChange = "last_username_change"
        case usernameChangeCount = "username_change_count"
        case previousUsername = "previous_username"
        
        // System Fields
        case preferredLanguage = "preferred_language"
        case referredByCreatorCode = "referred_by_creator_code"
        case insuranceEstimate = "insurance_estimate"
        case aiInsights = "ai_insights"
        case lastActive = "last_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
        // Additional
        case stats
        case isOwnProfile = "is_own_profile"
    }
    
    // Custom initializer for creating User instances
    init(id: Int, username: String, email: String, apiId: String? = nil, profilePicture: String? = nil, 
         listerRating: Float? = 0.0, renteeRating: Float? = 0.0, bio: String? = nil,
         emailVerified: Bool = false, idVerified: Bool = false, stripeLinked: Bool = false) {
        self.id = id
        self.username = username
        self.email = email
        self.apiId = apiId ?? "\(id)"
        self.birthdate = nil
        self.profilePicture = profilePicture
        self.idVerification = nil
        self.verified = false
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.listerRating = listerRating
        self.renteeRating = renteeRating
        self.emailVerified = emailVerified
        self.idVerified = idVerified
        self.lastActive = ISO8601DateFormatter().string(from: Date())
        self.stripeLinked = stripeLinked
        self.hasGreenMembership = false
        self.insuranceEstimate = nil
        self.aiInsights = nil
        self.bio = bio
        self.preferredLanguage = "en"
        self.badgeType = nil
        self.accountType = "personal"
        self.referredByCreatorCode = nil
        self.trustScore = nil
        self.location = nil
        self.stats = nil
        self.isOwnProfile = nil
        self.displayName = nil
        self.firstName = nil
        self.lastName = nil
        self.phone = nil
        self.website = nil
        self.lastUsernameChange = nil
        self.usernameChangeCount = 0
        self.previousUsername = nil
        self.appleUserId = nil
        self.phoneVerified = false
        self.verificationStatus = nil
        self.isActive = true
        self.isPremium = false
        self.borrowerRating = 0.0
        self.stripeCustomerId = nil
        self.commissionRate = 0.10
        self.subscriptionType = "free"
        self.subscriptionStatus = "inactive"
        self.subscriptionFeatures = nil
        self.subscriptionExpiresAt = nil
        self.maxListings = 20
        self.currentLevel = 1
        self.userAchievementProgress = nil
        self.updatedAt = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Core Identity
        self.id = try container.decode(Int.self, forKey: .id)
        self.apiId = try container.decode(String.self, forKey: .apiId)
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decode(String.self, forKey: .email)
        self.appleUserId = try container.decodeIfPresent(String.self, forKey: .appleUserId)
        
        // Personal Information
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.website = try container.decodeIfPresent(String.self, forKey: .website)
        self.birthdate = try container.decodeIfPresent(String.self, forKey: .birthdate)
        self.profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
        
        // Verification Status
        self.verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
        self.emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified) ?? false
        self.idVerified = try container.decodeIfPresent(Bool.self, forKey: .idVerified) ?? false
        self.phoneVerified = try container.decodeIfPresent(Bool.self, forKey: .phoneVerified) ?? false
        self.idVerification = try container.decodeIfPresent(String.self, forKey: .idVerification)
        self.verificationStatus = try container.decodeIfPresent(String.self, forKey: .verificationStatus)
        
        // Account Status
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        self.isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        self.hasGreenMembership = try container.decodeIfPresent(Bool.self, forKey: .hasGreenMembership) ?? false
        self.badgeType = try container.decodeIfPresent(String.self, forKey: .badgeType)
        self.accountType = try container.decodeIfPresent(String.self, forKey: .accountType) ?? "personal"
        
        // Ratings & Scores
        self.trustScore = try container.decodeIfPresent(Int.self, forKey: .trustScore) ?? 50
        self.listerRating = try container.decodeIfPresent(Float.self, forKey: .listerRating) ?? 0.0
        self.borrowerRating = try container.decodeIfPresent(Float.self, forKey: .borrowerRating) ?? 0.0
        self.renteeRating = try container.decodeIfPresent(Float.self, forKey: .renteeRating) ?? 0.0
        
        // Stripe & Payment
        self.stripeLinked = try container.decodeIfPresent(Bool.self, forKey: .stripeLinked) ?? false
        self.stripeCustomerId = try container.decodeIfPresent(String.self, forKey: .stripeCustomerId)
        self.commissionRate = try container.decodeIfPresent(Float.self, forKey: .commissionRate) ?? 0.10
        
        // Subscription Management
        self.subscriptionType = try container.decodeIfPresent(String.self, forKey: .subscriptionType) ?? "free"
        self.subscriptionStatus = try container.decodeIfPresent(String.self, forKey: .subscriptionStatus) ?? "inactive"
        self.subscriptionFeatures = try container.decodeIfPresent([String].self, forKey: .subscriptionFeatures)
        self.subscriptionExpiresAt = try container.decodeIfPresent(String.self, forKey: .subscriptionExpiresAt)
        self.maxListings = try container.decodeIfPresent(Int.self, forKey: .maxListings) ?? 20
        
        // Progress & Gamification
        self.currentLevel = try container.decodeIfPresent(Int.self, forKey: .currentLevel) ?? 1
        self.userAchievementProgress = try container.decodeIfPresent([String: String].self, forKey: .userAchievementProgress)
        
        // Username Management
        self.previousUsername = try container.decodeIfPresent(String.self, forKey: .previousUsername)
        self.usernameChangeCount = try container.decodeIfPresent(Int.self, forKey: .usernameChangeCount) ?? 0
        if let lastChangeString = try container.decodeIfPresent(String.self, forKey: .lastUsernameChange) {
            self.lastUsernameChange = ISO8601DateFormatter().date(from: lastChangeString)
        } else {
            self.lastUsernameChange = nil
        }
        
        // System Fields
        self.preferredLanguage = try container.decodeIfPresent(String.self, forKey: .preferredLanguage) ?? "en"
        self.referredByCreatorCode = try container.decodeIfPresent(String.self, forKey: .referredByCreatorCode)
        self.insuranceEstimate = try container.decodeIfPresent(String.self, forKey: .insuranceEstimate)
        self.aiInsights = try container.decodeIfPresent(String.self, forKey: .aiInsights)
        self.lastActive = try container.decodeIfPresent(String.self, forKey: .lastActive)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Additional
        self.stats = try container.decodeIfPresent(UserStats.self, forKey: .stats)
        self.isOwnProfile = try container.decodeIfPresent(Bool.self, forKey: .isOwnProfile)
    }
    
    // Computed properties for display
    var name: String {
        // Use display_name if available, otherwise username
        return displayName ?? username
    }
    
    var isVerified: Bool {
        return verified
    }
    
    var isFullyVerified: Bool {
        return verified && (emailVerified ?? false) && (idVerified ?? false)
    }
    
    var rating: Double {
        // Average of all three ratings
        let ratings = [listerRating, borrowerRating, renteeRating].compactMap { $0 }
        guard !ratings.isEmpty else { return 0.0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
    
    var locationObject: Location {
        // Default location - would come from API
        return Location(
            address: location ?? "San Francisco, CA",
            city: "San Francisco",
            state: "CA",
            zipCode: "94105",
            country: "USA",
            latitude: 37.7749,
            longitude: -122.4194
        )
    }
    
    var memberSince: Date {
        guard let createdAt = createdAt else { return Date() }
        return ISO8601DateFormatter().date(from: createdAt) ?? Date()
    }
    
    // Properties for UI with fallbacks
    var totalListings: Int { return stats?.totalListings ?? 5 }
    var completedRentals: Int { return stats?.itemsBorrowed ?? 12 }
    var responseTime: String { return "2 hours" }
}

// MARK: - Core Data Entity
@objc(UserEntity)
public class UserEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: Int32
    @NSManaged public var username: String
    @NSManaged public var email: String
    @NSManaged public var profilePicture: String?
    @NSManaged public var verified: Bool
    @NSManaged public var apiId: String
    @NSManaged public var listerRating: Float
    @NSManaged public var renteeRating: Float
    @NSManaged public var emailVerified: Bool
    @NSManaged public var isVerified: Bool
    @NSManaged public var idVerified: Bool
    @NSManaged public var lastActive: Date
    @NSManaged public var stripeLinked: Bool
    @NSManaged public var createdAt: Date
    
    // Relationships
    @NSManaged public var listings: NSSet?
    @NSManaged public var seeks: NSSet?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var chatMessages: NSSet?
}

extension UserEntity {
    func toUser() -> User {
        return User(
            id: Int(id),
            username: username,
            email: email,
            apiId: apiId,
            profilePicture: profilePicture
        )
    }
}