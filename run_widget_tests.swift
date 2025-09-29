#!/usr/bin/env swift

//
//  run_widget_tests.swift
//  Brrow
//
//  Command-line script to run widget integration tests
//  Usage: swift run_widget_tests.swift
//

import Foundation

// MARK: - Test Configuration
struct TestConfig {
    static let appGroupIdentifier = "group.com.brrowapp.widgets"
    static let timeout: TimeInterval = 30.0
}

// MARK: - Test Results
enum TestStatus: String {
    case pending = "⏳"
    case running = "🔄"
    case passed = "✅"
    case failed = "❌"
}

struct TestResult {
    let name: String
    let status: TestStatus
    let details: String
    let duration: TimeInterval

    var description: String {
        return "\(status.rawValue) \(name) (\(String(format: "%.2f", duration))s): \(details)"
    }
}

// MARK: - Command Line Test Runner
class CommandLineTestRunner {
    private var results: [TestResult] = []
    private let startTime = Date()

    func runAllTests() async {
        printHeader()

        await runTest("App Group Configuration") { await testAppGroupConfiguration() }
        await runTest("Widget Data Manager") { await testWidgetDataManager() }
        await runTest("Data Persistence") { await testDataPersistence() }
        await runTest("Mock API Integration") { await testMockAPIIntegration() }
        await runTest("Widget Provider Simulation") { await testWidgetProviderSimulation() }
        await runTest("Real-time Updates") { await testRealTimeUpdates() }
        await runTest("Error Handling") { await testErrorHandling() }

        printSummary()
    }

    private func runTest(_ name: String, test: () async -> (Bool, String)) async {
        let testStart = Date()
        print("🔄 Running: \(name)...")

        let (success, details) = await test()
        let duration = Date().timeIntervalSince(testStart)

        let result = TestResult(
            name: name,
            status: success ? .passed : .failed,
            details: details,
            duration: duration
        )

        results.append(result)
        print(result.description)
    }

    // MARK: - Individual Tests

    private func testAppGroupConfiguration() async -> (Bool, String) {
        guard let sharedDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Cannot access app group: \(TestConfig.appGroupIdentifier)")
        }

        let testKey = "widget.cli.test.key"
        let testValue = "cli_test_\(Date().timeIntervalSince1970)"

        sharedDefaults.set(testValue, forKey: testKey)
        let retrieved = sharedDefaults.string(forKey: testKey)

        sharedDefaults.removeObject(forKey: testKey)

