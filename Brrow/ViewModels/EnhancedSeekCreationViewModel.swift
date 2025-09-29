//
//  EnhancedSeekCreationViewModel.swift
//  Brrow
//
//  Enhanced seek creation with modern image handling and full CRUD support
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
class EnhancedSeekCreationViewModel: ObservableObject {
    // Basic seek info
    @Published var title = ""
    @Published var description = ""
    @Published var category = ""
    @Published var selectedTags: Set<String> = []
    @Published var customTags: [String] = []

    // Location
    @Published var location = ""
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var maxDistance: Double = 10.0 // km

    // Budget
    @Published var minBudget: Double?
    @Published var maxBudget: Double?
    @Published var hasBudgetRange = false

    // Urgency and timing
    @Published var urgency: SeekUrgency = .normal
    @Published var hasDeadline = false
    @Published var deadline = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week from now

    // Images
    @Published var selectedImages: [UIImage] = []
    @Published var uploadedImageURLs: [String] = []
    @Published var isUploadingImages = false

    // UI State
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var validationErrors: [String] = []

    // Available categories for seeks
    let availableCategories = [
        "Electronics", "Furniture", "Vehicles", "Books", "Clothing",
        "Tools", "Sports Equipment", "Musical Instruments", "Art & Collectibles",
        "Home & Garden", "Services", "Other"
    ]

    // Common tags
    let commonTags = [
        "urgent", "flexible", "budget-friendly", "quality", "vintage",
        "new", "used", "rare", "local", "pickup", "delivery"
    ]

