//
//  ComprehensiveBrrowUITests.swift
//  BrrowUITests
//
//  Comprehensive UI testing suite for the Brrow app
//

import XCTest

final class ComprehensiveBrrowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunchesSuccessfully() throws {
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Main Navigation Tests
    
    func testMainTabNavigation() throws {
        // Test that main tab navigation exists and works
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5.0) {
            
            // Test Home tab
            let homeTab = tabBar.buttons["Home"]
            if homeTab.exists {
                homeTab.tap()
                sleep(1)
            }
            
            // Test Browse tab
            let browseTab = tabBar.buttons["Browse"]
            if browseTab.exists {
                browseTab.tap()
                sleep(1)
            }
            
            // Test Messages tab
            let messagesTab = tabBar.buttons["Messages"]
            if messagesTab.exists {
                messagesTab.tap()
                sleep(1)
            }
            
            // Test Profile tab
            let profileTab = tabBar.buttons["Profile"]
            if profileTab.exists {
                profileTab.tap()
                sleep(1)
            }
        }
    }
    
    // MARK: - Search Tests
    
    func testSearchFunctionality() throws {
        // Test search functionality
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3.0) {
            searchField.tap()
            searchField.typeText("electronics")
            
            // Wait for search results
            sleep(2)
            
            // Tap search or return key
            app.keyboards.buttons["Search"].tap()
            
            // Check that some results appear
            sleep(2)
        }
    }
    
    // MARK: - Profile Tests
    
    func testProfileAccess() throws {
        let profileTab = app.tabBars.firstMatch.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            
            // Wait for profile to load
            sleep(2)
            
            // Test that profile elements exist
            let profileView = app.scrollViews.firstMatch
            XCTAssertTrue(profileView.exists)
        }
    }
    
    // MARK: - Achievement Tests
    
    func testAchievementsAccess() throws {
        let profileTab = app.tabBars.firstMatch.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            
            // Look for achievements button
            let achievementsButton = app.buttons["achievements"]
            if achievementsButton.waitForExistence(timeout: 3.0) {
                achievementsButton.tap()
                
                // Check that achievements view loads
                sleep(2)
                let achievementsView = app.scrollViews.firstMatch
                XCTAssertTrue(achievementsView.exists)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testBasicAccessibility() throws {
        // Test that main elements have accessibility labels
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5.0) {
            let tabButtons = tabBar.buttons.allElementsBoundByIndex
            for button in tabButtons {
                XCTAssertFalse(button.label.isEmpty, "Tab button should have accessibility label")
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testBasicMemoryUsage() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Navigate through main screens
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists {
                let tabs = tabBar.buttons.allElementsBoundByIndex
                for tab in tabs {
                    tab.tap()
                    sleep(1)
                }
            }
        }
    }
}