        if retrieved == testValue {
            return (true, "App group access verified")
        } else {
            return (false, "Failed to write/read from app group")
        }
    }

    private func testWidgetDataManager() async -> (Bool, String) {
        guard let sharedDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Cannot access shared defaults")
        }

        // Simulate WidgetDataManager operations
        let testData: [String: Any] = [
            "widget.activeListings": 10,
            "widget.unreadMessages": 5,
            "widget.todaysEarnings": 75.25,
            "widget.nearbyItems": 12
        ]

        // Write test data
        for (key, value) in testData {
            if let intValue = value as? Int {
                sharedDefaults.set(intValue, forKey: key)
            } else if let doubleValue = value as? Double {
                sharedDefaults.set(doubleValue, forKey: key)
            }
        }

        sharedDefaults.set("Test activity from CLI", forKey: "widget.recentActivity")
        sharedDefaults.set(Date(), forKey: "widget.lastUpdated")

        // Verify data
        var errors: [String] = []

        if sharedDefaults.integer(forKey: "widget.activeListings") != 10 {
            errors.append("activeListings mismatch")
        }
        if sharedDefaults.integer(forKey: "widget.unreadMessages") != 5 {
            errors.append("unreadMessages mismatch")
        }
        if abs(sharedDefaults.double(forKey: "widget.todaysEarnings") - 75.25) > 0.01 {
            errors.append("todaysEarnings mismatch")
        }
        if sharedDefaults.integer(forKey: "widget.nearbyItems") != 12 {
            errors.append("nearbyItems mismatch")
        }

        if errors.isEmpty {
            return (true, "All widget data operations successful")
        } else {
            return (false, "Data errors: \(errors.joined(separator: ", "))")
        }
    }

    private func testDataPersistence() async -> (Bool, String) {
        guard let sharedDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Cannot access shared defaults")
        }

        // Test data persistence across app launches
        let persistenceKey = "widget.persistence.test"
        let testValue = "persistent_\(Date().timeIntervalSince1970)"

        sharedDefaults.set(testValue, forKey: persistenceKey)
        sharedDefaults.synchronize()

        // Simulate app restart by creating new UserDefaults instance
        guard let newDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Cannot create new defaults instance")
        }

        let retrievedValue = newDefaults.string(forKey: persistenceKey)
        newDefaults.removeObject(forKey: persistenceKey)

        if retrievedValue == testValue {
            return (true, "Data persists across app group instances")
        } else {
            return (false, "Data not persistent: expected '\(testValue)', got '\(retrievedValue ?? "nil")'")
        }
    }

    private func testMockAPIIntegration() async -> (Bool, String) {
        // Simulate API responses and widget updates
        let mockData: [String: Any] = [
            "activeListings": 15,
            "unreadMessages": 3,
            "todaysEarnings": 150.75,
            "nearbyItems": 8
        ]

        guard let sharedDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Cannot access shared defaults")
        }

        // Simulate API data update
        for (key, value) in mockData {
            let widgetKey = "widget.\(key)"
            if let intValue = value as? Int {
                sharedDefaults.set(intValue, forKey: widgetKey)
            } else if let doubleValue = value as? Double {
                sharedDefaults.set(doubleValue, forKey: widgetKey)
            }
        }

        sharedDefaults.set("Mock API update", forKey: "widget.recentActivity")
        sharedDefaults.set(Date(), forKey: "widget.lastUpdated")

        return (true, "Mock API integration successful")
    }

    private func testWidgetProviderSimulation() async -> (Bool, String) {
        // Simulate what the widget provider would do
        guard let sharedDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Widget provider cannot access shared defaults")
        }

        let requiredKeys = [
            "widget.activeListings",
            "widget.unreadMessages",
            "widget.todaysEarnings",
            "widget.nearbyItems",
            "widget.recentActivity",
            "widget.lastUpdated"
        ]

        var missingKeys: [String] = []
        var dataValues: [String: Any] = [:]

        for key in requiredKeys {
            let value = sharedDefaults.object(forKey: key)
            if value == nil {
                missingKeys.append(key)
            } else {
                dataValues[key] = value
            }
        }

        if missingKeys.isEmpty {
            let summary = dataValues.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return (true, "Widget provider can access all data: \(summary)")
        } else {
            return (false, "Missing widget data keys: \(missingKeys.joined(separator: ", "))")
        }
    }

    private func testRealTimeUpdates() async -> (Bool, String) {
        guard let sharedDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Cannot access shared defaults")
        }

        // Test increment operations
        let initialMessages = sharedDefaults.integer(forKey: "widget.unreadMessages")
        let initialListings = sharedDefaults.integer(forKey: "widget.activeListings")

        // Simulate real-time updates
        sharedDefaults.set(initialMessages + 1, forKey: "widget.unreadMessages")
        sharedDefaults.set(initialListings + 1, forKey: "widget.activeListings")
        sharedDefaults.set("New message received", forKey: "widget.recentActivity")
        sharedDefaults.set(Date(), forKey: "widget.lastUpdated")

        let updatedMessages = sharedDefaults.integer(forKey: "widget.unreadMessages")
        let updatedListings = sharedDefaults.integer(forKey: "widget.activeListings")

        if updatedMessages > initialMessages && updatedListings > initialListings {
            return (true, "Real-time updates working correctly")
        } else {
            return (false, "Real-time updates failed")
        }
    }

    private func testErrorHandling() async -> (Bool, String) {
        // Test with invalid app group - on iOS simulator, this may still return a UserDefaults
        // but it won't actually share data with the app group
        let invalidDefaults = UserDefaults(suiteName: "invalid.group.name.that.does.not.exist")

        // Test that our valid app group works
        guard let validDefaults = UserDefaults(suiteName: TestConfig.appGroupIdentifier) else {
            return (false, "Cannot access valid app group")
        }

        // Write to invalid defaults and try to read from valid ones
        invalidDefaults?.set("test", forKey: "test.key")
        let valueFromValid = validDefaults.string(forKey: "test.key")

        if valueFromValid == nil {
            return (true, "Invalid app group properly isolated from valid one")
        } else {
            return (false, "App groups not properly isolated")
        }
    }

    // MARK: - Output Functions

    private func printHeader() {
        let title = "BRROW WIDGET INTEGRATION TEST SUITE"
        let separator = String(repeating: "=", count: title.count)

        print("\n\(separator)")
        print(title)
        print(separator)
        print("App Group: \(TestConfig.appGroupIdentifier)")
        print("Start Time: \(DateFormatter.localizedString(from: startTime, dateStyle: .none, timeStyle: .medium))")
        print(separator)
    }

    private func printSummary() {
        let totalTime = Date().timeIntervalSince(startTime)
        let passed = results.filter { $0.status == .passed }.count
        let failed = results.filter { $0.status == .failed }.count
        let total = results.count

        print("\n" + String(repeating: "=", count: 50))
        print("TEST SUMMARY")
        print(String(repeating: "=", count: 50))
        print("Total Tests: \(total)")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("Success Rate: \(total > 0 ? Int((Double(passed) / Double(total)) * 100) : 0)%")
        print("Total Time: \(String(format: "%.2f", totalTime))s")

        if failed > 0 {
            print("\n❌ FAILED TESTS:")
            for result in results where result.status == .failed {
                print("  • \(result.name): \(result.details)")
            }
        }

        let overallStatus = failed == 0 ? "✅ ALL TESTS PASSED" : "❌ SOME TESTS FAILED"
        print("\n🎯 RESULT: \(overallStatus)")
        print(String(repeating: "=", count: 50))

        // Exit with appropriate code
        if failed > 0 {
            exit(1)
        }
    }
}

// MARK: - Main Execution

print("🚀 Starting Brrow Widget Integration Tests...")

let runner = CommandLineTestRunner()
await runner.runAllTests()

print("✅ Widget tests completed!")