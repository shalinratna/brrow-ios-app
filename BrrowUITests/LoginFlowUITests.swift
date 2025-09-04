//
//  LoginFlowUITests.swift
//  BrrowUITests
//
//  UI tests for login and registration flow
//

import XCTest

final class LoginFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testLoginViewAppears() throws {
        // Test that login view appears on app launch when not authenticated
        XCTAssertTrue(app.staticTexts["Welcome to Brrow"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
        XCTAssertTrue(app.buttons["Create Account"].exists)
    }
    
    func testSwitchBetweenLoginAndSignup() throws {
        // Initially should be on login
        XCTAssertTrue(app.buttons["Sign In"].exists)
        
        // Tap "Create Account" to switch to signup
        app.buttons["Create Account"].tap()
        
        // Should now show signup form
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.buttons["Create Account"].exists)
        
        // Tap "Sign In" to switch back
        app.buttons["Sign In"].tap()
        
        // Should be back to login
        XCTAssertFalse(app.textFields["Username"].exists)
    }
    
    func testLoginWithValidCredentials() throws {
        // Enter valid credentials
        let emailField = app.textFields["Email or Username"]
        XCTAssertTrue(emailField.exists)
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Tap sign in
        app.buttons["Sign In"].tap()
        
        // Should navigate to main app (check for tab bar)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        
        // Check that all tabs exist
        XCTAssertTrue(app.buttons["Discover"].exists)
        XCTAssertTrue(app.buttons["Browse"].exists)
        XCTAssertTrue(app.buttons["Post"].exists)
        XCTAssertTrue(app.buttons["Messages"].exists)
        XCTAssertTrue(app.buttons["Earnings"].exists)
        XCTAssertTrue(app.buttons["Profile"].exists)
    }
    
    func testLoginWithInvalidCredentials() throws {
        // Enter invalid credentials
        let emailField = app.textFields["Email or Username"]
        emailField.tap()
        emailField.typeText("invalid@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        // Tap sign in
        app.buttons["Sign In"].tap()
        
        // Should show error message
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 3.0))
        
        // Dismiss error
        app.buttons["OK"].tap()
        
        // Should still be on login screen
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    func testSignupFlow() throws {
        // Switch to signup
        app.buttons["Create Account"].tap()
        
        // Fill signup form
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("testuser")
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("newuser@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("newpassword123")
        
        // Tap create account
        app.buttons["Create Account"].tap()
        
        // Should navigate to main app
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
    }
    
    func testForgotPasswordFlow() throws {
        // Tap forgot password
        app.buttons["Forgot Password?"].tap()
        
        // Should show password reset view
        XCTAssertTrue(app.staticTexts["Reset Password"].exists)
        
        // Enter email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Tap send reset link
        app.buttons["Send Reset Link"].tap()
        
        // Should show confirmation
        let confirmationAlert = app.alerts.firstMatch
        XCTAssertTrue(confirmationAlert.waitForExistence(timeout: 3.0))
        
        // Dismiss and go back
        app.buttons["OK"].tap()
        app.buttons["Back"].tap()
        
        // Should be back to login
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    func testSocialLoginButtons() throws {
        // Check that social login buttons exist
        XCTAssertTrue(app.buttons["Continue with Apple"].exists)
        XCTAssertTrue(app.buttons["Continue with Google"].exists)
        
        // Note: Testing actual social login would require 
        // integration with test accounts or mocking
    }
}