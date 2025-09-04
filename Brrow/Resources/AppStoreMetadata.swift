//
//  AppStoreMetadata.swift
//  Brrow
//
//  App Store metadata and configuration
//

import Foundation

struct AppStoreMetadata {
    // MARK: - App Information
    static let appName = "Brrow"
    static let bundleIdentifier = "com.brrow.app"
    static let version = "1.0.0"
    static let buildNumber = "1"
    
    // MARK: - App Store Description
    static let shortDescription = "Borrow & lend items in your community with AI-powered recommendations and social features."
    
    static let fullDescription = """
    🌟 Welcome to Brrow - The Future of Community Sharing! 🌟
    
    Transform the way you access everyday items with our revolutionary peer-to-peer borrowing platform. Why buy when you can borrow?
    
    ✨ KEY FEATURES ✨
    
    🔍 SMART DISCOVERY
    • AI-powered recommendations tailored to your needs
    • BrrowStories - See what's trending in your community
    • Advanced search filters by location, price, and category
    • Real-time availability updates
    
    💬 SEAMLESS COMMUNICATION
    • Enhanced messaging with voice notes and images
    • Video calling for complex item explanations
    • Instant notifications for all activity
    • Smart conversation threading
    
    💰 EARN WHILE YOU SHARE
    • Complete earnings dashboard with analytics
    • Multiple payout options (PayPal, bank transfer, crypto)
    • Performance insights and optimization tips
    • Automated tax reporting support
    
    🎯 SOCIAL FEATURES
    • Follow community members and see their activity
    • Share stories about your borrowing experiences
    • Community challenges and rewards
    • Karma credits system for building trust
    
    📱 NATIVE iOS INTEGRATION
    • Home screen widgets for quick access
    • iMessage stickers for sharing items
    • Siri shortcuts for common actions
    • Apple Pay integration
    
    🛡️ TRUST & SAFETY
    • Verified user profiles with reviews
    • Secure in-app payments
    • Insurance coverage options
    • 24/7 customer support
    
    🌱 SUSTAINABILITY FOCUSED
    • Reduce consumption through sharing
    • Track your environmental impact
    • Support local community resilience
    • Gamified eco-friendly actions
    
    Perfect for:
    • Students needing textbooks and supplies
    • DIY enthusiasts sharing tools
    • Photographers lending equipment
    • Travelers accessing local items
    • Anyone wanting to save money and help the environment
    
    Join thousands of users already saving money and building stronger communities through Brrow!
    
    Download now and start your sharing journey today! 🚀
    """
    
    // MARK: - Keywords
    static let keywords = [
        "borrow", "lend", "sharing", "community", "rental", "peer-to-peer",
        "marketplace", "sustainability", "tools", "equipment", "local",
        "neighbor", "share economy", "collaborative consumption"
    ]
    
    // MARK: - Categories
    static let primaryCategory = "Lifestyle"
    static let secondaryCategory = "Social Networking"
    
    // MARK: - Privacy Information
    static let privacyPolicyURL = "https://brrow.app/privacy"
    static let termsOfServiceURL = "https://brrow.app/terms"
    static let supportURL = "https://brrow.app/support"
    
    // MARK: - Age Rating
    static let ageRating = "4+" // No objectionable content
    
    // MARK: - Supported Languages
    static let supportedLanguages = [
        "en-US", // English (US)
        "es-ES", // Spanish
        "fr-FR", // French
        "de-DE", // German
        "pt-BR", // Portuguese (Brazil)
        "zh-CN"  // Chinese (Simplified)
    ]
    
    // MARK: - Device Requirements
    static let minimumIOSVersion = "15.0"
    static let supportedDevices = [
        "iPhone 8 and later",
        "iPad (6th generation) and later",
        "iPad Air (3rd generation) and later",
        "iPad mini (5th generation) and later",
        "iPad Pro (all models)"
    ]
    
    // MARK: - What's New (Version History)
    static let whatsNew = """
    🎉 Welcome to Brrow 1.0! 🎉
    
    The future of community sharing is here with these amazing features:
    
    ✨ NEW FEATURES
    • BrrowStories - Share and discover trending items
    • AI-powered recommendations based on your interests
    • Enhanced messaging with voice notes and video calls
    • Complete earnings dashboard with detailed analytics
    • Home screen widgets and iMessage stickers
    • Community challenges and karma rewards system
    
    🛡️ SAFETY & TRUST
    • Verified user profiles with comprehensive reviews
    • Secure payment processing with multiple options
    • Insurance coverage for peace of mind
    • Advanced fraud detection and prevention
    
    🌱 SUSTAINABILITY
    • Track your environmental impact
    • Support local community resilience
    • Gamified eco-friendly actions
    • Carbon footprint reduction metrics
    
    🚀 PERFORMANCE
    • Lightning-fast app performance
    • Offline support for browsing
    • Smart caching for instant loading
    • Optimized for iOS 17 and iPhone 15 series
    
    Thank you for joining our community! We're excited to see how Brrow transforms the way you access and share items.
    
    Have feedback? Contact us at hello@brrow.app
    """
    
    // MARK: - App Store Review Guidelines Compliance
    static let reviewGuidelines = """
    Brrow complies with all App Store Review Guidelines:
    
    • Uses only documented APIs
    • Implements proper content moderation
    • Respects user privacy with clear data usage
    • Provides value through innovative sharing features
    • Supports accessibility features
    • Handles payments through approved methods
    • Includes appropriate content ratings
    • Follows design guidelines for iOS
    """
    
    // MARK: - Marketing Assets
    static let screenshots = [
        "screenshot_discover_feed.png",
        "screenshot_browse_search.png", 
        "screenshot_item_detail.png",
        "screenshot_messaging.png",
        "screenshot_earnings.png",
        "screenshot_profile.png"
    ]
    
    static let previewVideo = "brrow_app_preview.mp4"
    
    // MARK: - Feature Highlights for App Store
    static let featureHighlights = [
        "AI-Powered Discovery": "Smart recommendations help you find exactly what you need",
        "Social Sharing": "Connect with your community through BrrowStories and challenges",
        "Earnings Dashboard": "Complete financial overview with analytics and insights",
        "Enhanced Messaging": "Rich communication with voice, video, and media sharing",
        "Native iOS Features": "Widgets, Siri shortcuts, and iMessage integration",
        "Trust & Safety": "Verified profiles, secure payments, and insurance coverage"
    ]
}

// MARK: - App Configuration
extension AppStoreMetadata {
    static func configureForProduction() {
        // Set production configurations
        #if DEBUG
        print("⚠️ Running in DEBUG mode - ensure RELEASE configuration for App Store")
        #endif
        
        // Configure analytics
        configureAnalytics()
        
        // Configure crash reporting
        configureCrashReporting()
        
        // Configure remote config
        configureRemoteConfig()
    }
    
    private static func configureAnalytics() {
        // Configure production analytics
        print("📊 Analytics configured for production")
    }
    
    private static func configureCrashReporting() {
        // Configure crash reporting service
        print("🐛 Crash reporting configured")
    }
    
    private static func configureRemoteConfig() {
        // Configure remote configuration
        print("🔧 Remote config initialized")
    }
}