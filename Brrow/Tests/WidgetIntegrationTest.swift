//
//  WidgetIntegrationTest.swift
//  Brrow
//
//  Comprehensive test to verify widget integration works correctly
//

import Foundation
import WidgetKit
import Combine

class WidgetIntegrationTest: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false
    @Published var overallStatus: TestStatus = .pending

    private var cancellables = Set<AnyCancellable>()
    private let appGroupIdentifier = "group.com.brrowapp.widgets"

    enum TestStatus {
        case pending, running, passed, failed

        var emoji: String {
            switch self {
            case .pending: return "⏳"
            case .running: return "🔄"
            case .passed: return "✅"
            case .failed: return "❌"
            }
        }
    }

    struct TestResult {
        let testName: String
        let status: TestStatus
        let details: String
        let timestamp: Date

        init(name: String, status: TestStatus, details: String) {
            self.testName = name
            self.status = status
            self.details = details
            self.timestamp = Date()
        }
    }

    // MARK: - Main Test Runner

    func runComprehensiveTest() async {
        await MainActor.run {
            isRunning = true
            testResults.removeAll()
            overallStatus = .running
        }

        print("🧪 Starting Comprehensive Widget Integration Test")
        print("=" * 50)

        // Test 1: App Group Configuration
        await testAppGroupConfiguration()

        // Test 2: Widget Data Manager Functionality
        await testWidgetDataManager()

        // Test 3: Widget Integration Service
        await testWidgetIntegrationService()

        // Test 4: API Data Flow
        await testAPIDataFlow()

        // Test 5: Widget Provider Data Access
        await testWidgetProviderDataAccess()

        // Test 6: Real-time Updates
        await testRealTimeUpdates()

        // Test 7: App Lifecycle Integration
        await testAppLifecycleIntegration()

        // Test 8: Error Handling
        await testErrorHandling()

        // Calculate overall result
        await calculateOverallResult()

        await MainActor.run {
            isRunning = false
        }

        print("\n🏁 Widget Integration Test Complete")
        await printSummary()
    }

    // MARK: - Individual Tests

    private func testAppGroupConfiguration() async {
        print("\n🔧 Test 1: App Group Configuration")

        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            await addResult(name: "App Group Access", status: .failed,
                          details: "Cannot access app group: \(appGroupIdentifier)")
            return
        }

        // Test write/read capability
        let testKey = "widget.test.key"
        let testValue = "test_value_\(Date().timeIntervalSince1970)"

        sharedDefaults.set(testValue, forKey: testKey)
        let retrievedValue = sharedDefaults.string(forKey: testKey)

        if retrievedValue == testValue {
            await addResult(name: "App Group Access", status: .passed,
                          details: "Successfully wrote and read from app group")
        } else {
            await addResult(name: "App Group Access", status: .failed,
                          details: "Failed to write/read from app group. Expected: \(testValue), Got: \(retrievedValue ?? "nil")")
        }

        // Clean up test data
        sharedDefaults.removeObject(forKey: testKey)
    }

    private func testWidgetDataManager() async {
        print("\n📊 Test 2: Widget Data Manager")

        let dataManager = WidgetDataManager.shared

        // Test data updates
        let testData = (
            activeListings: 5,
            unreadMessages: 3,
            todaysEarnings: 125.50,
            nearbyItems: 8,
            recentActivity: "Test activity"
        )

        dataManager.updateWidgetData(
            activeListings: testData.activeListings,
            unreadMessages: testData.unreadMessages,
            todaysEarnings: testData.todaysEarnings,
            nearbyItems: testData.nearbyItems,
            recentActivity: testData.recentActivity
        )

        // Wait a moment for update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Retrieve and verify data
        let retrievedData = dataManager.getWidgetData()

        var errors: [String] = []
        if retrievedData.activeListings != testData.activeListings {
            errors.append("ActiveListings: expected \(testData.activeListings), got \(retrievedData.activeListings)")
        }
        if retrievedData.unreadMessages != testData.unreadMessages {
            errors.append("UnreadMessages: expected \(testData.unreadMessages), got \(retrievedData.unreadMessages)")
        }
        if abs(retrievedData.todaysEarnings - testData.todaysEarnings) > 0.01 {
            errors.append("TodaysEarnings: expected \(testData.todaysEarnings), got \(retrievedData.todaysEarnings)")
        }
        if retrievedData.nearbyItems != testData.nearbyItems {
            errors.append("NearbyItems: expected \(testData.nearbyItems), got \(retrievedData.nearbyItems)")
        }
        if retrievedData.recentActivity != testData.recentActivity {
            errors.append("RecentActivity: expected '\(testData.recentActivity)', got '\(retrievedData.recentActivity)'")
        }

        if errors.isEmpty {
            await addResult(name: "Widget Data Manager", status: .passed,
                          details: "All data operations successful")
        } else {
            await addResult(name: "Widget Data Manager", status: .failed,
                          details: "Data mismatch: \(errors.joined(separator: ", "))")
        }
    }

    private func testWidgetIntegrationService() async {
        print("\n🔗 Test 3: Widget Integration Service")

        let integrationService = WidgetIntegrationService.shared

        // Test specific update methods
        let testListing = createTestListing()
        integrationService.notifyListingCreated(testListing)

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        let widgetData = WidgetDataManager.shared.getWidgetData()

        if widgetData.recentActivity.contains("Created: \(testListing.title)") {
            await addResult(name: "Integration Service", status: .passed,
                          details: "Listing creation properly updated widget data")
        } else {
            await addResult(name: "Integration Service", status: .failed,
                          details: "Listing creation did not update widget. Activity: '\(widgetData.recentActivity)'")
        }
    }

    private func testAPIDataFlow() async {
        print("\n🌐 Test 4: API Data Flow")

        guard AuthManager.shared.isAuthenticated else {
            await addResult(name: "API Data Flow", status: .failed,
                          details: "User not authenticated - cannot test API flow")
            return
        }

        let integrationService = WidgetIntegrationService.shared

        // Store initial widget data
        let initialData = WidgetDataManager.shared.getWidgetData()

        // Trigger a full data update
        integrationService.updateAllWidgetData()

        // Wait for API calls to complete
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        let updatedData = WidgetDataManager.shared.getWidgetData()

        // Check if data was updated (timestamps should be different)
        if updatedData.lastUpdated > initialData.lastUpdated {
            await addResult(name: "API Data Flow", status: .passed,
                          details: "Widget data successfully updated from API")
        } else {
            await addResult(name: "API Data Flow", status: .failed,
                          details: "Widget data not updated. Initial: \(initialData.lastUpdated), Updated: \(updatedData.lastUpdated)")
        }
    }

    private func testWidgetProviderDataAccess() async {
        print("\n📱 Test 5: Widget Provider Data Access")

        // Simulate what the widget provider does
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            await addResult(name: "Widget Provider Access", status: .failed,
                          details: "Widget provider cannot access shared defaults")
            return
        }

        // Check if all expected keys are accessible
        let expectedKeys = [
            "widget.activeListings",
            "widget.unreadMessages",
            "widget.todaysEarnings",
            "widget.nearbyItems",
            "widget.recentActivity",
            "widget.lastUpdated"
        ]

        var missingKeys: [String] = []
        for key in expectedKeys {
            if sharedDefaults.object(forKey: key) == nil {
                missingKeys.append(key)
            }
        }

        if missingKeys.isEmpty {
            await addResult(name: "Widget Provider Access", status: .passed,
                          details: "All widget data keys accessible from provider")
        } else {
            await addResult(name: "Widget Provider Access", status: .failed,
                          details: "Missing keys: \(missingKeys.joined(separator: ", "))")
        }
    }

    private func testRealTimeUpdates() async {
        print("\n⚡ Test 6: Real-time Updates")

        let dataManager = WidgetDataManager.shared

        // Get initial state
        let initial = dataManager.getWidgetData()

        // Test increment operations
        dataManager.incrementUnreadMessages()
        dataManager.handleNewListingCreated()

        // Wait for updates
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let updated = dataManager.getWidgetData()

        let messagesIncremented = updated.unreadMessages > initial.unreadMessages
        let listingsIncremented = updated.activeListings > initial.activeListings
        let activityUpdated = updated.recentActivity != initial.recentActivity

        if messagesIncremented && listingsIncremented && activityUpdated {
            await addResult(name: "Real-time Updates", status: .passed,
                          details: "All real-time updates working correctly")
        } else {
            await addResult(name: "Real-time Updates", status: .failed,
                          details: "Some updates failed. Messages: \(messagesIncremented), Listings: \(listingsIncremented), Activity: \(activityUpdated)")
        }
    }

    private func testAppLifecycleIntegration() async {
        print("\n🔄 Test 7: App Lifecycle Integration")

        let integrationService = WidgetIntegrationService.shared
        let dataManager = WidgetDataManager.shared

        // Get initial timestamp
        let initialData = dataManager.getWidgetData()

        // Simulate app becoming active
        dataManager.handleAppBecameActive()
        integrationService.refreshWidgetsOnAppActivation()

        // Wait for refresh
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        let refreshedData = dataManager.getWidgetData()

        if refreshedData.lastUpdated > initialData.lastUpdated {
            await addResult(name: "App Lifecycle Integration", status: .passed,
                          details: "Widgets properly refreshed on app activation")
        } else {
            await addResult(name: "App Lifecycle Integration", status: .failed,
                          details: "Widgets not refreshed on app activation")
        }
    }

    private func testErrorHandling() async {
        print("\n🛡️ Test 8: Error Handling")

        // Test with invalid app group
        let invalidDefaults = UserDefaults(suiteName: "invalid.group.identifier")

        if invalidDefaults == nil {
            await addResult(name: "Error Handling", status: .passed,
                          details: "Properly handles invalid app group identifier")
        } else {
            await addResult(name: "Error Handling", status: .failed,
                          details: "Should fail with invalid app group identifier")
        }
    }

    // MARK: - Helper Methods

    private func createTestListing() -> Listing {
        // Create a test listing for testing purposes
        let testJSON: [String: Any] = [
            "id": "test-listing-\(Date().timeIntervalSince1970)",
            "title": "Test Widget Listing",
            "description": "Test listing for widget integration",
            "categoryId": "electronics",
            "price": 25.0,
            "isActive": true,
            "userId": AuthManager.shared.currentUser?.id ?? "test-user",
            "availabilityStatus": "available",
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: testJSON)
            let listing = try JSONDecoder().decode(Listing.self, from: jsonData)
            return listing
        } catch {
            print("Error creating test listing: \(error)")
            return Listing.example
        }
    }

    @MainActor
    private func addResult(name: String, status: TestStatus, details: String) {
        let result = TestResult(name: name, status: status, details: details)
        testResults.append(result)
        print("\(status.emoji) \(name): \(details)")
    }

    private func calculateOverallResult() async {
        let failedTests = await MainActor.run { testResults.filter { $0.status == .failed } }

        await MainActor.run {
            overallStatus = failedTests.isEmpty ? .passed : .failed
        }
    }

    private func printSummary() async {
        let results = await MainActor.run { testResults }

        print("\n📊 TEST SUMMARY")
        print("=" * 30)

        let passed = results.filter { $0.status == .passed }.count
        let failed = results.filter { $0.status == .failed }.count
        let total = results.count

        print("Total Tests: \(total)")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("Success Rate: \(total > 0 ? Int((Double(passed) / Double(total)) * 100) : 0)%")

        if failed > 0 {
            print("\n❌ FAILED TESTS:")
            for result in results where result.status == .failed {
                print("  • \(result.testName): \(result.details)")
            }
        }

        print("\n🎯 OVERALL RESULT: \(overallStatus.emoji) \(overallStatus == .passed ? "ALL TESTS PASSED" : "SOME TESTS FAILED")")
    }
}

// MARK: - Convenience Extension

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}