    private let apiClient = APIClient.shared
    private let fileUploadService = FileUploadService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.isEmpty &&
        !location.isEmpty &&
        maxDistance > 0
    }

    var allTags: [String] {
        Array(selectedTags) + customTags
    }

    var formattedBudgetRange: String {
        guard hasBudgetRange else { return "Not specified" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0

        if let min = minBudget, let max = maxBudget {
            return "\(formatter.string(from: NSNumber(value: min)) ?? "$\(Int(min))") - \(formatter.string(from: NSNumber(value: max)) ?? "$\(Int(max))")"
        } else if let min = minBudget {
            return "From \(formatter.string(from: NSNumber(value: min)) ?? "$\(Int(min))")"
        } else if let max = maxBudget {
            return "Up to \(formatter.string(from: NSNumber(value: max)) ?? "$\(Int(max))")"
        }

        return "Not specified"
    }

    // MARK: - Image Handling

    func addImages(_ images: [UIImage]) {
        selectedImages.append(contentsOf: images)
        // Limit to 5 images
        if selectedImages.count > 5 {
            selectedImages = Array(selectedImages.prefix(5))
        }
    }

    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }

    private func uploadImages() async throws -> [String] {
        guard !selectedImages.isEmpty else { return [] }

        await MainActor.run {
            isUploadingImages = true
        }

        var uploadedURLs: [String] = []

        for (index, image) in selectedImages.enumerated() {
            do {
                let url = try await fileUploadService.uploadImage(
                    image,
                    fileName: "seek_image_\(index)_\(UUID().uuidString).jpg"
                )
                uploadedURLs.append(url)
                print("✅ Uploaded seek image \(index + 1): \(url)")
            } catch {
                print("❌ Failed to upload seek image \(index + 1): \(error)")
                // Continue with other images even if one fails
            }
        }

        await MainActor.run {
            uploadedImageURLs = uploadedURLs
            isUploadingImages = false
        }

        return uploadedURLs
    }

    // MARK: - Validation

    private func validateSeek() -> [String] {
        var errors: [String] = []

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title is required")
        }

        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Description is required")
        }

        if category.isEmpty {
            errors.append("Category is required")
        }

        if location.isEmpty {
            errors.append("Location is required")
        }

        if maxDistance <= 0 {
            errors.append("Search radius must be greater than 0")
        }

        if hasBudgetRange {
            if let min = minBudget, let max = maxBudget, min > max {
                errors.append("Minimum budget cannot be greater than maximum budget")
            }
        }

        if hasDeadline && deadline <= Date() {
            errors.append("Deadline must be in the future")
        }

        return errors
    }

    // MARK: - Location Handling

    func updateLocation(_ newLocation: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.location = newLocation
        self.latitude = latitude
        self.longitude = longitude
    }

    // MARK: - Create Seek

    func createSeek() {
        // Validate first
        let errors = validateSeek()
        if !errors.isEmpty {
            validationErrors = errors
            errorMessage = errors.first
            return
        }

        isCreating = true
        errorMessage = nil
        validationErrors = []

        Task {
            do {
                // Upload images first
                let imageURLs = try await uploadImages()

                // Prepare expiration date
                let expirationDate = hasDeadline ? deadline : nil
                let expirationString = expirationDate?.ISO8601Format()

                // Create seek request
                let request = CreateSeekRequest(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: category,
                    location: location,
                    latitude: latitude,
                    longitude: longitude,
                    maxDistance: maxDistance,
                    minBudget: hasBudgetRange ? minBudget : nil,
                    maxBudget: hasBudgetRange ? maxBudget : nil,
                    urgency: urgency.rawValue,
                    expiresAt: expirationString,
                    images: imageURLs,
                    tags: allTags
                )

                print("🔍 Creating seek with request:")
                print("   📝 Title: \(request.title)")
                print("   📂 Category: \(request.category)")
                print("   📍 Location: \(request.location)")
                print("   💰 Budget: \(formattedBudgetRange)")
                print("   📸 Images: \(imageURLs.count)")
                print("   🏷️ Tags: \(allTags)")

                let createdSeek = try await apiClient.createSeek(request)

                await MainActor.run {
                    self.isCreating = false
                    self.showSuccess = true
                    print("✅ Seek created successfully with ID: \(createdSeek.id)")

                    // Track analytics
                    self.trackSeekCreation()
                }

            } catch {
                await MainActor.run {
                    self.isCreating = false
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to create seek: \(error)")
                }
            }
        }
    }

    // MARK: - Analytics

    private func trackSeekCreation() {
        // Track seek creation for analytics
        let properties: [String: Any] = [
            "category": category,
            "has_budget_range": hasBudgetRange,
            "has_deadline": hasDeadline,
            "urgency": urgency.rawValue,
            "image_count": selectedImages.count,
            "tag_count": allTags.count
        ]

        // Add to analytics system when available
        print("📊 Seek creation tracked with properties: \(properties)")
    }

    // MARK: - Reset

    func reset() {
        title = ""
        description = ""
        category = ""
        selectedTags.removeAll()
        customTags.removeAll()
        location = ""
        latitude = nil
        longitude = nil
        maxDistance = 10.0
        minBudget = nil
        maxBudget = nil
        hasBudgetRange = false
        urgency = .normal
        hasDeadline = false
        deadline = Date().addingTimeInterval(7 * 24 * 60 * 60)
        selectedImages.removeAll()
        uploadedImageURLs.removeAll()
        isUploadingImages = false
        isCreating = false
        errorMessage = nil
        showSuccess = false
        validationErrors.removeAll()
    }
}

// MARK: - Seek Urgency Enum
enum SeekUrgency: String, CaseIterable {
    case low = "low"
    case normal = "medium"
    case high = "high"
    case urgent = "urgent"

    var displayName: String {
        switch self {
        case .low: return "Low Priority"
        case .normal: return "Normal"
        case .high: return "High Priority"
        case .urgent: return "Urgent"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "tortoise.fill"
        case .normal: return "hare.fill"
        case .high: return "flame.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }

    var description: String {
        switch self {
        case .low: return "Flexible timeline"
        case .normal: return "Within a week"
        case .high: return "Within 2-3 days"
        case .urgent: return "ASAP - Within 24 hours"
        }
    }
}