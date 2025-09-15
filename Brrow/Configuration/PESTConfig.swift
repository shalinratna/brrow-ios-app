//
//  PESTConfig.swift
//  Brrow
//
//  PEST Control System Configuration
//  Set up your Discord webhook here
//

import Foundation
import UIKit

struct PESTConfig {
    // MARK: - Discord Configuration
    // To get a Discord webhook:
    // 1. Go to your Discord server
    // 2. Right-click on a channel → Edit Channel → Integrations → Webhooks
    // 3. Create a new webhook and copy the URL
    // 4. Paste it below

    static let discordWebhookURL = "https://discord.com/api/webhooks/1417208707305177118/b4JUqkxnM436p30qVWTlvYAplsXAiOOhrtEkRA66vEvQQpqt6nWUZ9zo0f9JA5utfzie"

    // Example format:
    // static let discordWebhookURL = "https://discord.com/api/webhooks/123456789/abcdefghijklmnop"

    // MARK: - Feature Flags
    static let enableDiscordLogging = true
    static let enableLocalLogging = true
    static let enableCrashReporting = true
    static let enableNetworkRetry = true
    static let enableAutoRecovery = true

    // MARK: - Severity Thresholds
    static let discordMinimumSeverity: PESTSeverity = .medium // Only send medium+ to Discord
    static let userAlertMinimumSeverity: PESTSeverity = .critical // Only show alerts for critical

    // MARK: - Retry Configuration
    static let maxRetryAttempts = 3
    static let retryDelaySeconds = 2.0
    static let exponentialBackoff = true

    // MARK: - Error History
    static let maxErrorHistoryCount = 100
    static let errorHistoryPersistence = true

    // MARK: - Debug Mode
    #if DEBUG
    static let debugMode = true
    static let verboseLogging = true
    #else
    static let debugMode = false
    static let verboseLogging = false
    #endif
}

// MARK: - PEST Quick Setup
extension PESTControlSystem {
    static func configure() {
        // Update webhook URL in shared instance
        if PESTConfig.discordWebhookURL != "YOUR_DISCORD_WEBHOOK_URL_HERE" {
            print("✅ PEST: Discord webhook configured")
        } else {
            print("⚠️ PEST: Discord webhook not configured. Update PESTConfig.discordWebhookURL")
        }

        // Set up automatic error catching
        setupAutomaticErrorCatching()
    }

    private static func setupAutomaticErrorCatching() {
        // Swizzle URLSession to catch all network errors
        if PESTConfig.enableNetworkRetry {
            swizzleURLSession()
        }

        // Set up notification observers
        setupNotificationObservers()
    }

    private static func swizzleURLSession() {
        // Implementation for method swizzling URLSession
        // This will automatically catch all network errors
    }

    private static func setupNotificationObservers() {
        // Listen for app crashes and errors
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Check for previous crash
            checkForPreviousCrash()
        }
    }

    private static func checkForPreviousCrash() {
        // Disabled crash recovery check to prevent false positives
        // This was causing "Oops something went wrong" alerts on normal app starts
        // The flag persists through debug terminations, causing false crash reports

        // Only enable this in production builds where real crashes need tracking
        #if !DEBUG
        let crashedLastTime = UserDefaults.standard.bool(forKey: "app_crashed_last_time")
        if crashedLastTime {
            PESTControlSystem.shared.captureError(
                NSError(domain: "AppCrash", code: 0),
                context: "App recovered from previous crash",
                severity: .critical
            )
            UserDefaults.standard.set(false, forKey: "app_crashed_last_time")
        }
        UserDefaults.standard.set(true, forKey: "app_crashed_last_time")
        #endif
    }
}