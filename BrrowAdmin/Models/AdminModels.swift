//
//  AdminModels.swift
//  BrrowAdmin
//
//  Data models for all admin API responses
//

import Foundation

// MARK: - Authentication
struct AdminLoginResponse: Codable {
    let success: Bool
    let token: String
    let admin: AdminUser
}

struct AdminUser: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let role: AdminRole
    let permissions: [String]?
    let isActive: Bool
    let isSuperAdmin: Bool
    let lastLoginAt: Date?
    let createdAt: Date
}

enum AdminRole: String, Codable {
    case superAdmin = "SUPER_ADMIN"
    case admin = "ADMIN"
    case moderator = "MODERATOR"
    case support = "SUPPORT"
    case analyst = "ANALYST"
    case readOnly = "READ_ONLY"
}

// MARK: - Dashboard
struct DashboardStats: Codable {
    let totalUsers: Int
    let activeUsers: Int
    let totalListings: Int
    let activeListings: Int
    let pendingListings: Int
    let totalRevenue: Double
    let revenueToday: Double
    let transactionsToday: Int
    let newUsersToday: Int
    let flaggedListings: Int
    let openReports: Int
}

struct ActivityLog: Codable, Identifiable {
    let id: String
    let adminUserId: String
    let action: String
    let resourceType: String
    let resourceId: String?
    let details: String
    let severity: LogSeverity
    let createdAt: Date
    let adminEmail: String?
}

enum LogSeverity: String, Codable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

struct RealtimeMetrics: Codable {
    let activeUsers: Int
    let ongoingTransactions: Int
    let serverLoad: Double
    let apiResponseTime: Double
    let errorRate: Double
}

// MARK: - User Management
struct UsersResponse: Codable {
    let success: Bool
    let data: [AdminUserDetail]
    let pagination: PaginationInfo
}

struct AdminUserDetail: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let phoneNumber: String?
    let profileImageUrl: String?
    let isVerified: Bool
    let isBanned: Bool
    let isSuspended: Bool
    let suspensionReason: String?
    let suspensionExpiresAt: Date?
    let banReason: String?
    let moderationNotes: String?
    let createdAt: Date
    let lastLoginAt: Date?
    let listingsCount: Int?
    let transactionsCount: Int?
    let totalRevenue: Double?
}

struct UserFilters: Encodable {
    var verified: Bool?
    var banned: Bool?
    var suspended: Bool?
    var flagged: Bool?
}

struct CreateUserRequest: Encodable {
    let email: String
    let fullName: String
    let password: String
    let phoneNumber: String?
}

struct UpdateUserRequest: Encodable {
    var fullName: String?
    var email: String?
    var phoneNumber: String?
    var isVerified: Bool?
    var moderationNotes: String?
}

// MARK: - Listing Management
struct ListingsResponse: Codable {
    let success: Bool
    let data: [AdminListingDetail]
    let pagination: PaginationInfo
}

struct AdminListingDetail: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let price: Double
    let categoryId: String
    let userId: String
    let userName: String?
    let userEmail: String?
    let status: ListingStatus
    let moderationStatus: ModerationStatus?
    let isFlagged: Bool
    let flagReason: String?
    let flaggedAt: Date?
    let reviewedByAdmin: String?
    let reviewedAt: Date?
    let moderationNotes: String?
    let imageUrls: [String]?
    let viewsCount: Int?
    let createdAt: Date
    let updatedAt: Date
}

enum ListingStatus: String, Codable {
    case upcoming = "UPCOMING"
    case available = "AVAILABLE"
    case sold = "SOLD"
    case removed = "REMOVED"
}

enum ModerationStatus: String, Codable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case flagged = "FLAGGED"
    case removed = "REMOVED"
}

struct UpdateListingRequest: Encodable {
    var title: String?
    var description: String?
    var price: Double?
    var moderationStatus: String?
    var moderationNotes: String?
}

// MARK: - Transactions
struct TransactionsResponse: Codable {
    let success: Bool
    let data: [AdminTransactionDetail]
    let pagination: PaginationInfo
}

struct AdminTransactionDetail: Codable, Identifiable {
    let id: String
    let listingId: String
    let listingTitle: String?
    let buyerId: String
    let buyerEmail: String?
    let sellerId: String
    let sellerEmail: String?
    let amount: Double
    let platformFee: Double
    let netAmount: Double
    let status: TransactionStatus
    let paymentIntentId: String?
    let refundedAmount: Double?
    let refundReason: String?
    let createdAt: Date
    let completedAt: Date?
}

enum TransactionStatus: String, Codable {
    case pending = "PENDING"
    case completed = "COMPLETED"
    case refunded = "REFUNDED"
    case failed = "FAILED"
}

