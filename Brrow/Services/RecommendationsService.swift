import Foundation
import CoreLocation

/// Service for fetching ML-powered personalized recommendations
class RecommendationsService {
    static let shared = RecommendationsService()

    private init() {}

    // MARK: - Fetch Personalized Feed
    /// Get the main "For You" feed with smart blending
    func fetchForYouFeed(
        limit: Int = 30,
        userLocation: CLLocationCoordinate2D? = nil
    ) async throws -> [Listing] {
        var endpoint = "recommendations/for-you?limit=\(limit)"

        if let location = userLocation {
            endpoint += "&lat=\(location.latitude)&lng=\(location.longitude)"
        }

        let response: RecommendationsResponse = try await APIClient.shared.makeRequest(endpoint)

        if response.success {
            return response.data
        } else {
            throw RecommendationError.fetchFailed
        }
    }

    // MARK: - Fetch Personalized Recommendations
    /// Get personalized recommendations based on user's patterns
    func fetchPersonalizedRecommendations(
        limit: Int = 20,
        userLocation: CLLocationCoordinate2D? = nil
    ) async throws -> [Listing] {
        var endpoint = "recommendations/personalized?limit=\(limit)"

        if let location = userLocation {
            endpoint += "&lat=\(location.latitude)&lng=\(location.longitude)"
        }

        let response: RecommendationsResponse = try await APIClient.shared.makeRequest(endpoint)

        if response.success {
            return response.data
        } else {
            throw RecommendationError.fetchFailed
        }
    }

    // MARK: - Fetch Similar Listings
    /// Get listings similar to a specific listing
    func fetchSimilarListings(
        to listingId: String,
        limit: Int = 5
    ) async throws -> [Listing] {
        let endpoint = "recommendations/listings/\(listingId)/similar?limit=\(limit)"

        let response: RecommendationsResponse = try await APIClient.shared.makeRequest(endpoint)

        if response.success {
            return response.data
        } else {
            throw RecommendationError.fetchFailed
        }
    }

    // MARK: - Fetch Frequently Viewed Together
    /// Get listings frequently viewed with a specific listing
    func fetchFrequentlyViewedTogether(
        with listingId: String,
        limit: Int = 5
    ) async throws -> [Listing] {
        let endpoint = "recommendations/listings/\(listingId)/viewed-together?limit=\(limit)"

        let response: RecommendationsResponse = try await APIClient.shared.makeRequest(endpoint)

        if response.success {
            return response.data
        } else {
            throw RecommendationError.fetchFailed
        }
    }

    // MARK: - Refresh Recommendations
    /// Clear recommendation cache and force fresh results
    func refreshRecommendations() async throws {
        struct RefreshResponse: Codable {
            let success: Bool
            let message: String
        }

        let response: RefreshResponse = try await APIClient.shared.makeRequest(
            "recommendations/refresh",
            method: "POST"
        )

        if response.success {
            print("✅ Recommendations cache cleared")
        } else {
            throw RecommendationError.refreshFailed
        }
    }
}

// MARK: - Response Models
private struct RecommendationsResponse: Codable {
    let success: Bool
    let data: [Listing]
    let count: Int
    let algorithm: String?
    let metadata: RecommendationMetadata?
}

private struct RecommendationMetadata: Codable {
    let personalizedCount: Int?
    let collaborativeCount: Int?
    let contentBasedCount: Int?
    let blendRatio: String?
    let personalizationEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case personalizedCount = "personalized_count"
        case collaborativeCount = "collaborative_count"
        case contentBasedCount = "content_based_count"
        case blendRatio = "blend_ratio"
        case personalizationEnabled = "personalization_enabled"
    }
}

// MARK: - Errors
enum RecommendationError: Error {
    case fetchFailed
    case refreshFailed
}
