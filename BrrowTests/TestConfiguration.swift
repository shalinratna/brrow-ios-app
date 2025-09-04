//
//  TestConfiguration.swift
//  BrrowTests
//
//  Test configuration and mocking utilities
//

import Foundation
@testable import Brrow

class TestConfiguration {
    static let shared = TestConfiguration()
    
    private init() {}
    
    // MARK: - Mock Data
    
    static let mockUser = User(
        id: 1,
        username: "testuser",
        email: "test@example.com",
        profilePicture: nil
    )
    
    static let mockListings: [Listing] = [
        Listing(
            id: 1,
            ownerId: 2,
            title: "Professional Camera",
            description: "High-quality DSLR camera perfect for photography",
            price: 45.0,
            priceType: .daily,
            buyoutValue: nil,
            createdAt: Date(),
            updatedAt: nil,
            status: "available",
            category: "Electronics",
            type: "rental",
            location: Location(
                address: "123 Market St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94105",
                country: "US",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            views: 25,
            timesBorrowed: 15,
            inventoryAmt: 1,
            isActive: true,
            isArchived: false,
            images: ["https://picsum.photos/300/200?random=1"],
            rating: 4.8
        ),
        Listing(
            id: 2,
            ownerId: 3,
            title: "Power Drill",
            description: "Cordless power drill with multiple bits",
            price: 15.0,
            priceType: .daily,
            buyoutValue: nil,
            createdAt: Date(),
            updatedAt: nil,
            status: "available",
            category: "Tools",
            type: "rental",
            location: Location(
                address: "456 Mission St",
                city: "San Francisco",
                state: "CA",
                zipCode: "94103",
                country: "US",
                latitude: 37.7849,
                longitude: -122.4094
            ),
            views: 18,
            timesBorrowed: 8,
            inventoryAmt: 1,
            isActive: true,
            isArchived: false,
            images: ["https://picsum.photos/300/200?random=2"],
            rating: 4.9
        )
    ]
    
    static let mockConversations: [Conversation] = [
        Conversation(
            id: "1",
            otherUser: mockUser,
            lastMessage: ChatMessage(
                id: "1",
                senderId: "2",
                receiverId: "1",
                content: "Hi! Is the camera still available?",
                messageType: "text",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                isRead: false
            ),
            unreadCount: 1,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    ]
    
    // MARK: - Test Helpers
    
    static func setupMockAuthenticatedUser() {
        AuthManager.shared.currentUser = mockUser
        AuthManager.shared.isAuthenticated = true
    }
    
    static func clearAuthentication() {
        AuthManager.shared.currentUser = nil
        AuthManager.shared.isAuthenticated = false
    }
    
    static func createMockListing(
        title: String = "Test Item",
        price: Double = 25.0,
        category: String = "Electronics"
    ) -> Listing {
        return Listing(
            id: Int.random(in: 1000...9999),
            ownerId: 1,
            title: title,
            description: "Test description for \(title)",
            price: price,
            priceType: .daily,
            buyoutValue: nil,
            createdAt: Date(),
            updatedAt: nil,
            status: "available",
            category: category,
            type: "rental",
            location: Location(
                address: "123 Test St",
                city: "Test City",
                state: "CA",
                zipCode: "90210",
                country: "US",
                latitude: 34.0522,
                longitude: -118.2437
            ),
            views: Int.random(in: 1...50),
            timesBorrowed: 10,
            inventoryAmt: 1,
            isActive: true,
            isArchived: false,
            images: ["https://picsum.photos/300/200?random=\(Int.random(in: 1...100))"],
            rating: 4.5
        )
    }
    
    static func createMockMessage(
        content: String = "Test message",
        senderId: String = "1",
        receiverId: String = "2"
    ) -> ChatMessage {
        return ChatMessage(
            id: UUID().uuidString,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            messageType: "text",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            isRead: false
        )
    }
}

// MARK: - Mock APIClient for Testing

class MockAPIClient {
    var shouldReturnError = false
    var delayResponse = false
    var mockListings = TestConfiguration.mockListings
    var mockUser = TestConfiguration.mockUser
    
    func fetchListings() async throws -> [Listing] {
        if shouldReturnError {
            throw APIError.networkError
        }
        
        if delayResponse {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
        
        return mockListings
    }
    
    func searchListings(query: String) async throws -> [Listing] {
        if shouldReturnError {
            throw APIError.networkError
        }
        
        return mockListings.filter { listing in
            listing.title.lowercased().contains(query.lowercased()) ||
            listing.description.lowercased().contains(query.lowercased())
        }
    }
    
    func fetchUserProfile(userId: String) async throws -> User {
        if shouldReturnError {
            throw APIError.networkError
        }
        
        if userId == "invalid" {
            throw APIError.notFound
        }
        
        return mockUser
    }
    
    func fetchListingsWithDelay(delay: TimeInterval) async throws -> [Listing] {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return mockListings
    }
}

// MARK: - Test Extensions

extension APIError: @retroactive Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError, .networkError),
             (.invalidResponse, .invalidResponse),
             (.notFound, .notFound),
             (.unauthorized, .unauthorized):
            return true
        default:
            return false
        }
    }
}