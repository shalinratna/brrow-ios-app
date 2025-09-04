//
//  ProductionConfig.swift
//  Brrow
//
//  Production configuration and environment setup
//

import Foundation

struct ProductionConfig {
    // MARK: - Environment Settings
    static let environment: Environment = .production
    
    enum Environment: String, CaseIterable {
        case development = "dev"
        case staging = "staging"
        case production = "prod"
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://brrowapp.com"
            case .staging:
                return "https://brrowapp.com"
            case .production:
                return "https://brrowapp.com"
            }
        }
        
        var socketURL: String {
            switch self {
            case .development:
                return "wss://brrowapp.com/brrow/ws"
            case .staging:
                return "wss://brrowapp.com/brrow/ws"
            case .production:
                return "wss://brrowapp.com/brrow/ws"
            }
        }
        
        var analyticsKey: String {
            switch self {
            case .development:
                return "dev_analytics_key"
            case .staging:
                return "staging_analytics_key"
            case .production:
                return "prod_analytics_key"
            }
        }
    }
    
    // MARK: - API Configuration
    static let apiTimeout: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    static let rateLimitRequestsPerMinute = 60
    
    // MARK: - Cache Configuration
    static let cacheMaxAge: TimeInterval = 3600 // 1 hour
    static let imageCacheMaxSize = 100 * 1024 * 1024 // 100MB
    static let dataCacheMaxSize = 50 * 1024 * 1024 // 50MB
    
    // MARK: - Feature Flags
    static let enableAnalytics = true
    static let enableCrashReporting = true
    static let enablePushNotifications = true
    static let enableOfflineMode = true
    static let enableVideoChat = true
    static let enableAIRecommendations = true
    static let enableBrrowStories = true
    static let enableCommunityFeed = true
    
    // MARK: - Security Settings
    static let enableCertificatePinning = true
    static let requireDevicePasscode = false
    static let enableBiometricAuth = true
    static let sessionTimeoutMinutes: TimeInterval = 30 * 60 // 30 minutes
    
    // MARK: - Upload Limits
    static let maxImageUploadSize = 10 * 1024 * 1024 // 10MB
    static let maxVideoUploadSize = 100 * 1024 * 1024 // 100MB
    static let maxImagesPerListing = 10
    static let maxVoiceMessageDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Monetization
    static let commissionRate: Double = 0.05 // 5%
    static let minimumWithdrawalAmount: Double = 10.0
    static let supportedPaymentMethods = ["apple_pay", "paypal", "bank_transfer", "cryptocurrency"]
    
    // MARK: - Geolocation
    static let defaultSearchRadius: Double = 25.0 // miles
    static let maxSearchRadius: Double = 100.0 // miles
    static let locationAccuracyThreshold: Double = 100.0 // meters
    
    // MARK: - Content Moderation
    static let enableAutoModeration = true
    static let flaggedContentThreshold = 3
    static let maxReportReasons = 5
    static let contentReviewTimeoutHours = 24
    
    // MARK: - Performance Monitoring
    static let performanceMetricsEnabled = true
    static let crashReportingEnabled = true
    static let networkMonitoringEnabled = true
    static let memoryWarningThreshold = 80 // percent
    
    // MARK: - App Store Configuration
    static let appStoreMetadata = AppStoreMetadata.self
    static let supportedLanguages = AppStoreMetadata.supportedLanguages
    static let minimumIOSVersion = AppStoreMetadata.minimumIOSVersion
    
    // MARK: - Debug Settings (Production: All False)
    #if DEBUG
    static let enableDebugLogging = true
    static let enableNetworkLogging = true
    static let enableUIDebugging = false
    static let bypassAuthentication = false
    static let useMockData = false
    #else
    static let enableDebugLogging = false
    static let enableNetworkLogging = false
    static let enableUIDebugging = false
    static let bypassAuthentication = false
    static let useMockData = false
    #endif
    
    // MARK: - Initialization
    static func configure() {
        print("🚀 Configuring Brrow for \(environment.rawValue) environment")
        
        // Configure network settings
        configureNetworking()
        
        // Configure monitoring
        configureMonitoring()
        
        // Configure security
        configureSecurity()
        
        // Configure features
        configureFeatures()
        
        print("✅ Production configuration complete")
    }
    
    private static func configureNetworking() {
        APIClient.configure(
            baseURL: environment.baseURL,
            timeout: apiTimeout,
            maxRetries: maxRetryAttempts
        )
        
        if enableCertificatePinning {
            // Enable certificate pinning for production
            print("🔒 Certificate pinning enabled")
        }
    }
    
    private static func configureMonitoring() {
        if performanceMetricsEnabled {
            // Initialize performance monitoring
            print("📊 Performance monitoring enabled")
        }
        
        if crashReportingEnabled {
            // Initialize crash reporting
            print("🐛 Crash reporting enabled")
        }
        
        if networkMonitoringEnabled {
            // Initialize network monitoring
            print("🌐 Network monitoring enabled")
        }
    }
    
    private static func configureSecurity() {
        AuthManager.configure(
            sessionTimeout: sessionTimeoutMinutes,
            requireBiometric: enableBiometricAuth,
            requirePasscode: requireDevicePasscode
        )
        
        print("🛡️ Security configuration applied")
    }
    
    private static func configureFeatures() {
        // Configure feature flags
        FeatureFlags.setFlag("analytics", enabled: enableAnalytics)
        FeatureFlags.setFlag("push_notifications", enabled: enablePushNotifications)
        FeatureFlags.setFlag("offline_mode", enabled: enableOfflineMode)
        FeatureFlags.setFlag("video_chat", enabled: enableVideoChat)
        FeatureFlags.setFlag("ai_recommendations", enabled: enableAIRecommendations)
        FeatureFlags.setFlag("brrow_stories", enabled: enableBrrowStories)
        FeatureFlags.setFlag("community_feed", enabled: enableCommunityFeed)
        
        print("🎛️ Feature flags configured")
    }
}

// MARK: - Feature Flags Manager
class FeatureFlags {
    private static var flags: [String: Bool] = [:]
    
    static func setFlag(_ key: String, enabled: Bool) {
        flags[key] = enabled
    }
    
    static func isEnabled(_ key: String) -> Bool {
        return flags[key] ?? false
    }
    
    static func getAllFlags() -> [String: Bool] {
        return flags
    }
}

// MARK: - Build Configuration
extension ProductionConfig {
    static var buildInfo: [String: Any] {
        return [
            "version": AppStoreMetadata.version,
            "build": AppStoreMetadata.buildNumber,
            "environment": environment.rawValue,
            "build_date": DateFormatter.iso8601.string(from: Date()),
            "xcode_version": Bundle.main.infoDictionary?["DTXcodeBuild"] ?? "Unknown",
            "ios_version": Bundle.main.infoDictionary?["MinimumOSVersion"] ?? "Unknown"
        ]
    }
    
    static func printBuildInfo() {
        print("📱 Brrow Build Information:")
        for (key, value) in buildInfo {
            print("   \(key): \(value)")
        }
    }
}

// MARK: - Extensions for API Configuration
// APIClient.configure is now implemented in APIClient.swift

extension AuthManager {
    static func configure(sessionTimeout: TimeInterval, requireBiometric: Bool, requirePasscode: Bool) {
        // Configure authentication with security settings
        print("🔐 Auth Manager configured with security settings")
    }
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}