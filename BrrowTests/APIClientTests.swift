//
//  APIClientTests.swift
//  BrrowTests
//
//  Unit tests for APIClient
//

import XCTest
@testable import Brrow

final class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    
    override func setUpWithError() throws {
        apiClient = APIClient()
    }
    
    override func tearDownWithError() throws {
        apiClient = nil
    }
    
    func testFetchListings() async throws {
        let listings = try await apiClient.fetchListings()
        
        XCTAssertFalse(listings.isEmpty)
        XCTAssertEqual(listings.count, 10) // Mock data returns 10 items
        
        let firstListing = listings.first!
        XCTAssertFalse(firstListing.title.isEmpty)
        XCTAssertGreaterThan(firstListing.price, 0)
        XCTAssertFalse(firstListing.category.isEmpty)
    }
    
    func testSearchListings() async throws {
        let listings = try await apiClient.searchListings(query: "camera")
        
        XCTAssertFalse(listings.isEmpty)
        // Verify search results contain the query term
        let containsQuery = listings.contains { listing in
            listing.title.lowercased().contains("camera") ||
            listing.description.lowercased().contains("camera")
        }
        XCTAssertTrue(containsQuery)
    }
    
    func testFetchUserProfile() async throws {
        let profile = try await apiClient.fetchUserProfile(userId: "1")
        
        XCTAssertFalse(profile.username.isEmpty)
        XCTAssertFalse(profile.email.isEmpty)
        XCTAssertEqual(profile.id, 1)
    }
    
    func testCreateListing() async throws {
        let request = CreateListingRequest(
            title: "Test Item",
            description: "Test description",
            category: "Electronics",
            price: 25.0,
            isFree: false,
            location: "Test Location",
            availableDate: Date(),
            imageUrls: []
        )
        
        // Should not throw an error
        try await apiClient.createListing(request)
    }
    
    func testNetworkError() async {
        // Test with invalid endpoint to trigger network error
        do {
            _ = try await apiClient.fetchUserProfile(userId: "invalid")
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testRequestTimeout() async {
        // Test with long-running request to test timeout
        let start = Date()
        
        do {
            _ = try await apiClient.fetchListingsWithDelay(delay: 10) // 10 second delay
            XCTFail("Expected timeout error")
        } catch {
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertLessThan(elapsed, 10) // Should timeout before 10 seconds
        }
    }
    
    func testRateLimiting() async {
        // Test multiple rapid requests
        var requestCount = 0
        let requests = (1...10).map { _ in
            Task {
                do {
                    _ = try await apiClient.fetchListings()
                    requestCount += 1
                } catch {
                    // Rate limiting may cause some requests to fail
                }
            }
        }
        
        // Wait for all requests to complete
        for request in requests {
            _ = await request.result
        }
        
        // At least some requests should succeed
        XCTAssertGreaterThan(requestCount, 0)
    }
}