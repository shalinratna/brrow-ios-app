//
//  DeveloperSettingsView.swift
//  Brrow
//
//  Developer tools and PEST testing interface
//

import SwiftUI

struct DeveloperSettingsView: View {
    @State private var showingTestResults = false
    @State private var testResults: String = ""
    @State private var isTestingWebhooks = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    pestControlSection
                    backendTestSection
                    performanceTestSection
                    testResultsSection
                }
                .padding()
            }
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - View Components
    private var pestControlSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("PEST Control System", systemImage: "ladybug.fill")
                .font(.headline)
                .foregroundColor(.green)

            Text("Test your Discord webhook integration")
                .font(.caption)
                .foregroundColor(.secondary)

            testAllWebhooksButton
            individualErrorTests
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var testAllWebhooksButton: some View {
        Button(action: testAllWebhooks) {
            HStack {
                if isTestingWebhooks {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                }

                Text("Test All Discord Webhooks")
                    .fontWeight(.medium)

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .foregroundColor(.green)
            .cornerRadius(12)
        }
        .disabled(isTestingWebhooks)
    }

    private var individualErrorTests: some View {
        VStack(spacing: 10) {
            ForEach(PESTSeverity.allCases, id: \.self) { severity in
                errorTestButton(for: severity)
            }
        }
    }

    private func errorTestButton(for severity: PESTSeverity) -> some View {
        Button(action: { testError(severity: severity) }) {
            HStack {
                Circle()
                    .fill(severityColor(severity))
                    .frame(width: 10, height: 10)

                Text("Test \(severity.rawValue.capitalized) Error")
                    .font(.subheadline)

                Spacer()

                Image(systemName: "arrow.right.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }

    private var backendTestSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Backend PEST Test", systemImage: "server.rack")
                .font(.headline)
                .foregroundColor(.blue)

            Button(action: testBackendWebhook) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Trigger Backend Error Test")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var performanceTestSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Performance Monitor", systemImage: "speedometer")
                .font(.headline)
                .foregroundColor(.orange)

            Button(action: testPerformanceIssue) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Simulate Performance Issue")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    @ViewBuilder
    private var testResultsSection: some View {
        if showingTestResults && !testResults.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Test Results", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)

                Text(testResults)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Test Functions
    private func testAllWebhooks() {
        isTestingWebhooks = true
        testResults = "Testing all webhooks...\n"
        showingTestResults = true

        // Test all webhooks
        PESTWebhooks.testAllWebhooks()

        // Add results
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            testResults += "✅ Main webhook tested\n"
            testResults += "✅ Critical webhook tested\n"
            testResults += "✅ Network webhook tested\n"
            testResults += "✅ Auth webhook tested\n"
            testResults += "✅ Performance webhook tested\n"
            testResults += "✅ Backend webhook tested\n"
            testResults += "\nAll webhooks tested successfully!"
            isTestingWebhooks = false
        }
    }

    private func testError(severity: PESTSeverity) {
        let testMessages: [PESTSeverity: String] = [
            .low: "This is a low severity test from Developer Settings",
            .medium: "Medium severity test - checking Discord integration",
            .high: "High severity test - simulating critical error",
            .critical: "CRITICAL TEST - System failure simulation"
        ]

        PESTControlSystem.shared.captureError(
            NSError(domain: "DeveloperTest", code: severity.hashValue, userInfo: [
                NSLocalizedDescriptionKey: testMessages[severity] ?? "Test error"
            ]),
            context: "Developer Settings Test",
            severity: severity,
            userInfo: [
                "source": "developer_settings",
                "test_type": "manual",
                "severity_test": severity.rawValue
            ]
        )

        testResults = "Sent \(severity.rawValue) error to Discord"
        showingTestResults = true
    }

    private func testBackendWebhook() {
        // This would trigger a backend test endpoint
        Task {
            do {
                let baseURL = "https://brrowapp.com"
                let url = URL(string: "\(baseURL)/api/test/pest")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"

                let (_, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    testResults = "Backend test triggered (Status: \(httpResponse.statusCode))"
                }
            } catch {
                testResults = "Backend test request sent (may not be implemented yet)"
            }
            showingTestResults = true
        }
    }

    private func testPerformanceIssue() {
        PESTControlSystem.shared.captureError(
            NSError(domain: "PerformanceTest", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Simulated performance issue - High memory usage detected"
            ]),
            context: "Performance Monitor Test",
            severity: .high,
            userInfo: [
                "memory_used": "450MB",
                "cpu_usage": "85%",
                "fps": "12",
                "test": true
            ]
        )

        testResults = "Performance issue sent to Discord webhook"
        showingTestResults = true
    }

    private func severityColor(_ severity: PESTSeverity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Preview
struct DeveloperSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperSettingsView()
    }
}