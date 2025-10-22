//
//  User.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import Foundation
import CoreData

// Helper for dynamic coding keys
struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}


// MARK: - User Model (Codable for API)
struct User: Codable, Identifiable {
    // Core Identity
    let id: String  // Changed from Int to String to match backend response
    let apiId: String?
    let username: String
    let email: String?  // Optional: only available for own profile
    let appleUserId: String?
    let authMethod: String?
    
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
    let verified: Bool?  // Made optional since backend might not always send it
    let isVerified: Bool?  // Backend sends this as "isVerified"
    let emailVerified: Bool?
    let idVerified: Bool?
    let phoneVerified: Bool?
    let idVerification: String?
    let verificationStatus: String?
    let hasPassword: Bool?  // NEW: Check if user has password set (for Create Password vs Change Password button)
    let hasBlueCheckmark: Bool?  // NEW: True only when BOTH email AND ID are verified (Stripe Identity)
    
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

    // Profile Statistics
    let activeListings: Int?
    let totalReviews: Int?
    let activeRentals: Int?
    let offersMade: Int?
    
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
        case authMethod = "auth_method"
        
        // Personal Information
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case bio
        case phone
        case location
        case website
        case birthdate
        case profilePicture  // Encodes as "profilePicture" for backend
        case profilePictureUrl = "profile_picture_url"  // Decodes from backend response
        
        // Verification Status
        case verified
        case isVerified = "isVerified"  // Backend sends camelCase
        case emailVerified = "emailVerified"  // FIXED: Backend sends camelCase (not email_verified)
        case idVerified = "idVerified"  // FIXED: Backend sends camelCase (not id_verified)
        case phoneVerified = "phone_verified"
        case idVerification = "id_verification"
        case verificationStatus = "verification_status"
        case hasPassword = "hasPassword"  // Backend sends camelCase
        case hasBlueCheckmark = "hasBlueCheckmark"  // Backend sends camelCase - requires BOTH email + ID verified
        
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

        // Profile Statistics
        case activeListings = "active_listings"
        case totalReviews = "total_reviews"
        case activeRentals = "active_rentals"
        case offersMade = "offers_made"
        
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
    init(id: String, username: String, email: String? = nil, apiId: String? = nil, profilePicture: String? = nil,
         listerRating: Float? = 0.0, renteeRating: Float? = 0.0, bio: String? = nil,
         emailVerified: Bool = false, idVerified: Bool = false, stripeLinked: Bool = false) {
        self.id = id
        self.username = username
        self.email = email  // Optional: may be nil for other users' profiles
        self.apiId = apiId ?? id
        self.birthdate = nil
        self.profilePicture = profilePicture
        self.idVerification = nil
        self.verified = false
        self.isVerified = false
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.listerRating = listerRating
        self.renteeRating = renteeRating
        self.emailVerified = emailVerified
        self.idVerified = idVerified
        self.hasPassword = nil  // NEW: Default to nil for placeholder users
        self.hasBlueCheckmark = emailVerified && idVerified  // Computed: requires BOTH email + ID verified
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
        self.authMethod = nil
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
        self.activeListings = 0
        self.totalReviews = 0
        self.activeRentals = 0
        self.offersMade = 0
        self.updatedAt = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // CRITICAL DEBUG: Print raw JSON values being decoded
        print("🔍 [User Decoder] === DECODING USER ===")

        // Core Identity - Try multiple field names for ID
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = idString
            print("🔍 [User Decoder] Decoded id (String): '\(idString)'")
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
            print("🔍 [User Decoder] Decoded id (Int): \(idInt) -> '\(String(idInt))'")
        } else {
            // Fallback to a default if all else fails
            self.id = "unknown"
            print("🔍 [User Decoder] ⚠️ No id field found, using 'unknown'")
        }

        // API ID - Try multiple field names and ensure it's not nil
        if let apiIdValue = try container.decodeIfPresent(String.self, forKey: .apiId) {
            self.apiId = apiIdValue
            print("🔍 [User Decoder] Decoded apiId (String): '\(apiIdValue)'")
        } else {
            do {
                if let apiIdInt = try container.decodeIfPresent(Int.self, forKey: .apiId) {
                    self.apiId = String(apiIdInt)
                    print("🔍 [User Decoder] Decoded apiId (Int): \(apiIdInt) -> '\(String(apiIdInt))'")
                } else {
                    // Fallback: use the main id if apiId is missing
                    print("🔍 [User Decoder] ⚠️ WARNING: apiId not found in response, using id as fallback")
                    print("🔍 [User Decoder] Falling back: apiId = id = '\(self.id)'")
                    self.apiId = self.id
                }
            } catch {
                // Fallback: use the main id if apiId is missing
                print("🔍 [User Decoder] ⚠️ WARNING: apiId decode error, using id as fallback")
                print("🔍 [User Decoder] Error: \(error)")
                print("🔍 [User Decoder] Falling back: apiId = id = '\(self.id)'")
                self.apiId = self.id
            }
        }