struct RefundResponse: Codable {
    let success: Bool
    let refund: RefundDetail
}

struct RefundDetail: Codable {
    let id: String
    let amount: Double
    let status: String
}

struct RevenueAnalytics: Codable {
    let totalRevenue: Double
    let platformFees: Double
    let refundedAmount: Double
    let netRevenue: Double
    let transactionCount: Int
    let averageTransactionValue: Double
    let dailyBreakdown: [DailyRevenue]
}

struct DailyRevenue: Codable {
    let date: String
    let revenue: Double
    let transactions: Int
}

// MARK: - Reports
struct ReportsResponse: Codable {
    let success: Bool
    let data: [ReportDetail]
    let pagination: PaginationInfo
}

struct ReportDetail: Codable, Identifiable {
    let id: String
    let reportType: String
    let reportedUserId: String?
    let reportedUserEmail: String?
    let reportedListingId: String?
    let reportedListingTitle: String?
    let reporterId: String
    let reporterEmail: String?
    let reason: String
    let description: String?
    let status: ReportStatus
    let priority: Priority
    let assignedTo: String?
    let assignedToEmail: String?
    let actionTaken: String?
    let notes: String?
    let createdAt: Date
    let resolvedAt: Date?
}

enum ReportStatus: String, Codable {
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case resolved = "RESOLVED"
    case dismissed = "DISMISSED"
}

enum Priority: String, Codable {
    case low = "LOW"
    case normal = "NORMAL"
    case high = "HIGH"
    case urgent = "URGENT"
}

// MARK: - Fraud Alerts
struct FraudAlertsResponse: Codable {
    let success: Bool
    let data: [FraudAlert]
    let pagination: PaginationInfo
}

struct FraudAlert: Codable, Identifiable {
    let id: String
    let userId: String
    let userEmail: String?
    let alertType: String
    let riskScore: Double
    let reason: String
    let details: [String: String]?
    let status: String
    let reviewedBy: String?
    let reviewAction: String?
    let reviewNotes: String?
    let createdAt: Date
    let reviewedAt: Date?
}

// MARK: - Analytics
struct UserGrowthMetrics: Codable {
    let totalUsers: Int
    let newUsers: Int
    let activeUsers: Int
    let growthRate: Double
    let dailySignups: [DailySignup]
}

struct DailySignup: Codable {
    let date: String
    let count: Int
}

struct ListingPerformanceMetrics: Codable {
    let totalListings: Int
    let newListings: Int
    let soldListings: Int
    let averageTimeToSell: Double
    let conversionRate: Double
}

struct PlatformHealthMetrics: Codable {
    let uptime: Double
    let apiResponseTime: Double
    let errorRate: Double
    let activeConnections: Int
    let databaseLoad: Double
}

// MARK: - Announcements
struct Announcement: Codable, Identifiable {
    let id: String
    let type: AnnouncementType
    let priority: Priority
    let title: String
    let message: String
    let targetAudience: String
    let isActive: Bool
    let publishedAt: Date?
    let expiresAt: Date?
    let createdBy: String
    let createdAt: Date
}

enum AnnouncementType: String, Codable {
    case info = "INFO"
    case warning = "WARNING"
    case maintenance = "MAINTENANCE"
    case feature = "FEATURE"
    case promotion = "PROMOTION"
    case security = "SECURITY"
}

struct CreateAnnouncementRequest: Encodable {
    let type: String
    let priority: String
    let title: String
    let message: String
    let targetAudience: String
    let publishedAt: Date?
    let expiresAt: Date?
}

struct UpdateAnnouncementRequest: Encodable {
    var title: String?
    var message: String?
    var isActive: Bool?
    var expiresAt: Date?
}

// MARK: - Settings
struct AdminSetting: Codable, Identifiable {
    let id: String
    let key: String
    let value: AnyCodable
    let category: String
    let description: String?
    let dataType: String
    let isPublic: Bool
    let updatedAt: Date
    let updatedBy: String?
}

struct SettingHistory: Codable, Identifiable {
    let id: String
    let settingKey: String
    let oldValue: AnyCodable?
    let newValue: AnyCodable
    let changedBy: String
    let changeReason: String?
    let changedAt: Date
}

// MARK: - Audit Logs
struct AuditLogsResponse: Codable {
    let success: Bool
    let data: [ActivityLog]
    let pagination: PaginationInfo
}

// MARK: - Common
struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
}

struct BulkActionResponse: Codable {
    let success: Bool
    let successCount: Int
    let failureCount: Int
    let errors: [String]?
}

struct ResetPasswordResponse: Codable {
    let success: Bool
    let temporaryPassword: String
}

// MARK: - AnyCodable for dynamic JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictionaryValue as [String: Any]:
            try container.encode(dictionaryValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
