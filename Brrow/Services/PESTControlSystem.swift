//
//  PESTControlSystem.swift
//  Brrow
//
//  PEST - Problem Error Solution Tracking
//  Comprehensive error handling and Discord webhook debugging
//

import Foundation
import UIKit
import os.log

// MARK: - PEST Control System
final class PESTControlSystem {
    static let shared = PESTControlSystem()

    // Discord Webhook Configuration
    private let discordWebhookURL = "YOUR_DISCORD_WEBHOOK_URL" // Replace with your webhook
    private let enableDiscordLogging = true

    // Enable console logging only in DEBUG builds
    #if DEBUG
    private let enableLocalLogging = true
    #else
    private let enableLocalLogging = false
    #endif

    // Error tracking
    private var errorHistory: [PESTError] = []
    private let maxErrorHistory = 100

    // Logging
    private let logger = Logger(subsystem: "com.brrow.pest", category: "ErrorTracking")

    // Error recovery
    private var recoveryHandlers: [String: () -> Void] = [:]

    private init() {
        setupErrorHandlers()
        setupCrashReporting()
    }

    // MARK: - Error Capture
    func captureError(
        _ error: Error,
        context: String,
        severity: PESTSeverity = .medium,
        userInfo: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let pestError = PESTError(
            error: error,
            context: context,
            severity: severity,
            userInfo: userInfo,
            file: file,
            function: function,
            line: line
        )

        // Store in history
        errorHistory.append(pestError)
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }

        // Log locally
        if enableLocalLogging {
            logLocal(pestError)
        }

        // Send to Discord
        if enableDiscordLogging && severity != .low {
            sendToDiscord(pestError)
        }

        // Attempt recovery
        attemptRecovery(for: pestError)