        print("🔍 [User Decoder] FINAL VALUES: id = '\(self.id)', apiId = '\(self.apiId ?? "nil")'")
        print("🔍 [User Decoder] === END DECODING ===\n")
        
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)  // Optional: not returned for other users' profiles
        self.appleUserId = try container.decodeIfPresent(String.self, forKey: .appleUserId)
        self.authMethod = try container.decodeIfPresent(String.self, forKey: .authMethod)
        
        // Personal Information
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.website = try container.decodeIfPresent(String.self, forKey: .website)
        self.birthdate = try container.decodeIfPresent(String.self, forKey: .birthdate)
        // Try to decode from profile_picture_url (backend sends this) or profilePicture (fallback)
        if let profilePictureUrl = try container.decodeIfPresent(String.self, forKey: .profilePictureUrl) {
            self.profilePicture = profilePictureUrl
        } else {
            self.profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
        }
        
        // Verification Status
        self.verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
        self.isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        self.emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified) ?? false
        self.idVerified = try container.decodeIfPresent(Bool.self, forKey: .idVerified) ?? false
        self.phoneVerified = try container.decodeIfPresent(Bool.self, forKey: .phoneVerified) ?? false
        self.idVerification = try container.decodeIfPresent(String.self, forKey: .idVerification)
        self.verificationStatus = try container.decodeIfPresent(String.self, forKey: .verificationStatus)
        self.hasPassword = try container.decodeIfPresent(Bool.self, forKey: .hasPassword)
        self.hasBlueCheckmark = try container.decodeIfPresent(Bool.self, forKey: .hasBlueCheckmark) ?? false
        
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

        // Profile Statistics
        self.activeListings = try container.decodeIfPresent(Int.self, forKey: .activeListings) ?? 0
        self.totalReviews = try container.decodeIfPresent(Int.self, forKey: .totalReviews) ?? 0
        self.activeRentals = try container.decodeIfPresent(Int.self, forKey: .activeRentals) ?? 0
        self.offersMade = try container.decodeIfPresent(Int.self, forKey: .offersMade) ?? 0
        
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

    // Custom encode to ensure profilePicture is sent as "profilePicture", not "profile_picture_url"
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Only encode non-nil values
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(apiId, forKey: .apiId)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)  // Optional: may be nil for other users
        try container.encodeIfPresent(appleUserId, forKey: .appleUserId)
        try container.encodeIfPresent(authMethod, forKey: .authMethod)

        // Personal Information
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(birthdate, forKey: .birthdate)
        // Encode as "profilePicture" (what backend expects)
        try container.encodeIfPresent(profilePicture, forKey: .profilePicture)

        // Note: We don't encode all other fields as they're typically only decoded from backend
        // If needed, add more fields here
    }

    // Computed properties for display
    var name: String {
        // Use display_name if available, otherwise username
        return displayName ?? username
    }
    
    var isUserVerified: Bool {
        return isVerified ?? verified ?? false
    }
    
    var isFullyVerified: Bool {
        return (verified ?? false) && (emailVerified ?? false) && (idVerified ?? false)
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
    var totalListings: Int { return activeListings ?? stats?.totalListings ?? 0 }
    var completedRentals: Int { return activeRentals ?? stats?.itemsBorrowed ?? 0 }
    var responseTime: String { return "Usually responds within a few hours" }
    
    // Helper method to get the full profile picture URL
    var fullProfilePictureURL: String? {
        guard let profilePictureString = profilePicture else { return nil }

        // SECURITY: Only allow profile pictures from our platform domains
        // Reject external URLs (Google, Facebook, etc.)
        if profilePictureString.hasPrefix("http://") || profilePictureString.hasPrefix("https://") {
            let allowedDomains = [
                "brrow-backend-nodejs-production.up.railway.app",
                "brrowapp.com",
                "api.brrowapp.com",
                "res.cloudinary.com" // For uploaded images via Cloudinary
            ]

            // Check if URL is from an allowed domain
            for domain in allowedDomains {
                if profilePictureString.contains(domain) {
                    return profilePictureString
                }
            }

            // Reject external URLs (Google, Facebook, etc.)
            print("🚫 Rejected external profile picture URL: \(profilePictureString)")
            return nil
        }
        
        // If it's a relative path starting with /uploads/, prepend base URL
        if profilePictureString.hasPrefix("/uploads/") || profilePictureString.hasPrefix("uploads/") {
            let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
            let formattedPath = profilePictureString.hasPrefix("/") ? profilePictureString : "/\(profilePictureString)"
            return "\(baseURL)\(formattedPath)"
        }
        
        // For other relative paths, assume they need the base URL
        let baseURL = "https://brrow-backend-nodejs-production.up.railway.app"
        return "\(baseURL)/\(profilePictureString)"
    }

    // MARK: - Static Methods
    static func placeholder() -> User {
        return User(
            id: "placeholder",
            username: "Loading...",
            email: "placeholder@example.com",
            apiId: "placeholder",
            profilePicture: nil,
            listerRating: 0.0,
            renteeRating: 0.0,
            bio: nil,
            emailVerified: false,
            idVerified: false,
            stripeLinked: false
        )
    }
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
            id: String(id),  // CoreData id is Int16, convert to String
            username: username,
            email: email,
            apiId: apiId,
            profilePicture: profilePicture
        )
    }
}
