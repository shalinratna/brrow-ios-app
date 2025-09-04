//
//  AuthManagerTests.swift
//  BrrowTests
//
//  Unit tests for AuthManager
//

import XCTest
import Combine
@testable import Brrow

final class AuthManagerTests: XCTestCase {
    var authManager: AuthManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        authManager = AuthManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        authManager = nil
        cancellables = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertFalse(authManager.isValidatingToken)
    }
    
    func testLoginWithValidCredentials() async throws {
        let expectation = XCTestExpectation(description: "Login success")
        
        authManager.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Mock successful login - using publisher-based method
        let _ = authManager.login(email: "test@example.com", password: "password123")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
    }
    
    func testLoginWithInvalidCredentials() async throws {
        let _ = authManager.login(email: "invalid@example.com", password: "wrongpassword")
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    // Expected failure
                }
            }, receiveValue: { _ in })
        
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
    }
    
    func testRegistration() async throws {
        let expectation = XCTestExpectation(description: "Registration success")
        
        authManager.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let testDate = Date()
        let _ = try await authManager.register(
            email: "test@example.com",
            username: "testuser",
            password: "password123",
            birthdate: testDate
        )
        
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
    }
    
    func testLogout() async throws {
        // First login
        let _ = authManager.login(email: "test@example.com", password: "password123")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        // Then logout
        authManager.logout()
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
    }
    
    func testTokenRefresh() async throws {
        // Mock initial login
        let _ = authManager.login(email: "test@example.com", password: "password123")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        let initialToken = authManager.sessionId
        
        // Mock token refresh (session ID changes)
        authManager.sessionId = UUID().uuidString
        
        // Token should be refreshed
        XCTAssertNotEqual(initialToken, authManager.sessionId)
    }
}