        // Show user-friendly message if needed
        if severity == .critical {
            showUserMessage(for: pestError)
        }
    }

    // MARK: - Network Error Handler
    func handleNetworkError(
        _ error: Error,
        endpoint: String,
        retry: @escaping () -> Void
    ) {
        let isNetworkError = (error as NSError).code == NSURLErrorNotConnectedToInternet ||
                            (error as NSError).code == NSURLErrorTimedOut

        if isNetworkError {
            // Store retry handler
            recoveryHandlers["network_\(endpoint)"] = retry

            captureError(
                error,
                context: "Network request to \(endpoint)",
                severity: .medium,
                userInfo: [
                    "endpoint": endpoint,
                    "network_status": getNetworkStatus()
                ]
            )

            // Show offline banner
            NotificationCenter.default.post(
                name: .showOfflineBanner,
                object: nil
            )
        } else {
            captureError(
                error,
                context: "API Error: \(endpoint)",
                severity: .high
            )
        }
    }

    // MARK: - Discord Integration
    private func sendToDiscord(_ pestError: PESTError) {
        guard !discordWebhookURL.isEmpty && discordWebhookURL != "YOUR_DISCORD_WEBHOOK_URL" else {
            print("⚠️ PEST: Discord webhook not configured")
            return
        }

        let embed = createDiscordEmbed(for: pestError)

        guard let url = URL(string: discordWebhookURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(embed)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ PEST: Failed to send to Discord: \(error)")
                }
            }.resume()
        } catch {
            print("❌ PEST: Failed to encode Discord message: \(error)")
        }
    }

    private func createDiscordEmbed(for pestError: PESTError) -> DiscordWebhookPayload {
        let color = pestError.severity.discordColor
        let emoji = pestError.severity.emoji

        // Get current user info from AuthManager
        let currentUser = AuthManager.shared.currentUser
        let userId = currentUser?.id ?? "Not logged in"
        let username = currentUser?.username ?? "Guest"
        let email = currentUser?.email ?? "N/A"
        let displayName = currentUser?.displayName ?? username

        var fields: [[String: Any]] = [
            ["name": "📍 Context", "value": pestError.context, "inline": false],
            ["name": "👤 User ID", "value": userId, "inline": true],
            ["name": "🏷️ Username", "value": username, "inline": true],
            ["name": "📧 Email", "value": email, "inline": true],
            ["name": "📁 File", "value": "\(pestError.fileName):\(pestError.line)", "inline": true],
            ["name": "🔧 Function", "value": pestError.function, "inline": true],
            ["name": "⚡ Severity", "value": pestError.severity.rawValue, "inline": true],
            ["name": "💻 Device", "value": UIDevice.current.name, "inline": true],
            ["name": "📱 iOS", "value": UIDevice.current.systemVersion, "inline": true],
            ["name": "🕐 Time", "value": pestError.timestamp.formatted(), "inline": true]
        ]

        var description = "```swift\n\(pestError.error.localizedDescription)\n```"

        // Add debug info from userInfo
        if let userInfo = pestError.userInfo, !userInfo.isEmpty {
            description += "\n**🔍 Debug Info (for Claude Code):**\n"

            for (key, value) in userInfo.sorted(by: { $0.key < $1.key }) {
                let valueString = String(describing: value)
                    .replacingOccurrences(of: "\n", with: " ")
                    .prefix(200) // Limit length
                description += "• **\(key)**: `\(valueString)`\n"
            }
        }

        // Add authentication context
        if AuthManager.shared.isAuthenticated {
            description += "\n**🔐 Auth Status:**\n"
            description += "• Token: `\(AuthManager.shared.authToken?.prefix(20) ?? "N/A")...`\n"
            description += "• Guest Mode: `\(AuthManager.shared.isGuestUser ? "Yes" : "No")`\n"
        } else {
            description += "\n**⚠️ User is NOT authenticated**\n"
        }

        return DiscordWebhookPayload(
            username: "PEST Control 🐛",
            avatar_url: "https://i.imgur.com/4M34hi2.png",
            embeds: [
                DiscordEmbed(
                    title: "\(emoji) \(pestError.errorType)",
                    description: description,
                    color: color,
                    fields: fields,
                    footer: DiscordFooter(
                        text: "Brrow iOS App v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") • User: \(displayName)"
                    ),
                    timestamp: ISO8601DateFormatter().string(from: pestError.timestamp)
                )
            ]
        )
    }

    // MARK: - Recovery System
    private func attemptRecovery(for error: PESTError) {
        // Network recovery
        if error.context.contains("Network") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let retry = self.recoveryHandlers["network_\(error.context)"] {
                    print("🔄 PEST: Attempting network recovery...")
                    retry()
                    self.recoveryHandlers.removeValue(forKey: "network_\(error.context)")
                }
            }
        }

        // Token refresh recovery
        if error.error.localizedDescription.contains("401") ||
           error.error.localizedDescription.contains("unauthorized") {
            print("🔐 PEST: Token refresh needed")
            // Token refresh would be called here if implemented
        }

        // Cache clear recovery
        if error.error.localizedDescription.contains("decode") ||
           error.error.localizedDescription.contains("parse") {
            print("🗑️ PEST: Cache clear needed for corrupted data")
            // DataCacheManager.shared.clearCache() if implemented
        }
    }

    // MARK: - User Messaging
    private func showUserMessage(for error: PESTError) {
        DispatchQueue.main.async {
            let message = self.getUserFriendlyMessage(for: error)

            if error.severity == .critical {
                // Show alert for critical errors
                if let topVC = UIApplication.shared.keyWindow?.rootViewController {
                    let alert = UIAlertController(
                        title: "Oops! Something went wrong",
                        message: message,
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
                        self.retryLastAction()
                    })

                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))

                    topVC.present(alert, animated: true)
                }
            } else {
                // Show toast for non-critical
                ToastManager.shared.showError(
                    title: "Error",
                    message: message
                )
            }
        }
    }

    private func getUserFriendlyMessage(for error: PESTError) -> String {
        let errorDescription = error.error.localizedDescription.lowercased()

        if errorDescription.contains("internet") || errorDescription.contains("network") {
            return "Please check your internet connection and try again."
        } else if errorDescription.contains("server") {
            return "Our servers are experiencing issues. Please try again later."
        } else if errorDescription.contains("unauthorized") {
            return "Your session has expired. Please log in again."
        } else if errorDescription.contains("not found") {
            return "The requested item could not be found."
        } else {
            return "Something went wrong. Please try again."
        }
    }

    // MARK: - Crash Reporting
    private func setupCrashReporting() {
        NSSetUncaughtExceptionHandler { exception in
            PESTControlSystem.shared.captureError(
                NSError(domain: "UncaughtException", code: 0, userInfo: [
                    "name": exception.name.rawValue,
                    "reason": exception.reason ?? "Unknown",
                    "callStackSymbols": exception.callStackSymbols ?? []
                ]),
                context: "Uncaught Exception",
                severity: .critical
            )
        }
    }

    // MARK: - Error Handlers
    private func setupErrorHandlers() {
        // Handle memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleMemoryWarning() {
        captureError(
            NSError(domain: "Memory", code: 0, userInfo: ["available_memory": getAvailableMemory()]),
            context: "Memory Warning",
            severity: .high
        )

        // Clear caches
        ImageCacheManager.shared.clearCache()
        // DataCacheManager.shared.clearCache() if implemented
    }

    // MARK: - Helpers
    private func getNetworkStatus() -> String {
        // Implementation for network status check
        return "Unknown"
    }

    private func getAvailableMemory() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            return String(format: "%.1f MB", usedMemory)
        }

        return "Unknown"
    }

    private func retryLastAction() {
        // Retry the last failed action if available
        if let lastRecovery = recoveryHandlers.values.first {
            lastRecovery()
        }
    }

    private func logLocal(_ error: PESTError) {
        logger.error("""
        🐛 PEST Error:
        Context: \(error.context)
        Error: \(error.error.localizedDescription)
        File: \(error.fileName):\(error.line)
        Function: \(error.function)
        Severity: \(error.severity.rawValue)
        """)
    }
}

