//
//  PESTWebhooks.swift
//  Brrow
//
//  Discord Webhook Configuration for PEST Control System
//  IMPORTANT: Update these webhook URLs with your actual Discord webhooks
//

import Foundation

struct PESTWebhooks {

    // MARK: - Discord Webhooks
    // Create separate webhooks for different error types/severities

    // Main error reporting webhook (all errors)
    static let mainWebhook = "https://discord.com/api/webhooks/1417208707305177118/b4JUqkxnM436p30qVWTlvYAplsXAiOOhrtEkRA66vEvQQpqt6nWUZ9zo0f9JA5utfzie"

    // Critical errors only (app crashes, data loss, etc.)
    static let criticalWebhook = "https://discord.com/api/webhooks/1417208707305177118/b4JUqkxnM436p30qVWTlvYAplsXAiOOhrtEkRA66vEvQQpqt6nWUZ9zo0f9JA5utfzie"

    // Network errors (API failures, timeouts, etc.)
    static let networkWebhook = "https://discord.com/api/webhooks/1417208707305177118/b4JUqkxnM436p30qVWTlvYAplsXAiOOhrtEkRA66vEvQQpqt6nWUZ9zo0f9JA5utfzie"

    // Authentication errors (login failures, token issues)
    static let authWebhook = "https://discord.com/api/webhooks/1417208707305177118/b4JUqkxnM436p30qVWTlvYAplsXAiOOhrtEkRA66vEvQQpqt6nWUZ9zo0f9JA5utfzie"

    // Performance issues (memory warnings, slow operations)
    static let performanceWebhook = "https://discord.com/api/webhooks/1417209300610322575/VqUumVQIr17nfURlp9y0QycEQtVtdYN2B-KUTRVvH8K7FJM-ZKM22OJt4rQSvGg_U0k4"

    // User actions tracking (for debugging user flows)
    static let userActionsWebhook = "https://discord.com/api/webhooks/1417208707305177118/b4JUqkxnM436p30qVWTlvYAplsXAiOOhrtEkRA66vEvQQpqt6nWUZ9zo0f9JA5utfzie"

    // Backend errors (from Node.js server)
    static let backendWebhook = "https://discord.com/api/webhooks/1417209200655863970/WugY_68WsyGlkEiT1SCQjnb-Uz9Iv_CWmI1narCT_9BuIvsGbzir7atQuBqL1q9F9YUG"

    // MARK: - Webhook Selection
    static func getWebhook(for category: ErrorCategory) -> String {
        switch category {
        case .critical:
            return criticalWebhook != "YOUR_CRITICAL_WEBHOOK_URL" ? criticalWebhook : mainWebhook
        case .network:
            return networkWebhook != "YOUR_NETWORK_WEBHOOK_URL" ? networkWebhook : mainWebhook
        case .authentication:
            return authWebhook != "YOUR_AUTH_WEBHOOK_URL" ? authWebhook : mainWebhook
        case .performance:
            return performanceWebhook != "YOUR_PERFORMANCE_WEBHOOK_URL" ? performanceWebhook : mainWebhook
        case .userAction:
            return userActionsWebhook != "YOUR_USER_ACTIONS_WEBHOOK_URL" ? userActionsWebhook : mainWebhook
        case .backend:
            return backendWebhook != "YOUR_BACKEND_WEBHOOK_URL" ? backendWebhook : mainWebhook
        case .general:
            return mainWebhook
        }
    }

    // MARK: - Test Webhooks
    static func testAllWebhooks() {
        let webhooks = [
            ("Main", mainWebhook),
            ("Critical", criticalWebhook),
            ("Network", networkWebhook),
            ("Auth", authWebhook),
            ("Performance", performanceWebhook),
            ("User Actions", userActionsWebhook),
            ("Backend", backendWebhook)
        ]

        for (name, url) in webhooks {
            if url != "YOUR_\(name.uppercased().replacingOccurrences(of: " ", with: "_"))_WEBHOOK_URL" {
                sendTestMessage(to: url, webhookName: name)
            }
        }
    }

    private static func sendTestMessage(to webhookURL: String, webhookName: String) {
        guard let url = URL(string: webhookURL) else { return }

        let testPayload: [String: Any] = [
            "username": "PEST Test Bot 🧪",
            "content": "✅ \(webhookName) webhook is configured and working!",
            "embeds": [[
                "title": "🐛 PEST Control System Test",
                "description": "This is a test message from your Brrow iOS app",
                "color": 0x00FF00,
                "fields": [
                    ["name": "Webhook Type", "value": webhookName, "inline": true],
                    ["name": "Status", "value": "Connected ✅", "inline": true],
                    ["name": "Timestamp", "value": Date().formatted(), "inline": false]
                ],
                "footer": ["text": "PEST Control System v1.0"]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
            URLSession.shared.dataTask(with: request) { _, response, error in
                if error == nil {
                    print("✅ PEST: \(webhookName) webhook test successful")
                } else {
                    print("❌ PEST: \(webhookName) webhook test failed")
                }
            }.resume()
        } catch {
            print("❌ PEST: Failed to send test to \(webhookName)")
        }
    }
}

// MARK: - Error Categories
enum ErrorCategory {
    case critical
    case network
    case authentication
    case performance
    case userAction
    case backend
    case general

    var emoji: String {
        switch self {
        case .critical: return "🔴"
        case .network: return "🌐"
        case .authentication: return "🔐"
        case .performance: return "⚡"
        case .userAction: return "👤"
        case .backend: return "🖥️"
        case .general: return "⚠️"
        }
    }

    var color: Int {
        switch self {
        case .critical: return 0xFF0000 // Red
        case .network: return 0x0099FF // Blue
        case .authentication: return 0xFF9900 // Orange
        case .performance: return 0xFFFF00 // Yellow
        case .userAction: return 0x00FF00 // Green
        case .backend: return 0x9900FF // Purple
        case .general: return 0x808080 // Gray
        }
    }
}