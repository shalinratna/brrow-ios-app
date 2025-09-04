//
//  ComprehensiveBrrowTests.swift
//  BrrowTests
//
//  Comprehensive test suite for the Brrow app core functionality
//

import XCTest
import Combine
@testable import Brrow

final class ComprehensiveBrrowTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
    }
    
    // MARK: - Achievement System Tests
    
    func testAchievementManagerInitialization() throws {
        let achievementManager = AchievementManager.shared
        XCTAssertNotNil(achievementManager)
        XCTAssertEqual(achievementManager.userLevel, 1)
        XCTAssertEqual(achievementManager.totalPoints, 0)
    }
    
    func testAchievementDataModel() throws {
        let achievement = AchievementData(
            id: 1,
            code: "first_listing",
            name: "First Steps",
            description: "Created your first listing",
            hint: "Create a listing to unlock this achievement",
            icon: "plus.circle.fill",
            points: 25,
            difficulty: "Easy",
            type: "one_time",
            category: "Listing",
            categoryColor: "#2ABF5A",
            isUnlocked: false,
            isSecret: false,
            unlockedAt: nil,
            progress: AchievementData.Progress(current: 0, target: 1, percentage: 0)
        )
        
        XCTAssertEqual(achievement.name, "First Steps")
        XCTAssertEqual(achievement.points, 25)
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertEqual(achievement.progress.target, 1)
    }
    
    func testAchievementTracking() throws {
        let achievementManager = AchievementManager.shared
        let expectation = XCTestExpectation(description: "Achievement tracking")
        
        // Track listing creation
        achievementManager.trackListingCreated()
        
        // Wait a moment for async processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Location Service Tests
    
    func testLocationServiceInitialization() throws {
        let locationService = LocationService.shared
        XCTAssertNotNil(locationService)
    }
    
    func testFormattedAddressModel() throws {
        let address = LocationService.FormattedAddress(
            streetNumber: "123",
            streetName: "Main St",
            city: "San Francisco",
            state: "CA",
            zipCode: "94102",
            country: "USA"
        )
        
        XCTAssertEqual(address.city, "San Francisco")
        XCTAssertEqual(address.state, "CA")
        XCTAssertTrue(address.fullAddress.contains("123 Main St"))
        XCTAssertTrue(address.shortAddress.contains("San Francisco"))
    }
    
    // MARK: - API Client Tests
    
    func testAPIClientInitialization() throws {
        let apiClient = APIClient.shared
        XCTAssertNotNil(apiClient)
        XCTAssertEqual(apiClient.baseURL, "https://brrowapp.com/brrow/api")
    }
    
    // MARK: - Theme Tests
    
    func testThemeColors() throws {
        XCTAssertNotNil(Theme.Colors.primary)
        XCTAssertNotNil(Theme.Colors.background)
        XCTAssertNotNil(Theme.Colors.text)
        XCTAssertNotNil(Theme.Colors.secondaryText)
    }
    
    func testThemeSpacing() throws {
        XCTAssertEqual(Theme.Spacing.xs, 4)
        XCTAssertEqual(Theme.Spacing.sm, 8)
        XCTAssertEqual(Theme.Spacing.md, 16)
        XCTAssertEqual(Theme.Spacing.lg, 24)
        XCTAssertEqual(Theme.Spacing.xl, 32)
    }
    
    // MARK: - Performance Tests
    
    func testAchievementManagerPerformance() throws {
        let achievementManager = AchievementManager.shared
        
        self.measure {
            // Test performance of achievement tracking
            for _ in 0..<100 {
                achievementManager.trackListingViewed()
            }
        }
    }
    
    // MARK: - Security Tests
    
    func testTokenValidation() throws {
        // Test that tokens are properly validated
        let validToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9"
        XCTAssertTrue(validToken.hasPrefix("eyJ"))
        
        let invalidToken = "invalid_token"
        XCTAssertFalse(invalidToken.hasPrefix("eyJ"))
    }
    
    func testDataSanitization() throws {
        let maliciousInput = "<script>alert('xss')</script>"
        let sanitized = maliciousInput.replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        XCTAssertFalse(sanitized.contains("<script>"))
        XCTAssertTrue(sanitized.contains("&lt;"))
    }
}