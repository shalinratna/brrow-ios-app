//
//  CreateListingViewModel.swift
//  Brrow
//
//  Created by Shalin Ratna on 7/16/25.
//

import SwiftUI
import PhotosUI
import CoreLocation
import Combine

class CreateListingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title = ""
    @Published var description = ""
    @Published var selectedCategory = ""
    @Published var selectedType = ""
    @Published var price = ""
    @Published var pricePerDay = ""
    @Published var buyoutValue = ""
    @Published var location = ""
    @Published var inventoryAmount = "1"
    @Published var isFree = false
    
    // Image handling
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    
    // UI State
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showSuccessAlert = false
    
    // Location properties
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var isLoadingLocation = false
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    let categories = ["Tools", "Electronics", "Books", "Clothing", "Sports", "Home & Garden", "Vehicles", "Other"]
    
    let listingTypes: [(key: String, value: (title: String, description: String))] = [
        ("for_sale", (title: "For Sale", description: "Sell this item permanently")),
        ("for_rent", (title: "For Rent", description: "Rent this item for a period of time")),
        ("borrow", (title: "Borrow", description: "Lend this item temporarily for free")),
        ("giveaway", (title: "Giveaway", description: "Give this item away for free"))
    ]
    
    // MARK: - Initialization
    init() {
        setupLocationObserver()
        setupPhotoObserver()
        
        // Use current location as default if available
        if let currentLocation = locationService.currentLocation {
            self.currentCoordinate = currentLocation.coordinate
            
            // Get formatted address
            locationService.getAddress(from: currentLocation)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] address in
                        self?.location = address
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func setupPhotoObserver() {
        $selectedPhotos
            .sink { [weak self] photos in
                self?.loadImages(from: photos)
            }
            .store(in: &cancellables)
    }
    
    func refreshLocation() {
        locationService.startUpdatingLocation()
        
        // If we already have a location, use it
        if let currentLocation = locationService.currentLocation {
            self.currentCoordinate = currentLocation.coordinate
            
            // Get formatted address if location field is empty
            if self.location.isEmpty {
                locationService.getAddress(from: currentLocation)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] address in
                            self?.location = address
                        }
                    )
                    .store(in: &cancellables)
            }
        }
    }
    
    private func setupLocationObserver() {
        locationService.$currentLocation
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                self.currentCoordinate = location.coordinate
                
                // Auto-fill location field with address if empty
                if self.location.isEmpty {
                    self.locationService.getAddress(from: location)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { [weak self] address in
                                self?.location = address
                            }
                        )
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    var isTitleValid: Bool {
        // Check length
        guard title.count >= 3 && title.count <= 100 else { return false }
        // Check for special characters - only allow letters, numbers, spaces, and basic punctuation
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        let specialCharacters = CharacterSet(charactersIn: "#@$%^&*()_+={}[]|\\:;<>?,/~`")
        return title.rangeOfCharacter(from: specialCharacters) == nil
    }
    
    var titleValidationMessage: String? {
        if title.isEmpty {
            return nil
        }
        if title.count < 3 {
            return "Title must be at least 3 characters"
        }
        if title.count > 100 {
            return "Title must be less than 100 characters"
        }
        let specialCharacters = CharacterSet(charactersIn: "#@$%^&*()_+={}[]|\\:;<>?,/~`")
        if title.rangeOfCharacter(from: specialCharacters) != nil {
            return "Title cannot contain special characters like #, @, $, etc."
        }
        return nil
    }
    
    var isDescriptionValid: Bool {
        // Check length
        guard description.count >= 10 && description.count <= 1000 else { return false }
        // Allow more characters in description but still block potentially harmful ones
        let dangerousCharacters = CharacterSet(charactersIn: "<>{}[]\\|`")
        return description.rangeOfCharacter(from: dangerousCharacters) == nil
    }
    
    var descriptionValidationMessage: String? {
        if description.isEmpty {
            return nil
        }
        if description.count < 10 {
            return "Description must be at least 10 characters"
        }
        if description.count > 1000 {
            return "Description must be less than 1000 characters"
        }
        let dangerousCharacters = CharacterSet(charactersIn: "<>{}[]\\|`")
        if description.rangeOfCharacter(from: dangerousCharacters) != nil {
            return "Description cannot contain characters like <, >, {, }, etc."
        }
        return nil
    }
    
    var isPriceValid: Bool {
        if isFree { return true }
        guard let priceValue = Double(price) else { return false }
        // Minimum price is $3, maximum is $10000
        return priceValue >= 3.0 && priceValue <= 10000
    }
    
    var priceValidationMessage: String? {
        if isFree { return nil }
        guard let priceValue = Double(price) else {
            return "Please enter a valid price"
        }
        if priceValue < 3.0 {
            return "Minimum price is $3"
        }
        if priceValue >= 100 && !(AuthManager.shared.currentUser?.verified ?? false) {
            return "Verified account required for listings $100+"
        }
        if priceValue > 10000 {
            return "Maximum price is $10,000"
        }
        return nil
    }
    
    var isLocationValid: Bool {
        return location.count >= 3 && location.count <= 100
    }
    
    var isInventoryValid: Bool {
        guard let inventory = Int(inventoryAmount) else { return false }
        return inventory > 0 && inventory <= 100
    }
    
    var canSubmit: Bool {
        // Check basic validations
        let basicValid = isTitleValid &&
                        isDescriptionValid &&
                        !selectedCategory.isEmpty &&
                        !selectedType.isEmpty &&
                        isPriceValid &&
                        isLocationValid &&
                        isInventoryValid &&
                        !isLoading
        
        // Check verified account requirement for high-value listings
        if !isFree, let priceValue = Double(price), priceValue >= 100 {
            return basicValid && (AuthManager.shared.currentUser?.verified ?? false)
        }
        
        return basicValid
    }
    
    // MARK: - Image Handling
    private func loadImages(from photos: [PhotosPickerItem]) {
        selectedImages.removeAll()
        
        for photo in photos {
            photo.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            self.selectedImages.append(image)
                        }
                    case .failure(let error):
                        print("Error loading image: \(error)")
                    }
                }
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        selectedPhotos.remove(at: index)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func getCategoryId(for categoryName: String) async -> String {
        // Map category names to IDs (these should match what's in the database)
        let categoryMap: [String: String] = [
            "Electronics": "cmf7c7sci0000pt0ruo6ooqui",
            "Furniture": "cmf7c7sps0001pt0rliuzbu0u",
            "Clothing & Fashion": "cmf7c7taa0002pt0r718q1iw7",
            "Vehicles": "cmf7c7tal0003pt0rw8agqrq3",
            "Sports & Outdoors": "cmf7c7tax0004pt0r0l90rc4b",
            "Books & Media": "cmf7c7tbg0005pt0rx36ct66l",
            "Toys & Games": "cmf7c7tc70006pt0rikmtbbd8",
            "Tools & Equipment": "cmf7c7tcx0007pt0rwcdafp3n",
            "Home & Garden": "cmf7c7td70008pt0rhgd2oi1r",
            "Beauty & Health": "cmf7c7u0f0009pt0rld3ijaf5",
            "Pets & Animals": "cmf7c7u19000apt0r35ztyxj9",
            "Services": "cmf7c7u1j000bpt0rtnhiwsiy",
            "Other": "cmf7c7u1x000cpt0rhf0gw3v3"
        ]
        
        return categoryMap[categoryName] ?? "cmf7c7u1x000cpt0rhf0gw3v3" // Default to "Other"
    }
    
    // MARK: - Location Methods
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func geocodeLocation() {
        guard !location.isEmpty else { return }
        
        isLoadingLocation = true
        locationService.getCoordinates(from: location)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingLocation = false
                    if case .failure(let error) = completion {
                        print("Geocoding error: \(error)")
                    }
                },
                receiveValue: { [weak self] coordinate in
                    self?.currentCoordinate = coordinate
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - API Methods
    func createListing() {
        // Check price validation first
        if let priceError = priceValidationMessage {
            errorMessage = priceError
            return
        }
        
        guard canSubmit else { 
            errorMessage = "Please fill in all required fields correctly"
            return 
        }
        
        // Perform local content moderation
        let moderationResult = ContentModerator.shared.moderateListingContent(
            title: title,
            description: description,
            category: selectedCategory
        )
        
        if !moderationResult.isPassed {
            errorMessage = moderationResult.message
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task { @MainActor in
            do {
                // Upload images with proper error handling and parallel execution
                let uploadedImageUrls = try await uploadImagesInParallel()
                
                // If no images uploaded successfully, show error
                if selectedImages.count > 0 && uploadedImageUrls.isEmpty {
                    throw BrrowAPIError.networkError("Failed to upload images. Please try again.")
                }
                
                // Note: The location coordinates are now passed directly in the request
                
                let request = CreateListingRequest(
                    title: title,
                    description: description,
                    price: isFree ? 0.0 : Double(price) ?? 0.0,
                    category: selectedCategory,
                    location: location,
                    type: selectedType,
                    images: uploadedImageUrls,
                    inventoryAmt: Int(inventoryAmount) ?? 1,
                    isFree: isFree,
                    pricePerDay: selectedType == "for_rent" ? Double(price) : nil,
                    buyoutValue: buyoutValue.isEmpty ? nil : Double(buyoutValue),
                    latitude: currentCoordinate?.latitude ?? 37.7749,  // Default to SF if no location
                    longitude: currentCoordinate?.longitude ?? -122.4194
                )
                
                let listing = try await APIClient.shared.createListing(request)
                
                isLoading = false
                trackListingCreationSuccess(listing)
                // Update widget data
                WidgetDataManager.shared.handleNewListingCreated()
                WidgetIntegrationService.shared.notifyListingCreated(listing)
                // Post notification for other observers
                NotificationCenter.default.post(name: .listingCreated, object: listing)
                // Show success alert last to avoid any UI conflicts
                showSuccessAlert = true
                
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                trackListingCreationError(error.localizedDescription)
            }
        }
    }
    
    // Upload images with highest quality processing
    private func uploadImagesInParallel() async throws -> [String] {
        guard !selectedImages.isEmpty else { return [] }
        
        // Use high-quality image processor
        let processor = HighQualityImageProcessor.shared
        
        print("🖼️ Processing \(selectedImages.count) listing images with highest quality...")
        
        // Process all images with high quality settings for listings
        let processedImages = try await processor.processImages(
            selectedImages,
            for: .listing,  // Use listing context for highest resolution
            progress: { progress in
                Task { @MainActor in
                    // Update progress if needed
                    let percentage = Int(progress * 100)
                    print("Processing: \(percentage)%")
                }
            }
        )
        
        print("📤 Uploading processed images...")
        
        // Upload processed images in parallel for maximum speed
        // Generate a temporary listing ID for organizing uploads
        let tempListingId = "temp_\(UUID().uuidString.prefix(8))"
        
        let uploadedUrls = try await processor.uploadProcessedImages(
            processedImages,
            to: "api/upload",  // Use new entity-based upload endpoint
            entityType: "listings",
            entityId: tempListingId  // Will be updated with real ID after creation
        )
        
        // Log results
        print("✅ Successfully uploaded \(uploadedUrls.count) high-quality images")
        for (index, url) in uploadedUrls.enumerated() {
            let size = processedImages[index].readableFileSize
            let dimensions = processedImages[index].dimensions
            print("  📸 Image \(index + 1): \(Int(dimensions.width))x\(Int(dimensions.height)) (\(size)) -> \(url)")
        }
        
        return uploadedUrls
    }
    
    func resetForm() {
        title = ""
        description = ""
        selectedCategory = ""
        selectedType = ""
        price = ""
        pricePerDay = ""
        buyoutValue = ""
        location = ""
        inventoryAmount = "1"
        isFree = false
        selectedPhotos.removeAll()
        selectedImages.removeAll()
    }
    
    // MARK: - Analytics
    private func trackListingCreationSuccess(_ listing: Listing) {
        let event = AnalyticsEvent(
            eventName: "listing_created",
            eventType: "content",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "listing_id": listing.id,
                "category": selectedCategory,
                "type": selectedType,
                "has_images": String(selectedImages.count > 0),
                "image_count": String(selectedImages.count),
                "is_free": String(isFree),
                "platform": "ios"
            ]
        )
        
        Task {
            try? await APIClient.shared.trackAnalytics(event: event)
        }
    }
    
    private func trackListingCreationError(_ error: String) {
        let event = AnalyticsEvent(
            eventName: "listing_creation_error",
            eventType: "error",
            userId: AuthManager.shared.currentUser?.apiId,
            sessionId: AuthManager.shared.sessionId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            metadata: [
                "error": error,
                "category": selectedCategory,
                "type": selectedType,
                "platform": "ios"
            ]
        )
        
        Task {
            try? await APIClient.shared.trackAnalytics(event: event)
        }
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resizedImage(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}