//
//  PostCreationViewModel.swift
//  Brrow
//
//  Create Posts with AI Assistance
//

import Foundation
import UIKit
import PhotosUI
import Combine

@MainActor
class PostCreationViewModel: ObservableObject {
    // Listing properties
    @Published var title = ""
    @Published var description = ""
    @Published var selectedCategory = "Electronics"
    @Published var price = ""
    @Published var isFree = false
    @Published var location = ""
    @Published var availableNow = true
    @Published var availableDate = Date()
    @Published var selectedPhotos: [UIImage] = []
    
    // Seek properties
    @Published var seekTitle = ""
    @Published var seekDescription = ""
    @Published var maxBudget = ""
    @Published var neededBy = Date()
    @Published var aiSuggestions: [String] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let aiService = BrrowAIService.shared
    
    static let categories = [
        "Electronics", "Tools", "Sports", "Kitchen", "Books", 
        "Garden", "Furniture", "Clothing", "Toys", "Vehicles"
    ]
    
    enum PostType {
        case listing
        case seek
    }
    
    var canPost: Bool {
        if !title.isEmpty && !description.isEmpty && !location.isEmpty {
            return true
        }
        if !seekTitle.isEmpty && !seekDescription.isEmpty {
            return true
        }
        return false
    }
    
    func loadImages(from items: [Any]) {
        // Simplified for now - in real implementation would handle PhotosPickerItem
        print("Loading images from picker items")
    }
    
    func removePhoto(at index: Int) {
        selectedPhotos.remove(at: index)
    }
    
    func generateAISuggestions() {
        guard !seekDescription.isEmpty else {
            aiSuggestions = []
            return
        }
        
        Task {
            do {
                let suggestions = try await aiService.getSeekSuggestions(for: seekDescription)
                self.aiSuggestions = suggestions
            } catch {
                print("Failed to generate AI suggestions: \(error)")
                // Fallback suggestions
                self.aiSuggestions = generateFallbackSuggestions()
            }
        }
    }
    
    func applySuggestion(_ suggestion: String) {
        if seekTitle.isEmpty {
            seekTitle = suggestion
        } else {
            seekDescription += " " + suggestion
        }
    }
    
    func createPost(type: PostType) async {
        isLoading = true
        errorMessage = nil
        
        do {
            switch type {
            case .listing:
                try await createListing()
            case .seek:
                try await createSeek()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func createListing() async throws {
        // Upload images first
        var imageUrls: [String] = []
        for image in selectedPhotos {
            let url = try await uploadImage(image)
            imageUrls.append(url)
        }
        
        // Create location object with actual geocoding
        let locationObj = try await geocodeAddress(location)
        
        let listing = CreateListingRequest(
            title: title,
            description: description,
            price: isFree ? 0.0 : Double(price) ?? 0.0,
            categoryId: "cat_general",
            condition: "GOOD",
            location: Location(
                address: location,
                city: "Unknown",
                state: "Unknown",
                zipCode: "00000",
                country: "US",
                latitude: locationObj.latitude,
                longitude: locationObj.longitude
            ),
            isNegotiable: true,
            deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
            tags: [],
            images: imageUrls.map { url in
                CreateListingRequest.ImageUpload(
                    url: url,
                    thumbnailUrl: nil,
                    width: nil,
                    height: nil,
                    fileSize: nil
                )
            },
            videos: nil
        )
        
        _ = try await apiClient.createListing(listing)
        
        // Track analytics
        trackPostCreation(type: "listing")
    }
    
    private func createSeek() async throws {
        // Create location object with actual geocoding
        let locationObj = try await geocodeAddress(location)
        
        let seek = CreateSeekRequest(
            title: seekTitle,
            description: seekDescription,
            category: selectedCategory,
            maxPrice: Double(maxBudget) ?? 0.0,
            radius: 25.0, // Default 25 mile radius
            location: locationObj
        )
        
        _ = try await apiClient.createSeek(seek)
        
        // Track analytics
        trackPostCreation(type: "seek")
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        // Upload image to cloud storage via API
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let uploadResponse = try await apiClient.uploadImage(imageData: imageData)
        return uploadResponse.data?.url ?? ""
    }
    
    private func generateFallbackSuggestions() -> [String] {
        let commonSuggestions = [
            "Near me", "This weekend", "Good condition", "Clean",
            "Portable", "Easy pickup", "Flexible timing", "Fair price"
        ]
        return Array(commonSuggestions.shuffled().prefix(4))
    }
    
    private func trackPostCreation(type: String) {
        let event = AnalyticsEvent(
            eventName: "post_created",
            eventType: "content",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "post_type": type,
                "category": selectedCategory,
                "has_images": !selectedPhotos.isEmpty,
                "platform": "ios"
            ]
        )
        
        Task {
            _ = try? await apiClient.trackAnalytics(event: event)
        }
    }
    
    private func geocodeAddress(_ address: String) async throws -> Location {
        // Use API endpoint for geocoding
        return try await apiClient.geocodeAddress(address)
    }
}

// MARK: - Request Models (using APIClient models)

// MARK: - AI Service Extensions

extension BrrowAIService {
    func getSeekSuggestions(for description: String) async throws -> [String] {
        // Call AI endpoint for seek suggestions
        return try await APIClient.shared.fetchSeekSuggestions(description: description)
    }
}

// MARK: - API Client Extensions (methods are in APIClient.swift)