// MARK: - PEST Error Model
struct PESTError {
    let id = UUID()
    let timestamp = Date()
    let error: Error
    let context: String
    let severity: PESTSeverity
    let userInfo: [String: Any]?
    let file: String
    let function: String
    let line: Int

    var fileName: String {
        URL(fileURLWithPath: file).lastPathComponent
    }

    var errorType: String {
        if let nsError = error as NSError? {
            return "\(nsError.domain) (\(nsError.code))"
        }
        return String(describing: type(of: error))
    }
}

// MARK: - Severity Levels
enum PESTSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var emoji: String {
        switch self {
        case .low: return "💚"
        case .medium: return "💛"
        case .high: return "🧡"
        case .critical: return "❤️"
        }
    }

    var discordColor: Int {
        switch self {
        case .low: return 0x00FF00      // Green
        case .medium: return 0xFFFF00   // Yellow
        case .high: return 0xFF9900     // Orange
        case .critical: return 0xFF0000 // Red
        }
    }
}

// MARK: - Discord Models
struct DiscordWebhookPayload: Encodable {
    let username: String
    let avatar_url: String
    let embeds: [DiscordEmbed]
}

struct DiscordEmbed: Encodable {
    let title: String
    let description: String
    let color: Int
    let fields: [[String: Any]]
    let footer: DiscordFooter
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case title, description, color, fields, footer, timestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(color, forKey: .color)
        try container.encode(footer, forKey: .footer)
        try container.encode(timestamp, forKey: .timestamp)

        // Convert fields manually
        let fieldsData = try JSONSerialization.data(withJSONObject: fields)
        let fieldsArray = try JSONDecoder().decode([[String: String]].self, from: fieldsData)
        try container.encode(fieldsArray, forKey: .fields)
    }
}

struct DiscordFooter: Codable {
    let text: String
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let showOfflineBanner = Notification.Name("showOfflineBanner")
    static let hideOfflineBanner = Notification.Name("hideOfflineBanner")
}

// MARK: - Easy Error Capture Macros
func PESTCatch<T>(
    context: String,
    severity: PESTSeverity = .medium,
    default defaultValue: T,
    _ block: () throws -> T
) -> T {
    do {
        return try block()
    } catch {
        PESTControlSystem.shared.captureError(
            error,
            context: context,
            severity: severity
        )
        return defaultValue
    }
}

func PESTCatchAsync<T>(
    context: String,
    severity: PESTSeverity = .medium,
    default defaultValue: T,
    _ block: () async throws -> T
) async -> T {
    do {
        return try await block()
    } catch {
        PESTControlSystem.shared.captureError(
            error,
            context: context,
            severity: severity
        )
        return defaultValue
    }
}

// MARK: - Global Error Handler
func PESTReport(
    _ error: Error,
    context: String,
    severity: PESTSeverity = .medium
) {
    PESTControlSystem.shared.captureError(
        error,
        context: context,
        severity: severity
    )
}
