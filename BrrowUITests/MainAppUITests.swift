//
//  MainAppUITests.swift
//  BrrowUITests
//
//  UI tests for main app functionality
//

import XCTest

final class MainAppUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--authenticated"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testTabNavigation() throws {
        // Test navigation between all tabs
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Test Discover tab
        app.buttons["Discover"].tap()
        XCTAssertTrue(app.staticTexts["BrrowStories"].waitForExistence(timeout: 2.0))
        
        // Test Browse tab
        app.buttons["Browse"].tap()
        XCTAssertTrue(app.searchFields["Search items..."].waitForExistence(timeout: 2.0))
        
        // Test Post tab
        app.buttons["Post"].tap()
        XCTAssertTrue(app.staticTexts["Create Post"].waitForExistence(timeout: 2.0))
        
        // Test Messages tab
        app.buttons["Messages"].tap()
        XCTAssertTrue(app.staticTexts["Messages"].waitForExistence(timeout: 2.0))
        
        // Test Earnings tab
        app.buttons["Earnings"].tap()
        XCTAssertTrue(app.staticTexts["Total Earnings"].waitForExistence(timeout: 2.0))
        
        // Test Profile tab
        app.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Edit Profile"].waitForExistence(timeout: 2.0))
    }
    
    func testBrowseAndSearch() throws {
        // Navigate to Browse tab
        app.buttons["Browse"].tap()
        
        // Test search functionality
        let searchField = app.searchFields["Search items..."]
        XCTAssertTrue(searchField.exists)
        
        searchField.tap()
        searchField.typeText("camera")
        
        // Wait for search results
        let firstResult = app.cells.firstMatch
        XCTAssertTrue(firstResult.waitForExistence(timeout: 3.0))
        
        // Tap on first result to view details
        firstResult.tap()
        
        // Should show item detail view
        XCTAssertTrue(app.buttons["Request to Borrow"].waitForExistence(timeout: 2.0))
        
        // Go back
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    func testCreatePost() throws {
        // Navigate to Post tab
        app.buttons["Post"].tap()
        
        // Should show post creation options
        XCTAssertTrue(app.staticTexts["List Item"].exists)
        XCTAssertTrue(app.staticTexts["Post Seek"].exists)
        
        // Test listing creation
        app.buttons["List Item"].tap()
        
        // Fill in basic information
        let titleField = app.textFields["What are you lending?"]
        titleField.tap()
        titleField.typeText("Test Camera")
        
        let descriptionField = app.textViews.firstMatch
        descriptionField.tap()
        descriptionField.typeText("Great camera for photography")
        
        // Add photos
        app.buttons["Add Photos"].tap()
        
        // Note: Photo picker interaction would require additional setup
        // Cancel photo picker for now
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
        
        // Set price
        app.toggles["Free to borrow"].tap() // Turn off free
        let priceField = app.textFields["0.00"]
        priceField.tap()
        priceField.typeText("25")
        
        // Set location
        let locationField = app.textFields["Where can people pick this up?"]
        locationField.tap()
        locationField.typeText("Downtown SF")
        
        // Post the item
        app.buttons["Post"].tap()
        
        // Should return to main view
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
    
    func testMessaging() throws {
        // Navigate to Messages tab
        app.buttons["Messages"].tap()
        
        // If there are conversations, tap on first one
        let firstConversation = app.cells.firstMatch
        if firstConversation.exists {
            firstConversation.tap()
            
            // Should show chat detail view
            XCTAssertTrue(app.textFields["Message..."].waitForExistence(timeout: 2.0))
            
            // Test sending a message
            let messageField = app.textFields["Message..."]
            messageField.tap()
            messageField.typeText("Hello from UI test!")
            
            app.buttons["arrow.up.circle.fill"].tap()
            
            // Message should appear in chat
            XCTAssertTrue(app.staticTexts["Hello from UI test!"].exists)
            
            // Go back
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    func testEarningsView() throws {
        // Navigate to Earnings tab
        app.buttons["Earnings"].tap()
        
        // Check earnings components exist
        XCTAssertTrue(app.staticTexts["Total Earnings"].exists)
        XCTAssertTrue(app.staticTexts["This Month"].exists)
        XCTAssertTrue(app.buttons["Withdraw"].exists)
        
        // Test earnings stats tabs
        if app.buttons["Daily"].exists {
            app.buttons["Daily"].tap()
            app.buttons["Weekly"].tap()
            app.buttons["Monthly"].tap()
        }
    }
    
    func testProfileAndSettings() throws {
        // Navigate to Profile tab
        app.buttons["Profile"].tap()
        
        // Test profile sections
        XCTAssertTrue(app.buttons["Edit Profile"].exists)
        
        // Test profile tabs
        if app.buttons["Activity"].exists {
            app.buttons["Activity"].tap()
            app.buttons["Listings"].tap()
            app.buttons["Reviews"].tap()
            app.buttons["Stats"].tap()
        }
        
        // Test settings access
        let settingsButton = app.buttons["gearshape"]
        if settingsButton.exists {
            settingsButton.tap()
            
            // Should show settings view
            XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 2.0))
            
            // Go back
            app.buttons["Cancel"].tap()
        }
    }
    
    func testDiscoverFeatures() throws {
        // Navigate to Discover tab
        app.buttons["Discover"].tap()
        
        // Test BrrowStories
        if app.buttons["View Stories"].exists {
            app.buttons["View Stories"].tap()
            
            // Should show stories view
            XCTAssertTrue(app.otherElements["StoryView"].waitForExistence(timeout: 2.0))
            
            // Tap to go back
            app.tap()
        }
        
        // Test AI recommendations section
        XCTAssertTrue(app.staticTexts["AI Recommendations"].exists)
        
        // Test community challenges
        if app.staticTexts["Community Challenges"].exists {
            let challengeCard = app.otherElements.containing(.staticText, identifier: "Community Challenges").firstMatch
            if challengeCard.exists {
                challengeCard.tap()
                // Should show challenge details
            }
        }
    }
    
    func testFiltersAndAdvancedSearch() throws {
        // Navigate to Browse tab
        app.buttons["Browse"].tap()
        
        // Tap filters button
        let filtersButton = app.buttons["line.3.horizontal.decrease.circle"]
        if filtersButton.exists {
            filtersButton.tap()
            
            // Should show filters view
            XCTAssertTrue(app.staticTexts["Filters"].waitForExistence(timeout: 2.0))
            
            // Test category selection
            app.buttons["Electronics"].tap()
            
            // Test price range
            let priceSlider = app.sliders.firstMatch
            if priceSlider.exists {
                priceSlider.adjust(toNormalizedSliderPosition: 0.7)
            }
            
            // Apply filters
            app.buttons["Apply"].tap()
            
            // Should return to browse view with filters applied
            XCTAssertTrue(app.searchFields["Search items..."].exists)
        }
    }
}